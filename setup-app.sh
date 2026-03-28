#!/usr/bin/env bash
# ================================================================
#  setup_app.sh  —  Smart Full-Stack Project Scaffolding Tool
#  v2.0 — cross-platform, DB support, Docker, idempotent add-mode
# ================================================================

set -euo pipefail

# ─── Portability ─────────────────────────────────────────────────
# Works on Bash 3 (macOS default) and Bash 5 (Linux)
BASH_MAJOR="${BASH_VERSINFO[0]}"
if (( BASH_MAJOR < 3 )); then
    echo "ERROR: Bash 3.2+ required (you have ${BASH_VERSION})." >&2
    exit 1
fi

# Portable divider — avoids printf '─%.0s' which breaks on macOS Bash 3
divider() {
    local line=""
    local i=0
    while (( i < 55 )); do line="${line}─"; (( i++ )) || true; done
    echo -e "${CYAN}${line}${RESET}"
}

# ─── Colors ──────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

# ─── Helpers ─────────────────────────────────────────────────────
info()    { echo -e "${CYAN}${BOLD}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}${BOLD}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}${BOLD}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}${BOLD}[ERROR]${RESET} $*"; exit 1; }

ask_choice() {
    local prompt="$1"; shift
    local options=("$@")
    echo -e "\n${BOLD}${YELLOW}${prompt}${RESET}"
    local i=0
    for opt in "${options[@]}"; do
        echo -e "  ${CYAN}[$((i+1))]${RESET} ${opt}"
        (( i++ )) || true
    done
    local n="${#options[@]}"
    while true; do
        read -rp "$(echo -e "  ${BOLD}→ Enter choice [1-${n}]: ${RESET}")" choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= n )); then
            CHOICE="${options[$((choice-1))]}"
            return
        fi
        warn "Invalid. Enter a number between 1 and ${n}."
    done
}

ask_text() {
    local prompt="$1" default="$2"
    read -rp "$(echo -e "  ${BOLD}→ ${prompt} [${CYAN}${default}${RESET}${BOLD}]: ${RESET}")" input
    echo "${input:-$default}"
}

check_cmd() {
    command -v "$1" &>/dev/null || error "'$1' is not installed. Please install it and re-run."
}

# ─── Detect OS ───────────────────────────────────────────────────
OS="linux"
if [[ "$(uname)" == "Darwin" ]]; then
    OS="macos"
    warn "macOS detected — script is fully compatible."
fi

# ─── Banner ──────────────────────────────────────────────────────
clear
echo -e "${CYAN}${BOLD}"
cat << 'EOF'
  ███████╗███████╗████████╗██╗   ██╗██████╗      █████╗ ██████╗ ██████╗
  ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗    ██╔══██╗██╔══██╗██╔══██╗
  ███████╗█████╗     ██║   ██║   ██║██████╔╝    ███████║██████╔╝██████╔╝
  ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝     ██╔══██║██╔═══╝ ██╔═══╝
  ███████║███████╗   ██║   ╚██████╔╝██║         ██║  ██║██║     ██║
  ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝         ╚═╝  ╚═╝╚═╝     ╚═╝
EOF
echo -e "${RESET}"
echo -e "  ${BOLD}Full-Stack Scaffolding Tool v2.0${RESET}  —  Linux & macOS"
divider
echo ""

# ================================================================
#  MODE — normal scaffold OR add to existing project
# ================================================================
ORIGIN_DIR="$(pwd)"

ask_choice "What do you want to do?" \
    "Create new project  (full-stack)" \
    "Create new project  (backend only)" \
    "Create new project  (frontend only)" \
    "Add backend to existing frontend project" \
    "Add frontend to existing backend project"
SCAFFOLD_MODE="$CHOICE"

# ================================================================
#  PROJECT NAME / ROOT RESOLUTION
# ================================================================
divider

case "$SCAFFOLD_MODE" in
    "Create new project"*)
        PROJECT_NAME=$(ask_text "Project name" "my-app")
        [[ -d "$PROJECT_NAME" ]] && error "Directory '${PROJECT_NAME}' already exists. Use 'Add' mode to extend it."
        ROOT_DIR="${ORIGIN_DIR}/${PROJECT_NAME}"
        mkdir -p "$ROOT_DIR"
        ;;
    "Add backend to existing frontend project")
        PROJECT_NAME=$(ask_text "Existing project directory name" "my-app")
        [[ ! -d "$PROJECT_NAME" ]] && error "Directory '${PROJECT_NAME}' not found."
        ROOT_DIR="${ORIGIN_DIR}/${PROJECT_NAME}"
        [[ -d "${ROOT_DIR}/backend" ]] && error "A 'backend/' folder already exists in '${PROJECT_NAME}'."
        info "Found existing project: ${PROJECT_NAME}/"
        ;;
    "Add frontend to existing backend project")
        PROJECT_NAME=$(ask_text "Existing project directory name" "my-app")
        [[ ! -d "$PROJECT_NAME" ]] && error "Directory '${PROJECT_NAME}' not found."
        ROOT_DIR="${ORIGIN_DIR}/${PROJECT_NAME}"
        [[ -d "${ROOT_DIR}/frontend" ]] && error "A 'frontend/' folder already exists in '${PROJECT_NAME}'."
        info "Found existing project: ${PROJECT_NAME}/"
        ;;
