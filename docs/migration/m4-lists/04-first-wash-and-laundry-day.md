> Draft behaviour list for batch A's run ends (core/72): the First wash, the Laundry day (the Laundry bins and the Final
> wash) and the Final screen, written from the reference on 2026-11-24; for the designer to approve. The proposal built
> on it: `docs/architecture/run-ends.md` (its choices R1-R9 are core/72's `[blocking]` follow-ups).

# M4 piece: the First wash, the Laundry day and the Final screen

Draft behaviour list (catalogue B21 First wash, B22 Laundry day, B23 Final screen, B33 Laundry bin, P36 the Final
screen's leftovers, core/61's L6 what the Lobby offers after an ending). Refs are in the old game
(`reference/it-socks/`, tag v0.1.1) unless they start with `port:`. Short forms: L = `game/campaign/laundry.gd`,
LV = `game/campaign/laundry_view.gd`, RM = `game/devices/rogue_machine.gd`, RI = `game/devices/rogue_installer.gd`,
FS = `game/devices/first_wash_spit.gd`, CA = `game/campaign/campaign.gd`, ES = `game/ui/ending_screen.gd`,
FR = `game/campaign/final_record.gd`, M = `game/core/main.gd`, H = `game/ui/hud.gd`, PR = `game/ui/prompts.gd`,
RC = `game/player/rig_click.gd`, RG = `game/player/rig.gd`, HL = `assets/house/house_layout.json`,
TF = `data/tuning/first_wash.json`, TL = `data/tuning/laundry.json`, TS = `data/tuning/final_screen.json`,
TV = `data/tuning/voice.json`, I38..I92 = `docs/llm/progression/issues/38..92`. Every number under TF, TL, TS and TV is a
placeholder in the old game too.

Marks: "(washer)" a line whose doing is the washing machine's (core/73 builds it, this piece fires it); "(stages)" a
line of the Stage frame (core/71); "(B)" a line that needs batch B (Coins and Drawers payouts, Gifts, the Wardrobe,
Collections unlocking, the Profile, the Old Tree); "(C)" batch C (the Guide card, the Elevator, the Radio);
"(D)" batch D (the Drum finale). The Dirty Socks stay off (Q1817, ADR-0011): their lines (one empty bin, binning a Dirty
Sock, the stink wisp, "Dirty Socks left: N") are not listed and not ported.

## Behaviour list

### A New Game before the First wash
- When a New Game starts in the house (staged, not the zoo), then the washing machine is fine: no sparks, no smoke, no
  buzz, its face calm (anger 0 until the first bin goes in). (washer) (ref: CA:400-403 `anger()`; I86 answer; Q1846)
- When a New Game starts, then no Socks lie in the house: the first Stage's Socks are laid but kept aside (their rows
  saved) until the First wash. (stages) (ref: L:128-140 `begin_intro`, L:142-155 `intro_socks`; Q1847)
- When a New Game starts, then the World's Laundry bins already stand full in the house: the bin by the basement
  machine and the others drawn for this World (below). (ref: L:105-125 `start`, L:233-245 `_place_bins`; Q1848, Q1851)
- When a New Game starts, then the Guide card has one page: the first goal, "wash the laundry" (wording placeholder).
  (C) (ref: L:84-85, L:136-138; Q1849)
- When a New Game starts, then every Door between the laundry room and the garage stands open, so the Old Tree can be
  heard; it waits silent until the First wash is over. (B) (ref: L:86-91 `tree_call` TREE_WAITING; I88; Q1864)

### The First wash (the intro cutscene)
- When a player carrying a full bin clicks the washing machine while the First wash is pending, then the First wash
  begins for everyone (any player in co-op; any of the World's bins, not only the one by the machine). (ref: L:583-594
  `_early`; RC:63-65, RC:180-183; I86 follow-up "the bin clicked in may be any bin")
- When the machine is busy (someone in its drum) as the bin is clicked, then it is refused: "The washing machine is
  busy". (ref: L:584-587, L:600-601)
- When the First wash is granted, then the first Stage's Socks land in their usual places at once, for everyone, hidden
  by the cutscene; the machine is now at its angriest; the Guide gains page 2 (C). (ref: L:158-173 `_start_intro`;
  CA:404 `anger()`; Q1846, Q1847)
