# The Mess

Every loose Sock of a level as one Part (`game/mess/`, core/13). Read this before you change how
Socks lie, are drawn, move or wake.

## Who owns what

| File | Owns |
|---|---|
| `mess.gd` (`Mess`, the Part) | The records (designs, states, poses, throws, mates), the patches other Parts' answers use, the Host-only `rest`, `wake`, `fall`, `_show` (only the changed records, a split search over the packed arrays), lending a lying Sock its Looks, the flights' Looks and drawing |
| `mess_bodies.gd` (`MessBodies`) | Each lying Sock's static body in the physics server (no node), its RID to Sock id, and the queries over them through `PhysicsQueries` |
| `mess_drawing.gd` (`MessDrawing`) | The MultiMeshes: one per 8 m floor cell and shape for lying Socks, one per shape for flights without a Looks; a CPU copy of each buffer (never read back), flushed once a frame |
| `mess_moving.gd` (`MessMoving`) | The Host's flights (`flight.tscn`, `ball_flight.tscn`): the budget, the wait queue, starts and rests, hits, picks' column wakes, Door and drawer sweeps |
| `mess_tuning.gd` + `.tres` (`MessTuning`) | The numbers of the above |

## The tiers

- LYING: a server body on `Mess.LAYER_LYING` (two boxes, leg and foot; a Pair a sphere) and one
  MultiMesh instance. The crosshair reads `RayCast3D.get_collider_rid()` and asks `Mess.sock_at(rid)`.
- A lying Sock someone needs as a scene (the aimed one) asks `looks_of(sock)`: its Looks is lent, the
  instance hides; `return_looks(sock)` gives it back.
- HELD: nothing of the Mess (the HeldView draws it).
- FLYING: a RigidBody3D under `flights` (the spawner's path), drawn by the flying MultiMesh, or with a
  `Looks` child (cloth) for the `flying_cap` nearest the camera.

## Flows

- A pick: the Hands' answer writes HELD; `_show` notes the picked box; next tick `MessMoving` queries
  the column over it and queues what lay on it; they start as `fall` within the budget.
- A hit: a flight at `wake_speed` or more touching a lying body (read from its body state's contacts)
  queues that Sock and up to `wake_count` touching it; they start as `wake`.
- A Door or drawer: every `Openable` is in the group `openables`; while it animates, the Host sweeps
  its AnimatableBody3D shapes over the lying bodies and wakes those at once.
- A rest: still for `rest_time` (or Jolt asleep) asks `rest`; out of bounds or inside a wall, at the
  return spot.

## Gotchas

- Packed arrays in a Dictionary are values: take one out before writing it in place (`MessDrawing`).
- The instance buffer layout (transform rows, colour, custom) is the old game's; the custom data is
  `MessDrawing.look_data()`, the old pattern shader's input (M1).
- Godot's `TIME_PHYSICS_PROCESS` monitor is not a tick's cost (it stayed about 26 ms both before and
  after this rewrite while 124 ticks ran in 2 s); time a tick from its first `_physics_process`.
