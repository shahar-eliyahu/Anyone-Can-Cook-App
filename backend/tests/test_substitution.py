"""Phase 3A substitutions: patch semantics, the AI answer → validated operations, food safety,
and the endpoint — all with a fake provider (zero real AI calls)."""

import asyncio
import json
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from pydantic import SecretStr

from app.config import Settings, get_settings
from app.errors import ApiError
from app.knowledge.food_safety import REFERENCES
from app.main import app
from app.schemas.plan import CookingPlan
from app.schemas.recipe import Recipe
from app.schemas.substitution import SubstituteRequest, SubstituteResponse
from app.security import DailyBudget, SlidingWindowLimiter, get_ai_budget, get_limiter
from app.services.llm import get_llm_provider
from app.services.patching import apply_ops
from app.services.substitution import suggest_substitution
from tests.fakes import FakeProvider

SHARED = Path(__file__).resolve().parents[2] / "shared" / "fixtures"
BUNDLE = json.loads((SHARED / "sample_recipe.json").read_text(encoding="utf-8"))
RECIPE = Recipe.model_validate(BUNDLE["recipe"])
PLAN = CookingPlan.model_validate(BUNDLE["plan"])
SETTINGS = Settings(_env_file=None, ai_provider="mock")


def request(kind="ingredient", target_id="i3", note=None) -> SubstituteRequest:
    return SubstituteRequest(recipe=RECIPE, plan=PLAN, target={"kind": kind, "id": target_id}, user_note_he=note)


def answer(**kw) -> dict:
    base = {"verdict": "works", "explanation_he": "אפשר.", "replacement_name_he": "שמן קנולה", "omit": False,
            "quantity": None, "effects_he": None, "step_changes": [], "timer_changes": [], "safety_changes": []}
    return base | kw


def run(provider, req=None) -> SubstituteResponse:
    return asyncio.run(suggest_substitution(req or request(), provider=provider, settings=SETTINGS, budget=DailyBudget()))


def applied(resp: SubstituteResponse, req=None):
    req = req or request()
    return apply_ops(req.recipe, req.plan, resp.ops)


def test_shared_patch_fixture_semantics():
    from app.schemas.substitution import SubstituteResponse as R

    fixture = json.loads((SHARED / "patch_example.json").read_text(encoding="utf-8"))
    ops = R(verdict="works", explanation_he="x", ops=fixture["ops"]).ops
    recipe, plan = apply_ops(RECIPE, PLAN, ops)
    exp = fixture["expect"]
    ings = {i.id: i for i in recipe.ingredients}
    for iid, e in exp["ingredients"].items():
        i = ings[iid]
        assert (i.name, i.substituted_for, i.omitted, i.quantity.display) == (
            e["name"], e["substituted_for"], e["omitted"], e["quantity_display"])
    eqs = {e.id: e for e in recipe.equipment}
    for eid, e in exp["equipment"].items():
        assert (eqs[eid].name, eqs[eid].substituted_for, eqs[eid].omitted) == (e["name"], e["substituted_for"], e["omitted"])
    steps = {s.id: s for s in plan.steps}
    s1, s2, s3 = steps["s1"], steps["s2"], steps["s3"]
    assert {u.ingredient_id: u.quantity.display for u in s1.ingredient_uses} == exp["steps"]["s1"]["use_displays"]
    assert s1.notes_he == exp["steps"]["s1"]["notes_he"] and s1.equipment_ids == exp["steps"]["s1"]["equipment_ids"]
    assert s2.instruction_he == exp["steps"]["s2"]["instruction_he"] and s2.ingredient_ids == exp["steps"]["s2"]["ingredient_ids"]
    assert s3.warnings_he == exp["steps"]["s3"]["warnings_he"] and s3.doneness_cue_he == exp["steps"]["s3"]["doneness_cue_he"]
    assert s3.actions[-1].confirm_policy == exp["steps"]["s3"]["completing_policy"]
    t2 = plan.steps[3].timers[0]
    assert (t2.seconds, t2.max_seconds, t2.provenance) == (1200, None, "inferred")


