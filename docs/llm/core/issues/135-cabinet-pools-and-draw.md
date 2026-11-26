---
type: ticket
status: done
kind: build
area: core
feature: gifts
priority: now
created: 2026-11-26
done:
blocked_by: ["[[125-collections-as-data]]"]
notes: ["batch B (Q2614); order: docs/migration/milestones.md Batch B, wave 2", "suggested model: sonnet"]
terms: [Cabinet, Cabinet pool, Unlocked Collection, New Game, Stage]
suites: [stages, stage_socks, cabinet, cabinet_growth, cabinet_looks, house, save, coop_join, sock_generator]
---

# Cabinet pools and the New Game's draw

Each New Game draws which Collection stands at each Cabinet from its room's pool, among the Host's unlocked ones (batch
A kept the placed Collections, Q2618). Build `docs/architecture/gifts.md` "The New Game's draw (pools)":

- `Cabinet.pool: Array[StringName]` (an export on each placed Cabinet; empty keeps its placed `collection`, as every zoo
  station does); the house's eight get the old room pools in `house.tscn`.
- `CabinetDraw` (rules only): one unlocked, not held-back Collection per spot, never one twice, the shared pools solved
  by backtracking (the old `CPO:193-262`); `problems()` names why a draw cannot fill them.
- The draw runs first in `Stages.start` with the Host's profile's unlocked Collections (core/127's field when present,
  else `CollectionUnlocks.start`) and the World's seed; each Cabinet's `collection` patch is in the same answer before
  the Stage's Designs are chosen; an unfillable draw logs the reason and keeps the placed Collections.
- A Cabinet whose `collection` changes in an answer swaps its Looks (`dress()`, today run only at ready) and its
  drawer prompt follows.
- Pools on the Stages station's mini run's two Cabinets and a "New run" switch there if it has none.

Behaviour lines (`docs/migration/m4-lists/07-gifts-and-collections.md`): "Collections unlocking", the pool and draw
lines (the Grotto's pool is not ported, Q2599; the Lost Socks are in no pool, Q2675).

Batch B is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-b-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
The pools are edited on the placed Cabinets in the editor (the spot is the Cabinet): no JSON keyed by spot.

## Acceptance
- Real path: in the Stages station a click on the mini run's New run switch gives Cabinet B one of its pool's unlocked
  Collections; its Looks and drawer prompt follow, and Stage 1's Socks are of the drawn Collections only.
- The house's draw with the start set fills all eight spots, never one Collection twice, with the same seed giving the
  same draw; a save and a join keep it.
- Placeholders: none.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- In batch A each Cabinet spot kept its placed Collection; the room pools come with batch B's unlocking (Q2618,
  2026-11-24).
- The Lost Socks are left out of the start set and presents until the Drum (Q2675, 2026-11-25).

## Open follow-ups
- [later] The draw reads `CollectionUnlocks.start` (`Stages.unlocked_collections()`) until core/127 has its profile field: that function is the one place to switch to the Host profile set.
- [later] The station New run empties the Cabinets but Socks already in the Mess stay (shelved ones are not removed): a zoo-only seam; a Mess verb to clear them would fix it.
- Stages gets `draw_first_start` (the Stages station sets it off so its hand-laid Socks stay for the placed Collections; the house draws at its first start).
