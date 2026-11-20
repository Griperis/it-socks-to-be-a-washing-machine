---
type: ticket
status: done
kind: build
area: core
feature: core
priority: now
created: 2026-11-20
done: 2026-11-20
blocked_by: ["[[09-hand-details]]"]
notes: []
terms: []
---

# The two-tier Mess

Milestone M0.5 (batch 2). The every-Sock station (core/12) put about 2,000 lying Socks in the zoo, each a full Looks
scene of about 20 nodes: the physics tick went from 3 ms to about 40 ms. The port always meant the Mess to be the old
game's two tiers rewritten clean (Q2168, `docs/migration/coop-structure-for-the-port.md` section 5); the designer
settled its shape (Q2301, Q2305-Q2311). Old code: `reference/it-socks/game/world/` (`sock_world.gd`,
`sock_bodies.gd`, `sock_colliders.gd`, `sock_drawing.gd`, `sock_draw_group.gd`, `sock_flights.gd`, `pair_wakes.gd`),
`docs/adr/0008-two-tier-socks.md`; tuning `data/tuning/mess.json`, `release.json`, `upgrades.json` (throw).

## Behaviour list
From the designer's answers; every approved line of core/02, 03, 04, 08 and 10 still holds.

**Two tiers** (Q2305, Q2309, Q2310)
- M01 A lying Sock costs nothing per tick: a static collider (two boxes, leg and foot; a Pair a sphere) made in the
  physics server, and one instance in a MultiMesh; no node per Sock. The crosshair hits it and falling Socks land on it.
- M02 Lying Socks are drawn in MultiMeshes grouped by an 8 m floor grid (placeholder), with Godot's automatic LOD and
  visibility ranges; each instance tinted by its Design as today.
- M03 Only where it matters is a Sock a full Looks scene: the aimed Sock (its outline), held Socks, and the flying Socks
  that get cloth (core/09's `flying_cap`). A Sock goes between the two without a visible pop.
- M04 With the every-Sock station in the zoo, the physics tick stays near the zoo's old cost (before core/12, about
  3 ms headless); measured before and after and reported.

**Moving** (Q2306, Q2308, Q2311)
- M05 A moving Sock is a physics body counted against the moving budget: 512, 32 of it reserved for Throws; extra
  wakes wait in a queue and start nearest the players first; at most a set number start and stop per tick; under
  pressure the slowest Socks farthest from the players rest first (all numbers the old game's, placeholders until a
  stress test).
- M06 A moving Sock comes to rest once it has stopped moving (under the old rest speed and spin) for a short time; there
  is no limit on a flight's total time (Q2308).
- M07 When a Sock or Pair is picked, the lying Socks just above it (found by a physics query at that moment, no stored
  support links, Q2307) wake and fall, up to 40, Socks and Pairs alike.
- M08 When a body at 1.5 m/s or more hits a lying Sock, then that Sock and up to 8 touching it wake.
- M09 When a Door swings or a drawer slides, then the lying Socks in its way wake and are pushed; Socks inside a drawer
  ride out with it.
- M10 Thrown and dropped bodies bounce (restitution 0.35) and slide (friction 0.6); a woken Sock is damped 0.6 linear,
  3.0 angular; a dropped Sock 0.05 / 0.8. The Throw's spin stays the same each time and a thrown Pair keeps its drag
  (Q2311, kept).

**Invariants**
- The records, the Part, the Commands and the snapshot do not change shape; a Guest and a late joiner see the same
  Mess (M0.6 tests it).
- Every Design still has its records; pairing, shelving and the every-Sock station play as before.

## Design
Drafted by the agent (2026-11-20) before building.

