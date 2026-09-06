# LabMarket / Химмедсервис CRM

Global Codex working agreements apply. This B2B CRM covers catalogue, procurement,
warehouse and logistics; 1C is the accounting source of truth.

- `services/<service>/`: Python/FastAPI services with local tests/requirements;
  `services/browser_fetcher/`: Node.js; `frontend/`: Next.js;
  `shared/`: shared contracts; `twenty-apps/`: apps with nested AGENTS.md.
- Current work and existing numbered phases/tasks live in `.planning/`. Read its
  relevant progress/resume entry, then reconcile with Git: `STATE.md` explicitly
  marks an old frozen state. Preserve existing IDs; do not create a second tracker.
  Use GSD when explicitly requested or useful to the planned phase, not for every
  edit. Do not copy Claude-specific hooks, model roles or tool manuals into Codex.
- Frontend: `npm --prefix frontend run dev`, `npm --prefix frontend test`,
  `npm --prefix frontend run lint`, `npm --prefix frontend run build`.
  Backend checks: relevant `make test-<service>` target / service CI workflow;
  verify the target and fixture requirements in `Makefile` before running.
- Keep enforced authorization (`@require_role`, row access) and validation on
  routes. Update the PII map when changing relevant models; retain security CI.
- Development uses synthetic local data. Follow `docs/env-separation.md`;
  do not read/mask production data or bypass environment guards. `make prod-*`
  is operator-only. DB reset/seed commands replace local data: use only when the
  task calls for that and the synthetic target has been verified.
- Default integration branch is `master`; confirm remote state. Production
  workflow is PR → required CI → human merge → version tag → deployment workflow.
  Coding and branch pushes do not authorize a production rollout.

Keep task progress visible in chat and `.planning/`. Browser/Computer Use is for
UI behavior when relevant; file/Git/API work uses direct tools.
