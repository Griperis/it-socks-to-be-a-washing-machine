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
terms: [Stage, Floor, Cabinet, Row, Coins, World]
---

# Batch A: Stages and floors (design)

The run's frame (M4) after the menus and Lobby: the floor-by-floor campaign. A design ticket: findings and a
proposal, no game code.

## Step 1: findings
By examination of `reference/it-socks` (grep; never commit there) and `docs/migration/digests/digest-progression.md`
sections 1-4 and 6: Stages and floors (catalogue B20: the Stage bar, Rows per Stage, Stage spawning, locked doors
with chain and padlock and their reveal, the washer's Parts and floor opening, Collections per floor, the Pairs per
Drawer slider waiting from Q2586), the Whiteboard and Tab tallies (B27), the HUD's Stage bar, and how a run's
progress is saved in a World (`docs/architecture/saves.md`, core/58, core/65). How it meets the port: the Sock
generator's areas per floor (house/05, core/52), the eight Cabinets, the Lobby's Start. Write
`docs/migration/m4-lists/03-stages-and-floors.md` in the shape of `02-lobby.md`: every line, every motion, glide,
pop and sound (Q2277), with its old file:line; what was weak.

## Step 2: proposal (stop for the designer)
`docs/architecture/stages.md`: a Stage as a Resource (its floor, Collections, Rows, Socks, what unlocks), the run's
state as Parts (Host authoritative), the locks and the reveal, the Stage bar and Whiteboard, the save of a run in a
World; what core/58-68's code is reused. Leave the First wash, the Laundry day and the Final screen to core/72 and
the washer and voices to core/73, but name the seams they plug into (a Stage ends, a Stage starts, a lock opens).

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
