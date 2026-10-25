"""Creating a recipe with Remy (stage recipe_creation, docs/DECISIONS.md #85–#87): one AI call per
message, no repair and no retry (like Remy's other turns).

Remy may answer, offer a few dishes to choose from, or return one complete recipe. A recipe is
never trusted as it comes: it is rebuilt here with fresh ids, sane quantities and step links to
ingredients that exist, and rejected when it is incomplete or unsafe (meat or poultry served raw,
or never cooked). What survives becomes a RecipeAnalysis with source type "remy"; the app stores
it as a draft, the cook reviews it, and only saving it plans it through the usual /plan pipeline
(with its food-safety checks).
"""

import json
import re
from datetime import UTC, datetime

from app.config import Settings
from app.errors import ApiError
from app.prompts import load_prompt
from app.schemas.analysis import RecipeAnalysis, RecipeSourceInfo
from app.schemas.creation import CreationPreferences, RecipeCreationRequest, RecipeCreationResponse
from app.schemas.llm import LlmCreationPreferences, LlmRecipeCreation
from app.schemas.recipe import Equipment, Ingredient, Quantity, Recipe, Servings, SourceStep
from app.security import DailyBudget
from app.services.ai_calls import call_structured
from app.services.assistant import MAX_ANSWER_CHARS, REDIRECT_HE, speakable
from app.services.llm import LLMInvalidOutput, LLMProvider, TextPart

INVALID_RECIPE_HE = "לא הצלחתי להרכיב מתכון שלם הפעם. אפשר לנסות שוב, או לתאר במילים אחרות מה בא לכם."
UNSAFE_RECIPE_HE = "לא אציע מתכון שבו בשר או עוף לא מתבשלים עד הסוף. אפשר לבקש גרסה מבושלת היטב."

MAX_OPTIONS = 4
MAX_OPTION_CHARS = 60
MAX_INGREDIENTS = 40
MAX_EQUIPMENT = 15
MAX_STEPS = 25
MAX_TIPS = 3
MAX_AMOUNT = 10_000
MAX_SERVINGS = 50

# Meat and poultry must be cooked through: never "נא"/"מדיום", and some step must heat them.
_MEAT = re.compile(r"(עוף|פרגית|הודו|כרעיים|כרעי|שוקיים|כנפיים|חזה|בשר|טחון|קציצ|המבורגר|נקניק|סטייק|אנטריקוט|צלעות|כבד)")
_RAW = re.compile(r"(חצי נא|(?<![א-ת])נא(?![א-ת])|לא מבושל|מדיום|רייר|ורוד באמצע|ורוד מבפנים|ללא בישול|בלי לבשל)")
_HEAT = re.compile(
    r"(תנור|אופ|אפי|מחבת|טיגון|מטגנ|טגנ|צול|צלי|מבשל|בישול|בשלו|לבשל|סיר|רותח|רתיחה|גריל|מקפיצ|הקפיצ|הקפצ|אידוי|מאדים|צרבו|צורבים|חום)"
)


class CreationProblem(ValueError):
    def __init__(self, message_he: str, reason: str) -> None:
        super().__init__(reason)
        self.message_he = message_he


def recipe_text(recipe: Recipe) -> str:
    """The recipe as plain text: the source text of a Remy recipe (so the plan's provenance checks
    see its own numbers), rendered again whenever the recipe was edited."""
    lines = [recipe.title]
    if recipe.description:
        lines.append(recipe.description)
    if recipe.servings:
        lines.append(f"{recipe.servings.amount:g} {recipe.servings.unit}")
    lines.append("מצרכים:")
    for i in recipe.ingredients:
        q = f": {i.quantity.display}" if i.quantity and i.quantity.display else ""
        lines.append(f"- {i.name}{q}")
    if recipe.equipment:
        lines.append("ציוד: " + ", ".join(e.name for e in recipe.equipment))
    lines.append("אופן ההכנה:")
    lines += [f"{n}. {s.text}" for n, s in enumerate(recipe.source_steps, 1)]
    return "\n".join(lines)