esac

# ================================================================
#  BACKEND FRAMEWORK
# ================================================================
BACKEND_CHOICE=""
WANTS_BACKEND=false
case "$SCAFFOLD_MODE" in
    *"full-stack"*|*"backend only"*|"Add backend"*)
        WANTS_BACKEND=true
        divider
        echo -e "\n  ${BOLD}⬡  BACKEND${RESET}"
        ask_choice "Choose a backend framework:" \
            "Express (Node.js)" \
            "Django + DRF (Python)"
        BACKEND_CHOICE="$CHOICE"
        ;;
esac

# ================================================================
#  DATABASE
# ================================================================
DB_CHOICE="None"
DB_NAME="appdb"
DB_USER="appuser"
DB_PASS="secret"
DB_HOST="localhost"
DB_PORT=""

if $WANTS_BACKEND; then
    divider
    echo -e "\n  ${BOLD}⬡  DATABASE${RESET}"
    ask_choice "Choose a database:" \
        "None (SQLite / in-memory)" \
        "PostgreSQL" \
        "MySQL"
    DB_CHOICE="$CHOICE"

    if [[ "$DB_CHOICE" != "None"* ]]; then
        DB_NAME=$(ask_text "Database name"     "appdb")
        DB_USER=$(ask_text "Database user"     "appuser")
        DB_PASS=$(ask_text "Database password" "secret")
        DB_HOST=$(ask_text "Database host"     "localhost")
        if [[ "$DB_CHOICE" == "PostgreSQL" ]]; then
            DB_PORT=$(ask_text "Database port" "5432")
        else
            DB_PORT=$(ask_text "Database port" "3306")
        fi
    fi
fi

# ================================================================
#  FRONTEND FRAMEWORK
# ================================================================
FRONTEND_CHOICE=""
WANTS_FRONTEND=false
case "$SCAFFOLD_MODE" in
    *"full-stack"*|*"frontend only"*|"Add frontend"*)
        WANTS_FRONTEND=true
        divider
        echo -e "\n  ${BOLD}⬡  FRONTEND${RESET}"
        ask_choice "Choose a frontend framework:" \
            "React (Vite)" \
            "Vue (Vite)" \
            "Next.js"
        FRONTEND_CHOICE="$CHOICE"
        ;;
esac

# ================================================================
#  BACKEND API URL  (used to pre-fill frontend env)
# ================================================================
BACKEND_API_URL=""
if $WANTS_FRONTEND; then
    divider
    echo -e "\n  ${BOLD}⬡  API CONNECTION${RESET}"
    if [[ "$BACKEND_CHOICE" == *"Django"* ]]; then
        DEFAULT_API="http://localhost:8000/api"
    else
        DEFAULT_API="http://localhost:5000/api"
    fi
    BACKEND_API_URL=$(ask_text "Backend API base URL (used in frontend env)" "$DEFAULT_API")
fi

# ================================================================
#  JS PACKAGE MANAGER
# ================================================================
PKG_MGR="npm"
NEEDS_JS=false
[[ "$BACKEND_CHOICE" == *"Express"* ]] && NEEDS_JS=true
$WANTS_FRONTEND                        && NEEDS_JS=true

if $NEEDS_JS; then
    divider
    echo -e "\n  ${BOLD}⬡  PACKAGE MANAGER${RESET}"
    ask_choice "Preferred JS package manager:" "npm" "pnpm" "yarn"
    PKG_MGR="$CHOICE"
fi

# ================================================================
#  DOCKER
# ================================================================
divider
ask_choice "Generate Docker + docker-compose files?" "Yes" "No"
WANT_DOCKER="$CHOICE"

# ================================================================
#  GIT
# ================================================================
divider
ask_choice "Initialize a Git repository?" "Yes" "No"
INIT_GIT="$CHOICE"

