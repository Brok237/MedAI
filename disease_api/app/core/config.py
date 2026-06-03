"""
app/core/config.py
──────────────────
Central configuration using pydantic-settings.
All values can be overridden via environment variables or the .env file.
"""

from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache


class Settings(BaseSettings):
    # ── App meta ──────────────────────────────────────────────────────────
    APP_NAME: str = "Disease Prediction API"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False

    # ── Artifact paths ────────────────────────────────────────────────────
    MODEL_PATH: str = "ml_artifacts/sota_model.pkl"
    ENCODER_PATH: str = "ml_artifacts/label_encoder.pkl"
    DRUGS_CSV_PATH: str = "ml_artifacts/full_41_disease_egypt_drugs_dataset_with_safety.csv"

    # ── Server ────────────────────────────────────────────────────────────
    HOST: str = "0.0.0.0"
    PORT: int = 8000

    # ── CORS ──────────────────────────────────────────────────────────────
    CORS_ORIGINS: str = "*"

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    @property
    def cors_origins_list(self) -> list[str]:
        """Return CORS origins as a list (split on comma)."""
        if self.CORS_ORIGINS == "*":
            return ["*"]
        return [o.strip() for o in self.CORS_ORIGINS.split(",")]


@lru_cache()
def get_settings() -> Settings:
    """Cached settings – instantiated only once."""
    return Settings()
