# The run's ends: the First wash, the Laundry day and the Final screen

**Status: proposal for the designer (core/72, batch A, Q2606, Q2614). Nothing here is built.** Findings:
`docs/migration/m4-lists/04-first-wash-and-laundry-day.md` (73 old lines). The choices are R1-R9 at the end (core/72's
`[blocking]` follow-ups); the text follows each recommendation and names where another option changes it. Written
beside core/71 (Stages, `docs/architecture/stages.md`) and core/73 (the washer and voices, `washer.md`, `voice.md`),
designed at the same time: this file names the seams it needs from them and designs none of their parts.

## What it owns

The run's opening and its ending, between the Lobby's Start and the Lobby again:
- **the First wash**: a New Game's first bin into the washing machine plays the intro cutscene and lets the first
  Stage's Socks into the house;
- **the Laundry bins**: carried hampers of laundry standing in the house (an entity: behaviour plus Looks);
- **the Laundry day**: after the last Fix the bins load the machine and the tally counts them; the last one starts
  **the Final wash**, the ending's cutscene, which ends the run;
- **the Final screen** (a scene on the Theme) and its record of the run, and **Continue** back to the Lobby;
- **the spray** (the Socks flying out of the door), an effect core/71's Fix cutscenes reuse (Q1937-Q1940).

It does not own the Stages, the Parts and their Fixes, the locks, the Stage bar (core/71); the washer, its face, moods,
damage, pile and voice lines (core/73); the voice system (core/73, `voice.md`); Coins payouts, Drawers, Gifts, the
Wardrobe, Collections unlocking and the Profile (batch B); the Guide card, the Elevator (batch C); the Drum (batch D).

## The shape

| Thing | Kind | Where |
|---|---|---|
| `LaundryBin` | Part (state `used`, `full`) beside a `Carriable` on `laundry_bin.tscn`; no other script | `game/entities/laundry_bin/` |
| `LaundryBinLooks` | Looks scene: the hamper model, its `Contents` heap (blend shape `empty`), an AnimationPlayer (`tip`) | same |
| `LaundryDay` | Part, one per house: `first_wash` (PENDING, PLAYING, DONE), `drawn`, `loaded`, `ending_left`, `ended` | `game/laundry/` |
| `LaundryTuning` | Resource (`laundry_tuning.tres`): `bins_per_world`, `tip_seconds`, `pile_min`, the hold slot | `game/laundry/` |
| `FirstWashTuning` | Resource: `wash_seconds` (3.0), `bubbles` (40) | `game/laundry/` |
| `SockSpray` + `SockSprayTuning` | effect scene (MultiMesh per Collection) + Resource (the old `spit` numbers) | `game/laundry/` |
| `Cutscene` frame | a scene of the runtime: shared camera, fade, input off, HUD and things hidden, Host skip, respawn, duck | shared seam, below |
| `RunRecord` | Part: Pairs shelved `[player id, design, coins]`; B adds pieces and Gifts | `game/laundry/` |
| `FinalScreen`, `FinalColumn` | scenes on the Theme; `FinalScreenTuning` Resource (the old `final_screen.json`) | `game/ui/final_screen/` |
| `FinalTotal` | Resource per total line (caption, source name, format); a list in `final_totals.tres` | `game/ui/final_screen/` |

Code shape (Q2251-Q2253): `LaundryBin` and `LaundryDay` extend `Part` (one step); the bin has no script beyond its Part.
Decided state lives on the Parts and only the Host's answer writes it; the spray, the tip, the cutscene and the screen are
looks only (`coop-structure-for-the-port.md`).

## The Laundry bins (the entity)

**Authored by placing.** Every candidate spot is a `laundry_bin.tscn` instance placed by hand in `house.tscn` under
`LaundryBins` (the seven old spots, positions from the old layout, then judged by eye); its `LaundryBin.always` export
marks the one by the washer. A designer adds a spot by dropping another instance: no code, no list. The instances are
static, so every Part id is in the layout hash and no spawner is needed; a bin a World does not use is `used = false`
(hidden, no collision, not aimed).

**The draw** (`LaundryDay`, at a New Game, Host): `always` bins plus `bins_per_world - always` others drawn from the
World's seed (`WorldRecord.seed`, Q2524), written in one answer (`used` on each bin, `drawn` on LaundryDay), saved.
Clamped 1..spots (Q1850, Q1851). (R1 b: the non-`always` bins are drawn but stay hidden until the last Fix.)

