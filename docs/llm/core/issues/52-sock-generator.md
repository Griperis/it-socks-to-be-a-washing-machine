---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: mess
priority: now
created: 2026-11-23
done:
blocked_by: []
notes: ["designer, 2026-11-23: port the old Sock generator; authorable with a viewport preview of where Socks can land"]
terms: [Mess, Sock, Pair, Design]
---

# The Sock generator, ported, with a viewport preview of where Socks land

The designer wants the old game's generator of a floor's starting Mess ported and prepared, and authorable: a level
designer sees in the editor viewport where Socks can land, and tweaks it there.

## Step 1: the behaviour list (stop for the designer's approval)
Find the old generator in `reference/it-socks` (start from `game/campaign/` (Campaign.stage_designs(),
`laundry.gd` designs_for_floor()), `game/house/flat_layout.gd` (surfaces(), the layout's rooms and floors),
`game/house/house_parts.gd` (the furniture's resting tops, house/16), `game/world/sock_world.gd` and the old tuning).
Write `docs/migration/m06-lists/05-sock-generator.md` in the shape of lists 03 and 04: how many Socks and Pairs a
floor gets, which Designs, where they may land (floors, furniture tops, exclusions, distance from walls and doors,
spacing), the seed, how they appear (at rest, poured, dropped), what a late joiner gets, every motion and sound
(Q2277). Mark the open choices as questions. Stop and report: the lead takes the list to the designer.

## Step 2: build (after the list's approval)
- The generator in the Mess's code, typed Resource for its numbers, deterministic from a seed; the Host runs it, the
  Mess syncs the result as usual.
- Authoring: `@tool` nodes a level designer places, e.g. a `SockArea` (a box or a floor polygon, a weight, Designs or a
  share) and a `SockExclusion`, with a typed Resource for the floor's counts. In the editor each area draws itself
  (a translucent volume) and a preview of the landing points it would make with the current seed (dots or small
  Sock shapes on the surfaces under it, found by the editor's own physics or the mesh), redrawn when the area, the
  numbers or the seed change. Nothing of the preview runs in a game build.
- A zoo station `game/zoo/stations/sock_generator.tscn` with a few areas on the floor and furniture tops, and a
  button to regenerate with a new seed.

## Acceptance
- Real path: the station's areas generate their Socks at start; they lie where the preview showed (the same seed,
  every landing point inside an area and on a surface, none inside an exclusion, a wall or another Sock).
- The same seed makes the same Mess on Host and Guest; a late joiner sees it.
- Stills for the designer: the editor viewport with areas and the preview (`builds/review-sock-generator/`), and the
  game view of the same station after generation.
