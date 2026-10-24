"""Remy (Phase 3B): guardrails and proposals with a fake provider (zero real AI calls)."""

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
from app.schemas.assistant import AssistantTurnRequest
from app.security import DailyBudget, SlidingWindowLimiter, get_ai_budget, get_limiter
from app.services.assistant import NO_CLAIMS_HE, OFF_TOPIC_LINE_HE, REDIRECT_HE, assistant_turn, speakable
from app.services.llm import LLMRateLimited, LLMUnavailable, get_llm_provider
from app.services.patching import apply_ops
from tests.fakes import FakeProvider

SHARED = Path(__file__).resolve().parents[2] / "shared" / "fixtures"
BUNDLE = json.loads((SHARED / "sample_recipe.json").read_text(encoding="utf-8"))
SETTINGS = Settings(_env_file=None, ai_provider="mock")
SNAPSHOT = {
    "current_step_id": "s3",
    "completed_step_ids": ["s1", "s2"],
    "active_timers": [{"id": "t1", "label_he": "עוף בתנור", "status": "running", "remaining_seconds": 600}],
}


def request(message="למה העוף לא משחים?", **kw) -> AssistantTurnRequest:
    return AssistantTurnRequest.model_validate(
        {"message_he": message, "recipe": BUNDLE["recipe"], "plan": BUNDLE["plan"], "snapshot": SNAPSHOT} | kw
    )


def turn(**kw) -> dict:
    base = {"intent": "cooking_question", "answer_he": "אפשר להעביר לפס העליון לכמה דקות.", "proposal_kind": "none"}
    return base | kw


def run(provider, req=None):
    return asyncio.run(assistant_turn(req or request(), provider=provider, settings=SETTINGS, budget=DailyBudget()))


def test_a_cooking_question_gets_an_answer_and_speech_text():
    r = run(FakeProvider({"LlmAssistantTurn": [turn(answer_he="🔥 אפשר להעביר לפס העליון לכמה דקות.")]}))
    assert r.intent == "cooking_question" and r.proposal is None
    assert r.speech_he == "אפשר להעביר לפס העליון לכמה דקות."  # no emoji for text-to-speech


@pytest.mark.parametrize("topic", ["מי ניצח במשחק?", "איך מתקנים מכונית?", "כתוב לי קוד בפייתון"])
def test_out_of_scope_gets_the_fixed_redirect_and_no_proposal(topic):
    provider = FakeProvider({"LlmAssistantTurn": [turn(intent="out_of_scope", answer_he="הנה תשובה", proposal_kind="extend_timer",
                                                        timer_id="t1", extra_seconds=60)]})
    r = run(provider, request(topic))
    assert r.answer_he == REDIRECT_HE and r.proposal is None


def test_mixed_messages_keep_the_cooking_part_and_add_one_line():
    r = run(FakeProvider({"LlmAssistantTurn": [turn(has_off_topic_part=True)]}))
    assert r.answer_he.endswith(OFF_TOPIC_LINE_HE) and r.answer_he.count(OFF_TOPIC_LINE_HE) == 1


def test_success_claims_are_rewritten_into_proposal_wording():
    r = run(FakeProvider({"LlmAssistantTurn": [turn(answer_he="הוספתי 2 דקות לטיימר.", proposal_kind="extend_timer",
                                                     proposal_summary_he="להוסיף 2 דקות לעוף", timer_id="t1", extra_seconds=120)]}))
    assert r.answer_he == "הצעה: להוסיף 2 דקות לעוף. אשרו כדי שזה יתבצע."
    assert (r.proposal.kind, r.proposal.timer_id, r.proposal.seconds) == ("extend_timer", "t1", 120)
    r = run(FakeProvider({"LlmAssistantTurn": [turn(answer_he="שיניתי את השלב.")]}))
    assert r.answer_he == NO_CLAIMS_HE


