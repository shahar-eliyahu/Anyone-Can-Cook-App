"""Recipe-specific substitutions (Phase 3A, docs/DECISIONS.md #40, #41): one AI call (plus at
most one repair call) when the app's local table has no reliable answer.

The model's answer is converted into concrete patch operations, applied to a copy of the
recipe and plan, and validated like a generated plan. Food safety is recomputed by the
server from the curated table whenever the food type of a step changes, so the model never
writes safety lines itself. Every step that uses the replaced item gets a short note unless
the model rewrote its instructions, so recipe and plan never disagree silently.
"""

import json

from pydantic import ValidationError

from app.config import Settings
from app.errors import ApiError
from app.knowledge.food_safety import REFERENCES, reference_for
from app.prompts import load_prompt
from app.schemas.llm import LlmSubstitution
from app.schemas.plan import PlanStep
from app.schemas.recipe import Quantity
from app.schemas.substitution import (
    AddStepNote,
    OmitEquipment,
    OmitIngredient,
    ReplaceEquipment,
    ReplaceIngredient,
    SetIngredientUse,
    SetStepSafety,
    SetStepText,
    SetTimerSeconds,
    SubstituteRequest,
    SubstituteResponse,
)
from app.security import DailyBudget
from app.services.ai_calls import call_structured
from app.services.llm import LLMInvalidOutput, LLMProvider, TextPart
from app.services.patching import apply_ops
from app.services.planning import _apply_safety
from app.services.validation.logic import plan_problems

SUBSTITUTE_NOTE_HE = "תחליף"


def _target_name(req: SubstituteRequest) -> str:
    items = req.recipe.ingredients if req.target.kind == "ingredient" else req.recipe.equipment
    for item in items:
        if item.id == req.target.id:
            return item.name
    raise ApiError(422, "invalid_request", "unknown target")


def _uses_target(step: PlanStep, req: SubstituteRequest) -> bool:
    if req.target.kind == "ingredient":
        return req.target.id in step.ingredient_ids or any(u.ingredient_id == req.target.id for u in step.ingredient_uses)
    return req.target.id in step.equipment_ids


def _quantity(display: str, amount: float | None, unit: str | None, amount_max: float | None = None) -> Quantity:
    return Quantity(
        amount=amount, amount_max=amount_max, unit=unit, display=display, provenance="inferred",
        note_he=SUBSTITUTE_NOTE_HE,
    )


def safety_op(step: PlanStep, safety_food: str) -> SetStepSafety:
    """The step's safety lines for a (new) food type, from the curated table only."""
    ref_cues = {r.check_cue_he for r in REFERENCES.values()}
    d = step.model_dump(mode="json")
    d["warnings_he"] = [w for w in d.get("warnings_he", []) if w not in ref_cues]
    # The old cue described the old food ("העוף שחום…"): the new food's reference cue replaces it.
    d.pop("doneness_cue_he", None)
    for a in d["actions"]:
        if a.get("completes_step"):
            a["confirm_policy"] = "auto_ok"
    _apply_safety(d, reference_for(safety_food), False)
    return SetStepSafety(
        op="set_step_safety",
        step_id=step.id,
        warnings_he=d.get("warnings_he", []),
        doneness_cue_he=d.get("doneness_cue_he"),
        confirm_completion=any(a.get("completes_step") and a.get("confirm_policy") == "always_ask" for a in d["actions"]),
    )


