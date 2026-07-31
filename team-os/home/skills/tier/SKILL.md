---
name: tier
description: Force a tier for a task, overriding the router.
argument-hint: "T0|T1|T2|T3 <task>"
disable-model-invocation: true
---

# /tier — user override

`$ARGUMENTS` = tier + task. The override is binding: do not re-triage, do not argue.

1. Announce: `[<tier>] (user override) plan: <one sentence>`.
2. Journal: `[plan] tier override <tier>: <task>` (if a team/ dir exists).
3. Execute per the tier: T0 → single pass + self-check; T1 → skill `t1`; T2 → skill `t2`; T3 → skill `t3`.

Escalation triggers still apply upward (an override sets the floor, not a ceiling): if T0 turns out to need T1+, escalate with a journal line as usual — but never de-escalate below the user's override.
