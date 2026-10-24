import logging

from fastapi import FastAPI

from app import __version__
from app.errors import install_error_handlers
from app.routers import assistant, health, recipes
from app.security import BodySizeLimit

# Logs carry ids, purposes, counts and error codes only — never recipe content.
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(name)s: %(message)s")

app = FastAPI(title="Anyone Can Cook API", version=__version__)
app.add_middleware(BodySizeLimit)
install_error_handlers(app)  # after BodySizeLimit: its error middleware must be outermost
app.include_router(health.router)
app.include_router(recipes.router)
app.include_router(assistant.router)
