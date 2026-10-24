"""Gemini provider (Google AI Studio). Only used when AI_PROVIDER=gemini.

The `google-genai` SDK is imported lazily so the mock setup needs no extra dependency.
"""

import math
import re
from collections.abc import AsyncIterator

from pydantic import SecretStr, ValidationError

from app.services.llm.base import (
    ImagePart,
    LLMError,
    LLMInvalidOutput,
    LLMRateLimited,
    LLMUnavailable,
    Msg,
    T,
    TextPart,
)


class GeminiProvider:
    name = "gemini"

    def __init__(
        self,
        api_key: SecretStr,
        default_model: str,
        thinking_level: str | None = None,
    ) -> None:
        try:
            from google import genai
            from google.genai import errors
        except ImportError as e:
            raise LLMError("AI_PROVIDER=gemini requires `pip install google-genai`") from e
        self._genai = genai
        self._errors = errors
        self._client = genai.Client(api_key=api_key.get_secret_value())
        self._default_model = default_model
        self._thinking_level = thinking_level

    def _contents(self, parts: list[TextPart | ImagePart]) -> list:
        types = self._genai.types
        out = []
        for p in parts:
            if isinstance(p, TextPart):
                out.append(types.Part.from_text(text=p.text))
            else:
                out.append(types.Part.from_bytes(data=p.data, mime_type=p.mime_type))
        return out

    def _thinking(self):
        if not self._thinking_level:
            return None
        types = self._genai.types
        return types.ThinkingConfig(thinking_level=types.ThinkingLevel(self._thinking_level.upper()))

    def _translate(self, e: Exception) -> LLMError:
        if isinstance(e, self._errors.ClientError):
            if e.code == 429:
                return rate_limit_error(e.details)
            return LLMError(f"client error {e.code}")
        if isinstance(e, self._errors.ServerError):
            return LLMUnavailable(f"server error {e.code}")
        return LLMUnavailable(type(e).__name__)

    async def generate_structured(
        self,
        system: str,
        parts: list[TextPart | ImagePart],
        schema: type[T],
        model: str | None = None,
    ) -> T:
        types = self._genai.types
        try:
            response = await self._client.aio.models.generate_content(
                model=model or self._default_model,
                contents=self._contents(parts),
                config=types.GenerateContentConfig(
                    system_instruction=system,
                    response_mime_type="application/json",
                    response_schema=schema,
                    thinking_config=self._thinking(),
                ),
            )
        except Exception as e:  # SDK API errors and httpx network errors
            raise self._translate(e) from e
        text = response.text or ""
        if not text:
            raise LLMInvalidOutput("", "empty response")
        # Always validate ourselves; provider-side schema enforcement is not trusted.
        try:
            return schema.model_validate_json(text)
        except ValidationError as e:
            raise LLMInvalidOutput(text, _summarize(e)) from e

    async def stream_chat(
        self,
        system: str,
        context: str,
        history: list[Msg],
        model: str | None = None,
    ) -> AsyncIterator[str]:
        types = self._genai.types
        contents = [types.Content(role="user", parts=[types.Part.from_text(text=context)])]
        for m in history:
            role = "model" if m.role == "assistant" else "user"
            contents.append(types.Content(role=role, parts=[types.Part.from_text(text=m.text)]))
        stream = await self._client.aio.models.generate_content_stream(
            model=model or self._default_model,
            contents=contents,
            config=types.GenerateContentConfig(system_instruction=system),
        )
        async for chunk in stream:
            if chunk.text:
                yield chunk.text


def rate_limit_error(details) -> LLMRateLimited:
    """Reads a Gemini 429 body (RESOURCE_EXHAUSTED) without trusting its shape.

    The quota id says which window ran out (e.g. "...PerDay..." or "...PerMinute...");
    RetryInfo.retryDelay ("37s") is used only for short windows: for a daily quota it
    doesn't say when the quota resets.
    """
    error = details.get("error", details) if isinstance(details, dict) else {}
    items = error.get("details") if isinstance(error, dict) else None
    quota_ids, delay = [], None
    for item in items if isinstance(items, list) else []:
        if not isinstance(item, dict):
            continue
        kind = str(item.get("@type", ""))
        if kind.endswith("google.rpc.QuotaFailure"):
            for v in item.get("violations") or []:
                if isinstance(v, dict):
                    quota_ids.append(str(v.get("quotaId", "")) + " " + str(v.get("quotaMetric", "")))
        elif kind.endswith("google.rpc.RetryInfo"):
            m = re.fullmatch(r"(\d+(?:\.\d+)?)s", str(item.get("retryDelay", "")))
            if m:
                delay = math.ceil(float(m.group(1)))
    text = " ".join(quota_ids).lower()
    if "perday" in text or "per_day" in text:
        return LLMRateLimited("daily quota exhausted", scope="day")
    if "perminute" in text or "per_minute" in text:
        return LLMRateLimited("per-minute limit", scope="minute", retry_after_seconds=delay)
    return LLMRateLimited("rate limited", scope="unknown", retry_after_seconds=delay)


def _summarize(e: ValidationError, limit: int = 20) -> str:
    lines = [f"{'.'.join(str(p) for p in err['loc'])}: {err['msg']}" for err in e.errors()[:limit]]
    return "\n".join(lines)
