# Project Status

## Overview
- **Project**: LLM Developer Setup — short, portable configuration for Claude Code and Codex
- **Last verified**: 2026-08-16
- **Type**: active configuration repository

## Active branches

| Agent | Branch | Canonical directory |
| --- | --- | --- |
| Claude Code | `claude` | `team-os/home/` |
| Codex | `codex` | `codex/home/` |

`main` and `team-os` remain compatibility branches for the former Claude-only setup.

## Active configuration
- The global policy is deliberately brief: outcome, scope, verification, user decisions, security, and communication.
- Each project file contains only its own context, commands, and exceptional constraints.
- Claude's current global files are `team-os/home/CLAUDE.md` and `team-os/home/settings.json`.
- Current Delo Yasno project rules are `team-os/projects/delo_yasno_2/CLAUDE.md`.
- Codex keeps its native equivalents on branch `codex`: `AGENTS.md` and `config.toml`.

## Boundaries
- No secrets, authentication data, caches, session history, or local databases are versioned.
- Historical variants, backups, hooks, and experiments remain in the repository for reference only; they are not part of the active configuration.
