---
type: ticket
status: in-progress
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

## Answers
- The behaviour list (`docs/migration/m06-lists/05-sock-generator.md`) answered by Q2518-Q2528 (designer, 2026-11-23); fold
  them into its lines and header, then build Step 2 to them, overriding the Step 2 sketch above where they differ:
  - Q2518 one `SockArea` box over a room or floor finds every landing place under it (open floor, tops, insides,
    under-gaps), tinted by kind in the viewport; furniture under it joins automatically.
  - Q2519 furniture brings its own places (`Spots/Top<n>`, `Inside`, the crawl gap).
  - Q2520 one Pair count per area, split by place size x a weight per kind; a piece may override its weight; no pins.
  - Q2521 rarity does not decide hiding; hidden share one number on the area, 0.3 by default.
  - Q2522 the preview: dots tinted by kind. Q2523 Socks appear lying where the preview showed, no fall, no sound
    (the Mess gains an add of lying records).
  - Q2524 the level's seed by default, a switch for a new seed each New Game saved with the game.
  - Q2525 mates 0.4-6 m apart in a straight line (improving it: core/53).
  - Q2526 "heap" as an area option (the old roll-down); otherwise flat, spaced, never overlapping.
  - Q2527 exclusions: the old rules as numbers on the area plus `SockExclusion` boxes.
  - Q2528 now: under-edge strips, thinning from a washer marker, the stair trail; doors shut at a New Game only once
    the house has room doors (it has none yet: a [later] line, not built here). The rest parked with their feature.
  - The Host generates and sends the rows (the old rule, Q839; only the Host's answer writes state).
- Rest computed by rays and overlap tests in the editor's and the game's physics space (no physics step), so the
  preview and the game agree; the full old shape-cast stacking is not ported (Finding 5).

## Open follow-ups

## Built log
- 2026-11-23
  - Changed: Step 1 only. The old generator is `SockLayout` (`game/world/sock_layout.gd`, `bake()` for a New Game,
    `spawn()` for a stage) with `mess.json` "spill", `stages.json` and `HouseParts.tops()`; written up as 83 behaviour
    lines with refs, invariants, numbers, what the port already has, findings for the rework and 12 questions.
  - Files: docs/migration/m06-lists/05-sock-generator.md, docs/llm/core/issues/52-sock-generator.md
  - Verified: docs only (agent_finish --no-test).
