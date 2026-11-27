# Coins and Drawers, the Old Tree and the Upgrade grid

**Status: build plan for batch B (designed in core/120; answered Q2667-Q2672, 2026-11-25; filed by core/123 as
core/124, 129-133).** Behaviour list: `docs/migration/m4-lists/06-coins-drawers-upgrades.md`. Batch B (Q2614) is built
unattended in the order of `docs/migration/milestones.md` "Batch B", then reviewed in play as a whole (Q2603-Q2605). An
open choice an agent meets in the build takes the old game's answer and goes on the batch's review sheet,
`docs/migration/batch-b-review.md` (Q2604).

## What it owns

Both currencies (each player's Coins and the team's Drawers) as decided state, every payout of them (a shelved Pair, a
filled drawer, the two Stage bonuses, Q2667, a late joiner's start, the debug cheat) and every spending of them (an
Upgrade); the Coins and Drawers counters on the HUD with their flying "+N" (a bonus has none: the counter counts up,
Q2668); the Upgrades as data, the `buy` verb and how a feature reads an Upgrade's effect; the Upgrade menu; the Old Tree
as the Upgrade station and as a speaker (its lines, Q2670; its motion waits for its rework, Q2506); the Personal
effects that exist in the port's features (walk, Sprint, grab, carry, Throw, Sock Smarts and Sense) and the Sole cues
(Q2671); what a World keeps of all of it.

It does not own Stage presents, Gifts, their refund's reason or Collections unlocking (core/121), the Wardrobe, the
Profile's Lifetime tallies or Achievements (core/122), the X-rays, the Elevator or the vacuums whose Upgrades wait as
"Coming soon" (batch C, Q2669), the Final screen (core/95, built: it reads what this piece pays). Where they meet it, it
names the seam.

## The shape

Three Parts and some Resources. Inheritance stays one step (Q2251): each is a `Part`.

- **`Bank`** (`game/economy/bank.gd`, a Part, in the level runtime where `Coins` is now: `Runtime/Socks/Bank`). It is
  today's `Coins` Part renamed and grown (core/10, keyed by player id, Q2458): one place for both currencies, so a payout
  or a purchase is one patch. Saved and joined by its State group.
- **`Upgrades`** (`game/economy/upgrades.gd`, a Part beside the Bank): the levels bought, and the `buy` verb. Saved
  and joined by its State group.
- **`OldTree`** (`game/furniture/old_tree.gd`, a Part, a child of the tree's root in `old_tree.tscn`, so `house.tscn` is
  not touched): the station (prompt, outline, `use` opens this machine's menu) and the speaker (`talk`, as the
  washer's Part, `docs/architecture/voice.md` "Co-op").

Everything on screen is a view: the HUD counters and flights, the Upgrade menu, the tree's Looks.

### `Bank`'s state and verbs

| Field | Meaning |
|---|---|
| `coins: Dictionary` | player id -> their Coins (the peer number only while no Roster names them, as `Coins` today) |
| `drawers: int` | the team's Drawers |
| `recent: Dictionary` | not saved (Q2672): player id -> `[[host clock, amount], ...]` of payouts still flying, so the Host can tell the spendable Coins |

No verb pays by itself: every payout is a patch inside another Part's answer, as today (`paid_patch(by, amount)`,
`drawers_patch(amount)`, `spent_patch(by, coins, drawers)`), so a shelve, its Coins, its Drawers and its tallies are
one answer. Its own verbs:

