> Draft behaviour list for batch C's Cat and litterbox (core/148), written from the reference on 2026-11-26; for the
> designer to approve. No proposal is built on it yet: the design ticket follows the designer's look (index:
> `batch-c.md`).

# Batch C piece: the Cat and the litterbox

Draft behaviour list (catalogue B40 The Cat, B16 Litterbox; the Cat's naps in the Elevator's car are listed here and
named in list 11). Refs are in the old game (`reference/it-socks/`, tag v0.1.1) unless they start with `port:`. Short
forms: CAT = `game/cat/cat.gd`, CV = `game/cat/cat_view.gd`, CL = `game/cat/cat_litter.gd`, CF = `game/cat/cat_fetch.gd`,
CW = `game/cat/cat_watch.gd`, CN = `game/cat/cat_nav.gd`, CG = `game/cat/cat_gait.gd`, CI = `game/cat/cat_installer.gd`,
RC = `game/player/rig_cat.gd`, FR = `game/world/flight_rules.gd`, WA = `game/knockdown/washes.gd`, ER =
`game/house/elevator_rules.gd`, RD = `game/house/rides.gd`, SB = `game/audio/sound_bank.gd`, SEC =
`game/campaign/secrets.gd`, T:<name> = `data/tuning/<name>.json` (every number there is a placeholder in the old game
too, unless a Q set it), DC = `docs/migration/digests/digest-devices-cat-story.md` Part B.

Marks: "(11)" a line of list 11 (the Elevator), "(13)" of list 13 (the Radio); "(co-op)" a line that needs co-op
(who sees what, the Host's answer); "(sound)" a sound, "(rumble)" a pad rumble (the Cat has none of its own: a Throw
of it buzzes "throw", a knock "knock"); "(Secrets, later, Q2682)" a Secret, or a part of the Secrets subsystem, that
hangs on the piece. Not ported: the Cat in the Lost Sock Grotto (CW:1-8, Q2599); the litterbox's fixed three starting
Socks: its Socks are laid by the Sock generator (Q2600). The Cat has no Upgrades. The old Cat's model is
`assets/cat/cat.glb` (`tools/blender/make_cat.py`, its clips `tools/blender/cat_anims.py`): not in the port yet. The
litterbox is ported (port: `game/furniture/litterbox.tscn` with its `Flap` Openable, `Inside` and `litter_flap`
sounds, placed in the bathroom in `game/house/house.tscn`; assets/07).

## Behaviour list

### What it is
- When the house is played, then a black cat lives in it: a side character with no gameplay role beyond petting,
  fetching Socks and a Secret hook; stylised and cartoon (a round chubby body, a big head, short legs, a tail wrapped
  round its paws when it sits, paws tucked in when curled), glossy black with a soft rim, clear shaped eyes with a
  catchlight, content or curious, never sad. (ref: CAT:1-6; CV:1-17; DC B1; Q1009-Q1011; designer 2026-11-05,
  2026-11-06)
- When a New Game starts, then the Cat sits on the ground floor's couch and stays there until the ground floor opens;
  then it roams. (ref: CAT:229-240; DC B1; cat/02, designer 2026-11-06)
- When the Cat acts, then the Host decides everything (where it walks, how long it rests, when it meows, when it
  wriggles free, where it lands); every machine walks the path the Host's event gave at the same pace, so Guests see
  it the same; its record is in the join snapshot and the save (a held or flying cat saved standing where it is).
  (ref: CAT:48-52, CAT:1955-2030; CG:1-3) (co-op)

### Roaming and resting
- When it roams, then it walks the unlocked floors (rooms and the stairs between them), never through a shut or locked
  Door, never onto a locked floor, never into the Elevator's shaft by walking; it walks 1.5 to 7 m a walk, at 0.55 m/s,
  then stands (1 to 4 s), sits (4 to 10 s, chance 0.25) or naps (20 to 45 s, chance 0.3). (ref: CAT:1-3, CAT:48-56,
  CAT:771-826; T:cat speed, stand_*, sit_*, nap_*, walk_*; Q1080)
- When it naps, then it lies curled up with its eyes shut, breathing, in a nap spot: the middle of the sofa's and the
  beds' tops (the sofa, the double bed, the bunk bed, the old cot), the floor just inside each low window (a sunny
  patch: a fixed spot, not tied to the hour), or the Elevator's car standing open (below). (ref: CAT:78, CAT:1633-1672;
  CV:1-3; DC B1)