def test_an_invalid_proposal_is_dropped_not_repaired():
    provider = FakeProvider({"LlmAssistantTurn": [
        turn(proposal_kind="extend_timer", timer_id="t2", extra_seconds=60),  # rice isn't running
    ]})
    r = run(provider)
    assert r.proposal is None and r.answer_he and len(provider.calls) == 1  # one call per request


def test_substitution_proposal_reuses_validation_and_safety():
    sub = {"verdict": "changes_result", "explanation_he": "אפשר.", "replacement_name_he": "פילה סלמון",
           "omit": False, "effects_he": "טעם עדין.", "step_changes": [], "timer_changes": [{"timer_id": "t2", "seconds": 1000}],
           "safety_changes": [{"step_id": "s3", "safety_food": "fish"}]}
    r = run(FakeProvider({"LlmAssistantTurn": [turn(intent="change_request", proposal_kind="substitution",
                                                     substitution_target_kind="ingredient", substitution_target_id="i1",
                                                     substitution=sub, proposal_summary_he="להשתמש בסלמון")]}))
    assert r.proposal.kind == "patch"
    ops = [o.op for o in r.proposal.ops]
    assert "replace_ingredient" in ops and "set_step_safety" in ops
    # Notes for completed steps (s2 used the chicken) are dropped.
    assert all(getattr(o, "step_id", None) not in {"s1", "s2"} for o in r.proposal.ops)
    from app.schemas.plan import CookingPlan
    from app.schemas.recipe import Recipe
    _, plan = apply_ops(Recipe.model_validate(BUNDLE["recipe"]), CookingPlan.model_validate(BUNDLE["plan"]), r.proposal.ops)
    bake = {s.id: s for s in plan.steps}["s3"]
    assert bake.doneness_cue_he == REFERENCES["fish"].check_cue_he


def test_step_changes_may_not_touch_completed_steps():
    provider = FakeProvider({"LlmAssistantTurn": [turn(proposal_kind="step_change", step_changes=[{"step_id": "s1", "note_he": "x"}])]})
    assert run(provider).proposal is None
    provider = FakeProvider({"LlmAssistantTurn": [
        turn(proposal_kind="step_change", proposal_summary_he="להנמיך את האש", step_changes=[{"step_id": "s4", "note_he": "על אש נמוכה מאוד."}]),
    ]})
    assert run(provider).proposal.ops[0].step_id == "s4"


def test_output_that_does_not_match_the_schema_fails_clearly_after_one_call():
    provider = FakeProvider({"LlmAssistantTurn": [{"intent": "nonsense"}]})
    with pytest.raises(ApiError) as e:
        run(provider)
    assert e.value.code == "invalid_ai_output" and len(provider.calls) == 1


# ---- Gemini as a fallback interpreter (decision #59) --------------------------------------------


def test_a_conversational_request_becomes_a_validated_command():
    r = run(FakeProvider({"LlmAssistantTurn": [turn(
        intent="change_request", answer_he="מוסיף עוד קצת זמן לעוף.", command="extend_timer",
        command_timer_id="t1", command_seconds=240, user_uncertain=True,
    )]}), request("תן לעוף להתבשל עוד איזה ארבע דקות אם אפשר"))
    assert (r.command.action, r.command.timer_id, r.command.seconds, r.command.user_uncertain) == ("extend_timer", "t1", 240, True)
    assert r.proposal is None


@pytest.mark.parametrize("bad", [
    {"command": "extend_timer", "command_timer_id": "t9", "command_seconds": 60},  # no such running timer
    {"command": "extend_timer", "command_timer_id": "t1", "command_seconds": 99999},
    {"command": "complete_step", "command_step_id": "s1"},  # already completed
    {"command": "complete_step", "command_step_id": "s99"},
    {"command": "start_timer_action", "command_step_id": "s3", "command_action_id": "a2"},  # doesn't start a timer
    {"command": "pause_timer", "command_timer_id": "t9"},
])
def test_invalid_commands_are_dropped(bad):
    r = run(FakeProvider({"LlmAssistantTurn": [turn(**bad)]}))
    assert r.command is None


