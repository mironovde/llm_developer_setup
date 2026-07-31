# gym-fixture-team-directory — Team OS project

> Stack: Node.js static web app (zero deps), build step src/ → dist/

## Dev commands

| Command | What it does |
|---------|--------------|
| `npm run build` | Build src/ → dist/, stamping a fresh unique build-id |
| `npm start` | Serve dist/ on http://localhost:4173 (gym-fixture-server) |
| `npm test` | Run the unit tests (node --test) |

## Build marker

`src/index.html` carries `<meta name="build-id" content="__BUILD_ID__">`. `npm run build` replaces the placeholder with a fresh unique id on every run. The committed dist/ is stamped `INIT_BUILD` — if the served page still shows `INIT_BUILD`, you are looking at a stale build. Always rebuild before verifying UI changes in the browser, and confirm the served build-id changed.
