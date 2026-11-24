# Saves and the main menu

**Status: built (core/58), as decided (Q2553-Q2567).** The "As built" section below is what the code does
and wins over the proposal text after it where they differ (the proposal and its choices M1-M10 are kept for the
record). Findings: `docs/migration/m4-lists/01-main-menu-and-saves.md`; Steam Cloud: `docs/research/steam-cloud-saves.md`.

## As built (core/58)

**Files.** `game/save/`: `Save` (autoload, the kit template amended), `SaveStore` with `LocalFileStore` and
`MemoryStore`, `Worlds` (autoload), `WorldSlot`, `WorldRecord`, `Autosave` (a node of `level_runtime.tscn`),
`SaveTuning` (`save_tuning.tres`). Screens: `game/ui/title/`, `options/`, `licence/`, `loading/`, `esc_menu/`;
`SceneChanger` (`game/scenes/`, autoload); `UiSounds` (`game/audio/ui_sounds.gd`, autoload); `KeycapStyle`
(`game/look/keycap_style.gd`) for the keycaps and panels on `game/look/theme.tres`.

**A save.** `Autosave.collect()`: `{"world": WorldRecord, "parts": Parts.save_snapshot(), "versions":
Parts.save_versions()}`; `Save.encode()` wraps it as `{"version", "saved_at", "data"}` through `JSON.from_native`,
every `PackedByteArray` written as `"b64:<Base64>"` (the Mess's packed state). Part hooks: `save_state()`
(Knockdowns `{}`, Hands without `grabbed_at`, Roster with nobody playing and each present player's spot, the Mess
with every flying Sock laid where it would land: `Mess.landing_pose()`), `save_version()` / `upgrade_save()` (each
Part's own version, stepped by `Parts.load_save()`), `loaded(host)` (Openable shut, Carriable let go, the Mess's lost
Socks at the return spot, every absent player's Hands dropped at their Roster spot).

**A load.** The title picks a `WorldSlot` (`Worlds.pick_solo()` / `pick_host()`) and hands it to the level through
`SceneChanger.change_to(path, heading, setup)` (`LevelRuntime.world`, `from_title`, `launch`). `LevelNet.start()`
loads it (`Autosave.restore()`) before the player enters: alone `Session.enter_alone()` writes the player into its
own Roster by its profile's player id (the core/57 gap: Hands and Coins are keyed by player id, never the peer
number), a Host `Session.host()` does the same; the body stands at its Roster spot. The Roster lives in the game link (`game/net/game_link.gd`, core/62),
outside the level, but the level's Parts read through to the link's, so `Parts.save_snapshot()` and the file's
`"parts"` are one dictionary as before and the Roster keeps its id `Runtime/Session/Roster`. A load merges into the
live Roster (`Part.restored()`, `Roster.restored()`): present players stay, standing where the save kept them;
absent players' entries come back with their spot, colour and Hands.

**Saving.** Within `autosave_seconds` of any applied answer (`Save.write_later()`: the data copied on the main
thread, the text and the write on `WorkerThreadPool`); at once on Back to title, Quit game, End session, the window's
close and the level leaving with a change unsaved. Only a machine that decides (alone or the Host). A failed write
keeps the old file; the HUD says "Could not save the game" once until a save works. The Solo World played with a
Guest becomes the first free co-op World.

**Tests.** `tests/save_test.gd` (S01-S17; S99 writes a sample save), `tests/menus_test.gd`. Committed beside them in
`tests/saves/`: `sample_v<n>.json` (one per save version, all loaded by S10), `shape.json` (S11: each saved Part's
fields and version; a changed shape needs a raised `save_version()`), `house_ids.txt` (S12: the house's saved ids;
a rename shows). When a change is meant, run `GAME_SAVES_OUT=<folder> kit/tools/run.sh --grep=save:s1` (and
`--stress --grep=save:s99` for a new version's sample) and commit what it writes.

## Steam Cloud (Q2564-Q2567)

Every save read and write goes through `Save.store` (a `SaveStore`); no other code touches save files (the profile
keeps its own small file, `user://profile.json`, synced too). `application/config/use_custom_user_dir` is on with
the name "It Socks", so `user://` is `%APPDATA%\It Socks\` on Windows and `~/.local/share/It Socks/` on Linux.
Worlds are `user://worlds/<player id>/<slot>.json`. Next to a World the local-file store keeps `<slot>.json.tmp`
(the write in progress), `<slot>.json.bak` (the file before) and `<slot>.json.damaged` (one that read neither way):
none of them ends in `.json`, so none syncs; settings (`settings.json`), logs and benches are outside `worlds/`.

Auto-Cloud pattern: `worlds/*/*.json` (tests/save_test.gd S15 matches every name a store writes against this line).

The Steamworks Auto-Cloud settings to enter (the M4 Steam piece; not tried, Steam cannot run here):

| Root | Subdirectory | Pattern | OS | Recursive |
|---|---|---|---|---|
| `WinAppDataRoaming` | `It Socks/worlds/{64BitSteamID}` | `*.json` | `[Cross-Platform]` | no |
| `WinAppDataRoaming` | `It Socks` | `profile.json` | `[Cross-Platform]` | no |

Root override: `WinAppDataRoaming` on Linux becomes `LinuxXdgDataHome` (Replace Path keeps `It Socks/...`).
Byte quota: 50 MB, files: 20 (six Worlds and the profile, with room). Off Steam the player id folder is the
profile's 128-bit id; on Steam the Steam ID, matching `{64BitSteamID}`. Wrap a save in `Steam.beginFileWriteBatch()`
/ `endFileWriteBatch()` by overriding `SaveStore.begin_batch()` / `end_batch()` when Steam is present.

## What it owns

The save file of each World and everything that writes or reads it (autosave, the quit save, a failed write, a
damaged file, the version), the Worlds on this machine and their Groups, and the screens around play: the title and
its pages, Options, Licence, the loading screen, the ESC menu, the cursor and the menus' sounds. It does not own the
Lobby screen (B61, its own piece), Steam (the M4 Steam piece) or what any Part keeps (each Part's State group).

## The rule it rests on

**A save is the join snapshot written to a file** (the co-op shape, `coop-structure-for-the-port.md`;
`kit/skills/multiplayer-game-dev/templates/scene_parts/README.md`). `Parts.snapshot()` already gathers every Part's
State group by id, the Mess packing its own; a late Guest receives it. A save takes the same dictionary, a load
hands it to `Parts.load_snapshot()`. No feature writes save code: a new Part's State fields are saved because they
are State fields. That replaces the old `Saves.to_dict` / `load_dict`, which listed some 30 fields of `Game` by hand.

## Key types

- **`Save`** (autoload, `game/save/save.gd`): the kit's `save/` template copied in (it owns files, never their
  content): slots, sections, `{"ok", "reason"}` answers, a version with migration steps, plain data through
  `JSON.from_native` / `to_native`, `.tmp` then `.bak`. Amended in the game's copy with the old game's safety (the
  findings, "Saves"): the old file becomes `.bak` only when it reads (a broken file never replaces a good backup); a
  file that reads neither way is kept as `<slot>.corrupt.json`; the text is made and written on a worker thread; the
  next save, a load or a delete waits for it. The `.bak`-only-when-readable rule is a kit follow-up too.
- **`SaveTuning`** (Resource, `game/save/save_tuning.tres`): `autosave_seconds` (2.0, M3), `coop_slots` (5),
  `# placeholder:` until the designer sets them.
- **`WorldRecord`** (RefCounted, `game/save/world_record.gd`): the old `WorldMeta`, smaller. `kind` (solo or co-op),
  `group: Array[String]` (player ids, fixed at the first co-op Play), `members: {player id: {name, colour}}` (last
  seen), `play_time`, `last_played`, `floor`, `level` (the level scene's path), `seed` (Q2524). Host-only, never in
  the join snapshot. The old per-World player id is gone: the port's player id (Q2458: the Steam ID, or the 128-bit id
  off Steam) is already the key everywhere.
- **`Worlds`** (autoload, `game/save/worlds.gd`): the slots (`solo`, `coop1` .. `coop5`), each World's row for a menu
  (`Save.read_slot` of each: six small files), `chosen`, `free_slot()`, `delete(slot)`, and the old rules: Solo stays
  solo until a Play with a Guest, then moves to a free co-op slot (Q1646, Q1737); a full set asks to delete one
  (Q1650); a Group refusal for the gate (Q1652). `chosen` is passed to the level when it loads, never a static path
  another class reads (the old `Saves.save_path` was).
- **`Autosave`** (Node in `level_runtime.tscn`, Host or alone only): marks dirty on `Parts.applied`; saves when dirty
  and `autosave_seconds` passed; saves at once on Back to title, Quit game, End session, the window's close and the
  scene leaving (while the Mess still holds its Socks, old maintenance/76); never while the level sets up or bakes. A
  Guest's runtime has it switched off (only the Host saves, Q249).

### Two hooks on `Part` (inheritance stays one step)

- **`save_state() -> Dictionary`**: what this Part keeps in a save; `whole_state()` by default. `{}` means "not
  saved": Knockdowns (who lies down now is not kept). Roster overrides it to stamp each present player's current
  spot and facing (the old `_note_positions`, Q296) and to drop the live `peer` field; Hands drops `grabbed_at` (the
  Host's clock).
- **`loaded() -> Dictionary`** (Host, after a load, as a `grant(...)`): what a load resets, kept beside the thing it
  resets instead of in one function (the old `load_saved`). With M7 (a): an Openable answers "shut" (a drawer's
  contents slide back as on any shut), a TV "off", the Radio keeps its channel, the Mess puts any Sock outside its
  bounds at its return spot (the rule it already has for lost Socks).

**Absent players' things.** After a load the Host calls `Parts.left(id)` for every player id the save holds who is not
here, the Host excepted. A leaver's rule already drops their Hands where they stood (`Hands.left`), so a Guest's held
Socks lie round their spot in the loaded World and they come back empty-handed with their Coins and spot (Q295), with
no save-only code. This needs Hands keyed by the player id when alone too (today a Host of one keys its own Hands by
peer number, `game/hands/hands.gd:42-44`): the Host of one names itself by its profile id.

## The file

`user://worlds/<slot>.json`, written whole (M1 a):

```
{"version": 1, "saved_at": "2026-12-01T18:04:11",
 "data": {"world": {WorldRecord}, "parts": {Parts.snapshot() through save_state()}}}
```

- Plain data through `JSON.from_native`: the Mess's packed state (zstd bytes) becomes Base64 inside it. The old game
  wrote about 40 KB for 1,000 Socks; the build ticket measures the file and the time to make it at 2,000 and 10,000
  Socks, with a timing case.
- **One encoding for join and save:** both are `Parts.snapshot()`. The join sends the dictionary through
  `var_to_bytes`; the save wraps the same dictionary in JSON. A Part's own packing (the Mess's records) is shared by
  both, so a pose that went through once stays put either way.
- **The version** is the template's `version`. A test keeps a fingerprint of the save's shape (every saved Part id and
  its State field names and types) beside the version number and fails when the shape changes but the number does
  not, as the gate's layout hash does for the network. Before the first outside play-test (the project value), a
  shape change raises the number and an older file is shown as M5 decides; from the play-test on, a raised number
  comes with a migration step (`Save.register_migration`) and old files load.
- **A Part found by its id:** the id is the node path from the level today. Renaming or moving a placed thing loses its
  saved state (`Part.write` logs an unknown field; a missing id is skipped). M6 decides when stable ids come.

## Autosave and a failed write

- Autosave (M3 a): within `autosave_seconds` (2 s) of any applied change, and at once on every way out. The snapshot
  is taken on the main thread (the Mess packs and compresses there: measured by the build ticket); the JSON text and
  the write run on `WorkerThreadPool`, as the old game.
- A write: `.tmp`, flushed, closed and its error checked; the old file becomes `.bak` only when it reads; the `.tmp`
  takes its place; on any failure the old file stays and the reason goes to `Log` (`save` area). With M4 (a) the HUD
  also says "Could not save the game" (placeholder) once until a save succeeds again.
- A read: the file; else its `.bak` and the title says "Loaded your previous save" once (Q1188, Q1503); else the file
  is kept as `<slot>.corrupt.json` (its name only in the log), a New Game starts and the title says "Your laundry got
  lost in the wash. Starting fresh." once (Q1189, Q1502).
- Tests and tools point `Save.dir` at their own folder; shots, tours and the checks already run with a throwaway
  `user://`.

## Worlds (M2 a: the old rules)

One Solo World and up to 5 co-op Worlds, each its own file; a row shows the Solo World as "Solo World" and a co-op
World by its Group's names (or "No Group yet"), with "<floor> · played <h>h <mm>m · last <date>"; co-op Worlds newest
first. A co-op World's Group is whoever is in the Lobby at its first Play and never changes; a Guest outside it is
refused at the gate ("This World belongs to its Group: you are not in it", placeholder). The Solo World played with a
Guest moves to a free co-op slot. Delete asks "Delete <name>? It cannot be brought back." A file that does not read
shows "Damaged World" and may be deleted. Steam Cloud syncing the folder comes with Steam (Q1684): one small,
self-contained file per World keeps that cheap.

## The screens: scenes on one Theme (Q2163)

`game/look/theme.tres` (the old font and theme, core/18) becomes the project's theme (`gui/theme/custom`, a
`project.godot` change the build ticket names); every screen is a scene the designer can open, with no style
overrides in code. Code fills data and reacts to presses.

| Scene | What | Starts from |
|---|---|---|
| `game/ui/title/title.tscn` | the backdrop, the cream panel, the pages as child scenes shown one at a time (home, multiplayer, join), the status line, the corner keys | new; becomes `run/main_scene` (Q2509 kept the house only "until menus exist"; the house stays reachable with `-- --scene=`) |
| `game/ui/options/options.tscn` | the old rows (findings, "Options") plus the Voice volume (core/56 V5), on `Settings`; in the title and the ESC menu | the kit's `options/` template, rows rebuilt to the old ones |
| `game/ui/licence/licence.tscn` | the credits and licences, built at load from a `Credits` Resource (one entry per work, the old `credits.json` fields); a test that every asset is covered | new |
| `game/level/loading_screen.tscn` (house/09's, one scene for every wait) | the old card: tumbling sock, heading, progress bar; the 0.5 s fade in from the backdrop | the kit's `scenes/` template (`SceneChanger`: threaded load, drawn once before the work), its loading screen replaced by this one |
| `game/ui/esc_menu/esc_menu.tscn` | Back to title / Quit game (solo), End session with its question (Host), Leave (Guest), Options | the kit's `pause/` template with `can_pause_override` always false: menus never pause (Q253) |

- **Menu sounds:** a small autoload `UiSounds` hooks every button as it enters the tree (the old rule): `ui_click` on
  press, `ui_hover` on an enabled button, as `SoundEvent`s of the sound catalogue on the UI bus (core/17).
- **The cursor:** Godot's own `display/mouse_cursor/custom_image` and hotspot (3, 2) with the old white arrow
  (`assets/ui/cursor.svg`); no code, nothing to let go at quit.
- **Settings:** `Settings` is already the kit's template; Options adds keys with `register()` (graphics preset with
  Auto, SSAO, mouse speed, Invert Y, pad speed, subtitles, FPS cap), and the `MoveTuning` sensitivity and the
  project-setting preset (Q2238, Q2323) move to it.
- **Templates not used now:** `remap/` (key remapping; M10 c), `tour/` (already planned for the baseline).

## The menu flow (M9 a)

```
launch -> (studio intro, once per launch: M10) -> Title
  Solo        -> the Solo World: Continue it, or a New Game when there is none -> loading -> the house (alone)
  Multiplayer -> Host -> the last-played co-op World, or a New Game in a free slot -> loading -> the house, listening
              -> Join -> name + address -> "Connecting to <ip>..." -> loading "Joining..." -> the house
  Options | Licence (corner) | Quit
in play: Esc -> ESC menu -> Back to title (saves) | Quit game (saves, closes) | End session (asks, saves) | Leave
```

Solo and Host pick their World by the old Host rule, so no World list is built twice: the list, Continue / New Game,
the "Pairs per Drawer" page and Delete arrive with the Lobby piece, which then sits between the title and loading for
Solo and Host as in the old game. Until then a New Game over an existing Solo World is reached only by deleting it
(a debug flag, `--new-game`).

## Co-op

- Only the Host saves; a Guest's runtime has no `Autosave`. A Guest who leaves is a leaver as today.
- The Host's End session saves, then closes the Session; Guests go to the title with "The host ended the session".
- The join snapshot leaves `WorldRecord` out (Host-only). A Guest's own spot and Coins come back through the Roster
  and Coins Parts on their next join, keyed by their player id.

## The zoo station (sketch)

The zoo is never saved and always starts fresh (Q2295), so the save has no station of its own; the build's real-path
case runs in the house. The screens are scenes the designer opens directly. A small `game/zoo/stations/save.tscn`
could hold a "save now" pillar and a "load" pillar for a quick round trip of the zoo's Parts in a test folder, if the
designer wants one.

The real-path case for the build ticket: in the house the player opens a Door and picks a Sock (pressed actions);
Esc, then Back to title (presses); Solo; the loaded house shows the Door shut (M7) and the Sock in the player's Hands,
the player where they stood.

## Gotchas

- A placed Part renamed or moved loses its saved state until stable ids exist (M6).
- A State field's type changed with no version raise loads the wrong type: the fingerprint test is what catches it.
- `Part.write` from a save runs `_show(true)`: a Part whose looks depend on another Part's state must cope with any
  load order (the same as a late Guest today).
- The autosave's snapshot is on the main thread; with 10,000 Socks its cost is the Mess's packing. Measure before
  lowering `autosave_seconds`.

## Decided (Q2553-Q2562, 2026-11-23)
M1 a (JSON per World, the kit's template); M2 c (the old slots, no Group lock); M3 a (2 s after a change and on every
way out); M4 a (old file kept, a HUD line); M5: old saves always load: a version per Part's state, a migration chain,
defaults for new fields, sample saves of each version in the suite; built now, enforced from the first outside
play-test; M6 a (node paths now, an editor tool before the play-test); M7 a (the old resets); M8 b (things in the air
laid where they would land, as the old); M9 a (straight into the house); M10 a (core screens and saves). Where the
text above assumed another option, these win.

## Choices for the designer

Each with 2-3 options; **(rec)** marks the recommendation.

- **M1. The save file.**
  a) **(rec)** The kit's save template, one JSON file per World with two sections (the World's record, every Part's
     state); the menu reads the six small files whole.
  b) The old two-line file: a header line the menu reads alone, the save on the second line.
  c) A binary file (`var_to_bytes`): smallest and fastest, but not readable by eye when a tester sends one.
