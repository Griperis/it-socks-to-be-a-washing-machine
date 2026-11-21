---
type: ticket
status: ready-for-agent
kind: build
area: assets
feature: assets
priority: now
created: 2026-11-21
done:
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

## Built log
- Model: Opus (lead): Blender scripts and the pinned Blender.