- When it walks, then its way inside each room comes from a navigation mesh baked at run time from the house (round
  furniture, Heaps higher than 0.12 m, open Door leaves, along the stair ramps; walking under furniture it fits under),
  planned by the Host only; the walk is a smooth curve (corners rounded within 0.35 m), easing up from a standstill
  (1.2 m/s2, a run 4.0), slowing before it stops (1.5), turning on the spot before it sets off and slowing through
  bends (150 degrees a second); a Door shut across a walk makes the Host plan it again. (ref: CN:1-14; CG:1-20;
  CAT:48-60, CAT:1293-1300; T:cat accel, run_accel, decel, turn_rate, corner, heap_over; Q1901, Q1902) (co-op)
- When it walks among players, then it walks through them, with no avoidance; small Socks are walked over. (ref:
  CAT:58; Q1902)
- When it is awake, then its head turns toward the nearest player's head or moving Sock within 2.5 m and 100 degrees
  either side of its nose (200 degrees a second, at most 70 from its body, the neck taking 0.4 of it); not while it
  naps, is held, flies or is in the drum. (ref: CAT:291-338; CV:14-17, CV:32-35; T:cat head_*; Q1903)
- When it is awake and not napping, then it meows now and then (every 12 to 30 s), "cat_meow" at it. (ref: CAT:1-3;
  T:cat meow_min, meow_max; SB:57) (sound)
- When it walks, stands, sits, naps, is held, flies, swats or is dizzy, then the model plays that clip (stand, sit, curl,
  fall, held, walk, run, swat, dizzy; real Blender clips, the walk and run at its real speed, one stride 0.32 m),
  cross-fading 0.4 s; standing, its tail swishes. (ref: CV:1-31; Q1168, Q1173; designer 2026-11-07)

### Petting
- When a player aims at the Cat (a ball of 0.22 m round its middle) and presses E, then it stops, purrs ("cat_purr")
  for 2.5 s and little pink hearts float up from it and fade; everyone sees and hears it. (ref: CAT:254-262,
  CAT:279-290, CAT:455-481; CV:38, CV:447-470; RC:50-55; T:cat purr_seconds, reach; SB:58; Q1009, Q1010) (sound)
  (co-op)
- When it is petted, then with chance 0.6 (then 45 s of cooldown) it goes fetching (below); it never fetches unasked.
  (ref: CAT:18-23, CAT:1065-1179; T:cat fetch_chance, fetch_cooldown; Q1830, Q1946, Q1947) (co-op)
- When it is in the litterbox, shut in the Elevator's car, in the air or in the drum, then it cannot be petted. (ref:
  CAT:254-262)

### Picking up, holding, throwing
- When a player left-clicks the Cat with empty Hands, then it comes into their Hands (the whole Hands), meows, and the
  pick sound plays; with anything in the Hands they read "Hands full"; it cannot be picked up from someone else, in
  the air, in the litterbox or shut in the car. (ref: CAT:263-278, CAT:483-495; RC:41-48; Q1010, Q930) (sound)
  (co-op)
- When it is held, then it is drawn tipped up under its front legs (55 degrees, nose up), wriggling, at its holder's
  hands for everyone; after `hold_seconds` 3 s it wriggles free and jumps down 0.5 m in front of the holder, then runs
  2 m off. (ref: CAT:1-6; CV:2-3, CV:36-37, CV:62-63; T:cat hold_seconds, free_ahead, run_from; Q1010) (co-op)
- When the holder right-clicks, then it is set down. (ref: CAT:1-6, CAT:2041-2044)
- When the holder throws it, then it hisses ("cat_hiss": a real short spitty hiss, Dan Knoflicek's Cat 8, CC-BY), flies
  paws out, and always lands on its four paws ("cat_land"), then runs off (1.6 m/s, 2 m). (ref: CAT:5-6, CAT:497-520,
  CAT:827-859, CAT:1837-1862; SB:59-60; T:cat run_speed; Q1010, Q1126, Q1133) (sound) (co-op)
- When a thrown Cat hits a Teammate, then a full-charge Throw knocks them down and bounces off; a weaker one bounces off
  and drops at their feet, never caught; a rider of the Elevator, someone down or in the drum is not hit. M0.6 left
  the Cat's knock to this milestone (Q2483). (ref: FR:55-59, FR:186-193, FR:298-304; knockdown/04, Q1935, Q1936; port:
  Q2483, Q2484) (co-op) (rumble: the knock's buzz)

### Swatting Socks
- When it walks past a loose Sock or Pair lying within its paw's reach (0.55 m, no higher than 0.45 m over its feet)
  on its own floor, then now and then (every 60 to 120 s) it stops and bats it: the swat lasts 1 s and at the paw's
  contact (0.45 of it) the item moves 0.5 to 1 m for everyone, landing like a drop (a Sock knocked off a low piece of
  furniture falls), with a soft "cat_swat"; never from a Cabinet, a Drawer, inside furniture or the Hands. (ref:
  CAT:13-17, CAT:913-1064; T:cat swat_*, knock_*; SB:61; Q1080-Q1082) (sound) (co-op)

### Fetching (cat/07)
- When it goes fetching, then it walks to the two loose Socks of one Design nearest to it (both lying still on an
  unlocked floor, outside furniture, with a way to both), stops 0.4 s, takes them (they leave the World, a "pop"),
  carries them as a sock ball in its mouth to the player who petted it and sets the Pair down at their feet with a
  meow: an ordinary floor Pair, counted as a player's. (ref: CAT:18-23, CAT:1065-1179; CF:1-80; CV:95-101; T:cat
  fetch_*; Q1830-Q1833) (sound) (co-op)
