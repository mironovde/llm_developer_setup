# Codex — active configuration

Verified against the live Codex configuration on **2026-08-16**.

## Installable files

| File here | Install location | Purpose |
| --- | --- | --- |
| `home/AGENTS.md` | `~/.codex/AGENTS.md` | Compact global working agreement |
| `home/config.toml` | merge into `~/.codex/config.toml` | Portable global defaults |
| `projects/delo_yasno_2/AGENTS.md` | repository root | Current project-specific rules |
| `project-template/AGENTS.md` | new repository root | Compact starting point for a project |

## Codex adaptation

The source Claude guidance was retained as outcomes, not copied as syntax:

- `CLAUDE.md` becomes `AGENTS.md`.
- Claude permission rules and hooks are not translated; Codex uses its sandbox,
  approval policy, skills, plugins, and MCP configuration instead.
- `config.toml` retains every portable live setting. Project trust paths,
  marketplace cache timestamps, model migration notices, sessions, and credentials
  are machine state and must remain local.

The active remote branch for this configuration is **`origin/codex`**. The
separate **`origin/claude`** branch is the active Claude Code configuration.
See [ACTIVE_CONFIGURATIONS.md](../ACTIVE_CONFIGURATIONS.md) for the branch map.
