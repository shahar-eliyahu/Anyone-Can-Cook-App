"""The executable cooking plan run by the app's deterministic CookingEngine.

Fields added in Phase 2 are optional with defaults, so Phase 1 plans stay valid
(schema_version stays 1; see docs/DECISIONS.md #20).
"""

from typing import Literal

from pydantic import Field, model_validator

from app.schemas.common import Confidence, ContractModel, Provenance
from app.schemas.recipe import Quantity

ActionType = Literal["start", "done", "in_oven", "out_of_oven", "custom"]
ConfirmPolicy = Literal["auto_ok", "always_ask"]
WaitKind = Literal["cook", "bake", "rest", "chill", "freeze", "proof", "soak", "marinate", "other"]

MAX_TIMER_SECONDS = 72 * 3600


class PlanTimer(ContractModel):
    id: str
    label_he: str
    # When to check (the notification time).
    seconds: int = Field(gt=0, le=MAX_TIMER_SECONDS)
    provenance: Provenance
    note_he: str | None = None
    confidence: Confidence | None = None
    source_ids: list[str] = []
    wait_kind: WaitKind | None = None
    # Optional end of a range ("60–90 minutes"); must be after `seconds`.
    max_seconds: int | None = Field(default=None, gt=0, le=MAX_TIMER_SECONDS)
    wait_info_he: str | None = None
    check_cue_he: str | None = None
    # Ids of real steps or prep tasks worth doing during this wait.
    suggest_during: list[str] = []
    meanwhile_tips_he: list[str] = Field(default=[], max_length=3)
    # How long "not ready — check again" waits.
    recheck_seconds: int | None = Field(default=None, gt=0, le=6 * 3600)

    @model_validator(mode="after")
    def _range_after_check(self) -> "PlanTimer":
        if self.max_seconds is not None and self.max_seconds <= self.seconds:
            raise ValueError("max_seconds must be greater than seconds")
        return self


class StepAction(ContractModel):
    id: str
    type: ActionType
    label_he: str
    starts_timer: str | None = None
    completes_step: bool = False
    confirm_policy: ConfirmPolicy = "auto_ok"


class Temperature(ContractModel):
    value: int
    unit: Literal["C", "F"] = "C"
    provenance: Provenance
    confidence: Confidence | None = None
    source_ids: list[str] = []


class Minutes(ContractModel):
    value: int = Field(ge=0)
    provenance: Provenance
    note_he: str | None = None
    confidence: Confidence | None = None


class IngredientUse(ContractModel):
    """The amount of a recipe ingredient used in one step."""

    ingredient_id: str
    quantity: Quantity | None = None
    note_he: str | None = None


class PlanStep(ContractModel):
    id: str
    title: str
    instruction_he: str
    source_refs: list[str] = []
    ingredient_ids: list[str] = []
    ingredient_uses: list[IngredientUse] = []
    equipment_ids: list[str] = []
    depends_on: list[str] = []
    kind: Literal["active", "passive"] = "active"
    parallel_ok: bool = False
    actions: list[StepAction] = Field(min_length=1)
    timers: list[PlanTimer] = []
    temperature: Temperature | None = None
    doneness_cue_he: str | None = None
    # Optional short help shown only when the cook asks ("עזרה"): how to know it's ready,
    # one common problem, in plain words.
    help_he: str | None = Field(default=None, max_length=400)
    # Short notes added when the cook accepted a substitution ("במקום שמנת: …").
    notes_he: list[str] = []
    warnings_he: list[str] = []
    estimated_active_minutes: Minutes | None = None


class PrepSurface(ContractModel):
    with_step: str | None = None
    at_start: bool = False


class PrepTask(ContractModel):
    id: str
    kind: Literal["preheat_oven", "boil_water", "mise_en_place", "thaw", "other"]
    text_he: str
    needed_by_step: str | None = None
    lead_minutes: Minutes | None = None
    surface: PrepSurface = PrepSurface(at_start=True)
    timer: PlanTimer | None = None
    confirm_policy: ConfirmPolicy = "auto_ok"
    # One reminder notification `lead_minutes` before a wait that gates `needed_by_step` ends.
    remind_before_needed: bool = False


class CookingPlan(ContractModel):
    schema_version: Literal[1] = 1
    steps: list[PlanStep] = Field(min_length=1)
    prep_tasks: list[PrepTask] = []
    # e.g. "needs an overnight soak — start the day before".
    advance_notice_he: str | None = None
