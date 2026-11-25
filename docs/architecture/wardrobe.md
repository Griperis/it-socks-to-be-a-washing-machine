# The Wardrobe, its pieces, the Profile and Achievements

**Status: proposal for batch B (core/122), waiting for the designer's choices W1-W5 (core/122's Open follow-ups).**
Behaviour list: `docs/migration/m4-lists/08-wardrobe-profile-achievements.md`. Batch B is built unattended once the
designer approves its three proposals in one sitting (Q2603-Q2605); its neighbours are core/120 (Coins, the Old Tree:
`docs/architecture/economy.md`) and core/121 (presents, Collections, the encyclopedia: `docs/architecture/gifts.md`).
The seams to both are at the end. Written with each choice's recommended answer.

## What it owns

- **The pieces as data:** each of the 112 pieces (10 basic, 6 per Collection) as one Resource with its Looks scene.
- **The dressed Avatar:** a look (hat, clothes, socks, trail) on every Avatar, the own body and the mirror body; the
  swish, the rare touches, the Trails.
- **What a player owns and wears in co-op:** the look, the owned pieces, the colour and the Lifetime tallies on the
  Roster, asked for by Commands, decided by the Host.
- **The Wardrobe:** its page (preview, colour row, four rows), the station in the house, the Lobby's Wardrobe key and
  stats card.
- **The Profile file** (`game/net/player_profile.gd`): its version, its fields, a coalesced save; core/121 adds two
  fields to it.
- **The Lifetime tallies** and **Achievements**: the data, the decision on each machine, the toast, the Profile page,
  the backend seam for Steam (batch D).

It does not own: the presents, their draw and their reveal (core/121, through the seams); Coins (core/120); Secrets
(not ported, Q2600; W4); Steam itself (batch D, Q2616).

## The shape

```
game/wardrobe/                    the pieces and what dresses an Avatar
  wardrobe_piece.gd                 WardrobePiece (Resource): one piece
  pieces/<id>.tres                  112 files, one per piece (beanie.tres ... tumbling_socks.tres)
  wardrobe.gd                       Wardrobe (static): every piece in the folder, rows, pieces_of(), preview()
  look.gd                           WardrobeLook (static): a look as {hat, clothes, socks, trail}: clean, allowed
  dresser.gd                        Dresser (Node, a child of AvatarLooks): puts a look on, swish, tag lift
  trail_effect.gd                   TrailEffect (Node3D): the marks, their age and max, the demo
  trails/<id>.tscn + <id>.gd        17 Trails: root TrailEffect subclass with its exports, Parts (the meshes)
  looks/<id>.tscn                   a piece's Looks (AS-W1): the model, its AnimationPlayer "touch" clip when rare
  wardrobe_tuning.gd/.tres          WardrobeTuning: swish, preview stage, demo steps, tag lift
game/wardrobe/ui/                 the page, authored in nodes on the Theme (Q2658)
  wardrobe_page.tscn/.gd            the page: preview stage, colour row, four rows, Close
  wardrobe_row.tscn/.gd             one slot's row: heading, count, "<", name box, ">"
  colour_swatch.tscn                one swatch and its name
  preview_stage.tscn                the SubViewport stage (light, camera); the gift reveal reuses it (core/121)
  wardrobe_menu.tscn/.gd            the house's CanvasLayer holding the page
game/entities/wardrobe_station/   the oak wardrobe: its scene, WardrobeStation (Part), graybox and real Looks (AS-W2)
game/profile/                     the Profile's game side
  tally_recorder.gd                 TallyRecorder (Node, every machine, in run.tscn): the five Lifetime tallies
  achievement.gd                    Achievement (Resource): one Achievement
  achievements/<id>.tres            the list (W1)
  achievements.gd                   Achievements (Node, every machine, in the game link): decides for its player
  achievement_backend.gd            AchievementBackend (RefCounted, abstract): the seam
  local_achievement_backend.gd      over the Profile; always on
  fake_achievement_backend.gd       tests (lives under tests/, not shipped)
  achievement_toast.tscn/.gd        the card at the top right
  profile_page.tscn/.gd             the Profile page: tallies and Achievements (W3)
  achievement_cell.tscn             one Achievement on the page
```

