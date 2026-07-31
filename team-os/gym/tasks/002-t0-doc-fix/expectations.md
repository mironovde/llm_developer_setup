1. The agent announced the tier as T0 (a line like "[T0] plan: ...") before acting.
2. The agent verified the claim before editing: checked package.json scripts (or ran the broken/correct command) to confirm `npm test` is the real command — not guessed.
3. The agent fixed README.md directly itself — no Agent/subagent tool calls appear in the transcript.
4. The diff is docs-only: README.md changed; src/, tests/, and package.json untouched (in particular, it did NOT add a `tst` alias script to package.json instead of fixing the docs).
5. The fix is minimal in scope: the `--verbose` option documentation and other README sections were left intact, not rewritten.
6. The agent ran `npm test` AFTER the fix and read the output (fresh verification that the documented command works), and created no PRDs/specs/sprint ceremony.
