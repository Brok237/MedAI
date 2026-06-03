# Disease Prediction API

AI-powered FastAPI backend that predicts diseases from symptoms and returns Egyptian drug recommendations.

**Model:** Stacking ensemble (XGBoost + LightGBM + CatBoost → Logistic Regression), Isotonic calibration  
**Accuracy:** 97.6% on test set | AUC-ROC: 1.0 | 41 disease classes

---

## 1. Folder Structure

```
disease_api/
├── app/
│   ├── api/endpoints.py          ← /predict  /health
│   ├── core/config.py            ← settings from .env
│   ├── core/logging_config.py    ← structured logging
│   ├── models/request.py         ← Pydantic input schema
│   ├── models/response.py        ← Pydantic output schema
│   ├── services/predictor.py     ← ML pipeline
│   ├── services/drug_lookup.py   ← CSV search
│   └── utils/symptom_utils.py    ← vector builder + validators
├── ml_artifacts/
│   ├── sota_model.pkl            ← PUT YOUR MODEL HERE
│   ├── label_encoder.pkl         ← PUT YOUR ENCODER HERE
│   └── *.csv                     ← PUT THE DRUGS CSV HERE
├── main.py
├── requirements.txt
├── .env
├── Dockerfile
└── README.md
```

---

## 2. Setup & Run Locally

```bash
# 1. Clone / copy project
cd disease_api

# 2. Create virtual environment
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Place your .pkl files and CSV in ml_artifacts/

# 5. Run
python main.py
# OR
uvicorn main:app --reload --port 8000
```

Swagger UI → http://localhost:8000/docs

---

## 3. How Prediction Works

```
POST /api/v1/predict
        │
        ▼
1. Pydantic validates body  →  auto-lowercase, strip spaces
        │
        ▼
2. sanitise_symptoms()
   ├── valid:   ["headache", "high_fever", "vomiting"]
   └── unknown: ["xyz"]   (returned as warnings, not errors)
        │
        ▼
3. build_symptom_vector()
   → 1-row DataFrame with 132 columns (same order as Training.csv)
   → 1 for each valid symptom, 0 for everything else
        │
        ▼
4. add_engineered_features()
   → adds 7 group scores, total_symptoms, 3 interactions
   → 143-column DataFrame (matches training distribution exactly)
        │
        ▼
5. model.predict()  +  model.predict_proba()
   → class index  +  probability vector
        │
        ▼
6. LabelEncoder.inverse_transform()
   → "Malaria"
        │
        ▼
7. DrugLookupService.lookup_by_disease("Malaria")
   → all matching rows from drugs CSV
        │
        ▼
8. Return PredictResponse JSON
```

---

## 4. API Reference

### POST `/api/v1/predict`

**Request**
```json
{
  "symptoms": ["headache", "high_fever", "vomiting"]
}
```

**Response**
```json
{
  "predicted_disease": "Malaria",
  "confidence": 0.93,
  "symptoms_used": ["headache", "high_fever", "vomiting"],
  "unknown_symptoms": [],
  "recommended_drugs": [
    {
      "Disease": "Malaria",
      "Drug": "Artemether + Lumefantrine",
      "Egyptian_Brand": "Coartem",
      "Role": "First-line treatment",
      "Dosage": "...",
      "Key_Side_Effects": "...",
      "Avoid_In": "...",
      "Allergy_Warning": "...",
      "Drug_Interaction_Warning": "..."
    }
  ]
}
```

### GET `/api/v1/health`

```json
{
  "status": "ok",
  "model_loaded": true,
  "encoder_loaded": true,
  "drugs_db_loaded": true,
  "num_diseases": 41,
  "num_drug_entries": 123
}
```

---

## 5. Test with Postman

1. Import or create a new request
2. Method: `POST`
3. URL: `http://localhost:8000/api/v1/predict`
4. Headers: `Content-Type: application/json`
5. Body (raw JSON):

```json
{
  "symptoms": ["itching", "skin_rash", "nodal_skin_eruptions"]
}
```

---

## 6. Flutter Integration

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class DiseaseApiService {
  static const _baseUrl = 'http://10.0.2.2:8000/api/v1'; // Android emulator
  // Use http://localhost:8000/api/v1 for iOS simulator
  // Use your server IP in production

  Future<Map<String, dynamic>> predict(List<String> symptoms) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/predict'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'symptoms': symptoms}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Prediction failed');
    }
  }

  Future<Map<String, dynamic>> healthCheck() async {
    final response = await http.get(Uri.parse('$_baseUrl/health'));
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

// Usage example
void main() async {
  final api = DiseaseApiService();

  final result = await api.predict(['headache', 'high_fever', 'vomiting']);
  print('Disease: ${result['predicted_disease']}');
  print('Confidence: ${result['confidence']}');

  final drugs = result['recommended_drugs'] as List;
  for (final drug in drugs) {
    print('Drug: ${drug['Drug']} (${drug['Egyptian_Brand']})');
  }
}
```

Add `http` to your `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.2.0
```

---

## 7. Production Deployment

### Docker

```bash
# Build
docker build -t disease-api .

# Run
docker run -p 8000:8000 \
  -v $(pwd)/ml_artifacts:/app/ml_artifacts \
  --env-file .env \
  disease-api
```

### Environment Variables for Production

```env
DEBUG=false
CORS_ORIGINS=https://yourapp.com,https://www.yourapp.com
```

### Tips

- Set `DEBUG=false` in production (disables hot-reload, reduces log noise)
- Use a reverse proxy (nginx) in front of Uvicorn
- Mount `ml_artifacts/` as a Docker volume so you can update models without rebuilding
- Add rate limiting with `slowapi` if exposing publicly
- Consider `--workers 4` in the Dockerfile CMD for multi-core servers
