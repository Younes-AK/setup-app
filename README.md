<div align="center">

```
  ███████╗███████╗████████╗██╗   ██╗██████╗      █████╗ ██████╗ ██████╗
  ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗    ██╔══██╗██╔══██╗██╔══██╗
  ███████╗█████╗     ██║   ██║   ██║██████╔╝    ███████║██████╔╝██████╔╝
  ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝     ██╔══██║██╔═══╝ ██╔═══╝
  ███████║███████╗   ██║   ╚██████╔╝██║         ██║  ██║██║     ██║
  ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝         ╚═╝  ╚═╝╚═╝     ╚═╝
```

# setup\_app.sh

**Smart full-stack project scaffolding for Linux — one script, zero config, ready to code.**

![Bash](https://img.shields.io/badge/Bash-5.x-4EAA25?style=flat-square&logo=gnubash&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Linux-FCC624?style=flat-square&logo=linux&logoColor=black)
![Backend](https://img.shields.io/badge/Backend-Express%20%7C%20Django%20DRF-informational?style=flat-square)
![Frontend](https://img.shields.io/badge/Frontend-React%20%7C%20Vue%20%7C%20Next.js-61DAFB?style=flat-square)

</div>

---

## What is this?

`setup_app.sh` is an interactive Bash script that spins up a complete, production-ready full-stack project in seconds. It asks you a handful of questions, then creates a clean `backend/` + `frontend/` directory layout, installs all dependencies, wires up environment files, and optionally commits everything to Git — so you can open your editor and start writing actual code immediately.

No Yeoman. No global CLIs to install. Just Bash.

---

## Demo

```
  ⬡  BACKEND
  Choose a backend framework:
    [1] Express (Node.js)
    [2] Django + DRF (Python)
  → Enter choice [1-2]: 1

  ⬡  FRONTEND
  Choose a frontend framework:
    [1] React (Vite)
    [2] Vue (Vite)
    [3] Next.js
  → Enter choice [1-3]: 3

  ⬡  PACKAGE MANAGER
    [1] npm   [2] pnpm   [3] yarn
  → Enter choice [1-3]: 2

  Initialize a Git repository? [1] Yes  [2] No
  → Enter choice [1-2]: 1

  ✅  All done! Your project is ready.
```

---

## Generated Structure

```
my-app/
├── backend/                  # API server
│   ├── src/
│   │   ├── routes/
│   │   ├── controllers/
│   │   ├── middleware/
│   │   └── index.js
│   ├── .env / .env.example
│   ├── package.json
│   └── .gitignore
│
├── frontend/                 # UI app
│   ├── src/
│   │   ├── api/              # pre-configured axios client
│   │   ├── components/
│   │   ├── pages/ (or views/ for Vue)
│   │   └── hooks/
│   ├── .env / .env.example
│   └── .gitignore
│
├── README.md
└── .gitignore
```

---

## Supported Stack Combinations

| Backend | Frontend | Notes |
|---------|----------|-------|
| **Express** (Node.js) | React (Vite) | ES modules, nodemon, axios pre-wired |
| **Express** (Node.js) | Vue (Vite) | Same + Vue composables/stores folders |
| **Express** (Node.js) | Next.js | TypeScript + Tailwind + App Router |
| **Django + DRF** (Python) | React (Vite) | venv auto-created, settings patched |
| **Django + DRF** (Python) | Vue (Vite) | CORS + DRF configured out of the box |
| **Django + DRF** (Python) | Next.js | `requirements.txt` generated |

**Package managers supported:** `npm` · `pnpm` · `yarn`

---

## What each setup includes

### Express backend
- `express`, `cors`, `helmet`, `morgan`, `dotenv` installed
- `nodemon` as dev dependency
- ES module (`"type": "module"`) enabled
- `src/routes/`, `src/controllers/`, `src/middleware/`, `src/config/` structure
- Example route + controller at `GET /api/example`
- `GET /health` endpoint
- `.env` + `.env.example` pre-filled

### Django + DRF backend
- Python virtual environment created automatically
- `django`, `djangorestframework`, `django-cors-headers`, `python-dotenv` installed
- Project bootstrapped via `django-admin startproject config .`
- `api/` app created and registered
- `settings.py` auto-patched: CORS, REST_FRAMEWORK, dotenv loading, ALLOWED_HOSTS
- Example API view at `GET /api/example/`
- `requirements.txt` generated from `pip freeze`
- `.env` + `.env.example` pre-filled

### React / Vue (Vite) frontend
- Vite scaffold with the chosen template
- `axios` installed with a pre-configured `src/api/client.js`
- Folder structure: `components/`, `pages/` or `views/`, `hooks/`, `context/` or `composables/`, `stores/`
- `VITE_API_URL` env var pointing to backend

### Next.js frontend
- `create-next-app` with **TypeScript + Tailwind CSS + App Router + `src/` directory**
- `axios` installed with `src/lib/apiClient.ts`
- Folder structure: `components/`, `hooks/`, `types/`
- `NEXT_PUBLIC_API_URL` env var pointing to backend

---

## Requirements

| Dependency | Required for |
|------------|-------------|
| `bash` 5.x | Running the script |
| `node` + `npm` | Express backend & any JS frontend |
| `pnpm` or `yarn` | If selected as package manager |
| `python3` + `pip3` | Django + DRF backend |
| `git` | Optional — only if you choose to init a repo |

The script checks for required tools before doing anything and exits with a clear error if something is missing.

---

## Installation & Usage

```bash
# 1. Download the script
curl -O https://github.com/Younes-AK/setup-app/blob/master/setup-app.sh

# 2. Make it executable
chmod +x setup_app.sh

# 3. Run it
./setup_app.sh
```

Or clone the repo:

```bash
git https://github.com/Younes-AK/setup-app/blob/master/setup-app.sh
cd setup-app
chmod +x setup_app.sh
./setup_app.sh
```

> **Tip:** Move it somewhere on your `$PATH` (e.g. `/usr/local/bin/setup_app`) to use it from anywhere.

```bash
sudo mv setup_app.sh /usr/local/bin/setup_app
setup_app   # run from any directory
```

---

## After Scaffolding

### Express + any frontend

```bash
# Terminal 1 — backend
cd my-app/backend
cp .env.example .env
npm run dev          # http://localhost:5000

# Terminal 2 — frontend
cd my-app/frontend
cp .env.example .env
npm run dev          # http://localhost:3000
```

### Django + any frontend

```bash
# Terminal 1 — backend
cd my-app/backend
source venv/bin/activate
cp .env.example .env
python manage.py migrate
python manage.py runserver   # http://localhost:8000

# Terminal 2 — frontend
cd my-app/frontend
cp .env.example .env
npm run dev                  # http://localhost:3000
```

---

## Safety

- **Checks for existing directories** — refuses to overwrite a folder with the same project name.
- **Validates required tools** before touching anything.
- **Shows a full summary** and asks for confirmation before creating any files.
- Uses `set -euo pipefail` — stops immediately on any error.

---

## Contributing

Pull requests are welcome! Some ideas for future additions:

- [ ] PostgreSQL / MySQL setup option
- [ ] Docker Compose generation
- [ ] `--non-interactive` / flag-based mode for CI pipelines
- [ ] Svelte / Astro frontend options
- [ ] FastAPI backend option
- [ ] Monorepo mode (single `package.json` at root with workspaces)

---

## License

MIT — do whatever you want with it.

---

<div align="center">
Made with ☕ and Bash
</div>
