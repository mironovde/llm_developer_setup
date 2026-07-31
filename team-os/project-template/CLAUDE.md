# <Project> — Team OS project

> Initialized: <date> · Stack: <filled at init>

## Init protocol (first session in this repo)

Run once, then delete this section:

1. **Detect stack** from lockfiles/configs:
   - `pnpm-lock.yaml` / `yarn.lock` / `package-lock.json` → JS runner (pnpm/yarn/npm)
   - `pyproject.toml` / `requirements.txt` → Python
   - `*.xcodeproj` / `Package.swift` → iOS
2. Fill the **Stack** line in the header above.
3. Fill constraints in `team/PRODUCT.md`.
4. Pick real dev/test/build/lint commands into the table below.
5. Remove this **Init protocol** section.

## Dev commands

| Command | What it does |
|---------|--------------|
| `<dev>` | Run the app locally |
| `<test>` | Run the test suite |
| `<build>` | Production build |
| `<lint>` | Lint / format check |

## Key paths

- `src/` — application code
- `tests/` — test suite
- `team/` — team state (sprint, journal, backlog, decisions, specs, artifacts)

## Project conventions

- <naming, module layout, error handling — filled at init>
- <API/style conventions specific to this repo>
- <anything that would surprise a new engineer>

---

Team state lives in `team/` — SPRINT.md + last 5 JOURNAL lines are the resume point. MCP snippets for optional servers: `.claude/mcp-snippets/`.
