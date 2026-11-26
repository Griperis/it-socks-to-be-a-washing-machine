---
type: ticket
status: ready-for-agent
kind: build
area: assets
feature: assets
priority: now
created: 2026-11-26
done:
blocked_by: ["[[176-cat-walks-the-house]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 7", "suggested model: opus"]
terms: [Cat]
suites: [menus]        # menus l02: every new file under assets/ needs a credits entry
---

# The Cat's model and clips

The old Cat (`assets/cat/cat.glb` from `tools/blender/make_cat.py`, its clips from `tools/blender/cat_anims.py`) ported
by the port rules (technical only) into `assets_src/generate/cat/`, built by `build.py -- cat` to `assets/cat/cat.glb`:
the 16-bone rig, the `eyes_closed` shape key, the nine old clips (stand, sit, curl, fall, held, walk, run, swat, dizzy;
the held tip and the dizzy stagger baked into their clips where the old did them in code, keeping their numbers), the
calico patches as a vertex colour layer made once from the rest pose (the old CV:39-57 rule: frequency 9, cut 0.12,
white below 0.1 m), shared materials (Q2177), and `looks_cat.tscn` meeting core/176's contract (`scratch` still the
placeholder until assets/30). `docs/architecture/cat.md` draft AS-C. Behaviour lines (`12-cat-and-litterbox.md`): W1's
look, R7's real clips.

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Ported by examination, technical improvements only (origins, scale, names, collision, shared materials, file
size; Q2153); a look change is its own ticket.

## How it is authored
The generator script and its `assets/blender_assets.json` entry; the clips' keys are the motion's numbers; the coats
are core/176's `CatCoat` files (the fur's material takes the coat).

## Acceptance
- Look work: the before-and-after strip (the old beside the port, the same views) in
  `<main checkout>/builds/review-cat/`; `status: ready-for-human`; stops at its first line-up for the designer's go
  (the `review-material` skill).
- `python3 kit/tools/asset_lint.py` passes on its Looks scene; its Looks meets the entity's `looks_contract.json`.
- On the designer's yes (not before): the one line in `cat.tscn` swapping `looks_graybox.tscn` for `looks_cat.tscn`, done outside a wave where another ticket edits `cat.tscn`.
- No real-path case (a look ticket, Q2421).

## Answers
- Batch C's models are ported from the old game by the port rules, each family with its strip and the old colours (Q2705, 2026-11-26).
- The Cat and its clips (Q2705, 2026-11-26).

## Open follow-ups
