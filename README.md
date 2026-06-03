# MedAI — AI-Assisted Drug Recommendation & Doctor Review Platform
## Complete Setup & Deployment Guide

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter App                              │
│  Patient screens | Doctor screens | AI Chat | Notifications     │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTP (JWT)
                           ▼
┌──────────────────────────────────────────────────────────────┐
│                   Django Backend  :8000                        │
│  Auth | Cases | Doctor Approval | Chatbot | Notifications     │
│  PostgreSQL | Redis | Celery | WebSocket (Channels)           │
└───────────────┬──────────────────────────────────────────────┘
                │ Internal HTTP
                ▼
┌──────────────────────────────────────────┐
│        FastAPI ML Service  :8001          │
│  Symptom input → Feature engineering     │
│  → sota_model.pkl → Disease prediction   │
│  → Drug CSV lookup → Recommendations     │
└──────────────────────────────────────────┘
```

---

## Project Structure

```
medai_project/
├── backend/                    ← Django project
│   ├── config/
│   │   ├── settings.py
│   │   ├── urls.py
│   │   ├── asgi.py
│   │   ├── wsgi.py
│   │   └── celery.py
│   ├── apps/
│   │   ├── accounts/           ← Users, auth, doctor approval
│   │   ├── cases/              ← Symptom submission, predictions, prescriptions
│   │   ├── chatbot/            ← AI assistant (Arabic + English)
│   │   └── notifications/      ← In-app + email notifications
│   ├── requirements.txt
│   ├── Dockerfile
│   └── .env.example
│
├── disease_api/                ← FastAPI ML service (your existing code)
│   ├── main.py
│   ├── app/
│   │   ├── api/endpoints.py    → GET /health, POST /predict
│   │   ├── services/
│   │   │   ├── predictor.py    → loads sota_model.pkl
│   │   │   └── drug_lookup.py  → searches CSV
│   │   ├── models/
│   │   └── core/
│   ├── feature_engineer.py
│   ├── full_41_disease_egypt_drugs_dataset_with_safety.csv
│   └── requirements.txt
│
├── flutter_app/                ← Flutter mobile app
│   ├── lib/
│   │   ├── main.dart           ← Entry point + routing
│   │   ├── providers/          ← AuthProvider, CaseProvider
│   │   ├── services/           ← api_client, auth, case, chat, notification
│   │   ├── models/             ← UserModel, CaseModel, DrugRecommendation
│   │   ├── screens/            ← All UI screens
│   │   ├── storage/            ← SessionStorage (JWT tokens)
│   │   └── widgets/
│   └── pubspec.yaml
│
├── docker-compose.yml
├── render.yaml
└── README.md
```

---

## 1. FastAPI ML Service Setup

### Place Your ML Artifacts

```bash
cp /path/to/sota_model.pkl    disease_api/
cp /path/to/label_encoder.pkl disease_api/
```

The FastAPI service expects them at the paths in `.env`:
```
MODEL_PATH=sota_model.pkl
ENCODER_PATH=label_encoder.pkl
```

### Run FastAPI locally
```bash
cd disease_api
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8001 --reload
```

Test: http://localhost:8001/docs

---

## 2. Django Backend Setup

### Install dependencies
```bash
cd backend
python -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### Configure environment
```bash
cp .env.example .env
# Edit .env with your values
```

Minimum required `.env` for local development:
```env
SECRET_KEY=any-random-string-here
DEBUG=True
DATABASE_URL=sqlite:///db.sqlite3   # or your PostgreSQL URL
REDIS_URL=redis://localhost:6379/0
FASTAPI_ML_URL=http://localhost:8001
```

### Run migrations
```bash
python manage.py migrate
```

### Create admin superuser
```bash
python manage.py createsuperuser
# Enter email + password
# Then go to: http://localhost:8000/admin/
```

### Run Django development server
```bash
# With WebSocket support (recommended):
daphne -b 0.0.0.0 -p 8000 config.asgi:application

# Or simple dev server (no WebSocket):
python manage.py runserver
```

### Run Celery worker (for background tasks/emails)
```bash
# Requires Redis running
celery -A config worker -l info
```

---

## 3. Flutter App Setup

### Install Flutter dependencies
```bash
cd flutter_app
flutter pub get
```

### Configure API base URL
Open `lib/services/api_client.dart` and update:
```dart
static const String _baseUrl = 'http://10.0.2.2:8000/api/v1';
// Android emulator → 10.0.2.2
// iOS simulator    → 127.0.0.1
// Physical device  → your machine's local IP (e.g. 192.168.1.5)
// Production       → https://medai-backend.onrender.com/api/v1
```

### Run the app
```bash
flutter run
```

---

## 4. Docker Compose (Recommended for local dev)

```bash
# First: place your ML artifacts
cp /path/to/sota_model.pkl    disease_api/
cp /path/to/label_encoder.pkl disease_api/

# Uncomment the volume mount lines in docker-compose.yml:
# - ./ml_artifacts/sota_model.pkl:/app/sota_model.pkl
# - ./ml_artifacts/label_encoder.pkl:/app/label_encoder.pkl

# Start everything
docker-compose up --build

# Create Django admin user
docker-compose exec django python manage.py createsuperuser
```

Services will be available at:
- Django API:  http://localhost:8000
- FastAPI:     http://localhost:8001/docs
- Django Admin: http://localhost:8000/admin/

---

## 5. Deployment on Render

### Prerequisites
- Push this repo to GitHub
- Create a Render account at render.com

### Deploy with Blueprint
1. Go to render.com → New → Blueprint
2. Connect your GitHub repo
3. Render auto-detects `render.yaml` and creates:
   - PostgreSQL database (free tier)
   - Redis instance (free tier)
   - Django web service
   - FastAPI web service
   - Celery worker

