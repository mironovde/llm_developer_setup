# Delo Yasno

Global Codex rules apply. These are project-specific additions.

## Scope and state

- Keep changes within the requested scope; do not add speculative refactors or features.
- For a question, investigation, or diagnosis, report findings and stop unless a change was requested.
- Keep durable project state in `.planning/`: read the latest `V*-RESUME.md` when it exists. Do not create `NOTES.md` or `team/`.
- Use `.artifacts/<date>-<task>/` for screenshots, logs, dumps, and other temporary evidence; do not place them in the repository root.

## Risk and verification

- Treat changes to `packages/calc-engine`, tax constants, `shared/schemas`, auth, payments, PII, Docker Compose, and nginx as high risk.
- For UI changes, exercise the affected browser flow. For calculation changes, run focused tests and manually verify representative numbers. For frontend changes, run the relevant build before reporting completion.
- Never expose secrets or read `.env*`, private keys, or credential stores.

## Local commands

```bash
npm run dev:mock
npm run test:integration
cd frontend && npm test
cd backend && npm test
```

Do not run `npm run env:init` for local development.
