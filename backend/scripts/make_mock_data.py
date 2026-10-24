"""Builds the mock provider's canned model outputs from shared/fixtures/sample_recipe.json.

Run from backend/:  .venv/Scripts/python -m scripts.make_mock_data
A test fails if the files are stale.
"""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "shared" / "fixtures" / "sample_recipe.json"
OUT_DIR = Path(__file__).resolve().parents[1] / "app" / "services" / "llm" / "mock_data"


def build() -> dict[str, dict]:
    sample = json.loads(FIXTURE.read_text(encoding="utf-8"))
    recipe, plan = sample["recipe"], sample["plan"]

    analysis = {
        "is_recipe": True,
        "title": recipe["title"],
        "description": recipe.get("description"),
        "servings_amount": recipe["servings"]["amount"],
        "servings_unit": recipe["servings"]["unit"],
        "servings_stated": True,
        "ingredients": [
            {
                "id": i["id"],
                "name": i["name"],
                "quantity": None if "quantity" not in i else {
                    "amount": i["quantity"].get("amount"),
                    "unit": i["quantity"].get("unit"),
                    "display": i["quantity"]["display"],
                    "stated_in_source": i["quantity"]["provenance"] == "original",
                },
            }
            for i in recipe["ingredients"]
        ],
        "equipment": [
            {"id": e["id"], "name": e["name"], "stated_in_source": e["provenance"] == "original"}
            for e in recipe["equipment"]
        ],
        "source_steps": recipe["source_steps"],
        "transcription": "",
        "gaps": [
            {
                "id": "g1", "field": "rice_cook_time", "category": "outcome",
                "description_he": "המתכון לא ציין כמה זמן לבשל את האורז.",
                "estimate_display": "כ-18 דקות", "confidence": "high",
            },
            {
                "id": "g2", "field": "chicken_doneness", "category": "safety", "safety_food": "poultry",
                "description_he": "יש לוודא שהעוף עשוי לפני ההגשה.",
            },
        ],
        "assumptions_he": ["הנחנו תנור רגיל ולא טורבו."],
    }

    def timer(t: dict) -> dict:
        return {k: v for k, v in t.items() if k not in ("source_ids",)}

    steps = []
    for s in plan["steps"]:
        uses = s.get("ingredient_uses") or [{"ingredient_id": i} for i in s.get("ingredient_ids", [])]
        steps.append({
            **{k: v for k, v in s.items() if k not in ("ingredient_ids", "ingredient_uses", "timers", "actions")},
            "ingredient_uses": uses,
            "actions": [{k: v for k, v in a.items() if k != "confirm_policy"} for a in s["actions"]],
            "timers": [timer(t) for t in s.get("timers", [])],
            "safety_food": "poultry" if s["id"] == "s3" else "none",
        })
    prep = []
    for p in plan["prep_tasks"]:
        surface = p.get("surface", {})
        prep.append({
            **{k: v for k, v in p.items() if k not in ("surface", "confirm_policy", "timer")},
            "surface_at_start": bool(surface.get("at_start")),
            "surface_with_step": surface.get("with_step"),
            **({"timer": timer(p["timer"])} if "timer" in p else {}),
        })
    llm_plan = {"steps": steps, "prep_tasks": prep, "advance_notice_he": plan.get("advance_notice_he")}

    source_text = "\n".join(
        [recipe["title"], *(f"{i['name']} {i.get('quantity', {}).get('display', '')}" for i in recipe["ingredients"])]
        + [s["text"] for s in recipe["source_steps"]]
    )
    return {"sample_analysis.json": analysis, "sample_plan.json": llm_plan, "sample_source.json": {"text": source_text}}


def render(data: dict) -> str:
    return json.dumps(data, ensure_ascii=False, indent=2) + "\n"


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, data in build().items():
        (OUT_DIR / name).write_text(render(data), encoding="utf-8")
        print(f"wrote {OUT_DIR / name}")


if __name__ == "__main__":
    main()
