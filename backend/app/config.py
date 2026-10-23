from functools import lru_cache
from typing import Literal

from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """App settings, read from environment variables and an optional `.env` file."""

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    ai_provider: Literal["mock", "gemini"] = "mock"
    gemini_api_key: SecretStr | None = None
    ai_model: str | None = None
    parse_model: str | None = None
    plan_model: str | None = None
    chat_model: str | None = None

    @property
    def effective_parse_model(self) -> str | None:
        return self.parse_model or self.ai_model

    @property
    def effective_plan_model(self) -> str | None:
        return self.plan_model or self.ai_model

    @property
    def effective_chat_model(self) -> str | None:
        return self.chat_model or self.ai_model


@lru_cache
def get_settings() -> Settings:
    return Settings()
