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

## Open follow-ups
- [blocking] The first still waits for the designer's go: `builds/review-assets-02/cabinets-all-17.png` (all 17,
  new), `cabinets-old-beside-new.png` (the three baseline views cab-simple, cab-patterns, cab-winter beside the
  new), `cabinets-overview.png`, one `cabinets-<collection>.png` each. Not built yet, after the go: the tests (K01
  the Looks contract and the dress per Collection, K02 the station from data, K03 the colliders, the real path).
- [later] The old views show 5 (simple), 4 (patterns) and 3 (winter) drawers: the old Cabinet grew a drawer per
  Stage; the new one has 3 (core/04). Is that M4's growth, as planned?
- [later] Blender: the 17 glbs are the old exports copied unchanged (collider meshes still inside, unused: the
  collision is in the scenes). `make_cabinets.py`, `cabinet_art.py` and the `.blend` files are not ported to
  `tools/blender/` (no Blender in the sandbox). Port them, and re-export meshes only?
- [later] The line-up stands east of the station's pad (world x 12 to 19, z 2 to 7, clear of the heap's and the
  sounds' pads) and outside its Mess bounds (a Sock thrown there goes back to the return spot). The lead may move
  or grow the station in `zoo.tscn`.
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
