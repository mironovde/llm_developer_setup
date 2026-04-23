# LLM Developer Setup — Entry Point Configuration

> Этот проект — шаблон/entry point для новых проектов с Claude Code.
> Глобальные правила (pipeline, git, MCP, overrides) → `~/.claude/CLAUDE.md`

## Назначение

Этот репозиторий содержит:
- Набор skills для Claude Code (`.claude/skills/`)
- MCP конфигурацию (`.mcp.json`)
- Шаблон workflow для новых проектов

## Как создать CLAUDE.md для нового проекта

```markdown
# [Project Name]

> Last verified: [date]

## Stack
- [framework, language, DB, etc.]

## Key Files
- [основные пути]

## Conventions
- [project-specific правила]

## Dev Commands
- `[dev]`: [описание]
- `[test]`: [описание]
- `[build]`: [описание]
```

## Как инициализировать MEMORY.md для нового проекта

Создай `~/.claude/projects/-Users-mironovde-development-[project-name]/memory/MEMORY.md`:

```markdown
# [Project Name] — Project Memory

> Last verified: [date]

## Project Structure
- [to discover]

## Stack
- [to discover]

## Key Files
- [to discover]

## Known Patterns
- [to discover]

## History
- [date]: Memory file initialized
```

## Available Skills

Skills в `.claude/skills/` — project-local копии, работают только внутри этого репо:

| Skill | Назначение |
|-------|------------|
| skill-router | Роутинг задач → skills + MCP |
| task-decomposition | Декомпозиция на подзадачи |
| testing-challenger | Тестирование и качество |
| product-manager | Продуктовый челлендж |
| financial-analyst | ROI анализ |
| git-workflow | Git операции |
| context-manager | Оптимизация контекста |
| progress-tracker | Прогресс проекта |

> Глобальные skills (superpowers:*, feature-dev:*, code-review:*) доступны из любого проекта.

## Branching Strategy

```
main
  ├── feature/task-name
  ├── experiment/idea-name
  ├── bugfix/issue-name
  └── release/version
```

## Project Status

Прогресс в `PROJECT_STATUS.md`. Обновляется через `/progress-update`.
