"""Tests for the temporary AI check. A fake provider is used, so no real API calls are made."""

import pytest
from fastapi.testclient import TestClient
from pydantic import SecretStr

from app.config import Settings, get_settings
from app.main import app
from app.routers.ai_check import AiCheckReply, Cooldown, get_cooldown
from app.services.llm import LLMError, get_llm_provider

TOKEN = "test-check-token"
FAKE_API_KEY = "fake-gemini-key-123"


class FakeProvider:
    name = "fake"

    def __init__(self, reply: str = "אדום", error: Exception | None = None) -> None:
        self.reply = reply
        self.error = error
        self.calls: list[dict] = []

    async def generate_structured(self, system, parts, schema, model=None):
        self.calls.append({"system": system, "parts": parts, "schema": schema, "model": model})
        if self.error:
            raise self.error
        return AiCheckReply(reply=self.reply)


@pytest.fixture
def setup():
    def _setup(provider=None, token: str | None = TOKEN, cooldown_seconds: int = 60):
        provider = provider or FakeProvider()
        settings = Settings(
            _env_file=None,
            ai_provider="gemini",
            gemini_api_key=SecretStr(FAKE_API_KEY),
            ai_model="test-model",
            ai_check_token=SecretStr(token) if token else None,
            ai_check_cooldown_seconds=cooldown_seconds,
        )
        cooldown = Cooldown()
        app.dependency_overrides[get_settings] = lambda: settings
        app.dependency_overrides[get_llm_provider] = lambda: provider
        app.dependency_overrides[get_cooldown] = lambda: cooldown
        return TestClient(app), provider

    yield _setup
    app.dependency_overrides.clear()


def check(client, token: str | None = TOKEN):
    headers = {"X-AI-Check-Token": token} if token else {}
    return client.post("/internal/ai-check", headers=headers)


def test_disabled_when_token_not_configured(setup):
    client, provider = setup(token=None)
    assert check(client, token="anything").status_code == 404
    assert provider.calls == []


def test_rejects_missing_or_wrong_token(setup):
    client, provider = setup()
    assert check(client, token=None).status_code == 401
    assert check(client, token="wrong").status_code == 401
    assert provider.calls == []


def test_success_returns_hebrew_reply_and_uses_fixed_prompt(setup):
    client, provider = setup()
    response = check(client)

    assert response.status_code == 200
    body = response.json()
    assert body["ok"] is True
    assert body["provider"] == "fake"
    assert body["model"] == "test-model"
    assert body["reply"] == "אדום"
    assert body["reply_is_hebrew"] is True
    assert len(provider.calls) == 1
    assert provider.calls[0]["model"] == "test-model"
    assert provider.calls[0]["schema"] is AiCheckReply


def test_cooldown_blocks_second_real_call(setup):
    client, provider = setup()
    assert check(client).status_code == 200
    second = check(client)
    assert second.status_code == 429
    assert int(second.headers["Retry-After"]) > 0
    assert len(provider.calls) == 1


def test_provider_error_is_reported_without_leaking_key(setup):
    error = LLMError(f"request failed for key={FAKE_API_KEY}")
    client, _ = setup(provider=FakeProvider(error=error))
    response = check(client)

    assert response.status_code == 502
    body = response.json()
    assert body["ok"] is False
    assert body["error_type"] == "LLMError"
    assert FAKE_API_KEY not in response.text
    assert TOKEN not in response.text


def test_success_response_never_contains_secrets(setup):
    client, _ = setup()
    response = check(client)
    assert FAKE_API_KEY not in response.text
    assert TOKEN not in response.text


def test_endpoint_hidden_from_openapi(setup):
    client, _ = setup()
    assert "/internal/ai-check" not in client.get("/openapi.json").json()["paths"]
