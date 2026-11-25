# The run's ends: the First wash, the Laundry day and the Final screen

**Status: build plan for batch A (designed in core/72; R1-R9 answered Q2624-Q2632; filed by core/74 as core/78,
core/83, core/88-90 and core/93-97, assets/13, and the later pour core/99). Built so far: the cutscene frame, the spray, the
bin, the Laundry day, the First wash ("As built" notes below).** Findings:
`docs/migration/m4-lists/04-first-wash-and-laundry-day.md` (73 old lines). The answers are listed at the end. Written
beside core/71 (Stages, `docs/architecture/stages.md`) and core/73 (the washer and voices, `washer.md`, `voice.md`):
this file names the seams it needs from them and designs none of their parts, except the Cutscene frame, which is
designed here once for all three (below).

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
| `LaundryDay` | Part, one per house: `first_wash` (PENDING, PLAYING, DONE), `drawn`, `loaded`, `ending_left`, `ended`; the Stage bar's `laundry_bins` provider | `game/laundry/` |
| `LaundryTuning` | Resource (`laundry_tuning.tres`): `bins_per_world`, `tip_seconds`, `pile_min`, the hold slot | `game/laundry/` |
| `FirstWashTuning` | Resource: `wash_seconds` (3.0), `bubbles` (40) | `game/laundry/` |
| `SockSpray` + `SockSprayTuning` | effect scene (MultiMesh per Collection) + Resource (the old `spit` numbers) | `game/laundry/` |
| Cutscene frame | `Cutscenes` Part, `CutscenePlayer` (looks), `CutsceneScript` Resource: shared camera, fade, input off, HUD and things hidden, Host skip, respawn | `game/cutscene/`, below |
| `RunRecord` | Part: Pairs shelved `[player id, design, coins]`; B adds pieces and Gifts (built with core/71's tallies, core/83) | `game/run/` |
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
Clamped 1..spots (Q1850, Q1851). Every drawn bin stands full in its room from the New Game and is refused at the
machine until the last Fix, as the old (Q2624).

**Carrying** goes through the shared carry seam (below): left click with empty Hands picks it up; it takes the whole
Hands; right click puts it down at the yaw it is held (the Carriable's `yaw`); right click aimed at a Teammate hands it
over (into empty Hands, else at their feet, "Hands full"); a leaver lays it where they stood; a load lays a carried bin
where it was last laid (the Carriable's `loaded()`). Walk pace: normal; a carried bin does not slow its carrier, as
the old (Q2628).

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
`pile(loaded)` (0, then `pile_min` evenly to 1; seam W2), `socks_pour` plays at the porthole (seam W6). No Socks are
seen going in, as the old (Q2627); a visible pour is the later look ticket core/99.

**The tally:** once the last Fix is done (S2), the Stage bar changes to its Laundry day phase (`StagePlan.after_phase`,
`stages.md` "How it is authored"; Q2621): the old fold (fill 0.25 s, glow 0.25 s, back-ease shrink 0.3 s), then "Wash
clothes n/total" pops in with the bin icon (0.2 s, `pop`). `LaundryDay` is the phase's `laundry_bins` provider; there is
no tally scene of its own. (The old words were "Laundry bins loaded: %d/%d"; the phase's text is the designer's to
change in the inspector.)

**The ending's wait:** the Host counts `ending_left` down in `_physics_process` and asks `final_wash` (Host-only) at 0;
saved, so a load mid-wait asks again.

As built (core/93, `game/laundry/laundry_day.gd`, instanced in `house.tscn` beside `LaundryBins`):
- **State:** `first_wash` (DONE until core/94), `drawn`, `loaded_bins` (not `loaded`: a Part's `loaded()` is the load reset),
  `ending_left`, `final_started` (the stub core/96 replaces with its cutscene and `ended`), `zoo_fixed` (the station's
  stand-in for the last Fix; read only with no `stages`). `whole_state()` carries the Host's live wait.
- **Verbs:** `load` (any player, the washer's click: `Washer.use` asks it; refusals `not_carried`, `first_wash`, `unfixed`,
  `empty`, `busy`, `far`; the three with words are `LaundryDay.SAYS`), `draw` and `final_wash` (Host only), the zoo's
  `zoo_last_fix` and `zoo_final`. The answer carries `bin`; every machine's `_on_applied` tips it and plays `socks_pour`.
- **Reads:** `bins()`, `used_bins()`, `total()`, `fixed()`, `offers(carriable)` (the "Load the washing machine" row, built by
  `Player`), `pile_of(n, of)`; it is in `StageBarPhase.SOURCES` as `laundry_bins` and emits `bar_changed`.
- **Not here:** the Final wash's start (core/96). The First wash's parts are below (core/94).

## The First wash

**Held Socks (seam S1).** At a New Game the first Stage's Socks are laid behind the loading screen as now and kept out
of the Mess, their records held (saved) until told; the house shows none. `LaundryDay.first_wash = PENDING`. Until the
First wash the washing machine looks fine and is silent (no comments, Q2636).

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
the zoo's knob) start and end are one answer. **The first goal** (Q2625): until DONE the Stage bar shows its
`goal_phase`, "Wash the laundry" (placeholder wording; C's Guide card replaces it).

As built (core/94):
- **`LaundryDay`:** `first_wash` is PENDING at a New Game (`wants_first_wash()`, group `first_wash_wanters`: Stages holds
  Stage 1; `goal_pending()`, group `stage_bar_goal`: the bar's goal until DONE; neither in the zoo). A `load` while PENDING
  is the start (`_first_wash_answer`: refused only `busy` or an empty bin): one answer with Stages' `lay_first_answer()`,
  `Cutscenes.start(first_wash.tres)` and `first_wash = PLAYING` (DONE at once with `cutscene` off: the zoo's station, a
  test). The answer carries `first_wash: true`, so no tip and no pour. While PLAYING a bin is refused `busy`. The Host asks
  `first_wash_end` (Host only) once the frame plays nothing: its timeline, its skip, or a load mid-cutscene (the frame is
  not saved). `first_wash_done` on every machine that sees DONE arrive. Save version 2 (the zoo's held Socks).
- **`first_wash.tres`** (`game/laundry/`): `calm_wash("$bubbles")` at 0, `wash_break` at "$wash_seconds", `spray` after the
  line; `numbers` is `first_wash_tuning.tres` (`FirstWashTuning`), `lead_from` its `wash_seconds` (`CutsceneScript.value()`
  and `lead_seconds()` read them).
- **`WasherLooks`:** `calm_wash(count)` (the drum to `wash_spin` over `wash_ramp`, the bubbles, the `wash_calm` loop at the
  machine, the damage held calm, `shot_bob()` for the frame's wide shot), `wash_break()` (`machine_break`, all of it stops,
  the damage released, `room_flickering()`), `door_open(s)`, `door_close(s)`; `set_cutscene(null)` ends them. The graybox's
  `Bubbles` has the old bubble look.
- **The room's flicker:** `Washer` sets `HouseLights.set_flicker(at, room_flicker_range, looks.flicker())` while the Looks
  flickers (the old room.gd fields `flicker`, `flicker_at`, `flicker_range`).
- **`Washer.is_broken()`:** outside the zoo, the level's `first_wash` past PENDING; in the zoo its `broken` switch.
- **The Laundry station:** the "First wash" pillar (`zoo_first_wash`): PENDING, six Socks held in `zoo_held_designs` /
  `zoo_held_poses` round the washer box, let in by the next `load`; the station's Laundry day starts DONE, cutscene off.

**The spray** (`SockSpray`, `sock_spray.tscn`): 500 real Sock meshes (LOD0), Designs drawn from the catalogue with
`seed`, one MultiMesh per Collection, no physics (the old FS step: gravity, bounce 0.35, lie flat when slow); every
number in `SockSprayTuning` (`count`, `speed`, `speed_jitter`, `spread_deg`, `up_deg`, `window`, `length`, `door_open`,
`door_close`, `gravity`, `bounce`, `spin`, `seed`), each `# placeholder:`. Looks only: decoration that vanishes when
it ends; the first Stage's Socks lie in their usual places (Q2626).

## The Final wash and the end of the run

**Start** (`final_wash`, Host-only, from the wait): `ending_left = -1`, the washer's door shut (W2), the cutscene
`final_wash` (`final_wash.tres`): fade in; `happy_wash` for `happy.seconds - fade` (drum to `wash_spin`, bubbles, the
camera pushing from the wide shot to 1 m before the face over the first 40 %); the line of moment `cutscene_final_wash`
(the old `cutscene_6`, played whole, "You're alive!" included, Q2629) with the drum slowing to `after_spin`, the bubbles off a second later, the wide/close
cuts; fade out and hold black.

**End:** `LaundryDay.ended = true` (one answer, saved; the World's record gets `finished`, Q2631); every machine opens the
Final screen over the frozen game; play time stops (`Autosave`'s clock reads `ended`). A load or join with the Final
wash begun but not ended ends it at once.

As built (core/96):
- **`LaundryDay`:** `final_wash` (the wait's end, Host) is one answer: `final_started`, `ending_left = -1` and the
  cutscene `final_wash.tres` on the frame (with `cutscene` off, the zoo or a test, `ended` in the same answer). The door
  shuts (`door_close`) on every machine that sees it begin. The Host asks `final_wash_end` once the frame plays nothing
  (its timeline, its skip, a load or a join after it began): `ended = true`, `play_seconds`. Every machine that sees
  `ended` (arrive or bind) calls `CutscenePlayer.release()`, `Autosave.mark_finished()` and opens
  `LevelRuntime.final_screen` with `FinalSummary.of()` (play time from `play_seconds`); the zoo's Laundry day opens none.
- **`WorldRecord.finished`** (saved): `Autosave` counts no play time once it is set. Core/97 reads it for the Lobby.
- **`final_wash.tres`:** `happy_wash("$happy_bubbles")` at 0, `happy_done` at "$happy_lead", `respawn` off,
  `hold_black` on, `no_voice_seconds` 7; `numbers` is `washer_tuning.tres` (the `happy_*` placeholders).
- **`WasherLooks`:** `happy_wash` (drum to `wash_spin`, bubbles, the wide shot's bob, `shot_push()`, the room's lamps
  within 4 m under `room_flickering()` until the cutscene ends), `happy_done` (drum to `after_spin`, bubbles off a
  second later), `set_voiced(false)` for the old unvoiced look (hop, sway, warm glow, rumble). `CutscenePlayer` lerps
  the wide shot to `Shots/Push` by `shot_push()` and tells the Looks whether a line plays.
- **`Washer.ending()`:** the Final wash has begun: `senses_on()` is false and `could_speak()` refuses.
- **Tests:** `tests/final_wash_test.gd`, `tests/coop_final_wash_test.gd`.

## The Final screen

**`RunRecord`** (a Part, on every machine through the answers): a Cabinet's shelve answer appends `[player id, design,
coins]` (the Coins its shelving paid, Q2610's personal Coins; bonuses excluded), keyed by the Roster's player id
(Q2458), so a leaver's Pairs stay. Saved and in the join snapshot. Batch B adds `pieces` and `gifts` rows.

**`FinalScreen`** (`game/ui/final_screen/final_screen.tscn`, on the one Theme, a CanvasLayer over the frozen game):
the title "Every sock has its mate"; an `HBoxContainer` of `FinalColumn` scenes (`final_column.tscn`: a PanelContainer
whose style takes the player's colour, the name, the Coins icon and score, "n / total Pairs", "+N bonus", a
`SubViewport` Sock stage with an orthographic camera, a pieces strip hidden while empty); the totals row built from
`final_totals.tres`; the unlock strip (hidden while empty; B fills it); Continue. Columns: only the players in the
game at the end, in the Roster's order, as the old (Q2630); a player who left earlier has no column (their Pairs stay
in the `RunRecord` and count in the totals). No "who did what" titles in batch A (Q2632; asked again with batch B).
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
screen, the Session and Roster kept). The finished World is then kept as a record (Q2631): its row and card say
"Finished" with its play time; it cannot be continued; Start with it chosen (Solo: New Game) asks "Start a new game?
The finished World is replaced." (placeholder wording) and makes a New Game in its slot.

## The Cutscene frame (shared; core/88)

The First wash, the Final wash and core/71's Fix scenes are one frame, built once as core/88 (core/72's draft 4 and
core/73's draft 5 merged; the old `RogueMachine` did this with flags, weak point). voice.md gave it to "M5"; batch A
needs it now.

- **`Cutscenes`** (a Part in the level runtime, Host-authoritative): `playing` (the `CutsceneScript`'s path, empty when
  none), `takes` (the take index of each voice line, so every machine plays the same), `serial`. Started by the answer of
  the sequence's own Command (core/92's Fix, core/94's First wash, core/96's Final wash); ended by the Host's timeline or
  a Host-only `skip` Command (Q751). In the join snapshot: a late joiner during it spawns after it at the laundry and
  sees the end state (Q864). Not saved (a load mid-cutscene runs the sequence's own load rule).
- **`CutsceneScript`** (Resource): `beats: Array` of `[time or "after_voice", beat name, args]` (the beats call the
  washer's Looks: `calm_wash`, `break`, `door_open`, `door_close`, `happy_wash`, `spray`; W2); `voice: VoiceTrigger`
  (a CUTSCENE trigger, `voice.md`; empty for none); `lead` (s of beats before the line); `respawn: bool` (false for the
  Final wash); `hold_black: bool` (the Final wash ends on black); `no_voice_seconds` (its length without a line: the old
  5, 5.5, 6.5, 7.5, 8.5, 10 s by level).
- **`CutscenePlayer`** (a node of the level runtime, looks only, every machine): on start it closes open menus, turns
  the local player's input off, hides the HUD and draws no Sock, Pair, item, Laundry bin or avatar (Q1425, Q1426;
  nothing synced changes), cuts to one shared camera at the washer's `Shots/Wide` marker, fades in from black (the
  shared `fade.seconds`, 0.5 s), plays the beats on the clock, then the voice line through `Voices.play_cutscene`
  (lead-in 0.6 s, tail 0.9 s; the music duck is `Voices`'), cutting at each `segment_changed` between the wide and the
  close shot (wide for the first segment, then `index % 2`, the old rule); without a line it holds the wide shot for
  `no_voice_seconds`. The "[Space] Skip" keycap shows bottom right on the Host's screen only (the skip action, the pad's
  Start; Q862, Q1395). At the Host's end: fade to black; unless `respawn` is off, every player respawns side by side at
  the washer's `Spawns` with every knockdown and knockdown wash ended (Q745, Q759); the HUD, input and drawing come back;
  fade in. A Guest whose timeline ends first holds black until the Host's end.

As built (core/88, `game/cutscene/`):
- **Starting one** from a sequence's `decide()`: return (or merge the `changes` of) `LevelRuntime.of(self).cutscenes.start(path)`;
  it draws the takes and refuses while one plays. `path` is a `CutsceneScript` `.tres`, or a CUTSCENE trigger's file played
  plainly (`CutsceneScript.plain`: no beats, the washer's no-voice length for that trigger) as the washer station's
  "Play <trigger>" pillars do (the washer's zoo-only `zoo_cutscene`). `Cutscenes.trigger()` names the one playing.
- **The script** has one field more than above: `after_voice_seconds`, the length of the "after_voice" beats (the spray)
  before the fade. Timeline: voiced `lead + lead_in + Σ(line + tail) + after_voice_seconds + fade`; silent
  `no_voice_seconds + after_voice_seconds` (lead and fade inside). A beat is a method of the washer's Looks, called with
  its args; a missing one is a warning.
- **Numbers:** `cutscene_tuning.tres` (`fade_seconds` 0.5, `lead_in` 0.6); the tail is `VoiceTuning.cutscene_tail`.
- **The player's side:** `Player.set_cutscene(on)` (input off apart from a menu's, HUD hidden), `Player.respawn_at(t)`;
  `Mess.set_drawn(on)` hides every Sock and Pair; the camera's cull mask leaves out the first-person body and held items.
  The washer's Looks gets `set_cutscene(WasherCutsceneLook or null)` when it has it (core/87), and `Washer` writes no mood
  while a cutscene plays. `hold_black`: the end leaves black and input off until `CutscenePlayer.release()` (core/96).
- **The skip** is the input action `skip_cutscene` (Space, the pad's Start).

## Seams this piece needs

From **core/71** (Stages):
- **S1** a New Game's first Stage's Socks laid at load but held out of the Mess (saved while held) until a patch reveals
  them; nothing in the house until then.
- **S2** the last Fix done (the machine fixed): a state the Host reads in `decide()`, and its cutscene's end as an event.
  The last Stage is the last of the Stage list, so batch D's Drum slots in before the Laundry day with no change here.
- **S3** the Stage bar's phases (`StageBarPhase`, core/82): `goal_phase` before the First wash, `after_phase` in the
  Laundry day with `LaundryDay` as its provider.
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

(Each seam is built by the ticket that owns its side: S1 core/77, S2 and S4 core/76, S3 core/82, S5 core/92; W1 and
W6 core/86, W2 core/86 and core/87, W3 core/87 and core/94, W4 core/84, W7 core/86.)

For later batches (named, not built here): `first_wash_done` starts B's Old Tree calls; B's New Game opens the Doors
between the laundry and the garage; C's Guide card takes page 1 / page 2 from `first_wash`; B fills the Final screen's
pieces, Gifts, Drawers and unlock strip and counts the Profile's finished game; D's Drum is the Stage before the
Laundry day.

## The zoo stations (built from the data at load, Q2337)

- **`game/zoo/stations/laundry.tscn`** (made by core/89's spray pillar): the real washer once core/86 lands (a stand-in
  box with its markers before) and one
  `laundry_bin.tscn` per candidate kind of spot; pillars: "Last Fix done" (a switch, sets S2's state through a zoo-only
  Command), "First wash" (resets `first_wash` to PENDING and holds a few Socks), "Spray" (plays `SockSpray` alone with
  the current `SockSprayTuning`), "Final wash" (all but one bin loaded); a label shows `loaded/total` and the phase. The
  Sock previews use the catalogue's Designs, so a new Design shows in the spray with no change.
- **`game/zoo/stations/final_screen.tscn`**: pillars for 1, 2 and 4 players open the Final screen on a made-up
  `RunRecord` drawn from the catalogue at load (every Collection's Designs, rare ones included), and one whose record
  holds a player who left (no column; their Pairs in the totals).

## What is reused

Reused as it is: `Carriable` (`game/parts/carriable.gd`), Hands' refusals and the drop's place check, the Hand-off's aim,
`Coins` (the shelve pays as now), the Cabinet's shelve answer (one line appends to `RunRecord`), `WorldRecord`
(`play_time`, `seed`; adds `finished`), `GameLink` and the Lobby's Start handshake (reversed for Continue), the sound
catalogue, `HoldAnchor`-style hold slots, the Theme and `KeycapStyle`. New: everything in "The shape". Old code not
carried over: the `socks_mode()` branch, `RogueMachine`'s flag timelines, the flat Sock rows, the code-built screen.

## Tickets (filed by core/74)

| Draft | Ticket |
|---|---|
| 1 Carried things in the Hands | core/78 (shared with core/71's Machine Parts) |
| 2 The Laundry bin entity | core/90 (the ported model split out as assets/13) |
| 3 The run record | core/83 (with core/71's tallies: the same shelve answer) |
| 4 The Cutscene frame | core/88 (merged with core/73's draft 5) |
| 5 The spray | core/89 |
| 6 The Laundry day | core/93 |
| 7 The First wash | core/94 |
| 8 The Final wash | core/96 |
| 9 The Final screen | core/95 |
| 10 Back to the Lobby | core/97 |

Later: the visible pour, core/99 (`priority: later`, look work, Q2627). Not tickets: who-did-what titles (asked again
with batch B, Q2632); the Guide card's two pages (C); the Old Tree's calls and the open Doors (B). The order and waves:
`docs/migration/milestones.md` "Batch A".

## Gotchas

- `LaundryBin` instances are placed, never spawned: renaming or moving one in `house.tscn` once a build is shared breaks
  saves and the join gate (the layout hash), as for every placed Part.
- The held first-Stage Socks are the generator's records; a Guest gets them in the snapshot only after the reveal.
- The frame hides things from the draw only; a test that counts lying Socks during a cutscene still finds them.

## Answers (R1-R9, 2026-11-24)

- R1 The bins stand full in their rooms from the New Game, refused until the last Fix, as the old (Q2624).
- R2 A goal line "Wash the laundry" in the Stage bar's place until the First wash; the Guide card replaces it in C (Q2625).
- R3 The spray is decoration that vanishes; the first Stage's Socks lie in their usual places (Q2626).
- R4 Loading stays as the old, no Socks seen going in; a visible pour is a later polish ticket (Q2627; core/99).
- R5 A carried bin does not slow its carrier (Q2628).
- R6 cutscene_6 plays whole, "You're alive!" included (Q2629).
- R7 A Final screen column only for the players in the game at the end, as the old (Q2630).
- R8 A finished World stays in the Lobby as a record, not continued; Start or New Game asks and replaces it (Q2631).
- R9 No "who did what" titles in batch A (Q2632).
