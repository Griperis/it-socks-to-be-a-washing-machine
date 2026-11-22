# Can Godot's spawner and synchronizer carry a thrown Sock from the Host to a Guest (Option A), or do we keep a custom stream (Option C)?

Asked for: ticket coop/01 (M0.6 batch 0, Q2436), 2026-11-22. Engine 4.7.2 (Jolt Physics, project settings as in `main`).
The options are in `docs/migration/coop-structure-for-the-port.md` section 4.

## Answer

- **Option A works, with three conditions.** Jolt bodies spawned by `FlightSpawner` and carried by one
  `MultiplayerSynchronizer` per body (one stamped property `row = [pos, rot, vel, clock]`, played 0.1 s
  behind) arrive, move and come to rest where the Host's did. With the conditions met, a Guest copy never
  jumps (its largest step a frame equals the Host body's), trails the Host by exactly 0.1 s plus the
  one-way delay, and ends 0.4 mm from the pose the Host's answer gives.
- **Condition 1: ENet's packet throttle must be held at full** (`ENetPacketPeer.throttle_configure(5000, 32, 0)`
  on each peer, both ends). Left as it is, at 60 frames a second it sinks to 0 within a second of joining
  (probably because acks are read once a frame, so the measured round trip jitters; not proven) and ENet then drops 31 of every 32
  unreliable packets. Rows then come about twice a second; a copy holds its first pose and jumps 1.7 m
  when the next row comes. This hits every unreliable stream, Option C's and the avatars' too, not only A.
  Headless tests at free frame rate never show it: the test paces frames to 60 a second of wall time.
- **Condition 2: the body's pose is set before `add_child`.** The spawn packet (with the first row) is made
  when the body is ready, inside `add_child`; `MessMoving._launch` sets the pose after it, so the Guest's
  copy started at the world's origin and jumped 11 to 25 m. The test sets the pose from the record in
  its hook; in the game it is moving one line in `_launch`.
- **Condition 3 (both options): the Mess's answers must carry only the changed records.** Today every Mess
  patch holds the whole `states` and `poses` arrays: about 100 KB per answer in the whole zoo
  (2,038 Socks). One Throw and its rest send 200 KB reliable; 16 Throws 1.6 MB. That backs up the
  reliable channel: spawns and despawns wait behind answers. Unreliable rows for a body whose spawn has not
  arrived yet are dropped by Godot, so a copy can hold its first row for many frames (0.8 m jump measured),
  and once one came after its Host body had already rested (it showed only its launch pose, 2.9 m off).
  Option C would suffer the same: its Guest bodies come from the same answers.
- **The order of spawn and answer is settled: the spawn always comes first.** The Host starts a thrown
  body inside `parts.apply` (in `Mess._show`), so the spawn is queued before `Session` sends the answer,
  on the same reliable, ordered channel. 0 of 34 spawns (and 0 of 34 in the two stress runs) came after the
  answer naming them. Not so for a body started later by the budget's wait queue (a woken or poured Sock):
  then the answer comes first and the Sock is shown nowhere on the Guest until its spawn arrives (not
  measured here; Throws are never queued).
- **Recommendation: A** (A-with-stamp, one synchronizer per body), with the three conditions. Conditions 1
  and 3 are needed by C too, so they do not favour C; A then needs fewer lines and uses the spawner the
  zoo already has, which also gives late joiners the bodies in the air.

## The numbers

