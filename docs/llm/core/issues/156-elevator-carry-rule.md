---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: house
priority: now
created: 2026-11-26
done:
blocked_by: ["[[155-elevator-car-calls-hatches]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 3", "suggested model: opus"]
terms: [Elevator, Mess, Sock, Pair]
suites: [elevator, mess, carry, coop_mess, leaf_push, save]
---

# What rides the Elevator: the one carry rule

Whatever lies in the car when it departs rides it, by one rule that names no kind of thing (Q2699): Socks and floor
Pairs (the Mess), and every lying `Carriable` (the book, the Machine Parts, the Laundry bins, and later the Radio, the
detector and the Backpack vacuum). Build `docs/architecture/elevator.md` "The one carry rule", draft 149-C:

- `Mess.rides_patch(box, sill, delta, onto)` (lying records in `CarBox` or on `SillBox` moved by `delta`, a Moving Sock
  laid at its pose first) and `Mess.car_opened(box)` (the records in the box woken so they settle as the hatch opens);
- `Carriable.rides_patch` (nobody holds it, `at` in the box or on the sill: `at += delta`, clamped into the box), with
  the check that a sibling's `may_ride() -> bool`, when it has one, allows it (core/175's `Vacuum` answers it for the
  Sock vacuum's container, Q2710; no member yet);
- both join `elevator_cargo` (core/155 already calls the group; `fills_car` and `called_patch` get their member with
  the Cat, core/180);
- the hatch's AnimatableBody3D pushes Socks on the sill into the car as it shuts (the Doors' push, core/13); a Carriable
  on the sill is clamped in at `depart`.

All of it is one answer with the car's move, so nothing is seen half moved, cut or lost. While the car rides what is in
it lies still at the bound stop behind the shut hatch (lying records and Carriables do not simulate).

Behaviour lines (`11-elevator.md`): "Calling and sending" line 5's push and line 6 (nothing drawn moving; frozen at the
bound floor, back to life when the hatch opens); "Things in the car" line 2.

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
No data of its own: a new carried thing is a `Carriable` (it rides with no line of its own) or a Part that joins
`elevator_cargo` with `rides_patch`.

## Acceptance
- Real path: in the Elevator station the player drops Socks from the generator into the open car with the right click
  and clicks the other stop's call button; at the arrival the Socks the player sees lie in the car there, in the same
  places relative to the car.
- A floor Pair put in with the Hands and the Laundry bin set on the sill ride too; nothing in the car moves while it
  rides; none is lost or left in the shaft; the hatch shutting on Socks on the sill pushes them in.
- On a Guest the same; a load mid-ride keeps them in the car.
- Every Design keeps its two records throughout.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- Every carried thing rides the Elevator by one item rule (Q2699, 2026-11-26).
- The Sock vacuum's container rides only with its nozzle on its hook (Q2710, 2026-11-26): the rule's `may_ride()`
  check is built here, its member in core/175.

## Open follow-ups