def unsafe_problem(recipe: Recipe, tips: list[str] = ()) -> str | None:
    if not any(_MEAT.search(i.name) for i in recipe.ingredients if not i.omitted):
        return None
    text = " ".join([*(s.text for s in recipe.source_steps), *tips])
    if _RAW.search(text):
        return "meat or poultry served undercooked"
    if not _HEAT.search(text):
        return "meat or poultry is never cooked"
    return None


def _clean(text: str | None, limit: int) -> str:
    return re.sub(r"\s+", " ", text or "").strip()[:limit]


def build_recipe(llm: LlmRecipeCreation) -> tuple[Recipe, list[str]]:
    """The model's recipe rebuilt strictly; raises CreationProblem when it can't be cooked as is."""
    title = _clean(llm.title, 80)
    ingredients: list[Ingredient] = []
    ids: dict[str, str] = {}
    for raw in llm.ingredients[:MAX_INGREDIENTS]:
        name = _clean(raw.name, 80)
        if not name:
            continue
        amount = raw.amount
        if amount is not None and not 0 < amount <= MAX_AMOUNT:
            raise CreationProblem(INVALID_RECIPE_HE, f"impossible amount for {name}")
        amount_max = raw.amount_max if amount is not None and raw.amount_max and raw.amount_max > amount else None
        display = _clean(raw.display, 40) or (f"{amount:g} {raw.unit or ''}".strip() if amount is not None else "")
        new_id = f"i{len(ingredients) + 1}"
        ids.setdefault(raw.id, new_id)
        ingredients.append(Ingredient(
            id=new_id,
            name=name,
            quantity=Quantity(amount=amount, amount_max=amount_max, unit=_clean(raw.unit, 20) or None,
                              display=display, provenance="original") if display else None,
            preparation=_clean(raw.preparation, 80) or None,
            optional=raw.optional,
        ))
    equipment = [
        Equipment(id=f"e{n}", name=name)
        for n, name in enumerate(dict.fromkeys(_clean(e.name, 60) for e in llm.equipment if _clean(e.name, 60)), 1)
    ][:MAX_EQUIPMENT]
    steps = [SourceStep(id=f"src{n}", text=t) for n, t in enumerate([_clean(s.text, 400) for s in llm.steps if _clean(s.text, 400)], 1)]
    if not title or not ingredients or not steps:
        raise CreationProblem(INVALID_RECIPE_HE, "title, ingredients and steps are required")
    if len(llm.steps) > MAX_STEPS:
        raise CreationProblem(INVALID_RECIPE_HE, "too many steps")
    # A step that uses an ingredient missing from the list means the list is incomplete (an
    # ingredient no step mentions is fine, e.g. salt "to taste").
    if any(i not in ids for s in llm.steps for i in s.ingredient_ids):
        raise CreationProblem(INVALID_RECIPE_HE, "a step uses an ingredient that is not listed")
    servings = None
    if llm.servings_amount and 0 < llm.servings_amount <= MAX_SERVINGS:
        servings = Servings(amount=llm.servings_amount, unit=_clean(llm.servings_unit, 20) or "מנות", provenance="original")
    recipe = Recipe(
        title=title,
        description=_clean(llm.description, 300) or None,
        servings=servings,
        ingredients=ingredients,
        equipment=equipment,
        source_steps=steps,
    )
    tips = [t for t in (_clean(x, 200) for x in llm.tips_he) if t][:MAX_TIPS]
    if reason := unsafe_problem(recipe, tips):
        raise CreationProblem(UNSAFE_RECIPE_HE, reason)
    return recipe, tips


