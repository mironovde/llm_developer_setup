# LabMarket CRM — Project Conventions for Claude

> Last verified: 2026-05-29
> Наследует глобальный протокол `~/.claude/CLAUDE.md`. Здесь — только project-specific.
> (`AGENTS.md` в корне — это конфиг Codex CLI, НЕ для Claude. Не путать.)

## Workflow — GSD спайн (автономный движок)

Репо ведётся через **GSD** (`.planning/`). Для любой feature/bugfix/refactor → GSD:
`/gsd-progress` (где я) → `/gsd-plan-phase` → `/gsd-execute-phase` → `/gsd-verify-work` → `/gsd-secure-phase`.
`config.json`: модели = sonnet (все роли), `research + parallel agents`, `auto_commit: true`.
НЕ вызывай superpowers поверх GSD (см. global PIPELINE).

## Stack

- **Backend**: Python 3.12 микросервисы (FastAPI + structlog + pydantic v2), по одному `services/<svc>/` с собственным `requirements.txt` + `Dockerfile`.
- **Frontend**: Next.js + Biome (format) + ESLint, `frontend/`.
- **Bridge**: `bridge_1c` (интеграция с 1С), `browser_fetcher` (Node.js).
- **Events/infra**: см. `.planning/` + docker-compose.

## Сервисы (services/)

`analytics`, `auth`, `bridge_1c`, `browser_fetcher` (Node), `catalog`, `gateway`, `ingest`, `logistics`, `notifications`, `public_status`, `specs`, `tasks`, `tenders`, `warehouse`.

Изменение в сервисе → его тесты гейтятся отдельным workflow `test-<svc>.yml`.

## Security (152-ФЗ / PII — критично)

Проект под российский 152-ФЗ (персональные данные). **Перед любой работой с auth / PII / платежами → прочитай `~/.claude/SECURITY.md`.**

- **`@require_role` обязателен** на FastAPI routes — enforced линтером REQ001 (`services/*/app/routes/*.py`). Роут без декоратора = pre-commit fail.
- **PII map**: `shared.pii_report` генерит `pii-map.md`; pre-commit проверяет актуальность при изменении `services/*/models.py`. Меняешь модель с PII → обнови карту.
- **Enforcement активен**: `.pre-commit-config.yaml` (gitleaks, bandit, flake8 REQ001, frontend eslint/biome) + CI `security.yml` (pip-audit×services, npm audit, gitleaks, trivy, semgrep, SBOM → aggregator блокирует HIGH+).

## Dev команды

```bash
# Frontend
cd frontend && npm run dev
cd frontend && npx biome format src      # формат-чек
cd frontend && npx eslint src            # lint (incl. security)

# Backend (per service)
cd services/<svc> && uvicorn app.main:app --reload

# Pre-commit baseline
pre-commit run --all-files
```

## Conventions

- Новый endpoint → `@require_role` + input validation (pydantic) + per-row authz. См. SECURITY.
- Новый сервис → следуй раскладке существующих `services/<svc>/` (app/, tests/, requirements.txt, Dockerfile).
- Атомарные коммиты, conventional commits, feature-ветки (текущая работа на `chore/v25.2-followups`).
