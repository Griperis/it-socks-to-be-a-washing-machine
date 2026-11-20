# Audit: what the player sees and hears in the core, old game against new

Read-only audit of 2026-11-20. Old = `reference/it-socks/` at v0.1.1 (paths below are relative to it). New = this
project. Skipped as already listed or decided: `old-details-backlog.md`, core/09, core/11, `decisions.md`, the real
Sock and Cabinet models (Q2249, Q2263, Q2265). Rules and numbers belong to the other audit. "none" in the new column
means nothing of it exists in `game/` or `project.godot` (checked by reading the zoo scenes, `player.tscn`,
`player.gd`, `held_view.gd`, `cabinet.gd` and a grep for Audio, Particles, Label, Environment).

## 1. Lighting, environment, post-processing, anti-aliasing

| difference | old (file:line, value) | new (file:line or "none") | how a player would notice |
|---|---|---|---|
| Tonemapper and exposure | AgX, exposure 1.1 (`game/house/room.gd:1173-1174`) | none: the zoo Environment sets only `background_mode = 2` and a sky (`game/zoo/zoo.tscn:22-24`), so Godot's default linear tonemap | Colours look flatter and harder, highlights clip instead of rolling off |
| Colour grade | contrast 1.06, saturation 1.12 (`room.gd:1175-1177`), then 1.1 and 1.2 with a 3-point LUT that follows the hour (`game/house/ambient.gd:70-75, 108-110`) | none | The old warm, slightly saturated picture against a neutral one |
| Vignette | full-screen shader at CanvasLayer -10, amount 0.5 by day, 0.8 at night, tint (0.05, 0.03, 0.06) (`ambient.gd:81-93, 111-112`) | none | Dark screen corners are gone |
| Ambient occlusion | SSAO on: radius 0.5, intensity 1.6, power 1.4 (`room.gd:1178-1181`; off only on the Low preset, `data/tuning/graphics.json` presets) | none | Creases, under the Cabinet and where Socks heap lose their soft contact shadow |
| Glow | on: intensity 0.35, bloom 0.04, HDR threshold 1.1, soft-light blend (`room.gd:1182-1186`) | none | No soft bloom on bright parts; the Pair pop sparkles lose their halo |
| Edge smoothing | MSAA 4x (`msaa_3d=2`) and FXAA (`screen_space_aa=1`) (`project.godot` [rendering]) | none: `project.godot` [rendering] holds only the D3D12 driver line (`project.godot:147-149`) | Jagged edges on Sock outlines, drawer fronts, the crosshair ring and the held Socks |
| Sky and what it lights | A day, dusk and night HDRI blended by a shader (`room.gd:33-37, 782-797`); ambient light from the sky at energy 0.7 and reflections from the sky (`room.gd:799-801`); radiance 256 (`graphics.json` high) | `ProceduralSkyMaterial` with defaults (`zoo.tscn:17-24`); ambient and reflection sources default | A plain blue gradient sky and flat ambient instead of the photographed garden light; metal has nothing to reflect |
| Sun | warm directional light, `shadow_blur` 1.5, max distance 18 m, 4 cascades, 4096 atlas, `SKY_MODE_LIGHT_ONLY` (`room.gd:1081-1088, 1192-1201`; `graphics.json` high); colour and energy by hour, noon (1.0, 0.93, 0.82) at 2.4 (`game/house/day_cycle.gd:37`) | one `DirectionalLight3D` with `shadow_enabled` only: default colour, energy 1, blur and 100 m distance (`zoo.tscn:45-47`) | Whiter, harder-edged and less contrasty light; shadows resolve differently across the room |
| Day cycle | a 20-minute day starting at 9:00 (`data/tuning/day.json:3-4`); sun, sky, ambient, lamps and the grade all follow (`day_cycle.gd:32-42`) | none: the light is fixed | No dusk, no night, no change in the Sock colours over a session |
| Lamps | a ceiling omni per room, colour (1.0, 0.88, 0.7), energy 1.0, range 6 m, shadows with blur 2.0 and bias 0.05 (`room.gd:112, 1060-1070, 810-812`) | none (open graybox floor, `zoo.tscn:30-40`) | No warm pools of light or lamp shadows under the Cabinet |
| Mess shadows | every lying Sock casts a shadow ("mess_shadows": "all", `graphics.json` high) | not checked and not set anywhere in `game/mess/mess.gd`; the Sock stand-in uses default shadow casting | Possible: no little shadows under the heap |
| Basement fill | warm fill colour `#ffd4a0`, 0.35 of the sky ambient below ground (`data/tuning/day.json:7,9`) | none | Cabinets in the old basement stood in warm light; the zoo is neutral |

