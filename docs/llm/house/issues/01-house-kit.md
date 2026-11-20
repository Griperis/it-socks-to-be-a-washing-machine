---
type: ticket
status: ready-for-agent
kind: build
area: house
feature: house
priority: now
created: 2026-11-20
done:
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

## Acceptance
- One test per behaviour line (sizes on the grid, collision, a walk through the station's room on the real path).
- Stills in `builds/review-house-01/`: the piece line-up, the small room, a close-up of a door and a window; the ticket
  goes ready-for-human.

## Answers
- Q2154-Q2157, Q2175, Q2325-Q2328.

## Open follow-ups

## Built log
- Model: Opus (lead): Blender and modular meshes on a grid (Models: opus for Blender).
