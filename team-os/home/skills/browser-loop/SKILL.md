---
name: browser-loop
description: Hard protocol for the web edit→test cycle — build marker, full test path, console+network check, screenshot proof. Invoke for ANY web UI change that gets verified in a browser. Abandoning the loop is a blocker (hook-enforced).
---

# Browser edit-test loop

The classic failure: you edit, then test a STALE build, or drop the cycle halfway. This protocol makes both impossible. A Stop-hook blocks ending the turn while the loop is open.

## Protocol

1. **Open the loop**: `~/.claude/hooks/teamos-browser-loop.sh open "<task>"` — from the project root (needs team/).
2. **Build marker.** The page must expose which build it serves. If the project has no marker, add a dev-only stamp once (e.g. `<meta name="build-id" content="...">`, a `data-build` attr on body, or a console log with a timestamp/hash injected at build). Marker changes on every build.
3. **Rebuild** after your edit. Read the build output (the filter hook keeps the signal lines).
4. **Confirm freshness**: load the page via the browser MCP, read the served marker, compare with the fresh build's marker. Mismatch → you are testing a stale build; fix serving before any conclusions.
   → `teamos-browser-loop.sh prove build_marker "<marker value>"`
5. **Run the FULL user path** — the whole scenario the change belongs to, not just the changed element. Login flows: use `.env.test` credentials of our product freely (that is what they exist for).
   → save evidence to `team/artifacts/<slug>-test.md`, then `prove test_pass team/artifacts/<slug>-test.md`
6. **Console + network**: read browser console messages and failed network requests. New errors → fix and go back to step 3.
   → `prove console_clean "<summary, e.g. '0 errors, 0 failed requests'>"`
7. **Screenshot** of the final state → `team/artifacts/<slug>.png` → `prove screenshot team/artifacts/<slug>.png`
8. **Close**: `teamos-browser-loop.sh close` — fails if any proof is missing.

## Rules
- Any fix after step 4 → repeat FROM STEP 3 (rebuild). Never re-test without rebuilding.
- The loop closes in the same work session it opened. Blocked externally (server down, missing creds) → journal `[block]` with the reason, close the loop as blocked in SPRINT.md — do not leave it half-done silently.
- QA briefs for web tasks must include this protocol; QA's report carries the four proofs.
