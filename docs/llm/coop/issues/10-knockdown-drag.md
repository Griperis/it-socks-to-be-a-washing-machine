---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: coop
priority: now
created: 2026-11-22
blocked_by: []
notes: ["M0.6 batch 4 (Q2225, Q2437); list approved by Q2496; ragdoll facts: docs/research/coop-ragdoll-sync.md"]
terms: [Host, Guest, Teammate, Throw, Hands, Mess, Pair]
---

# Knockdown and drag in co-op, with Godot's own ragdoll

A full-charge Throw of a Sock or a Pair knocks a Teammate down: they fall as a Godot physical-bone
ragdoll, drop what they hold, see a vignette from the ragdoll's head, and get up 5.5 s later. A Teammate
can grab a lying body by the feet and drag it; the dragged player mashes Space to struggle free. Everyone
sees it. The wash waits for the washing machine (M5, Q2437).

## Behaviour list
`docs/migration/m06-lists/04-knockdown.md`, approved by Q2496, with Q2437, Q2438 and Q2483-Q2495 folded
in. Lines marked "needs ..." (the lantern, Radio, Beeper, Guide card, Cat, Backpack vacuum, Hamper,
Elevator, washing machine, launcher, stack, rogue sequence) are out of this ticket; section I (wash) is
out. One test per remaining line, named after it.

## Design
- **The ragdoll** (coop/02, `docs/research/coop-ragdoll-sync.md`): the avatar's 4 bones (Q2438) with a
  PhysicalBoneSimulator3D and one PhysicalBone3D each, authored in the avatar's scene, not made in code;
  numbers in a typed Resource (placeholders where the old ones were). The Host simulates it; every other
  machine eases a stamped pose at 12/s (option b: one PackedByteArray on a synchronizer at 0.05 s).
- **Decided state:** who is down, until when, who drags whom, struggle presses: on a Part, written by the
  Host's answer. The hit is decided by the Host from the Throw's stamped body (coop/09).
- **What the hit does:** the charge is cancelled; the Hands drop as a leaver's (Q2485, Q2486: reuse that
  path, a Pair as a ball); a drag the knocked player held ends.
- **The knocked view:** the camera rides the ragdoll's head with the wall gap; input frozen; HUD stays;
  the own body in the ragdoll pose (Q2495, building on coop/06); a vignette (Q2490) as a Looks scene or
  a shader on the camera's environment. **Look and feel stops at the first still** of the vignette and
  waits for the designer.
- **Getting up:** the old 0.6 s smoothstep blend, the same facing, feet onto the floor, no hop (Q2488);
  no immunity after (Q2487).
- **Drag:** left click on a lying body wins over a Sock or a station (Q2493); the feet are pulled to the
  dragger; the struggle is 10 Space presses with the hint "Mash: Struggle [Space]" only (Q2489); the
  drag ends at the rise, at a knockdown of the dragger, at a menu, at a leave.
- **Message, sound, rumble:** "<Name> knocked you down" to the knocked player alone (Q2494); the first
  "knockdown" placeholder at the hit point on every machine (Q2491); the "knock" rumble for the knocked
  and the dragged player only (Q2492); "drag_scrape" while dragged.
- **A zoo station** (`game/zoo/stations/knockdown.tscn`) with a stand-in Teammate that can be knocked and
  dragged when playing alone, driven only through what a real Teammate sends (as Q2468).

## Acceptance
- Real path: two zoos (Host, Guest) at 50 ms one way; the Host's input throws a full-charge Sock at the
  Guest's avatar: the Guest falls as a ragdoll on both machines, drops its held Socks where it stood,
  sees "Player knocked you down", hears the sound, and stands up 5.5 s later where it lies.
- A weaker Throw never knocks; the thrower and someone already down are never knocked.
- The Guest drags the knocked Host by the feet; the Host's 10 Space presses free it; the drag ends at
  the rise.
- A late joiner sees a lying ragdoll and a drag in progress.
- A forged knockdown or drag Command from a Guest is refused by the Host.
- Measured in the Built log at 0 and 50 ms: bytes a second per knocked player.
- Stills for the designer: the knocked view with the vignette, the own body while down, a Teammate lying
  and being dragged (`builds/review-knockdown/`).

## Answers
- Q2225, Q2437, Q2438, Q2483-Q2496 (2026-11-22).

## Open follow-ups

## Built log
