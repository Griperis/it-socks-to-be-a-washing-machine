---
type: ticket
status: done
kind: maintenance
area: maintenance
feature: frame
priority: now
created: 2026-11-27
blocked_by: []
notes: ["suggested model: opus", "Q2723; the facts: docs/research/headless-editor-scene-authoring.md"]
terms: []
suites: [house, zoo, menus, ui_nodes, save, coop_join, wardrobe_station, presents, furniture_devices, stages]
---

# Every scene and resource in the editor's own format, with nothing lost

The designer's editor re-save (Project > Tools > Upgrade Project Files) rewrote 475 text files and silently lost data
in 121 of them. The causes are found and a repair is proven on 4.7.2 (`docs/research/headless-editor-scene-authoring.md`,
read it whole first):
1. overrides and added nodes under an instanced scene not marked "Editable Children" (`[editable path="..."]`): the
   editor's `pack()` drops them (75 instances in 20 files on main);
2. `Packed*Array` exports declared with an array-literal default in scripts without `@tool` (7 declarations in 5
   scripts): the editor's placeholder cannot keep their values (credits `covers`, the options `labels`, ...); open engine
   issue godotengine/godot#124452 says exports may lose them too;
3. values the editor works out from its live tree (most harmless; the Achievement toast's Card `offset_bottom`
   80 -> 323 and one-shot GPUParticles saved `emitting = false` in the GUI are real).

The research's throwaway tools are in the lead's scratchpad:
`/tmp/claude-1000/-c-Users-Gripe-personal-repositories-it-socks-to-be-a-washing-machine/08fda595-82ec-42d1-a22f-67d094c58b5b/scratchpad/tools/`
(`repair_resave.gd`, `exp_repair.sh`, `upgrade_like.gd`, `dumpsem.gd`, `semdiff.py`, `scene_lint.py`). Read them; copy
what you run into a throwaway place, not into the game.

## Do
1. Rewrite the 7 array-literal `Packed*Array` exports so the editor keeps their values (non-empty defaults as `Array[T]`
   or a constructor with the value written into the `.tres`; say which, per declaration). The game's behaviour stays
   the same.
2. Mark "Editable Children" on every instance a scene overrides into or adds nodes under, then re-save every `.tscn`
   and `.tres` through the headless editor (`--headless --editor`, the research's two passes) until a further pass
   changes 0 files.
3. Keep what the player sees: the runtime dump of every node and sub-resource matches main's, except the values the
   engine works out again (named in the research). The Achievement toast keeps its look; the mirror's shader uniforms
   keep their values (the research saw them saved `null` headless).
4. Make a GUI save stable for one-shot particles (they must not be saved finished): say how, and if it needs a change
   in how a particle starts, keep the look and timing the same.
5. Commit the editor files missing on main: `assets/ui/menu_profile.svg.import`,
   `assets/wardrobe_station/wardrobe_station_fabric_palette.png` and its `.import` (made by the import), and any other
   file an import creates that is not committed.

## Acceptance
- After the merge, a headless editor re-save of the whole project changes 0 files, and `godot --import` leaves no new
  file (both run and their output in the report).
- The research's lint (`scene_lint.py`) reports no override under a non-editable instance and no array-literal
  `Packed*Array` export in a non-tool script.
- The runtime dump matches main's except the named engine-worked-out values (the `semdiff.py` summary in the report).
- The full suite passes (the integrate run); no test was edited to pass, except a pin that names a file's old text.
- Real path: in the zoo's cabinet station the player opens a drawer of the instanced Cabinet and its hands/bank wiring
  works as before (the existing case covers it; name it).

## Answers
- The editor re-save's losses are repaired at their source; the designer's re-save is discarded (Q2723, 2026-11-27).
- Files are kept in the Godot editor's own format (Q2268).

## Open follow-ups
- [later] The kit's own 9 scenes Godot sees (`kit/tests/{run,check,wiring}.tscn`, `kit/tests/support/wiring/*.tscn`,
  `kit/tools/{shot,net_shot}.tscn`) are not in the editor's format (no header uid, no ext uids, no `unique_id`): a
  headless re-save of `res://kit` changes all 9. A ticket agent cannot edit `kit/`; the lead re-saves them in the kit.
- [later] A cold import (no `.godot`) on Linux rewrites ~300 committed mesh `.res` files (`assets/cabinet/*.res`,
  `assets/furniture/meshes/*.res`) a few bytes each; a warm import leaves them alone. Not committed here (they are the
  glb imports' output, not this ticket's); worth a look whether the designer's Windows import writes them differently.
