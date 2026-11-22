---
type: ticket
status: ready-for-human
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
- [blocking] The vignette (Q2490) waits for the designer's go on its first still,
  `builds/review-knockdown/knockdown-view.png` (and `knockdown-own-body.png`): black edges, `vignette_dark`
  0.7 from `vignette_start` 0.45 (middle 0, corner 1), in `game/knockdown/knockdown_tuning.tres`. Keep, change the numbers, or another look?
- [blocking] H91 says the lying body is outlined (highlighted) under the crosshair; only the "Hold: Drag" prompt is
  built. The avatar has no Outline yet. Build the outline here, or later in its own ticket?
- [later] Looks for the designer to judge from the stills: a dragged body is pulled through the dragger to
  `hold_behind` 0.6 m behind them (the old numbers) and, let go, lies round their legs (it still lets them through
  until it stands, so it is not flung out of them); the knocked view in `knockdown-view.png` looks at the sky after a
  fall backwards.
- [later] The Knockdown station stands at (-17.5, 0, 3.5) beside Handling, its pad 4.5 x 4 m: the only free floor
  inside the Mess's bounds. The designer may move it by hand.
- [later] It holds 2 Socks, not 3: with 1 or 3 more Sock records in the zoo, `mess_settle:real_path` fails ("no Sock
  inside (2)": the heap's pour leaves two Socks resting inside each other). It passes with 0 or 2. A latent fault of
  the Mess's settle, found here, not fixed here.
- [later] Lines built and not proven by a case: F70-F71 (the view stops `wall_gap` short of a wall: no wall at the
  station), E53 (a Teammate inside the falling body), E62/F72 (the Host's bones drawn interpolated: headless shows no
  frames between ticks), H97 (a menu lets go), H101 ("apart"), D37 in co-op (a knocked dragger's drag ends: tested
  only in the Host's answer).
- [later] In the station the stand-in has no Roster entry, so a knock by it reads "A teammate knocked you down" (the
  old fallback); a real Teammate's name shows in co-op.

## Built log

### 2026-11-22
- Changed: a full-charge Throw of a Sock or a Pair knocks a Teammate down as Godot's physical-bone ragdoll (four bones
  authored in `ragdoll.tscn`, the Host simulates, a stamped 84-byte pose eased at 12/s elsewhere); the Hands drop as a
  leaver's; knockdown sound at the hit, knock rumble for the knocked and the grabbed; the knocked view rides the head
  with a vignette, input frozen, own body lying; up 5.5 s later where it lies; drag by the feet, 10 Space presses free;
  late joiners see it; a Guest's knock is dropped. Zoo station Knockdown with a stand-in Teammate. PROTOCOL 13.
- Files: game/knockdown/, game/parts/avatar/ragdoll.*, avatar.gd/tscn, avatar_looks.gd, game/player/player.*,
  game/zoo/stations/knockdown.tscn, tests/knockdown_test.gd, tests/coop_knockdown_test.gd
- Bytes a second per knocked player (Host's ENet total, falling, minus standing): 1,943-2,023 B/s at 0 ms,
  1,950-2,029 B/s at 50 ms; 16.7-17.3 poses a second reach the Guest.
- Verified: see the commit's `suite:` line; stills in builds/review-knockdown/ (view, own-body, lying, dragged).
