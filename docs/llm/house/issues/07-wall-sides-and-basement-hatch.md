---
type: ticket
status: ready-for-agent
kind: build
area: house
feature: house
priority: now
created: 2026-11-23
done:
blocked_by: []
notes: ["designer's house walk, 2026-11-23"]
terms: []
---

# Each side of a shared wall in its own room's colour; no hatch hole in the basement floor

From the designer's walk of the house (2026-11-23):
1. **Walls from the bathroom to the kids' room have the wrong colours:** a wall shared by two rooms shows one room's
   paint on both sides. Every partition between two rooms shows each room's own wall colour on its own side, as the
   old house did (`reference/it-socks/tools/blender/make_house.py`, the per-room wall skins). Check every shared wall of
   the house, not only those named, and list in the Built log which ones were wrong.
2. **Remove the hatch hole in the basement floor:** the lowest floor has a hatch opening (the kit's `floor_hatch_15m`)
   that leads nowhere. Close it with a plain floor piece. The upper floors' hatches stay.

## Design
The shell is built by `tools/house_shell_build.gd` into `game/house/shell.tscn` from the kit's pieces. Fix it at the
source (the builder's per-side material, or a two-sided piece with a material per face), then rebuild the shell; no
hand edits of the generated shell. house/05 edits `game/house/house.tscn` in parallel (Sock areas): do not touch it
unless a wall fix cannot be made in the shell, and then only the lines needed.

## Acceptance
- A look change, so no test (Q2421): a before/after strip of each fixed wall from both sides and of the basement floor
  where the hatch was (`builds/review-house-07/`).
- The full suite passes; the house's real-path walk still passes.
