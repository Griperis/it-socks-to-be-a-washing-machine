---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: laundry
priority: now
created: 2026-11-24
done:
blocked_by: [core/82, core/86, core/90, core/91]
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: sonnet"]
terms: [Laundry day, Laundry bin, Final wash]
---

# The Laundry day

After the last Fix the bins load the machine: build `docs/architecture/run-ends.md` "The Laundry bins": the draw, and "The Laundry day":
the bins placed in `house.tscn` under `LaundryBins` at the seven old spots (the one by the washer `always`), the draw
at a New Game from the World's seed (`bins_per_world`, clamped), the `LaundryDay` Part (`load` and its refusals in
order, `loaded`, the pile through `WasherLooks.pile`, the ending's wait counted down by the Host and saved), the use of
the washer with a carried bin ("[LMB] Load the washing machine" after the last Fix), `socks_pour` at the porthole,
`LaundryDay` as the bar's `laundry_bins` provider, and the washer's Laundry day comment set (Q2635). The Final wash
itself is core/96 (here the wait ends in a stub the station shows).

Behaviour lines (`docs/migration/m4-lists/04-first-wash-and-laundry-day.md`): "The Laundry bins": the spots and the draw; "The Laundry day" (all); "Words and sounds".

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

A bin spot is an instance placed in `house.tscn` (a new spot is a new instance, no code); `LaundryTuning`
placeholders. The Laundry station gets "Last Fix done" and "Final wash" (all but one loaded) pillars and a
`loaded/total` label.

## Acceptance
- Real path: in the house with the last Fix set by the zoo knob, the player carries a bin to the washing machine and clicks: the bar reads "Wash clothes 1/3", the bin is empty in the Hands, a second click is refused "That bin is empty".
- Before the last Fix a bin is refused "Fix the washing machine first"; during the wait "The washing machine is busy".
- Every machine draws the same bins from the seed; saved and in the join snapshot (loaded bins, pile, the wait).
- Reachable in the main scene. Placeholders: `LaundryTuning`, the seven spots (judged by eye in the review).
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The bins stand full from the New Game, refused until the last Fix (Q2624, 2026-11-24).
- Loading stays as the old: no Socks seen going in (Q2627, 2026-11-24).
- The Laundry day's comment set, Stage 4's by default (Q2635, 2026-11-24).

## Open follow-ups

## Built log
