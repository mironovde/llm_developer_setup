# Codex — active configuration

Verified against the live Codex configuration on **2026-08-16**.

## Installable files

| File here | Install location | Purpose |
| --- | --- | --- |
| `home/AGENTS.md` | `~/.codex/AGENTS.md` | Short global working agreement |
| `home/config.toml` | merge into `~/.codex/config.toml` | Portable global defaults |
| `projects/delo_yasno_2/AGENTS.md` | repository root | Current project-specific rules |
| `project-template/AGENTS.md` | new repository root | Short starting point for a project |

## Codex adaptation

Claude and Codex share the same concise outcomes, but use their native formats:

- `CLAUDE.md` becomes `AGENTS.md`.
- Claude permission rules and hooks are not copied. Codex uses its sandbox,
  approval policy, skills, plugins, and MCP configuration.
- `config.toml` contains the portable live settings. Project trust paths,
  cache timestamps, model migration notices, sessions, and credentials stay local.
- The bundled plugins mirror the live global configuration. Do not remove one
  merely because its skill appears available: the explicit setting enables it.

The active remote branch is **`origin/codex`**. The separate
**`origin/claude`** branch is the active Claude Code configuration.
See [ACTIVE_CONFIGURATIONS.md](../ACTIVE_CONFIGURATIONS.md) for the branch map.
