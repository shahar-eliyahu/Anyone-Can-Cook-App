"""Result of analyzing an imported recipe: what the app stores for a draft and shows on review."""

from typing import Literal

from app.schemas.common import ContractModel
from app.schemas.recipe import Recipe

GapCategory = Literal["safety", "outcome", "equipment", "preference", "minor"]
GapResolution = Literal["context", "reference", "estimate", "question", "unresolved"]


class RecipeSourceInfo(ContractModel):
    type: Literal["text", "image", "url", "sample"]
    url: str | None = None
    site_name: str | None = None
    title: str | None = None
    retrieved_at: str | None = None  # ISO 8601, UTC


class ReferenceSource(ContractModel):
    """A source a value relies on, e.g. a food-safety reference."""

    id: str
    title: str
    url: str | None = None
    kind: Literal["food_safety_reference", "recipe_source"]


class Question(ContractModel):
    id: str
    text_he: str
    why_he: str
    kind: Literal["choice", "number", "text"]
    options: list[str] = []
    unit_he: str | None = None
    category: GapCategory
    # Only unresolved safety questions are required.
    required: bool = False
    # Field paths this answer affects, e.g. "steps.s3.temperature".
    affects: list[str] = []


class Answer(ContractModel):
    question_id: str
    value: str | None = None
    # "לא יודע/ת": resolve with a reference or an estimate, never ask again.
    unknown: bool = False


class Gap(ContractModel):
    """A piece of missing information and how it was resolved."""

    id: str
    field: str
    category: GapCategory
    resolution: GapResolution
    question_id: str | None = None
    note_he: str | None = None


class RecipeAnalysis(ContractModel):
    schema_version: Literal[1] = 1
    is_recipe: bool
    not_recipe_reason_he: str | None = None
    source: RecipeSourceInfo
    # The recipe text as extracted (pasted text, transcribed photo, or page text).
    source_text: str = ""
    recipe: Recipe | None = None
    questions: list[Question] = []
    answers: list[Answer] = []
    gaps: list[Gap] = []
    sources: list[ReferenceSource] = []
    assumptions_he: list[str] = []
