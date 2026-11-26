> Draft behaviour list for batch C's TV and Radio (core/148), written from the reference on 2026-11-26; for the
> designer to approve. No proposal is built on it yet: the design ticket follows the designer's look (index:
> `batch-c.md`).

# Batch C piece: the TV and the Radio

Draft behaviour list (catalogue B14 TV and Radio, B71 Music, the Radio as its source, and the ducking). Refs are in
the old game (`reference/it-socks/`, tag v0.1.1) unless they start with `port:`. Short forms: DV =
`game/devices/device.gd`, RR = `game/devices/radio_rules.gd`, TS = `game/devices/tv_screen.gd`, TSH =
`game/devices/tv_shows.gd`, DI = `game/devices/devices_installer.gd`, MD = `game/audio/music_duck.gd`, RC =
`game/player/rig_click.gd`, CR = `game/hands/carriables.gd`, HA = `game/hands/hands.gd`, G = `game/core/game.gd`, SV =
`game/core/saves.gd`, SB = `game/audio/sound_bank.gd`, SEC = `game/campaign/secrets.gd`, TVJ = `data/tv.json`, RJ =
`data/radio.json`, CRJ = `data/credits_radio.json`, HL = `assets/house/house_layout.json`, T:<name> =
`data/tuning/<name>.json` (every number there is a placeholder in the old game too), DH =
`docs/migration/digests/digest-house.md` section 16.

Marks: "(11)" a line of list 11 (the Elevator carries the Radio), "(12)" of list 12 (the Cat); "(co-op)" a line
that needs co-op (who sees what, the Host's answer); "(sound)" a sound, "(rumble)" a pad rumble (the devices have
none of their own; throwing the Radio is the Throw's "throw" buzz); "(Secrets, later, Q2682)" a Secret that hangs on
the piece. Not ported: the old menu music on the Music bus is the main menu's (list 01), not this piece's. The old
models were `assets/tv/tv.glb` (the widescreen set on its walnut console, `tools/blender/make_tv.py`) and
`assets/radio/radio.glb` (`tools/blender/make_radio.py`); neither is in the port yet (DV:22-25). Neither device
cares about the hour of the day.

## Behaviour list

### What they are and where they stand
- When the house is built, then the TV stands in the living room (a modern widescreen flat-screen set on a walnut and
  cream console, 1.5 x 0.46 x 1.22 m, in front of the north window) and the Radio on a kitchen shelf (shown 1.5 times
  its modelled size). (ref: HL `devices`; DV:1-8, DV:22-25, DV:474-481; T:devices radio_scale; Q402, Q414, Q547; DH
  Open flat/62)
- When the crosshair is on either, then its model is outlined (never the TV's picture) and the hint names it and its
  channel: "TV" / "Radio" while off, "Radio: Theme" while on, with E. (ref: DV:28-29, DV:246-259)

### Turning the knob (the Host decides)
- When a player presses E on the TV or the Radio, then its knob turns to the next channel, Off, 1, 2, ..., the last,
  Off, for everyone in the Session: the Host decides every turn and everyone hears the same channel. (ref: DV:1-8,
  DV:195-210; G:292, G:376-381; `game/house/house_rules.gd`:28; Q344-Q349) (co-op)
- When the knob turns, then "device_click" plays at the device, and a burst of static (TV "tv_static", Radio
  "radio_static", 0.6 s) plays before the channel comes on; switching off has no static. (ref: DV:222-244, DV:286-303;
  DI:33; SB:118-120; T:devices static_time) (sound)
- When a channel plays, then it is a broadcast timed by the game's play time: every player sees and hears the same part
  of the same show or track, roughly in step; a joining Guest or a loaded game turns to it quietly (no static, no
  click). (ref: DV:10-13, DV:217-224, DV:304-357) (co-op)
- When the Radio is on, then its dial glows warm and its needle slides along the dial to the channel (over the static's
  time, eased); the TV's power light glows while it is on. (ref: DV:30-33, DV:260-279)

### The TV
- When the TV plays, then it is heard in 3D from where it stands, within `earshot` 7 m, in its own room or one open to
  it, never through a wall; a shut room Door between muffles it; it plays on the Music bus 7.2 dB under the Radio; it
  never quiets the Radio. (ref: DV:1-8, DV:61-82; T:devices earshot, unit_size, tv_volume_db; Q349, Q371, Q519)
  (sound)
- When the TV is on, then its picture is a small 16:9 world (428 x 240) drawn onto the screen glass with a CRT's
  scanlines and bulge, at most 15 times a second, and only while it is on, past its static, and on screen. (ref:
  TS:1-8, TS:80-104; T:devices tv_resolution, tv_fps; Q348, Q414)
- When the TV turns, then static fills the screen between channels; switched off, the picture collapses to a line and
  the glass goes dark. (ref: TS:3-4, TS:71-79)
- When channel 1 is on, then the Sock puppet show plays: two sock creatures (orange in a top hat, teal in a bobble hat)
  on a little stage talk gibberish in turns, their words in a bubble ("Blorp! Snibble?", "Snorf snorf.", ...), a 24 s
  loop, both laughing at the end ("tv_puppets", synthesised gibberish voices). (ref: TSH:178-234; TVJ `puppets`;
  SB:121) (sound)
- When channel 2 is on, then Sock shopping plays: a real Design turning on a turntable, its name, a made-up price
  "%d.99" by its rarity (pulsing gently), a pink announcer's gibberish ("Snazzle! Pomf pomf!", "Only today, blorp!",
  "Call now! Sockity sock!"), a jingle and a ding, the ticker "SOCK SHOPPING * ONE SOCK, ALL YOURS * MATE NOT INCLUDED
  * CALL NOW" scrolling; a new Design every 16 s loop ("tv_shop"). (ref: TSH:235-302; TVJ `shop`; SB:122) (sound)
- When channel 3 is on, then the Weather plays: a sock presenter in a bow tie at a desk beside a weather map of the
  house from above (its four levels side by side, the rooms as soft blocks), each room's forecast in turn with its sign
  lit and moving: "SOCK SHOWERS IN THE BATHROOM", "FLUFFY AND OVERCAST IN THE BEDROOM", "CRUMB WINDS IN THE KITCHEN",
  "SUNNY SPELLS ON THE SOFA", "LINT FOG IN THE HALL"; a sting, a 24 s loop ("tv_news"). (ref: TSH:303-412; TVJ `news`;
  SB:123) (sound)
- When channel 4 is on, then the Test card shows: colour bars, a grey step strip, "IT SOCKS TV" in a ringed box, and
  its 1 kHz tone ("tv_testcard"). (ref: TSH:413-444; TVJ `testcard`; SB:124) (sound)

### The Radio, the game's music
- When the Radio plays, then it is the game's only music: heard in every room at the Music bus level, up to 3 dB louder
  and panned toward it near it (fully within 1 m, none from 3 m, in its room or one open to it); a shut room Door
  between muffles it (the muffled Music bus: quieter and dull). (ref: DV:4-6, DV:61-82, DV:369-376; T:devices radio_*;
  Q364, Q519; port: the `Music` and `MuffledMusic` buses, `default_bus_layout.tres`) (sound)
- When a New Game starts, then the Radio is on its first channel, Theme. (ref: G:295, G:381; Q370)
- When the Radio's channels are turned, then they are, in dial order: Theme (the game's own cosy songs, 5 tracks), Lo-fi,
  Jazz 78s (three real public-domain 78s, 1918 and 1923), Funk, Metal, Rock (3 tracks each), then Off; each channel is
  a playlist that runs round and round, the channels 37 s apart in their playlists so they do not all start a track
  at once. (ref: RJ; DV:36-41, DV:330-367; Q365, Q368, Q370, Q426)
