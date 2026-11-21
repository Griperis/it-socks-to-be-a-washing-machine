---
type: ticket
status: wontfix
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
- [later] Not met: `mess_settle:real_path` fails on this branch: 4 of the zoo heap's 500 poured Socks rest with a
  box middle 6 mm or more inside another lying Sock ("inside" 4). core/37 has none there. Seen with the default
  budget of 128 jointed flights; a fallback to core/37's probe and a box-clear turn-back both made it worse (15
  and 22). Not understood; a guess is joint drift under load (the lying boxes are rebuilt from the angle only).
- [later] Added by the agent, the designer's call: a Throw and a drop from the hand fly as one body
  (`MessTuning.jointed_throws` off). Jointed, core/23's arc (solved for one body) landed off and the hand's carried
  cloth bend did not show. On, J5's "the held bend may start the joints" is not built.
- [later] Added by the agent, off by default: hinge stiffness and damping (`jointed_stiffness`,
  `jointed_damping`, a torque impulse a tick). Stiffness alone made an end flap a Sock along the floor; damping 0.002
  made about 600 of 2,000 poured Socks spin past `flip_spin` (4 with it off), at no tick cost either way. With
  plain hinges (the default) a Sock can rest standing on its edge like a folding screen (seen once, in a throw
  test, before throws went single). - [later] J3: a jointed flight with a cloth Looks has its cloth off and its bones posed from the hinges each frame
  (`SockBend.pose`), not the cloth on top. Not looked at in a still; the designer judges it in the review build.
- [later] `mess_bend_test.gd` (core/37's cases) now runs with `jointed_budget` 0: its cases test the probed bend
  of single-body flights.
- [later] Jolt's `penetration_slop` 0.005 (project setting, default 0.02) cleared `sunk` in `drape_500` at no
  measured cost, but did not fix the heap's "inside". Not changed: a project.godot change is the lead's call.
- [later] Not tried: the RigidBody3D-node and PhysicalBone3D/Skeleton3D routes (the segments are physics-server
  bodies with no node, which costs no node per segment and no transform sync), per-body solver iterations (Godot's
  Jolt has none per body), CCD only on the leg.
- [later] A Guest's copy of a jointed flight is the middle alone, drawn straight (the segments are Host only).
- [later] The lying instance gets the hinge angle snapped to 0 under `jointed_straight` (0.03 rad: 3 mm at a 10 cm
  end); about 97% of jointed rests still come out bent (Socks lie over each other's edges).

## Built log
- Model: Opus: hard physics and performance work.

### 2026-11-21
- Changed: up to `MessTuning.jointed_budget` (128) flights are three bodies (J1). The falling body is the middle.
  The leg and the foot are physics-server bodies (no node, no script; `JointedFlight`) on two Jolt hinges with
  limits, no motor. The mass is split by length, each part has the whole box's `turn_weight` inertia, and the
  middle's centre of mass is the whole Sock's. The segments carry the falling body's id, so picks and contacts
  find the Sock. Contacts are reported only while fast, CCD only with the middle, and materials and shapes are
  shared (J2). The flying instance is drawn with the hinge angles in its colour alpha. A cloth Looks has its cloth
  off and its bones posed from the hinges (J3). A rest writes the middle's pose and the angles, with no probe and
  no drape; a woken bent Sock starts jointed at its bend (J4). Pairs, Throws and drops fly as one body (J5,
  `jointed_throws`). The bench has `--tune=` and a "jointed at most" column. The report with core/37 vs this
  branch, the budget sweep and the steps is in `builds/review-core-38/report.md` (J6). Budget 128 is recommended:
  `pour_2000` p95 about 10 ms vs 7.5-8.9 ms single.
- Files: `game/mess/jointed_flight.gd` (new), `mess.gd`, `mess_moving.gd`, `mess_drawing.gd`, `mess_tuning.gd`;
  `game/debug/mess_bench.gd`, `mess_bench_report.gd`; `tests/mess_jointed_test.gd` (new), `tests/mess_bend_test.gd`;
  `docs/architecture/mess.md`.
- Verified: `kit/tools/run.sh --touched`: FAIL 1 of 16733 checks, 371 cases (`mess_settle:real_path`: "inside" 4),
  so the acceptance is not met and this is a WIP commit (Open follow-ups); rules PASS.

### 2026-11-21 (lead): closed
- The designer played the review build: jointed flights are not worth it (Q2423, 2026-11-21). Never merged; the branch
  and `builds/review-core-38/` stay for reference. A "really flappy" build followed on the designer's ask
  (`builds/review-core-38-flappy/`, commit 4ae1dd6: `jointed_flap` 0.05, hinges 2.4 rad, every flight and throws
  jointed; 21 checks fail, throws mostly; no tests run on it, an experiment).
- Taken to main: the pair-moment preload loop that broke exported builds (9b829af); the bench's `--tune=` and the
  flights' shared physics materials (cd3d60d). Jolt penetration slop 0.005 (fewer sunk Socks) was not taken.
- Learned: spin is what flips a Sock (hinge damping and torque raised flips many times); joints cost about 1.5x a
  one-body pour, not 3-4x; contact reports are most of a flying body's extra cost.