Inheritance stays one step (Q2251): `WardrobeStation` extends `Part`; each Trail extends `TrailEffect` (not a Part);
`LocalAchievementBackend` and the fake extend `AchievementBackend`; nothing extends those.

## The pieces as data

**`WardrobePiece`** (Resource, `game/wardrobe/pieces/<id>.tres`, edited in the inspector): `id: StringName` (the file
name, read at load), `name` ("Top hat", "Lint puffs"), `slot` (enum HAT, CLOTHES, SOCKS, TRAIL), `collection:
StringName` (empty for the ten basic pieces; else a `SockCollection` id, core/121), `rarity` (enum COMMON, UNCOMMON,
RARE: the old names), `order: int` (its place among its Collection's, the old `gifts.json` order), `looks: PackedScene`
(the hat or clothes model, the Socks pair, or the Trail scene), `swish_rate := 1` (Bee wings 4), `listed := true` (off:
not in the Wardrobe's rows or counts unless owned; the Lost Socks' six per W5).

**`Wardrobe`** (static): `all()` lists the folder with `ResourceLoader.list_directory` (export-safe, as core/120's
Upgrades), `of(id)`, `row(slot)` (basic pieces first by `order`, then by Collection in `Collections.all()` order, then
`order`: the old rows), `pieces_of(collection)` (S-122a), `piece_name(id)`, `counted(slot)`, `preview(id, tint) ->
Node3D` (S-122d: a hat or clothes Looks alone, a Socks pair on a bare-foot `AvatarLooks` in `tint` with its Body hidden,
a Trail scene in demo mode; fitted by its largest side, the old `GP:171-207`). **A designer adds a piece** by dropping
its model and making one `.tres` (or duplicating one) with its Looks: no code, and the Wardrobe zoo station, the rows,
presents (through `pieces_of`) and the Final screen pick it up.

**A piece's Looks** (`game/wardrobe/looks/<id>.tscn`, AS-W1): an inherited scene of the old glb. A hat's mesh is in the
HatPoint's frame; clothes keep their skin (the Dresser binds them to the Avatar's Skeleton3D); a Socks piece has
`sock_l` and `sock_r`. **The rare touches are authored in the Looks** (Q1618's "small animated touch"), not code: an
AnimationPlayer with a looping `touch` clip (a wave keys the "Touch" blend shape 0, 1, 0 over the old period; a glow
keys each `_glow` surface's override material's emission energy, `cycle` as staggered keys; drops are a
`GPUParticles3D` child with the old rate, life, gravity, size and colour), autoplay on. `PieceTouch` is not ported.

**`WardrobeLook`** (static helpers on a plain Dictionary `{hat, clothes, socks, trail}` of StringNames): `clean(look)`
(unknown ids and wrong slots become empty), `allowed(look, owned)` (unowned come off).

## The dressed Avatar

`AvatarLooks` gains `look: Dictionary` (an export with a setter) and a **`Dresser`** child (`dresser.gd`), so
`avatar_looks.gd` grows by a few lines only. The Dresser, on a changed slot:
- **Hat:** instances the piece's Looks under `HatPoint`; the name tag's height becomes `tag_lift` (0.25) over the hat's
  top (Q2462).
- **Clothes:** instances it under the Body, binds each skinned mesh's `skeleton` to the Avatar's, and follows the
  Body's "Crouch" blend shape with its own when it has one (`set_crouch` calls `Dresser.crouch()`).
- **Socks:** the pair's two meshes under `FootL` and `FootR` at identity (so they waddle, stay planted and ride the
  ragdoll); no shadow in first person.
- **Trail:** one instance of the Trail scene, `top_level` at the origin, given each step (below); a changed Trail
  frees the old with its marks.
- **Swish:** each frame, a hat or clothes mesh with "SwishL" and "SwishR" keys gets the old value (`AV:790-822`): the
  walk phase times `swish_rate`, 0.9 rad behind, times `walk` and `swish`; plus the idle sway. It reads `walk` and the
  phase the AvatarLooks already keeps. Numbers in `WardrobeTuning` (`# placeholder:` the old avatar.json values).
