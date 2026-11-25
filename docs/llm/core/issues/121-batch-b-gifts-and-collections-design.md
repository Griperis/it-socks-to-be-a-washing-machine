---
type: ticket
status: needs-info
kind: design
area: core
feature: gifts
priority: now
created: 2026-11-25
done:
blocked_by: []
notes: ["suggested model: opus", "batch B design (milestones.md), for the designer's one grilling sitting"]
terms: [Gift, Stage, Collection, Design, Cabinet, Old Tree]
---

# Batch B: Stage presents, Gifts, Collections unlocking and the encyclopedia (design)

What a player gets for progress, on top of batch A's run. A design ticket: findings and a proposal, no game code.

## Step 1: findings
Examine `reference/it-socks` (grep) and `docs/migration/digests/digest-progression.md` sections 4 (pools), 5, 9 and
13, plus catalogue B25 and B52. Cover:
- the Gift boxes per player and their reveal;
- the presents under the Old Tree after each Stage;
- which Collections and Designs unlock when, and the Cabinet room pools (batch A kept the placed Collections:
  Q2618);
- the collection-complete moment and the hints;
- the encyclopedia of Designs;
- what a World and the player's profile save of each.

Batch A's carried items: the Machine Part's pop spot is kept clear of gift boxes (core/79, carried here). Write
`docs/migration/m4-lists/07-gifts-and-collections.md`: every line and every motion, glide, pop and sound, with its
old file:line, and what was weak.

## Step 2: proposal (stop for the designer)
`docs/architecture/gifts.md`, covering:
- a Gift and a present as Resources and scenes;
- the reveal as Looks with an AnimationPlayer;
- the unlock rules as data (a designer adds a Collection or an unlock with no code);
- the encyclopedia screen, authored in nodes;
- the save;
- the seams to core/120 (Coins) and core/122 (pieces as Gifts).

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
The proposal (`docs/architecture/gifts.md`) is written with each (a). Q numbers are the lead's to give.
- [blocking] G1 A present when the player already owns every piece of its Collection (Q1609 "for now", Q1834 never
  answered): (a) **rec.** Coins, 75, as the old; (b) a piece of another unlocked Collection they lack (Coins only once
  they own every piece); (c) the piece goes to a Teammate who lacks it, else Coins.
- [blocking] G2 Q2612 says presents are "opened together". Which? (a) **rec.** each player picks up and opens their
  own whenever they like, as the old (Q1592, Q715); (b) a shared moment: once every player with a present has picked
  theirs up, all shake and pop at once.
- [blocking] G3 The Lost Socks lived only in the Grotto, which is not ported (Q2599), so it cannot be played or its
  pieces won: (a) **rec.** leave it out of the encyclopedia, the start set and presents until it gets a home; (b) add it
  to the attic's pool; (c) keep its page, always "???".
- [blocking] G4 The encyclopedia book in the house (workbench, one Hands slot, E reads): (a) **rec.** in batch B, as the
  old; its one-slot Hands item is reused by batch C's guide card; (b) batch B has only the title screen's
  encyclopedia; the book comes with the guide card in batch C.
- [blocking] G5 Nothing told the player a left click opens a carried present (only "Drop [RMB]"): (a) **rec.** add
  "[LMB] Pick up" aimed at your own present and "[LMB] Open" while carrying it; (b) as the old.
- [blocking] G6 Q1948 assumed every Stage completes a Collection, but Stage 1 cannot (Simple needs six Drawers), so
  the first presents come after Stage 2: (a) **rec.** keep it so; (b) a Stage that completes no Collection gives each
  player one present, themed by a Collection of its bar.

## Built log
- 2026-11-25, core/121-batch-b-gifts-design: Changed: the behaviour list of Stage presents, Gifts, Collections
  unlocking and the encyclopedia (when presents come, what is inside, the heap under the Old Tree, carrying, opening and
  the reveal, unlocking and the pools, the encyclopedia and its book, saves and co-op, words) with old file:line and
  what was weak; the proposal (Collections as `SockCollection` files and `CollectionUnlocks`; pools on the placed
  Cabinets drawn in `Stages.start`; `Stages.completed`; presents as spawned scenes through a new `SpawnedParts` with a
  `Carriable` and a `Present` Part, Looks clips `drop`, `lying`, `open`; `GiftReveal` in nodes; `ProfileRecorder`; the
  encyclopedia pages, the title key and the book; the save; the seams S-122a-f, S-120a-c and batch A's; nine build
  drafts 121-A..121-I and two asset drafts AS-B1, AS-B2 in five waves with their clashes); the choices G1-G6 above.
  Files: `docs/migration/m4-lists/07-gifts-and-collections.md`, `docs/architecture/gifts.md`, `docs/architecture.md`
  (its row), this ticket. Verified: docs only, no game code (`--no-test`).