def test_works_answer_becomes_operations_with_notes_for_every_step_that_uses_it():
    provider = FakeProvider({"LlmSubstitution": [answer(
        quantity={"amount": 3, "unit": "כפות", "display": "3 כפות", "stated_in_source": False},
        step_changes=[{"step_id": "s1", "use_display": "1 כף", "use_amount": 1, "use_unit": "כף"}],
    )]})
    resp = run(provider)
    assert resp.verdict == "works" and resp.replacement_name_he == "שמן קנולה"
    recipe, plan = applied(resp)
    oil = next(i for i in recipe.ingredients if i.id == "i3")
    assert (oil.name, oil.substituted_for, oil.quantity.display, oil.quantity.provenance) == (
        "שמן קנולה", "שמן זית", "3 כפות", "inferred")
    steps = {s.id: s for s in plan.steps}
    assert steps["s1"].notes_he == ["במקום שמן זית: שמן קנולה"]
    assert steps["s2"].notes_he == ["במקום שמן זית: שמן קנולה"]  # also uses the oil
    assert steps["s4"].notes_he == []
    assert len(provider.calls) == 1


def test_equipment_alternative_rewrites_the_step_instead_of_noting_it():
    provider = FakeProvider({"LlmSubstitution": [answer(
        replacement_name_he="מחבת עמוקה עם מכסה",
        step_changes=[{"step_id": "s4", "instruction_he": "בשלו את האורז במחבת עמוקה מכוסה על אש קטנה."}],
    )]})
    resp = run(provider, request("equipment", "e2"))
    _, plan = applied(resp, request("equipment", "e2"))
    rice = {s.id: s for s in plan.steps}["s4"]
    assert rice.instruction_he.startswith("בשלו את האורז במחבת")
    assert rice.notes_he == []


@pytest.mark.parametrize("verdict", ["no_substitute", "not_recommended"])
def test_no_reliable_substitute_is_explained_and_changes_nothing(verdict):
    provider = FakeProvider({"LlmSubstitution": [answer(verdict=verdict, explanation_he="בלי שמרים הלחם לא יתפח.")]})
    resp = run(provider)
    assert resp.verdict == verdict and resp.ops == [] and "שמרים" in resp.explanation_he


def test_optional_item_can_be_omitted_with_a_note():
    provider = FakeProvider({"LlmSubstitution": [answer(omit=True, replacement_name_he=None)]})
    req = request("ingredient", "i6")
    resp = run(provider, req)
    recipe, plan = applied(resp, req)
    assert next(i for i in recipe.ingredients if i.id == "i6").omitted
    assert {s.id: s for s in plan.steps}["s2"].notes_he == ["בלי פלפל שחור"]


def test_changing_the_food_type_recomputes_safety_from_the_table():
    poultry_cue = REFERENCES["poultry"].check_cue_he
    provider = FakeProvider({"LlmSubstitution": [answer(
        verdict="changes_result", replacement_name_he="פילה סלמון", effects_he="טעם עדין יותר.",
        timer_changes=[{"timer_id": "t1", "seconds": 1200}],
        safety_changes=[{"step_id": "s3", "safety_food": "fish"}],
    )]})
    req = request("ingredient", "i1")
    resp = run(provider, req)
    _, plan = applied(resp, req)
    bake = {s.id: s for s in plan.steps}["s3"]
    assert poultry_cue not in bake.warnings_he
    assert bake.doneness_cue_he == REFERENCES["fish"].check_cue_he
    assert bake.actions[-1].confirm_policy == "auto_ok"
    assert bake.timers[0].seconds == 1200


