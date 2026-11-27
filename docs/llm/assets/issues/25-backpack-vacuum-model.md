---
type: ticket
status: ready-for-human
kind: build
area: assets
feature: assets
priority: now
created: 2026-11-26
done:
blocked_by: []
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 4", "suggested model: opus"]
terms: [Backpack vacuum]
suites: [menus]        # menus l02: every new file under assets/ needs a credits entry
---

# The Backpack vacuum's model

The old Backpack vacuum (`make_backpack_vacuum.py`, `vd_common.py`) ported by the asset port rules, the old colours: the
capsule tank with its porthole and heap markers, the straps, the port, the nozzle with its dial gauge; its worn and
lying poses as the `worn` / `lying` clips. Its Looks meets `docs/architecture/devices.md` "Looks contracts" (`Tank`
heap markers, `Port`, `Dial`, `Straps`; clips `worn`, `lying`, `fill`). Draft AS-C2-2.

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Ported by examination, technical improvements only (origins, scale, names, collision, shared materials, file
size; Q2153); a look change is its own ticket.

## How it is authored
The generator script under `assets_src/generate/backpack_vacuum/` and its `assets/blender_assets.json` entry; the
shared materials; the clips keyed in the Looks.

## Acceptance
- Look work: the before-and-after strip (the old beside the port, the same views) in
  `<main checkout>/builds/review-backpack-vacuum/`; `status: ready-for-human`; stops at its first line-up for the designer's go
  (the `review-material` skill).
- `python3 kit/tools/asset_lint.py` passes on its Looks scene; its Looks meets the entity's `looks_contract.json`.
- On the designer's yes (not before): `backpack_vacuum.tscn` points its Looks at this scene; the graybox goes.
- No real-path case (a look ticket, Q2421).

## Answers
- Batch C's models are ported from the old game by the port rules, each family with its strip and the old colours (Q2705, 2026-11-26).

## Open follow-ups
