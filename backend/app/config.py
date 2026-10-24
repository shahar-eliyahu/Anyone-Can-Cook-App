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
    # e.g. "minimal"; unset sends no thinking configuration (model default).
    ai_thinking_level: str | None = None
    ai_timeout_seconds: float = 60

    # Abuse deterrent, not authentication: the value ships inside the app.
    # Required for AI endpoints whenever a real provider is configured.
    app_client_token: SecretStr | None = None
    # Render's proxy appends the client address to X-Forwarded-For.
    trusted_proxy_hops: int = 1

    # In-memory limits (reset on restart; shared IP addresses share them).
    rate_limit_per_hour: int = 10
    rate_limit_per_day: int = 30
    ai_daily_call_cap: int = 300
    # Remy (assistant questions) has its own per-device limit; calls still count toward the daily cap.
    assistant_rate_limit_per_hour: int = 30
    assistant_rate_limit_per_day: int = 100

    max_body_bytes: int = 3_000_000
    max_text_chars: int = 20_000
    max_image_bytes: int = 2_000_000
    url_fetch_timeout_seconds: float = 10
    url_max_bytes: int = 2_000_000

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
