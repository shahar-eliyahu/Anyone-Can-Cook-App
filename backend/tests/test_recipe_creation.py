"""Creating a recipe with Remy (stage recipe_creation) with a fake provider: zero real AI calls."""

import asyncio
import json
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from app.config import Settings, get_settings
from app.errors import ApiError
from app.main import app
from app.schemas import CookingPlan, Recipe
from app.schemas.creation import RecipeCreationRequest
from app.security import DailyBudget, SlidingWindowLimiter, get_ai_budget, get_limiter
from app.services.assistant import REDIRECT_HE
from app.services.llm import get_llm_provider
from app.services.planning import plan_recipe
from app.services.recipe_creation import (
    INVALID_RECIPE_HE,
    UNSAFE_RECIPE_HE,
    create_turn,
    recipe_text,
)
from app.services.validation.logic import plan_problems
from tests.fakes import FakeProvider, mock_json

SETTINGS = Settings(_env_file=None, ai_provider="mock")
CATALOG = Path(__file__).resolve().parents[2] / "app" / "assets" / "recipes" / "catalog.json"


def cake(**kw) -> dict:
    base = {
        "intent": "recipe",
        "answer_he": "הנה עוגת שוקולד פשוטה. אפשר לעבור עליה לפני ששומרים.",
        "title": "עוגת שוקולד",
        "description": "עוגה בקערה אחת.",
        "servings_amount": 12,
        "servings_unit": "פרוסות",
        "total_minutes": 55,
        "ingredients": [
            {"id": "a", "name": "קמח", "amount": 1.5, "unit": "כוסות", "display": "1½ כוסות"},
            {"id": "b", "name": "ביצים", "amount": 3, "display": "3"},
            {"id": "c", "name": "מלח", "display": "קורט"},
        ],
        "equipment": [{"id": "x", "name": "קערה"}, {"id": "y", "name": "תבנית"}, {"id": "z", "name": "קערה"}],
        "steps": [
            {"id": "1", "text": "מערבבים קמח וביצים.", "ingredient_ids": ["a", "b"]},
            {"id": "2", "text": "אופים 35 דקות ב-180 מעלות.", "ingredient_ids": []},
        ],
        "tips_he": ["אפשר להוסיף שוקולד צ'יפס."],
        "preferences": {"servings": 12},
    }
    return base | kw


def request(message="בא לי עוגת שוקולד", **kw) -> RecipeCreationRequest:
    return RecipeCreationRequest.model_validate({"message_he": message} | kw)


def run(provider, req=None):
    return asyncio.run(create_turn(req or request(), provider=provider, settings=SETTINGS, budget=DailyBudget()))


def test_a_specific_request_returns_a_strict_recipe_draft():
    r = run(FakeProvider({"LlmRecipeCreation": [cake()]}))
    assert r.kind == "recipe"
    recipe = r.analysis.recipe
    assert r.analysis.source.type == "remy" and r.analysis.is_recipe
    assert [i.id for i in recipe.ingredients] == ["i1", "i2", "i3"]  # fresh ids
    assert [e.name for e in recipe.equipment] == ["קערה", "תבנית"]  # duplicates dropped
    assert [s.id for s in recipe.source_steps] == ["src1", "src2"]
    assert recipe.ingredients[2].quantity.display == "קורט" and recipe.ingredients[2].quantity.amount is None
    assert r.total_minutes == 55 and r.tips_he == ["אפשר להוסיף שוקולד צ'יפס."]
    assert "1½ כוסות" in r.analysis.source_text and "אופים 35 דקות" in r.analysis.source_text
    assert r.preferences.servings == 12


def test_a_broad_request_gets_a_few_options_and_nothing_else():
    out = {"intent": "options", "answer_he": "יש לי כמה רעיונות.", "options_he": ["עוגת שוקולד", "עוגת שוקולד", "עוגת וניל", "עוגת לימון",
                                                                                  "עוגת גזר", "עוגת תפוזים"]}
    r = run(FakeProvider({"LlmRecipeCreation": [out]}), request("בא לי עוגה"))
    assert r.kind == "options" and r.analysis is None
    assert r.options_he == ["עוגת שוקולד", "עוגת וניל", "עוגת לימון", "עוגת גזר"]  # unique, at most 4


