"""Request and response bodies of the /v1/recipes endpoints."""

from typing import Literal

from pydantic import Field

from app.schemas.analysis import RecipeAnalysis, ReferenceSource
from app.schemas.common import ContractModel
from app.schemas.plan import CookingPlan


class AnalyzeRequest(ContractModel):
    type: Literal["text", "url"]
    content: str = Field(min_length=1)


class PlanRequest(ContractModel):
    # The stored analysis including the cook's answers; the server keeps no state.
    analysis: RecipeAnalysis


class PlanResponse(ContractModel):
    plan: CookingPlan
    warnings_he: list[str] = []
    # What could not be resolved safely, shown before approval.
    limitations_he: list[str] = []
    sources: list[ReferenceSource] = []
