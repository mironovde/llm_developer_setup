---
name: skill-router
description: Routes tasks to appropriate skills and MCPs. MUST be invoked before any task execution. Analyzes requirements, identifies relevant skills, checks MCP availability, and optimizes context loading.
user-invocable: true
argument-hint: "[task description]"
---

# Skill Router

You are the central routing system for all development tasks. Your role is CRITICAL and you must be invoked before any implementation work begins.

## Your Responsibilities

1. **Analyze the Task**
   - Parse user request for requirements
   - Identify domain (frontend, backend, ML, mobile, etc.)
   - Determine complexity and scope
   - List required capabilities

2. **Route to Skills**
   - Match task requirements to available skills
   - Prioritize skills by relevance
   - Identify skill dependencies
   - Plan skill loading sequence

3. **Check MCPs**
   - Review `.mcp.json` for configured servers
   - Identify missing MCPs for the task
   - Provide installation commands for needed MCPs
   - Verify MCP connectivity

4. **Optimize Context**
   - Recommend minimal skill set
   - Identify what NOT to load
   - Plan context cleanup after task

## Routing Process

### Step 1: Task Analysis

For task: `$ARGUMENTS`

Answer these questions:
- What is the primary domain? (frontend/backend/mobile/ml/fullstack)
- What technologies are involved?
- What is the expected output?
- What quality standards apply?
- Is this a new feature, bug fix, or refactor?

### Step 2: Skill Mapping

Match to these skill categories:

**Development Skills** (load based on domain):
- Frontend: React, Vue, CSS, accessibility
- Backend: API design, database, security
- Mobile: Swift, iOS, macOS, watchOS
- ML: Model training, data processing, deployment
- Fullstack: Combination of above

**Universal Skills** (always consider):
- `/task-decomposition` - Break complex tasks
- `/git-workflow` - Version control
- `/test-challenge` - Quality assurance
- `/pm-challenge` - Product validation
- `/progress-update` - Status tracking

**Optional Skills** (load if needed):
- `/financial-review` - Cost/revenue analysis
- `/context-manage` - Long session management

### Step 3: MCP Verification

Check `.mcp.json` for these common MCPs by task type:

| Task Type | Recommended MCPs |
|-----------|------------------|
| GitHub work | github, git |
| Database | postgres, sqlite, supabase |
| Web research | brave-search, fetch |
| File operations | filesystem |
| Browser testing | puppeteer, playwright |
| API development | postman, swagger |
| Design | figma |
| Documentation | notion, confluence |

### Step 4: Output Routing Decision

Provide this structured output:

```markdown
## Routing Decision for: [Task Summary]

### Primary Domain
[Identified domain]

### Required Skills (Load These)
1. [Skill name] - [Reason]
2. [Skill name] - [Reason]
...

### Skills to Skip (Don't Load)
- [Skill name] - [Reason not needed]
...

### MCP Status
✅ Available: [list]
❌ Missing: [list with install commands]

### Recommended Workflow
1. [First step]
2. [Second step]
...

### Context Budget
- Estimated skills context: [size]
- Recommended cleanup after: [milestone]
```

## Example Routing

**Task**: "Create a REST API endpoint for user authentication"

```markdown
## Routing Decision for: User Auth API Endpoint

### Primary Domain
Backend Development

### Required Skills (Load These)
1. `/task-decomposition` - Complex feature needs breakdown
2. `/git-workflow` - Feature branch needed
3. `/test-challenge` - Security-critical, needs thorough testing
4. `/pm-challenge` - UX of auth flow matters

### Skills to Skip (Don't Load)
- Frontend skills - API only task
- ML skills - Not applicable
- `/financial-review` - No cost implications

### MCP Status
✅ Available: github, filesystem
❌ Missing:
  - postgres: `claude mcp add postgres npx @anthropic-ai/postgres-mcp`

### Recommended Workflow
1. Create feature/user-auth branch
2. Decompose into: schema, endpoints, validation, tests
3. Implement with TDD approach
4. Challenge security aspects
5. PM review auth flow UX
6. Merge after approval

### Context Budget
- Estimated skills context: ~2000 tokens
- Recommended cleanup after: feature merge
```

## MCP Installation Commands

Common MCP installations:

```bash
# GitHub
claude mcp add github -- npx -y @anthropic-ai/github-mcp

# PostgreSQL
claude mcp add postgres -- npx -y @anthropic-ai/postgres-mcp

# Filesystem
claude mcp add filesystem -- npx -y @anthropic-ai/filesystem-mcp

# Brave Search
claude mcp add brave-search -- npx -y @anthropic-ai/brave-search-mcp

# Puppeteer (browser automation)
claude mcp add puppeteer -- npx -y @anthropic-ai/puppeteer-mcp

# Fetch (HTTP requests)
claude mcp add fetch -- npx -y @anthropic-ai/fetch-mcp
```

## Critical Reminders

1. **Always run first** - No implementation without routing
2. **Be selective** - Load only necessary skills
3. **Check MCPs** - Missing tools cause failures
4. **Plan cleanup** - Context is precious
5. **Document decisions** - Transparency in routing

## After Routing

Once routing is complete, instruct the user to:
1. Install any missing MCPs
2. Invoke `/task-decomposition` with the task
3. Begin implementation following the workflow
