# Disease Prediction API – Project Structure

```
disease_api/
│
├── app/
│   ├── __init__.py
│   ├── api/
│   │   ├── __init__.py
│   │   └── endpoints.py          # /predict and /health routes
│   │
│   ├── core/
│   │   ├── __init__.py
│   │   ├── config.py             # Settings, env vars
│   │   └── logging_config.py     # Structured logging setup
│   │
│   ├── models/
│   │   ├── __init__.py
│   │   ├── request.py            # Pydantic request schema
│   │   └── response.py           # Pydantic response schema
│   │
│   ├── services/
│   │   ├── __init__.py
│   │   ├── predictor.py          # ML prediction pipeline
│   │   └── drug_lookup.py        # CSV drug search service
│   │
│   └── utils/
│       ├── __init__.py
│       └── symptom_utils.py      # Symptom vector builder + validators
│
├── ml_artifacts/
│   ├── sota_model.pkl            # ← PUT YOUR FILE HERE
│   ├── label_encoder.pkl         # ← PUT YOUR FILE HERE
│   └── full_41_disease_egypt_drugs_dataset_with_safety.csv  # ← PUT YOUR FILE HERE
│
├── feature_engineer.py           # ← PUT YOUR FILE HERE (project root)
├── main.py                       # FastAPI app entry point
├── requirements.txt
├── .env                          # Environment variables
├── .gitignore
├── Dockerfile
└── README.md
```
