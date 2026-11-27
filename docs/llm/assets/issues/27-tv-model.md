---
type: ticket
status: done
kind: build
area: assets
feature: assets
priority: now
created: 2026-11-26
done: 2026-11-27
blocked_by: []
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 9", "suggested model: opus"]
terms: [TV]
suites: [menus]        # menus l02: every new file under assets/ needs a credits entry
---

# The TV's model

The old TV (`make_tv.py`) ported by the asset port rules, the old colours: the modern widescreen flat-screen set on its
walnut and cream console, the glass as its own mesh (`Glass`, left out of the outline), the power light
(`PowerLight`); clips `static`, `off`, `on` per `docs/architecture/tv-and-radio.md` "Looks contracts". Draft AS-C2-4.

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Ported by examination, technical improvements only (origins, scale, names, collision, shared materials, file
size; Q2153); a look change is its own ticket.

## How it is authored
The generator script under `assets_src/generate/tv/` and its `assets/blender_assets.json` entry; the shared materials.

## Acceptance
- Look work: the before-and-after strip (the old beside the port, the same views) in
  `<main checkout>/builds/review-tv/`; `status: ready-for-human`; stops at its first line-up for the designer's go
  (the `review-material` skill).
- `python3 kit/tools/asset_lint.py` passes on its Looks scene; its Looks meets the entity's `looks_contract.json`.
- On the designer's yes (not before): `tv.tscn` points its Looks at this scene; the graybox goes.
- No real-path case (a look ticket, Q2421).

## Answers
- Batch C's models are ported from the old game by the port rules, each family with its strip and the old colours (Q2705, 2026-11-26).
- Yes to the TV's model as the line-up shows it; the screen's thicker bottom band, the brighter doors and the early glass shader stay as they are (Q2729, 2026-11-27). `tv.tscn` does not exist on this base (nor on main), so pointing its Looks at `looks_tv.tscn` and dropping the graybox belongs to core/165.

## Open follow-ups
