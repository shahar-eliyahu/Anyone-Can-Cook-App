"""Applies substitution patch operations to a recipe and plan (pure, deterministic).

Mirrors `app/lib/features/prepare/patch.dart`; both are checked against
`shared/fixtures/patch_example.json`. Unknown ids raise ValueError.
"""

from app.schemas.plan import CookingPlan
from app.schemas.recipe import Recipe
from app.schemas.substitution import PatchOp


def _find(items: list[dict], item_id: str, kind: str) -> dict:
    for item in items:
        if item["id"] == item_id:
            return item
    raise ValueError(f"unknown {kind} {item_id}")


def _timer(plan: dict, timer_id: str) -> dict:
    for s in plan["steps"]:
        for t in s.get("timers", []):
            if t["id"] == timer_id:
                return t
    for p in plan.get("prep_tasks", []):
        if (p.get("timer") or {}).get("id") == timer_id:
            return p["timer"]
    raise ValueError(f"unknown timer {timer_id}")


def apply_ops(recipe: Recipe, plan: CookingPlan, ops: list[PatchOp]) -> tuple[Recipe, CookingPlan]:
    r = recipe.model_dump(mode="json")
    p = plan.model_dump(mode="json")
    for op in ops:
        match op.op:
            case "replace_ingredient":
                ing = _find(r["ingredients"], op.ingredient_id, "ingredient")
                ing["substituted_for"] = ing.get("substituted_for") or ing["name"]
                ing["name"] = op.name
                ing["omitted"] = False
                if op.quantity is not None:
                    ing["quantity"] = op.quantity.model_dump(mode="json")
            case "omit_ingredient":
                ing = _find(r["ingredients"], op.ingredient_id, "ingredient")
                ing["omitted"] = True
                for s in p["steps"]:
                    s["ingredient_uses"] = [u for u in s.get("ingredient_uses", []) if u["ingredient_id"] != op.ingredient_id]
                    s["ingredient_ids"] = [i for i in s.get("ingredient_ids", []) if i != op.ingredient_id]
            case "replace_equipment":
                eq = _find(r["equipment"], op.equipment_id, "equipment")
                eq["substituted_for"] = eq.get("substituted_for") or eq["name"]
                eq["name"] = op.name
                eq["omitted"] = False
            case "omit_equipment":
                eq = _find(r["equipment"], op.equipment_id, "equipment")
                eq["omitted"] = True
                for s in p["steps"]:
                    s["equipment_ids"] = [e for e in s.get("equipment_ids", []) if e != op.equipment_id]
            case "set_ingredient_use":
                _find(r["ingredients"], op.ingredient_id, "ingredient")
                step = _find(p["steps"], op.step_id, "step")
                quantity = None if op.quantity is None else op.quantity.model_dump(mode="json")
                uses = step.setdefault("ingredient_uses", [])
                for u in uses:
                    if u["ingredient_id"] == op.ingredient_id:
                        u["quantity"] = quantity
                        break
                else:
                    uses.append({"ingredient_id": op.ingredient_id, "quantity": quantity})
                if op.ingredient_id not in step.setdefault("ingredient_ids", []):
                    step["ingredient_ids"].append(op.ingredient_id)
            case "set_step_text":
                _find(p["steps"], op.step_id, "step")["instruction_he"] = op.instruction_he
            case "add_step_note":
                notes = _find(p["steps"], op.step_id, "step").setdefault("notes_he", [])
                if op.note_he not in notes:
                    notes.append(op.note_he)
            case "set_timer_seconds":
                t = _timer(p, op.timer_id)
                t["seconds"] = op.seconds
                t["max_seconds"] = op.max_seconds if op.max_seconds and op.max_seconds > op.seconds else None
                t["provenance"] = "inferred"
            case "set_step_safety":
                step = _find(p["steps"], op.step_id, "step")
                step["warnings_he"] = list(op.warnings_he)
                step["doneness_cue_he"] = op.doneness_cue_he
                for a in step["actions"]:
                    if a.get("completes_step"):
                        a["confirm_policy"] = "always_ask" if op.confirm_completion else "auto_ok"
    return Recipe.model_validate(r), CookingPlan.model_validate(p)
