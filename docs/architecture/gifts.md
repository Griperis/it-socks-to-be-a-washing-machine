# Gifts, Collections and the encyclopedia

**Status: build plan for batch B (designed in core/121; answered Q2673-Q2678, 2026-11-25; filed by core/123 as
core/125, 126, 134-140 and assets/16-17).** Behaviour list: `docs/migration/m4-lists/07-gifts-and-collections.md`.
Batch B is built unattended in the order of `docs/migration/milestones.md` "Batch B" (Q2603-Q2605); its neighbours are core/120 (Coins and Drawers, the Old
Tree, the Upgrade grid: `docs/architecture/economy.md`) and core/122 (the Wardrobe, its pieces, the Profile and
Achievements: `docs/architecture/wardrobe.md`). The seams to both are named at the end; neither piece is designed here.

## What it owns

- **The Collections as data:** each Collection's name, colour, Cabinet name, icon and wrapping in one Resource, and the
  rule that unlocks Collections across games.
- **The New Game's draw** of each Cabinet spot's Collection from its pool.
- **A Collection completing** during a Stage (noted, no show).
- **Stage presents:** dropped under the Old Tree when a Stage completes, picked up, carried, put down, opened, revealed.
- **The encyclopedia:** recording the Designs a player has seen shelved, its pages on the title and in the house's book.
- What a World and the player's profile keep of all that.

It does not own: the pieces, what a player owns or wears, the Profile's file, its version and its Lifetime tallies
(core/122); Coins, the Old Tree as a thing, its menu and its voice (core/120); the Stages, the Final screen's frame
and the Hands (batch A, used through the seams below).

## The shape

```
game/collections/            Collections as data, the unlock rule, the draw, the encyclopedia record
  sock_collection.gd           SockCollection (Resource): one Collection
  <id>.tres                    17 files, one per Collection (simple.tres ... lost.tres)
  collections.gd               Collections (static): every SockCollection in the folder, in catalogue order
  collection_unlocks.gd/.tres  CollectionUnlocks (Resource): the start set, the order, how many a finished game unlocks
  cabinet_draw.gd              CabinetDraw (RefCounted rules): fills every spot from its pool
  profile_recorder.gd          ProfileRecorder (Node, every machine, in run.tscn): the encyclopedia and the unlocks
game/gifts/                  Stage presents
  present.tscn                 one present: Carriable + Present (Part) + its Looks
  present.gd                   Present (Part): whose, which piece, which Collection; the open verb
  presents.gd                  Presents (Part, in run.tscn): the drop verb and the heap
  present_draw.gd              PresentDraw (RefCounted rules): which piece each player gets
  present_tuning.gd/.tres      PresentTuning (Resource)
  looks_present_graybox.tscn   the box until the model (assets, assets/16): Box, Box/Lid, Glow, Sparkle, Tag, AnimationPlayer
  present_opening.tscn         the opened box's last second on every machine (shake, pop, burst), then gone
  gift_paper.gdshader          the old wrapping shader, ported
  gift_reveal.tscn/.gd         the opener's reveal (a CanvasLayer authored in nodes)
game/parts/spawned_parts.gd  SpawnedParts (Part): Parts made during play (a present), through a MultiplayerSpawner
game/ui/encyclopedia/        encyclopedia.tscn (the pages), encyclopedia_cell.tscn, encyclopedia_menu.tscn (the book's)
game/entities/encyclopedia_book/  the book: its scene, Looks (the old glb, assets/17)
```

Inheritance stays one step (Q2251): `Present`, `Presents` and `SpawnedParts` extend `Part`; nothing extends
`Carriable`. A present is a scene with a `Carriable` and a sibling `Present` Part, as the Machine Part is a scene with a
`Carriable` (core/79).

## Collections as data

