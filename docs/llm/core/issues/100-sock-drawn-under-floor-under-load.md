---
type: ticket
status: done
kind: bug
area: core
feature: mess
priority: now
created: 2026-11-25
done: 2026-11-25
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
- [later] Jolt's penetration slop 0.005 m instead of the default 0.02 m: Socks under a heap would not sink up to about 1 cm into the floor; it alters every contact (core/100 measured 0 bad frames in 8 suite orders at 0.005). Settled for now by the old game (Q2604; reference/it-socks/project.godot sets no slop): kept Jolt's default; row in docs/migration/batch-a-review.md.

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
- Changed (the lead's decision, Q2604: the old game kept Jolt's default slop, reference/it-socks/project.godot:257-260
  sets none): the slop stays at 0.02 m, `project.godot` untouched. `real_path_thin_floor`'s frame watch now counts
  a flying Sock's middle only inside a wall or under a floor's top by the rest rule's `sunk` or more (P13); a Sock
  sunk within Jolt's slop under the heap is not counted. With the put-back switched off the watch still fails (113
  frames). The question is [later]; a row in docs/migration/batch-a-review.md "Settled by the old game".
- Files: tests/drawn_floor_watch.gd, tests/mess_settle_test.gd, docs/architecture/mess.md,
  docs/migration/batch-a-review.md, this ticket
- Verified: `--suite=mess_settle --part=2/2` `PASS 117 checks, 15 cases`; `--part=3/3` `PASS 82 checks, 11 cases`;
  the full suite 10 runs in a row, each `PASS 19788 checks, 616 cases`, no FLAKY line (each printed SLOW, the whole
  suite 122-125 s, over 120 s)
- Merged: b2de5927 (2026-11-25, branch core/100-sock-drawn-under-floor-under-load)
