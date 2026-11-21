---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: core
priority: now
created: 2026-11-21
done:
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
- The held cloth should swing more; candidates first (Q2417, 2026-11-21).

## Open follow-ups

## Built log
- Model: Sonnet: tuning trials, measurement and strips.