def test_unsupported_commands_fail_schema_validation():
    provider = FakeProvider({"LlmAssistantTurn": [turn(command="delete_everything")]})
    with pytest.raises(ApiError):
        run(provider)


def test_command_and_proposal_are_exclusive():
    r = run(FakeProvider({"LlmAssistantTurn": [turn(command="undo", proposal_kind="extend_timer", timer_id="t1", extra_seconds=60)]}))
    assert r.command.action == "undo" and r.proposal is None


@pytest.mark.parametrize("error, code", [
    (LLMUnavailable("down"), "ai_unavailable"),
    (LLMRateLimited(scope="minute", retry_after_seconds=20), "ai_rate_limited"),
    (LLMRateLimited(scope="day"), "ai_quota_exhausted"),
])
def test_errors_are_never_retried_for_remy(error, code):
    provider = FakeProvider({"LlmAssistantTurn": [error, turn()]})
    with pytest.raises(ApiError) as e:
        run(provider)
    assert e.value.code == code and len(provider.calls) == 1


def test_only_minimal_context_is_sent():
    provider = FakeProvider({"LlmAssistantTurn": [turn()]})
    run(provider)
    text = provider.calls[0]["parts"][0].text
    assert BUNDLE["recipe"]["source_steps"][0]["text"] not in text  # no source text
    assert '"completed": true' in text  # completed steps by title only
    s1_instruction = BUNDLE["plan"]["steps"][0]["instruction_he"]
    assert s1_instruction not in text


def test_data_blocks_carry_the_state_and_history():
    provider = FakeProvider({"LlmAssistantTurn": [turn()]})
    run(provider, request("ומה עכשיו?", history=[{"role": "user", "text": "שלום"}], modality="voice"))
    text = provider.calls[0]["parts"][0].text
    assert "<cooking_state>" in text and '"completed_step_ids": ["s1", "s2"]' in text
    assert "<modality>voice</modality>" in text and "שלום" in text


def test_speakable_strips_symbols():
    assert speakable("⏱ נשארו 5 דקות! 🎉") == "נשארו 5 דקות!"


def test_request_limits():
    with pytest.raises(Exception):
        request("א" * 501)
    with pytest.raises(Exception):
        request(history=[{"role": "user", "text": "x"}] * 7)


# ---- HTTP --------------------------------------------------------------------------------------

TOKEN = "test-app-token"


@pytest.fixture
def client():
    def make(provider):
        settings = Settings(_env_file=None, ai_provider="gemini", gemini_api_key=SecretStr("fake"), ai_model="m",
                            app_client_token=SecretStr(TOKEN), assistant_rate_limit_per_hour=3)
        app.dependency_overrides[get_settings] = lambda: settings
        app.dependency_overrides[get_llm_provider] = lambda: provider
        limiter, budget = SlidingWindowLimiter(), DailyBudget()
        app.dependency_overrides[get_limiter] = lambda: limiter
        app.dependency_overrides[get_ai_budget] = lambda: budget
        return TestClient(app)

    yield make
    app.dependency_overrides.clear()


def body():
    return {"message_he": "מה זה לקפל?", "recipe": BUNDLE["recipe"], "plan": BUNDLE["plan"], "snapshot": SNAPSHOT}


def test_endpoint_requires_the_token_and_has_its_own_limit(client):
    provider = FakeProvider({"LlmAssistantTurn": [turn()]})
    c = client(provider)
    assert c.post("/v1/assistant/turn", json=body()).status_code == 401
    for _ in range(3):
        assert c.post("/v1/assistant/turn", json=body(), headers={"X-App-Token": TOKEN}).status_code == 200
    r = c.post("/v1/assistant/turn", json=body(), headers={"X-App-Token": TOKEN})
    assert r.status_code == 429 and r.json()["error_code"] == "rate_limited"
    # Recipe imports keep their own limit.
    assert len(provider.calls) == 3
