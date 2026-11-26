# The TV and the Radio

**Status: build plan for batch C (designed in core/150 on the designer's answers Q2697-Q2706, 2026-11-26). Filed by
core/153: 150-A core/163, 150-B core/164, 150-C core/165, 150-D core/166, AS-C2-4 assets/27, AS-C2-5 assets/28; the
places in the house in core/174, the ride in core/175; the sounds and the station's shell in the groundwork core/154.
The build order is `docs/migration/milestones.md` "Batch C".** Behaviour list: `docs/migration/m4-lists/13-tv-and-radio.md` (33 lines, here R1-R33 in its
order). The other half of this design, the vacuums and the detector, and the two rules every carried device follows
(**the whole-Hands rule**, **the thrown-knock rule**) are in `docs/architecture/devices.md`.

## What it owns

The TV (its knob, its picture, its four shows, its sound), the Radio as the game's only music (its knob, its six
channels and their playlists, its sound everywhere and near, its credits) and as a carried thing (picked, carried,
put down, handed off, thrown, saved), the broadcast clock both share, and the Radio's place under the cutscene's
music duck (built in batch A).

It does not own: the music duck itself (`docs/architecture/voice.md` V5, `Voices`, built), the Elevator's carry rule
(core/149: the Radio is one lying `Carriable` it carries), the Secrets that hang here (Radio Dance, the Radio in the
drum: Q2682, Q2699), the main menu's music (list 01).

## The designer's answers this doc is built on

- **Q2704** (list 13 questions 1-6, 8): as the old. The four shows with their texts and timings; the old tracks; the
  hint names the current channel; a load turns the TV off (Q2559 too: the Radio keeps its channel); the Radio's
  "near" reaches into rooms open to its room; Socks lying on a picked-up Radio fall; the TV's spot in front of the
  living room's north window.
- **Q2700** (list 13 question 7): a thrown Radio that hits a Teammate: a full-charge Throw knocks down, a weaker one
  bounces off to their feet, never caught; an Elevator rider is never hit (`devices.md` "The thrown-knock rule").
- **Q2699**: every carried thing rides the Elevator by one item rule (the Radio as the old); putting things into the
  washer's drum is a Secret and waits (the Radio in the drum, R32).
- **Q2705** (list 13 question 9): the TV and the Radio models are ported by the port rules, each with its strip and the
  old colours.
- **Q2697**: motion is clips in a Looks scene.

## The shape

Inheritance one step (Q2251). One Part class serves both devices: the knob. Everything else is a view.

