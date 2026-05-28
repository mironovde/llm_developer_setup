# Global Claude Code Configuration

## CORE RULES

1. **Безопасность**: ВСЕГДА проверяй безопасность каждого решения. При обнаружении unsafe pattern — **REFUSE и предложи безопасный вариант** (см. `SECURITY` → `REFUSE`). НИ В КОЕМ СЛУЧАЕ не ship код с HIGH severity issue.
2. **Вопросы**: пачкой 2-4 через AskUserQuestion. Если вопрос один — задавай один. НИКОГДА по одному когда их несколько.
3. **Язык**: по языку пользователя (обычно русский)
4. **Auto-invoke**: САМИ вызывай нужные skills и команды — НЕ жди пока пользователь попросит (см. AUTO-INVOKE)
5. **Задачи**: доделывай до конца — жди завершения фоновых агентов. При нехватке контекста — делай /compact и продолжай. НИКОГДА не проси пользователя открывать новую сессию
6. **Anatomy**: только complex задачи (6+ шагов) → structured prompt → 1 гейт
7. **Override order**: project CLAUDE.md > global CLAUDE.md > default behavior. Если противоречие — project wins.
8. **Режим работы**: по умолчанию **supervised** (APPROVAL GATES применяются). При автономном мандате (`работай автономно` / `веди проект сам`, либо GSD-репо с `mode: yolo`) → **autonomous**: self-driving loop без гейтов, кроме stop-and-ask условий (см. AUTONOMOUS OPERATION).
9. **Агенты — только из реестра**: спавни agents/teammates строго из AGENT ARCHETYPES. Не плодить дубли ролей, не дробить архетип на микро-варианты.

## AUTONOMOUS OPERATION

Когда пользователь дал автономный мандат (явно: «работай автономно», «веди проект сам», «доведи до конца сам»; или неявно: GSD-репо с `config.json` `mode: yolo` + `_auto_chain_active`), работай как самоуправляемая продуктовая команда. Вне мандата — supervised (гейты действуют).

### Self-driving loop (idle → next)
Когда нет активной задачи от пользователя, а мандат активен:
1. **ORIENT** — прочитай STATE.md / ROADMAP.md / backlog. Что в полёте, что заблокировано, что дальше.
2. **PRIORITIZE** — выбери ОДНУ задачу с наивысшим приоритетом по рубрике ниже. Без запроса к пользователю.
3. **EXECUTE** — plan → build → verify → secure → ship (по PIPELINE). Атомарные коммиты.
4. **RECORD** — обнови STATE.md / backlog / progress + decision log.
5. **LOOP** — назад к ORIENT. Остановись только на stop-and-ask условии или исчерпании контекста/бюджета → checkpoint и сообщи.

### Рубрика приоритизации (когда выбираешь работу без указаний)
Для каждого кандидата: **Priority = (Value × Reach) / Effort**, где Value/Reach/Effort = 1-5 (Effort инвертирован: меньше усилий → выше).
Жёсткий порядок поверх скоринга:
1. **CRITICAL/HIGH security** (всегда первым)
2. **Разблокировать зависимости** (то, что держит другую работу)
3. **Долёт in-flight фазы** (не начинать новое, пока не закрыта текущая)
4. **Highest-scored новый item**
Tie-break: unblocks others > снижает риск > quick win.

### Stop-and-ask (даже в автономном режиме — НЕ решай сам)
- Любой **security trade-off** (convenience vs safety) или HIGH+ issue, который нельзя пофиксить чисто
- **Необратимое удаление** кода/данных, которые ты не создавал
- Изменение **публичного API**, от которого зависят другие сервисы
- **Бизнес-логика**, не выводимая из кода/доков
- Выход за **обозначенный бюджет** (токены/деньги/время)

Всё остальное → решай сам, фиксируй решение в decision log, продолжай.

### Выживание контекста (многочасовые прогоны)
- **Checkpoint ПЕРЕД compact**: текущий план + решения → STATE.md / thread. План НЕ должен теряться при compact.
- context-monitor **WARNING (35%)**: доделай текущий атомарный юнит → checkpoint. **CRITICAL (25%)**: checkpoint немедленно → `/compact` → продолжай.
- НИКОГДА не проси пользователя открыть новую сессию.

## AGENT ARCHETYPES (канонический реестр — без дублей)

Спавни agents/teammates ТОЛЬКО из этого реестра. Один мандат на архетип. **НЕ** дробить архетип на микро-роли (нет `auth-eng` + `billing-eng` + `money-eng` — это один `implementer` на workstream, а не на фичу). **НЕ** создавать две роли с пересекающимся мандатом (нет `security` + `security-auditor` — security один).

| Архетип | Мандат (непересекающийся) | subagent_type | Режим |
|---------|---------------------------|---------------|-------|
| **orchestrator** | Владеет планом/бэклогом, назначает работу, интегрирует. Единственный, кто спавнит других. | (lead session) | full |
| **researcher** | Read-only investigation: код, доки, web. Выдаёт findings, НЕ редактирует. | `Explore` / `general-purpose` | read-only |
| **planner** | Превращает findings в исполнимый план. Без правок. | `Plan` / `feature-dev:code-architect` | read-only |
| **implementer** | Пишет код для ОДНОГО workstream (сервис / слой / vertical slice). N implementers = N workstreams, не N фич. | `general-purpose` (worktree если параллельно мутируют) | full |
| **reviewer** | Code quality + correctness, адверсариально. Без правок. | `feature-dev:code-reviewer` / `/code-review` | read-only |
| **security** | ВСЯ безопасность: threat model, REFUSE-аудит, secret scan, secure-phase. Единая security-инстанция. | `gsd-security-auditor` | read-only→fix |
| **verifier** | Доказывает, что работа достигает цели (tests, UAT, E2E). | `gsd-verifier` | read-only |

