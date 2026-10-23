"""Provider-neutral interface for every AI call the backend makes.

Routers depend only on `LLMProvider`; concrete providers (mock, Gemini, later others)
live in sibling modules and are chosen by `factory.get_llm_provider()`.
"""

from collections.abc import AsyncIterator
from dataclasses import dataclass
from typing import Literal, Protocol, TypeVar

from pydantic import BaseModel

T = TypeVar("T", bound=BaseModel)


@dataclass(frozen=True)
class TextPart:
    text: str


@dataclass(frozen=True)
class ImagePart:
    data: bytes
    mime_type: str = "image/jpeg"


@dataclass(frozen=True)
class Msg:
    role: Literal["user", "assistant"]
    text: str


class LLMError(Exception):
    """Raised when a provider can't produce a usable response."""


class LLMProvider(Protocol):
    name: str

    async def generate_structured(
        self,
        system: str,
        parts: list[TextPart | ImagePart],
        schema: type[T],
        model: str | None = None,
    ) -> T:
        """Return a response validated against `schema`."""
        ...

    def stream_chat(
        self,
        system: str,
        context: str,
        history: list[Msg],
        model: str | None = None,
    ) -> AsyncIterator[str]:
        """Yield the answer as text chunks."""
        ...
