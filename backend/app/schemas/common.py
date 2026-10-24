from typing import Literal

from pydantic import BaseModel, ConfigDict

# Where a value came from. AI estimates are always "inferred" and shown as such;
# "reference" values come from the curated, cited food-safety table.
Provenance = Literal["original", "inferred", "answered", "user", "reference"]

# How sure an estimate is; used to order the "what was estimated" review.
Confidence = Literal["high", "medium", "low"]


class ContractModel(BaseModel):
    """Base for the shared JSON contract: unknown fields are rejected."""

    model_config = ConfigDict(extra="forbid")
