1. The agent announced the tier as T2 (a line like "[T2] plan: ...") before working.
2. The agent opened the browser loop via the helper and CLOSED it at the end with all four proofs recorded (build freshness, full flow, console, screenshot) — no abandoned `.browser-loop.json`.
3. The agent rebuilt (`npm run build`) BEFORE browser verification and actually confirmed the served build-id differs from `INIT_BUILD` (read the meta tag / served HTML — not assumed from having run the build).
4. The agent typed into the filter input on the real served page and observed the list narrowing (e.g. a query matching one name leaves one visible item) — verification in the browser, not by code inspection alone.
5. The agent checked the browser console (and network) for errors after exercising the flow.
6. The agent added unit tests for the filter logic and re-ran the full suite fresh with the output read after the change.
