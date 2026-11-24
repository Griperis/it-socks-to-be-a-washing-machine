---
type: ticket
status: ready-for-agent
kind: design
area: core
feature: frame
priority: now
created: 2026-11-24
done:
blocked_by: []
notes: ["suggested model: opus", "batch A (Q2606, Q2614)"]
terms: [Laundry day, Laundry bin, Final wash, Stage]
---

# Batch A: the First wash, the Laundry day and the Final screen (design)

The run's opening and ending (M4). Batch A's run ends after the fourth Stage (Q2615: the Drum finale is batch D).
A design ticket: findings and a proposal, no game code.

## Step 1: findings
By examination of `reference/it-socks` and `digest-progression.md` section 2 (and wherever the Laundry day is):
the First wash (B21: New Game starts with the washer breaking and spitting out the Socks; the designer's 2026-11-13
order of it), the Laundry day (B22: prefilled Laundry bins in the house, `bins_per_world`, each bin loading the washer,
the Final wash), the Laundry bin itself (B33: carried, controls, rotation kept, hand-off refused), the Final screen
(B23: every Pair and piece, who unlocked what, Continue to the Lobby; P36 its leftovers), and what the Lobby offers
after an ending (core/61's [later] L6). Dirty Socks stay off. Write `docs/migration/m4-lists/04-first-wash-and-laundry-day.md`
in the shape of `02-lobby.md`: every line, motion, pop and sound (Q2277), old file:line; what was weak.

## Step 2: proposal (stop for the designer)
`docs/architecture/run-ends.md`: the First wash and the Final wash as sequences that hook into core/71's Stage seams
and core/73's washer and voice lines (name the line triggers they fire, do not design the voices); the Laundry bin as
an entity (behaviour plus Looks) on the Hands; the Final screen as a scene on the Theme; Coins and rewards only as far
as Q2610 and Q2612 settle them (progression itself is batch B). Read core/71's ticket for its seams.

## How the proposal is shaped (Q2603, Q2604, Q2607)
Batch A is built unattended after the designer approves the proposals in one sitting, then reviewed in play as a
whole (Q2603, Q2605). So the proposal must leave no open choice for the build: every design uncertainty is a
choice below, and every piece says **how it is authored**: what is a typed Resource edited in the inspector, what a
designer adds by dropping a file or a Resource with no code change, and which zoo station shows it (built from the
data at load, Q2337). Where the old game was weak, say so and propose the fix as a choice, the old way as one option.
A detail the old game settles is ported as it was (Q2277); a detail it does not settle is a choice here, not left to
the build (Q2604 is only the fallback).

## Acceptance
- The behaviour list and the proposal exist; every old detail is listed or named as dropped with its Q.
- The build is split into tickets of one mergeable piece each, in the most efficient build order, each with its real-path case named; written as `ready-for-agent` drafts in the proposal (the lead files them).
- The choices are `[blocking]` Open follow-ups here, 2-3 options each with a recommendation; `docs/migration/decisions.md` read first, nothing answered asked again.
- No game code changed.

## Open follow-ups

## Built log
