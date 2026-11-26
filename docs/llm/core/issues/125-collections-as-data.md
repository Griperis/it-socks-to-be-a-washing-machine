---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: gifts
priority: now
created: 2026-11-26
done:
blocked_by: []
notes: ["batch B (Q2614); order: docs/migration/milestones.md Batch B, wave 1", "suggested model: sonnet"]
terms: [Collection, Unlocked Collection, Cabinet, Design]
suites: [cabinet, cabinet_looks, pairing, sock_looks, every_sock, stages, zoo]
---

# Collections as data

Each Collection becomes one Resource a designer edits in the inspector, and the unlock rule becomes one Resource too.
Build `docs/architecture/gifts.md` "Collections as data".

- `SockCollection` (`game/collections/sock_collection.gd`) and its 17 `.tres` (from the old `data/designs.json` and
  `data/tuning/wrapping.json`, the 2026-11-19 names Simple and Patterns): `id`, `name`, `colour`, `cabinet_name`, `icon`,
  `paper`, `ink`, `bow`, `held_back` (on only for the Lost Socks, Q2675).
- `Collections` (static): `all()` by `ResourceLoader.list_directory` in `DesignCatalogue.collections()` order, `of(id)`,
  and a `shown()` list that leaves out held-back ones.
- `CollectionUnlocks` (`collection_unlocks.tres`): `start` (Simple, Sport, Patterns, Animals, Superhero, Winter, Nature,
  Food: Q1439 without the Lost Socks, Q2675), `order` (Space, Fruit, Machinery, Drinks, Tech, Vegetables, Transport,
  Math: Q1465), `per_finished_game` 1, `next_after(unlocked)`.
- `DesignCatalogue.collection_colours` and `cabinet_names` go; `collection_colour()` and `cabinet_name()` keep their
  signatures and read the files.
- The Collections station `game/zoo/stations/collections.tscn` (instanced by hand in `zoo.tscn`): one row per file
  (icon, name, colour swatch, Cabinet name, the three wrapping swatches, "start" or its place in the order, "held
  back"), built from the folder at load (Q2337); a row scene instanced per Collection (Q2658).

Behaviour lines (`docs/migration/m4-lists/07-gifts-and-collections.md`): "Collections unlocking", the lines on the
start set, the order and data (the draw is core/135's, the unlock at a finished run core/134's).

Batch B is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-b-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
A designer adds a Collection by its Designs in `designs.tres` and one `SockCollection` file: no code; it shows in the
station with no other change. The start set, the order and the count are edited on `collection_unlocks.tres`.

## Acceptance
- Real path: in the Cabinet station, aiming at a drawer shows "[E] <cabinet_name> Drawer" read from the Collection's
  file, and a Pair shelved there by a left click bursts in the file's colour.
- Changing a file's `colour` (a test writes a copy) changes the pairing sparkles with no code change.
- The Collections station lists all 17 rows, the Lost Socks marked held back.
- Placeholders: none new (the old colours and wrapping values).
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The Lost Socks belong in the Drum (batch D); until then they are left out of the encyclopedia, the start set and
  presents (Q2675, 2026-11-25).
- Each Collection a Resource tuned in the inspector and shown in a zoo station (Q2607, 2026-11-24).

## Open follow-ups
