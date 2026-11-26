---
type: ticket
status: ready-for-agent
kind: build
area: assets
feature: assets
priority: now
created: 2026-11-26
done:
blocked_by: []
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 2", "suggested model: opus"]
terms: [Radio]
suites: [menus]        # menus l02: every new file under assets/ needs a credits entry
---

# The Radio's model

The old radio (`make_radio.py`) ported by the asset port rules, the old colours: the radio with its dial (`Dial`),
needle (`Needle`) and speaker cloth (`Speaker`), shown at 1.5 times by its Looks (R1); clips `on`, `off` (the dial's warm
glow) and `dial` (the needle along the dial) per `docs/architecture/tv-and-radio.md` "Looks contracts". Draft AS-C2-5.

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Ported by examination, technical improvements only (origins, scale, names, collision, shared materials, file
size; Q2153); a look change is its own ticket.

## How it is authored
The generator script under `assets_src/generate/radio/` and its `assets/blender_assets.json` entry; the shared
materials.

## Acceptance
- Look work: the before-and-after strip (the old beside the port, the same views) in
  `<main checkout>/builds/review-radio/`; `status: ready-for-human`; stops at its first line-up for the designer's go
  (the `review-material` skill).
- `python3 kit/tools/asset_lint.py` passes on its Looks scene; its Looks meets the entity's `looks_contract.json`.
- On the designer's yes (not before): `radio.tscn` points its Looks at this scene; the graybox goes.
- No real-path case (a look ticket, Q2421).

## Answers
- Batch C's models are ported from the old game by the port rules, each family with its strip and the old colours (Q2705, 2026-11-26).

## Open follow-ups
