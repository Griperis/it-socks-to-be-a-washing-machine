---
type: ticket
status: needs-triage
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
Draft; finished when house/02's plan is approved.
- B01 The house scene holds every room, partition, doorway, window, the U stair, the elevator shaft's opening, the
  front and garage door openings, the basement wells and the roof with its dormer, at the plan's grid numbers, each
  built from kit pieces only (no hand-made mesh).
- B02 Each room has the old house's materials on its floor, ceiling and walls' inside faces; the outside has the old
  render.
- B03 The player walks in the front door, through every floor's rooms, and climbs from the basement to the attic.
- B04 Seen from the old looks-baseline views, the shell matches the old house (stills side by side); every difference
  is listed for the designer.

## Acceptance
- The real-path case: the player walks from the front door to the attic by its own input.
- Stills from the baseline views, old beside new, in `builds/review-house-03/`, for the designer's go.

## Answers
- The whole house is rebuilt as the kit's proof (Q2345, 2026-11-20).

## Open follow-ups
- [blocking] Where the house scene lives (its own scene under `game/house/`, or a zoo station) and whether the main
  scene starts in it: decided when the ticket is shaped after house/02's plan.

## Built log
