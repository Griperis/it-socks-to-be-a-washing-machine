# The day cycle and the exterior view

**Status: build plan for batch C (designed in core/149 on the designer's answers Q2693, Q2694, Q2706; 2026-11-26).
Not filed yet: the drafts below are for the lead to file.** There is no behaviour list file for these two pieces: the
lead's grilling settled them (Q2693, Q2694; `docs/migration/m4-lists/batch-c.md`), and the lines below are written
from the old game here. The waves are with the Elevator's, at the end of `docs/architecture/elevator.md`.

## What it owns

The in-game hour and its 20-minute day (Q2693): the sun's path and the moon by night, the dusk and night skies, the
light and ambient by the hour, the lamps on and off by the clock on every floor (Q2706); the outside seen through the
windows (Q2694): garden, fences, trees, street, light wells; what a World keeps of the hour. The zoo keeps its fixed
noon (Q2299): only the house and the Day station run a day.

It does not own the floor locks or a floor's reveal (core/80, built: `HouseLights.set_level_dark`, `reveal`), the
picture's presets, grade and vignette at noon (core/18, built: `Picture`), the front and garage doors (they stay shut,
Q2514, Q2694), the TV, the Radio or the Cat (none cares about the hour: core/150, core/151), or the X-ray's on and off
sounds the lamps share (core/152's). Where they meet it, it names the seam.

## Behaviour list (from the old game; refs in `reference/it-socks/`)

Short forms: DC = `game/house/day_cycle.gd`, RM = `game/house/room.gd`, SKY = `game/house/day_sky.gdshader`, AM =
`game/house/ambient.gd`, EG = `game/house/exterior_glow.gdshader`, MX = `tools/blender/make_exterior.py`, DJ =
`data/tuning/day.json`, G = `game/core/game.gd`, SB = `game/audio/sound_bank.gd`. A line marked **(ask)** is a detail of
the old day that Q2693's "nothing else of the old day" may drop; it is asked under the ticket's Open follow-ups and is
built only on the designer's answer (the small details rule, Q2277).

### The day (Q2693)
- When a New Game starts in the house, then the hour is 9:00 (`start_hour`), and it runs on at 24 hours in 20 real
  minutes (`length_minutes`), wrapping past midnight. (ref: DJ; G:352, G:558-559, G:755)
- When the World is saved or a player joins, then the hour is in the save and the join snapshot; every machine runs
  the same hour from there. (ref: `game/core/saves.gd`:29, :123)
- When the hour passes, then the sun moves: up at 6:00 in the east, across the south at a low 28 degrees at most so
  warm patches fall through the windows, down at 20:00 in the south-west (150 degrees from east). (ref: DC:9-22,
  DC:98-106)
- When it is night (20:00 to 6:00), then the light is the moon's, still in the south-east sky (40 degrees up, 60 from
  east), pale blue and faint; the light's energy is 0 at sunrise and sunset, where sun and moon swap. (ref: DC:14-16,
  DC:32-42)
- When the hour passes, then the light's colour and energy, the sky's phase (day, dusk, night) and brightness, the
  ambient and the lamps' brightness follow the nine old keyframes (0:00, 4:30, 6:00, 7:30, 12:00, 16:30, 18:48, 20:00,
  21:30), eased between keys. (ref: DC:31-42, DC:69-96)
- When it is dusk or night, then the sky seen through the windows and lighting the rooms is the dusk photo (the
  Stuttgart suburbs) or the night photo (the street lamp), blended with the day's (the suburban garden); each photo is
  turned so its bright spot sits where the sun or moon is, and above its trees only its sky shows. (ref: SKY; RM:33-45)
- When the sky's phase or energy changes, then it is re-baked only when it moved enough (a still midday or night
  costs nothing). (ref: RM:104-110, RM:368-373)
- When the hour passes, then the basement's fill follows the sky: 0.35 of the sky's ambient (`basement_ambient`) in its
  warm tint `#ffd4a0` (`basement_tint`), since only the light wells' sun and the lamps light it otherwise. (ref: DJ;
  RM:294-301)

