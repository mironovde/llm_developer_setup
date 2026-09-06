# Delo Yasno

Global Codex working agreements apply, including numbered delivery, regular push,
visible checkpoints and proportional tool use.

## Product and architecture

- Build a clear, attractive, trustworthy financial product. Desktop first;
  mobile polish is deferred. Preserve financial correctness and functionality.
  Monetization requires a working tariff lifecycle and clear free/paid value.
- Backend calculations are the source of truth; frontend renders results.
- Current goal, stable `D001` / `D001-T01` IDs, dependencies and evidence live in
  `.planning/DELIVERIES.md` when present. Read its current position first; otherwise
  follow the existing `.planning/` entry point. Verify older plans against Git.
- Use `.artifacts/` for temporary logs, screenshots and evidence.
- Commands: `npm run dev:mock`, `npm run test:integration`,
  `npm --prefix frontend test`, `npm --prefix backend test`.
  Do not run `npm run env:init` for local development.
- Verify calculations, taxes, schemas, auth, payments, personal data and
  deployment changes according to their risk; do not weaken required gates.

## Delivery specifics

- Keep one active delivery. Existing unfinished branches are preserved backlog;
  finish the active delivery's integration blockers before another capability.
- A release contains one complete user scenario. Separate independent editor,
  reports, curves and monetization capabilities. Keep UI/API/schema/calculation
  pieces together only where required for that scenario to work.
- Branch: `codex/001-unified-model-editor`; PR: `[D001] Единый редактор модели`.
  Preserve established `[D001] ...` commit subjects. Use global push cadence.
- Completion requires criteria verified on `main`; deployment is a separate
  state. Follow the active task's merge authorization and required review/CI.
- Before review, reconcile duplicate features, remove incidental scope, and
  describe the final diff. Map legacy branches to deliveries before cleanup;
  prove content inclusion before closing superseded PRs or deleting branches.
- Distinguish owner feedback, actual user studies, AI review, UI walkthroughs
  and automated checks. Do not claim conversion gains without measurements.

## UI acceptance and machine resources

- Prefer CLI/API for code, data, logs and deterministic checks. Use in-app
  Browser for visual and interaction acceptance. Preserve this project's choice
  of browser: no Chrome, standalone Playwright or agent-browser fallback.
- Use Computer Use / native Excel for actual workbook behavior. Launching Excel
  via `open` is authorized. Keep the UI check relevant to the changed scenario.
- Root plus at most one scoped helper, only when authorized and useful to the
  active delivery; no subdelegation or parallel agent builds/tests/installs.
- One heavy job at a time, one test worker, one frontend preview. Stop the preview
  before a full build/test. Check memory pressure and owned process RSS during
  heavy work; initial combined target <=3 GiB. Stop owned jobs if pressure rises.
  This is an operating target, not an OS cap. Preserve user processes and files.
- Track owned PIDs/ports and stop unused jobs/apps. Keep large logs in `.artifacts/`
  and preserve disk headroom. Reuse valid evidence; do not run broad suites again
  without a change/failure that invalidates their result.
