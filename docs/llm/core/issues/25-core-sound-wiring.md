---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: core
priority: now
created: 2026-11-21
done:
blocked_by: ["[[11-outline]]", "[[23-flights-flip-and-throw-from-hand]]"]
notes: []
terms: []
---

# Core sound wiring: every core sound and pad rumble at its moment

M0.5 batch 6 (Q2278, Q2296, Q2318-Q2321). core/17 built the sound system and wired steps, the landing and the zoo
ambience; its "Parked scope" lists the other call sites. This ticket wires them, with the old clips and numbers. The old
code: `reference/it-socks/game/core/game.gd:1445-1470`, `game/hands/hands_rules.gd`, `game/hands/thrower.gd:116-133`,
`game/world/flights.gd:37`, `game/world/flight.gd:318-330`, `game/campaign/cabinets.gd:311`,
`game/campaign/cabinet_drawer.gd:50-60`, `game/house/openable.gd:37-50, 152`, `game/audio/sound_installer.gd`,
`game/player/pad_rumble.gd`, `game/player/player.gd:415-444`; the numbers: `data/sounds.json`, `data/tuning/audio.json`,
`data/tuning/pad.json`.

## How the old one works
- **One cue name per moment**, played flat for the player's own (`Game.cue`) or in 3D at a spot (`cue_at`). One clip is
  picked at random per play from the event's picks; pitch is `1 + randf(-0.05, 0.05)` (`audio.json` pitch_jitter). World
  sounds: unit size 3 m, max distance 20 m. Buses: SFX (flat and 3D), master 0.6, SFX 1.0.
- **No cooldown and no speed scaling.** Only 8 flat and 8 3D voices, used in turn (`sfx.gd:30-31, 117-129`). Bounce has
  one clip at one level, heard when a flight hits a surface at over 1.5 m/s into it (`flight.gd:321-327`).
