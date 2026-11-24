---
type: ticket
status: done
kind: bug
area: core
feature: mess
priority: later
created: 2026-11-24
done: 2026-11-24
blocked_by: []
notes: ["suggested model: opus (physics debugging)", "found by core/69"]
terms: [Sock, Mess]
---

# A Sock pushed under the floor may be drawn there for one frame

## What happens
- core/69 found that Jolt can push a poured Sock from above the floor to under it in one physics step (y 0.172 to
  -0.051 in `flight_start:t01_heap` when the suite's earlier cases change Jolt's body order). The Mess puts it back
  0.01 above the floor on its next tick (the core/50 fix). If a frame is drawn between the push and the put-back, the
  player sees that Sock under the floor for one frame (about 1/60 s). Not yet checked whether such a frame is drawn.
- The designer asked for this as a small follow-up (2026-11-24).

## Acceptance
- Reproduced first: whether a drawn frame ever shows a Sock under the floor (a shot or a per-frame log on the
  heap pour of `flight_start:t01_heap` in suite order); written down either way.
- If it can be seen: the put-back happens before the frame is drawn (same physics step, or the looks hold the last
  good place), with no change to a look or feel number; a case that fails before the fix.
- If it cannot be seen: the reason in the Built log, ticket closed.

## Open follow-ups

## Built log

### 2026-11-24
- Changed: reproduced on main. `flight_start:t01_heap` in suite order no longer gets a push (0 steps put back in 3
  runs, forward and reversed). So the check runs on `mess_settle:real_path_thin_floor`: the player clicks More at the
  heap with the zoo floor's margin at 1 mm, and there Jolt pushes poured Socks under the floor in every pour.
  A per-frame log, taken after every `_process` (after the Mess placed its flying drawings, before the draw), saw
  4 pushes (Socks at y -0.035 to -0.083 when the physics tick starts, each put back by the Mess in that tick) and
  0 frames out of 306 with a flying Sock drawn under the floor. That holds for the MultiMesh rows and for bodies with
  a Looks. At 120 ticks a second (two steps a frame) the result was the same: 1 push, 0 frames.
- **Cannot be seen. Why:** Godot sends a body's place after a step to its node only at the sync at the start of the
  next physics tick. Right after that sync, in the same tick, the Mess's `_physics_process` puts the push back and
  resets its interpolation (`MessMoving.undo_push()`, core/50). A frame is drawn only after the ticks of an iteration,
  so it shows the place before the push or the put-back, never the push. Frames drawn between ticks interpolate
  between two places the node held, and neither is the pushed one. Checked the other way too: with the put-back
  switched off, the new check failed with 146 frames drawn under the floor, the first one tick after the push.
- Kept as a guard: `real_path_thin_floor` now also checks, every frame as drawn, that no flying Sock is drawn under the
  floor, and that the pour had at least one push (the case still tests what its title says)
  (`tests/drawn_floor_watch.gd`). No game code or number changed.
- Not this ticket: with physics at 30 ticks a second (the game runs at 60), Socks sat with a shape middle in the floor
  that the push rule does not count as a push (its motion explains them). Seen only in the probe.
- Files: tests/drawn_floor_watch.gd, tests/drawn_floor_watch.gd.uid, tests/mess_settle_test.gd
- Verified: touched `PASS 286 checks, 31 cases`; rules `PASS rules: 9 rules, no new hit`
- Merged: 9f53ce79 (2026-11-25, branch core/70-sock-under-floor-frame)