**Who owns what.** `Mess` (the Part, `game/mess/mess.gd`) keeps the records, the patches, the Commands and the
flights, as today. Two helpers it owns, plain `RefCounted`s with no node of their own (Q2251-Q2253: one class per
file, no inheritance past one step):
- `MessBodies` (`game/mess/mess_bodies.gd`): every lying Sock's static body made with `PhysicsServer3D`
  (`body_create`, mode static, layer `LAYER_LYING`, the level's own space), its RID to Sock id, and the queries on
  them (touching, the column over a picked Sock, a mover's sweep) through `PhysicsQueries` (the one file that reads
  the space). The shapes are made once per Size and shared: a Sock is two boxes, leg and foot (Q2309), split along
  its long side where the two boxes cover the least floor, at least the old 2.4 cm thick; a Pair is a sphere.
- `MessDrawing` (`game/mess/mess_drawing.gd`): one `MultiMeshInstance3D` per 8 m floor cell and shape mesh under
  `lying` (Q2310; the lead's note: grouped by shape as well as cell, so M1's ankle, crew, tube and chunky models are
  more groups, not a rework; today every Sock is the crew stand-in and a Pair the ball, `MessDrawing.shape_of()`).
  Each instance carries its Design as the old `sock_drawing.gd` / `sock_look.gd` packed it: the colour as the
  instance colour (`use_colors`), the look data as `INSTANCE_CUSTOM` (`use_custom_data`, `MessDrawing.look_data()`:
  r pattern + 16 x patches index, g motif + 1 + (coat + 1) x 256 + layout x 65536, b colour2 (none yet: 0), a
  colour3 as `pack_rgb()`), so the old pattern shader drops in as the material in M1; today's material reads only
  the colour. Scaled by its Size, using the Looks' own mesh (`crew.glb`, `ball_crew_plain.glb`, their imported
  automatic LODs) and a visibility range; one more MultiMesh per shape draws the flying Socks that have no Looks,
  from their bodies each frame (interpolated), packed the same way.
  It lends a lying Sock's full Looks scene (`SockDress.make`, a child of `lying`) while somebody needs it: the aimed
  Sock's outline (the player asks `looks_of`, returns it with `return_looks`) and tests; while lent, its MultiMesh
  instance is hidden, so nothing pops (same mesh, tint, scale and pose).
- `MessMoving` (`game/mess/mess_moving.gd`, split out of `Mess` while building, it passed 900 lines): the Host's
  flights, the budget and wait queue, the rests, hits, picks' column wakes and the Door and drawer sweeps.
- `MessTuning` (`game/mess/mess_tuning.gd` + `.tres`): every new number, the old ones marked as ported.

