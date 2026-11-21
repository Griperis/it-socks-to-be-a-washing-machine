# Build rooms with the house kit

## What this is for

The house is built by hand in the Godot editor from a kit of snapping pieces: walls, corners, Ts, floor and ceiling tiles, doors, windows, stairs, roof, dormer. You drag a piece from the file dock into a scene and snap it on a 0.5 m grid. This page shows how to place pieces, which pieces there are, how the pieces avoid flickering faces, the two window sets, and how to change a piece's size and rebuild.

## The pieces

All in `game/house/kit/pieces/*.tscn` (85 files). Each is one mesh with a `Body` of boxes on layer 1 (the house layer). They have no script.

- **Walls:** `wall_exterior_{05m,1m,2m}`, `wall_partition_{05m,1m,2m}`, `wall_partition_hatch_1m`, `knee_exterior_*` (the low wall between gables).
- **Wall ends:** `wall_partition_end_exterior_*` and `wall_partition_end_partition_*`: a partition that starts at the face of the wall it meets.
- **Joins:** `corner_exterior`, `corner_exterior_open`, `corner_partition`, `t_exterior`, `t_exterior_partition`, `t_partition`.
- **Floors and ceilings:** `floor_{05m,1m,2m}`, `floor_hatch_15m`, `floor_shaft_1m`, `ceiling_*`, `ceiling_attic_*`.
- **Doors:** `door_exterior`, `door_exterior_15m`, `door_partition`, `door_partition_15m`, `door_partition_offset_15m`, `door_partition_offset_hatch_2m`, `door_garage`.
- **Windows:** `window_<width>_<sill>_<head>_<length>m`, for example `window_100_090_215_15m` is 1.00 m wide, sill 0.90 m, head 2.15 m, in a 1.5 m piece. Plus `window_100_130_200_frosted_15m` and `window_stair`.
- **Stairs:** `stair_u`, `stair_u_solid` (lowest storey), `stair_full`, `stair_half`, `landing`, `stair_newel_top`, `stair_balustrade`.
- **Roof:** `roof_{05m,1m,2m}`, `roof_verge_w`, `roof_verge_e`, `roof_post`, `gable_exterior*`, `dormer`, `dormer_grid`.

The zoo station `HouseKit` (`game/zoo/stations/house_kit.tscn`) shows every file of `pieces/` in a line-up, built from the folder when it loads. A piece you add appears there with no other change.

## Place pieces in the editor

1. Open a scene (a station, or start from `game/zoo/house_kit/rooms/u_room.tscn`, a sample room).
2. In the 3D view turn on **Use Snap** (the magnet button, or Y). In the snap settings set **Translate Snap** to 0.5 and **Rotate Snap** to 90.
3. Drag a piece from the file dock into the scene. Its origin is on a grid corner, so it snaps.
4. Walls run along +X from their origin. A wall's inside (the face you paint with the room's colour) is on +Z. So place the walls of a room **clockwise as seen from above**, and the inside faces the room.
5. Corners and Ts are the joins. Their arms reach 0.5 m along +X and +Z. Put a corner where two walls meet, then walls between corners.
6. A storey is 3.0 m high (floor top to the next floor top). The ground floor's top is at y 0; floors above at y 3.0 and 6.0. The basement is at y -3.0.
7. A floor tile runs +X and +Z from its origin, top at the origin, 0.1 m thick. A ceiling tile goes right under the floor tile of the same square (0.2 m, or 0.3 m under the attic floor).
8. A door or window piece has its opening in the middle of its wall piece (one off-centre door piece exists).
9. The U stair's origin is on the well's corner: x 0 on the west partition's centre line, z 0 on the first riser. Roof pieces have their origin on the outer wall's centre line at the attic floor; the far slope is the same piece turned half round (180 degrees), its origin on the far wall line.
10. Where a T's arm would cover an opening, use a `wall_partition_end_*` piece instead.

## Materials

Each piece has material slots in a fixed order:

- Walls, corners, Ts, doors, windows, knee walls, gables: slot 0 inside face, 1 outside face (for a partition: its two rooms), 2 trim (skirting, linings, casings), 3 glass.
- Tiles: 0. Stairs: 0 oak, 1 the newel (trim). Roof slopes: 0 rafters (under), 1 tiles (over).
- Dormer: 0 inside, 1 outside, 2 trim, 3 glass, 4 rafters, 5 roof tiles, 6 ceiling.

