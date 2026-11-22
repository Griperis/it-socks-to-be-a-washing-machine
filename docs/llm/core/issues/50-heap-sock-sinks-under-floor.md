---
type: ticket
status: ready-for-agent
kind: bug
area: core
feature: core
priority: soon
created: 2026-11-22
blocked_by: []
notes: ["found by core/49 (2026-11-22); a FLAKY case is a defect to rework (kit/docs/TESTING.md)"]
terms: [Mess, Sock]
---

# A Sock in the heap sinks 116 mm under the floor, then is lifted while still moving

## What happens
In about 1 of 30 heap pours (`mess_settle:real_path_2` run in reverse order, once also with a 5 mm slop),
one Sock is pressed 116 mm under the floor by the heap. The rest rule then lifts it back up while it is
still moving, and the watch reports it as "hot" and "jumped". The case passed on its rerun, so it shows
as FLAKY. In play, a Sock would vanish into the floor and pop back up.

## Reproduce
On main (d2b9087 or later), run `mess_settle` reversed, repeating `real_path_2` until it fails. The
pour's places are seeded, so log the Sock's id and tick once it is seen.

## Acceptance
- The cause is found and written in the Built log: what lets a lying or falling Sock get 116 mm through
  the static floor (the floor's thickness, a Sock pushed out of a body, the wait queue, a body started
  inside the floor?), and why the rest rule lifts a moving Sock.
- Fixed in the Mess, not hidden in the test: no Sock is ever under the floor, and the rest rule never moves
  a Sock that is still moving. `real_path` at 0 to 4 extra records, in order and reversed, run repeatedly
  with no FLAKY line.
- core/49's counts and coop/07's and coop/08's co-op cases and budgets still pass.

## Answers

## Open follow-ups

## Built log
