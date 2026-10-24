import base64
import binascii

from fastapi import APIRouter, Depends
from pydantic import Field

from app.config import Settings, get_settings
from app.errors import ApiError
from app.schemas.analysis import RecipeAnalysis
from app.schemas.api import AnalyzeRequest, PlanRequest, PlanResponse
from app.schemas.common import ContractModel
from app.schemas.substitution import SubstituteRequest, SubstituteResponse
from app.security import DailyBudget, get_ai_budget, rate_limit_ai, require_app_token
from app.services.analysis import SourceInput, analyze_source
from app.services.llm import LLMProvider, get_llm_provider
from app.services.planning import plan_recipe
from app.services.substitution import suggest_substitution
from app.services.url_fetcher import fetch_recipe_page

router = APIRouter(
    prefix="/v1/recipes",
    dependencies=[Depends(require_app_token), Depends(rate_limit_ai)],
)


class AnalyzeImageRequest(ContractModel):
    # Base64 in JSON keeps the server free of a multipart dependency.
    image_base64: str = Field(min_length=1)


_IMAGE_SIGNATURES = (
    (b"\xff\xd8\xff", "image/jpeg"),
    (b"\x89PNG\r\n\x1a\n", "image/png"),
)


def _image_type(data: bytes) -> str | None:
    for signature, mime in _IMAGE_SIGNATURES:
        if data.startswith(signature):
            return mime
    if data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return "image/webp"
    return None


@router.post("/analyze", response_model=RecipeAnalysis)
async def analyze(
    req: AnalyzeRequest,
    settings: Settings = Depends(get_settings),
    provider: LLMProvider = Depends(get_llm_provider),
    budget: DailyBudget = Depends(get_ai_budget),
) -> RecipeAnalysis:
    if req.type == "text":
        if len(req.content) > settings.max_text_chars:
            raise ApiError(413, "too_large", "text too long")
        source = SourceInput(type="text", text=req.content.strip())
    else:
        page = await fetch_recipe_page(req.content, settings=settings)
        source = SourceInput(
            type="url", text=page.text, url=page.final_url, site_name=page.site_name, title=page.title
        )
    return await analyze_source(source, provider=provider, settings=settings, budget=budget)


@router.post("/analyze-image", response_model=RecipeAnalysis)
async def analyze_image(
    req: AnalyzeImageRequest,
    settings: Settings = Depends(get_settings),
    provider: LLMProvider = Depends(get_llm_provider),
    budget: DailyBudget = Depends(get_ai_budget),
) -> RecipeAnalysis:
    try:
        data = base64.b64decode(req.image_base64, validate=True)
    except (binascii.Error, ValueError) as e:
        raise ApiError(422, "invalid_request", "image is not base64") from e
    if len(data) > settings.max_image_bytes:
        raise ApiError(413, "too_large", "image too large")
    mime = _image_type(data)
    if mime is None:
        raise ApiError(415, "unsupported_media")
    source = SourceInput(type="image", image=data, mime_type=mime)
    return await analyze_source(source, provider=provider, settings=settings, budget=budget)


@router.post("/plan", response_model=PlanResponse)
async def plan(
    req: PlanRequest,
    settings: Settings = Depends(get_settings),
    provider: LLMProvider = Depends(get_llm_provider),
    budget: DailyBudget = Depends(get_ai_budget),
) -> PlanResponse:
    result = await plan_recipe(req.analysis, provider=provider, settings=settings, budget=budget)
    return PlanResponse(
        plan=result.plan,
        warnings_he=result.warnings_he,
        limitations_he=result.limitations_he,
        sources=result.sources,
    )


@router.post("/substitute", response_model=SubstituteResponse)
async def substitute(
    req: SubstituteRequest,
    settings: Settings = Depends(get_settings),
    provider: LLMProvider = Depends(get_llm_provider),
    budget: DailyBudget = Depends(get_ai_budget),
) -> SubstituteResponse:
    """A recipe-specific substitute for a missing ingredient or piece of equipment (one AI call)."""
    return await suggest_substitution(req, provider=provider, settings=settings, budget=budget)