## 2. HUD, crosshair, prompts, screen text

| difference | old (file:line, value) | new (file:line or "none") | how a player would notice |
|---|---|---|---|
| Crosshair shape | two bars, 18 x 2 px, centred, white at alpha 0.9 (`game/ui/hud.gd:121-129`, `CROSS_COLOUR` `hud.gd:19`) | a `Label` showing "+" in the default font, white at full alpha (`game/player/player.tscn:55-70`, `player.gd:36`) | A thin font glyph instead of a crisp bar cross; it sits slightly off-centre (the old code says why, `hud.gd:119`) |
| Crosshair "blocked" red | `Color(0.95, 0.25, 0.2)` at alpha 0.9 (`game/ui/ui_bits.gd:30`, `hud.gd:19`) | `Color(1.0, 0.25, 0.2)` (`player.gd:37`) | Slightly different red; same behaviour |
| Font and theme | one Theme with the Patrick Hand font (`assets/fonts/patrickhand`), ink-outlined white text, cream keycap panels (`ui_bits.gd:11-15, 33-34, 64-67`) | Godot default font, no Theme anywhere (`project.godot` has no `[gui]` theme; labels in `player.tscn:55-100`) | Every word on screen looks different and unstyled |
| Coins counter | top-left row: coin icon at 1.45 x font plus the number, 30 pt (`hud.gd:144-146`, `ui_bits.gd:466-474`); a pulse of 0.35 when a coin lands (`hud.gd:196-201`) | none: `Coins` exists as a Part (`game/coins/coins.gd`) but nothing in the HUD shows it (`player.tscn:53-100`, `zoo.tscn:130-136`) | Shelving a Pair pays out and the player cannot see it |
| Shelved-Pairs counter | "Pairs n/m" shown in the stats (`hud.gd:176-179`) | none | No progress of what is shelved |
| Hint rows beyond the listed ones | corner hints "Zoom [G]" and "Turn [R]" for a held Sock, "Cycle [Wheel]" with 2+ items, "Sprint [Shift]" (`game/ui/prompts.gd:97-105`) | none (the backlog lists only "Drop" and "Drop / hold: Throw") | The player is not told about zoom, turn or the wheel |
| Openable prompts | "Open the Drawer" / "Shut the Drawer" with the LMB keycap when aimed at a drawer, door or cupboard (`game/house/openable.gd:53-56`, `prompts.gd:28`) | none (an aimed drawer or Door shows nothing; the backlog covers only "Pick up") | No hint that a drawer can be opened |
| Keycap icons in prompts and the message | `{key_lmb}` style icons drawn inline, 32 px in prompts, 40 px in messages (`hud.gd:603-610, 678-681`) | text only | Words where the old game had mouse and key pictures |
| Message look | centred row at 70 % of screen height, 28 pt, white (red only for a refusal) (`hud.gd:174, 692-696`) | one label 24 px under the crosshair, always tinted red, default font (`player.tscn:72-88`) | The message is smaller, off the old spot and red even when it is not a refusal (there are none today) |
| Aimed Sock label position | row at 63 % of height, 28 pt, icon beside (`hud.gd:166-172`) | `Size` label 150 px right, 40 px below the crosshair (`player.tscn:90-105`) | Letter sits in a different place from the old one (the letter itself is in the backlog) |
| Throw ring | same look (Q2260) | `game/player/power_ring.gd` | none, noted only to confirm it is ported |

## 3. Menus reachable in core play

Q2161 (`decisions.md:59`) puts menus outside the first slice; flagged here because the designer asked for the core
to be a true slice.

