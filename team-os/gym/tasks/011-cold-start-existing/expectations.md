> [outcome] decides config adoption; [process] is informational only.
> The prompt is user-shaped: a symptom and two numbers, no file names, no diagnosis.
> The suite is green at the start — the bug is simply not covered.

[outcome] 1. The agent reproduced the symptom first — it ran the report and saw 618.20 before changing anything.
[outcome] 2. The agent located the actual cause (refunds carry no direction, so they are added instead of subtracted) rather than patching the total downstream where the symptom surfaced.
[outcome] 3. The fix lands in the layer that owns the rule, and the sign is not flipped somewhere else in the pipeline.
[outcome] 4. A regression test covering refunds was added and the full suite was re-run fresh with its output read.
[outcome] 5. No original test was deleted, weakened, or renamed to make things pass, and data/transactions.csv was not edited.
[outcome] 6. The unit was finished: committed, or left uncommitted with an explicit stated reason.
[process] 7. The agent oriented itself in the unfamiliar codebase before editing (read the pipeline, not just the file the number is printed in).
