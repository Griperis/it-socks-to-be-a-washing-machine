---
type: ticket
status: ready-for-agent
kind: design
area: core
feature: economy
priority: now
created: 2026-11-25
done:
blocked_by: []
notes: ["suggested model: opus", "batch B design (milestones.md), for the designer's one grilling sitting"]
terms: [Coins, Drawer, Cabinet, Upgrade, Old Tree, Stage]
---

# Batch B: Coins and Drawers, the Old Tree and the Upgrade grid (design)

Progression's economy, on top of batch A's run. A design ticket: findings and a proposal, no game code.

## Step 1: findings
Examine `reference/it-socks` (grep) and `docs/migration/digests/digest-progression.md` sections 4, 7, 8 and 12,
plus catalogue B36 (`docs/migration/feature-catalogue.md`). Cover:
- how Coins are earned (per Pair, bonuses, rare Pairs) and how they show (the Final screen counts them: core/95);
- buying Drawers and Rows;
- the two currencies;
- the Old Tree and its Upgrade grid: 33 nodes in `data/upgrades.json`, the menu, costs, what each Upgrade changes
  in play;
- what a World saves of it.

Batch A's open seam: Stage Coins bonuses were left to this piece (Q2619). Write
`docs/migration/m4-lists/06-coins-drawers-upgrades.md` in the shape of `03-stages-and-floors.md`: every line and
every motion, glide, pop and sound (Q2277), with its old file:line, and what was weak.

## Step 2: proposal (stop for the designer)
`docs/architecture/economy.md`, covering:
- Coins as Host-decided state on Parts, and where they are shown;
- a Drawer or Row purchase;
- the Old Tree in the house and its Upgrade menu (a screen, authored in nodes);
- each Upgrade as a typed Resource whose effect a designer can add without code where possible;
- the save;
- the seams to core/121 (Gifts may cost or give Coins) and core/122 (the Wardrobe may cost).

## How the proposal is shaped (Q2603, Q2604, Q2607, as batch A)
Batch B is built unattended after the designer approves the proposals in one sitting, then reviewed in play as a
whole. So the proposal leaves no open choice for the build: every design uncertainty is a choice below, and every
piece says **how it is authored**:
- what is a typed Resource edited in the inspector;
- what a designer adds by dropping a file or a Resource, with no code change;
- which zoo station shows it, built from the data at load (Q2337);
- what is authored in nodes (Q2658).

Where the old game was weak, say so and propose the fix as a choice, with the old way as one option. A detail the
old game settles is ported as it was (Q2277). A detail it does not settle is a choice here, not left to the build.
Co-op is the scene-parts shape: the Host decides, Parts sync and save
(`docs/migration/coop-structure-for-the-port.md`).

## Acceptance
- The behaviour list and the proposal exist. Every old detail is listed, or named as dropped with its Q.
- The build is split into tickets of one mergeable piece each, in the most efficient build order, each with its
  real-path case named. Write them as `ready-for-agent` drafts in the proposal (the lead files them), and name the
  waves and which tickets clash.
- The choices are `[blocking]` Open follow-ups here, 2-3 options each with a recommendation, as short as a question
  can be. Read `docs/migration/decisions.md` and `docs/migration/batch-a-review.md` first; ask nothing already
  answered.
- No game code changed. The old game is at the main checkout's `reference/it-socks` (grep it, never commit there).

## Open follow-ups

## Built log