def test_one_option_is_just_an_answer():
    out = {"intent": "options", "answer_he": "אולי עוגת שוקולד?", "options_he": ["עוגת שוקולד"]}
    assert run(FakeProvider({"LlmRecipeCreation": [out]})).kind == "answer"


def test_out_of_scope_gets_the_fixed_redirect():
    r = run(FakeProvider({"LlmRecipeCreation": [cake(intent="out_of_scope")]}), request("מי ניצח במשחק?"))
    assert r.kind == "answer" and r.answer_he == REDIRECT_HE and r.analysis is None


@pytest.mark.parametrize("change", [
    {"ingredients": []},
    {"steps": []},
    {"title": "  "},
    {"ingredients": [{"id": "a", "name": "קמח", "amount": 0, "display": "0 כוסות"}]},
    {"ingredients": [{"id": "a", "name": "קמח", "amount": 50000, "unit": "כוסות", "display": "50000 כוסות"}]},
    # a step uses an ingredient that isn't listed
    {"steps": [{"id": "1", "text": "מערבבים קמח וסוכר.", "ingredient_ids": ["a", "sugar"]}]},
])
def test_incomplete_or_impossible_recipes_are_rejected(change):
    r = run(FakeProvider({"LlmRecipeCreation": [cake(**change)]}))
    assert r.kind == "answer" and r.analysis is None and r.answer_he == INVALID_RECIPE_HE


def test_an_impossible_range_is_dropped_not_kept():
    out = cake(ingredients=[{"id": "a", "name": "קמח", "amount": 2, "amount_max": 1, "unit": "כוסות", "display": "2 כוסות"}],
               steps=[{"id": "1", "text": "אופים 30 דקות.", "ingredient_ids": ["a"]}])
    q = run(FakeProvider({"LlmRecipeCreation": [out]})).analysis.recipe.ingredients[0].quantity
    assert q.amount == 2 and q.amount_max is None


@pytest.mark.parametrize("steps", [
    [{"id": "1", "text": "צורבים את הסטייק דקה מכל צד ומגישים מדיום רייר."}],
    [{"id": "1", "text": "מגישים את חזה העוף כשהוא עדיין ורוד באמצע."}],
    [{"id": "1", "text": "פורסים את חזה העוף דק ומגישים עם רוטב."}],  # never cooked
])
def test_meat_or_poultry_that_is_not_cooked_through_is_refused(steps):
    out = cake(title="עוף", ingredients=[{"id": "a", "name": "חזה עוף", "amount": 500, "unit": "גרם", "display": "500 גרם"},
                                         {"id": "b", "name": "סטייק אנטריקוט", "amount": 1, "display": "1"}], steps=steps)
    r = run(FakeProvider({"LlmRecipeCreation": [out]}))
    assert r.kind == "answer" and r.analysis is None and r.answer_he == UNSAFE_RECIPE_HE


def test_cooked_poultry_is_fine():
    out = cake(title="חזה עוף במחבת", ingredients=[{"id": "a", "name": "חזה עוף", "amount": 500, "unit": "גרם", "display": "500 גרם"}],
               steps=[{"id": "1", "text": "צורבים במחבת 5 דקות מכל צד, עד שאין ורוד במרכז.", "ingredient_ids": ["a"]}])
    assert run(FakeProvider({"LlmRecipeCreation": [out]})).kind == "recipe"


def test_malformed_output_is_an_error_and_never_retried():
    provider = FakeProvider({"LlmRecipeCreation": [{"intent": "recipe"}]})  # missing answer_he
    with pytest.raises(ApiError) as e:
        run(provider)
    assert e.value.code == "invalid_ai_output"
    assert len(provider.calls) == 1


def test_only_this_conversation_goes_to_the_model():
    provider = FakeProvider({"LlmRecipeCreation": [cake()]})
    run(provider, request(
        "בלי ביצים",
        preferences={"servings": 4, "diet_he": ["צמחוני"]},
        history=[{"role": "user", "text": "בא לי עוגה"}, {"role": "assistant", "text": "הנה עוגה"}],
        current_recipe={"title": "עוגת שוקולד", "ingredients_he": ["קמח: 1½ כוסות"], "steps_he": ["אופים."]},
    ))
    text = provider.calls[0]["parts"][0].text
    assert "<stage>recipe_creation</stage>" in text
    assert '"servings":4.0' in text and "צמחוני" in text
    assert "הנה עוגה" in text and "<current_recipe>" in text and "בלי ביצים" in text
    assert len(provider.calls) == 1