- When the First wash plays, then every player's view cuts to one shared camera on the machine (the wide shot, 2.0 m
  out along its front, 0.95 m up, 0.35 m to its right, looking at its middle, fov 60), input is off, the HUD goes, and
  no Socks, Pairs, items, Laundry bins or avatars are drawn (each machine hides them for itself). (ref: RM:140-191
  `play`, RM:400-405 `_place_camera`; RI:96-103 `set_cutscene_view`, RI:168-172 `_cinematic`; `data/tuning/rogue.json` `camera_*`;
  Q746, Q1425, Q1426; I86 "hide the bin")
- When the First wash plays, then it opens out of black over the shared fade (0.5 s) and ends fading to black over the
  same before the view comes back. (ref: RM:166-168, RM:252-255; `fade.seconds`; Q1262)
- When the First wash plays, then the music (Radio, menu music) ducks to about 25 % in about 0.5 s and comes back after
  (every cutscene does). (ref: I87; Q1867; port: Q2549 V5 b)
- When part 1 plays, then the machine first washes calmly for 3 s: the drum turns (ramping up over 1 s), bubbles (40)
  rise out of the porthole, the calm wash loops (`wash_calm`), the camera holds the wide shot with a faint 1 cm bob.
  (washer) (ref: RM:182-184, RM:191, RM:334-342 `_step_voiced`; TF:`wash_seconds`, `bubbles`; TV:`wash_spin`; Q1846, Q1866)
- When the calm wash ends, then the machine breaks: the wash loop stops, the clanks and rattle play (`machine_break`, at
  the machine, 0.4 m up), the bubbles stop, the damage shows (blue-white sparks off its back and cable, smoke puffs, the
  buzz, at the angriest), the room's light flickers within 4 m, the drum stops. (washer) (ref: RM:278-292 `_step_intro`;
  Q1007, Q1846, Q1866)
- When the machine has broken, then it talks: the voiced `cutscene_1` (12 s: "What? What is this? What the? How many
  socks can one person have?" / "Okay, that's it. I'm done." / "If you ever want to get out of the basement, you first
  have to learn to take care of me."), starting 0.6 s after the wash, the cutscene stretched to the line's end plus
  0.9 s and the fade; the camera cuts between the wide and the close shot at each subtitle line (wide for the first).
  (washer) (ref: RM:212-221 `_start_voice`, RM:350-360; `data/voiceover/cutscene_1.json`; TV:`lead_in`, `tail`,
  `close_shot`, `close_up`; Q1411, Q1412)
- When the line is over, then part 2, the spit, plays: its own effect with its own numbers, so it can be tweaked alone:
  the machine's door swings open (0.4 s), 500 Socks fly out of the porthole over 1.8 s (2.6 m/s, 35 % jitter, a 24
  degree cone aimed 35 degrees up, spinning 8 rad/s, gravity 9.8, 35 % bounce off the floor, then lying still flat), the
  whoosh plays (`socks_pour`, at the porthole), and the door shuts again over the last 0.6 s of its 3.6 s. (washer for
  the door) (ref: RM:296-308 `_step_spit`; FS:1-6, FS:51, FS:170-205; TF:`spit`; Q1847, Q1854, Q1866)
- When the spit draws its Socks, then each is the real Sock model (LOD0) in a Design's look, Designs drawn seeded from
  the catalogue (seed 7: every machine draws the same spray), one MultiMesh per Collection, no physics; decoration only.
  The spray's Socks vanish when the effect ends; the real Mess already lies in its places. (ref: FS:1-6; FS:118-133
  `stop`; Q1854)