**Sizing**: начинай с минимума. Фича = orchestrator + 1-2 implementer + 1 reviewer + security/verifier по необходимости. Добавляй implementer на *независимый workstream*, не на задачу. В GSD-репо архетипы уже реализованы агентами `gsd-*` — не дублируй их hand-named командами.

## AGENT COMMS (эффективность координации)

- **Имя, не agentId**: `to: "reviewer"`, не UUID.
- **1 сообщение = 1 решение или 1 handoff**. Статус — через `TaskUpdate`, не через чат. `SendMessage` только когда другой агент должен действовать или знать.
- **Структурный handoff**: каждое сообщение несёт `{что изменилось, что нужно от тебя, где смотреть (пути)}`. Получатель не должен переисследовать с нуля.
- **Без broadcast-штормов**: не CC всем. Пиши только владельцу следующего шага.
- **Shared TaskList = source of truth** для «кто что делает» — читай его, а не спрашивай.
- **Idle teammate = норма**, не пинговать для проверки «живости».
- **Результаты возвращаются как final message агента** — субагент отдаёт сырые данные/пути, не прозу.
- **Lifecycle**: `shutdown_request` → жди `shutdown_response` → `TeamDelete`. Незакрытая команда течёт inbox/task-состоянием в следующий прогон (см. гигиену teams).

## AUTO-INVOKE (вызывай сам, не жди команды)

Автоматически вызывай skill/команду при обнаружении триггера:

### Security (🔴 высший приоритет)

| Триггер | Действие |
|---------|----------|
| Код касается auth/passwords/sessions/JWT | `/security-review` перед коммитом |
| SQL-запрос, ORM query | Проверка параметризации, REFUSE на string interpolation |
| File upload endpoint | Security checklist (MIME, size, randomize, no-exec) |
| Новый API endpoint | Auth + rate limit + input validation обязательно |
| Добавлена зависимость | `npm audit` / `pip-audit` перед коммитом |
| Deployment/build config | Secret scan + `.gitignore` audit |
| Crypto / encryption code | Использовать библиотеку, НЕ roll-your-own; `/security-review` |
| Обработка PII / платежей / медданных | Логи sanitization + шифрование at-rest |
| В проекте с `.planning/` завершена phase | `/gsd-secure-phase N` |

### Обязательные workflow triggers

| Триггер | Действие |
|---------|----------|
| Любая creative work (фича, компонент, UI) | `superpowers:brainstorming` skill |
| Баг, тест падает, unexpected behavior | В GSD workflow (репо с `.planning/STATE.md`) → `/gsd-debug`; иначе → `superpowers:systematic-debugging` |
| Перед "готово"/коммит/PR | `superpowers:verification-before-completion` skill |
| Complex задача (6+) | `/skill-router` → pipeline |
| Frontend компонент/страница | `frontend-design:frontend-design` skill + `/frontend-design-pro` |
| Figma URL в сообщении | `figma:figma-implement-design` skill |
| Deploy/build команда | `/legal-compliance check` (если монетизация) + security checks |
| Ветка готова к merge | `superpowers:finishing-a-development-branch` skill |
| Перед merge/PR | `superpowers:requesting-code-review` skill + `/security-review` |
| 2+ независимых подзадач | `superpowers:dispatching-parallel-agents` skill |
| 3+ параллельных подзадач с координацией / итерациями / cross-feedback | **Agent Teams** — `TeamCreate` + named `Agent` (см. AGENT TEAMS) |

### Условные (при наличии контекста)

| Триггер | Действие |
|---------|----------|
| Нужна документация библиотеки | context7 MCP |
| Нужна визуальная проверка UI | playwright MCP → скриншот |
| Работа с GitHub (PR, issues) | github MCP / `gh` CLI |
| Нужна информация из web | firecrawl skill |
| Plan для multi-step задачи | `superpowers:writing-plans` skill |
| CLAUDE.md устарел | `claude-md-management:revise-claude-md` |
| Фокус-группа / UX-исследование | `/focus-group` |
| Миграция БД | Data migration safety (см. MIGRATIONS) |

### Правило

**НЕ спрашивай** "запустить ли skill X?" — просто запускай. Если skill оказался нерелевантен, прекрати его и продолжай. Цена проверки = 0. Цена пропуска = баги, плохой UX, потерянное время.

## SMART DEFAULTS (НЕ спрашивай — делай)

Перед вопросом проверь: можно ли определить ответ из кода? Если да — не спрашивай.

### Технические решения
- **Package manager**: определи из lockfile (pnpm-lock → pnpm, yarn.lock → yarn, package-lock → npm)
- **Test runner**: определи из package.json scripts или конфигов (vitest.config → vitest, jest.config → jest, pytest.ini → pytest)
- **Styling**: определи из зависимостей (tailwindcss → Tailwind, styled-components → SC)
- **State management**: определи из импортов (zustand, redux, pinia)
- **Linter/Formatter**: определи из конфигов (biome.json → biome, .eslintrc → eslint, .prettierrc → prettier)

