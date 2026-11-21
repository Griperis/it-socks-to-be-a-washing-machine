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
- Materials: in each group the variant the most old pieces used stays; on a tie the one nearest the group's
  median roughness; named `game/materials/<group>.tres`, the winner and its piece count recorded in
  `docs/architecture/materials.md` so any group can be overridden by name; the other files dropped (Q2389,
  2026-11-21).
- The fab_* sheen: ported without sheen for now, as the old game looked (Q2390, 2026-11-21).

## Open follow-ups
- [later] Q2390: a look-change ticket to give the fabrics (fab_*) a soft sheen: the designer wants it; the lead
  files it.
- [later] Small details of pieces that are devices, not assets, each still to be asked and ported in its own
  piece (all in the old game): the piano's 88 keys play a note and dip 3 degrees when played (house/28; the keys
  are named and carry their MIDI note, nothing moves them); the wall mirror's reflection (`mirror.gd`, its
  `MirrorGlass` mesh is kept); the sheeted sofa's dust sheet (`dust_sheet.gd`); the Old Tree's own shader
  (`old_tree.gdshader`; its lamp is ported); each opening's sound by its old container kind (`kind` metadata on
  each Openable, the old cue table in `game/house/openable.gd`).
- [later] Player collision: the old game gave players the manifest's coarser `colliders` (or one box over the
  footprint from `crawl_gap` up) and Socks the fine collision nodes; here both meet the fine collision, on the one
  house layer. A player layer of its own would need game/player (not this ticket's).
- [later] Blender: the 67 glbs are the old exports (collision nodes taken out, meshes renamed by
  `tools/furniture_from_old.py`); `house_furniture/*.py` is not ported to `tools/blender/` (no Blender here).
- [later] The Furniture station stands off the zoo floor's east edge on its own ground; the zoo's Mess bounds end
  at the floor, so a Sock thrown onto it goes back to the return spot.
- [later] Every old furniture material was double-sided (culling off); the library keeps it, as the old import
  did. Single-sided is cheaper; it can be tried per piece.
- [later] `tests/mess_test.gd` m04 (the zoo keeps a few thousand nodes with every Sock) now leaves out the
  Furniture station's own nodes (about 3,000: collision, openings, spots); the Sock rule it checks is unchanged.

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

### 2026-11-21 (the picks, F02-F04, second still)
- Changed: the 24 groups picked by Q2389 into `game/materials/<group>.tres` (table in
  `docs/architecture/materials.md`), candidates dropped. The 67 old pieces as scenes in `game/furniture/`:
  their old collision on the house layer, their still Looks, 28 openings the cupboard way (Openable, a Looks of
  AnimatableBody3Ds named as in the old model, "open"/"shut" as the old 0.35 s swing, the interior as Inside),
  584 Sock spot rects, the Old Tree's lamp; glbs cleaned and mapped to the library. The Furniture station lines
  them up from the folder; the shot set `furniture` puts each view beside the old models.
- Files: `assets/furniture/`, `game/furniture/`, `tools/furniture_from_old.py`, `game/zoo/furniture_line_up*.gd`,
  `game/zoo/furniture_line_up_layout.tres`, `game/zoo/stations/furniture.tscn`, `game/zoo/zoo.tscn`,
  `game/materials/`, `tools/shot_hooks.gd`, `tools/shots/sets/furniture.txt`, `tests/furniture_test.gd`,
  `tests/materials_test.gd`, `tests/mess_test.gd`, `docs/architecture/furniture.md`, `materials.md`.
- Verified: `run.sh --touched` PASS 14609 checks, 163 cases (furniture_test 9 cases incl. the real path); asset_lint
  PASS (97 glb, 145 look scenes); grep_rules PASS; stills `builds/review-furniture/furniture-beside-old.png` (each
  view old beside new), `furniture-*.png`, `materials-overview.png`.

