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

<Boot, a frame, a save, a join: one short list each, naming files, once they exist.>