- When the Host presses the skip key (or the pad's Start), then the cutscene ends at once for everyone; no Guest can
  skip; the skip prompt shows on the Host's screen only. (ref: RM:229-245; Q751)
- When the cutscene ends (the Host's timeline or its skip), then every player respawns standing by the machine, side by
  side as at a New Game, every knockdown ended, view and input back, the HUD back; a Guest whose timeline ends first
  holds the black screen until the Host's end arrives. (ref: RI:151-165 `_rogue_ended`; RM:8-11; Q745, Q759)
- When the First wash is over, then the bin is still in its carrier's Hands, still full: one of the bins for the
  ending. (ref: I86 answer; Q1848)
- When the First wash is over, then the Guide card flips to its new page 2 at once (a page-turn tween, 0.5 s squeeze),
  page 1 readable by flipping back (R on a held card). (C) (ref: L:176-197 `rogue_ended`, `flip_guide`, `turn_page`;
  Q1849; I86 follow-up)
- When the First wash is over, then the Old Tree starts calling now and then (first after 20 s, then every 25-55 s,
  12.5 dB louder, heard to 16 m) until a player first comes near it. (B) (ref: L:176-180; I88; Q1864, Q1865)
- When the First wash has played, then it never plays again in this World (saved); a loaded World skips it. (ref:
  L:763-797; Q1849)
- When the cutscene is turned off (tests, the zoo), then the Socks land and the Guide flips at once, with no cutscene.
  (ref: L:166-173)
- When a Guest joins mid-cutscene, then it sees the end state (the Mess lying, the machine angry), no cutscene.
  (ref: I86 Built log)
- When a bin is clicked into the machine after the First wash and before the last Fix, then it is refused: "Fix the
  washing machine first". (ref: L:593-594, L:602-603; Q1819)

### The Laundry bins (the entity)
- When a World is made, then its bins stand at spots of the house layout: seven candidates, one per room where it makes
  sense: laundry (basement, by the machine, always), kitchen and living (ground), bathroom, bedroom and kids (first),
  loft (attic). (ref: HL:`laundry_bins`; L:219-245; Q1818, Q1850)
- When a New Game draws its bins, then it uses `bins_per_world` spots (3; clamped to 1..all): the one by the machine
  always, the rest drawn at random from the other six from the World's seed, saved with the World; the other spots have
  no bin. (ref: L:213-231 `bins_per_world`, `pick_spots`; TL:`bins_per_world`; Q1850, Q1851)
- When a bin stands full, then it is a white perforated plastic hamper (0.44 x 0.52 x 0.34 m) with a heap of laundry
  in it made of real Sock meshes (its `contents` heap, the `empty` blend shape driven as 1 - fill, hidden when empty).
  (ref: L:39; LV:12-14, LV:133-149; `tools/blender/make_laundry_bin.py`; Q1036, I40)
- When a bin is aimed at, then the readout names it "Laundry bin, dirty" (full) or "Laundry bin, empty"; with empty
  Hands the left-click key shows beside it. (ref: L:351-357; PR:24-26)
- When a lying bin is left-clicked with empty Hands, then it comes into the Hands (a "pick" cue); with anything in the
  Hands it is refused "Hands full". (ref: L:469-489; RC:68-70; Q1094)
- When a bin is carried, then it takes the whole Hands (no Sock, Pair or Guide card comes in), rides low in front of the
  carrier (the body frame, 0.45 m up, 0.72 m ahead, going down with Crouch), steady (it follows the drawn camera, not
  the physics tick). The carrier walks at the normal pace (Q1820's question offered "slow walk"; it was never built).
  (ref: `data/tuning/hold.json` `bin`; `game/hands/hands.gd:86-104`; I38 "held items must be steady"; R5)
- When a carrier right-clicks, then the bin goes down where the crosshair is, if a drop may go there (else the refusal
  of a drop), at the yaw it was held, the same on Host and Guest, saved. (ref: L:494-546; `game/player/rig_drop.gd:65-66`;
  I44; designer 2026-11-06)
- When a carrier right-clicks aimed at a teammate, then the bin goes into the teammate's Hands if they are empty, else
  down at their feet with "Hands full" for them. (ref: L:507-513, L:534-541)
- When a bin's carrier leaves, then the bin is laid where they stood; a save stands a carried bin where it was picked
  up. (ref: L:746-760; L:763-772)
- When a bin is put down from a carry, then it eases from where it was held to where it lies (the shared put). (ref:
  LV:117-125; `release.flick`)
- When a cutscene plays, then every bin is hidden, carried or lying, and comes back as it was. (ref: RI:100-101; I86)

### The Laundry day (after the last Fix)
- When the last Stage's Fix is done (in the old game the Drum's softener, D; in batch A the fourth Stage's), then the
  machine is fixed and calm and the Laundry day begins: the bins may now load it. (stages) (ref: CA:324-332
  `_machine_fixed`; L:378-381 `machine_fixed`; Q1819; Q2615)
- When the machine is fixed, then the Stage bar gives way to the bin tally: the bar fills (0.25 s), glows (0.25 s),
  shrinks into itself with a back ease (0.3 s), and the tally pops in (0.2 s) with a cheerful sound (`pop`,
  placeholder); after that it is the tally alone. (stages for the bar) (ref: H:325-360; H:99-102; RG:260, RG:636-646;
  Q1619, Q1620)
- When the tally shows, then it reads "Laundry bins loaded: n/total" with the bin icon, at the Stage bar's place
  (top centre, 12 px down), the same on every machine. (ref: H:298-328; RG:643-645; I91 follow-up wording)
- When the machine is fixed, then the drum's laundry pile behind the porthole is empty (it showed full before). (washer)
  (ref: L:364-376 `pile`)
- When a carrier of a full bin aims at the fixed machine, then the prompt reads "[LMB] Load the washing machine".
  (ref: PR:36-37; Q1905)
- When the carrier left-clicks the machine, then the bin loads it: it tips toward the door in the carrier's Hands
  (up to 105 degrees, out and back over 1.4 s, `sin` shaped), its heap empties, its Socks pour into the drum with the
  whoosh (`socks_pour`), the pile behind the porthole grows a step (0.4 after the first, evenly to 1 at the last); the
  bin is empty in the carrier's Hands, to put away anywhere; there is no wash wait. (washer for the pile) (ref:
  L:620-630 `_load`; LV:61-63, LV:167-186; TL:`tip_seconds`, `pile_min`; Q1845, Q1905)
- When an empty bin is clicked into the machine, then it is refused: "That bin is empty". (ref: L:569-571, L:606-607)
- When the ending's wait runs, or someone is in the drum, then a bin is refused: "The washing machine is busy". (ref:
  L:572-574, L:600-601)
- When the last of the World's bins is loaded, then after the tip (1.4 s) the Host starts the ending for everyone: the
  Final wash. (ref: L:576-577, L:632-652; Q1906)
- When a save is made in the Laundry day, then which bins are loaded, the pile and an ending's wait in progress are
  kept; a Guest who joins gets them. (ref: L:763-797; Q1906)

### The Final wash (the ending's cutscene)
- When the Final wash starts, then the door shuts, the cutscene frame plays as above (shared camera, input off, HUD
  gone, nothing drawn but the machine, music ducked, the Host's skip) and the run is marked washed (saved). (ref:
  L:663-674 `_finish`; RM:140-191; Q1006, Q1906)
- When the Final wash plays, then the machine washes happily for 6.5 s (7 s less the fade): the drum spins up (to 0.8
  turns a second over the first second), bubbles (40) rise out of the porthole, and the camera pushes in from the wide
  shot to 1 m in front of the face over the first 40 %, looking from the machine's middle to the brows. (washer) (ref:
  RM:216, RM:334-342, RM:381-390; TL:`happy`; TV:`wash_spin`)
