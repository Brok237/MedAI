"""
app/services/predictor.py
──────────────────────────
ML prediction pipeline.

Flow
────
1. Receive valid symptom list
2. Build 132-column binary vector (FEATURE_COLUMNS order)
3. Apply add_engineered_features() → 143-column DataFrame
4. model.predict()  +  model.predict_proba()
5. LabelEncoder.inverse_transform() → disease name string
6. Return disease name + confidence score
"""

from __future__ import annotations

import sys
import os
import joblib
import numpy as np
import pandas as pd
from typing import Tuple

from app.core.logging_config import get_logger
from app.utils.symptom_utils import build_symptom_vector

logger = get_logger(__name__)

# ── Import feature engineering from project root ──────────────────────────────
# feature_engineer.py lives at the project root (same level as main.py).
# We use the standalone add_engineered_features function that mirrors what
# the notebook did during training.  We do NOT use the FeatureEngineer class
# because the pkl was NOT serialised as part of a Pipeline – the model was
# trained on a plain DataFrame, so we replicate that transformation manually.

SYMPTOM_GROUPS = {
    "respiratory_score": [
        "cough", "breathlessness", "phlegm", "throat_irritation",
        "runny_nose", "congestion", "sinus_pressure", "chest_pain",
        "blood_in_sputum", "mucoid_sputum", "rusty_sputum",
    ],
    "gi_score": [
        "stomach_pain", "acidity", "vomiting", "indigestion",
        "nausea", "loss_of_appetite", "constipation", "abdominal_pain",
        "diarrhoea", "belly_pain", "passage_of_gases",
        "swelling_of_stomach", "distention_of_abdomen", "stomach_bleeding",
    ],
    "neurological_score": [
        "headache", "dizziness", "loss_of_balance", "unsteadiness",
        "slurred_speech", "loss_of_smell", "altered_sensorium",
        "lack_of_concentration", "visual_disturbances", "coma",
    ],
    "skin_score": [
        "itching", "skin_rash", "nodal_skin_eruptions", "yellowish_skin",
        # note: training CSV uses "dischromic_patches" (single underscore)
        "dischromic_patches", "pus_filled_pimples", "blackheads",
        "skin_peeling", "silver_like_dusting", "blister",
        "red_sore_around_nose", "yellow_crust_ooze", "red_spots_over_body",
    ],
    "musculo_score": [
        "joint_pain", "muscle_wasting", "back_pain", "neck_pain",
        "cramps", "bruising", "swollen_legs", "swelling_joints",
        "movement_stiffness", "muscle_weakness", "hip_joint_pain",
        "knee_pain", "painful_walking",
    ],
    "metabolic_score": [
        "weight_gain", "weight_loss", "obesity", "excessive_hunger",
        "increased_appetite", "polyuria", "irregular_sugar_level",
        "dehydration", "fatigue", "lethargy",
    ],
    "fever_infection_score": [
        "high_fever", "mild_fever", "sweating", "chills", "shivering",
        "malaise", "swelled_lymph_nodes", "toxic_look_(typhos)",
    ],
}


def add_engineered_features(X: pd.DataFrame) -> pd.DataFrame:
    """
    Replicates exactly what the notebook's add_engineered_features() did
    during training – so inference matches the training distribution.

    Adds 11 columns:
        7 group score columns
        total_symptoms
        fever_and_cough
        jaundice_combo
        rash_itch
    """
    X = X.copy()
    cols = X.columns.tolist()

    # ── Group scores ──────────────────────────────────────────────────────
    for feat_name, symptoms in SYMPTOM_GROUPS.items():
        available = [s for s in symptoms if s in cols]
        if available:
            X[feat_name] = X[available].sum(axis=1)
        else:
            X[feat_name] = 0  # keep column even if no symptoms present

    # ── Total symptom burden (sum of original 132 columns only) ──────────
    original_cols = [c for c in cols if c in set(cols)]
    X["total_symptoms"] = X[original_cols].sum(axis=1)

    # ── Interaction features ──────────────────────────────────────────────
    if "high_fever" in cols and "cough" in cols:
        X["fever_and_cough"] = (X["high_fever"] & X["cough"]).astype(int)
    else:
        X["fever_and_cough"] = 0

    if "yellowing_of_eyes" in cols and "dark_urine" in cols:
        X["jaundice_combo"] = (X["yellowing_of_eyes"] & X["dark_urine"]).astype(int)
    else:
        X["jaundice_combo"] = 0

    if "skin_rash" in cols and "itching" in cols:
        X["rash_itch"] = (X["skin_rash"] & X["itching"]).astype(int)
    else:
        X["rash_itch"] = 0

    return X


class PredictorService:
    """
    Loads model + label encoder once (at app startup) and exposes predict().
    Thread-safe for read-only inference.
    """

    def __init__(self, model_path: str, encoder_path: str) -> None:
        logger.info(f"Loading model from:   {model_path}")
        self._model = joblib.load(model_path)
        logger.info("Model loaded ✓")

        logger.info(f"Loading encoder from: {encoder_path}")
        self._encoder = joblib.load(encoder_path)
        logger.info(f"Encoder loaded ✓  |  {len(self._encoder.classes_)} disease classes")

    # ── Public API ────────────────────────────────────────────────────────

    def predict(self, valid_symptoms: list[str]) -> Tuple[str, float]:
        """
        Parameters
        ──────────
        valid_symptoms : already-validated list of symptom strings

        Returns
        ───────
        (disease_name, confidence)
            disease_name : str   – human-readable disease label
            confidence   : float – max predicted class probability (0-1, 2 d.p.)
        """
        # Step 1: build binary vector DataFrame (132 columns)
        X = build_symptom_vector(valid_symptoms)

        # Step 2: apply feature engineering (→ 143 columns)
        X_fe = add_engineered_features(X)

        logger.debug(f"Feature vector shape: {X_fe.shape}")

        # Step 3: predict class index
        class_idx: int = int(self._model.predict(X_fe)[0])

        # Step 4: predict probabilities for confidence score
        proba: np.ndarray = self._model.predict_proba(X_fe)[0]
        confidence: float = round(float(proba[class_idx]), 4)

        # Step 5: decode class index → disease name
        disease_name: str = self._encoder.inverse_transform([class_idx])[0]

        logger.info(f"Prediction: {disease_name} (confidence={confidence})")
        return disease_name, confidence

    # ── Health checks ─────────────────────────────────────────────────────

    @property
    def is_loaded(self) -> bool:
        return self._model is not None and self._encoder is not None

    @property
    def num_diseases(self) -> int:
        return len(self._encoder.classes_)
