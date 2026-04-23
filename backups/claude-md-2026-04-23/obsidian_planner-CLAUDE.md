<!-- GSD:project-start source:PROJECT.md -->
## Project

**Obsidian Planner**

Плагин для Obsidian, который с помощью LLM автоматически анализирует заметки, планирует день, расставляет приоритеты и дедлайны, и двусторонне синхронизируется с Apple Calendar и Apple Reminders. Для личного использования на macOS.

**Core Value:** LLM-driven планирование дня: плагин собирает задачи, напоминания и контекст из заметок, и создаёт осмысленный план дня с приоритетами и временными слотами.

### Constraints

- **Platform**: macOS only — JXA/osascript для Apple Calendar/Reminders
- **Runtime**: Obsidian Plugin API (Node.js + Electron)
- **LLM Cost**: Обращения должны быть экономичными — batch-анализ, а не per-keystroke
- **Privacy**: API ключи хранятся локально, заметки не отправляются без явного действия
- **Models**: Только актуальные модели OpenAI. GPT-4o, GPT-4, GPT-3.5 — НЕ использовать
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

## Recommended Stack
### Core Technologies
| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| TypeScript | ^5.8.3 | Primary language | Official Obsidian plugin language. Type safety critical for plugin API, LLM response schemas, and Calendar data models. Matches obsidian-sample-plugin template. |
| Obsidian Plugin API (`obsidian`) | 1.12.3 | Plugin framework | The only way to build Obsidian plugins. Provides Plugin, ItemView, SettingTab, Modal, Notice, requestUrl, and all vault/file APIs. Marked as external in esbuild -- Obsidian provides at runtime. |
| esbuild | 0.25.5 | Bundler | Official Obsidian template uses esbuild. Sub-second builds, watch mode for dev, tree-shaking, handles ESM-to-CJS conversion for output. No webpack/rollup complexity needed. |
| Node.js child_process | built-in | JXA/osascript bridge | Executes `osascript -l JavaScript` to interact with Apple Calendar and Reminders via JXA. Available in Obsidian desktop (Electron). No native addon compilation needed. |
| React | ^19.0.0 | UI views (Calendar, Reminders) | Official Obsidian docs support React in ItemView via createRoot. Calendar view and Reminders view require rich interactive UI that plain DOM manipulation makes painful. Obsidian Copilot (most popular AI plugin) uses React. |
| react-dom | ^19.0.0 | React DOM rendering | Required companion for React. Use createRoot in ItemView.onOpen(), root.unmount() in onClose(). |
### LLM Integration
| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Direct fetch API | built-in | OpenAI & OpenRouter HTTP calls | **Use direct fetch, NOT the openai SDK or @openrouter/sdk.** Rationale: (1) Both APIs are OpenAI-compatible REST -- same endpoint shape, same SSE streaming format. (2) The `openai` npm package (v6.33.0) adds ~2MB to bundle and has complex ESM-only dependencies. (3) `@openrouter/sdk` (v0.10.2) is ESM-only beta with breaking changes between versions. (4) Obsidian's Electron runtime provides full `fetch` with streaming support. (5) Existing successful Obsidian LLM plugins (ChatGPT-MD) use direct fetch. A thin ~200-line wrapper gives us full control with zero dependency risk. |
| Zod | ^4.3.6 | LLM response validation | Validate and type-infer LLM JSON responses (day plans, task analysis, priorities). Prevents runtime crashes from malformed AI output. Small bundle footprint with tree-shaking. |
### Apple Integration
| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| JXA via osascript | macOS built-in | Calendar & Reminders CRUD | The proven approach for macOS automation from Node.js/Electron. No compilation, no native addons, no Info.plist hacks. Runs JXA scripts via `child_process.execFile('osascript', ['-l', 'JavaScript', '-e', script])`. Full CRUD for both Calendar.app and Reminders.app. |
| moment.js | Obsidian built-in | Date/time handling | Obsidian bundles moment.js at runtime. Import via `import { moment } from 'obsidian'`. Use for date formatting, time slot calculations, and calendar event scheduling. Do NOT install separately. |
### Supporting Libraries
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Zod | ^4.3.6 | Schema validation | Validate ALL LLM responses before use. Parse frontmatter schemas. Validate settings. |
| obsidian-daily-notes-interface | ^0.9.4 | Daily notes API | Access daily notes paths/settings consistently. Respects user's daily notes config (folder, format, template). |
| gray-matter | ^4.0.3 | YAML frontmatter parsing | Parse/modify frontmatter in markdown files for priority (!!!/!!/!) and metadata. More robust than regex for frontmatter manipulation. |
### Development Tools
| Tool | Purpose | Notes |
|------|---------|-------|
| esbuild | Bundle + watch | `node esbuild.config.mjs` for dev (watch mode), `tsc -noEmit && node esbuild.config.mjs production` for build |
| TypeScript | Type checking | `tsc -noEmit -skipLibCheck` -- type-check only, esbuild handles compilation |
| ESLint + typescript-eslint | Linting | Use eslint-plugin-obsidianmd (v0.1.9) for Obsidian-specific rules |
| Hot-reload plugin | Dev workflow | Install "Hot Reload" community plugin in dev vault. Watches for main.js changes and auto-reloads plugin. |
## Installation
# Core dependencies (bundled into main.js)
# Types
# Build tooling (from official template)
# Linting
# Optional: daily notes integration
## esbuild Configuration
## tsconfig.json
## Alternatives Considered
| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Direct fetch + thin wrapper | `openai` SDK v6 | If you need function calling, tool use orchestration, or Assistants API -- the SDK handles these complex flows better. Our use case (chat completions + streaming) is too simple to justify the dependency. |
| Direct fetch + thin wrapper | `@openrouter/sdk` | If OpenRouter adds features not available via their OpenAI-compatible endpoint (e.g., provider routing controls). Currently their REST API covers everything we need. |
| Direct fetch + thin wrapper | LangChain.js | If supporting 10+ LLM providers, RAG pipelines, agent chains. For 2 providers with identical API shape, LangChain is massive overkill. |
| JXA via osascript | eventkit-node | If you need high-performance bulk operations (1000+ events). JXA has ~50ms overhead per osascript call, but for typical daily planning (<100 events) it's imperceptible. |
| JXA via osascript | AppleScript (osascript without -l JavaScript) | Never. JXA is JavaScript -- same language as the plugin. AppleScript is a separate language with different syntax and worse error messages. |
| React 19 | Svelte / Preact | If bundle size is critical constraint. React adds ~40KB gzipped but gives us ecosystem, hooks, devtools, and community examples. Most Obsidian plugins with complex UI use React. |
| React 19 | Plain DOM / vanilla JS | If only building simple settings UI. Our Calendar view and Reminders view have interactive state, drag-drop potential, and complex rendering -- React is justified. |
| Zod 4 | io-ts / Yup / ArkType | Zod is the TypeScript ecosystem standard. Best DX, widest adoption, best tree-shaking. No reason to use alternatives. |
## What NOT to Use
| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `openai` npm package | ESM-only, 2MB+ bundle impact, complex dependency tree, bundling friction with Obsidian's CJS output format | Direct fetch wrapper (~200 lines, zero deps) |
| `@openrouter/sdk` | ESM-only beta, breaking changes without semver, unnecessary abstraction for OpenAI-compatible API | Direct fetch wrapper using same OpenAI-compatible endpoint |
| LangChain.js | 20+ packages, massive bundle, complex abstraction for a 2-provider use case | Direct fetch wrapper with simple provider config |
| eventkit-node | Native addon requires Xcode compilation, Electron N-API fragility, cannot distribute .node binaries via Obsidian plugin system, requires Info.plist modifications | JXA via child_process.execFile osascript |
| node-jxa | Abandoned since 2019, adds unnecessary dependency for what is a 3-line child_process call | Direct child_process.execFile('osascript', ['-l', 'JavaScript', '-e', script]) |
| Webpack / Rollup | Slower, more complex config, no advantage over esbuild for Obsidian plugins | esbuild (official template) |
| GPT-4o, GPT-4, GPT-3.5 models | Deprecated by OpenAI. Project requirements explicitly exclude these. | gpt-4.1, o3-mini, o4-mini via OpenAI API; or any model via OpenRouter |
| date-fns / dayjs | Obsidian already bundles moment.js. Adding another date library wastes bundle size and creates inconsistency. | `import { moment } from 'obsidian'` |
| Axios | Unnecessary in Electron environment where fetch is available natively with full streaming support | Native fetch API |
| requestUrl (Obsidian API) | Does not support streaming responses (returns full body at once). Useless for LLM token-by-token streaming. | Native fetch with response.body.getReader() for SSE streaming |
## Stack Patterns by Variant
- The direct fetch approach still works -- Anthropic and Google have different API shapes but the wrapper pattern scales. Add a new provider class per API shape.
- If reaching 5+ distinct API shapes, reconsider a lightweight abstraction. Still not LangChain -- consider Vercel AI SDK (`ai` package) which is lighter.
- No changes needed. The stack produces a single main.js file. No native addons, no binaries, no platform-specific files beyond JXA scripts (which run via osascript at runtime).
- JXA/osascript usage means the plugin is macOS-only. Document this clearly in manifest.json description and README.
- Consider FullCalendar React (`@fullcalendar/react`) for a proper calendar grid. ~80KB gzipped but provides day/week/month views, drag-drop, and event rendering out of the box.
- For MVP, a simple custom React component is sufficient.
## Version Compatibility
| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| obsidian@1.12.3 | TypeScript ^5.8.3 | Official template uses this combination |
| esbuild@0.25.5 | TypeScript ^5.8.3 | esbuild handles TS compilation; tsc is only for type-checking |
| React@19 | react-dom@19 | Must match major versions exactly |
| React@19 | esbuild jsx: 'automatic' | React 19 uses the new JSX transform (no import React needed) |
| Zod@4.3.6 | TypeScript ^5.5 | Zod 4 requires TS 5.5+ for full type inference |
| gray-matter@4.0.3 | Any | Stable, no special compatibility requirements |
| child_process | Obsidian Desktop (Electron) | NOT available on Obsidian Mobile. This plugin is macOS-only by design. |
| moment.js | Obsidian runtime | Do not install -- use `import { moment } from 'obsidian'` |
## Project Structure
## Sources
- [Obsidian Sample Plugin (official template)](https://github.com/obsidianmd/obsidian-sample-plugin) -- package.json, esbuild.config.mjs, tsconfig.json reference (HIGH confidence)
- [Obsidian API npm package](https://www.npmjs.com/package/obsidian) -- v1.12.3 verified (HIGH confidence)
- [Obsidian Developer Docs: Views](https://docs.obsidian.md/Plugins/User+interface/Views) -- ItemView pattern (HIGH confidence)
- [Obsidian Developer Docs: React](https://docs.obsidian.md/Plugins/Getting+started/Use+React+in+your+plugin) -- React in plugin pattern (HIGH confidence)
- [OpenAI Node.js SDK](https://github.com/openai/openai-node) -- v6.33.0, ESM-only, confirmed (HIGH confidence)
- [OpenRouter TypeScript SDK](https://github.com/OpenRouterTeam/typescript-sdk) -- v0.10.2, ESM-only beta (HIGH confidence)
- [OpenRouter API Docs: Streaming](https://openrouter.ai/docs/api/reference/streaming) -- SSE streaming format (HIGH confidence)
- [OpenAI API Docs: Streaming](https://developers.openai.com/api/docs/guides/streaming-responses) -- SSE streaming format (HIGH confidence)
- [JXA Examples](https://jxa-examples.akjems.com/) -- Calendar and Reminders JXA CRUD examples (MEDIUM confidence)
- [Apple Calendar Scripting Guide](https://developer.apple.com/library/archive/documentation/AppleApplications/Conceptual/CalendarScriptingGuide/index.html) -- Official Apple docs, archived but still accurate (MEDIUM confidence)
- [eventkit-node](https://github.com/dacay/eventkit-node) -- v1.0.5, native addon, evaluated and rejected (HIGH confidence)
- [Obsidian Copilot](https://github.com/logancyang/obsidian-copilot) -- LangChain architecture reference, evaluated (HIGH confidence)
- [ChatGPT-MD](https://github.com/bramses/chatgpt-md) -- Direct fetch LLM plugin reference (MEDIUM confidence)
- [Obsidian Forum: Streaming](https://forum.obsidian.md/t/support-streaming-the-request-and-requesturl-response-body/87381) -- requestUrl limitations confirmed (HIGH confidence)
- [Zod](https://www.npmjs.com/package/zod) -- v4.3.6 verified (HIGH confidence)
- [Obsidian Forum: child_process](https://forum.obsidian.md/t/when-i-use-child-process-in-nodejs-i-get-the-following-error-and-i-dont-know-why/56211) -- Desktop-only confirmed (HIGH confidence)
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd:quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd:debug` for investigation and bug fixing
- `/gsd:execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd:profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