| difference | old (file:line, value) | new (file:line or "none") | how a player would notice |
|---|---|---|---|
| ESC menu | `SessionMenu`: heading "Menu", "Options", "Back to title" (solo) and "Quit game", an ESC keycap "Back to the game"; the world keeps running, only the own player freezes (`game/net/session_menu.gd:1-9, 55-90`, `game/ui/menu_layer.gd:1-30`) | none: ESC only frees the mouse (`game/player/player.gd:139-141`) | No menu, no way to quit or change anything in a build |
| Options page | rows: Graphics (Auto, Low, Medium, High), SSAO, Master, Music, Effects, Ambience, Mouse speed, Invert Y, Pad speed, Pad rumble, Subtitles, Display, V-sync, FPS cap; cream keycaps and sliders, applied live (`game/ui/options_view.gd:55-73`) | none | No volume or sensitivity control, no graphics preset |
| Menu look | cream keycap panels, orange `#f29b4b` accent, ink `#3b2a22`, 28 and 24 pt (`ui_bits.gd:11-15, 33-34`) | none | n/a until a menu exists |
| Mouse cursor | the game's own ink-outlined arrow, everywhere (`game/core/settings.gd:56-57, 82-84`, Q361-Q362) | the system arrow when ESC frees the mouse | The system cursor appears on ESC |
| Graphics presets | High, Medium, Low sets MSAA, FXAA, render scale and FSR, shadow sizes, SSAO, glow (`data/tuning/graphics.json` presets) | none | No quality choice; and all of section 1 is also missing at "High" |

## 4. Furniture looks in core play

| difference | old (file:line, value) | new (file:line or "none") | how a player would notice |
|---|---|---|---|
| Cabinet drawers take no outline | `outlined = false` on the Cabinet's drawers ("the Cabinet's drawers take no outline"), so the aimed look is the prompt only (`game/campaign/cabinet_drawer.gd:36`) | core/11 plans one outline on every interactable | A decision for the designer: keep the old rule or outline the drawers too |
| Drawer tray layout | five staggered rows of 5, dx 0.26, dz 0.0725, z start -0.15, balls on the tray floor at y 0.04, ball scale 1.0, 25 Pairs per drawer (`cabinet_drawer.gd:8-17`; `data/tuning/drawers.json:4`) | 25 `Slot` markers on the drawer (`game/entities/drawer/looks_simple.tscn:56-130`), floor height in `game/entities/cabinet/cabinet.gd:30` | Not compared marker by marker; needs one still of both in line |
| Drawer slide | travel 0.40 m, 0.3 s, sine ease-out both ways (`cabinet_drawer.gd:10`, `openable.gd:174-177`) | travel 0.4 m, 0.3 s (`looks_simple.tscn` AnimationPlayer); ease-out both ways is in core/09 D12 | none beyond core/09 |
| Door and cupboard swing | Door 0.6 s (`data/tuning/doors.json:4`), kitchen units `SWING_TIME` 0.35 (`openable.gd:27`), all sine ease-out | Door 0.6 s, cupboard 0.4 s (`game/entities/door/looks_graybox.tscn`, `game/entities/cupboard/looks_graybox.tscn`) | The cupboard is 0.05 s slower; barely seen |
| Sock creature as a teammate | waddle, bob 0.035, sway 3 deg, pupils turn to the nearest player, squash and stretch on landing (`data/tuning/avatar.json`) | a capsule at the sent pose (`game/parts/avatar/avatar.gd:1-10`) | A teammate is a capsule; probably M0.6 and the models, flagged so it is on record |

## 5. Camera feel

The two match on field of view (75, zoom 50, 0.15 s, `data/tuning/view.json`; `player.tscn:43`, `hands_tuning.gd`),
eye height (stand 1.7, crouch 1.0, eyes 0.1 below the top: `game/player/player.gd:34-36`; `move_tuning.gd:21-22`) and
the slower look while zoomed. The old camera has no head bob or roll outside a knockdown. Found no further difference
in the camera.

## 6. Sound: what the new core has against the old

