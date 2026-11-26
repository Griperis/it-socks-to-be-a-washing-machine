---
type: ticket
status: ready-for-agent
kind: build
area: assets
feature: assets
priority: now
created: 2026-11-26
done:
blocked_by: ["[[29-cat-model-and-clips]]", "[[179-cat-litterbox-visit]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave later", "suggested model: opus"]
terms: [Cat]
suites: [menus]        # menus l02: every new file under assets/ needs a credits entry
---

# The litterbox scratch clip

A new `scratch` clip on the ported rig: the front paws digging in the litter (the old swat's timing only as a starting
point), added to `assets_src/generate/cat/` and exported with the others; `looks_cat.tscn`'s `scratch` points at it.
Q2703 gives the litterbox scratch its own clip. `docs/architecture/cat.md` draft AS-K. Behaviour line
(`12-cat-and-litterbox.md`): L4's own clip. Waits for the designer's go on assets/29 (its rig).

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). A new clip on the ported rig, not a port of an old one: its motion is the designer's to judge at the strip.

## How it is authored
The clip's keys in the generator; a new motion is the designer's to judge.

## Acceptance
- Look work: a strip of the new scratch beside the old swat (the same views) in
  `<main checkout>/builds/review-cat-scratch/`; `status: ready-for-human`; stops at its first line-up for the designer's go
  (the `review-material` skill).
- `python3 kit/tools/asset_lint.py` passes on its Looks scene; its Looks meets the entity's `looks_contract.json`.
- On the designer's yes (not before): `looks_cat.tscn`'s `scratch` is the new clip (core/179's visit plays it).
- No real-path case (a look ticket, Q2421).

## Answers
- The litterbox scratch gets its own clip and sound (Q2703, 2026-11-26).

## Open follow-ups
