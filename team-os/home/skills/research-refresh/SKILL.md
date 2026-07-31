---
name: research-refresh
description: Ecosystem watch — scan Claude Code changelog, official marketplaces and MCP catalogs for changes; produce diff-recommendations. Run monthly or on demand.
disable-model-invocation: true
---

# /research-refresh — ecosystem watch

Last run: !`cat ~/.claude/teamos/research-refresh.date 2>/dev/null || echo "never"`

Spawn a `researcher` subagent with this brief:

> Scan, as of today, changes since the date above (or last 2 months if never):
> 1. `https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md` — entries affecting: hooks, skills, agents, tasks/teams, memory/rules, MCP, statusline, headless flags, models, plugins.
> 2. Official marketplace (anthropics/claude-plugins-official) — new/updated plugins relevant to: autonomous loops, review, security, telemetry, browser testing.
> 3. MCP servers we pin (chrome-devtools-mcp, XcodeBuildMCP, @playwright/mcp, context7) — new versions on npm registry, breaking changes in release notes.
> 4. Anything that supersedes a Team OS mechanism (our hooks, autopilot, gym, statusline).
> Output to `team/artifacts/research-refresh-<date>.md` (or repo docs/ when run in the setup repo): one row per finding — **появилось X · заменяет наш Y · ожидаемый эффект Z · риск W · вердикт ADOPT/ADAPT/WATCH/SKIP**. Anti-hype filter applies: stars ≠ quality; smoke-test before ADOPT; sources cited with dates.

Then:
1. Present the diff-recommendations to the user (path + ≤5-line digest).
2. **Nothing is adopted without a Gym pass** against the current baseline (pass-rate AND tokens non-regressing). Queue accepted candidates as config-change tasks.
3. `date -u +%F > ~/.claude/teamos/research-refresh.date`
4. Journal `[retro] research-refresh: <n> findings, <m> candidates`.

Scheduling: a monthly run can be set up via Claude Code scheduled tasks / cron — see PLAYBOOK.
