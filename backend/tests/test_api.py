"""HTTP-level behavior of /v1/recipes: security, limits and the error shape (fake provider)."""

import base64

import pytest
from fastapi.testclient import TestClient
from pydantic import SecretStr

from app.config import Settings, get_settings
from app.main import app
from app.security import DailyBudget, SlidingWindowLimiter, get_ai_budget, get_limiter
from app.services.llm import get_llm_provider
from scripts import make_mock_data
from tests.fakes import SAMPLE_SOURCE_TEXT, FakeProvider, mock_json

TOKEN = "test-app-token"
FAKE_KEY = "fake-gemini-key-xyz"


@pytest.fixture
def client():
    def make(provider=None, **settings_kw):
        settings = Settings(
            _env_file=None,
            ai_provider=settings_kw.pop("ai_provider", "gemini"),
            gemini_api_key=SecretStr(FAKE_KEY),
            ai_model="test-model",
            app_client_token=SecretStr(settings_kw.pop("token", TOKEN)) if settings_kw.get("token", TOKEN) else None,
            **{k: v for k, v in settings_kw.items() if k != "token"},
        )
        provider = provider or FakeProvider({
            "LlmAnalysis": [mock_json("sample_analysis.json")],
            "LlmPlan": [mock_json("sample_plan.json")],
        })
        app.dependency_overrides[get_settings] = lambda: settings
        app.dependency_overrides[get_llm_provider] = lambda: provider
        limiter, budget = SlidingWindowLimiter(), DailyBudget()
        app.dependency_overrides[get_limiter] = lambda: limiter
        app.dependency_overrides[get_ai_budget] = lambda: budget
        return TestClient(app), provider

    yield make
    app.dependency_overrides.clear()


def auth(token=TOKEN):
    return {"X-App-Token": token}


def test_full_text_flow_analyze_then_plan(client):
    c, provider = client()
    r = c.post("/v1/recipes/analyze", json={"type": "text", "content": SAMPLE_SOURCE_TEXT}, headers=auth())
    assert r.status_code == 200, r.text
    analysis = r.json()
    assert analysis["is_recipe"] and analysis["questions"] == []
    r = c.post("/v1/recipes/plan", json={"analysis": analysis}, headers=auth())
    assert r.status_code == 200, r.text
    body = r.json()
    assert [s["id"] for s in body["plan"]["steps"]] == ["s1", "s2", "s3", "s4", "s5"]
    assert len(provider.calls) == 2


def test_token_is_required_when_configured(client):
    c, provider = client()
    for headers in ({}, auth("wrong")):
        r = c.post("/v1/recipes/analyze", json={"type": "text", "content": "x"}, headers=headers)
        assert r.status_code == 401
        assert r.json() == {"error_code": "unauthorized", "detail": ""}
    assert provider.calls == []


def test_real_provider_without_token_is_refused(client):
    c, provider = client(token=None)
    r = c.post("/v1/recipes/analyze", json={"type": "text", "content": "x"})
    assert r.status_code == 503 and r.json()["error_code"] == "not_configured"
    assert provider.calls == []


def test_local_mock_works_without_token(client):
    c, _ = client(token=None, ai_provider="mock")
    r = c.post("/v1/recipes/analyze", json={"type": "text", "content": SAMPLE_SOURCE_TEXT})
    assert r.status_code == 200


def test_per_ip_rate_limit(client):
    c, _ = client(rate_limit_per_hour=2)
    ok = {"type": "text", "content": SAMPLE_SOURCE_TEXT}
    assert c.post("/v1/recipes/analyze", json=ok, headers=auth()).status_code == 200
    assert c.post("/v1/recipes/analyze", json=ok, headers=auth()).status_code == 200
    r = c.post("/v1/recipes/analyze", json=ok, headers=auth())
    assert r.status_code == 429 and r.json()["error_code"] == "rate_limited"
    assert int(r.headers["Retry-After"]) > 0
    # Another client address has its own limit.
    other = c.post("/v1/recipes/analyze", json=ok, headers={**auth(), "X-Forwarded-For": "203.0.113.9"})
    assert other.status_code == 200


