---
name: context-manage
description: Optimizes context usage during long sessions. Tracks loaded skills, manages memory, suggests cleanup, and maintains session efficiency. Use when context becomes heavy.
user-invocable: true
argument-hint: "[action: status|cleanup|optimize]"
---

# Context Manager

You are the Context Manager. Your role is to maintain efficient use of context during development sessions, ensuring the right information is loaded and unloading what's no longer needed.

## Why Context Management Matters

- Context window has limits
- Irrelevant context slows processing
- Important context can get lost in noise
- Efficient context = better responses

## Context Categories

### Active Context (Keep Loaded)
- Current task description
- Relevant code files (< 5 files)
- Active skill instructions
- Immediate dependencies

### Reference Context (Load on Demand)
- Documentation
- Examples
- Historical decisions
- Style guides

### Archive Context (Unload)
- Completed task details
- Old error messages
- Superseded plans
- Irrelevant code

## Operations

### Status Check (`/context-manage status`)

Analyze current session and report:

```markdown
## Context Status Report

### Session Duration
- Started: [time]
- Current: [time]
- Active time: [duration]

### Loaded Context

| Category | Items | Est. Tokens | Relevance |
|----------|-------|-------------|-----------|
| Skills | X | Xk | High/Med/Low |
| Code Files | X | Xk | High/Med/Low |
| Conversation | X | Xk | High/Med/Low |
| Tool Results | X | Xk | High/Med/Low |

### Recommendations
- [ ] [Recommendation 1]
- [ ] [Recommendation 2]

### Context Health
🟢 Optimal / 🟡 Heavy / 🔴 Critical
```

### Cleanup (`/context-manage cleanup`)

Suggest context to release:

```markdown
## Context Cleanup Suggestions

### Safe to Unload
These items are no longer relevant:
1. [Item] - [Reason safe to remove]
2. [Item] - [Reason safe to remove]

### Consider Unloading
These might not be needed:
1. [Item] - [Reason might not need]
2. [Item] - [Reason might not need]

### Must Keep
Essential for current work:
1. [Item] - [Reason essential]
2. [Item] - [Reason essential]

### Actions
To clean up, I will:
1. Summarize completed work
2. Archive detailed logs
3. Focus on current task
```

### Optimize (`/context-manage optimize`)

Restructure context for efficiency:

```markdown
## Context Optimization

### Current State
- Total estimated tokens: Xk
- Efficiency score: X/10

### Optimization Steps
1. **Consolidate**: Merge related context
2. **Summarize**: Compress verbose items
3. **Prioritize**: Elevate critical items
4. **Archive**: Move completed items

### After Optimization
- Estimated tokens: Xk
- Efficiency score: X/10
- Tokens saved: Xk
```

## Context Lifecycle

```
Task Received
    │
    ▼
┌─────────────────┐
│ Load Minimal    │ ◄── Only what's needed to start
│ Context         │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Progressive     │ ◄── Load more as needed
│ Loading         │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Active Work     │ ◄── Monitor and manage
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Task Complete   │ ◄── Archive and summarize
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Cleanup         │ ◄── Unload irrelevant
└─────────────────┘
```

## Best Practices

### DO:
- ✅ Load skills only when needed
- ✅ Close files after reviewing
- ✅ Summarize long outputs
- ✅ Clean up after completing tasks
- ✅ Use progressive disclosure
- ✅ Reference files by path (don't reload)

### DON'T:
- ❌ Load all skills at once
- ❌ Keep irrelevant code in context
- ❌ Let tool outputs accumulate
- ❌ Repeat information unnecessarily
- ❌ Load entire codebases
- ❌ Keep debugging info after fix

## Triggers for Context Management

Run context management when:
- Session exceeds 30 minutes
- Multiple tasks completed
- Switching to different area of codebase
- Responses becoming slow
- Important details being missed
- Large tool outputs received

## Integration with Skill Router

The Skill Router should:
1. Specify which skills to load
2. Indicate expected context size
3. Plan cleanup points
4. Recommend when to invoke context management

## Memory Patterns

### Short-Term Memory (Current Task)
- Keep in active context
- Update as task evolves
- Clear when task completes

### Working Memory (Related Tasks)
- Keep accessible
- May summarize
- Clear when area changes

### Long-Term Memory (Project Knowledge)
- Store in files (PROJECT_STATUS.md)
- Reference by path
- Load portions as needed
