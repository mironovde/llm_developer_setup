# RESEARCH — каталог находок и вердиктов

> Протокол §4 ТЗ. Формат записи: дата проверки · источник · вердикт (**ADOPT / ADAPT / WATCH / SKIP**) · причина.
> Приложение А ТЗ (срез 31.07.2026) — стартовая карта. Здесь: выборочная перепроверка того, на чём строятся ключевые решения, локальные эксперименты и скан новинок. Всё проверено **31.07.2026** ресёрч-агентами по официальным докам (code.claude.com/docs) и локальными прогонами; установленный CLI — **v2.1.207**.

## 1. Локальная верификация CLI (2026-07-31 · `claude --help` v2.1.207 · авторитетнее доков для этой машины)

| Факт | Статус vs Приложение А | Следствие для дизайна |
|---|---|---|
| `--max-turns` в help v2.1.207 **отсутствует** (в cli-reference.md для новых версий — упоминается) | СПОРНО → не полагаемся | Лимит итераций автопилота — собственным wrapper'ом (`scripts/autopilot`); per-agent `maxTurns` во frontmatter субагентов есть — используем его |
| `--max-budget-usd` (только `-p`) существует | НОВОЕ | Пояс безопасности; бюджеты считаем по usage из stream-json, не по USD |
| `--json-schema` (print) — валидируемый структурный вывод | НОВОЕ | Судья Gym отдаёт `grading.json` строго по схеме — без парсинга прозы |
| `--permission-mode`: `acceptEdits\|auto\|bypassPermissions\|manual\|dontAsk\|plan` | CHANGED (добавились `auto`, `dontAsk`, `manual`) | Автопилот: `acceptEdits` + точечные allowlists; `bypassPermissions` не используем (§8 ТЗ) |
| `--setting-sources` + `--settings <file>` + `--strict-mcp-config` | CONFIRMED | Основа герметичности Gym (см. эксперимент §2) |
| `--bare` — минимальный режим, auth **только** `ANTHROPIC_API_KEY` | НОВОЕ | На подписке Max неприменим |
| `--effort low..max`, `--fallback-model` (до 3 фолбэков), `--fork-session`, `--no-session-persistence` | НОВОЕ/CONFIRMED | `--effort low` — судья Gym; `--fallback-model` — устойчивость ночных прогонов |
| Алиасы моделей в help: `fable`, `opus`, `sonnet` | CHANGED | См. §3 «Модели» |
| Вложенный `claude -p` из сессии Claude Code работает | ЭКСПЕРИМЕНТ | Gym и autopilot запускаемы откуда угодно; всегда `< /dev/null` (иначе 3-сек ожидание stdin) |

## 2. Локальные эксперименты (2026-07-31, решающие)

1. **`CLAUDE_CONFIG_DIR` для герметичного Gym — ОТВЕРГНУТ.** Свежий конфиг-дир теряет авторизацию («Not logged in»), даже с перенесённым `~/.claude.json`: креды OAuth в кейчейне привязаны к конфиг-диру. → ADR-003.
2. **Герметичность через `--setting-sources project --strict-mcp-config` — ПОДТВЕРЖДЕНА.** Замер (haiku, «Say OK»): полный пользовательский конфиг = **45 409** ток. свежего инпута; project-only = **7 468** свежих + 19 113 из кэша. Auth работает, вложенный запуск работает. Gym ставит конфиг Team OS в фикстуру на **project-уровне** (project поддерживает agents/skills/hooks/rules/settings). Побочный результат: текущий конфиг пользователя жжёт ~45k токенов на старте каждой сессии — измеренная боль №5.
3. **Схема usage в `-p --output-format json`** (поле в поле совпадает со stream-json `result`): `total_cost_usd, duration_ms, num_turns, session_id, is_error, permission_denials, terminal_reason, usage{input_tokens, cache_creation_input_tokens, cache_read_input_tokens, output_tokens, cache_creation{ephemeral_1h_input_tokens, ephemeral_5m_input_tokens}}, modelUsage` — источник телеметрии.
4. **Xcode отсутствует на машине** → iOS-задача Gym auto-skip; XcodeBuildMCP — закомментированный опт-ин в шаблоне.

