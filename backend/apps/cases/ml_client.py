"""
apps/cases/ml_client.py
────────────────────────
HTTP client that calls the FastAPI ML microservice.
Django → FastAPI (port 8001) → disease prediction + drug recommendations.

If the FastAPI service is unreachable, raises MLServiceError.
"""

import requests
import logging
from django.conf import settings

logger = logging.getLogger(__name__)


class MLServiceError(Exception):
    """Raised when the FastAPI ML service returns an error or is unreachable."""
    pass


class MLClient:
    """
    Thin wrapper around the FastAPI ML service HTTP API.
    All methods raise MLServiceError on failure.
    """

    BASE_URL = None  # Set from settings in __init__

    def __init__(self):
        self.BASE_URL = getattr(settings, 'FASTAPI_ML_URL', 'http://localhost:8001')
        self.session = requests.Session()
        self.session.headers.update({
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        })
        self.timeout = 30  # seconds

    def predict(self, symptoms: list[str]) -> dict:
        """
        Send a list of symptom strings to the ML service.

        Returns dict with keys:
            predicted_disease   : str
            confidence          : float
            top_predictions     : [{disease, confidence}]
            drug_recommendations: [{disease, drug, egyptian_brand, role,
                                    dosage, key_side_effects, avoid_in,
                                    allergy_warning, drug_interaction_warning}]
        """
        payload = {'symptoms': symptoms}

        try:
            response = self.session.post(
                f'{self.BASE_URL}/api/v1/predict',
                json=payload,
                timeout=self.timeout
            )
            response.raise_for_status()
            return response.json()

        except requests.exceptions.ConnectionError:
            logger.error('ML service is unreachable at %s', self.BASE_URL)
            raise MLServiceError(
                'The prediction service is currently unavailable. Please try again later.'
            )
        except requests.exceptions.Timeout:
            logger.error('ML service timed out after %ds', self.timeout)
            raise MLServiceError('The prediction service timed out. Please try again.')
        except requests.exceptions.HTTPError as e:
            logger.error('ML service HTTP error: %s', str(e))
            detail = ''
            try:
                detail = response.json().get('detail', '')
            except Exception:
                pass
            raise MLServiceError(f'Prediction service error: {detail or str(e)}')
        except Exception as e:
            logger.exception('Unexpected error calling ML service')
            raise MLServiceError(f'Unexpected error: {str(e)}')

    def health_check(self) -> bool:
        """Return True if the FastAPI service is healthy."""
        try:
            response = self.session.get(
                f'{self.BASE_URL}/api/v1/health',
                timeout=5
            )
            return response.status_code == 200
        except Exception:
            return False


# Singleton instance
ml_client = MLClient()
