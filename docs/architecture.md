# Architecture

How the code fits together, for an agent about to change it. This page is the index: read it,
then only the file for the subsystem you touch. Keep each subsystem file short (what it owns, its
key types, its flows, its gotchas) and update it in the same commit as the code.

## Layout

- `game/<feature>/` holds a feature's rules (plain data and logic) beside its views (nodes,
  scenes). Views depend on rules, never back; rules never reach into the scene tree.
- **How state changes** depends on the "Co-op" value in `CLAUDE.md`:
  - **not planned:** a feature's state is changed only through that feature's own rules object
    (one script that owns the state and its checks). Nothing else is needed.
  - **planned or undecided, scene parts:** shared state lives on `Part` nodes in each thing's scene
    (`game/parts/`): asked by a Command, decided by the part's own `decide()` on the Host, written
    only by `Parts`; netcode is one `Session` node. A player alone is a Host of one, so co-op adds
    no rework. A placed thing is never renamed or moved once a build is shared
    (`kit/skills/multiplayer-game-dev/templates/scene_parts/README.md`).
  - **planned or undecided, the Command seam:** netcode lives in one folder and talks to the rules
    through one Command seam.
- Shared lists are one file per item (a tuning file, a manifest entry, a test suite), so
  parallel branches never collide at the end of a list.
- Before a second feature copies the first one's way of doing something (holding, opening, saving,
  landing), stop and make one shared seam: a small typed interface both features go through, with the
  rule behind it and its test.

## Native defaults

How this game is built, unless a decision record says otherwise. They are the game's to change
(with the designer); the kit's skills point here.

- **Screens are scenes on one Theme.** Why: the designer opens and changes them in the editor;
  one Theme keeps them alike.
- **Numbers are typed Resources per feature** (`@export_range` fields, one `.tres`); a number of
  one placed thing is an export on it. Why: typos fail to parse, ranges show in the inspector.
- **Levels are built by hand in the editor** from scenes that snap to a 0.5 m grid. Why: what the
  designer sees is the level, with no generator to rerun.
- **Code-built nodes become scenes.** Why: they can be opened, seen and tuned in the editor.
- **An entity is behaviour plus a swappable `Looks` scene.** Why: the real model replaces the
  graybox with no change to rules or tests. Its authored motion is an AnimationPlayer's; UI feel,
  one-shot effects and motion that follows the game are driven from code (a Tween, or state each
  frame).
<!-- opt:zoo -->
- **The zoo** (`game/zoo/zoo.tscn`) has one station per feature, each its own scene in
  `game/zoo/stations/`, built from the game's own scenes; a new station is its own scene file plus
  one instance under `Stations` in `zoo.tscn`, placed by hand (the zoo suite fails for a file not
  instanced). `ZooStations` only joins each station's Socks to the zoo's (the `zoo-design` skill).
  Everything only the zoo needs lives under `game/zoo/`, in a folder per station (`game/zoo/sounds/`,
  `screen/`, `house_kit/`, `heap/`, ...): its helper scripts, layouts and zoo-only props (the Screen
  station's `UpgradeSwitch` and `zoo_upgrades.tres`, the Sounds station's `SoundSpot`, the kit's sample
  rooms). The game never refers to `game/zoo/`, so a release build can leave the folder out whole
  (Q2409; no guard check, Q2410). A Part's crosshair words come from its own `prompt_title()`, so
  `Prompts` names no zoo class. The two build-time generators are in `tools/`, not `game/`.
  A station built from data at load (Q2337) instances small scenes and fills them, never a tree of
  `.new()` nodes: every name or info text is `game/zoo/zoo_label.tscn` (lying on the ground, dark;
  a standing one overrides its turn and colour), a Sounds button `sounds/sound_button.tscn`, an icon
  `icons/icon_cell.tscn`, a material `materials/swatch.tscn` (core/30).
<!-- /opt:zoo -->

