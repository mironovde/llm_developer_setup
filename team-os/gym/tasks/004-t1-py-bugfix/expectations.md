> [outcome] decides config adoption; [process] is informational only.

[outcome] 1. The agent reproduced the failure first (ran `python3 -m unittest discover -s tests` and read the failing output) BEFORE changing code.
[outcome] 2. The fix landed in src/stats.py and no test file was modified.
[outcome] 3. After the fix the full suite was re-run fresh and its output read.
[outcome] 4. The fix addresses the real defect rather than special-casing the failing inputs.
[outcome] 5. No planning documents were created for this single-subsystem task.
[process] 6. Verification happened in a context independent of the implementation rather than only self-checking.
