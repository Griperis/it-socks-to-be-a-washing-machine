---
type: ticket
status: ready-for-agent
kind: build
area: house
feature: house
priority: now
created: 2026-11-21
done:
blocked_by: []
notes: []
terms: []
---

# The old house's shell details the kit still lacks

From house/03's comparison with the old house (Q2391, 2026-11-21; `builds/review-house-03/side-*.png`). Each is a kit
piece or a fix, ported from `reference/it-socks/tools/blender/make_house.py` and `make_exterior.py`; shaped and asked
before it is built.

## Behaviour list (draft)
- D01 The bathroom's tile wainscot (a skin in the old shell; a kit piece or a wall face material).
- D02 The basement light wells: concrete walls and grates outside the well windows.
- D03 The plinth: the house stands 0.3 m over the lawn on a plinth, as the old house did.
- D04 The front step at the front door.
- D05 Fences, trees and the street around the house (the old exterior; may become its own asset ticket).
- D06 The garage ramp as the old one, not a plain slope.
- D07 The elevator shaft: walls and floor lips instead of an open hole on the ground, first and attic floors (the
  elevator itself is an entity, M5).
- D08 The station's name label no longer floats over the house in exterior views.
- D09 The small orange marks on the south roof slope seen from the front (also in the old still): explained or fixed.

## Design
The house is the game's own scene, not a zoo station (Q2503). Shell and furniture only: no game functions in it yet (M3 brings the core loop into the house). Rooms, windows and doors as house B has them on the 0.5 m grid (house/02, house/03).

## Acceptance
- `game/house/house.tscn`: house B moved out of the zoo into its own playable scene, built only from the kit's pieces, with the player and the shared-state path set up as in the zoo (a Host of one; `--host` and `--join` work there too). It becomes the project's main scene (F5 and a plain launch start in the house); the zoo stays playable with `-- --zoo` and by running `zoo.tscn` in the editor.
- `old_house_a.tscn` and its zoo instance are removed; `old_house_b.tscn` goes from the zoo too once `house.tscn` holds it.
- The shell details, the house only: the bathroom's tile wainscot (D01), the plinth (D03) and the front step (D04) so the front door is reachable, the garage ramp as old (D06), the elevator shaft's walls and floor lips (D07), the orange marks on the south roof explained or fixed (D09). D08 goes with the move out of the zoo. Out (Q2503): fences, trees, the street and the basement light wells (D02, D05).
- The ported furniture (assets/04) placed where the old house had it (from `reference/it-socks/tools/layout.py`), so Play walks through a furnished house, as M2's "done when" says.
- Walkable in first person on every floor, stairs included; a test walks the player from the front door to every floor.
- A strip in `builds/review-house-04/`: each floor, old beside new, and the front.

## Answers
- Q2503 (2026-11-23): the house only, no exterior; keep house B (windows on the 0.5 m grid), remove house A; the house becomes a main scene launched from the game, built from the kit pieces.
- Q2504 (2026-11-23): built to the end with no stop at the first still; a before and after strip for the designer's batch review before the merge.

## Open follow-ups

## Built log
