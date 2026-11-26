---
type: ticket
status: done
kind: design
area: core
feature: player
priority: now
created: 2026-11-25
done: 2026-11-26
blocked_by: []
notes: ["suggested model: opus", "batch B design (milestones.md), for the designer's one grilling sitting"]
terms: [Wardrobe, piece, Profile, Achievement, Secret]
---

# Batch B: the Wardrobe, the Profile and Achievements (design)

The player's own side of progression. A design ticket: findings and a proposal, no game code.

## Step 1: findings
Examine `reference/it-socks` (grep) and `docs/migration/digests/digest-progression.md` sections 10 and 15, plus
catalogue B29 and B52. Cover:
- the Wardrobe station and its cosmetic pieces (hats, clothes: `assets/avatar/wardrobe/`);
- lifetime unlocks kept on the player's profile, not the World;
- how pieces show on the Avatar for Teammates;
- the Profile page;
- the Wash cycles and Achievements (designed, not built, in the old game);
- the Secrets (hidden triggers that give pieces: the Duet in the Elevator, Piano Four Hands and the like). Many
  depend on batch C's house devices, so say which can come in batch B.

Write `docs/migration/m4-lists/08-wardrobe-profile-achievements.md`: every line and every motion, glide, pop and
sound, with its old file:line, and what was weak.

## Step 2: proposal (stop for the designer)
`docs/architecture/wardrobe.md`, covering:
- a piece as a Resource and a Looks scene on the Avatar's slots (a designer adds a piece by dropping its files);
- the Wardrobe in the house;
- the profile's lifetime unlocks and their save (`game/net/player_profile.gd`), with co-op sync of what a Teammate
  wears;
- the Profile screen and Achievements, authored in nodes;
- which Secrets come now and which wait for batch C, as a choice;
- the seams to core/121 (pieces arrive as Gifts) and core/120 (anything bought).

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
Behaviour list `docs/migration/m4-lists/08-wardrobe-profile-achievements.md`; proposal `docs/architecture/wardrobe.md`,
made a build plan to these answers by core/123, which filed its drafts as core/127, 128, 141-147 and assets/18-20.
- W1 The ten basic pieces: owned from the start (option c; reverses Q696). Which Achievements batch B ships is not
  settled by it: core/146 asks. (Q2679, 2026-11-25)
- W2 The 17 Trails: remade as particle scenes authored in the editor, not ported scripts; the look is judged on stills
  (option b; Q2658). (Q2680, 2026-11-25)
- W3 The Achievements page: one Profile page, the five Lifetime tallies on top, the Achievements under them (option
  a). (Q2681, 2026-11-25)
- W4 Secrets: none in batch B; the eight and their pieces come together later (option a; Q2600). (Q2682, 2026-11-25)
- W5 The Lost Socks' six pieces: hidden from the Wardrobe and its "N/M" until the Lost Socks come with the Drum
  (option a; follows Q2675). (Q2683, 2026-11-25)

## Open follow-ups

## Built log
- 2026-11-25, core/122-batch-b-wardrobe-design: Changed: the behaviour list of the Wardrobe, its pieces, the Profile
  and Achievements (the 112 pieces and their slots, where a piece comes from, the Avatar wearing them with swish and the
  rare touches, the 17 Trails' motions, the own body and mirrors, Teammates, the station and its doors, the page and its
  colour row, the Lobby's key and stats card, the Profile file and its Lifetime tallies, Achievements as designed,
  Secrets' seam, the preview, words) with old file:line and what was weak; the proposal (`WardrobePiece` files and the
  `Wardrobe` catalogue; Looks per piece with the touches as clips; a `Dresser` on `AvatarLooks`; Trails as scenes; the
  Roster's look, owned, tallies and the `wear`, `colour`, `own` verbs; the page and the station in nodes; the profile's
  version 2 and coalesced save; `TallyRecorder`; `Achievement` files, `Achievements`, the backend seam, the toast, the
  Profile page; seams S-122a-f and to core/120, the Lobby, batch D; eight build drafts 122-A..122-H and two asset drafts
  AS-W1, AS-W2 in four waves with their clashes); the choices W1-W5 above. Files:
  `docs/migration/m4-lists/08-wardrobe-profile-achievements.md`, `docs/architecture/wardrobe.md`,
  `docs/architecture.md` (its row), this ticket. Verified: docs only, no game code (`--no-test`).
