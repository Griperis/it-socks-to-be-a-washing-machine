> Draft behaviour list for batch A's first piece, Stages and floors (core/71), written from the reference on
> 2026-11-24; for the designer to approve. The proposal built on it: `docs/architecture/stages.md` (its choices are
> core/71's Open follow-ups S1-S7).

# Batch A piece: Stages and floors

Draft behaviour list (catalogue B20 Stages and floors, B27 the Whiteboard and the Tab tallies, the HUD's Stage bar,
P106 their leftovers; how a run's progress sits in a World). Refs are in the old game (`reference/it-socks/`, tag
v0.1.1) unless they start with `port:`. Short forms: ST = `game/campaign/stages.gd`, CA = `game/campaign/campaign.gd`,
CI = `game/campaign/campaign_installer.gd`, CB = `game/campaign/cabinets.gd`, CC = `game/campaign/cabinet.gd`
(the old Cabinet view), CP = `game/campaign/cabinet_plan.gd`, LV = `game/campaign/locks_view.gd`, LD =
`game/campaign/locked_door.gd`, PL = `game/campaign/padlock.gd`, LH = `game/campaign/lock_hint.gd`, PV =
`game/campaign/part_view.gd`, WV = `game/campaign/whiteboard_view.gd`, WS = `game/campaign/whiteboard_sheet.gd`, HUD =
`game/ui/hud.gd`, RIG = `game/player/rig.gd`, RM = `game/house/room.gd`, SL = `game/world/sock_layout.gd`, SB =
`game/audio/sound_bank.gd`, T:<name> = `data/tuning/<name>.json`, HL = `assets/house/house_layout.json`, MH =
`tools/blender/make_house.py`, D = `docs/migration/digests/digest-progression.md`. Every number under T: is a
placeholder in the old game too.

Marks: "(washer)" a line whose show is the washing machine's (core/73), named here because a Stage seam fires it;
"(run-ends)" a line of the First wash, the Laundry day or the Final screen (core/72); "(batch B)", "(batch C)",
"(batch D)" a line of a later batch (Q2614), listed so nothing is lost. Not ported at all (Q2599): the Lost Sock
Grotto's Stage and its softener on the shrine (ST:133-135, CA:446-458), Hampers, the pairing machine. Dropped before v0.1.1 and not ported: the together-hold on the padlock and the one-click
padlock (Q1008: floors open by fixing the washing machine), the Dirty Socks and their counter (switched off). The Drum
finale's fifth Stage is batch D (Q2615): batch A's run has four Stages and ends after the fourth.

## Behaviour list

### The run's Stages
- When a run is played, then it is one Stage per floor in unlock order: basement, ground, first, attic (the fifth,
  the Drum's, batch D). (ref: T:stages floors; ST:1-15; Q620, Q625; Q2615)
- When a New Game starts, then the run is at Stage 1 (the basement's), only the basement is open and only Stage 1's
  Cabinets are unlocked, each at its starting Rows. (ref: ST:113-127; CA:186-195; Q620)
- When a New Game starts, then each Cabinet spot draws its Collection at random from its room's pool, never the same
  Collection twice (laundry Simple; garage Machinery, Transport, Sport, Tech; kitchen Fruit, Vegetables, Drinks, Food;
  living room Patterns; kids' room two of Animals, Nature, Superhero, Space, Math; attic two of Winter, Space, Nature,
  Tech), only from the Collections unlocked in the Profile; kept in the save. Choice S2 (the unlocking across games
  is batch B). (ref: CP:23-47; `game/campaign/cabinet_pools.gd`; `data/cabinet_pools.json`; Q1437-Q1441, Q1467)
- When a Cabinet stands on an open floor but unlocks with a later Stage, then it stands locked under its dust sheet
  (today only the garage's: unlocked with Stage 2, the basement's completion; Q1467 "hidden_until"). (ref: CP:50-62;
  `data/cabinet_pools.json` modes.normal.hidden_until; LV:200-217; Q644, Q1463, Q1467)
- When a Stage is current, then its bar counts every Row of every unlocked Cabinet that is not full when the Stage
  begins, so Rows added to older Cabinets must be filled too and players go back to older floors. (ref: ST:130-141;
  Q633, Q648)
- When the last Stage (the Grotto's or the Drum's) begins, then its bar counts only its own Cabinets (a patch for the
  Grotto, whose Mess held only Lost Socks: ticket progression/82). The port's last Stage in batch A is the attic, a
  normal floor: choice S7. (ref: ST:133-135; Q1816, Q1821)
- When every Row of the bar is full, from Pairs found anywhere in the house, then the Stage is complete. (ref:
  ST:144-149; CA:88-90; Q624)
- When the Rows are counted, then they are the same for any number of players: more players finish faster. (ref:
  ST:15; Q631)
- When the campaign is off (the zoo, the old shot tool), then every Cabinet is unlocked with all its Drawers and no
  Stage counts. (ref: ST:22-24)

### Rows and Drawers
- When a Cabinet unlocks, then it has `start_rows` Rows (2), never more than it can fill. (ref: ST:196-203;
  T:stages start_rows; Q617)
- When a floor opens (after the Fix), then every unlocked Cabinet gains `rows_per_stage` Rows (1) until it is full;
  its full height is its Collection's in-play Designs over the Pairs per Drawer, rounded up (Simple's 130: 6 Rows;
  Sport's 70: 3; Patterns' 100: 4; Winter's 55: 3; the 50-Design Collections: 2). (ref: ST:176-193; CB:89-93,
  CB:196-200; Q641)
- When a Row is the Collection's last, then it takes only the Designs left (Simple's sixth Row takes 5, Sport's third
  20, Winter's third 5); a Row is full when it holds them. (ref: CB:203-216; ticket progression/02 follow-up)
- When a Cabinet stands in the house, then it shows only its current Rows' Drawers, bottom up; a locked Cabinet shows
  the Rows it will unlock with (2); a full Cabinet is the whole stack. (ref: CC:1-9; LV:106-111; Q693-Q695)
- When a floor opens, then each Cabinet whose Rows grew drops its new Drawers in on top: after `drop_delay` 0.8 s, each
  Drawer module (its segment and drawer, the top riding on it) falls `drop_height` 0.8 m in `drop_time` 0.35 s
  (quad, ease in), `drop_gap` 0.25 s apart on one Cabinet, every Cabinet at once. (ref: CC:123-153; LV:143-149;
  T:locks drop_*; ticket progression/23)
- When a dropped Drawer lands, then a thunk plays at its top seam (`drawer_thunk`, sharing the oven-close clip) and a
  brief puff of beige dust (`#cbbfa8`, 24 particles, 0.7 s, sideways from the seam, rising slightly, fading) bursts
  from the seam. (ref: CC:200-230; SB:72)
- When a Drawer is added while nobody sees its Cabinet, then (decided, Q824, never built: ticket progression/31
  stayed ready-for-agent, priority later Q1580) it waits hidden until the first player has that Cabinet in the same
  room and in view; the Host decides; then it drops for everyone. Choice S4. (ref: D 4; Q824)
- When a Drawer is above its Cabinet's Rows or the Cabinet is locked, then it is shut to everyone and takes no Pair;
  a Pair aimed at a locked Drawer goes into the nearest unlocked Row with room. (ref: port:
  `game/entities/cabinet/cabinet.gd` lock_patch, next_drawer; ticket progression/24)
- When a Cabinet is full or locked, then shelving is refused ("Cabinet full", "Cabinet locked", after "Wrong
  Cabinet", Q2285) and the Pairs stay in the Hands; a Throw at it bounces. (ref: port: cabinet.gd SAYS,
  shelve_refusal; D 1 ticket 02)
- When Debug builds show the New Game page, then a "Pairs per Drawer" slider (1 to 25, default 25) sets this World's
  Drawer size; it scales every Stage's Pairs by size/25; it is saved and in the join snapshot; a release build never
  shows it and always uses 25. (ref: CB:79-87; CA:253-256; Q668; Q2586: it waits for this piece)

### A Stage's Socks
- When a New Game starts, then the Mess holds only Stage 1's Socks (the basement's Simple Pairs); locked floors are
  empty until their door opens. (ref: CA:197-251; Q619, Q637; with the First wash the Socks come with its spit:
  (run-ends) Q1847)
- When a Stage's Socks are chosen, then for every unlocked Cabinet enough of its in-play Designs not yet spawned or
  shelved to fill all its unlocked Rows; then, until the Stage's `pairs` is reached, more Designs of the unlocked
  Cabinets (their later Rows'), one Cabinet at a time in catalogue order; a locked Cabinet's Designs never spawn; each
  Design spawns once in a run; the rest spread evenly through each Collection (a golden-ratio walk), commons and
  rares alike; every machine picks the same. (ref: CA:197-270)
- When the Stage's least Pairs are counted, then they are `pairs` [50, 160, 150, 130] (the Drum's 50 in batch D),
  scaled by the Pairs per Drawer over 25; above that a Stage always spawns what its Rows need (Stage 2 needs 175).
  Paced at about 10, 15, 20 and 25 minutes a Stage alone. (ref: T:stages pairs; CA:253-256; Q660, Q669; balance
  round Q967)
- When a floor opens, then the new Stage's Socks are laid from the game's seed and the Stage's index, onto the house
  as it lies and the Socks already lying there (no washer fan), and land for everyone. (ref: CI:43-52, CI:59-70;
  `game/core/game.gd`:817-818; SL:300-330)
- When the new Socks are laid, then the old code spreads them over every open floor (`mess.spill.level_shares`, 25 %
  each); the designer's words at ticket progression/92 are "the next Stage's Socks still appear on the floor that just
  opened" (Q1938). Choice S1. (ref: CI:43-52; SL:1234-1265; `data/tuning/mess.json` spill.level_shares; Q1938)
- When 2 or more players are in the game at the spawn, then 5 % of the Stage's Socks lie on high spots (a furniture
  top at least 1.7 m over its floor); alone the same Socks go to reachable spots, so the count never changes. (ref:
  CI:55-57; T:stages high_spot, high_share; Q657, Q664)
