---
type: ticket
status: needs-info
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
Choices R1-R9 of `docs/architecture/run-ends.md` (recommendations followed in its text); none is answered in
`docs/migration/decisions.md` (read to Q2616).
- [blocking] R1 When do the World's bins stand in the house? a) (rec) from the New Game, all drawn bins full in their
  rooms, refused at the machine until the last Fix, as the old; b) only the bin by the machine at first, the other drawn
  bins appear when the last Fix is done.
- [blocking] R2 What tells a new player the first goal before the First wash (the Guide card is batch C)? a) (rec) a HUD
  goal line "Wash the laundry" in the Stage bar's slot until the First wash; b) nothing new until batch C.
- [blocking] R3 The spray and the first Stage's Socks? a) (rec) as the old: the spray is decoration that vanishes, the
  Socks lie in their usual places after; b) the spray's Socks stay as real first-Stage Socks in the laundry room.
- [blocking] R4 The bin's pour (the Socks never seen going in, Q1907 "later")? a) (rec) as the old in batch A, a visible
  pour as its own look ticket after the review (Q2153); b) the visible pour built into batch A.
- [blocking] R5 Does a carried bin slow its carrier? a) (rec) no, as the old code; b) slower, no Sprint or jump, as the
  Hamper.
- [blocking] R6 `cutscene_6` opens "You're alive!", written for the return from the Drum (batch D). In batch A? a) (rec)
  the whole line as the old; b) from its second subtitle line until the Drum is ported.
- [blocking] R7 Who has a column on the Final screen? a) (rec) everyone who shelved a Pair or is in the game, a leaver
  greyed "(left)"; b) as the old, only those in the game at the end.
- [blocking] R8 What the Lobby offers for a finished World (core/61 L6, P36)? a) (rec) kept as a record ("Finished",
  play time), not continued; Start / New Game asks and replaces it; b) Keep tidying: Continue loads the finished house to
  play freely; c) deleted at Continue.
- [blocking] R9 "Who did what" titles on the Final screen (P36)? a) (rec) not in batch A, asked again with batch B; b)
  three titles (most Pairs, most bins loaded, most Socks thrown).
- [later] For the lead: the Cutscene frame (shared camera, fade, Host skip, respawn, duck) is needed by core/71's Fix,
  core/72's two washes and core/73's washer; `voice.md` gave it to "M5". Proposed as core/72's ticket 4; dedupe with
  core/71's and core/73's lists when filing. Likewise ticket 1 (carried things in the Hands) with core/71's Parts.
- [later] For the lead: the seams asked of core/71 (S1-S5) and core/73 (W1-W4, W6, W7) are listed in `run-ends.md`
  "Seams this piece needs"; check them against their proposals before the sitting.
- [later] GLOSSARY: "Laundry day" is no glossary term (the catalogue's own note); the **Final wash** and **Laundry bin**
  entries still name the softener and the Drum as the last Fix; in batch A the last Fix is the fourth Stage's (Q2615).
  The designer settles the wording.

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
