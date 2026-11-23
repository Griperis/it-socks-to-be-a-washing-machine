---
type: ticket
status: ready-for-agent
kind: build
area: assets
feature: assets
priority: now
created: 2026-11-23
done:
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
