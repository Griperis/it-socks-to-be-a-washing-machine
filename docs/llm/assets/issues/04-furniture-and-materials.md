---
type: ticket
status: ready-for-human
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

# House furniture and the shared material library

M1 for M2 (Q2378). Old: `assets/house/furniture/` (67 glb, `manifest.json`: moving parts, containers, colliders, Sock
spots), `tools/blender/house_furniture/build.py` and its group files; the old materials. One shared material library
for all models; where variants differ (oak: 9 in 39 models) the designer picks the one that stays from a strip
(Q2177). Things built by code become models or scenes (Q2178).

## Behaviour list
- F01 A shared material library (typed `.tres` materials) the furniture, the house kit (house/01-02) and later
  families use; a strip of each variant group (oak and the others) for the designer to pick the one that stays,
  **the first stop**.
- F02 Each piece is a scene with its model, its collision, its named moving parts (Door, Drawer_n, Lid, ...) as
  entities' Looks where they open (the cupboard pattern), and its Sock spots, from the old manifest (Q2151).
- F03 A furniture station in the zoo shows every piece, built from the folder at load (Q2337).
- F04 Origins at the floor centre of the bounding box, +Z front, as the old manifest says.

## Port rules (for every asset ticket)
- Ported by examination, technical improvements only (origins, scale, names, collision, shared materials, file size);
  a look change is its own ticket (Q2153). Blender scripts stay and build meshes only (`.glb`); placement, collision,
  spots and settings live in Godot scenes edited by hand (Q2151, Q2152). Each Looks passes `kit/tools/asset_lint.py`
  and its folder's `looks_contract.json`.
- Approved as a family: a before/after strip in `builds/review-<family>/`, old game beside new, stopped at the first
  still for the designer's go (Q2216). The old files: `reference/it-socks/` (see `docs/migration/assets-inventory.md`).

## Acceptance
- One test per behaviour line (the Looks contract, the station built from data, the real path where the player sees
  it); the strip in `builds/review-<family>/`, stopped at the first still for the designer's go.

## Answers
- Started beside M0.5 (Q2378, 2026-11-21).

## Open follow-ups
- [blocking] F01: which candidate stays in each of the 24 groups (strips in `builds/review-furniture/`,
  `materials-<group>.png`; `materials-strip.png` all of them; `materials-overview.png` the board). Most groups
  differ only in roughness (oak: one colour, roughness 0.4 to 0.8; the house kit's `oak_kit` 0.62 and not
  double-sided). The chosen file becomes `game/materials/<name>.tres` and its group folder goes.
- [blocking] F01: the old fab_* cloths carried glTF sheen (KHR_materials_sheen), which StandardMaterial3D has
  no field for and the old Godot import dropped too: keep them without it (as the old game looked), or a
  look change ticket?
- [later] F01: every old furniture material was double-sided (culling off); the library keeps it, as the old
  import did. Single-sided is cheaper; it can be tried per piece when the models are ported (F02).
- [later] The Materials station is its own station (one per feature) at the zoo's north edge, (-5.5, 17.5);
  the furniture station (F03) is still to come.

## Built log

### 2026-11-21 (first stop: F01 strips)
- Changed: the shared material library `game/materials/`: the 54 old furniture materials, 30 as one `.tres`
  each, 24 names the old game used with several sets of values as candidates (`candidates/<name>/<name>_<k>.tres`,
  k = 1 the set most pieces used, `_kit` the house kit's), each with its old pieces as metadata; written once
  by `tools/materials_from_old.py`. The zoo's Materials station: a board built from the folder at load
  (`MaterialBoard`); the shot set `materials`. No furniture built (waits for the go).
- Files: `game/materials/`, `tools/materials_from_old.py`, `game/zoo/material_board*.gd`,
  `game/zoo/material_board_layout.tres`, `game/zoo/stations/materials.tscn`, `game/zoo/zoo.tscn`,
  `tools/shot_hooks.gd`, `tools/shots/sets/materials.txt`, `tests/materials_test.gd`.
- Verified: `run.sh --touched` PASS 8430 checks, 122 cases (materials_test: real path, f01_library, f01_station,
  f01_from_data); grep_rules PASS; stills `builds/review-furniture/materials-*.png`, `materials-strip.png`.

