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

# The 17 Cabinets

M1 (Q2378). Today one Cabinet entity (core/04) uses the old "simple" cabinet model for every Collection. The old game had
one Cabinet per Collection with its own front art: `assets/cabinet/<collection>.glb` (17), the loose front art png, the
`.blend` sources, `tools/blender/make_cabinets.py`, `cabinet_art.py`.

## Behaviour list
- K01 Each Collection's Cabinet looks as in the old game, as a Looks of the one Cabinet entity (`game/entities/cabinet/`),
  chosen by the Cabinet's Collection; the drawers, their slide, the outline (core/11) and the balls shown in a drawer
  work on every one (the folder's `looks_contract.json`).
- K02 The Cabinet station shows every Collection's Cabinet (built from the Collections at load, Q2337).
- K03 The drawers' collision and Sock spots as the old ones, in the Godot scene.

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
- The 17 Cabinets are approved as on the first still; they keep 3 drawers, drawers growing by Stage come in M4
  (Q2385, 2026-11-21).

## Open follow-ups
- [later] Blender: the 17 glbs are the old exports copied unchanged (collider meshes still inside, unused: the
  collision is in the scenes). `make_cabinets.py`, `cabinet_art.py` and the `.blend` files are not ported to
  `tools/blender/` (no Blender in the sandbox). Port them, and re-export meshes only?
- [later] Kit: `asset_lint.py` reads only a scene's own text, so an inherited Looks (`instance=` of
  looks_simple) fails its contract. The 16 new Looks are therefore full copies of looks_simple with their meshes.

## Built log

### 2026-11-21 (first still)
- Changed: the 17 old Cabinet models as Looks of the one Cabinet and its drawers, chosen by the Cabinet's
  Collection (`Cabinet.dress()`, at ready and in `_show`); the Cabinet station lines up every Collection's
  Cabinet from the catalogue at load (`CabinetGallery`); the shot set `cabinets`; simple.glb moved to
  `assets/cabinet/`.
- Files: `assets/cabinet/`, `game/entities/cabinet/looks_*.tscn`, `game/entities/drawer/looks_*.tscn`,
  `game/entities/cabinet/cabinet.gd`, `game/zoo/cabinet_gallery*.gd`, `game/zoo/cabinet_gallery_layout.tres`,
  `game/zoo/stations/cabinet.tscn`, `tools/shot_hooks.gd`, `tools/shots/sets/cabinets.txt`.
- Verified: PASS 7491 checks, 259 cases (--touched); PASS asset_lint; PASS rules.

### 2026-11-21 (after the go, Q2385)
- Changed: tests for K01 (the Looks of every Collection against the contracts, the dress on a Cabinet and an
  open drawer), K02 (the station shows each Collection once, on its pad, in its Mess bounds; a new Collection in
  the catalogue gets a Cabinet), K03 (drawer front, shell and 25 slot points as the old models) and the real
  path (a Patterns Pair shelved by real input into the line-up's Patterns Cabinet); the station's pad
  (13 x 7.5 m) and Mess bounds cover the line-up; the station stays at its place in the zoo (its pad overlaps
  no other).
- Files: `tests/cabinet_looks_test.gd`, `game/zoo/stations/cabinet.tscn`, this ticket.
- Verified: PASS 8988 checks, 265 cases (--touched, every suite ran); PASS asset_lint; PASS rules.
- Merged: cdcab1cb (2026-11-21, branch assets/02-cabinets)
