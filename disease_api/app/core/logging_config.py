"""
app/core/logging_config.py
──────────────────────────
Structured logging setup.  Call setup_logging() once at startup.
"""

import logging
import sys


def setup_logging(debug: bool = False) -> None:
    """Configure root logger with a clean, consistent format."""
    level = logging.DEBUG if debug else logging.INFO

    fmt = "%(asctime)s | %(levelname)-8s | %(name)s | %(message)s"
    datefmt = "%Y-%m-%d %H:%M:%S"

    logging.basicConfig(
        level=level,
        format=fmt,
        datefmt=datefmt,
        stream=sys.stdout,
    )

    # Silence overly chatty third-party loggers
    for noisy in ("uvicorn.access", "multipart"):
        logging.getLogger(noisy).setLevel(logging.WARNING)


def get_logger(name: str) -> logging.Logger:
    return logging.getLogger(name)