def ops_from(llm: LlmSubstitution, req: SubstituteRequest) -> list:
    """Concrete operations for an accepted answer; raises ValueError when incomplete."""
    if llm.verdict not in ("works", "changes_result"):
        return []
    target, old_name = req.target, _target_name(req)
    ops: list = []
    if llm.omit:
        ops.append(OmitIngredient(op="omit_ingredient", ingredient_id=target.id) if target.kind == "ingredient"
                   else OmitEquipment(op="omit_equipment", equipment_id=target.id))
        new_name = None
    else:
        new_name = (llm.replacement_name_he or "").strip()
        if not new_name:
            raise ValueError("replacement_name_he is required unless omit=true")
        if target.kind == "ingredient":
            q = None if llm.quantity is None else _quantity(
                llm.quantity.display, llm.quantity.amount, llm.quantity.unit, llm.quantity.amount_max
            )
            ops.append(ReplaceIngredient(op="replace_ingredient", ingredient_id=target.id, name=new_name, quantity=q))
        else:
            ops.append(ReplaceEquipment(op="replace_equipment", equipment_id=target.id, name=new_name))
    rewritten: set[str] = set()
    for c in llm.step_changes:
        if c.use_display and target.kind == "ingredient" and not llm.omit:
            ops.append(SetIngredientUse(
                op="set_ingredient_use", step_id=c.step_id, ingredient_id=target.id,
                quantity=_quantity(c.use_display, c.use_amount, c.use_unit),
            ))
        if c.instruction_he and c.instruction_he.strip():
            ops.append(SetStepText(op="set_step_text", step_id=c.step_id, instruction_he=c.instruction_he.strip()))
            rewritten.add(c.step_id)
        if c.note_he and c.note_he.strip():
            ops.append(AddStepNote(op="add_step_note", step_id=c.step_id, note_he=c.note_he.strip()))
    for t in llm.timer_changes:
        ops.append(SetTimerSeconds(op="set_timer_seconds", timer_id=t.timer_id, seconds=t.seconds, max_seconds=t.max_seconds))
    # Steps that mention the replaced item but were not rewritten get a clear note.
    note = f"בלי {old_name}" if llm.omit else f"במקום {old_name}: {new_name}"
    for step in req.plan.steps:
        if _uses_target(step, req) and step.id not in rewritten:
            ops.append(AddStepNote(op="add_step_note", step_id=step.id, note_he=note))
    return ops


def validated_substitution(llm: LlmSubstitution, req: SubstituteRequest) -> SubstituteResponse:
    ops = ops_from(llm, req)
    if ops:
        recipe, plan = apply_ops(req.recipe, req.plan, ops)
        steps = {s.id: s for s in plan.steps}
        for change in llm.safety_changes:
            if change.step_id not in steps:
                raise ValueError(f"unknown step {change.step_id}")
            ops.append(safety_op(steps[change.step_id], change.safety_food))
        recipe, plan = apply_ops(req.recipe, req.plan, ops)
        problems = plan_problems(plan, recipe)
        if problems:
            raise ValueError("; ".join(problems))
    return SubstituteResponse(
        verdict=llm.verdict,
        explanation_he=llm.explanation_he.strip(),
        replacement_name_he=None if llm.omit else llm.replacement_name_he,
        effects_he=llm.effects_he,
        ops=ops,
    )


def _prompt_data(req: SubstituteRequest) -> str:
    recipe = json.dumps(req.recipe.model_dump(mode="json", exclude_none=True), ensure_ascii=False)
    steps = [
        {
            "id": s.id,
            "title": s.title,
            "instruction_he": s.instruction_he,
            "ingredient_uses": [u.model_dump(mode="json", exclude_none=True) for u in s.ingredient_uses],
            "equipment_ids": s.equipment_ids,
            "timers": [{"id": t.id, "label_he": t.label_he, "seconds": t.seconds} for t in s.timers],
        }
        for s in req.plan.steps
    ]
    target = {"kind": req.target.kind, "id": req.target.id, "name": _target_name(req)}
    return (
        f"<recipe>\n{recipe}\n</recipe>\n"
        f"<plan_steps>\n{json.dumps(steps, ensure_ascii=False)}\n</plan_steps>\n"
        f"<missing_item>\n{json.dumps(target, ensure_ascii=False)}\n</missing_item>\n"
        f"<cook_note>\n{req.user_note_he or ''}\n</cook_note>"
    )


async def suggest_substitution(
    req: SubstituteRequest,
    *,
    provider: LLMProvider,
    settings: Settings,
    budget: DailyBudget,
) -> SubstituteResponse:
    _target_name(req)  # 422 before any AI call
    parts = [TextPart(_prompt_data(req))]
    kwargs = dict(
        provider=provider, system=load_prompt("substitute_recipe"), schema=LlmSubstitution,
        model=settings.effective_plan_model, settings=settings, budget=budget,
    )
    problems = ""
    for attempt in (1, 2):
        try:
            llm = await call_structured(parts=parts, purpose="substitute" if attempt == 1 else "substitute_repair", **kwargs)
            return validated_substitution(llm, req)
        except LLMInvalidOutput as e:
            problems = e.problems
        except (ValueError, ValidationError) as e:
            problems = str(e)[:1500]
        if attempt == 1:
            parts = parts + [TextPart(
                f"Your previous answer had these problems:\n{problems}\nReturn a corrected answer as JSON only."
            )]
    raise ApiError(502, "invalid_ai_output", "substitution failed validation")

