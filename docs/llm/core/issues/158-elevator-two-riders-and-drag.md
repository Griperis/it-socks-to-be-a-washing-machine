---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: house
priority: now
created: 2026-11-26
done:
blocked_by: ["[[157-elevator-riders]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 6", "suggested model: opus"]
terms: [Elevator, Roomy Car, Drag, Teammate]
suites: [elevator, knockdown, coop_knockdown, avatar, upgrades]
---

# Two in the Elevator's car, and the dragged body

Two squeeze into the car (three with Roomy Car), and a dragger pulls the body they drag in with them. Build
`docs/architecture/elevator.md` "The riders" (two in the car, a dragger), draft 149-E:

- the second seat's `squeeze` clip on both riders (0.25 over 0.7 s, three dying wobbles), the view's jostle,
  `elevator_squeeze` at the car (its SoundEvent is core/154's);
- the stat `car_extra_seats` (ADD, base 0, step 1, "%d") on `roomy_car.tres` (no longer "Coming soon"; it keeps
  `needs` Elevator Repair and stays co-op only); seats = `seats` + the stat, a dragger counting with the body;
- the dragged body as the dragger's next seat: lifted from lying to standing at the hatch (`lift`, 0.5 s), then the
  creature's climb; the ragdoll hidden while seated; the drag holds through the ride; at the climb out the body comes
  out with its dragger, half as far out, and falls where it comes out (Q836, Q984).

Behaviour lines (`11-elevator.md`): "Riders" lines 7, 8, 9; "The Upgrades" Roomy Car.

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
`roomy_car`'s stat in the inspector (`# placeholder:` the old); the squeeze and the lift are clips in the car's Looks.

## Acceptance
- Real path: a Guest's Space aimed into the car where the Host already rides puts both avatars squeezed in their seats
  on both machines, and `elevator_squeeze` plays at the car.
- A third player is refused "Elevator full" until Roomy Car is bought, then fits.
- A player dragging a knocked-down Teammate climbs in with them; both come out at the arrival, the body half as far and
  falling; on a Guest the same.
- Placeholders: the stat's step.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The Elevator as the old (Q2702, 2026-11-26).

## Open follow-ups
