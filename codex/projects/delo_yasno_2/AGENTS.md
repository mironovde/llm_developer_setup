# Delo Yasno

Global working rules apply.

- The backend is the source of truth for financial calculations; the frontend renders results.
- Keep durable project context in `.planning/`; use its current entry point and
  verify it against actual Git state. Preserve existing phase/wave IDs; add stable
  task IDs there when needed, without a second tracker or automatic GSD pipeline.
- Use `.artifacts/` for temporary evidence, screenshots, and logs.
- Core commands: `npm run dev:mock`, `npm run test:integration`, `cd frontend && npm test`, `cd backend && npm test`.
- Do not run `npm run env:init` for local development.
- Treat changes to calculations, taxes, schemas, authentication, payments, personal data, and deployment as high risk; verify them accordingly.

Use the global delivery, progress and Git agreements. Determine the acceptance
branch from the active task; local checks alone do not establish integration or
deployment. Preserve unfinished work when updating configuration.
