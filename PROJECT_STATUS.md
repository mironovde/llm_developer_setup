# Project Status

## Overview
- **Project**: LLM Developer Setup — versioned, portable configuration for Claude Code and Codex
- **Last verified**: 2026-08-16
- **Type**: active configuration repository

## Active branches

| Agent | Branch | Canonical directory |
| --- | --- | --- |
| Claude Code | `claude` | `team-os/home/` |
| Codex | `codex` | `codex/home/` |

`main` and `team-os` remain compatibility branches for the prior Claude-only setup.

## Current Claude configuration
- Global guidance, security reference, hooks, status line, and install tooling: `team-os/home/`.
- `team-os/home/settings.json` was synchronized from the live `~/.claude/settings.json` on 2026-08-16.
- Framework-managed GSD hooks are not duplicated; their installer remains the source of truth.

## Current Codex configuration
- Added on branch `codex`. It is intentionally native to Codex: global `AGENTS.md`,
  `config.toml`, plus a repository `AGENTS.md` template.
- Claude hooks, permissions syntax, and plugins are not copied into Codex because
  Codex uses its own sandbox, skills, plugins, MCP and config surfaces.

## Boundaries
- No secrets, authentication data, caches, session history, or local databases are versioned.
- Historical snapshots stay in `backups/` and are not active configuration.