- When the wash part ends, then the machine talks: `cutscene_6` (38 s: "You're alive! And you've got the last
  ingredient!" ... "I'd say we won't have to see each other like this again, but knowing how things go, we'll see you in
  a few months."); the drum slows to a gentle 0.12 turns a second, the bubbles stop a second later, the camera cuts wide
  and close per subtitle line. (washer) (ref: RM:343-360; `data/voiceover/cutscene_6.json`; TV:`after_spin`; Q1413;
  `cutscene_6_part_1/2` merged into one by the designer, `rogue-machine/04` 2026-11-09; R6)
- When the Final wash plays unvoiced (no line), then the old happy look carries it: the machine hops (6 cm, 1.1 a
  second) and sways (3 degrees), a warm glow pulses, the room lights steady, the rumble plays. (washer) (ref: RM:171-191,
  RM:311-328)
- When the Final wash ends (its timeline or the Host's skip), then the screen stays black and the run ends once: the
  Final screen opens for every player together; nobody respawns. (ref: CA:335-341 `end_run`, CA:365-370; RG:233-235)
- When a load or a join comes after the Final wash began but before the run ended, then the Host ends the run at once
  (straight to the Final screen). (ref: CA:432-436 `step`)
- When the run has ended, then play time stops counting. (ref: M:820-821)

### The Final screen
- When the run ends, then every player sees the Final screen together, over the frozen game (inset 20 px, the ending
  panel on the one Theme), the mouse free; the ESC menu does not open over it; the player is frozen. (ref: ES:1-9,
  ES:108-138; M:396; RG:228-235; Q1836, Q1853, Q1855)
- When the screen opens, then its title reads "Every sock has its mate". (ref: ES:169)
- When the screen opens, then it has a column per player side by side, each in their Player colour (a 22 % tint, a 4 px
  border, 16 px corners): the name (32 px, in the colour, clipped), the Coins icon and the score (40 px), "n / total
  Pairs" (22 px) and a "+N bonus" caption, a Sock stage under it and a strip of Wardrobe pieces under that (B). (ref:
  ES:251-317; Q1842)
- When the screen lists players, then they are the players in the game now, by player number; Solo shows the player's
  name (or "You"). A player who shelved Pairs and left is not shown (R7). (ref: M:947-954)
- When a column fills, then the Pairs that player shelved this run pop in one by one as Sock previews (one Sock of the
  Pair's Design, seen from above, fitted to its grid cell, in shelving order), each flying in from 25 % of the stage's
  height above its cell with a back-out pop and a turn over 0.35 s, each adding its Coins to the score, which counts
  up toward it (9 a second share) with a coin tick (at most every 0.12 s). (ref: ES:329-360, ES:471-532; FR:16-17,
  FR:39-42; TS:`pop_time`, `fly_from`, `count_speed`; Q1843)
- When the Pairs pop, then the pace is slow, then a fast stream: 0.8 s before the first, the gap shrinking from 0.7 s
  to 0.03 s over the first 14 Pairs; a rare Pair holds 0.9 s more and sparkles (in the player's colour mixed with gold)
  with the "match" sound; others a "pop" (no two pops closer than 0.07 s). (ref: ES:404-419, ES:552-570; TS; Q1844)
- When a column's last Pair is in, then the Coins not from a Pair (floor payouts, batches, refunds) land as one "+N
  bonus" step so the score ends at what the player earned. (B for most bonuses) (ref: ES:517-532; I85 follow-up)
- When a column's Pairs are done, then after 0.8 s the Wardrobe pieces the player won this run pop in (0.7 s apart),
  turning slowly; a rare one sparkles. (B) (ref: ES:362-379, ES:503-515; FR:19-21, FR:44-53; Q1843)
- When every column is done, then after 1.0 s the World totals show and count up over 1.6 s: Play time (h:mm:ss),
  Coins earned, Stages, Gifts opened (B), Wardrobe pieces won (B); then the finale: three waves of bursts over every
  column over 2.5 s in the players' colours toward gold, and the sting (`cabinet_reveal`, placeholder). (ref:
  ES:421-443, ES:572-612; TS:`totals_delay`, `count_time`, `finale_time`, `confetti`; Q1835; I85 "Stages = Stages
  completed, confirm")
- When the totals have shown, then the Collections this game unlocked pop in 0.6 s later under them: "New Collection
  unlocked" (or "New Collections unlocked"), each icon at 96 px with its name (24 px) below, a bounce (0.5 s) and a gold
  sparkle (24 bits), 0.25 s apart; hidden when none. (B) (ref: ES:652-765; `game/player/profile_installer.gd:66-79`;
  TS:`unlock_*`; Q1904)
- When any key, mouse button or pad button is pressed before the totals show, then that machine's screen skips to the
  totals at once (every Pair and piece in place, scores final, no patter of sounds for what flashes by); a skip is each
  machine's own. (ref: ES:614-640; Q1844)
- When the totals have shown, then "Continue" (a keycap, 30 px) waits; with a pad it takes the focus. (ref: ES:218-220,
  ES:642-644)
- When any player presses Continue, then everyone goes back to the Lobby: the Host (or Solo) saves and takes the game
  there, a Guest's press asks the Host; the World stays chosen. (ref: M:1068-1104; Q1836; I85 follow-up "a Guest's
  Continue takes everyone")
- When the Final screen is not the end of a Stage, then it never shows when a Stage completes. (ref: Q1853, Q1855)
- When the run ends, then every player's Profile counts a finished game and unlocks the next Collection, shown on the
  screen. (B) (ref: `game/player/profile_installer.gd:22-23`, :66-79; Q1440, Q1466)
- When the record of the run is kept, then it is every Pair shelved (who, which Design, the Coins its shelving paid,
  bonuses excluded), every Wardrobe piece won (who, which; B), the Gifts opened (B); kept on every machine from the
  Host's answers, saved and in the join snapshot. (ref: FR:1-101)

### What the Lobby offers after an ending (L6, P36)
- When everyone is back in the Lobby after an ending, then the finished World is still chosen and its Continue would
  load an ended World with nothing to do: the old game left open what the Lobby offers (a finished World, only New
  Game, a note on the World's card) and whether a player may stay and keep tidying ("Keep tidying" was cut). (ref: I85
  follow-ups; P36; core/61 L6; R8)
- When the Final screen shows, then "who did what" titles (most throws, most Cat pets) were proposed and never picked.
  (ref: I85 follow-up; P36; R9)

### Words and sounds
- When this piece's words show, then they are the old placeholders: "Laundry bin, dirty", "Laundry bin, empty",
  "Load the washing machine", "Fix the washing machine first", "That bin is empty", "The washing machine is busy",
  "Hands full", "Laundry bins loaded: %d/%d", "Every sock has its mate", "%d / %d Pairs", "+%d bonus", "Play time",
  "Coins earned", "Stages", "Gifts opened", "Wardrobe pieces won", "New Collection unlocked", "New Collections unlocked",
  "Continue". (ref: L:351-357, L:596-607; PR:37; H:328; ES:169, ES:218, ES:232-233, ES:530-531, ES:677)
- When this piece plays sounds, then they are the old first recordings, none picked by the designer yet: `wash_calm`
  (the calm wash loop, -6 dB), `machine_break` (clanks), `socks_pour` (the spit and each bin's pour), `pop`, `coins`,
  `match`, `cabinet_reveal` (the Final screen's placeholders), `pick` and `drop` (the bin). `wash_bin` lost its player
  when the per-bin wash went (I91) and is not ported. The Final wash's voiced cutscene has no wash sound of its own;
  the unvoiced one used the old synth rumble. (ref: `data/sounds.json`; I87; I91 follow-up; Q1866, Q1871)

## What was weak in the old run ends
- Three endings in one history: the Dirty Socks into one bin (I38), then prefilled bins each washed for 6 s (I83),
  then bins that load the machine (I91); `laundry.gd` (855 lines) still carries all three behind `socks_mode()`, and the
  Final wash's sound is still a `part_fit` placeholder in the dead branch (L:655-660).
- The First wash is a `final_wash` Command with an `intro` flag through `_early()` (L:583-594): the run's opening rides
  the ending's verb. The Socks it holds back are a flat float array of rows (L:94, L:128-155).
- One `RogueMachine` (540 lines) plays every cutscene with flags (`intro`, `happy`, `spit_after`) and a second, unvoiced
  timeline per flag that only the tests saw (RM:171-191, RM:311-328).
- The bins' spots live in the generated house layout JSON (HL), placeholders never placed by eye; one is in each room
  "where it makes sense" but nobody looked at them in play.
- Every bin stands in the house from New Game, carried about for four Stages before it can do anything; nothing tells a
  player why the machine refuses it beyond "Fix the washing machine first".
- The pile behind the porthole is small and dark; the bin's tip barely shows in first person; the Socks are never seen
  going in, only heard (I91 follow-ups, Q1907).
- `cutscene_6` greets the players back from the Drum ("You're alive!"); without the Drum (batch A) its first line does
  not fit.
- The Final screen lists only who is in the game at its end, keyed by the peer number; a player who shelved half the
  run and left is lost; a loaded World with `ended` set shows nothing and has nothing to do.
- The Final screen's chrome is built in code (827 lines, sizes as constants), its three placeholder sounds borrowed
  from other moments.
- The carried bin's "slow walk" offered in Q1820's question never reached the code.
