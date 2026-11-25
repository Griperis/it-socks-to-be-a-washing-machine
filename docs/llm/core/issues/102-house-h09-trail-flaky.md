---
type: ticket
status: ready-for-agent
kind: bug
area: core
feature: house
priority: now
created: 2026-11-25
done:
blocked_by: []
notes: ["suggested model: opus (flaky test debugging)", "ledger: tests/flaky/ledger.md, house:h09_trail_stays_on_treads (2026-11-25)", "batch A side ticket"]
terms: []
---

# The house trail case waits too long for the player under load

`house:h09_trail_stays_on_treads` failed once during batch A while 4-5 agents and a merge ran at once, and passed on rerun. The ledger line:
"waited 900 frames (2.4 s) for the player to stand in the house, and it never came true". A flaky case is a defect to rework, never to tolerate or switch off (kit/docs/TESTING.md "Flaky cases").

## Acceptance
- Reproduced first (the suite order, a part/shard, or a forced slow frame), and the cause named.
- Fixed at the cause: the test waits on the real condition, not more frames, unless the game itself is wrong (then
  fix the game). No look or feel number changed (else a [blocking] follow-up).
- The case passes 10 runs in a row in its suite order under load; no FLAKY line.

## Open follow-ups

## Built log
