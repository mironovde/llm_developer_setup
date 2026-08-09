---
name: browser-loop
description: Protocol for verifying a web UI change in a real browser — rebuild, confirm the served build is the new one, run the whole user path, check console and network, keep a screenshot. Invoke for any web UI change you intend to call working.
---

# Browser edit-test loop

The failure this prevents is specific and common: you edit, then verify against a stale build, and
conclude the change works. The second failure is dropping the cycle halfway and reporting anyway.

**Tool choice:** with the user present, use the native surface (Claude in Chrome or the app's built-in
browser pane). Unattended work — subagents, headless runs — uses chrome-devtools MCP with
`--headless --isolated`; never drive the user's own browser unattended. Reach for playwright only when
the brief actually requires cross-browser coverage.

Helper: `HELPER=.claude/hooks/teamos-browser-loop.sh` in the project, else `~/.claude/hooks/…`.
It keeps a marker in `.artifacts/` and a Stop hook refuses to end the turn while the loop is open.

1. `bash $HELPER open "<task>"`
2. **Build marker.** The page must say which build it serves — a `<meta name="build-id">`, a `data-build`
   attribute, a stamped console line. If the project has none, add a dev-only one once.
3. **Rebuild** after the edit and read the build output.
4. **Confirm freshness**: load the page, read the served marker, compare it with the build you just
   produced. A mismatch means you are looking at a stale build — fix serving before concluding anything.
   → `bash $HELPER prove build_marker "<value>"`
5. **Run the whole user path**, not just the changed control. Test credentials in `.env.test` exist to
   be used. → evidence to `.artifacts/<slug>-test.md`, then `prove test_pass <path>`
6. **Console + network**: read console messages and failed requests. New errors → fix, return to step 3.
   → `prove console_clean "<summary>"`
7. **Screenshot** the final state → `.artifacts/<slug>.png` (a DOM/text snapshot if the tool cannot write
   files) → `prove screenshot <path>`
8. `bash $HELPER close` — fails while any proof is missing.

Any fix after step 4 restarts at step 3. Never re-test without rebuilding. Blocked from outside (server
down, missing credentials): say so explicitly and close the loop as blocked — do not leave it hanging.
