---
type: ticket
status: ready-for-agent
kind: research
area: core
feature: coop
priority: now
created: 2026-11-22
done:
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

## Built log
- 2026-11-22 lead: model opus (hard netcode and physics, CLAUDE.md "Models").
