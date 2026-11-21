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

# The Sock models and prints

M1, started beside M0.5 (designer, Q2378, 2026-11-21). The graybox Sock is the old `crew.glb`, tinted (Q2249). The old
look is four shape models with shared bones, nine ball models and one pattern shader with a prints atlas, not a model
per Design (2026-11-20). Old: `assets/sock/` (4 shapes ankle, crew, tube, chunky; 9 balls), `assets/sock/prints.png`
(3072x4608, 12x18 cells of 256 px, 206 motifs) and `prints.json`, the old pattern shader and how a Design picks its
shape, colours, pattern and print (`data/designs.json`, the old sock look code: grep `reference/it-socks/game/world/`
for the shader and `sock_look`/`dress`), `tools/blender/make_socks.py`.

## Behaviour list
- S01 Every Design is drawn as in the old game: its shape (by Collection, scaled by Size), its colours, its pattern (solid, dots, stripes,
  ...) and its print from the atlas, through one shader; the every-Sock station shows all of them.
- S02 The four shape models share one skeleton (Cuff, Leg, Heel, Foot, Toe as the stand-in), so the cloth (core/09)
  and the Looks contract work on every shape.
- S03 A Pair is drawn by its ball model as the old game picked it; the pairing moment shows the right ball.
- S04 The lying tier draws the same look: the MultiMesh instance data (colour plus INSTANCE_CUSTOM, core/13's layout,
  `MessDrawing.look_data()`) feeds the same shader, so a held, flying and lying Sock look alike (no change at rest).
- S05 LODs as the old models had, within the old budgets (sock 320 tris, ball 540).

## Design (draft)
New Looks scenes beside the graybox (`game/sock/looks_<shape>.tscn`, `looks_ball_<name>.tscn`, the shader in
`game/sock/`), the Design-to-look mapping in the Design data or a typed Resource. The swap of the Sock entity's Looks
waits until core/23 (which owns the flight scenes and the Mess) has merged: build and test the new Looks and the
shader on their own and in a zoo comparison, then swap in a last commit after merging main.

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
- The models, balls, shader and prints are approved; the shape follows the Collection, as the old game. Look
  updates come later in assets/05 (Q2384, 2026-11-21).

## Open follow-ups
- [later] The lying bodies (MessBodies) and SockDress.box() still fit the crew model for every shape, so
  an ankle Sock's box is a little big and a chunky Sock's a little small when Socks stack; the Pair
  balls use their own radius. Per-shape boxes are a physics change for the Mess's owner.
- [later] The cloth (core/09) is tuned on the crew Sock: on the small ankle Sock its chain dips 3.9 mm
  below the floor in flight (d05 allows 3 mm) and lags less when walking. hand_details now takes a
  small crew Sock (Design 135) for its cases; per-shape cloth numbers are the designer's call.
- [later] Kit: the test and shot mirror (`kit/tools/_mirror.sh`) leaves out every `*.import`, so tests and
  `shot.sh` import with Godot's defaults: no `model_lods_import.gd` (SockLook.dress folds the LODs at run
  time there too) and `prints.png` VRAM-compressed, so print detail in shot.sh stills is softer than in
  the game. The review stills were rendered straight from the worktree for that reason.
- [later] The old Blender scripts (`make_socks.py`, `make_sock_balls.py`) are not ported; the 13 .glb and
  `prints.png` are the old files, unchanged. `prints.json` (motif names) was not copied: the Designs
  already hold atlas cells and the grid is in `sock_looks.tres`.
- [later] LOD switch sizes (ModelLods MID_PX 64, FAR_PX 24) are the old game's own placeholders.

## Built log
- 2026-11-21 (after the designer's go, Q2384, and core/23's merge)
  - Changed: the swap. SockDress makes and dresses every Looks through SockLook (shape and ball by
    Collection, the sock shader), with `swap()` for a scene's stand-in Looks; the pairing moment shows the
    Design's own Socks and ball; MessDrawing draws one MultiMesh per Collection shape with its instance
    material (lying and flying tiers), the LODs folded; a Pair's ball radius is its ball's. The graybox
    crew.glb, ball_crew_plain.glb, looks_graybox.tscn and looks_ball.tscn are gone. Tests: S04's tiers
    (a lying instance and its lent Looks: one mesh, place and material; held and flying Looks alike).
  - Files: game/sock/sock_dress.gd, sock_look.gd, pair_moment.tscn; game/mess/mess_drawing.gd;
    game/hands/held_view.gd; tests/sock_looks_test.gd, pairing_test.gd, hand_details_test.gd;
    docs/architecture/mess.md.
- 2026-11-21 (stopped at the first still, look work)
  - Changed: the four shape models and nine sock balls as Looks scenes (Looks contract, cloth on the
    shared Cuff-Leg-Heel-Foot-Toe skeleton, balls centred), the old pattern shader unchanged, the
    Design-to-look table (shape, cloth, ball per Collection; the shader's fit per model), SockLook
    (material, instance material, make/dress), the old hand-made LODs folded at import (ModelLods), the
    Sock looks station in the zoo built from the data, a `sock_looks` shot action.
  - Files: assets/sock/ (13 .glb, prints.png, imports), game/sock/sock_look.gd, sock_look_table.gd,
    sock_cloth_fit.gd, sock_looks.tres, sock_pattern.gdshader, model_lods.gd, model_lods_import.gd,
    looks_<shape>.tscn x4, looks_ball_<cuff>.tscn x9; game/zoo/sock_looks_station.gd, sock_looks_layout.*,
    stations/sock_looks.tscn, zoo.tscn; tools/shot_hooks.gd, tools/grep_rules_allow.txt;
    tests/sock_looks_test.gd.
  - Still: builds/review-assets-01/ (lineup-old-new.png, collections-, patterns-, balls-old-new.png,
    top-diff.png): the old render is the old v0.1.1 code, models, prints and shader in a scratch project,
    same places, sky, sun and camera; the only differences are edge anti-aliasing.
  - Verified: PASS 6444 checks, 110 cases; PASS rules; PASS asset_lint
