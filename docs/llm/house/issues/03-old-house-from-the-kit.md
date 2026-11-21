---
type: ticket
status: done
kind: build
area: house
feature: house
priority: now
created: 2026-11-20
done: 2026-11-21
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
- The designer's go on both houses from the stills in `builds/review-house-03/` (Q2391, 2026-11-21).
- `mess:m04_every_sock` counts only the Mess's own nodes (the zoo's Socks, its lying and flying Socks)
  and keeps its 8,000 budget (Q2392, 2026-11-21).
- Both 1 cm K14 fixes (the shaft hole into the x 4 partition, the balustrade's north rail back from the
  void) and both new pieces (`corner_exterior_open`, `door_partition_offset_hatch_2m`) stay; the pieces
  are in `tools/house_plan.py`'s list (Q2393, 2026-11-21).

## Open follow-ups
- [later] The bathroom's tile wainscot to 1.2 m (a skin in the old shell) has no kit piece: its walls are plain paint.
- [later] The light wells are holes in the lawn with a gravel floor: no concrete walls, no grates.
- [later] No plinth band round the house; the lawn is at the ground floor's height (old: 0.3 m lower).
- [later] No front step at the front door (only a flat threshold).
- [later] No fences, trees, neighbours' houses or street round the stations.
- [later] The garage ramp is one plain slope: no retaining walls, kerbs or posts.
- [later] The elevator shaft is an open hole in the ground, first and attic floors until the elevator stands in it.
- [later] The station's name label floats over the house in the exterior views.
- [later] Small orange marks on the south roof slope seen from the front (also in the old still): to be looked at.

## Built log
- 2026-11-21 (agent). Changed: both houses built from kit pieces only by `tools/old_house_build.gd` at
  the plan's new numbers, painted per room (old materials), on their own ground east of the zoo floor
  (A at x 23, B at x 50, z -10); two kit pieces added, two 1 cm K14 fixes; `old_house` shot action and
  the `old-house` set; stills old | A | B. Files: game/zoo/stations/old_house_a.tscn, old_house_b.tscn,
  game/zoo/zoo.tscn, tools/old_house_build.gd, tests/old_house_test.gd, game/house/kit/ (build script,
  sizes, 2 new pieces, shaft tiles, balustrade), tools/shot_hooks.gd, tools/shots/sets/old-house.txt,
  docs/architecture/house-kit.md. Verified: --touched FAIL 1 of 8752 checks, 146 cases (only m04, above); old_house 9 cases incl. the
  real paths front door to attic (A) and basement out of the front door (B), K14 on both houses.
- 2026-11-21 (agent). Changed: m04 counts the Mess's own nodes (Q2392); the two new pieces in
  `tools/house_plan.py`'s list and the plan (Q2393); answers and follow-ups in. Files: tests/mess_test.gd,
  tools/house_plan.py, docs/architecture/house-kit-plan.md, this ticket. Verified: PASS 8752 checks, 146 cases (--touched).
- Model: Opus (lead): a large hand-built scene from many pieces, on the approved plan.
- Merged: a452c29d (2026-11-21, branch house/03-old-house-from-the-kit)
