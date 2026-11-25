> Draft behaviour list for batch B's first piece, Coins and Drawers, the Old Tree and the Upgrade grid (core/120),
> written from the reference on 2026-11-25; for the designer to approve. The proposal built on it:
> `docs/architecture/economy.md` (its choices are core/120's Open follow-ups E1-E6).

# Batch B piece: Coins and Drawers, the Old Tree and the Upgrade grid

Draft behaviour list (catalogue B36 Upgrades and the Upgrade menu, the Coins and Drawers of B20/B27's payouts, the
Old Tree of digest section 12; how a World keeps them). Refs are in the old game (`reference/it-socks/`, tag v0.1.1)
unless they start with `port:`. Short forms: UP = `game/campaign/upgrades.gd`, UM = `game/campaign/upgrade_menu.gd`,
US = `game/campaign/upgrade_station.gd`, CB = `game/campaign/coin_bank.gd`, CBS = `game/campaign/cabinets.gd`, CA =
`game/campaign/campaign.gd`, CF = `game/ui/coin_flight.gd`, HUD = `game/ui/hud.gd`, RIG = `game/player/rig.gd`, PR =
`game/ui/prompts.gd`, TN = `game/ui/teammate_news_installer.gd`, J = `game/net/join.gd`, SV = `game/core/saves.gd`, PS =
`game/core/player_state.gd`, SM = `game/campaign/sole_mates_view.gd`, OTV = `game/audio/old_tree_voice.gd`, TVD =
`game/audio/tree_voice_director.gd`, OTM = `game/campaign/old_tree_motion.gd`, SB = `game/audio/sound_bank.gd`,
UJ:<line> = `data/upgrades.json` at that line, T:<name> = `data/tuning/<name>.json`, VO = `data/voiceover/old_tree/`,
D = `docs/migration/digests/digest-progression.md`. Every number under T: and every price in UJ is a placeholder in
the old game too.

Marks: "(121)" a line of core/121 (Stage presents, Gifts, Collections unlocking), "(122)" of core/122 (Wardrobe,
Profile, Achievements), named here because this piece's seam carries it; "(batch C)", "(batch D)" a line of a later
batch (Q2614), listed so nothing is lost. Not ported at all (Q2599): the Hampers and their two Upgrades (UJ:433,
UJ:458), the pairing machine and its four (UJ:597-668), the splitter and its four (UJ:687-753), the Lost Sock Grotto
(its Drawer payout 4, its Cabinet hint, its floor line). Switched off before v0.1.1 and not ported: the Dirty Socks
(the Old Tree's `tip_dirty`). Dropped earlier and not proposed again (D "Decided against"): the branching tree with
lines (Q1226), the Whiteboard or the washer as the Upgrade station (Q1012, Q1013, Q1241), a Collection-complete Coins
bonus (Q1590, Q1602), Coins for binning (Q1068), a jump Upgrade (Q657), Throw as a purchase, Deep Hands, Hands I-III,
Double Glow (v2 list), any face on the Old Tree (Q1542).

Numbers check: the catalogue's B36 says 33 Upgrades; v0.1.1's `data/upgrades.json` has 37 (the splitter's four were
added by old ticket tools/28). Ported: 27 (16 Personal, 11 House).

## Behaviour list

### Two currencies
- When the game counts money, then there are two currencies: each player's own Coins, and the team's Drawers; names,
  icons and payouts are tunable (Q2610). (ref: D 7; Q1220, Q1225, Q2610)
- When a player shelves a Pair, then the Coins go to that player (the shelver), `base` 10 times its rarity's factor
  (common 1, uncommon 2, rare 5), paid once per Cabinet drawer the shelving used. (ref: CBS:280-301; T:payout base,
  rarity_multiplier; Q1221; port: `game/entities/cabinet/cabinet.gd` `_shelve`, `cabinet_tuning.gd` pay_for: built in M0.5)
- When a Cabinet drawer fills to the Pairs per Drawer, then the team earns Drawers: the payout of the floor its Cabinet
  stands on (basement 1, ground 1, first 2, attic 3; the Grotto's 4 not ported), once per drawer. (ref: CBS:168-176,
  CBS:290-292; T:drawers payout_by_floor; Q1224, Q1405)
- When a Collection's last Row holds fewer Pairs than a drawer (Simple's sixth, Sport's third), then filling it pays no
  Drawers. (ref: CBS:290 `size() == per`; D Numbers; Q1405)
- When the Pairs go in by the zoo's or a test's fill, then the drawer pays its Drawers too; a practice game pays none.
  (ref: CBS:134-144, CBS:290)
- When a floor opens (at the end of its Fix), then every player in the game is paid `floor_complete` 100 Coins in full,
  each into their own Coins; the last Fix pays the same. Choice E1 (batch A paid none, Q2619). (ref: CA:310-327;
  CB:30-35; T:payout floor_complete; Q646, Q1248)
- When a Cabinet's current Rows all fill, then whoever filled the last one is paid `cabinet_batch` 50 Coins, once per
  Rows count (a Cabinet that grows can pay again). Choice E1. (ref: CA:93-110, CA:621-623; T:payout cabinet_batch;
  Q634, Q646)
- When a Gift's piece is one the opener already owns, then the opener gets `refund` 75 Coins (121). (ref:
  CA:647-652; T:gifts refund; Q646, Q1248)
- When a player joins a game for the first time, then they start with the average of the Coins of the players already
  in it, rounded down, decided by the Host and sent in the join snapshot; a returning player keeps their saved Coins;
  a new player's Personal levels start empty. (ref: CB:38-47; J:42-45; Q1249)
- When the Host's debug F9 is pressed in a debug build, then 1000 Coins go straight into the Host's own Coins, with no
  flight, and the Host reads "Debug: +1000 {coins}"; a Guest's F9 does nothing. (ref: `game/core/main.gd`:1144-1147;
  `game/house/house_rules.gd`:74, :181-183; T:debug cheat_coins; Q292)
