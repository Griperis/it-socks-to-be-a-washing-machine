# Gifts, Collections and the encyclopedia

**Status: proposal for batch B (core/121), waiting for the designer's choices G1-G6 (core/121's Open follow-ups).**
Behaviour list: `docs/migration/m4-lists/07-gifts-and-collections.md`. Batch B is built unattended once the designer
approves its three proposals in one sitting (Q2603-Q2605); its neighbours are core/120 (Coins and Drawers, the Old
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
  looks_present_graybox.tscn   the box until the model (assets, AS-B1): Box, Box/Lid, Glow, Sparkle, Tag, AnimationPlayer
  present_opening.tscn         the opened box's last second on every machine (shake, pop, burst), then gone
  gift_paper.gdshader          the old wrapping shader, ported
  gift_reveal.tscn/.gd         the opener's reveal (a CanvasLayer authored in nodes)
game/parts/spawned_parts.gd  SpawnedParts (Part): Parts made during play (a present), through a MultiplayerSpawner
game/ui/encyclopedia/        encyclopedia.tscn (the pages), encyclopedia_cell.tscn, encyclopedia_menu.tscn (the book's)
game/entities/encyclopedia_book/  the book: its scene, Looks (the old glb, AS-B2)
```

Inheritance stays one step (Q2251): `Present`, `Presents` and `SpawnedParts` extend `Part`; nothing extends
`Carriable`. A present is a scene with a `Carriable` and a sibling `Present` Part, as the Machine Part is a scene with a
`Carriable` (core/79).

## Collections as data

**`SockCollection`** (Resource, one `.tres` per Collection in `game/collections/`, edited in the inspector):
`id: StringName`, `name` ("Simple"; the 2026-11-19 names, Q1954), `colour` (the pairing moment's sparkles, the old
designs.json colour), `cabinet_name` ("Simple cabinet"), `icon: Texture2D` (`assets/ui/<id>.svg`), the wrapping
`paper`, `ink`, `bow` (the old `wrapping.json` values; a transparent colour falls back to the old rule: paper = colour
lightened 35%, ink darkened 25%, bow = colour), `in_encyclopedia: bool` (on for all but per G3). `Collections.all()`
lists the folder with `ResourceLoader.list_directory` (export-safe) and orders it as `DesignCatalogue.collections()`;
`Collections.of(id)`. **A designer adds a Collection** by its Designs in `designs.tres` and one `.tres` here: no code.
`DesignCatalogue.collection_colours` and `cabinet_names` go; `collection_colour()` and `cabinet_name()` keep their
signatures and read the Collection files, so no caller changes. Dirty has no file (not ported).

**`CollectionUnlocks`** (Resource, `collection_unlocks.tres`): `start: Array[StringName]` (Simple, Sport, Lost Socks
per G3, Patterns, Animals, Superhero, Winter, Nature, Food: Q1439), `order: Array[StringName]` (Space, Fruit, Machinery,
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
(rules only, the old `GI:79-140`): for each player, for each completed Collection with pieces, one piece they lack and
do not have waiting, a piece of rarity RARE weighing `rare_weight` (0.25) against 1; none lacked: any piece of it (its
opening pays per G1). The answer is `SpawnedParts` rows, one per present, each at a spot of the heap (the run's record counts
a present only when it is opened). No Collection completed, no present (G6).

**The heap** (`Presents.heap_spots(n, lying)`): round a **`PresentSpot`** Marker3D placed by hand at the Old Tree's south
foot (the old first clear `tree_spots` entry, Q1605) under `Run` in the house and in each station that drops presents:
the free spots of a hex grid `apart` (0.42 m) across turned at random, nearest first, at least 0.9 x `apart` from a box
already lying, nudged 5% at random (the Host's rng): the old `GI:202-226`. The marker replaces the old search of 13
offsets clear of walls, furniture, Cabinets and Hampers (weak point). Placing it is the level's author's job; it is not a
child of the Old Tree's scene, so core/120 may rework the tree freely.

**The Machine Part's pop spot** (core/79's `complete`): the pop spot moves to the nearest hex spot clear of any lying
present, the same `heap_spots` with the lying presents (the old `CA:439-479`; batch A's carried item).

### The box's Looks (an AnimationPlayer, as every entity)

`looks_present_graybox.tscn` (contract for AS-B1's model): `Box` (body, ribbon cross; the paper's surfaces use
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
present's `SpawnedParts` row, writes the opener's refund into `Coins` (core/120's seam, a bonus) when they own the
piece, appends `[player id, piece]` to `RunRecord.pieces` (a new piece only) and counts `RunRecord.gifts_opened`, and
carries `present_opened(by, piece, refund, collection, at)`. On every machine, before the node goes, its `Looks` is
handed to a **`present_opening.tscn`** effect that follows the carrier's hold point and plays the `open` clip: the old
wobble (5 Hz quickening by 3 Hz, 0.04 to 0.3 rad by 70%), the crouch, the 0.45 box hop, the lid's flight and the
shrink, the 28-speck burst, the `gift_rattle` at the box; scaled to `shake` (1.0 s) by its speed, then freed. On the
opener's machine the world box only rattles and vanishes (as the old) and **`GiftReveal`** opens: a CanvasLayer scene
(`gift_reveal.tscn`, on the Theme) with a 520 x 520 `SubViewportContainer` stage (its camera, a turntable node, a box
Looks instance playing `open` at 1.6 x), and a `Caption` VBox of three Labels (name, Rarity, "New in your Wardrobe" or
"Already yours: +%d Coins") with Theme variations; code only fills them and puts the piece's preview (core/122) on the
turntable after the pop (0.35 s back-out pop-in, 1.6 rad/s, a Trail 0.5 rad/s tipped -0.6). It stays `preview` (3.0 s);
any click or pad face button then closes it and is consumed; during the shake a click is consumed and does nothing; the
player may walk. The opener's own machine then writes a new piece into its profile (core/122's `unlock_piece`), which
core/122's sync makes the Host's owned list.

**The Final screen** (run-ends' seams): `RunRecord` gains `pieces` and `gifts_opened` (its batch B rows); each
`FinalColumn`'s pieces strip shows its player's pieces (core/122's preview, fitted); two `FinalTotal` Resources,
`gifts_opened` ("Gifts opened") and `pieces_won` ("Wardrobe pieces won"), join `final_totals.tres`: no screen change.

### Prompts and sounds
Aimed own present: the outline only (as the old) or the row of G5; carried: "Drop [RMB]" (and "Open [LMB]" per G5).
Sounds as SoundEvents in the catalogue with the old picks: `pick` on the pick-up and the open (placeholder), `drop` on
the put down, `gift_rattle` (the first synthesised candidate; the designer picks on the bench). The landing is silent.

### The Old Tree's lines (core/120's speaker)
The presents fire three VoiceTriggers this piece adds (`game/voice/triggers/presents_ready.tres`, `presents.tres`,
`present_taken.tres`, COMMENT kind, the Old Tree's speaker); `Presents.waiting_for(player_id) -> int` and the signals
`presents_dropped(players)` and `present_taken(by)` (a Carriable pick of a present) are what the tree's director reads
for "near". The eleven old lines (`VO tree_presents*`, `tree_present_taken*`) go into the Old Tree's line file
(Q2640) by the ticket that brings the tree's voice (core/120's, after Q2506's rework); until then the triggers exist and
nothing speaks.

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
"???". Pages: one per unlocked Collection with `in_encyclopedia` on, in catalogue order, 50 a page, sorted small, medium,
large then catalogue order; names are the catalogue's (they already carry their colour where shared, Q1198).
- **On the title:** a 72 x 72 corner key (`menu_encyclopedia`, tooltip "Sock encyclopedia") left of the Licence key
  opens an Encyclopedia page of the title (`title.tscn` gets the key and the page; the key is the old Q1195, the "later"
  of Q2562).
- **In the house** (G4): `encyclopedia_menu.tscn` (a CanvasLayer, the cream panel style, the same pages) opened by E
  while the book is the active Hands item; the player frozen and the mouse free, the world running; arrows, A / D,
  Left / Right turn; E or Esc closes; it closes when the book leaves the Hands.

**The book** (G4 (a)): `game/entities/encyclopedia_book/encyclopedia_book.tscn`, placed by hand on the workshop's
workbench in the house: a `Carriable` (title "Sock Encyclopedia", `handable` on, never thrown) whose new export
`one_slot` makes it a Hands item in one slot instead of the whole Hands, listed and cycled with the Socks and Pairs (the
seam batch C's guide card reuses); E reads it ("Read" in the hints). Its Looks is the old glb (AS-B2). Saved and in the
snapshot as every Carriable; a New Game puts it back on the bench.

## The save

- **The World** (each Part's State, `docs/architecture/saves.md`): `SpawnedParts` rows (every present: its Carriable's
  holder, place and turn, its Present's player, piece and Collection; a carried one laid where it would lie, as every
  Carriable on a load, Q2559-Q2560), `Presents.next_id`, `Stages.completed`, each `Cabinet.collection` (the draw), the
  book's Carriable, `RunRecord.pieces` and `gifts_opened`. A New Game starts with none of them (unopened presents lost,
  Q1601). Each Part's version steps as Q2557 says.
- **The profile** (core/122 owns the file, its version and its cloud sync, Q2565): this piece's fields are `designs:
  PackedInt32Array` (the encyclopedia, sorted ids) and `collections: Array[StringName]` (unlocked; a new profile starts
  with `CollectionUnlocks.start`).

## Co-op

The Host decides the draw, the drop, a pick, a put down and an opening; every machine sees the presents, the labels,
the shakes and the pops; only the opener sees the reveal. Presents are keyed by the Roster's player id (Q2458), so a
player who leaves and comes back finds their presents still lying for them (the old keyed them the same way). A joiner
mid-run is owed nothing for Stages before (Q1603). The draw needs each present player's owned pieces on the Host:
core/122's sync of the profile's pieces (the old sent them in the join, unchecked).

## Zoo stations (built from the data at load, Q2337)

- **`game/zoo/stations/collections.tscn`** (new, 121-A): one row per `SockCollection` from `Collections.all()`: icon,
  name, colour swatch, Cabinet name, wrapping swatches (paper, ink, bow) and a wrapped graybox present once 121-C lands,
  whether it is in the start set or its place in the unlock order; a switch per Collection toggles its unlock in the
  zoo's profile (Q1441). A new Collection file shows with no other change.
- **`game/zoo/stations/gifts.tscn`** (new, 121-B makes it, 121-C fills it): an Old Tree stand-in with a `PresentSpot`;
  switches (zoo-only Commands under `game/zoo/gifts/`): "Drop presents" (one per player for a Collection picked on a
  dial), "Complete a Collection"; each Collection's pieces (core/122's) laid out beside its wrapped box. The real-path
  cases of 121-C and 121-D run here and on the Stages station's mini run.
- **The Stages station's mini run** gets a `PresentSpot` and pools on its Cabinets (121-E, 121-C), so a whole Stage ends
  in presents.
- **The Final screen station's** pillars get pieces and an unlock in their made-up records (121-D, 121-F).
- **An Encyclopedia pillar** on the Collections station opens the pages on the zoo's profile (121-G).

## Seams

| Seam | Other side | What crosses |
|---|---|---|
| S-122a pieces by Collection | core/122's piece catalogue | `pieces_of(collection) -> Array[piece]`, each with `id`, `name`, `slot`, `rarity` (RARE weighs `rare_weight`); `piece_name(id)` |
| S-122b owned pieces on the Host | core/122's profile sync | `owned_pieces(player_id) -> PackedStringArray` for every present player |
| S-122c a piece won | core/122's profile | the opener's machine calls `unlock_piece(id)`; the Wardrobe offers it |
| S-122d a piece's preview | core/122's Looks | `preview(id, tint) -> Node3D` for the reveal's turntable and the Final screen's strip (a hat or clothes model, Socks on feet in the tint, a Trail's live sample) |
| S-122e the profile file | core/122's `player_profile.gd` | two fields, `designs` and `collections`, in its versioned shape; its coalesced save |
| S-122f Lifetime tallies | core/122's tallies | the `collection_completed` Stage event (and batch A's `stage_completed`) |
| S-120a the refund | core/120's Coins | the open answer writes `Coins.paid_patch(by, refund)` marked a bonus (the Final screen's "+N bonus") |
| S-120b the Old Tree's lines | core/120's tree voice | three VoiceTriggers, `Presents.waiting_for()`, `presents_dropped`, `present_taken` |
| S-120c the tree's place | core/120's Old Tree | none: the `PresentSpot` marker is the level's, beside the tree |
| run-ends | core/95's Final screen, RunRecord | `pieces`, `gifts_opened`, two `FinalTotal`s, the unlock strip |
| stages | core/76's `start`, core/79's pop spot | the draw's Cabinet patches before the Stage's Designs; `completed`; the pop spot clear of presents |
| hands | core/78's `Carriable` | the `carry_guards` seam (pick refusal, aimable); `one_slot` for the book (G4) |

## Tickets (drafts for the lead to file, `ready-for-agent`)

Every core ticket builds on graybox Looks; AS-B1 and AS-B2 stop at their first line-up and swap in on the designer's yes.

**121-A Collections as data** (sonnet). `SockCollection` x 17 (from the old designs.json and wrapping.json, the
renamed Simple and Patterns), `Collections`, `CollectionUnlocks` (`.tres` with Q1439 and Q1465), `DesignCatalogue`
reading colour and Cabinet name from them (its dictionaries removed), the Collections station. Real path: in the
Cabinet station, aiming at a drawer shows "[E] <cabinet_name> Drawer" from the Collection's file, and a Pair shelved by
a left click bursts in the file's colour.

**121-B Spawned Parts** (opus). `SpawnedParts` with its `MultiplayerSpawner`, `Parts.adopt` and `release`, rows in the
save and the join snapshot (spawn before states; a state arriving before its node waits for it), the Gifts station
with its `PresentSpot` and a zoo-only "Spawn a crate" switch (a plain Carriable crate under `game/zoo/gifts/`). Real
path: a click on the switch puts a crate at the spot on the Host and a Guest; the player picks it up and puts it down;
a late joiner sees it where it lies; a save and load keeps it.

**121-C Presents under the Old Tree** (opus; blocked by S-122a, S-122b). `Stages.completed` and `note_complete` with the
`collection_completed` event and the "done" rumble; `Presents`, `PresentDraw`, `present.tscn` with its graybox Looks,
clips `drop`, `lying`, `RESET`, the wrapping shader, the Tag, Glow, Sparkle and Burst; the `carry_guards` seam on
`Carriable`; `PresentSpot` in the house and on the Stages station's mini run; the Machine Part's pop spot clear of
presents; G5's prompts. Real path: on the Stages station's mini run the player shelves Cabinet A's last Pairs by
clicks, the Stage completes, a present wrapped in A's Collection drops at the spot labelled for the player (co-op: one
each, a Teammate's not aimable); a left click carries it; a right click puts it down.

**121-D Opening and the reveal** (sonnet; blocked by 121-C, S-122c, S-122d). `Present.open`, `present_opening.tscn` and
the `open` clip, `GiftReveal`, the refund (S-120a), `RunRecord.pieces` and `gifts_opened`, the Final screen's pieces
strip and two totals. Real path: carrying their present the player left-clicks: the box shakes and pops, the reveal
shows the piece's name and "New in your Wardrobe", a click closes it, the profile lists the piece; the Teammate's
machine sees the box shake and pop where it is carried; opening a piece already owned shows "Already yours: +75 Coins"
and the Coins rise by 75.

**121-E Cabinet pools and the New Game's draw** (sonnet; after 121-F). `Cabinet.pool`, `CabinetDraw` with its shared-pool
solving and `problems()`, the draw in `Stages.start` from the Host's unlocked set, the Cabinet's Looks swap on a changed
`collection`, the house's eight pools, pools on the mini run's two Cabinets. Real path: in the Stages station a click on
the mini run's New run switch gives Cabinet B one of its pool's unlocked Collections, its Looks and drawer prompt follow,
and Stage 1's Socks are of the drawn Collections only.

**121-F The profile's Collections and encyclopedia record** (sonnet; coordinated with core/122's profile ticket on
`player_profile.gd`). The two profile fields, `ProfileRecorder` (shelve answers, a loaded World's shelves, a Guest from
its join on), the unlock at the finished run and the Final screen's unlock strip. Real path: on the Stages station's
mini run a Pair shelved by a click puts its Design in the profile file; the Final screen station's pillar "with an
unlock" shows the strip, and a finished mini run (the Laundry station's Final wash pillar, the last bin loaded by a
click) unlocks Space in the profile.

**121-G The encyclopedia pages and the title's key** (sonnet; after 121-F). `encyclopedia.tscn`, its cell, the silhouette,
the title's key and page, the Collections station's Encyclopedia pillar. Real path: on the title a click on the
encyclopedia key opens the pages: a Design in the profile shows its Sock and name, the others "???"; a click on ">"
turns to the next Collection; a locked Collection has no page.

**121-H The book in the house** (opus; G4 (a); after 121-G and AS-B2). `Carriable.one_slot` with the Hands listing and
cycling it, `encyclopedia_book.tscn` on the workbench, `encyclopedia_menu.tscn`, its prompts ("Sock Encyclopedia
[LMB]", "Read [E]", "Drop [RMB]"), never thrown. Real path: in the house the player left-clicks the book on the workbench
into a free Hands slot, presses E, the pages show their own profile; A turns back, Esc closes; a right click puts it
down.

**121-I The Old Tree's present lines** (sonnet; blocked by core/120's tree voice). The three triggers, the lines added
to the tree's file, `waiting_for` and the two signals read by the tree's director. Real path: after a present drops the
player walks up to the tree and its subtitle shows a "presents_ready" line; taking the present near it gives a
"present_taken" line.

**AS-B1 The present box** (opus, Blender; stops at its line-up). The old box (Q1591, `presents_tree.png` approved,
Q1611) as a model: body, separate lid, ribbon cross, bow; paper surfaces taking `gift_paper.gdshader`; the Looks
contract above. **AS-B2 The encyclopedia book** (sonnet; stops at its line-up). The old `encyclopedia_book.glb` (Q1267)
imported as a Looks scene by the asset port rules.

### Waves (at most 5 agents; a wave starts when the ones before are merged)

| Wave | Tickets | Clash kept apart |
|---|---|---|
| 1 | 121-A, 121-B, 121-F, AS-B1, AS-B2 | 121-F alone on `run.tscn` and `final_screen`; 121-B alone on `parts.gd`; 121-F and core/122's profile ticket both edit `player_profile.gd`: the lead orders them |
| 2 | 121-E, 121-G | 121-E alone on `stages.gd`, `cabinet.gd`, `house.tscn`; 121-G alone on `title.tscn` |
| 3 | 121-C | alone on `stages.gd`, `house.tscn`, `carriable.gd`, the Gifts station, the Stages station |
| 4 | 121-D, 121-H | 121-D on the Gifts station and `final_screen`; 121-H on `house.tscn`, the Hands, `carriable.gd`, the prompts |
| later | 121-I | after core/120's tree voice |

Cross-piece clashes the lead must order with core/120 and core/122: `stages.gd` (121-E, 121-C and any Coins bonus at a
Stage, Q2619), `house.tscn` (121-E, 121-C, 121-H and the Old Tree's or the Wardrobe's placement), `final_screen`
(121-F, 121-D and core/120's Drawers total), `run.tscn` (121-F, 121-C and core/120's parts), `player_profile.gd`.

## Choices (core/121's Open follow-ups)

G1 a duplicate piece; G2 "opened together"; G3 the Lost Socks; G4 the book; G5 the present's hints; G6 Stage 1's
presents. Each has a recommendation; the proposal above is written with the recommended answers.

## Gotchas for the build

- A Collection completes only once per run; `completed` is per Stage and empties when the next Stage begins.
- The draw must patch the Cabinets before `stage_designs` runs in the same `start` answer.
- A present waiting in a box counts as "had" for the next draw (no second copy while one waits).
- The opened box's last second is a looks-only effect: the save never sees an opened present.
- The reveal consumes the clicks that close or skip it; nothing behind it picks up.
- A spawned Part's state may reach a Guest before its node (snapshot vs spawner order, coop-structure line 205): wait
  by id.
- Lost Socks (G3 (a)): `in_encyclopedia` off, not in `start`, no pool names it; nothing else special-cases it.
