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
Each choice is written into `docs/architecture/stages.md` for its recommended answer; the behaviour list is
`docs/migration/m4-lists/03-stages-and-floors.md`. Nothing here is answered in `decisions.md` (Q2599-Q2616 read).
- [blocking] S1 Where a Stage's new Socks lie. The old code spread them over every open floor (25 % each); the
  designer's words at old ticket 92 say "the next Stage's Socks still appear on the floor that just opened" (Q1938).
  (a) All on the floor just opened, laid by its own generator (Recommended: Q1938's words, and the floor is empty of
  players when it is laid); (b) over every open floor in even shares, as the old code; (c) half on the new floor, the
  rest over the open floors.
- [blocking] S2 Which Collection stands at each Cabinet spot in batch A. The old game drew each spot from its room's pool
  per New Game (Q1437) among the Profile's unlocked Collections (Q1439). (a) Each spot keeps the Collection placed in the
  house today (Simple, Sport, Food, Patterns, Animals, Superhero, Winter, Space); the pools come with batch B's
  Collections unlocking (Recommended: the pools draw from the unlocked set, which is batch B); (b) the pools now, from the
  old first-game set, unlocking later.
- [blocking] S3 The Stage's Coins bonuses: +100 Coins to every player when a floor opens, +50 to whoever fills all of a
  Cabinet's current Rows (Q646, Q1248). Q2612 says a filled Drawer flies in its Coins and Drawers "and nothing else".
  (a) Not paid in batch A; batch B's Coins and Drawers decides them (Recommended); (b) paid now as the old game.
- [blocking] S4 A new Drawer added while nobody looks. Q824 decided it waits hidden until a player has its Cabinet in
  view, then drops for everyone; the old game never built it (progression/31, priority later). (a) Drops at once on the
  opening, seen or not, as v0.1.1 played; (b) waits until a player on its floor has the Cabinet in view, the Host
  deciding, and takes no Pair until it has dropped (Recommended: the designer's own Q824).
- [blocking] S5 What the HUD shows between a Stage's completion and its Fix. The old bar just stays full; only the
  padlock's hint and the washer's lines point to the washer. (a) As the old: the bar stays full (Recommended: the old
  game first, Q2607); (b) the bar's label reads "Bring the <Part> to the washing machine" until the Fix (wording a
  placeholder).
- [blocking] S6 The Stage bar's floor names. The old label capitalised the floor's id: "Stage 3: First  12/150". (a) The
  Stage's own title: "Basement", "Ground floor", "First floor", "Attic" (Recommended: reads as a place); (b) as the old:
  "Basement", "Ground", "First", "Attic".
- [blocking] S7 The attic's (batch A's last) Stage bar. The old code counts only the last Stage's own Cabinets, a patch
  for the Grotto's Lost Socks (old ticket 82); the rule for every other floor counts every unlocked Cabinet's unfilled
  Rows, grown ones too (Q633, Q648). (a) The attic counts every unlocked Cabinet's unfilled Rows, as every floor
  (Recommended: Q648; the Drum's Stage in batch D keeps its own patch); (b) the attic counts only Winter and Space, as
  the old last-Stage code.

## Built log
- 2026-11-24, core/71-stages-design: Changed: the behaviour list of Stages and floors (Stages, Rows and Drawers, a Stage's
  Socks, the Part, the locks and reveals, the Stage bar, the Whiteboard and Tab, saves) with old file:line, what was
  weak; the proposal (one `Run` with `Stages`, `RunTallies` and `StageSpawner`; one phase instead of five counters; the
  verbs and the seams for core/72 and core/73; how each piece is authored; eight build drafts 71-A..71-H and three asset
  drafts AS1-AS3 in order); the choices S1-S7 above. Files: `docs/migration/m4-lists/03-stages-and-floors.md`,
  `docs/architecture/stages.md`, `docs/architecture.md` (its row). Verified: docs only, no game code (`--no-test`).
