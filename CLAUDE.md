# LLM Developer Setup - Fullstack Developer Specialization

## Specialization: Fullstack Development (React + Node.js/Python Backend)

This configuration is optimized for fullstack web development combining modern frontend frameworks with robust backend services.

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
- Frontend components tested with Jest/RTL
- Backend endpoints tested with integration tests
- E2E tests for critical user flows
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

### Fullstack-Specific Skills
| Skill | Command | Purpose |
|-------|---------|---------|
| React Development | `/react-dev` | React patterns and best practices |
| CSS Styling | `/css-style` | Modern CSS, Tailwind, design systems |
| Accessibility | `/accessibility` | WCAG compliance |
| API Design | `/api-design` | REST/GraphQL API patterns |
| Database Design | `/db-design` | Schema design and queries |
| Fullstack Integration | `/fullstack-integration` | Frontend-backend integration |
| Deployment | `/deployment` | Docker, CI/CD, infrastructure |

## Technology Stack

### Frontend
- **Framework**: React 18+ / Next.js 14+
- **Language**: TypeScript (strict mode)
- **Styling**: Tailwind CSS / CSS Modules
- **State**: React Query, Zustand
- **Forms**: React Hook Form + Zod

### Backend
- **Runtime**: Node.js / Python
- **Framework**: Express, Fastify, NestJS / FastAPI, Django
- **ORM**: Prisma, Drizzle / SQLAlchemy
- **Validation**: Zod / Pydantic

### Database
- **Primary**: PostgreSQL
- **Cache**: Redis
- **ORM**: Prisma / SQLAlchemy

### Infrastructure
- **Containers**: Docker, Docker Compose
- **CI/CD**: GitHub Actions
- **Cloud**: Vercel, Railway, AWS

## Workflow Pattern

```
User Request
    │
    ▼
┌─────────────────┐
│  /skill-router  │ ◄── MANDATORY: Route to fullstack skills
└────────┬────────┘
         │
         ▼
┌─────────────────────┐
│ /task-decomposition │ ◄── Break into frontend/backend tasks
└────────┬────────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌────────┐ ┌────────┐
│Frontend│ │Backend │  ◄── Can be parallel
│ Skills │ │ Skills │
└───┬────┘ └───┬────┘
    │          │
    └────┬─────┘
         ▼
┌──────────────────────────┐
│  /fullstack-integration  │ ◄── Connect frontend and backend
└────────┬─────────────────┘
         │
         ▼
┌─────────────────────┐
│   /test-challenge   │ ◄── E2E testing
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

## Parallel Development Pattern

For fullstack features, decompose into parallel tracks:

```
Feature Request
    │
    ├── Frontend Track (branch: feature/ui-component)
    │   ├── Component design
    │   ├── State management
    │   └── Mock API integration
    │
    ├── Backend Track (branch: feature/api-endpoint)
    │   ├── Database schema
    │   ├── API endpoints
    │   └── Business logic
    │
    └── Integration Track (branch: feature/integration)
        ├── Connect real API
        ├── E2E tests
        └── Merge to main
```

## Project Structure

### Monorepo (Recommended)
```
project/
├── apps/
│   ├── web/                 # Next.js frontend
│   │   ├── app/
│   │   ├── components/
│   │   └── lib/
│   └── api/                 # Backend API
│       ├── src/
│       │   ├── routes/
│       │   ├── services/
│       │   └── models/
│       └── tests/
├── packages/
│   ├── shared/              # Shared types/utils
│   │   ├── types/
│   │   └── utils/
│   └── ui/                  # Shared UI components
├── docker-compose.yml
└── turbo.json
```

### Separate Repos
```
Frontend (Next.js):
├── app/
├── components/
├── hooks/
├── lib/
└── tests/

Backend (Express/FastAPI):
├── src/
│   ├── routes/
│   ├── controllers/
│   ├── services/
│   ├── models/
│   └── middleware/
└── tests/
```

## API Contract Pattern

### TypeScript Shared Types
```typescript
// packages/shared/types/api.ts
export interface User {
  id: string;
  email: string;
  name: string;
}

export interface CreateUserRequest {
  email: string;
  password: string;
  name: string;
}

export interface ApiResponse<T> {
  data: T;
  meta?: {
    page?: number;
    total?: number;
  };
}

export interface ApiError {
  code: string;
  message: string;
  details?: unknown;
}
```

### API Client
```typescript
// apps/web/lib/api.ts
import { User, CreateUserRequest, ApiResponse } from '@project/shared';

class ApiClient {
  private baseUrl: string;

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl;
  }

  async getUsers(): Promise<ApiResponse<User[]>> {
    const res = await fetch(`${this.baseUrl}/users`);
    if (!res.ok) throw new ApiError(await res.json());
    return res.json();
  }

  async createUser(data: CreateUserRequest): Promise<ApiResponse<User>> {
    const res = await fetch(`${this.baseUrl}/users`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    if (!res.ok) throw new ApiError(await res.json());
    return res.json();
  }
}
```

## Code Standards

### Frontend
- TypeScript strict mode
- Functional components
- Custom hooks for logic
- Server Components where possible

### Backend
- Input validation on all endpoints
- Proper error handling
- Authentication middleware
- Consistent response format

### Integration
- Type-safe API contracts
- Environment-based configuration
- CORS properly configured
- Error handling end-to-end

## MCP Configuration for Fullstack

Recommended MCPs for fullstack development:
- `github` - Repository management
- `postgres` - Database queries
- `filesystem` - Project file access
- `browser` - E2E testing

## Branching Strategy

```
main
  │
  ├── feature/frontend-component
  ├── feature/backend-endpoint
  ├── feature/fullstack-feature
  ├── bugfix/issue-description
  └── release/v1.0.0
```

## Remember

1. **Never skip the skill router** - it's the gateway to efficient context
2. **Decompose before implementing** - split frontend/backend tasks
3. **Type safety end-to-end** - shared types between front and back
4. **Test at all levels** - unit, integration, E2E
5. **Challenge results** - better products through critique
6. **API contract first** - design API before implementation
