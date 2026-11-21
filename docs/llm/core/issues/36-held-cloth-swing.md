---
type: ticket
status: done
kind: build
area: core
feature: core
priority: now
created: 2026-11-21
done: 2026-11-21
blocked_by: []
notes: []
terms: []
---

# The held Sock's cloth swings

The designer (Q2417, 2026-11-21): the Sock in hand "always snaps quickly when I change direction, it doesn't keep
any inertia"; "Could you figure out settings for the socks in hand that make it look more swinging?"
The lead's reading: `game/sock/sock_cloth_tuning.tres` has `drag = 1.0`, which in Godot's `SpringBoneSimulator3D`
is fully damped (all bone speed removed each step: no momentum, no overshoot), with `stiffness` 5 and `gravity` 3.
The held Looks is a child of `HeldView` under the camera, so a turn moves it rigidly and only the spring bones can
lag. Look work: find candidates, show them, change nothing until the designer picks.

## Behaviour list
- S1 Candidate settings of `drag`, `stiffness` and `gravity` (the `SockClothTuning` fields; the same tuning drives
  flying Socks, so note what each does to a throw's flop too). At least: today (1.0 / 5 / 3); drag 0.6; drag 0.4;
  drag 0.4 with stiffness 3; drag 0.25 with stiffness 2 and gravity 4; plus any the measurements suggest. Read
  Godot 4.7's `SpringBoneSimulator3D` docs/source for what drag, stiffness and gravity do per step, and whether the
  simulation runs in world space for a held Looks (its `center_from` setting; a centre on the camera would hide the
  turn).
- S2 For each candidate, measured: the toe bone's swing after a fixed quick view turn of 90° in 0.15 s and stop
  (peak overshoot angle, how many swings, time to settle), and after a walk start and stop. A small table.
- S3 For each candidate, one strip at 60 frames a second of the same turn-and-stop (and one of walk-stop), side by
  side in one sheet (`builds/review-core-36/`, `review-material` skill), using the existing shot actions
  (`pick_floor`, `turn_view`, `walk`, `stop`) with a per-run tuning override (an env var or shot option; nothing
  committed to the game's `.tres` until the go).
- S4 Name a recommendation, with the reason. If no tuning gives a real swing because the Looks turns rigidly with
  the camera, say so and sketch (not build) the alternative: the held layout lagging the camera's turn a little.
- S5 After the designer's pick: write the chosen values into `sock_cloth_tuning.tres` and the four Looks scenes'
  `SpringBoneSimulator3D` settings (they repeat the same numbers), and a case that the held toe overshoots after a
  turn (drag below 1).

## Acceptance
- The sheet and table in `builds/review-core-36/`; status `ready-for-human` for the designer's pick (look work stops
  at its first still).
- After the pick: the values in, the case passing, `--touched` passing.
- Real-path case: in the zoo, the player picks a Sock and turns the view; the held toe swings past and settles
  (the measured overshoot above a placeholder threshold).

## Answers
- No test for a visual tweak: the swing test is removed; the sheet and the designer's eye judge it (Q2421, 2026-11-21).
- The designer picked drag 0.25, stiffness 5, gravity 3 (Q2420, 2026-11-21).
- The held cloth should swing more; candidates first (Q2417, 2026-11-21).

## Open follow-ups
- [answered, Q2420] The designer's pick among the candidates (`builds/review-core-36/`: `sheet-turn.png`, `sheet-walk.png`,
  `table.txt`). S5 (values into the `.tres`, the four Looks scenes, the overshoot case) waits for it.

## Built log
- 2026-11-21 (look work, stopped at the sheet). Changed: no game value. Godot 4.7 per step:
  `next = tail + (tail - prev) * (1 - drag) + stiffness*dt*rest_dir + gravity*dt*down`; drag 1 keeps no speed, so
  no overshoot (measured: today 0 deg). The centre is the world origin, so the camera's turn does move the bones and
  a lower drag gives a swing: S4's alternative (the held layout lagging the camera's yaw) is not needed.
  Turn, deg (peak / overshoot / swings / settle s): today 35.5/0/0/0.10; d0.6 27.7/2.0/0/0.08; d0.4 25.1/7.5/1/0.08;
  d0.4s3 32.0/8.2/1/0.10; d0.25s2g4 33.0/16.0/2/0.18; d0.25s5 24.4/12.9/1/0.13; d0.15s3 29.0/18.6/2/0.22;
  d0.1s2 33.4/23.7/2/0.27; d0.1s1g4 36.4/26.4/3/0.30; walk stop is the same order, a little larger (table.txt).
  Throws: the same numbers drive flying Socks, so lower drag makes the flop ring; lower stiffness and higher gravity
  droop and flop more. Recommendation: d0.25s5 (drag 0.25, stiffness 5, gravity 3): one clear swing past rest
  (13 deg) settling in 0.13 s, stiffness and gravity unchanged so the droop and a throw's bend keep their size;
  d0.25s2g4 for a longer, floppier swing. Only 60 Hz measured (drag acts per physics step).
  Files: tests/held_cloth_swing_test.gd (measurement case; restores the tuning), tools/shot_hooks.gd (`cloth:drag/stiffness/gravity`
  override, `turn_view:quick`). Verified: see the commit.
- Model: Sonnet: tuning trials, measurement and strips.
- 2026-11-21 (S5). Changed: drag 0.25 in sock_cloth_tuning.tres (and the .gd default and its comment), in the four looks_*.tscn; hand_details_test now expects 0.25; real-path case in held_cloth_swing_test. Verified: see the commit.
- Merged: 7e66c2a2 (2026-11-21, branch core/36-held-cloth-swing)
