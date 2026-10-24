"""No-cost abuse protection for the AI endpoints.

Limitations (documented for the user): the app token ships inside the app and
can be extracted, so it only deters casual use; counters live in memory, so they
reset when Render restarts the service, and clients behind one IP share a limit.
"""

import secrets
import time
from collections import defaultdict, deque
from datetime import UTC, datetime
from collections.abc import Callable
from functools import lru_cache

from fastapi import Depends, Request
from fastapi.responses import JSONResponse

from app.config import Settings, get_settings
from app.errors import ApiError


def client_ip(request: Request, trusted_proxy_hops: int) -> str:
    """The client address as seen by the trusted proxy (rightmost hops)."""
    forwarded = [p.strip() for p in request.headers.get("x-forwarded-for", "").split(",") if p.strip()]
    if trusted_proxy_hops > 0 and len(forwarded) >= trusted_proxy_hops:
        return forwarded[-trusted_proxy_hops]
    return request.client.host if request.client else "unknown"


def require_app_token(request: Request, settings: Settings = Depends(get_settings)) -> None:
    expected = settings.app_client_token.get_secret_value() if settings.app_client_token else ""
    if not expected:
        # Without a token, only the offline mock may be used (local development).
        if settings.ai_provider != "mock":
            raise ApiError(503, "not_configured", "APP_CLIENT_TOKEN is not set")
        return
    given = request.headers.get("x-app-token", "")
    if not secrets.compare_digest(given, expected):
        raise ApiError(401, "unauthorized")


class SlidingWindowLimiter:
    SWEEP_EVERY = 500

    def __init__(self, clock=time.monotonic) -> None:
        self._clock = clock
        self._hits: dict[str, deque[float]] = defaultdict(deque)
        self._windows: dict[str, float] = {}
        self._checks = 0

    def __len__(self) -> int:
        return len(self._hits)

    def _sweep(self, now: float) -> None:
        """Forgets clients with no hit inside their window, so memory stays bounded."""
        for key in [k for k, hits in self._hits.items() if not hits or hits[-1] <= now - self._windows[k]]:
            del self._hits[key]
            del self._windows[key]

    def check(self, key: str, limit: int, window_seconds: float) -> float | None:
        """Records a hit; returns seconds to wait if over the limit (hit not recorded)."""
        now = self._clock()
        self._checks += 1
        if self._checks % self.SWEEP_EVERY == 0:
            self._sweep(now)
        self._windows[key] = window_seconds
        hits = self._hits[key]
        while hits and hits[0] <= now - window_seconds:
            hits.popleft()
        if len(hits) >= limit:
            return hits[0] + window_seconds - now
        hits.append(now)
        return None


class DailyBudget:
    """App-wide cap on real AI calls per UTC day, protecting the free quota."""

    def __init__(self, today=lambda: datetime.now(UTC).date()) -> None:
        self._today = today
        self._day = today()
        self.used = 0

    def consume(self, cap: int) -> None:
        if self._today() != self._day:
            self._day, self.used = self._today(), 0
        if self.used >= cap:
            raise ApiError(429, "daily_limit", headers={"Retry-After": "3600"})
        self.used += 1


@lru_cache
def get_limiter() -> SlidingWindowLimiter:
    return SlidingWindowLimiter()


@lru_cache
def get_ai_budget() -> DailyBudget:
    return DailyBudget()


def rate_limit_ai(
    request: Request,
    settings: Settings = Depends(get_settings),
    limiter: SlidingWindowLimiter = Depends(get_limiter),
) -> None:
    ip = client_ip(request, settings.trusted_proxy_hops)
    for window, limit in ((3600, settings.rate_limit_per_hour), (86400, settings.rate_limit_per_day)):
        wait = limiter.check(f"{ip}:{window}", limit, window)
        if wait is not None:
            raise ApiError(429, "rate_limited", headers={"Retry-After": str(int(wait) + 1)})


class BodySizeLimit:
    """ASGI middleware: rejects request bodies over the cap with 413, whether the size is
    declared (Content-Length) or not (chunked). At most the cap is ever held in memory."""

    def __init__(self, app, max_bytes: Callable[[], int] = lambda: get_settings().max_body_bytes) -> None:
        self.app = app
        self.max_bytes = max_bytes

    async def __call__(self, scope, receive, send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        limit = self.max_bytes()
        length = dict(scope.get("headers") or []).get(b"content-length", b"")
        if length.isdigit() and int(length) > limit:
            await self._too_large(send)
            return
        messages, size = [], 0
        while True:
            message = await receive()
            if message["type"] != "http.request":  # client went away
                messages.append(message)
                break
            size += len(message.get("body", b""))
            if size > limit:
                await self._too_large(send)
                return
            messages.append(message)
            if not message.get("more_body", False):
                break

        async def replay():
            return messages.pop(0) if messages else await receive()

        await self.app(scope, replay, send)

    @staticmethod
    async def _too_large(send) -> None:
        await JSONResponse({"error_code": "too_large", "detail": ""}, status_code=413)({"type": "http"}, None, send)
