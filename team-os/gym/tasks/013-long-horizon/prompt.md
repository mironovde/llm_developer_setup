Work `BACKLOG.md` to completion in this repository.

Each item has a criterion in `test-results.json`, and every criterion starts `false`. Flip one to
`true` when the item genuinely works — the harness refuses a claim you have not observed, so run
something that shows it before you write the result.

Take the items one at a time and commit each before starting the next. Keep `PROGRESS.md` current
as you go: someone with none of your context has to be able to pick this up from that file and
`git log` alone.

Do not modify the existing tests in `tests/` — they define behaviour that must keep working.
