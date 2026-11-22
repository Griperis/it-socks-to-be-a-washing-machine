---
type: ticket
status: done
kind: build
area: core
feature: core
priority: now
created: 2026-11-20
done: 2026-11-20
blocked_by: []
notes: []
terms: []
---

# The sound system

M0.5 batch 6 (Q2296), built ahead in its own worktree and parked ready (Q2317). A plug-and-play sound system
(Q2278) with the core's sounds. How the old game did it: `docs/migration/audit-core-looks-sound.md` section 7; old code
`reference/it-socks/game/audio/` (`sound_bank.gd`, `sfx.gd`, `ui_sounds.gd`), `data/sounds.json`,
`data/tuning/audio.json`, `assets/audio/candidates.json`, `assets/audio/SOURCES.md` (licences). The sound list for the
core: `docs/migration/old-details-backlog.md` "M1.1 Sound" and the audit's sound rows.

## Behaviour list
From the designer's answers (Q2278, Q2318-Q2321).
- S01 Every sound is a named event (`pick`, `drop`, `cycle`, `pair`, `pop`, `throw_charge`, `throw`, `refuse`, `bounce`,
  `drawer_open`, `drawer_close`, `door_open`, `door_close`, `cupboard_open`, `cupboard_close`, `shelve`, `step_wood`,
  `step_tile`, `land`, and the old core's others): a `SoundEvent` typed Resource edited in the inspector (its clips,
  volume, bus, flat or 3D, loop) in one catalogue. Code asks by name; a name the catalogue does not know fails a test.
- S02 Plug-and-play: adding or swapping a sound is dropping in a file and adding it to its event in the inspector, with
  no code change.
- S03 Each play picks one of the event's clips at random and jitters its pitch by up to 0.05, through Godot's
  `AudioStreamRandomizer`.
- S04 Buses as the old game had them, in the editor's bus layout: Master, SFX, Ambient, Music, UI, mixed 0.6, 1.0, 0.5,
  0.8, 0.8; volume per bus is a setting (stored, ready for the Options menu later).
