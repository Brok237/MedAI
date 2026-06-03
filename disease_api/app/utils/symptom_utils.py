"""
app/utils/symptom_utils.py
──────────────────────────
Master symptom list (132 symptoms), input sanitisation, and binary vector builder.

IMPORTANT DESIGN NOTE – DIRTY COLUMN NAMES
───────────────────────────────────────────
The Training.csv had 3 column names with accidental spaces that were saved
directly into the model's feature_names.  We must use those exact dirty names
when building the DataFrame, otherwise XGBoost throws a feature_names mismatch.

Dirty names the model expects:
  "spotting_ urination"    (space after first underscore)
  "dischromic _patches"    (space before second underscore)
  "foul_smell_of urine"    (space before 'urine')

The API still accepts clean user input ("spotting_urination" etc.) and maps
it internally to the dirty column name before building the vector.
"""

from __future__ import annotations
from typing import Tuple
import pandas as pd

# ──────────────────────────────────────────────────────────────────────────────
# 132-symptom master list – uses the EXACT column names from Training.csv
# (including the 3 names with accidental spaces)
# ──────────────────────────────────────────────────────────────────────────────
MASTER_SYMPTOMS: list[str] = [
    "itching", "skin_rash", "nodal_skin_eruptions", "continuous_sneezing",
    "shivering", "chills", "joint_pain", "stomach_pain", "acidity",
    "ulcers_on_tongue", "muscle_wasting", "vomiting", "burning_micturition",
    "spotting_ urination",                 # ← dirty: space after underscore
    "fatigue", "weight_gain", "anxiety",
    "cold_hands_and_feets", "mood_swings", "weight_loss", "restlessness",
    "lethargy", "patches_in_throat", "irregular_sugar_level", "cough",
    "high_fever", "sunken_eyes", "breathlessness", "sweating", "dehydration",
    "indigestion", "headache", "yellowish_skin", "dark_urine", "nausea",
    "loss_of_appetite", "pain_behind_the_eyes", "back_pain", "constipation",
    "abdominal_pain", "diarrhoea", "mild_fever", "yellow_urine",
    "yellowing_of_eyes", "acute_liver_failure", "fluid_overload",
    "swelling_of_stomach", "swelled_lymph_nodes", "malaise",
    "blurred_and_distorted_vision", "phlegm", "throat_irritation",
    "redness_of_eyes", "sinus_pressure", "runny_nose", "congestion",
    "chest_pain", "weakness_in_limbs", "fast_heart_rate",
    "pain_during_bowel_movements", "pain_in_anal_region", "bloody_stool",
    "irritation_in_anus", "neck_pain", "dizziness", "cramps", "bruising",
    "obesity", "swollen_legs", "swollen_blood_vessels", "puffy_face_and_eyes",
    "enlarged_thyroid", "brittle_nails", "swollen_extremeties",
    "excessive_hunger", "extra_marital_contacts", "drying_and_tingling_lips",
    "slurred_speech", "knee_pain", "hip_joint_pain", "muscle_weakness",
    "stiff_neck", "swelling_joints", "movement_stiffness", "spinning_movements",
    "loss_of_balance", "unsteadiness", "weakness_of_one_body_side",
    "loss_of_smell", "bladder_discomfort",
    "foul_smell_of urine",                 # ← dirty: space before 'urine'
    "continuous_feel_of_urine", "passage_of_gases", "internal_itching",
    "toxic_look_(typhos)", "depression", "irritability", "muscle_pain",
    "altered_sensorium", "red_spots_over_body", "belly_pain",
    "abnormal_menstruation",
    "dischromic _patches",                 # ← dirty: space before underscore
    "watering_from_eyes",
    "increased_appetite", "polyuria", "family_history", "mucoid_sputum",
    "rusty_sputum", "lack_of_concentration", "visual_disturbances",
    "receiving_blood_transfusion", "receiving_unsterile_injections", "coma",
    "stomach_bleeding", "distention_of_abdomen", "history_of_alcohol_consumption",
    "fluid_overload.1", "blood_in_sputum", "prominent_veins_on_calf", "palpitations",
    "painful_walking", "pus_filled_pimples", "blackheads", "scurring",
    "skin_peeling", "silver_like_dusting", "small_dents_in_nails",
    "inflammatory_nails", "blister", "red_sore_around_nose", "yellow_crust_ooze",
    "prognosis",   # placeholder – dropped before prediction
]

# Drop "prognosis" – it's the target column, not a feature
FEATURE_COLUMNS: list[str] = [s for s in MASTER_SYMPTOMS if s != "prognosis"]

# ──────────────────────────────────────────────────────────────────────────────
# Clean → dirty name mapping
# Users send clean names; we map them to the exact dirty column the model needs.
# All other symptoms map to themselves (clean = dirty).
# ──────────────────────────────────────────────────────────────────────────────
_CLEAN_TO_DIRTY: dict[str, str] = {
    "spotting_urination":  "spotting_ urination",
    "foul_smell_of_urine": "foul_smell_of urine",
    "dischromic_patches":  "dischromic _patches",
}

# Reverse map: dirty → clean  (used to build _FEATURE_SET for validation)
_DIRTY_TO_CLEAN: dict[str, str] = {v: k for k, v in _CLEAN_TO_DIRTY.items()}

# The set of CLEAN names that users may send
_FEATURE_SET: set[str] = {
    _DIRTY_TO_CLEAN.get(col, col) for col in FEATURE_COLUMNS
}


def sanitise_symptoms(raw: list[str]) -> Tuple[list[str], list[str]]:
    """
    Lowercase, strip, deduplicate, and separate valid from unknown symptoms.
    Returns clean names (no spaces) – build_symptom_vector handles dirty mapping.

    Returns
    -------
    valid   : list[str]  – clean symptom names present in the master list
    unknown : list[str]  – symptom names NOT in the master list
    """
    seen: set[str] = set()
    valid: list[str] = []
    unknown: list[str] = []

    for s in raw:
        cleaned = s.strip().lower().replace(" ", "_")
        if cleaned in seen:
            continue
        seen.add(cleaned)

        if cleaned in _FEATURE_SET:
            valid.append(cleaned)
        else:
            unknown.append(cleaned)

    return valid, unknown


def build_symptom_vector(valid_symptoms: list[str]) -> pd.DataFrame:
    """
    Build a single-row DataFrame with 132 columns whose names EXACTLY match
    the model's training feature names (including the 3 dirty names with spaces).

    valid_symptoms contains clean names → we map dirty before building.
    """
    # Start with all columns = 0  (use dirty column names as keys)
    row = {col: 0 for col in FEATURE_COLUMNS}

    for s in valid_symptoms:
        # Map clean name → dirty name if needed, else use as-is
        dirty = _CLEAN_TO_DIRTY.get(s, s)
        if dirty in row:
            row[dirty] = 1

    return pd.DataFrame([row], columns=FEATURE_COLUMNS)