- When the game quits while a Stage's Socks are still being laid, then the Host lays the ones still due again after
  the load (any caught falling are taken out first; a Design already held, lying as a floor Pair or shelved is no
  longer due). (ref: CA:272-291)

### A Stage completes: the Part
- When the bar fills, then the Stage completes on every machine: its Part is earned and pops out of the top of the
  Cabinet where the last Pair was shelved (the bar's last Row's Cabinet when there is none), arcing to the floor
  `ahead` 1.5 m in front of it (clear of gift boxes lying there): a hop up, an arc peaking `pop_height` 0.6 m over the
  top, a small bounce, in `pop_time` 0.7 s; `part_pop` plays at the Cabinet's top; a burst of 18 pale blue sparks
  where it lands. (ref: CA:294-308, CA:439-479; PV:54-77, PV:108-114, PV:117-127; T:parts; Q999-Q1001)
- When the Parts are listed, then one per floor in floor order: the New filter (basement), the New motor (ground), the
  Drum belt (first), the Detergent (attic); the Softener is the Drum's (batch D). (ref: T:parts list; Q1000, Q1003)
- When a Part lies, then it turns slowly (1 rad/s), bobs 3.5 cm (2.2 Hz), and shows a soft pale-blue glow disc on the
  floor under it and a slow rising sparkle; carried, glow and sparkle are off. (ref: PV:10-14, PV:90-105,
  PV:128-176)
