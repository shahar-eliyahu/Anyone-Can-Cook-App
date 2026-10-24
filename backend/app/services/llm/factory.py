from functools import lru_cache

from app.config import Settings, get_settings
from app.services.llm.base import LLMError, LLMProvider
from app.services.llm.mock import MockProvider, sample_fixtures


def build_llm_provider(settings: Settings) -> LLMProvider:
    if settings.ai_provider == "mock":
        return MockProvider(sample_fixtures())
    if settings.ai_provider == "gemini":
        if settings.gemini_api_key is None or not settings.gemini_api_key.get_secret_value():
            raise LLMError("AI_PROVIDER=gemini but GEMINI_API_KEY is not set")
        if not settings.ai_model:
            raise LLMError("AI_PROVIDER=gemini but AI_MODEL is not set")
        from app.services.llm.gemini import GeminiProvider

        return GeminiProvider(
            settings.gemini_api_key,
            settings.ai_model,
            thinking_level=settings.ai_thinking_level,
        )
    raise LLMError(f"Unknown AI_PROVIDER: {settings.ai_provider}")


@lru_cache
def get_llm_provider() -> LLMProvider:
    """FastAPI dependency; override in tests with `app.dependency_overrides`."""
    return build_llm_provider(get_settings())
