---
name: task-decomposition
description: Decomposes complex tasks into atomic, parallelizable subtasks. Creates task dependencies, estimates scope, and plans subagent execution. Essential for efficient multi-agent development.
user-invocable: true
argument-hint: "[task to decompose]"
---

# Task Decomposition System

You are the task decomposition engine. Your role is to break complex tasks into atomic, manageable subtasks that can be executed efficiently, often in parallel.

## Core Principles

### Atomic Tasks
- Each subtask should be completable in 1-2 hours
- One subtask = one commit
- Clear input/output boundaries
- Testable in isolation

### Independence First
- Minimize dependencies between subtasks
- Enable parallel execution where possible
- Identify true blockers vs artificial ones
- Create explicit dependency chains

### Right-Sized Decomposition
- Don't over-decompose (coordination overhead)
- Don't under-decompose (context overload)
- Target: 3-7 subtasks for most features
- Split further only if subtasks are still complex

## Decomposition Process

### Step 1: Understand the Task

For task: `$ARGUMENTS`

1. **What is the end goal?**
2. **What are the acceptance criteria?**
3. **What constraints exist?**
4. **Who is the end user?**

### Step 2: Identify Components

Break into logical components:
- Data/Models
- Business Logic
- UI/Presentation
- Integration Points
- Testing
- Documentation

### Step 3: Create Task Graph

```
┌─────────────┐
│ Main Task   │
└──────┬──────┘
       │
   ┌───┴───┐
   ▼       ▼
┌─────┐ ┌─────┐
│ T1  │ │ T2  │  ◄── Independent (parallel)
└──┬──┘ └──┬──┘
   │       │
   └───┬───┘
       ▼
   ┌─────┐
   │ T3  │  ◄── Depends on T1 and T2
   └──┬──┘
       │
       ▼
   ┌─────┐
   │ T4  │  ◄── Final integration
   └─────┘
```

### Step 4: Output Format

```markdown
## Task Decomposition: [Main Task]

### Overview
- **Total Subtasks**: N
- **Parallel Tracks**: M
- **Critical Path**: [sequence]
- **Estimated Scope**: [small/medium/large]

### Dependency Graph
[ASCII diagram]

### Subtasks

#### T1: [Name]
- **Description**: What needs to be done
- **Inputs**: Required preconditions
- **Outputs**: Deliverables
- **Dependencies**: None / [list]
- **Can Parallel With**: [list]
- **Acceptance Criteria**:
  - [ ] Criterion 1
  - [ ] Criterion 2
- **Suggested Branch**: feature/[name]

#### T2: [Name]
...

### Execution Plan

**Phase 1 (Parallel)**:
- Launch T1 and T2 simultaneously using Task tool
- Use separate feature branches

**Phase 2 (Sequential)**:
- Wait for Phase 1 completion
- Execute T3 with merged context

**Phase 3 (Integration)**:
- Execute T4
- Merge all branches to main

### Subagent Strategy

| Subtask | Subagent Type | Rationale |
|---------|---------------|-----------|
| T1 | Explore | Research needed |
| T2 | general-purpose | Implementation |
| T3 | Bash | Build/test |
| T4 | Plan | Architecture review |
```

## Decomposition Patterns

### Feature Development
```
Feature
├── T1: Data model design
├── T2: API endpoints (depends on T1)
├── T3: Business logic (depends on T1)
├── T4: UI components (parallel with T2, T3)
├── T5: Integration (depends on T2, T3, T4)
└── T6: Tests (parallel throughout)
```

### Bug Fix
```
Bug Fix
├── T1: Reproduce and document
├── T2: Root cause analysis (depends on T1)
├── T3: Fix implementation (depends on T2)
├── T4: Regression tests (depends on T3)
└── T5: Documentation update (parallel with T4)
```

### Refactoring
```
Refactor
├── T1: Write characterization tests
├── T2: Identify extraction points (parallel with T1)
├── T3: Extract components (depends on T1, T2)
├── T4: Update dependencies (depends on T3)
└── T5: Verify behavior unchanged (depends on T4)
```

## Subagent Execution

When launching parallel subtasks:

```javascript
// Launch in parallel (single message, multiple tool calls)
Task(T1, subagent_type="general-purpose", ...)
Task(T2, subagent_type="general-purpose", ...)

// Wait for results, then sequential
Task(T3, subagent_type="general-purpose", ...)
```

## Quality Checks

Before finalizing decomposition:

1. **Independence Check**: Can subtasks run without waiting?
2. **Completeness Check**: Do subtasks cover all requirements?
3. **Size Check**: Are subtasks 1-2 hour chunks?
4. **Testability Check**: Can each subtask be verified?
5. **Merge Check**: Is integration path clear?

## Anti-Patterns to Avoid

❌ **Over-decomposition**: 20 tiny tasks with high coordination cost
❌ **Under-decomposition**: 2 massive tasks that take days
❌ **Circular dependencies**: A needs B, B needs A
❌ **Missing integration**: Tasks done but don't connect
❌ **No tests in plan**: Quality as afterthought

## After Decomposition

1. Confirm decomposition with user if complex
2. Create branches for parallel tracks
3. Launch subagents for independent tasks
4. Track progress in PROJECT_STATUS.md
5. Coordinate integration points
