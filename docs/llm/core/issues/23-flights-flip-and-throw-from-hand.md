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

# Flights: Socks flip and glitch; the Throw flies from the hand

M0.5, from the designer's play (2026-11-21). Both faults are about how a flight starts and settles, in the same files
(`game/mess/mess_moving.gd`, `mess.gd`, `game/hands/hands.gd`, `held_view.gd`, the flight scenes), so one agent does
both.

## The faults
- **F1 Socks flip and glitch** (designer: "socks fly and glitch when they spawn and are established, they are kinda
  flipping"). Seen everywhere (Q2357): the heap pour, settling on the floor, the player's drops and throws, the
  every-Sock station. Reproduce before you diagnose: strips of each, frame by frame, with the body's pose, speed and
  spin and the drawn pose logged (core/21's way). Suspects to check one by one, not to assume: the pose at a start
  (lying record to flight body: basis, the leg/foot boxes' offset against the Looks), the pose at a rest (flight
  back to a record), the drawn Looks against its body (the cloth's flat blend, the flying MultiMesh's transform),
  Jolt contact jitter between the two boxes or against other lying bodies (margins, CCD, the boxes' sizes against the
  mesh), spawned Socks overlapping and pushed apart, angular damping. Fix the cause, not the look.
- **F2 The Throw flies from the hand** (designer: "throw should not fly first towards the player cursor, but from the
  hand towards the target"). Today the body starts at the eyes and the drawn Sock catches up from the hand over 0.1 s
  (core/19, the old Q483), so it seems to swing toward the cursor first. The designer chose (Q2356): **the real body
  leaves from the hand**, on an arc aimed to land where the crosshair is (the old charge decides the speed as now;
  the direction is solved from the hand to the aimed point), and the catch-up goes. Close to a wall the hand's way can
  be blocked where the eye-line was not: a hand inside a wall or behind it throws from the eye-line's clear point
  instead (no Sock through a wall). A Guest's throw stays decided by the Host from the same numbers.

## Behaviour list
- T01 A Sock that spawns, falls, lands or comes to rest never flips, spins up or jumps without a cause: its pose and
  its drawn pose change smoothly every frame (a case fails on a tilt or position jump over a set limit per frame,
  over the heap pour, a drop, a throw and the every-Sock station's start).
- T02 A thrown Sock's body starts at the hand's drawn place and flies straight on its arc toward the aimed point;
  the first frames move away from the hand toward the target, never toward the screen's middle first.
- T03 The thrown Sock lands where the crosshair was (within the old throw's spread) at every charge that reaches it.
- T04 With the hand inside or behind a wall, the throw starts at the nearest clear point of the eye-line; nothing
  passes through a wall.
- T05 A drop leaves from the hand too (Q2367, replacing "the old flick unchanged"): the body is let go at the
  hand's drawn place and falls on its own to the spot, with no drawn flick to the spot and no hold 3 cm over it.
  It lands where the drop was aimed (the drop-target check and its refusals stay) and never passes through a
  wall (the T04 rule).

## Acceptance
- One case per line; the real-path cases: the player throws from the handling station and the body's first
  positions lie on the line from the hand to the aimed point; the player drops with the real button and the body
  leaves from the hand and lands on the aimed spot.
- Strips: F1 before and after for each place it was seen; F2 the throw's and the drop's first 10 frames before
  and after, in
  `builds/review-core-23/`. Stop at the strips for the designer's go.
- `Session.PROTOCOL` bumped if a synced field or RPC changes.

## Answers
- The Throw's real body leaves from the hand, aimed at the crosshair's point (Q2356, 2026-11-21).
- The flipping is seen in the heap pour, on settling, in drops and throws, and at the every-Sock station (Q2357, 2026-11-21).
- A drop leaves from the hand as well: let go at the hand's drawn place, it falls on its own to the aimed spot;
  no flick, no 3 cm hold; the drop-target check and refusals stay; never through a wall (Q2367, 2026-11-21).

- Merged on the designer's go, to be tried in play; numbers such as turn_weight are tuned from that (Q2382, 2026-11-21).
- A thrown Sock keeps the hand's pose in the air (lands as it flies), not turned flat (Q2383, 2026-11-21).

## Open follow-ups
- [closed 2026-11-21] F1 at the every-Sock station's start: not reproduced. Nothing moves there (2031 Sock records
  lying, 0 moving over 300 ticks; picks and drops there come to rest with no jump; the strip is still).
  The lead needs what the designer did there (walked in, picked, dropped, a Pair) for the next repro. — Q2407 and Q2415: core/31 found and fixed the settle teleport
- [closed 2026-11-21] `turn_weight` 3 (new, MessTuning): a flying Sock turns as three times its flat box's inertia.
  At 1 (a rigid 50 g board, as before) an edge landing spins it to Jolt's 47 rad/s cap, a flip of 45
  degrees a frame. The designer's number on the strips: higher turns slower still, its throw's spin
  and its topple flat slower too. — Q2382: core/23 merged on the strips; Q2413: `turn_weight` stays 3
- [closed 2026-11-21] A drop (Q2367) needs choices the ticket did not make; as built, each waits for the designer:
  the dropped Sock turns from its hanging pose to lying flat (its length across the view) by the time
  it lands, so it lands as the old drop lay (without the turn it landed on its end and toppled off a
  lying Sock); it falls as a woken Sock (no bounce, 0.9 slide, 0.6 / 3.0 drag) and wakes nothing it
  falls on, as the old 3 cm drop did; a dropped Pair drags as a Pair from the start; when its fall from
  the hand would meet something (a shelf inside a cupboard, a table's edge) or drift faster than
  `drop_drift` 3 m/s (new, HandsTuning), it is let go farther along the eye-line instead, so it still
  lands where aimed. A Pair dropped on a thin Sock may now roll off it (pairing p08 lays it there). — Q2382: core/23 merged on the strips as built; Q2401 sets the bend
- [closed 2026-11-21] The drawn Sock grows from the hand's size (0.6 of its own) to its own over `let_go_grow`
  0.1 s (new, HandsTuning; it replaces `catch_up`): the body is full size from the hand. Without it the
  Sock pops 1.7 times bigger on release. Its held cloth bend is not carried over: the flying Looks
  starts straight. The zoom and the turn button are not in the hand's pose the Host uses. — Q2382: merged as built; Q2401: a drop keeps no bend, a Throw does (core/27 P08)
- [later] An aim out of the Throw's reach (the far floor at a light charge) flies along the aim from
  the hand, as before, and lands short of the crosshair.

## Built log
- Model: Opus (lead): debugging physics and a flight's start across the Mess and the Hands.

### 2026-11-21
- Changed: F1 reproduced by logging every flight each tick (core/21's way). Drops and the rest switch
  were clean (0 m, 0 degrees at the switch). The flips were rigid-board physics: a 50 g, 2.6 cm box
  landing on an edge spun up to Jolt's 47 rad/s cap (45 degrees a frame); in a 60-Sock pour 201 ticks
  turned over 20 degrees, Socks bounced back up 0.26 m and 31 of 60 rolled over. Causes fixed: poured
  Socks flew as Throws (bounce 0.35, drag 0.8) where the old pour let them fall as woken Socks;
  flights flew as one wide box but lay as leg and foot boxes (now the same shapes, as the old game);
  CCD was always on (now from 1 m/s, off under 0.5, as the old game); a flying Sock now has
  `turn_weight` 3 times its flat box's inertia. After: 4 ticks over 20 degrees, a rise of 0.015 m, the
  worst turn 31 degrees a tick. F2 (Q2356): a Throw's body leaves from the hand's pose (the HeldView's
  active place at full depth) on the arc (`Arc`, drag included) to the crosshair's point; the
  catch-up is gone, the drawn Looks grows from the hand's size over `let_go_grow`. T04: a hand inside
  or behind a wall throws from the eye-line's clear point. Q2367: a drop leaves from the hand too and
  falls on its own to the spot (no flick, no 3 cm hold); see Open follow-ups for how. PROTOCOL 9.
- Files: game/hands/arc.gd (+ .uid), game/hands/hands.gd, hands_tuning.gd, held_view.gd,
  physics_queries.gd, game/mess/mess.gd, mess_bodies.gd, mess_moving.gd, mess_tuning.gd,
  game/entities/cabinet/cabinet.gd (a drop is never shelved), game/parts/session.gd,
  docs/architecture/mess.md, tests/flight_start_test.gd (+ .uid), tests/cabinet_test.gd,
  hand_details_test.gd, handling_test.gd, mess_test.gd, pairing_test.gd, throw_test.gd, zoo_test.gd,
  tools/shot_hooks.gd (heap_more:close, drop_aimed).
- Verified: PASS 7327 checks, 225 cases (run.sh --touched); PASS rules. T01's cases fail on
  turn_weight 1 (45 degrees a tick). Strips in builds/review-core-23/: f2-throw-first-frames,
  f2-drop-first-frames, f1-throw-landing, f1-drop-landing, f1-heap-pour, f1-every-sock-start
  (each -before-after.png; frames in before/ and after/). The strips' lob (charge 0.3 at a far
  crosshair) is out of the arc's reach, so it lands short in both.
- Merged: 53ae1fd8 (2026-11-21, branch core/23-flights-flip-and-throw-from-hand)
