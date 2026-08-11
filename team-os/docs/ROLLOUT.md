# Раскатка конфига на новое устройство

Проверено на чистом `CLAUDE_HOME` 2026-08-11 (после третьего раунда): установка воспроизводит
полный набор — `CLAUDE.md` 4706 Б · 4 скилла · 4 роли · 28 команд · 9 хуков · 5 скриптов — без
ручных шагов. Все восемь ссылок на хуки из `settings.json` разрешаются.

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
| `agents/` (4 роли: implementer · researcher · security-auditor · evaluator) | `~/.claude/mcp-servers/1c_mcp` — внешний сервер: `git clone https://github.com/vladimir-kharin/1c_mcp.git` |
| `commands/` (28 слэш-команд) | Авторизация в MCP (Figma, Supabase, Vercel и т.п.) |
| `hooks/` (9 штук, включая контракт default-FAIL и операторские контроли) | История, память проектов (`~/.claude/projects/`) |
| `teamos/bin/` (autopilot, standup, doctor, efficiency-report) | |
| `SECURITY.md` — глобальная политика безопасности | |
| `legal-templates/` — 6 шаблонов правовых документов | |
| Пользовательские хуки из `claude-sync/hooks/` — ставит **отдельный** `claude-sync/install.sh` | |

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

## Раскатка на проекты (сделано 2026-08-09)

Новый закон состояния звучит «`NOTES.md` или установленный эквивалент проекта». Без явного
названия эквивалента агент завёл бы лишний `NOTES.md` рядом с уже используемым слоем. В каждом
активном проекте эквивалент назван прямо:

| Проект | Слой состояния | Коммит |
|---|---|---|
| crm_npf | GSD `.planning/` (план) + `team/` (спринт, доказательства) | `9743754f` |
| obsidian_planner | `.planning/` + `team/` — оба живые | `5967453` |
| fin_planner | `team/`; CLAUDE.md создан с нуля (его не было) | `adf2b5d` |
| fin_planner_2 | `team/`; CLAUDE.md создан с нуля, добавлены pnpm-команды | `c61bc5b` |
| delo_yasno_2 | `.planning/STATE.md`; строка добавлена в существующую таблицу соответствий | `7c2b0afd` |
| risk-platform-2 | `.planning/` | `25ab82c` |
| interior-design | `.planning/` | `6a55981` |

`.artifacts/` добавлен в `.gitignore` шести проектов (в `delo_yasno_2` уже был).

Каждый коммит содержит **только** `CLAUDE.md` и `.gitignore` — в `interior-design` рядом лежало
40+ чужих незакоммиченных файлов, в `risk-platform-2` — правки `.planning/`; ничего из этого не
затронуто. Откат любого: `git -C <проект> revert <хеш>`.

## Управление автономным прогоном с другого терминала

| Файл в корне репозитория | Что делает |
|---|---|
| `AGENT_STOP` | пока существует, каждый вызов инструмента запрещается — агент останавливается чисто, состояние остаётся на диске |
| `STEER.md` | содержимое один раз показывается агенту и файл очищается — смена направления без рестарта |
| `test-results.json` | необязательный контракт: критерии стартуют `false`, отметить `true` нельзя без прочитанного доказательства |

Первые два работают всегда. Третий инертен, пока проект не заведёт файл.

## Что проверено, а что нет

Проверено на macOS (Node 25, BSD-утилиты). Непортируемые вызовы вычищены: `shasum` заменён на
выбор между `shasum` и `sha256sum`, `sed -i ''` в тестовой обвязке — на `perl -pi`. На Linux
установка не прогонялась ни разу — при первой раскатке туда стоит начать с
`bash team-os/gym/gate-test.sh` и `hook-test.sh`, они не тратят токенов и поймают несовместимость
за секунды.
