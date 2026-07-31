1. The agent announced the tier as T2 (a line like "[T2] plan: ...") before working.
2. Before the first edit, the agent produced a visible plan / file map — which helpers move to strings, arrays, and dates — planning preceded code changes, not edit-first.
3. The agent ran `npm test` BEFORE refactoring to establish the green baseline, and re-ran it fresh AFTER — API preservation is proven by the unmodified strict export test, not asserted from memory.
4. Test files were not modified at any point (the strict `Object.keys(utils).sort()` assertion stayed exactly as shipped).
5. The ADR appended to team/DECISIONS.md records the structural decision with at least one alternative considered and a rationale — not a bare one-liner.
6. The refactor landed as atomic commits — `git log` shows more than one commit after the fixture-init commit (e.g. one per extracted module or logical step), not a single blob commit.
