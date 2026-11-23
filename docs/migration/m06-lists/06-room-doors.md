> Behaviour list for house/08 (the room Doors in the house), written from the reference on 2026-11-23. **Not yet approved:** the questions at the end wait for the designer. Step 2 (build) starts after the answers; each `(changed by Q####)` is added then.

# M0.6 piece 6: The room Doors (behaviour list)

Words follow `GLOSSARY.md`. Paths are in `reference/it-socks/` (tag v0.1.1) unless they start with `game/`, `docs/`, `data/`
or `assets/` of the port (a line says "port" then). "Old" is the game at tag v0.1.1. A line is one thing the designer can keep
or drop. Nothing is left out as minor.

The old room Door is three parts: **`Doors`** (`game/house/doors.gd`, 178 lines: the records, which stand open, the push
maths), **`DoorRules`** (`game/house/door_rules.gd`, 93 lines: the `door` Command, the push, the New Game's shut share) and
**`RoomDoor`** (`game/house/room_door.gd`, an `Openable`: the leaf, its swing, its sound). Numbers are in
`data/tuning/doors.json` (`shut_share` 0.333, `swing_time` 0.6, `muffle_db` -9, `muffle_cutoff_hz` 900, `reach` 0.12) and the
eight records `room_doors[]` of `assets/house/house_layout.json`. The Socks the swing sweeps are `SockBodies.sweep()`
(`game/world/sock_bodies.gd:405`).

Scope tags used below:
- **(zoo)** can exist in a zoo station today.
- **(needs a house)** needs the house of house/03-05 (rooms, levels, the generator); it exists now.
- **(needs Stages)** the old locked doors and the floor campaign (M4).
- **(needs the Old Tree)** the Upgrade station in the garage (M4).
- **(needs devices)** the Radio, the TV and the washing machine, not yet in the port.

## Already in the port

- Exists: the Door entity `game/entities/door/door.tscn`: a Node3D with an `Openable` Part (`open_sound` `door_open`, `close_sound`
  `door_close`, `noun` "Door") and a swappable Looks `looks_graybox.tscn` (a 0.9 x 2 x 0.05 m brown leaf on a `Hinge`, an AnimationPlayer
  "open" of 0.6 s, eased in and out, turning 90 degrees; contract `looks_contract.json`: nodes `Hinge`, `Outline`, animation `open`).
  Not placed in the house; the zoo has it in the cupboard and drawer stations.
- Exists: `Openable` (`game/parts/openable.gd`): state `open`, the `open` Command carrying the wanted value (refused `far`, `locked`,
  `already`, `wrong`), the prompt "Open the Door" / "Shut the Door" (Q2388), `reach` 4 m, a sound once per turn-over by use and none when a
  state arrives whole (a load, a late Guest), the swing turning back smoothly from where it is, the group `openables`.
- Exists: the Mess sweeps every moving `Openable`'s AnimatableBody3Ds over the Socks lying and in flight: the Host wakes them, a Guest
  sweeps its own (coop/08, so the backlog line "Doors and drawers sweep on the Host only" is already answered in the zoo); a Sock in a leaf
  when it shuts is pushed out of it, flat, to the side the leaf swept from (core/39, Q2428). (port `docs/architecture/mess.md`)
- Exists: muffling: `Sounds.is_muffled(where)` looks from the camera to the sound through up to 6 walls and shut Doors; a shut `Openable` of
  `door.tscn` muffles (-9 dB, 900 Hz, the `Muffled*` buses, Q2321). (port game/audio/sounds.gd:248, `muffling_scenes`)
- Exists: the house shell (`game/house/shell.tscn`, `tools/house_shell_build.gd` PARTITIONS) has the doorways as `door_partition_*` kit
  pieces, open: 4 in the basement, 2 on the ground floor, 4 on the first floor (10; the old house had 8 Doors, none on the ground floor).
  The front and garage doors stay shut plain leaves (Q2514).
- Exists: a late Guest gets every Part's state whole (`Part.whole_state()`), so an open or shut Door arrives as it stands.
- Missing: Doors in `house.tscn`; a Looks fitted to the kit's doorway; the share shut at a level's start; a station of Doors in a house setting.

## Behaviour list

### A. Which doorways have Doors, and where each stands

1. When the house is built, then eight doorways have a room Door: basement WorkshopLobby, LaundryLobby, BoilerLobby, LobbyGarage; first
   floor OfficeLanding, BedroomLanding, BathroomLanding, KidsLanding. The ground floor's doorways have none (open for good). (needs a house)
   (see Q1) (ref: assets/house/house_layout.json room_doors; game/house/flat_layout.gd:655-658)
2. When a Door is placed, then it stands in its doorway's wall line with its hinge at one jamb and the leaf running along the doorway: leaf
   0.866 m wide, 2.075 m high, 0.04 m thick, in a wall 0.12 m thick, 0.008 m off the floor. Each record names its hinge point and the
   direction the leaf runs. (needs a house) (see Q6) (ref: house_layout.json room_doors width, thickness, wall, min, max, hinge, along)
3. When a Door opens, then it turns 90 degrees into its own room (the record's `into`; the sign of `open_deg` is +90 for WorkshopLobby,
   BoilerLobby, LobbyGarage, OfficeLanding and -90 for LaundryLobby, BedroomLanding, BathroomLanding, KidsLanding), so a leaf never swings
   out into the stair lobby or the landing. (needs a house) (ref: house_layout.json open_deg, into; game/house/doors.gd:3-5)
4. When two Doors stand on one wall line (WorkshopLobby and LaundryLobby, 0.334 m apart on the lobby's west wall; OfficeLanding and
   BedroomLanding likewise), then each swings into its own room, so they never meet. (needs a house) (ref: house_layout.json hinge z 3.063, 3.397)
5. When a doorway has a Door, then it is one single leaf: no double doors. (ref: game/house/room_door.gd:1-9)
6. When the front door and the garage door are met, then they stay shut leaves nobody opens (kept, Q2514). The elevator's hatches are not room
   Doors. (ref: house/04)
7. When a Door is made, then it is the one entity `game/entities/door/door.tscn` placed once per doorway under `Doors` in `house.tscn`, named
   as the old doorway ("KidsLanding"); only its placement differs. (Q2251: behaviour plus a swappable Looks)

### B. Aiming, the prompt and the click

8. When the crosshair is on a Door's leaf (the leaf's collision is a Station on the pick layer), then the Door is outlined and the prompt
   reads "Open the Door" while it is shut, "Shut the Door" while it is open. (zoo) (kept, Q2388) (ref: game/house/room_door.gd:76-78; game/house/openable.gd:108-109)
