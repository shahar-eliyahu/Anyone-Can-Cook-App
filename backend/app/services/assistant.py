"""Remy, the cooking assistant (Phase 3B, docs/PLAN.md): one AI call per question.

The app answers simple commands itself ("הבא", "כמה זמן נשאר", "תוסיף 5 דקות"); this
service handles questions and change requests. It answers, and may propose ONE change:
extend a running timer, a substitution, or a change to steps not started yet. Deterministic
guardrails around the model (docs/PLAN.md §5.4):

- cooking scope only: out-of-scope messages get a fixed redirect, mixed messages a fixed line;
- the model never claims it changed anything (it can't): such answers are replaced;
- proposals are validated like 3A substitutions (patch operations, plan checks, food safety
  recomputed from the curated table) and may only touch steps that aren't completed;
- answers are capped; a plain speech version is always returned for future text-to-speech.
"""

import json
import re

from pydantic import ValidationError

from app.config import Settings
from app.errors import ApiError
from app.prompts import load_prompt
from app.schemas.assistant import AssistantCommand, AssistantProposal, AssistantTurnRequest, AssistantTurnResponse
from app.schemas.llm import LlmAssistantTurn
from app.schemas.substitution import AddStepNote, SetStepText, SetTimerSeconds, SubstituteRequest
from app.security import DailyBudget
from app.services.ai_calls import call_structured
from app.services.llm import LLMInvalidOutput, LLMProvider, TextPart
from app.services.patching import apply_ops
from app.services.substitution import validated_substitution
from app.services.validation.logic import plan_problems

REDIRECT_HE = (
    "אני רמי, עוזר הבישול של לבשל כל אחד יכול. אני כאן כדי לעזור במתכונים, במצרכים ובתהליך הבישול. "
    "במה אוכל לעזור לך במטבח?"
)
OFF_TOPIC_LINE_HE = "לגבי שאר השאלה, אני כאן רק לעזרה במטבח."
NO_CLAIMS_HE = "אני יכול להציע שינויים, והם מתבצעים רק אחרי שתאשרו אותם באפליקציה."
MAX_ANSWER_CHARS = 600
MAX_SPEECH_CHARS = 300

# Past-tense "I did it" claims; Remy only proposes (the app executes after approval).
_CLAIMS = re.compile(r"(הוספתי|הפעלתי|שיניתי|עדכנתי|הארכתי|סימנתי|החלפתי|ביטלתי|העברתי|הגדרתי|כיוונתי|קבעתי)")
_NOT_SPEAKABLE = re.compile(r"[^\w\s֐-׿.,:;!?\"'()\-–—%°/]")


def speakable(text: str) -> str:
    """Plain text for text-to-speech: no emoji or symbols, short."""
    plain = re.sub(r"\s+", " ", _NOT_SPEAKABLE.sub(" ", text)).strip()
    return plain[:MAX_SPEECH_CHARS]


def _completed(req: AssistantTurnRequest) -> set[str]:
    ids = req.snapshot.get("completed_step_ids") or []
    return {i for i in ids if isinstance(i, str)}


def _active_timers(req: AssistantTurnRequest) -> set[str]:
    timers = req.snapshot.get("active_timers") or []
    return {t.get("id") for t in timers if isinstance(t, dict) and isinstance(t.get("id"), str)}


def _pending_only(ops: list, req: AssistantTurnRequest) -> list:
    """Drops operations on completed steps (the app re-checks against its live state)."""
    done = _completed(req)
    return [o for o in ops if getattr(o, "step_id", None) not in done]


def _proposal(llm: LlmAssistantTurn, req: AssistantTurnRequest) -> AssistantProposal | None:
    summary = (llm.proposal_summary_he or "").strip()[:300]
    match llm.proposal_kind:
        case "none":
            return None
        case "extend_timer":
            if llm.timer_id not in _active_timers(req):
                raise ValueError("extend_timer needs a timer_id from snapshot.active_timers")
            seconds = llm.extra_seconds or 0
            if not 0 < seconds <= 3600:
                raise ValueError("extra_seconds must be 1..3600")
            return AssistantProposal(kind="extend_timer", summary_he=summary or "להאריך את הטיימר",
                                     timer_id=llm.timer_id, seconds=seconds)
        case "substitution":
            if llm.substitution is None or not llm.substitution_target_kind or not llm.substitution_target_id:
                raise ValueError("substitution needs substitution, substitution_target_kind and substitution_target_id")
            sub_req = SubstituteRequest(
                recipe=req.recipe, plan=req.plan,
                target={"kind": llm.substitution_target_kind, "id": llm.substitution_target_id},
                user_note_he=req.message_he,
            )
            result = validated_substitution(llm.substitution, sub_req)
            ops = _pending_only(result.ops, req)
            if not ops:
                return None
            name = result.replacement_name_he or "תחליף"
            return AssistantProposal(kind="patch", summary_he=summary or f"להשתמש ב{name}", ops=ops)
        case "step_change":
            ops: list = []
            for c in llm.step_changes:
                if c.instruction_he and c.instruction_he.strip():
                    ops.append(SetStepText(op="set_step_text", step_id=c.step_id, instruction_he=c.instruction_he.strip()))
                if c.note_he and c.note_he.strip():
                    ops.append(AddStepNote(op="add_step_note", step_id=c.step_id, note_he=c.note_he.strip()))
            for t in llm.timer_changes:
                ops.append(SetTimerSeconds(op="set_timer_seconds", timer_id=t.timer_id, seconds=t.seconds,
                                           max_seconds=t.max_seconds))
            done = _completed(req)
            if any(getattr(o, "step_id", None) in done for o in ops):
                raise ValueError("step changes may only touch steps that are not completed")
            if not ops:
                return None
            recipe, plan = apply_ops(req.recipe, req.plan, ops)
            problems = plan_problems(plan, recipe)
            if problems:
                raise ValueError("; ".join(problems))
            return AssistantProposal(kind="patch", summary_he=summary or "שינוי בשלבים הבאים", ops=ops)
    return None


