# LabMarket CRM — Project Conventions for Claude

> Last verified: 2026-05-29
> Inherits the global protocol `~/.claude/CLAUDE.md`. This file contains only project-specific rules.
> (`AGENTS.md` in the root is a Codex CLI config, NOT for Claude. Don't confuse them.)

## Workflow — GSD spine (autonomous engine)

The repo is driven through **GSD** (`.planning/`). For any feature/bugfix/refactor → GSD:
`/gsd-progress` (where am I) → `/gsd-plan-phase` → `/gsd-execute-phase` → `/gsd-verify-work` → `/gsd-secure-phase`.
`config.json`: models = sonnet (all roles), `research + parallel agents`, `auto_commit: true`.
Do NOT invoke superpowers on top of GSD (see global PIPELINE).

## Stack

- **Backend**: Python 3.12 microservices (FastAPI + structlog + pydantic v2), one per `services/<svc>/` with its own `requirements.txt` + `Dockerfile`.
- **Frontend**: Next.js + Biome (format) + ESLint, `frontend/`.
- **Bridge**: `bridge_1c` (1C integration), `browser_fetcher` (Node.js).
- **Events/infra**: see `.planning/` + docker-compose.

## Services (services/)

`analytics`, `auth`, `bridge_1c`, `browser_fetcher` (Node), `catalog`, `gateway`, `ingest`, `logistics`, `notifications`, `public_status`, `specs`, `tasks`, `tenders`, `warehouse`.

A change in a service → its tests are gated by a separate workflow `test-<svc>.yml`.

## Security (152-FZ / PII — critical)

The project falls under the Russian 152-FZ (Russian personal-data law) (personal data). **Before any work with auth / PII / payments → read `~/.claude/SECURITY.md`.**

- **`@require_role` is mandatory** on FastAPI routes — enforced by linter REQ001 (`services/*/app/routes/*.py`). A route without the decorator = pre-commit fail.
- **PII map**: `shared.pii_report` generates `pii-map.md`; pre-commit checks it is up to date whenever `services/*/models.py` changes. If you change a model with PII → update the map.
- **Enforcement is active**: `.pre-commit-config.yaml` (gitleaks, bandit, flake8 REQ001, frontend eslint/biome) + CI `security.yml` (pip-audit×services, npm audit, gitleaks, trivy, semgrep, SBOM → aggregator blocks HIGH+).

## Dev commands

```bash
# Frontend
cd frontend && npm run dev
cd frontend && npx biome format src      # format check
cd frontend && npx eslint src            # lint (incl. security)

# Backend (per service)
cd services/<svc> && uvicorn app.main:app --reload

# Pre-commit baseline
pre-commit run --all-files
```

## Conventions

- New endpoint → `@require_role` + input validation (pydantic) + per-row authz. See SECURITY.
- New service → follow the layout of the existing `services/<svc>/` (app/, tests/, requirements.txt, Dockerfile).
- Atomic commits, conventional commits, feature branches (current work on `chore/v25.2-followups`).