**The tiers.** LYING: a server body plus one MultiMesh instance, no node (M01, M02). HELD: nothing of the Mess (the
HeldView draws it). FLYING: a `RigidBody3D` (`flight.tscn` / `ball_flight.tscn`, now a body and its shape only,
spawnable as before), drawn by the flying MultiMesh; the `flying_cap` (core/09's) flights nearest the camera get a
Looks child (cloth), given at launch while there is room and to the nearest one without when a place frees (no
stealing, so no pop). `_show` changes only the Socks whose state, pose or mate changed (a native split search over
the packed arrays), so a Command costs a few Socks, not 2,000.

**Moving and the budget** (M05-M10), the Host's: a woken Sock waits in a queue (nearest the players first) and
starts as a `wake` (hit, mover) or `fall` (a pick took what held it) Command, at most `start_cap` a tick, while the
flights are under `moving_budget - throw_reserve`; drops and Throws never wait. Under pressure (Socks waiting, the
general share full) the slowest flights farthest from the players rest first (`stop_cap` a tick, never one faster
than `pressure_speed`). A flight rests when it has stayed under the rest speed and spin for `rest_time` or Jolt
sleeps it; no total time limit (Q2308). A pick notes the picked thing's box; the next tick one column query over
it finds the lying Socks and Pairs resting on it, lowest first, up to `pick_wakes` (Q2307: no stored links). Hits:
a flight's contacts are read from its body state each tick (RIDs: the lying bodies have no node); a hit on a lying
Sock at `wake_speed` or more wakes it and up to `wake_count` touching it. Movers: every `Openable` is in the group
`openables`; while its animation plays, the Host sweeps each AnimatableBody3D's shapes (grown by `sweep_margin`)
over the lying Socks and wakes those in its way or on it at once (at most `sweep_cap` a tick); the AnimatableBody
pushes them and carries those on it by friction (M09). Bodies: drops and Throws bounce 0.35 and slide at 0.6, a
woken Sock slides at the old 0.9 and is damped 0.6 / 3.0, a dropped Sock 0.05 / 0.8 like a Throw (Q2311).

**Unchanged:** the records, the Part's state, the Commands' kinds (a Host-only `wake` and `fall` also take a
`socks` list, so one tick's starts are one Command; Host-only args never travel) and the snapshot. `sock_at` takes
the crosshair's RID (the lying bodies have no node), the one change in `player.gd`. `flight.tscn` lost its Looks:
the spawnable changed, so `Session.PROTOCOL` goes to 7.

## Acceptance
- One test per behaviour line; the real-path case: the player picks a Sock from under another at the handling station
  and the one on top falls; a throw into the every-Sock rows wakes the Socks it hits.
- The physics tick and frame time before and after, with the every-Sock station in the zoo, in the report.

## Answers
- The shape, the budget, support by query, the wake and push rules, the collider, the drawing, the physics numbers:
  Q2305-Q2311 (2026-11-20).

## Open follow-ups
- [later] A hit wakes lying Pairs as well as Socks (M08 says "that Sock and up to 8 touching"; the old Q1742 said hitting
  a resting Pair does nothing). Designer: should a Throw knock a lying Pair loose?
- [later] M07 (Q2308) overrides core/02's approved M13 "the one on top stays": picking the lower Sock now lets the one
  on top fall. `handling:m13_tip` was changed to say so. Designer to confirm the M13 line is retired.
- [later] `HandsTuning.settle_limit`, `wake_reach` and `wake_gap` are no longer read (M06 has no time limit; the
  column query replaced the Pair-only support check). The lead may remove them from `game/hands/hands_tuning.gd`
  (not this ticket's file).
- [later] M0.6: every woken flight is a spawned node (up to 512 over the spawner on a big wake), with no synchronizer
  yet; Doors and drawers sweep on the Host only.
- [later] Godot's `TIME_PHYSICS_PROCESS` monitor is not a tick's cost: it reads about 26 ms both before and after
  (core/12's "39 ms" was this monitor). The numbers below time a tick from its first `_physics_process`.
- [later] Q2303 ("a sliding Sock can be picked") is not built here; picks still need a lying Sock.

## Built log
- Model: Opus (lead): a core rewrite of the Mess's bodies and drawing, physics and performance.
- 2026-11-20 (Opus, agent)
  - Changed: lying Socks are server static bodies (leg and foot boxes, a Pair a sphere) and MultiMesh instances by
    8 m cell and shape, packed with the Design's colour and the old look data; the aimed Sock is lent its Looks;
    flights carry a Looks only for the cloth's `flying_cap`; the moving budget, wait queue, start and stop caps,
    pressure rests, the still-time rest (no time limit), column wakes on a pick, hit wakes from contacts, Door and
    drawer sweeps (Openables are in the group `openables`), the M10 materials and drags. `Session.PROTOCOL` 6 to 7
    (`flight.tscn` lost its Looks). `player.gd` reads the crosshair's RID and gives the outlined Looks back.
  - Measured (zoo with the every-Sock station, headless, 300 frames after 120, three runs each): physics tick (first
    `_physics_process` to the next frame) 1.3-1.9 ms before, 0.69-0.74 ms after; its worst 3.5-4.2 ms before,
    1.0-1.7 ms after; process frame 15.6-18.5 ms before, 0.9 ms after; nodes 48,060 before, 3,407 after.
  - Files: `game/mess/` (mess.gd, mess_bodies.gd, mess_drawing.gd, mess_moving.gd, mess_tuning.gd, .tres),
    `game/sock/flight.tscn`, `ball_flight.tscn` (lying_sock.tscn and lying_ball.tscn removed),
    `game/parts/openable.gd`, `game/parts/session.gd`, `game/player/player.gd`, `game/hands/physics_queries.gd`,
    `tests/mess_test.gd` (new), handling, throw, hand_details and zoo tests, `docs/architecture/mess.md`.
  - Verified: `kit/tools/run.sh --touched`: PASS 5121 checks, 166 cases; grep_rules PASS
- Merged: 746852f1 (2026-11-20, branch core/13-two-tier-mess)
