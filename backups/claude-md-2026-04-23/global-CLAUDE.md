# Global Claude Code Configuration

## CORE RULES

1. **Вопросы**: пачкой 2-4 через AskUserQuestion. Если вопрос один — задавай один. НИКОГДА по одному когда их несколько.
2. **Язык**: по языку пользователя (обычно русский)
3. **Auto-invoke**: САМИ вызывай нужные skills и команды — НЕ жди пока пользователь попросит (см. AUTO-INVOKE)
4. **Задачи**: доделывай до конца — жди завершения фоновых агентов. При нехватке контекста — делай /compact и продолжай. НИКОГДА не проси пользователя открывать новую сессию
5. **Anatomy**: только complex задачи (6+ шагов) → structured prompt → 1 гейт

## AUTO-INVOKE (вызывай сам, не жди команды)

Автоматически вызывай skill/команду при обнаружении триггера:

### Обязательные (ВСЕГДА при триггере)

| Триггер | Действие |
|---------|----------|
| Любая creative work (фича, компонент, UI) | `brainstorming` skill |
| Баг, тест падает, unexpected behavior | `systematic-debugging` skill |
| Перед "готово"/коммит/PR | `verification-before-completion` skill |
| Complex задача (6+) | `/skill-router` → pipeline |
| Frontend компонент/страница | `frontend-design` skill + `/frontend-design-pro` |
| Figma URL в сообщении | `figma:implement-design` skill |
| Deploy/build команда | `/legal-compliance check` (если монетизация) |
| Ветка готова к merge | `finishing-a-development-branch` skill |
| Перед merge/PR | `requesting-code-review` skill |
| 2+ независимых подзадач | `dispatching-parallel-agents` skill |

### Условные (при наличии контекста)

| Триггер | Действие |
|---------|----------|
| Нужна документация библиотеки | context7 MCP |
| Нужна визуальная проверка UI | playwright MCP → скриншот |
| Работа с GitHub (PR, issues) | github MCP / `gh` CLI |
| Нужна информация из web | firecrawl skill |
| Plan для multi-step задачи | `writing-plans` skill |
| CLAUDE.md устарел | `claude-md-management:revise-claude-md` |
| Фокус-группа / UX-исследование | `/focus-group` |

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

## APPROVAL GATES (предсказуемое количество вопросов)

| Сложность | Вопросы | Поведение |
|-----------|---------|-----------|
| **simple** (1-2 шага) | 0 | Сразу делай |
| **medium** (3-5 шагов) | 0 | Озвучь план в 1-2 предложения → делай (не жди OK) |
| **complex** (6+ шагов) | 1 гейт | Покажи anatomy → получи OK → делай до конца без пауз |

**Между волнами агентов** — НЕ спрашивать, делать подряд.
**brainstorming** — вопросы только если бизнес-логика неясна (см. "когда спрашивать" выше).

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
| **simple** (1-2 шага) | Делай → verify → ship |
| **medium** (3-5 шагов) | Озвучь план → build → verify → ship |
| **complex** (6+ шагов, существующий проект) | superpowers: anatomy → brainstorming → writing-plans → subagent-driven → verify → ship |
| **project** (новый проект с нуля) | GSD: `/gsd:new-project` → phases → execute → verify |
| **vibekanban** (явный запрос пользователя) | VK: `/generate-prd` → `/create-plan` → `/generate-tasks` → `/work-next` |

### Правила выбора (НЕ смешивать)

- **В GSD workflow** → используй GSD инструменты (`gsd:debug`, `gsd:progress`, `gsd-verifier`). НЕ вызывай superpowers skills.
- **В superpowers workflow** → используй superpowers skills (`systematic-debugging`, `verification-before-completion`). НЕ вызывай GSD.
- **В VibeKanban workflow** → используй VK команды. НЕ смешивай с GSD/superpowers.
- **APPROVAL GATES** применяются только ВНЕ GSD/VK workflow. Внутри GSD — GSD сам управляет вопросами.

### Деконфликт инструментов