### Set environment variables in Render dashboard
After deploy, add these in the Django service's Environment tab:
```
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password
```

### ML Artifacts on Render
Since pkl files are large, either:
- **Option A:** Commit them to the repo (if < 100MB)
- **Option B:** Store on Render Disk (persistent storage)
- **Option C:** Store on AWS S3 and download at startup in `main.py`

---

## 6. API Reference

### Auth endpoints
| Method | URL | Auth | Description |
|--------|-----|------|-------------|
| POST | `/api/v1/auth/register/patient/` | No | Register patient |
| POST | `/api/v1/auth/register/doctor/` | No | Register doctor (pending approval) |
| POST | `/api/v1/auth/login/` | No | Login → returns JWT tokens |
| POST | `/api/v1/auth/logout/` | Yes | Blacklist refresh token |
| POST | `/api/v1/auth/token/refresh/` | No | Refresh access token |
| POST | `/api/v1/auth/google/` | No | Google Sign-In |
| GET  | `/api/v1/auth/me/` | Yes | Get current user |
| POST | `/api/v1/auth/change-password/` | Yes | Change password |

### Cases endpoints
| Method | URL | Role | Description |
|--------|-----|------|-------------|
| POST | `/api/v1/cases/submit/` | Patient | Submit symptoms → triggers ML |
| GET  | `/api/v1/cases/my/` | Patient | List own cases |
| GET  | `/api/v1/cases/my/<id>/` | Patient | Case detail |
| POST | `/api/v1/cases/my/<id>/upload/` | Patient | Upload file attachment |
| GET  | `/api/v1/cases/my/<id>/prescription/` | Patient | Get approved prescription |
| GET  | `/api/v1/cases/queue/` | Doctor | Cases awaiting review |
| GET  | `/api/v1/cases/<id>/review/` | Doctor | Full case for review |
| POST | `/api/v1/cases/<id>/decision/` | Doctor | Approve or reject case |
| GET  | `/api/v1/cases/admin/all/` | Admin | All cases |
| GET  | `/api/v1/cases/admin/stats/` | Admin | Platform statistics |

### User management
| Method | URL | Role | Description |
|--------|-----|------|-------------|
| GET/PUT | `/api/v1/users/patient/profile/` | Patient | Own profile |
| GET/PUT | `/api/v1/users/doctor/profile/` | Doctor | Own profile |
| GET  | `/api/v1/users/doctors/` | Any | List approved doctors |
| GET  | `/api/v1/users/admin/doctors/` | Admin | All doctors (filter by status) |
| POST | `/api/v1/users/admin/doctors/<id>/approval/` | Admin | Approve/reject doctor |
| GET  | `/api/v1/users/admin/users/` | Admin | All users |

### Chat endpoints
| Method | URL | Auth | Description |
|--------|-----|------|-------------|
| POST | `/api/v1/chat/` | Yes | Send message (creates session if needed) |
| GET  | `/api/v1/chat/sessions/` | Yes | List chat sessions |
| GET  | `/api/v1/chat/sessions/<id>/` | Yes | Message history |

### FastAPI ML endpoints
| Method | URL | Description |
|--------|-----|-------------|
| GET  | `/api/v1/health` | Service health check |
| POST | `/api/v1/predict` | `{"symptoms": ["cough", "fever", ...]}` |

---

## 7. User Roles & Flows

### Patient Flow
1. Register → Login
2. Submit symptoms (symptom picker)
3. See status: "Awaiting doctor review"
4. Notification: "Prescription ready"
5. View approved drugs + dosage + brand

### Doctor Flow
1. Register with license → Wait for admin approval
2. Login → See case queue
3. Click a case → Review prediction + drug suggestions
4. Toggle approve/reject per drug, edit dosages
5. Submit decision → Patient is notified

### Admin Flow
1. Login at /admin/ (Django admin panel)
2. Approve/reject pending doctors
3. Monitor all cases and users
4. View platform stats at `/api/v1/cases/admin/stats/`

---

## 8. Upgrade: Connect a Real LLM to the Chatbot

In `backend/apps/chatbot/engine.py`, replace `_call_llm()`:

```python
# OpenAI example
import openai

def _call_llm(self, prompt: str) -> str:
    client = openai.OpenAI(api_key=os.environ['OPENAI_API_KEY'])
    response = client.chat.completions.create(
        model='gpt-4',
        messages=[
            {'role': 'system', 'content': 'You are a helpful medical assistant. Always remind users to consult their doctor.'},
            {'role': 'user', 'content': prompt}
        ]
    )
    return response.choices[0].message.content
```

Then in `get_response()`, replace the rule-based logic with `_call_llm(message)`.

---

## 9. WebSocket Notifications

Connect from Flutter:
```dart
final channel = WebSocketChannel.connect(
  Uri.parse('ws://localhost:8000/ws/notifications/'),
  headers: {'Authorization': 'Bearer $accessToken'},
);
channel.stream.listen((data) {
  final msg = jsonDecode(data);
  if (msg['type'] == 'notification') {
    // Show local notification
  }
});
```

---

## Important Notes

- **ML artifacts** (`sota_model.pkl`, `label_encoder.pkl`) are NOT included — place them in `disease_api/`
- **Doctors cannot login** until an admin approves their account
- **Patients cannot see drug details** until a doctor approves the case
- The chatbot uses rule-based responses by default — swap to OpenAI/Gemini when ready
- All passwords are bcrypt-hashed via Django's auth system
- JWT access tokens expire in 24h; refresh tokens last 30 days
