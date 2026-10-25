"""Creating a recipe with Remy (stage recipe_creation): POST /v1/assistant/create.

The server keeps no conversation. Each request carries the cook's message, the last few turns,
the preferences gathered so far in this creation conversation (returned by the previous turn and
kept by the app) and, when the cook is refining a draft Remy made, a short summary of that draft.
A created recipe comes back as a validated RecipeAnalysis that the app stores as a DRAFT: nothing
is saved as a recipe until the cook reviews it and saves it.
"""

from typing import Annotated, Literal

from pydantic import Field

from app.schemas.analysis import RecipeAnalysis
from app.schemas.assistant import HistoryItem
from app.schemas.common import ContractModel

ShortText = Annotated[str, Field(max_length=60)]


class CreationPreferences(ContractModel):
    servings: float | None = Field(default=None, gt=0, le=50)
    max_minutes: int | None = Field(default=None, gt=0, le=1440)
    diet_he: list[ShortText] = Field(default=[], max_length=6)
    available_ingredients_he: list[ShortText] = Field(default=[], max_length=20)
    avoid_he: list[ShortText] = Field(default=[], max_length=10)


class DraftSummary(ContractModel):
    """The draft being refined ("בלי חלב", "לארבעה"): enough to change it, not the whole record."""

    title: str = Field(max_length=120)
    ingredients_he: list[Annotated[str, Field(max_length=120)]] = Field(default=[], max_length=40)
    steps_he: list[Annotated[str, Field(max_length=400)]] = Field(default=[], max_length=25)


class RecipeCreationRequest(ContractModel):
    stage: Literal["recipe_creation"] = "recipe_creation"
    message_he: str = Field(min_length=1, max_length=500)
    modality: Literal["text", "voice"] = "text"
    preferences: CreationPreferences = CreationPreferences()
    history: list[HistoryItem] = Field(default=[], max_length=6)
    current_recipe: DraftSummary | None = None


class RecipeCreationResponse(ContractModel):
    # answer: a reply or one short question; options: a few dishes to choose from;
    # recipe: a complete draft in `analysis`.
    kind: Literal["answer", "options", "recipe"]
    answer_he: str
    speech_he: str
    options_he: list[str] = []
    preferences: CreationPreferences = CreationPreferences()
    analysis: RecipeAnalysis | None = None
    total_minutes: int | None = None
    tips_he: list[str] = []