- S05 A world sound plays from where it happens (unit size 3 m, max distance 20 m); a flat one (UI, the player's own)
  plays flat.
- S06 A sound behind a shut Door plays quieter (-9 dB) and duller (900 Hz low-pass).
- S07 Footsteps: a step every 1.4 m walked on the floor, wood or tile by the floor under the player (the zoo floor's
  surface set in the editor); a landing sound after a fall of 3 m/s or more.
- S08 A quiet ambience on the Ambient bus in the zoo.
- S09 The clips are the old game's picks for each event, with their volumes (Q2319); their licences go with them.
- S10 A "Sounds" station in the zoo plays every event, flat or from a spot, so each is heard in place (Q2320).

## Design
Built as follows (Godot's own nodes first; Q2251-Q2253).
- `SoundEvent` (Resource: name, clips, volume_db, bus, spatial, loop, note) and `SoundCatalogue` (Resource: the events,
  pitch jitter 0.05, unit size 3, max distance 20, the scenes that muffle) in `game/audio/`; the one catalogue is
  `game/audio/sound_catalogue.tres`. Clips are `assets/audio/*.ogg` with `assets/audio/SOURCES.md` (licences).
- `Sounds` (autoload): `play(name)` flat, `play_at(name, where)` world, `start_loop`/`stop_loop`, `is_muffled(where)`.
  Eight flat `AudioStreamPlayer`s and eight `AudioStreamPlayer3D`s in turn; each play uses an `AudioStreamRandomizer`
  over the event's clips (random clip, pitch 1 +- 0.05). A name that is unknown, or asked the wrong way (a world
  event flat, a flat one from a spot), is an error.
- Buses: `default_bus_layout.tres` (Master -4.4 dB = 0.6, SFX 0, Ambient -6 = 0.5, Music -1.9 = 0.8, UI -1.9 = 0.8, and
  MuffledSFX/Ambient/Music: -9 dB, 900 Hz low-pass, sending into their bus). Volume per bus is a setting
  `audio/<bus>_volume` (0 to 1, default 1) kept by `Settings` (the kit's settings template, copied to
  `game/settings/`, autoload) and multiplied onto the layout's mix; Options writes it later.
- Muffling: a ray from the listener's camera toward the sound, hop by hop, meets a shut `Openable` of a scene in
  `muffling_scenes` (the room Door) -> the voice goes to the Muffled bus.
- Floor: `Footsteps` (a child of the player) walks 1.4 m per step (`FootstepTuning`), looks straight down for the floor
  and reads its `surface` metadata (the zoo floor "wood", the Sounds station's tile patch "tile", set in the editor;
  none = wood); `land` after a fall of 3 m/s. `player.gd` is unchanged; `player.tscn` has the node.
- Zoo: `SoundSpot` (a Part: use plays its event), `AmbientLoop` (a node: plays a loop while in the tree), and the
  station `game/zoo/stations/sounds.tscn` (a pillar per event, blue flat and orange from the spot, a tile patch, a
  shut Door with a pillar behind it and one beside it, the room ambience).

**Parked scope.** Wired now: steps, landing, ambience, the station. Where each call goes in batch 6 (all
`Sounds.play(&"x")` for the player's own, `Sounds.play_at(&"x", position)` for the world; `Parts.applied` is the
seam: "sounds and the HUD may listen"):
- `pick`, `drop`, `cycle`: when the Host's answer to the Hands' pick, drop, cycle reaches this machine (`Parts.applied`
  with the Hands' id, or `Player._on_applied` in `game/player/player.gd`); the player's own, flat.
- `refuse`: the same `_on_applied` where it calls `say(...)` for a refusal (and `Player.say`).
- `pair`: where Hands/Mess answers a pairing (the fuse); `pop`: where the paired moment's ball pops.
- `throw_charge`: `Player._set_charge(true)`; `throw`: `Player._throw` after `h.throw(...)`.
- `bounce`: where a thrown item or ball lands or hits (`game/mess/` flights), `play_at` at the contact.
- `drawer_open`/`drawer_close`: `Openable._show(false)` of a drawer (Cabinet drawers, `game/entities/cabinet/cabinet.gd`
  and `game/entities/drawer/`), `play_at` the drawer's position; `shelve`: the Cabinet's answer to a shelving click.
- `door_open`/`door_close` and `cupboard_open`/`cupboard_close`: `Openable._show(false)` for the Door and cupboard
  scenes. (`_show(true)`, a state arriving whole, makes no sound.)

## Acceptance
- One test per behaviour line; the real-path case: walking in the zoo plays steps by surface; the station plays an
  event.
- The ticket goes ready-for-human and the branch waits for batch 6.

## Answers
- Q2278, Q2317-Q2321 (2026-11-20).

## Open follow-ups
- [moved 2026-11-22] `amb_room`: the old game's room tone was silent (no pick). S08 asks for a quiet ambience, so it plays the
  old first candidate `rubberduck_ambient1` at -12 dB as a placeholder. The designer picks the clip and level. — Q2432: silent, as the old game (core/47).
- [closed 2026-11-21] The first autoloads of the game's own are added: `Settings` (copied template, `game/settings/`) and `Sounds`.
  The Options menu (later) writes `audio/*_volume`. Settings' own Master apply is overridden by `Sounds` (mix times slider). — Settings and Sounds are the game's first autoloads by design; the Options menu comes in M4
- [closed 2026-11-21] The Sounds station stands at (13, 0, 13) beside the Movement and Cabinet stations, off the grid. — stations are placed by hand in the editor (Q2359)
- [closed 2026-11-21] Run output prints `ERROR: res://game/sock/pair_moment.tscn ... looks_graybox.tscn non-existent` on this
  branch's base (not this ticket's); the suites pass. — `game/sock/looks_graybox.tscn` is gone and the preload loop was fixed in 9b829af; the error no longer prints with the suites
- [moved 2026-11-21] Not built from the old game: see the Built log, "Old details not built". — to docs/migration/m06-backlog.md

## Built log
- Model: Sonnet (lead): a new system from a known design, data and wiring.
- 2026-11-20 Changed: the sound system (see Design); the old game's picks for the 19 named events plus the room tone,
  with licences; the Sounds station; footsteps by floor and the landing in the player. Files: `game/audio/*`,
  `game/settings/settings.gd`, `assets/audio/*`, `default_bus_layout.tres`, `game/zoo/stations/sounds.tscn`,
  `game/player/player.tscn` (Footsteps node), `game/zoo/zoo.tscn` (floor `surface` metadata), `project.godot`
  (autoloads Settings, Sounds), `tests/sounds_test.gd`, `tests/settings_test.gd`, `tests/hooks.gd` (scrub).
  Verified: `PASS 5376 checks, 200 cases` (`--touched`), `PASS rules`, `PASS asset_lint`.
  Old details not built: the other ~80 old events (UI clicks and hover, piano, voices, vacuum, radio, cat, fridge);
  `shares` (an event borrowing another's clips: the Door has its own pick); the sound bench and its ~800 candidate
  clips (only the picked clips came); `silent` flag; `layers`/`playlist` modes; window ambience and its fade;
  UI sounds and their +-1.5 dB jitter; the music duck in cutscenes; teammates' sounds from where they happen (Q246);
  pad rumble; the piano voice pool.
- Merged: 99dec60d (2026-11-20, branch core/17-sound-system)
