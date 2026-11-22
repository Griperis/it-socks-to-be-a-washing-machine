---
type: ticket
status: done
kind: research
area: core
feature: coop
priority: now
created: 2026-11-22
done: 2026-11-22
blocked_by: []
notes: ["M0.6 batch 0 (Q2436): a spike; only its report merges"]
terms: [Host, Guest, knockdown]
---

# Spike: a Godot ragdoll's pose reaching a Guest

Q2225: the knockdown uses Godot's own physical-bone ragdoll, and how its pose reaches other players is
tested before it is built. The avatar keeps the old 4 bones, Root and Spine0-2 (Q2438). The old ragdoll:
four stacked capsules of 0.3 m radius, cone joints 45 degrees swing and 22.5 twist, simulated on the Host,
4 bones x 20 bytes sent 20 times a second, Guests easing at 12 per second
(`docs/migration/m06-lists/04-knockdown.md` section 4; reference `game/player/ragdoll.gd`).

## Acceptance
- A throwaway skeleton with the 4 bones (a stand-in for `avatar.glb`, which is not ported yet) under a
  PhysicalBoneSimulator3D with PhysicalBone3D nodes, on Jolt, knocked by an impulse on the Host.
- A headless Host and Guest test: the Guest's skeleton shows the Host's ragdoll pose; compare (a) a
  synchronizer on the bone poses, (b) one stamped property with all bones eased on the Guest; measure the
  largest pose jump, lag and bytes per second at 0 ms and 50 ms one way.
- Report in `docs/research/coop-ragdoll-sync.md`: whether Godot's PhysicalBone3D works under Jolt in 4.7.2
  for this skeleton, the sync that worked, the numbers, and what the avatar model must provide (bone names,
  rest pose, collision shapes).
- No change to game behaviour on `main`; only the report merges unless a test is worth keeping and not flaky.

## Answers
- Godot's own physical-bone ragdoll (Q2225); 4 bones as the old avatar (Q2438); drag in M0.6, wash later (Q2437).

## Open follow-ups
- [later] The recommended sync (stamped, eased at 12/s) shows a Teammate's fall about 100 ms late at 0 ms
  and 155 ms at 50 ms one way. Whether that reads well is the designer's eye at the knockdown walkthrough;
  the fallback (interpolating the two newest poses) is in the report.
- [later] Keep or drop `tests/ragdoll_spike_test.gd` and `tests/support/ragdoll_spike/` at merge: stable in
  4 runs (about 10 s), a guard for PhysicalBone3D on Jolt at an engine bump; retire them when the knockdown's
  own suite lands.

## Built log
- 2026-11-22 lead: model opus (hard netcode and physics, CLAUDE.md "Models").
- 2026-11-22 agent: Changed: a 4-bone stand-in ragdoll (PhysicalBoneSimulator3D, 4 PhysicalBone3D,
  cone joints) on Jolt, a shown copy skeleton, and two syncs measured Host to Guest over real ENet at 0
  and 50 ms one way; report with numbers and what the avatar must provide. No game file touched. No
  player-input real path exists yet (no avatar or hit): the cases drive the Host's knock and read the
  Guest's skeleton. Files: tests/ragdoll_spike_test.gd, tests/support/ragdoll_spike/ragdoll_spike.gd,
  tests/support/ragdoll_spike/ragdoll_spike.tscn, docs/research/coop-ragdoll-sync.md. Verified: PASS 28
  checks, 5 cases (4 runs of --only=ragdoll_spike).
