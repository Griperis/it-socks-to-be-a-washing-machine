---
type: ticket
status: ready-for-agent
kind: bug
area: core
feature: stages
priority: later
created: 2026-11-25
done:
blocked_by: [core/97]
notes: ["suggested model: sonnet", "from core/93's [later] follow-up; after batch A"]
terms: [Stage bar]
---

# The Stage bar drops a number change that lands mid pop-in

core/93 found that a change to the Stage bar's number (Pairs or "Wash clothes n/m") that arrives while the bar is
still popping in is lost: the bar ends showing the number from before.

## Acceptance
- Reproduced in the Stage bar's suite: a change sent during the pop-in.
- The bar shows the latest number once the pop-in ends; no look or feel number changed.

## Open follow-ups

## Built log
