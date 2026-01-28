# LLM Developer Setup - Frontend Developer Specialization

## Specialization: Frontend Development (React, Vue, TypeScript, CSS)

This configuration is optimized for modern frontend development with focus on React ecosystem, TypeScript, and modern CSS techniques.

## Critical Workflow: Always Start Here

**MANDATORY FIRST STEP**: Before ANY task execution, you MUST:
1. Read this file completely
2. Invoke `/skill-router` to determine relevant skills and MCPs
3. Decompose the task using `/task-decomposition`
4. Only then proceed with implementation

## Core Principles

### Context Efficiency
- Load only relevant skills for current task
- Unload context that's no longer needed
- Use skill router to optimize context usage
- Keep working memory focused on active task

### Git Discipline
- Create feature branches for any non-trivial work
- Make atomic, well-documented commits
- Update PROJECT_STATUS.md after each milestone
- Merge to main only after testing and review

### Quality Standards
- Every component must be tested (Jest, Testing Library)
- Components must be accessible (WCAG 2.1 AA)
- Design must be responsive
- Product usability is paramount

## Available Skills

### Core Skills (All Specializations)
| Skill | Command | Purpose |
|-------|---------|---------|
| Skill Router | `/skill-router` | **MANDATORY** - Determines which skills to load |
| Task Decomposition | `/task-decomposition` | Breaks tasks into atomic subtasks |
| Product Manager | `/pm-challenge` | Challenges product decisions |
| Financial Analyst | `/financial-review` | Reviews financial aspects |
| Git Workflow | `/git-workflow` | Manages git operations |
| Testing Challenger | `/test-challenge` | Tests and challenges results |
| Context Manager | `/context-manage` | Optimizes context usage |
| Progress Tracker | `/progress-update` | Updates project status |

### Frontend-Specific Skills
| Skill | Command | Purpose |
|-------|---------|---------|
| React Development | `/react-dev` | React patterns and best practices |
| CSS Styling | `/css-style` | Modern CSS, Tailwind, design systems |
| Accessibility | `/accessibility` | WCAG compliance and a11y patterns |
| Frontend Testing | `/frontend-testing` | Jest, Testing Library, E2E |
| Performance | `/performance` | Core Web Vitals, optimization |

## Technology Stack

### Core
- **Language**: TypeScript (strict mode)
- **Framework**: React 18+ / Next.js 14+
- **State**: React Query, Zustand, Jotai
- **Forms**: React Hook Form + Zod

### Styling
- **CSS**: Tailwind CSS / CSS Modules
- **Components**: Radix UI, shadcn/ui
- **Animation**: Framer Motion
- **Icons**: Lucide React

### Testing
- **Unit**: Jest + React Testing Library
- **E2E**: Playwright / Cypress
- **Visual**: Storybook + Chromatic
- **A11y**: axe-core, jest-axe

### Build
- **Bundler**: Vite / Turbopack
- **Package Manager**: pnpm
- **Linting**: ESLint + Prettier
- **CI/CD**: GitHub Actions

## Workflow Pattern

```
User Request
    │
    ▼
┌─────────────────┐
│  /skill-router  │ ◄── MANDATORY: Route to frontend skills
└────────┬────────┘
         │
         ▼
┌─────────────────────┐
│ /task-decomposition │ ◄── Break into atomic subtasks
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│   /react-dev        │ ◄── Component architecture
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│   /css-style        │ ◄── Styling and design
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│   /accessibility    │ ◄── Ensure WCAG compliance
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│ /frontend-testing   │ ◄── Test components
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│   /performance      │ ◄── Optimize performance
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│   /pm-challenge     │ ◄── Product review
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│   /progress-update  │ ◄── Update status & commit
└─────────────────────┘
```

## Code Standards

### TypeScript
- Strict mode enabled
- No `any` types
- Explicit return types for functions
- Use type inference where clear

### React Patterns
- Functional components only
- Custom hooks for logic reuse
- Composition over inheritance
- Server Components where possible

### CSS Patterns
- Design tokens for consistency
- Mobile-first responsive
- CSS custom properties
- Avoid !important

## Project Structure

```
src/
├── app/                 # Next.js app router
│   ├── (auth)/         # Route groups
│   ├── api/            # API routes
│   └── layout.tsx
├── components/
│   ├── ui/             # Base components
│   ├── features/       # Feature components
│   └── layouts/        # Layout components
├── hooks/              # Custom hooks
├── lib/                # Utilities
├── styles/             # Global styles
├── types/              # TypeScript types
└── __tests__/          # Tests
```

## Design Principles

### Visual Hierarchy
- Clear focal points
- Consistent spacing (8px grid)
- Typography scale
- Color with purpose

### Responsive Design
- Mobile-first approach
- Breakpoints: sm(640), md(768), lg(1024), xl(1280)
- Fluid typography
- Flexible layouts

### Interaction Design
- Clear affordances
- Immediate feedback
- Error prevention
- Graceful degradation

## MCP Configuration for Frontend

Recommended MCPs for frontend development:
- `github` - Repository management
- `filesystem` - Project file access
- `figma` - Design file access (if available)
- `browser` - Testing and debugging

## Branching Strategy

```
main
  │
  ├── feature/component-name
  ├── feature/page-name
  ├── bugfix/issue-description
  ├── style/design-update
  └── release/v1.0.0
```

## Remember

1. **Never skip the skill router** - it's the gateway to efficient context
2. **Decompose before implementing** - atomic tasks succeed
3. **Accessibility is not optional** - WCAG 2.1 AA minimum
4. **Test components** - unit + integration + E2E
5. **Challenge results** - better products through critique
6. **Performance matters** - Core Web Vitals are critical