- When a Part is aimed at or carried, then the hover readout names it ("New filter"); it has no floating label. (ref:
  PV:4; Q1020, designer 2026-11-06)
- When a player clicks a lying Part with empty Hands, then they carry it in front of them (one player, one Part);
  with anything in their Hands it is refused "Hands full". (ref: CA:711-731; Q1002)
- When the carrier right-clicks, then the Part goes down where the crosshair is if it may (else "Can't drop there"),
  landing on what is under it; aimed at a teammate it goes into their Hands if they are empty, else down at their feet
  and they read "Hands full". (ref: CA:734-753, CA:779-796; Q1020)
- When the carrier clicks the washing machine, then the Part goes in (a Fix): refused "The washing machine is busy"
  while it washes or plays a cutscene; `part_fit` plays; everyone watches the machine's Fix scene at its new, calmer
  mood, then everyone respawns by it (washer). (ref: CA:799-841; SB:103; Q1002, Q1007)
- When the Fix scene ends (or at once where there is none: the zoo, a test), then the next floor opens. (ref:
  CA:356-370; CA:850-861)
- When the game is loaded between a Fix and its floor's opening, then the floor opens at once after the load. (ref:
  CA:348-353, CA:431-436)
- When a Stage completes, then the Parts earned, the Parts fitted and the machine's mood follow: angriest at a New Game,
  one step calmer per Part (washer). (ref: CA:393-407; Q1007)
