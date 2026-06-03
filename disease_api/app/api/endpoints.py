"""
app/api/endpoints.py
────────────────────
FastAPI route handlers.

/health  – liveness + readiness check
/predict – disease prediction endpoint
"""

from fastapi import APIRouter, HTTPException, Request
from app.models.request import PredictRequest
from app.models.response import PredictResponse, HealthResponse
from app.utils.symptom_utils import sanitise_symptoms
from app.core.logging_config import get_logger

logger = get_logger(__name__)
router = APIRouter()


# ─────────────────────────────────────────────────────────────────────────────
# GET /health
# ─────────────────────────────────────────────────────────────────────────────

@router.get(
    "/health",
    response_model=HealthResponse,
    summary="Health Check",
    tags=["System"],
)
async def health(request: Request) -> HealthResponse:
    """
    Returns the liveness / readiness state of the API.
    Confirms that the model, encoder, and drugs DB are all loaded.
    """
    state = request.app.state

    predictor   = getattr(state, "predictor",   None)
    drug_lookup = getattr(state, "drug_lookup",  None)

    return HealthResponse(
        status="ok",
        model_loaded=predictor is not None and predictor.is_loaded,
        encoder_loaded=predictor is not None and predictor.is_loaded,
        drugs_db_loaded=drug_lookup is not None,
        num_diseases=predictor.num_diseases if predictor else 0,
        num_drug_entries=drug_lookup.num_entries if drug_lookup else 0,
    )


# ─────────────────────────────────────────────────────────────────────────────
# POST /predict
# ─────────────────────────────────────────────────────────────────────────────

@router.post(
    "/predict",
    response_model=PredictResponse,
    summary="Predict Disease",
    tags=["Prediction"],
)
async def predict(body: PredictRequest, request: Request) -> PredictResponse:
    """
    Accepts a list of symptom strings and returns:
    - predicted disease
    - confidence score (0–1)
    - recommended drugs from the Egyptian drugs dataset
    - list of unknown / unrecognised symptoms (warnings)
    """
    state = request.app.state

    # ── Guard: services must be initialised ──────────────────────────────
    if not hasattr(state, "predictor") or state.predictor is None:
        raise HTTPException(status_code=503, detail="Model not loaded. Try again shortly.")
    if not hasattr(state, "drug_lookup") or state.drug_lookup is None:
        raise HTTPException(status_code=503, detail="Drug database not loaded.")

    # ── Sanitise & validate symptoms ─────────────────────────────────────
    valid_symptoms, unknown_symptoms = sanitise_symptoms(body.symptoms)

    if unknown_symptoms:
        logger.warning(f"Unknown symptoms in request: {unknown_symptoms}")

    if not valid_symptoms:
        raise HTTPException(
            status_code=422,
            detail=(
                "None of the provided symptoms were recognised. "
                f"Unknown: {unknown_symptoms}. "
                "Please use symptoms from the supported list."
            ),
        )

    # ── Predict ───────────────────────────────────────────────────────────
    try:
        disease, confidence = state.predictor.predict(valid_symptoms)
    except Exception as exc:
        logger.exception("Prediction failed")
        raise HTTPException(status_code=500, detail=f"Prediction error: {str(exc)}")

    # ── Drug lookup ───────────────────────────────────────────────────────
    drug_rows = state.drug_lookup.lookup_by_disease(disease)

    if not drug_rows:
        logger.warning(f"No drug entries found for disease: '{disease}'")

    # ── Build response ────────────────────────────────────────────────────
    return PredictResponse(
        predicted_disease=disease,
        confidence=confidence,
        symptoms_used=valid_symptoms,
        unknown_symptoms=unknown_symptoms,
        recommended_drugs=drug_rows,
    )