def test_a_high_risk_replacement_keeps_the_cooks_confirmation():
    provider = FakeProvider({"LlmSubstitution": [answer(
        replacement_name_he="חזה עוף", safety_changes=[{"step_id": "s3", "safety_food": "poultry"}],
    )]})
    req = request("ingredient", "i1")
    _, plan = applied(run(provider, req), req)
    bake = {s.id: s for s in plan.steps}["s3"]
    assert REFERENCES["poultry"].check_cue_he in bake.warnings_he
    assert bake.actions[-1].confirm_policy == "always_ask"


@pytest.mark.parametrize("bad", [
    {"step_changes": [{"step_id": "s99", "note_he": "x"}]},
    {"timer_changes": [{"timer_id": "t1", "seconds": 0}]},
    {"replacement_name_he": None},
])
def test_invalid_answers_get_one_repair_call(bad):
    provider = FakeProvider({"LlmSubstitution": [answer(**bad), answer()]})
    resp = run(provider)
    assert resp.verdict == "works" and len(provider.calls) == 2
    assert "problems" in provider.calls[1]["parts"][-1].text


def test_answers_that_stay_invalid_fail_clearly_after_one_repair():
    provider = FakeProvider({"LlmSubstitution": [answer(step_changes=[{"step_id": "s99", "note_he": "x"}])]})
    with pytest.raises(ApiError) as e:
        run(provider)
    assert e.value.code == "invalid_ai_output" and len(provider.calls) == 2


def test_unknown_target_is_rejected_before_any_ai_call():
    provider = FakeProvider({"LlmSubstitution": [answer()]})
    with pytest.raises(ApiError) as e:
        run(provider, request("ingredient", "i99"))
    assert e.value.code == "invalid_request" and provider.calls == []


# ---- HTTP --------------------------------------------------------------------------------------

TOKEN = "test-app-token"


@pytest.fixture
def client():
    def make(provider):
        settings = Settings(_env_file=None, ai_provider="gemini", gemini_api_key=SecretStr("fake"),
                            ai_model="test-model", app_client_token=SecretStr(TOKEN))
        app.dependency_overrides[get_settings] = lambda: settings
        app.dependency_overrides[get_llm_provider] = lambda: provider
        limiter, budget = SlidingWindowLimiter(), DailyBudget()
        app.dependency_overrides[get_limiter] = lambda: limiter
        app.dependency_overrides[get_ai_budget] = lambda: budget
        return TestClient(app)

    yield make
    app.dependency_overrides.clear()


def body(target_id="i3"):
    return {"recipe": BUNDLE["recipe"], "plan": BUNDLE["plan"], "target": {"kind": "ingredient", "id": target_id},
            "user_note_he": "יש לי שמן קנולה"}


def test_endpoint_requires_the_app_token(client):
    provider = FakeProvider({"LlmSubstitution": [answer()]})
    c = client(provider)
    assert c.post("/v1/recipes/substitute", json=body()).status_code == 401
    assert provider.calls == []


def test_endpoint_returns_validated_operations(client):
    provider = FakeProvider({"LlmSubstitution": [answer()]})
    r = client(provider).post("/v1/recipes/substitute", json=body(), headers={"X-App-Token": TOKEN})
    assert r.status_code == 200, r.text
    data = r.json()
    assert data["verdict"] == "works"
    assert [o["op"] for o in data["ops"]] == ["replace_ingredient", "add_step_note", "add_step_note"]
    assert "יש לי שמן קנולה" in provider.calls[0]["parts"][0].text  # the cook's note reaches the model


def test_endpoint_rejects_an_unknown_target_and_respects_rate_limits(client):
    provider = FakeProvider({"LlmSubstitution": [answer()]})
    c = client(provider)
    r = c.post("/v1/recipes/substitute", json=body("i99"), headers={"X-App-Token": TOKEN})
    assert r.status_code == 422 and r.json()["error_code"] == "invalid_request"
    for _ in range(9):
        c.post("/v1/recipes/substitute", json=body(), headers={"X-App-Token": TOKEN})
    r = c.post("/v1/recipes/substitute", json=body(), headers={"X-App-Token": TOKEN})
    assert r.status_code == 429 and r.json()["error_code"] == "rate_limited"