The new game has no audio at all (`grep AudioStream` over `game/` finds none) and no bus layout. The backlog's M1.1
list covers footsteps, landing, pick, drop, cycle, refuse, pair, pop, throw charge, throw, drawer open and shut, the
Door, bounce and pad rumble. Not on it:

| difference | old (file:line, value) | new | how a player would notice |
|---|---|---|---|
| Shelving sound | "shelve", `cc0/kenney_book_place1`, 3D at the drawer (`data/sounds.json` events.shelve; `game/audio/sound_bank.gd` EVENTS) | none | A Pair goes into a drawer silently |
| Cupboard open and shut | `cupboard_open` `cc0/qubodup_door_open1`, `cupboard_close` `cc0/qubodup_door_close1`, 3D (`sounds.json`; `openable.gd:39-47` CUE_STEMS) | none (the zoo has a cupboard, `game/entities/cupboard/`) | Silent cupboard |
| Coins landing | "coins" `cc0/starninjas_coin1`, flat, plays when a coin reaches the bank | none | Payout has no sound (the +N flight itself is M4) |
| Muffling behind a shut Door | every 3D sound and the ambience of SFX, Ambient and Music play on a "Muffled" copy of their bus: -9 dB and a low-pass at 900 Hz while a shut room Door lies between the ear and the source (`game/audio/sfx.gd:158-188`; `data/tuning/doors.json:5-6`) | none | A sound behind the zoo's Door is as loud as in the open |
| Ambience | looping layers: room tone (silent pick), the fridge hum at (0.42, 1.0, 0.42), the ticking clock at (9.49, 1.95, 0.05), and birds and park noise at each window, gated as a 4 to 8 s call and a 15 to 40 s gap, fading over 1.5 s, full within 0.3 m and gone at 1.5 m of the opening, level -12 dB (`sfx.gd:34, 482-524`; `data/tuning/audio.json`; `sounds.json` amb_outside) | none | The zoo is silent; the old rooms were never silent (tied to the house, so a designer decision whether the zoo gets any) |
| Music | none in core. The Radio is the game's only music, heard on the Music bus; a cutscene ducks it to 0.25 over 0.5 s (`sfx.gd:15-17`; `game/audio/music_duck.gd`; `audio.json` cutscene_duck_*) | none | no difference in core play |
| UI sounds | `ui_click` -8 dB and `ui_hover` -20 dB on the UI bus, a level jitter of 1.5 dB either way plus the pitch jitter, 4 voices; menu open and close are silent (`game/audio/ui_sounds.gd:10-16`; `sounds.json`) | none | Menus (when they come) are mute |
| Zoom and crouch sounds | both marked silent (`sounds.json` zoom_in, zoom_out, crouch); jump has an empty pool so it is silent too | none | no difference |

## 7. How the old game's audio was organised (for the "plug-and-play" sound system)

**Files.** `game/audio/sound_bank.gd` (the event table and the data), `game/audio/sfx.gd` (player; the `Game.cue()`
and `cue_at()` front), `game/audio/ui_sounds.gd` (autoload for menu buttons), `game/audio/music_duck.gd`,
`assets/audio/candidates.json`, `data/sounds.json`, `data/tuning/audio.json`, `tools/sound_bench.tscn` (F6 bench).

**Catalogue.** `SoundBank.EVENTS` (`sound_bank.gd:26-143`) is one line per event: a group, a label, `space`
("flat" or "3d"), a `bus`, and optional `loop`, `mode` ("layers" or "playlist"), `shares` (the event whose candidates
it borrows, so a new event needs no new clips) and `instrument` (the piano). About 100 events. Code asks by name:
`cue("pick")` for flat, `cue_at("drawer_open", pos)` for 3D. An event named only in `sounds.json` still works (group
"Other", flat, SFX). The tests fail on an event no table knows.

**Candidates and picks (plug-and-play).** `assets/audio/candidates.json` lists every clip: id (`cc0/owlish_cloth5`,
`synth/cycle_a`), file, author, licence, label, loop. About 420 CC0 `.ogg` files plus 398 synthesised ones, made by
`tools/gen_sounds.py`; licences in `assets/audio/SOURCES.md`. The designer listens in the sound bench and the bench
writes `data/sounds.json`: per event `picks` (candidate ids), `volume_db`, `note`, optional `silent`. Empty picks play
the first candidate; `silent: true` plays nothing. So the whole sound set is swapped by editing a JSON, with no code.

