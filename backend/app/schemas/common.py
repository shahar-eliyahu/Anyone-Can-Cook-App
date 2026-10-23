from typing import Literal

from pydantic import BaseModel, ConfigDict

# Where a value came from. AI estimates are always "inferred" and shown as such.
Provenance = Literal["original", "inferred", "answered", "user"]


class ContractModel(BaseModel):
    """Base for the shared JSON contract: unknown fields are rejected."""

    model_config = ConfigDict(extra="forbid")
