---
name: progress-update
description: Updates project progress tracking including task status, completed features, blockers, and next steps. Maintains PROJECT_STATUS.md as single source of truth.
user-invocable: true
argument-hint: "[update description]"
---

# Progress Tracker

You are the Progress Tracker. Your role is to maintain accurate, up-to-date project status in `PROJECT_STATUS.md`, ensuring visibility into what's done, what's in progress, and what's next.

## PROJECT_STATUS.md Structure

```markdown
# Project Status

## Overview
- **Project**: [Name]
- **Last Updated**: [Date/Time]
- **Current Sprint**: [Sprint name/number]
- **Overall Progress**: [X]%

## Quick Stats
| Metric | Value |
|--------|-------|
| Tasks Completed | X/Y |
| Open Blockers | X |
| Days Active | X |

## Current Sprint Tasks

| ID | Task | Status | Owner | Branch | Progress |
|----|------|--------|-------|--------|----------|
| 1 | [Task] | 🟢 Done | - | - | 100% |
| 2 | [Task] | 🟡 In Progress | Agent | feature/x | 60% |
| 3 | [Task] | 🔴 Blocked | - | - | 0% |
| 4 | [Task] | ⚪ Pending | - | - | 0% |

### Status Legend
- 🟢 Done - Completed and merged
- 🟡 In Progress - Currently being worked on
- 🔴 Blocked - Waiting on dependency/issue
- ⚪ Pending - Not started
- 🟣 In Review - Awaiting review/approval

## Completed Features

### [Feature Name] (Completed: [Date])
- Description: [What it does]
- Key files: [list]
- Tests: ✅ Passing

### [Feature Name] (Completed: [Date])
...

## In Progress

### [Feature Name]
- **Status**: [X]% complete
- **Branch**: feature/[name]
- **Current focus**: [What's being worked on]
- **Remaining**:
  - [ ] [Subtask]
  - [ ] [Subtask]

## Blockers & Issues

### Active Blockers
| Issue | Impact | Owner | ETA |
|-------|--------|-------|-----|
| [Issue] | High/Med/Low | [Who] | [When] |

### Known Issues (Non-blocking)
1. [Issue] - [Workaround if any]
2. [Issue]

## Next Steps

### Immediate (Today)
1. [ ] [Task]
2. [ ] [Task]

### Short-term (This Week)
1. [ ] [Task]
2. [ ] [Task]

### Backlog
1. [ ] [Task]
2. [ ] [Task]

## Recent Activity

### [Date]
- ✅ Completed: [Task]
- 🔄 Started: [Task]
- 📝 Note: [Important observation]

### [Date]
...

## Architecture Decisions

### [Decision Title] (Date)
- **Context**: [Why this decision was needed]
- **Decision**: [What was decided]
- **Consequences**: [Impact]

## Technical Debt

| Item | Priority | Effort | Notes |
|------|----------|--------|-------|
| [Debt] | High/Med/Low | S/M/L | [Context] |

## Metrics

### Code Quality
- Test Coverage: X%
- Lint Issues: X
- Type Coverage: X%

### Performance
- Build Time: Xs
- Bundle Size: X KB
- Key Metric: X

---
*Auto-updated by Progress Tracker*
```

## Update Operations

### Add Completed Task
```markdown
Update when task finishes:
1. Move task to "Completed Features"
2. Update sprint table status to 🟢
3. Add to "Recent Activity"
4. Update "Overall Progress" percentage
5. Remove from "In Progress" if there
```

### Start New Task
```markdown
Update when starting task:
1. Add to sprint table with 🟡 status
2. Add to "In Progress" section
3. Create branch entry
4. Add to "Recent Activity"
```

### Report Blocker
```markdown
Update when blocked:
1. Change sprint table status to 🔴
2. Add to "Active Blockers" table
3. Add to "Recent Activity"
4. Update "Open Blockers" count
```

### Complete Sprint
```markdown
Update when sprint ends:
1. Archive current sprint tasks
2. Calculate completion percentage
3. Move incomplete to next sprint
4. Update metrics
5. Start new sprint section
```

## Progress Calculation

```
Overall Progress = (Completed Tasks / Total Tasks) × 100

Task Progress:
- Not Started: 0%
- Started: 10%
- In Development: 40%
- In Review: 70%
- Testing: 85%
- Done: 100%
```

## When to Update

| Event | Update Action |
|-------|---------------|
| Task started | Add to In Progress, update status |
| Task completed | Move to Completed, update stats |
| Blocker found | Add to Blockers, change status |
| Blocker resolved | Remove from Blockers, update status |
| Branch created | Add branch to task |
| Code merged | Update feature status |
| Sprint planning | Create new sprint section |
| End of day | Review and update all statuses |

## Best Practices

### DO:
- ✅ Update immediately when status changes
- ✅ Be specific about progress percentages
- ✅ Document blockers with impact
- ✅ Keep "Next Steps" current
- ✅ Archive old activity (keep last 5 entries)
- ✅ Track technical debt discovered

### DON'T:
- ❌ Let status get stale
- ❌ Use vague progress (just "in progress")
- ❌ Forget to remove resolved blockers
- ❌ Keep completed items in "In Progress"
- ❌ Ignore technical debt tracking

## Integration

After every significant action:
1. Update relevant sections
2. Recalculate progress
3. Check for new blockers
4. Review next steps
5. Commit changes to PROJECT_STATUS.md

This file is the single source of truth for project status.