- **First person** (`first_person` on, the own body, Q2466): only Socks and Trail; never hat or clothes (Q888).
- **Mirror body** (the Player's `MirrorBody`): the whole look, `leaves_trail` off.

**Steps.** `AvatarLooks` already rocks its feet from the walk phase; it emits a `stepped(foot: Node3D)` signal when the
rocking turns over and `walk > 0.3` (the old `AV:775-780`), and the Dresser hands the Trail `step(at, yaw)` at that
foot, 0.006 m up. A remote Teammate, the own body and the zoo's stand-in all step the same way, so every machine draws
every creature's Trail from its own waddle (nothing on the network).

**Trails (W2 (a)).** `TrailEffect` is the old base (`TE`): `marks`, `step`, `advance`, `life`, `max`, `start_demo`
(DEMO numbers in `WardrobeTuning`), `spring()`. Each of the 17 is a scene `trails/<id>.tscn`: its root carries its own
script (the old `_spawn` / `_animate`, ported line by line) and its numbers as `@export` fields with the old values and
`# placeholder:`; a `Parts` child holds the model's meshes (the old `parts()` read the glb at run time). The motion
stays exactly the approved one (Q872, Q916, Q952). A designer tunes a Trail in its scene's inspector.

## What a player owns and wears, in co-op

The Roster (a Part of the game link, `game/net/roster.gd`) already keeps each player's name and colour by player id and
is in the link's snapshot, so the Lobby and the run both have it. Its entry grows:

| Field | Meaning |
|---|---|
| `look` | `{hat, clothes, socks, trail}` the player wears |
| `owned` | the piece ids they own (for the Host's checks and core/121's draw) |
| `tallies` | their five Lifetime tallies as they came in (the Lobby's stats card) |

**The word at the gate** (`session_gate.gd`) carries, beside the id, name and Hands: the profile's `look`, `owned`,
`tallies` and `colour` wish. The Host clamps them (known piece ids only, at most 112, `WardrobeLook.allowed(look,
owned)`; tallies finite, 0 to 999,999,999; the colour index in range) and `joined()` writes them. The colour: the
wished one if free, else the next free (the old `Session.free_colour`, Q276; Q2441's "next free" stays the fallback).
Off Steam a Guest's `owned` cannot be proved (the old trusted it whole); the Host keeps it for the session and adds to
it only through its own answers below.

**Verbs** (a Guest asks for itself only: the id comes from the sender, never the args; Solo is its own Host):

| Verb | Asks | The Host decides |
|---|---|---|
| `wear {look}` | the Wardrobe page, on each step | refused unless every piece is in the asker's `owned` (silent: the page only offers owned); else `look` patched |
| `colour {index}` | the colour row | refused (`taken`) when another present player has it: the asker's swatch springs back; else patched |
| `own {piece}` | the asker's machine after a local unlock (an Achievement's reward) | a known id appended to `owned` |

A present opened (core/121's `Present.open`) puts `Roster.owned_patch(by, piece)` in its own answer, so a piece won from
a present reaches `owned` with no extra ask. Every machine's `Avatar._dress()` (it already reads the colour and name
from the Roster) also reads `look`; the Player's own body and mirror body read their own entry. The Roster's save
merge (saves.md) keeps a present player's live `look`, `owned` and `tallies` over a saved entry's: they are the
profile's, the word wins.

**This machine's profile** follows its own entry: an applied `look` or `colour` answer for the local player writes
`look` / `colour` into the profile (coalesced save), so the next game starts in it.

## The Wardrobe page (authored in nodes, Q2658)

`wardrobe_page.tscn` (a Control on the Theme; Theme variations for the panel, the heading, the name box well, the
swatch): a `Heading` Label ("Colour & Wardrobe"), an HBox of the `PreviewStage` (`preview_stage.tscn`: SubViewport
300 x 380, own world, transparent, MSAA 4x, its WorldEnvironment (ambient (1.0, 0.95, 0.88) 0.55, AgX) and key light
(1.3) and its 36 degree camera, all nodes with the old values) and a `Rows` VBox (separation 26) holding the `Colours`
HFlow and four `wardrobe_row.tscn` instances (`slot` export set per instance), and the `Close` button
(`close_button.tscn`). Code only fills them: the preview is an `AvatarLooks` in the player's colour and look turning one
turn per `spin_time` (8 s) with the pupils' watch set while it faces the camera (within 1.05 rad), and the worn
Trail's demo beside it, counter-turned. A row lists "None" and the owned listed pieces of its slot, `"%d/%d unlocked"`,
steps on "<" / ">" and A / D on a focused arrow, wrapping; each step asks `wear`. The colour row instances one
`colour_swatch.tscn` per CoopTuning colour; taken ones greyed with their holder's name. The arrows and swatches are
the pad's stops (PadFocus, Q2647, Q2654).

**In the house:** `wardrobe_menu.tscn` (a CanvasLayer, the cream panel 900 px, the page inside) opens from the
station; the player frozen, the mouse free, the world running; `menu_open` / `menu_close`; Esc, E or Close shuts it.
**In the Lobby:** the same page in the Lobby's page layer (core/63's page pattern), opened by the Wardrobe key.

## The station in the house

`game/entities/wardrobe_station/wardrobe_station.tscn`: a `StaticBody3D` root (the old box, 1.0 x 1.92 x 0.56 m, on
the station layer), `WardrobeStation` (Part), `Looks` (graybox: a box and two door leaves on hinge pivots, an
AnimationPlayer with `open` (each leaf 80 degrees, 0.7 s, ease in-out) and `shut` (ease out); AS-W2 brings the old glb
with the same names). **`WardrobeStation`** (State `inside: PackedStringArray`, player ids): verb `use` (E, for itself:
the asker's machine opens its menu from the answer, `inside` gains the asker) and `leave` (on close; a leaver from the
Roster is dropped too). The Looks plays `open` when `inside` turns non-empty and `shut` when it empties, with
`wardrobe_open` / `wardrobe_close` (the old picks as SoundEvents) 1 m up; a state arriving whole shows without sound
(as `Openable`). Prompt "Wardrobe", the doors outlined. It is placed by hand in `house.tscn` at the old spot (parents'
bedroom, west wall, HL), and **Sock places keep clear** in front of it: `SockPlaces` reads a `sock_clear` group (a node
with a `clear_box: Vector2`) beside its `is Cabinet` check, and the station joins it with the old 1.25 x 1.09 m zone.

## The Lobby (core/63's seams)

`lobby_place.tscn`'s Avatar takes the Roster's `look` (and steps its Trail's demo under the feet). A **Wardrobe key**
(84 px orange keycap, hanger icon from the UI icons, tooltip "Wardrobe") floats beside this machine's own figure's head
at 82% of its width (`LobbyTuning`); pressing it opens the page and asks `LobbyState.ready(false)` (Q1764). A **stats
card** (`lobby_stats_card.tscn`, 280 px, cream, name 28 px, five rows 22 px "Pairs", "Coins", "Collections",
"Floors", "Games", thousands apart) shows beside the focused figure from the Roster's `tallies`, flipping left near the
screen's edge (48 px), never taking the mouse.

## The Profile file

`PlayerProfile` (`game/net/player_profile.gd`, RefCounted) grows, all plain JSON: `version` (2; a file of version 1, as
written today, reads with the new fields empty: no migration step is needed before save compatibility starts),
`colour: int`, `look: Dictionary`, `pieces: PackedStringArray` (owned), `tallies: Dictionary` (the five, ints),
`achievements: Dictionary` (id -> unix time earned), and core/121's `designs` and `collections`. New:
- `save_soon()`: marks it dirty; a timer on the Session writes it at most once every 2 s (`WardrobeTuning.save_every`,
  placeholder) and at quit, so a Pair shelved never writes a file (the old wrote on each). `save()` stays for the name.
- `unlock_piece(id) -> bool`: appends, `save_soon()`, emits `piece_unlocked(id)` (a signal on the Session's profile
  holder, as RefCounted signals work).
- `count(tally, n)`, `tally(name)`, `earn(achievement_id) -> bool`.
A damaged file is made anew (the old). The file stays one per `--profile=<tag>` (ProfileLock). Steam Auto-Cloud already
syncs it (saves.md, Q2565).

## The Lifetime tallies

`TallyRecorder` (a Node on every machine, in `run.tscn`; its own file so core/121's `ProfileRecorder` and this never
edit one script): from applied answers only, into the local profile, never while a World loads or from a snapshot
(Q1197's rule, as core/121's recorder):

| Tally | Counted on |
|---|---|
| `pairs_shelved` | each shelve answer (any shelver: the whole team counts, Q896) |
| `coins_earned` | `Bank.paid(player, amount, ...)` for the local player id (bonuses and refunds included; at the decided payout, not when the flight lands: looks only) |
| `collections_completed` | core/121's `collection_completed` Stage event |
| `floors_completed` | `Stages.stage_completed` (the last floor's included) |
| `games_finished` | the Laundry day's `ended` (run-ends) |

Each count calls `Achievements.check()`.

## Achievements

**`Achievement`** (Resource, `game/profile/achievements/<id>.tres`): `id: StringName` (the file name; the future Steam
API name: lowercase a-z, 0-9 and `_`, at most 40, never renamed once live: a test checks), `title`, `description`,
`icon: Texture2D` (empty: the shared placeholder, Q1698), `hidden: bool` ("???" until earned, Q1693), `credit` (enum
TEAM, OWN: Q1691; with every batch B condition a tally, TEAM), `tally: StringName` and `at: int` (the batch B
condition kind: a Lifetime tally reaching `at`), `reward: WardrobePiece` (optional, Q1690). Later kinds (an event in a
Stage, a skill) add fields and a branch in `check()`; none is in batch B (W1). **A designer adds an Achievement** by
dropping a `.tres`: it shows on the page and in the zoo station.

**`Achievements`** (Node in the game link, every machine): `check()` earns, for the local player only, every
Achievement whose tally the profile has reached and that it has not (`profile.earn`); for each: its `reward` goes
through `profile.unlock_piece` and `Roster.own`, the backend's `unlock(id)` runs, the toast queues, and the old
message "Wardrobe: <name> unlocked" shows on the HUD when it gave a piece (`PI:254`). It also runs at the game link's
start (a profile whose tallies already reached one, as the old `WI:9`). No Command, RPC or World field (ADR9). **The
seam:** `AchievementBackend` (`unlock(id)`, `is_unlocked(id)`, `unlocked_ids()`, `flush()`); `LocalAchievementBackend`
over the profile is always on; the Steam mirror and the start-up union both ways come in batch D (Q1957, Q2616).
**Debug** (debug builds, Q1696): the zoo station's switches and two F-key actions (`debug_achievement_grant_all`,
`debug_achievement_reset`) through `input_actions.py`; a reset clears `achievements` but never takes a piece away.
Achievements count in every build, a run with a debug cheat included (Q1696; release builds have no cheats).

**The toast** (`achievement_toast.tscn`, on the HUD's layer, authored in nodes): a cream card at the top right (icon 48
px, "Achievement" caption, the title), slides in, stays `toast_seconds` (4 s), slides out; a soft chime (`achievement`
SoundEvent, the first synthesised candidate, the designer picks on the bench); several queue; held while a cutscene or
the Final screen shows (the HUD's own hide rule). Timings in `AchievementTuning` (placeholders).

**The Profile page** (W3 (a); `profile_page.tscn`, a Control on the Theme): the player's name, the five Lifetime
tallies in a row of captions and numbers, then a `GridContainer` of `achievement_cell.tscn` (icon, title, description;
earned in full colour with the date, unearned greyed, hidden unearned "???"), "%d / %d earned". Opened from a 72 x 72
corner key on the title (beside core/121's encyclopedia key, tooltip "Profile") and from an entry in the ESC menu
(Q1694), Esc or Close shuts it.

## Saves and co-op, in short

- The World keeps nothing of this piece but the station's `inside` (empty on a load: menus never survive one) and the
  Roster's entries (look, owned, tallies merged as above).
- The profile keeps the rest; each machine writes only its own.
- The Host decides wear, colour, own, and the station's `use`/`leave`; every machine sees the look and the doors;
  Achievements are decided per machine for its own player (no Host involvement).

## Zoo stations (built from the data at load, Q2337)

- **`game/zoo/stations/wardrobe.tscn`** (122-B): one stand per slot, each piece from `Wardrobe.all()` worn by its own
  `AvatarLooks` in a row (hats, clothes, socks, trails stepping their demo), labelled with name, Collection and Rarity;
  a stand-in Teammate walking a loop in a look picked by four zoo switches (one per slot, stepping through the pieces:
  zoo-only Commands under `game/zoo/wardrobe/`, asking the real `wear`); the station's Wardrobe (122-D) beside a wall
  mirror. A new piece file shows with no other change.
- **`game/zoo/stations/achievements.tscn`** (122-G): one pillar per `Achievement` file (title, condition, reward's
  preview, earned or not on the zoo's profile), switches "Grant all", "Reset" and "+100 Pairs" (adds to the zoo
  profile's tally, then `check()`).
- The Gifts station (core/121) lays each Collection's pieces through `Wardrobe.preview`.

## Seams

| Seam | Other side | What crosses |
|---|---|---|
| S-122a pieces by Collection | core/121's `PresentDraw` | `Wardrobe.pieces_of(collection) -> Array[WardrobePiece]` (`id`, `name`, `slot`, `rarity`); `Wardrobe.piece_name(id)` |
| S-122b owned pieces on the Host | core/121's drop | `Roster.owned_of(player_id) -> PackedStringArray` |
| S-122c a piece won | core/121's `Present.open` | its answer carries `Roster.owned_patch(by, piece)`; the opener's machine calls `profile.unlock_piece(id)` |
| S-122d a piece's preview | the gift reveal, the Final screen's strip | `Wardrobe.preview(id, tint) -> Node3D`; `preview_stage.tscn` reused by the reveal |
| S-122e the profile file | core/121's `ProfileRecorder` | `designs`, `collections` fields and `save_soon()` |
| S-122f Lifetime tallies | core/121, batch A | `collection_completed`, `stage_completed`, the Laundry day's `ended` |
| S-120 Coins | core/120's `Bank` | `Bank.paid` for the local player is `coins_earned`; nothing in the Wardrobe costs (the old) |
| lobby | core/63 | the place's look, the Wardrobe key, the stats card, `ready(false)` on opening |
| HUD | the HUD scene | the toast's layer, the HUD message line |
| batch D | Steam | `AchievementBackend`'s Steam mirror and union; Steam's name in the profile |

## Changed technically from the old (no choice: tell the designer at the sitting)

- A piece is one `.tres` plus its Looks; the rare touches are an AnimationPlayer clip in the Looks, not code.
- The page, the rows, the station and its doors are scenes; the lock icon goes (nothing shows a locked piece since
  ticket 36; the "worn from an old Profile" case cannot arise before save compatibility starts).
- The Host checks a look against the pieces a player owns (the old took any look).
- The profile is written at most every 2 s, not on every Pair.
- Coins earned count at the decided payout, not when the flight lands (a Coin in flight at quit now counts).
- "Who is in the Wardrobe" is the station's own state, not string toggles in a shared Game.

## Tickets (drafts for the lead to file, `ready-for-agent`)

Every core ticket builds on graybox (four `graybox_*` pieces, one per slot, `listed` off, deleted by AS-W1); AS-W1 and
AS-W2 stop at their first line-up and swap in on the designer's yes.

**122-A The Profile file and the Lifetime tallies** (sonnet; coordinated with core/121's 121-F on
`player_profile.gd`). `PlayerProfile` version 2 and its fields, `save_soon()`, `unlock_piece`, `count`, `earn`;
`TallyRecorder` in `run.tscn` and its five tallies (`coins_earned` waits for core/120's `Bank`: until 120-A merges it
reads today's `Coins`). Real path: on the Stages station's mini run the player shelves a Pair by a click; the profile's
`pairs_shelved` reads 1 and its `coins_earned` the Pair's Coins; a loaded save counts nothing.

**122-B Pieces as data and the dressed Avatar** (opus). `WardrobePiece`, `Wardrobe` (`all`, `row`, `pieces_of`,
`preview`), `WardrobeLook`, `WardrobeTuning`, the 112 `.tres` (written once by a tool from the old `wardrobe.json` and
`gifts.json`, Looks pointing at graybox until AS-W1), `Dresser` on `AvatarLooks` (hat, clothes skin and crouch, socks
on feet, tag lift, swish, first person, mirror), the `stepped` signal, `TrailEffect` and Lint puffs as the first Trail;
the Wardrobe zoo station. Real path: in the Wardrobe station the player presses E on the stand-in's Hat switch: the
stand-in Teammate walking its loop wears the next hat and its name tag rises over it; with the Trail switch on Lint
puffs it leaves puffs as it walks.

**122-C Looks, colours and owned pieces in co-op** (opus; after 122-A, 122-B). The Roster's `look`, `owned`,
`tallies`; the gate's word and the Host's clamps; `wear`, `colour`, `own`, `owned_patch`, `owned_of`; `Avatar._dress`
and the own and mirror bodies from the Roster; the profile following its own entry; the save merge. Real path (co-op):
a Guest presses E on the Wardrobe station's Hat switch (the zoo's, asking the real `wear`); on the Host the Guest's
Avatar wears the hat; a `wear` of a piece the Guest does not own is refused and the Host still shows the old look.

**122-D The Wardrobe page and the station in the house** (opus; after 122-C and core/121's 121-A (Collections order)).
`preview_stage.tscn`, `wardrobe_page.tscn`, `wardrobe_row.tscn`, `colour_swatch.tscn`, `wardrobe_menu.tscn`; the
`WardrobeStation` entity with graybox Looks, its `use` / `leave`, doors and sounds, placed in `house.tscn`; the
`sock_clear` group in `SockPlaces`; the station in the Wardrobe zoo station. Real path: in the house the player walks to
the wardrobe and presses E; the doors swing open and the page shows them in their colour; a click on the Hats ">" puts
an owned hat on the preview and (co-op) on their Avatar for the Teammate; Esc shuts it and the doors close.

**122-E The Lobby's Wardrobe key and stats card** (sonnet; after 122-D). The place's look and Trail demo, the key,
`ready(false)` on opening, the stats card from the Roster's tallies. Real path: in the Lobby the player clicks the
Wardrobe key beside their own figure, steps the Socks row with a click, closes; their figure wears the Socks and their
Ready is cleared; hovering a Guest's figure shows the card with the Guest's tallies.

**122-F The other sixteen Trails** (sonnet; W2 (a); after 122-B; Looks from AS-W1). Each old Trail ported to its
scene line by line with its exports. Real path: in the Wardrobe station the stand-in walks with each Trail picked by
the Trail switch and its marks appear and age; a case per Trail checks marks spawn, move and go by `life`.

**122-G Achievements, the toast and the ten** (opus; W1 (a); after 122-A, 122-C). `Achievement`, `Achievements`,
`AchievementBackend`, the local backend, the fake (tests), `AchievementTuning`, the toast, the debug actions, the ten
`.tres` of W1, the Achievements zoo station. Real path: on the Stages station's mini run with a fresh zoo profile the
player shelves a Pair by a click: the toast "Two of a Kind" slides in, the HUD says "Wardrobe: Beanie unlocked" and the
Wardrobe's Hats row lists Beanie.

**122-H The Profile page** (sonnet; W3 (a); after 122-G and core/121's 121-G (the title's corner keys)).
`profile_page.tscn`, `achievement_cell.tscn`, the title's key, the ESC menu's entry. Real path: on the title a click on
the Profile key opens the page with the five tallies; an earned Achievement shows its title and date, an unearned one
greyed; Esc shuts it; in the house Esc then "Profile" opens the same page.

**AS-W1 The 112 pieces** (opus; stops at its line-up). The old glbs (`assets/avatar/wardrobe/`, Q914, Q1629's line-ups
approved in the old game) imported by the asset port rules into `assets/wardrobe/`, a Looks scene per piece, the
thirteen rare touches as `touch` clips and drops particles, the sixteen Trails' `Parts` meshes; the graybox pieces
deleted. Line-up: every piece on the Avatar in the old views beside the old game's shots, one strip per Collection.

**AS-W2 The Wardrobe station's model** (sonnet; stops at its line-up). The old `wardrobe_station.glb` as a Looks scene
with `door_left` / `door_right` pivots on their hinges and the `open` / `shut` clips; line-up shut and open beside the
old.

### Waves (at most 5 agents; a wave starts when the ones before are merged)

| Wave | Tickets | Clash kept apart |
|---|---|---|
| 1 | 122-A, 122-B, AS-W1, AS-W2 | 122-A alone on `player_profile.gd` and `run.tscn` in this piece (121-F also edits both: the lead orders 121-F and 122-A, either first); 122-B alone on `avatar_looks.gd` and the Wardrobe station |
| 2 | 122-C, 122-F | 122-C alone on `roster.gd`, `session_gate.gd`, `avatar.gd`, `player.gd`; 122-F only `game/wardrobe/trails/` |
| 3 | 122-D, 122-G | 122-D alone on `house.tscn` and `sock_places.gd`; 122-G on the HUD scene (not with 120-A or 120-D) and the game link scene |
| 4 | 122-E, 122-H | 122-E alone on the Lobby scenes; 122-H alone on `title.tscn` (not with 121-G) and the ESC menu |

Cross-piece clashes for the lead: `player_profile.gd` and `run.tscn` (121-F, 122-A, core/120's parts); `house.tscn`
(122-D, 121-C, 121-E, 121-H, 120-F); the HUD scene (122-G, 120-A, 120-D); `title.tscn` (121-G, 122-H); core/121's
121-C needs S-122a and S-122b (122-B, 122-C) and 121-D needs S-122c and S-122d (122-B, 122-C).

## Choices (core/122's Open follow-ups)

W1 the ten basic pieces and the Achievements of batch B; W2 how the Trails are ported; W3 the Profile page; W4
Secrets; W5 the Lost Socks' pieces. Each has a recommendation; the proposal above is written with them.

**W1 (a)'s ten** (team credit, none hidden; names from the old draft where it had one; each a Lifetime tally):

| id | Title | Condition | Gives |
|---|---|---|---|
| `first_pair` | Two of a Kind | 1 Pair shelved | Beanie |
| `pairs_100` | Sock Drawer Regular | 100 Pairs shelved | Cap |
| `pairs_1000` | The Thousand Pair Club | 1,000 Pairs shelved | Top hat |
| `coins_1000` | Pocket Lint Fortune | 1,000 Coins earned | Apron |
| `coins_10000` | Sock Market Tycoon | 10,000 Coins earned | Crown |
| `first_collection` | The Full Set | 1 Collection completed | Bow tie |
| `basement_done` | Spin Cycle One | 1 floor completed | Scarf |
| `floors_10` | Floor Show | 10 floors completed | Jumper |
| `first_wash` | Fresh and Clean | 1 game finished | Party hat |
| `games_5` | Repeat Cycle | 5 games finished | Bobble hat |

The numbers are the draft's (placeholders, Q967's balance round).

## Gotchas for the build

- A Guest's `wear` arrives before its `own` when an Achievement gives a piece and the player puts it on at once: the
  page asks `own` first, then `wear`, in that order (both on one reliable channel).
- `stepped` must fire on a remote Avatar too (it walks by its synchronized pose): the waddle runs there already.
- Clothes are skinned: bind `skeleton` after the mesh enters the tree, or it draws at rest.
- A preview `AvatarLooks` (the page, the gift reveal, a Socks preview) is in its own SubViewport world: it must not be in
  the `avatars` group or the nearest-player watch.
- Tallies count only on applied answers after the World is in; a Guest counts from its join on.
- Achievement ids are frozen once Steam is live: a test checks the id rules on every file.
- `ResourceLoader.list_directory()` for the pieces and Achievements folders (export-safe).
- Playing alone is a Host of one (`Parts`): check the Roster has the lone player's entry in Solo; if it has none, the
  build gives it one (as the Host's own at a hosted start), so the look has one home in every mode.
