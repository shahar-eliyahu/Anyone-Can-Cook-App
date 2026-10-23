from fastapi import APIRouter, Depends
from pydantic import BaseModel

from app import __version__
from app.services.llm import LLMProvider, get_llm_provider

router = APIRouter()


class HealthResponse(BaseModel):
    status: str
    version: str
    ai_provider: str


@router.get("/health", response_model=HealthResponse)
def health(provider: LLMProvider = Depends(get_llm_provider)) -> HealthResponse:
    return HealthResponse(status="ok", version=__version__, ai_provider=provider.name)
