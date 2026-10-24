"""Recipe analysis: one structured AI call (plus at most one repair), converted into a
strict RecipeAnalysis. A plain function, reusable by any import path (and by future
recipe discovery): callers prepare the source, this does the rest.
"""

import json
from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Literal

from app.config import Settings
from app.errors import ApiError
from app.prompts import load_prompt
from app.schemas.analysis import RecipeAnalysis, RecipeSourceInfo
from app.schemas.llm import LlmAnalysis
from app.schemas.recipe import Equipment, Ingredient, Quantity, Recipe, Servings, SourceStep
from app.security import DailyBudget
from app.services import gap_resolution
from app.services.ai_calls import call_structured
from app.services.llm import ImagePart, LLMInvalidOutput, LLMProvider, TextPart
from app.services.validation.numbers import states_number

NOT_IN_SOURCE_HE = "לא נמצא בטקסט המקורי — סומן כהערכה"


@dataclass
class SourceInput:
    type: Literal["text", "image", "url"]
    text: str = ""  # pasted text, or the extracted page text for URLs
    image: bytes | None = None
    mime_type: str = "image/jpeg"
    url: str | None = None
    site_name: str | None = None
    title: str | None = None


async def analyze_source(
    src: SourceInput,
    *,
    provider: LLMProvider,
    settings: Settings,
    budget: DailyBudget,
) -> RecipeAnalysis:
    system = load_prompt("analyze_recipe")
    parts: list[TextPart | ImagePart]
    if src.type == "image":
        parts = [TextPart("Extract the recipe from this photo."), ImagePart(src.image or b"", src.mime_type)]
    else:
        parts = [TextPart(f"<recipe_source>\n{src.text}\n</recipe_source>")]

    llm = await _call_with_repair(provider, system, parts, settings, budget)
    source_text = llm.transcription if src.type == "image" else src.text
    info = RecipeSourceInfo(
        type=src.type,
        url=src.url,
        site_name=src.site_name,
        title=src.title,
        retrieved_at=datetime.now(UTC).replace(microsecond=0).isoformat(),
    )
    if not llm.is_recipe:
        return RecipeAnalysis(
            is_recipe=False,
            not_recipe_reason_he=llm.not_recipe_reason_he,
            source=info,
            source_text=source_text,
        )
    try:
        recipe = _recipe_from(llm, source_text)
    except ValueError as e:
        raise ApiError(502, "invalid_ai_output", "recipe conversion failed") from e
    ladder = gap_resolution.resolve(llm.gaps)
    return RecipeAnalysis(
        is_recipe=True,
        source=info,
        source_text=source_text,
        recipe=recipe,
        questions=ladder.questions,
        gaps=ladder.gaps,
        sources=ladder.sources,
        assumptions_he=llm.assumptions_he,
    )


async def _call_with_repair(provider, system, parts, settings, budget) -> LlmAnalysis:
    kwargs = dict(
        provider=provider, system=system, schema=LlmAnalysis,
        model=settings.effective_parse_model, settings=settings, budget=budget,
    )
    try:
        return await call_structured(parts=parts, purpose="analyze", **kwargs)
    except LLMInvalidOutput as first:
        repair = parts + [TextPart(_repair_note(first))]
        try:
            return await call_structured(parts=repair, purpose="analyze_repair", **kwargs)
        except LLMInvalidOutput as e:
            raise ApiError(502, "invalid_ai_output", "analysis did not match the schema") from e


def _repair_note(e: LLMInvalidOutput) -> str:
    return (
        "Your previous answer did not match the required schema. Problems:\n"
        f"{e.problems}\nReturn corrected JSON only."
    )


def _recipe_from(llm: LlmAnalysis, source_text: str) -> Recipe:
    ingredients = []
    for i in llm.ingredients:
        q = None
        if i.quantity is not None:
            stated = i.quantity.stated_in_source and (
                i.quantity.amount is None or states_number(source_text, i.quantity.amount)
            )
            q = Quantity(
                amount=i.quantity.amount,
                amount_max=i.quantity.amount_max,
                unit=i.quantity.unit,
                display=i.quantity.display,
                provenance="original" if stated else "inferred",
                note_he=None if stated else NOT_IN_SOURCE_HE,
            )
        ingredients.append(Ingredient(
            id=i.id, name=i.name, quantity=q, preparation=i.preparation,
            group=i.group, optional=i.optional,
        ))
    servings = None
    if llm.servings_amount and llm.servings_amount > 0 and llm.servings_unit:
        stated = llm.servings_stated and states_number(source_text, llm.servings_amount)
        servings = Servings(
            amount=llm.servings_amount,
            unit=llm.servings_unit,
            provenance="original" if stated else "inferred",
        )
    recipe = Recipe(
        title=llm.title or "מתכון",
        description=llm.description,
        servings=servings,
        ingredients=ingredients,
        equipment=[
            Equipment(id=e.id, name=e.name, provenance="original" if e.stated_in_source else "inferred")
            for e in llm.equipment
        ],
        source_steps=[SourceStep(id=s.id, text=s.text) for s in llm.source_steps],
    )
    for ids in ([i.id for i in recipe.ingredients], [e.id for e in recipe.equipment], [s.id for s in recipe.source_steps]):
        if len(set(ids)) != len(ids):
            raise ValueError("duplicate ids")
    return recipe


def analysis_json_for_prompt(analysis: RecipeAnalysis) -> str:
    return json.dumps(analysis.recipe.model_dump(mode="json") if analysis.recipe else {}, ensure_ascii=False)
