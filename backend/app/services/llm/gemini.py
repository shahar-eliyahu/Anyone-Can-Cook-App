"""Gemini provider (Google AI Studio). Not exercised until GEMINI_API_KEY is configured.

The `google-genai` SDK is imported lazily so the mock setup needs no extra dependency.
"""

from collections.abc import AsyncIterator

from pydantic import SecretStr

from app.services.llm.base import ImagePart, LLMError, Msg, T, TextPart


class GeminiProvider:
    name = "gemini"

    def __init__(self, api_key: SecretStr, default_model: str) -> None:
        try:
            from google import genai
        except ImportError as e:
            raise LLMError("AI_PROVIDER=gemini requires `pip install google-genai`") from e
        self._genai = genai
        self._client = genai.Client(api_key=api_key.get_secret_value())
        self._default_model = default_model

    def _contents(self, parts: list[TextPart | ImagePart]) -> list:
        types = self._genai.types
        out = []
        for p in parts:
            if isinstance(p, TextPart):
                out.append(types.Part.from_text(text=p.text))
            else:
                out.append(types.Part.from_bytes(data=p.data, mime_type=p.mime_type))
        return out

    async def generate_structured(
        self,
        system: str,
        parts: list[TextPart | ImagePart],
        schema: type[T],
        model: str | None = None,
    ) -> T:
        types = self._genai.types
        response = await self._client.aio.models.generate_content(
            model=model or self._default_model,
            contents=self._contents(parts),
            config=types.GenerateContentConfig(
                system_instruction=system,
                response_mime_type="application/json",
                response_schema=schema,
            ),
        )
        if not response.text:
            raise LLMError("Gemini returned an empty response")
        # Always validate ourselves; provider-side schema enforcement is not trusted.
        return schema.model_validate_json(response.text)

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