## Subsystems

| Subsystem | File | Read it when |
|---|---|---|
| The Mess | `docs/architecture/mess.md` | you change how Socks lie, are drawn, move or wake |
| The house kit | `docs/architecture/house-kit.md` | you add or change a kit piece, a library material or the kit's sizes |
| The material library | `docs/architecture/materials.md` | you add, pick or change a shared material, or a model uses one |
| Furniture | `docs/architecture/furniture.md` | you place, change or add a furniture piece, its openings, collision or Sock spots |

A ticket that adds a subsystem adds its row here and its file.

## Key flows

**Boot.** `project.godot` loads six autoloads in order: `Log`, `ProfilerBoot` (F3, debug builds), `GameCliBoot`
(`game/debug/game_cli.gd`: reads the arguments after `--`; a bench or `--scene=` swaps the scene after one frame),
`Profily`, `Settings` (`game/settings/settings.gd`, `user://settings.json`) and `Sounds` (`game/audio/sounds.gd`).
**The log.** `Log` (`game/log/log.gd`, the kit's log template) is the one stream: the game's lines
(`Log.info/warn/error(area, text)`) and every engine or script error with its script calls, in `user://logs/game.log`
(this run; `game.1.log` the run before, five kept). The file starts with the build line (name, version, Godot,
debug or release). The game's refusals go through `Log` with an area; only the command line's and the benchmark's
terminal output stays a plain `print()`.

The main scene is the zoo (`game/zoo/zoo.tscn`): `ZooStations` joins every station's Socks to the zoo's one Mess
before anything binds, `Parts.bind` registers every Part by its node path, and `ZooNet` hosts or joins on
`--host` / `--join=`.

**A frame.** `player.gd` moves the body, looks the aim up once (`AimFinder`), feeds the outline, the prompts and the
HUD, then reads the buttons. On the Host, `MessMoving.tick` checks hits, picks' columns, Door and drawer sweeps and
rests, then starts woken flights within the budget. `MessDrawing` flushes the dirty cell buffers; `HeldView` lays out
the held Socks; `SockCloth` ranks and bends the held and nearest flying Socks. Nothing else runs per frame.

**A change (pick, drop, Throw, shelve, open).** The asker builds a `Command` and calls `Parts.ask`. On the Host (or
alone) `Parts.answer` runs the target Part's `decide()`, which reads only and returns patches for one or more Parts or
a refusal; `Parts.apply` writes them (`Part.write`, then `_show`) and emits `applied`. A Guest's `ask` goes up through
`Session` (packet guards, rate), and the Host's `Session` sends each applied answer to every Guest, who applies it the
same way. The Player passes each answer to the HUD's words and `Hearing` (sound, rumble).

**A join.** `Session.join(where)` connects through its `NetTransport` (`game/net/`: `EnetTransport` is the only
file that names ENet or reads an address; Steam comes in as another transport at M4). The Guest's gate word carries
the protocol (`PROTOCOL`), the scene layout hash (the sorted Part ids) and its player id (`PlayerProfile`,
`user://profile[_<tag>].json`); the Host refuses another version, a full game (4) or an id already playing, else
admits it, writes it into the `Roster` Part (keyed by player id: peer, name, colour, place; the next free colour,
0.6 m beside the Host or where it left) and sends one snapshot (`Parts.snapshot()`: every Part's State group by id),
which the Guest writes with `Parts.load_snapshot`. `Avatars` spawns by the Roster on the Host; falling Socks come
through the zoo's `FlightSpawner`. A leaver: `Parts.left` drops their Hands where they stood (`Hands.left`) and the
Roster keeps that place. `ZooNet` reads `--host`, `--join=`, `--profile=` and puts the toasts on the HUD.

**A save.** Not built yet: saving starts at the first outside play-test. The seam is the same snapshot
(`Parts.snapshot` / `load_snapshot`); settings are saved on their own by `Settings`.