| Scene | Nodes | State kind |
|---|---|---|
| `game/entities/radio/radio.tscn` | root `Radio` (Node3D, a body on the house layer while it lies); `Carriable` (title "Radio", `handable` on, `throwable` on, `slot` `hold_slot_radio.tres`); `ChannelKnob` (Part); `RadioSound` (a view: an `AudioStreamPlayer3D` that follows the model); `Looks` (the model at 1.5 times its modelled size, R1) | decided (Parts); the sound is looks |
| `game/entities/tv/tv.tscn` | root `TV` (a static body: 1.5 x 0.46 x 1.22 m); `ChannelKnob`; `TvScreen` (a view: the `SubViewport` with the channel's show scene, drawn on the glass); `TvSound` (a view: an `AudioStreamPlayer3D` at the set); `Looks` | decided; picture and sound are looks |

Both are **placed** in `house.tscn` (static Parts, in the layout hash; 150-L places them).

### `ChannelKnob` (`game/devices/channels/channel_knob.gd`)

| Field | Meaning |
|---|---|
| `channel: int` | 0 Off, 1..n the channels in dial order |
| `on_air: float` | the broadcast clock, in seconds: the Host writes its current value into every answer of this Part, the save and the join snapshot; every machine runs it on from there on its own clock |

Exports: `folder` (the channels' folder), `keeps_on_load: bool` (the Radio's on, the TV's off: R19), `start_channel`
(the Radio's 1, Theme, at a New Game: R15; the TV's 0), `reach` (as a Part's use).

| Verb | Who | What it decides |
|---|---|---|
| `turn` | any player: E aimed at it, or the Radio's carrier's E whatever else is in reach (R21, `held_input`) | `channel` = the next, Off after the last; the answer carries `on_air` and a `click` mark: every machine plays `device_click` at the device and, unless the new channel is Off, the device's static for `static_seconds` (0.6 s) before the channel comes on (R3, R4) |

`loaded()`: `keeps_on_load` keeps the channel, else Off (R19). A late joiner's snapshot and a load bring the channel
with no click and no static (R5: "turns to it quietly"). `prompt_title()`: "TV" / "Radio" while Off, "Radio: Theme"
while on ("%s: %s"), with the E key (R2; the current channel, Q2704). Saved and joined by its State group.

**The broadcast (R5):** every channel plays at its place in `on_air`, so every player sees and hears the same part of
the same show or track, roughly in step: a TV show at `on_air` mod its loop; a Radio channel's playlist runs round and
round, channel k (from 0) at `on_air + k x stagger` (37 s) into its playlist so they do not all start a track at once
(R16). `on_air` counts while the World is played (it is saved with it), not the hour of the day: neither device cares
about the hour.

### The Radio, the game's music (R14)

`RadioSound` plays the current channel's track at its place on the **Music** bus, heard in every room (attenuation
off) at `RadioTuning.volume_db`; within `near_m` (3 m) of the Radio, in its room or one open to it, up to `near_db`
(3 dB) louder and panned toward it, fully within `near_full_m` (1 m) (the old `nearness`: `panning_strength`); with a
shut room Door between it plays on **MuffledMusic** (quieter and dull, exists). It follows the model wherever it is,
carried or flying (R22). The cutscene's duck needs nothing here: `Voices` ducks the Music bus and MuffledMusic sends
into it (R18; voice.md V5).

The room test both devices need, "in its room or one open to it, never through a wall" (R7, R14), is one new question
beside `Sounds.is_muffled()`: `Sounds.reach_of(where) -> int` answering CLEAR, MUFFLED (a shut Door between) or WALLED
(a wall between), by the same hops of rays (150-B builds it; the TV uses it).

### The TV

- **The picture (R8):** the channel's show scene (a 428 x 240 Control, 16:9) in a `SubViewport` whose texture the
  glass's material shows through the CRT shader (scanlines and bulge); drawn at most `fps` (15) times a second, and
  only while on, past its static, and on screen (`VisibleOnScreenNotifier3D`); else the SubViewport does not update.
- **Turning (R9):** static fills the screen between channels (the CRT shader's `noise` keyed by the Looks' `static`
  clip, 0.6 s); switched off, the picture collapses to a line and the glass goes dark (the `off` clip). The power
  light glows while on (`on` / `off` clips, R6).
- **Its sound (R7):** `TvSound` plays the show's sound event at the set, 3D, `unit_size` 2.5, heard within `earshot`
  (7 m) when `Sounds.reach_of` is CLEAR or MUFFLED (MUFFLED plays on MuffledMusic), on the Music bus at `volume_db`
  -7.2 under the Radio; it never quiets the Radio.
- **The four shows** (R10-R13): each its own scene under `game/devices/tv/shows/`, its motion one AnimationPlayer
  clip `show` as long as its loop (seeked to `on_air` mod loop when the TV comes on, and kept in step), its lines as
  keys of the bubble's text on that clip, its voices the copied recording of the old synthesised gibberish:
  - **Sock puppet show** (`puppets.tscn`, 24 s, `tv_puppets`): the two sock creatures (orange `#e8945a` in a top hat,
    teal `#6fb3a8` in a bobble hat) on a little stage, talking in turns, their words in a bubble, both laughing at the
    end; the old eleven lines and their times (TVJ `puppets`).
  - **Sock shopping** (`shop.tscn`, 16 s, `tv_shop`): a real Design turning on a turntable (the loop's Design: the
    catalogue's Designs in a fixed order, the loop's number picking, so every machine shows the same), its name, a
    made-up price "%d.99" by its rarity (`ShopTuning.price_by_rarity`) pulsing gently, the pink (`#d9568f`)
    announcer's three lines, the jingle (0.0-2.6 s) and the ding (14.4 s), the ticker "SOCK SHOPPING * ONE SOCK,
    ALL YOURS * MATE NOT INCLUDED * CALL NOW" scrolling.
  - **Weather** (`news.tscn`, 24 s, `tv_news`): the sock presenter in a bow tie at a desk beside the weather map (the
    house from above, its four levels side by side, the rooms as soft blocks, drawn in nodes), each room's forecast
    in turn with its sign lit and moving, the sting (0.0-2.0 s); the five old forecasts.
  - **Test card** (`testcard.tscn`, 4 s, `tv_testcard`): colour bars, a grey step strip, "IT SOCKS TV" in a ringed
    box, its 1 kHz tone.

### The Radio as a carried thing (R20-R29)

The whole-Hands rule and the thrown-knock rule of `devices.md`, with the Radio's own details:
- Left click with empty Hands: into the Hands, seen in their hands by everyone and in their own view (R20); with
  anything in the Hands (the book's slot included) "Hands full". Lying Socks resting on it fall at the pick (Q2704:
  its shapes go off while carried, and the pick answer wakes what rested on it, a Mess `fall`: one rule for every
  Carriable).
- The carrier's E turns the dial whatever else is in reach (R21). Carried, it keeps playing and its sound follows it
  (R22).
- Right click: down where aimed on any top a Sock can be dropped on, easing there from the hands, facing back at
  them (R23; the Carriable's put, exists); where nothing takes it, the drop refusal. Aimed at a Teammate: a Hand-off
  into empty Hands, else at their feet ("Hands full") (R24).
- Thrown (R25): a Throw's arc; it lands with `radio_land` and keeps playing. A Teammate hit: knocked at full charge,
  else bounced to their feet, never caught (R26, Q2700).
- A leaver drops it at their feet (R27). Fallen off the map: back lying in front of the washer (R28).
- Saved and joined: carrier, spot, turn, flight (the Carriable) and channel (the knob); a Guest's carried Radio is
  saved lying where they stood (R29).

## How it is authored (Q2607)

- **Typed Resources edited in the inspector** (every number `# placeholder:` the old `data/tuning/devices.json`):
  - `Channel` (`game/devices/channels/channel.gd`), one `.tres` per channel: `title` ("Sock puppet show", "Theme"),
    `dial: int` (its order on the knob), and for the TV `show: PackedScene`, `sound: StringName`, `loop_seconds`; for
    the Radio `tracks_folder` (the channel's music folder).
  - `ChannelKnobTuning` (`game/devices/channels/channel_knob_tuning.tres`): `static_seconds` 0.6, `stagger` 37 s.
  - `RadioTuning` (`game/entities/radio/radio_tuning.tres`): `volume_db` 0, `near_m` 3, `near_full_m` 1, `near_db` 3,
    `scale` 1.5.
  - `TvTuning` (`game/entities/tv/tv_tuning.tres`): `volume_db` -7.2, `earshot` 7, `unit_size` 2.5, `resolution`
    (428, 240), `fps` 15.
  - `ShopTuning` (`game/devices/tv/shows/shop_tuning.tres`): the price by rarity.
  - `Forecast` (`game/devices/tv/shows/forecasts/*.tres`): the room's block (a node name on the map), the sign (rain,
    cloud, wind, sun, fog), the text ("SOCK SHOWERS IN THE BATHROOM").
  - `hold_slot_radio.tres` (the old hold).
- **Dropped in with no code change:**
  - **a Radio channel**: a `Channel` `.tres` in `game/devices/radio/channels/` and a folder of tracks; **a track**:
    an `.ogg` dropped into its channel's folder under `assets/radio/music/<channel>/` (the channel lists its folder
    at load by `ResourceLoader.list_directory()`) plus its line in `game/ui/licence/credits.tres` (R17);
  - **a TV channel**: a `Channel` `.tres` in `game/devices/tv/channels/` naming its show scene;
  - **a forecast**: a `Forecast` `.tres` (the Weather show takes them in name order, one per turn of its loop);
  - **a Sock Design** shows in Sock shopping (the catalogue).
- **Zoo station, built from the data at load (Q2337):** `game/zoo/stations/tv_radio.tscn` (its own things under
  `game/zoo/tv_radio/`): the real TV and Radio; a room with a room Door between the Radio and a second room (to hear
  the muffle and the walled silence), a doorway (the near through an open room); a board listing every channel of
  both folders (dial order, title, loop or tracks, each track's licence line from the credits; a new channel or track
  shows with no change); a pillar per TV show to see its frame at a set time (it sets the knob through a
  station-only `tune {channel}` the Part grants in the zoo alone); a stand-in cutscene button to hear the duck.
- **Authored in nodes (Q2658):** each show is a scene of Controls on the Theme (the puppets and the presenters as
  Control-drawn sprites or a small 3D stage in the SubViewport's own world, the bubble a `PanelContainer` with a Theme
  variation `TvBubble`, the ticker a `Label` in a clipping container, the weather map's room blocks a
  `weather_room.tscn` per block, placed by hand); the Test card a scene. Code seeks clips and fills texts; it never
  builds a Control or StyleBox.
- **Motion as clips (Q2697):** each show's `show` clip (the puppets' bob and turn, the shop's turntable and price
  pulse and ticker, the presenter's gestures and the lit sign); the TV's `static`, `off`, `on`; the Radio's `on` /
  `off` (the dial's warm glow) and `dial` (the needle along the dial; a turn plays the section from the old channel's
  mark to the new one's over the static's time, eased, with `AnimationPlayer.play_section`).
- **Looks contracts:** the TV: `Glass` (the screen mesh, left out of the outline: R2 "never the TV's picture"),
  `PowerLight`, clips `static`, `off`, `on`; the Radio: `Dial`, `Needle`, `Speaker`, clips `on`, `off`, `dial`.
- **Sounds** (`sound_catalogue.tres`, added by core/154): `device_click` (shared with the Elevator's button), `tv_static`,
  `radio_static`, `tv_puppets`, `tv_shop`, `tv_news`, `tv_testcard`, `radio_land`. The music tracks are plain
  `AudioStream` files, not SoundEvents.

## What each line becomes

| Lines | Draft |
|---|---|
| R1 (where they stand) | 150-L (the spots); 150-A (the Radio's 1.5 scale); 150-C (the TV's size) |
| R2 (outline and hint) | 150-A ("Radio"), 150-B (": Theme"), 150-C ("TV", the glass left out) |
| R3 (the knob, the Host decides), R4 (click and static; the TV's static with 150-C), R5 (the broadcast, the quiet join), R6 (the dial's glow and needle; the TV's power light with 150-C), R14 (the music everywhere, near, muffled), R15 (Theme at a New Game), R16 (the channels and playlists), R17 (the credits), R18 (the duck), R19 (the Radio keeps its channel; the TV off with 150-C), R21 (the carrier's E), R22 (keeps playing, follows) | 150-B |
| R7 (the TV's sound), R8 (the picture), R9 (static, off), R13 (the Test card) | 150-C |
| R10, R11, R12 (the three shows) | 150-D |
| R20, R23, R24, R25, R26, R27, R28, R29 (the carried Radio; its channel's save with 150-B) | 150-A |
| R30 (rides the Elevator) | 150-M (`devices.md`) |
| R31 (Radio Dance) | not drafted: a Secret (Q2682) |
| R32 (the Radio in the drum) | not drafted: a Secret (Q2682, Q2699) |
| R33 (the words) | each draft its own: "Radio", "Hands full" (150-A); "%s: %s", "Off", the Radio's channel names (150-B); "TV", "Test card" (150-C); the shows' names and texts (150-D). "Throw not bought" is dropped: the Throw is free from the start (Q1344) |

## Saves, joins and co-op

Nothing writes save code: the two `ChannelKnob`s and the Radio's `Carriable` are saved and joined by their State
groups. The TV's channel is saved but `loaded()` turns it off (R19, Q2559, Q2704).

- **Who decides:** the Host, every turn (R3) and every carry verb; everyone hears the same channel.
- **Each machine on its own:** the picture, the static, the sound's level, nearness, muffle and the broadcast's place
  (from the last `on_air` it was given): roughly in step, as the old.
- **Prediction:** none for a turn (it waits for the answer, as the old devices did); the Radio's Throw is looks-first
  for the thrower (the thrown-knock rule).

## Seams to the other pieces

- **core/78 (`Carriable`) and the two rules:** `devices.md` "The two shared rules": 150-A builds the Throw, `land`,
  `bounce`, `flight`, the lost-thing return, the pick's `fall` of what rested on it, and the held thing's input.
- **coop/10 (the knockdown):** the hit test reads the Radio in the air (150-A).
- **Batch A's music duck (voice.md V5):** the Radio and the TV play on Music and MuffledMusic; `Voices` ducks Music; no
  code here. The Voice station's radio stand-in may be swapped for the real Radio once 150-B lands (not required).
- **core/149 (the Elevator), this side only:** the lying Radio is a `Carriable` with a writable `at`; it keeps playing
  while it rides; the Radio needs nothing else (150-M's case). core/149's button shares `device_click`.
- **core/151 (the Cat):** Radio Dance (the Cat near the playing Radio) waits with the Secrets (Q2682); the Cat's
  design names `RadioSound`'s place and `ChannelKnob.channel` as what it would read.
- **The licence page (`game/ui/licence/credits.tres`):** one `CreditEntry` per track (CC0 or public domain; CC-BY with
  credit for Metal and Rock), 150-B.
- **Batch D, Secrets (Q2682, Q2699):** the Radio in the drum, playing muffled 4 dB quieter while it spins
  (`RadioTuning.drum_db` waits with it).

## Changed technically from the old (no choice: tell the designer at the sitting)

- One `ChannelKnob` Part serves both devices; the TV and the Radio are two scenes, not one `Device` class switching
  on its `id` (520 lines).
- The shows are scenes in nodes with one clip each, not built in code in a SubViewport (TSH, 444 lines).
- The Radio's place and carrier are its `Carriable`'s state, not loose fields on the Game.
- The broadcast clock is the knob's own saved `on_air`, given out by the Host, not each machine's play time.
- The shows' gibberish voices are the old synthesised recordings copied as they are: changing a line's timing
  needs a new recording (the old `tools/gen_sounds.py` is not ported).
- A Channel and a track are files: a new one appears on the knob and in the station with no code.

## Asset drafts (Q2705: the port rules, one family each, look work; opus)

As `devices.md` "Asset drafts": the old Blender script re-made as the game's, technical improvements only, the old
colours, `asset_lint.py`, the contract above, a before-and-after strip in `<main checkout>/builds/review-<family>/`,
**stopping at its first line-up** for the designer's go.

- **AS-C2-4 The TV** (`make_tv.py`): the modern widescreen flat-screen set on its walnut and cream console, the glass
  as its own mesh (`Glass`), the power light.
- **AS-C2-5 The Radio** (`make_radio.py`): the radio with its dial, needle and speaker cloth (shown at 1.5 times by its
  Looks).

## Build drafts (filed by core/153; the order in `docs/migration/milestones.md` "Batch C")

**150-A The Radio carried and thrown; the thrown-knock rule** (opus; after the groundwork, core/130; filed: core/163)
- Lines: R20, R23, R24, R25, R26, R27, R28, R29 (carrier, spot, turn, flight); R1's scale; R2's "Radio"; the words
  "Radio", "Hands full".
- Build: `radio.tscn` (graybox Looks at 1.5, `Carriable` `throwable` `handable`, `hold_slot_radio.tres`, silent until
  150-B); on `Carriable`: `throwable`, `radius`, `throw`, `land`, `bounce`, `flight`, the lost-thing return by the
  washer, the pick's `fall` of what rested on it; `Knockdowns`' hit test reads `Carriable.FLYING` (full: knock and
  bounce; weaker: bounce to the feet, never caught); the held thing's input seam in `player.gd` (the book's E folded
  in if core/139 has landed); the Radio in the tv_radio station.
- Acceptance: real path: in the tv_radio station the player left-clicks the lying Radio (two Socks lying on it fall),
  holds the right button and releases at full charge toward the floor; it flies, lands with `radio_land` and lies
  there. Co-op: a full-charge Throw at a Teammate knocks them down and bounces off; a weak one drops at their feet,
  never caught; aimed right tap hands it into their empty Hands, or at their feet with "Hands full"; a leaver drops it
  at their feet; a late joiner sees it mid-air. Thrown off the level, it comes back in front of the washer (a house
  case). Saved and joined.
- `suites: [carry, coop_carry, throw, knockdown, coop_knockdown, hand_off, coop_hand_off, save, zoo]`
- Authored: the Carriable's exports and the slot in the inspector; graybox Looks, then AS-C2-5.

**150-B The Radio's channels: the game's music** (opus; after 150-A; filed: core/164)
- Lines: R3, R4 (the Radio's), R5, R6 (the dial), R14, R15, R16, R17, R18, R19 (the Radio's), R21, R22; R2's
  channel; the words "%s: %s", "Off", the Radio's channel names.
- Build: `ChannelKnob`, `ChannelKnobTuning`, `Channel`; the six Radio channels in `game/devices/radio/channels/` and
  the old tracks copied into `assets/radio/music/<channel>/` with their `credits.tres` lines; `RadioSound` (Music,
  attenuation off, near and pan, MuffledMusic); `Sounds.reach_of()`; `RadioTuning`; the dial clips; the carrier's E
  through `held_input`; the station's board, rooms and duck button.
- Acceptance: real path: in the tv_radio station the player presses E on the Radio: `device_click`, 0.6 s of
  `radio_static`, then the next channel plays and the hint reads "Radio: Lo-fi"; walking into the next room through
  the Door the music stays, louder and panned within 3 m of the Radio; with the Door shut it plays on MuffledMusic.
  Carrying it, E turns it while the TV is in reach. Co-op: a Guest's E turns it for everyone; a late joiner hears the
  same track near the same place, no click. A load keeps the channel; a New Game starts on Theme. The duck button
  lowers the Music bus to 0.25 over 0.5 s.
- `suites: [sounds, sound_wiring, save, coop_join, voice, zoo]` (a new `devices` suite for the broadcast's place)
- Authored: channels and tracks are files (a new one shows with no code); the credits a `.tres`; numbers in the
  inspector.

**150-C The TV and its Test card** (opus; after 150-B; filed: core/165)
- Lines: R7, R8, R9, R13; R4's TV static, R6's power light, R19's TV off, R2's "TV"; the words "TV", "Test card".
- Build: `tv.tscn` (static body of the old size, `ChannelKnob` with `keeps_on_load` off, `TvScreen` with the
  SubViewport and the CRT shader, the fps cap and on-screen check, `TvSound` with earshot and `reach_of`, `TvTuning`),
  graybox Looks with `Glass` out of the outline and the `static`, `off`, `on` clips; `testcard.tscn` and its channel
  file; the TV in the station.
- Acceptance: real path: in the tv_radio station the player presses E on the TV: `device_click`, the screen fills with
  static for 0.6 s and the Test card shows with its tone heard 3D; walking 8 m away it is silent; through a wall
  silent, through a shut Door muffled; E past the last channel collapses the picture to a line and the glass goes dark.
  The picture is not drawn while off or off screen (a counter). A load turns it off. The outline never covers the
  glass.
- `suites: [sounds, outline, save, profiler, zoo]` (the `devices` suite)
- Authored: `TvTuning` in the inspector; the Test card a scene; clips in the Looks; then AS-C2-4.

**150-D The TV's three shows** (sonnet; after 150-C; filed: core/166)
- Lines: R10, R11, R12; the shows' names and texts (TVJ).
- Build: `puppets.tscn`, `shop.tscn`, `news.tscn` with their `show` clips (the old texts and timings, Q2704), the
  copied voices, `ShopTuning`, the five `Forecast` files, `weather_room.tscn` and the map placed by hand, the
  `TvBubble` Theme variation; their three channel files in dial order before the Test card.
- Acceptance: real path: in the tv_radio station the player presses E on the TV once: the Sock puppet show plays, and
  at 0.5 s into its loop the bubble reads "Blorp! Snibble?"; E again: Sock shopping shows a catalogue Design's name
  and a "%d.99" price, the ticker moving; again: the Weather, the bathroom's sign lit with "SOCK SHOWERS IN THE
  BATHROOM" in its turn. Two machines show the same Design in the same loop (co-op).
- `suites: [zoo]` (the `devices` suite)
- Authored: shows in nodes on the Theme, motion as clips; forecasts and channels are files; the Designs from the
  catalogue.
