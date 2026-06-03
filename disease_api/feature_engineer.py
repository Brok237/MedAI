import pandas as pd
from sklearn.base import BaseEstimator, TransformerMixin
import numpy as np
class FeatureEngineer(BaseEstimator, TransformerMixin):

    def fit(self, X, y=None):
        return self

    def transform(self, X):
        X = X.copy()
        X = X.apply(pd.to_numeric, errors="coerce").fillna(0)
        cols = X.columns.tolist()

        SYMPTOM_GROUPS = {
            "respiratory_score": ["cough","breathlessness","phlegm","throat_irritation",
                                  "runny_nose","congestion","sinus_pressure","chest_pain",
                                  "blood_in_sputum","mucoid_sputum","rusty_sputum"],

            "gi_score": ["stomach_pain","acidity","vomiting","indigestion",
                         "nausea","loss_of_appetite","constipation","abdominal_pain",
                         "diarrhoea","belly_pain","passage_of_gases",
                         "swelling_of_stomach","distention_of_abdomen","stomach_bleeding"],

            "neurological_score": ["headache","dizziness","loss_of_balance","unsteadiness",
                                   "slurred_speech","loss_of_smell","altered_sensorium",
                                   "lack_of_concentration","visual_disturbances","coma"],

            "skin_score": ["itching","skin_rash","nodal_skin_eruptions","yellowish_skin",
                           "dischromic__patches","pus_filled_pimples","blackheads",
                           "skin_peeling","silver_like_dusting","blister",
                           "red_sore_around_nose","yellow_crust_ooze","red_spots_over_body"],

            "musculo_score": ["joint_pain","muscle_wasting","back_pain","neck_pain",
                              "cramps","bruising","swollen_legs","swelling_joints",
                              "movement_stiffness","muscle_weakness","hip_joint_pain",
                              "knee_pain","painful_walking"],

            "metabolic_score": ["weight_gain","weight_loss","obesity","excessive_hunger",
                                "increased_appetite","polyuria","irregular_sugar_level",
                                "dehydration","fatigue","lethargy"],

            "fever_infection_score": ["high_fever","mild_fever","sweating","chills","shivering",
                                      "malaise","swelled_lymph_nodes","toxic_look_(typhos)"],
        }
        for feat, symptoms in SYMPTOM_GROUPS.items():
            available = [s for s in symptoms if s in cols]
            if available:
                X[feat] = X[available].sum(axis=1)

        # total symptoms
        numeric_cols = X.select_dtypes(include=[np.number]).columns
        X["total_symptoms"] = X[numeric_cols].sum(axis=1)

        # interactions
        if "high_fever" in cols and "cough" in cols:
            X["fever_and_cough"] = (X["high_fever"] & X["cough"]).astype(int)

        if "yellowing_of_eyes" in cols and "dark_urine" in cols:
            X["jaundice_combo"] = (X["yellowing_of_eyes"] & X["dark_urine"]).astype(int)

        if "skin_rash" in cols and "itching" in cols:
            X["rash_itch"] = (X["skin_rash"] & X["itching"]).astype(int)

        return X