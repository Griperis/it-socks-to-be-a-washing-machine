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
- T05 A dropped Sock keeps the old flick (core/08, H10) unchanged.

## Acceptance
- One case per line; the real-path case: the player throws from the handling station and the body's first positions
  lie on the line from the hand to the aimed point.
- Strips: F1 before and after for each place it was seen; F2 the throw's first 10 frames before and after, in
  `builds/review-core-23/`. Stop at the strips for the designer's go.
- `Session.PROTOCOL` bumped if a synced field or RPC changes.

## Answers
- The Throw's real body leaves from the hand, aimed at the crosshair's point (Q2356, 2026-11-21).
- The flipping is seen in the heap pour, on settling, in drops and throws, and at the every-Sock station (Q2357, 2026-11-21).

## Open follow-ups

## Built log
- Model: Opus (lead): debugging physics and a flight's start across the Mess and the Hands.
