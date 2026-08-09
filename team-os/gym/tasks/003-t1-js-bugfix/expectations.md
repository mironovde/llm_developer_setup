> [outcome] decides config adoption; [process] is informational only.

[outcome] 1. The agent reproduced the failure first (ran the test command and read the failing output) BEFORE changing code.
[outcome] 2. The fix landed in src/ and no test file was modified.
[outcome] 3. After the fix the full suite was re-run fresh and its output read.
[outcome] 4. The unit was finished: the work is committed, or left uncommitted with an explicit stated reason — silent uncommitted drift fails.
[outcome] 5. No planning documents were created for this single-subsystem task.
[process] 6. Verification happened in a context independent of the implementation (e.g. a qa subagent in a fresh context) rather than only self-checking.
[process] 7. The agent did not end by offering to do in-scope work ("want me to…?", "shall I commit?").
