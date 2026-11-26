---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: house
priority: now
created: 2026-11-26
done:
blocked_by: ["[[154-batch-c-groundwork]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 3", "suggested model: opus"]
terms: [the house, Session]
suites: [day, save, net_day, look, house]
---

# The day: the clock, the sun and moon, the sky

The house gets the old 20-minute day (Q2693): a New Game starts at 9:00, the hour runs on at 24 hours in 20 real
minutes, the sun crosses the south low and warm, the moon lights the night, the sky turns to the dusk and night photos,
and every machine runs the Host's hour. Build `docs/architecture/day-and-exterior.md` "The day", "The shape" (`Day`,
`DayLight`), "How it is authored", draft 149-G:

- `Day` (`game/day/day.gd`, a Part in `house.tscn` beside `Lights`): `hour` as decided state, `shown_hour()`, the
  verbs `start` and `sync` (Host only: on a join's `linked` and every `sync_every`), saved with the shown hour;
- `DayTuning` (`length_minutes` 20, `start_hour` 9, `sunrise` 6, `sunset` 20, `sun_max_elevation` 28,
  `sunset_azimuth` 150, `moon_elevation` 40, `moon_azimuth` 60, `lamps_on` 19.5, `lamps_off` 7, `basement_ambient`
  0.35, `basement_tint` `#ffd4a0`, and the technical `sync_every`, `sky_every`, `light_every`, `sky_step`);
- `DayKey` and the nine old keys as dropped `.tres` in `game/day/keys/` (listed with `ResourceLoader.list_directory()`);
- `DayLight` (a view on every machine): the Sun (direction, colour, energy; hidden at 0), the sky's `phase` and
  `energy` (re-baked only when they moved by `sky_step`), the ambient, the basement's fill (a ReflectionProbe:
  `basement_ambient` x the sky's energy x the ambient, in `basement_tint`), `HouseLights.night`, and the signal
  `lamps_switched(on)` for core/161 (not on the first sample);
- `Picture`'s `sky_material()` and `environment()` getters;
- `game/look/day_sky.gdshader` with the old dusk and night panoramas (`phase` 0 is today's noon, so the zoo is
  unchanged), the two CC0 Poly Haven photos (`stuttgart_suburbs_2k.hdr`, `street_lamp_2k.hdr`) in `assets/sky/` with
  their `SOURCES.md` rows and credits;
- the Day station filled (shell from core/154 at x = 222): a small room of house kit pieces with two windows and two
  lamps (one on a "locked" level), its own `Day`, `DayLight`, `HouseLights`, `WorldEnvironment`; a board with one
  `day_key_button.tscn` per key in the folder (hour and swatch; a click sets the station's hour), an hour slider, a
  speed switch (x1, x60), a "Lock the level" switch. The rest of the zoo stays at noon (Q2299).

Behaviour lines (`day-and-exterior.md` "The day"): all 8.

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
`DayTuning` in the inspector (every old number `# placeholder:`, Q2693); a key is a dropped `.tres`; a sky photo is a
texture on the material; the station's board instances a button scene per key (Q2658). No clip motion: the sun's path
is the hour's.

## Acceptance
- Real path: the Solo New Game launched from the title into the house, the game's own clock running (a test
  `DayTuning` of a short day), to the Sun light and the sky material the player's camera renders at 21:00: moonlight
  from the south-east, the night photo.
- A New Game starts at 9:00; the Sun moves along the old path, is hidden at sunrise and sunset; the sky's phase is 1 at
  20:00 and 2 at 23:00; the basement's fill follows the sky.
- A save at 18:00 and a load show 18:00; a Guest's hour matches the Host's within 0.01 h, a late Guest's too.
- The zoo's other stations stay at noon; a key `.tres` dropped into the folder shows on the station's board.
- Placeholders: `DayTuning`, the nine keys.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The old 20-minute day, its numbers as placeholders; nothing else of the old day (Q2693, 2026-11-26).
- The zoo keeps its fixed noon (Q2299).

## Open follow-ups
