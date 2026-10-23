from fastapi import FastAPI

from app import __version__
from app.routers import health

app = FastAPI(title="Anyone Can Cook API", version=__version__)
app.include_router(health.router)
