---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: core
priority: now
created: 2026-11-21
done:
blocked_by: ["[[37-bent-lying-socks-experiment]]"]
notes: ["experiment: branched from core/37's branch, never merged until the designer says (Q2419, Q2422)"]
terms: []
---

# Experiment: jointed flying Socks (the full bend sim)

The designer (Q2422, 2026-11-21): "For 37 could we try the full bend sim? Ideally super optimized. But only for 37."
core/37 bends a Sock only as it comes to rest (probes, shader). This tries option B of the lead's estimate: a flying
Sock is three segments joined by two hinges (heel, ankle), so it flops, drapes and tangles while it moves, and comes
to rest with the bends the simulation gave it. Built on a branch **from `core/37-bent-lying-socks-experiment`**, never
merged; the designer plays it from a review build beside core/37's, to compare.

The lead's estimate to beat: done naively, three bodies, two joints and about three times the contacts per flight make
a pour tick about 3-4 times dearer (a 2,000-Sock pour from about 7 ms to 20+ ms median, over the 16.6 ms budget).
"Super optimized" is the brief: find what Jolt in Godot 4.7.2 makes cheap, measure each step, keep what pays.

## Behaviour list
- J1 A flight is three bodies (leg, heel, foot), each one simple shape (a box or capsule fitted to the segment, sized
  from the shape's bones like `MessBodies.parts_at`), joined by two joints with limits near the cloth's range (Jolt's
  hinge or a 6DOF with tight limits and soft drives; the cheapest that holds). The three bodies never collide with
  each other. Mass split by length; inertia handled as core/23's `turn_weight` does (no spin to Jolt's cap).
- J2 Optimise, measure each step on core/31's benchmark, and keep what pays. Candidates to try: a moving budget for
  jointed flights below the 512 cap (nearest the camera first, the rest fly as today's single body and rest with
  core/37's probed bend); solver iterations per body; joints as Jolt constraints with no motor; CCD only on the leg
  segment or only above a speed; one shared PhysicsMaterial; sleeping thresholds so a draped Sock sleeps fast; the
  three bodies under one node with no per-body script; Godot's `PhysicalBone3D`/`Skeleton3D` route versus plain
  RigidBody3D + joints (whichever is cheaper per flight). The report says what each step bought.
- J3 Drawing: a jointed flight with no Looks is drawn as one instance bent by core/37's shader from its two joint
  angles each frame (no skeleton, no extra MultiMesh); a nearest flight with a cloth Looks drives its bones from the
  three bodies (the cloth node's own bend off, or added on top lightly: say which looks right).
- J4 Rest: a jointed Sock rests when all three are still (or Jolt sleeps them); its lying pose is the leg's transform
  plus the two joint angles straight into core/37's record (no probe needed; the probe stays for the single-body
  fliers). No pop at the switch: core/31's watch, `jumped` 0.
- J5 Everything a flight does today still works on a jointed one: a pick in the air, hits that wake, door and drawer
  sweeps, the throw and drop from the hand (the held bend may start the joints), pairs (a ball stays one body),
  shelving, the lost rule.
- J6 Bench: every scenario on core/37's branch versus this branch, plus the jointed budget's effect (e.g. 64, 128,
  256, all) on `pour_2000` and `drape_500`; the report recommends a budget that keeps `pour_2000`'s p95 under the
  16.6 ms frame on this machine.

## Acceptance
- The bench report in `builds/review-core-38/report.md` (core/37 vs this branch, the budget sweep, what each
  optimisation bought).
- The existing suite passes (no new tests for the look, Q2421; behaviour that changes gets its case).
- Status `ready-for-human`: the lead exports the review build; not merged until the designer says.

## Answers
- The full bend sim, as optimised as possible, only on the experiment branch (Q2422, 2026-11-21).

## Open follow-ups

## Built log
- Model: Opus: hard physics and performance work.
