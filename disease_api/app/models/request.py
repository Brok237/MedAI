"""
app/models/request.py
─────────────────────
Pydantic v2 request schema for the /predict endpoint.
"""

from pydantic import BaseModel, field_validator, model_validator
from typing import List
from app.utils.symptom_utils import _FEATURE_SET


class PredictRequest(BaseModel):
    symptoms: List[str]

    # ── Validators ────────────────────────────────────────────────────────

    @field_validator("symptoms", mode="before")
    @classmethod
    def must_not_be_empty(cls, v: list) -> list:
        if not v:
            raise ValueError("symptoms list must not be empty.")
        return v

    @field_validator("symptoms", mode="after")
    @classmethod
    def lowercase_and_strip(cls, v: list[str]) -> list[str]:
        """Auto-lowercase and strip whitespace for every symptom."""
        return [s.strip().lower().replace(" ", "_") for s in v]

    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "symptoms": ["headache", "high_fever", "vomiting"]
                }
            ]
        }
    }
