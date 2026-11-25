---
type: ticket
status: done
kind: bug
area: core
feature: house
priority: now
created: 2026-11-25
done: 2026-11-25
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

### 2026-11-25
- Cause: `_level_up()` waited 900 frames for the player to stand, and the loading screen holds the player
  until the house's Socks are laid. On a busy machine `SliceClock` times units long, so fewer fit a 14 ms
  slice (down to one a frame) and the laying takes more frames than 900, each frame short (the ledger: 900
  frames in 2.4 s). Not core/77: the house suite sets `start_all`, so it lays what it laid before (990 Socks,
  90 frames quiet). Reproduced by a forced short slice (3 ms: one unit a frame): the same failure line.
- Changed: `_level_up()` first waits for the loading screen to lift with a 20 s wall-time floor
  (`LAYING_S`), then for the player to stand; `real_path_loading_screen`'s laying loop has the same floor.
  No game code or number changed.
- Files: tests/house_test.gd
- Verified: forced 3.6 ms slice: laid in 1627 frames, the case passes; house suite 10 runs in a row under
  load (loadavg 4.5-11.6, reruns off; runs 3-10 without the unchanged timing case): every one
  `PASS`, no FLAKY line; `run.sh --touched`: see the commit

