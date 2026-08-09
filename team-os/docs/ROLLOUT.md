# Раскатка конфига на новое устройство

Проверено на чистом `CLAUDE_HOME` 2026-08-09: установка воспроизводит полный набор
(CLAUDE.md · 4 скилла · 5 ролей · 28 команд · 6 хуков · 5 скриптов) без ручных шагов.

## Процедура

```bash
git clone <этот-репозиторий> ~/development/llm_developer_setup
cd ~/development/llm_developer_setup
git checkout team-os

bash team-os/install.sh --dry-run    # показывает, что будет заменено
bash team-os/install.sh              # спросит подтверждение; --yes чтобы без него
bash ~/.claude/teamos/bin/doctor     # проверка машины
```

Установщик делает датированный бэкап **каждого** файла, который заменяет, в
`~/.claude/teamos-backups/<timestamp>/`. Откат — одна команда, она печатается в конце вывода.

## Что переносится, а что нет

| Переносится `install.sh` | Не переносится, нужно вручную |
|---|---|
| `CLAUDE.md`, `settings.json`, `statusline.sh` | Плагины (`enabledPlugins`) — ставятся из маркетплейса |
| `skills/` (browser-loop, gym, retro, threat-model) | MCP-серверы под конкретный проект |
| `agents/` (5 ролей) | `~/.claude/mcp-servers/1c_mcp` — внешний сервер: `git clone https://github.com/vladimir-kharin/1c_mcp.git` |
| `commands/` (28 слэш-команд) | Авторизация в MCP (Figma, Supabase, Vercel и т.п.) |
| `hooks/` (6 штук) | История, память проектов (`~/.claude/projects/`) |
| `teamos/bin/` (autopilot, standup, doctor, efficiency-report) | |

## Личные настройки не затираются

`install.sh` сохраняет из старого `settings.json`: `enabledPlugins`, `theme`, `effortLevel`,
уведомления, `forceLoginMethod` — и **сливает** `env` (ключи Team OS выигрывают при конфликте).
То есть на новой машине сначала настраиваешь плагины и тему, потом ставишь конфиг — порядок
не важен, ничего не потеряется.

## Проверка после установки

```bash
bash ~/.claude/teamos/bin/doctor        # 16 ok / 1 warn (xcodebuild) — норма на машине без Xcode
bash team-os/gym/gate-test.sh           # 22/22 — ворота
bash team-os/gym/hook-test.sh           # 11/11 — Stop-хуки
bash team-os/gym/run.sh smoke           # 2 задачи вживую, ~30k токенов
```

`doctor` помечает отсутствующие на машине возможности (`xcodebuild`, Chrome) как WARN, а не FAIL:
gym-задачи, которым они нужны, будут SKIPPED — это норма, а не поломка.

## Если что-то пошло не так

```bash
ls -t ~/.claude/teamos-backups | head        # последние бэкапы
cp -R ~/.claude/teamos-backups/<ts>/. ~/.claude/
```

Отставные скиллы и роли (t1/t2/t3, tier, verify, decide, autonomy, standup, research-refresh,
architect, code-reviewer, pm, ux-designer, visual-designer, devops) удалялись отдельно от
установщика — их бэкап лежит в `~/.claude/teamos-backups/<ts>-retired/`.
