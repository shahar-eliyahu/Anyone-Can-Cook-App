import asyncio

import pytest
from pydantic import BaseModel

from app.config import Settings
from app.services.llm import LLMError, TextPart
from app.services.llm.factory import build_llm_provider
from app.services.llm.mock import MockProvider


class Greeting(BaseModel):
    text: str


def test_factory_defaults_to_mock():
    provider = build_llm_provider(Settings(_env_file=None))
    assert provider.name == "mock"


def test_factory_gemini_without_key_fails_clearly():
    with pytest.raises(LLMError, match="GEMINI_API_KEY"):
        build_llm_provider(Settings(_env_file=None, ai_provider="gemini", gemini_api_key=None))


def test_mock_returns_registered_fixture_validated():
    provider = MockProvider({Greeting: {"text": "שלום"}})
    result = asyncio.run(provider.generate_structured("sys", [TextPart("hi")], Greeting))
    assert result == Greeting(text="שלום")


def test_mock_without_fixture_raises():
    with pytest.raises(LLMError):
        asyncio.run(MockProvider().generate_structured("sys", [TextPart("hi")], Greeting))


def test_mock_stream_chat_yields_text():
    async def collect():
        return "".join([c async for c in MockProvider().stream_chat("sys", "ctx", [])])

    assert "דמו" in asyncio.run(collect())


def test_guard_blocks_gemini_client_and_outside_network():
    import socket

    from google import genai

    from tests.conftest import RealNetworkUsed

    with pytest.raises(RealNetworkUsed):
        genai.Client(api_key="not-a-key")
    with pytest.raises(RealNetworkUsed):
        socket.create_connection(("93.184.216.34", 443), timeout=1)


# ---- Gemini quota and rate-limit errors (mocked 429 bodies, no client is created) ----------

from google.genai import errors as genai_errors

from app.services.llm import LLMRateLimited
from app.services.llm.gemini import GeminiProvider, rate_limit_error


def gemini_429(quota_id: str | None, retry_delay: str | None = None) -> dict:
    details = []
    if quota_id:
        details.append({
            "@type": "type.googleapis.com/google.rpc.QuotaFailure",
            "violations": [{
                "quotaMetric": "generativelanguage.googleapis.com/generate_content_free_tier_requests",
                "quotaId": quota_id,
                "quotaValue": "20",
            }],
        })
    if retry_delay:
        details.append({"@type": "type.googleapis.com/google.rpc.RetryInfo", "retryDelay": retry_delay})
    return {"error": {"code": 429, "message": "You exceeded your current quota.", "status": "RESOURCE_EXHAUSTED",
                      "details": details}}


def test_daily_quota_is_recognized_and_its_retry_delay_is_not_trusted():
    e = rate_limit_error(gemini_429("GenerateRequestsPerDayPerProjectPerModel-FreeTier", "37s"))
    assert (e.scope, e.retry_after_seconds) == ("day", None)


def test_per_minute_limit_keeps_the_stated_delay():
    e = rate_limit_error(gemini_429("GenerateRequestsPerMinutePerProjectPerModel-FreeTier", "12.4s"))
    assert (e.scope, e.retry_after_seconds) == ("minute", 13)


@pytest.mark.parametrize("body", [
    gemini_429(None),
    gemini_429(None, "20s"),
    {"error": {"code": 429, "details": "not a list"}},
    {"error": "text"},
    None,
    ["unexpected"],
])
def test_unclear_429_bodies_are_temporary_with_no_promised_time_unless_stated(body):
    e = rate_limit_error(body)
    assert e.scope == "unknown"
    assert e.retry_after_seconds == (20 if body == gemini_429(None, "20s") else None)


def test_gemini_client_error_429_maps_to_rate_limited():
    provider = GeminiProvider.__new__(GeminiProvider)  # no real client
    provider._errors = genai_errors
    e = provider._translate(genai_errors.ClientError(429, gemini_429("GenerateRequestsPerDayPerProjectPerModel-FreeTier")))
    assert isinstance(e, LLMRateLimited) and e.scope == "day"
    assert not isinstance(provider._translate(genai_errors.ClientError(400, {"error": {"code": 400}})), LLMRateLimited)