To paint a room, set slot 0 of its walls to a file from `game/house/kit/materials/` (`wall_kitchen`, `wall_hall`, `wall_bathroom`, `wall_bedroom` and so on) in the Inspector: Surface Material Override. Edit a colour once in its `.tres` and every wall using it changes. The build script never overwrites a material file that exists, so your edits stay.

## No two faces in one plane (no z-fighting)

Two faces that face the same way in one plane flicker. The kit keeps them apart, so do not fight it:

- Anything that stands on a floor starts 0.02 m under the floor line (inside the floor tile) and a wall ends 0.02 m under the next floor line. This is `sink`.
- Trim sinks less, each kind a different amount, so no two trims share a foot plane: skirting 0.01 m (`trim_sink`), door casings 0.0125 m, linings 0.015 m (`lining_sink`).
- Floor and ceiling tiles keep the grid; the walls run through them.
- A partition meeting a wall without a T starts at that wall's face.
- Window sills stand 0.03 m proud of the outside; casings sit flush inside.
- In the zoo, the zoo floor is the ground storey's floor: put no floor tiles at y 0 in a station (they would flicker with it). The station's pad is 5 mm over the zoo floor.
- Do not put your own box or plane flush against a wall or floor face. Move it 1 cm or tuck it inside the wall.

## The two window sets

The old house's windows come in two sets in `game/house/kit/house_kit_sizes.tres`, both with pieces in `pieces/`:

- **Old widths:** `windows_old`, the old house's widths (0.5, 0.8, 1.0, 1.1, 1.2, 1.4, 1.5, 2.0, 2.4 m).
- **Grid widths:** `windows_grid`, the same windows rounded to 0.5 m.

Both stay for now. The two stations `old_house_a.tscn` (old widths) and `old_house_b.tscn` (rounded widths) build the whole old house with each so you can walk through and choose. The choice is still open: no set is chosen yet. Frosted windows (the bathroom's) are in both.

## Change a piece's size and rebuild

Never edit a piece, a mesh or a file in `game/zoo/house_kit/rooms/` by hand: a rebuild replaces them.

1. Open `game/house/kit/house_kit_sizes.tres` in the Inspector. Groups: Grid, Walls, Floors, Openings, Stairs and more. Change a number: wall thickness (`exterior` 0.2 m, `partition` 0.12 m), storey (3.0 m), skirting height, door width and height (0.9 by 2.1 m), a window row (width, sill, head, piece length), the stair's steps, and so on.
2. Save, then run the build script from the project folder:
   `"$(kit/tools/engine.sh --path)" --headless --path . --script res://tools/house_kit_build.gd`
3. The script rewrites `pieces/`, `meshes/`, `rooms/` and any missing material. Piece files keep their uid; node ids inside change.
4. If you want the old house stations to follow, run:
   `"$(kit/tools/engine.sh --path)" --headless --path . --script res://tools/old_house_build.gd`
   It writes `old_house_a.tscn` and `old_house_b.tscn` again at the numbers of the plan `docs/architecture/house-kit-plan.md`. A hand edit to those two stations is lost, so change the plan's numbers, not the scenes. The plan is written by `tools/house_plan.py`, which holds the numbers and checks the plan's rules.
5. To add a new piece (not just resize): the build script has to learn it. Ask for a piece to be added; do not copy a `.tscn`.

## Checking it worked

- Open `game/zoo/zoo.tscn`, go to `HouseKit`, and look: walls, corners and windows in rows, the sample U room and the attic corner. Look for flicker where two faces meet (none should show).
- Walk into `OldHouseA` and `OldHouseB` from the zoo floor.
- `kit/tools/run.sh --only=house_kit` (includes the check `k14` for faces in one plane) and `kit/tools/run.sh --only=old_house`. Each ends with `PASS`.
- Stills: the shot sets `house-kit` and `old-house` in `tools/shots/sets/`.

## Gotchas

- After a size change the pieces in any scene you placed change too (they are instances). Check your rooms.
- The station's line-up is 25 by 36 m and has its own ground beyond the zoo floor's west edge.
- A rebuild renumbers `unique_id` lines inside the files. That is normal.
- Rotations are 90 degrees only. A piece at 45 degrees will not meet its neighbours.
- Pieces for the old house's details not yet built (shell details) are in `docs/llm/house/issues/04-shell-details.md`, not done.

Sources: `docs/architecture/house-kit.md` and `house-kit-plan.md`; tickets `docs/llm/house/issues/01` to `03`; Q2154, Q2175, Q2343, Q2355, Q2358, Q2381.
