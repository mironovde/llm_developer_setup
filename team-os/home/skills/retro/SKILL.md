---
name: retro
description: Retrospective + compound step — turn metrics and journal into lessons, config hypotheses (Gym-gated), and new golden tasks. Invoke after each sprint, after autopilot night runs, every ~5 cycles, or in lite mode after a notable T2.
---

# Retro — the self-improvement loop

Fresh data is injected below at invocation time:

## Efficiency (last 7 days)
!`bash ~/.claude/teamos/bin/efficiency-report . --days 7 2>/dev/null || echo "(no metrics yet)"`

## Journal tail
!`grep -E '^[0-9]{4}-' team/JOURNAL.md 2>/dev/null | tail -20 || echo "(no journal)"`

## Full mode (sprint close, night run)
1. **Analyze** the data above: where did tokens burn (top burners vs value delivered)? which escalations/reverts/budget-alerts repeated? what blocked and why?
2. **Lessons**: for the single most valuable insight, write ONE lesson file `team/solutions/<category>/<slug>.md` (categories: process|debugging|architecture|tooling|product) with frontmatter `date, category, symptoms, applies_when` and a body: what happened → root cause → what to do next time. One lesson per retro — batching dilutes them. Lessons are read at T2/T3 design time (grep by keywords), so write searchable symptoms.
3. **Config hypotheses** (≤3): concrete changes to CLAUDE.md/skills/hooks/budgets that the data supports. Each hypothesis → validated in Gym against baseline BEFORE adoption (pass-rate AND tokens must not regress; regression → discard). Never adopt a config change on impressions.
4. **Gym candidates**: every real process failure this cycle (broken loop, stale-build test, budget blowout, wrong-tier triage) → append to `team/solutions/gym-candidates.md`: symptom, how to reproduce as a fixture, what check would catch it. The test set grows from real failures.
5. Journal one `[retro]` line: key numbers + decisions.

## Lite mode (after a notable T2)
Only step 2 (one lesson) + step 4 if a process failure occurred. Skip the analysis ceremony.

Never: adopt config changes without a Gym pass; write multi-lesson dumps; let a "we'll remember" insight go unrecorded.
