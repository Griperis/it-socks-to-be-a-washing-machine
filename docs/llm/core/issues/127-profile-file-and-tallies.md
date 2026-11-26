---
type: ticket
status: done
kind: build
area: core
feature: player
priority: now
created: 2026-11-26
done: 2026-11-26
blocked_by: ["[[124-coins-and-drawers]]"]
notes: ["batch B (Q2614); order: docs/migration/milestones.md Batch B, wave 2", "suggested model: sonnet"]
terms: [Profile, Lifetime tallies, Coins]
suites: [save, game_link, main, stages, run_tallies, game_cli, lobby]
---

# The Profile file and the Lifetime tallies

The one ticket that changes `game/net/player_profile.gd` in batch B (core/121's and core/122's profile drafts merged),
and the five Lifetime tallies counted into it. Build `docs/architecture/wardrobe.md` "The Profile file" and "The
Lifetime tallies", with `docs/architecture/gifts.md` "The save", the profile's two fields:

- `PlayerProfile` version 2, plain JSON: `colour`, `look`, `pieces` (owned; the ten basic pieces are never stored:
  `Wardrobe.owned()` adds them, Q2679), `tallies` (the five), `achievements` (id -> unix time), `designs` (sorted
  Design ids) and `collections` (unlocked; a new profile starts with `CollectionUnlocks.start` when core/125's file
  exists, else empty). A version 1 file reads with the new fields empty; a damaged file is made anew.
- `save_soon()` (dirty mark; a timer on the Session writes it at most every `save_every` 2 s, and at quit), `unlock_piece(id)` with
  the `piece_unlocked(id)` signal on the Session's profile holder, `count(tally, n)`, `tally(name)`, `earn(id)`.
- `TallyRecorder` (`game/profile/tally_recorder.gd`, a Node in `run.tscn`, every machine): `pairs_shelved` (each
  shelve answer, any shelver), `coins_earned` (`Bank.paid` for the local player, at the decided payout, bonuses and
  refunds included), `floors_completed` (`Stages.stage_completed`, the last floor's included), `games_finished` (the
  Laundry day's `ended`); never while a World loads or from a snapshot; a Guest counts from its join on.
  `collections_completed` is counted by core/137, which makes its event. Each count calls `Achievements.check()` when
  core/145's node exists (a guarded call until then).

Behaviour lines (`docs/migration/m4-lists/08-wardrobe-profile-achievements.md`): "The Profile and its Lifetime tallies"
(the old wrote the file on each Pair: replaced by the coalesced save, wardrobe.md "Changed technically"; the older
version's cleared list does not apply before save compatibility starts).

Batch B is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-b-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
`WardrobeTuning.save_every` (2 s, `# placeholder:`) if core/128 has made `WardrobeTuning`, else a `ProfileTuning`
Resource beside the profile. The file stays one per `--profile=<tag>` (ProfileLock).

## Acceptance
- Real path: on the Stages station's mini run the player shelves a Pair by a left click; the profile's
  `pairs_shelved` reads 1 and its `coins_earned` the Pair's Coins, and the file on disk has them within the save gap.
- A loaded World counts nothing; a Guest joining mid-run counts only what is shelved after it joined.
- A version 1 profile (the shape written today) loads with its name and id kept and the new fields empty.
- Shelving many Pairs in a second writes the file at most once per `save_every`.
- Placeholders: `save_every`.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The ten basic Wardrobe pieces are owned from the start (Q2679, 2026-11-25).
- Saves live in the player's own profile file, synced by Steam Auto-Cloud (Q2565).

## Open follow-ups
