"""Analysis and planning pipeline, driven by a fake provider (zero real Gemini calls)."""

import asyncio
import copy

import pytest

from app.config import Settings
from app.errors import ApiError
from app.schemas.analysis import Answer
from app.security import DailyBudget
from app.services.analysis import NOT_IN_SOURCE_HE, SourceInput, analyze_source
from app.services.llm import LLMRateLimited, LLMUnavailable
from app.services.planning import plan_recipe
from tests.fakes import SAMPLE_SOURCE_TEXT, FakeProvider, mock_json

SETTINGS = Settings(_env_file=None, ai_model="test-model")


def run(coro):
    return asyncio.run(coro)


def analysis_out(**changes):
    data = copy.deepcopy(mock_json("sample_analysis.json"))
    data.update(changes)
    return data


def plan_out():
    return copy.deepcopy(mock_json("sample_plan.json"))


async def analyze(provider, text=SAMPLE_SOURCE_TEXT, budget=None):
    return await analyze_source(
        SourceInput(type="text", text=text), provider=provider, settings=SETTINGS, budget=budget or DailyBudget()
    )


async def plan(provider, analysis, budget=None):
    return await plan_recipe(analysis, provider=provider, settings=SETTINGS, budget=budget or DailyBudget())


def sample_analysis():
    return run(analyze(FakeProvider({"LlmAnalysis": [analysis_out()]})))


# ---- analysis -------------------------------------------------------------

def test_analysis_keeps_original_amounts_and_resolves_gaps_without_questions():
    a = sample_analysis()
    assert a.is_recipe and a.recipe is not None
    flour = a.recipe.ingredients[0]
    assert (flour.quantity.display, flour.quantity.provenance) == ('1 ק"ג', "original")
    assert {g.field: g.resolution for g in a.gaps} == {"rice_cook_time": "estimate", "chicken_doneness": "reference"}
    assert a.questions == []
    assert [s.id for s in a.sources] == ["ref_fsis_temps", "ref_il_moh_5keys"]
    assert a.source_text == SAMPLE_SOURCE_TEXT


def test_amount_not_in_the_source_is_downgraded_to_an_estimate():
    a = run(analyze(FakeProvider({"LlmAnalysis": [analysis_out()]}), text="עוף, תפוחי אדמה ואורז. אופים עד שמוכן."))
    flour = a.recipe.ingredients[0]
    assert flour.quantity.provenance == "inferred"
    assert flour.quantity.note_he == NOT_IN_SOURCE_HE


def test_not_a_recipe():
    a = run(analyze(FakeProvider({"LlmAnalysis": [{"is_recipe": False, "not_recipe_reason_he": "זה מתכון לחיים, לא לבישול"}]})))
    assert not a.is_recipe and a.recipe is None


def gap(**kw):
    base = {"id": "g", "field": "f", "category": "outcome", "description_he": "חסר מידע"}
    return {**base, **kw}


@pytest.mark.parametrize(
    "g,resolution,asked,required",
    [
        (gap(confidence="high", estimate_display="כ-35 דקות"), "estimate", False, False),
        (gap(confidence="low", suggest_asking=True, question_he="?"), "question", True, False),
        (gap(confidence="medium", suggest_asking=True, question_he="?"), "estimate", False, False),
        (gap(category="equipment", suggest_asking=True, question_he="באיזו תבנית?"), "question", True, False),
        (gap(category="equipment"), "estimate", False, False),
        (gap(category="preference", suggest_asking=False), "estimate", False, False),
        (gap(category="minor", suggest_asking=True, question_he="?"), "context", False, False),
        (gap(category="safety", safety_food="fish"), "reference", False, False),
        (gap(category="safety", safety_food="none", question_he="איזה בשר?"), "question", True, True),
        (gap(category="safety", safety_food="home_preserving"), "unresolved", False, False),
    ],
)
def test_resolution_ladder(g, resolution, asked, required):
    a = run(analyze(FakeProvider({"LlmAnalysis": [analysis_out(gaps=[g])]})))
    assert a.gaps[0].resolution == resolution
    assert (len(a.questions) == 1) == asked
    if asked:
        assert a.questions[0].required == required
        assert a.gaps[0].question_id == a.questions[0].id


def test_no_fixed_question_limit():
    gaps = [gap(id=f"g{i}", field=f"f{i}", category="equipment", suggest_asking=True, question_he=f"שאלה {i}") for i in range(5)]
    a = run(analyze(FakeProvider({"LlmAnalysis": [analysis_out(gaps=gaps)]})))
    assert len(a.questions) == 5


# ---- planning -------------------------------------------------------------

def test_plan_is_valid_for_the_engine_and_applies_food_safety():
    r = run(plan(FakeProvider({"LlmPlan": [plan_out()]}), sample_analysis()))
    steps = {s.id: s for s in r.plan.steps}
    bake = steps["s3"]
    assert bake.actions[-1].confirm_policy == "always_ask"
    assert any("74°C" in w for w in bake.warnings_he)
    assert bake.timers[0].provenance == "original"  # 45 minutes is in the source
    assert steps["s4"].timers[0].provenance == "inferred"
    assert {s.id for s in r.sources} >= {"ref_fsis_temps"}
    assert steps["s1"].ingredient_ids == ["i2", "i3", "i4", "i5"]