- When Coins or Drawers change, then the Host decides (every payout, every purchase); a Guest never mints. (ref: D 7;
  Q1225; UP:9-10)
- When Coins are earned but their flight has not landed, then they cannot be spent yet: the spendable Coins are the
  landed ones (`coins - coins_in_flight`); a load lands them at once. (ref: CB:66-70; `game/core/game.gd`:1232-1234)

### Coins and Drawers on the HUD
- When the game is played, then the top left shows two counters, each an icon and a number (30 px), 28 px apart, at
  24 px from the left and 16 px down: the player's own Coins (the coin icon) and the team's Drawers (the blue chest
  with the star); no names, no outlines, no pill behind them. (ref: HUD:132-138; Q1246, Q1247, Q1253, Q1254)
- When the Coins counter shows, then it shows the landed Coins only; the Drawers counter holds back the Drawers still
  flying. (ref: HUD:216-217, HUD:240-245)
- When a player's own shelving pays Coins, then on their screen a "+N" with the coin icon (56 px text, the icon 1.2x)
  pops over the open drawer that took the last Pair (0.2 m above it, at its front; the screen's centre when behind the
  camera): it grows in over 0.12 s with a little overshoot, holds 0.5 s, then bursts into N coin icons (34 px) that
  spread out over 0.2 s within 70 px and fly to the Coins counter over 0.45 s on a curve that rounds into it from
  below, shrinking to 0.75; the stream is staggered so the whole payout ends in 1.5 s whatever N. (ref: CF:1-6,
  CF:55-82, CF:125-201; RIG:650-680; T:coins)
- When a teammate's shelving pays them Coins, then nothing shows on this player's screen. (ref: RIG:653-656; Q281)
- When a player's own shelving fills a Cabinet drawer, then a "+N" with the Drawer icon pops 80 px above the Coins'
  "+N" in the House blue (`#1e2b55`, the Cabinets' dark blue), bursts into N Drawer icons and flies to the Drawers
  counter with the Coins' timing; the counter ticks up as each lands. A teammate's filled drawer just moves the counter.
  (ref: HUD:200-213; RIG:661-664; CF:222-229; T:coins drawer_tint, drawer_rise; Q1416, Q1430, Q1468)
- When the "+N" pop would leave the screen, then it is kept 16 px inside it. (ref: CF:214-219)
- When coins land in the counter, then the coin icon pulses (to 1.35x, easing back) and "coins" plays for the shelver
  alone (flat, SFX). (ref: HUD:188-192, HUD:220-222; CB:73-93; SB:82; Q281)
- When Drawers land in the counter, then a soft wooden "drawer_clack" plays (sharing the drawer_close pool), for the
  shelver alone. (ref: RIG:261; SB:83; Q1468)
- When a Cabinet drawer fills for this player, then a pad's rumble gives its "done" buzz. (ref:
  `game/audio/sound_installer.gd`:35-37; Q1556)
