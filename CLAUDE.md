# LLM Developer Setup - Swift Developer Specialization

## Specialization: Swift Development (iOS, macOS, watchOS, tvOS, Vapor Backend)

This configuration is optimized for Swift ecosystem development including native Apple platform apps and server-side Swift with Vapor.

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
- Every feature must be tested (XCTest, Quick/Nimble)
- Code must follow Swift API Design Guidelines
- SwiftUI views must be previewed and tested
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

### Swift-Specific Skills
| Skill | Command | Purpose |
|-------|---------|---------|
| iOS Development | `/swift-ios` | iOS app development patterns |
| macOS Development | `/swift-macos` | macOS app development patterns |
| Vapor Backend | `/swift-vapor` | Server-side Swift with Vapor |
| SwiftUI Design | `/swift-ui-design` | SwiftUI design patterns and best practices |
| Swift Testing | `/swift-testing` | Swift testing strategies |

## Technology Stack

### Frontend (Native)
- **UI Framework**: SwiftUI (preferred), UIKit (when needed)
- **Architecture**: MVVM, TCA (The Composable Architecture)
- **State Management**: @Observable, @State, @Binding
- **Navigation**: NavigationStack, NavigationSplitView
- **Async**: Swift Concurrency (async/await, actors)

### Backend (Vapor)
- **Framework**: Vapor 4+
- **ORM**: Fluent
- **Authentication**: JWT, Sessions
- **Database**: PostgreSQL, SQLite
- **Deployment**: Docker, Railway, Heroku

### Testing
- **Unit**: XCTest, Quick/Nimble
- **UI**: XCUITest
- **Snapshot**: swift-snapshot-testing
- **Mocking**: Mockolo, Cuckoo

### Tools
- **Package Manager**: Swift Package Manager
- **Linting**: SwiftLint
- **Formatting**: swift-format
- **CI/CD**: Xcode Cloud, GitHub Actions

## Workflow Pattern

```
User Request
    │
    ▼
┌─────────────────┐
│  /skill-router  │ ◄── MANDATORY: Route to Swift-specific skills
└────────┬────────┘
         │
         ▼
┌─────────────────────┐
│ /task-decomposition │ ◄── Break into atomic subtasks
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│   Platform Check    │ ◄── iOS? macOS? Vapor? Multi-platform?
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│   Load Platform     │ ◄── /swift-ios, /swift-macos, /swift-vapor
│   Skills            │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│   Implement with    │ ◄── Follow Swift best practices
│   /swift-ui-design  │
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│   /swift-testing    │ ◄── Comprehensive testing
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│   /test-challenge   │ ◄── Challenge implementation
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

## Swift Code Standards

### Naming Conventions
- Types: `UpperCamelCase`
- Functions, variables: `lowerCamelCase`
- Boolean: `is`, `has`, `should` prefix
- Protocols: `-able`, `-ible`, `-ing` suffix for capabilities

### Architecture Patterns
- **MVVM** for simple apps
- **TCA** for complex state management
- **Clean Architecture** for large projects
- **Repository Pattern** for data access

### SwiftUI Best Practices
- Extract reusable views
- Use ViewModifiers for styling
- Leverage @Observable for state
- Test with PreviewProvider

### Vapor Best Practices
- Use dependency injection
- Implement middleware properly
- Handle errors with proper types
- Use migrations for schema changes

## MCP Configuration for Swift

Recommended MCPs for Swift development:
- `github` - Repository management
- `filesystem` - Project file access
- `xcode` - Xcode project manipulation (if available)

## Branching Strategy

```
main
  │
  ├── feature/ios-feature-name
  ├── feature/macos-feature-name
  ├── feature/vapor-api-name
  ├── bugfix/platform-issue
  └── release/v1.0.0
```

## Remember

1. **Never skip the skill router** - it's the gateway to efficient context
2. **Decompose before implementing** - atomic tasks succeed
3. **Follow Swift API Design Guidelines** - consistency matters
4. **Test on all target platforms** - don't assume cross-platform works
5. **Challenge results** - better products through critique
6. **Think SwiftUI-first** - but know when UIKit is better
