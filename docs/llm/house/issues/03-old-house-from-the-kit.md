---
type: ticket
status: ready-for-agent
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

## Built log
- Model: Opus (lead): a large hand-built scene from many pieces, on the approved plan.