- When a bonus is paid (the floor's 100, the Cabinet's 50, a Gift refund), then no "+N" pops: the Coins land in the
  counter over the payout's time, `bonus_delay` 0.35 s later, with the landing sound. Choice E2. (ref: CB:19-27,
  CB:50-63; no `paid` emit for bonuses: CA:621-623, CA:647-652)
- When a Collection-complete bonus pops (gold, 1.4x, 90 px higher, gold-tinted coins), then: never in v0.1.1 (the
  bonus was cut, Q1590, Q1602); the look is code that stayed. Not ported. (ref: CF:55-80; T:coins bonus_*)

### The Old Tree, the Upgrade station
- When the house is played, then the Old Tree, the forgotten Christmas tree, stands in the basement garage; it is the
  Upgrade station (Q2611). (ref: US:1-5; D 12; Q1508; port: `game/furniture/old_tree.tscn` in `house.tscn`, placed)
- When the crosshair is on the Old Tree, then the tree's mesh is outlined and the prompt reads "The Old Tree" with the
  E key. (ref: US:9-10, US:51-60; `game/house/station.gd`:37-46; Q1516)
- When the player presses E on it, then the Upgrade menu opens with "menu_open"; closing it plays "menu_close" (the
  sounds the Whiteboard's menu played). (ref: `game/player/rig_click.gd`:184-185; RIG:264-265; SB:75-76; Q1518)
- When there is no tree model (a bare test house), then a plain box stands by the washer instead. (ref: US:41-48)
  Not ported: the port's tree is a scene.
- When a run starts, then every Door on the way from the laundry to the garage starts open (the Lobby-Garage path);
  after the first wash's cutscene the tree calls the players now and then (a `tree_call_<n>` line, 5 drafts, heard from
  the laundry: the first after 20 s, then every 25 to 55 s, louder, carrying 16 m) until a player first comes near; then
  its "first" line plays as usual. (ref: OTV:208-212; `game/house/doors.gd`:74-83; `game/campaign/laundry.gd`:90;
  VO tree_call_1..5; T:old_tree call_*; Q1864, Q1865)

### The Old Tree moves and talks (Q1541-Q1548)
- When the tree stands, then it has no face: its tiers slowly breathe (a 6.5 s period, spreading 4.5 % of their radius,
  lifting 1.2 cm) and its lit bulbs flicker together like a loose contact (depth 0.35, a slow noise with a fast
  stutter); the lamp by them stays steady. Every machine draws it on its own. (ref: OTM:1-6, OTM:34-40; T:old_tree
  breathe_*, flicker_*, glow; Q1542)
- When it talks, then the speech key (the line's loudness, as the washer's door) makes the tiers rustle (1.2 cm at
  speed 21) and the bulbs pulse brighter (2.2x at a fully open key), a light wave running up the string. (ref: OTM:1-6;
  T:old_tree rustle, rustle_speed, pulse; Q1546)
- When it speaks, then the voice is a distinct older synthesised voice (Piper en_US "norman", aged: slower, lower,
  breathy, creaky, a faint wooden resonance); positional at the tree (unit size 2.5 m, max 9 m); heard and subtitled
  only by players within its earshot (4.5 m, and within 1.8 m of its height), with the washer's subtitles. (ref:
  OTV:1-9; T:old_tree earshot, level_band, unit_size, max_distance, voice_db 12.5; Q1543, Q1544, Q1547, Q1548, Q1575)
- When it may speak, then at most one line every `cooldown` 120 s, never during a cutscene or while the washer talks;
  the washer cuts it off (V4: cutscene > washer > Old Tree, Q2548); within a moment every line plays once before any
  repeats, never the same line twice running (Q2637). (ref: TVD:1-14, TVD:79-112; T:old_tree cooldown; Q1544)
- When a player comes near for the first time in the game, then it says a "first" line (3); near again after 45 s away,
  a "greet" line (5). (ref: TVD:4-6, TVD:79-94; VO tree_first, tree_greet; T:old_tree away_seconds; Q1541)