- When the tracks are credited, then each is CC0 or public domain (CC-BY with credit only for Metal and Rock), credited
  in the licence page. (ref: CRJ; DH)
- When a cutscene plays, then the Music bus (the Radio and the TV) fades to 0.25 of its level over 0.5 s and back after;
  the Options slider keeps working. (ref: MD:1-4; T:audio cutscene_duck_level, cutscene_duck_seconds; Q1867; port:
  `docs/architecture/voice.md` V5, built in batch A by `Voices`)
- When a World is loaded, then the Radio keeps its channel and the TV is off. (ref: SV:133, SV:438-440; Q369; port: Q2559)

### Carrying the Radio
- When a player left-clicks the Radio with empty Hands, then it goes into their Hands (the Hands hold nothing else),
  seen in their hands by everyone and in their own view; with anything in the Hands they read "Hands full". (ref:
  RR:1-3, RR:30-37, RR:55-79, RR:146-151; RC:82-83, RC:105-108; HA:27, HA:90; Q366, Q369) (co-op)
- When the carrier presses E, then the Radio's dial turns, whatever else is in reach. (ref: RC:111-135; Q366)
- When the Radio is carried, then it keeps playing and its sound follows it. (ref: DV:377-424)
- When the carrier right-clicks, then it goes down where aimed (floor, table, shelf, any surface a Sock can be dropped
  on), easing there from their hands, facing back at them; where nothing takes it, they read the drop refusal. (ref:
  RR:38-53, RR:84-120; DV:397-417; Q366)
- When the carrier aims the drop at a Teammate, then it goes into their empty Hands (a Hand-off); if their Hands hold
  anything, it goes down at their feet and they read "Hands full"; a Teammate never grabs it from the carrier. (ref:
  RR:94-101, RR:120-128; Q367) (co-op)
