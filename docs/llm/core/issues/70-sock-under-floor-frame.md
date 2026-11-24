---
type: ticket
status: ready-for-agent
kind: bug
area: core
feature: mess
priority: later
created: 2026-11-24
done:
blocked_by: []
notes: ["suggested model: opus (physics debugging)", "found by core/69"]
terms: [Sock, Mess]
---

# A Sock pushed under the floor may be drawn there for one frame

## What happens
- core/69 found that Jolt can push a poured Sock from above the floor to under it in one physics step (y 0.172 to
  -0.051 in `flight_start:t01_heap` when the suite's earlier cases change Jolt's body order). The Mess puts it back
  0.01 above the floor on its next tick (the core/50 fix). If a frame is drawn between the push and the put-back, the
  player sees that Sock under the floor for one frame (about 1/60 s). Not yet checked whether such a frame is drawn.
- The designer asked for this as a small follow-up (2026-11-24).

## Acceptance
- Reproduced first: whether a drawn frame ever shows a Sock under the floor (a shot or a per-frame log on the
  heap pour of `flight_start:t01_heap` in suite order); written down either way.
- If it can be seen: the put-back happens before the frame is drawn (same physics step, or the looks hold the last
  good place), with no change to a look or feel number; a case that fails before the fix.
- If it cannot be seen: the reason in the Built log, ticket closed.

## Open follow-ups

## Built log