- When the last Stage's Part is fitted, then the machine is fixed and the Laundry day may begin (run-ends); the run no
  longer ends at a Stage. (ref: CA:324-341; Q1006, Q2615)
- When every Stage but the one before the Drum completes, then the Fix scene ends with the spit (washer; in batch A
  every Stage spits, Q1937). (ref: CA:844-848; Q1937-Q1940)
- When a Stage completes, then each player gets one present per Collection completed in it, under the Old Tree (batch
  B, Q2612). (ref: CA:136-166; Q1944, Q1948)
- When a floor opens, then every player is paid `floor_complete` 100 Coins in full; a Cabinet whose current Rows all
  fill pays `cabinet_batch` 50 Coins to whoever filled it (no gift, Q1590). Choice S3. (ref: CA:93-110, CA:314-317,
  CA:614-618; T:payout; Q646, Q1248)
- When a Stage completes, then each player's Lifetime "Floors" tally counts one (batch B, Profile). (ref:
  `game/player/profile_installer.gd`:21)

### The floor opens: locks and reveals
- When a floor is locked, then its way up is shut: a plank door (ledges and a Z brace) at the top of the ground's and
  the first floor's flights, a painted baby gate at the foot of the attic's flight with an unseen blocker over it to the
  ceiling; a steel chain runs across the side players come from, closed with a brass padlock. (ref: LD:1-9,
  LD:59-75; HL locked_doors; MH:225-241, MH:1139-1310; Q638, Q678)
- When a locked door is shut, then its leaf stops the player, thrown items and the crosshair like a wall. (ref: LD:3-4)
- When the crosshair is on a locked door's padlock, then the padlock is outlined and the hint reads "Please the
  washing machine" with no key (nothing to press). (ref: LH:1-13, LH:86-102; LV:47-52; Q1008)
- When a floor opens, then its padlock springs up and out with a spin (up 0.12 m, out 0.22 m in 30 % of `pop_time`
  0.6 s, a 0.6 x 0.3 turn), falls to the floor; the chain drops (from 15 % of the time) and swings 0.4 rad; both shrink
  away after 1.4 x the time; `padlock_pop` at the pop (sharing device_click), `chain_drop` at 75 % (sharing
  oven_close). (ref: PL:55-82; LV:58-62; SB:68-69; T:locks pop_time)
- When the padlock has popped, then after `swing_delay` 0.8 s the leaf swings open over `swing_time` 1.4 s (sine, in
  and out), back over the flight to rest along the newel wall (the gate out onto the first floor); `lock_door_open`
  plays 1 m up (sharing wardrobe_open); a floor never locks again. (ref: LD:89-105, LD:118-123; SB:70; T:locks)
- When the leaf swings, then a player in its way is nudged out and the Socks in its way are woken and pushed, as by a
  room Door. (ref: LD:6-8; Q852)
- When a floor opens, then its lamps fade in over `lights_fade` 0.6 s, stay lit by day for `lights_hold` 6 s, then fade
  back over 1.2 s to the day's rule; a locked floor's lamps stay off. (ref: RM:171-180, RM:319-351, RM:852-878; LV:98,
  LV:122; T:locks)
