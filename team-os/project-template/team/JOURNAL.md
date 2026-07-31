# JOURNAL — append-only event log

> One line per event: `YYYY-MM-DDTHH:MMZ [tier] [event] text`
> events: start | plan | escalate | deescalate | block | unblock | budget-alert | ship | halt | veto | retro
> Example: `2026-07-31T14:02Z [T1] [escalate] touched files grew 4→9, ambiguous spec → T2, replanning`