**`SockCollection`** (Resource, one `.tres` per Collection in `game/collections/`, edited in the inspector):
`id: StringName`, `name` ("Simple"; the 2026-11-19 names, Q1954), `colour` (the pairing moment's sparkles, the old
designs.json colour), `cabinet_name` ("Simple cabinet"), `icon: Texture2D` (`assets/ui/<id>.svg`), the wrapping
`paper`, `ink`, `bow` (the old `wrapping.json` values; a transparent colour falls back to the old rule: paper = colour
lightened 35%, ink darkened 25%, bow = colour), `held_back: bool` (on only for the Lost Socks, whose home is the Drum
of batch D, Q2675: a held-back Collection is in no encyclopedia page, start set, pool or present, and its pieces are
not in the Wardrobe's rows or its "N/M", Q2683; the Drum's ticket switches it off). `Collections.all()`
lists the folder with `ResourceLoader.list_directory` (export-safe) and orders it as `DesignCatalogue.collections()`;
`Collections.of(id)`. **A designer adds a Collection** by its Designs in `designs.tres` and one `.tres` here: no code.
`DesignCatalogue.collection_colours` and `cabinet_names` go; `collection_colour()` and `cabinet_name()` keep their
signatures and read the Collection files, so no caller changes. Dirty has no file (not ported).

**`CollectionUnlocks`** (Resource, `collection_unlocks.tres`): `start: Array[StringName]` (Simple, Sport, Patterns,
Animals, Superhero, Winter, Nature, Food: Q1439 without the Lost Socks, Q2675), `order: Array[StringName]` (Space, Fruit, Machinery,
Drinks, Tech, Vegetables, Transport, Math: Q1465), `per_finished_game := 1` (Q1440). `next_after(unlocked) ->
Array[StringName]`. **A designer changes the start set, the order or the count** in the inspector; a new Collection
unlocks by adding its id to `order`. The old "modes" layer is dropped with wash cycles (Q1464, Q2602).

## The New Game's draw (pools)

- **`Cabinet.pool: Array[StringName]`** (an export on each placed Cabinet, edited on the instance in `house.tscn`;
  empty: the Cabinet keeps its placed `collection`, as every zoo station does). The house's eight get the old room
  pools (laundry `[simple]`, garage `[machinery, transport, sport, tech]`, kitchen `[fruit, vegetables, drinks, food]`,
  living `[patterns]`, both kids' `[animals, nature, superhero, space, math]`, both loft `[winter, space, nature, tech]`).
  Pools on the placed thing replace the old JSON keyed by spot and room: the spot is the Cabinet.
- **`CabinetDraw`** (rules only): `draw(spots: Array[Cabinet pools], unlocked, rng) -> Array[StringName]` picks one
  unlocked Collection per spot, never one twice, solving the shared pools by backtracking (the old `CPO:193-262`);
  `problems()` names why a draw cannot fill them (too few unlocked).
- **`Stages.start`** (core/76's Host verb) runs it first, with the Host's own unlocked Collections (its profile,
  Q1440) and the World's seed, and puts each Cabinet's `collection` patch in the same answer, before the Stage's
  Designs are chosen, so Stage 1's Socks and every later spawn are the run's Collections only (Q1228). `Cabinet.collection`
  is already saved State, so the draw is in the World and the join snapshot with no new field. A Cabinet whose
  `collection` changes in an answer swaps its Looks (`dress()`, which today runs only at ready). An unfillable draw
  logs an error with the reason and the placed Collections stand (never a broken run).
- `Cabinet.unlock_stage` already is the old `hidden_until` (Q1463).

## A Collection completes

`Stages` gains `completed: Array[StringName]` (State, saved, in the snapshot), emptied by `open_floor`. The Host's
`Stages` already looks after every applied shelve (to ask `complete`); it also asks a Host-only `note_complete` verb when a
Cabinet of the bar is complete (every Drawer unlocked and full, or every Design of it in play shelved, the old
`CB:61-69`) and not yet noted. Its answer appends it and carries a `collection_completed(collection, by)` Stage event:
the completer's pad buzzes (a `RumbleCue` "done", as the Drawer's) and core/122's Lifetime tally counts it. No banner,
no confetti, no Coins (Q1602).

## Stage presents

### A present is a spawned scene

Presents are made during play, so they come through Godot's spawner (the port's rule): **`SpawnedParts`** (a Part under
`Run`, with a `MultiplayerSpawner` child whose `spawn_function` builds a scene from `{scene, id, states}`) holds the
rows of what it spawned. Its Host verbs' patches add or remove rows; the spawner creates or frees the node on every
machine, a late joiner gets the live ones from the spawner, and `Parts.adopt(node)` / `Parts.release(node)` bind the
spawned node's Parts by path (`Run/Spawned/Present<id>/...`) as `Parts.bind` does for placed ones. The save and the join
snapshot keep each row with its Parts' states (the coop-structure's "spawned things store {scene, spawn_seq, state}");
a load spawns the rows before the states are written. Batch C's bought devices reuse it.