def _preferences(llm: LlmCreationPreferences, req: RecipeCreationRequest) -> CreationPreferences:
    """What the cook asked for so far: the model's update, falling back to what the app sent."""
    known = req.preferences

    def items(new: list[str], old: list[str], limit: int) -> list[str]:
        merged = [t for t in (_clean(x, 60) for x in [*new, *old]) if t]
        return list(dict.fromkeys(merged))[:limit]

    servings = llm.servings if llm.servings and 0 < llm.servings <= MAX_SERVINGS else known.servings
    minutes = llm.max_minutes if llm.max_minutes and 0 < llm.max_minutes <= 1440 else known.max_minutes
    return CreationPreferences(
        servings=servings,
        max_minutes=minutes,
        diet_he=items(llm.diet_he, known.diet_he, 6),
        available_ingredients_he=items(llm.available_ingredients_he, known.available_ingredients_he, 20),
        avoid_he=items(llm.avoid_he, known.avoid_he, 10),
    )


def _answer(text: str, preferences: CreationPreferences, speech: str | None = None) -> RecipeCreationResponse:
    text = text.strip()[:MAX_ANSWER_CHARS]
    return RecipeCreationResponse(kind="answer", answer_he=text, speech_he=speakable(speech or text), preferences=preferences)


def guarded(llm: LlmRecipeCreation, req: RecipeCreationRequest) -> RecipeCreationResponse:
    if llm.intent == "out_of_scope":
        return _answer(REDIRECT_HE, req.preferences)
    preferences = _preferences(llm.preferences, req)
    speech = llm.speech_he
    if llm.intent == "options":
        options = list(dict.fromkeys(o for o in (_clean(x, MAX_OPTION_CHARS) for x in llm.options_he) if o))[:MAX_OPTIONS]
        if len(options) < 2:
            return _answer(llm.answer_he, preferences, speech)
        answer = llm.answer_he.strip()[:MAX_ANSWER_CHARS]
        return RecipeCreationResponse(
            kind="options", answer_he=answer, speech_he=speakable(speech or answer), options_he=options,
            preferences=preferences,
        )
    if llm.intent != "recipe":
        return _answer(llm.answer_he, preferences, speech)
    try:
        recipe, tips = build_recipe(llm)
    except CreationProblem as e:
        return _answer(e.message_he, preferences)
    analysis = RecipeAnalysis(
        is_recipe=True,
        source=RecipeSourceInfo(type="remy", retrieved_at=datetime.now(UTC).replace(microsecond=0).isoformat()),
        source_text=recipe_text(recipe),
        recipe=recipe,
    )
    minutes = llm.total_minutes if llm.total_minutes and 0 < llm.total_minutes <= 1440 else None
    answer = llm.answer_he.strip()[:MAX_ANSWER_CHARS] or recipe.title
    return RecipeCreationResponse(
        kind="recipe", answer_he=answer, speech_he=speakable(speech or answer), preferences=preferences,
        analysis=analysis, total_minutes=minutes, tips_he=tips,
    )


def _prompt_data(req: RecipeCreationRequest) -> str:
    """Only this creation conversation: no other recipes, no app state."""
    data = (
        f"<stage>{req.stage}</stage>\n"
        f"<preferences>\n{req.preferences.model_dump_json(exclude_defaults=True)}\n</preferences>\n"
        f"<conversation>\n{json.dumps([h.model_dump() for h in req.history], ensure_ascii=False)}\n</conversation>\n"
    )
    if req.current_recipe is not None:
        data += f"<current_recipe>\n{req.current_recipe.model_dump_json()}\n</current_recipe>\n"
    return data + f"<modality>{req.modality}</modality>\n<cook_message>\n{req.message_he}\n</cook_message>"


async def create_turn(
    req: RecipeCreationRequest,
    *,
    provider: LLMProvider,
    settings: Settings,
    budget: DailyBudget,
) -> RecipeCreationResponse:
    try:
        llm = await call_structured(
            provider, parts=[TextPart(_prompt_data(req))], system=load_prompt("create_recipe"),
            schema=LlmRecipeCreation, model=settings.effective_chat_model, settings=settings,
            budget=budget, purpose="create_recipe", max_attempts=1,
        )
    except LLMInvalidOutput as e:
        raise ApiError(502, "invalid_ai_output", "recipe creation did not match the schema") from e
    return guarded(llm, req)
