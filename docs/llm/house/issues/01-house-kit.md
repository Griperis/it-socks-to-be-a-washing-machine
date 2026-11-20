---
type: ticket
status: done
kind: build
area: house
feature: house
priority: now
created: 2026-11-20
done: 2026-11-20
blocked_by: []
notes: []
terms: []
---

# The house kit

M2, started beside the zoo (designer, 2026-11-20). The house is built by hand in the editor from a kit of snapping pieces
(Q2154, Q2156), on a half-metre grid (Q2175); the first goal is today's floors and rooms rebuilt from the kit, walkable
in first person with no functions (Q2155, Q2157). This ticket makes the kit; the shell rebuild is the next ticket.
Old facts: `reference/it-socks/tools/layout.py --help` (rooms, walls, openings, floor heights; never read the 167 KB
layout or the 1.2 MB manifest whole), `reference/it-socks/docs/architecture/campaign-house.md`, the old house
materials (`reference/it-socks/assets/house/`, `tools/blender/` house scripts).

## Behaviour list
From the designer's answers (Q2154-Q2157, Q2175, Q2325-Q2328).
- K01 Wall pieces 0.5, 1 and 2 m long, outer and inner corners and a T-join, at the old house's wall height and
  thickness (per floor where the old house differed; measure them and list them in the report).
- K02 Floor and ceiling tiles 0.5, 1 and 2 m square.
- K03 Wall pieces with a doorway and with a window, sized as the old house's openings (measure the common sizes).
- K04 A straight stair rising one floor, and a landing, on the grid.
- K05 Every piece is a scene whose origin sits on a grid corner, so Godot's own 0.5 m snap places it; dragged from the
  file dock; rotated in 90-degree steps; no editor plugin (Q2327).
- K06 Every piece collides through a simple box (or a few), never its drawn mesh, on the house's physics layer; the
  player walks on floors and stairs and is stopped by walls; Socks lie on floors.
- K07 Every piece has one material slot, overridden per placed piece; a shared material library ported from the old
  house's wall, floor and tile materials to pick from (Q2328).
- K08 A "House kit" station in the zoo shows every piece and a small room built from them, walkable.

## Design
To be drafted by the agent here first (the folder layout under `game/house/kit/`, how pieces are made: Blender through
the pipeline or Godot meshes, the material library as resources, the collision layer shared with the Mess), then built.
Look work: stop at the first stills.

Drafted (agent, 2026-11-20):
- **Folders:** `game/house/kit/pieces/<piece>.tscn` (what the designer drags), `meshes/<piece>.tres` (each piece's one
  mesh), `materials/<name>.tres` (the library), `textures/` (the old house's four tile and plank images),
  `house_kit_sizes.tres` (every size, typed, in the inspector) and `house_kit_build.gd`, which makes the pieces and
  meshes from the sizes (run headless; its header says how). No Blender: every piece is boxes, so Godot's
  SurfaceTool makes them; a Blender pipeline would add an export per piece for no gain at this stage.
- **A piece** is a `MeshInstance3D` root (so its one material slot, Surface Material Override 0, is on the placed
  instance itself, no Editable Children, no script) with a `StaticBody3D` "Body" of one to four `BoxShape3D`s on
  layer 1, the Mess's `LAYER_HOUSE`, mask 0.
- **The grid convention:** walls are centred on grid lines; a straight wall runs +X from its origin. A corner (an L)
  and a T are the joins, their arms 0.5 m from the join along +X and +Z. Floor tiles run +X +Z from their origin,
  top at the origin, 0.1 m thick; a ceiling tile hangs right under the floor tile of the same square (so one storey
  line carries both, each with its own material). Walls stand a full storey (3.0 m) so storeys stack with no gap;
  clear height 2.8 m. Stairs rise towards +Z.
- **Materials:** StandardMaterial3D from the old house's colours and roughness; the four textured ones (wood,
  kitchen_tile, bath_tile, wall_tile) are world triplanar at the old repeat sizes, so a pattern runs on across
  neighbouring pieces at any turn.
- **The station** `game/zoo/stations/house_kit.tscn` stands at (-13, 0, 12.5), the free corner behind the spawn,
  west of Movement.

## Acceptance
- One test per behaviour line (sizes on the grid, collision, a walk through the station's room on the real path).
- Stills in `builds/review-house-01/`: the piece line-up, the small room, a close-up of a door and a window; the ticket
  goes ready-for-human.

## Answers
- Q2154-Q2157, Q2175, Q2325-Q2328.
- The kit should build the old house nearly identically; the old house is re-gridded to the 0.5 m grid (Q2343,
  2026-11-20), the kit grows to windows and door frames, skirting and railings, roof and attic, openings for
  entities (Q2344), proved by rebuilding the whole house from it (Q2345): all in house/02.
- Merged as a first step; the open follow-ups below are carried into house/02 (Q2346, 2026-11-20).

## Open follow-ups
Carried into house/02 (Q2346).
- [later] Storey height: the old house was 2.9 m floor to floor on every floor (clear 2.7 m basement and ground,
  2.6 m first); nudged to the grid that is one 3.0 m storey everywhere, 0.2 m of floor and ceiling, clear 2.8 m. Is
  2.8 m clear right, or should the first floor be lower (it cannot be on the grid with a 2.9 m storey)?
- [later] Outer and inner corners: with walls centred on grid lines one L piece is both (its outside closes the
  building's corner, its inside is the room's corner), so the kit has `corner_*` instead of two pieces. Say if an
  inner corner should be its own piece (a filler for walls of two thicknesses, say).
- [later] Stair numbers are the agent's (placeholders in house_kit_sizes.tres): 1.0 m wide (old 1.1), 16 steps of
  0.1875 x 0.25 m, a 4 m run, about 37 degrees (old ramps 31). The player walks it through a ramp collider like the
  old ramps. A half flight (8 steps) was added so the landing has a use (a U stair like the old house's).
- [later] Windows: one 1.0 m window (the old house's most common) in a 2 m piece, sill 0.9, head 2.1 (the first
  floor's; the ground floor's heads were 2.15). The old 1.1, 1.2, 1.4-2.4 m windows, the basement wells (sill 1.75 m
  over the floor) and the high bathroom window are not pieces yet.
- [later] The station room has no floor tiles on its ground floor: the zoo floor's top is at y 0, where a floor
  tile's top would be, and two surfaces there flicker. Tiles show on the upper floor and in the line-up (raised).
- [later] Rebuilding the pieces (house_kit_build.gd) keeps each file's uid but renumbers the nodes' unique_id lines:
  a cosmetic diff in every piece file. Godot gives a script no way to keep them.

## Built log
- 2026-11-20 (agent, look work: first stills)
  - Changed: the house kit: 23 pieces (walls 0.5/1/2 m outside and partition, corners, Ts, door and window walls,
    floor and ceiling tiles 0.5/1/2 m, full and half stair, landing) made from typed sizes; a library of 20 materials
    from the old house; the House kit station with a line-up and a two-storey room; the `house_kit` shot action and
    shot set; suite `house_kit` (K01-K08 and the real path).
  - Files: game/house/kit/, game/zoo/stations/house_kit.tscn, tests/house_kit_test.gd, tools/shot_hooks.gd,
    tools/shots/sets/house-kit.txt, docs/architecture/house-kit.md
  - Verified: `PASS 4982 checks, 62 cases` (--touched: every_sock, handling, house_kit, runner, wiring, zoo); `PASS rules`; `PASS asset_lint`. Stills: builds/review-house-01/house-kit-*.png
- Model: Opus (lead): Blender and modular meshes on a grid (Models: opus for Blender).
