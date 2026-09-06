# LLM Developer Setup

This repository versions portable agent configuration. The Astra configuration
lives on `gpt-6-astra`; `codex` is the previous Codex baseline. A local branch
named `codex` prevents `codex/*` names in this repository, so use `astra/<id>-<slug>`
for subsequent deliveries here. Keep Claude configuration on its existing branch.

- Canonical Codex files: `codex/home/`, `codex/projects/`, and
  `codex/project-template/`. Global working agreements apply.
- Current delivery and numbered tasks: `TASKS.md`. Research and installation
  evidence belong in `codex/docs/`; temporary output belongs in `.artifacts/`.
- Read `codex/README.md` before installing. Preserve unrelated local settings,
  plugins, MCP servers, credentials, trust entries, and concurrent project work.
- Verify configuration parsing, installer dry-run/idempotence/rollback, and
  instruction discovery with the installed Codex CLI. Prompt behavior needs
  real-task evaluation; passing file checks does not prove model effectiveness.
- A configuration delivery is complete when its documented scope is installed,
  checked, committed, and pushed to the intended configuration branch. Updating
  application repositories does not authorize shipping their unrelated code.
- Never commit private backups, full live config, session history, or credentials.
