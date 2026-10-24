"""Offline provider that returns canned data. Used until a real API key is configured."""

import asyncio
import json
from collections.abc import AsyncIterator
from pathlib import Path
from typing import Any

from pydantic import BaseModel

from app.services.llm.base import ImagePart, LLMError, Msg, T, TextPart

MOCK_CHAT_ANSWER = "זוהי תשובת דמו מהשרת המקומי. חיבור ל-AI אמיתי יתווסף בהמשך."

_MOCK_DATA = Path(__file__).parent / "mock_data"


def sample_fixtures() -> dict[type[BaseModel], dict[str, Any]]:
    """Canned analysis and plan (the sample chicken recipe) for local development."""
    from app.schemas.llm import LlmAnalysis, LlmAssistantTurn, LlmPlan, LlmSubstitution

    def load(name: str) -> dict[str, Any]:
        return json.loads((_MOCK_DATA / name).read_text(encoding="utf-8"))

    return {
        LlmAnalysis: load("sample_analysis.json"),
        LlmPlan: load("sample_plan.json"),
        LlmSubstitution: load("sample_substitution.json"),
        LlmAssistantTurn: load("sample_assistant.json"),
    }


class MockProvider:
    name = "mock"

    def __init__(self, fixtures: dict[type[BaseModel], dict[str, Any]] | None = None) -> None:
        # Canned responses keyed by schema class; features register theirs as they're built.
        self._fixtures: dict[type[BaseModel], dict[str, Any]] = dict(fixtures or {})

    def register(self, schema: type[BaseModel], data: dict[str, Any]) -> None:
        self._fixtures[schema] = data

    async def generate_structured(
        self,
        system: str,
        parts: list[TextPart | ImagePart],
        schema: type[T],
        model: str | None = None,
    ) -> T:
        if schema not in self._fixtures:
            raise LLMError(f"MockProvider has no fixture for {schema.__name__}")
        return schema.model_validate(self._fixtures[schema])

    async def stream_chat(
        self,
        system: str,
        context: str,
        history: list[Msg],
        model: str | None = None,
    ) -> AsyncIterator[str]:
        for word in MOCK_CHAT_ANSWER.split(" "):
            await asyncio.sleep(0)
            yield word + " "
