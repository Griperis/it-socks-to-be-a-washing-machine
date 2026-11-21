---
type: ticket
status: done
kind: build
area: house
feature: house
priority: now
created: 2026-11-20
done: 2026-11-21
blocked_by: ["[[01-house-kit]]"]
notes: []
terms: []
---

# The kit grows to the old house: the re-gridded plan and every piece it needs

M2. house/01 made a first kit (walls, corners, Ts, floor and ceiling tiles, door and window walls, a straight stair with a
landing) on the 0.5 m grid. The designer wants the kit ready to build the old house nearly identically (Q2343):
the old house is **re-gridded** to the kit's 0.5 m grid (it is 10.1 x 8.34 m with rooms like 3.83 m and 0.12 m
partitions; on the grid it becomes about 10 x 8.5 m, rooms and windows moving up to 0.25 m), and the kit gets every
part the old shell has (Q2344). house/03 then rebuilds the whole house from it (Q2345).

Old facts: `reference/it-socks/tools/blender/make_house.py` (grep it, 1,896 lines: the contract dimensions at the
top, `ROOMS`, `DOORWAYS`, `WINDOWS`, `STAIR`, `SHAFT`, `FRONT_DOOR`, `GARAGE_DOOR`, `make_windows`, `make_door_frames`,
`make_stairs`, `make_roof`, `make_partitions`, `make_exterior_walls`, `wall_mat`), `reference/it-socks/tools/layout.py
--help`, the old house's looks in `docs/migration/baseline/`. The kit as built: `docs/architecture/house-kit.md`.

## Behaviour list
Draft for the designer; the numbers are the old house's, moved to the grid.

**The plan (stops for the designer's go before any piece is built)**
- K01 A re-gridded plan of the old house exists: the footprint, every room, partition, doorway, window, the stair,
  the elevator shaft, the front and garage doors, the basement wells, the roof and dormer, each with its old number
  and its grid number side by side, and how far it moved. A top-down plan still per floor, old over new.
- K02 Storeys are 3.0 m floor to floor (the grid; the old 2.9 m, Q2343 as the lead read it), each floor's clear height
  as near the old one as the grid allows; the plan says the numbers and the designer confirms them on the still.

**Walls**
- K03 Every wall piece has two faces, inside and outside, each with its own material slot (the old `wall_mat` per
  face), so a room's paint and the outside render differ on one wall.
- K04 Outer walls 0.2 m, partitions 0.12 m (the old ones), each in the lengths the plan needs; a wall of two
  thicknesses meets another without a gap (an inner corner or filler piece if the plan needs one; house/01's open
  question).
- K05 Skirting runs along the inside faces (a piece or part of the wall, as the plan needs), as the old rooms had.

**Openings**
- K06 Every old window has a window piece at its re-gridded width, with its old sill and head inside the piece:
  ground 0.9-2.15, first 0.9-2.1, kitchen north 1.1-2.15, the small hall and bathroom windows 1.3-2.0, the basement
  wells 1.75-2.45 over the basement floor, the stair window 2.35-3.45, the gable 0.8-1.7 over the attic floor.
- K07 A window piece has the old frame: sill, casing, frame bars (a middle bar over 1.0 m wide), and a pane of glass,
  frosted for the bathroom; the pane stops Socks as the old one did.
- K08 Door openings have the old jamb linings (frames) for the room doorways (0.9 m), the front door and the garage
  door (2.4 m); the doors themselves stay entities.
- K09 Wall openings are sized for the entities that stand in them: the elevator shaft, the garage door, the front
  door, the basement window wells.

**Stair**
- K10 The U stair of the old house: two flights, the half landing, the newel wall between them and the railings, at
  the old width (1.1 m) and the old pitch as near as the grid allows; the player walks it through a ramp collider as
  the old ramps did.

**Roof and attic**
- K11 The pitched roof at 40 degrees, the 0.4 m knee walls, the gables with their window, the dormer with its flat
  ceiling and the attic floor, as pieces that snap to the grid.

**Every piece**
- K12 Each piece snaps on the 0.5 m grid (origin on a grid corner, 90 degree turns), has box colliders on the house
  layer and its material slots from the shared library; a new size is a number in `house_kit_sizes.tres` and a rebuild.
- K13 The kit station shows every piece, labelled, and a small room built from them that the player walks in, climbs
  the U stair to an upper floor and looks out of a window.
- K14 No two pieces placed by the grid convention have faces facing the same way in one plane that overlap where they
  can be seen: floor and ceiling tiles against walls on every floor, walls at corners and Ts, skirting, frames and
  sills, the station's own floor (Q2358). The convention is in `docs/architecture/house-kit.md`.

## Design
The agent drafts it from house/01's build script and sizes before building: how the two-face walls and skirting are
made (one mesh with two surfaces, so Surface Material Override 0 and 1 on a placed piece), the window and frame
pieces (one piece per re-gridded window size, or a wall piece plus a frame piece), the stair and roof pieces, and
what the plan file looks like (a Markdown table in `docs/architecture/house-kit.md` or its own file, plus the plan
stills). Open choices go back as `[blocking]` follow-ups.

The plan (first stop, drafted): its own file, `docs/architecture/house-kit-plan.md`, written with its stills by
`tools/house_plan.py`, which holds the old numbers beside the new ones and checks the plan's rules (centre lines on
grid lines; an opening centred in a wall piece of 0.5 m steps, so on a 0.25 m lattice, old widths kept; an
opening's edge a casing clear of a meeting wall; heights over a floor kept). House/03 reads the new numbers there.
The pieces (built after the go): one generated mesh per piece with fixed material slots (0 inside, 1 outside, 2
trim, 3 glass for walls; see `docs/architecture/house-kit.md` "Material slots"); skirting, door frames and window
frames are part of their wall pieces (trim slot); one window piece per width, sill/head and piece length, in both
sets; the U stair one piece a storey; roof slopes by length, verges, a dormer piece, gables wall line to wall line;
two sample rooms (`rooms/`) and a line-up built at load from the pieces folder.

## Acceptance
- One test per behaviour line (`tests/house_kit_test.gd`); the real-path case: in the kit station the player walks in
  the room's door, climbs the U stair to the upper floor and stands at a window, by its own input.
- **First stop:** the re-gridded plan (K01, K02) with its per-floor stills in `builds/review-house-02/`, for the
  designer's go before the pieces are built.
- **Second stop:** a line-up still of the new pieces and close-ups (a window with its frame, a door frame, the U
  stair, a roof corner with the dormer), beside the old house's from the baseline views.
- `asset_lint` passes; house/01's cases still pass.

## Answers
- The pieces are approved and merge (Q2380, 2026-11-21).
- Both window sets stay in the kit: the old widths (A) for the house, and the house is also built with the rounded set (B) to compare; the goal is the old house rebuilt with this kit (Q2381, 2026-11-21).
- The kit builds the old house nearly identically; the old house is re-gridded to 0.5 m (Q2343, 2026-11-20).
- It covers windows and door frames, skirting and railings, roof and attic, openings for entities (Q2344, 2026-11-20).
- The proof, the whole house rebuilt, is house/03 (Q2345, 2026-11-20).
- house/01 merged as a first step; its open follow-ups are carried here (Q2346, 2026-11-20).
- The stair: a 0.9 m half landing, 33.3 degrees (Q2350, 2026-11-21).
- D2 and D8: an off-centre door piece keeps both doorways in their old places (Q2351, 2026-11-21). Built as the old
  0.1 m from the z3.5 partition's face (z 3.65..4.55): the old place itself would cut into the partition, which moved
  0.18 m south.
- The width: outer wall centre lines 10.5 m apart (Q2352, 2026-11-21).
- K02: storeys 3.0 m, the old clear heights 2.7 / 2.7 / 2.6 m kept through thicker ceiling tiles (Q2353, 2026-11-21).
- The roof: 40 degrees, the ridge 3.88 m over the attic floor (Q2354, 2026-11-21).
- Openings: both sets are built, old widths and widths rounded to 0.5 m; the designer compares (Q2355, 2026-11-21).
- The Cellar hatch and the tiles with a hole are in (the designer, 2026-11-21). The Cellar hatch's tile is 1.5 m:
  a 1 m tile cannot hold the 0.75 m hatch at its planned place.
- No z-fighting: a kit rule, tested (K14, Q2358, 2026-11-21).
- The corner question (house/01, K04): no inner corner or filler piece is needed; a partition that cannot meet a wall
  through a T is an end piece that starts at the wall's face (2026-11-21, with K14).

## Open follow-ups
For the designer at the second stop (stills in `builds/review-house-02/`):
- [later] The roof's rafters stand one a metre in each 1 and 2 m slope piece (the old ones every 0.9 m); a 0.5 m
  piece has none.
- [later] house/01's straight flights (`stair_full`, `stair_half`, `landing`) keep the agent's numbers; the house
  uses the U stair.
- [later] A rebuild renumbers the nodes' `unique_id` lines in every piece file (cosmetic diff); the rooms' files
  repeat each piece's mesh as an override (harmless).
- [later] The House kit station moved its line-up beyond the zoo floor's west edge on its own ground (the line-up is
  25 x 36 m); the zoo floor is 40 x 80 m and full.

