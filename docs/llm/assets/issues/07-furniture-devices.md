---
type: ticket
status: done
kind: build
area: assets
feature: assets
priority: now
created: 2026-11-21
done: 2026-11-23
blocked_by: []
notes: []
terms: []
---

# Furniture devices: opening sounds, mirror, piano, dust sheet, Old Tree

The small details of furniture pieces that are devices in the old game (designer, Q2395, 2026-11-21: all four kinds,
now). Old code: `reference/it-socks/game/house/openable.gd` (the cue table by container kind), `mirror.gd`
(`MirrorGlass`), house/28's piano (88 `Key_<midi>` parts), `dust_sheet.gd`, `old_tree.gdshader`.

## Behaviour list (expanded from the old code; the test of each line in brackets: `tests/piano_test.gd` for the P lines, `tests/furniture_devices_test.gd` for the rest)
The draft's five lines (V01-V05) stand as approved (Q2502-Q2508); each is expanded below into every sound, motion
and number of the old code (Q2277). Old sources: `game/house/openable.gd` (CUE_STEMS), `game/audio/sound_bank.gd` and
`data/sounds.json` (picks; an event with no pick plays its pool's first candidate), `game/audio/sound_installer.gd`,
`data/tuning/audio.json`; `game/house/mirror.gd`, `mirror.gdshader`, `data/tuning/mirror.json`, `graphics.json`;
`game/devices/piano_key.gd`, `game/audio/sfx.gd` (play_note), `house_rules.gd` (key), `data/tuning/piano.json`,
`assets/audio/candidates.json`; `game/campaign/dust_sheet.gd`, `locks_view.gd`, `cabinet.gd` (set_covered),
`data/tuning/locks.json`.

**V01 Openings** (19 pieces, 28 openings; kinds from the old manifest, as assets/04 kept them):
- V01a `drawer` (12: desk, dresser x3, filing cabinet x3, kitchen cupboard's drawer, kitchen drawers x3, nightstand):
  drawer_open / drawer_close, the old picks laleksic drawer open / close [v01_kinds].
- V01b `cupboard` (10: car Cabin and Boot, kitchen cupboard door, sink doors, wall cupboard, mine barrel and crate lids,
  toy chest and trunk lids, vanity doors): cupboard_open / cupboard_close, qubodup door open1 / close1 [v01_kinds].
- V01c `fridge` (its two doors): fridge_open / fridge_close, rubberduck microwave open / close [v01_kinds, v01_real_path].
- V01d `oven`: oven_open / oven_close, rubberduck metal open / close [v01_kinds].
- V01e `basket` (the laundry basket's lid): basket_open (kenney creak3) / basket_close (rubberduck wood misc2) [v01_kinds].
- V01f `litter_flap`: litter_flap_open / close, no old pick, so the cupboard pool's first (kenney door open1 / close4),
  6 dB under (audio.json litter_flap_gain_db -6) [v01_kinds].
- V01g `piano_lid`: piano_lid_open / close, no old pick: the cupboard pool's first (kenney door open1 / close4)
  [v01_kinds, p02_real_path].
- V01h Each plays once as the swing starts, a world sound from the opening's place (full within 3 m, gone at 20 m,
  muffled behind a shut Door, pitch +-5%), for every player (the Host's answer); a refused use and a state
  arriving whole (a late Guest, a load) play nothing [v01_real_path, v01_once].
- V01i The swings themselves stay assets/04's (0.35 s, easing out both ways) [furniture suite].

**V02 The wall mirror** (Q2505):
- M01 Its glass (MirrorGlass: the 0.6 x 1.1 m oval, centre 0.607 m over the piece's origin, facing +Z) shows a planar
  reflection: a second camera at the eye's mirror image behind the glass, looking out through it, a frustum cut to
  the glass (offset to its centre), the near plane 0.012 m past the glass's plane, far 6 m [m01_reflection].
- M02 The picture 256 px high, as wide as the glass's shape (140 px), no MSAA, no lamp shadows (the sun's stay),
  linear HDR, no audio listener; a copy of the world's environment with linear tonemap, no grade, glow or SSAO (the
  eye's camera tonemaps the glass with the room) [m01_reflection].
- M03 It renders only while on screen: the eye more than 0.02 m in front of the glass, within 4.5 m, one of five probe
  points (the centre and four at 0.9 of the rim) in the eye's view and clear of walls (rays once a physics tick, to
  0.055 m in front of the glass: past the frame) [m03_on_screen].
- M04 In view it draws its first frame at once, then every 3rd frame; out of view nothing [m04_every_third].
- M05 The picture is mirrored left to right, tinted faintly cool (0.93, 0.97, 1.0), drawn as light of its own [m06_low].
- M06 Off (the Low preset; Medium and High reflect), or before its first picture: a soft gradient (0.86, 0.92, 0.95 at
  the top to 0.6, 0.68, 0.74), a diagonal sheen (0.18), roughness 0.2, specular 0.7 [m06_low].
- M07 The quad is cut to the inscribed oval [m06_low].
- M08 Teammates and their held things show in it; the player's own full body shows in it and only in it (a second,
  whole sock creature on a render layer the eye's camera skips, shown while any mirror renders, bending and crouching
  with the player, in their colour); the first-person belly and the held items do not; the Mess Socks do not
  (their own render layer) [m08_real_path].
- M09 The glass is never in its own reflection [m01_reflection].

**V03 The piano** (Q2508):
- P01 88 keys, A0 to C8 (MIDI 21-108), each its own thing on its old hinge (the key's back) with its old collision box
  (2 cm taller, so the crosshair finds it over the old keyboard hull) and the Looks' `Key_<midi>` mesh; the shut lid
  covers them, so the crosshair reaches a key only once the lid is open [p01_keys, p02_real_path].
- P02 The aimed key shows its outline (the old "highlightable"); a left click plays it; the use key (E) does not; its prompt reads "Play C4" with the left button (note
  names C, C#, D ... B, octave midi / 12 - 1: 60 is C4, 21 A0, 108 C8) [p02_real_path].
- P03 Played, the key dips 3 degrees about its back in 0.04 s (sine, easing out) and rises back in 0.16 s (sine,
  easing in and out); played again while moving it goes on from where it is [p03_dip].
- P04 Its note: the instrument's (the old first, cc0/piano_remeau: a Remeau upright by Sadiquecat, 23 recorded notes
  A0-C8 with measured roots) nearest sample, pitched by 2^((note - root) / 12), no jitter, a world sound at the key:
  full within 3 m, gone at 20 m, muffled behind a shut Door [p04_note].
- P05 It rings at full for 1.6 s, then fades to -60 dB over 1.2 s (easing in) and stops [p05_ring].
- P06 A note played again while it still rings: the ringing one fades out over 0.08 s [p06_restrike].
- P07 12 voices in turn; a 13th note cuts the oldest [p07_voices].
- P08 Anyone plays it and every player sees the key dip and hears the note once; a Guest's own key sounds and dips at
  once, before the Host's word, and not again when the word comes; a player out of reach (4 m) is refused; a late
  Guest gets the count and hears nothing played before [p08_coop].
- P09 The lid opens and shuts as an opening (V01g) [p02_real_path].

**V04 The dust sheet** (Q2507):
- D01 An off-white cloth (#ece4d4, matt, both sides drawn, casting a shadow, no collision) over a locked Cabinet: 1.5 cm
  roomier than it, over its top, rounded over its edges (3.5 cm), hanging down its front and sides (up to 0.9 m past
  them) to the floor, 8 cm down its back, bulging 1.8 cm, in folds 2.2 cm deep; what reaches the floor spills onto
  it [d01_drape].
- D02 A cloth of 28 x 30 cells [d01_drape].
- D03 On the unlock it is pulled off: it slides forward over the top front edge by its length and 0.2 m (easing in,
  quadratic) in 0.5 s, fading over the last 40%, then it is gone [d03_real_path].
- D04 The reveal sounds 1 m over the Cabinet once the pull is done (0.5 s, and at least the old reveal_delay 0.5 s):
  cabinet_reveal, no old pick, so the drawer_open pool's first (laleksic drawer open) [d03_real_path].
- D05 While sheeted the Cabinet is locked: its drawers stay shut, and neither it nor its drawers can be aimed at: no
  outline, no prompt, a click or the use key asks nothing; once the sheet is off, the drawers aim as usual (Q2513, the
  old set_covered) [d01_drape, d05_unaimable].
- D06 A state arriving whole shows it as it stands, no pull or sound; locked again, it drapes at once [d06_now].
- D07 At the Furniture station a sheeted Sport Cabinet and a switch: the switch's use asks the Host, whose answer is the
  Cabinet's lock patch, for every player [d03_real_path].
- D08 The sheeted sofa stays a model [v05_old_tree].

**V05** The Old Tree stays as it is: its motion, flicker and voice wait for its rework (Q2506) [v05_old_tree].

## Acceptance
- The behaviour list above is first expanded from the old code into every sound, motion and number (one line each, small details included, Q2277), written into this ticket; then built with one test per line.
- Each device is placed at the furniture station (`game/zoo/stations/furniture.tscn`) and works there: a door, a drawer, a lid and a flap each play their kind's open and shut sound; the mirror reflects; each piano key plays its note and dips; the dust sheet as old; the Old Tree unchanged.
- Sounds go through the sound catalogue with the old clips (plug and play, no code per sound).
- A strip in `builds/review-furniture-devices/`: the mirror, the piano, the dust sheet's pull-off, old beside new.

## Answers
- Q2513 (2026-11-23): see D05; the other three [later] items stay as built (placeholders).
- Q2505-Q2508 (2026-11-23): see V02-V05.
- Q2502 (2026-11-23): all five devices as the old game, the behaviour list written in full from the old code.
- Q2504 (2026-11-23): built to the end with no stop at the first still; a before and after strip for the designer's batch review before the merge.

## Open follow-ups
- Answered (Q2513, 2026-11-23): a Cabinet under its dust sheet cannot be aimed at, as the old game (no outline, no
  prompt, no click while sheeted; once the sheet is off the drawers aim as usual). Built: D05.
- [later] Look: the dust sheet's floor spill is the old geometry (it spreads up to 0.9 m to the sides and slides 0.2 m
  past its length); on the station's pad it reaches well out in front. Placeholder: as old.
- [later] Look: the station's wall mirror stands on the floor in the line-up (wall-hung pieces are lifted where they are
  placed); the still lifts it to 0.9 m. Its reflection numbers are the old ones (placeholders in mirror_tuning.tres).
- [later] The piano keys' aim boxes are 2 cm taller than the old ones so the crosshair finds them over the old keyboard
  hull (a Sock resting on the keys sits that much higher). Placeholder until the designer tries it.

## Built log
- 2026-11-23
  - Changed: every furniture opening sounds its old kind's open and shut clips through the catalogue (11 new events,
    the old clips); the piano's 88 keys are PianoKey Parts (left click, outline, dip, sampled note on a new
    catalogue Instrument with Sounds.play_note, a Guest's own key at once); the wall mirror draws the old planar
    reflection (Mirror scene, own mirror body on the player, Mess Socks on their own render layer, off on Low); the
    dust sheet drapes a locked Cabinet and is pulled off on the unlock with the reveal sound; a zoo switch at the
    Furniture station unlocks its Sport Cabinet. Part.click_only() added (E skips it, prompt shows the left button).
  - Files: game/devices/*, game/audio/{instrument.gd,sounds.gd,sound_event.gd,sound_catalogue.tres},
    game/furniture/*.tscn (19 openings, piano keys, wall mirror), game/entities/cabinet/cabinet.gd, game/player/*,
    game/parts/part.gd, game/ui/prompts.gd, game/mess/mess_drawing.gd, game/look/*, game/zoo/furniture/cabinet_lock_switch.*,
    game/zoo/stations/furniture.tscn, game/zoo/sounds/sound_spot.gd, assets/audio/*, tests/{furniture_devices,piano}_test.gd,
    tests/{sounds,furniture}_test.gd, tools/{shot_hooks.gd,piano_keys_from_old.py,shots/sets/furniture-devices.txt}.
    Strip: builds/review-furniture-devices/furniture-devices-strip.png.
  - Verified: suite: PASS 17437 checks, 469 cases (every suite: the audio files cannot be placed); PASS rules; PASS asset_lint.
- 2026-11-23 (Q2513)
  - Changed: a Cabinet under its dust sheet and its drawers are passed by the crosshair (Part.aimable(),
    Cabinet.sheeted(), Player.aimed_part()): no outline, no prompt, no click; aimed as usual once unsheeted.
  - Files: game/parts/part.gd, game/entities/cabinet/cabinet.gd, game/player/player.gd, tests/furniture_devices_test.gd.
  - Verified: suite: PASS 17446 checks, 470 cases (--touched); PASS rules.
- Merged: 711108e7 (2026-11-23, branch assets/07-furniture-devices)
