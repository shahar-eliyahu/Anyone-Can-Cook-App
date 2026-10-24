"""The single path for structured AI calls: daily cap, timeout, one retry, error mapping."""

import asyncio
import logging

from app.config import Settings
from app.errors import ApiError
from app.security import DailyBudget
from app.services.llm import (
    ImagePart,
    LLMError,
    LLMInvalidOutput,
    LLMProvider,
    LLMRateLimited,
    LLMUnavailable,
    TextPart,
)
from app.services.llm.base import T

logger = logging.getLogger(__name__)


async def call_structured(
    provider: LLMProvider,
    *,
    system: str,
    parts: list[TextPart | ImagePart],
    schema: type[T],
    model: str | None,
    settings: Settings,
    budget: DailyBudget,
    purpose: str,
    max_attempts: int = 2,
) -> T:
    """Every attempt counts against the daily cap. Rate limits are never retried, and
    after one the provider isn't called again for a while; temporary failures are
    retried once unless `max_attempts=1` (Remy: one call per request). `LLMInvalidOutput`
    is left to the caller (it decides whether to make a repair call)."""
    for attempt in range(1, max_attempts + 1):
        budget.check_paused()
        budget.consume(settings.ai_daily_call_cap)
        logger.info("ai call purpose=%s attempt=%d calls_today=%d", purpose, attempt, budget.used)
        try:
            return await asyncio.wait_for(
                provider.generate_structured(system, parts, schema, model=model),
                timeout=settings.ai_timeout_seconds,
            )
        except TimeoutError as e:
            raise ApiError(504, "timeout") from e
        except LLMRateLimited as e:
            logger.warning("ai %s limit purpose=%s", e.scope, purpose)
            if e.scope == "day":
                budget.pause("ai_quota_exhausted", budget.QUOTA_PAUSE_SECONDS, known=False)
                raise ApiError(429, "ai_quota_exhausted") from e
            known = e.retry_after_seconds is not None
            budget.pause("ai_rate_limited", e.retry_after_seconds or budget.RATE_PAUSE_SECONDS, known=known)
            headers = {"Retry-After": str(e.retry_after_seconds)} if known else None
            raise ApiError(429, "ai_rate_limited", headers=headers) from e
        except LLMUnavailable as e:
            if attempt == max_attempts:
                raise ApiError(503, "ai_unavailable") from e
        except LLMInvalidOutput:
            raise
        except LLMError as e:
            raise ApiError(502, "ai_error", type(e).__name__) from e
    raise AssertionError("unreachable")
