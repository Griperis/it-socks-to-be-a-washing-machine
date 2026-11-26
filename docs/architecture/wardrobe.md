# The Wardrobe, its pieces, the Profile and Achievements

**Status: build plan for batch B (designed in core/122; answered Q2679-Q2683, 2026-11-25; filed by core/123 as
core/127, 128, 141-147 and assets/18-20).** Behaviour list: `docs/migration/m4-lists/08-wardrobe-profile-achievements.md`
(where an answer below differs from a line there, the answer binds). Batch B is built unattended in the order of
`docs/migration/milestones.md` "Batch B" (Q2603-Q2605); its neighbours are core/120 (Coins, the Old Tree:
`docs/architecture/economy.md`) and core/121 (presents, Collections, the encyclopedia: `docs/architecture/gifts.md`).
The seams to both are at the end.

## What it owns

- **The pieces as data:** each of the 112 pieces (10 basic, 6 per Collection) as one Resource with its Looks scene.
- **The dressed Avatar:** a look (hat, clothes, socks, trail) on every Avatar, the own body and the mirror body; the
  swish, the rare touches, the Trails.
- **What a player owns and wears in co-op:** the look, the owned pieces, the colour and the Lifetime tallies on the
  Roster, asked for by Commands, decided by the Host.
- **The Wardrobe:** its page (preview, colour row, four rows), the station in the house, the Lobby's Wardrobe key and
  stats card.
- **The Profile file** (`game/net/player_profile.gd`): its version, its fields (core/121's two included: one ticket,
  core/127, writes them all), a coalesced save.
- **The Lifetime tallies** and **Achievements**: the data, the decision on each machine, the toast, the Profile page,
  the backend seam for Steam (batch D).

It does not own: the presents, their draw and their reveal (core/121, through the seams); Coins (core/120); Secrets
(none in batch B: the eight and their pieces come together later, Q2600, Q2682); Steam itself (batch D, Q2616).

## The shape

```
game/wardrobe/                    the pieces and what dresses an Avatar
  wardrobe_piece.gd                 WardrobePiece (Resource): one piece
  pieces/<id>.tres                  112 files, one per piece (beanie.tres ... tumbling_socks.tres)
  wardrobe.gd                       Wardrobe (static): every piece in the folder, rows, pieces_of(), preview()
  look.gd                           WardrobeLook (static): a look as {hat, clothes, socks, trail}: clean, allowed
  dresser.gd                        Dresser (Node, a child of AvatarLooks): puts a look on, swish, tag lift
  trail_mark.gd                     TrailMark (Node3D): the one script of every Trail's mark: its life, then gone
  trails/<id>.tscn                  17 Trails: one mark each, particle nodes authored in the editor (Q2680)
  looks/<id>.tscn                   a piece's Looks (assets/18, 19): the model, its AnimationPlayer "touch" clip when rare
  wardrobe_tuning.gd/.tres          WardrobeTuning: swish, preview stage, demo steps, tag lift
game/wardrobe/ui/                 the page, authored in nodes on the Theme (Q2658)
  wardrobe_page.tscn/.gd            the page: preview stage, colour row, four rows, Close
  wardrobe_row.tscn/.gd             one slot's row: heading, count, "<", name box, ">"
  colour_swatch.tscn                one swatch and its name
  preview_stage.tscn                the SubViewport stage (light, camera); made with `preview()` (core/128), the gift reveal reuses it
  wardrobe_menu.tscn/.gd            the house's CanvasLayer holding the page
game/entities/wardrobe_station/   the oak wardrobe: its scene, WardrobeStation (Part), graybox and real Looks (assets/20)
game/profile/                     the Profile's game side
  tally_recorder.gd                 TallyRecorder (Node, every machine, in run.tscn): the five Lifetime tallies
  achievement.gd                    Achievement (Resource): one Achievement
  achievements/<id>.tres            the list: none in batch B (Q2687)
  achievements.gd                   Achievements (Node, every machine, in the game link): decides for its player
  achievement_backend.gd            AchievementBackend (RefCounted, abstract): the seam
  local_achievement_backend.gd      over the Profile; always on
  fake_achievement_backend.gd       tests (lives under tests/, not shipped)
  achievement_toast.tscn/.gd        the card at the top right
  profile_page.tscn/.gd             the Profile page: tallies and Achievements (Q2681)
  achievement_cell.tscn             one Achievement on the page
```