def _command(llm: LlmAssistantTurn, req: AssistantTurnRequest) -> AssistantCommand | None:
    """The interpreted command, or None when it's missing, unsupported or refers to things
    that don't exist (it is dropped, never repaired: one call per request)."""
    if llm.command == "none":
        return None
    steps = {s.id: s for s in req.plan.steps}
    timers = _active_timers(req)
    match llm.command:
        case "complete_step":
            if llm.command_step_id not in steps or llm.command_step_id in _completed(req):
                return None
        case "start_timer_action":
            step = steps.get(llm.command_step_id or "")
            action = next((a for a in step.actions if a.id == llm.command_action_id), None) if step else None
            if action is None or action.starts_timer is None:
                return None
        case "extend_timer":
            if llm.command_timer_id not in timers or not 0 < (llm.command_seconds or 0) <= 3600:
                return None
        case "pause_timer" | "resume_timer":
            if llm.command_timer_id is not None and llm.command_timer_id not in timers:
                return None
    return AssistantCommand(
        action=llm.command,
        step_id=llm.command_step_id,
        action_id=llm.command_action_id,
        timer_id=llm.command_timer_id,
        seconds=llm.command_seconds if llm.command == "extend_timer" else None,
        confidence=llm.command_confidence,
        user_uncertain=llm.user_uncertain,
    )


def _guarded(llm: LlmAssistantTurn, req: AssistantTurnRequest) -> AssistantTurnResponse:
    if llm.intent == "out_of_scope":
        return AssistantTurnResponse(intent="out_of_scope", answer_he=REDIRECT_HE, speech_he=speakable(REDIRECT_HE))
    command = _command(llm, req)
    try:
        proposal = None if command is not None else _proposal(llm, req)
    except (ValueError, ValidationError):
        proposal = None  # an invalid proposal is dropped, not repaired (one call per request)
    answer = llm.answer_he.strip()
    if _CLAIMS.search(answer):
        answer = f"הצעה: {proposal.summary_he}. אשרו כדי שזה יתבצע." if proposal else NO_CLAIMS_HE
    if llm.has_off_topic_part:
        answer = f"{answer}\n{OFF_TOPIC_LINE_HE}"
    answer = answer[:MAX_ANSWER_CHARS]
    speech = speakable(llm.speech_he if llm.speech_he and not _CLAIMS.search(llm.speech_he) else answer)
    return AssistantTurnResponse(
        intent=llm.intent, answer_he=answer, speech_he=speech, proposal=proposal, command=command,
        safety_note_he=llm.safety_note_he,
    )


def _prompt_data(req: AssistantTurnRequest) -> str:
    """Only the context Remy needs: ingredients and equipment (no source text), full detail
    for steps not completed, titles for completed ones."""
    recipe = json.dumps(
        {
            "title": req.recipe.title,
            "ingredients": [i.model_dump(mode="json", exclude_none=True) for i in req.recipe.ingredients],
            "equipment": [e.model_dump(mode="json", exclude_none=True) for e in req.recipe.equipment],
        },
        ensure_ascii=False,
    )
    done = _completed(req)
    steps = [
        {"id": s.id, "title": s.title, "completed": True}
        if s.id in done
        else {
            "id": s.id, "title": s.title, "instruction_he": s.instruction_he,
            "notes_he": s.notes_he, "doneness_cue_he": s.doneness_cue_he, "help_he": s.help_he,
            "warnings_he": s.warnings_he,
            "actions": [{"id": a.id, "label_he": a.label_he, "starts_timer": a.starts_timer} for a in s.actions],
            "ingredient_uses": [u.model_dump(mode="json", exclude_none=True) for u in s.ingredient_uses],
            "timers": [{"id": t.id, "label_he": t.label_he, "seconds": t.seconds} for t in s.timers],
        }
        for s in req.plan.steps
    ]
    history = [h.model_dump() for h in req.history]
    return (
        f"<recipe>\n{recipe}\n</recipe>\n"
        f"<plan_steps>\n{json.dumps(steps, ensure_ascii=False)}\n</plan_steps>\n"
        f"<cooking_state>\n{json.dumps(req.snapshot, ensure_ascii=False)}\n</cooking_state>\n"
        f"<conversation>\n{json.dumps(history, ensure_ascii=False)}\n</conversation>\n"
        f"<modality>{req.modality}</modality>\n"
        f"<cook_message>\n{req.message_he}\n</cook_message>"
    )


async def assistant_turn(
    req: AssistantTurnRequest,
    *,
    provider: LLMProvider,
    settings: Settings,
    budget: DailyBudget,
) -> AssistantTurnResponse:
    # Exactly one call per request (decision #59): no repair call, no retry on errors.
    try:
        llm = await call_structured(
            provider, parts=[TextPart(_prompt_data(req))], system=load_prompt("assistant"),
            schema=LlmAssistantTurn, model=settings.effective_chat_model, settings=settings,
            budget=budget, purpose="assistant", max_attempts=1,
        )
    except LLMInvalidOutput as e:
        raise ApiError(502, "invalid_ai_output", "assistant answer did not match the schema") from e
    return _guarded(llm, req)

