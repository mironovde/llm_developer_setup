# Active configuration branches

| Agent | Remote branch | Canonical files | Verified |
| --- | --- | --- | --- |
| GPT-6 Astra / Codex | `origin/gpt-6-astra` | `codex/home/`, `codex/projects/` | 2026-09-06 |
| Previous Codex baseline | `origin/codex` | historical Codex snapshot | 2026-08-16 |
| Claude Code | `origin/claude` | `team-os/home/` | 2026-08-16 |

New Astra configuration changes go to `gpt-6-astra`. The existing branch `codex`
prevents `codex/*` branch names locally, so use `astra/<id>-<slug>` for later
configuration deliveries in this repository. Application repos use their normal
`codex/<id>-<slug>` convention when available.

Global guidance defines delivery defaults; project files provide facts and local
exceptions. Goals, numbered work and evidence live in one tracker per project.
No mandatory hook pipeline is installed. Claude branches, historical variants,
backups and gym experiments are preserved as reference, not active Codex rules.

Only portable non-secret configuration is versioned. Live credentials, sessions,
model catalogs, trust paths, backups and generated plugin configuration stay local.
See [installation guide](codex/README.md) and [current delivery](TASKS.md).
