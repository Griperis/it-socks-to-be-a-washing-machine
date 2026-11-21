# Add or swap a sound

## What this is for

You want a new sound in the game, or a different clip for a sound that exists. All sounds are named events in one catalogue. Swapping a clip is only a change in the inspector. A new name needs a place in the game that asks for it.

## The pieces

- **Clips:** `assets/audio/<event>__<source>.ogg`, for example `pick__owlish_cloth5.ogg`. Licences and where each came from are in `assets/audio/SOURCES.md`.
- **A SoundEvent** (`game/audio/sound_event.gd`): one named sound, edited in the inspector.
- **The catalogue:** `game/audio/sound_catalogue.tres`, a list of every SoundEvent. Open it in the inspector to edit.
- **Sounds:** the autoload `game/audio/sounds.gd`. Code calls `Sounds.play(&"pick")` for a flat sound and `Sounds.play_at(&"drawer_open", where)` for a world sound. A name the catalogue does not know is an error.
- **Buses:** `default_bus_layout.tres`: Master, SFX, Ambient, Music, UI, plus Muffled copies. The player's volume per bus is a setting.

## Swap a clip

1. Drop the `.ogg` into `assets/audio/`. Name it `<event>__<source>.ogg`.
2. Open `game/audio/sound_catalogue.tres`, open the event, and change the `Clips` list. Several clips are allowed: one plays at random each time, pitch jittered by 5 % (`pitch_jitter`).
3. Add a line for it in `assets/audio/SOURCES.md`: file, author, licence, page.
4. Check the Sounds station (below).

## Add a new event

1. Drop the clip into `assets/audio/` as above.
2. In `sound_catalogue.tres`, add an element to `Events` and create a new SoundEvent. Fill in:
   - `Event`: the name, lowercase with underscores (`step_wood`). The name is exact.
   - `Clips`: the files.
   - `Volume Db`: the level on its bus.
   - `Bus`: `SFX`, `Ambient`, `Music` or `UI`.
   - `Spatial`: on for a **3D** world sound (fades with distance, muffled behind a shut Door); off for a **flat** one (the player's own sounds, the UI).
   - `Loop`: on for an ambience.
   - `Min Gap`: the least time in seconds between two plays (a bounce heard twenty times in one tick is one bounce). 0 plays every one. Examples: `bounce` 0.05, `drawer_open` 0.1.
   - `Note`: where the clip came from and what is open.
3. The code has to ask for the name. Someone has to add the one line of code that plays it; a new event nobody asks for only sounds in the Sounds station.
4. A test reads the game's code for event names that are not in the catalogue, so a typo shows up as a failed run.

## 3D or flat

- Flat: `Spatial` off, played with `Sounds.play`.
- 3D: `Spatial` on, played with `Sounds.play_at(name, where)`. The fade is full inside `Unit Size` (3 m) and gone at `Max Distance` (20 m), both in the catalogue. Sounds behind a shut Door are quieter and duller (-9 dB, 900 Hz low-pass on the Muffled buses). The doors that muffle are listed in `Muffling Scenes` in the catalogue.
- Playing the wrong way (`play` on a 3D event, or `play_at` on a flat one) is an error.

## Strength: a bounce by hit speed

A play can carry a strength from 0 (soft) to 1 (hard). In the event's group **By strength**:

- `Soft Db`: how much quieter than `Volume Db` the softest play is (`bounce` has -15).
- `Soft Pitch` and `Hard Pitch`: the pitch of the softest and the hardest.

All at their defaults means strength changes nothing. A bounce asks for its strength from the hit speed: below `Bounce Speed` (1.5 m/s) it is silent, at `Bounce Hard Speed` (8 m/s) it is loudest. Both are in `game/mess/mess_tuning.tres`, group Sound.

## Footsteps by surface

- The player's steps are in `game/audio/footsteps.gd`. A step comes every `Step Distance` metres walked (1.4 m), set in `game/audio/footstep_tuning.tres`. A landing after a fall of `Land Speed` (3 m/s) or more plays `land`.
- The sound is `step_<surface>`, by the floor under the player. A floor's surface is the metadata `surface` on its body (or a node above it), for example `wood` or `tile`. With no metadata it is `wood`.
- Add a surface: put the metadata `surface` = `marble` on the floor body in the Inspector (Metadata, add String), and add the event `step_marble` to the catalogue.

## The Sounds zoo station

`game/zoo/stations/sounds.tscn` (node `Sounds`) builds itself from the catalogue when it loads: one small box button per event that does not loop, in the catalogue's order, grouped by bus. Press E on a button to hear the event, from the box for a 3D one. A looping event (the room tone) has no button; the station's `Ambience` plays it. A new event has its button with no other change. In the station you also hear the muffling: a button behind the Door and one in the open, and a tile floor patch for the tile step.

## Checking it worked

1. Open `game/zoo/zoo.tscn`, walk to the Sounds station, and press E on the new button. You hear your clip.
2. Run `kit/tools/run.sh --only=sounds`. It ends with `PASS`.
3. For sounds played in real moments (pick, throw, shelve, steps) run `kit/tools/run.sh --only=sound_wiring`.

## Gotchas

- The event name is the key. A rename in the catalogue breaks every place that asks for the old name.
- Many playing at once: eight flat and eight world voices are used in turn. A burst can cut an older sound off.
- `Min Gap` drops plays silently: if a sound seems missing in a fast moment, check it.
- Pitch jitter, distances and the footstep numbers are placeholders ported from the old game; they are yours to change.
- The old game had about 80 more events (UI clicks, piano, voices, vacuum, radio, cat, fridge, window ambience, pad rumble extras). Only the first 19 plus the room tone are in. Missing ones need a clip, an event and a call.

Sources: tickets `docs/llm/core/issues/17-sound-system.md` and `22-sounds-station-from-data.md`; Q2319 (the old picks), Q2337 (stations built from data).
