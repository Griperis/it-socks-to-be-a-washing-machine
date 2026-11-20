---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: core
priority: now
created: 2026-11-20
done:
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
To be drafted by the agent here first (classes, the catalogue, the voice pools or players, the bus layout file, how
muffling knows a Door is between, how the floor says its surface), then built. Godot's own nodes first; code shape
Q2251-Q2253.
**Parked scope:** footsteps, the landing, ambience and the station are wired now. The game's other events (pick, drop,
the Throw, pairing, the Cabinet, Doors) are in the catalogue with their clips and named in the station, but the calls
from the game's code are added when batch 6 comes (the motions are final then); list where each call will go.

## Acceptance
- One test per behaviour line; the real-path case: walking in the zoo plays steps by surface; the station plays an
  event.
- The ticket goes ready-for-human and the branch waits for batch 6.

## Answers
- Q2278, Q2317-Q2321 (2026-11-20).

## Open follow-ups

## Built log
- Model: Sonnet (lead): a new system from a known design, data and wiring.
