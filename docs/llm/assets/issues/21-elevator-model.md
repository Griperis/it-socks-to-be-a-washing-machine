---
type: ticket
status: ready-for-human
kind: build
area: assets
feature: assets
priority: now
created: 2026-11-26
done:
blocked_by: []
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 1", "suggested model: opus"]
terms: [Elevator]
suites: [menus]        # menus l02: every new file under assets/ needs a credits entry
---

# The Elevator's model

The old Elevator (`tools/blender/make_elevator.py`, `assets/house/elevator.glb`) ported by the asset port rules as the
game's `tools/blender/elevator.py` (the Blender skill): the stainless car with its caged brass lamp (a `lamp` node kept
for the later Elevator Duet), the hatch and its frame, the brass call button, and, now modelled parts where the old
built them in code, the floor letters with their rings and the "OUT OF ORDER" plaque and the padlock sign (Q2705).
Fitted to the port's shaft and hatch (house-kit-plan K09: 0.7 x 0.7 m, hatch 0.54 x 0.58 at sill 0.8 m). Looks scenes
for the car and the stop, meeting the contract `docs/architecture/elevator.md` "How it is authored" names (core/155
writes `game/entities/elevator/looks_contract.json`; if this ticket runs first it builds to the doc's list and checks
against the file once it lands).

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Ported by examination, technical improvements only (origins, scale, names, collision, shared materials, file
size; Q2153); a look change is its own ticket.

## How it is authored
The generator script under `assets_src/generate/elevator/` and its `assets/blender_assets.json` entry; the shared
materials (Q2177); the stop's clips (`open`, `shut`, `out_of_order`, `repaired`, `locked`, `unlock`, `press`) and the
letters' (`lit`, `dark`, `locked`) keyed in the Looks.

## Acceptance
- Look work: the before-and-after strip (the old beside the port, the same views) in
  `<main checkout>/builds/review-elevator/`; `status: ready-for-human`; stops at its first line-up for the designer's go
  (the `review-material` skill).
- `python3 kit/tools/asset_lint.py` passes on its Looks scene; its Looks meets the entity's `looks_contract.json`.
- On the designer's yes (not before): `game/entities/elevator/elevator.tscn` and `elevator_stop.tscn` point their Looks at these scenes; the graybox goes.
- No real-path case (a look ticket, Q2421).

## Answers
- Batch C's models are ported from the old game by the port rules, each family with its strip and the old colours (Q2705, 2026-11-26).
- The letters and the plaque as modelled parts (Q2705, 2026-11-26).

## Open follow-ups
- [blocking] The designer's look at the first line-up (stops here, Q2603 batch C's look rule):
  `builds/review-elevator/elevator-old-vs-port.png` (Blender EEVEE; pairs old | port: the stop shut and out of order,
  open with the car standing there, the call button, the column locked with the padlock sign, inside the car (the
  floor letters: B plain, G lit, 1 locked, A plain; the old drew them in code, so its tile is a bare wall), the caged
  lamp). Single tiles in `builds/review-elevator/tiles/`. The port's shaft wall and sill in the tiles are a stand-in
  of the house kit's (not this model). Go or changes?
- [later] Left for after the designer's yes: the Looks scenes (`elevator_car`, `elevator_stop`, `elevator_letter`
  with the signs) built on these glbs to `game/entities/elevator/looks_contract.json` once core/155 lands (it is
  not on main yet), their clips (`open`, `shut`, `out_of_order`, `repaired`, `locked`, `unlock`, `press`; `lit`,
  `dark`, `locked`), `asset_lint` on them, and `elevator.tscn` / `elevator_stop.tscn` pointed at them.
- [later] The ticket names the script both `tools/blender/elevator.py` and "under `assets_src/generate/elevator/`":
  it is `tools/blender/elevator.py`, as the other single-asset ports (laundry bin, book, Wardrobe Station), listed in
  `assets_src/generate/README.md`.
