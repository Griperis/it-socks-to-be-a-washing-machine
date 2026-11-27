---
type: ticket
status: ready-for-agent
kind: maintenance
area: maintenance
feature: audio
priority: now
created: 2026-11-27
blocked_by: ["[[139-encyclopedia-book]]"]
notes: ["suggested model: sonnet", "batch C scheduling (Q2721); before core/154"]
terms: [SoundEvent]
suites: [sounds, sound_wiring, zoo, menus, voice]
---

# One sound catalogue file per feature

Every SoundEvent lives in one file, `game/audio/sound_catalogue.tres`, so every ticket that adds a sound clashes there
at merge. The designer chose one catalogue file per feature, gathered at load (Q2721), so a ticket that adds sounds adds
its own file.

## Do
1. Make a folder `game/audio/catalogue/` of `SoundCatalogue` resources, one per feature (for example `core.tres`,
   `economy.tres`, `gifts.tres`, `wardrobe.tres`, `old_tree.tres`; group by the feature that owns each event, from its
   doc or ticket; when unsure, `core.tres`). Move every existing SoundEvent into one of them, unchanged: same id, clips,
   numbers and order within a file.
2. `Sounds` gathers every catalogue in that folder at load (in a fixed order: by file name) into the one lookup it has
   today. It must work in an exported build, where `res://` lists `.remap`/`.import` names (use
   `ResourceLoader.list_directory()` or an equivalent that works exported). The catalogue-wide numbers
   `SoundCatalogue` carries today stay in one place (say which).
3. Two catalogues naming the same event id is an error the wiring check reports (a test case).
4. The Sounds zoo station and every other reader of the catalogue (`Sounds.CATALOGUE` users, tests, tools) read the
   gathered set; the station shows every event with no other change (Q2337).
5. Remove `sound_catalogue.tres` once nothing reads it. Update `docs/architecture/` where it names the one file, and
   core/154's and core/179's text if they still name it.

## Acceptance
- Real path: in the Sounds station the player walks to the `pick` pillar and presses E and it plays; the same for a
  sound from another feature file (for example a Gift's or the Old Tree's).
- A new file dropped into `game/audio/catalogue/` with one SoundEvent shows up in the station and plays, with no other
  change (a case).
- A duplicate id across two files fails the wiring check (a case).
- Every sound the game played before still plays: the suites named pass, and the event count before and after is equal.
- No sound changes how it sounds: no clip, volume or bus edited.

## Answers
- The sound catalogue is split per feature, gathered at load (Q2721, 2026-11-27).
- A zoo station that shows game data is built from it at load (Q2337).
