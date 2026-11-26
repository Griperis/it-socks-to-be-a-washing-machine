---
type: ticket
status: done
kind: build
area: core
feature: gifts
priority: now
created: 2026-11-26
done: 2026-11-26
blocked_by: ["[[127-profile-file-and-tallies]]", "[[125-collections-as-data]]"]
notes: ["batch B (Q2614); order: docs/migration/milestones.md Batch B, wave 3", "suggested model: sonnet"]
terms: [Sock encyclopedia, Unlocked Collection, Profile, Design, Final wash]
suites: [cabinet_draw, final_screen, final_wash, laundry_day, save, stages, coop_join]
---

# The encyclopedia record and Collections unlocking

What a player has seen shelved goes into their Profile, and a finished game unlocks the next Collection. Build
`docs/architecture/gifts.md` "The encyclopedia", "Recording" and "Unlocking" (the profile's two fields are core/127's):

- `ProfileRecorder` (`game/collections/profile_recorder.gd`, a Node in `run.tscn`, every machine): an applied shelve
  answer adds its Designs to the local profile's `designs`; a World loaded by its Host (or Solo) adds the Cabinets'
  shelved Designs; a Guest adds only what is shelved after it joined (a snapshot emits nothing); written through
  `save_soon()`.
- At the Laundry day's applied `ended`, `CollectionUnlocks.next_after(profile.collections)` is unlocked into the local
  profile and handed to the Final screen's unlock strip: a heading ("New Collection unlocked" / plural) and one
  `unlock_cell.tscn` (icon 96 px, name) per Collection, popping in after the totals with `FinalScreenTuning`'s unlock
  reveal and a `pop` cue; a skip shows them at once.
- The Final screen station gets a pillar "with an unlock" in its made-up records.

Behaviour lines (`docs/migration/m4-lists/07-gifts-and-collections.md`): "Collections unlocking" (the unlock at a
finished game and its strip) and "The encyclopedia" (recording only; the pages are core/136's, the book core/139's).

Batch B is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-b-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
The unlock strip and its cell are scenes on the Theme (Q2658); code instances one cell per Collection. The start set,
order and count are `collection_unlocks.tres` (core/125). A held-back Collection is never unlocked by the order.

## Acceptance
- Real path: on the Stages station's mini run a Pair shelved by a left click puts its Design in the profile file.
- The Final screen station's pillar "with an unlock" shows the strip; a finished mini run (the Laundry station's Final
  wash pillar, the last bin loaded by a click) unlocks Space in the profile.
- A Guest's profile records only what was shelved after it joined; a loaded World adds its shelved Designs once.
- The New Game's draw reads the profile's unlocked Collections: `Stages.unlocked_collections()` (core/135) switches from
  `CollectionUnlocks.start` to the local profile's `collections`, the one place core/135 left for it.
- Placeholders: none new (the reveal timings are `FinalScreenTuning`'s).
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The Lost Socks are left out of the encyclopedia and the start set until the Drum (Q2675, 2026-11-25).

## Open follow-ups
