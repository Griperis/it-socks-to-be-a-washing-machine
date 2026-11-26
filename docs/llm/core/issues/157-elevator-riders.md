---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: house
priority: now
created: 2026-11-26
done:
blocked_by: ["[[155-elevator-car-calls-hatches]]", "[[163-radio-carried-and-thrown]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 4", "suggested model: opus"]
terms: [Elevator, Teammate, Hands, Throw]
suites: [elevator, knockdown, coop_knockdown, player, teammates, avatar, save]
---

# The Elevator's riders

Players ride the Elevator (Q2702): Space aimed into the open car climbs in, the creature shrinks, hops over the sill and
rides curled in first person, low and dim with the rumble, Hands and all; a rider sends the car by the letters; every
rider climbs out on arrival. Build `docs/architecture/elevator.md` "The riders", draft 149-D:

- the verbs `climb_in`, `climb_out`, `send`, `everyone_out` (Host only, the First wash's end, core/94's signal) and
  `left()`; the refusals (not open, beyond `reach`, down or in the drum, no seat, a cargo member's `fills_car`: "Elevator
  full"; out of order and locked as core/155's words);
- the Player's jump asks the aimed Elevator first ("Climb in [Space]", the `jump` action, no new input);
- the rider's camera at the seat's `Eyes`; `ride_view.tscn` (a CanvasLayer with a ColorRect, `dim_in` / `dim_out`);
  the camera rig's `ride_shake`; the seats' `climb_in` and `climb_out` clips and the avatar's `curl`; a rider drawn at
  their seat from decided state on every machine, only their look (yaw, pitch) read from the sync;
- the letters aimed by riders only (the aim skips Teammates in the car): a left click or E sends ("Send the Elevator to
  %s"), the car's floor's letter `lit`, a locked one `locked` ("Elevator locked");
- `elevator_ride` played for the rider alone from the hatch shutting to the arrival (its SoundEvent is core/154's);
- `Knockdowns` refuses the knock of a rider, for every thrown thing (Socks, and core/163's thrown Carriables) (Q2484,
  Q2700).

Behaviour lines (`11-elevator.md`): "Calling and sending" the send from the letters; "Riders" lines 1-6 and 10-15;
"Sounds" `elevator_ride`; "Words" (Climb in, Climb out, Elevator full, "Send the Elevator to %s"). No climb sound (Q2702).

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
The motion is clips (Q2697): the seat's `climb_in` (shrink to 0.33, hop 0.3 m, turn, curl 70 degrees, 0.8 s),
`climb_out`, the avatar's `curl`, the ride view's `dim_in` (0.6 dark over 0.4 s), the camera's `ride_shake` (12 mm); their
numbers are the clips' keys. `reach` and `eye_height` are `ElevatorTuning`'s. The ride view is a scene in nodes (Q2658).

## Acceptance
- Real path: in the house with Elevator Repair bought, the player's Space aimed at the open car puts the camera at the
  seat's eyes (curled); after a left click on the "1" letter and the ride, the camera is back on the floor 0.8 m in
  front of the other stop's hatch.
- The view dims and shakes while the hatch is shut and `elevator_ride` plays for the rider only; Space climbs out where
  the car stands open; a refused climb reads its words; the Hands keep what they hold through the ride.
- A Guest rider seen on the Host is curled at the seat and faces their look; a late Guest sees a rider curled at once;
  a load draws riders curled.
- A full-charge Throw at a rider never knocks them down; a rider who leaves the game is out; `everyone_out` empties
  the car.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- Players ride (shrink, hop in, curl, the low dim view); riders climb out on arrival; no climb sound (Q2702,
  2026-11-26).
- An Elevator rider is never hit by a Throw (Q2700, 2026-11-26).

## Open follow-ups
