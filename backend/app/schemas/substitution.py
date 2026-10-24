"""Substitutions before cooking (Phase 3A): request/response of POST /v1/recipes/substitute
and the concrete patch operations the app applies to the recipe and plan.

Operations are plain data from a small fixed set, so the app can rebuild the effective
recipe and plan deterministically as "original + accepted operations" (and undo any
substitution exactly). The app implements the same semantics
(`app/lib/features/prepare/patch.dart`); `shared/fixtures/patch_example.json` keeps both in step.
"""

from typing import Annotated, Literal

from pydantic import Field

from app.schemas.common import ContractModel
from app.schemas.plan import MAX_TIMER_SECONDS, CookingPlan
from app.schemas.recipe import Quantity, Recipe

Verdict = Literal["works", "changes_result", "not_recommended", "no_substitute"]


class ReplaceIngredient(ContractModel):
    op: Literal["replace_ingredient"]
    ingredient_id: str
    name: str = Field(min_length=1, max_length=120)
    quantity: Quantity | None = None  # None keeps the current amount


class OmitIngredient(ContractModel):
    op: Literal["omit_ingredient"]
    ingredient_id: str


class ReplaceEquipment(ContractModel):
    op: Literal["replace_equipment"]
    equipment_id: str
    name: str = Field(min_length=1, max_length=120)


class OmitEquipment(ContractModel):
    op: Literal["omit_equipment"]
    equipment_id: str


class SetIngredientUse(ContractModel):
    op: Literal["set_ingredient_use"]
    step_id: str
    ingredient_id: str
    quantity: Quantity | None = None


class SetStepText(ContractModel):
    op: Literal["set_step_text"]
    step_id: str
    instruction_he: str = Field(min_length=1, max_length=600)


class AddStepNote(ContractModel):
    op: Literal["add_step_note"]
    step_id: str
    note_he: str = Field(min_length=1, max_length=300)


class SetTimerSeconds(ContractModel):
    op: Literal["set_timer_seconds"]
    timer_id: str
    seconds: int = Field(gt=0, le=MAX_TIMER_SECONDS)
    max_seconds: int | None = Field(default=None, gt=0, le=MAX_TIMER_SECONDS)


class SetStepSafety(ContractModel):
    """Concrete safety lines for a step (computed by the server from the food-safety table)."""

    op: Literal["set_step_safety"]
    step_id: str
    warnings_he: list[str] = []
    doneness_cue_he: str | None = None
    confirm_completion: bool = False


PatchOp = Annotated[
    ReplaceIngredient
    | OmitIngredient
    | ReplaceEquipment
    | OmitEquipment
    | SetIngredientUse
    | SetStepText
    | AddStepNote
    | SetTimerSeconds
    | SetStepSafety,
    Field(discriminator="op"),
]


class SubstituteTarget(ContractModel):
    kind: Literal["ingredient", "equipment"]
    id: str


class SubstituteRequest(ContractModel):
    recipe: Recipe
    plan: CookingPlan
    target: SubstituteTarget
    # What the cook has instead, in their words ("יש לי חלב"); optional.
    user_note_he: str | None = Field(default=None, max_length=300)


class SubstituteResponse(ContractModel):
    verdict: Verdict
    explanation_he: str
    replacement_name_he: str | None = None
    effects_he: str | None = None
    # Empty unless the verdict is "works" or "changes_result".
    ops: list[PatchOp] = []