Inheritance stays one step (Q2251): `WardrobeStation` extends `Part`; a Trail has no script of its own (its root uses
`TrailMark`); `LocalAchievementBackend` and the fake extend `AchievementBackend`; nothing extends those.

## The pieces as data

**`WardrobePiece`** (Resource, `game/wardrobe/pieces/<id>.tres`, edited in the inspector): `id: StringName` (the file
name, read at load), `name` ("Top hat", "Lint puffs"), `slot` (enum HAT, CLOTHES, SOCKS, TRAIL), `collection:
StringName` (empty for the ten basic pieces; else a `SockCollection` id, core/121), `rarity` (enum COMMON, UNCOMMON,
RARE: the old names), `order: int` (its place among its Collection's, the old `gifts.json` order), `looks: PackedScene`
(the hat or clothes model, the Socks pair, or the Trail scene), `swish_rate := 1` (Bee wings 4), `owned_from_start: bool`
(on for the ten basic pieces: every player owns them from a new Profile on, Q2679, reversing Q696; a designer can tick
it on any piece), `listed := true` (off: not in the Wardrobe's rows or counts unless owned; only the graybox stand-ins).
A piece of a held-back Collection (`SockCollection.held_back`: the Lost Socks' six until the Drum, Q2683) is treated as
not listed, and no present draws it.

**`Wardrobe`** (static): `all()` lists the folder with `ResourceLoader.list_directory` (export-safe, as core/120's
Upgrades), `of(id)`, `row(slot)` (basic pieces first by `order`, then by Collection in `Collections.all()` order, then
`order`: the old rows), `pieces_of(collection)` (S-122a), `piece_name(id)`, `counted(slot)` (listed pieces only),
`owned(pieces: PackedStringArray) -> PackedStringArray` (the given ones plus every `owned_from_start` piece: the one
place the ten basic pieces become owned, so no profile stores them), `preview(id, tint) -> Node3D` (S-122d: a hat or
clothes Looks alone, a Socks pair on a bare-foot `AvatarLooks` in `tint` with its Body hidden, a Trail scene stepping
its demo; fitted by its largest side, the old `GP:171-207`), shown in `preview_stage.tscn`. **A designer adds a piece** by dropping
its model and making one `.tres` (or duplicating one) with its Looks: no code, and the Wardrobe zoo station, the rows,
presents (through `pieces_of`) and the Final screen pick it up.

**A piece's Looks** (`game/wardrobe/looks/<id>.tscn`, assets/18-19): an inherited scene of the old glb. A hat's mesh is in the
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
- **Trail:** at each step (below) one new mark, an instance of the Trail scene, `top_level`, at the foot facing the
  heading; at most the mark's `max` alive per creature (the oldest freed first); a changed Trail frees its marks.
- **Swish:** each frame, a hat or clothes mesh with "SwishL" and "SwishR" keys gets the old value (`AV:790-822`): the
  walk phase times `swish_rate`, 0.9 rad behind, times `walk` and `swish`; plus the idle sway. It reads `walk` and the
  phase the AvatarLooks already keeps. Numbers in `WardrobeTuning` (`# placeholder:` the old avatar.json values).
- **First person** (`first_person` on, the own body, Q2466): only Socks and Trail; never hat or clothes (Q888).
- **Mirror body** (the Player's `MirrorBody`): the whole look, `leaves_trail` off.

**Steps.** `AvatarLooks` already rocks its feet from the walk phase; it emits a `stepped(foot: Node3D)` signal when the
rocking turns over and `walk > 0.3` (the old `AV:775-780`), and the Dresser lays a mark at that foot, 0.006 m up. A remote Teammate, the own body and the zoo's stand-in all step the same way, so every machine draws
every creature's Trail from its own waddle (nothing on the network).

**Trails: particle scenes authored in the editor (Q2680).** The 17 old Trail scripts are not ported. Each Trail is a
scene `trails/<id>.tscn`, one mark: a root `Node3D` with `TrailMark` (exports `life` and `max`, the old numbers,
`# placeholder:`), and under it the mark's look as editor nodes: `GPUParticles3D` nodes (one shot, emitting when the
mark is made, local coordinates, no shadow; their `ParticleProcessMaterial` curves give the rise, sway, spin, swell,
bounce and fade; their draw passes are the Trail's meshes from the old glb, assets/19, or a stand-in quad until then),
sub-emitters where a mark bursts into more (Bubblegum pops' shreds), and, where a mark has staged motion that particles
do not give (Tyre tracks' strip unrolling, the Turf tufts one after another), an `AnimationPlayer` with an autoplay
`mark` clip keying the nodes. `TrailMark` only frees the mark after `life`; it moves nothing. The old motions in the
behaviour list ("Trails") are the brief; the looks may shift and are judged on stills (Q2680). A designer tunes a
Trail in its scene. **The demo** (the page's preview, the gift reveal, the zoo's stands): the Dresser lays a mark on a
timer (`WardrobeTuning`'s demo steps) as if walking.

## What a player owns and wears, in co-op

The Roster (a Part of the game link, `game/net/roster.gd`) already keeps each player's name and colour by player id and
is in the link's snapshot, so the Lobby and the run both have it. Its entry grows:

| Field | Meaning |
|---|---|
| `look` | `{hat, clothes, socks, trail}` the player wears |
| `owned` | the piece ids they own (for the Host's checks and core/121's draw); `owned_of()` returns it through `Wardrobe.owned()`, so the ten basic pieces always count (Q2679) |
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
| `wear {look}` | the Wardrobe page, on each step | refused unless every piece is in `owned_of(asker)` (silent: the page only offers owned); else `look` patched |
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
Trail's demo beside it, counter-turned. A row lists "None" and the owned listed pieces of its slot (the basic pieces
from the first game on, Q2679), `"%d/%d unlocked"` (listed pieces only: the Lost Socks' six neither listed nor counted,
Q2683),
steps on "<" / ">" and A / D on a focused arrow, wrapping; each step asks `wear`. The colour row instances one
`colour_swatch.tscn` per CoopTuning colour; taken ones greyed with their holder's name. The arrows and swatches are
the pad's stops (PadFocus, Q2647, Q2654).

**In the house:** `wardrobe_menu.tscn` (a CanvasLayer, the cream panel 900 px, the page inside) opens from the
station; the player frozen, the mouse free, the world running; `menu_open` / `menu_close`; Esc, E or Close shuts it.
**In the Lobby:** the same page in the Lobby's page layer (core/63's page pattern), opened by the Wardrobe key.

## The station in the house

`game/entities/wardrobe_station/wardrobe_station.tscn`: a `StaticBody3D` root (the old box, 1.0 x 1.92 x 0.56 m, on
the station layer), `WardrobeStation` (Part), `Looks` (graybox: a box and two door leaves on hinge pivots, an
AnimationPlayer with `open` (each leaf 80 degrees, 0.7 s, ease in-out) and `shut` (ease out); assets/20 brings the old glb
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
| `collections_completed` | core/121's `collection_completed` Stage event (the one line is added by core/137, which makes the event) |
| `floors_completed` | `Stages.stage_completed` (the last floor's included) |
| `games_finished` | the Laundry day's `ended` (run-ends) |

Each count calls `Achievements.check()`.

## Achievements

**`Achievement`** (Resource, `game/profile/achievements/<id>.tres`): `id: StringName` (the file name; the future Steam
API name: lowercase a-z, 0-9 and `_`, at most 40, never renamed once live: a test checks), `title`, `description`,
`icon: Texture2D` (empty: the shared placeholder, Q1698), `hidden: bool` ("???" until earned, Q1693), `credit` (enum
TEAM, OWN: Q1691; with every batch B condition a tally, TEAM), `tally: StringName` and `at: int` (the batch B
condition kind: a Lifetime tally reaching `at`), `reward: WardrobePiece` (optional, Q1690). Later kinds (an event in a
Stage, a skill) add fields and a branch in `check()`; none is in batch B. **A designer adds an Achievement** by
dropping a `.tres`: it shows on the page and in the zoo station. **Batch B ships no Achievements list (Q2687):** the ten
basic pieces no longer need Achievements to be had (Q2679), so the draft ten (each giving a basic piece) were not
taken; the system (core/145) is built and tested with test fixtures, and the list waits for a later content round.

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

**The Profile page** (one page: the tallies on top, the Achievements under them, Q2681; `profile_page.tscn`, a Control on the Theme): the player's name, the five Lifetime
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

- **`game/zoo/stations/wardrobe.tscn`** (core/128): one stand per slot, each piece from `Wardrobe.all()` worn by its own
  `AvatarLooks` in a row (hats, clothes, socks, trails stepping their demo), labelled with name, Collection and Rarity;
  a stand-in Teammate walking a loop in a look picked by four zoo switches (one per slot, stepping through the pieces:
  zoo-only Commands under `game/zoo/wardrobe/`, asking the real `wear`); the station's Wardrobe (core/142) beside a wall
  mirror. A new piece file shows with no other change.
- **`game/zoo/stations/achievements.tscn`** (core/145): one pillar per `Achievement` file (title, condition, reward's
  preview, earned or not on the zoo's profile), switches "Grant all", "Reset" and "+100 Pairs" (adds to the zoo
  profile's tally, then `check()`).
- The Gifts station (core/121) lays each Collection's pieces through `Wardrobe.preview`.

## Seams

| Seam | Other side | What crosses |
|---|---|---|
| S-122a pieces by Collection (core/128) | core/137's `PresentDraw` | `Wardrobe.pieces_of(collection) -> Array[WardrobePiece]` (`id`, `name`, `slot`, `rarity`); `Wardrobe.piece_name(id)` |
| S-122b owned pieces on the Host (core/141) | core/137's drop | `Roster.owned_of(player_id) -> PackedStringArray` (basic pieces included) |
| S-122c a piece won (core/141, core/127) | core/138's `Present.open` | its answer carries `Roster.owned_patch(by, piece)`; the opener's machine calls `profile.unlock_piece(id)` |
| S-122d a piece's preview (core/128) | core/138's reveal, the Final screen's strip | `Wardrobe.preview(id, tint) -> Node3D`; `preview_stage.tscn` reused by the reveal |
| S-122e the profile file (core/127) | core/134's `ProfileRecorder` | `designs`, `collections` fields and `save_soon()` |
| S-122f Lifetime tallies (core/127) | core/137, batch A | `collection_completed`, `stage_completed`, the Laundry day's `ended` |
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

## The designer's answers (Q2679-Q2683, 2026-11-25)
- W1: the ten basic pieces are owned from the start (Q2679, reversing Q696). Batch B ships no Achievements
  list (Q2687).
- W2: the 17 Trails are remade as particle scenes authored in the editor, not ported scripts; the look is judged on
  stills (Q2680).
- W3: one Profile page: the five Lifetime tallies on top, the Achievements under them (Q2681).
- W4: no Secrets in batch B; the eight and their pieces come together later (Q2682).
- W5: the Lost Socks' six pieces are hidden from the Wardrobe and its "N/M" until the Lost Socks come with the Drum
  (Q2683).

## Tickets (filed by core/123)
Build order and waves: `docs/migration/milestones.md` "Batch B". Every core ticket builds on graybox (four `graybox_*`
pieces, one per slot, `listed` off, deleted by assets/18-19); the asset tickets stop at their first line-up and swap in
on the designer's yes.

| Draft | Filed as | Note |
|---|---|---|
| 122-A | core/127 The Profile file and the Lifetime tallies | also core/121's two profile fields (one ticket on `player_profile.gd`) |
| 122-B | core/128 Wardrobe pieces as data and the dressed Avatar | `owned_from_start` (Q2679); `preview_stage.tscn` moved here from 122-D; the Trail frame and Lint puffs as particles (Q2680) |
| 122-C | core/141 Looks, colours and owned pieces in co-op | |
| 122-D | core/142 The Wardrobe page and the station in the house | |
| 122-E | core/143 The Lobby's Wardrobe key and stats card | |
| 122-F | core/144 The Trails as particle scenes | remade, not ported (Q2680); look work, stops at its first stills |
| 122-G | core/145 Achievements: the system, the toast and the station; core/146 Batch B's Achievements list | the draft ten dropped by Q2679; no list in batch B (Q2687) |
| 122-H | core/147 The Profile page | Q2681 |
| AS-W1 | assets/18 The hats and clothes; assets/19 The Socks pieces and the Trails' meshes | split in two |
| AS-W2 | assets/20 The Wardrobe station's model | |

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
