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


def sample_fixtures() -> dict[type[BaseModel], Any]:
    """Canned analysis and plan (the sample chicken recipe) for local development."""
    from app.schemas.llm import LlmAnalysis, LlmAssistantTurn, LlmPlan, LlmRecipeCreation, LlmSubstitution

    def load(name: str) -> dict[str, Any]:
        return json.loads((_MOCK_DATA / name).read_text(encoding="utf-8"))

    return {
        LlmAnalysis: load("sample_analysis.json"),
        LlmPlan: load("sample_plan.json"),
        LlmSubstitution: load("sample_substitution.json"),
        LlmAssistantTurn: load("sample_assistant.json"),
        LlmRecipeCreation: _mock_creation(load("sample_analysis.json")),
    }


def _mock_creation(analysis: dict[str, Any]):
    """Local development only: a short request gets three options, anything else the sample
    recipe (the only one the canned plan fits)."""
    recipe = {
        "intent": "recipe",
        "answer_he": "הנה הצעה למתכון (דמו מהשרת המקומי). אפשר לעבור עליו לפני ששומרים.",
        "title": analysis["title"],
        "description": analysis["description"],
        "servings_amount": analysis["servings_amount"],
        "servings_unit": analysis["servings_unit"],
        "total_minutes": 80,
        "ingredients": [
            {"id": i["id"], "name": i["name"], **{k: v for k, v in (i.get("quantity") or {}).items() if k != "stated_in_source"}}
            for i in analysis["ingredients"]
        ],
        "equipment": [{"id": e["id"], "name": e["name"]} for e in analysis["equipment"]],
        "steps": [{"id": s["id"], "text": s["text"]} for s in analysis["source_steps"]],
        "tips_he": ["אפשר להכין את האורז בזמן שהעוף בתנור."],
    }
    options = {
        "intent": "options",
        "answer_he": "יש לי כמה רעיונות (דמו מהשרת המקומי). מה מתאים לכם?",
        "options_he": [analysis["title"], "פסטה ברוטב עגבניות", "שקשוקה"],
    }

    def respond(parts: list) -> dict[str, Any]:
        text = "".join(getattr(p, "text", "") for p in parts)
        message = text.rsplit("<cook_message>", 1)[-1].split("</cook_message>", 1)[0].strip()
        return options if len(message.split()) <= 2 and analysis["title"] not in message else recipe

    return respond


class MockProvider:
    name = "mock"

    def __init__(self, fixtures: dict[type[BaseModel], Any] | None = None) -> None:
        # Canned responses keyed by schema class; features register theirs as they're built.
        self._fixtures: dict[type[BaseModel], Any] = dict(fixtures or {})

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
        fixture = self._fixtures[schema]
        return schema.model_validate(fixture(parts) if callable(fixture) else fixture)

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
