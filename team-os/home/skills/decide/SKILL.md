---
name: decide
description: Record an ADR in team/DECISIONS.md — key decisions (framework, storage, API shape, anything irreversible or constraining) get logged in the same iteration they are made. Also /decide <topic> to force one.
argument-hint: "[topic]"
---

# Decide — ADR entry

For the decision at hand (or `$ARGUMENTS` if given):

1. Read the last ADR number in team/DECISIONS.md; use the next one.
2. Append, ≤12 lines total:

```
## ADR-NNN: <title>
- date: <today> · status: accepted · tier: <current>
- context: <why a decision was needed, 1–3 lines>
- options: A) <…> B) <…> C) <…>
- choice: <letter> — <reason in one line>
- consequences: <what this constrains or enables>
```

3. Journal: `[plan] ADR-NNN <title>`.

Rules:
- 2–3 real options minimum; a one-option ADR is a description, not a decision — say what you rejected.
- Autonomy L0/L1: propose to the user first (status: proposed). L2/L3: decide, record, move on.
- User veto (any time later): set `status: vetoed (user, <date>)`, journal `[veto]`, replan affected work. Vetoes are honored without argument; capture the user's reasoning if given.
- What does NOT need an ADR: reversible implementation detail, convention already set by the codebase, anything a smart default covers.