def test_size_limits(client):
    c, provider = client(max_text_chars=100, max_body_bytes=5000)
    r = c.post("/v1/recipes/analyze", json={"type": "text", "content": "א" * 101}, headers=auth())
    assert r.status_code == 413 and r.json()["error_code"] == "too_large"
    r = c.post("/v1/recipes/analyze", json={"type": "text", "content": "x" * 6000}, headers=auth())
    assert r.status_code == 413
    assert provider.calls == []


def test_image_checks(client):
    c, provider = client(max_image_bytes=1000)
    png = b"\x89PNG\r\n\x1a\n" + b"\0" * 20
    r = c.post("/v1/recipes/analyze-image", json={"image_base64": base64.b64encode(b"GIF89a....").decode()}, headers=auth())
    assert r.status_code == 415 and r.json()["error_code"] == "unsupported_media"
    r = c.post("/v1/recipes/analyze-image", json={"image_base64": "not base64!!"}, headers=auth())
    assert r.status_code == 422
    big = base64.b64encode(b"\xff\xd8\xff" + b"\0" * 2000).decode()
    r = c.post("/v1/recipes/analyze-image", json={"image_base64": big}, headers=auth())
    assert r.status_code == 413
    assert provider.calls == []
    r = c.post("/v1/recipes/analyze-image", json={"image_base64": base64.b64encode(png).decode()}, headers=auth())
    assert r.status_code == 200
    assert provider.calls[0]["parts"][1].mime_type == "image/png"


def test_invalid_request_shape(client):
    c, _ = client()
    r = c.post("/v1/recipes/analyze", json={"type": "pdf", "content": "x"}, headers=auth())
    assert r.status_code == 422 and r.json()["error_code"] == "invalid_request"


def test_responses_never_contain_secrets(client):
    c, _ = client()
    for r in (
        c.post("/v1/recipes/analyze", json={"type": "text", "content": SAMPLE_SOURCE_TEXT}, headers=auth()),
        c.post("/v1/recipes/analyze", json={"type": "text", "content": "x"}, headers=auth("bad")),
    ):
        assert FAKE_KEY not in r.text and TOKEN not in r.text


def test_mock_data_is_up_to_date():
    for name, data in make_mock_data.build().items():
        assert (make_mock_data.OUT_DIR / name).read_text(encoding="utf-8") == make_mock_data.render(data), (
            "run: python -m scripts.make_mock_data"
        )


# ---- body limit without Content-Length, limiter memory, content-free errors --------------------

import logging

from fastapi import FastAPI

from app.errors import install_error_handlers
from app.security import BodySizeLimit


def test_a_body_without_content_length_over_the_cap_is_rejected(client):
    c, provider = client()

    def chunks():  # an iterator body is sent chunked, with no Content-Length
        for _ in range(64):
            yield b"x" * 100_000

    r = c.post("/v1/recipes/analyze", content=chunks(), headers={**auth(), "Content-Type": "application/json"})
    assert r.status_code == 413 and r.json()["error_code"] == "too_large"
    assert provider.calls == []


def test_body_limit_passes_small_chunked_bodies_through():
    received = []

    async def echo(scope, receive, send):
        body = b""
        while True:
            m = await receive()
            body += m.get("body", b"")
            if not m.get("more_body"):
                break
        received.append(body)
        await send({"type": "http.response.start", "status": 200, "headers": []})
        await send({"type": "http.response.body", "body": b"ok"})

    c = TestClient(BodySizeLimit(echo, max_bytes=lambda: 1000))
    assert c.post("/", content=iter([b"a" * 400, b"b" * 400])).status_code == 200
    assert received == [b"a" * 400 + b"b" * 400]
    assert c.post("/", content=iter([b"a" * 600, b"b" * 600])).status_code == 413
    assert c.post("/", content=b"c" * 1001).status_code == 413  # declared size
    assert len(received) == 1


def test_limiter_forgets_idle_clients():
    now = [0.0]
    limiter = SlidingWindowLimiter(clock=lambda: now[0])
    for i in range(SlidingWindowLimiter.SWEEP_EVERY - 1):
        limiter.check(f"ip{i}:3600", 10, 3600)
    assert len(limiter) == SlidingWindowLimiter.SWEEP_EVERY - 1
    now[0] = 3601
    limiter.check("new:3600", 10, 3600)  # triggers the sweep
    assert len(limiter) == 1