- When an Upgrade becomes affordable for a player, then it says an "affordable" line (5) when they are near, now or on
  their next visit (in place of the greeting). (ref: OTV:3-5; TVD:145-156; VO tree_affordable; Q1541)
- When anyone buys an Upgrade near it, then it says a "bought" line (6). (ref: OTV:5; VO tree_bought; Q1541)
- When a player stays near 40 s with nothing said, then an idle line: a musing (7), or with chance 0.35 a grumble about
  the washer (5, only while it is broken), or with chance 0.35 a hint (below). (ref: TVD:1-14; VO tree_idle,
  tree_grumble; T:old_tree idle_seconds, grumble_chance, hint_chance; Q1541, Q1595)
- When the Stage's bar passes a half, most (0.8) or nearly all (0.95), then it may say a stage_half, stage_most or
  stage_last line (3 each) to a player near. (ref: TVD:26-27, TVD:157-172; VO tree_stage_*; T:old_tree
  stage_thresholds; Q1594)
- When it hints, then it names a room whose Cabinet still has a Row of the bar to fill ("cabinet_<spot>", 4 lines per
  spot: laundry, garage, kitchen, living, kids north, kids east, loft west, loft east), or a vague floor where a loose
  Mate lies (with a loose Sock in the Hands its Mate's floor, else a loose Sock of a Collection the bar still needs;
  "hint_<floor>", 4 per floor); never a spot. (ref: TVD:28-31, TVD:174-212; VO tree_cabinet_*, tree_hint_*; Q1594,
  Q1608; D Open [96])
- When a player first meets a thing, then a first-time tip, once per player per run, repeated in every New Game: the
  Throw (from the start, 1 line), a Part (once the first Stage completes, 2); the vacuum (3) and the Elevator (once
  Elevator Repair is bought, 1) are batch C's; the pairing machine and the Dirty Socks are not ported. (ref:
  TVD:32-39, TVD:214-238; VO tree_tip_*; Q1594, Q1606)
- When a Part is fitted or a floor opens, then it is not said on the spot: with chance 0.75 one comment (a
  "part_<floor>" or "floor_<floor>" line, 4 each) is said some time 120 to 420 s into the next Stage to a player near;
  it lapses after 120 s unheard. The last Part's fitting is the peace line's. (ref: OTV:153-170; TVD:40-42; VO
  tree_part_*, tree_floor_*; T:old_tree beat_*; Q1607)
- When the Final wash is done, then a "final_wash" line (3), and after the last Fix one "peace" line (3) that makes
  peace with the washer; story beats skip the cooldown, waiting only `beat_gap` 20 s. (ref: OTV:172-176; TVD:10-11,
  TVD:43-44; VO tree_final_wash, tree_peace; Q1595)
- When presents wait under the tree, then the tree says it ("presents_ready" 3 once, "presents" 4 again after 240 s
  near, "present_taken" 4) to a player near; no house-wide call, no HUD hint (121's moments, this speaker). (ref:
  TVD:24-25; VO tree_presents*, tree_present_taken; T:old_tree presents_nag_seconds; Q1593, Q1666, Q1667)
- When a New Game starts, then what is once per run (the tips, the first visit, the beats) starts again. (ref:
  OTV:178-187)
- When the tree talks in co-op, then each machine picked its own line for its own player (two players could hear
  different lines; old ticket 95 asked). The port's rule: the Host decides every speaker's line and everyone near hears
  the same (Q2545). (ref: OTV:1-2; D Open [95])
- When cutscene 3 plays (Fix 2), then the washer and the Old Tree both talk; the tree's line joins by its recording and
  trigger, no code (Q2609, Q2633); no recording exists yet. (ref: port: `docs/architecture/voice.md` "Cutscenes")
- When Q2506 (2026-11-23) is read, then the tree's motion, flicker and voice were held back "because it will be
  reworked". Choice E4.

### The Upgrade menu (Q2613: the old grid)
- When the menu opens, then it is one page over the play view: the title "The Old Tree" with the Coins and Drawers
  balances together top right, two sections side by side, Personal (coin icon, cream) first and House (Drawer icon,
  the Cabinets' dark blue) second, and "[ESC] Close" at the bottom right. (ref: UM:1-14, UM:76-118; Q1323, Q1324,
  Q1341, Q1364, Q1430)
