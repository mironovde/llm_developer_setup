# Skill Router — Анализ задачи и подбор инструментов

Проанализируй задачу: $ARGUMENTS

## Шаг 1: Классификация

Определи:
- **Тип**: feature | bugfix | refactor | research | review | devops | design
- **Scope**: user-facing | internal | infrastructure
- **Сложность**: simple (1-2 шага) | medium (3-5) | complex (6+)
- **Домены**: frontend | backend | database | infra | mobile | ML | API

## Шаг 2: Pipeline по типу задачи

### REQUIRED — полные цепочки скиллов

| Тип + сложность | Pipeline |
|------------------|----------|
| **Feature (user-facing, medium+)** | ANATOMY → `brainstorming` → `writing-plans` → BUILD → Quality Gates → `verification-before-completion` → SHIP → `progress-update` |
| **Feature (internal, medium+)** | ANATOMY → `brainstorming` → `writing-plans` → BUILD → Quality Gates → `verification-before-completion` → SHIP → `progress-update` |
| **Feature (simple)** | implement → `verification-before-completion` → SHIP |
| **Bugfix** | `systematic-debugging` → fix → `verification-before-completion` → SHIP |
| **Refactor** | ANATOMY (сокр.) → plan → implement → `verification-before-completion` → SHIP |
| **Research** | Explore agent → summarize |
| **Review** | `receiving-code-review` / `requesting-code-review` |
| **Design/UI** | ANATOMY → `frontend-design:frontend-design` + `/frontend-design-pro` → implement → `verification-before-completion` |

**ANATOMY** = structured prompt по шаблону из CLAUDE.md (полная для complex, сокращённая для medium)
**BUILD** = `subagent-driven-development` (default) | `executing-plans` (по запросу) | direct (simple)
**SHIP** = `/git-workflow` → push → [`finishing-a-development-branch`]
**Quality Gates** = Product Review + Code Quality из CLAUDE.md

### CONDITIONAL — при выполнении условия

| Условие | Skill | Когда в pipeline |
|---------|-------|-----------------|
| User-facing UI/UX | Product Review (CLAUDE.md) | на этапе VERIFY |
| Cost impact (infra, API, hosting) | `/financial-review` | перед финальным решением |
| 2+ независимых подзадач | `/agent-team` | на этапе BUILD |
| Frontend компонент | `frontend-design:frontend-design` + `/frontend-design-pro` | на этапе design |
| TDD запрошен явно | `test-driven-development` | заменяет BUILD |
| Feature development | `feature-dev:feature-dev` | заменяет BUILD |

### LIFECYCLE — события сессии

| Событие | Действие |
|---------|----------|
| 3+ задач завершено | `/context-manage status` |
| Фича завершена / ветка смержена | `/progress-update` |
| Паттерн обнаружен | обновить MEMORY.md |
| MEMORY.md "Last verified" > 14 дней | `/context-manage freshness` |

## Шаг 3: MCP

MCP серверы и recovery команды — см. CLAUDE.md секция MCP.

Проверь доступные MCP через ToolSearch.

## Выходной формат

```
ROUTING DECISION
================
Тип: [тип] | Scope: [user-facing/internal/infra]
Сложность: [simple/medium/complex]
Домены: [список]

ANATOMY: [полная/сокращённая/не нужна]
PIPELINE: [skill1] → [skill2] → ... → [skillN]
Conditional skills: [список с условиями или "—"]
Lifecycle reminders: [список или "—"]

MCP: [доступные] | Нужно добавить: [список]
Agent Team: [да/нет] → [конфигурация]
Git: [ветка: feature/название]

Следующий шаг: [конкретное действие]
```

Выполни анализ и СРАЗУ приступай к первому шагу pipeline.
