"""
app/models/response.py
──────────────────────
Pydantic v2 response schemas.
"""

from pydantic import BaseModel
from typing import Any, Dict, List, Optional


class DrugInfo(BaseModel):
    """
    Mirrors the columns of the drugs CSV.
    All fields are Optional so a missing CSV column never crashes the API.
    """
    Disease: Optional[str] = None
    Drug: Optional[str] = None
    Egyptian_Brand: Optional[str] = None
    Role: Optional[str] = None
    Dosage: Optional[str] = None
    Key_Side_Effects: Optional[str] = None
    Avoid_In: Optional[str] = None
    Allergy_Warning: Optional[str] = None
    Drug_Interaction_Warning: Optional[str] = None

    model_config = {"populate_by_name": True}


class PredictResponse(BaseModel):
    predicted_disease: str
    confidence: float
    symptoms_used: List[str]
    unknown_symptoms: List[str]
    recommended_drugs: List[Dict[str, Any]]   # full matching rows from CSV


class HealthResponse(BaseModel):
    status: str
    model_loaded: bool
    encoder_loaded: bool
    drugs_db_loaded: bool
    num_diseases: int
    num_drug_entries: int
