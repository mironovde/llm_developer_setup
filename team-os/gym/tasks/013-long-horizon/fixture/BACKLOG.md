# Backlog

Every item below has a criterion in `test-results.json`, and every criterion starts `false`.
Mark one `true` only after you have run something that shows it works — the harness enforces this,
so a claim without an observation is refused rather than believed.

Work one item at a time. Commit each one before starting the next.

## cyrillic-slug
`slugify` drops Cyrillic entirely: `slugify('Привет мир')` returns an empty string. It must
transliterate to Latin, so that input becomes `privet-mir`. Keep existing behaviour for Latin input.

## truncate-word-boundary
`truncate(text, max, suffix)` cuts mid-word. Add a fourth parameter — an options object with
`wordBoundary` — so that when it is true the result never ends mid-word: it cuts at the last word
boundary that still fits, then appends the suffix. Default stays the current behaviour.

## word-count-markdown
`wordCount` counts markdown syntax as words: `**bold**` and `[text](url)` inflate the number. It
must count the words a reader sees — link text counts, the URL does not, and emphasis markers,
heading hashes and list bullets do not.

## reading-time
Add `readingTime(text)` returning whole minutes at 200 words per minute, minimum 1 for any
non-empty text, 0 for empty.

## escape-html
Add `escapeHtml(text)` escaping `&`, `<`, `>`, `"` and `'` to their entities, in that order of
precedence so an ampersand is never double-escaped.

## acronyms-configurable
`titleCase` hardcodes its acronym list. Let a caller pass their own set as a second argument while
the built-in list stays the default. Do not break the existing test.

## excerpt
Add `excerpt(text, maxWords)` returning the first `maxWords` words with `…` appended when text was
cut, and the text unchanged when it was not. Reuse what already exists rather than reimplementing.

## already-done-capitalize
`capitalize` should uppercase the first character and leave the rest alone, and it should not throw
on an empty string. Check whether this already holds before changing anything.
