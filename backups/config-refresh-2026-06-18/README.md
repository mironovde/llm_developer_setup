# Config snapshot — 2026-06-18

Point-in-time backup of the live `~/.claude/` config and per-project `CLAUDE.md`
files, taken on 2026-06-18. Source of truth is the live config / each project's
own repo; this is a versioned backup only.

## What's captured

- `global-settings.json` — live `~/.claude/settings.json`
  (refreshed to `effortLevel: "xhigh"` + `fastMode: true`; previous snapshot
  `autonomous-enforcement-2026-05-31` had `effortLevel: "high"`).
- `projects/*-CLAUDE.md` — live `CLAUDE.md` of each real project under
  `~/development/`:
  crm_npf, delo_yasno, delo_yasno_2, interior-design, obsidian_planner,
  risk-platform, risk-platform-2.

## Not captured (intentionally)

- `risk-platform-2-{client360,jurisdictions,simulation}` — git worktrees of
  `risk-platform-2`; their `CLAUDE.md` is byte-identical to the parent.
- `llm_developer_setup/CLAUDE.md` — this repo's own root `CLAUDE.md`
  (already tracked at the repo root).
- Global `CLAUDE.md`, `SECURITY.md`, hooks, `scripts/claude-autonomous`,
  launchd plist — verified IN SYNC with snapshot
  `autonomous-enforcement-2026-05-31`; unchanged, so not duplicated here.
