"""Plan generation: analyzed recipe + resolved facts → a validated CookingPlan the app's
deterministic engine can run. One AI call, plus at most one repair call.
"""

import json
from dataclasses import dataclass, field

from pydantic import ValidationError

from app.config import Settings
from app.errors import ApiError
from app.knowledge.food_safety import REFERENCES, SOURCES, UNSCHEDULABLE_HE, reference_for
from app.prompts import load_prompt
from app.schemas.analysis import RecipeAnalysis, ReferenceSource
from app.schemas.llm import LlmPlan
from app.schemas.plan import CookingPlan
from app.security import DailyBudget
from app.services import gap_resolution
from app.services.ai_calls import call_structured
from app.services.llm import LLMInvalidOutput, LLMProvider, TextPart
from app.services.validation.logic import plan_problems
from app.services.validation.numbers import states_duration, states_number, states_temperature

NOT_IN_SOURCE_HE = "לא נמצא בטקסט המקורי — סומן כהערכה"
MAX_TIPS = 3


@dataclass
class PlanResult:
    plan: CookingPlan
    warnings_he: list[str] = field(default_factory=list)
    limitations_he: list[str] = field(default_factory=list)
    sources: list[ReferenceSource] = field(default_factory=list)


async def plan_recipe(
    analysis: RecipeAnalysis,
    *,
    provider: LLMProvider,
    settings: Settings,
    budget: DailyBudget,
) -> PlanResult:
    if not analysis.is_recipe or analysis.recipe is None:
        raise ApiError(422, "not_a_recipe")
    facts = gap_resolution.facts_for_plan(analysis.gaps, analysis.answers)
    unresolved = [f for f in facts if f.status == "unresolved"]
    if any(f.note_he == UNSCHEDULABLE_HE for f in unresolved):
        raise ApiError(422, "unsafe_to_plan", "home preserving")

    parts = [TextPart(_prompt_data(analysis, facts))]
    kwargs = dict(
        provider=provider, system=load_prompt("plan_recipe"), schema=LlmPlan,
        model=settings.effective_plan_model, settings=settings, budget=budget,
    )
    problems: list[str] = []
    for attempt in (1, 2):
        try:
            llm = await call_structured(parts=parts, purpose="plan" if attempt == 1 else "plan_repair", **kwargs)
        except LLMInvalidOutput as e:
            problems = [e.problems]
        else:
            try:
                plan, warnings = _plan_from(llm, analysis)
            except (ValidationError, ValueError) as e:
                problems = [str(e)[:2000]]
            else:
                problems = plan_problems(plan, analysis.recipe)
                if not problems:
                    sources = {s.id: s for s in analysis.sources}
                    for step in llm.steps:
                        if ref := reference_for(step.safety_food):
                            for sid in ref.source_ids:
                                sources[sid] = SOURCES[sid]
                    return PlanResult(
                        plan=plan,
                        warnings_he=warnings,
                        limitations_he=[f.note_he for f in unresolved if f.note_he],
                        sources=list(sources.values()),
                    )
        if attempt == 1:
            parts = parts + [TextPart(
                "Your previous plan had these problems:\n- " + "\n- ".join(problems)
                + "\nReturn a corrected plan as JSON only."
            )]
    raise ApiError(502, "invalid_ai_output", f"plan failed validation ({len(problems)} problems)")


def _mentions_thermometer(text: str | None) -> bool:
    low = (text or "").lower()
    return "מדחום" in low or "thermometer" in low


def _apply_safety(step: dict, ref, source_mentions_thermometer: bool) -> None:
    """Practical guidance (docs/DECISIONS.md #37, #38).

    High-risk foods (poultry, ground meat): one short warning line, the doneness cue,
    and the cook confirms doneness (`always_ask`). Other safety-tagged foods: an
    observable cue only, no warning and no forced confirmation. Steps that are not
    high-risk never get a thermometer requirement the recipe itself doesn't mention:
    such lines added by the model are dropped, and a cue that relies on one is replaced
    by the reference's observable cue.
    """
    high_risk = ref is not None and ref.high_risk
    if not high_risk and not source_mentions_thermometer:
        step["warnings_he"] = [w for w in step.get("warnings_he", []) if not _mentions_thermometer(w)]
        cue = step.get("doneness_cue_he")
        if cue and _mentions_thermometer(cue):
            if ref is not None:
                step["doneness_cue_he"] = ref.check_cue_he
            else:
                step.pop("doneness_cue_he")
    if ref is None:
        return
    if high_risk:
        step["warnings_he"] = list(dict.fromkeys([*step.get("warnings_he", []), ref.check_cue_he]))
        step.setdefault("doneness_cue_he", ref.check_cue_he)
        for a in step["actions"]:
            if a.get("completes_step"):
                a["confirm_policy"] = "always_ask"
    else:
        step.setdefault("doneness_cue_he", ref.check_cue_he)


