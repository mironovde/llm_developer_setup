> [outcome] decides config adoption; [process] is informational only.

[outcome] 1. The agent verified the real command (checked package.json scripts or ran it) instead of guessing.
[outcome] 2. README.md was fixed; src/, tests/ and package.json are untouched — in particular no `tst` alias was added to package.json instead of fixing the docs.
[outcome] 3. The fix is minimal: the `--verbose` documentation and other README sections were left intact, not rewritten.
[outcome] 4. The agent ran `npm test` AFTER the fix and read the output.
[outcome] 5. No planning documents were created for this trivial task.
[process] 6. Before editing, the agent stated in one line what it was about to do.