**Carrying** goes through the shared carry seam (below): left click with empty Hands picks it up; it takes the whole
Hands; right click puts it down at the yaw it is held (the Carriable's `yaw`); right click aimed at a Teammate hands it
over (into empty Hands, else at their feet, "Hands full"); a leaver lays it where they stood; a load lays a carried bin
where it was last laid (the Carriable's `loaded()`). Walk pace: normal (R5 a; R5 b adds a `pace` to the carry slot).

**Looks** (`LaundryBinLooks`, a Looks child scene swapped with no rule change): the old hamper, ported by the Blender
skill as `tools/blender/laundry_bin.py` from `make_laundry_bin.py` (white perforated plastic, the Sock-mesh heap,
blend shape `empty`), with `Contents` driven as `1 - fill` (1 full, 0 empty: a bin is full until it loads), eased at 0.8
a second; `tip` is an AnimationPlayer animation (out to 105 degrees and back over `tip_seconds`), turned toward the
washer by the Looks (it rotates its pivot to face `washer.global_position` before playing). Hidden in cutscenes by the
frame (below). Readout words "Laundry bin, dirty" / "Laundry bin, empty".

## The Laundry day

**Load** (a Command `load` to `LaundryDay`, from the washer's use with a carried bin, seam W1): `decide()` refuses, in
order: not carrying a bin; `first_wash == PENDING` (that is the First wash, below); not the last Fix done (seam S2):
"Fix the washing machine first"; the bin empty: "That bin is empty"; `ending_left >= 0` or the washer busy (seam W1):
"The washing machine is busy". Granted: the bin `full = false`, `loaded += 1`; the last of the drawn bins sets
`ending_left = tip_seconds`. Every machine on the answer: the bin's Looks plays `tip`, the washer's pile goes to
`pile(loaded)` (0, then `pile_min` evenly to 1; seam W2), `socks_pour` plays at the porthole (seam W6).

**The tally:** once the last Fix is done (S2), the HUD's top slot (S3) folds the Stage bar (fill 0.25 s, glow 0.25 s,
back-ease shrink 0.3 s) and pops in "Laundry bins loaded: n/total" with the bin icon (0.2 s, `pop`); the tally is a
small scene `bin_tally.tscn` reading `LaundryDay`.

**The ending's wait:** the Host counts `ending_left` down in `_physics_process` and asks `final_wash` (Host-only) at 0;
saved, so a load mid-wait asks again.

## The First wash

**Held Socks (seam S1).** At a New Game the first Stage's Socks are laid behind the loading screen as now and kept out
of the Mess, their records held (saved) until told; the house shows none. `LaundryDay.first_wash = PENDING`.

**Start.** A carried full bin used on the washer while PENDING (any of the World's bins, Q1848, I86): `decide()` refuses
only while the washer is busy; granted, one answer patches `first_wash = PLAYING`, has core/71 reveal the held Socks
(S1; they lie in their places, hidden by the cutscene) and starts the cutscene `first_wash` on the frame. The bin stays
in its carrier's Hands, full (Q1848).

**The sequence** (a `CutsceneScript` Resource `first_wash.tres` the frame plays; its beats call the washer's Looks, W2):
1. fade in from black (`fade.seconds`); the wide shot (W7) with a 1 cm bob; `calm_wash` for `wash_seconds` (drum
   ramps over 1 s, bubbles, the `wash_calm` loop);
2. `break`: the loop stops, `machine_break` at the machine, bubbles stop, the damage at its angriest, the room's
   flicker within 4 m, the drum stops; the washer's mood becomes angriest (W3);
3. the voiced line of moment `cutscene_first_wash` (the old `cutscene_1`, W4), 0.6 s after the wash, the cut between
   the wide and close shot at each subtitle line;
4. the spray: `door_open`, `SockSpray.play(porthole, forward, floor)` with `socks_pour`, `door_close` over its last
   0.6 s (W2, W6);
5. fade out; the Host's end.

**End** (the Host's timeline, or its skip, a Host-only `cutscene_end`): `first_wash = DONE`; the frame respawns everyone
by the washer (Q745). It emits `first_wash_done` for B's Old Tree calls and C's Guide flip. With cutscenes off (tests,
the zoo's knob) start and end are one answer. **The first goal** (R2 a): until DONE the HUD's top slot shows "Wash the
laundry" (placeholder; C's Guide card page 1 replaces it).

**The spray** (`SockSpray`, `sock_spray.tscn`): 500 real Sock meshes (LOD0), Designs drawn from the catalogue with
`seed`, one MultiMesh per Collection, no physics (the old FS step: gravity, bounce 0.35, lie flat when slow); every
number in `SockSprayTuning` (`count`, `speed`, `speed_jitter`, `spread_deg`, `up_deg`, `window`, `length`, `door_open`,
`door_close`, `gravity`, `bounce`, `spin`, `seed`), each `# placeholder:`. Looks only; gone when it ends (R3 a).

## The Final wash and the end of the run

**Start** (`final_wash`, Host-only, from the wait): `ending_left = -1`, the washer's door shut (W2), the cutscene
`final_wash` (`final_wash.tres`): fade in; `happy_wash` for `happy.seconds - fade` (drum to `wash_spin`, bubbles, the
camera pushing from the wide shot to 1 m before the face over the first 40 %); the line of moment `cutscene_final_wash`
(the old `cutscene_6`, W4, R6) with the drum slowing to `after_spin`, the bubbles off a second later, the wide/close
cuts; fade out and hold black.

**End:** `LaundryDay.ended = true` (one answer, saved; the World's record gets `finished`, R8); every machine opens the
Final screen over the frozen game; play time stops (`Autosave`'s clock reads `ended`). A load or join with the Final
wash begun but not ended ends it at once.

## The Final screen

**`RunRecord`** (a Part, on every machine through the answers): a Cabinet's shelve answer appends `[player id, design,
coins]` (the Coins its shelving paid, Q2610's personal Coins; bonuses excluded), keyed by the Roster's player id
(Q2458), so a leaver's Pairs stay. Saved and in the join snapshot. Batch B adds `pieces` and `gifts` rows.

**`FinalScreen`** (`game/ui/final_screen/final_screen.tscn`, on the one Theme, a CanvasLayer over the frozen game):
the title "Every sock has its mate"; an `HBoxContainer` of `FinalColumn` scenes (`final_column.tscn`: a PanelContainer
whose style takes the player's colour, the name, the Coins icon and score, "n / total Pairs", "+N bonus", a
`SubViewport` Sock stage with an orthographic camera, a pieces strip hidden while empty); the totals row built from
`final_totals.tres`; the unlock strip (hidden while empty; B fills it); Continue. Columns: every player in the
`RunRecord` or the Roster (R7 a), in the Roster's order; one who left is greyed with "(left)".
Timing in `FinalScreenTuning` (the old numbers): pops, the slow-then-fast schedule, the rare pause and sparkle (a
Design's `rarity` RARE or above), the count-up, the bonus step, totals, finale, unlock reveal. Any key skips this
machine's screen to the totals (Q1844). The sounds are SoundEvents: `final_pop`, `final_tick`, `final_rare`,
`final_sting`, first set to the old placeholder recordings (`pop`, `coins`, `match`, `cabinet_reveal`) in the sound
catalogue so the designer can pick their own on the Sounds bench.

**Totals** (Q1835): each a `FinalTotal` Resource (caption, `source`: a StringName a provider answers, format: count or
time). Batch A: `play_time` (WorldRecord), `coins_earned` (RunRecord), `stages` (S4). Batch B adds `gifts_opened`,
`pieces_won`, `drawers` by adding Resources to the list: no screen change.

**Continue** (Q1836): any player's press asks the Host; the Host saves and takes everyone to the Lobby through the game
link (core/62's `GameLink`, the reverse of the Lobby's Start: the Host loads `lobby.tscn` for everyone behind the loading
screen, the Session and Roster kept). The finished World then behaves as R8 says.

## The Cutscene frame (shared seam)

The First wash, the Final wash and core/71's Fix cutscenes are one frame, so it is built once. voice.md gave it to "the
cutscene feature, M5"; batch A needs it now. **Lead: whichever of core/71, 72, 73's ticket lists lands first owns it;
here it is ticket 4.** What it is: a `Cutscenes` Part in the level runtime (state: the playing `CutsceneScript`, its
start serial; the Host starts and ends), and a `CutscenePlayer` node (looks): on start every machine cuts to one shared
camera at the washer's shot markers (W7), freezes the local player, hides the HUD, hides every Sock, Pair, carried
thing, Laundry bin and avatar from the draw (nothing synced changes), fades in from black, ducks the music (Q2549 V5 b,
via `Voices`), plays the script's beats on the clock, stretches to its voice line (lead-in 0.6 s, tail 0.9 s), shows the
skip prompt on the Host only (the skip action, the pad's Start); at the Host's end it fades, respawns every player side
by side by the washer (unless the script says `respawn = false`, the Final wash) and gives everything back. A Guest
whose timeline ends first holds black until the Host's end; a late joiner sees the end state. A `CutsceneScript` is a
Resource: its beats as `[time or after-voice, beat name, args]`, its voice moment, `respawn`, `hold_black`.

## Seams this piece needs

From **core/71** (Stages):
- **S1** a New Game's first Stage's Socks laid at load but held out of the Mess (saved while held) until a patch reveals
  them; nothing in the house until then.
- **S2** the last Fix done (the machine fixed): a state the Host reads in `decide()`, and its cutscene's end as an event.
  The last Stage is the last of the Stage list, so batch D's Drum slots in before the Laundry day with no change here.
- **S3** the HUD's top slot: the Stage bar node with a `fold()` (or the bar exposing its fill, glow and scale) so the
  tally takes its place; and the slot free before the first Stage for R2's goal line.
- **S4** the count of Stages completed, for the totals.
- **S5** the Fix cutscene plays on the Cutscene frame and ends with `SockSpray` after every Fix that opens a floor, not
  after the last Fix (Q1937-Q1940: no floor opens, so no spray).

From **core/73** (the washer):
- **W1** the washer is used with a carried thing: the use routes to the carried thing's Part (core/71's Part Fix, this
  piece's `load`) and the prompt list includes "[LMB] Load the washing machine" while a full bin is carried after the last
  Fix; a `busy()` read (someone in its drum, a cutscene).
- **W2** the Looks beats the scripts call: `calm_wash`, `break`, `door_open(s)`, `door_close(s)`, `happy_wash`, and the
  `pile` (0..1) behind the porthole.
- **W3** its mood from the run's state: calm and undamaged while the First wash is PENDING, angriest from its `break`,
  one calmer per Fix (core/71), fixed after the last Fix, happy in the Final wash.
- **W4** two voice moments: `cutscene_first_wash` (the old `cutscene_1`) and `cutscene_final_wash` (`cutscene_6`),
  played by the frame; core/73 names them in its trigger list.
- **W6** markers in the washer's scene: the porthole (spray origin, pour), its forward, the floor under it.
- **W7** shot markers: `WideShot` (2.0 m out, 0.95 m up, 0.35 m right) and `CloseShot` (the old `close_shot`,
  `close_up`), and the face point for the Final wash's push-in.

For later batches (named, not built here): `first_wash_done` starts B's Old Tree calls; B's New Game opens the Doors
between the laundry and the garage; C's Guide card takes page 1 / page 2 from `first_wash`; B fills the Final screen's
pieces, Gifts, Drawers and unlock strip and counts the Profile's finished game; D's Drum is the Stage before the
Laundry day.

## The zoo stations (built from the data at load, Q2337)

- **`game/zoo/stations/laundry.tscn`**: a stand-in washer (the real one once core/73 lands, W1-W7) and one
  `laundry_bin.tscn` per candidate kind of spot; pillars: "Last Fix done" (a switch, sets S2's state through a zoo-only
  Command), "First wash" (resets `first_wash` to PENDING and holds a few Socks), "Spray" (plays `SockSpray` alone with
  the current `SockSprayTuning`), "Final wash" (all but one bin loaded); a label shows `loaded/total` and the phase. The
  Sock previews use the catalogue's Designs, so a new Design shows in the spray with no change.
- **`game/zoo/stations/final_screen.tscn`**: pillars for 1, 2 and 4 players open the Final screen on a made-up
  `RunRecord` drawn from the catalogue at load (every Collection's Designs, rare ones included), and one with a leaver.

## What is reused

Reused as it is: `Carriable` (`game/parts/carriable.gd`), Hands' refusals and the drop's place check, the Hand-off's aim,
`Coins` (the shelve pays as now), the Cabinet's shelve answer (one line appends to `RunRecord`), `WorldRecord`
(`play_time`, `seed`; adds `finished`), `GameLink` and the Lobby's Start handshake (reversed for Continue), the sound
catalogue, `HoldAnchor`-style hold slots, the Theme and `KeycapStyle`. New: everything in "The shape". Old code not
carried over: the `socks_mode()` branch, `RogueMachine`'s flag timelines, the flat Sock rows, the code-built screen.

## Ticket drafts (ready-for-agent, in build order; the lead files them)

Each one mergeable piece; numbers are placeholders for the lead's.

1. **Carried things in the Hands** (shared with core/71's Parts: the first of the two lists to land owns it). A
   `Carriable` comes into empty Hands and takes them whole (no Sock in, "Hands full"), rides a hold slot from a typed
   `HoldSlot` Resource (frame body, `at`, Crouch), steady at the drawn camera; right click puts it down at the held yaw,
   at a Teammate hands it over; leave and load lay it. Real path: in the Handling station, left-click a stand-in crate,
   walk, right-click: it lies at the crosshair turned as held; a Guest sees it. Blocked by: none.
2. **The Laundry bin entity.** `laundry_bin.tscn` (Carriable + `LaundryBin`), the graybox Looks, then the ported model
   (`tools/blender/laundry_bin.py`, assets per family batch), the heap's `empty`, the `tip` animation, readout words;
   the Laundry station with the bins. Real path: in the Laundry station pick a bin, carry it, put it down; its readout
   says "Laundry bin, dirty". Blocked by: 1.
3. **The run record.** `RunRecord` Part, the shelve answer's row, save and join. Real path: shelve a Pair in the Cabinet
   station; the record holds `[the player's id, the Design, the Coins paid]`; a Guest's shelve too. Blocked by: none.
4. **The Cutscene frame** (may be core/73's or core/71's, see above). `Cutscenes` Part, `CutscenePlayer`,
   `CutsceneScript`; a zoo pillar plays a test script. Real path: use the pillar; the view cuts to the shot, input and
   HUD are off, Socks are hidden; the Host's skip key ends it for both machines and both respawn by the stand-in washer.
   Blocked by: none (W7's markers on a stand-in until core/73).
5. **The spray.** `SockSpray` scene and `SockSprayTuning`, the Laundry station's Spray pillar. Real path: use the
   pillar; Socks leave the porthole marker and lie still on the floor by the end; every Collection's MultiMesh drawn.
   Blocked by: none.
6. **The Laundry day.** The bins drawn at New Game (placed in `house.tscn`), `LaundryDay` Part (`load`, refusals,
   pile, the ending's wait), the tally and the fold, the prompts. Real path: in the house with the last Fix set by the
   zoo knob, carry a bin to the washer and click: the tally reads 1/3, the bin is empty in the Hands, a second click is
   refused "That bin is empty". Blocked by: 2, core/71's S2 and S3, core/73's W1 and W2.
7. **The First wash.** Held Socks (S1), `first_wash`, `first_wash.tres` on the frame, the goal line (R2), respawn, the
   once-per-World rule, late join. Real path: a New Game in the house: no Socks lie; click the bin into the washer; the
   cutscene plays; after it the Mess count is the first Stage's, the bin is still full in the Hands, a second bin is
   refused "Fix the washing machine first". Blocked by: 4, 5, 6, core/71's S1, core/73's W2-W4.
8. **The Final wash.** `final_wash`, `final_wash.tres`, `ended`, `WorldRecord.finished`, the load and join rules. Real
   path: with one bin left, click it in; after the cutscene the Final screen is open on both machines and play time has
   stopped. Blocked by: 4, 6.
9. **The Final screen.** The scenes, `FinalScreenTuning`, `final_totals.tres`, the sounds, the skip, the station. The
   screen's look goes in the batch's review sheet (stills of 1, 2 and 4 players, a long name, a leaver) rather than
   stopping, as batch A is built unattended (Q2603); the lead decides. Real path: in the Final screen station press the
   2-player pillar, press a key: both columns' scores show their final Coins and the totals show. Blocked by: 3, 8.
10. **Back to the Lobby.** Continue (any player asks the Host), the Host's save, the game link carries everyone to
    `lobby.tscn`; the finished World as R8 says (its row, its card, what Start or Continue does). Real path: a Guest
    presses Continue; both machines are in the Lobby with the same Roster, and the World's row says what R8 picked.
    Blocked by: 9, core/63.

Later, not tickets yet: the pour made visible (R4 a: its own look ticket after the batch review); who-did-what titles
(R9); the Guide card's two pages (C); the Old Tree's calls and the open Doors (B).

## Gotchas

- `LaundryBin` instances are placed, never spawned: renaming or moving one in `house.tscn` once a build is shared breaks
  saves and the join gate (the layout hash), as for every placed Part.
- The held first-Stage Socks are the generator's records; a Guest gets them in the snapshot only after the reveal.
- The frame hides things from the draw only; a test that counts lying Socks during a cutscene still finds them.

## Choices for the designer (R1-R9)

Each with 2-3 options; **(rec)** marks the recommendation. Nothing here is answered in `docs/migration/decisions.md`.

- **R1. When do the World's bins stand in the house?**
  a) **(rec)** From the New Game, as the old game: all drawn bins full in their rooms, carried any time, refused at the
     machine until the last Fix ("Fix the washing machine first").
  b) Only the bin by the machine at a New Game; the other drawn bins appear in their rooms (a small pop) when the last
     Fix is done, so the Laundry day is a fresh errand and nothing sits about for four Stages.
- **R2. What tells a new player the first goal before the First wash?** (The Guide card's page 1 comes in batch C.)
  a) **(rec)** A goal line in the HUD's top slot, "Wash the laundry" (placeholder), until the First wash; the Stage bar
     takes the slot after; C's Guide page replaces it.
  b) Nothing new: the full bin by the machine and the washer's prompt only, until batch C.
- **R3. The spray and the first Stage's Socks?**
  a) **(rec)** As the old game: the spray is decoration that vanishes; the first Stage's Socks lie in their usual places
     (the Sock generator's) when the cutscene ends.
  b) The spray's Socks stay: they become real Socks of the first Stage lying in the laundry room, and the rest lie in
     their usual places.
- **R4. The bin's pour (old: a tip, a whoosh and the pile; the Socks never seen going in, the tip barely seen in first
  person, Q1907 "later")?**
  a) **(rec)** Ported as the old game in batch A; a visible pour (a short stream of Socks from the bin into the door,
     a tip seen in first person) is its own look ticket after the batch review (Q2153: a look change is its own ticket).
  b) Build the visible pour into batch A's Laundry day ticket now.
- **R5. Does a carried bin slow its carrier?**
  a) **(rec)** No, the normal walk, as the old code (the "slow walk" in Q1820's question never reached it).
  b) Yes: a slower walk, no Sprint, no jump (as the Hamper), a number in `LaundryTuning`.
- **R6. `cutscene_6` opens with "You're alive! And you've got the last ingredient!", written for the return from the Drum
  (batch D). In batch A?**
  a) **(rec)** The whole line, as the old game; it fits again once the Drum comes in D.
  b) From its second subtitle line ("Hey, yeah, awesome!") until the Drum is ported (a start offset on the line).
- **R7. Who has a column on the Final screen?**
  a) **(rec)** Everyone who shelved a Pair this run or is in the game now; one who left is greyed with "(left)".
  b) As the old game: only the players in the game at the end.
- **R8. What the Lobby offers for a finished World (core/61 L6, P36)?**
  a) **(rec)** It is kept as a record: its row and card say "Finished" with its play time; it cannot be continued; Start
     with it chosen (Solo: New Game) asks "Start a new game? The finished World is replaced." and makes a New Game in
     its slot.
  b) Keep tidying: Continue loads the finished house to walk and play freely (no Stages, no ending again); New Game
     replaces it.
  c) It is deleted at Continue: its slot is free and the Lobby is on a New Game.
- **R9. "Who did what" titles on the Final screen (P36, never picked)?**
  a) **(rec)** Not in batch A; asked again with batch B's tallies.
  b) Three titles under the columns from what the run already counts (most Pairs shelved, most bins loaded) plus one new count
     (most Socks thrown), wording placeholders.