- When a Cabinet under its dust sheet unlocks, then the sheet is pulled off where it stands (slides forward, spills,
  fades in `sheet_time` 0.5 s) and `cabinet_reveal` plays 1 m over the Cabinet after the pull, at least
  `reveal_delay` 0.5 s; the Cabinet becomes usable. (ref: LV:138-142, LV:159-176; T:locks; port:
  `game/devices/dust_sheet.gd`, assets/07, Q2507)
- When a Cabinet stands under its dust sheet, then it cannot be aimed at: no outline, no prompt, no click, no Pair in
  by hand or Throw. (ref: port: cabinet.gd sheeted, aimable; Q2513)
- When a load, a join or a New Game shows the house, then every lock, sheet, lamp and Cabinet height stands as the run
  has it at once, with no animation and no sound. (ref: LV:79-103)
- When the Elevator is in the house, then it is locked until the ground floor opens, then works for every open floor;
  a locked stop wears a padlock sign and reads "Elevator locked" (batch C, with the Elevator). (ref: CA:54-64;
  LV:69-71, LV:124-137, LV:220-229; Q643, Q680)

### The Stage bar (HUD)
- When the campaign is on, then the Stage bar sits at the top centre, 12 px down: a cream keycap panel
  (`StagePanel`: cream, cream shade, radius 6, 14 px padding, 3 px edge, 10 px shade), with the Collection icons of
  the Cabinets its Rows belong to stacked on its left (44 px, overlapping 26 px apart, in catalogue order), then a
  label over a track. (ref: HUD:79-97, HUD:258-296; `game/ui/ui_bits.gd`:49, :103; Q684)
- When the bar shows, then the label reads "Stage n: <Floor>  p/c" (22 px, ink, no outline: "Stage 2: Ground
  83/175"; the floor is its id capitalised, so "Stage 3: First": choice S6), p the Pairs shelved in the bar's Rows, c the Pairs they take; the track is 300 x 16 px, dark (0.9 alpha,
  radius 8, 2 px edge), its fill the accent colour. (ref: HUD:386-406; CA:67-85)
- When a Pair is shelved into one of the bar's Rows, then the fill moves to the new share in 0.35 s. (ref:
  HUD:428-441)
- When a new Stage begins, then the fill drains in 0.6 s (cubic) and refills to the new share in 0.35 s; the new
  icons pop in one after another (from nothing, 0.4 s, back-out ease, 0.12 s apart after the drain). (ref:
  HUD:399-425, HUD:437-440; Q633)
- When the Stage is complete and its Part not yet fitted, then the bar stays as it was, full; nothing else on screen points to the washer. Choice S5. (ref: ST:152-160)
- When the machine is fixed, then the bar gives way to the Laundry day's counter "Laundry bins loaded: n/m"
  (run-ends; the Dirty Socks counter and its fold are off, Q1619-Q1620 switched off). (ref: RIG:636-647;
  HUD:298-352)
- When nothing changed, then the bar is not built again. (ref: HUD:46-48, HUD:389-391)

### The Whiteboard and the Tab tallies
- When the house is played, then the Whiteboard stands in the laundry by the Old Tree's old place: a marker board on a
  wheeled easel (port: `game/furniture/collection_board.tscn`, already placed). (ref: WV:1-8; Q639, Q667, Q1508)
- When the board shows, then its face is a 4:3 picture (1024 x 768) drawn as if in marker, lit a little by itself
  (`glow` 0.2) so the basement's dim lamp still lets it read: the heading "This Run" (54 px) underlined in red, three
  column heads as icons (pairs, sock, coins: Pairs shelved, Socks picked, Coins earned), one row per player in their
  colour (darkened 20 %), the numbers centred in ink (56 px, shrinking to fit), a Team row of the totals last after a
  stronger divider, faint wiped marker ghosts on the board. (ref: WS:1-89, WS:121-142; T:whiteboard)