**`present.tscn`**: root `Present<id>` (Node3D); `Carriable` (`title` "Present", `handable` off: a right click aimed
at a Teammate puts it down at the crosshair, as the old never handed one over; never thrown; `slot`
`present_hold.tres`: body frame, 0.95 m up, 0.5 m out, the old hold); `Present` (Part, State: `for_player: String`
the Roster's player id, `piece: StringName`, `collection: StringName`); `Looks` (the box). `Present` is the Carriable's
pick guard: `Carriable` asks a sibling in the group `carry_guards` for `pick_refusal(by) -> StringName` (empty: allowed;
`&"not_yours"`: refused silently) and `aimable_by(by) -> bool` (the aim and the outline skip a Teammate's box): one
small seam on `Carriable`, which Present fills. "Hands full" is the Carriable's own refusal.

### The drop

**`Presents`** (Part in `run.tscn`, `presents.gd`; State `next_id`): on the Host, at `stage_completed` (Stages'
signal), it asks its Host-only `drop` verb. `drop` reads `Stages.completed`, the Session's present players (the
Roster), each one's owned pieces (core/122) and the pieces already waiting in lying presents, and asks **`PresentDraw`**
(rules only, the old `GI:79-140`): for each player, for each completed Collection with pieces, one piece of it they
lack and do not have waiting, a piece of rarity RARE weighing `rare_weight` (0.25) against 1. **When they own (or have
waiting) every piece of it** (Q2673, replacing Q1609): one piece they lack of another unlocked Collection, by the same
weights over all the lacked pieces of every unlocked Collection that is not held back; only when they lack no piece of
any of them: any piece of the completed one, whose opening pays the refund (75 Coins). "Unlocked" here is the Host's
unlocked set, the one the New Game's draw used (the only set the Host knows; the lead's reading, on the review
sheet). The box is wrapped in the completed Collection's paper whatever piece it holds (the Stage earned it; the lead's
reading, on the review sheet). The answer is `SpawnedParts` rows, one per present, each at a spot of the heap (the run's
record counts a present only when it is opened). No Collection completed, no present, so the first presents come after
Stage 2 (Q2678; Stage 1 cannot complete Simple).

