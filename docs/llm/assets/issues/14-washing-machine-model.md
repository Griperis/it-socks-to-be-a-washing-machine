---
type: ticket
status: ready-for-agent
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

## Open follow-ups

## Built log
