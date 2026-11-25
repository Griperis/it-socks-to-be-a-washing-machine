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
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: opus"]
terms: [Stage, Floor]
---

# Floor lock models

The locked ways up, ported by examination: the plank door (ledges, Z brace), the painted baby gate, the steel chain
and the brass padlock from the old `tools/blender/make_house.py`:1051-1310, fitted to the port's stair openings, in
`assets_src/` by the Blender skill, built to core/80's Looks names (`looks_lock_door.tscn`, `looks_lock_gate.tscn`,
the chain and padlock nodes its `unlock` animation keys). Design: `docs/architecture/stages.md` "The floor locks".

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the lines named below is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

Models built by `tools/blender/` scripts (build() safe to re-run); the shared materials (Q2177).

## Acceptance
- (core/91) Keep the placed locks' swing: the lock door opens to -90°, and the gate hangs on its other post (chain on the players' side).
- (core/80) The Looks make `leaf` an AnimatableBody3D: physics follows only a body's own keyed transform. Fixed on the branch when the designer says yes.
- Look work: stops at its first line-up (the old and the port side by side) in `builds/review-assets-10/`, `ready-for-human`; assets are approved per family batch.
- No real-path case (a look ticket, Q2421); core/80's Looks names and animations still play on the models.

## Answers
- None beyond the design's (see the files named above).

## Open follow-ups
- [later] After the go: `chain`, `lock_dark`, `trim` and `wall_hall` are not in the shared library `game/materials/` yet
  (the house kit has its own `trim` and `wall_hall`); the glbs draw their own copies of those four until the library gets
  them. `brass`, `dark_wood`, `oak` and `steel` are mapped to the library.
- [later] core/80 builds `looks_lock_door.tscn` and `looks_lock_gate.tscn` on these glbs and keys `unlock` and `open`
  on the nodes `leaf`, `chain`, `padlock` (docs/architecture/stages.md "The floor locks"); not done here (core/80
  comes in wave 4).

## Built log
- 2026-11-25 (first line-up, stopped for the designer's look)
  - Changed: the plank door (planks, ledges both faces, Z brace, ring pulls, frame and head, the wall panel up to the
    ceiling) and the painted baby gate (stiles, rail, spindles, oak handrail; posts with oak caps and knobs), each with
    the chain on two eyes and the brass padlock, ported from the old make_house.py:1051-1322 and fitted to the port's
    1.13 m flight; family `lock` in `assets_src/generate/build.py`; the old bevel (corner vertices only) kept. Triangle
    counts match the old per node (leaf 568, chain 1600/1920, padlock 308) but the gate's leaf (+1 spindle, 492).
    Choices settled by the old: docs/migration/batch-a-review.md (two assets/10 rows).
  - Files: `assets_src/generate/lock/make_locks.py`, `assets_src/generate/build.py`, `assets_src/generate/README.md`,
    `assets_src/blender/lock/lock_door.blend`, `lock_gate.blend`, `assets/lock/lock_door.glb(.import)`,
    `lock_gate.glb(.import)`, `assets/blender_assets.json`, `game/ui/licence/credits.tres`,
    `docs/architecture/stages.md`, `docs/migration/batch-a-review.md`.
  - Line-up (old | port door, old | port gate): `builds/review-assets-10/lineup-front.png`, `lineup-back.png`,
    `lineup-locks-door.png`, `lineup-locks-gate.png`.
  - Verified: asset checks PASS both; glb_compare script vs .blend 2/2 the same; `PASS 20987 checks, 617 cases`; grep_rules PASS; asset_lint PASS.