### The lamps by the clock (Q2693, Q2706)
- When the hour reaches 19:30, then the lamps switch on; at 7:00 they switch off; by day only the basement's lamps stay
  on (`basement_lamps_by_day`). (ref: DC:23-25, DC:58-61; DJ; port: `HouseLights.day_level`)
- When it is night, then every lamp on every floor is on, a locked floor's too: the clock wins over core/80's rule
  that a locked floor's lamps stay off (Q2706). By day a locked floor's lamps stay off and its reveal (fade in 0.6 s,
  lit 6 s, fade 1.2 s) shows as core/80 built it.
- When the lamps are on, then their brightness follows the keyframes' lamp factor (1.0 by day to 1.5 at night).
  (ref: DC:31-42, DC:93-94)
- **(ask)** When the lamps switch, then a click plays, flat: `lamp_on` at dusk, `lamp_off` in the morning (sharing the
  X-ray's on and off pools). (ref: SB:73-74; `game/audio/sound_installer.gd`:56; RM:340)
- **(ask)** When the lamps are on, then the globe shades' paper glows with them (0.8 at a factor of 1), dark when
  they are off or their floor is dark. (ref: RM:48-49, RM:341-350; flat/28 Q203)
- **(ask)** When it is night, then the window panes darken to night blue (`NIGHT_GLASS` 0.02, 0.04, 0.14) by the
  keyframes' night share. (ref: DC:26-27, RM:360-366)
- **(ask)** When the hour passes, then the colour grade follows it (warmer at dusk, bluer at night) and the vignette
  closes in at night (0.5 to 0.8). (ref: AM:1-3, AM:99-112; graphics/01 Q1402)
- **(ask)** When the hour passes, then the wall clock's hands show it (the clock is not ported yet: its model would be
  one more asset). (ref: RM:6, RM:32, RM:528-546; `tools/blender/make_clock.py`)

### The exterior view (Q2694)
- When a player looks out of a window, then they see the old outside, a simple soft stylised low-poly world lit by the
  day: north the front garden (a path from the front door to a gate in the picket fence, bushes, the garage ramp
  through a gap in the fence), the quiet street with a parked car and two street lamps, the houses across; east the
  side lawn, a board fence, the neighbour's bungalow; south the patio, the back garden (a washing line with socks, an
  apple tree, a shed, flower beds), the back fence and the houses behind; west the side lawn, a board fence, the
  neighbour's house; a ring of distant tree tops on every side. (ref: MX:1-30)
- When a player looks out of a basement window, then it looks into a light well: a concrete pit with a gravel floor and
  a grate over it at lawn level (0.9 m out from the wall, 0.25 m wider each side). (ref: MX:12-15; Q461;
  house-kit-plan "Windows")
- When the garage is seen from outside, then a concrete ramp runs down from the pavement to its shut up-and-over door,
  between retaining walls with a rail, a drain grate at its foot. (ref: MX:15-16; Q453)
- When the outside is drawn, then it casts no shadow, and each side is its own mesh so the camera culls the sides it
  cannot see. (ref: MX:32-41; RM:520-525)
- **(ask)** When the lamps are on, then the neighbours' windows, the street lamp heads and the pools of light under
  them glow (1.6 at a factor of 1), switching with the house's lamps. (ref: EG; RM:52-56, RM:351-355)
- When the front door or the garage door is clicked, then it does not open: the exterior is a view only, nobody walks
  out (Q2514, Q2694; built: `shut_front_door.tscn`, `shut_garage_door.tscn`).

## The shape