## 3. Верификация официальных доков (2026-07-31 · code.claude.com/docs · агенты с цитатами)

**Субагенты** (`sub-agents.md`):
- Полный frontmatter: `name, description, tools, disallowedTools, model, permissionMode, maxTurns, skills, mcpServers, hooks, memory, background, effort, isolation, color, initialPrompt` — богаче Приложения А (`maxTurns`, `effort`, `permissionMode` — используем в ролях).
- Вложенные субагенты: **по умолчанию включены, глубина 3** (v2.1.219); `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=1` отключает. Капы: 20 одновременно, 200 за сессию.
- **Субагенты по умолчанию фоновые** (v2.1.198) с урезанным набором тулов; модель по умолчанию — inherit.
- `model:` принимает `sonnet|opus|haiku|fable|<ID>|inherit`.

**Skills** (`skills.md`):
- Полный frontmatter: `name, description, when_to_use, argument-hint, arguments, disable-model-invocation, user-invocable, allowed-tools, disallowed-tools, model, effort, context, agent, background, hooks, paths, shell`.
- `disable-model-invocation: true` ⇒ описание **не грузится в контекст вообще** — ручные команды бесплатны на старте. `user-invocable: false` ⇒ только для модели. → ADR-009.
- Динамический контекст: `` !`command` `` выполняется до отправки скилла модели — вывод скрипта вместо плейсхолдера (standup почти бесплатен). `paths:`-глобы на скиллах — автоподгрузка по касанию файлов.
- `.claude/commands/*.md` живы, но избыточны — всё делаем скиллами.

**Hooks** (`hooks.md`):
- Событий **29** (не 8): + `PostToolUseFailure, TaskCreated, TaskCompleted, TeammateIdle, InstructionsLoaded, MessageDisplay, ConfigChange, WorktreeCreate…`
- **`SessionStart` matchers `startup|resume|clear|compact` НЕ существуют** — Приложение А ошибалось.
- PostToolUse-подмена вывода: `{"hookSpecificOutput":{"hookEventName":"PostToolUse","updatedToolOutput":"…"}}` — подтверждено дословно. PreToolUse: `permissionDecision allow|deny|ask|defer` + `updatedInput`.
- Exit 2 блокирует **не везде**: PreToolUse/UserPromptSubmit/Stop/SubagentStop/TaskCreated/TaskCompleted/PreCompact — да; PostToolUse — нет (тул уже выполнен). **JSON из stdout читается только при exit 0.**
- Stop/SubagentStop могут вернуть `hookSpecificOutput.additionalContext` — официальный канал «продолжай работать» (v2.1.163) — основа loop-guard.

**Настройки/пермишены** (`settings.md`, `permissions.md`):
- Приоритет: managed > CLI > `.claude/settings.local.json` (с v2.1.211 — от корня репо) > `.claude/settings.json` > `~/.claude/settings.json`.
- Порядок правил: **deny → ask → allow**, первый матч побеждает. `Bash(ls *)` — пробел = граница слова. `WebFetch(domain:*.x.com)` не матчит `x.com`. Новое: параметрические правила `Agent(model:opus)` в deny/ask.
- Trust-ворота действуют только на allow-правила project-настроек — на новой машине `.mcp.json` серверы ждут одобрения.

**Statusline** (`statusline.md`): на stdin — `model, workspace, cost, context_window{used_percentage, current_usage…}, exceeds_200k_tokens, effort, **rate_limits**, pr, agent…` + env `COLUMNS/LINES`; триггеры событийные + `refreshInterval`. Показ времени сброса лимита в статусе — бесплатный.

**Headless/лимиты** (`headless.md`, `errors.md`): stream-json: события + финальный `result` (схема — §2.3). Машиночитаемый сигнал лимита: событие **`rate_limit_event`** со `"status":"rejected"`; текстовые форматы: «You've hit your session limit · resets 3:45pm», «You're out of extra usage · resets 9pm», 429. → парсер backoff в autopilot/gym.

