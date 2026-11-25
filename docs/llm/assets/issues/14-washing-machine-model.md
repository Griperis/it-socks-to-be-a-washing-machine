---
type: ticket
status: ready-for-human
kind: build
area: assets
feature: assets
priority: now
created: 2026-11-24
done:
blocked_by: [core/86]
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: opus"]
terms: [Voice line]
---

# The washing machine's model, rig and animations

Build `docs/architecture/washer.md` "The model and rig": `reference/it-socks/assets_src/blender/washing_machine.blend` to
`assets_src/blender/appliance/washing_machine.blend`, `make_washing_machine_face.py` ported into `tools/blender/` (the
brows, the lit drum, the laundry, the rig `face_rig` and its eight actions), exported to
`assets/appliance/washing_machine.glb` with a collider and the shared materials, `looks_washer.tscn` built to core/86's
`looks_contract.json`, and the one-line swap in `washer.tscn`. Technical improvements only (Q2151-Q2153).

Behaviour lines (`docs/migration/m4-lists/05-washer-and-voices.md`): "Where it stands and what it is": the look line (no eye, side-hinged door, brows, drum).

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the lines named below is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

The model by its script; the game's AnimationTree and properties stay in the Looks scene, not in the glb.

## Acceptance
- Look work: stops at its first line-up (old and port side by side, each mood pose, the mouth open) in `builds/review-assets-14/`, `ready-for-human`; assets per family batch.
- No real-path case (Q2421); the Looks contract test passes on `looks_washer.tscn`.

## Answers
- None beyond the design's (see the files named above).
- Q2655 (2026-11-25, on the line-up): "OK except there are some weird shadow artifacts, most likely." Sent back:
  find and fix them in the asset (not the game's lights or shadow settings), a before/after line-up of the
  fixed spots (`*-shadowfix*`), stop at ready-for-human again.

## Open follow-ups
- [later] The designer's go on the line-up (old beside port, each mood pose, the mouth open):
  `builds/review-assets-14/` (Look work stops here; assets per family batch). After Q2655: the shadow fix,
  before beside after, `washer-lineup-<pose>-shadowfix.png` and the spots `washer-lineup-shadowfix-spots.png`.
- [blocking] What is left is the sun's shadow itself, not the model: with the door open, the edge of the
  shadow inside the drum is stepped in squares, and the door ring's face shows a few small steps where its
  lip shadows it (spots 4 and 1 of `washer-lineup-shadowfix-spots.png`). The steps are the size of the
  shadow map's texels at this distance (the zoo's Sun, normal bias 2, blur 0 from the Picture). Only a light
  or shadow setting makes them finer, which this ticket may not change: does the designer want that looked
  at (a ticket of its own, it touches every model in the sun), or is it fine as it is?
- [later] The kit's asset contract wants snake_case node names; the Looks contract's `Lining` and `Pile` are glb
  mesh names (advice only, asset_checks; the export does not stop on it).
- [later] The script lives with the other generators in `assets_src/generate/appliance/` (the ticket said
  `tools/blender/`, the folder before zoo/34 moved the generators).

## Built log

### 2026-11-25
- Changed: the washer wears the old washing machine (no eye, side-hinged door mouth, brows, lit drum, laundry): the
  old face script ported (every bone up so Godot rests are moves only; lining and power light one `Lining` mesh that
  glows per mood; the laundry `Pile` on its bone, growing from its bottom middle), exported with its eight actions; an
  import script lifts the Skeleton3D to `face_rig`, drops the collider, keeps each action's own bones and splits the
  three players by the contract; `looks_washer.tscn` inherits the glb; washer.tscn swapped. Brass and steel from the
  library; its other materials stay its own. Contract parents: the face bones under `bob`, as the old rig.
- Files: assets_src/generate/appliance/make_washing_machine_face.py, assets/appliance/washing_machine.glb(.import),
  game/entities/washer/looks_washer.tscn, washer_model_import.gd, looks_contract.json, tools/shots/sets/washer-lineup.txt
- Verified: see the commit's verdict lines; line-up builds/review-assets-14/

### 2026-11-25 (shadow fix, Q2655)
- Changed: the stripes of false shadow on the washer in the sun are gone. (1) The body's big flat faces (the
  front round the door hole, the panel) are long thin triangles whose corners shared smooth normals with the
  bevels and the gasket, up to 46 degrees off the face; the shadow's normal bias followed them, so the body
  shadowed itself in stripes fanning out round the door, the brows and the panel. Each flat face now has its
  own normal at its corners (a weighted-normal modifier on the body, the door, the dial and the drawer, at
  export). (2) The raised trims (worktop, panel, ring round the door, gasket, feet, steel and brass bits) stand
  1-2 cm proud of the shell and drew false stripes beside them in the sun's coarse shadow: they are their own
  mesh `body_trim` now and, with the dial and the drawer, cast no shadow (the import script); they still take
  shadow, and the shell, the door and the brows still cast. A rebuild from the saved .blend joins the trim
  back first (and `_join` takes an emptied material slot).
- Files: assets_src/generate/appliance/make_washing_machine_face.py, assets_src/blender/appliance/washing_machine.blend,
  assets/appliance/washing_machine.glb, game/entities/washer/washer_model_import.gd
- Verified: see the commit's verdict lines; before/after builds/review-assets-14/*-shadowfix*
