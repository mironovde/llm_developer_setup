# Active configuration branches

This repository keeps the installable configuration for both agents. Do not treat the
historical `backups/` tree as the active setup.

| Agent | Active remote branch | Canonical files | Verified from live config |
| --- | --- | --- | --- |
| Claude Code | `origin/claude` | `team-os/home/` | 2026-08-16 |
| Codex | `origin/codex` | `codex/home/` | 2026-08-16 |

`main` and `team-os` are retained for compatibility with the previous Claude
rollout. New Claude updates go to `claude`; new Codex updates go to `codex`.

## What is versioned

Only durable, non-secret configuration is tracked: guidance, config, hooks/scripts
already shipped by this repository, and a project template. Caches, session history,
tokens, databases, and machine-specific authentication are deliberately excluded.

## Updating a branch

1. Compare the live files with the branch's canonical directory.
2. Record the verification date in the branch README.
3. Commit and push the branch. Do not copy settings between Claude and Codex
   verbatim: their configuration formats and enforcement mechanisms differ.

