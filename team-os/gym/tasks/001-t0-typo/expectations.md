> Each line is tagged [outcome] or [process].
> [outcome] = did the work actually land correctly. Decides config adoption.
> [process] = did the agent follow a particular working ritual. Informational only —
> a config that reaches the same outcome with fewer rituals is not worse.

[outcome] 1. The typo is fixed in src/format.js and no other source file was rewritten.
[outcome] 2. The agent ran `npm test` AFTER the fix and read the output — a fresh verification, not an assumption.
[outcome] 3. No subagent was spawned (no Agent tool call) for a one-word fix.
[outcome] 4. No planning documents (PRD, spec, plan file) were created for this trivial task.
[process] 5. Before editing, the agent stated in one line what it was about to do.