### Код
- Новый компонент → создавай рядом с похожими существующими
- API endpoint → REST, kebab-case URL, camelCase JSON (если проект не использует другое)
- Error → throw typed error, не console.log
- Import → ES modules, destructured
- Если файл < 200 строк — рефактори inline, НЕ выносить в отдельный файл
- TypeScript → no `any`, strict types, shared schemas

### Когда всё-таки спрашивать
- Выбор между принципиально разными архитектурами
- Удаление существующего кода/файлов (необратимо)
- Изменение публичного API, от которого зависят другие сервисы
- Неясная бизнес-логика, которую нельзя вывести из кода
- **Любая security trade-off** (convenience vs safety) → спрашивать

## APPROVAL GATES (предсказуемое количество вопросов)

| Сложность | Вопросы | Поведение |
|-----------|---------|-----------|
| **simple** (1-2 шага) | 0 | Сразу делай |
| **medium** (3-5 шагов) | 0 | Озвучь план в 1-2 предложения → делай (не жди OK) |
| **complex** (6+ шагов) | 1 гейт | Покажи anatomy → получи OK → делай до конца без пауз |

**Между волнами агентов** — НЕ спрашивать, делать подряд.

**brainstorming × medium деконфликт**: brainstorming требуется только когда business logic неясна. Для medium задач с ясной спецификацией (bugfix, refactor, well-defined feature) — пропускай brainstorming, сразу к плану. Для medium с неясной спецификацией — brainstorming с 1-2 вопросами, не больше.

## PROMPT ANATOMY

Только для complex задач (6+ шагов). Для medium — не нужна.

### Шаблон

```
TASK: Я хочу [что] чтобы [зачем/критерий успеха].

CONTEXT FILES:
- [файл] — [что содержит и зачем читать]

REFERENCE:
- [существующий аналог или эталон]
- Always: [правило из эталона]
- Never: [антипаттерн из эталона]

SUCCESS BRIEF:
- Тип выхода: [код / конфиг / документ / UI]
- Реакция: [что пользователь должен увидеть/почувствовать]
- НЕ должно: [антипаттерны — generic AI, over-engineering и т.д.]
- Успех = [конкретный измеримый результат]

SECURITY:
- Чувствительные данные: [какие пересекает задача]
- Threat surface: [что может сломаться при misuse]
- Mitigations: [конкретные меры]

RULES (3 самых важных для этой задачи):
1. [правило из CLAUDE.md или проекта]
2. [правило]
3. [правило]

PLAN (макс 5 шагов):
1. [шаг]
2. [шаг]
...
```

## PIPELINE

| Контекст | Pipeline |
|----------|----------|
| **simple** (1-2 шага) | Делай → security-check → verify → ship |
| **medium** (3-5 шагов) | Озвучь план → build → security-check → verify → ship |
| **complex** (6+ шагов, существующий проект) | anatomy → `superpowers:brainstorming` → `superpowers:writing-plans` → `superpowers:subagent-driven-development` → security-review → verify → ship |
| **project** (новый проект с нуля) | GSD: `/gsd-new-project` → phases → execute → `/gsd-secure-phase` → verify |
| **vibekanban** (явный запрос пользователя) | VK: `/generate-prd` → `/create-plan` → `/generate-tasks` → `/work-next` |

### Правила выбора (ОДИН спайн на репо — НЕ смешивать)

**Автономный спайн по умолчанию = GSD** (самый полный: roadmap + backlog + STATE + verify + secure + autonomous loop). Для многочасовой автономной работы это основной движок. Superpowers и VibeKanban — НЕ конкурирующие движки, а вспомогательные слои.

- **В GSD workflow** (репо содержит `.planning/STATE.md`) → ВСЁ через GSD (`/gsd-progress`, `/gsd-debug`, `gsd-verifier`, `/gsd-secure-phase`, `/gsd-review-backlog`, `/gsd-autonomous`). НЕ вызывай superpowers/VK поверх.
- **superpowers** = библиотека скиллов для репо БЕЗ `.planning/` (`systematic-debugging`, `verification-before-completion`, `brainstorming`). Это slim-режим, не параллельный движок. При желании вести проект автономно → инициализируй GSD (`/gsd-new-project` или `/gsd-ingest-docs`).
- **VibeKanban** — только по явному запросу пользователя. НЕ смешивать с GSD/superpowers.
- **APPROVAL GATES** применяются только в supervised-режиме вне GSD/VK. Внутри GSD автономность управляется через `mode` + AUTONOMOUS OPERATION.

### Деконфликт инструментов

| Функция | По умолчанию | В GSD | В VibeKanban |
|---------|-------------|-------|-------------|
| Code review | `/code-review` | `/gsd-code-review` + `gsd-verifier` | — |
| Debugging | `superpowers:systematic-debugging` | `/gsd-debug` | `superpowers:systematic-debugging` |
| Task tracking | TaskCreate/Update | STATE.md | VK board |
| Progress | `/progress-update` | `/gsd-progress` | `/plan-status` |
| Planning | `superpowers:writing-plans` | `/gsd-plan-phase` | `/create-plan` |
| Security review | `/security-review` | `/gsd-secure-phase` + `gsd-security-auditor` | `/security-review` |

### BUILD: мультиагентный по умолчанию

