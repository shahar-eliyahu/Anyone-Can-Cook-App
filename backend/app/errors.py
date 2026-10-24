"""One error shape for the API: {"error_code": ..., "detail": ...}.

The app maps `error_code` to Hebrew text from its own strings; `detail` is for
developers and never contains recipe content or secrets.
"""

import logging

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse


logger = logging.getLogger(__name__)


class ApiError(Exception):
    def __init__(
        self,
        status: int,
        code: str,
        detail: str = "",
        headers: dict[str, str] | None = None,
    ) -> None:
        super().__init__(code)
        self.status = status
        self.code = code
        self.detail = detail
        self.headers = headers


def install_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(ApiError)
    async def _api_error(_: Request, exc: ApiError) -> JSONResponse:
        return JSONResponse(
            {"error_code": exc.code, "detail": exc.detail},
            status_code=exc.status,
            headers=exc.headers,
        )

    @app.exception_handler(RequestValidationError)
    async def _invalid_request(_: Request, exc: RequestValidationError) -> JSONResponse:
        fields = sorted({".".join(str(p) for p in e.get("loc", ())) for e in exc.errors()})
        return JSONResponse(
            {"error_code": "invalid_request", "detail": ", ".join(fields)},
            status_code=422,
        )

    # Added last so it wraps the other middleware.
    app.add_middleware(HideUnhandledErrors)


class HideUnhandledErrors:
    """ASGI middleware: an unexpected exception becomes a plain 500 and is logged by type only.

    Starlette's own handler re-raises so the server logs the full traceback, and exception
    messages (validation errors, for example) can quote recipe content.
    """

    def __init__(self, app) -> None:
        self.app = app

    async def __call__(self, scope, receive, send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        started = False

        async def tracking_send(message) -> None:
            nonlocal started
            started = started or message["type"] == "http.response.start"
            await send(message)

        try:
            await self.app(scope, receive, tracking_send)
        except Exception as exc:
            logger.error("unhandled %s on %s", type(exc).__name__, scope.get("path"))
            if not started:
                await JSONResponse({"error_code": "server_error", "detail": ""}, status_code=500)(scope, receive, send)
