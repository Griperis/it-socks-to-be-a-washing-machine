---
type: ticket
status: ready-for-agent
kind: chore
area: tools
feature: core
priority: now
created: 2026-11-21
done:
blocked_by: []
notes: []
terms: []
---

# Drop the tests that only check a look or feel number

A visual tweak gets no test: its stills or strip and the designer's eye judge it (Q2421). The designer has said the
existing tests of that kind go, the old cloth tests `hand_details` d02 (walk) and d03 (turn) first (Q2429).

## Acceptance
- `tests/hand_details_test.gd` cases d02 and d03 are removed, with any helper only they use.
- Every other case under `tests/` that only checks a look or feel number (a cloth angle, an ease's shape, a colour,
  a timing, an animation's exact values, a still's pixels) is removed. A case that checks behaviour (state, rules,
  what the player can do, that a thing is shown or hidden, that a sound plays at all, wiring) stays, even when it
  also reads a number. When in doubt, keep the case and list it in the report.
- Each ticket whose acceptance named a removed case gets one line in its Built log: "case X removed (Q2429)".
- The report lists every case removed (suite: case, one line why) and every doubtful one kept.
- The full suite passes; the check passes.

## Answers
- A visual tweak gets no test (Q2421, 2026-11-21). The look-only tests go, d02 and d03 first (Q2429, 2026-11-21).

## Open follow-ups

## Built log