Setup: `tests/coop_flight_test.gd`. Two zoos in one process, each with its own MultiplayerAPI and its own
3D world (a SubViewport with `own_world_3d`), real ENet over 127.0.0.1, `tests/support/lag_peer.gd` on both
ends for the delay (held in real time) and to count bytes. Frames paced to 60 a second of wall time. One
Throw through the Hands' Command (`Hands.throw`, charge 0.7), then 16 Throws in one tick as the Host's
answers (`Mess.thrown_patch`, the benchmark's burst, 5 m/s from a 4 x 4 grid 1.5 to 2.2 m up). The small zoo
keeps only the stations whose Socks are placed by hand (28 Socks), so the answers are small; the whole zoo
has 2,038.

| Run | Largest step a frame: Guest copy / Host body | Lag behind the Host: median / 95th / largest | Snap at rest | Sock-frames shown twice | Spawn after its answer |
|---|---|---|---|---|---|
| 0 ms, one | 0.111 / 0.111 m | 0.100 / 0.100 / 0.100 s | 0.0000 m | 0 | 0 of 1 |
| 0 ms, sixteen | 0.105 / 0.105 m | 0.100 / 0.100 / 0.100 s | 0.0004 m | 0 | 0 of 16 |
| 50 ms, one | 0.111 / 0.111 m | 0.150 / 0.150 / 0.150 s | 0.0000 m | 0 | 0 of 1 |
| 50 ms, sixteen | 0.105 / 0.105 m | 0.150 / 0.150 / 0.150 s | 0.0004 m | 0 | 0 of 16 |
| 50 ms, sixteen, throttle left on | **1.686** / 0.105 m | 0.167 / 0.367 / 0.383 s | 0.0098 m | 35 | 0 of 16 |
| 50 ms, sixteen, whole zoo | **0.823** / 0.105 m | 0.150 / 0.150 / 0.333 s | 0.0004 m | 30 | 0 of 16 |
| 0 ms, sixteen, whole zoo, throttle on, pose after add_child (first try) | 25.6 / 0.105 m | 0.100 / - / 0.800 s | 2.88 m | - | 0 of 16 |

- Lag is measured, not assumed: for each Guest frame, the frames since the Host's body was nearest the
  copy's place (while it moves). 0.100 s at 0 ms is the playback delay alone; 0.150 s at 50 ms adds the
  one-way delay, which the stamp's clock offset finds by itself.
- Shown twice: a frame where a Sock had a flying copy on the Guest and its record there still said lying.
  It happens only when spawns and answers are far apart (throttle, backlog).
- Bytes, Host to one Guest, payload before ENet and UDP headers: **about 4.8 KB/s per flying body**
  (4,826 to 4,834 B/s with 16 flying; 5.6 KB/s with one, where the sync packet's own header is not shared).
  That is about 80 B per row at 60 rows a second: Godot encodes the row as an Array of Variants (Vector3,
  Quaternion, Vector3, float). The idle baseline (avatars) was 560 to 590 B/s and is taken off. Sixteen
  bodies: 77 KB/s, one sync packet a frame (Godot packs every synchronizer into packets up to 1,350 B).
- Reliable from the Host: 3.3 KB for one Throw and its rest in the small zoo, 37 KB for sixteen; in the
  whole zoo 200 KB and 1.6 MB.
- Each everyday case takes about 6 s; three runs in a row and the `--touched` run passed with the same numbers.

## What carries over to the game (Option A)

What the test adds that the game would hold:

| Piece | Where | Lines (estimate) |
|---|---|---|
| The row: Host reads it live, Guest keeps rows and plays them 0.1 s behind, extrapolates at most 0.1 s | `tests/support/flight_row.gd` -> a script on `flight.tscn` and `ball_flight.tscn` (or a `FlightRow` node) | 80 |
| One synchronizer per body: `Row:row`, spawn on, mode Always, interval 0 | `flight.tscn`, `ball_flight.tscn` | 0 (scene edits) |
| Pose before `add_child` | `MessMoving._launch` | 2 |
| A Guest's copy frozen, kinematic | `Mess._on_flight_in` when not the Host | 3 |
| Throttle held at full on each peer | `Session.host()` (on peer join) and `Session.join()` | 6 |
| `PROTOCOL` bump (new synchronized property) | `Session` | 1 |
| **Total** | | **about 90** |

Option C instead: an unreliable stream on `Session` or the Mess (Host gathers a row per flying body each
tick: about 50 lines), Guest-side bodies created and freed from the Mess's records (no spawner: about 40),
the same playback (80), the same throttle and late-join handling (about 20): **about 190 lines**, and the
zoo's `FlightSpawner` goes.

Both need, besides: sparse Mess patches (condition 3; size not estimated here, it is the Mess's own
change), and the thrower's ghost and its 0.2 s blend (Q2221), which this spike did not build.

## Smaller findings

- Spawn state works: a synchronizer added as the body's child inside `Flights.child_entered_tree` (Host and
  Guest) is in the spawn packet, and on the Guest it gets the first row before the body is ready.
- A Jolt body under a synchronizer needs nothing special on the Host. On the Guest it must be frozen
  (`FREEZE_MODE_KINEMATIC`) or it simulates on its own; frozen, setting `global_transform` each tick is enough
  and the Mess draws it as any flight (`get_global_transform_interpolated`).
- No engine error on either machine in any run, including despawns while rows were in flight.
- A body that rests and is woken again gets the same name (`Flight<id>`); no clash was seen (the old body is
  freed before the new one is added), but a rest and a wake in one tick would make Godot rename the new body
  (`Flight<id+1>`), and a Guest reads the Sock id from the name. Worth a guard in A (not reproduced).
- Not measured: loss (the LagPeer can drop packets; rows are stamped, so a lost row only shortens the
  interpolation), jitter, two Guests, a late joiner mid-flight, a real PC pair over a LAN.

## Sources

- `tests/coop_flight_test.gd` (the runs above; `--only=coop_flight --verbose` prints the `SPIKE` lines; the
  throttled and whole-zoo runs are `stress` cases: `--only=coop_flight:flight_throttled_50ms`,
  `--only=coop_flight:flight_full_50ms`).
- ENet's throttle: `enet_protocol_check_outgoing_commands` drops an unreliable packet when the peer's
  throttle counter passes its packet throttle; `enet_peer_throttle` lowers it on a round trip above the
  last plus twice the variance. Godot exposes it as `ENetPacketPeer.throttle_configure()` and
  `get_statistic(PEER_PACKET_THROTTLE)`, which read 0 here before the fix.
