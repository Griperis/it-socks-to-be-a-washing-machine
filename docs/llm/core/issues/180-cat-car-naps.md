---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: house
priority: now
created: 2026-11-26
done:
blocked_by: ["[[177-cat-petting-holding-throwing]]", "[[155-elevator-car-calls-hatches]]", "[[156-elevator-carry-rule]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 9", "suggested model: opus"]
terms: [Cat, Elevator]
suites: [cat, elevator, save]
---

# The Cat's naps in the Elevator's car

The Cat naps in the open, empty Elevator car; a call from another floor takes it along asleep and it wakes and hops out
there; while it lies inside nobody can climb in ("Elevator full"); shut in at its stop it naps 20 s, then opens the
hatch itself and walks out. Build `docs/architecture/cat.md` "The Cat's side of the car", draft 151-E:

- `CarNap` (`game/entities/cat/cat_car_nap.gd`, a Part with no state, a child of `cat.tscn`), member of core/155's
  `elevator_cargo` and of `cat_places`: `nap_spot` (the car standing OPEN, nobody riding: the middle of `CarBox`'s
  floor, hopped into with `fall` and `cat_land`), `rides_patch`, `fills_car`, `called_patch` (a call where it lies
  wakes it; elsewhere it sleeps on and rides), `takes_cat` (set down or thrown into the open car it stays), `holds_cat`;
- its Host-only `wake` (on `Elevator.arrived` with the Cat in the car, or a call where it lies), patching the Cat
  through its patch functions (no edit to `cat.gd`); the shut nap on `car_shut_seconds` 20 s, then the Elevator's
  `open_hatch {floor}`;
- the real Elevator (two stops) in the Cat station.

Behaviour lines (`docs/migration/m4-lists/12-cat-and-litterbox.md`, by `cat.md`'s heading letters): C1, C2, C3, C4 (the Cat's side; the carry rule and the refusal words are core/155-157's).

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
No data of its own (`CatTuning.car_shut_seconds`); the car is a place by the group contract.

## Acceptance
- Real path: the player clicks the other stop's call button with the Cat asleep in the car; at the arrival the Cat the
  player sees wakes there and hops out; the player's Space at the car reads "Elevator full" while it is inside.
- With the car open and empty the Cat naps in it; a call where it lies wakes it; the hatch shut on it at its stop: after
  20 s the hatch opens by itself and it walks out.
- While riding or shut in it cannot be petted or picked; set down or thrown into the open car it stays in.
- A load mid-ride keeps it in the car; a Guest sees it ride.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- Every carried thing rides by one rule; the Cat is cargo (Q2699, 2026-11-26).

## Open follow-ups
