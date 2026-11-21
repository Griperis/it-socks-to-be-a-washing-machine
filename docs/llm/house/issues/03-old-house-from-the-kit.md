---
type: ticket
status: ready-for-human
kind: build
area: house
feature: house
priority: now
created: 2026-11-20
done:
blocked_by: ["[[02-kit-for-the-old-house]]"]
notes: []
terms: []
---

# The old house rebuilt from the kit

M2. The proof that the kit builds the old house nearly identically (Q2345): the whole old house, four floors
(basement, ground, first, attic), built in the editor only from house/02's kit pieces, on house/02's re-gridded plan.
Shell only: walkable in first person, no functions, no furniture (Q2155, Q2157).

## Behaviour list
House/02's plan (`docs/architecture/house-kit-plan.md`) and kit are approved (Q2350-Q2358, Q2380).
- B01 The house scene holds every room, partition, doorway, window, the U stair, the elevator shaft's opening, the
  front and garage door openings, the basement wells and the roof with its dormer, at the plan's grid numbers, each
  built from kit pieces only (no hand-made mesh).
- B02 Each room has the old house's materials on its floor, ceiling and walls' inside faces; the outside has the old
  render.
- B03 The player walks in the front door, through every floor's rooms, and climbs from the basement to the attic.
- B05 It is built twice from the same plan: house A with the old-width windows, house B with the windows rounded to
  0.5 m (Q2381), so the two can be compared; the goal is the old house rebuilt with this kit.
- B06 Both houses stand beside the zoo as stations (`game/zoo/stations/old_house_a.tscn`, `old_house_b.tscn`, each
  instanced in `zoo.tscn` on its own ground off the zoo floor's edge, the house kit station's way); the player walks
  over from the zoo and in at the front door (Q2386).
- B04 Seen from the old looks-baseline views, the shell matches the old house (stills side by side); every difference
  is listed for the designer.

## Acceptance
- The real-path case: the player walks from the front door to the attic by its own input.
- Stills from the baseline views, old beside new, in `builds/review-house-03/`, for the designer's go.

## Answers
- Built twice, A (old widths) and B (rounded) (Q2381); both stand beside the zoo as stations (Q2386) (2026-11-21).
- The whole house is rebuilt as the kit's proof (Q2345, 2026-11-20).

## Open follow-ups
- [blocking] `mess:m04_every_sock` fails: the zoo must keep under 8,000 nodes and now has 11,309; each
  house station is about 2,050 nodes (a kit piece is a mesh, a body and its boxes; ~600 pieces a
  house), so even one house goes over. Not raised by the agent (a budget). Raise the zoo's budget,
  count only the Mess's nodes in m04, or keep the old houses out of the zoo (their own scene)?
- [blocking] The designer's go on the stills in `builds/review-house-03/` (`side-<view>.png`: old | A | B,
  21 views). Differences seen, each for the designer: shell only (no furniture, lamps, rugs, room doors,
  elevator); the zoo's noon light (old: 9:08, lamps on); a flat lawn at the ground floor's height (old:
  0.3 m lower with plinth, front step, fences, trees, street), wells without concrete walls or grates,
  the garage ramp a plain slope; no bathroom tile wainscot (a skin in the old shell, no kit piece); the
  elevator shaft an open hole in the ground, first and attic floors; the plan's moves (first riser
  +0.25 m, 3.0 m storeys, 40 deg roof); small orange marks on the south slope seen from the front (also
  in the old still); the station's name label floats over the house in the exterior views.
- [later] Kit fixes made here (the lead's to confirm, they change approved pieces by 1 cm): the shaft
  hole runs 0.01 m into the x 4 partition (its side lay in the partition's face, K14); the attic
  balustrade's north rail stands 0.01 m back from the void (its foot lay in the floor tile's edge, K14).
- [later] Two pieces added (`corner_exterior_open`, `door_partition_offset_hatch_2m`): the plan's W15
  piece runs into the SW corner's arm, and D8's and the hatch's pieces overlap on the first floor's x 4
  partition. `tools/house_plan.py`'s piece list does not name them yet.

## Built log
- 2026-11-21 (agent). Changed: both houses built from kit pieces only by `tools/old_house_build.gd` at
  the plan's new numbers, painted per room (old materials), on their own ground east of the zoo floor
  (A at x 23, B at x 50, z -10); two kit pieces added, two 1 cm K14 fixes; `old_house` shot action and
  the `old-house` set; stills old | A | B. Files: game/zoo/stations/old_house_a.tscn, old_house_b.tscn,
  game/zoo/zoo.tscn, tools/old_house_build.gd, tests/old_house_test.gd, game/house/kit/ (build script,
  sizes, 2 new pieces, shaft tiles, balustrade), tools/shot_hooks.gd, tools/shots/sets/old-house.txt,
  docs/architecture/house-kit.md. Verified: --touched FAIL 1 of 8752 checks, 146 cases (only m04, above); old_house 9 cases incl. the
  real paths front door to attic (A) and basement out of the front door (B), K14 on both houses.
- Model: Opus (lead): a large hand-built scene from many pieces, on the approved plan.
