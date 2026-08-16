# Active configuration branches

This repository keeps small, portable configurations for both agents.

| Agent | Active remote branch | Canonical files | Verified |
| --- | --- | --- | --- |
| Claude Code | `origin/claude` | `team-os/home/` | 2026-08-16 |
| Codex | `origin/codex` | `codex/home/` | 2026-08-16 |

`main` and `team-os` are compatibility branches for the previous Claude setup.
New Claude updates go to `claude`; new Codex updates go to `codex`.

## Principles

The active configuration is intentionally short. It gives the model goals, safety
boundaries, and project facts, but does not prescribe a workflow, impose hooks, or
duplicate rules across projects.

Only durable, non-secret files are versioned. Caches, session history, credentials,
machine-local trust paths, and generated marketplace data stay local.