# ================================================================
#  SUMMARY
# ================================================================
divider
echo -e "\n  ${BOLD}📋  Summary${RESET}"
echo -e "  Mode      : ${GREEN}${SCAFFOLD_MODE}${RESET}"
echo -e "  Project   : ${GREEN}${PROJECT_NAME}${RESET}"
[[ -n "$BACKEND_CHOICE"  ]] && echo -e "  Backend   : ${GREEN}${BACKEND_CHOICE}${RESET}"
[[ -n "$DB_CHOICE"       ]] && echo -e "  Database  : ${GREEN}${DB_CHOICE}${RESET}"
[[ -n "$FRONTEND_CHOICE" ]] && echo -e "  Frontend  : ${GREEN}${FRONTEND_CHOICE}${RESET}"
[[ -n "$BACKEND_API_URL" ]] && echo -e "  API URL   : ${GREEN}${BACKEND_API_URL}${RESET}"
$NEEDS_JS                   && echo -e "  Pkg mgr   : ${GREEN}${PKG_MGR}${RESET}"
echo -e "  Docker    : ${GREEN}${WANT_DOCKER}${RESET}"
echo -e "  Git       : ${GREEN}${INIT_GIT}${RESET}"
echo ""
read -rp "$(echo -e "  ${BOLD}Proceed? [Y/n]: ${RESET}")" confirm
[[ "${confirm,,}" == "n" ]] && { warn "Aborted."; exit 0; }

# ================================================================
#  BACKEND SETUP
# ================================================================
setup_backend() {
    local target_dir="$1"
    mkdir -p "$target_dir"
    cd "$target_dir"

    divider
    echo -e "\n${BOLD}${YELLOW}⬡  Setting up Backend...${RESET}\n"

    # ── Express ────────────────────────────────────────────────
    if [[ "$BACKEND_CHOICE" == *"Express"* ]]; then
        check_cmd node; check_cmd npm
        [[ "$PKG_MGR" == "pnpm" ]] && check_cmd pnpm
        [[ "$PKG_MGR" == "yarn" ]] && check_cmd yarn

        info "Initialising Express project..."
        npm init -y --silent

        # Core packages
        local pkgs="express cors dotenv morgan helmet"
        # DB driver
        if [[ "$DB_CHOICE" == "PostgreSQL" ]]; then
            pkgs="$pkgs pg"
            info "Adding PostgreSQL driver (pg)..."
        elif [[ "$DB_CHOICE" == "MySQL" ]]; then
            pkgs="$pkgs mysql2"
            info "Adding MySQL driver (mysql2)..."
        fi

        info "Installing dependencies..."
        case "$PKG_MGR" in
            pnpm) pnpm add $pkgs ;;
            yarn) yarn add $pkgs ;;
            *)    npm install --silent $pkgs ;;
        esac

        info "Installing dev dependencies..."
        case "$PKG_MGR" in
            pnpm) pnpm add -D nodemon ;;
            yarn) yarn add --dev nodemon ;;
            *)    npm install --silent -D nodemon ;;
        esac

        node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json','utf8'));
pkg.main = 'src/index.js';
pkg.type = 'module';
pkg.scripts = { start:'node src/index.js', dev:'nodemon src/index.js', test:'echo \"No tests yet\"' };
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
"
        mkdir -p src/routes src/controllers src/middleware src/config

        # ── DB config file ──────────────────────────────────
        if [[ "$DB_CHOICE" == "PostgreSQL" ]]; then
            cat > src/config/db.js << 'DBCFG'
import pg from 'pg';
import 'dotenv/config';

const { Pool } = pg;

const pool = new Pool({
  host:     process.env.DB_HOST,
  port:     Number(process.env.DB_PORT),
  database: process.env.DB_NAME,
  user:     process.env.DB_USER,
  password: process.env.DB_PASS,
});

pool.on('error', (err) => {
  console.error('Unexpected DB error', err);
  process.exit(-1);
});

export const query = (text, params) => pool.query(text, params);
export default pool;
DBCFG
        elif [[ "$DB_CHOICE" == "MySQL" ]]; then
            cat > src/config/db.js << 'DBCFG'
import mysql from 'mysql2/promise';
import 'dotenv/config';

const pool = mysql.createPool({
  host:     process.env.DB_HOST,
  port:     Number(process.env.DB_PORT),
  database: process.env.DB_NAME,
  user:     process.env.DB_USER,
  password: process.env.DB_PASS,
  waitForConnections: true,
  connectionLimit:    10,
});

export default pool;
DBCFG
        fi

        # ── src/index.js ────────────────────────────────────
        local db_import=""
        if [[ "$DB_CHOICE" != "None"* ]]; then
            db_import="import db from './config/db.js';"
        fi

        cat > src/index.js << EXPR