def test_preferences_keep_what_the_cook_said_before():
    out = cake(preferences={"diet_he": ["בלי חלב"]})
    r = run(FakeProvider({"LlmRecipeCreation": [out]}), request(preferences={"servings": 4, "diet_he": ["צמחוני"]}))
    assert r.preferences.servings == 4
    assert r.preferences.diet_he == ["בלי חלב", "צמחוני"]


def test_request_limits():
    with pytest.raises(ValueError):
        request(history=[{"role": "user", "text": "א"}] * 7)
    with pytest.raises(ValueError):
        request("א" * 501)
    with pytest.raises(ValueError):
        request(preferences={"servings": 500})


def test_a_created_recipe_plans_through_the_usual_pipeline():
    """The draft goes to /plan like any import; its source text is rendered from the (possibly
    edited) recipe, so the plan's provenance checks see the recipe's own numbers."""
    analysis_llm = mock_json("sample_analysis.json")
    out = {
        "intent": "recipe", "answer_he": "הנה.", "title": analysis_llm["title"], "servings_amount": 4, "servings_unit": "מנות",
        "ingredients": [{"id": i["id"], "name": i["name"], **{k: v for k, v in (i.get("quantity") or {}).items() if k != "stated_in_source"}}
                        for i in analysis_llm["ingredients"]],
        "equipment": [{"id": e["id"], "name": e["name"]} for e in analysis_llm["equipment"]],
        "steps": [{"id": s["id"], "text": s["text"]} for s in analysis_llm["source_steps"]],
    }
    created = run(FakeProvider({"LlmRecipeCreation": [out]}))
    edited = created.analysis.model_copy(update={"source_text": "ערוך"})
    provider = FakeProvider({"LlmPlan": [mock_json("sample_plan.json")]})
    result = asyncio.run(plan_recipe(edited, provider=provider, settings=SETTINGS, budget=DailyBudget()))
    assert result.plan.steps
    sent = provider.calls[0]["parts"][0].text
    assert recipe_text(edited.recipe) in sent and "ערוך" not in sent


def test_the_endpoint_needs_no_state_and_validates_input():
    provider = FakeProvider({"LlmRecipeCreation": [cake()]})
    app.dependency_overrides[get_llm_provider] = lambda: provider
    app.dependency_overrides[get_settings] = lambda: SETTINGS
    app.dependency_overrides[get_ai_budget] = lambda: DailyBudget()
    app.dependency_overrides[get_limiter] = lambda: SlidingWindowLimiter()
    try:
        client = TestClient(app)
        ok = client.post("/v1/assistant/create", json={"stage": "recipe_creation", "message_he": "עוגת שוקולד"})
        assert ok.status_code == 200 and ok.json()["kind"] == "recipe"
        assert client.post("/v1/assistant/create", json={"stage": "cooking", "message_he": "א"}).status_code == 422
        assert client.post("/v1/assistant/create", json={"message_he": ""}).status_code == 422
    finally:
        app.dependency_overrides.clear()


def test_the_dev_mock_offers_options_then_a_recipe_its_plan_fits():
    from app.services.llm.mock import MockProvider, sample_fixtures

    mock = MockProvider(sample_fixtures())
    options = asyncio.run(create_turn(request("בא לי"), provider=mock, settings=SETTINGS, budget=DailyBudget()))
    assert options.kind == "options" and len(options.options_he) == 3
    made = asyncio.run(create_turn(request(options.options_he[0]), provider=mock, settings=SETTINGS, budget=DailyBudget()))
    assert made.kind == "recipe"
    plan = asyncio.run(plan_recipe(made.analysis, provider=mock, settings=SETTINGS, budget=DailyBudget()))
    assert not plan_problems(plan.plan, made.analysis.recipe)


def test_the_bundled_catalog_matches_the_contract():
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    assert 20 <= len(catalog["recipes"]) <= 30
    for entry in catalog["recipes"]:
        recipe = Recipe.model_validate(entry["recipe"])
        plan = CookingPlan.model_validate(entry["plan"])
        assert not plan_problems(plan, recipe), entry["id"]