def _prompt_data(analysis: RecipeAnalysis, facts: list[gap_resolution.Fact]) -> str:
    recipe = json.dumps(analysis.recipe.model_dump(mode="json"), ensure_ascii=False)
    fact_list = [
        {"field": f.field, "status": f.status, "value_he": f.value_he, "note_he": f.note_he} for f in facts
    ]
    refs = [
        {
            "food": r.food,
            "min_internal_c": r.min_internal_c,
            "rest_minutes": r.rest_minutes,
            "check_cue_he": r.check_cue_he,
            "high_risk": r.high_risk,
        }
        for r in REFERENCES.values()
    ]
    return (
        f"<recipe>\n{recipe}\n</recipe>\n"
        f"<source_text>\n{analysis.source_text}\n</source_text>\n"
        f"<resolved_facts>\n{json.dumps(fact_list, ensure_ascii=False)}\n</resolved_facts>\n"
        f"<food_safety_references>\n{json.dumps(refs, ensure_ascii=False)}\n</food_safety_references>"
    )


def _plan_from(llm: LlmPlan, analysis: RecipeAnalysis) -> tuple[CookingPlan, list[str]]:
    """Converts and repairs what can be repaired deterministically; returns warnings."""
    source = analysis.source_text
    answers = " ".join(a.value or "" for a in analysis.answers if not a.unknown)
    warnings: list[str] = []
    step_ids = {s.id for s in llm.steps}
    prep_ids = {p.id for p in llm.prep_tasks}
    deps = {s.id: set(s.depends_on) for s in llm.steps}

    def waits_for(step_id: str, owner_id: str) -> bool:
        seen, stack = set(), [step_id]
        while stack:
            cur = stack.pop()
            if cur in seen:
                continue
            seen.add(cur)
            if owner_id in deps.get(cur, ()):
                return True
            stack.extend(deps.get(cur, ()))
        return False

    def check_prov(prov: str, stated: bool, answered: bool) -> str:
        if prov == "original" and not stated:
            return "inferred"
        if prov == "answered" and not answered:
            return "inferred"
        return prov

    def timer_dict(t, owner_id: str | None) -> dict:
        d = t.model_dump(exclude_none=True)
        stated = states_duration(source, t.seconds) and (
            t.max_seconds is None or states_duration(source, t.max_seconds)
        )
        d["provenance"] = check_prov(t.provenance, stated, states_duration(answers, t.seconds))
        if d["provenance"] == "inferred" and t.provenance != "inferred":
            d["note_he"] = NOT_IN_SOURCE_HE
        if d["provenance"] == "reference":
            d["provenance"] = "inferred"  # durations never come from the reference table
        d["meanwhile_tips_he"] = t.meanwhile_tips_he[:MAX_TIPS]
        # Keep only real ids that do not wait for this timer's own step.
        d["suggest_during"] = [
            sid for sid in t.suggest_during
            if sid in prep_ids
            or (sid in step_ids and owner_id is not None and sid != owner_id and not waits_for(sid, owner_id))
        ]
        return d

    source_mentions_thermometer = _mentions_thermometer(source)
    steps: list[dict] = []
    for s in llm.steps:
        d = s.model_dump(exclude_none=True, exclude={"safety_food"})
        d["timers"] = [timer_dict(t, s.id) for t in s.timers]
        d["ingredient_ids"] = list(dict.fromkeys(u.ingredient_id for u in s.ingredient_uses))
        uses = []
        for u in s.ingredient_uses:
            ud = u.model_dump(exclude_none=True)
            if u.quantity is not None:
                q = ud["quantity"]
                stated = u.quantity.amount is None or states_number(source, u.quantity.amount)
                q["provenance"] = check_prov(u.quantity.provenance, stated, True)
                if q["provenance"] == "reference":
                    q["provenance"] = "inferred"
            uses.append(ud)
        d["ingredient_uses"] = uses
        if s.temperature is not None:
            temp = d["temperature"]
            prov = s.temperature.provenance
            if prov == "reference":
                valid = {r.min_internal_c for r in REFERENCES.values() if r.min_internal_c is not None}
                temp["provenance"] = "reference" if s.temperature.value in valid else "inferred"
            else:
                temp["provenance"] = check_prov(
                    prov, states_temperature(source, s.temperature.value), states_number(answers, s.temperature.value)
                )
        for key in ("estimated_active_minutes",):
            if key in d and d[key]["provenance"] == "original" and not states_duration(source, d[key]["value"] * 60):
                d[key]["provenance"] = "inferred"
        _apply_safety(d, reference_for(s.safety_food), source_mentions_thermometer)
        steps.append(d)

    prep_tasks = []
    for p in llm.prep_tasks:
        d = p.model_dump(exclude_none=True, exclude={"surface_at_start", "surface_with_step"})
        d["surface"] = (
            {"with_step": p.surface_with_step}
            if p.surface_with_step in step_ids
            else {"at_start": True}
        )
        if p.timer is not None:
            d["timer"] = timer_dict(p.timer, None)
        if "lead_minutes" in d and d["lead_minutes"]["provenance"] == "original":
            d["lead_minutes"]["provenance"] = "inferred"
        prep_tasks.append(d)

    plan = CookingPlan.model_validate({
        "steps": steps,
        "prep_tasks": prep_tasks,
        "advance_notice_he": llm.advance_notice_he,
    })
    downgraded = sum(
        1 for s in plan.steps for t in s.timers if t.note_he == NOT_IN_SOURCE_HE
    )
    if downgraded:
        warnings.append(f"{downgraded} זמנים לא הופיעו במתכון המקורי וסומנו כהערכה.")
    return plan, warnings
