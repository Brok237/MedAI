"""
main.py
───────
FastAPI application entry point.

Startup lifecycle:
  1. Load settings from .env
  2. Configure logging
  3. Load ML model + label encoder  →  app.state.predictor
  4. Load drugs CSV                 →  app.state.drug_lookup

All services are loaded ONCE and reused across every request.
"""

import uvicorn
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import get_settings
from app.core.logging_config import setup_logging, get_logger
from app.api.endpoints import router
from app.services.predictor import PredictorService
from app.services.drug_lookup import DrugLookupService

settings = get_settings()
setup_logging(debug=settings.DEBUG)
logger = get_logger(__name__)


# ─────────────────────────────────────────────────────────────────────────────
# Lifespan  (replaces deprecated @app.on_event)
# ─────────────────────────────────────────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load heavy resources on startup; release on shutdown."""

    logger.info("═" * 55)
    logger.info(f"  {settings.APP_NAME}  v{settings.APP_VERSION}")
    logger.info("═" * 55)

    # ── Load model + encoder ──────────────────────────────────────────────
    logger.info("[1/2] Loading ML artefacts …")
    app.state.predictor = PredictorService(
        model_path=settings.MODEL_PATH,
        encoder_path=settings.ENCODER_PATH,
    )

    # ── Load drugs database ───────────────────────────────────────────────
    logger.info("[2/2] Loading drugs database …")
    app.state.drug_lookup = DrugLookupService(
        csv_path=settings.DRUGS_CSV_PATH,
    )

    logger.info("✅  All services ready.  API is live.")
    logger.info("═" * 55)

    yield  # ← app runs here

    # ── Shutdown ──────────────────────────────────────────────────────────
    logger.info("Shutting down …")
    app.state.predictor   = None
    app.state.drug_lookup = None


# ─────────────────────────────────────────────────────────────────────────────
# App factory
# ─────────────────────────────────────────────────────────────────────────────

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description=(
        "AI-powered disease prediction API. "
        "Submit a list of symptoms and receive a predicted diagnosis "
        "along with Egyptian drug recommendations."
    ),
    docs_url="/docs",       # Swagger UI
    redoc_url="/redoc",     # ReDoc
    lifespan=lifespan,
)

# ── CORS ──────────────────────────────────────────────────────────────────────
# Allows Flutter (or any frontend) to call the API from any origin.
# In production, replace "*" with your actual domain(s).
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routes ────────────────────────────────────────────────────────────────────
app.include_router(router, prefix="/api/v1")


# ─────────────────────────────────────────────────────────────────────────────
# Dev runner
# ─────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=8001,
        reload=settings.DEBUG,   # hot-reload only in debug mode
        log_level="debug" if settings.DEBUG else "info",
    )
