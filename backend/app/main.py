from fastapi import FastAPI

from app import __version__
from app.routers import ai_check, health

app = FastAPI(title="Anyone Can Cook API", version=__version__)
app.include_router(health.router)
app.include_router(ai_check.router)  # TEMPORARY (Phase 0)
