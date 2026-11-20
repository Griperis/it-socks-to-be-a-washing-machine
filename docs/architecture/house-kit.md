# The house kit

What the house is built from by hand in the editor (house/01, Q2154-Q2157, Q2175, Q2325-Q2328).

## What it owns

- `game/house/kit/pieces/*.tscn`: the pieces the designer drags from the file dock. Each is a
  `MeshInstance3D` root (one mesh, one surface: Surface Material Override 0 on a placed piece is
  its material) with a `StaticBody3D` "Body" of one to four `BoxShape3D`s on layer 1
  (`Mess.LAYER_HOUSE`), mask 0. No script.
- `meshes/*.tres`: each piece's mesh. `materials/*.tres`: the library (the old house's colours;
  the textured ones world triplanar). `textures/`: the old house's plank and tile images.
- `house_kit_sizes.tres` (`HouseKitSizes`): every size. `house_kit_build.gd` makes `pieces/` and
  `meshes/` from it and any missing material; run it headless after a size change (its header).

## The grid convention

Origins on 0.5 m grid corners, turns in 90 degree steps. Walls centred on grid lines, running +X
from the origin, a 3.0 m storey high (floor top to the next floor top). Corners (L) and Ts are the
joins, arms 0.5 m along +X and +Z. Floor tiles run +X +Z, top at the origin, 0.1 m thick; a
ceiling tile sits right under the floor tile of the same square. Stairs rise towards +Z and
collide through one ramp box under the step middles plus a flat box on the top step.

## Gotchas

- Never hand-edit a piece or mesh file: change the sizes or the build script and rebuild. A
  rebuild keeps file uids but renumbers node `unique_id`s.
- A floor tile at y 0 in the zoo flickers against the zoo's own floor.
- Tests: `tests/house_kit_test.gd`.