- When the board's lettering is drawn, then it is Patrick Hand, thick strokes (an outline in the same colour). (ref:
  WV:13-15; WS:121-125; port: Q2331 "Patrick Hand waits for the whiteboard")
- When a tally changes, then the board's picture is drawn again (only then). (ref: WV:107-120)
- When Tab (or the pad's Select) is held, then the same sheet shows over the play view at 80 % of the screen's height
  in a grey frame; let go, it goes; it never opens over a menu and closes when one opens. (ref: WV:73-87,
  WV:122-178; `project.godot` whiteboard_overlay; T:whiteboard overlay_height)
- When the tallies are counted, then they are this run's, per player: Pairs shelved (by hand or Throw), Socks picked
  (Mess picks only, not a Pair picked up), Coins earned (bonuses included); counted on every machine from the Host's
  answers, kept in the save; a player who left keeps their row. (ref: `game/core/player_state.gd`:40-51;
  `game/hands/hands_rules.gd`:136-142; `game/campaign/coin_bank.gd`:18-27; CB:302; WV:88-105; Q1077, Q1180-Q1183)
- When the Collections' progress is wanted, then it is on the Cabinets only, not on the board or Tab. (ref: WS:4-5;
  Q1078)

### Saves and co-op
- When a run is saved, then its Stage, whether a floor waits for its Fix, every Cabinet's Rows, the bar, which Designs
  were spawned and which are still due, the Parts earned and fitted, where each Part lies (a carried one laid where it
  lay) and the Pairs per Drawer are in the World's file and the join snapshot. (ref: ST:206-245; CI:43-52)
- When a World is listed (the Lobby's row and card), then its details name the floor it is on. (ref:
  `game/net/lobby.gd`:162-207; port: `game/save/world_record.gd` floor_name, "until Stages exist")
- When anything of a Stage changes, then the Host decides and every machine shows the same; a Guest who joins sees it
  as it stands. (ref: ST:3-4; LV:10-12)

### Words
- When the Stage's wording is shown, then it is the old placeholder wording: "Stage %d: %s  %d/%d", "Please the washing
  machine", "Hands full", "Can't drop there", "The washing machine is busy", "Cabinet locked", "Cabinet full", "This
  Run", "Team", the Part names "New filter", "New motor", "Drum belt", "Detergent". (ref: HUD:397; LH:9; CA:731,
  CA:819; `game/core/game.gd`:243; WS:63, WS:81; T:parts)

## What was weak in the old Stages
- One state in five counters: `stage`, `door_due`, `earned`, `fixes`, `fixed`, with `fit_pending()` and `stage_open()`
  derived from them (ST:30-45, CA:343-353); every new case (the Grotto, the drum, a load mid-Fix) added a branch.
- The last Stage's bar counted only its own Cabinets: a patch for the Grotto's Lost Socks (ST:133-135), wrong for any
  normal last floor.
- Which Cabinets wear a sheet was guessed from where they stand (`level_index` of the position, LV:200-217); the locked
  doors, padlocks and hints were built in code from a layout JSON (LD:36-76, LH:27-44) and tweened by hand (PL:57-82).
- A new Drawer drops wherever nobody looks (Q824 decided, never built).
- The new Socks' floors: the code spreads them over every open floor, the designer's later words say the floor just
  opened (Q1938); never reconciled.
- Nothing on screen says what to do with an earned Part: the bar just stays full until the Fix (ST:152-154); only the
  padlock's hint and the washer's lines say it.
- "Stage 3: First" reads oddly (the floor's id capitalised, HUD:397); the label is ink with no outline (ticket 20
  follow-up, never answered).
- Stage 2 is the heaviest (175 Pairs: three new Cabinets and a grown Row); the Pairs and pace were never balanced
  (Q669, Q967).
- The Whiteboard was built as a Collection legend, then turned into the tallies board (progression/43); its Tab
  overlay is a plain grey frame; the board's spot was never confirmed (ticket 01 follow-up).
- The Pairs per Drawer slider lived only on the old New Game pages and reached the Stages through a global
  (`drawer_pairs`), with the Stage Pairs scaled from it (CA:253-256).