- **`Day`** (`game/day/day.gd`, a Part, in `house.tscn` beside `Lights`): the hour as decided state. State: `hour:
  float` (the hour as of its last answer). Each machine shows `shown_hour()` = `hour` + the real seconds since that
  answer x the rate (24 / (`length_minutes` x 60)); `save_state()` gives the shown hour, so a save keeps the hour to the
  second. Verbs: `start` (Host, a New Game: `hour = start_hour`), `sync` (Host only: `hour = shown_hour()`, asked when a
  player joins, Session's `linked`, and every `sync_every` s, so every machine's hour stays the Host's within a frame).
  The day runs while the level runs and stops when the game pauses, as the old. No Guest verb: nothing a player does
  changes the hour.
- **`DayLight`** (`game/day/day_light.gd`, a Node in `house.tscn`, a view on every machine): samples the keyframes at
  `shown_hour()` and writes the Sun (direction, colour, energy; hidden at 0), the sky material's `phase` and `energy`
  (only when they moved by `sky_step`, every `sky_every` frames), the Environment's ambient, the basement's fill (a
  ReflectionProbe over the basement, its ambient `basement_ambient` x the sky's energy x the ambient, in
  `basement_tint`), and `HouseLights.night` and `HouseLights.lamp_factor`; it emits `lamps_switched(on)` when the lamps
  cross 19:30 or 7:00 (not on the first sample, so a load switches silently). Its exports name what it writes (the
  Sun, the `Picture`, `Lights`, the basement probe; 149-H and 149-I add the glass, shades and the exterior's glow).
  `Picture` works on its own copies of the Environment and Sky (core/18): it gains `sky_material()` and
  `environment()` getters, so the day writes the copies on screen.
- **`HouseLights`** (built) changes in 149-H: Q2706's rule in `_switch()`: at night every lamp is on whatever
  `dark_levels` says; by day as now (the day level's lamps, the reveals, a locked floor dark); `lamp_factor`
  multiplies every lamp's base energy.
- **The exterior** (`game/house/exterior/exterior.tscn`, a Looks-only scene: no script, no colliders, cast shadows off,
  the four sides `Exterior_North`, `_East`, `_South`, `_West` as MeshInstance3D), instanced under the house as
  `Exterior`; graybox first (a lawn plane, the light wells, fence and house boxes, a street strip), then the ported
  model (AS-E). The front and garage doors stay the shut StaticBodies they are.

### The kinds of state

| What | Kind | Where |
|---|---|---|
| the hour | decided state | the `Day` Part (`hour`), written by `start` and `sync` |
| the hour between answers, the sun, sky, ambient, lamps, glass, glow | looks | `DayLight` on each machine, from `shown_hour()` |
| the floors' locks and reveals | decided state, core/80's | `Stages`; `HouseLights` shows them |

## How it is authored (Q2607)

- **Typed Resources edited in the inspector:** `DayTuning` (`game/day/day_tuning.tres`, every old number
  `# placeholder:` Q2693): `length_minutes` 20, `start_hour` 9, `sunrise` 6, `sunset` 20, `sun_max_elevation` 28,
  `sunset_azimuth` 150, `moon_elevation` 40, `moon_azimuth` 60, `lamps_on` 19.5, `lamps_off` 7, `basement_ambient`
  0.35, `basement_tint` `#ffd4a0`, `night_glass` (0.02, 0.04, 0.14), `shade_glow` 0.8, `exterior_glow` 1.6; and the
  technical ones (not the designer's): `sync_every` 10 s, `sky_every` and `light_every` (the old frame strides),
  `sky_step` (the old least change worth a re-bake).
- **Added by dropping a file, no code:** each keyframe is a `DayKey` (`game/day/day_key.gd`: `hour`, `light_colour`,
  `light_energy`, `sky_phase`, `sky_energy`, `ambient`, `lamps`, `night`), one `.tres` per key in `game/day/keys/` (the
  nine old ones: `key_0000.tres` .. `key_2130.tres`); `DayLight` lists the folder with `ResourceLoader.list_directory()`
  and sorts by `hour`, so a new key is a dropped file. The skies are three textures on the sky material: a new photo
  is a swapped texture.
- **The zoo station** `game/zoo/stations/day.tscn` (its own things under `game/zoo/day/`), built from the data at load
  (Q2337): a small room of house kit pieces with two windows and two lamps (one on a "locked" level), its own `Day`,
  `DayLight`, `HouseLights` and `WorldEnvironment` with the day sky; a board with one button per `DayKey` in the folder
  (its hour and colour swatch: a click sets the station's hour to it; a new key shows with no other change), an hour
  slider, a speed switch (x1, x60), a "Lock the level" switch (to see Q2706 at night), and in 149-I a cut of the
  exterior's graybox outside one window. The rest of the zoo stays at noon (Q2299).
- **Authored in nodes (Q2658):** the station's board (`day_key_button.tscn` instanced per key), the exterior, the
  basement probe, the Sun and the Environment are nodes in scenes; code only sets their values.
- **Motion:** the day has no clip motion; the sun's path is the hour's (a sampled light, as the old). The lamps switch
  at once, as the old.
- **Sounds** (149-H, if kept): `lamp_on`, `lamp_off` SoundEvents (flat), sharing the X-ray's on and off clips (core/152
  adds `xray_on` / `xray_off`; whichever lands first adds the clips).
- **Skies:** `game/look/day_sky.gdshader` grows back the old shader's dusk and night panoramas (`phase` 0 is today's
  noon, so the zoo's sky is unchanged); the two photos (`stuttgart_suburbs_2k.hdr`, `street_lamp_2k.hdr`, CC0 Poly
  Haven, the old game's) are copied into `assets/sky/` with their rows in `SOURCES.md` and the credits.

## Saves, joins and the Lobby

Nothing writes save code: `Day` is saved and joined by its State group, its `save_state()` giving the shown hour. A
joiner gets the snapshot's hour, then the Host's `sync` answer on `linked` (the snapshot is a frame old by then).
`tests/saves/shape.json` gains the `Day` part once (149-G).

## Seams to the other pieces

- **core/80 (`HouseLights`, the floor locks; built):** Q2706 is the one rule: at night the clock wins (every lamp on);
  by day the locks keep their floors dark and the reveal shows as built. `set_level_dark` and `reveal` keep their
  callers; `night` (already "the day cycle will set it") is set by `DayLight`; 149-H adds `lamp_factor`.
- **core/18 (`Picture`; built):** the day writes the Picture's copies of the Environment and the Sky through two
  getters; the presets, the grade at noon and the vignette stay the Picture's. The grade and vignette by the hour (the
  old `ambient.gd`) are asked (above).
- **The Elevator (`elevator.md`):** nothing of the hour. The car's caged lamp is the Elevator's Looks, not a house
  lamp.
- **core/150 (TV, Radio), core/151 (the Cat):** nothing of the hour (`batch-c.md`); the Cat's "sunny patch" naps are
  fixed spots by the low windows, not the sun's (core/151).
- **core/152 (the X-rays):** the lamps' clicks share its on and off pools.
- **The house (`house.md`):** the front and garage doors stay shut (Q2694 keeps Q2514); `house.md`'s "until the
  exterior ticket brings the door entities" is closed by Q2694 (no door entities: the doors stay the shut bodies).

## Changed technically from the old (no choice: tell the designer at the sitting)

- The hour is a Part's decided state with a Host `sync`; the old let each machine run its own clock from the join.
- The keyframes are dropped `.tres` files, not a const table; the lamps and the Sun are written by a view node, not
  by the 1,199-line `Room`.
- The exterior is a Looks scene placed in the house, not built and re-materialed in code.

## The designer's answers this piece rests on

- Q2693: the old 20-minute day: the sun's path, the dusk and night skies, the moon, and the lamps on and off by the
  clock (19:30 and 7:00), the old `day.json` numbers as placeholders; nothing else of the old day.
- Q2694: the exterior is a view only (garden, fences, trees, street, light wells) through the windows; the front and
  garage doors stay shut.
- Q2706: the day's lamps follow the clock on every floor, locked or not: at night every lamp is on.
- Q2299: the zoo keeps its fixed noon.
- Q2705: batch C's models are ported by the port rules (the exterior with them).

## Draft tickets (ready-for-agent; the lead files them)

### 149-G The day: the clock, the sun and moon, the sky
- **Lines:** "The day" (all 8).
- **Build:** `Day`, `DayTuning`, `DayKey` and the nine keys, `DayLight` (Sun, sky, ambient, basement probe,
  `HouseLights.night`), `Picture`'s two getters, the three-panorama sky shader, the two photos with their sources and
  credits; `Day` and `DayLight` placed in `house.tscn`; the Day station.
- **Acceptance:** a New Game in the house starts at 9:00; with a test `DayTuning` of a short day the hour passes, the
  Sun the camera sees moves along the old path, is the moon by night and is hidden at sunrise and sunset; the sky's
  phase is 1 at 20:00 and 2 at 23:00; a save at 18:00 and a load show 18:00; a Guest's hour matches the Host's within
  0.01 h, and a late Guest's too; the zoo's other stations stay at noon. **Real path:** the Solo New Game launched from
  the title into the house, the game's own clock running, to the Sun light and the sky material the player's camera
  renders at 21:00 (moonlight, the night photo).
- **suites:** [day, save, net_day]
- **Model:** opus.
- **Authored:** `DayTuning` in the inspector; a key is a dropped `.tres`; a sky photo is a texture on the material.

### 149-H The lamps follow the clock
- **Lines:** "The lamps by the clock" lines 1-3 (19:30 and 7:00, the basement by day; at night every lamp, locked
  floors too, Q2706; the lamp factor), and those of lines 4-8 and the exterior's glow the designer keeps (Open
  follow-ups).
- **Build:** Q2706 in `HouseLights._switch()`; `lamp_factor`; `DayLight`'s `lamps_switched`; what the answer keeps of:
  the `lamp_on` / `lamp_off` sounds, the shades' glow, the night glass, the grade and vignette by the hour, the
  exterior's glow (149-I's material). A kept wall clock adds an asset ticket (the old `make_clock.py`) and its hands'
  line here.
- **Acceptance:** in the house at 19:29 the first floor's lamps are off while it is locked; at 19:31 every lamp on every
  floor is lit, the locked floors' too; at 7:01 only the basement's are; by day a floor's reveal still fades in, holds
  and fades out; a load at 22:00 shows every lamp on with no switch sound. **Real path:** a New Game from the title,
  the game's clock run to 19:31, to the first floor's ceiling light visible and lit at its base energy x the factor.
- **suites:** [day, house_lights, stages]
- **Model:** sonnet.
- **Authored:** the hours and glows in `DayTuning`; the lamps' factor in the keys.

### 149-I The exterior seen through the windows
- **Lines:** "The exterior view" (all 6; the glow's line only as the designer answers).
- **Build:** `game/house/exterior/exterior.tscn` (graybox, its four side meshes, the light wells at the port's basement
  windows, the garage ramp at the port's garage door), instanced in `house.tscn`; the glow material (the old
  `exterior_glow.gdshader`, its `glow` uniform for 149-H); a cut of it in the Day station.
- **Acceptance:** from inside the living room a ray from the player's eyes through the south window meets the
  exterior's back garden, and through a basement window the light well; the exterior has no collider and casts no
  shadow; the front door still does not open. **Real path:** the player walks to the living room window (movement
  input) and looks out; the camera's view ray through the window hits `Exterior_South`.
- **suites:** [house, day]
- **Model:** sonnet.
- **Authored:** a Looks scene; the model swaps in by replacing the graybox's meshes (AS-E).

### AS-E The exterior's model (asset ticket, `assets/<NN>`)
Ported from the old `tools/blender/make_exterior.py` (`assets/house/exterior.glb`) by the port rules (Q2705, the old
vertex colours): refitted to the port's house (house-kit-plan: its footprint, the 22 windows' moves W1-W22, the light
wells moving with the basement windows, the ramp to the port's garage door, the front step at the port's front door),
the four side meshes, the `exterior_glow` surface kept. Its scene replaces 149-I's graybox meshes under the same
names; the before-and-after strip from the same windows in `builds/review-exterior/`; stops at its first line-up
(`ready-for-human`). Model: opus. No core ticket waits for it.

### Behaviour lines not in a draft
None: every line is in 149-G, H or I; the **(ask)** lines are built or dropped by the designer's answer.
