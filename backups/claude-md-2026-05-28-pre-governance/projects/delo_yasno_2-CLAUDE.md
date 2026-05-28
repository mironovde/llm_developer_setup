# Delo Yasno — Финансовое моделирование

## Stack
- Frontend: Next.js 14.2.35 (App Router), Tailwind CSS, Recharts
- Backend: Express + Prisma (port 3001)
- Frontend dev: port 3000, API proxy через next.config.js

## Глобальные инструкции
Этот проект наследует глобальный протокол из `~/.claude/CLAUDE.md`:
- Автоматический роутинг задач
- Git дисциплина (conventional commits, feature-ветки, push после коммита)
- Автоподбор MCP (context7, github, etc.)
- Agent Teams для сложных задач

## Дизайн-система
- Tailwind config: `frontend/tailwind.config.ts`
- Custom colors: primary, neutral, success, danger, warning (50-950 shades)
- `accent` определён как `accent.blue`, `accent.indigo` — НЕ `accent-500`
- Для gradient targets используй `violet-500`, `indigo-500` etc.
- Card: `@/components/ui/Card.tsx` с вариантами (default, bordered, elevated, interactive)
- Не допускай вложенности карточек (card-gradient wrapper + Card inside)

## Ключевые паттерны
- `scrollbar-gutter: stable` на html для предотвращения сдвига layout
- Toast уведомления: `top-20` (ниже header 64px + 16px gap)
- Tailwind НЕ обнаруживает динамически собранные классы — используй полные статические строки
- Model detail: layout `page-container-wide`

## Структура проекта
- Wizard: `frontend/src/components/wizard/`
- Model detail: `frontend/src/app/models/[id]/page.tsx`
- Analytics: `frontend/src/components/analytics/`
- Charts: `frontend/src/components/charts/`
- AI Insights: `frontend/src/components/model/AIInsights.tsx`
- Goals: `frontend/src/components/model/GoalProgressPanel.tsx`
- UI: `frontend/src/components/ui/`

## Разработка
```bash
# Frontend
cd frontend && npm run dev

# Backend
cd backend && npm run dev

# Тесты
cd frontend && npm test
```

## MCP для этого проекта
- `postgres` — подключена к БД проекта
- `filesystem` — доступ к файлам проекта
- `context7` — документация Next.js, Tailwind, Recharts, Prisma