- **M2. Worlds.**
  a) **(rec)** The old rules: one Solo World and 5 co-op Worlds, a co-op World's Group fixed at its first Play, only
     its Group may join, the Solo World moves to co-op when played with a Guest.
  b) Simpler: up to N Worlds, any of them played alone or hosted, anyone may join.
  c) The old slots without the Group lock (anyone may join a co-op World).
- **M3. Autosave.**
  a) **(rec)** The old: within 2 s of any change and at once on every way out, written on a worker thread.
  b) Every 30 s and on every way out (less disk work; up to 30 s lost on a crash).
  c) Only on the ways out (Back to title, Quit, End session, closing the window).
- **M4. A save that cannot be written.**
  a) **(rec)** The old file stays, the log says why, and the HUD says "Could not save the game" (placeholder) once
     until a save works again.
  b) The old: the old file stays and only the log says why (the player is never told).
- **M5. A World saved by another version, before the first outside play-test.**
  a) The old: it shows as an empty slot and a New Game there overwrites it.
  b) **(rec)** It shows as "Made by another version" (placeholder) and can only be deleted.
  c) It is loaded anyway, what still fits (risky: a Part's changed field may load wrong).
- **M6. Stable ids for placed things (a renamed or moved thing keeps its save).**
  a) **(rec)** Node paths now, with a committed id list in a test that shows every rename; ids filled by an editor tool
     before the first outside play-test.
  b) The editor tool now, with this piece.
  c) Node paths always (a rename after the play-test loses that thing's state in testers' saves).
- **M7. What a load resets.**
  a) **(rec)** The old: every Door, drawer and lid shut (what rode out in a drawer slides back), the TV off, the Radio
     keeps its channel, lost things back in front of the washer, absent players' held Socks dropped where they stood,
     nobody knocked down.
  b) Everything as it was saved (open Doors stay open), absent players' Socks still dropped.
- **M8. Things in the air when the game saves.**
  a) **(rec)** Saved in flight and flying on after the load (the late joiner's path; no new code).
  b) The old: laid where they would have landed.
- **M9. The menu flow until the Lobby piece.**
  a) **(rec)** Solo continues the Solo World (or starts one), Host the last-played co-op World (or a new one), straight
     into the house; the World list, Continue / New Game and Delete come with the Lobby.
  b) A temporary World list page on the title now, replaced by the Lobby later.
  c) The Lobby screen built in this piece.
- **M10. What the first build holds.**
  a) **(rec)** Title, Options, Licence, loading screen, cursor, menu sounds, ESC menu and saves; the studio intro and
     the encyclopedia key come later with their own tickets.
  b) As a), plus the studio intro (the old folder is self-contained, an asset piece).
  c) As a), plus key remapping in Options (the kit's remap template; the old game had none).
