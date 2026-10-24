"""The original recipe (ingredients, equipment, source text), stored separately from the plan."""

from typing import Literal

from pydantic import Field

from app.schemas.common import Confidence, ContractModel, Provenance


class Quantity(ContractModel):
    amount: float | None = None
    amount_max: float | None = None
    unit: str | None = None
    display: str
    provenance: Provenance
    confidence: Confidence | None = None
    source_ids: list[str] = []
    note_he: str | None = None


class Ingredient(ContractModel):
    id: str
    name: str
    quantity: Quantity | None = None
    preparation: str | None = None
    group: str | None = None
    optional: bool = False


class Equipment(ContractModel):
    id: str
    name: str
    provenance: Provenance = "original"


class SourceStep(ContractModel):
    id: str
    text: str


class Servings(ContractModel):
    amount: float = Field(gt=0)
    unit: str
    provenance: Provenance


class Recipe(ContractModel):
    schema_version: Literal[1] = 1
    title: str
    description: str | None = None
    servings: Servings | None = None
    ingredients: list[Ingredient]
    equipment: list[Equipment] = []
    source_steps: list[SourceStep] = []
