"""The resolution ladder for missing information (docs/PLAN.md, Phase 2 design):
recipe context → curated food-safety reference → model estimate → a question only
when genuinely needed. Decided in code, not by the model.
"""

from dataclasses import dataclass, field

from app.knowledge.food_safety import SOURCES, UNSCHEDULABLE_HE, reference_for
from app.schemas.analysis import Answer, Gap, Question, ReferenceSource
from app.schemas.llm import LlmGap

_QUESTION_ORDER = {"safety": 0, "outcome": 1, "equipment": 2, "preference": 3, "minor": 4}


@dataclass
class LadderResult:
    gaps: list[Gap] = field(default_factory=list)
    questions: list[Question] = field(default_factory=list)
    sources: list[ReferenceSource] = field(default_factory=list)


def resolve(llm_gaps: list[LlmGap]) -> LadderResult:
    result = LadderResult()
    source_ids: set[str] = set()
    for g in llm_gaps:
        resolution, note, question = _decide(g)
        question_id = None
        if question is not None:
            question_id = f"q{len(result.questions) + 1}"
            result.questions.append(question.model_copy(update={"id": question_id}))
        if resolution == "reference":
            source_ids.update(reference_for(g.safety_food).source_ids)  # type: ignore[union-attr]
        result.gaps.append(Gap(
            id=g.id,
            field=g.field,
            category=g.category,
            resolution=resolution,
            question_id=question_id,
            note_he=note,
        ))
    result.questions.sort(key=lambda q: (not q.required, _QUESTION_ORDER[q.category]))
    result.sources = [SOURCES[s] for s in sorted(source_ids)]
    return result


def _decide(g: LlmGap) -> tuple[str, str | None, Question | None]:
    if g.category == "safety":
        if g.safety_food == "home_preserving":
            return "unresolved", UNSCHEDULABLE_HE, None
        ref = reference_for(g.safety_food)
        if ref is not None:
            return "reference", ref.check_cue_he, None
        # The food type is unknown, so no reference applies: ask (required).
        if g.question_he:
            return "question", g.description_he, _question(g, required=True)
        return "unresolved", g.description_he, None
    if g.category == "minor":
        return ("estimate" if g.estimate_display else "context"), g.estimate_display, None
    wants_answer = g.suggest_asking and bool(g.question_he)
    if g.category == "outcome":
        # Ask only when the estimate is weak and the answer would change the plan.
        if wants_answer and g.confidence in (None, "low"):
            return "question", g.description_he, _question(g)
        return "estimate", g.estimate_display, None
    if wants_answer:  # equipment or a preference that changes the steps
        return "question", g.description_he, _question(g)
    return "estimate", g.estimate_display, None


def _question(g: LlmGap, required: bool = False) -> Question:
    kind = g.question_kind or ("choice" if g.options else "text")
    return Question(
        id="",
        text_he=g.question_he or g.description_he,
        why_he=g.why_he or g.description_he,
        kind=kind,
        options=g.options if kind == "choice" else [],
        unit_he=g.unit_he,
        category=g.category,
        required=required,
        affects=[g.field],
    )


@dataclass(frozen=True)
class Fact:
    """A resolved gap, handed to the plan call as data."""

    field: str
    status: str  # answered | reference | estimate | unresolved
    value_he: str | None
    note_he: str | None


def facts_for_plan(gaps: list[Gap], answers: list[Answer], llm_estimates: dict[str, str] | None = None) -> list[Fact]:
    """Applies the cook's answers. "לא יודע/ת" (or no answer) never re-asks: a
    safety gap stays unresolved (no invented value), others become estimates."""
    by_question = {a.question_id: a for a in answers}
    estimates = llm_estimates or {}
    facts: list[Fact] = []
    for g in gaps:
        if g.resolution == "question":
            a = by_question.get(g.question_id or "")
            if a is not None and not a.unknown and a.value:
                facts.append(Fact(g.field, "answered", a.value, None))
            elif g.category == "safety":
                facts.append(Fact(g.field, "unresolved", None, g.note_he))
            else:
                facts.append(Fact(g.field, "estimate", estimates.get(g.id), "המשתמש לא ידע; יש להעריך ולסמן כהערכה"))
        elif g.resolution == "reference":
            facts.append(Fact(g.field, "reference", g.note_he, None))
        elif g.resolution in ("estimate", "context"):
            facts.append(Fact(g.field, "estimate", g.note_he, None))
        else:
            facts.append(Fact(g.field, "unresolved", None, g.note_he))
    return facts
