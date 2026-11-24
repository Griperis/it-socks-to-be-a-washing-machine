---
type: ticket
status: done
kind: design
area: core
feature: frame
priority: now
created: 2026-11-24
done: 2026-11-24
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

## Answers
Answered in one sitting, 2026-11-24 (`docs/migration/decisions.md`); `docs/architecture/run-ends.md` is written to them.
- R1 The World's bins stand full in their rooms from the New Game, refused until the last Fix, as the old (Q2624, 2026-11-24).
- R2 Before the First wash a HUD goal line "Wash the laundry" stands in the Stage bar's place; the Guide card replaces it
  in batch C (Q2625, 2026-11-24).
- R3 The spray is decoration that vanishes; the first Stage's Socks lie in their usual places (Q2626, 2026-11-24).
- R4 Loading a bin stays as the old (no Socks seen going in); a visible pour is a later polish ticket, core/99
  (Q2627, 2026-11-24).
- R5 A carried bin does not slow its carrier (Q2628, 2026-11-24).
- R6 cutscene_6 plays whole, "You're alive!" included (Q2629, 2026-11-24).
- R7 The Final screen has a column only for the players in the game at the end (Q2630, 2026-11-24).
- R8 A finished World stays in the Lobby as a record ("Finished", play time), not continued; Start or New Game asks and
  replaces it (Q2631, 2026-11-24).
- R9 No "who did what" titles in batch A; asked again with batch B (Q2632, 2026-11-24).
- The two "for the lead" notes: the Cutscene frame is one ticket, core/88, and the carrying seam one, core/78; the seams
  were checked against core/71's and core/73's plans (core/74).
- GLOSSARY: Final wash and Laundry bin name no Part ("the run's last Fix"); "Laundry day" added (Q2643, 2026-11-24).

## Open follow-ups
None: answered and filed by core/74.

## Built log
### 2026-11-24 (ticket agent)
Changed: step 1 and step 2 as a design, docs only; stopped at step 2 for the designer. 73 old lines listed with their
file:line (a New Game before the First wash, the First wash, the bins, the Laundry day, the Final wash, the Final screen,
the Lobby after an ending, words and sounds) and the old run ends' weak points. The proposal: `LaundryBin` (placed,
Carriable plus a Part, Looks with heap and tip), `LaundryDay` Part (draw, load, First wash, ending), `SockSpray`,
`RunRecord`, the Final screen and its totals as Resources, Continue through the game link; the shared Cutscene frame;
the seams asked of core/71 (S1-S5) and core/73 (W1-W7); ten ticket drafts in build order with their real-path cases;
nine choices R1-R9.
Files: docs/migration/m4-lists/04-first-wash-and-laundry-day.md, docs/architecture/run-ends.md, this ticket.
Verified: docs only; no game code changed.
