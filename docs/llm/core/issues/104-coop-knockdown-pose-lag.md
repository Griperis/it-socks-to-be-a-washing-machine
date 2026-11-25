---
type: ticket
status: done
kind: bug
area: core
feature: coop
priority: soon
created: 2026-11-25
done: 2026-11-25
blocked_by: [core/103]
notes: ["suggested model: opus (netcode test debugging)", "from core/103's [later] follow-up"]
terms: [Guest, Host]
---

# coop_knockdown still races when the Guest's pose arrives late

core/103 forced the Guest's pose 0.4 s late (a temporary hack in `Avatar._copy_follow`): with it,
`coop_knockdown:real_path` and its two drag cases still fail, although core/101 made `_aim` wait for the Host's copy
of the Guest's place. core/101 forced a different late path (the position send), so its wait does not cover this one.
Not yet seen flaky in a normal run, but the race is real.

## Acceptance
- Reproduced with core/103's forced 0.4 s pose lag; the cause named per failing case.
- Each case waits on the real condition the Host judges by (not more frames); passes with the forced lag, and the
  suite passes 10 runs in a row in suite order under load with no FLAKY line.
- No game code or look/feel number changed unless the game is wrong (then a [blocking] follow-up).

## Open follow-ups

## Built log
- 2026-11-25 (agent): Reproduced with the Guest's pose 0.4 s late (temporary hack in `Avatar._copy_follow`, Guest only,
  reverted): `real_path` and `drag_ends` failed (39 of 170 checks). Causes: `real_path`: the Host aimed at its avatar of
  the Guest 20 frames after the Guest moved, while it still stood (pose and drawn) 1.9 m off at the pick spot, and the
  hit test (`Knockdowns.place_of`, the newest pose) missed. `drag_ends`: the grab came a fixed time after the Guest
  stepped to the feet; with the late pose the Host either refused it or, after the fixed 70-frame wait, the drag
  started so late that the rise ended it ("up") before H101's "apart" could reach the Host. `drag_and_struggle` passed
  here but measured H99 a fixed 40 frames after the pull. The game is right.
  Changed: `real_path` waits until the Host has the Guest at its spot as judged (`place_of`) and as drawn; the fixed
  70-frame waits are a wait until the body lies still (`_lain`); `_down_and_grabbed` steps the Guest up as the Host
  falls and waits on the Host's own grab check (`Parts.near_point` within `grab_reach + REACH_SLACK` of feet or
  middle); H99 waits until the Host has the Guest where it stopped, then for the feet; core/101's wait is `_host_has`.
  No game code or number changed.
  Files: tests/coop_knockdown_test.gd.
  Verified: forced-lag repro PASS 182 checks, 8 cases; `--only=coop_knockdown` 12 runs, 3 at once, reruns off: PASS 182
  checks, 8 cases each, no FLAKY; `grep_rules.py`: PASS.
- Merged: 863d6bcc (2026-11-25, branch core/104-coop-knockdown-pose-lag)
