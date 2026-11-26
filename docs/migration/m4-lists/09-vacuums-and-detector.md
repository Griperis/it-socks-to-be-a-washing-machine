> Draft behaviour list for batch C's vacuums and the Sock detector (core/148), written from the reference on
> 2026-11-26; for the designer to approve. No proposal is built on it yet: the design ticket follows the designer's
> look (index: `batch-c.md`).

# Batch C piece: the Sock vacuum, the Backpack vacuum and the Sock detector

Draft behaviour list (catalogue B30 Sock vacuum, B32 Sock detector, P01-P07 the vacuum devices; their five House
Upgrades). The catalogue's P rows were "planned" when it was written; v0.1.1 has them built: the Spit and the Pour
and the Filter (P02, tools/25), the Backpack vacuum (P03, tools/27), the Filter nozzle Upgrade (P05, tools/29), the
models (P06, tools/30) and the glossary words (P07: in the port's `GLOSSARY.md` already, Q2188-Q2195). Refs are in the
old game (`reference/it-socks/`, tag v0.1.1) unless they start with `port:`. Short forms: VA =
`game/devices/vacuums.gd`, VV = `game/devices/sock_vacuum_view.gd`, VFX = `game/devices/vacuum_fx.gd`, WH =
`game/devices/window_heap.gd`, BP = `game/devices/backpack_vacuums.gd`, BPV = `game/devices/backpack_vacuum_view.gd`,
SF = `game/devices/sock_filter.gd`, SFD = `game/devices/sock_filter_display.gd`, BR = `game/devices/beeper_rules.gd`, BM
= `game/devices/beeper_model.gd`, BV = `game/devices/beeper_view.gd`, FR = `game/world/flight_rules.gd`, G =
`game/core/game.gd`, UP = `game/campaign/upgrades.gd`, SB = `game/audio/sound_bank.gd`, TVD =
`game/audio/tree_voice_director.gd`, HL = `assets/house/house_layout.json`, UJ:<line> = `data/upgrades.json`,
T:<name> = `data/tuning/<name>.json` (every number there is a placeholder in the old game too, unless a Q set it), GL
= the port's `GLOSSARY.md`, DC = `docs/migration/digests/digest-devices-cat-story.md` Part A.

Marks: "(11)" a line of list 11 (the Elevator); "(batch D)" a line of a later batch; "(co-op)" a line that needs co-op
(who sees what, the Host's answer); "(sound)" a sound, "(rumble)" a pad rumble (the devices have none of their own:
a Throw of the detector buzzes "throw", a knock "knock"); "(Secrets, later, Q2682)": none hang on these devices. Not
ported (Q2599): the Splitter (P04) and its four Upgrades (UJ:687-770), the pairing machine (the vacuum's hopper feed,
`pairing_feed`, VFX:324-326) and its Wide Funnel (UJ:643), the Hampers (their pour into a vacuum). Removed in the old
game already by tools/25 and not proposed again: the mode button, hand mode's take-one click, the rear outlet's timed
spit and the Quick Spit Upgrade (Q2097, Q2119); the `vacuum_mode_click` and `vacuum_spit_out` sounds stayed in the bank
unused (SB:106, SB:108). The old models (`assets/sock_vacuum/`, `assets/vacuum_devices/backpack_vacuum.glb` and
`nozzle_display.glb`, `assets/sock_detector/sock_detector.glb`) are not in the port yet.

## Behaviour list

### Where they are
- When a New Game starts, then the house's one Sock vacuum stands in the kitchen (ground floor) and two Backpack
  vacuums lie beside it, whatever the player count; the Sock detector lies on the workshop's workbench beside the
  encyclopedia book (0.35 m to its side, turned 20 degrees), falling onto what is under it. (ref: HL `machines`;
  G:785-800; BR:52-72; T:beeper start; Q1822, Q1827, Q2101, Q2132, Q2136; port: the book is batch B's, core/139)
- When the kitchen's floor is locked, then the vacuums are out of reach behind its lock; nothing else gates them.
  (ref: G:785-787; Q1041)
- When the ground floor opens, then the Old Tree's "tip_vacuum" is due for each player, said once per player per run
  when they are near (3 lines, e.g. "There's a vacuum in the kitchen now. It gobbles up loose socks in a flash. Don't
  be too proud to use it."). (ref: TVD:32-39, TVD:214-228; `data/voiceover/old_tree/tree_tip_vacuum_1..3.json`; Q1594,
  Q1606; port: core/132 copies the recordings, core/133 leaves this trigger to batch C) (sound) (co-op)

### The Sock vacuum: the nozzle
- When a player left-clicks the nozzle (on its hook or lying), then it comes into their Hands and takes the whole
  Hands: held Socks and Pairs drop to the floor; with something else carried (the Radio, a Gift box) they read "Hands
  full"; one nozzle per vacuum, a teammate's held one is gone. (ref: VA:1-10, VA:383-450; VV:15-22; Q720, Q732, Q734,
  Q736, Q742) (co-op)
- When the left button is held with the nozzle in the Hands, then the suction is on: the nearest loose Mess Sock in the
  cone in front (2 m, 22 degrees each side) that passes the filter flies into the nozzle (0.2 s) and lands on the heap
  in the Tank, one every 0.12 s (Strong Suction lowers it); Pairs, Socks in Hands, shelved Socks and Gifts are never
  touched. (ref: VA:1-10, VA:281-299; VV:18-21; UP:249-258; T:vacuum reach, cone_deg, fly_time; T:upgrades house
  suck_interval_*; Q721, Q1362)
- When a Guest sucks, then their own machine flies the Sock to the nozzle at once (a prediction); the Host's answer
  confirms it, or the Sock lands back. (ref: VA:23-26, VA:603-623) (co-op)
- When the Tank is full (24 Socks; Big Bag adds 12 a level), then sucking stops: the hint reads "Vacuum: full" and
  nothing happens. (ref: VA:86-92, VA:150-154; VV:232-235; UP:253-254; T:vacuum capacity; Q725, Q738)
- When the Host refuses a suck, then the reason is: not held, gone, full, a teammate's Pour tilting it ("tilted"), the
  filter ("filtered") or out of reach ("far"). (ref: VA:383-450; Q2088, Q2118)
- When the nozzle holder taps right click (shorter than `spit_tap` 0.25 s), then the nozzle drops where aimed within
  the hose's reach and lies on its hose ("Drop the nozzle"); aimed at its own container, or dropped within 0.6 m of
  its hook, it hangs itself ("Hang the nozzle"); out of reach they read "The hose won't reach". (ref: VV:19-21,
  VV:174-200, VV:263-266; VA:260-280; T:vacuum hang_reach, spit_tap; Q741, Q2115)
- When the nozzle holder holds right click (longer than the tap), then the Spit: a stream of Socks out of the nozzle
  toward where they aim (within 4 m, at 4 m/s, a little scatter), one every 0.1 s, oldest first, ignoring the filter;
  the release drops nothing; each spat Sock is in Flight until it rests and starts on the room's side of a wall.
  (ref: VA:12-17, VA:228-258, VA:314-319, VA:353-377; VV:19-21; T:vacuum spit_*; Q1585, Q2096, Q2111, Q2115-Q2117)
  (co-op)
- When many released Socks are in the air, then the stream waits while 24 of them fly (the shared budget of released
  bodies), so the spit slows. (ref: VA:15-17, VA:223-227; T:vacuum spit_bodies; Q1257)

### The Sock vacuum: the hose
- When the nozzle is out, then the hose (cream and ribbed, chrome cuffs at both ends) runs from the container's top to
  the nozzle as a rope that drapes over furniture and wraps round door frames, never through walls; at its length
  (5 m; Long Hose adds 2 m a level), measured along where it lies, it pulls taut with a tug (0.25 s of shaking) and the
  holder cannot walk further. (ref: VV:8-12, VV:599-660; VA:62-66, VA:200-206; UP:261-263; T:vacuum hose, tug,
  hose_*; Q733, Q936, Q1079)
- When a room Door, a furniture door or a drawer moves against the hose, then it pushes the hose; the Elevator's car
  does not. (ref: DC A1; Q1105) (11)
- When each machine lays the hose, then it lays its own (the rope is looks); the Host refuses a drop or a suck past
  the hose's length along where it lies on the Host. (ref: VA:62-66; VV:8-12; host_slack 1 m: T:vacuum) (co-op)
- When the hose is idle and off screen, then it costs nothing: only a vacuum in use, a tug or a moving hose is placed
  each frame (a held hose at most 0.3 ms a physics tick). (ref: VV:488-508, VV:575-585; T:vacuum hose_budget_ms;
  designer, tools/12)

### The Sock vacuum: the container, carrying and the Pour
- When a player left-clicks the container with its nozzle on its hook (or in a teammate's Hands), then they pick the
  whole vacuum up (it takes the whole Hands; "vacuum_lift"); right click puts it down ("vacuum_set_down"); no sucking
  while it is carried by the nozzle's holder. (ref: VA:320-330; VV:15-22; VFX:316-321; Q724, Q742) (sound)
- When one player carries the container while a teammate holds its nozzle, then both work: at the hose's length
  whichever walks away is stopped with the tug, neither drags the other; a teammate may also take the nozzle off a
  carried container. (ref: VA:7-10; VV:10-12, VV:101-103; Q1135; DC A1 Open tools/10) (co-op)
- When the carrier holds E, then the Pour: the container tips about 70 degrees forward over 0.25 s (everyone sees it
  tilt) and one Sock falls out over its front lip every 0.15 s (0.6 m/s forward) until E is released, the carrier
  lets it go or it is empty; a teammate's suction pauses while it is tilted; a poured Sock makes no sound of its own,
  only its landing. (ref: VA:12-17, VA:37-41, VA:178-189, VA:307-313; VV:22, VV:55, VV:201-223; VFX:9-11; T:vacuum
  pour_*; Q2097, Q2098, Q2118, Q2120, Q2128) (co-op)

### The Sock vacuum: what it shows
- When it stands, then it is a mint canister of the retro appliance family with a capsule window at the front showing
  its load as a settled heap of low-LOD Socks in their Designs (a sucked Sock drops onto the top and settles), a fill
  gauge in a slot beside the window, and a parking clip at the side where the nozzle hangs upright. (ref: VV:1-8,
  VV:26-48, VV:428-446; WH:1-33; Q939, Q941, Q1490)
- When the crosshair is on a part of it, then the hint counts the load: "Take the nozzle   n/24", "Pick up   n/24",
  "Sock vacuum   n/24"; no floating 3D text. (ref: VV:13, VV:247-262; Q737)
- When the nozzle is held, then the hints read "Hold: Vacuum [LMB]", "Drop the nozzle [RMB]", "Hold: Spit out [RMB]",
  and with the Filter nozzle "Up: Size  Down: Collection [wheel]"; carrying the container, "Hold: Pour out [E]", "Put
  down [RMB]". (ref: VV:232-246)
- When the nozzle is held, then the holder sees it low and right in front of the camera along the aim; a teammate sees
  it in that player's hand along their aim. (ref: VV:586-598) (co-op)
- When the Nozzle display shows, then on the nozzle's clip-on pod it shows how full the Tank is from the start, and the
  Size (a word) and the Collection (its icon and name) once the Filter nozzle is bought; it blinks a red frame each
  half second while a filter is set and nothing in front of the nozzle matches; no count of Socks left in the house.
  (ref: SFD:1-9, SFD:95-135; VV:51-57, VV:447-460; Q2122, Q2173, Q2187; GL "Nozzle display")

### The Sock vacuum: the Filter (with the Filter nozzle)
- When the Filter nozzle is bought and the nozzle is held, then the wheel steps its Filter: wheel up the Size, wheel
  down the Collection; each list is "any", then the values, wrapping; the Collection list holds only Collections with
  a loose Sock in the Mess now (Lost Socks when one lies loose); a set Collection stays set when it runs out and the
  next step starts from "any". (ref: SF:1-82; VA:18-21, VA:109-113, VA:300-306; Q2087, Q2089, Q2121, Q2123, Q2124)
  (co-op)
- When both halves are set, then a Sock must match both; either may be "any"; the nozzle picks the nearest matching
  Sock and the Host refuses a mismatch. (ref: SF:16-24; VA:212-216; Q2088)
- When the vacuum's Filter is set, then it lives on the vacuum, shared by whoever holds its nozzle, saved and in the
  join snapshot. (ref: VA:18-21, VA:652-690) (co-op)
- When the Filter nozzle is not bought, then the wheel does nothing and the nozzle sucks everything in reach. (ref:
  VA:109-113; GL "Filter nozzle")

### The suck's look and sounds
- When a vacuum's suction is on (held, button down, not full), then soft white air streaks (18, 0.28 s each) flow into
  the nozzle's mouth and dust motes (14, 0.7 s) rise off the floor in front of it into the mouth; every machine sees
  it (a teammate's comes with their pose). (ref: VFX:1-6, VFX:13-32; Q1136) (co-op)
- When the suction is on, then the motor runs (a 3D loop at the container, fading in and out over 0.12 s). (ref:
  VFX:4-5, VFX:250-270; SB:104; Q1137) (sound)
- When a Sock is sucked in, then a "thwip" plays; when one is spat, the spit tick plays at the nozzle's mouth; the
  per-Sock sounds keep 0.09 s apart per vacuum. (ref: VFX:8-12, VFX:296-326; SB:105, SB:107; Q1137, Q2128) (sound)
- When the nozzle is hung or dropped, or the vacuum lifted or set down, then "vacuum_nozzle_hang", "vacuum_nozzle_drop",
  "vacuum_lift", "vacuum_set_down" play at it, for everyone. (ref: VFX:300-321; SB:109-112) (sound) (co-op)

### The Backpack vacuum (tools/27)
- When a player left-clicks a lying Backpack vacuum with empty Hands, then they carry it (it takes the whole Hands;
  first come, first served: another got there first is refused); right click puts a carried one down, to share it.
  (ref: BP:1-6, BP:180-205; BPV:8-12, BPV:118-132; Q2129, Q2130, Q2132) (co-op)
- When the carrier presses E, then they wear it: the nozzle comes out and takes the whole Hands; E again takes it off
  into the Hands ("Put it on [E]", "Take it off [E]"). (ref: BP:3-6; BPV:118-121; Q2093, Q2130)
- When it is worn, then the left button held sucks every Sock in the cone (the Sock vacuum's reach, cone and rate, no
  filter, no hose limit) into its own Tank of 16 (Big Bag adds to it); full, the hint reads "Backpack: full" and it
  stops. (ref: BP:8-12, BP:206-230; BPV:8-12, BPV:118-119; T:backpack tank; Q2125, Q2131, Q2135)
- When the wearer holds right click, then it Spits as the Sock vacuum does (the same pace and budget); there is no Pour.
  (ref: BP:9-12; Q2096, Q2099, Q2111)
- When it is worn, then the wearer sees only the nozzle with its dial gauge (the needle turns with the fill); a
  teammate sees the capsule tank on the wearer's back (straps round the body) with a hose from its port to the nozzle;
  lying or carried, its straps hang loose and the nozzle stands in its clips; its porthole shows the load as a heap. A
  worn Wardrobe backpack is hidden while it is worn. (ref: BPV:1-6, BPV:13-24; Q2094, Q2134, Q2171) (co-op)
- When the wearer or carrier is knocked down or leaves, then it drops beside them with its load. (ref: BP:14-15;
  Q2133) (co-op)
- When the World is saved or a player joins, then each backpack's place, load, carrier and wearer are in it; a Guest's
  is laid where they stood. (ref: BP:14-15) (co-op)
- When Guests suck with it, then their sucks are predicted as the Sock vacuum's are. (ref: BP:17-18) (co-op)

### The Sock detector (B32, tools/15)
- When a player left-clicks the lying detector with empty Hands, then it comes into their Hands (the whole Hands, like
  the Radio); right click puts it down where aimed; aimed at a Teammate, it goes into their empty Hands (a Hand-off),
  else at their feet; a carrier who leaves drops it where they stood. (ref: BR:1-6, BR:44-110; GL "Sock detector";
  Q1822, Q1824) (co-op)
- When it is thrown, then it flies as a Throw; a full-charge Throw knocks down a Teammate it hits, a weaker one bounces
  off to their feet, never caught. (ref: BR:98-100; FR:55-59, FR:186-193, FR:298-304; knockdown/04, Q1935, Q1936;
  port: Q2483 left its knock to this milestone) (co-op) (rumble: the knock's buzz)
- When someone holds it, then every machine looks a few times a second (every 0.2 s) for the nearest loose Sock in the
  Mess on any floor from the holder's eyes (Socks in Hands, in the air or shelved do not count) and its screen shows the
  distance band as one to three bars (far from 10 m, mid, near within 3 m) in the band's colour (green, amber, red), and
  an up or down arrow when that Sock is on another floor (nothing on the holder's floor); no loose Sock left: the bars
  dim. (ref: BR:5-6, BR:14-17; BM:1-8, BM:144-170; BV:1-7, BV:116-138; T:beeper near_m, far_m, update_every, screen_*;
  Q1823, Q1826) (co-op)
- When someone holds it, then it beeps from its model ("beeper_beep", 3D, -6 dB, the ping's pool as a placeholder) at a
  gap from 0.12 s (within 0.5 m) to 1.6 s (from 20 m on), linear between; the holder and nearby Teammates hear it.
  (ref: BV:5-7, BV:18-28; SB:125; T:beeper close_m, beep_far_m, interval_*, volume_db; Q1823) (sound) (co-op)
- When it is held, then it is a flat handheld gadget whose screen fills almost all its face plate, held bigger and
  closer so the screen reads at a glance without covering much of the view; holding it never pushes its carrier. (ref:
  BM:1-8, BM:53-62; `data/tuning/hold.json` "beeper"; Q1857, Q1861-Q1863; tools/17)
- When it lies, then it has no Mess collider; it does not ride the Elevator; it cannot go in the washer's drum. (ref:
  DC A6 Open) (11)
- When the run's end pulls into the Drum, then it is moved in, the only house item there (batch D). (ref: GL "Sock
  detector"; Q1891)
- When the World is saved or a player joins, then its carrier, spot, turn and flight are in it. (ref: BR:1-6) (co-op)

### The Upgrades (batch B shows them "Coming soon", Q2669)
All House, bought with Drawers (prices placeholders); the Sock vacuum's and the Backpack's numbers both, unless named:
- `big_bag` (2 levels, 1/1, cell [2,0]): "The vacuum holds more Socks": +12 a level (Sock vacuum 24, 36, 48; Backpack 16
  plus the same). The card shows the capacity. (ref: UJ:484; UP:253-254; T:upgrades house big_bag_per_level; Q1356,
  Q2125; port: core/129, "Coming soon" until this piece)
- `strong_suction` (3 levels, 1/1/1, cell [2,1]): "The vacuum sucks more Socks per second. It starts at about half
  today's rate.": 0.12 s between Socks, 0.02 s less a level (0.06 s at 3); the card shows "%.1f/s". (ref: UJ:507;
  UP:249-258; T:upgrades house suck_interval_*; Q1362; port: core/129)
- `long_hose` (2 levels, 1/1, cell [2,2]): "The vacuum reaches farther": +2 m of hose a level (5, 7, 9 m); nothing for
  the Backpack. (ref: UJ:531; UP:261-263; T:upgrades house hose_per_level; Q2135; port: core/129)
- `wide_nozzle` (1 level, 1, needs Long Hose, cell [2,3]): "The vacuum's nozzle takes a wider swath": +1 m of reach and
  +10 degrees of cone (3 m, 32 degrees). (ref: UJ:554; UP:265-270; T:upgrades house nozzle_reach, nozzle_cone_deg;
  port: core/129)
- `filter_nozzle` (1 level, 2, no prerequisite, cell [2,4]): "The nozzle gets a display and a Size and Collection
  filter" (the Nozzle display shows the Tank from the start, Q2187: only the Filter lines come with it). (ref: UJ:578;
  UP:274-275; VA:109-113; Q2090, Q2126; port: core/129)

### Words
- When the devices' wording is shown, then it is the old: "Hold: Vacuum", "Vacuum: full", "Backpack: full", "Drop the
  nozzle", "Hang the nozzle", "Hold: Spit out", "Up: Size  Down: Collection", "Hold: Pour out", "Put down", "Put it
  on", "Take it off", "Take the nozzle   %s", "Pick up   %s", "Sock vacuum   %s", "Hands full", "The hose won't reach",
  "Sock detector", and the five Upgrades' names and tooltips from UJ; the code's own words are not renamed (GL names:
  Sock vacuum, Backpack vacuum, Tank, Spit, Pour, Filter, Filter nozzle, Nozzle display, Q2188-Q2195). (ref:
  VV:232-266; BPV:118-132; VA:532-600; BR:8-12)

## What was weak in the old devices
- Each device was plain data on the Game with its own Command prefix ("vacuum_", "backpack_", "beeper" events), its
  views built every part in code: the hose's tube mesh by hand each frame (VV, 1378 lines), the gauge, the Stations.
- The rope hose was laid by every machine on its own and the Host checked distances along its own rope (host slack 1 m):
  two machines could disagree on where the hose reaches.
- The Backpack's view called into the Sock vacuum's view for its suction (`nearest_in_cone`), so one view needed the
  other.
- Two dead sounds (`vacuum_mode_click`, `vacuum_spit_out`) and the pairing machine's feed path stayed in the code
  after tools/25 and the switch-off.
- The detector's screen reading was drawn with plain meshes laid over the model (BM), its record loose fields on the Game
  like the Radio's.
- The look numbers (streaks, motes, the motor's fade) were constants in the view, not tuning.

## Open questions for the designer
1. The Sock vacuum, both Backpack vacuums and the detector are all in the house from a New Game (the vacuums behind
   the ground floor's lock). (a) Keep, as the old (Q1041, Q2136); (b) something unlocks them (what?).
2. The Spit's pace is the old 0.1 s a Sock, which "the designer owes" (tools/25). (a) Keep 0.1 s as a placeholder; (b)
   set it now.
3. A full vacuum just stops (the motor runs on, no sound). (a) Keep, as the old; (b) the motor strains; (c) a refusal
   sound.
4. Taking the nozzle plays the Hands' pick rustle. (a) Keep, as the old; (b) its own unclip sound.
5. The motor fades in and out over 0.12 s at one pitch. (a) Keep, as the old; (b) a spin-up and run-down whine; (c) its
   pitch rises as the Tank fills.
6. The poured Sock makes no sound of its own, only its landing (Q2128 "until the sound bench"). (a) Keep, as the old;
   (b) a pour sound.
7. A teammate may take the nozzle off a container someone already carries (both orders work). (a) Keep both, as the
   old; (b) only "carry while a teammate holds it".
8. A nozzle dropped while its container is carried lies where it was dropped and the hose holds the carrier back.
   (a) Keep, as the old; (b) it hangs itself on the carried container's hook.
9. The hose's tug at its length is only the hose shaking on the walker's machine. (a) Keep, as the old; (b) add a
   camera nudge; (c) add a sound.
10. The detector lies on the workbench beside the book (a placeholder spot). (a) Keep, as the old; (b) another spot
    (where?).
11. The detector's beep borrows the ping's pool (a placeholder). (a) Keep, as the old; (b) pick its own sound.
12. The detector does not ride the Elevator and cannot go in the drum, unlike the Radio. (a) Keep, as the old; (b) it
    rides the Elevator like the Radio.
13. A thrown detector that hits a Teammate (Q2483 left its knock to this milestone). (a) A full-charge Throw knocks
    down, a weaker one bounces off to their feet, as the old (Q1935, Q1936); (b) it never knocks down.
14. The models (the Sock vacuum, the Backpack vacuum's capsule tank, the nozzle's display pod, the detector) are not
    ported yet. (a) Port them by the port rules (one asset family with its strip); (b) new models.
15. The pad bindings for the Spit, the Pour and the two wheel directions were placeholders (tools/25). (a) Keep the old
    placeholders; (b) set them now (batch D's controller work may own this).