**Tasks/Teams** (`agent-teams.md`, `tools-reference.md`): TaskCreate/Update/List/Get есть; лист переживает resume автоматически; семантика `CLAUDE_CODE_TASK_LIST_ID` не документирована (Приложение А CHANGED). Teams: флаг тот же; **`TeamCreate`/`TeamDelete` удалены (v2.1.178)** — одна неявная команда на сессию, тиммейты спавнятся `Agent` с `name`; in-process тиммейты не переживают `/resume`; ×7 токенов — подтверждено в costs.md.

## 4. MCP-серверы — вердикты (2026-07-31)

| Сервер | Версия | Вердикт | Причина / конфиг |
|---|---|---|---|
| context7 (Upstash) | 3.2.5 / remote | **ADOPT** (user-scope) | 2 тула, remote HTTP `https://mcp.context7.com/mcp` — ноль локальных процессов; ключ через `Authorization: Bearer ${CONTEXT7_API_KEY:-}` |
| chrome-devtools-mcp (Google) | 1.6.0 | **ADOPT** (project, web) | Официальный; `--headless --isolated`; 53 тула → режем категории (memory/extensions off); дефолт для цикла правка→тест |
| playwright-mcp (Microsoft) | 0.0.78 | **ADAPT** (project, по нужде) | Только когда нужен кросс-браузерный E2E; не держать вместе с chrome-devtools постоянно |
| XcodeBuildMCP (getsentry) | 2.7.0 | **ADAPT** (project, iOS) | Только с `XCODEBUILDMCP_ENABLED_WORKFLOWS=simulator,project-discovery` + `SENTRY_DISABLED=true`; без фильтра 110+ тулов |
| ios-simulator-mcp | 1.6.0 | **WATCH** | ~15 тулов, но дублирует встроенный iOS Simulator-тул Claude Code и XcodeBuildMCP |
| GitHub MCP | — | **SKIP** | `gh` CLI дешевле на операцию; 100+ тулов не нужны |
| memory-MCP, filesystem/git-MCP, Tavily/Exa | — | **SKIP** | native memory / Bash / WebSearch покрывают |

**Факты `.mcp.json`** (mcp.md): экспансия `${VAR}` и `${VAR:-default}` работает в `command/args/env/url/headers`. **ВАЖНО (Приложение А CHANGED):** незаполненная переменная **не отключает сервер** — конфиг грузится с литеральной строкой `${VAR}` и warning'ом. Следствие: всегда `${VAR:-}` + сервер должен переживать пустое значение, либо держать сервер закомментированным. Remote-шейп: `{"type":"http","url":…,"headers":…}`; SSE deprecated. `MAX_MCP_OUTPUT_TOKENS` дефолт 25k. Tool-деферрал включён по умолчанию — но фильтрация категорий всё равно улучшает выбор тулов.

## 5. Фреймворки и паттерны — вердикты (2026-07-31)