- **Clips and levels** (`sounds.json`; all 0 dB except `pop` +3 dB):
  `pick` owlish_cloth5 · `drop` kenney_drop_leather · `cycle` synth/cycle_a · `refuse` kenney_error6 · `pair`
  owlish_cloth4 · `pop` wubitog_pop1 or cogitollc_pop1 (+3 dB) · `throw_charge` synth/throw_charge_b · `throw`
  artisticdude_swish1 · `bounce` owlish_fruit2 (3D) · `shelve` kenney_book_place1 (3D) · `drawer_open` / `drawer_close`
  laleksic_drawer_open / _close (3D) · `door_open` oiboo_door_open and `door_close` starninjas_door2 (3D; the bank also
  lets them borrow the wardrobe's forster_hinge and rubberduck_wood_slam4 through `shares`) · `cupboard_open` /
  `cupboard_close` qubodup_door_open1 / _close1 (3D) · `step_wood` kenney_footstep00 · `step_tile` owlish_hard1 · `land`
  qubodup_jumpland · `jump` has no pick (silent) · `coins` starninjas_coin1.
- **Rumble** (`pad.json`, 0.0-1.0 weak / strong motor, seconds): throw 0.3 / 0.7 for 0.25 s; pair 0.5 / 0.2 for 0.2 s;
  knock 0.6 / 1.0 for 0.5 s (knocked down or dragged); done 0.4 / 0.4 for 0.5 s (a Drawer or a Collection completed).
  Every connected pad, unless the "Pad rumble" option is off (`pad_rumble.gd:19-26`).

## Behaviour list
- W01 When a pick is granted, then "pick" plays flat (`game.gd:1458`, `rig.gd:255-258`).
- W02 When a pick completes a Pair, then "pair" plays flat, not "pick" (`game.gd:1461-1462`).
- W03 When the paired moment's ball pops out, then "pop" plays flat, +3 dB (`rig.gd:259`, `held_view.gd` popped).
- W04 When the active item changes by the wheel, then "cycle" plays flat (`game.gd:23`).
- W05 When the active item is dropped, then "drop" plays flat (`hands_rules.gd:267`).
- W06 When a refusal is said (Hands full, wrong or locked Cabinet, full drawer, a drop refused), then "refuse" plays flat
  with the red line (`game.gd:1446-1449`).
- W07 When the throw charge starts, then "throw_charge" plays flat (`thrower.gd:116`).
- W08 When the throw is released, then "throw" plays flat and the pad rumbles 0.3 / 0.7 for 0.25 s
  (`hands_rules.gd:374`, `thrower.gd:133`, `pad.json`).
- W09 When a pick completes a Pair, then the pad rumbles 0.5 / 0.2 for 0.2 s (`sound_installer.gd:43`).
- W10 When a thrown or dropped item or a ball hits a surface at over 1.5 m/s into it, then "bounce" plays in 3D at the
  contact, one level whatever the speed (`flight.gd:321-327`, `flights.gd:37-39`).
- W11 When a Pair is shelved, then "shelve" plays in 3D at the drawer it went into (`cabinets.gd:311`).
- W12 When a drawer opens or shuts by use, then "drawer_open" / "drawer_close" plays in 3D at the drawer; the Door and
  the cupboard play "door_*" / "cupboard_*" the same way; a state arriving whole makes no sound
  (`cabinet_drawer.gd:56-60`, `openable.gd:37-50, 152`).
- W13 When the player lands from a fall of 3 m/s or more, then "land" plays flat; a jump of 5.5 m/s lands this way every
  time (`player.gd:430`, `audio.json`). "jump" itself is silent.
- W14 Footsteps every 1.4 m on the floor, "step_wood" or "step_tile" by surface (`player.gd:423-444`). Wired in core/17;
  a test here reads it from the player's real walk.
- W15 When a lost Sock or Pair comes back to the washer's front, then "pop" plays in 3D at each, except one only
  pushed up out of a slab (`hands_rules.gd:497, 508`; the motion is core/16 P12).
- W16 A name unknown to the catalogue fails a test (core/17 S01); every wired call uses a name of the catalogue.
- W17 When a Pair is shelved and a Drawer fills, then "coins" plays and the pad rumbles "done": M4, with the Coins flight
  (core/04 C06), not here.

## Design (draft)
- Calls only, no new system: `Sounds.play(&"x")` for the player's own, `Sounds.play_at(&"x", pos)` for the world, at the
  seams core/17 names (`Parts.applied`, `Player._on_applied`, `Player._set_charge`, `Player._throw`, the flights'
  contact, `Openable._show(false)`). Rumble is one `PadRumble` static with a typed `RumbleCue` Resource per cue
  (weak, strong, seconds) in `game/audio/`.
- Rule of core/17: only the machine that decided the moment plays it; a Guest hears the Host's answer through the same
  `Parts.applied`.
- The Sounds station (core/22) already lists every event; the new calls need no change there.
- Model: Sonnet.

## Acceptance
- One test per behaviour line; the real-path case: the player, in the handling and the Cabinet stations, picks, pairs,
  cycles, drops, throws, is refused and shelves, and the events heard (and the rumble last asked) are read in order.
- No still (sound only). The designer listens in a play session; the ticket waits for batch 6.

## Answers
- The bounce follows the hit speed: soft hits quiet, hard ones louder and higher (Q2371, 2026-11-21).
- Each sound event has a minimum gap set in its SoundEvent, e.g. 0.05 s for bounce (Q2372).
- The shelve sound plays at the click, as the old game (Q2373).
- Pad rumble always on, a setting `pad/rumble` (default on) for the menu later (Q2375).
- A teammate's own sounds and the knockdown rumble: M0.6 (Q2376).
- Every jump lands with "land", as the old game (Q2377).
- Q2278 (every old sound and rumble, plug-and-play), Q2296 (core sounds and rumble in M0.5), Q2318-Q2321 (catalogue,
  the old picks and volumes, the station, muffling, steps, ambience), Q2302 (pad differences later; the rumble is not one).
- core/17's Built log lists the old details it left out; those of the core are here.

## Open follow-ups

## Built log
