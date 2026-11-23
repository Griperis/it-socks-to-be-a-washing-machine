---
type: ticket
status: done
kind: bug
area: core
feature: coop
priority: now
created: 2026-11-22
blocked_by: []
notes: ["reported by the designer in play, 2026-11-22"]
terms: [Host, Guest, Throw, Flight]
---

# A Guest's own Throw looks weaker on the Guest's screen, then jumps

## What happens (the designer, in two windows)
When the Guest throws, the Guest's own screen shows the Sock flying weaker or shorter than the same
charge does on the Host, and then it jumps or snaps to another spot. The Host's window shows the Guest's
Throw correctly, and the Host's own Throws are fine. So the Host's real flight is right, and the
thrower's ghost (Q2221, coop/09) is launched differently from it. The jump is then the hand-over onto the
streamed body, which Q2481 meant as a 0.2 s ease of about 0.3 m, not a visible snap.

## Suspects, not checked
- The ghost's launch speed, charge or direction differs from what the Host computes. It may read
  another Hands' tuning, a default `HandsTuning`, the charge before the release frame, or no
  `max_speed` scaling.
- Gravity, damping or mass on the ghost's body differ from the Host's flight body.
- The ghost is ended or reset when the stream's first row arrives, instead of easing.

## Reproduce
Two processes (the designer's way), Host `-- --host`, Guest `-- --join=127.0.0.1 --profile=b`, plus a
headless case with two zoos at 0 and 50 ms one way. The Guest throws at full charge and at half charge
toward a fixed point. Record the ghost's path and the Host's body's path, as the Guest sees them, side by
side.

## Acceptance
- The cause is written in the Built log, with the two recorded paths before the fix.
- The ghost's path matches the Host's flight within a small tolerance until the hand-over: the same
  launch speed, direction, gravity and damping. Write the tolerance in the Built log.
- The hand-over is the 0.2 s ease of Q2481, with no jump larger than the Host's own motion in one frame.
- A case at 0 and 50 ms checks both, through the Guest's real input path (charge, release).
- coop/09's cases and budgets still pass.

## Answers
- Q2221, Q2481 (2026-11-22).

## Open follow-ups
- [later] A Guest's drop ghost still leaves from the first-person hand with its own drift (Hands.drop_of),
  while the Host's drop leaves from the avatar's hand; both are aimed to land on the same spot, so it was
  not seen to differ, but it could take the same avatar-hand launch as the Throw now does. Technical, no
  design choice; the lead decides whether it is worth a ticket.
- [later] Reproduced headless only (two zoos in one process, real ENet, 0 and 50 ms); the two-window run
  (`-- --host`, `-- --join=127.0.0.1 --profile=b`) is the designer's check of the fix.

## Built log
- 2026-11-23 agent (coop/11): Cause, three faults, all on the Guest's side (the Host's flight was right):
  1. The ghost aimed its own arc from the first-person hand, the Host from the avatar's hand (worn, ~0.3-0.45 m
     away and lower, often moved out of the furniture by start_of()); both aim at the crosshair's point, so the
     same charge gave the same speed but another direction (recorded: ghost vel (-4.37,-2.42,-0.14), Host
     (-2.88,-3.84,-1.40), both 5.0 m/s).
  2. The ghost body had no physics material (friction 1, no bounce) where the Host's Throw bounces
     (`released_friction`, `released_bounce`): it died on the first touch, "weaker, shorter"; a thrown Pair
     also dragged as a Pair from the start, the Host's only from its first touch; no CCD switching.
  3. The Host's flight time counted from the first row's stamp, but a body let go outside a physics tick (a
     Guest's Command) still shows its launch pose at the next stamp: the Host's flight read one step ahead
     of the ghost, so the blend pulled the drawing a frame of motion forward all flight.
  Paths before the fix (Guest's real input, Throw at a point 4 m ahead and 1.2 m up, as the Guest's stream
  shows the Host's body): ghost body vs Host flight at most 0.496 m (0 ms, full), 0.497 m (0 ms, half), same
  at 50 ms; drawn ghost off the flight by 0.60/0.52 m (0 ms) and 0.61/0.53 m (50 ms), drawn under the floor
  (y -0.41); at 50 ms the drawing changed its step by 0.113 m in one frame, more than the Host body's own
  frame (0.102 m): the jump. After: 0.0000 m body and drawn (after the hand-over) over 14-15 moments before
  the first touch, at 0 and 50 ms, full and half; largest change of step 0.018 m against the Host's frame
  0.089-0.102 m.
- Changed: a Guest's Throw ghost flies the Host's launch: `Hands.avatar_hand_of()` works out where the Host
  draws the Sock on this player's avatar (the own body's HoldPoint with its `belly_back` undone,
  `AvatarLooks.avatar_hold()`, times the worn hang, `HeldView.worn_pose()`), and `launch_of()`/`start_of()`
  take that hand. The ghost is drawn from the first-person hand, that lead easing away by smoothstep over
  `GhostTuning.hand_over_time` (0.2 s, Q2481). The ghost body gets the Host's material
  (`MessMoving.let_go_material()`), CCD switching (`MessMoving.switch_ccd()`, was private) and a thrown Pair's
  damping on first touch. The ghost's age counts its body's steps from the tick of its first step; a
  FlightRow carries `born` (spawn only, not every row), the Host tick of its launch pose, and counts the
  flight from it.
- Tolerance: the ghost's body within 0.02 m of the Host's flight at the same moment until its first touch,
  and the drawn ghost within 0.02 m once the 0.2 s hand-over is done; no frame's step change over the body's
  own more than the Host's body moves in a frame. After the first touch the two bodies may part (a bounce
  off lying Socks the ghost cannot touch); coop/09's blend carries the drawing onto the Host's then.
- Files: `game/hands/throw_ghost.gd`, `game/hands/guest_ghosts.gd`, `game/hands/hands.gd`,
  `game/hands/held_view.gd`, `game/hands/ghost_tuning.gd`, `game/mess/mess_moving.gd`,
  `game/parts/avatar/avatar_looks.gd`, `game/sock/flight_row.gd`, `tests/coop_hands_test.gd` (new case
  `guest_throw_ghost_on_host_flight`).
- Verified: case PASS 52 checks (0 and 50 ms, full and half); `run.sh --touched` PASS 16279 checks, 410 cases
  (coop/09's coop_hands and coop_flight cases and budgets among them); grep_rules PASS.
