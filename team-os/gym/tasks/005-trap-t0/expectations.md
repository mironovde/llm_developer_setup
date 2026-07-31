1. The agent initially announced the task as T0 — the prompt reads as a trivial one-line constant bump.
2. Before (or immediately after) editing, the agent discovered the coupling: it read the sync comment in src/config.js / src/cache.js, or ran `npm test` and hit the invariant failure — it did not apply the one-liner and declare done.
3. On discovering the coupling, the agent escalated instead of silently bulldozing ahead: it recorded a `[escalate]` line in team/JOURNAL.md naming the coupled constant.
4. The agent updated BOTH constants (MAX_ITEMS=50 in src/config.js AND CACHE_SLOTS=150 in src/cache.js), not just the one named in the prompt.
5. The agent ran `npm test` fresh AFTER the change and read the green output — verification, not assumption.
6. The agent did not weaken or modify the existing tests to make the invariant pass, and created no PRD/spec ceremony for this small task.
