"""Write the shared JSON Schemas from the Pydantic models (the source of truth).

Run from backend/:  .venv/Scripts/python -m scripts.export_schemas
"""

import json
from pathlib import Path

from app.schemas import CookingPlan, Recipe

SCHEMA_DIR = Path(__file__).resolve().parents[2] / "shared" / "schema"
SCHEMAS = {"recipe.schema.json": Recipe, "cooking_plan.schema.json": CookingPlan}


def render(model) -> str:
    return json.dumps(model.model_json_schema(), ensure_ascii=False, indent=2, sort_keys=True) + "\n"


def main() -> None:
    SCHEMA_DIR.mkdir(parents=True, exist_ok=True)
    for name, model in SCHEMAS.items():
        (SCHEMA_DIR / name).write_text(render(model), encoding="utf-8")
        print(f"wrote {SCHEMA_DIR / name}")


if __name__ == "__main__":
    main()
