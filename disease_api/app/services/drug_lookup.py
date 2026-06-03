"""
app/services/drug_lookup.py
────────────────────────────
Loads the drugs CSV once and provides a fast lookup by disease name.

The CSV disease column is normalised to lowercase+stripped on load so matching
is case-insensitive.  The model's predicted disease label (from LabelEncoder)
is also stripped before matching.
"""

from __future__ import annotations
import pandas as pd
from typing import List, Dict, Any
from app.core.logging_config import get_logger

logger = get_logger(__name__)


class DrugLookupService:
    """
    Loads the drugs dataset into memory once.
    Provides lookup_by_disease() for fast, case-insensitive matching.
    """

    def __init__(self, csv_path: str) -> None:
        logger.info(f"Loading drugs CSV from: {csv_path}")
        self._df = pd.read_csv(csv_path)

        # ── Normalise column names (strip spaces, replace spaces with _) ──
        self._df.columns = (
            self._df.columns
            .str.strip()
            .str.replace(" ", "_")
        )

        # ── Add a normalised disease key column for matching ──────────────
        self._df["_disease_key"] = (
            self._df["Disease"]
            .str.strip()
            .str.lower()
        )

        logger.info(
            f"Drugs DB loaded: {len(self._df)} rows, "
            f"{self._df['Disease'].nunique()} unique diseases."
        )

    # ── Public API ────────────────────────────────────────────────────────

    def lookup_by_disease(self, disease_name: str) -> List[Dict[str, Any]]:
        """
        Return all CSV rows whose Disease column matches disease_name
        (case-insensitive, stripped).

        Returns an empty list if no match is found – never raises.
        """
        key = disease_name.strip().lower()
        matched = self._df[self._df["_disease_key"] == key].copy()

        # Drop the internal key column before serialising
        matched.drop(columns=["_disease_key"], inplace=True)

        # Convert NaN → None so JSON serialisation works cleanly
        matched = matched.where(pd.notna(matched), other=None)

        return matched.to_dict(orient="records")

    @property
    def num_entries(self) -> int:
        return len(self._df)

    @property
    def num_diseases(self) -> int:
        return self._df["Disease"].nunique()