- When the petter is out of reach (a shut Door, another floor), then it sets the Pair down at the closest spot it can
  walk to and meows; a petter who walks more than 1.2 m off meanwhile is followed; a petter who leaves the game gets it
  set down where the Cat stands. (ref: CF:74-80; T:cat fetch_redirect, fetch_drop_reach; DC B3)

### The litterbox (B16, cat/11, cat/14)
- When the house is built, then a covered litterbox stands in the bathroom, on the floor left of the toilet against the
  back wall: a tray, a hood with a carry handle (in the tray's dark sage), a flap door with a paw print hinged at its
  top that swings in 85 degrees up under the roof; players reach its Socks through the flap only (the hood does not
  lift). (ref: CL:1-20; DC B5; Q1942, Q1951, Q1980, Q1981, Q1985, Q1986, Q1990, Q1993; port:
  `game/furniture/litterbox.tscn`, placed)
- When a New Game lays its Socks, then a few Socks lie inside it, laid by the Sock generator like any hiding place.
  (ref: DC B5 (the old: about 3, 1 to 5 by seed, Q1949); port: Q2600, the generator's `Inside` spots,
  `docs/architecture/sock-generator.md`)
- When a player opens or shuts the flap, then the "litter_flap" sounds play (the cupboard pool, 6 dB under). (ref:
  `game/house/openable.gd`:34; T:audio litter_flap_gain_db; Q2012; port: `game/audio/sound_catalogue.tres`
  `litter_flap_open`, built in assets/07) (sound)
- When about `litter_every` 240 s (give or take 45) have passed, then the Cat visits it: walks to the floor in front of
  the flap, noses the flap open if it is shut (pushing it open again if it was shut on it from outside), steps in over
  the sill, scratches for 6 s (the swat clip and its sound), and walks out again; a visit that cannot start tries
  again in 15 s. (ref: CAT:24-31, CAT:1180-1292; CL:1-38; T:cat litter_*; Q1950, Q2008) (sound) (co-op)
- When a visit ends, then the Host shuts the flap behind the Cat, whoever opened it. (ref: CAT:1180-1292; Q2009)
- When a visit starts, then on about 1 in 3 visits (0.33) it first takes the nearest loose Sock within 5 m in its mouth
  (across its jaws, showing its real Design), a "pop", carries it there and drops it on the litter inside. (ref:
  CAT:28-31; CL:39-77; CV:102-104; T:cat litter_hide_chance, litter_sock_reach, litter_take_reach; Q1943, Q1950, Q2011,
  Q2059) (sound) (co-op)
- When the Cat is inside the box, then it cannot be petted, picked up or swat. (ref: CAT:31, CAT:254-278)

### Naps in the Elevator's car (cat/13, cat/14) (11)
- When the car stands open where it was called and nobody rides, then it is one more nap spot, at the same weight as
  the others, hopped into from the floor in front of its hatch (the "fall" pose, landing with "cat_land"). (ref:
  CAT:35-46, CAT:1711-1836; Q1982, Q2007) (sound)
- When the Cat sleeps in the car, then it rides wherever the car is called and wakes on that floor; a call where it
  lies, a pet or a pick-up wakes it; nobody climbs in while it is in the car ("Elevator full"). (ref: CAT:1739-1779;
  ER:88-89, ER:107, ER:166-167; RD:70-71, RD:164; Q1983, Q1984, Q2003) (co-op)
- When the car stands shut at its stop with the Cat in it (not riding), then it naps on 20 s, then opens the hatch
  itself (the Host's call) and walks out; while the car rides or its hatch is shut it is out of reach. (ref: CAT:40-43,
  CAT:1697-1702; T:cat car_shut_seconds; Q2004)
- When the Cat is dropped or thrown into the open car, then it lands inside and stays (it may nap or ride). (ref:
  CAT:43-46, CAT:1780-1795; Q2005)

### The watchdog (cat/10)
- When the Cat stands somewhere it never should (outside every room, on a locked floor, in the Elevator's shaft but not
  its car, under a floor, inside furniture, in the air, on floor its roams cannot reach, on a top with no way down) or
  has not moved for `park_seconds` 90 s (not held, not on the couch before the ground floor opens), then the Host puts
  it back on the nearest floor spot it can walk from, for everyone. (ref: CW:1-22; CAT:813-817; T:cat park_seconds;
  Q1928, Q1932, Q2006) (co-op)

### The drum and the coats (secrets/02, cat/05)
- When the Cat is dropped by the washer's door, aimed at the washer, then it goes into the drum for a gentle cycle (4 s,
  the drum turning at 0.45), comes out dizzy (staggering on the spot 2.5 s, its head circling, its eyes half shut), and
  runs off in its next coat: black, grey, ginger, white, calico, then black (calico white with ginger and black
  patches; dark whiskers on the light coats); the coat lasts until its next wash and is saved; a New Game's Cat is
  black. (Secrets, later, Q2682: the drum load is the Secrets subsystem's, secrets/02) (ref: CAT:8-11, CAT:860-912;
  CV:4-9, CV:39-57, CV:105-109; WA:21-25; T:cat dizzy_seconds; T:wash cat_seconds, cat_spin; Q1106, Q1125,
  Q1127-Q1129, Q1142-Q1144)

