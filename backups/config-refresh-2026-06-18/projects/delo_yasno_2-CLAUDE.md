# Delo Yasno — Financial Modeling

## Stack
- Frontend: Next.js 16.2.6 + Turbopack (App Router), Tailwind CSS, Recharts (charts are client-only)
- Backend: Express + Prisma (port 3001; local dev mock backend runs on 3101 if 3001 is taken)
- Frontend dev: port 3000, API proxy via next.config.js

## Perf note
Chart-heavy Recharts panels must be imported DIRECTLY (e.g. `@/components/model/NpvIrrPanel`),
never via the `@/components/model` barrel — the barrel re-exports them type-only so they can't
be pulled into a route's First Load JS. Lazy-load below-the-fold/tab-gated charts with `next/dynamic`.

## Global instructions
This project inherits the global protocol from `~/.claude/CLAUDE.md`:
- Automatic task routing
- Git discipline (conventional commits, feature branches, push after commit)
- Automatic MCP selection (context7, github, etc.)
- Agent Teams for complex tasks (only archetypes from the global AGENT ARCHETYPES — no duplicates)

## Workflow — GSD spine (autonomous engine)

The repo is driven through **GSD** (`.planning/`, `config.json` `mode: yolo` = auto-advance, `parallelization: true`, `skip_discuss: true`). For feature/bugfix/refactor → GSD tools:
`/gsd-progress` → `/gsd-plan-phase` → `/gsd-execute-phase` → `/gsd-verify-work` → `/gsd-secure-phase`.
Autonomous mode (global AUTONOMOUS OPERATION) is active via `mode: yolo`: self-driving loop, stopping only on stop-and-ask conditions. Do NOT mix with superpowers.

## Security

Financial modeling = sensitive financial data. Before working with auth / calculations / data export → read `~/.claude/SECURITY.md`. Backend (Express+Prisma) is the source of truth for all calculations; the client only renders (trust boundaries).

## Design system
- Tailwind config: `frontend/tailwind.config.ts`
- Custom colors: primary, neutral, success, danger, warning (50-950 shades)
- `accent` is defined as `accent.blue`, `accent.indigo` — NOT `accent-500`
- For gradient targets use `violet-500`, `indigo-500` etc.
- Card: `@/components/ui/Card.tsx` with variants (default, bordered, elevated, interactive)
- Do not allow card nesting (card-gradient wrapper + Card inside)

## Key patterns
- `scrollbar-gutter: stable` on html to prevent layout shift
- Toast notifications: `top-20` (below the 64px header + 16px gap)
- Tailwind does NOT detect dynamically assembled classes — use full static strings
- Model detail: layout `page-container-wide`

## Project structure
- Wizard: `frontend/src/components/wizard/`
- Model detail: `frontend/src/app/models/[id]/page.tsx`
- Analytics: `frontend/src/components/analytics/`
- Charts: `frontend/src/components/charts/`
- AI Insights: `frontend/src/components/model/AIInsights.tsx`
- Goals: `frontend/src/components/model/GoalProgressPanel.tsx`
- UI: `frontend/src/components/ui/`

## Development
```bash
# Frontend
cd frontend && npm run dev

# Backend
cd backend && npm run dev

# Tests
cd frontend && npm test
```

## MCP for this project
- `postgres` — connected to the project DB
- `filesystem` — access to project files
- `context7` — documentation for Next.js, Tailwind, Recharts, Prisma
