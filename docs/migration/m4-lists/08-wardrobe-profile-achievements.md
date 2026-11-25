> Draft behaviour list for batch B's piece the Wardrobe, its pieces, the Profile and Achievements (core/122), written
> from the reference on 2026-11-25; for the designer to approve. The proposal built on it:
> `docs/architecture/wardrobe.md` (its choices are core/122's Open follow-ups W1-W5).

# Batch B piece: the Wardrobe, the Profile and Achievements

Draft behaviour list (catalogue B29 Secrets, B52 Gifts and milestones; digest-progression sections 10 and 15).
Refs are in the old game (`reference/it-socks/`, tag v0.1.1) unless they start with `port:`. Short forms:
WD = `game/player/wardrobe.gd`, WV = `game/player/wardrobe_view.gd`, WM = `game/player/wardrobe_menu.gd`, WI =
`game/player/wardrobe_installer.gd`, WS = `game/player/wardrobe_station.gd`, PR = `game/player/profile.gd`, PI =
`game/player/profile_installer.gd`, AV = `game/player/avatar.gd`, PT = `game/player/piece_touch.gd`, TE =
`game/player/trail_effect.gd`, TR:<name> = `game/player/trails/<name>.gd`, GP = `game/campaign/gift_preview.gd`, MN =
`game/core/main.gd`, RO = `game/net/roster.gd`, SE = `game/net/session.gd`, JN = `game/net/join.gd`, RM =
`game/house/room.gd`, HI = `game/house/house_installer.gd`, RC = `game/player/rig_click.gd`, OP =
`game/house/openable.gd`, T:<name> = `data/tuning/<name>.json`, HL = `assets/house/house_layout.json` "wardrobe", SND =
`data/sounds.json`, ADR9 = `docs/adr/0009-achievements-live-in-the-profile.md`, D = `docs/migration/digests/
digest-progression.md`, DC = `docs/migration/digests/digest-devices-cat-story.md`, LB = `port: docs/migration/m4-lists/
02-lobby.md`. Every number under T: is a placeholder in the old game too.

Marks: "(gifts)" a line whose other side is core/121's (presents, Collections, the encyclopedia), "(economy)" core/120's
(Coins, the Old Tree), "(lobby)" a Lobby line already listed in LB and split out to this piece (Q2584), "(batch C)" /
"(batch D)" a line of a later batch, listed so nothing is lost.

Not ported at all: the Secrets and their eight pieces (Bellhop cap, Boombox hat, Cat-ear headband, Concert tie,
Pocket-watch chain, Purring collar, Rubber duck hat, Whisker mask; Q2600: designed later; WD:21-23, WD:94-99, PI:258-265,
WV:252), wash cycles and the themed piece each first cycle gave (Q2602 dropped them, which voids Q1562). Dropped before
v0.1.1 and not ported: the dimmed grid of pieces (Q681, replaced by Q699), the silhouette of a locked piece (Q713), the
lock and "???" entries for every locked piece (replaced by ticket 36: only unlocked pieces are listed), the co-op
variants (Q964, Q965: designed in old ticket 34, never built: no model, no data), the Socks piece patterning the body
(Q870), the Wardrobe milestones' table (always empty, Q308, then replaced by Achievements, Q1692).

## Behaviour list

### The pieces
- When the game has its pieces, then each is in one of four slots: Hat, Clothes, Socks (a little sock over each of the
  Avatar's stubby feet) and Trail (an effect behind its steps); a player wears at most one per slot and any slot may be
  empty. (ref: WD:11-12, WD:28-31; Q330, Q622, Q662, Q870)
- When pieces are counted, then there are 112: ten basic pieces with no Collection (hats Beanie, Cap, Top hat, Party
  hat, Bobble hat, Crown; clothes Scarf, Apron, Bow tie, Jumper) and six for each of the 17 Collections (two Hats, two
  Clothes, one Socks, one Trail), each with its name and Rarity. (ref: T:wardrobe hats, clothes; T:gifts pieces; WD:38-40;
  Q647, Q1613, Q1614)
- When a Collection's six are ranked, then its first Hat and first Clothes are common, its second Hat and Socks
  uncommon, its second Clothes and Trail rare; the Lost Socks' six are all rare. (ref: T:gifts pieces; D section 10;
  Q1613, Q1614)
- When the pieces are listed, then the 102 Collection pieces are those approved: Simple (Sock hat, Peg band, Laundry
  sack, Odd-sock scarf, Odd pair, Lint puffs), Sport (Sweatband, Bike helmet, Team jersey, Gold medal, Tube stripes,
  Turf prints), Food (Chef hat, Cone hat, Pizza poncho, Donut float, Strawberry socks, Sprinkles), Patterns (Bucket hat,
  Headphones, Hoodie, Backpack, Rainbow stripes, Bubblegum pops), Animals (Bear ears, Frog hood, Tiger tail, Bee wings,
  Paw socks, Paw prints), Superhero (Hero mask, Winged helmet, Hero cape, Power belt, Hero boots, Lightning sparks),
  Winter (Earmuffs, Santa hat, Reindeer jumper, Puffy coat, Fair Isle, Snowflakes), Space (Antenna band, Space helmet,
  Space suit, Jetpack, Moon boots, Stardust), Fruit, Nature, Vegetables, Drinks, Math, Tech, Transport, Machinery and
  the Lost Socks as Q1624-Q1626 picked them. (ref: T:gifts pieces; Q873-Q880, Q1624-Q1627)
- When a piece is shown, then it is its own model in its own fixed colours, never the player's colour; a hat is made
  in the HatPoint's frame, clothes in the Avatar's space skinned to its bones. (ref: WD:3-4, AV:475-496; Q331)
- When a piece is named, then a basic piece reads as its keycap name ("Top hat"), a Collection piece as its name, else
  its id capitalised. (ref: WD:150-154)

### Where a piece comes from
- When a new Profile is made, then every slot is "None" and every piece is locked, the basic ones included. (ref:
  WD:4-6, WD:176-179; Q696)
- When a player opens a Stage present, then a piece they lacked is theirs for good, in their own Profile (gifts). (ref:
  PI:179-187; Q677, Q715)
- When a player's Lifetime tally reaches a milestone, then the piece the milestone names unlocks with the HUD message
  "Wardrobe: <names> unlocked"; the old table of milestones was empty, so no piece ever unlocked this way and the ten
  basic pieces could not be had outside the zoo. (ref: WD:191-201, PI:241-255; T:wardrobe unlocks {}; Q308, Q893)
- When a piece is unlocked, then it stays unlocked in every game: a New Game never locks it again. (ref: WD:9, PR:31-33;
  Q893)
- When a player loads, then a worn piece they no longer have comes off. (ref: WD:182-188, WI:9-10)
- When the zoo shows the Wardrobe, then every piece is unlocked (M/M). (ref: D section 10, ticket 36)

### The Avatar wearing them
- When a hat is worn, then it sits on the HatPoint, bending and crouching with the head. (ref: AV:409-420; port: the
  avatar's `HatPoint` exists, looks_contract.json)
- When clothes are worn, then they are skinned to the Avatar's own bones (the piece's own armature dropped) and follow
  its "Crouch" shape key. (ref: AV:421-435, AV:529-536)
- When a Socks piece is worn, then its two leg Socks (the model's `sock_l`, `sock_r`) go under the Avatar's feet, so
  they waddle with each foot, stay planted when the body crouches and lie with the ragdoll; with none the feet are bare.
  (ref: AV:443-472; Q870, Q887)
- When a Socks piece is worn, then its trim (cuff band and toe cap) keeps its own colours and motif size. (ref: Q889)
- When a hat is worn, then the name tag rises over it (0.25 m over the hat's top), so a tall hat never hides the name.
  (ref: AV:36, AV:436-439; Q2462)
- When clothes or a hat have "SwishL" and "SwishR" shape keys (Tiger tail, Hero cape, Bee wings, Jetpack's flames,
  Antenna band's springs: the only pieces whose build scripts make them), then they swish side to side: walking, with each step, 0.9 rad behind the body's sway, at full swing (1.0) at a
  full waddle; standing, slowly (0.3 of it at 1.8 rad/s). (ref: AV:790-822; T:avatar swish, swish_idle,
  swish_idle_speed; `tools/blender/wardrobe_pieces/` animals.py, superhero.py, space.py; Q951, Q953)
- When Bee wings are worn, then they swing 4 times a waddle (a small fast buzz). (ref: AV:794-795, AV:818-822;
  T:avatar swish_rate; Q951)
- When the Santa hat is worn, then it stays still, its tip flopped to the creature's left (modelled so; no swish keys).
  (ref: `tools/blender/wardrobe_pieces/winter.py`; Q951, Q958)
- When a rare piece is worn (or previewed, or revealed), then its small animated touch plays wherever its model shows:
  - a wave: its "Touch" shape key goes 0, 1, 0 every period (Fruit-basket backpack 1.6 s, Ivy wrap 1.2 s, Onion layers
    2.4 s, Bubble-tea backpack 1.4 s, Balloon backpack 2.0 s, Tool belt 1.8 s, Softener cape 2.6 s);
  - a glow: every surface whose material name ends in "_glow" pulses its emission between low and high (Calculator
    chestplate 0.3-1.8 over 1.6 s, Porthole helmet 0.1-0.9 over 2.2 s, Glowing odd socks 0.4-2.0 over 2.0 s); with
    `cycle` the surfaces take turns, one lit at a time (Robot chest panel 0.15-2.2 over 1.2 s);
  - drops: small balls from a point (Detergent-cap crown: bubbles rising at 0.3, 2 a second, 1.2 s, white; Hose scarf:
    drips falling at 6, 1.5 a second, 0.6 s, blue), casting no shadow.
  Commons are simple and still. (ref: PT:1-157; T:wardrobe touches; Q1618)
- When a piece's touch is shown, then nothing of it goes over the network but the look. (ref: PT:13-14)
- When Bee wings, the Tiger tail, the Hero cape, Antenna band springs and Jetpack's flicker play, then they keep their
  approved motion (Q951, Q953); Onion layers' hood tip sways, Calculator chestplate's digits glow and Tool belt's tools
  swing as built (old ticket 94 open: kept as built). (ref: Q951, Q953; D Open [94])

### Trails
- When a creature walks with a Trail on and its waddle is over 0.3, then each time its rocking turns over the foot
  coming down leaves a mark of its Trail on the floor where it stands (0.006 m up), facing its heading. (ref:
  AV:775-780, AV:864-879)
- When marks are left, then they stay where they were left (not following the creature), each lasting the Trail's
  life, and at most its `max` marks are kept per creature (the oldest go first). (ref: TE:57-84; T:wardrobe trail life
  4.0, size 0.12, max 24)
- When the Trail is drawn, then every machine draws every creature's own from its own waddle; nothing goes over the
  network but the look. (ref: TE:8-11)
- When a creature's Trail changes, then its marks already laid go at once. (ref: AV:402-403, AV:881-885)
- When each Trail is drawn, then it is its own effect, different in shape and motion, from the meshes of its model
  (Q872), with its own numbers (T:wardrobe trails):
  - Lint puffs (Simple): 3 grey fluff puffs a step pop up small, float up 0.28 m and 0.12 m aside on a lazy sway,
    turning, swelling to 1.6 times their size 2.0, fading over the second half of a 4.0 s life; 36 kept; a puff starts
    up to 0.12 s late. (ref: TR:lint_puffs:1-52; Q916)
  - Turf prints (Sport): a soil footprint with 4 grass tufts in the foot's shape; the tufts shoot up one after another
    with a springy overshoot over 0.25 s, sway, sink back from 0.6 of the 2.4 s life; the soil fades. (ref:
    TR:turf_prints)
  - Sprinkles (Food): 7 candy rods tossed up (1.3 m/s) and out (0.7 m/s), tumbling, one bounce (0.35), landing flat at
    random angles; from 0.8 of 3.0 s each swells and pops away, one after another. (ref: TR:sprinkles)
  - Bubblegum pops (Patterns): a pink bubble blown up behind the foot with a rubbery wobble, swelling to 1.35 times,
    bursting at 0.45 of 2.4 s into a flat gum splat and 5 shreds flying out at 0.8 m/s. (ref: TR:bubblegum_pops; Q876)
  - Paw prints (Animals): a pad drops from 0.12 m with a squashy wobble, then four toe beans land 0.05 s apart, turned
    with the creature and a little askew; fades from 0.65 of 3.2 s. (ref: TR:paw_prints)
  - Lightning sparks (Superhero): 3 zigzag bolts crack out of the floor leaning outward with a glint at the foot,
    jumping out (0.6 m/s, slowing), blinking 24 times a second and flipping their zigzag; fade from 0.45 of 1.1 s. (ref:
    TR:lightning_sparks)
  - Snowflakes (Winter): 4 flakes (branched and plain star in turn) drift down from up to 0.35 m, fluttering, tumbling,
    landing flat over 0.7 s; from 0.55 each shrinks into a wet spot that fades from 0.85 of 4.0 s. (ref: TR:snowflakes)
  - Stardust (Space): 6 specks (gold sparkle, white star, pink glitter in turn) float up to 0.3 m within 0.5 s, hang
    drifting round the foot, twinkling (3 a second), fading from 0.6 of 2.6 s; size 1.8. (ref: TR:stardust; Q952)
  - Juice drops (Fruit): a splash crown slumps into a puddle, 4 droplets arc out and land, a tiny orange or lime slice
    flips up (1.3 m/s), spins and lands beside it; gravity 6.0, fade from 0.6 of 2.4 s. (ref: TR:juice_drops; Q1626)
  - Falling leaves (Nature): orange, yellow and red leaves let go from overhead sway down like pendulums, rocking,
    landing flat, fading. (ref: TR:falling_leaves)
  - Sprouting footprints (Vegetables): stems spring up in the foot's shape, their two seed leaves uncurl open, then wilt.
    (ref: TR:sprouting_footprints; Q1626)
  - Fizz bubbles (Drinks): streams of tiny clear bubbles rise wobbling, swelling, and pop at their life's end. (ref:
    TR:fizz_bubbles)
  - Floating digits (Math): numerals (white 1, orange 2, purple 3, coral 7) pop up, float up on an easing curve with a
    sway, turning and rocking, fading. (ref: TR:floating_digits)
  - Falling pixels (Tech): green, cyan and yellow cubes drop one after another onto a 2 x 2 grid square to the heading,
    land with a squash and stack, then blink out. (ref: TR:falling_pixels)
  - Tyre tracks (Transport): a tread strip unrolls from heel forward; dust puffs kick up at its front, drift back,
    rising and swelling; the print fades. (ref: TR:tyre_tracks)
  - Oil drips (Machinery): a drop falls and spreads into a glossy black puddle, wobbling; three sheen arcs (purple,
    green, gold) fade in and swirl each its own way; it all fades. (ref: TR:oil_drips; Q1626)
  - Tumbling socks (Lost Socks): tiny pink, blue, yellow and green socks tumble round a little drum behind the foot,
    carried back, spinning, shrinking and fading over the second half. (ref: TR:tumbling_socks)
  The last nine's numbers are the old placeholders (life 3.0, max 30, size 1.6 and their own keys). (ref: T:wardrobe
  trails)
- When a mark is drawn, then it casts no shadow. (ref: TE:128-133)

### The player's own body and the mirrors
- When the player looks down in first person, then they see their Socks piece on their feet and their Trail on the
  floor behind them; their own body never wears the hat or clothes. (ref: AV:393-407; Q888; port: Q2466)
- When a mirror shows the player, then it shows their whole creature in their whole look; the mirror's copy leaves no
  Trail. (ref: WI:15-20, MN:537-543; Q350; D section 10 ticket 08; port: the player's MirrorBody, assets/07, Q2505)

### Teammates
- When a player changes their look, then every Teammate sees it on their creature at once. (ref: WM:1-5, MN:537-543,
  RO:169-198)
- When a Guest joins, then it brings its look and the pieces it owns, and the Host shows its creature in that look; a
  player who joins later is told everyone's look. (ref: SE:334, SE:458-459, JN:37-39, RO:182-191)
- When a Guest says it wears a look, then the old Host took it without checking the Guest owns the pieces (only that
  each is a piece of that slot's row). (ref: RO:169-191, WD:157-164)

### The Wardrobe in the house
- When the house is laid, then the Wardrobe Station (the oak wardrobe, its own model) stands against the parents'
  bedroom's west wall (1.0 x 1.92 x 0.56 m), the floor in front of it kept free of Socks like a Cabinet's. (ref:
  RM:425-441, WS:1-6; HL pos, size, zone; Q309)
- When a player aims at it, then its doors are outlined and the prompt reads "Wardrobe"; using it (E) opens the
  Wardrobe. (ref: RM:430, WS:96-98, RC:146-148)
- When anyone is in the Wardrobe, then its two doors swing open (each 80 degrees about its hinge, in 0.7 s: twice the
  Openable's 0.35 s, easing in and out); when the last one leaves they swing shut (easing out); teammates see the doors
  move. (ref: WS:2-5, WS:21-23, WS:35-36, WS:101-117, HI:188-191; HL doors; Q337)
- When the doors open or shut, then `wardrobe_open` (cc0/forster_hinge) or `wardrobe_close`
  (cc0/rubberduck_wood_slam4) sounds where it stands, 1 m up, for everyone near. (ref: WS:26-32; SND:202-215; Q337)
- When the Wardrobe opens, then the player is frozen and the mouse is free, as at the Upgrade station; the world keeps
  running; `menu_open` plays; Esc, E or Close shuts it, `menu_close` plays and the player moves again. (ref: WM:1-5,
  WI:28-35, WM:193-194)

### The Wardrobe page
- When the page opens, then a cream panel 900 px wide shows the heading "Colour & Wardrobe" (with a colour row) or
  "Wardrobe", the preview beside a row per slot, and the "Close" Esc keycap at the bottom right. (ref: WM:12-41,
  WV:63-85)
- When the preview shows, then the player's creature in their colour and look stands on a 300 x 380 px stage (clear
  background, warm ambient light (1.0, 0.95, 0.88) at 0.55, key light 1.3 from up right, AgX tone mapping, 4x MSAA),
  seen by a 36 degree camera 4.1 m away at 1.25 m looking at 1.02 m. (ref: WV:22, WV:102-144)
- When the preview shows, then it turns all the way round on its own, one turn every 8 s, the head with the body, with
  no drag or keys; its pupils glance at the viewer while it roughly faces them (within 1.05 rad) and wander otherwise.
  (ref: WV:23-28, WV:355-371; Q1138, Q1140, Q1141)
- When a Trail is worn, then a sample of it steps beside the preview on its own: six steps 0.26 m apart, 0.3 m to the
  side, a new one every 0.35 s, coming up from behind, left and right in turn, already laid when it opens; it stays
  beside the creature as it turns. (ref: AV:886-902, TE:15-21, TE:86-109, WV:369-371)
- When a slot's row shows, then it reads its heading ("Hats", "Clothes", "Socks", "Trail", 120 px wide) with "N/M
  unlocked" under it, then "<", the name box (white, ink ring 4 px, radius 10, 230 px) and ">"; rows 26 px apart.
  (ref: WD:30-31, WV:147-204, WV:88-99, WV:258)
- When a row is stepped (a click on "<" or ">", or A / D on a focused arrow), then it moves through "None" and the
  unlocked pieces only, wrapping, and the piece is worn at once, on the preview and for everyone. (ref: WV:207-219,
  WV:243-283, WV:310-321; Q698; ticket 36)
- When a row counts, then M is every piece of that slot and N the ones this player has unlocked. (ref: WV:245-258)
- When the player has no piece of a slot, then that row reads only "None". (ref: WV:243-258)
- When the page has a colour row (always in the old game: the house and the Lobby both passed one), then a swatch per
  Player colour (52 px, in cells 64 px wide) stands above the slots; the picked one is ringed in ink and raised, a
  taken one greyed (75% toward grey, faded to 0.45), not clickable, with the name of who has it under it. (ref:
  WV:374-444, WI:26-27, MN:546-560; Q342, Q343, Q276, Q314)
- When a free swatch is picked, then the preview takes the colour at once; Solo it is the player's, in co-op the Host
  gives it unless someone else has it (then the asker keeps theirs); the colour is kept in the Profile. (ref:
  WV:446-456, MN:563-585, RO:201-217; Q343)
- When the pad is in use, then the arrows and swatches are its focus stops, the name boxes never. (ref: WV:72, WV:85,
  WM:188; Q2647, Q2654)

### The Lobby (lobby)
- When the Lobby shows a player's place, then their Avatar stands in their colour and look with a sample of their Trail
  under its feet. (ref: LB "The places")
- When this machine's own place is shown, then a Wardrobe key (84 px orange keycap, hanger icon, tooltip "Wardrobe")
  floats beside its head at 82% of the figure's width; pressing it opens the Wardrobe page over the Lobby and clears this
  player's Ready; closing shows the new look to the others. (ref: LB "The stats card and the Wardrobe key"; Q1759,
  Q1764, Q1773)
- When a place is focused, then the stats card shows beside the figure: the name (28 px) and five Lifetime tallies (22
  px): Pairs, Coins, Collections, Floors, Games, thousands apart; a Guest's are what it told the Host when it came in,
  clamped to counts 0 to 999,999,999. (ref: LB "The stats card and the Wardrobe key"; Q1757, Q1769)
- When the Solo page shows, then it has no Wardrobe key before the Lobby: players dress only in the Lobby (and the
  house). (ref: LB; Q1661, Q1749)

### The Profile and its Lifetime tallies
- When the player's Profile is kept, then it is its own small file apart from the World, so the look and unlocks
  travel with the player into any game, as Host or Guest. (ref: PR:1-6)
- When the Profile is saved, then it holds a version, the id, name, colour, last address, the four worn slots, the
  unlocked pieces, the Lifetime tallies, the encyclopedia and the unlocked Collections (gifts). (ref: PR:88-95)
- When a Profile of an older version loads, then its unlocked list is cleared once. (ref: PR:17-19, PR:75-79; Q714)
- When a Profile cannot be read, then a new one is made, not an error. (ref: PR:55)
- When the game runs, then the Profile keeps five Lifetime tallies: Pairs shelved, Coins earned (landed in the
  counter, bonuses and refunds included), Collections completed, floors completed (each floor's Stage, the last one
  included) and games finished. (ref: WD:32-36, PI:161-173; Q893; D Open [32])
- When anything counts in a game, then it counts for every player there: each machine counts the events it sees into
  its own player's Profile, Host or Guest. (ref: PI:161-173, WD:6-8; Q311, Q896)
- When a World is loaded or a Guest receives the join snapshot, then nothing is counted again; nothing counts while a
  New Game is laid. (ref: PI:150-154, PI:161-163, PI:232-235)
- When a tally changes, then the old Profile was written to disk at once, once per Pair shelved. (ref: PI:232-238)

### Achievements (designed, never built: D section 15, ADR9)
- When the Achievements are designed, then the word is Achievement: a named badge a player earns in their own Profile
  when a condition is met, not a Secret. (ref: Q1697)
- When an Achievement is earned, then it may give a Wardrobe piece; Achievements replace the Wardrobe milestones. (ref:
  Q1690, Q1692)
- When an Achievement counts, then it is team credit for Stage, Collection, Final wash and big Pair counts, own credit
  for skill, Hand-off and prank ones. (ref: Q1691)
- When an Achievement is hidden, then it shows as "???" until earned; which are hidden is decided with the content.
  (ref: Q1693)
- When the player looks for them, then a page opens from an entry on the title screen beside the Sock encyclopedia and
  from the pause menu. (ref: Q1694)
- When an Achievement is earned, then a small card slides in at the top right with its icon, title and a soft chime,
  for about 4 s; a Steam build shows only Steam's own pop-up. (ref: Q1695)
- When the game is built, then Achievements count in every build, with a debug grant and reset for testing. (ref:
  Q1696)
- When an Achievement has no art, then it shows its text and a shared placeholder icon. (ref: Q1698)
- When Achievements are stored, then they live in the Profile (id and when earned); the Steam store is a mirror behind
  one seam (Local always on, Steam later, Fake in tests); each machine decides only for its own player, with no new
  Command; earned once, never taken away; on a Steam start the two are joined both ways. (ref: ADR9; Q1684)
- When Steam work starts, then only on the designer's word (on hold; batch D). (ref: Q1957, Q2616)
- When the list is written, then the old draft of 46 is a draft only, for the designer to cut and rename; the old
  game built the system for none of them. (ref: D section 15; Q1688, Q1699)

### Secrets (not ported, Q2600; listed so the seam is known)
- When a Secret is found, then its piece goes into the finder's Profile for good and a special gift reveal plays; a
  Secret's piece is never counted in "N/M" and never shown locked. (ref: PI:258-265, WD:21-23, WV:252; Q1016, Q1019)
- When the Secrets are designed again, then of the old eight only Rubber Duck Load needs nothing of batch C (the fixed
  washer and a present in its drum); the Cat's four and Cat Cradle need the Cat (batch C), Elevator Duet the Elevator
  (batch C), Piano Four Hands a playable piano (no batch yet). (ref: DC Part E; Q1045-Q1048)

### The piece's preview (for the gift reveal and the Final screen; gifts)
- When a piece is previewed, then a Hat or Clothes shows as its model alone, a Socks piece as the leg Socks on bare
  feet in the opener's colour, a Trail as its live sample; it is fitted to the stage by its largest side. (ref:
  GP:6-9, GP:171-207)

### Saves and co-op
- When the World is saved, then nothing of the Wardrobe is in it; the look, the pieces and the tallies are the
  Profile's. (ref: PR:1-6)
- When a Guest joins, then the Host draws presents from the pieces it said it owns (gifts). (ref: JN:37-39, WI:11-12)

### Words
- The old wording: "Wardrobe", "Colour & Wardrobe", "Hats", "Clothes", "Socks", "Trail", "None", "%d/%d unlocked",
  "Close", "Wardrobe: %s unlocked", "Taken", the basic pieces' names, the stats card's "Pairs", "Coins", "Collections",
  "Floors", "Games". (ref: WM:156, WD:31, WD:38-40, WV:230, WV:258, PI:254, WV:441; LB)

## What was weak in the old piece
- The ten basic pieces could never be had: every piece starts locked (Q696), the milestones' table stayed empty (Q308)
  and gifts draw only Collection pieces. Achievements were to replace the milestones (Q1692) but no list was made.
- A piece's data was spread over two tuning files (`wardrobe.json` rows and touches, `gifts.json` pieces) and found by
  its id in three folders (the glb, the Trail script, the touches); a designer added a piece by editing JSON in three
  places.
- The rare pieces' touches were code reading JSON (PieceTouch), not animation in the piece's own scene.
- The Wardrobe page, its rows, the lock icon and the preview stage were built in code (WV, WM); nothing to open in the
  editor (Q2658).
- The Station was built in code from a layout entry with code-made door boards as a stand-in (WS:52-93).
- The Host took a Guest's look and owned pieces unchecked (RO:182-191, JN:37-39).
- The Profile was written to disk on every Pair shelved (PI:232-238).
- "Who is in the Wardrobe" was a set of string toggles in the shared Game (`wardrobe:<id>`), not a part of the station.
- The Lost Socks' six pieces were counted in "N/M" but, without the Grotto (Q2599), cannot be had.