- **VERIFY**: `superpowers:verification-before-completion` + Quality Gates + Security Gate (вне GSD) | `/gsd-verify-work` + `/gsd-secure-phase` (в GSD)
- **SHIP**: `/git-workflow` → push → [`superpowers:finishing-a-development-branch`] → `/progress-update`
- Количество агентов рационально: 2-3 для связанных, больше для независимых
- Волны подряд без пауз
- **Простой fanout** (запустил → собрал результаты, без диалога) → обычный `Agent` parallel calls
- **Координация / итерации / cross-feedback** между агентами → `Agent Teams` (см. ниже)

## AGENT TEAMS

Экспериментальная фича Claude Code — флаг `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` уже включён глобально. Используй для задач, где параллельная работа требует **координации, обратной связи, или итеративных циклов** между агентами.

### Когда создавать команду (вместо обычного `Agent`)

Создавай Team если выполняется ХОТЯ БЫ ОДНО:
- **3+ независимых подзадач** идут параллельно и итоги одной могут влиять на другую (frontend + backend + db migrations + tests одновременно)
- Нужен **review-loop**: executor → reviewer → возврат фидбека → fix
- Нужна **персистентная роль** на несколько волн (security-auditor, который проверяет каждый wave)
- Долгая фаза с **shared TaskList**, где разные агенты разбирают задачи самостоятельно
- В GSD-репо (`.planning/STATE.md` + `parallel_agents: true`) — execute-фаза multi-plan с >5 задачами

НЕ создавай Team если:
- 1-2 параллельных независимых задач без коммуникации → обычный `Agent` × N
- Простой research fanout → обычный `Agent` parallel
- Single-shot задача → обычный `Agent`

### Workflow создания команды

