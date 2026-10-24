"""Remy, the cooking assistant (Phase 3B): request/response of POST /v1/assistant/turn.

The server answers and may PROPOSE one change; it never changes anything itself. The app
validates every proposal against the live cooking state, asks the cook to approve it, and
executes it through its deterministic engine. The same request serves typed text and
(Phase 3D) speech: `modality` only tunes the answer length.
"""

from typing import Any, Literal

from pydantic import Field, field_validator

from app.schemas.common import ContractModel
from app.schemas.plan import CookingPlan
from app.schemas.recipe import Recipe
from app.schemas.substitution import PatchOp

MAX_SNAPSHOT_CHARS = 20_000


class HistoryItem(ContractModel):
    role: Literal["user", "assistant"]
    text: str = Field(max_length=600)


class AssistantTurnRequest(ContractModel):
    message_he: str = Field(min_length=1, max_length=500)
    modality: Literal["text", "voice"] = "text"
    recipe: Recipe
    plan: CookingPlan
    # The app's engine snapshot: current/completed steps, available actions, active timers.
    snapshot: dict[str, Any] = {}
    history: list[HistoryItem] = Field(default=[], max_length=6)

    @field_validator("snapshot")
    @classmethod
    def _small_snapshot(cls, v: dict[str, Any]) -> dict[str, Any]:
        import json

        if len(json.dumps(v, ensure_ascii=False)) > MAX_SNAPSHOT_CHARS:
            raise ValueError("snapshot too large")
        return v


class AssistantProposal(ContractModel):
    kind: Literal["extend_timer", "patch"]
    summary_he: str = Field(max_length=300)
    timer_id: str | None = None
    seconds: int | None = Field(default=None, gt=0, le=3600)
    ops: list[PatchOp] = []


class AssistantTurnResponse(ContractModel):
    intent: Literal["cooking_question", "session_question", "change_request", "out_of_scope", "unclear"]
    answer_he: str
    speech_he: str
    proposal: AssistantProposal | None = None
    safety_note_he: str | None = None
