"""Schemas the model fills in. Deliberately simple (no $ref-heavy unions, no
forbidden-extra rules) for Gemini structured output; server code converts them
into the strict contract models and validates the result.

Field semantics are explained in the prompts (app/prompts/*.md).
"""

from typing import Literal

from pydantic import BaseModel

Category = Literal["safety", "outcome", "equipment", "preference", "minor"]
Conf = Literal["high", "medium", "low"]
SafetyFoodName = Literal[
    "poultry", "ground_meat", "whole_cut_meat", "fish", "egg_dish", "eggs_stovetop", "leftovers",
    "home_preserving", "none",
]


class LlmQuantity(BaseModel):
    amount: float | None = None
    amount_max: float | None = None
    unit: str | None = None
    display: str
    stated_in_source: bool


class LlmIngredient(BaseModel):
    id: str
    name: str
    quantity: LlmQuantity | None = None
    preparation: str | None = None
    group: str | None = None
    optional: bool = False


class LlmEquipment(BaseModel):
    id: str
    name: str
    stated_in_source: bool


class LlmSourceStep(BaseModel):
    id: str
    text: str


class LlmGap(BaseModel):
    id: str
    field: str
    category: Category
    description_he: str
    estimate_display: str | None = None
    confidence: Conf | None = None
    safety_food: SafetyFoodName | None = None
    # The model's suggestion; the backend policy decides whether to actually ask.
    suggest_asking: bool = False
    question_he: str | None = None
    why_he: str | None = None
    question_kind: Literal["choice", "number", "text"] | None = None
    options: list[str] = []
    unit_he: str | None = None


class LlmAnalysis(BaseModel):
    is_recipe: bool
    not_recipe_reason_he: str | None = None
    title: str = ""
    description: str | None = None
    servings_amount: float | None = None
    servings_unit: str | None = None
    servings_stated: bool = False
    ingredients: list[LlmIngredient] = []
    equipment: list[LlmEquipment] = []
    source_steps: list[LlmSourceStep] = []
    # Verbatim text read from a photo (empty for text and URL inputs).
    transcription: str = ""
    gaps: list[LlmGap] = []
    assumptions_he: list[str] = []


Prov = Literal["original", "inferred", "answered", "reference"]


class LlmPlanQuantity(BaseModel):
    amount: float | None = None
    unit: str | None = None
    display: str
    provenance: Prov
    note_he: str | None = None


class LlmIngredientUse(BaseModel):
    ingredient_id: str
    quantity: LlmPlanQuantity | None = None


class LlmTimer(BaseModel):
    id: str
    label_he: str
    seconds: int
    max_seconds: int | None = None
    provenance: Prov
    confidence: Conf | None = None
    note_he: str | None = None
    wait_kind: Literal["cook", "bake", "rest", "chill", "freeze", "proof", "soak", "marinate", "other"] | None = None
    wait_info_he: str | None = None
    check_cue_he: str | None = None
    suggest_during: list[str] = []
    meanwhile_tips_he: list[str] = []
    recheck_seconds: int | None = None


class LlmAction(BaseModel):
    id: str
    type: Literal["start", "done", "in_oven", "out_of_oven", "custom"]
    label_he: str
    starts_timer: str | None = None
    completes_step: bool = False


class LlmTemperature(BaseModel):
    value: int
    unit: Literal["C", "F"] = "C"
    provenance: Prov


class LlmMinutes(BaseModel):
    value: int
    provenance: Prov
    note_he: str | None = None


class LlmStep(BaseModel):
    id: str
    title: str
    instruction_he: str
    source_refs: list[str] = []
    ingredient_uses: list[LlmIngredientUse] = []
    equipment_ids: list[str] = []
    depends_on: list[str] = []
    kind: Literal["active", "passive"] = "active"
    parallel_ok: bool = False
    actions: list[LlmAction]
    timers: list[LlmTimer] = []
    temperature: LlmTemperature | None = None
    doneness_cue_he: str | None = None
    help_he: str | None = None
    warnings_he: list[str] = []
    estimated_active_minutes: LlmMinutes | None = None
    safety_food: SafetyFoodName | None = None


class LlmPrepTask(BaseModel):
    id: str
    kind: Literal["preheat_oven", "boil_water", "mise_en_place", "thaw", "other"]
    text_he: str
    needed_by_step: str | None = None
    lead_minutes: LlmMinutes | None = None
    surface_at_start: bool = False
    surface_with_step: str | None = None
    timer: LlmTimer | None = None
    remind_before_needed: bool = False


class LlmStepChange(BaseModel):
    step_id: str
    instruction_he: str | None = None
    note_he: str | None = None
    # The amount of the replacement used in this step, when it differs from the whole amount.
    use_display: str | None = None
    use_amount: float | None = None
    use_unit: str | None = None


class LlmTimerChange(BaseModel):
    timer_id: str
    seconds: int
    max_seconds: int | None = None


class LlmSafetyChange(BaseModel):
    step_id: str
    safety_food: SafetyFoodName


class LlmSubstitution(BaseModel):
    verdict: Literal["works", "changes_result", "not_recommended", "no_substitute"]
    explanation_he: str
    replacement_name_he: str | None = None
    # True when the best answer is to cook without it (no replacement needed).
    omit: bool = False
    quantity: LlmQuantity | None = None
    effects_he: str | None = None
    step_changes: list[LlmStepChange] = []
    timer_changes: list[LlmTimerChange] = []
    safety_changes: list[LlmSafetyChange] = []


class LlmAssistantTurn(BaseModel):
    intent: Literal["cooking_question", "session_question", "change_request", "out_of_scope", "unclear"]
    answer_he: str
    # A short plain-text version for text-to-speech (no emoji or symbols); optional.
    speech_he: str | None = None
    has_off_topic_part: bool = False
    proposal_kind: Literal["none", "extend_timer", "substitution", "step_change"] = "none"
    proposal_summary_he: str | None = None
    timer_id: str | None = None
    extra_seconds: int | None = None
    substitution_target_kind: Literal["ingredient", "equipment"] | None = None
    substitution_target_id: str | None = None
    substitution: LlmSubstitution | None = None
    step_changes: list[LlmStepChange] = []
    timer_changes: list[LlmTimerChange] = []
    safety_note_he: str | None = None


class LlmPlan(BaseModel):
    steps: list[LlmStep]
    prep_tasks: list[LlmPrepTask] = []
    advance_notice_he: str | None = None
