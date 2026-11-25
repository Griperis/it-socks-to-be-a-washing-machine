---
type: ticket
status: done
kind: bug
area: core
feature: coop
priority: soon
created: 2026-11-25
done: 2026-11-25
blocked_by: [core/101]
notes: ["suggested model: sonnet", "from core/101's [later] follow-up"]
terms: [Guest, Host]
---

# Co-op tests that click a fixed time after moving the Guest

core/101 found `coop_knockdown:real_path` clicking 15 frames after moving the Guest, while the Host judges reach by
the Guest's position as last heard (sent on a wall-clock interval, may be late). On a busy machine the Host refuses
the pick as too far. `coop_hands`, `coop_carry` and `coop_pings` move the Guest the same way and may share the race.

## Acceptance
- Each of the three suites checked: where a click follows a Guest move, it waits until the Host has the player at
  the spot (core/101's `_aim` wait), not a fixed number of frames.
- Shown by forcing the Guest's position 0.4 s late (as core/101 did): each case passes with the wait, and a case that
  had the race fails without it.
- No game code or look/feel number changed unless the game is wrong (then a [blocking] follow-up).

## Open follow-ups
- [later] `coop_knockdown` still fails under a 0.4 s late Guest pose in `real_path` and the two drag cases (the core/101 wait is not enough there; the Host throws at the late avatar). Test-side; not seen on a normal run.

## Built log
- 2026-11-25 (agent): Changed: `_aim` / `_aim_at` of `coop_carry`, `coop_hands`, `coop_pings` end with `_host_has(player)`, which waits
  until the Host's `LevelNet.where()` has the player within 0.1 m (3D: reach is 3D) of where it stands, as core/101 did for
  knockdown. Forced the Guest's pose 0.4 s late (temporary hack in `Avatar._copy_follow`, Guest only, reverted): with the
  wait all three pass; without it `coop_carry:carry` fails ("the Guest carries it on both"). `coop_hands` and `coop_pings`
  did not fail without the wait under the hack (their Guest clicks are not placed-then-clicked, or pass anyway), so the
  wait there is a guard, not a shown fix. The game is right. The hack also broke `coop_knockdown` cases (real_path throws
  at the late avatar, drag cases), which this ticket does not touch: see follow-up.
  Files: tests/coop_carry_test.gd, tests/coop_hands_test.gd, tests/coop_pings_test.gd.
  Verified: `--touched` PASS 689 checks, 35 cases; `grep_rules.py` PASS.
