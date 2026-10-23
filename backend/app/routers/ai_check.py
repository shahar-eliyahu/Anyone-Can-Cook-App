"""TEMPORARY (Phase 0): token-protected check that one real AI request works end to end.

Disabled (404) unless AI_CHECK_TOKEN is set. The prompt is fixed, so callers can't
spend quota on their own prompts, and real calls are limited to one per cooldown window.
Remove this file, its test, the settings fields and the include in main.py when done.
"""

import asyncio
import logging
import secrets
import time
from functools import lru_cache

from fastapi import APIRouter, Depends, Header, HTTPException, Response
from pydantic import BaseModel

from app.config import Settings, get_settings
from app.services.llm import LLMProvider, TextPart, get_llm_provider

logger = logging.getLogger(__name__)
router = APIRouter()

SYSTEM_PROMPT = "אתה עוזר לבדיקת חיבור. ענה בעברית, במילה אחת בלבד."
USER_PROMPT = "מה הצבע של עגבנייה בשלה?"
TIMEOUT_SECONDS = 30
MAX_REPLY_CHARS = 100


class AiCheckReply(BaseModel):
    reply: str


class AiCheckResponse(BaseModel):
    ok: bool
    provider: str
    model: str | None
    latency_ms: int | None = None
    reply: str | None = None
    reply_is_hebrew: bool | None = None
    error_type: str | None = None
    error: str | None = None


class Cooldown:
    def __init__(self) -> None:
        self._last: float | None = None
        self._lock = asyncio.Lock()

    def retry_after(self, seconds: int) -> int:
        if self._last is None:
            return 0
        return max(0, int(self._last + seconds - time.monotonic()) + 1)

    def mark(self) -> None:
        self._last = time.monotonic()


@lru_cache
def get_cooldown() -> Cooldown:
    return Cooldown()


def _redact(text: str, settings: Settings) -> str:
    key = settings.gemini_api_key.get_secret_value() if settings.gemini_api_key else ""
    if key:
        text = text.replace(key, "***")
    return text[:300]


def _is_hebrew(text: str) -> bool:
    return any("֐" <= ch <= "׿" for ch in text)


@router.post("/internal/ai-check", response_model=AiCheckResponse, include_in_schema=False)
async def ai_check(
    response: Response,
    x_ai_check_token: str | None = Header(default=None),
    settings: Settings = Depends(get_settings),
    provider: LLMProvider = Depends(get_llm_provider),
    cooldown: Cooldown = Depends(get_cooldown),
) -> AiCheckResponse:
    expected = settings.ai_check_token.get_secret_value() if settings.ai_check_token else ""
    if not expected:
        raise HTTPException(status_code=404)
    if not x_ai_check_token or not secrets.compare_digest(x_ai_check_token, expected):
        raise HTTPException(status_code=401, detail="Invalid token")

    async with cooldown._lock:
        wait = cooldown.retry_after(settings.ai_check_cooldown_seconds)
        if wait:
            raise HTTPException(
                status_code=429, detail="Cooldown active", headers={"Retry-After": str(wait)}
            )
        cooldown.mark()

    model = settings.effective_chat_model
    start = time.perf_counter()
    try:
        result = await asyncio.wait_for(
            provider.generate_structured(
                SYSTEM_PROMPT, [TextPart(USER_PROMPT)], AiCheckReply, model=model
            ),
            timeout=TIMEOUT_SECONDS,
        )
    except Exception as e:  # report any provider failure without leaking secrets
        message = _redact(str(e), settings)
        logger.warning("AI check failed: %s: %s", type(e).__name__, message)
        response.status_code = 502
        return AiCheckResponse(
            ok=False,
            provider=provider.name,
            model=model,
            error_type=type(e).__name__,
            error=message,
        )

    latency_ms = int((time.perf_counter() - start) * 1000)
    reply = result.reply.strip()[:MAX_REPLY_CHARS]
    logger.info("AI check ok: provider=%s model=%s latency_ms=%d", provider.name, model, latency_ms)
    return AiCheckResponse(
        ok=True,
        provider=provider.name,
        model=model,
        latency_ms=latency_ms,
        reply=reply,
        reply_is_hebrew=_is_hebrew(reply),
    )
