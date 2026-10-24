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
