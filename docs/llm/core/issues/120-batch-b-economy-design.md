---
type: ticket
status: done
kind: design
area: core
feature: economy
priority: now
created: 2026-11-25
done: 2026-11-26
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

## Answers
Behaviour list `docs/migration/m4-lists/06-coins-drawers-upgrades.md`; proposal `docs/architecture/economy.md`, made a
build plan to these answers by core/123, which filed its drafts as core/124 and core/129-133.
- E1 Stage Coins bonuses: both, as the old: +100 to every player when a floor opens and +50 to whoever fills a
  Cabinet's current Rows (option b; closes Q2619). (Q2667, 2026-11-25)
- E2 How a bonus shows: as the old: the Coins counter counts up, no "+N" (option b). (Q2668, 2026-11-25)
- E3 The 16 batch C Upgrades: greyed "Coming soon" in the grid until then, the old rule Q1272 (option a). (Q2669,
  2026-11-25)
- E4 The Old Tree: its voice in batch B, its motion waits for its rework, Q2506 (option b). (Q2670, 2026-11-25)
- E5 Sole Mates, Sole Hands and Mate Radar: built in batch B with the Upgrade grid (option a). (Q2671, 2026-11-25)
- E6 Coins still flying: spendable only once landed, as the old (option a). (Q2672, 2026-11-25)

## Open follow-ups
- [later] For the lead: Q2632 said the Final screen's "who did what" titles are asked again with batch B; no piece
  owns them and the batch B sitting did not ask them. Carried to core/123's Open follow-ups.

## Built log
- 2026-11-25, core/120-batch-b-economy-design: Changed: the behaviour list of Coins and Drawers, the Old Tree and the
  Upgrade grid (two currencies and every payout, the HUD counters and flights, the Old Tree as station and speaker, the
  menu, buying, the 27 ported Upgrades of v0.1.1's 37, saves) with old file:line, what was weak; the proposal (`Bank`
  from `Coins` with the team's Drawers, `Upgrades` with `Upgrade` and `UpgradeStat` Resources dropped into a folder,
  `OldTree` Part; the menu and HUD authored in nodes; the Economy zoo station; the seams to core/121, core/122, batch A
  and C; six build drafts 120-A..120-F in four waves with their clashes); the choices E1-E6 above. Files:
  `docs/migration/m4-lists/06-coins-drawers-upgrades.md`, `docs/architecture/economy.md`, `docs/architecture.md` (its
  row). Verified: docs only, no game code (`--no-test`).
