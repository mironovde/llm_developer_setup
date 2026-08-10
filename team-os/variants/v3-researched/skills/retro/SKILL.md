---
name: retro
description: Turn what actually happened into one lesson and at most three config hypotheses — each of which must survive the gym before adoption. Invoke after a long run or a notable failure.
---

# Retro

## Recent runs
!`bash ~/.claude/teamos/bin/efficiency-report . --days 7 2>/dev/null || echo "(no metrics yet)"`

1. **Read the data above and the tail of NOTES.md.** Where did the tokens go, and what did they buy?
   What failed twice? What was blocked and why?
2. **One lesson.** Write the single most valuable insight to `.notes/lessons/<slug>.md`: what happened,
   the root cause, what to do differently. One per retro — a batch of five dilutes all five.
3. **At most three config hypotheses**, each concrete enough to test: a line to add, a line to delete,
   a budget to change. Every one goes through the gym against the current baseline before adoption.
   Outcome pass-rate must not regress and tokens must not grow. No exceptions for good-sounding ideas.
4. **Every real process failure becomes a golden task** — symptom, how to reproduce it as a fixture,
   what check would have caught it. The suite grows from actual failures, not imagined ones.