import express from 'express';
import cors    from 'cors';
import morgan  from 'morgan';
import helmet  from 'helmet';
import 'dotenv/config';
${db_import}

import apiRouter from './routes/index.js';

const app  = express();
const PORT = process.env.PORT || 5000;

app.use(helmet());
app.use(cors({ origin: process.env.CLIENT_ORIGIN || 'http://localhost:3000' }));
app.use(morgan('dev'));
app.use(express.json());

app.use('/api', apiRouter);

app.get('/health', (_req, res) => res.json({ status: 'ok' }));

app.listen(PORT, () => console.log(\`🚀  Server running on http://localhost:\${PORT}\`));
EXPR

        cat > src/routes/index.js << 'EXPR'
import { Router } from 'express';
import exampleRouter from './example.js';

const router = Router();
router.use('/example', exampleRouter);
export default router;
EXPR

        cat > src/routes/example.js << 'EXPR'
import { Router } from 'express';
import { getAll } from '../controllers/example.controller.js';

const router = Router();
router.get('/', getAll);
export default router;
EXPR

        cat > src/controllers/example.controller.js << 'EXPR'
export const getAll = (_req, res) => {
  res.json({ message: 'Hello from Express!', items: [] });
};
EXPR

        # ── .env ────────────────────────────────────────────
        {
            echo "PORT=5000"
            echo "CLIENT_ORIGIN=http://localhost:3000"
            echo "NODE_ENV=development"
            if [[ "$DB_CHOICE" != "None"* ]]; then
                echo ""
                echo "# Database"
                echo "DB_HOST=${DB_HOST}"
                echo "DB_PORT=${DB_PORT}"
                echo "DB_NAME=${DB_NAME}"
                echo "DB_USER=${DB_USER}"
                echo "DB_PASS=${DB_PASS}"
            fi
        } > .env
        cp .env .env.example

        cat > .gitignore << 'GIGN'
node_modules/
.env
dist/
GIGN

        success "Express backend ready → ${target_dir}"

    # ── Django + DRF ───────────────────────────────────────────
    elif [[ "$BACKEND_CHOICE" == *"Django"* ]]; then
        check_cmd python3; check_cmd pip3

        info "Creating Python virtual environment..."
        python3 -m venv venv
        # shellcheck disable=SC1091
        source venv/bin/activate

        local pip_pkgs="django djangorestframework python-dotenv django-cors-headers"
        if [[ "$DB_CHOICE" == "PostgreSQL" ]]; then
            pip_pkgs="$pip_pkgs psycopg2-binary"
            info "Adding psycopg2 (PostgreSQL driver)..."
        elif [[ "$DB_CHOICE" == "MySQL" ]]; then
            pip_pkgs="$pip_pkgs mysqlclient"
            info "Adding mysqlclient (MySQL driver)..."
        fi

        info "Installing Python dependencies..."
        pip install --quiet $pip_pkgs

        info "Starting Django project..."
        django-admin startproject config .

        info "Creating 'api' app..."
        python manage.py startapp api

        # ── Write settings.py from template (robust, no string patching) ──
        info "Writing settings.py from template..."

        # Grab the secret key Django generated
        DJANGO_GEN_SECRET=$(python -c "
import subprocess, re
result = subprocess.run(['python', 'manage.py', 'shell', '-c',
    'from django.conf import settings; print(settings.SECRET_KEY)'],
    capture_output=True, text=True)
print(result.stdout.strip())
")

        # Determine DB engine block
        local db_engine_block=""
        if [[ "$DB_CHOICE" == "PostgreSQL" ]]; then
            db_engine_block="
DATABASES = {
    'default': {
        'ENGINE':   'django.db.backends.postgresql',
        'NAME':     os.getenv('DB_NAME', '${DB_NAME}'),
        'USER':     os.getenv('DB_USER', '${DB_USER}'),
        'PASSWORD': os.getenv('DB_PASS', '${DB_PASS}'),
        'HOST':     os.getenv('DB_HOST', '${DB_HOST}'),
        'PORT':     os.getenv('DB_PORT', '${DB_PORT}'),
    }
}"
        elif [[ "$DB_CHOICE" == "MySQL" ]]; then
            db_engine_block="
DATABASES = {
    'default': {
        'ENGINE':   'django.db.backends.mysql',
        'NAME':     os.getenv('DB_NAME', '${DB_NAME}'),
        'USER':     os.getenv('DB_USER', '${DB_USER}'),
        'PASSWORD': os.getenv('DB_PASS', '${DB_PASS}'),
        'HOST':     os.getenv('DB_HOST', '${DB_HOST}'),
        'PORT':     os.getenv('DB_PORT', '${DB_PORT}'),
    }
}"
        else
            db_engine_block="
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME':   BASE_DIR / 'db.sqlite3',
    }
}"
        fi

        # Write complete settings.py from scratch
        cat > config/settings.py << SETTINGS
\"\"\"
Django settings for config project.
Generated by setup_app.sh — do not hand-edit the structure.
\"\"\"

import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = os.getenv('DJANGO_SECRET_KEY', '${DJANGO_GEN_SECRET}')
DEBUG      = os.getenv('DEBUG', 'True') == 'True'
ALLOWED_HOSTS = os.getenv('ALLOWED_HOSTS', 'localhost,127.0.0.1').split(',')

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    # Third-party
    'rest_framework',
    'corsheaders',
    # Local
    'api',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS':    [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'

${db_engine_block}

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

LANGUAGE_CODE = 'en-us'
TIME_ZONE     = 'UTC'
USE_I18N      = True
USE_TZ        = True

STATIC_URL = 'static/'
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# ── CORS ──────────────────────────────────────────────────────────
CORS_ALLOWED_ORIGINS = os.getenv(
    'CORS_ALLOWED_ORIGINS', 'http://localhost:3000'
).split(',')

# ── Django REST Framework ─────────────────────────────────────────
REST_FRAMEWORK = {
    'DEFAULT_RENDERER_CLASSES':     ['rest_framework.renderers.JSONRenderer'],
    'DEFAULT_AUTHENTICATION_CLASSES': [],
    'DEFAULT_PERMISSION_CLASSES':     [],
}
SETTINGS

        cat > config/urls.py << 'DURLS'
from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse

def health(request):
    return JsonResponse({'status': 'ok'})

urlpatterns = [
    path('admin/', admin.site.urls),
    path('health/', health),
    path('api/', include('api.urls')),
]
DURLS

        cat > api/urls.py << 'AURLS'
from django.urls import path
from .views import ExampleView

urlpatterns = [
    path('example/', ExampleView.as_view(), name='example'),
]
AURLS

        cat > api/views.py << 'AVIEWS'
from rest_framework.views import APIView
from rest_framework.response import Response

class ExampleView(APIView):
    def get(self, request):
        return Response({'message': 'Hello from Django + DRF!', 'items': []})
AVIEWS

        # ── .env ──────────────────────────────────────────────
        {
            echo "DJANGO_SECRET_KEY=change-me-in-production"
            echo "DEBUG=True"
            echo "ALLOWED_HOSTS=localhost,127.0.0.1"
            echo "CORS_ALLOWED_ORIGINS=http://localhost:3000"
            if [[ "$DB_CHOICE" != "None"* ]]; then
                echo ""
                echo "# Database"
                echo "DB_HOST=${DB_HOST}"
                echo "DB_PORT=${DB_PORT}"
                echo "DB_NAME=${DB_NAME}"
                echo "DB_USER=${DB_USER}"
                echo "DB_PASS=${DB_PASS}"
            fi
        } > .env
        cp .env .env.example

        info "Running initial migrations..."
        python manage.py migrate --run-syncdb 2>/dev/null || python manage.py migrate

        pip freeze > requirements.txt

        cat > .gitignore << 'GIGN'
venv/
__pycache__/
*.pyc
.env
db.sqlite3
media/
staticfiles/
GIGN

        deactivate
        success "Django + DRF backend ready → ${target_dir}"
    fi

    cd "$ORIGIN_DIR"
}

# ================================================================
#  FRONTEND SETUP
# ================================================================
setup_frontend() {
    local target_dir="$1"
    local parent_dir dir_name
    parent_dir="$(dirname "$target_dir")"
    dir_name="$(basename "$target_dir")"

    check_cmd node
    [[ "$PKG_MGR" == "pnpm" ]] && check_cmd pnpm
    [[ "$PKG_MGR" == "yarn" ]] && check_cmd yarn

    divider
    echo -e "\n${BOLD}${YELLOW}⬡  Setting up Frontend...${RESET}\n"

    cd "$parent_dir"

    # ── React via Vite ──────────────────────────────────────────
    if [[ "$FRONTEND_CHOICE" == "React (Vite)" ]]; then
        info "Scaffolding React + Vite..."
        case "$PKG_MGR" in
            pnpm) pnpm create vite "$dir_name" --template react ;;
            yarn) yarn create vite "$dir_name" --template react ;;
            *)    npm create vite@latest "$dir_name" -- --template react ;;
        esac
        cd "$dir_name"
        case "$PKG_MGR" in
            pnpm) pnpm install ;;
            yarn) yarn ;;
            *)    npm install --silent ;;
        esac
        case "$PKG_MGR" in
            pnpm) pnpm add axios ;;
            yarn) yarn add axios ;;
            *)    npm install --silent axios ;;
        esac
        mkdir -p src/api src/components src/pages src/hooks src/context
        cat > src/api/client.js << AXCLIENT
import axios from 'axios';

// Base URL is set via .env — update VITE_API_URL when deploying
// to a remote backend (e.g. https://api.myapp.com)
const client = axios.create({
  baseURL: import.meta.env.VITE_API_URL || '${BACKEND_API_URL}',
  headers: { 'Content-Type': 'application/json' },
});

export default client;
AXCLIENT
        echo "VITE_API_URL=${BACKEND_API_URL}" > .env
        cp .env .env.example

    # ── Vue via Vite ────────────────────────────────────────────
    elif [[ "$FRONTEND_CHOICE" == "Vue (Vite)" ]]; then
        info "Scaffolding Vue + Vite..."
        case "$PKG_MGR" in
            pnpm) pnpm create vite "$dir_name" --template vue ;;
            yarn) yarn create vite "$dir_name" --template vue ;;
            *)    npm create vite@latest "$dir_name" -- --template vue ;;
        esac
        cd "$dir_name"
        case "$PKG_MGR" in
            pnpm) pnpm install ;;
            yarn) yarn ;;
            *)    npm install --silent ;;
        esac
        case "$PKG_MGR" in
            pnpm) pnpm add axios ;;
            yarn) yarn add axios ;;
            *)    npm install --silent axios ;;
        esac
        mkdir -p src/api src/components src/views src/composables src/stores
        cat > src/api/client.js << AXCLIENT
import axios from 'axios';

// Base URL is set via .env — update VITE_API_URL when deploying
// to a remote backend (e.g. https://api.myapp.com)
const client = axios.create({
  baseURL: import.meta.env.VITE_API_URL || '${BACKEND_API_URL}',
  headers: { 'Content-Type': 'application/json' },
});

export default client;
AXCLIENT
        echo "VITE_API_URL=${BACKEND_API_URL}" > .env
        cp .env .env.example

    # ── Next.js ─────────────────────────────────────────────────
    elif [[ "$FRONTEND_CHOICE" == "Next.js" ]]; then
        info "Scaffolding Next.js (App Router, TypeScript, Tailwind)..."
        case "$PKG_MGR" in
            pnpm) pnpm create next-app "$dir_name" --typescript --eslint --tailwind --app --src-dir --import-alias "@/*" --use-pnpm ;;
            yarn) yarn create next-app "$dir_name" --typescript --eslint --tailwind --app --src-dir --import-alias "@/*" --use-yarn ;;
            *)    npx create-next-app@latest "$dir_name" --typescript --eslint --tailwind --app --src-dir --import-alias "@/*" ;;
        esac
        cd "$dir_name"
        case "$PKG_MGR" in
            pnpm) pnpm add axios ;;
            yarn) yarn add axios ;;
            *)    npm install --silent axios ;;
        esac
        mkdir -p src/lib src/components src/hooks src/types
        cat > src/lib/apiClient.ts << AXCLIENT
import axios from 'axios';

// Base URL is set via .env.local — update NEXT_PUBLIC_API_URL when
// deploying to a remote backend (e.g. https://api.myapp.com)
const apiClient = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || '${BACKEND_API_URL}',
  headers: { 'Content-Type': 'application/json' },
});

export default apiClient;
AXCLIENT
        echo "NEXT_PUBLIC_API_URL=${BACKEND_API_URL}" > .env.local
        cat > .env.example << ENVEX
NEXT_PUBLIC_API_URL=${BACKEND_API_URL}
ENVEX
    fi

    printf '\n# Local env — never commit\n.env\n.env.local\n' >> .gitignore

    success "Frontend ready → ${target_dir}"
    cd "$ORIGIN_DIR"
}

# ================================================================
#  DOCKER GENERATION
# ================================================================
write_docker() {
    info "Writing Docker files..."

    local compose_file="${ROOT_DIR}/docker-compose.yml"

    # ── Backend Dockerfile ──────────────────────────────────────
    if $WANTS_BACKEND; then
        local be_dir
        case "$SCAFFOLD_MODE" in
            *"backend only"*) be_dir="${ROOT_DIR}" ;;
            *)                be_dir="${ROOT_DIR}/backend" ;;
        esac

        if [[ "$BACKEND_CHOICE" == *"Express"* ]]; then
            cat > "${be_dir}/Dockerfile" << 'DFILE'
FROM node:20-alpine AS base
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
EXPOSE 5000
CMD ["node", "src/index.js"]
DFILE
        elif [[ "$BACKEND_CHOICE" == *"Django"* ]]; then
            cat > "${be_dir}/Dockerfile" << 'DFILE'
FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
DFILE
        fi
    fi

    # ── Frontend Dockerfile ─────────────────────────────────────
    if $WANTS_FRONTEND; then
        local fe_dir
        case "$SCAFFOLD_MODE" in
            *"frontend only"*) fe_dir="${ROOT_DIR}" ;;
            *)                 fe_dir="${ROOT_DIR}/frontend" ;;
        esac

        if [[ "$FRONTEND_CHOICE" == "Next.js" ]]; then
            cat > "${fe_dir}/Dockerfile" << 'DFILE'
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci

FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
EXPOSE 3000
CMD ["node", "server.js"]
DFILE
        else
            cat > "${fe_dir}/Dockerfile" << 'DFILE'
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
DFILE
        fi
    fi

    # ── docker-compose.yml ──────────────────────────────────────
    {
        echo "version: '3.9'"
        echo ""
        echo "services:"

        # backend service
        if $WANTS_BACKEND; then
            local be_context
            case "$SCAFFOLD_MODE" in
                *"backend only"*) be_context="." ;;
                *)                be_context="./backend" ;;
            esac
            local be_port
            [[ "$BACKEND_CHOICE" == *"Express"* ]] && be_port="5000" || be_port="8000"

            echo "  backend:"
            echo "    build: ${be_context}"
            echo "    ports:"
            echo "      - \"${be_port}:${be_port}\""
            echo "    env_file:"
            echo "      - ${be_context}/.env"
            if [[ "$DB_CHOICE" != "None"* ]]; then
                echo "    depends_on:"
                echo "      - db"
            fi
            echo "    restart: unless-stopped"
            echo ""
        fi

        # frontend service
        if $WANTS_FRONTEND; then
            local fe_context
            case "$SCAFFOLD_MODE" in
                *"frontend only"*) fe_context="." ;;
                *)                 fe_context="./frontend" ;;
            esac
            local fe_port
            [[ "$FRONTEND_CHOICE" == "Next.js" ]] && fe_port="3000" || fe_port="80"

            echo "  frontend:"
            echo "    build: ${fe_context}"
            echo "    ports:"
            echo "      - \"${fe_port}:${fe_port}\""
            echo "    restart: unless-stopped"
            echo ""
        fi

        # database service
        if [[ "$DB_CHOICE" == "PostgreSQL" ]]; then
            echo "  db:"
            echo "    image: postgres:16-alpine"
            echo "    environment:"
            echo "      POSTGRES_DB:       ${DB_NAME}"
            echo "      POSTGRES_USER:     ${DB_USER}"
            echo "      POSTGRES_PASSWORD: ${DB_PASS}"
            echo "    ports:"
            echo "      - \"${DB_PORT}:5432\""
            echo "    volumes:"
            echo "      - db_data:/var/lib/postgresql/data"
            echo "    restart: unless-stopped"
            echo ""
            echo "volumes:"
            echo "  db_data:"
        elif [[ "$DB_CHOICE" == "MySQL" ]]; then
            echo "  db:"
            echo "    image: mysql:8"
            echo "    environment:"
            echo "      MYSQL_DATABASE:      ${DB_NAME}"
            echo "      MYSQL_USER:          ${DB_USER}"
            echo "      MYSQL_PASSWORD:      ${DB_PASS}"
            echo "      MYSQL_ROOT_PASSWORD: rootpassword"
            echo "    ports:"
            echo "      - \"${DB_PORT}:3306\""
            echo "    volumes:"
            echo "      - db_data:/var/lib/mysql"
            echo "    restart: unless-stopped"
            echo ""
            echo "volumes:"
            echo "  db_data:"
        fi
    } > "$compose_file"

    # root .dockerignore
    cat > "${ROOT_DIR}/.dockerignore" << 'DIGN'
node_modules/
venv/
__pycache__/
*.pyc
.env
.env.local
.git/
dist/
.next/
DIGN

    success "Docker files written."
}

# ================================================================
#  DISPATCH
# ================================================================
case "$SCAFFOLD_MODE" in
    *"full-stack"*)
        setup_backend  "${ROOT_DIR}/backend"
        setup_frontend "${ROOT_DIR}/frontend"
        ;;
    *"backend only"*)
        setup_backend "${ROOT_DIR}"
        ;;
    *"frontend only"*)
        setup_frontend "${ROOT_DIR}"
        ;;
    "Add backend to existing frontend project")
        setup_backend "${ROOT_DIR}/backend"
        ;;
    "Add frontend to existing backend project")
        setup_frontend "${ROOT_DIR}/frontend"
        ;;
esac

# ── Docker ───────────────────────────────────────────────────────
[[ "$WANT_DOCKER" == "Yes" ]] && write_docker

# ── Root .gitignore (only for new full-stack projects) ───────────
if [[ "$SCAFFOLD_MODE" == *"full-stack"* ]]; then
    cat > "${ROOT_DIR}/.gitignore" << 'GIGN'
# OS
.DS_Store
Thumbs.db

# Editors
.vscode/
.idea/

# Env files — never commit secrets
.env
.env.local
.env*.local
# allow examples
!.env.example
GIGN
fi

# ── Root README ──────────────────────────────────────────────────
{
    echo "# ${PROJECT_NAME}"
    echo ""
    echo "> Generated by \`setup_app.sh\`"
    echo ""
    echo "| Layer    | Technology |"
    echo "|----------|------------|"
    [[ -n "$BACKEND_CHOICE"  ]] && echo "| Backend  | ${BACKEND_CHOICE} |"
    [[ "$DB_CHOICE" != "None"* ]] && echo "| Database | ${DB_CHOICE} |"
    [[ -n "$FRONTEND_CHOICE" ]] && echo "| Frontend | ${FRONTEND_CHOICE} |"
} > "${ROOT_DIR}/README.md"

# ── Git init ─────────────────────────────────────────────────────
if [[ "$INIT_GIT" == "Yes" ]]; then
    cd "${ROOT_DIR}"
    check_cmd git
    info "Initialising Git repository..."
    git init -q
    git add .
    git commit -q -m "chore: initial scaffold via setup_app.sh"
    success "Git repository initialised."
fi

# ================================================================
#  DONE
# ================================================================
divider
echo ""
echo -e "${GREEN}${BOLD}  ✅  All done! Your project is ready.${RESET}"
echo ""

echo -e "  ${BOLD}Layout:${RESET}"
case "$SCAFFOLD_MODE" in
    *"full-stack"*)
        echo -e "  ${CYAN}${PROJECT_NAME}/${RESET}"
        echo -e "  ├── backend/    ${BACKEND_CHOICE}"
        echo -e "  ├── frontend/   ${FRONTEND_CHOICE}"
        [[ "$WANT_DOCKER" == "Yes" ]] && echo -e "  └── docker-compose.yml"
        echo ""
        echo -e "  ${BOLD}Start backend:${RESET}"
        if [[ "$BACKEND_CHOICE" == *"Express"* ]]; then
            echo -e "  ${CYAN}cd ${PROJECT_NAME}/backend && ${PKG_MGR} run dev${RESET}"
        else
            echo -e "  ${CYAN}cd ${PROJECT_NAME}/backend && source venv/bin/activate && python manage.py runserver${RESET}"
        fi
        echo -e "  ${BOLD}Start frontend:${RESET}"
        echo -e "  ${CYAN}cd ${PROJECT_NAME}/frontend && ${PKG_MGR} run dev${RESET}"
        ;;
    *"backend only"*|"Add backend"*)
        echo -e "  ${CYAN}${PROJECT_NAME}/${RESET}  (${BACKEND_CHOICE})"
        echo ""
        echo -e "  ${BOLD}Start:${RESET}"
        if [[ "$BACKEND_CHOICE" == *"Express"* ]]; then
            echo -e "  ${CYAN}cd ${PROJECT_NAME} && ${PKG_MGR} run dev${RESET}"
        else
            echo -e "  ${CYAN}cd ${PROJECT_NAME} && source venv/bin/activate && python manage.py runserver${RESET}"
        fi
        ;;
    *"frontend only"*|"Add frontend"*)
        echo -e "  ${CYAN}${PROJECT_NAME}/${RESET}  (${FRONTEND_CHOICE})"
        echo ""
        echo -e "  ${BOLD}Start:${RESET}"
        echo -e "  ${CYAN}cd ${PROJECT_NAME} && ${PKG_MGR} run dev${RESET}"
        ;;
esac

if [[ "$WANT_DOCKER" == "Yes" ]]; then
    echo ""
    echo -e "  ${BOLD}Or run everything with Docker:${RESET}"
    echo -e "  ${CYAN}cd ${PROJECT_NAME} && docker compose up --build${RESET}"
fi

if [[ "$DB_CHOICE" != "None"* ]]; then
    echo ""
    echo -e "  ${YELLOW}${BOLD}⚠  Database:${RESET} make sure ${DB_CHOICE} is running and"
    echo -e "     credentials in ${PROJECT_NAME}/.env match your setup."
    [[ "$WANT_DOCKER" == "Yes" ]] && \
        echo -e "     Or just use ${CYAN}docker compose up${RESET} — the DB service is included."
fi

echo ""
divider