- When the carrier throws it, then it flies as a Throw, lands with a clunk ("radio_land") and keeps playing. (ref:
  RR:87-92, RR:129-145; SB:126; HA:61; Q367) (sound) (co-op)
- When a thrown Radio hits a Teammate, then a full-charge Throw knocks them down and bounces off; a weaker one
  bounces off and drops at their feet, never caught; one knocked down, in the drum or riding the Elevator is not hit.
  M0.6 left the Radio's knock to this milestone (Q2483). (ref: `game/world/flight_rules.gd`:55-59, :186-193,
  :298-304; knockdown/04, Q1935, Q1936; port: Q2483, Q2484) (co-op) (rumble: the knock's buzz)
- When a carrier leaves the game, then the Radio drops at their feet. (ref: CR:188-215)
- When it falls off the map, then it comes back lying in front of the washer. (ref: SV:441-443; GLOSSARY "Carrying the Radio"; maintenance/06)
- When the World is saved or a player joins, then the Radio's carrier, spot, turn and flight, and its channel, are in
  the save and the join snapshot; a Guest's carried Radio is saved lying where they stood. (ref: CR:188-215; SV:133;
  Q369) (co-op)
- When the Radio lies in the Elevator's car, then it rides along with everything in the car. (ref:
  `game/house/elevator_rules.gd`:148-153; `game/devices/radio_rules.gd`:158-161) (11)

### Secrets that hang on them
- When the Cat sits about 2 m from the playing Radio for 10 s, then Radio Dance is found: its head bobs, the Boombox
  Hat. (Secrets, later, Q2682) (ref: SEC:27, SEC:199-205, SEC:228-231; Q1045) (12)
- When the Radio is dropped by the washer's door, then it goes into the drum for a load and keeps playing, muffled
  (4 dB quieter), while it spins. (Secrets, later, Q2682) (ref: DV:83-91, DV:437-445; T:wash radio_db; Q1106,
  Q1125)

### Words
- When the devices' wording is shown, then it is the old: "TV", "Radio", "%s: %s", "Off", the channel names ("Sock
  puppet show", "Sock shopping", "Weather", "Test card"; "Theme", "Lo-fi", "Jazz 78s", "Funk", "Metal", "Rock"), "Hands
  full", "Throw not bought", and the shows' texts in TVJ. (ref: DV:28-29, DV:205-210, DV:256-258; RR:72, RR:128-131;
  TVJ; RJ)

## What was weak in the old devices
- One `Device` class drew both the TV and the Radio, switching on `id` (static events, glow parts, the needle, the
  Radio's carry and drum); 520 lines.
- The TV's four shows were built in code in a SubViewport (TSH, 444 lines): stages, labels, a StyleBox for the bubble.
- The Radio's place and carrier lived as loose fields on the Game (`radio_by`, `radio_pos`, `radio_yaw`,
  `radio_flight`), each carrier rule a branch in RR; the Elevator and the Secrets read them directly.
- The shows' gibberish voices were synthesised from TVJ's timings by a tool (`tools/gen_sounds.py`): a change of a
  line needs a rerun.
- The TV's picture and its show logic ran on the play-time clock on every machine; the TV's channel was not saved
  (a load turns it off).

## Open questions for the designer
1. The TV has four channels (Sock puppet show, Sock shopping, Weather, Test card), drawn in the engine with the retro
   filter. (a) Keep the four shows as the old, texts and timings included; (b) change or drop some (which?).
2. Each Radio channel but Theme has three tracks; Theme has five. (a) Keep the old picks, as the old; (b) more or
   other tracks per channel.
3. The hint shows the current channel ("Radio: Theme"). (a) Keep, as the old; (b) show what E turns to next.
4. A load keeps the Radio's channel and turns the TV off (Q2559). Should the TV's channel be saved too? (a) No, the TV
   is off after a load, as the old; (b) the TV keeps its channel.
5. The Radio's "near" (louder and panned within 3 m) reaches into rooms open to its room. (a) Keep, as the old; (b)
   stop at the edge of its own room.
6. Picking up the Radio with Socks lying on it (an old open question, never answered). (a) They fall, as the old: the
   carried Radio has no collision (DV:92-93); (b) the pick-up is refused while Socks lie on it.
7. A thrown Radio that hits a Teammate (Q2483 left its knock to this milestone). (a) A full-charge Throw knocks them
   down, a weaker one bounces off to their feet, never caught, as the old (Q1935, Q1936); (b) it never knocks down;
   (c) the Teammate catches it.
8. The TV stands in front of the living room's north window (its console reaches in front of it). (a) Keep the spot,
   as the old; (b) square it to the wall; (c) another wall.
9. The TV and Radio models (`assets/tv/tv.glb`, `assets/radio/radio.glb`) are not ported yet. (a) Port them by the port
   rules (an asset family with its strip); (b) new models.