| Функция | По умолчанию | В GSD | В VibeKanban |
|---------|-------------|-------|-------------|
| Code review | `/code-review` | `gsd-verifier` | — |
| Debugging | `systematic-debugging` | `gsd:debug` | `systematic-debugging` |
| Task tracking | TaskCreate/Update | STATE.md | VK board |
| Progress | `/progress-update` | `/gsd:progress` | `/plan-status` |
| Planning | `writing-plans` | `/gsd:plan-phase` | `/create-plan` |

### BUILD: мультиагентный по умолчанию

- **VERIFY**: `verification-before-completion` + Quality Gates (вне GSD) | `gsd:verify-work` (в GSD)
- **SHIP**: `/git-workflow` → push → [`finishing-a-development-branch`] → `/progress-update`
- Количество агентов рационально: 2-3 для связанных, больше для независимых
- Волны подряд без пауз

## GSD (Get Shit Done)

Для **новых проектов** и задач, где нужен spec-driven подход с `.planning/`.

- `/gsd:new-project` — новый проект с PRD и roadmap
- `/gsd:plan-phase N` → `/gsd:execute-phase N` → `/gsd:verify-work N`
- `/gsd:quick` — быстрая задача с atomic commits
- `/gsd:resume-work` — восстановление после перезапуска

## VIBEKANBAN (только по явному запросу)

Канбан для **долгих задач с множеством подзадач**. ТОЛЬКО когда пользователь явно просит.

- PRD и спеки пиши **самостоятельно** — из контекста, кода, CLAUDE.md. Не задавай лишних вопросов.
- `/generate-prd` → `/prd-review` → `/create-plan` → `/generate-tasks` → `/work-next`
- `/work-parallel` — через git worktrees
- MCP: `vibe_kanban`

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
- [ ] Безопасность — нет injection, XSS, hardcoded секретов?
- [ ] Edge cases — null, пустые массивы, граничные значения?
- [ ] Тесты — покрыты ключевые сценарии?

### Security Baseline (для КАЖДОГО проекта)

- [ ] CORS — НЕ wildcard `*`. Указывать конкретные origins. НИКОГДА `allow_origins=["*"]` + `allow_credentials=True`
- [ ] Rate limiting — обязательно на auth, API, формы
- [ ] Security headers — Helmet (Node.js), соответствующий middleware (Python)
- [ ] Секреты — НЕ дефолтные значения в коде (`changeme`, `secret`). Только через env vars без fallback
- [ ] SQL — только параметризованные запросы. НИКОГДА string interpolation в SQL
- [ ] Input validation — Zod (TS), Pydantic (Python) на границах API

## FRONTEND QUALITY

При любой фронтенд-работе ОБЯЗАТЕЛЬНО:

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
- **Accessibility**: семантический HTML, aria-labels на иконках, contrast ratio ≥ 4.5:1

### Верификация
- Используй **playwright MCP** для скриншотов и визуальной проверки
- Сравнивай с существующими компонентами проекта (consistency)
- Если есть Figma — используй **figma MCP** для сверки с макетом

### Anti-patterns (НИКОГДА)
- Generic AI look: purple gradients, одинаковые карточки, cookie-cutter layouts
- Забытые состояния: empty state, loading, error
- Хардкоженные строки без i18n-ready структуры
- Отсутствие transition/animation на state changes

## GIT

1. `git status` → `git diff` → `git add file1 file2` (НЕ `git add .`) → commit → push
2. НИКОГДА в main — только feature-ветки
3. Conventional commits: `feat/fix/refactor/docs/test/chore/perf`
4. Один коммит = одно логическое изменение
5. Push СРАЗУ после коммита

## LEGAL COMPLIANCE

- Проекты с оплатой/auth/аналитикой → `/legal-compliance` перед деплоем
- Hook `legal-deploy-check.sh` автоматически проверяет при deploy/build
- Глобальные шаблоны: `~/.claude/legal-templates/` → проектные копии в `<project>/legal/`
- Не перезаписывать кастомизированные документы
- Перед деплоем: ВСЕГДА проверять незаполненные `{{...}}`

## TOON FORMAT

- `@toon-format/toon` — установлен глобально, конвертер: `~/.claude/scripts/toon`
- Использовать для табличных данных, массивов объектов, конфигов
- НЕ использовать для глубокой вложенности, неоднородных массивов

## AUTONOMOUS TOOLS

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