| Источник | Вердикт | Что взято |
|---|---|---|
| obra/superpowers `verification-before-completion` | **ADOPT** (адаптация) | «Iron Law: no completion claims without fresh verification evidence» + Gate Function (identify→run→read→verify→claim) + таблица «заявление → обязательное доказательство» → скилл `verify` |
| obra/superpowers brainstorm→plan→execute | **ADAPT** | Цепочка стадий с воротами; жёсткий gate «no code before approved design» → тир-плейбуки T2/T3; пути и «вопросы по одному» — не берём |
| anthropics/skills skill-creator eval-схемы | **ADOPT** | Точные схемы `evals.json` и `grading.json` (expectations[] → {text, passed, evidence}, pass_rate, execution_metrics) → формат судьи Gym; правило «assert correctness, not presence» |
| EveryInc/compound-engineering | **ADAPT** | Механика lessons: один урок за прогон, YAML-frontmatter для поиска, `solutions/<category>/<slug>.md`, авто-подтяжка уроков при планировании → скилл `retro` + `team/solutions/` |
| Официальный плагин **ralph-loop** (Stop-hook цикл) | **ADAPT** | Паттерны: fail-open state-файл, completion-promise (литеральное сравнение), max-iterations, атомарный инкремент. Сам плагин не ставим: in-session цикл гибнет с сессией → наш autopilot внешний (ADR-006) |
| frankbria/ralph-claude-code | **ADAPT** | 4-слойный детект лимита (структурный `rate_limit_event status:rejected` → текстовые фолбэки с фильтрацией tool_result-строк от false positive), circuit breaker «нет прогресса», детект permission-denials → `scripts/autopilot` |
| hookify, security-guidance, claude-security, session-report, project-artifact (офиц. плагины) | **WATCH** | Пересекаются с нашими хуками/скриптами; не ставим сейчас (дубль мандата), кандидаты `/research-refresh` |
| VoltAgent + wshobson каталоги ролей | **ADOPT** (выборочно) | Дистилляты 11 ролей (PM, UX, UI, architect, frontend, backend, QA, reviewer, security, devops, researcher) → `home/agents/` |
| claude-flow/ruflo | **SKIP** | Эталон анти-хайп фильтра (Приложение А), не перепроверялся |

## 6. Скан новинок (май–июль 2026; дата сборки = дате среза Приложения А)

Из changelog v2.1.145→v2.1.219 — то, что меняет дизайн:

1. **`/verify` и `/code-review` больше не самовызываются (v2.1.215)** — авто-инвок надо прописывать в собственных триггерах явно. Встроено в тир-плейбуки.
2. **Agent Teams**: `TeamCreate`/`TeamDelete` удалены (v2.1.178) — неявная команда, спавн через `Agent{name}`. Половина «Agent Teams»-разделов старого конфига пользователя устарела.
3. **Модели**: `sonnet`→Sonnet 5 (дефолт Claude Code, 1M), `opus`→Opus 5 (24.07.2026, 1M), `haiku`→Haiku 4.5, `fable`→Fable 5 (**жрёт usage credits** — вне дефолтных ярусов), `opusplan` жив. Opus 5 low/medium effort необычно сильны — субагентам можно снижать effort.
4. **Ultracode / dynamic workflows** — нативный массовый фан-аут (`workflowSizeGuideline`); конкурент самодельным мульти-агентным конструкциям для широких коротких задач.
5. Worktree-агенты по завершении **сами коммитят и открывают draft-PR** (v2.1.198) — конвейер должен это учитывать (у нас: агенты работают в ветке, PR — только через ship-ворота).
6. Автономность ужесточена харнесом: уведомления фоновых задач не считаются одобрением; auto-mode блокирует деструктивный git; `AskUserQuestion` без ответа висит вечно — L3-автопилот не должен задавать вопросов (halt-файл вместо вопроса).
7. Ретраи транзиентов встроены: `CLAUDE_CODE_RETRY_WATCHDOG`, `CLAUDE_CODE_MAX_RETRIES` (≤15) — autopilot не дублирует ретраи, только межокное ожидание.
8. `--forward-subagent-text` (v2.1.211) — субагентский текст в stream-json: отладка Gym.
9. MCP-вызовы >2 мин авто-уходят в фон (v2.1.212) — длинные браузерные операции не блокируют ход.
10. Официальный маркетплейс: 276 плагинов, 39 от Anthropic (снапшот 31.07.2026): `ralph-loop`, `hookify`, `security-guidance`, `claude-security`, `session-report`, `project-artifact`, 11 LSP. Вердикты — §5.

## 7. Открытые вопросы → в `/research-refresh`

- `--max-turns` в CLI: появится/подтвердится в >2.1.207 — перепроверить при обновлении CLI.
- `CLAUDE_CODE_TASK_LIST_ID`: семантика не документирована — следить.
- hookify/security-guidance: заменить ли ими наши хуки — решать через Gym после стабилизации baseline.
- crystaldba/postgres-mcp, Supabase MCP, Sentry MCP — не перепроверялись (вне ключевых решений сборки); брать по нужде проекта из Приложения А.
