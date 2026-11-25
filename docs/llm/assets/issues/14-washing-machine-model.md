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
- (lead, at the designer's yes) The real Looks takes core/87's Damage nodes (sparks, smoke, flash, buzz, rumble) from the graybox; the branch has placeholders. The rig parent fix is already on main (bob carries the door, brows and drum).
- Look work: stops at its first line-up (old and port side by side, each mood pose, the mouth open) in `builds/review-assets-14/`, `ready-for-human`; assets per family batch.
- No real-path case (Q2421); the Looks contract test passes on `looks_washer.tscn`.

## Answers
- None beyond the design's (see the files named above).

## Open follow-ups
- [later] The designer's go on the line-up (old beside port, each mood pose, the mouth open):
  `builds/review-assets-14/` (Look work stops here; assets per family batch).
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