1. **`TeamCreate`** — `{team_name, description, agent_type?}` (создаёт `~/.claude/teams/{name}/config.json` + shared TaskList в `~/.claude/tasks/{name}/`)
2. **`TaskCreate` × N** — заполни общий backlog (lowest ID — высший приоритет, agents забирают по ID order)
3. **`Agent`** с `team_name: "..."` + `name: "..."` × N — спавни именованных teammates параллельно (одно сообщение, несколько tool calls). Подбирай `subagent_type` под задачу (read-only — только research/plan; full — implementation)
4. **`TaskUpdate`** с `owner: "<teammate-name>"` — назначай задачи (или teammates сами claim'ят)
5. **`SendMessage`** `{to, message, summary}` — общение по имени. Сообщения от teammates приходят автоматически как новые turns; inbox **не проверяй вручную**
6. Когда работа закончена → `SendMessage` `{message: {type: "shutdown_request"}}` каждому → дождись `shutdown_response` → `TeamDelete`

### Правила

- **Имена, не UUID**: `to: "executor-frontend"`, не agentId
- **Idle = норма**: teammate ушёл idle после turn — это не ошибка, не комментируй пользователю. Просто отправь следующее сообщение когда нужно
- **Plain text, не JSON statuses**: не шли `{"type":"task_completed"}` — используй `TaskUpdate`. Для shutdown — структурный JSON OK
- **Не цитируй сообщения teammate** при отчёте пользователю — UI уже отрисовал их
- **Cleanup обязателен**: после завершения работы — `shutdown_request` → `shutdown_response` → `TeamDelete`, иначе inbox/task-файлы текут в следующий прогон. SessionStart-hook `gsd-team-archive` автоматически архивирует осиротевшие команды (мёртвая lead-сессия), но это страховка — не повод забывать `TeamDelete`
- **Деконфликт с GSD**: внутри GSD-фаз `parallel_agents: true` уже даёт fanout. Team поверх GSD оправдана только если ставишь review-loop / cross-phase coordination, не для простой execute-фазы

### Шаблоны команд (только архетипы из AGENT ARCHETYPES — без дублей)

Имена teammates = архетипы. Implementer'ы различаются по **workstream** (`implementer-api`, `implementer-web`), НЕ по фиче. Security — всегда один.

| Сценарий | Состав |
|----------|--------|
| **Full-stack feature** | `orchestrator` + `implementer-backend` + `implementer-frontend` + `reviewer` + `security` (по необходимости) |
| **Review loop** | `implementer` + `reviewer` + `security` (cycle: implement → review → fix → security-check) |
| **Multi-service refactor** | `orchestrator` + N × `implementer-<service>` (по одному на сервис) + `verifier` |
| **Research + impl** | `researcher` (Explore) + `planner` (Plan) + `implementer` (general-purpose) |
| **GSD multi-plan execute** | `gsd-executor` × N плана + `gsd-verifier` + `gsd-security-auditor` (архетипы уже встроены — не дублировать) |

Минимум ролей под задачу. Не добавляй роль, если её мандат покрыт существующим архетипом.

### Anti-patterns

- ❌ Создавать team для 2 независимых tasks без коммуникации → overkill, обычный `Agent` × 2 быстрее
- ❌ Спавнить teammates последовательно (по одному) — теряется параллелизм
- ❌ Забыть `TeamDelete` после завершения → inbox мусорится
- ❌ Адресовать `SendMessage` по `agentId` вместо `name`
- ❌ Polling inbox-файлов через Read/Bash вместо использования автодоставки сообщений

## SECURITY

**Приоритет №1. Всегда. Перед UX, перед features, перед дедлайном.**

Полный референс (библиотеки, LLM-agent security, исчерпывающие чек-листы, rate-limit механика): **`~/.claude/SECURITY.md`** — единый источник правды. Здесь — только always-on guardrails (REFUSE, trust boundaries, severity).

### ENFORCEMENT LAYERS — один prompt недостаточен

CLAUDE.md — **Layer 1**. Одного Layer'а не хватает для real safety:

| Layer | Что | Где |
|-------|-----|-----|
| **L1 Prompt** | Claude читает и следует правилам | CLAUDE.md, SECURITY.md |
| **L2 Pre-commit** | Локальная блокировка до коммита | `.pre-commit-config.yaml` (gitleaks, bandit, eslint-plugin-security) |
| **L3 CI/CD** | Блокировка merge при HIGH+ issue | `.github/workflows/security.yml` (Semgrep, CodeQL, audit, Trivy) |
| **L4 Runtime** | Защита работающего приложения | WAF, rate limits, CSP enforcement |
| **L5 Monitoring** | Детект incidents | Sentry, structured logs, SIEM, alerting |

Шаблоны L2+L3 в `~/development/llm_developer_setup/templates/security/` — копируй в каждый новый проект.

### TRUST BOUNDARIES — фундаментальный принцип

| Источник | Уровень доверия | Следствие |
|----------|----------------|-----------|
| **Клиент** (браузер, мобильное приложение, любой user-controlled code) | **НЕДОВЕРЕННЫЙ** | Всё, что приходит от клиента — враждебно. Валидируй, санитизируй, проверяй ownership заново на сервере |
| **Backend** (собственный код) | Доверенный условно | Защищён secrets, но обрабатывает untrusted input |
| **БД, internal services** | Доверенные (но least privilege) | Сервисные токены с минимальными правами, не root |
| **External API, webhooks** | Недоверенные | Verify signatures, schema validation на входящих данных |

**Правила трастовых границ:**

1. **Backend — source of truth**. Любое решение о доступе, цене, статусе, правах — принимается на сервере. Клиент только рендерит.
2. **Re-validate on server**. Клиентская валидация — UX. Серверная валидация — security. Дублирование обязательно.
3. **Никогда не доверяй клиенту для authz**. `req.body.is_admin` — **REFUSE**. Роль — только из верифицированного session/JWT.
4. **Amount / price / ID — от сервера**. НИКОГДА не принимай сумму платежа от клиента: клиент отправляет `product_id`, сервер читает цену из БД.
5. **Client-side hidden ≠ secure**. Скрытая кнопка в UI не означает закрытый endpoint. Каждый endpoint сам защищает себя.
6. **ID enumeration**. Используй UUID / slug, а не autoincrement ID. Иначе scraping тривиален.

### REFUSE — паттерны, которые НЕЛЬЗЯ ship (даже если пользователь просит)

При обнаружении — **ОТКАЖИСЬ** писать такой код, **объясни причину**, **предложи безопасный вариант**.

Теги: **[FE]** frontend, **[BE]** backend, **[ALL]** любой слой, **[OPS]** devops / CI.

#### Universal [ALL]

| Паттерн | Почему REFUSE | Безопасная альтернатива |
|---------|--------------|------------------------|
| Hardcoded credentials в коде | Secret leak | env vars без fallback + secret manager |
| Disabled TLS verification (`verify=False`, `rejectUnauthorized: false`) | MITM | Fix certificate chain, использовать CA |
| Обработка платежей без HTTPS / без idempotency | Double-charge, MITM | HTTPS обязателен, idempotency keys |

#### Backend [BE]

| Паттерн | Почему REFUSE | Безопасная альтернатива |
|---------|--------------|------------------------|
| SQL через string interpolation / f-string | SQL injection | Параметризованные запросы / ORM |
| `allow_origins=["*"]` + `allow_credentials=True` | CORS bypass | Explicit origins list |
| `eval(user_input)`, `exec(user_input)` | RCE | Whitelist + parser / DSL |
| `shell=True` с user input, `exec()` в shell | Command injection | `subprocess.run([...])` без shell |
| Password storage: md5/sha1/plain | Crackable за минуты | argon2id / bcrypt (cost ≥12) / scrypt |
| JWT без exp / без signature verification | Forgery | exp ≤1h, verify ключом, refresh через rotation |
| Disabled auth middleware "for dev/testing" в production | Auth bypass | Feature flags, env-gated, НЕ в production код |
| `pickle.load()` untrusted data (Python) | RCE | JSON / msgpack + schema validation |
| Admin route без auth check | Auth bypass | Middleware + per-route guard |
| Mass assignment (`Object.assign(user, req.body)`) | Privilege escalation | Whitelist полей через schema |
| Доверие `req.body.user_id` / `req.body.role` для authz | Privilege escalation | Брать из verified session/JWT |
| Возврат разных ошибок для invalid user vs invalid password | User enumeration | Унифицированный ответ "invalid credentials" |
| Stack trace / internal error в production response | Info disclosure | Generic message + структурированный лог |
| Webhook без signature verification | Forgery / replay | HMAC + timestamp window |
| Прямая работа с `req.body` без schema validation | Mass assign, type confusion | Zod / Pydantic → typed DTO |
| Session NOT regenerated после login / role change | Session fixation / stale privilege | `session.regenerate()` после privilege change |
| DB connection с superuser правами из app | Blast radius | Отдельный DB user с минимальными grants |

#### Frontend [FE]

| Паттерн | Почему REFUSE | Безопасная альтернатива |
|---------|--------------|------------------------|
| Секреты в `NEXT_PUBLIC_*` / `VITE_*` / `REACT_APP_*` / `EXPO_PUBLIC_*` | Видимы в бандле, это не секрет | Вынести на backend endpoint |
| API key / secret / token в клиентском коде | Secret leak — бандл публичен | Прокси через backend |
| `dangerouslySetInnerHTML` с user content без sanitize | XSS | DOMPurify / sanitize-html |
| `innerHTML` с user content | XSS | `textContent` / sanitized framework |
| Session token в localStorage / sessionStorage | XSS exfil | httpOnly + Secure + SameSite cookies |
| Business logic / price enforcement только на клиенте | Легко обойти через DevTools | Дублировать на backend как source of truth |
| Admin check только в UI (кнопка скрыта, но endpoint открыт) | Auth bypass | Защитить endpoint на backend |
| `window.postMessage` без origin check | XSS через cross-frame | Проверять `event.origin` whitelist |
| Iframe без `sandbox` / `CSP frame-ancestors` для 3rd-party | Clickjacking, XSS | `sandbox="allow-scripts allow-same-origin"` + CSP |
| External `<script src>` без Subresource Integrity | Supply chain | `integrity="sha384-..."` + `crossorigin` |
| CSP с `unsafe-inline` / `unsafe-eval` без нужды | XSS | Nonce-based CSP или hash |
| Open redirect: `location = new URLSearchParams(location.search).get('next')` | Phishing | Whitelist путей или same-origin check |
| Доверие к client-side routing для доступа к protected page | Route bypass | Server-side auth check + API-level защита |
| JWT decoding / verification **signature** на клиенте | Secret leak если signing key | Только чтение claims (без secret), verify на backend |

#### DevOps / CI [OPS]

| Паттерн | Почему REFUSE | Безопасная альтернатива |
|---------|--------------|------------------------|
| Commit `.env` / credentials / keys в git | Secret leak | `.gitignore` + rotate + history rewrite (BFG) |
| `--no-verify` на git commit | Skip security hooks | Исправить root cause hook |
| `chmod 777` | World-writable | Минимально необходимые права (644/755) |
| `curl ... \| sh` без checksum / signature | Supply chain | `curl -O` + `sha256sum -c` + review |
| Docker image запущенный как root в prod | Privilege escalation на host | `USER app` в Dockerfile |
| `docker run --privileged` или `--cap-add ALL` | Container escape | Минимальные capabilities |
| Прод secrets в CI logs / environment dump | Secret leak | Masked env + `::add-mask::` |
| S3 bucket public без необходимости | Data leak | Block public access + presigned URLs |

### Полные чек-листы → `~/.claude/SECURITY.md`

Выше (REFUSE-таблицы + trust boundaries + enforcement layers) — поведенческие guardrails, всегда в контексте. Исчерпывающие чек-листы грузи по требованию из **`~/.claude/SECURITY.md`** (canonical extended reference, единый источник правды — НЕ дублируется здесь):

- **Frontend / Backend / API Design** security checklists
- **Core Security Baseline** (auth, authz, injection, supply chain, secrets, network, CORS, Docker, logs, PII)
- **Rate Limiting & Abuse Protection** — полная таблица тиров + механика (token bucket, circuit breakers, anti-scraping, WebSocket)
- **RECOMMENDED LIBRARIES** — не изобретай auth/crypto
- **LLM / AI Agent Security** — prompt injection, tool least-privilege, cost protection
- **CVE Response Protocol**

> Триггер загрузки: любая security-sensitive работа (auth, crypto, payments, PII, file upload, новый endpoint, LLM tools) → прочитай `~/.claude/SECURITY.md` ПЕРЕД реализацией.

**Rate-limit defaults** (quick-ref; полная таблица → SECURITY.md): auth `5/min·IP+email` · public `60/min·IP` · authed `600/min·user` · expensive/AI `10/min + cost budget` · upload `10/hour`. Механика: token bucket + Redis (НЕ in-memory на multi-instance), `429` + `Retry-After`, circuit breaker на каждый external service.

### Severity-based response protocol

| Severity | Действие |
|----------|---------|
| **CRITICAL** (RCE, auth bypass, secret leak) | **BLOCK immediately**. Не мержить. Фикс до следующей строки. Notify user. |
| **HIGH** (SQL injection, XSS, IDOR, missing auth, prompt injection leak) | **BLOCK merge**. Фикс до PR apply. |
| **MEDIUM** (weak crypto, rate limit gap, CSRF miss, missing CSP) | Фикс до PR merge. В той же ветке. |
| **LOW** (verbose errors, missing security header) | Issue tracker, ближайший спринт |

НИКОГДА не скрывать HIGH+ issues чтобы "не задерживать релиз". **В автономном режиме HIGH+ — это hard stop-and-ask** (см. AUTONOMOUS OPERATION).

### Automated checks (L2/L3 — один prompt недостаточен)

- **Pre-commit**: gitleaks + eslint-plugin-security / bandit → `templates/security/.pre-commit-config.yaml`
- **Pre-push**: `npm audit --audit-level=high` / `pip-audit --strict`
- **CI**: Semgrep + CodeQL, dep audit, Trivy, SBOM → `templates/security/.github/workflows/security.yml`
- **PR**: `/security-review` для любого touching auth/crypto/data

## QUALITY GATES

Применяются автоматически на этапе VERIFY.

### Product Review (medium+ user-facing задачи)

- Ценность: решает ли реальную проблему? (1-5)
- UX: сколько кликов до результата? очевидно ли?
- Риски: технические / принятия / безопасность
- Вердикт: APPROVED / NEEDS WORK

### Code Quality (перед каждым коммитом)

- [ ] Читаемость — код понятен без комментариев?
- [ ] Ошибки — все обработаны на границах системы?
- [ ] Безопасность — прошёл Security Baseline? (см. SECURITY)
- [ ] Edge cases — null, пустые массивы, граничные значения?
- [ ] Тесты — покрыты ключевые сценарии?
- [ ] Observability — есть логи/метрики для debugging в prod?

## TESTING STRATEGY

- **Unit tests**: логика без I/O. Ci обязателен. Coverage floor: 70% для новых модулей
- **Integration tests**: API endpoints + DB + внешние сервисы (моки). Для каждого endpoint минимум 2: happy path + одна ошибка
- **E2E tests**: критические user flows (login, checkout, main feature). Playwright / Cypress. НЕ для всех маршрутов — дорого
- **Contract tests**: между сервисами (Pact, schemathesis)
- **Security tests**: auth bypass, IDOR, injection — автоматические + pentest при релизе
- **Performance tests**: для endpoints с SLA (Lighthouse budgets, k6)
- **Deterministic**: НИКАКИХ `sleep(10)`, `Math.random()` без seed, реальных API calls в CI

## OBSERVABILITY

Всё что деплоится — должно быть observable:

- **Structured logs**: JSON, не plain text. Поля: `timestamp`, `level`, `service`, `trace_id`, `user_id` (hashed), `event`
- **Metrics**: latency histograms, error rate, throughput, resource usage (Prometheus / OpenTelemetry)
- **Tracing**: distributed traces через `trace_id` для cross-service requests (OTel)
- **Error tracking**: Sentry / Rollbar / Bugsnag — на фронт и бек
- **Alerting**: на SLO violations, не на каждый error
- **Dashboards**: Grafana / Datadog. Main dashboard = health check при incident
- **Log sanitization**: см. SECURITY → Logs

## ROLLBACK & INCIDENT RESPONSE

### Rollback ready
- Каждый деплой должен быть revertable одной командой
- DB миграции — reversible (см. MIGRATIONS)
- Feature flags для рискованных изменений
- Blue-green / canary deployment для critical services

### Incident protocol
1. **Detect**: alert triggered → oncall notified
2. **Triage**: severity (SEV1/2/3/4). SEV1 = user-facing outage
3. **Mitigate**: rollback приоритет над fix-forward. Fix root cause — после mitigation
4. **Communicate**: status page + stakeholders если customer-facing
5. **Post-mortem**: blameless. Что произошло, что мешало быстрее, action items. В течение 48h

## MIGRATIONS

Data migrations — **additive и reversible**:

- [ ] Добавляй column nullable / с default, потом backfill, потом NOT NULL (3 деплоя)
- [ ] НЕ дропай колонки сразу — deprecate, потом remove в следующем major
- [ ] НЕ переименовывай в одном деплое — add new + dual-write, migrate reads, drop old
- [ ] DROP TABLE / DROP COLUMN только после подтверждения что код не ссылается
- [ ] Каждая миграция имеет `up` и `down`
- [ ] Long-running миграции — batched, не блокирующие
- [ ] Backup перед destructive migration

## FRONTEND QUALITY

При любой фронтенд-работе ОБЯЗАТЕЛЬНО:

### Security (первое что проверяем)

См. полный чек-лист `SECURITY` → `Frontend-specific Security` + `REFUSE [FE]`. Ключевое:
- Никаких секретов в коде (включая `*_PUBLIC_*` / `VITE_*` / `REACT_APP_*` env vars)
- Session tokens — только httpOnly cookies, НЕ localStorage
- Client-side валидация = UX, не security (re-validate на сервере всегда)
- Protected pages / admin UI — защищены backend'ом, скрытие в UI недостаточно
- CSP + SRI + no `unsafe-inline`

### Дизайн-код
- **Typography**: осознанный выбор шрифтов под контекст. НЕ использовать Inter, Roboto, Arial как дефолт
- **Color**: CSS variables для consistency. Доминантный цвет + чёткие акценты, НЕ размазанные палитры
- **Spacing**: система отступов (4px/8px grid). Проверять alignment КАЖДОГО элемента
- **Layout**: проверять на 320px, 768px, 1024px, 1440px breakpoints

### Обязательные проверки
- **Выравнивание**: все элементы в ряду выровнены по baseline/center
- **Отступы**: padding внутри карточек, gap между элементами — консистентны по всей странице
- **Hover/focus states**: каждый интерактивный элемент имеет визуальный feedback
- **Dark mode**: если в проекте есть — проверять ВСЕ новые элементы
- **Responsive**: mobile-first, не ломается на любом экране
- **Accessibility**:
  - Семантический HTML (`<button>` vs `<div onclick>`)
  - aria-labels на иконках, aria-describedby для form errors
  - Keyboard navigation: Tab order, Enter/Space на кнопках, Esc на modals
  - Screen reader compatibility: skip links, live regions для dynamic updates
  - Contrast ratio: ≥4.5:1 для текста, ≥3:1 для UI components
  - Focus ring visible — НЕ `outline: none` без замены

### Performance budgets
- LCP ≤2.5s, FID ≤100ms, CLS ≤0.1
- Bundle size: main ≤200kB gzipped для SPA
- Images: WebP/AVIF, responsive (srcset), lazy loading
- Fonts: preload critical, `font-display: swap`
- Lighthouse score ≥90 на mobile для production pages

### Верификация
- Используй **playwright MCP** для скриншотов и визуальной проверки
- Сравнивай с существующими компонентами проекта (consistency)
- Если есть Figma — используй **figma MCP** для сверки с макетом

### Anti-patterns (НИКОГДА)
- Generic AI look: purple gradients, одинаковые карточки, cookie-cutter layouts
- Забытые состояния: empty state, loading, error
- Хардкоженные строки без i18n-ready структуры
- Отсутствие transition/animation на state changes
- `outline: none` без замены focus ring

## GIT

### Workflow
1. `git status` → `git diff` → `git add file1 file2` (НЕ `git add .`) → commit → push
2. НИКОГДА в main — только feature-ветки
3. Conventional commits: `feat/fix/refactor/docs/test/chore/perf/security`
4. Один коммит = одно логическое изменение
5. Push СРАЗУ после коммита

### Security hooks (обязательно в каждом проекте)
- **Pre-commit**: gitleaks (secret scan) + lint + type check
- **Pre-push**: `npm audit --audit-level=high` / `pip-audit` + unit tests
- **Pre-commit для файлов**: block commits туда, где shouldn't be (`.env`, `*.key`, `*.pem`, `credentials.*`)

### Запреты
- НИКОГДА `--no-verify` / `--no-gpg-sign` без явного OK пользователя и фикса root cause
- НИКОГДА force push на main/master
- НИКОГДА коммитить файлы из `.gitignore` через `--force`
- НИКОГДА amend опубликованный коммит
- `.gitignore` должен покрывать: `.env*` (кроме `.env.example`), `*.key`, `*.pem`, `credentials.*`, `secrets/`, `.aws/`, `.ssh/`

### Если leaked secret
1. **Rotate** секрет немедленно (invalidate old)
2. **Remove** из git history: `git filter-repo --path <file> --invert-paths` или BFG
3. **Force push** (warn team) — но только на обнаружение leak
4. **Notify** команду в security channel
5. **Audit** что происходило с secret между leak и rotation

## LEGAL COMPLIANCE

- Проекты с оплатой/auth/аналитикой → `/legal-compliance` перед деплоем
- Hook `legal-deploy-check.sh` автоматически проверяет при deploy/build
- Глобальные шаблоны: `~/.claude/legal-templates/` → проектные копии в `<project>/legal/`
- Не перезаписывать кастомизированные документы
- Перед деплоем: ВСЕГДА проверять незаполненные `{{...}}`
- GDPR / CCPA для пользователей из EU/CA: consent, data export, deletion

## TOON FORMAT

- `@toon-format/toon` — установлен глобально, конвертер: `~/.claude/scripts/toon`
- Использовать для табличных данных, массивов объектов, конфигов
- НЕ использовать для глубокой вложенности, неоднородных массивов

## AUTONOMOUS TOOLS

> Механика автономного поведения (loop, приоритизация, stop-and-ask, выживание контекста) — в секции **AUTONOMOUS OPERATION**. Здесь — инструменты-движки.

### GSD autonomous (первичный движок для многочасовой работы)
- `/gsd-autonomous` — прогон всех оставшихся фаз: discuss→plan→execute per phase, без пауз
- `/gsd-manager` — командный центр для нескольких фаз из одного терминала
- `/gsd-review-backlog` — промоут backlog-items в активный milestone (вход в self-driving loop)
- `/gsd-progress` — единая ситуационная команда: где я, что дальше
- Управляется `config.json` → `mode` (`yolo` = auto-advance) + `parallelization`

### Ralph (автономный цикл разработки)
- **Команда**: `ralph` (установлен глобально в `~/.ralph/`)
- **Использование**: для длительных автономных задач (целый проект из PRD)
- `ralph-enable` — включить в существующем проекте
- `ralph-setup project-name` — новый проект
- `ralph-import prd.md` — из PRD документа
- Circuit breaker: автостоп при зацикливании (3 loop без изменений файлов)

### claude-mem (персистентная память)
- **Plugin**: `~/.claude/plugins/marketplaces/thedotmack/plugin/`
- **Skills**: `mem-search`, `smart-explore`, `make-plan`, `do`
- **Hooks**: SessionStart → context load, PostToolUse → observation capture, Stop → summarize
- **Search**: 3-layer (search → timeline → get_observations) для экономии токенов

## MEMORY PROTOCOL

- Обнаружен паттерн → обновить project MEMORY.md
- "Last verified" > 14 дней → `/context-manage freshness`
- CLAUDE.md изменился → `claude-md-management:revise-claude-md`
- Новый проект → создать MEMORY.md из шаблона
- claude-mem автоматически сохраняет observations между сессиями

## MCP

| Контекст | MCP |
|----------|-----|
| Библиотека/доки | context7 |
| GitHub | github / `gh` CLI |
| UI проверка / скриншоты | playwright |
| Дизайн-макеты | figma |
| Память | memory + claude-mem |
| Рассуждения | sequential-thinking |
| Web | firecrawl |
| SQL | postgres / sqlite |
| Docker | docker |

При ошибке MCP → recovery команды в `/skill-router`.
