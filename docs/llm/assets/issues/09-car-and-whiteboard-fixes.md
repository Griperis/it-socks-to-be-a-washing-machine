---
type: ticket
status: done
kind: build
area: assets
feature: assets
priority: now
created: 2026-11-23
done: 2026-11-23
blocked_by: []
notes: ["designer's house walk, 2026-11-23"]
terms: []
---

# Model fixes: the car's window gaps and separate doors; the whiteboard's pens

From the designer's walk of the house (2026-11-23):
1. **The car has gaps between its windows:** close them so the glass and frame meet with no see-through slit.
2. **The car's doors open separately:** each door is its own opening that a click opens and shuts by itself
   (with the openables' sound, assets/07), not all together. Its insides (Socks lie in the cabin, core/52) stay
   reachable through any open door.
3. **The whiteboard's pens overlap:** each pen lies apart on the tray (find which furniture piece carries the
   whiteboard; `game/furniture/collection_board.tscn` is a guess).

## Design
Fix the meshes at their Blender source (`assets_src/blender/`, the game-kit:blender-3d-modelling skill), re-export,
and keep the furniture scenes' collision and Spots in line (the car's cabin `Inside` box). The doors: the car's
openings as the other openables (Part, Openable; one opening per door), by the kit's and assets/07's rules.

## Acceptance
- Real path for the doors: aim at each door, click: only that door opens, its sound plays, a click again shuts it.
- Stills for the designer: the car's windows close up, each door open alone, the whiteboard's tray
  (`builds/review-assets-09/`); the window and pen fixes are looks only (no test, Q2421).

## Open follow-ups
- [later] Both car doors' prompt reads "Car Door" (Openable `title`; before, the one opening read "Cabin", its
  node name). The wording is the designer's.
- [later] The window slit is closed with a body-colour sill (6 cm high, 10 cm deep) under the side and rear glass,
  on the body, each door and the tailgate; the glass and pillars stay where they were. If the designer would
  rather have the glass moved out onto the body's wall instead (no sill), that is a remodel of the greenhouse and
  its colliders.
- [later] Every other furniture `.blend` saved by assets/08 still names its meshes `<piece>_<node>`: exported as
  is, Godot names them `<piece>_<piece>_<node>` and its `.glb.import` no longer saves them to
  `meshes/<piece>_<node>.res` (the Looks then show the old mesh). fkit.py names them `<node>` now; rebuild a piece
  with `build.py ... --save` (or rename its meshes) before its next export.

## Built log
- 2026-11-23
  - Changed: the car's side and rear glass meet the body with no see-through slit (a sill under the glass, on
    the body, each door and the tailgate); the whiteboard's three markers lie end to end apart on the tray. The
    car's Cabin opening is now two, DoorL and DoorR: each door its own Openable and Looks (one AnimationPlayer
    per door), opening by itself with the cupboard sounds onto its half of the cabin floor (the Inside box split
    in two). fkit.py names meshes as their nodes so Godot saves them to `meshes/<piece>_<node>.res`.
    Furniture openings 28 -> 29.
  - Files: assets_src/generate/furniture/{basement,fkit}.py, assets_src/blender/furniture/{car,collection_board}.blend,
    assets/furniture/{car,collection_board}.glb, assets/furniture/meshes/{car,collection_board}_*.res,
    game/furniture/car.tscn, game/furniture/parts/looks_car_door_{l,r}.tscn (was looks_car_cabin.tscn),
    tests/{furniture,furniture_devices}_test.gd, tools/shot_hooks.gd, tools/shots/sets/car-and-board.txt,
    docs/architecture/furniture.md. Stills: builds/review-assets-09/ (shot set car-and-board, car-slit-before-after.png).
  - Verified: run.sh --touched: PASS 12894 checks, 290 cases (new real path furniture_devices:car_doors_real_path:
    a left click on each door opens only it with cupboard_open, a click again shuts it with cupboard_close);
    grep_rules PASS; asset_lint PASS.
- Merged: 1444b48d (2026-11-23, branch assets/09-car-and-whiteboard-fixes)
