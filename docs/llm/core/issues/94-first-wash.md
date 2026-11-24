---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: laundry
priority: now
created: 2026-11-24
done:
blocked_by: [core/77, core/87, core/88, core/89, core/93]
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: opus"]
terms: [First wash, Laundry bin, Stage]
---

# The First wash

A New Game's opening: build `docs/architecture/run-ends.md` "The First wash": the held first-Stage Socks (`LaundryDay.wants_first_wash()` now true, so a New Game
holds core/77's records; no `house.tscn` change), `LaundryDay.first_wash`, a carried full bin used on the washer while PENDING
starts it (any of the World's bins; refused only while busy), `first_wash.tres` on the frame (calm wash, break,
cutscene_1, the spray with the door's swing, fade), the respawn, the bin still full in the Hands, once per World, a
late joiner seeing the end state, cutscenes off in tests and the zoo; the washer fine and silent until it breaks (the
`broken` read for core/86 and core/87, Q2636); the bar's goal phase until DONE (Q2625).

Behaviour lines (`docs/migration/m4-lists/04-first-wash-and-laundry-day.md`): "A New Game before the First wash" (the lines not marked B or C), "The First wash" (the
lines not marked B or C); `docs/migration/m4-lists/05-washer-and-voices.md` "What the face rig carries for others": the wash, door and bubbles lines.

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

`FirstWashTuning` (`wash_seconds` 3.0, `bubbles` 40), placeholders; the sequence is `first_wash.tres` (beats as
data). The Laundry station's "First wash" pillar resets it and holds a few Socks.

## Acceptance
- Real path: a New Game in the house: no Socks lie and the bar reads "Wash the laundry"; the player clicks the bin into the washing machine; the cutscene plays; after it the Mess count is the first Stage's, the bin is still full in the Hands, the bar shows Stage 1, and a second bin is refused "Fix the washing machine first".
- Before it the washer shows no damage and makes no comment; after it, the angriest.
- It never plays again in that World (saved); a Guest joining mid-cutscene sees the end state.
- Placeholders: `FirstWashTuning`.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The spray is decoration; the Socks lie in their usual places (Q2626, 2026-11-24).
- The goal line "Wash the laundry" until the First wash (Q2625, 2026-11-24).
- The washer is silent until the First wash breaks it (Q2636, 2026-11-24).

## Open follow-ups

## Built log
