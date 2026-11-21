# The old house shell's scripts: to read, not to run

`make_house.py` and `make_flat.py` (the old game's `tools/blender/`, `v0.1.1`, copied unchanged) built the old house
as one model, `assets/house/house.glb`, with 1,003 collision-only nodes, plus `house_layout.json`: every placement,
collider, light and window of the house in one file. They are here so the old rooms, sizes and openings can be looked
up next to the other sources (ticket `docs/llm/assets/issues/08-model-sources.md`, M01).

They are not ported to run, and this project has no `house.glb` to compare a run with:

- This game builds the house in Godot from numbers, not from one Blender model: the kit pieces come from
  `tools/house_kit_build.gd` and `game/house/kit/house_kit_sizes.tres` (`docs/human/house-kit.md`).
- Most of what the scripts write is what Q2152 keeps in the Godot scenes: placement (`house_layout.json`), collision
  and lights. A meshes-only port would leave walls and floors with no game file to go to.
- `make_house.py` also reads the old plan (`docs/art/house/plan.py`) and writes into `assets/house/` and
  `assets/flat/`, which are not part of this project.

To read the old numbers for a room, grep these files (`make_house.py` lists the rooms, doors and windows near its
top); the old plan itself is `reference/it-socks/docs/art/house/plan.py`.
