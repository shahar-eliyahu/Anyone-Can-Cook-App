from fastapi import APIRouter, Depends

from app.config import Settings, get_settings
from app.schemas.assistant import AssistantTurnRequest, AssistantTurnResponse
from app.schemas.creation import RecipeCreationRequest, RecipeCreationResponse
from app.security import DailyBudget, get_ai_budget, rate_limit_assistant, require_app_token
from app.services.assistant import assistant_turn
from app.services.llm import LLMProvider, get_llm_provider
from app.services.recipe_creation import create_turn

router = APIRouter(
    prefix="/v1/assistant",
    dependencies=[Depends(require_app_token), Depends(rate_limit_assistant)],
)


@router.post("/turn", response_model=AssistantTurnResponse)
async def turn(
    req: AssistantTurnRequest,
    settings: Settings = Depends(get_settings),
    provider: LLMProvider = Depends(get_llm_provider),
    budget: DailyBudget = Depends(get_ai_budget),
) -> AssistantTurnResponse:
    """Remy answers a cooking question and may propose one change (the app executes it after approval)."""
    return await assistant_turn(req, provider=provider, settings=settings, budget=budget)


@router.post("/create", response_model=RecipeCreationResponse)
async def create(
    req: RecipeCreationRequest,
    settings: Settings = Depends(get_settings),
    provider: LLMProvider = Depends(get_llm_provider),
    budget: DailyBudget = Depends(get_ai_budget),
) -> RecipeCreationResponse:
    """Remy helps choose what to cook: an answer, a few options, or one recipe draft (never saved here)."""
    return await create_turn(req, provider=provider, settings=settings, budget=budget)
