---
type: ticket
status: done
kind: build
area: house
feature: house
priority: now
created: 2026-11-21
done: 2026-11-23
blocked_by: []
notes: []
terms: []
---

# The old house's shell details the kit still lacks

From house/03's comparison with the old house (Q2391, 2026-11-21; `builds/review-house-03/side-*.png`). Each is a kit
piece or a fix, ported from `reference/it-socks/tools/blender/make_house.py` and `make_exterior.py`; shaped and asked
before it is built.

## Behaviour list (draft)
- D01 The bathroom's tile wainscot (a skin in the old shell; a kit piece or a wall face material).
- D02 The basement light wells: concrete walls and grates outside the well windows.
- D03 The plinth: the house stands 0.3 m over the lawn on a plinth, as the old house did.
- D04 The front step at the front door.
- D05 Fences, trees and the street around the house (the old exterior; may become its own asset ticket).
- D06 The garage ramp as the old one, not a plain slope.
- D07 The elevator shaft: walls and floor lips instead of an open hole on the ground, first and attic floors (the
  elevator itself is an entity, M5).
- D08 The station's name label no longer floats over the house in exterior views.
- D09 The small orange marks on the south roof slope seen from the front (also in the old still): explained or fixed.

## Design
The house is the game's own scene, not a zoo station (Q2503). Shell and furniture only: no game functions in it yet (M3 brings the core loop into the house). Rooms, windows and doors as house B has them on the 0.5 m grid (house/02, house/03).

## Acceptance
- `game/house/house.tscn`: house B moved out of the zoo into its own playable scene, built only from the kit's pieces, with the player and the shared-state path set up as in the zoo (a Host of one; `--host` and `--join` work there too). It is the game level and the project's main scene (F5 and a plain launch start in the house) until menus exist (Q2509); the zoo stays playable with `-- --zoo` and by running `zoo.tscn` in the editor (F6).
- `old_house_a.tscn` and its zoo instance are removed; `old_house_b.tscn` goes from the zoo too once `house.tscn` holds it.
- The shell details, the house only: the bathroom's tile wainscot (D01), the elevator shaft's walls and floor lips (D07), the orange marks on the south roof explained or fixed (D09). D08 goes with the move out of the zoo. Out (Q2503, Q2511): nothing outside the house: no lawn, plinth, step, ramp, fences, trees, street or light wells (D02-D06). The player starts inside at the old spawn (`reference/it-socks/game/house/room.gd` spawn_pos and spawn_yaw, moved with the re-gridded plan).
- The ported furniture (assets/04) placed where the old house had it (from `reference/it-socks/tools/layout.py`), so Play walks through a furnished house, as M2's "done when" says (Q2510).
- Light: the zoo's noon light (sun, sky, AgX, grade) plus each old room lamp's light as the old house had it (the old lamp lights' places, colours, energy and range, written in the Built log) (Q2512).
- Walkable in first person on every floor, stairs included; a test walks the player from the spawn to every floor.
- A strip in `builds/review-house-04/`: each floor, old beside new, furnished and lit.

## Answers
- Q2509-Q2512 (2026-11-23): see the acceptance.
- Q2503 (2026-11-23): the house only, no exterior; keep house B (windows on the 0.5 m grid), remove house A; the house becomes a main scene launched from the game, built from the kit pieces.
- Q2504 (2026-11-23): built to the end with no stop at the first still; a before and after strip for the designer's batch review before the merge.

## Open follow-ups
- [later] D01 found: the old house's own shell (make_house.py) has no bathroom wainscot (the old still shows plain
  walls); the numbers are the old flat's (make_flat.py make_wall_tiles: tiles to 1.2 m, a trim 3.5 cm over).
  Built as a wall paint (`wall_bathroom_tiled`), so the trim band is painted, not a raised board. Keep it?
- [later] D07: the shaft's walls are the old "door" cream, its sill stainless; the hatch's frame, panel,
  buttons and car are the elevator entity's (M5).
- [later] D09 explained: the balustrade's side rails ran to the south wall, under the 40 degree slope, so their
  ends came out through the roof (the old house too). They now stop where the slope clears the handrail by
  5 cm; the rail ends there without a post. A post or a rail that follows the slope instead?
- [later] Nothing outside the house (Q2503): a player who walks out of the front door or the garage door falls
  for ever. A floor, a fall catch or a shut door until the exterior ticket?
- [later] Every lamp is lit at noon. The old house switched all but the basement's off by day and lit each
  floor's lights only on its own floor (light layers); neither is ported.
- [later] The corner label and the joiner's line say "house" ("Joined <name>'s house"), the zoo's "zoo":
  placeholder wording.
- [later] The old openables' own names (the fridge's Fridge and Freezer, the car's CarBoot) are not carried
  over: the openings keep the furniture scenes' node names.
- [later] Kit: `kit/tools/shot.gd` reads only the main scene as its default; the game's `tools/shot_hooks.gd`
  setup() sets the harness's `_scene` to the zoo so the old sets still work. A hooks constant (as the runner's
  `WORLD`) would be cleaner. `kit/tools/net_shot.gd` loads the main scene: co-op net shots now start in the house.
- [later] The strip's room-kitchen view stands in the fridge's player box (the old view point, 0.7, 0.7, is where the
  fridge now stands), so it shows the fridge's side; the old baseline still was taken before the fridge stood there.
- [later] `tools/house_kit_build.gd` (1181 lines) and `tools/shot_hooks.gd` (714) are over grep_rules' 600:
  to split.

## Built log

### 2026-11-23
- Changed: the house is the game's level and main scene (`game/house/house.tscn`): house B's shell
  (`game/house/shell.tscn`, kit pieces only, no ground), the 66 old furniture placements moved to the plan, the
  old lights, the zoo's noon light, the player at the old spawn in the laundry, the zoo's shared-state path with
  `LevelNet` (`--host`, `--join=`; `ZooNet` extends it). `-- --zoo` starts the zoo. Both old-house stations
  gone (D08 with them); the Furniture station moved from x 75.5 to 21.5, next to the zoo floor, as nothing led
  to it any more. Shell details: the shaft's walls, hatches and sills (D07), the bathroom's tile wainscot
  (D01), the balustrade no longer through the roof (D09). Lights (room.gd `_build_light`): colour
  (1, 0.88, 0.7); 18 ceiling lights 8 cm under the old markers, in proportion across their rooms, energy 1,
  range 6, shadow (blur 2, bias 0.05); the floor lamp's (1.38 m up) and the nightstand's lamps, energy 0.7,
  range 3, no shadow. Spawn (1.68, -3, 5.87), yaw 0.922.
- Files: game/house/house.tscn, shell.tscn, kit/ (3 shaft pieces, wainscot.gdshader, 3 materials, balustrade),
  game/net/level_net.gd, game/zoo/zoo_net.gd, zoo.tscn, game/debug/game_cli.gd, project.godot,
  tools/house_shell_build.gd (was old_house_build.gd), house_from_old.py, house_kit_build.gd, shot_hooks.gd,
  shots/sets/house.txt, tests/house_test.gd (was old_house_test.gd), game_cli_test.gd, zoo_test.gd,
  docs/architecture.md, architecture/house.md, house-kit.md, furniture.md.
- Verified: `PASS 16354 checks, 455 cases` (--touched: every suite, project.godot); house 14 cases incl. the real paths spawn to the attic and front door to the attic;
  `PASS rules`, `PASS asset_lint`. Strip: `builds/review-house-04/floor-1-basement.png` .. `floor-4-attic-outside.png`
  (old, house/03, house/04 per view) and the `house` set's stills (`house-roof-south.png`: D09).
