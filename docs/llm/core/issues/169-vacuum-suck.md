---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: hands
priority: now
created: 2026-11-26
done:
blocked_by: ["[[168-sock-vacuum-nozzle-hose]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 5", "suggested model: opus"]
terms: [Sock vacuum, Tank, Mess, Teammate]
suites: [vacuum, coop_hands, coop_mess, mess, teammates, avatar, zoo]
---

# The Sock vacuum's suck

Holding the left button with the nozzle sucks the nearest loose Sock in its cone into the Tank, one at a time, with a
thwip, the motor running, streaks and motes at the mouth; the heap grows in the canister's window and the gauge fills;
a full vacuum just stops. Build `docs/architecture/devices.md` "`Vacuum`" (`suck`), "Saves, joins and co-op"
(prediction), draft 150-G:

- `suck {sock, from}` with its refusals ("not_held", "gone", "full", "far"; "tilted" reads `pour`, "filtered" asks a
  sibling `VacuumFilter` when present: hooks for core/170 and core/171 so neither edits the suck) and its rate (the suck
  interval, `accepts()`); the Tank's Socks as HELD Mess records (`Mess.held_patch`, never copies; anything walking HELD
  records to find their Hands skips ids a `Vacuum` holds);
- the fly to the nozzle (looks, `fly_time` 0.2 s); the heap's places (`Marker3D`s in the Looks) and its `settle` clip;
  the gauge's `fill` clip seeked to the Tank's share;
- `pose_suction` on the avatar (`avatar.gd`, `avatar.tscn`): on while the left button is held with a nozzle and the Tank
  not full, so a Teammate sees the streaks and hears the motor;
- the Guest's ghost suck (`guest_ghosts.gd`, coop/09's pattern);
- the streaks and motes as `GPUParticles3D` in the nozzle's Looks; the motor `vacuum_motor` with `motor_on` /
  `motor_off` (0.12 s fades, one pitch, Q2698); `vacuum_thwip`; the hint "Sock vacuum   n/24", "Vacuum: full".

Behaviour lines (`docs/migration/m4-lists/09-vacuums-and-detector.md`, V1-V53 in its order as `devices.md` numbers them): V5, V6, V7, V8 ("tilted" with core/170, "filtered" with core/171), V19, V28, V29, V30 (the thwip).

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
The particles' numbers are the `GPUParticles3D` nodes' own fields in the Looks (18 streaks of 0.28 s, 14 motes of
0.7 s); the settle, fill and motor fades are clips (Q2697); the reach, cone and interval are `VacuumTuning`'s.

## Acceptance
- Real path: in the vacuums station the player holding the nozzle aims at loose Socks and holds the left button; the
  nearest in the 2 m, 22-degree cone flies in one every 0.12 s, the heap grows in the window and the hint reads "Sock
  vacuum   n/24".
- A Pair, a held Sock and a shelved Sock are never taken; at 24 it stops ("Vacuum: full"), the motor running on with
  no other sound.
- Co-op: a Guest's suck flies at once; refused (taken by another first), the ghost lands back; the Teammate sees the
  streaks and hears the motor.
- Every Design keeps its two records with Socks in the Tank.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- A full vacuum just stops; the motor's one pitch with its 0.12 s fade (Q2698, 2026-11-26).

## Open follow-ups
