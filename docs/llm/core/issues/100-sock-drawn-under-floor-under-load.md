---
type: ticket
status: needs-info
kind: bug
area: core
feature: mess
priority: now
created: 2026-11-25
done:
blocked_by: []
notes: ["suggested model: opus (physics debugging)", "ledger: tests/flaky/ledger.md, mess_settle:real_path_thin_floor (3 lines, 2026-11-25)", "reopens core/70's finding"]
terms: [Sock, Mess]
---

# A Sock is drawn under the floor when the machine is loaded

core/70 found no drawn frame with a Sock under the floor (0 of 306) and added a drawn-frame watch to
`mess_settle:real_path_thin_floor`. In the full suite (several runs at once) that watch fails and then passes alone:
12 to 35 frames draw a flying Sock 1.1-1.3 cm under the floor (ledger, 2026-11-25 00:12, 00:16, 00:45; e.g. "frame 74:
a body drawn at y -0.013"). Under load more than one physics step can run per drawn frame, or frames are drawn between
steps (physics interpolation), so the push and the put-back no longer share a step before the draw. A player on a
slow frame may see it. A flaky case is a defect to rework (kit/docs/TESTING.md "Flaky cases").

## Acceptance
- Reproduced first under load (the suite order, or the case with a forced slow frame / several steps per frame).
- The cause named (steps per frame, interpolation, or when the Mess's put-back runs) and fixed so no drawn frame shows
  a Sock under the floor, with no look or feel number changed (else a [blocking] follow-up).
- The watch passes in the full suite 10 runs in a row; no FLAKY line.

## Open follow-ups
- [blocking] The rest of the fix is Jolt's penetration slop, an engine number in `project.godot`
  (`physics/jolt_physics_3d/simulation/penetration_slop`, Jolt's default 0.02 m, not set in the project). Jolt leaves
  a contact up to that deep unresolved, and a Sock's leg box is 26 mm thick, so a Sock pressed by the heap on it rests
  with its leg's middle up to about 7 mm under the floor's top (its bottom up to 20 mm in): that Sock is drawn sunk
  into the floor, flying and then lying (the rest rule's `sunk` 0.02 m keeps it there, P13). This is in every heap
  pour, also on the game's own floors with their normal margin: with the frame watch turned on in the five
  `real_path` cases (normal floor), 2 to 61 such frames per pour, 0 pushes. Set to 0.005 m, together with this
  branch's rule, no frame drew a flying Sock under the floor in any of 8 orders (suite, reversed, the shards that
  failed in the ledger, the case alone), the thin floor and all five normal floors, and every other mess_settle check
  passed. It changes every body's contacts in the game (Socks in each other too: Q2499 accepted 20 mm because of this
  default), so the full suite must judge it. Does the designer let the project set Jolt's penetration slop to 0.005 m
  (or another value), or keep Jolt's 0.02 m and accept a Sock sunk up to about 1 cm into the floor under a heap
  (then the watch counts only the core/70 push, as the rest rule does)?
- [later] The acceptance's "full suite 10 runs in a row" is the lead's run (a ticket agent runs `--touched` only).

## Answers
- What to do with a Sock drawn about 1 cm under the floor on slow frames: fix it, no look or feel number changed (Q2652, 2026-11-25). It merges before batch A starts (Q2653, 2026-11-25).

## Built log

### 2026-11-25
- Changed: reproduced on main, and it is not load. The case fails by suite order, the same frames every time: the
  shard `--suite=mess_settle --part=2/2` gives the ledger's "35; 5 steps put back, frame 74 at y -0.013" and
  `--part=3/3` its "12; 7 steps put back, frame 84 at y -0.011" (the full suite splits mess_settle so); the whole
  suite and `--reverse` fail with other frames; the case alone and other shards pass. Load changes only the frame
  count (273 to 346), never the bad frames. A per-frame and per-tick log: the physics interpolation fraction is 0 at
  each drawn frame (one step a frame) and the body's place as it is, not only as drawn, has a middle in the floor.
- Cause, two parts. (1) In the step Jolt pushes one Sock through the floor (put back, core/50), it presses the Sock
  under it 13-18 mm down; that is less than `push_slack` (0.02 m), so the push rule left it, its leg's middle up to
  10 mm in the floor. With Jolt's default penetration slop (0.02 m) nothing pushes it out again, and it rests there
  (the rest rule's `sunk`). (2) Without any push, a Sock pressed by the heap sinks slowly into the floor within
  Jolt's slop until its leg's middle is under the floor's top; its motion explains every step. This happens on the
  game's normal floors too (Open follow-ups).
- Fixed (1): within the slack, a step that took a middle of the Sock into the house from outside it is undone as a
  push (`MessMoving.undo_push`, also a Guest's Throw ghost); one already in is left alone. No number changed. (2)
  waits on the designer ([blocking]).
- New case `mess_settle:pressed_in` (fails before: "undone (0)", "-0.0160 m"). `real_path_thin_floor` still fails
  in suite order until (2) is decided.
- Files: game/mess/mess_moving.gd, game/mess/mess_tuning.gd (comment only), tests/mess_settle_test.gd,
  docs/architecture/mess.md, this ticket
- Verified: touched `FAIL 1 of 19674 checks, 577 cases` (only `real_path_thin_floor`, part (2), the shard's known frames); `pressed_in` PASS, and FAIL before the fix; rules `PASS rules: 9 rules, no new hit`
