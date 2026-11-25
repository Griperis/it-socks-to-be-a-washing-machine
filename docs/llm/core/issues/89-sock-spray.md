---
type: ticket
status: done
kind: build
area: core
feature: laundry
priority: now
created: 2026-11-24
done: 2026-11-25
blocked_by: []
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: sonnet"]
terms: [Sock, Design, First wash]
---

# The spray of Socks

The burst of Socks out of the washer's door: build `docs/architecture/run-ends.md` "The spray": `SockSpray` (`sock_spray.tscn`, one
MultiMesh per Collection, real Sock meshes, Designs drawn seeded from the catalogue, the old FS step without physics,
gone when it ends) and `SockSprayTuning` (every old `spit` number), and the Laundry station with its Spray pillar (a
stand-in box with a Porthole marker until core/86's washer).

Behaviour lines (`docs/migration/m4-lists/04-first-wash-and-laundry-day.md`): "The First wash": the spit lines (the door's swing is the washer's, called by core/94).

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

`SockSprayTuning` (count 500, speed 2.6, jitter 35 %, cone 24, up 35, window 1.8 s, spin 8, gravity 9.8, bounce
0.35, seed 7), placeholders; the spray draws from the catalogue, so a new Design shows with no change.

## Acceptance
- Real path: in the Laundry station the player presses E on the Spray pillar; Socks leave the porthole marker and lie still on the floor by the end, then vanish; every Collection's MultiMesh is drawn.
- Two machines draw the same spray from the seed.
- Placeholders: `SockSprayTuning`.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The spray is decoration that vanishes (Q2626, 2026-11-24).

## Open follow-ups

## Built log

### 2026-11-25
Changed: `SockSpray` (`sock_spray.tscn`, MultiMesh per Collection from the catalogue's Designs, seeded, the old FS step without physics, gone when it ends) and `SockSprayTuning` (every old spit number, plus `floor_grip` and `rest_speed`, the two the old code hard-coded); the Laundry station (`laundry.tscn`, placed at 60, 0, 0 in the zoo) with a stand-in washer box, a Porthole marker and the Spray pillar (`SprayPillar`, a Part, E plays the spray on the pressing machine only). The door's swing stays the washer's.
Files: game/laundry/sock_spray.gd, sock_spray.tscn, sock_spray_tuning.gd, sock_spray_tuning.tres; game/zoo/laundry/spray_pillar.gd; game/zoo/stations/laundry.tscn; game/zoo/zoo.tscn; tests/sock_spray_test.gd; docs/migration/batch-a-review.md (two rows).
Verified: see the commit's suite line.
- Merged: 407e7409 (2026-11-25, branch core/89-sock-spray)
