---
type: ticket
status: done
kind: build
area: assets
feature: assets
priority: now
created: 2026-11-24
done: 2026-11-25
blocked_by: []
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: sonnet"]
terms: [Part]
---

# Machine Part models

The four old Part glbs (`reference/it-socks/assets/parts/part_*.glb`: filter, motor, drum belt, detergent; within
0.22 m, bottom centre on the origin) imported with their Looks scenes (`looks_filter` .. `looks_detergent`), each with
core/79's `lying` animation node names; each `MachinePartKind` points at its Looks. Design: `docs/architecture/stages.md` "Machine Parts".

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the lines named below is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

One Looks scene per kind; nothing else.

## Acceptance
- Look work: a line-up of the four Parts, old and port, in `builds/review-assets-12/`, `ready-for-human`.
- No real-path case (Q2421); the Parts still pop, lie and carry in the Stages station.

## Answers
- None beyond the design's (see the files named above).

## Open follow-ups
- [later] For core/79 (a hand-over, not a choice): the Looks names are `Part`, `Model`, `Outline`, `AnimationPlayer`
  with `lying` (`game/entities/machine_part/looks_contract.json`); its graybox Looks must carry the same. The old bob
  ran on each Part's own phase (`+ id`, `part_view.gd:135`): core/79 seeks `lying` to a per-Part start. Carried or
  popping, the old set the Part's turn and bob to 0: core/79 plays `RESET`. Its ticket's `MachinePartTuning` spin and
  bob are now keys in the Looks (and the old rate is 2.2 rad/s, not 2.2 Hz): the lead decides whether core/79 drops them.
- [later] The softener (`part_softener.glb`, the old fifth Part) is not in this ticket's four; it comes with whoever ports the shrine.
- [later] The old generator scripts `make_part_*.py` need `washer_parts.py` (the washer's): they belong with assets/14.

## Built log

### 2026-11-25
- Changed: the four old Part glbs (filter, motor, drum belt, detergent) imported unchanged with the old import settings,
  their old `.blend` sources beside the others; one Looks per kind (`Part` holding `Model` and `Outline`, an
  AnimationPlayer with `RESET` and the looping `lying`: the old spin and bob as keys); each `MachinePartKind` names its
  Looks; `looks_contract.json` fixes the names core/79's graybox and Part follow. Shot hook `machine_parts`, set `machine-parts`.
- Files: `assets/parts/`, `assets_src/blender/parts/`, `assets/blender_assets.json`, `game/entities/machine_part/`,
  `tools/shot_hooks.gd`, `tools/shots/sets/machine-parts.txt`, `assets_src/generate/README.md`, `docs/migration/batch-a-review.md`
- Verified: `PASS 20681 checks, 601 cases` (run.sh --touched); `PASS rules`, `PASS asset_lint`; stills `builds/review-assets-12/line-up-old-port.png`, `lying-strip.png`