**The heap** (`Presents.heap_spots(n, lying)`): round a **`PresentSpot`** Marker3D placed by hand at the Old Tree's south
foot (the old first clear `tree_spots` entry, Q1605) under `Run` in the house and in each station that drops presents:
the free spots of a hex grid `apart` (0.42 m) across turned at random, nearest first, at least 0.9 x `apart` from a box
already lying, nudged 5% at random (the Host's rng): the old `GI:202-226`. The marker replaces the old search of 13
offsets clear of walls, furniture, Cabinets and Hampers (weak point). Placing it is the level's author's job; it is not a
child of the Old Tree's scene, so core/120 may rework the tree freely.

**The Machine Part's pop spot** (core/79's `complete`): the pop spot moves to the nearest hex spot clear of any lying
present, the same `heap_spots` with the lying presents (the old `CA:439-479`; batch A's carried item).

### The box's Looks (an AnimationPlayer, as every entity)

`looks_present_graybox.tscn` (contract for assets/16's model): `Box` (body, ribbon cross; the paper's surfaces use
`gift_paper.gdshader`), `Box/Lid` (lid, ribbon, bow), `Glow` (a quad with a radial `GradientTexture2D`, 2.6 box sizes),
`Sparkle` (a particles node: 10 specks, 1.2 s, rising), `Tag` (Label3D, the old style, hidden solo and while carried),
`Burst` (a one-shot particles node, 18 specks, at the landing), and an AnimationPlayer:
- `drop`: from 1.4 m, 0.5 s, bounce ease out, `Burst` at the end (the old `GV:84-92`).
- `lying` (loop): a turn of 1.2 rad/s and a bob of `0.04 * (0.5 + 0.5 sin(2.4 t))` m; one 2π/1.2 s loop holds one turn
  and two bobs, so it wraps seamlessly; each present starts at its own phase (`id`), as the old `+ id`.
- `RESET`: held (no turn, no bob, glow and sparkle off).
The wrapping (paper, ink, icon, bow) is set from the present's `SockCollection` in `_show`; tiles 2 and ink strength
0.85 are `PresentTuning`'s. **What is authored:** the clips' keys in the editor; the numbers that are not keys
(`rare_weight`, `refund`, `apart`, `shake`, `preview`, `tiles`, `ink_strength`) in `present_tuning.tres`
(`# placeholder:` the old values).

### Opening

`Present.open` (verb, asked by the carrier's second left click, the Hands' click routing for a carried thing that
`Carriable` already has, core/78): the Host decides that the asker is `for_player` and holds it. The answer removes the
present's `SpawnedParts` row, writes the opener's refund into the `Bank` (core/120's seam, a bonus) when they own the
piece (they owned every piece, Q2673), puts `Roster.owned_patch(by, piece)` in for a new piece (core/122's seam, so
the Host's owned list grows with no extra ask), appends `[player id, piece]` to `RunRecord.pieces` (a new piece only) and counts `RunRecord.gifts_opened`, and
carries `present_opened(by, piece, refund, collection, at)`. On every machine, before the node goes, its `Looks` is
handed to a **`present_opening.tscn`** effect that follows the carrier's hold point and plays the `open` clip: the old
wobble (5 Hz quickening by 3 Hz, 0.04 to 0.3 rad by 70%), the crouch, the 0.45 box hop, the lid's flight and the
shrink, the 28-speck burst, the `gift_rattle` at the box; scaled to `shake` (1.0 s) by its speed, then freed. On the
opener's machine the world box only rattles and vanishes (as the old) and **`GiftReveal`** opens: a CanvasLayer scene
(`gift_reveal.tscn`, on the Theme) with a 520 x 520 `SubViewportContainer` holding core/122's `preview_stage.tscn`
(its light and camera; a turntable node, a box Looks instance playing `open` at 1.6 x), and a `Caption` VBox of three Labels (name, Rarity, "New in your Wardrobe" or
"Already yours: +%d Coins") with Theme variations; code only fills them and puts the piece's preview (core/122) on the
turntable after the pop (0.35 s back-out pop-in, 1.6 rad/s, a Trail 0.5 rad/s tipped -0.6). It stays `preview` (3.0 s);
any click or pad face button then closes it and is consumed; during the shake a click is consumed and does nothing; the
player may walk. The opener's own machine then writes a new piece into its profile (core/122's `unlock_piece`).

**The Final screen** (run-ends' seams): `RunRecord` gains `pieces` and `gifts_opened` (its batch B rows); each
`FinalColumn`'s pieces strip shows its player's pieces (core/122's preview, fitted); two `FinalTotal` Resources,
`gifts_opened` ("Gifts opened") and `pieces_won` ("Wardrobe pieces won"), join `final_totals.tres`: no screen change.

### Prompts and sounds
Aimed own present: the outline and "[LMB] Pick up"; carried: "[LMB] Open" and "Drop [RMB]" (Q2677: the old showed only
the outline and "Drop [RMB]"). A Teammate's present is not aimed (no outline, no row).
Sounds as SoundEvents in the catalogue with the old picks: `pick` on the pick-up and the open (placeholder), `drop` on
the put down, `gift_rattle` (the first synthesised candidate; the designer picks on the bench). The landing is silent.

### The Old Tree's lines (core/120's speaker)
The presents fire three VoiceTriggers this piece adds (`game/voice/triggers/presents_ready.tres`, `presents.tres`,
`present_taken.tres`, COMMENT kind, the Old Tree's speaker); `Presents.waiting_for(player_id) -> int` and the signals
`presents_dropped(players)` and `present_taken(by)` (a Carriable pick of a present) are what the tree's director reads
for "near". The eleven old lines (`VO tree_presents*`, `tree_present_taken*`) go into the Old Tree's line file
(Q2640) with the rest of its lines (core/132: the tree's voice is batch B, Q2670); core/140 adds the three triggers, the
two signals and their moments in the tree's director.

## The encyclopedia

**Recording.** `ProfileRecorder` (every machine, in `run.tscn`): an applied shelve answer adds its Designs to the
local player's profile `designs` (core/122's file; this piece's field); a World loaded by its Host (or Solo) adds the
Cabinets' shelved Designs (they were in that World); a Guest adds only what is shelved after it joined (Q1197: a
snapshot emits nothing). It writes the profile through core/122's save (coalesced, not per Pair).

**Unlocking.** The same recorder, when the Laundry day's `ended` is applied (the run finished, run-ends), unlocks
`CollectionUnlocks.next_after(profile.collections)` into the local profile and hands them to the Final screen's unlock
strip (`FinalScreen.unlocked_strip()`): a heading ("New Collection unlocked" / plural) and one `unlock_cell.tscn` (icon
96 px, name) per Collection, each popping in after the totals with the old timings (`FinalScreenTuning` already holds
the unlock reveal) and a `pop` cue; a skip shows them at once.

**The pages.** `encyclopedia.tscn` (a Control authored in nodes on the Theme): a header row (`Prev` "<" and `Next` ">"
buttons, 80 px, wrapping round; the Collection's `Icon` 48 px; `Title` "Simple (1/3)"; `Count` "37 / 130") and a
`Page` holding a `SockStage` (a SubViewport with an orthographic camera, 400 px a metre) under a `Cells` GridContainer of
10 columns; code instances one `encyclopedia_cell.tscn` (150 x 124: the name Label, 14 px, and the existing
`size_box.tscn` badge) per Design and puts each Design's Sock (its Looks, fitted to 0.34 m) behind its cell in the
stage, a collected one in its own look, an uncollected one with `silhouette.tres` (unshaded, the UI ink colour) and
"???". Pages: one per unlocked Collection that is not held back, in catalogue order, 50 a page, sorted small, medium,
large then catalogue order; names are the catalogue's (they already carry their colour where shared, Q1198).
- **On the title:** a 72 x 72 corner key (`menu_encyclopedia`, tooltip "Sock encyclopedia") left of the Licence key
  opens an Encyclopedia page of the title (`title.tscn` gets the key and the page; the key is the old Q1195, the "later"
  of Q2562).
- **In the house** (Q2676): `encyclopedia_menu.tscn` (a CanvasLayer, the cream panel style, the same pages) opened by E
  while the book is the active Hands item; the player frozen and the mouse free, the world running; arrows, A / D,
  Left / Right turn; E or Esc closes; it closes when the book leaves the Hands.

**The book** (batch B, as the old, Q2676): `game/entities/encyclopedia_book/encyclopedia_book.tscn`, placed by hand on the workshop's
workbench in the house: a `Carriable` (title "Sock Encyclopedia", `handable` on, never thrown) whose new export
`one_slot` makes it a Hands item in one slot instead of the whole Hands, listed and cycled with the Socks and Pairs (the
seam batch C's guide card reuses); E reads it ("Read" in the hints). Its Looks is the old glb (assets/17). Saved and in the
snapshot as every Carriable; a New Game puts it back on the bench.

## The save

- **The World** (each Part's State, `docs/architecture/saves.md`): `SpawnedParts` rows (every present: its Carriable's
  holder, place and turn, its Present's player, piece and Collection; a carried one laid where it would lie, as every
  Carriable on a load, Q2559-Q2560), `Presents.next_id`, `Stages.completed`, each `Cabinet.collection` (the draw), the
  book's Carriable, `RunRecord.pieces` and `gifts_opened`. A New Game starts with none of them (unopened presents lost,
  Q1601). Each Part's version steps as Q2557 says.
- **The profile** (core/122 owns the file, its version and its cloud sync, Q2565; one ticket, core/127, writes every
  batch B field of it): this piece's fields are `designs: PackedInt32Array` (the encyclopedia, sorted ids) and
  `collections: Array[StringName]` (unlocked; a new profile starts with `CollectionUnlocks.start`).

## Co-op

The Host decides the draw, the drop, a pick, a put down and an opening; every machine sees the presents, the labels,
the shakes and the pops; only the opener sees the reveal. Presents are keyed by the Roster's player id (Q2458), so a
player who leaves and comes back finds their presents still lying for them (the old keyed them the same way). A joiner
mid-run is owed nothing for Stages before (Q1603). The draw needs each present player's owned pieces on the Host:
core/122's sync of the profile's pieces (the old sent them in the join, unchecked).

## Zoo stations (built from the data at load, Q2337)

- **`game/zoo/stations/collections.tscn`** (new, core/125): one row per `SockCollection` from `Collections.all()`: icon,
  name, colour swatch, Cabinet name, wrapping swatches (paper, ink, bow) and a wrapped graybox present once core/137 lands,
  whether it is in the start set or its place in the unlock order; a switch per Collection toggles its unlock in the
  zoo's profile (Q1441). A new Collection file shows with no other change.
- **`game/zoo/stations/gifts.tscn`** (new, core/126 makes it, core/137 fills it): an Old Tree stand-in with a `PresentSpot`;
  switches (zoo-only Commands under `game/zoo/gifts/`): "Drop presents" (one per player for a Collection picked on a
  dial), "Complete a Collection"; each Collection's pieces (core/122's) laid out beside its wrapped box. The real-path
  cases of core/137 and core/138 run here and on the Stages station's mini run.
- **The Stages station's mini run** gets a `PresentSpot` and pools on its Cabinets (core/135, core/137), so a whole Stage ends
  in presents.
- **The Final screen station's** pillars get pieces and an unlock in their made-up records (core/138, core/134).
- **An Encyclopedia pillar** on the Collections station opens the pages on the zoo's profile (core/136).

## Seams

| Seam | Other side | What crosses |
|---|---|---|
| S-122a pieces by Collection | core/128's `Wardrobe` | `Wardrobe.pieces_of(collection) -> Array[WardrobePiece]` (`id`, `name`, `slot`, `rarity`; RARE weighs `rare_weight`); `piece_name(id)` |
| S-122b owned pieces on the Host | core/141's Roster | `Roster.owned_of(player_id) -> PackedStringArray` for every present player (the ten basic pieces count as owned, Q2679) |
| S-122c a piece won | core/141's Roster, core/127's profile | the open answer carries `Roster.owned_patch(by, piece)`; the opener's machine calls `unlock_piece(id)`; the Wardrobe offers it |
| S-122d a piece's preview | core/128's `Wardrobe.preview` and `preview_stage.tscn` | `preview(id, tint) -> Node3D` for the reveal's turntable and the Final screen's strip (a hat or clothes model, Socks on feet in the tint, a Trail's live sample) |
| S-122e the profile file | core/127's `player_profile.gd` | two fields, `designs` and `collections`, in its versioned shape; its coalesced save |
| S-122f Lifetime tallies | core/127's `TallyRecorder` | the `collection_completed` Stage event (counted by core/137, which makes it) and batch A's `stage_completed` |
| S-120a the refund | core/124's `Bank` | the open answer writes `Bank.paid_patch(by, refund)` marked a bonus (the counter counts up, Q2668; the Final screen's "+N bonus") |
| S-120b the Old Tree's lines | core/132's tree voice | three VoiceTriggers, `Presents.waiting_for()`, `presents_dropped`, `present_taken` (core/140) |
| S-120c the tree's place | core/120's Old Tree | none: the `PresentSpot` marker is the level's, beside the tree |
| run-ends | core/95's Final screen, RunRecord | `pieces`, `gifts_opened`, two `FinalTotal`s, the unlock strip |
| stages | core/76's `start`, core/79's pop spot | the draw's Cabinet patches before the Stage's Designs; `completed`; the pop spot clear of presents |
| hands | core/78's `Carriable` | the `carry_guards` seam (pick refusal, aimable); `one_slot` for the book (Q2676) |

## The designer's answers (Q2673-Q2678, 2026-11-25)
- G1: a present whose Collection the player already owns whole gives a piece of another unlocked Collection they lack;
  Coins (75) only once they own every piece (Q2673, replacing Q1609).
- G2: each player picks up and opens their own present whenever they like, as the old: that is what "opened together"
  (Q2612) means (Q2674).
- G3: the Lost Socks belong in the Drum (batch D); until then they are left out of the encyclopedia, the start set and
  presents (Q2675); their six pieces are hidden from the Wardrobe and its "N/M" (Q2683).
- G4: the encyclopedia book stands in the house in batch B, as the old; batch C's guide card reuses its one-slot Hands
  item (Q2676).
- G5: "[LMB] Pick up" aimed at your own present, "[LMB] Open" while carrying it (Q2677).
- G6: the first presents come after Stage 2, as the rules fall out (Q2678).

## Tickets (filed by core/123)
Build order and waves: `docs/migration/milestones.md` "Batch B". Every core ticket builds on graybox Looks; the asset
tickets stop at their first line-up and swap in on the designer's yes.

| Draft | Filed as | Note |
|---|---|---|
| 121-A | core/125 Collections as data | `held_back` (Q2675) instead of `in_encyclopedia` |
| 121-B | core/126 Spawned Parts | |
| 121-C | core/137 Presents under the Old Tree | the G1 draw (Q2673), G5's hints (Q2677), the Machine Part's pop spot (batch-a-review question 4) |
| 121-D | core/138 Opening a present and the reveal | the reveal's stage is core/128's `preview_stage.tscn` |
| 121-E | core/135 Cabinet pools and the New Game's draw | |
| 121-F | core/134 The encyclopedia record and Collections unlocking | its two profile fields move into the one profile ticket, core/127 |
| 121-G | core/136 The encyclopedia pages and the title's key | |
| 121-H | core/139 The encyclopedia book in the house | Q2676 |
| 121-I | core/140 The Old Tree's present lines | the lines themselves come with core/132 |
| AS-B1 | assets/16 The present box | |
| AS-B2 | assets/17 The encyclopedia book | |

## Gotchas for the build

- A Collection completes only once per run; `completed` is per Stage and empties when the next Stage begins.
- The draw must patch the Cabinets before `stage_designs` runs in the same `start` answer.
- A present waiting in a box counts as "had" for the next draw (no second copy while one waits).
- The opened box's last second is a looks-only effect: the save never sees an opened present.
- The reveal consumes the clicks that close or skip it; nothing behind it picks up.
- A spawned Part's state may reach a Guest before its node (snapshot vs spawner order, coop-structure line 205): wait
  by id.
- Lost Socks (Q2675, Q2683): `held_back` on, not in `start`, no pool names it; everything that lists Collections or
  pieces asks `held_back` and nothing else special-cases it. The Drum's ticket (batch D) switches it off and adds the
  Lost Socks to every profile's `collections`.