- When the menu is open, then the player's input is frozen and the mouse is free; the world keeps running (no pause).
  (ref: UM:14)
- When a section is laid out, then each Upgrade sits at its `cell` [row, col] of its section's grid; empty cells are
  allowed; a row no shown Upgrade stands in is closed up; the menu rebuilds from the data with no code change. (ref:
  UM:120-175; Q1334, Q1335, Q1339)
- When a button shows, then it is the icon only (44 px; the name is in the tooltip), the level "2/4" (18 px) and the
  next level's price small under it with its currency icon (16 px); 92 x 92 px cells, 8 px apart. (ref: UM:22-47,
  UM:237-317; Q1325, Q1329, Q1428)
- When a button is hovered or focused, then it lifts 5 px, grows to 1.08 over 0.1 s and glows softly in its section's
  colour (gold for Personal, `#5f7fe0` for House). (ref: UM:28-31, UM:41, UM:516-540; Q1429)
- When an Upgrade's prerequisites are not met, then its button is greyed with a big lock (38 px) over a dimmed icon;
  what it needs is in the tooltip only ("Needs: Sock Smarts"), never highlighted. (ref: UM:44-45, UM:443-453,
  UM:487-503; Q1326, Q1327, Q1870)
- When an Upgrade's effect is not built, then its button is greyed and reads "Coming soon": seen, not buyable. Choice
  E3 for the batch C ones. (ref: UM:8, UM:483-497; UP:108-116; Q1272, Q1337)
- When an Upgrade is at its top level, then it has a gold frame and "MAX" in place of the price. (ref: UM:9,
  UM:487-490; Q1336)
