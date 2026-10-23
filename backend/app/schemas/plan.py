"""The executable cooking plan run by the app's deterministic CookingEngine."""

from typing import Literal

from pydantic import Field

from app.schemas.common import ContractModel, Provenance

ActionType = Literal["start", "done", "in_oven", "out_of_oven", "custom"]
ConfirmPolicy = Literal["auto_ok", "always_ask"]


class PlanTimer(ContractModel):
    id: str
    label_he: str
    seconds: int = Field(gt=0, le=24 * 3600)
    provenance: Provenance
    note_he: str | None = None


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


class Minutes(ContractModel):
    value: int = Field(ge=0)
    provenance: Provenance
    note_he: str | None = None


class PlanStep(ContractModel):
    id: str
    title: str
    instruction_he: str
    source_refs: list[str] = []
    ingredient_ids: list[str] = []
    equipment_ids: list[str] = []
    depends_on: list[str] = []
    kind: Literal["active", "passive"] = "active"
    parallel_ok: bool = False
    actions: list[StepAction] = Field(min_length=1)
    timers: list[PlanTimer] = []
    temperature: Temperature | None = None
    doneness_cue_he: str | None = None
    warnings_he: list[str] = []


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


class CookingPlan(ContractModel):
    schema_version: Literal[1] = 1
    steps: list[PlanStep] = Field(min_length=1)
    prep_tasks: list[PrepTask] = []