def test_unexpected_errors_return_500_and_log_no_content(caplog):
    demo = FastAPI()
    install_error_handlers(demo)

    @demo.get("/boom")
    def boom():
        raise ValueError("secret recipe text: 3 eggs")

    with caplog.at_level(logging.INFO):
        r = TestClient(demo, raise_server_exceptions=False).get("/boom")
    assert r.status_code == 500 and r.json() == {"error_code": "server_error", "detail": ""}
    assert "secret recipe text" not in caplog.text and "ValueError" in caplog.text


# ---- quota exhaustion and rate limits from the AI provider (FakeProvider, zero real calls) ----

from app.services.llm import LLMRateLimited

TEXT = {"type": "text", "content": "x" * 50}


def test_daily_quota_exhausted_is_reported_and_the_provider_is_not_called_again(client):
    c, provider = client(provider=FakeProvider({
        "LlmAnalysis": [LLMRateLimited(scope="day"), mock_json("sample_analysis.json")],
    }))
    now = [0.0]
    app.dependency_overrides[get_ai_budget] = (lambda b: lambda: b)(DailyBudget(clock=lambda: now[0]))
    r = c.post("/v1/recipes/analyze", json=TEXT, headers=auth())
    assert r.status_code == 429 and r.json()["error_code"] == "ai_quota_exhausted"
    assert "Retry-After" not in r.headers  # the reset time is not known: nothing is promised
    assert len(provider.calls) == 1
    # Further requests get the same answer without reaching the provider (no retry storm).
    for _ in range(3):
        r = c.post("/v1/recipes/analyze", json=TEXT, headers=auth())
        assert r.status_code == 429 and r.json()["error_code"] == "ai_quota_exhausted"
        assert "Retry-After" not in r.headers
    assert len(provider.calls) == 1
    # After the internal pause the provider is tried again (and now succeeds).
    now[0] = DailyBudget.QUOTA_PAUSE_SECONDS + 1
    r = c.post("/v1/recipes/analyze", json={"type": "text", "content": SAMPLE_SOURCE_TEXT}, headers=auth())
    assert r.status_code == 200 and len(provider.calls) == 2


def test_short_rate_limit_states_only_the_known_delay(client):
    c, provider = client(provider=FakeProvider({
        "LlmAnalysis": [LLMRateLimited(scope="minute", retry_after_seconds=20)],
    }))
    now = [0.0]
    app.dependency_overrides[get_ai_budget] = (lambda b: lambda: b)(DailyBudget(clock=lambda: now[0]))
    r = c.post("/v1/recipes/analyze", json=TEXT, headers=auth())
    assert r.status_code == 429 and r.json()["error_code"] == "ai_rate_limited"
    assert r.headers["Retry-After"] == "20"
    now[0] = 5
    r = c.post("/v1/recipes/analyze", json=TEXT, headers=auth())
    assert r.json()["error_code"] == "ai_rate_limited" and r.headers["Retry-After"] == "15"
    assert len(provider.calls) == 1  # paused: no call while the provider asked us to wait


def test_rate_limit_without_a_stated_delay_promises_no_time_and_is_not_retried(client):
    c, provider = client(provider=FakeProvider({"LlmAnalysis": [LLMRateLimited()]}))
    r = c.post("/v1/recipes/analyze", json=TEXT, headers=auth())
    assert r.status_code == 429 and r.json()["error_code"] == "ai_rate_limited"
    assert "Retry-After" not in r.headers
    assert len(provider.calls) == 1


def test_quota_exhausted_during_planning_is_not_retried_or_repaired(client):
    c, provider = client(provider=FakeProvider({
        "LlmAnalysis": [mock_json("sample_analysis.json")],
        "LlmPlan": [LLMRateLimited(scope="day")],
    }))
    analysis = c.post("/v1/recipes/analyze", json={"type": "text", "content": SAMPLE_SOURCE_TEXT}, headers=auth()).json()
    r = c.post("/v1/recipes/plan", json={"analysis": analysis}, headers=auth())
    assert r.status_code == 429 and r.json()["error_code"] == "ai_quota_exhausted"
    assert [call["schema"] for call in provider.calls] == ["LlmAnalysis", "LlmPlan"]