| Verb | Who | What it decides |
|---|---|---|
| `welcome {player}` | Host, when the Roster takes in a player id the Bank has never seen (Session's `linked`) | their Coins = the average of the present players' Coins, rounded down (Q1249); a known id keeps its own |
| `cheat` | Host, debug builds only, the `debug_cheat_coins` action (F9) | +`EconomyTuning.cheat_coins` (1000) into the Host's Coins, no flight, the message "Debug: +1000 {coins}"; a Guest's press asks nothing (Q292) |

Who pays what:
- **A shelved Pair** (exists, `Cabinet._shelve`): `CabinetTuning.pay_for(rarity)` to the shelver.
- **A filled drawer** (new, in the same answer): when a Row's count reaches the World's `pairs_per_drawer` (a short
  last Row never does: Simple's sixth, Sport's third), `drawers += payout`, the payout being `Stage.drawer_payout` of
  the Stage the Cabinet unlocks with (`Cabinet.unlock_stage`): basement 1, ground 1, first 2, attic 3 (`# placeholder:`
  the old by-floor table; the garage's Cabinet unlocks with Stage 2 and stands in the basement, both pay 1). The answer
  carries `drawers_paid: [[drawer, amount]]` for the flight.
- **The Stage bonuses** (both, as the old: Q2667, closing Q2619): in the `open_floor` answer (and the last Fix's, `phase = FIXED`), every
  player in the game `EconomyTuning.floor_bonus` (100); in a shelve answer that leaves a Cabinet's current Rows all
  full, its shelver `EconomyTuning.cabinet_bonus` (50), once per Rows count (`Cabinet.bonus_rows`, a new State field).
  Each bonus is also added to `RunTallies` coins, so the Final screen's "+N bonus" step counts it (core/95 reads
  tallies minus the record's Pair Coins).
- **A Gift refund** (core/121): only when the opener owns every piece a present could hold (Q2673); its open answer
  patches `paid_patch(opener, PresentTuning.refund)` (75) and tallies, and carries `bonus: true` so the HUD shows it
  as a bonus (Q2668).

### `Upgrades`' state and verbs

| Field | Meaning |
|---|---|
| `personal: Dictionary` | player id -> {upgrade id: level} |
| `house: Dictionary` | upgrade id -> level |

| Verb | Who | What it decides |
|---|---|---|
| `buy {upgrade}` | any player, from the menu | refused (`SAYS`) when the id is unknown, `hidden` (co-op only and the game is single player: `Session` alone and not hosting, Q1357, Q1399), `maxed`, `soon` (no `stat`: Coming soon, seen and not buyable, Q1272, Q2669), `locked` (a `needs` entry below its level) or `poor` (the buyer's spendable Coins, the landed ones, Q2672, or the team's Drawers, below the price); else one answer: the Bank's `spent_patch` and the level +1 (Personal: the buyer's; House: the team's) |
| `set_level {upgrade, level, player}` | Host only: the zoo's switches and tests (the old `set_level`) | the level outright, nothing paid |

Refusals read the old words: "Co-op only", "Maxed out", "Coming soon", "Locked", "Need {coins} %d" / "Need {drawers} %d".

**How a feature reads an effect.** `Upgrades.value(stat: UpgradeStat, by: int) -> float`: the stat's value at the sum
of the levels of every Upgrade that names it (Personal ones the player's, House ones the team's: the old
`effect_level`). `Upgrades.of(node)` finds the level's Upgrades Part; a feature in a level without one (most zoo
stations) keeps its own tuning, so the zoo stays as it is. Each feature holds the `UpgradeStat` it reads as a typed
export (a missing file is a load error, not a silent 0), as the voice triggers do.

**The Hands numbers in co-op.** Today a Guest's machine sends its capacity, reach, charge time and Throw speed and the
Host clamps them (D13, `SessionGate.clamped_hands`). With the Upgrades Part the Host computes them from the levels it
keeps; the sent numbers and `HandsTuning.*_most` go (core/130). Every machine reads the same synced levels for its
guesses.

### Signals (every machine, from applied answers): the seams

| Signal | Who plugs in |
|---|---|
| `Bank.paid(player, amount, at_drawer: Node3D or null, bonus: bool)` | the HUD's Coin flight (this machine's player only); core/122's Lifetime "coins_earned" (counted at the decided payout) |
| `Bank.drawers_paid(player, amount, at_drawer)` | the HUD's Drawer flight (the shelver only), the pad's "done" buzz |
| `Upgrades.bought(player, upgrade)` | the menu's refresh, the teammate line "<name> bought <Upgrade>" (Q243), the Old Tree's "bought" moment, any feature whose House level changed (batch C's Elevator, vacuums) |
| `Upgrades.affordable(player, upgrade)` (each machine, for its own player, when an Upgrade becomes buyable) | the Old Tree's "affordable" moment |

## How it is authored

- **`Upgrade`** (Resource, `game/economy/upgrade.gd`): `title` ("Footwork"), `tooltip`, `icon: Texture2D`
  (`assets/ui/upgrade_*.svg`, exist), `section` (PERSONAL or HOUSE), `cell: Vector2i` (row, column of its section's
  grid), `prices: PackedInt32Array` (one per level: the level count), `needs: Dictionary[Upgrade, int]`, `stat:
  UpgradeStat` (empty: its feature is not built, the button says "Coming soon"), `coop_only: bool`, `key_hint` (the
  title's bracket: "hold Shift", "key 1"). Its id is its file's stem.
  **A designer adds an Upgrade by dropping a `.tres` into `game/economy/upgrades/`**: the menu, the zoo's list and the
  `buy` verb find it by `ResourceLoader.list_directory()` (an exported build lists the remapped files too), sorted by
  name; its place on the page is its `cell`. One that changes a number an existing stat already covers needs no code.
- **`UpgradeStat`** (Resource, `game/economy/upgrade_stat.gd`, `game/economy/stats/<id>.tres`): `base: float` (the
  value with no level: the start in a level with an Upgrades Part), `kind` (ADD: base + level x step; SCALE_UP: base x
  (1 + level x step); SCALE_DOWN: base x max(least, 1 - level x step); FLAG: 1 once any level is bought), `step`,
  `least`, `format` (the tooltip's "now -> next": "x%.2f", "%.2fs", "%d"). The old `data/tuning/upgrades.json` numbers
  become the stats' fields, each `# placeholder:` as in the old. A new stat (a new kind of effect) is the `.tres` plus
  one line in the feature that reads it.
- **The 27 ported Upgrades** (16 Personal, 11 House) with the old cells, prices, needs and tooltips (behaviour list
  "The Upgrades"). The House prices are re-scaled by the old rule (Q1405): together 0.9 x the Drawers this house can pay,
  rounded, the old proportions kept, each at least 1. This house pays about 33 (Simple 5, Sport 2, Food 2, Patterns 4,
  Animals 4, Superhero 4, Winter 6, Space 6), so the House prices total about 30 (the old 21 for these eleven,
  scaled); the ticket computes it from the house plan and a test keeps the total within 2 (the old
  `upgrades:house_total`).
- **`Currency`** (Resource, `game/economy/currency.gd`; `coins.tres`, `drawers.tres`): `name`, `icon`, `tint` (the "+N"
  text: white; the House blue `#1e2b55`). Q2610's "names, icons and payouts tunable".
- **Numbers** (typed Resources, one per feature, all `# placeholder:` the old values): `EconomyTuning`
  (`game/economy/economy_tuning.tres`: `floor_bonus` 100, `cabinet_bonus` 50, `cheat_coins` 1000), `Stage.drawer_payout`
  (a new field on the four Stage `.tres`), `CoinFlightTuning` (`game/ui/money/coin_flight_tuning.tres`: hold 0.5,
  pop_in 0.12, burst 0.2, flight 0.45, total 1.5, radius 70 px, icon 34 px, text 56 px, bonus delay 0.35, Drawer rise
  80 px, counter pulse 1.35), `UpgradeMenuTuning` (cell 92 px, gap 8, tip width 360; the button's lift 5 px, grow 1.08,
  glow 0.1 s and refusal shake are AnimationPlayer clips on the button scene, Q2697), `OldTreeTuning` (below).
- **Sounds** (SoundEvents in `sound_catalogue.tres`, the old picks or shares): `coins` (the old cc0 coin, already in
  the catalogue for `final_tick`), `drawer_clack` (shares `drawer_close`), `menu_open`, `menu_close`, `buy`, `refuse`
  (the UI's), `match` (Sole Mates, the first synth candidate at -8 dB as the old). The designer swaps any on the Sounds
  bench.
- **Authored in nodes (Q2658):** `game/ui/money/money_counters.tscn` (an HBox of two `money_counter.tscn`: icon and
  number, on the HUD at the top left), `game/ui/money/coin_flight.tscn` (a Control layer; `flying_icon.tscn` and
  `money_pop.tscn` ("+N" and its icon) instanced per payout from a pool), `game/ui/upgrade_menu/upgrade_menu.tscn` (a
  CanvasLayer: the menu panel, header with the title and a `money_counters.tscn`, two `upgrade_section.tscn` (heading
  icon and title, a GridContainer), the existing `close_button.tscn`), `upgrade_button.tscn` (the holder cell, the
  button, its glow panel, icon box with the lock, level label, price row), `upgrade_tip.tscn` (the keycap card). The
  looks are Theme variations on the one Theme: `UpgradeButtonPersonal` / `UpgradeButtonHouse` with `Off` and `Max`,
  `UpgradeTipPersonal` / `UpgradeTipHouse`, `PriceShort`, `PriceMax`. Code fills them and instances one button per
  Upgrade at its cell and a spacer per empty cell.
- **The zoo:** `game/zoo/stations/economy.tscn` (its own things under `game/zoo/economy/`), built from data at load
  (Q2337): a board listing every Upgrade in the folder (icon, title, section, levels and prices, needs, its stat's now
  -> top; a new `.tres` shows with no other change), an Old Tree that opens the real menu, a small Cabinet (drawer
  capacity 2, its own `CabinetTuning`) with a `SockGenerator` of its Pairs, the station's own Bank and Upgrades, and
  switches: "+100 Coins", "+5 Drawers", "Reset levels", "Co-op" (shows the co-op-only Upgrades). The Stages station's
  mini run already shows the floor bonus. Only core/124 and core/129 edit the station's scene.

## The pieces

### The HUD counters and the flight
`money_counters.tscn` on the HUD shows this machine's player's Coins and the team's Drawers, each minus what is still
flying on this machine (looks only: the Bank holds the decided numbers). `Bank.paid` for this machine's player with a
drawer: the "+N" pops over that drawer's front (0.2 m up; the screen's centre when behind the camera), grows in,
holds, bursts into N icons that fly to the counter in the old timing; each landing pulses the counter's icon and plays
`coins`. `Bank.drawers_paid`: the same with the Drawer icon, 80 px higher, in the House blue, `drawer_clack` on
landing. A teammate's payout moves only the Drawers counter. **A bonus** (`bonus: true`: the floor's 100, the
Cabinet's 50, a Gift refund) shows as the old (Q2668): no "+N" and no flying icons; its Coins land in the counter one by
one, spread over the payout's time as the Coins of a "+N" would, starting `bonus_delay` (0.35 s) later than a "+N"'s
first landing, so the counter counts up, its icon pulsing and `coins` playing per landing (the old `CB:19-27`,
`CB:50-93`). A load or a join shows the totals at once, nothing flying.

### The Old Tree, the station
`OldTree`'s `prompt()` is "The Old Tree" with the E key; the outline goes round the Looks' tree mesh (the kit's outline,
as any Part); `use(by)` opens this machine's `UpgradeMenu` when `by` is its own player (no Command: opening a menu
decides nothing). The menu, while open, freezes the player's input and frees the mouse; the world runs on; Esc or Close
shuts it. The open and close play `menu_open` and `menu_close`.

### The Upgrade menu
Built from the Upgrades folder when it is first opened: per section the listed Upgrades (co-op-only ones left out
alone, Q1357), rows no listed Upgrade stands in closed up. A button shows the icon, "level/top" and the next price with
its currency icon; locked: greyed, the lock over a dimmed icon; no stat: greyed, "Coming soon"; top: the gold frame and
"MAX"; price above the funds: `PriceShort`. Hovered or focused (pad and keyboard per `docs/architecture/ui.md`), it
lifts, grows and glows in its section's colour, and the tip card shows beside it. A click asks `buy`; a refusal shakes
the button and plays `refuse` (the Host's refusal text shows as any refusal). The pad's route is the old true grid.
`Upgrades.bought` and the Bank's changes refresh it while open. The counters in its header are the HUD's scene.

### The Personal effects (core/130) and the Sole cues (core/131)
| Upgrade | Stat (kind, base, step) | Read by |
|---|---|---|
| Footwork | `walk_speed` (SCALE_UP, 1.0, 0.05) | the player's walk (`MoveTuning.walk_speed` x it) |
| Sprint | `sprint` (FLAG) | the new `sprint` action (Shift, pad RT: `input_actions.py add`), x `MoveTuning.sprint_multiplier` 1.3 while held; the corner hint "Sprint [Shift]" once bought |
| Quick Grab | `grab_interval` (SCALE_DOWN, 0.35 s, 0.08, least 0) | the Hands' pick gap |
| Big Hands | `carry` (ADD, 1, 1) | the Hands' capacity (1 to 5, Q1397) |
| Long Arm | `throw_speed` (ADD, 5 m/s, 4) | a full Throw's speed (the Throw stays free and weak, Q1344) |
| Quick Charge | `charge_time` (SCALE_DOWN, 1.2 s, 0.25, least 0.1) | a Throw's charge |
| Sock Smarts, Sock Sense | `sock_smarts`, `sock_sense` (FLAG; Sense needs Smarts) | the HUD's readouts (`PlayerUpgrades` reads them; its zoo toggles stay); wired by core/129 |
| Sole Mates, Sole Hands, Mate Radar | `sole_mates`, `sole_hands`, `mate_radar` (FLAG, House) | a `SoleCues` view on each machine (built in batch B, Q2671): the Teammate's mate Sock outlined in their colour in sight (0.15 s linger), the whole Teammate with Sole Hands, through walls and with edge arrows (the existing `HintArrows`) with Mate Radar; `match` once at their Hands and a brief glow on your own Sock |

### The Old Tree talks (Q2670)
- **No motion in batch B:** the tree's breathing, rustle and bulb flicker and pulse wait for its rework (Q2506, Q2670);
  `looks_old_tree.tscn` is not changed and nothing on the tree moves while it talks. The rework brings the motion as
  Looks (the old `old_tree.gdshader` and an `idle` clip) and an acting resource that keys it; the behaviour list's
  motion lines ("The Old Tree moves and talks") are carried to that rework, not dropped.
- **The speaker:** `game/voice/speakers/old_tree.tres` (priority 10, positional, unit size 2.5 m, max 9 m, earshot
  4.5 m, level band 1.8 m, cooldown 120 s), with no acting; the lines `game/voice/lines/old_tree.json`
  with the old recordings in `assets/voice/old_tree/` (162 lines of the old `data/voiceover/old_tree/`, less those of features not ported: `tip_dirty`, `tip_pairing`,
  `cabinet_grotto`, `hint_grotto`, `floor_grotto`; the old folder holds 161, so 145 are copied, unchanged); the old
  +12.5 dB is applied at playback, as the old player's volume (`OldTreeTuning.voice_db` and `call_db`, the old
  values), so the lines clip only where the old clipped, up close (the lead's reading of Q2638 for a faithful port,
  core/132).
- **Who decides:** the Host (Q2545). Each machine senses for its own player (near: the camera within earshot and
  level band; away 45 s; idle 40 s; an Upgrade newly affordable; the Stage bar's share; a waiting story beat) and asks
  `OldTree.talk {trigger}`; the Host runs the cooldown, `busy` (a cutscene or the washer talking), the chance and the
  picker, and answers the line; every machine plays it from the tree, heard and subtitled only near it. A first visit
  turns `greet` into `first`. The calls (after the first wash, until someone comes near) are the Host's own timer.
- **`OldTree`'s state** (saved): `met: PackedStringArray` (player ids that heard their first line), `tips: Dictionary`
  (player id -> tips said this run), `calling: bool`, `beat: Dictionary` (`comment`: the Fix comment due and not yet
  said; `story`: the story beats waiting; the Host arms a comment on its own clock and lapses either after `beat_hold`),
  `said: Dictionary` (`stage` and `step`: the Stage's thresholds already said). What the tree reads of the house is
  `OldTreeHelp` (the bar's step, the Cabinets with a Row to fill, a loose Mate's floor, the tips due).
- **`OldTreeTuning`** (`game/furniture/old_tree_tuning.tres`, the old `old_tree.json`, placeholders): away 45 s, idle
  40 s, check 0.25 s, beat gap 20 s, beat hold 120 s, beat delay 120-420 s, beat chance 0.75, presents nag 240 s
  (core/121's moment), stage thresholds 0.5/0.8/0.95, grumble and hint chances 0.35, call first delay 20 s, call gap
  25-55 s, call reach 16 m. (The motion's numbers, breath 6.5 s / 4.5 % / 1.2 cm, rustle 1.2 cm at 21, flicker 0.35
  at 1.0, glow 4, pulse 2.2, come with the rework.)
- **Triggers** (`game/voice/triggers/`, kind COMMENT unless said; the data that names them):

| Trigger | Fired by | Named on |
|---|---|---|
| `tree_call` | the Host's call timer, from the First wash's end (core/94's) until a player is near | `OldTree` |
| `tree_first`, `tree_greet`, `tree_idle`, `tree_grumble` (only while the washer is broken) | the near player's machine | `OldTree` |
| `tree_affordable`, `tree_bought` | `Upgrades.affordable` (near now, or on the next visit), `Upgrades.bought` near | `OldTree` |
| `tree_stage_half`, `_most`, `_last` | the near player's machine, the Stage bar's share | `OldTree` |
| `tree_cabinet_<room>` (8) | an idle spell's hint: a Cabinet with a Row of the bar to fill | `Cabinet.tree_hint` on each placed Cabinet (`house.tscn`) |
| `tree_hint_<floor>` (4) | an idle spell's hint: the floor of a loose Mate | `Stage.tree_hint` |
| `tree_part_<floor>` (4), `tree_floor_<floor>` (3) | a Fix's comment, some time into the next Stage | `Stage.tree_part_comment`, `Stage.tree_floor_comment` |
| `tree_tip_throw`, `tree_tip_part` | once per player per run (the Throw from the start; a Part once Stage 1 completes) | `OldTree` |
| `tree_final_wash`, `tree_peace` | story beats (`waits`, skip the cooldown after the beat gap) | `OldTree` (core/96's Final wash, `Stages.machine_fixed`) |
| `tree_presents_ready`, `tree_presents`, `tree_present_taken` | core/121's `Presents` Part (core/137) | core/140 |
| `cutscene_fix_2` | core/92's Fix 2: the tree's line joins the washer's when its recording is dropped (Q2633) | the line's JSON |

A new room, floor or tip is a trigger file, a recording, its JSON entry and the field on the Cabinet or Stage: no code.

## Saves, joins and the Lobby
Nothing writes save code: `Bank`, `Upgrades` and `OldTree` are saved and joined by their State groups
(`docs/architecture/saves.md`); `Cabinet.bonus_rows` joins the Cabinet's state. The save tests' `shape.json` changes
(`Coins` becomes `Bank`, two new parts); no old save needs to load (save compatibility starts at the first outside
play-test). The Coins in flight are looks, never saved. A Guest's Coins and Personal levels wait in the World under
their player id for their next join (as `Coins` today); a new id is `welcome`d.

## Seams to the other pieces
- **core/121 (Gifts, presents):** a refund (only once the opener owns every piece, Q2673) is `Bank.paid_patch` with
  `bonus: true` and a tallies patch in the present's open answer (refund 75 is `PresentTuning`'s); the presents' heap
  is placed round a `PresentSpot` marker the level places beside the tree (`gifts.md`), so `old_tree.tscn` is not
  touched for it; the tree's three present moments are core/121's trigger files and fire calls, on this speaker
  (core/140). If a Gift ever costs Coins, it is a Command whose answer
  carries `spent_patch`.
- **core/122 (Wardrobe, Profile, Achievements):** nothing in the Wardrobe costs (the old: the ten basic pieces are
  owned from the start, Q2679, the others come in presents). The Lifetime "coins_earned" tally counts `Bank.paid` for
  the profile's player at the decided payout (bonuses and refunds included; `wardrobe.md` "Changed technically"). A
  debug cheat's Coins (`cheat`) are not paid through `paid`, so they count in no tally; Achievements count in every
  build (Q1696).
- **Batch A (built):** `Cabinet._shelve` grows the drawer payout and the Cabinet bonus; `Stages.open_floor` and the last
  Fix carry the floor bonus; `RunTallies` takes the bonuses; `RunRecord` stays Pair Coins only; the Final screen's
  totals need no change and get no Drawers total (the old had none; `run-ends.md`'s "batch B adds drawers" was a
  placeholder, not a decision).
- **Batch C:** an X-ray, Elevator or vacuum ticket sets its Upgrades' `stat` (their `.tres` exist with the old
  prices, "Coming soon" until then) and reads `Upgrades.value`; the Old Tree's `tree_tip_vacuum` and
  `tree_tip_elevator` lines come with them (their recordings are copied now, their triggers then).
- **Batch D:** the Drum's fifth Stage gets its `drawer_payout` and tree triggers by its Stage `.tres`; the Drum hatch
  pays nothing (the old).

## Changed technically from the old (no choice: tell the designer at the sitting)
- The flight is looks only; the Host decides the Coins at once. They are spendable only once landed, as the old
  (Q2672): the Host keeps the payouts still flying in `recent`.
- The tree's line is the Host's pick, the same for everyone near (Q2545), not one per machine.
- An Upgrade's effect is data (`UpgradeStat`), not a match in code; the old effect names map one to one.
- The Host derives a Guest's Hands numbers from the levels (no more sent and clamped numbers).

## The designer's answers (Q2667-Q2672, 2026-11-25)
- E1: both Stage Coins bonuses, as the old: +100 to every player when a floor opens, +50 to whoever fills a Cabinet's
  current Rows (Q2667).
- E2: a bonus shows as the old: the Coins counter counts up, no "+N" (Q2668).
- E3: the 16 Upgrades whose features come in batch C show greyed "Coming soon" until then, not buyable (Q2669).
- E4: the Old Tree's voice comes in batch B; its motion waits for its rework (Q2670).
- E5: Sole Mates, Sole Hands and Mate Radar are built in batch B (Q2671).
- E6: Coins still flying are spendable only once landed (Q2672).

## Tickets (filed by core/123)
Build order and waves: `docs/migration/milestones.md` "Batch B". Each builds on graybox where an asset is missing; every
number `# placeholder:` the old.

| Draft | Filed as | Note |
|---|---|---|
| 120-A | core/124 Coins and Drawers: the Bank, the payouts and the HUD counters | both bonuses (Q2667), the counting-up bonus (Q2668), landed-only spending (Q2672) |
| 120-B | core/129 The Upgrades and the menu at the Old Tree | "Coming soon" (Q2669) |
| 120-C | core/130 The Personal Upgrades take effect | |
| 120-D | core/131 The Sole cues | Q2671 |
| 120-E | core/132 The Old Tree's voice | the Looks part dropped: no motion until the rework (Q2670) |
| 120-F | core/133 The Old Tree's help | |

## Gotchas for the build
- `Coins` is referenced by the Cabinet's `coins` export, `LevelRuntime.coins`, `RunTallies`, the Final screen's station
  and tests: rename in one ticket (core/124), keep the group's name `coins` -> `bank` consistent.
- A Row pays Drawers when it reaches the World's `pairs_per_drawer` (the debug slider makes drawers of 2): the last
  Row's short capacity never pays.
- The Cabinet bonus pays again when a Cabinet grows and its new Rows all fill (the old `batch_done` held the Rows count).
- A House Upgrade bought changes every player's numbers at once, a later joiner's too: features read `value()` when
  they use it, never cache it at ready.
- `ResourceLoader.list_directory()` (Godot 4.4+) is needed for the folder of Upgrades to list in an export; DirAccess
  would miss the remapped files.
- The old voice "norman" (Piper, LibriVox) must have its licence checked before a shipping build (Q1575, old ticket 95).
- Co-op-only Upgrades show for a Host before anyone joins (Q1399): "single player" is Solo, not "alone in a session".
