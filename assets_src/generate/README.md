# The Blender scripts that build the game's models

Ported from the old game's `tools/blender/` (ticket `docs/llm/assets/issues/08-model-sources.md`, Q2400). They build
**meshes only** (Q2152): shapes, materials, UVs, rigs and LODs, the Cabinet's slot points. Where a thing stands, its
collision, its Sock spots and its settings live in the Godot scenes and are never written from here.

| Family | Script | Source files it builds | glb in the game |
|---|---|---|---|
| Sock shapes (4) | `sock/make_socks.py` | `assets_src/blender/sock/socks.blend` | `assets/sock/<shape>.glb` |
| Sock knit tile (1) | `sock/make_knit.py` (run alone: `blender -b -P assets_src/generate/sock/make_knit.py -- [--out <png>]`; a picture, no `.blend`, assets/05) | none | `assets/sock/knit.png` |
| Sock balls (9) | `sock/make_sock_balls.py` | `assets_src/blender/sock/sock_balls.blend` | `assets/sock/ball_<cuff>.glb` |
| Cabinets (17) | `cabinet/make_cabinets.py` (+ `cabinet_art.py`, the front art; `appliance_family.py`, shared helpers) | `assets_src/blender/cabinet/cabinet_<collection>.blend` | `assets/cabinet/<collection>.glb` |
| Furniture (67) | `furniture/fkit.py` (+ `kit.py`, the look; the group files `basement.py`, `ground.py`, `first.py`, `attic.py`, `plants.py`, `grotto.py`, one function per piece) | `assets_src/blender/furniture/<piece>.blend` | `assets/furniture/<piece>.glb` |
| Floor locks (2) | `lock/make_locks.py` (the old `make_house.py` locks, fitted to the port's flight; assets/10) | `assets_src/blender/lock/lock_<kind>.blend` | `assets/lock/lock_door.glb`, `assets/lock/lock_gate.glb` |
| Avatar (2) | `avatar/make_avatar.py` (the old script unchanged but its header; its own export keeps the glTF extras and the Crouch key, no root object, facing -z as the old game; not in `blender_assets.json`, coop/04) | `assets_src/blender/avatar/avatar.blend` | `assets/avatar/avatar.glb`, `assets/avatar/feet.glb` |
| Machine Parts (4) | none yet: the old `tools/blender/make_part_*.py` build on `washer_parts.py`, the washer's (assets/14); the old `.blend` and glb came over unchanged (assets/12) | `assets_src/blender/parts/part_<old name>.blend` (`part_belt` is the drum belt) | `assets/parts/<kind>.glb` |
| Laundry bin (1) | `tools/blender/laundry_bin.py` (the old `make_laundry_bin.py` with the bits of `washer_parts.py` it needs; builds, exports the root's children only, `--save` writes the source; no collider: the entity's box; assets/13) | `assets_src/blender/laundry/laundry_bin.blend` | `assets/laundry_bin/laundry_bin.glb` |
| Encyclopedia book (1) | `tools/blender/encyclopedia_book.py` (the old `make_encyclopedia_book.py`; exports the root's children, no collider, `--save` writes the source; assets/17) | `assets_src/blender/encyclopedia_book/encyclopedia_book.blend` | `assets/encyclopedia_book/encyclopedia_book.glb` |
| Wardrobe Station (1) | `tools/blender/wardrobe_station.py` (the old `make_wardrobe_station.py`; exports the root's children, no collider: the station's box, `--save` writes the source; `oak`, `dark_wood`, `brass` are the library's; assets/20) | `assets_src/blender/wardrobe_station/wardrobe_station.blend` | `assets/wardrobe_station/wardrobe_station.glb` |
| Washing machine (1) | `appliance/make_washing_machine_face.py` (the old face script, applied to the model in its `.blend`; its own export: no root object, the eight actions, assets/14) | `assets_src/blender/appliance/washing_machine.blend` | `assets/appliance/washing_machine.glb` |
| Sock vacuum (2) | `sock_vacuum/make_sock_vacuum.py` (the old `make_sock_vacuum.py` and `make_nozzle_display.py` on `cabinet/appliance_family.py`, and the hose the old game drew in code as a skinned tube of 12 bones; exports the root's children, no collider, `--save` writes the sources; assets/24) | `assets_src/blender/sock_vacuum/sock_vacuum.blend`, `hose.blend` | `assets/sock_vacuum/sock_vacuum.glb`, `assets/sock_vacuum/hose.glb` |
| House shell | `house/make_house.py`, `house/make_flat.py`: kept to read, not run (see `house/README.md`) | none | none |

`assets/blender_assets.json` lists every source (`source`, relative to `assets_src/blender/`) and its glb.

## Run

Blender is the kit's pinned one (`kit/tools/blender.sh`, 5.3). From the repository root:

    blender -b -P assets_src/generate/build.py -- <family> [--only a,b] [--out <dir>] [--save] [--no-export]

- `<family>`: `sock`, `cabinet`, `furniture`, `lock`, `avatar` or `appliance`. `--only` takes shapes and balls (`crew`, `ball_crew_plain`),
  Collections (`food`) or pieces (`sofa`).
- Without `--out` the glbs are written **over the game's own files**. Write to a scratch folder first and compare.
- `--save` also rewrites the family's `.blend` sources from the script.
- The last line is `PASS build <family>: <n> models` or `FAIL build ...`.

To export from a `.blend` (after editing it by hand) instead of from the script:

    assets_src/generate/export.sh [--out <dir>] <asset>...       # or --family sock|cabinet|furniture

It prints the kit's contract report for each asset (`kit/tools/blender/asset_checks.py`; advice only, see below) and
one `EXPORT-OK` line. The kit's own `kit/tools/blender/export.sh` cannot be used for these yet (see below).

## The mesh check

    python3 assets_src/generate/glb_compare.py <new dir or glb> <game dir or glb>

Plain Python. Compares node names, parents and transforms, each mesh's materials, vertex and triangle counts and
every vertex position (0.1 mm tolerance), the skins' bones, and the embedded pictures pixel by pixel. Collision-only
nodes are skipped. Prints `MESH-SAME` or `MESH-DIFF` per glb and `PASS glb_compare` or `FAIL glb_compare`.

Last run (2026-11-21, bpy 5.3.0), both from the scripts and from the `.blend` files; from the scripts again with the
pinned Blender binary 5.3.0 (`kit/tools/blender.sh`): 97/97 the same.

| Family | From the script | From the `.blend` |
|---|---|---|
| Sock shapes and balls | 13/13 the same | 13/13 the same |
| Cabinets | 17/17 the same (front art pixels too) | 17/17 the same |
| Furniture | 67/67 the same | 67/67 the same |

## Without the Blender binary

`bpy_run.py` runs any of these with pip's `bpy` module instead (same version, 5.3; meshes and glbs come out the same,
renders do not work). bpy 5.3 needs Python 3.13:

    uv venv --python 3.13 <dir> && uv pip install --python <dir>/bin/python "bpy==5.3.*"
    <dir>/bin/python assets_src/generate/bpy_run.py assets_src/generate/build.py -- sock --out <scratch>
    BPY_PYTHON=<dir>/bin/python assets_src/generate/export.sh --out <scratch> --family cabinet

## What differs from the old scripts

- `make_cabinets.py`: no collider boxes (`shell-convcolonly`, `drawer_front-convcolonly`); `build()` no longer
  calls the old contract checks. The Patterns front art keeps its old image name `casual_front_art`: Godot names
  the picture it takes out of the glb after it (`assets/cabinet/patterns_casual_front_art.png`).
- `furniture/fkit.py`: no Sock colliders (old `sockcol.py`), no resting tops (old `tops.py`), no manifest. The group
  files still record boxes, containers and lamps through the old calls (`P.collide`, `P.container`, `P.sock_*`,
  `P.extra`); nothing is built from them, so the group files are the old ones and build the same meshes.
  `furniture/kit.py` is the old `tools/blender/style_trial/kit.py`.
- `build.py` builds each furniture piece in its own empty scene; the old `house_furniture/build.py` built a room's
  pieces together for its line-up render. The line-up renders and `label.py` are not ported.
- The Cabinet and furniture `.blend` files differ in one way: the 17 Cabinet sources are the old game's own
  (hand-modelled through the MCP, still holding the two collider boxes, which the game ignores); the 67 furniture
  sources were written by `build.py --save` (the old game kept none).

## Known gaps (follow-ups in the ticket)

- `kit/tools/blender/export.sh` and `asset_checks.py` look for `assets/blender_assets.json` inside `kit/`
  (`REPO` is two folders up from `kit/tools/blender/`), and its `BUDGETS` has no `sock` (320) or `sock_ball` (540)
  class. `export.py` here points the checks at the game's manifest and only shows their report.
- The kit's contract wants snake_case node names; the game's furniture contract uses `Body`, `Door_L`,
  `Drawer_1` ..., and 18 old pieces have more than 8 materials. Advice only; the export does not stop on them.
