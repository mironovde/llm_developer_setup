# LLM Developer Setup - Backend Developer Specialization

## Specialization: Backend Development (Node.js, Python, Go, Databases)

This configuration is optimized for backend development including API design, database management, security, and deployment.

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
- Every endpoint must be tested
- Security review for all changes
- API documentation maintained
- Product usability is paramount (API DX)

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

### Backend-Specific Skills
| Skill | Command | Purpose |
|-------|---------|---------|
| API Design | `/api-design` | REST/GraphQL API patterns |
| Database Design | `/db-design` | Schema design, queries, migrations |
| Security | `/security` | Authentication, authorization, OWASP |
| Backend Testing | `/backend-testing` | Unit, integration, load testing |
| Deployment | `/deployment` | Docker, CI/CD, infrastructure |

## Technology Stack

### Languages
- **Node.js**: Express, Fastify, NestJS
- **Python**: FastAPI, Django, Flask
- **Go**: Gin, Echo, Fiber
- **TypeScript**: Full type safety

### Databases
- **SQL**: PostgreSQL, MySQL, SQLite
- **NoSQL**: MongoDB, Redis, DynamoDB
- **ORM/ODM**: Prisma, TypeORM, Drizzle, SQLAlchemy

### Infrastructure
- **Containers**: Docker, Docker Compose
- **Orchestration**: Kubernetes, ECS
- **Cloud**: AWS, GCP, Azure
- **Serverless**: Lambda, Cloud Functions

### Tools
- **API Docs**: OpenAPI/Swagger
- **Testing**: Jest, pytest, Go testing
- **CI/CD**: GitHub Actions, GitLab CI
- **Monitoring**: Prometheus, Grafana, DataDog

## Workflow Pattern

```
User Request
    │
    ▼
┌─────────────────┐
│  /skill-router  │ ◄── MANDATORY: Route to backend skills
└────────┬────────┘
         │
         ▼
┌─────────────────────┐
│ /task-decomposition │ ◄── Break into atomic subtasks
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│   /api-design       │ ◄── Design endpoints and contracts
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│   /db-design        │ ◄── Schema and data modeling
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│   /security         │ ◄── Security review
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│   /backend-testing  │ ◄── Test implementation
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│   /deployment       │ ◄── Deploy and monitor
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

### API Design
- RESTful conventions
- Consistent error responses
- Pagination for lists
- Versioning strategy

### Database
- Normalize appropriately
- Index strategically
- Use migrations
- Connection pooling

### Security
- Input validation
- SQL injection prevention
- Authentication required
- Secrets in environment

## Project Structure

### Node.js/TypeScript
```
src/
├── api/
│   ├── routes/
│   ├── controllers/
│   └── middleware/
├── services/
├── repositories/
├── models/
├── utils/
├── config/
└── __tests__/
```

### Python
```
app/
├── api/
│   ├── routes/
│   └── dependencies/
├── services/
├── repositories/
├── models/
├── schemas/
├── core/
└── tests/
```

## API Design Principles

### REST
- Use nouns for resources
- HTTP methods for actions
- Status codes properly
- HATEOAS when needed

### Error Handling
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input",
    "details": [
      { "field": "email", "message": "Invalid format" }
    ]
  }
}
```

### Response Formats
```json
{
  "data": { ... },
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 100
  }
}
```

## MCP Configuration for Backend

Recommended MCPs for backend development:
- `github` - Repository management
- `postgres` - Database queries
- `filesystem` - Project file access
- `docker` - Container management

## Branching Strategy

```
main
  │
  ├── feature/api-endpoint-name
  ├── feature/service-name
  ├── bugfix/issue-description
  ├── migration/schema-change
  └── release/v1.0.0
```

## Remember

1. **Never skip the skill router** - it's the gateway to efficient context
2. **Decompose before implementing** - atomic tasks succeed
3. **Security is not optional** - review every change
4. **Test all endpoints** - unit + integration + load
5. **Challenge results** - better products through critique
6. **Document APIs** - developer experience matters
