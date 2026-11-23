---
type: ticket
status: done
kind: build
area: house
feature: house
priority: now
created: 2026-11-23
done: 2026-11-23
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

## Built log

- 2026-11-23. Changed: the partitions already painted each face with its own room (checked all 14 lines of
  every storey). The wrong colours were the OUTER walls: a plain exterior piece (2 m, 1 m) that straddled the
  line where two rooms meet took one room's paint over both, so a strip of the next room showed in the
  corner. `_plain` in the shell builder now cuts each run at the room lines. Wrong before (storey, wall,
  span, rooms): Basement N 2.5-4.5 workshop|boiler; Basement S 6-8 lobby|garage; Basement W 2.5-4.5
  workshop|laundry; First N 2.5-4.5 office|landing; First N 6-7 landing|bathroom; First E 2.5-4.5
  bathroom|kids; First W 2.5-4.5 office|bedroom. The basement's `floor_hatch_15m` tile is gone (plain
  floor tiles); `tests/house_test.gd` now expects the workshop floor whole. Shell rebuilt. Added a
  `cam:` view to the `house` shot action and shot sets `house-07`, `house-07-ext`.
  Files: tools/house_shell_build.gd, game/house/shell.tscn, tests/house_test.gd, tools/shot_hooks.gd,
  tools/shots/sets/house-07.txt, house-07-ext.txt. Strips: builds/review-house-07/
  (outer-walls-before-after.png, hatch-before-after.png, before/, after/).
  Verified: PASS 1447 checks, 80 cases.
- 2026-11-23 (Q2538). Changed: the bathroom's wainscot trim is a raised strip (3.5 cm high, the skirting's
  depth and profile) at the tiles' top, no longer painted: the kit builder makes four `wainscot_trim_*`
  pieces (north/south 380 cm, east 334, west 213 and 17 either side of the door's casings), the shell
  builder places them on the first floor's bathroom walls, and `wall_bathroom_tiled` has `band` 0
  (the shader keeps the uniform). Strips: builds/review-house-07/house-07-trim-before-after.png,
  trim-close-up.png. Files: tools/house_kit_build.gd, tools/house_shell_build.gd, game/house/shell.tscn,
  game/house/kit/{pieces,meshes}/wainscot_trim_*, game/house/kit/materials/wall_bathroom_tiled.tres,
  tools/shots/sets/house-07-trim.txt.
- Merged: 5db5b975 (2026-11-23, branch house/07-wall-sides-and-basement-hatch)
