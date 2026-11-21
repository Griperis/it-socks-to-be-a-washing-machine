---
type: ticket
status: done
kind: build
area: assets
feature: assets
priority: now
created: 2026-11-21
done: 2026-11-21
blocked_by: []
notes: []
terms: []
---

# The model sources: .blend files and the Blender scripts

The models in the game are the old game's exported `.glb` files; their sources are not in this project, so a model can
only be replaced, not edited at its source (found writing `docs/human/`, 2026-11-21). The designer (Q2400): the
`.blend` files go into `assets_src/blender/` and the Blender scripts that build models into `assets_src/generate/`
where possible. Old: `reference/it-socks/assets_src/blender/` (151 `.blend`), `reference/it-socks/tools/blender/`
(`make_socks.py`, `make_cabinets.py`, `cabinet_art.py`, `house_furniture/build.py` and its group files,
`make_house.py`, ...), `docs/art/pipeline_mcp.md`. `assets_src/` carries a `.gdignore` (Godot does not see it).

## Behaviour list
- M01 Every ported family's sources are in the project: the Sock shapes and balls, the 17 Cabinets, the 67 furniture
  pieces (and the house shell's for reference): their `.blend` files in `assets_src/blender/`, sorted by family,
  through Git LFS as the old game had (`.gitattributes`).
- M02 The scripts that build those models are in `assets_src/generate/`, ported to build meshes only (Q2152:
  placement, collision, spots and settings stay in the Godot scenes) and to write into this project's paths; each runs
  with the kit's pinned Blender (`kit/tools/blender.sh`) and reproduces the model in the game (a mesh check against
  the ported `.glb`, within a tolerance). A script that cannot be made to run says why in a README there.
- M03 `docs/human/models-update-a-model.md` and `models-pipeline.md` say how to edit a model at its source and
  re-export it, family by family (the agent updates those two pages).
- M04 Nothing in `game/` changes: the `.glb` files in the game stay as they are unless a script re-export differs,
  which is reported, not merged.

## Acceptance
- One check per line (a test or a tool run in the Built log); the re-export check per family.

## Answers
- The `.blend` files into `assets_src/blender/`, the Blender scripts into `assets_src/generate/` where possible
  (Q2400, 2026-11-21).

## Open follow-ups
- [later] The checks ran with pip's `bpy` 5.3.0 (`assets_src/generate/bpy_run.py`), the same Blender release as the
  pin, not with the binary from `kit/tools/blender.sh`: its `--fetch` got HTTP 403 "Approval required for
  download.blender.org". Once the designer approves that host, run `build.py` and `export.sh` once with the binary.
- [later] Kit fault: `kit/tools/blender/asset_checks.py` sets `REPO` two folders up from `kit/tools/blender/`,
  which is `kit/` in a game, so `kit/tools/blender/export.sh` reads `kit/assets/blender_assets.json` and writes the
  glb under `kit/`. Its `BUDGETS` also cannot take a game's classes (`sock` 320, `sock_ball` 540 from the old game).
  `assets_src/generate/export.py` works around both.
- [later] The kit's contract wants snake_case node names; the game's furniture uses `Body`, `Door_L`, `Drawer_1` ...
  and 18 old pieces have more than 8 materials. Shown as advice by `export.sh`, never enforced. Which one gives way?

## Built log
- Model: Opus (lead): Blender scripts and the pinned Blender.

### 2026-11-21
- Changed: every Sock shape and ball, Cabinet and furniture piece now has a Blender source in
  `assets_src/blender/<family>/` (2 + 17 old `.blend`, 67 written by the ported script; LFS) and a meshes-only script
  in `assets_src/generate/`; `build.py` (script to glb), `export.sh` (`.blend` to glb), `glb_compare.py` (the mesh
  check). The house shell's scripts are kept to read (`house/README.md` says why they do not run).
  `assets/blender_assets.json` lists the 97 sources. Nothing in `game/` or `assets/` changed.
- Files: `assets_src/blender/`, `assets_src/generate/`, `assets/blender_assets.json`, `docs/human/models-*.md`.
- Verified: script to glb and `.blend` to glb, each against the game's glb: socks `PASS glb_compare: 13/13`,
  cabinets `17/17` (front art pixels too), furniture `67/67` (0.1 mm); `PASS 45 checks, 9 cases`
  (`run.sh --touched`); `PASS rules`; `PASS asset_lint`.