**Variation.** A pool of 2 to 4 picks plays one chosen at random per play (`sfx.gd:549-555`); no repeat guard. Examples:
`pop` has 2 clips at +3 dB, `climb` 2, `cat_meow` 3.

**Pitch randomisation.** `pitch_scale = 1 + randf(-j, +j)` with `pitch_jitter` 0.05 (`sfx.gd:558-559`;
`audio.json`), applied to every play; UI clicks add 1.5 dB level jitter (`ui_sounds.gd:13`).

**Buses** (`sfx.gd:25-27, 157-180`, built in code, no `default_bus_layout.tres`): Master plus SFX, Ambient, Music and
UI, each sending to Master; and "MuffledSFX/Ambient/Music" copies (prefix "Muffled", sending into their bus, -9 dB, a
900 Hz low-pass). Mix (`audio.json`): master 0.6, sfx 1.0, ambient 0.5, music 0.8, ui 0.8, each times the Options
slider (Master, Music, Effects, Ambience, UI map to those buses, `settings.gd:48-54`), stored as dB with -80 for 0.

**Voices.** Eight flat `AudioStreamPlayer`s and eight `AudioStreamPlayer3D`s used round-robin (`sfx.gd:30-31, 117-129`);
a ninth pool for piano. Looping layers get their own players.

**3D attenuation.** World events use `AudioStreamPlayer3D` with `unit_size` 3.0 and `max_distance` 20.0
(`audio.json` world_unit_size, world_max_distance; `sfx.gd:495-496`); default attenuation model. Windows use their
own distance fade in code (attenuation disabled). A teammate's own sounds (pick, throw) play from where they happen
(`play_from`, Q246).

**Footsteps by surface.** The Player emits `cue` "step_wood" or "step_tile" every `step_distance` 1.4 m walked on the
floor (the stride accumulates horizontal speed times time, reset on landing); the surface is
`FlatLayout.floor_at(position)`, "tile" if the finish ends in "tile", else wood (`game/player/player.gd:423-444`).
Clips: `step_wood` `cc0/kenney_footstep00`, `step_tile` `cc0/owlish_hard1`. A landing plays "land"
(`cc0/qubodup_jumpland`) from a fall of 3.0 m/s (`land_speed`).

**Music.** None except the Radio device (flat/50, Q364), on the Music bus at 0.8; the TV also plays on Music. A
`MusicDuck` ramps the bus to 0.25 over 0.5 s during cutscenes. Menus never pause the game (Q253).

**Levels per event** (`sounds.json`): most 0 dB; `pop` +3; `ui_click` -8; `ui_hover` -20; `climb` and `elevator_creak`
-6; `lamp_on` and `lamp_off` -6; `amb_outside` -12; `drag_scrape` -4.

## 8. What a player would notice most

1. No sound at all, on any action (the M1.1 list plus the shelving, cupboard and Door-muffling gaps above).
2. The picture: no AgX tonemap, no grade or vignette, no SSAO, no glow, and no anti-aliasing at all (old: MSAA 4x
   plus FXAA); the sky and the light are Godot defaults, with no HDRI, no tuned sun and no day.
3. All on-screen text uses Godot's default font with no theme, so the crosshair, message and letters look unlike the
   old Patrick Hand style.
4. The crosshair is a "+" glyph instead of the two crisp bars.
5. No Coins or Pairs counter, so a payout is invisible.
6. The old hint rows (Zoom, Turn, Cycle, Sprint) and the "Open the Drawer" prompt are missing.
7. No ESC menu or Options (volumes, mouse speed, graphics preset, quit); ESC only frees the mouse and the system
   cursor shows.
8. A teammate is a capsule, not the waddling Sock creature (likely M0.6).
9. Cabinet drawers: the old game did not outline them; core/11 will. Needs the designer's word.
