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
