# Delo Yasno

Global working rules apply.

- The backend is the source of truth for financial calculations; the frontend renders results.
- Keep durable project context in `.planning/`; start with the latest `V*-RESUME.md` when present.
- Use `.artifacts/` for temporary evidence, screenshots, and logs.
- Core commands: `npm run dev:mock`, `npm run test:integration`, `cd frontend && npm test`, `cd backend && npm test`.
- Do not run `npm run env:init` for local development.
- Treat changes to calculations, taxes, schemas, authentication, payments, personal data, and deployment as high risk; verify them accordingly.