def test_timer_claimed_original_but_not_in_source_is_downgraded():
    out = plan_out()
    out["steps"][3]["timers"][0]["provenance"] = "original"  # rice: 18 minutes is not in the source
    r = run(plan(FakeProvider({"LlmPlan": [out]}), sample_analysis()))
    rice = [s for s in r.plan.steps if s.id == "s4"][0].timers[0]
    assert rice.provenance == "inferred"
    assert rice.note_he == NOT_IN_SOURCE_HE
    assert r.warnings_he


def test_suggestions_that_wait_for_the_same_step_are_removed_and_tips_capped():
    out = plan_out()
    bake_timer = out["steps"][2]["timers"][0]
    bake_timer["suggest_during"] = ["s4", "s5", "missing", "p2"]  # s5 depends on s3
    bake_timer["meanwhile_tips_he"] = ["א", "ב", "ג", "ד"]
    r = run(plan(FakeProvider({"LlmPlan": [out]}), sample_analysis()))
    t = [s for s in r.plan.steps if s.id == "s3"][0].timers[0]
    assert t.suggest_during == ["s4", "p2"]
    assert len(t.meanwhile_tips_he) == 3


def test_dont_know_answer_is_resolved_and_safety_unknown_becomes_a_limitation():
    gaps = [
        gap(id="g1", field="pan_size", category="equipment", suggest_asking=True, question_he="באיזו תבנית?"),
        gap(id="g2", field="meat_type", category="safety", safety_food="none", question_he="איזה בשר?"),
    ]
    a = run(analyze(FakeProvider({"LlmAnalysis": [analysis_out(gaps=gaps)]})))
    answered = a.model_copy(update={"answers": [Answer(question_id=q.id, unknown=True) for q in a.questions]})
    provider = FakeProvider({"LlmPlan": [plan_out()]})
    r = run(plan(provider, answered))
    prompt = provider.calls[0]["parts"][0].text
    assert '"status": "estimate"' in prompt and '"status": "unresolved"' in prompt
    assert r.limitations_he == ["חסר מידע"]


def test_home_preserving_is_never_planned():
    a = run(analyze(FakeProvider({"LlmAnalysis": [analysis_out(gaps=[gap(category="safety", safety_food="home_preserving")])]})))
    with pytest.raises(ApiError) as e:
        run(plan(FakeProvider({"LlmPlan": [plan_out()]}), a))
    assert e.value.code == "unsafe_to_plan"


def test_structural_problem_triggers_one_repair_call():
    broken = plan_out()
    broken["steps"][0]["actions"].reverse()  # completing action not last
    provider = FakeProvider({"LlmPlan": [broken, plan_out()]})
    r = run(plan(provider, sample_analysis()))
    assert len(provider.calls) == 2
    assert "completing action must be last" in provider.calls[1]["parts"][-1].text
    assert r.plan.steps[0].actions[-1].completes_step


def test_two_invalid_plans_fail_cleanly():
    broken = plan_out()
    broken["steps"][0]["actions"].reverse()
    provider = FakeProvider({"LlmPlan": [broken, broken]})
    with pytest.raises(ApiError) as e:
        run(plan(provider, sample_analysis()))
    assert e.value.code == "invalid_ai_output"
    assert len(provider.calls) == 2


def test_malformed_analysis_gets_one_repair():
    provider = FakeProvider({"LlmAnalysis": [{"is_recipe": "maybe"}, analysis_out()]})
    a = run(analyze(provider))
    assert a.is_recipe and len(provider.calls) == 2


# ---- the AI call wrapper --------------------------------------------------

def test_rate_limit_is_never_retried():
    provider = FakeProvider({"LlmAnalysis": [LLMRateLimited("429")]})
    with pytest.raises(ApiError) as e:
        run(analyze(provider))
    assert e.value.code == "ai_rate_limited" and e.value.status == 429
    assert len(provider.calls) == 1


def test_temporary_failure_is_retried_once():
    provider = FakeProvider({"LlmAnalysis": [LLMUnavailable("500"), analysis_out()]})
    assert run(analyze(provider)).is_recipe
    assert len(provider.calls) == 2

    provider = FakeProvider({"LlmAnalysis": [LLMUnavailable("500"), LLMUnavailable("500")]})
    with pytest.raises(ApiError) as e:
        run(analyze(provider))
    assert e.value.code == "ai_unavailable" and len(provider.calls) == 2


def test_timeout():
    class Slow(FakeProvider):
        async def generate_structured(self, *a, **k):
            await asyncio.sleep(1)

    settings = Settings(_env_file=None, ai_model="m", ai_timeout_seconds=0.01)
    with pytest.raises(ApiError) as e:
        run(analyze_source(SourceInput(type="text", text="x"), provider=Slow(), settings=settings, budget=DailyBudget()))
    assert e.value.code == "timeout"


def test_daily_cap_counts_every_attempt():
    budget = DailyBudget()
    settings = Settings(_env_file=None, ai_model="m", ai_daily_call_cap=1)
    provider = FakeProvider({"LlmAnalysis": [LLMUnavailable("500"), analysis_out()]})
    with pytest.raises(ApiError) as e:
        run(analyze_source(SourceInput(type="text", text="x"), provider=provider, settings=settings, budget=budget))
    assert e.value.code == "daily_limit"
    assert budget.used == 1
