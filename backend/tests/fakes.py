"""A scripted fake LLM provider: zero real API calls in automated tests."""

import json
from pathlib import Path
from typing import Any

from pydantic import BaseModel

from app.services.llm import LLMInvalidOutput

MOCK_DATA = Path(__file__).resolve().parents[1] / "app" / "services" / "llm" / "mock_data"


def mock_json(name: str) -> dict[str, Any]:
    return json.loads((MOCK_DATA / name).read_text(encoding="utf-8"))


SAMPLE_SOURCE_TEXT = mock_json("sample_source.json")["text"]


class FakeProvider:
    """Returns queued outputs per schema; an Exception in the queue is raised.

    `calls` records every call so tests can assert exactly how many were made."""

    name = "fake"

    def __init__(self, outputs: dict[str, list[Any]] | None = None) -> None:
        self.outputs = {k: list(v) for k, v in (outputs or {}).items()}
        self.calls: list[dict[str, Any]] = []

    async def generate_structured(self, system, parts, schema: type[BaseModel], model=None):
        self.calls.append({"schema": schema.__name__, "parts": parts, "model": model})
        queue = self.outputs.get(schema.__name__, [])
        if not queue:
            raise AssertionError(f"no fake output queued for {schema.__name__}")
        item = queue.pop(0) if len(queue) > 1 else queue[0]
        if isinstance(item, Exception):
            raise item
        try:
            return schema.model_validate(item)
        except Exception as e:  # mimic a provider returning malformed JSON
            raise LLMInvalidOutput(json.dumps(item, ensure_ascii=False), str(e)) from e

    async def stream_chat(self, *args, **kwargs):  # pragma: no cover - unused
        yield ""