- When the price is more than the funds, then the price shows in the "short" style. (ref: UM:497; `UiBits.PRICE_SHORT`)
- When a button is hovered or focused, then a keycap card in its section's colours shows beside it (on the side with
  room, inside the screen, 360 px wide): the name (28 px), its description (22 px), the now -> next numbers ("x1.10 ->
  x1.15"), "Level n/m" and the price with its currency icon (or MAX), "Needs: ..." while locked and "Coming soon" while
  unbuilt. (ref: UM:551-631; Q1331, Q1332)
- When a few Upgrades name a key, then their titles say it: "Sprint (hold Shift)", "X-ray: Show pair (key 1)",
  "Cabinet X-ray: Show drawer (key 2)". (ref: UM:18-20)
- When one click lands on an affordable button, then the next level is bought at once and "buy" plays. (ref:
  UM:399-410; UP:426-440; Q1328)
- When a locked, unbuilt, maxed or too dear button is clicked, then it shakes (turns 0.07, -0.07, 0.05, -0.05, 0.025,
  0 radians, 0.045 s each) and the refusal buzzes ("refuse"); nothing is bought. (ref: UM:48-50, UM:399-425; Q1338)
- When the Host refuses a purchase, then the buyer reads why: "Co-op only", "Maxed out", "Coming soon", "Locked" or
  "Need {coins} 120" / "Need {drawers} 2". (ref: UP:409-424)
- When something changes while the menu is open (a teammate buys, Coins land), then it refreshes at once; shut, it
  refreshes when it opens. (ref: UM:455-506)
- When a pad or the keyboard walks the menu, then Left and Right walk a row and cross to the other section's same row,
  Up and Down go to the nearest button of the next row, the last row's Down is Close; it opens on the first button
  when a pad is active. (ref: UM:177-229, UM:370-382; port: Q2647-Q2654, `docs/architecture/ui.md`)
- When the screen is below 1080p, then the whole UI scales uniformly and the menu keeps its layout (fits 720p). (ref:
  D 8; Q1469; port: the project's stretch)
- When the game is single player, then the co-op-only Upgrades (Roomy Car, Sole Mates, Sole Hands, Mate Radar) are
  hidden and cannot be bought; hosting counts as co-op even before anyone joins. (ref: UP:47-58; Q1357, Q1399)
- When a teammate buys an Upgrade, then everyone else reads "<name> bought <Upgrade>" (the title without its
  bracket); the buyer sees it in their menu. (ref: TN:46-52; Q243)

### Buying (the Host decides)
- When a player buys, then a Personal Upgrade is theirs alone, paid with their own Coins; a House Upgrade is the
  team's, paid with the team's Drawers by anyone in any order, and applies to every player, later joiners too. (ref:
  UP:1-10, UP:162-174; Q1216, Q1217, Q1223, Q1240)
- When a purchase is decided, then it is refused when the Upgrade is unknown, hidden (co-op only alone), at its top
  level, not built, not open (a prerequisite below the level it asks), or too dear; else the price leaves the funds and
  the level rises by one. (ref: UP:382-440)
- When several Upgrades add to one effect, then their levels sum (e.g. Big Hands is the carry effect). (ref:
  UP:129-138)
- When a Personal branch is started, then any branch may be started any time; every node is buyable eventually; the
  order makes the specialist. (ref: Q1222, Q1233)
- When the House prices are set, then they total 0.9 of the Drawers a run can earn, rounded, the old proportions kept,
  every price at least 1; a test checks the total within 2. (ref: D Numbers; Q1398, Q1405) In v0.1.1 the rule was
  broken: the splitter's 11 Drawers came later (tools/28).

### The Upgrades (UJ, prices placeholders, Q1365)
Personal, bought with Coins (UJ:4-363):
- Footwork, 4 levels 40/60/90/135: walk 5 % faster a level (x1.00 to x1.20). (ref: UJ:4; T:upgrades speed
  per_level_pct; Q1234)
- Sprint, 1 level 80: unlocks Sprint (hold Shift, pad RT, x1.3); nobody sprints without it; once bought, the corner
  hints show "Sprint [Shift]". (ref: UJ:29; T:upgrades sprint; PR:104-105; Q1343, Q1238; port: Q2233)
- Quick Grab, 4 levels 40/70/120/200: the least time between two pick-ups, 0.35 s down 8 % a level. (ref: UJ:48;
  T:upgrades speed grab_interval_*; Q1234)
- Big Hands, 4 levels 50/100/200/330: carry one more item a level, from 1 to 5. (ref: UJ:73; T:hands start_capacity;
  T:upgrades carry; Q1349, Q1397)
- Long Arm, 3 levels 240/380/600: a full Throw flies 4 m/s faster a level, from 5 m/s; the Throw itself is free and
  weak. (ref: UJ:98; T:upgrades throw; Q1344, Q1396)
- Quick Charge, 2 levels 120/190: a Throw charges 25 % quicker a level, from 1.2 s. (ref: UJ:122; Q1234)
- Sock Smarts, 1 level 30: a held Sock shows its readout; without it the model only, and no "1/3" count. (ref:
  UJ:145; Q1347, Q1419; port: core/15's `PlayerUpgrades.sock_smarts`, a zoo toggle today, Q2360)
- Sock Sense, 1 level 120, needs Sock Smarts: the Sock under the crosshair shows its readout. (ref: UJ:164; Q1021,
  Q1348; port: `PlayerUpgrades.sock_sense`)
- X-ray 150; All-Hands X-ray 250 (needs X-ray); X-ray Recharge 100/160 (-20 % of the 50 s cooldown a level); Lingering
  X-ray 100/160 (+5 s on 10 s a level); Cabinet X-ray 200; All-Hands Cabinet X-ray 300; Cabinet X-ray Recharge 100/160
  (on 30 s); Lingering Cabinet X-ray 100/160 (batch C: the X-rays). (ref: UJ:185-340; T:xray, T:cabinet_xray; Q1239,
  Q1345, Q1420)

House, bought with Drawers (UJ:365-812):
- Elevator Repair 1 (the Elevator works, locked until bought); Fast Elevator 2/2 (needs Repair; 25 % off the 2 s a
  floor a level); Roomy Car 2 (needs Repair; three ride together; co-op only) (batch C: the Elevator). (ref:
  UJ:365-409; Q1350)
- Big Bag 1/1 (+12 vacuum Socks a level); Strong Suction 1/1/1 (0.12 s between Socks, 0.02 s less a level); Long Hose
  1/1 (+2 m); Wide Nozzle 1 (needs Long Hose; +1 m reach, +10 degrees); Filter nozzle 2 (the nozzle's display and Size
  and Collection filter) (batch C: the vacuums). (ref: UJ:484-578; T:upgrades house; Q1356, Q1362, Q1433, Q2090)
- Sole Mates 2 (co-op only): while you and a Teammate hold mates (your active loose Sock, their Sock), their Sock keeps
  the Highlight outline in their Player colour, as wide as a Ping's, in line of sight only (lingering 0.15 s); a soft
  sound ("match", positional at their Hands) once when the match starts, and your own Sock glows briefly; without it no
  cue at all. (ref: UJ:772; SM:1-11, SM:182-184; T:sole_mates; Q1115-Q1118, Q1130, Q1131, Q1361)
- Sole Hands 1 (needs Sole Mates, co-op only): the whole Teammate glows when your active Sock's mate is in any of their
  slots. (ref: UJ:791; SM:105-107; Q1361)
- Mate Radar 1 (needs Sole Mates, co-op only): the Sole cues show through walls, and hint arrows at the screen's edge
  point to each Teammate holding your mate, in their colour. (ref: UJ:812; TN:25-40; Q1236, Q1519)

### Saves and co-op
- When a World is saved, then each player's Coins and Personal levels (keyed by player, so a Guest's wait for them),
  the team's Drawers and House levels, and the Coins earned are in its file and the join snapshot; Coins in flight are
  not saved (a load lands them). (ref: SV:29, SV:124-128, SV:171-180; PS:13-20; Q1225)
- When the Profile counts, then it counts the Coins that land for its player as its Lifetime "coins_earned" (bonuses
  and refunds included), the Wardrobe's milestones read it (122). (ref: `game/player/profile_installer.gd`:24;
  `game/player/wardrobe.gd`:33-35; D Open [32])
- When the Final screen counts Coins, then a player's score is every Coin they earned and the "+N bonus" step is the
  part the Pairs did not pay (floor and Cabinet bonuses, Gift refunds); the World's totals show "Coins earned"; no
  Drawers total. (ref: `game/ui/ending_screen.gd`:46-50, :232-245, :421-426; port: core/95 built it)

### Words
- When the economy's wording is shown, then it is the old: "The Old Tree", "Personal", "House", "Coming soon",
  "Maxed out", "Locked", "Co-op only", "Need {coins} %d", "Need {drawers} %d", "Needs: %s", "%s level %d", "Level
  %d/%d", "MAX", "Close", "%s bought %s", "A teammate", "Debug: +%d {coins}", each Upgrade's name and tooltip from UJ.
  (ref: UP:409-424; UM:18-20, UM:443-453, UM:566-584; TN:46-52)

## What was weak in the old economy
- The flight of the Coins was in the rules: `CoinBank` scheduled each Coin's landing on the Game's clock and the
  spendable Coins waited for it (CB:50-93), so a HUD timing number changed what a player could buy and when.
- Every effect was code: `Upgrades.stat()` matched 20 stat names (UP:176-224) and 30 accessor functions read them
  (UP:241-380); a new Upgrade needed code even when it only changed a number. Prerequisites were id strings; the
  switched-off features were special-cased (`is_hamper_node`, `is_pairing_node`, UP:61-69).
- The floor's 100 Coins and the Cabinet's 50 arrive with no "+N": the counter jumps while nothing says why (CB:19-27).
- Completions burst all at once (Coins, Drawers, gifts, confetti; old ticket 72): fixed by Q2612 already (a filled
  Drawer flies its Coins and Drawers and nothing else).
- The menu was 676 lines building every node in code (UM), its sizes and colours constants; the tree's station was a
  box built over the mesh in code (US:24-48).
- The House prices drifted from their own rule (Q1405): 37 Drawers planned, 49 after the splitter; prices fit to
  features now not ported.
- The tree picked lines on each machine, so two players near it could hear different lines (D Open [95]); its moments
  were sensed from shared state with no Command.
- A Guest's Hands numbers came from the Guest's machine and were clamped by the Host (port D13) rather than decided
  from the levels the Host keeps.
- The words: "Drawers" the currency sits beside the Cabinet's drawers (old ticket 48 follow-up); the HUD tells them
  apart by the icon alone.
- In batch B many Upgrades' features are not built yet (X-rays, Elevator, vacuums: batch C), so the House section is
  mostly "Coming soon" and the team's Drawers pile up with little to buy (choice E3).
