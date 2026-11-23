# The house kit

What the house is built from by hand in the editor (house/01, Q2154-Q2157, Q2175, Q2325-Q2328;
house/02, Q2343-Q2358).

## What it owns

- `game/house/kit/pieces/*.tscn`: the pieces the designer drags from the file dock. Each is a
  `MeshInstance3D` root (one mesh, its material slots below) with a `StaticBody3D` "Body" of
  `BoxShape3D`s on layer 1 (`Mess.LAYER_HOUSE`), mask 0. No script.
- `meshes/*.tres`: each piece's mesh. `materials/*.tres`: the library (the old house's colours;
  the textured ones world triplanar). `textures/`: the old house's plank and tile images.
- `house_kit_sizes.tres` (`HouseKitSizes`): every size. `tools/house_kit_build.gd` makes `pieces/`,
  `meshes/`, `game/zoo/house_kit/rooms/` and any missing material from it; run it headless after a size change (its
  header).
- `game/zoo/house_kit/rooms/u_room.tscn`, `attic_corner.tscn`: two sample rooms made of pieces by the build
  script (the station's room and roof corner). `game/zoo/house_kit/house_kit_line_up.gd`: the station's line-up, built
  when the station loads from whatever is in `pieces/` (Q2337).

## The old house on the grid (house/02)

`house-kit-plan.md`: the old house re-gridded, every wall, room, opening, the stair, the shaft and the
roof with its old and new numbers. It is written by `tools/house_plan.py`, which holds the numbers and
checks the plan's rules; its stills go to `builds/review-house-02/`. House/03 builds from it.

## The old house from the kit (house/03, house/04)

`game/house/shell.tscn`: the whole old house from the plan's new column with its windows rounded to
0.5 m (house B, Q2381, Q2503; house A with the old widths is gone), kit pieces only, under
`<storey>/` (`Basement`, `Ground`, `First`, `Attic` at y -3, 0, 3, 6; groups `N` `E` `S` `W` for the
outer walls, `X4`, `X6_5`, `Z3_5`, `Z2` for the partitions, `Floor`, `CeilingBelow`, `Stair`, `Shaft`,
`Roof`; openings named by their plan id, W1-W22, D11, D12). No ground round it (Q2503). It is written by
`tools/house_shell_build.gd` (its header says how to run it): change the plan's numbers there, never
the shell by hand. The level that holds it is `docs/architecture/house.md`. Tests: `tests/house_test.gd`;
stills: the `house` shot set (the old looks-baseline views, `tools/shot_hooks.gd` `house`).

House/04 added the shell details: the elevator shaft's walls a storey each at the shaft tile
(`shaft_hatch_w` with the hatch open west in the basement and on the ground floor, `shaft_closed` on the
first floor where the x 4 partition has the hatch, `shaft_attic` with the hatch east and a lid at
2.15 m; 4 cm walls inside the tiles' hole, so they cover its edges, and a stainless sill 5 mm proud of
the opening's foot; make_elevator.py's SHEATH, LIP, ATTIC_SHAFT); the bathroom's tile wainscot as a wall
paint, `wall_bathroom_tiled` (a ShaderMaterial on `wainscot.gdshader`: the old wall tiles to 1.2 m over
the piece's origin, a 3.5 cm trim band, the bathroom's paint above; make_flat.py make_wall_tiles); and
the balustrade's side rails stopping where the slope's underside clears the handrail by 5 cm (they came
out through the roof, as in the old house). `house_kit_build.gd -- --only=<prefix>` writes only those
pieces.

House/03 added two pieces: `corner_exterior_open` (a corner without its +X arm, where W15 runs to
the south wall's line) and `door_partition_offset_hatch_2m` (D8's off-centre doorway and the
elevator's hatch in one partition: their own pieces would overlap).

## The grid convention

Origins on 0.5 m grid corners, turns in 90 degree steps. Walls centred on grid lines, running +X
from the origin, a 3.0 m storey high (floor top to the next floor top), their inside (slot 0) on
+Z: placed clockwise round a room seen from above, the inside faces the room. Corners (L) and Ts
are the joins, arms 0.5 m along +X and +Z. Where a T's arm would cover an opening, the meeting
partition is a `wall_partition_end_exterior_*` or `_end_partition_*` piece instead: it starts at the
other wall's face. Knee walls between gables: `knee_exterior_start_1m` and `_end_1m` at the ends.
Floor tiles run +X +Z, top at the origin, 0.1 m thick; a ceiling tile sits right under the floor
tile of the same square: `ceiling_*` 0.2 m (clear 2.7 m), `ceiling_attic_*` 0.3 m (clear 2.6 m).
An opening sits in the middle of its wall piece (one off-centre door piece, Q2351).

The U stair (`stair_u`, `stair_u_solid` for the lowest storey) has its origin on the well's corner:
x 0 on the west partition's centre line, z 0 on the first riser; the flights collide through two
ramps a centimetre over the nosings, the landing and the newel through boxes. The attic has
`stair_newel_top` and `stair_balustrade` at the same origin. Roof pieces have their origin on the
outer wall's centre line at the attic floor; the far slope is the same piece turned half round,
its origin on the far wall line; `roof_verge_w` / `_e` end a slope at a gable. The dormer is placed
like a far-slope piece (turned half round) between its cheeks' centre lines.

## Material slots

- Walls, corners, Ts, doors, windows, knee walls, gables: 0 inside face, 1 outside face (for a
  partition: its two rooms), 2 trim (skirting, linings, casings, sill, frame bars), 3 glass. Every
  face that is neither inside nor outside (ends, top, reveals) is split at the wall's middle, each
  half its side's paint (K03).
- Tiles: 0. Stairs: 0 oak, 1 the newel (trim). Roof slopes: 0 rafters (under), 1 tiles (over).
- Dormer: 0 inside, 1 outside, 2 trim, 3 glass, 4 rafters, 5 roof tiles, 6 ceiling.

## No two faces in one plane (K14, Q2358)

Two faces facing the same way in one plane flicker (z-fight). The kit keeps them apart:

- Everything that stands on a floor starts under the floor line, inside the floor tile, and a wall
  ends the same distance under the next floor line: walls, newels, stair steps and the balustrade
  run from -0.02 m to the storey less 0.02 m (`sink`). The storey above starts where the one below
  ends, so their meeting faces face each other, inside the floor tile.
- Trim sinks less, and each kind differently: skirting -0.01 m (`trim_sink`), door casings -0.0125 m,
  linings -0.015 m (`lining_sink`), so no two trims share a foot plane.
- Floor and ceiling tiles keep the grid; the walls run through them, so no tile face lies in a wall
  face (the walls' faces are at 0.06 or 0.1 m off the grid lines, the tiles' on them).
- A partition meeting a wall without a T starts at that wall's face, its skirting after that wall's
  skirting; a piece's own trim (corner, T) butts in the same way.
- Window sills stand 0.03 m proud of the outside face and never reach a piece's end; window casings
  sit flush on the inside face (their back faces the wall); a head casing runs between the side
  casings, never over them.
- A roof's ridge board sits on the slab's top face; a dormer's cheeks and front wall end inside its
  flat roof; knee walls and gables end inside the slab.
- In the zoo the zoo floor is the ground storey's floor: no floor tiles at y 0 (they would lie in
  the zoo floor's plane), and the line-up lifts tiles half a metre. The station's pad is 5 mm over
  the zoo floor, its own ground outside it.

Faces may meet face to face (a wall's end against the next wall's end): one of them always faces
away from any camera. Some faces still meet inside a wall or a tile (a wall piece's end and a floor
tile's end on one grid line); no camera can see those. `tests/house_kit_test.gd` k14 checks every
face of the station, its floor and a two-storey test house, and fails on two faces facing one way
in one plane that overlap where they can be seen (a point just in front of the overlap is inside no
piece).

## Gotchas

- Never hand-edit a piece, mesh or `rooms/` file: change the sizes or the build script and rebuild.
  A rebuild keeps file uids but renumbers node `unique_id`s.
- The station has its own ground beyond the zoo floor's west edge (the line-up is 25 x 36 m).
- A rebuild of every piece renumbers every piece file's node ids: build one family with `--only=`.
- A wall paint in the library may be a ShaderMaterial (`wall_bathroom_tiled`): its heights are over the
  piece's origin, which is the floor line for every wall-like piece.
- Tests: `tests/house_kit_test.gd`. Stills: the `house-kit` shot set.
