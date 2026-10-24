import json
from pathlib import Path

import pytest
from pydantic import ValidationError

from app.schemas import CookingPlan, Recipe
from scripts.export_schemas import SCHEMA_DIR, SCHEMAS, render

FIXTURE = Path(__file__).resolve().parents[2] / "shared" / "fixtures" / "sample_recipe.json"


@pytest.fixture
def sample():
    return json.loads(FIXTURE.read_text(encoding="utf-8"))


def test_sample_fixture_matches_contract(sample):
    recipe = Recipe.model_validate(sample["recipe"])
    plan = CookingPlan.model_validate(sample["plan"])
    assert recipe.title
    assert [s.id for s in plan.steps] == ["s1", "s2", "s3", "s4", "s5"]


def test_bread_fixture_uses_phase2_fields():
    data = json.loads((FIXTURE.parent / "sample_bread.json").read_text(encoding="utf-8"))
    plan = CookingPlan.model_validate(data["plan"])
    proof = plan.steps[1].timers[0]
    assert (proof.seconds, proof.max_seconds, proof.wait_kind) == (3600, 5400, "proof")
    assert plan.prep_tasks[0].remind_before_needed
    assert plan.steps[0].ingredient_uses[0].quantity.display == "500 גרם"


def test_phase1_plan_without_new_fields_is_still_valid(sample):
    # Strip every Phase 2 field: what a Phase 1 app stored must still validate.
    phase2_timer_fields = {
        "wait_kind", "wait_info_he", "check_cue_he", "suggest_during",
        "meanwhile_tips_he", "recheck_seconds", "max_seconds", "confidence", "source_ids",
    }
    for step in sample["plan"]["steps"]:
        for t in step.get("timers", []):
            for f in phase2_timer_fields:
                t.pop(f, None)
    plan = CookingPlan.model_validate(sample["plan"])
    assert plan.schema_version == 1


def test_range_end_must_follow_check_time(sample):
    sample["plan"]["steps"][2]["timers"][0]["max_seconds"] = 2700
    with pytest.raises(ValidationError):
        CookingPlan.model_validate(sample["plan"])


def test_at_most_three_meanwhile_tips(sample):
    sample["plan"]["steps"][2]["timers"][0]["meanwhile_tips_he"] = ["a", "b", "c", "d"]
    with pytest.raises(ValidationError):
        CookingPlan.model_validate(sample["plan"])


@pytest.mark.parametrize("name", SCHEMAS)
def test_exported_json_schemas_are_up_to_date(name):
    exported = (SCHEMA_DIR / name).read_text(encoding="utf-8")
    assert exported == render(SCHEMAS[name]), "run: python -m scripts.export_schemas"


def test_unknown_fields_are_rejected(sample):
    sample["plan"]["steps"][0]["surprise"] = True
    with pytest.raises(ValidationError):
        CookingPlan.model_validate(sample["plan"])


def test_action_cannot_carry_a_timer_duration(sample):
    # Durations live only on plan timers, never on actions.
    sample["plan"]["steps"][2]["actions"][0]["seconds"] = 60
    with pytest.raises(ValidationError):
        CookingPlan.model_validate(sample["plan"])


def test_timer_bounds(sample):
    sample["plan"]["steps"][2]["timers"][0]["seconds"] = 0
    with pytest.raises(ValidationError):
        CookingPlan.model_validate(sample["plan"])


def test_provenance_values_are_restricted(sample):
    sample["plan"]["steps"][2]["timers"][0]["provenance"] = "guessed"
    with pytest.raises(ValidationError):
        CookingPlan.model_validate(sample["plan"])