## Built log
- Model: Opus (lead): many pieces, a build script, geometry from the old Blender script.

### 2026-11-20
- Changed: the first stop. The old house re-gridded: footprint, storeys, every wall line, room, doorway, window,
  the U stair, the elevator shaft and hatch, the Cellar hatch, roof, dormer and posts, old and new side by side
  with the move; a plan still per floor and a section, old (red) over new. No piece built.
- Files: `tools/house_plan.py`, `docs/architecture/house-kit-plan.md`, `docs/architecture/house-kit.md`;
  stills `builds/review-house-02/plan_1_basement.png` to `plan_5_section.png`.
- Verified: `house_plan: PASS, 0 rules broken`; `PASS rules: 9 rules, no new hit`.

### 2026-11-21
- Changed: the plan to the answers (Q2350-Q2355), with a still of both window sets. The kit grew to the old house:
  two-faced walls with skirting, partition end pieces, knee walls, door pieces with linings and casings (1.5 m,
  off-centre, garage), the elevator hatch partition, window pieces of both sets with the old frame and a pane that
  stops Socks, the two-storey stair window, ceiling tiles for 2.7 / 2.6 m, tiles with the shaft's and the Cellar
  hatch's holes, the U stair with newel cap and balustrade, roof slopes and verges at 40 degrees, the dormer, the
  gables, a roof post. The no-z-fight rule (K14). The station: a line-up built at load, the U room (door, U stair,
  window) and a roof corner with the dormer. Second stop: line-up and close-ups beside the old house.
- Files: `game/house/kit/house_kit_build.gd`, `house_kit_sizes.gd`, `house_kit_line_up.gd`, `rooms/`, `pieces/`,
  `meshes/`, `game/zoo/stations/house_kit.tscn`, `tests/house_kit_test.gd`, `tools/house_plan.py`,
  `tools/shot_hooks.gd`, `docs/architecture/house-kit.md`, `house-kit-plan.md`; stills in `builds/review-house-02/`.
- Verified: `PASS 1670 checks, 19 cases` (house_kit); `PASS asset_lint`; `PASS rules: 9 rules, no new hit`.
