---
type: ticket
status: done
kind: build
area: core
feature: hands
priority: now
created: 2026-11-24
done: 2026-11-25
blocked_by: []
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: sonnet"]
terms: [Hands, Part, Laundry bin, Teammate]
---

# Carried things in the Hands

One seam for every thing that takes the whole Hands: core/71's Machine Parts and core/72's Laundry bin (the two
drafts merged here). A `Carriable` comes into empty Hands only and takes them whole (no Sock, Pair or Guide card
comes in, "Hands full"); it rides a hold slot from a typed `HoldSlot` Resource (body frame, `at`, going down with
Crouch), steady at the drawn camera (it follows the drawn camera, not the physics tick); right click puts it down
where the crosshair may drop, at the yaw it was held ("Can't drop there" otherwise), or aimed at a Teammate into
their empty Hands (else at their feet, they read "Hands full"); a leaver lays it where they stood; a load lays a
carried one where it was last laid. `Hands.carries()`; `Carriable.handable` (core/42's Hand-off: off for the bin, on
for a Part). Design: `docs/architecture/stages.md` "Shared seam with core/72", `docs/architecture/run-ends.md` "Carrying".

Behaviour lines: `docs/migration/m4-lists/04-first-wash-and-laundry-day.md` "The Laundry bins": the pick, carry, right-click, Teammate, leaver and load lines; `docs/migration/m4-lists/03-stages-and-floors.md` "A
Stage completes": the carry and right-click lines.

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

`HoldSlot` Resources (one per kind of carried thing; the bin's from the old `hold.json` `bin`: 0.45 m up, 0.72 m
ahead); the Handling station gets a stand-in crate with a `Carriable` and its slot.

## Acceptance
- Real path: in the Handling station the player left-clicks the stand-in crate, walks, and right-clicks the floor: it lies at the crosshair turned as it was held; a Guest sees it lying there.
- With the crate carried a Sock click is refused "Hands full"; right click at a Teammate with empty Hands puts it in theirs, with full Hands at their feet.
- The carried thing does not slow its carrier (the bin, Q2628).
- A leaver's carried thing lies where they stood; a save and load lays it where it was last laid.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- A carried bin does not slow its carrier (Q2628, 2026-11-24).

## Open follow-ups

## Built log

### 2026-11-25
- Changed: a `Carriable` takes the whole Hands: picked by the left click into empty Hands only ("Hands full"
  otherwise; while carried a Sock pick is refused and a Sock handed or caught lies at the carrier's feet). Every
  machine draws it at its carrier's `HoldSlot` (body frame, down with Crouch to 0.25 m, the drawn body); the right
  click lays it at the crosshair at the turn it was held ("Can't drop there" by the drop's place check), its Looks
  easing from the Hands (the shared put); aimed at a Teammate (`handable`) into their empty Hands, else at their feet
  with "Hands full" for them; a leaver lays it where they stood; a load where it last lay. No slow walk. Corner
  "Drop", crosshair name. Stand-in crate on the Handling station. `Hands.loaded()` no longer errors on an int key.
- Files: game/parts/carriable.gd, game/hands/hold_slot.gd, game/hands/hold_slot_bin.tres, game/hands/hands.gd,
  game/player/player.gd, game/ui/prompts.gd, game/zoo/handling/crate.tscn, game/zoo/stations/handling.tscn,
  tests/carry_test.gd, tests/coop_carry_test.gd
- Verified: `kit/tools/run.sh --touched` (agent_finish's run, PASS); carry 43 checks, coop_carry 16 checks.
- Merged: 1688c2ec (2026-11-25, branch core/78-carried-things-in-the-hands)
