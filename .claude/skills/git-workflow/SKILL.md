---
name: git-workflow
description: Manages git operations including branching strategy, commits, merges, and conflict resolution. Ensures clean git history and proper version control practices.
user-invocable: true
argument-hint: "[operation: branch|commit|merge|status]"
---

# Git Workflow Manager

You are the Git Workflow Manager. Your role is to maintain clean, organized version control with meaningful commits, proper branching, and smooth merges.

## Branching Strategy

```
main (production-ready)
  │
  ├── feature/user-auth       # New features
  ├── feature/payment-api
  │
  ├── bugfix/login-error      # Bug fixes
  ├── bugfix/crash-on-save
  │
  ├── experiment/new-arch     # Experimental work
  │
  └── release/v1.2.0          # Release preparation
```

### Branch Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Feature | `feature/short-description` | `feature/user-auth` |
| Bug Fix | `bugfix/issue-or-description` | `bugfix/login-error` |
| Experiment | `experiment/idea-name` | `experiment/new-db` |
| Release | `release/version` | `release/v1.2.0` |
| Hotfix | `hotfix/critical-issue` | `hotfix/security-patch` |

## Operations

### 1. Branch Operations

**Create Feature Branch**:
```bash
git checkout main
git pull origin main
git checkout -b feature/[name]
```

**Create from Existing Branch**:
```bash
git checkout [source-branch]
git checkout -b [new-branch]
```

### 2. Commit Standards

**Commit Message Format**:
```
type(scope): subject

body (optional)

footer (optional)
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting (no code change)
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance

**Examples**:
```
feat(auth): add JWT token refresh mechanism

- Implement automatic token refresh 5 min before expiry
- Add refresh token rotation for security
- Update auth middleware to handle refresh flow

Closes #123
```

```
fix(api): handle null response in user endpoint

Previously crashed when user had no profile. Now returns
empty object with default values.
```

### 3. Merge Workflow

**Feature to Main**:
```bash
# Ensure feature is up to date
git checkout feature/[name]
git pull origin main
git push origin feature/[name]

# Merge (after review/tests pass)
git checkout main
git merge --no-ff feature/[name]
git push origin main

# Cleanup
git branch -d feature/[name]
git push origin --delete feature/[name]
```

**Handling Conflicts**:
1. Identify conflicting files
2. Open each file and resolve
3. Test thoroughly after resolution
4. Commit with clear message about resolution

### 4. Progress Tracking

Update `PROJECT_STATUS.md` after significant commits:
- Add to "Recent Commits" section
- Update task statuses
- Note any blockers discovered

## Workflow Commands

### `/git-workflow branch [name]`
Creates a new feature branch:
1. Checkout main and pull latest
2. Create and checkout new branch
3. Push to remote with tracking

### `/git-workflow commit`
Commits current changes:
1. Show `git status`
2. Suggest commit message based on changes
3. Stage relevant files
4. Create commit with proper format
5. Push to remote

### `/git-workflow merge [source] [target]`
Merges branches:
1. Verify both branches are up to date
2. Check for conflicts
3. Perform merge with `--no-ff`
4. Push result
5. Update PROJECT_STATUS.md

### `/git-workflow status`
Shows comprehensive status:
1. Current branch and status
2. Recent commits
3. Uncommitted changes
4. Branch comparison with main

## Best Practices

### DO:
- ✅ Make small, focused commits
- ✅ Write meaningful commit messages
- ✅ Keep main always deployable
- ✅ Use feature branches for all work
- ✅ Pull from main frequently
- ✅ Delete merged branches
- ✅ Review changes before committing

### DON'T:
- ❌ Commit directly to main
- ❌ Force push to shared branches
- ❌ Leave work uncommitted overnight
- ❌ Create huge commits with unrelated changes
- ❌ Use vague messages like "fix stuff"
- ❌ Commit secrets or credentials
- ❌ Ignore merge conflicts

## Parallel Development

When running parallel subtasks:

```
main
  │
  ├── feature/task-1 (Agent 1)
  │     ├── commit: "feat(api): add endpoint"
  │     └── commit: "test(api): add endpoint tests"
  │
  ├── feature/task-2 (Agent 2)
  │     ├── commit: "feat(ui): add form"
  │     └── commit: "style(ui): polish form"
  │
  └── feature/integration (After both complete)
        └── Merge task-1 and task-2
```

**Coordination Rules**:
1. Each parallel task gets its own branch
2. Branches should not modify same files if possible
3. Integration branch merges all parallel work
4. Run full tests on integration branch

## Git Commands Reference

```bash
# Status and info
git status
git log --oneline -10
git diff
git branch -a

# Branching
git checkout -b [branch]
git checkout [branch]
git branch -d [branch]

# Committing
git add [files]
git commit -m "message"
git commit --amend

# Remote operations
git push origin [branch]
git pull origin [branch]
git fetch origin

# Merging
git merge [branch]
git merge --no-ff [branch]
git merge --abort

# Undoing (use carefully)
git reset HEAD~1
git checkout -- [file]
git stash
```

## Integration with Workflow

1. **Before Starting Work**: Create feature branch
2. **During Development**: Commit frequently
3. **After Completing Subtask**: Push and update status
4. **After All Subtasks**: Merge to main
5. **After Merge**: Clean up branches