9. When the player is more than 4 m from the Door, then there is no prompt and the press does nothing (refused "far"). (zoo)
   (the port's `Openable.reach`) (ref: game/player/rig_click.gd:139-171)
10. When the player presses the use button (the port's use action, E or the click) on the aimed Door, then the Host is asked to turn it the
    other way: the Command carries the wanted value, so of two players pressing at once the second is refused "already" and does not undo the
    first. (zoo) (the old `door` Command, `name` + `open`) (ref: game/house/door_rules.gd:23-45; game/player/rig_click.gd:169-171)
11. When a Door is turned, then every player sees it swing, whoever pressed. (zoo) (ref: game/house/door_rules.gd:42-44)
12. When a Guest presses more than 5 times a second, then the presses over that rate are dropped. (zoo) (port: `Openable.accepts` rate 5)
13. When a player or a Sock stands in a Door's arc, then nothing refuses the press: a Door is never "blocked"; it swings and pushes (rows
    21-28). (ref: game/house/room_door.gd:9-10)
14. When a Door is locked, then it refuses ("locked") and does not swing. The old locked doors are the floor doors at the top of the stairs,
    not room Doors. (needs Stages) (ref: game/campaign/locked_door.gd)

### C. The swing

15. When a Door swings open or shut, then it takes 0.6 s, eased in and out both ways (sine in-out). (zoo) (kept: Q2368; the designer tunes the
    curve in the AnimationPlayer, Q2403) (ref: data/tuning/doors.json swing_time; game/house/room_door.gd:36-48)
16. When a Door is turned again while swinging, then it turns back from where the leaf stands (never a jump to an end). (zoo) (the port's
    `Openable` turns back from the pose now) (ref: game/house/openable.gd `_animate`, `_from()`)
17. When a Door swings, then the leaf turns about its hinge on the vertical axis only; it never slides or lifts. (zoo) (ref: game/house/room_door.gd:39-41)
18. When a Door stands shut, then its leaf is a wall: it stops the player, thrown Socks and the crosshair, and casts the sun's and the lamps'
    shadows. When open, the leaf stands against the wall in its room, a box that still stops what hits it. (zoo) (ref: game/house/room_door.gd:3-7)
19. When a Door is in its doorway, then the frame and casing stay (they are the kit's wall piece); only the leaf moves. (needs a house) (ref:
    assets/house/house.glb; the old leaf `Door_<name>` node taken out of the model)
20. When the level starts or a late Guest joins, then each Door stands at its end pose with no swing and no sound. (zoo) (port `_show(now)`)
    (ref: game/house/room_door.gd `set_open(open, now)`)

### D. What a swing does to Socks and players (Q403)

21. When a Door swings, then every Sock lying in the leaf's way is moved out of it by the leaf, and wakes if it must; Socks pushed into others
    wake those. (zoo) (the port's sweep, core/13 and core/39; the old also moved them by maths at the click, see Q2) (ref: game/world/sock_bodies.gd:405; game/house/door_rules.gd:55-74)
22. When a Door shuts onto a Sock lying where the leaf will stand (the reveal, the doorway), then the Sock is pushed out of the leaf, flat, to
    the side the leaf swept from, never sent to the return spot with a pop. (zoo) (kept, Q2428; the old pushed a Sock in the reveal out in front
    of the doorway on its other side, `_beyond`: see Q2) (ref: game/house/doors.gd:122-129, 133-145)
23. When a Sock is moved by the old push, then it lies still where it goes: a push is not a throw. (the old; the port's sweep may leave a Sock
    in flight for a moment, see Q2) (ref: game/house/door_rules.gd:55-58, 64-74)
24. When the Radio lies in a Door's way (on the floor), then it is pushed out too. (needs devices) (ref: game/house/door_rules.gd:84-91)
25. When a floor Pair lies in a Door's way (a dropped Pair), then it is pushed out and re-shown. The port has no floor Pairs: a Pair is two
    Mess Socks. (not ported: no floor Pairs) (ref: game/house/door_rules.gd:76-83)
26. When a swinging leaf meets a standing player, then it moves through them and the physics nudges them out as they move; the player is not
    stuck and not thrown, and the leaf never stops. (zoo) (the old open follow-up of house/21; the port's player is a character body against an
    animated body: to be tried in step 2) (ref: game/house/room_door.gd:9-10)
27. When the old push finds no free spot for a Sock in the arc (furniture, another room), then it goes out in front of the doorway on the
    other side, kept 0.15 m off the jambs. (the old `_free` and `_beyond`; the port's sweep leaves it on the side the leaf swept from: see Q2)
    (ref: game/house/doors.gd:122-154)
28. When a Sock lies on a Door's open leaf (a thrown Sock landing on its top edge), then it slides off when the leaf turns: no Sock sticks to a
    moving leaf. (zoo) (port: Jolt) (ref: game/world/sock_bodies.gd:724-745)

### E. Sounds

29. When a Door starts to open, then "door_open" plays once, a world sound at the leaf (1 m over the floor in the old game), full within 3 m,
    gone at 20 m, pitch +-5% from its pool; "door_close" plays when it starts to shut. Everyone hears it (the Host's answer). (zoo) (kept: the
    port's `Openable` sound, which plays at the thing's origin) (ref: game/house/room_door.gd:51-62; game/house/openable.gd CUE_STEMS "door")
30. When a Door is refused (far, already), then no sound. A state that arrives whole (a load, a late Guest) makes none. (zoo) (port)
31. When two sounds of a kind come within 0.1 s, then the second is dropped (the sound's min gap). (zoo) (port sound catalogue)
32. When a shut Door stands between the listener and a sound (the Radio, the TV, the fridge, the clock, a voice, a Sock's bounce), then the sound
    plays muffled: -9 dB, low-passed at 900 Hz, until the Door opens. A sound at the shut Door itself is not muffled by it. (zoo) (built, Q2321:
    the port asks by rays, the old by rooms joined only through shut Doors) (ref: game/audio/sfx.gd:191-215; data/tuning/doors.json muffle_*)
33. When a Door opens, then sounds behind it lose their muffling as the leaf clears the line (the port's ray sees the leaf's collision, which
    moves with the swing); the old changed it at once when the swing began. (a difference of timing; see Q7) (ref: game/house/door_rules.gd:42)
34. When the ear and a sound are in the same room, or in rooms joined by an open doorway, then the sound is clear; a Door shut in a third room
    does not muffle it. (zoo) (ref: game/audio/sfx.gd:197-202)
35. When the player walks through a Door, then the leaf makes no sound (no latch, no creak); footsteps are the floor's. (ref: game/house/room_door.gd)

### F. The shut share at a New Game (Q518, Q2528)

36. When a New Game starts, then about a third of the Doors start shut: `round(count x 0.333)` of them (3 of the old 8), picked from the seed by a
    shuffle, the rest open. (needs a house) (changed by Q2528: from the level's seed, with the generator, core/52) (ref: game/house/doors.gd:75-92;
    game/house/door_rules.gd:86-93; data/tuning/doors.json shut_share)
37. When the Doors are picked, then LaundryLobby and LobbyGarage (the way from the laundry room to the garage) always start open, so the Old
    Tree's calls carry. (needs the Old Tree) (see Q3) (ref: game/house/doors.gd:61-63)
38. When the shut ones are chosen, then the old game swung them shut at the New Game's bake, with their sound, under the loading screen, pushing
    out the Socks the layout had left in their way (the layout ran with every Door open). (changed: see Q4; the port's generator lays onto the
    house as it stands) (ref: game/house/door_rules.gd:86-93; game/core/main.gd:661-662)
39. When the same seed starts the level again, then the same Doors start shut. (kept: same seed, same shuffle) (ref: game/house/doors.gd:75-92)
40. When a game runs with random layouts off (the tests, the shots, the zoo), then every Door starts open unless the test says otherwise. (kept:
    the old `shut_doors_at_new_game` switch; the port: the share is a typed number, 0 in a test) (ref: game/core/game.gd:271-272)
41. When the share is changed, then it is one number on the level's resource (typed, placeholder until the designer sets it), not a constant.
    (port)

### G. Co-op

42. When a Door is turned, then the Host decides (the `open` Command's answer) and every machine shows the swing and plays the sound; a Guest
    cannot change a Door by itself. (ref: game/house/door_rules.gd:41-47)
43. When a Door swings, then the Host's sweep moves the Socks, and a Guest sweeps its own copy of the leaf over its own copy of the Socks for the
    looks; the Host's answer decides where they lie. (kept: coop/08; the old pushed by the same maths on every machine) (ref:
    game/house/door_rules.gd:54-58)
44. When a Guest joins late, then each Door stands as it stands now (open or shut; one mid-swing at its end pose), with the Socks that were pushed
    already where they lie. (needs a house) (ref: game/house/doors.gd:166-172 to_dict/load_dict; the port's whole state)
45. When two players turn two Doors in the same moment, then each is its own Command; they never undo each other. (ref: game/house/door_rules.gd:23-45)
46. When a Guest hears a Door, then it is muffled by its own rays from its own camera, not the Host's. (ref: game/audio/sfx.gd)
47. When a player leaves, then the Doors stay as they are. (ref: game/house/doors.gd "Doors never move by themselves, Q520")

### H. Persistence and state

48. When a game is saved, then each Door's open or shut is saved; a load shuts them (Q2559: "Doors, drawers and lids shut" at a load). (needs
    saves, M7) (changed by Q2559) (ref: game/house/doors.gd:166-172; game/core/saves.gd)
49. When Doors are decided, then nothing moves one but a player (no cat, no draught, no timer); a cat opening Doors is its own piece. (ref:
    game/house/doors.gd:10 "Doors never move by themselves, Q520")

### I. Looks

50. When a Door is drawn in the old game, then the leaf is the house model's own `Door_<name>` mesh, taken out of the model and put on the
    hinge. (ref: game/house/room_door.gd `build`) (see Q5)
51. When a Door's leaf is graybox, then it is a plain 0.9 x 2 x 0.05 m box (the port's stand-in). A Looks scene with the same contract (nodes
    `Hinge`, `Outline`, animation `open`) swaps it with no code change. (zoo) (port)
52. When the Door's Looks changes, then the sweeps and sounds do not. (port; the old collision was the record's box, not the mesh) (ref:
    game/house/room_door.gd `build`, FlatLayout._box)

### J. Station and tests

53. When the zoo's Doors station is used, then it shows a Door in a doorway-like wall, open and shut, with a Sock lying in its arc and a sound
    behind it to hear the muffling. (zoo) (the port's zoo rule, Q2337)
54. When the old tests ran, then they checked: every Door open at start, `shut_share` of them shut by a seed, TREE_PATH open, a push out of the
    arc, a push out of the reveal, one Command one swing, a join snapshot. (the old test files were not read whole)

## Differences the port already has (not questions)

- The old pushed Socks by maths at the click (`Doors.pushed`, rows 21-23, 27); the port's physics sweep moves them as the leaf moves (core/13, core/39).
  Q2 asks whether to keep the old push as well.
- The old Door was one class of `Openable`; the port's is the Part `Openable` on an entity with a Looks child (Q2251).
- The old swing was a code Tween; the port's is an AnimationPlayer in the Looks.

## Questions for the designer

1. **The ground floor's two doorways.** The old house had Doors in the basement (4) and first floor (4) and open doorways on the ground floor. The
   port's shell has 2 ground-floor doorways with the same kind of kit door piece. (a) No Doors there (as the old; 8 Doors, 3 shut). (b) A Door in
   each (10 Doors, 3 shut at a New Game). (c) A Door in each but never shut at a New Game. Recommended: (a): the ticket says "in the old doorways", the
   old house is the reference, and a Door there is a one-line addition later.
2. **How a Door moves a Sock: the physics sweep only, or the old push as well.** The old game both swept (the leaf as a body over resting Socks) and,
   at the click, moved every Sock in the quarter disc and the reveal out by maths, into the room or in front of the doorway on the other side, the Socks
   lying still after (rows 21-23, 27). The port has the sweep, and a Sock caught in a shutting leaf is pushed flat out of it (Q2428). (a) The sweep
   only: Socks wake, may roll a little, a Sock in a shutting leaf goes to the side the leaf came from. (b) The sweep plus the old push at the click:
   nothing lies in a Door's arc and every Sock lies still where it is put. (c) The sweep, and the old push only for the reveal (what a shutting leaf
   would crush). Recommended: (a): Q2308 and Q2428 chose the physics and "pushed out", the Mess already does it on both machines, and the old push's
   "other side of the doorway" is dropped (rows 22 and 27 change accordingly).
3. **LaundryLobby and LobbyGarage always open (row 37).** The old kept both open at a New Game so the Old Tree's calls carry; the Tree is M4. (a)
   Keep a list of the two names on the level's resource now, used until the Tree exists. (b) Drop it: any Door may start shut. Recommended: (a): a
   two-name list costs nothing and the Tree is still planned.
4. **Shut at the start: at once and silent, or the old swing.** The old swung the shut ones closed at the New Game under the loading screen, with
   their sound. The port has no loading screen and starts a level with no sound (Q2523). (a) They start shut, no swing, no sound, and the generator
   lays Socks knowing which leaves are shut. (b) They swing shut when the level appears, with the sound. Recommended: (a).
5. **The leaf's Looks.** The old leaf was the house model's panelled leaf; the port's is a graybox box. (a) Keep the graybox in this ticket, and make
   the leaf's look in a later look ticket (Q2153). (b) Build the panelled leaf from the kit's wood materials now (a Blender job). Recommended: (a): the
   ticket is the behaviour; the strip shows the graybox shut, mid-swing and open.
6. **The leaf's size against the kit's doorway.** The old leaf is 0.866 x 2.075 m; the port's graybox is 0.9 x 2 m and the kit's piece is named 1.5 m
   (the opening inside it is not read yet). (a) Size the leaf to the kit's real opening, read in step 2, the old numbers a guide. (b) Keep the old
   leaf size whatever the opening is. Recommended: (a): a leaf that does not fill its doorway is a visible fault.
7. **Old details to keep or drop** (Q2277): the sound at 1 m over the floor, not at the leaf's origin (row 29); the muffling lifting as the leaf
   clears the line, not at the swing's start (row 33); the swinging leaf nudging a player through the physics (row 26); a quiet walk-through (row 35);
   the cat opening Doors (row 49, its own later piece). Recommended: keep rows 26 and 35 as written, take the port's sound place and muffling timing
   (rows 29, 33) as differences to show in the station, park the cat to its piece.
