# claude-sync — переносимые пользовательские хуки Claude Code

Каноничный, версионируемый источник **пользовательских** хуков Claude Code и
установщик для переноса их между машинами.

## Что здесь

```
claude-sync/
  hooks/                     # 9 пользовательских хуков (канон, держим в актуальном виде)
  launchd/
    com.claude.autonomous-watchdog.plist.template   # шаблон с __HOME__
  install.sh                 # идемпотентный установщик: repo -> ~/.claude
  README.md
```

## Какие хуки сюда входят (и почему именно эти)

Только **пользовательские** хуки — те, что **не** ставит и не обновляет сам GSD:

| Хук | Назначение | Проводка (settings.json) |
|-----|------------|--------------------------|
| `gsd-autonomous-driver.js` | Stop-driver автономного цикла | `Stop` |
| `gsd-autonomous-heartbeat.sh` | PostToolUse heartbeat | `PostToolUse` |
| `gsd-autonomous-watchdog.sh` | launchd-воскрешение сессии | launchd (не settings) |
| `gsd-cross-project-guard.sh` | блок деструктива по чужим/shared путям | `PreToolUse(Bash)` |
| `gsd-team-archive.sh` | reaper забытых team | `SessionStart` |
| `pipeline-reminder.sh` | напоминание о pipeline | `UserPromptSubmit` |
| `auto-format.sh` | автоформат после правок | `PostToolUse(Edit\|Write)` |
| `legal-deploy-check.sh` | legal-проверка на deploy/build | `PreToolUse(Bash)` |
| `pre-commit-check.sh` | проверки перед коммитом | `PreToolUse(Bash)` |

**Не входят** (≈12 шт.): хуки фреймворка GSD (`gsd-statusline.js`,
`gsd-context-monitor.js`, `gsd-prompt-guard.js`, `gsd-read-guard.js`,
`gsd-workflow-guard.js`, `gsd-validate-commit.sh`, `gsd-check-update*.js`,
`gsd-phase-boundary.sh`, `gsd-session-state.sh`, `gsd-read-injection-scanner.js`,
`gsd-update-banner.js`). Они регенерируются установкой/апдейтом GSD — дублировать
их здесь нельзя (устареют на каждом апдейте GSD).

## Перенос на новую машину

```bash
# 1. Поставить GSD (даёт фреймворк-хуки + skills + апдейтер)
#    -> по процедуре GSD

# 2. Склонировать этот репозиторий и запустить установщик
git clone https://github.com/mironovde/llm_developer_setup.git
cd llm_developer_setup/claude-sync
./install.sh --dry-run     # посмотреть, что будет сделано
./install.sh               # применить: копирует хуки -> ~/.claude/hooks, ставит watchdog

# 3. Дотащить проводку и общую конфигурацию из бэкапа
#    backups/<latest>/global-settings.json  -> ~/.claude/settings.json
#    (см. блок "hooks"; правки переносимости — ниже)
#    ~/.claude/CLAUDE.md, SECURITY.md       -> из соответствующих снапшотов
```

Флаги установщика: `--dry-run` (ничего не меняет), `--no-launchd` (пропустить
launchd), `-h` (справка). Установщик идемпотентен — можно гонять повторно.

## Подводные камни переносимости (важно)

1. **launchd-plist** — содержал захардкоженный `/Users/mironovde/...`. Поэтому в
   репо лежит **шаблон** с `__HOME__`; `install.sh` подставляет `$HOME` при
   установке. Не копируйте plist напрямую.
2. **`settings.json` ссылается на node по абсолютному пути** `/opt/homebrew/bin/node`
   (Apple Silicon). На другой машине/Intel/Linux путь иной — замените на `node`.
3. **Абсолютные пути в `settings.json`** (`/Users/mironovde/.claude/hooks/...`) —
   замените на `~/.claude/hooks/...`, чтобы не зависеть от имени пользователя.
4. **Сами хуки** путей не хардкодят (проверено) — переносимы как есть.
