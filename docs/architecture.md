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
| The Sock generator | `docs/architecture/sock-generator.md` | you change where a level's starting Socks land, its areas, exclusions or preview |
| The house kit | `docs/architecture/house-kit.md` | you add or change a kit piece, a library material or the kit's sizes |
| The material library | `docs/architecture/materials.md` | you add, pick or change a shared material, or a model uses one |
| Furniture | `docs/architecture/furniture.md` | you place, change or add a furniture piece, its openings, collision or Sock spots, or a device (opening sounds, the piano, the mirror, the dust sheet) |
| The house level | `docs/architecture/house.md` | you change the house scene: its shell, furniture, lights, spawn or what it holds |
| Co-op | `docs/architecture/coop.md` | you touch the Session, the transport, the Roster, avatars, a Guest's guesses, a Throw's stream, knockdown, or anything a Guest sees or sends |

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

The main scene is the house (`game/house/house.tscn`, house/04, Q2509: F5 and a plain launch start there until
menus exist): the shell, the old furniture, the lamps and one level runtime. `Parts.bind` registers every Part by its
node path from the level's root (so the runtime's are `Runtime/Socks/Mess` and the like) and `LevelNet`
(`game/net/level_net.gd`) hosts or joins on `--host` / `--join=`. The zoo (`game/zoo/zoo.tscn`) starts with
`-- --zoo` or F6 in the editor: `ZooStations` joins every station's Socks to the zoo's one Mess (its runtime's)
before anything binds. Shots load the zoo unless a set line gives `--scene=`
(`tools/shot_hooks.gd` `SCENE`).

**A level (core/51, Q2517).** Every level shares one game setup, `game/level/level_runtime.tscn` (`LevelRuntime`):
the Player, Players and Avatars, Session and Roster, Net (`LevelNet`), Parts, Socks (Mess, Hands, Knockdowns, Coins),
Spots, Lying, Flights, the FlightSpawner and the LoadingScreen (house/09), wired inside it. It is sealed: a level instances it once, as a child of
its root named `Runtime`, and overrides nothing inside it (no editable children). What differs per level is set on
that instance: `spawn` and `return_spot` (empty: the level's children `Spawn` and `ReturnSpot`, the return spot
falling back to the spawn), `mess_bounds`, the player's `hands_tuning` and `upgrades`, and `place_name` (the corner's
word), and `load_screen` (the starting Socks laid behind the loading screen, `docs/architecture/sock-generator.md`). Before any of its nodes is ready it puts the player on the spawn, gives the Mess its return spot and bounds and
gives the Parts the whole level to bind. Code reaches its nodes with `LevelRuntime.of(node)` (the level or anything in
it: `.player`, `.mess`, `.hands`, `.session`, `.net` ...); `LevelRuntime.level_of(node)` is the level a runtime node
belongs to, where code used to read `owner`. **A new level** is a new scene: its geometry (and look: Environment, Sun,
Picture, lights), a `Spawn` marker and one instance of `level_runtime.tscn`; `game/level/one_box_level.tscn` (one
floor box) is the smallest, walked and played in co-op by `tests/level_test.gd`.

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
which the Guest writes with `Parts.load_snapshot`. `Avatars` spawns by the Roster on the Host (an `Avatar` per player: its pose, position, yaw, pitch and crouch, goes from its owner every network frame and is checked in its setters where it lands; elsewhere it eases to it, its `AvatarLooks` derives the waddle, bend, squash and pupils, a worn `HeldView` hangs its Hands at the HoldPoint, where a Teammate's Throw leaves, and `TeammateSteps` plays its steps at its body; `Hearing` plays a Teammate's cues with `Sounds.play_from` at 1.2 m over their feet); thrown Socks come
through the zoo's `FlightSpawner`, each with its stamped row (`FlightRow`); a Guest's own actions show at once
as looks-only guesses (`GuestGhosts`) until the Host's answer, matched by the Command's `seq`. A leaver: `Parts.left` drops their Hands where they stood (`Hands.left`) and the
Roster keeps that place; the leaver's machine (every Guest's, when the Host quits) is a Host of one and
`Parts.went_alone` turns its looks-only bodies into its own (coop/12). `LevelNet` reads `--host`, `--join=`, `--profile=` and puts the toasts on the HUD.

**A knockdown (coop/10).** `Knockdowns` (`game/knockdown/`, one Part under `Socks`, keyed by peer) holds who is down
(their fall, a serial), who drags whom and the struggle presses. On the Host it tests every full-charge Throw in the
air (the launch carries its `charge`) against each player's body every tick and asks `knock`, a Host-only verb whose
answer also drops the knocked player's Hands through `Hands.left`; `grab`, `let_go` and `struggle` are players'.
`down` counts on each machine's own clock. Each `Avatar` follows it every frame: its `Ragdoll` child
(`game/parts/avatar/ragdoll.tscn`: a Skeleton3D, a PhysicalBoneSimulator3D and four PhysicalBone3D, never drawn, the
Host its multiplayer authority) is simulated on the Host and streams one stamped 84-byte pose on its own Sync;
elsewhere its bones are kinematic and ease to that pose; every machine plays the rise itself. The avatar's Looks
copies it (`AvatarLooks.copy_ragdoll`), and its `Mate` capsule (what a falling ragdoll bumps) is off while it lies.
The knocked `Player` freezes its input, stays at its ragdoll's feet, puts the camera on the ragdoll's head and shows
the vignette (`game/knockdown/vignette.tscn`); a lying body under the crosshair shows its Outline (a child of the
avatar's Looks) and wins the left button for a drag.

**A save.** Not built yet: saving starts at the first outside play-test. The seam is the same snapshot
(`Parts.snapshot` / `load_snapshot`); settings are saved on their own by `Settings`.
