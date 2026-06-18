# Project Status

## Overview
- **Project**: LLM Developer Setup — entry point + бэкап/синк глобальной конфигурации Claude Code
- **Last Updated**: 2026-06-18
- **Type**: живой шаблон/конфиг-репозиторий (не sprint-проект)

## Что это репо делает
1. **Entry point** для новых проектов (skills `.claude/skills/`, `.mcp.json`, шаблон workflow).
2. **Версионируемый бэкап** глобального `~/.claude/` (`backups/<dated>/`).
3. **Перенос между машинами** пользовательских хуков (`claude-sync/` + `install.sh`).

## Completed Features
- 🟢 Набор project-local skills (`.claude/skills/`)
- 🟢 Шаблоны безопасности (`templates/security/`)
- 🟢 Слой автономной работы (хуки driver/watchdog/heartbeat/guards) + бэкап в `backups/`
- 🟢 **Снапшот конфигурации 2026-06-18** (`backups/config-refresh-2026-06-18/`): живой `settings.json` + 7 project-CLAUDE.md
- 🟢 **`claude-sync/`** — каноничные 9 пользовательских хуков + идемпотентный `install.sh` ($HOME-relative, `--dry-run`/`--no-launchd`), шаблон watchdog-plist

## Architecture Decisions
- **Разделение владения хуками**: 9 пользовательских хуков версионируются здесь (`claude-sync/`); ~12 хуков фреймворка GSD НЕ дублируются (управляются апдейтером GSD — иначе устареют).
- **Overlay-модель переноса**: на новой машине = установить GSD → `git clone` → `claude-sync/install.sh` → дотащить `settings.json`/`CLAUDE.md` из `backups/`.
- **launchd-plist как шаблон** (`__HOME__`): живой plist содержал захардкоженный `/Users/...`; установщик подставляет `$HOME`.

## Next Steps
1. [ ] (опционально) Нормализовать переносимость проводки в `settings.json`: `/opt/homebrew/bin/node` → `node`, `/Users/<name>/.claude` → `~/.claude`; положить переносимый `settings.json` в `claude-sync/`.
2. [ ] (опционально) Решить судьбу устаревшего локального патча `gsd-statusline.js` (v1.38.3 vs живой v1.42.3).

## Blockers & Issues
- Нет активных блокеров.
- Known issue (non-blocking): проводка хуков в `settings.json` пока не переносима (абсолютный путь к node + пути `/Users/...`). Задокументировано в `claude-sync/README.md`.

## Recent Activity

### 2026-06-18
- ✅ Проверка актуальности конфигурации Claude на git (глобальной и проектной)
- ✅ `backups/config-refresh-2026-06-18/` — снапшот живого `settings.json` + 7 project-CLAUDE.md (commit `74eb710`)
- ✅ `claude-sync/` — переносимые пользовательские хуки + `install.sh` (commit `4dc40fb`)
- 🔎 Разобран дрейф локального патча `gsd-statusline.js` (устаревший артефакт, pristine не восстановим)

---
*Updated manually 2026-06-18 (session wrap-up)*