### Secrets that hang on it (Secrets, later, Q2682)
- Cat on the Piano: a thrown Cat lands on the piano's keys; a tail flick and a faint note; the Cat-ear Headband. (ref:
  SEC:26, SEC:294; Q1045)
- Radio Dance: the Cat sits about 2 m from the playing Radio for 10 s; its head bobs; the Boombox Hat (13). (ref:
  SEC:27, SEC:199-205; Q1045)
- Clock Stare: the Cat stays by the wall clock 15 s; its tail flicks once a clock tick; the Pocket-watch Chain. (ref:
  SEC:28, SEC:205, SEC:233-238; Q1045, Q1071)
- Fur Fetch: the Cat thrown into the empty laundry basket lands on its paws; the basket twitches; the Whisker Mask.
  (ref: SEC:29, SEC:296; Q1045)
- Cat Cradle (co-op): one holds the Cat while the other pets it (a held Cat may be petted only with the Secrets on);
  a purr ripple; the Purring Collar. (ref: SEC:32, SEC:300; CAT:254-262; Q1047)

### Words
- When the Cat's wording is shown, then it is the old: "Hands full", the Cat's hint names (E pet, left click pick up).
  (ref: CAT:455-460; RC:41-55)

## What was weak in the old Cat
- One 2057-line class held the roam, the pet, the hold, the throw, the swat, the fetch, the litter visit, the car nap,
  the drum and the save; the others reached into it (`game.cat.wake_in_car()`, `fills_car()`).
- Its routes were planned from the layout's data in code (rooms, doorways, ramps), the navigation mesh baked per room
  at run time (a bake could hitch 5 to 70 ms).
- The held Cat was drawn in the world, not in the held view; a pet stopped a walk at once.
- The scratch reused the swat clip and sound; the flap had no sound pick of its own.
- The long soak case failed at seed 8 (off the stairs after a pet, 1638 s), cause unknown (DC B4, cat/16).
- The Grotto special cases stayed in the watchdog.

## Open questions for the designer
1. The Cat starts each New Game sitting on the ground floor's couch until the ground floor opens. (a) Keep, as the old
   (cat/02); (b) it roams from the start.
2. A petted Cat fetches two loose Socks of one Design and brings them as a ready Pair that counts like a player's
   (chance 0.6, 45 s cooldown). (a) Keep, as the old (Q1830-Q1833, Q1946); (b) drop the fetch; (c) change the numbers.
3. Which two Socks the Cat fetches. (a) The nearest pair of one Design, as the old (a placeholder rule, Q1831); (b)
   another rule (which?).
4. The litterbox visit: every 240 s give or take 45, a 6 s scratch, a hidden Sock on 1 in 3 visits. (a) Keep the old
   numbers as placeholders; (b) set them now.
5. The Cat's drum cycle and coat change come with the washer's drum loads, which are part of the Secrets subsystem.
   (a) Wait for the Secrets, as Q2682 says of the Secrets; (b) port the Cat's drum cycle and coats now, without the
   Secrets.
6. The scratch in the litterbox reuses the swat clip and sound. (a) Keep, as the old (Q2008); (b) its own clip and
   sound.
7. A thrown Cat that hits a Teammate (Q2483 left its knock to this milestone). (a) A full-charge Throw knocks down, a
   weaker one bounces off to their feet, as the old (Q1935, Q1936); (b) it never knocks down.
8. The held Cat is drawn in the world at the holder's hands, not in the first-person held view. (a) Keep, as the old;
   (b) in the held view.
9. The Cat's model and clips (`assets/cat/cat.glb`) are not ported yet. (a) Port them by the port rules (an asset piece
   with its strip); (b) a new model.
10. The coat colours and calico patches are placeholders ("in warm basement light grey reads brownish"). (a) Keep the
    old colours; (b) set them now.
