---
type: ticket
status: done
kind: build
area: core
feature: house
priority: now
created: 2026-11-26
done: 2026-11-27
blocked_by: ["[[154-batch-c-groundwork]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 2", "suggested model: opus"]
terms: [Elevator, Upgrade, Elevator Repair, Stage]
suites: [elevator, save, upgrades, stages, floor_lock, furniture, room_doors, house]
---

# The Elevator: the car, calls, hatches, locks and out of order

The house's Elevator as one entity and one Part: the car stands at a floor, a click on a stop's brass call button or
its shut hatch brings it, the hatch slides shut, the car is drawn at the bound floor (no car is seen moving, Q2702) and
the hatch there opens with the bell; out of order until Elevator Repair is bought, locked until the ground floor opens,
then open floors only. Build `docs/architecture/elevator.md` "The shape", "Its verbs" (`call`, `hatch`, `depart`,
`arrive`, `open_hatch`), "Locked and out of order", "How it is authored", draft 149-A:

- `elevator.tscn` with graybox Looks and `looks_contract.json`, `elevator_stop.tscn` (one per floor, placed by hand),
  `elevator_letter.tscn` (the letters' column on the car's +z wall built from the stops, B at the bottom, with its
  `lit`, `dark`, `locked` clips; sending from them is core/157);
- the `Elevator` Part with every State field of the doc (riders empty for now, so `tests/saves/shape.json` changes
  once);
- the group `elevator_cargo`'s calls (`rides_patch` at `depart`, `called_patch` at `call`, `car_opened` after
  `arrive`, `fills_car` for core/157's `climb_in`) with no member yet (core/156 adds the Mess and `Carriable`);
- `ElevatorControl` (BUTTON, HATCH, LETTER), `Openable`'s small `driven` export, `keeps_open_on_load` on the hatches;
- `ElevatorTuning` (`hatch_time` 0.5, `floor_time` 2.0, `creak_every` 0.7, `reach` 1.6, `seats` 2, `exit_gap` 0.8,
  `eye_height` 0.3) and the stats `elevator_repair` (FLAG) and `elevator_floor_time` (SCALE_DOWN, base 1, step 0.25,
  least 0.1, "%.1f s" of 2 s) set on `elevator_repair.tres` and `fast_elevator.tres` (no longer "Coming soon");
- the bell, the creak at the shaft every 0.7 s along the ride, the hatch sounds, the button's click from the answer
  (the SoundEvents are core/154's);
- placed in the Elevator slot `game/house/systems/elevator.tscn` (core/154, Q2720; not `house.tscn`) at the shaft (house-kit-plan K09: inside x 3.24..3.94, z 4.8..5.5, a stop per floor);
- the Elevator station (shell from core/154 at x = 208): a two-storey shaft of house kit pieces with the real Elevator
  and two stops, a board of the stops, the tuning and the three Elevator Upgrades with their stat now -> top, a
  `SockGenerator` area and a Laundry bin by the lower hatch, its own `Run` mini plan with a locked upper floor and its
  own `Upgrades`, switches "Repair", "Open upper floor", "Fast Elevator +1", "Roomy Car +1".

Behaviour lines (`docs/migration/m4-lists/11-elevator.md`): "Where it is and what it is" (all 3); "Calling and
sending" lines 1-5 and 7-9 (the sill push of line 5 is core/156's, the letters' send core/157's); "Locked and out of
order" (all 5); "Things in the car" line 1 (the hatch and the car's colliders); "Sounds" (bell, creak, hatch, button;
no climb sound); "The Upgrades" Elevator Repair and Fast Elevator; "Words" (all but the riders'). Read the old
`ER:32-90` and `EL:99-148` before writing `call` (the doc's "Gotchas").

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
`ElevatorTuning` and the two stats are typed Resources edited in the inspector (`# placeholder:` the old
`data/tuning/elevator.json`); a stop is a dropped `elevator_stop.tscn` with its `floor` (the letters and the board are
built from the stops); the hatch, plaque, padlock and button motion are clips in the stop's Looks (`open`, `shut` keyed
on the AnimatableBody3D itself, `out_of_order`, `repaired`, `locked`, `unlock`, `press`, Q2697); the plaque is a modelled
part, not floating text (Q1350). No Control, mesh or material built in code (Q2658).

## Acceptance
- Real path: in the house from a New Game (stages on), the player's left click on the ground floor's call button reads
  "Out of order (needs the Elevator Repair upgrade)" and the plaque shows; after the real `buy` of Elevator Repair and
  the ground floor open, a click on the basement's button shuts the kitchen hatch (its clip, `hatch_close`), and after
  `hatch_time` + `floor_time` the basement hatch opens with the bell heard at that stop.
- A call while riding turns the car (the newest call wins, Q513); a click on the shut hatch where the car stands opens
  it; the button never shuts it (Q2702); the hatch at the car's floor opens and shuts on a click ("Open the hatch" /
  "Shut the hatch").
- A locked floor's stop shows its padlock and reads "Elevator locked"; its padlock plays `unlock` when the floor opens.
- Fast Elevator level 2 makes a floor 1.0 s; the Upgrade cards no longer read "Coming soon".
- Save mid-ride and load: the ride ends at its floor; a Guest's click waits for the answer and its button sound comes
  from it; a late Guest sees the car where it is and the hatches as they are.
- In the zoo (no `Stages`) the Elevator is never out of order and has no locked floor.
- Placeholders: `ElevatorTuning`, the stats' steps.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The Elevator as the old: no car seen moving; out of order until Elevator Repair and locked until the ground floor
  opens, then open floors only; empty at a New Game; the call button only opens a shut hatch; the letters on the car's
  side wall; the old placeholder sounds (Q2702, 2026-11-26).
- Models ported by the port rules, the letters and the plaque as modelled parts (Q2705, 2026-11-26).

## Open follow-ups
