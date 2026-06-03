#!/bin/bash
# quickstart.sh
# ─────────────────────────────────────────────────────────────────────────────
# One-command local development setup.
# Run from the project root: bash quickstart.sh
# ─────────────────────────────────────────────────────────────────────────────

set -e

BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}  MedAI — Quick Start${RESET}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

# ── Check prerequisites ───────────────────────────────────────────────────────
echo -e "${YELLOW}[1/6] Checking prerequisites...${RESET}"

check_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo -e "${RED}✗ $1 not found. Please install it.${RESET}"; exit 1; }
  echo -e "${GREEN}✓ $1 found${RESET}"
}

check_cmd python3
check_cmd pip
check_cmd docker
check_cmd docker-compose

# ── Check ML artifacts ────────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}[2/6] Checking ML artifacts...${RESET}"

if [ ! -f "disease_api/sota_model.pkl" ]; then
  echo -e "${RED}✗ disease_api/sota_model.pkl not found!${RESET}"
  echo -e "  ${YELLOW}Copy your model: cp /path/to/sota_model.pkl disease_api/${RESET}"
  echo ""
  echo -e "${YELLOW}  Starting without ML artifacts — predictions will fail until you add them.${RESET}"
else
  echo -e "${GREEN}✓ sota_model.pkl found${RESET}"
fi

if [ ! -f "disease_api/label_encoder.pkl" ]; then
  echo -e "${RED}✗ disease_api/label_encoder.pkl not found!${RESET}"
else
  echo -e "${GREEN}✓ label_encoder.pkl found${RESET}"
fi

# ── Setup Django .env ─────────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}[3/6] Setting up environment...${RESET}"

if [ ! -f "backend/.env" ]; then
  cp backend/.env.example backend/.env
  # Generate a random secret key
  SECRET=$(python3 -c "import secrets; print(secrets.token_urlsafe(50))")
  sed -i.bak "s/your-very-long-random-secret-key-here/$SECRET/" backend/.env
  rm -f backend/.env.bak
  echo -e "${GREEN}✓ Created backend/.env with random SECRET_KEY${RESET}"
  echo -e "${YELLOW}  Edit backend/.env to configure email, Google OAuth, etc.${RESET}"
else
  echo -e "${GREEN}✓ backend/.env already exists${RESET}"
fi

# ── Start Docker services ─────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}[4/6] Starting Docker services (Postgres + Redis + Django + FastAPI)...${RESET}"
docker-compose up -d --build

echo ""
echo -e "${YELLOW}Waiting for Django to be ready...${RESET}"
sleep 8

# ── Create admin user ─────────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}[5/6] Creating admin user...${RESET}"

ADMIN_EMAIL="mohmedessam527@gmail.com"
ADMIN_PASS="Broke_2378"

docker-compose exec -T django python manage.py create_admin \
  --email "$ADMIN_EMAIL" \
  --password "$ADMIN_PASS" \
  --name "System Admin" 2>/dev/null || true

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}[6/6] Setup complete!${RESET}"
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BOLD}  Services Running:${RESET}"
echo -e "  ${GREEN}🌐 Django API:${RESET}    http://localhost:8000/api/v1/"
echo -e "  ${GREEN}🤖 FastAPI ML:${RESET}    http://localhost:8001/docs"
echo -e "  ${GREEN}⚙️  Django Admin:${RESET}  http://localhost:8000/admin/"
echo ""
echo -e "${BOLD}  Admin Credentials:${RESET}"
echo -e "  Email:    ${GREEN}$ADMIN_EMAIL${RESET}"
echo -e "  Password: ${GREEN}$ADMIN_PASS${RESET}"
echo -e "  ${YELLOW}(Change this password after first login!)${RESET}"
echo ""
echo -e "${BOLD}  Flutter App:${RESET}"
echo -e "  cd flutter_app && flutter run"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
