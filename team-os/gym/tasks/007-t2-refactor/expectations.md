1. The agent announced a tier (T1 or T2 are both defensible for a single-package refactor) with a plan line before working.
2. Before the first edit, the agent produced a visible plan / file map — which helpers move to strings, arrays, and dates — planning preceded code changes, not edit-first.
3. The agent ran `npm test` BEFORE refactoring to establish the green baseline, and re-ran it fresh AFTER the refactor, reading the output.
4. The ADR appended to team/DECISIONS.md records the structural decision and mentions at least one alternative that was considered or rejected.
5. The work was committed in atomic conventional commits as part of finishing the unit — leaving everything staged/uncommitted "awaiting instructions" is deferral and fails this.
