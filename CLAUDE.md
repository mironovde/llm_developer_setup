# LLM Developer Setup - Base Configuration

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
- Every feature must be tested
- Code must be challenged before merge
- Product usability is paramount
- Technical debt must be documented

## Available Core Skills

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

## Workflow Pattern

```
User Request
    │
    ▼
┌─────────────────┐
│  /skill-router  │ ◄── MANDATORY: Identify relevant skills & MCPs
└────────┬────────┘
         │
         ▼
┌─────────────────────┐
│ /task-decomposition │ ◄── Break into atomic subtasks
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│   Load Skills &     │ ◄── Only load what's needed
│   Configure MCPs    │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│   Execute Tasks     │ ◄── Parallel when possible
│   (with subagents)  │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│   /test-challenge   │ ◄── Test and challenge results
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

## Branching Strategy

```
main
  │
  ├── feature/task-name      # Individual features
  ├── experiment/idea-name   # Experimental work
  ├── bugfix/issue-name      # Bug fixes
  └── release/version        # Release preparation
```

## Project Status Location

All project progress is tracked in `PROJECT_STATUS.md`:
- Current sprint tasks with statuses
- Completed features
- Known issues and blockers
- Next steps

## MCP Configuration

MCPs are configured in `.mcp.json`. The skill router will:
1. Analyze task requirements
2. Check currently configured MCPs
3. Recommend additional MCPs if needed
4. Provide installation commands

## Subagent Usage

For parallel task execution:
- Use Task tool with appropriate subagent_type
- Launch independent tasks in parallel
- Coordinate dependent tasks sequentially
- Always challenge results before merge

## Remember

1. **Never skip the skill router** - it's the gateway to efficient context
2. **Decompose before implementing** - atomic tasks succeed
3. **Test everything** - quality over speed
4. **Update progress** - visibility matters
5. **Challenge results** - better products through critique
