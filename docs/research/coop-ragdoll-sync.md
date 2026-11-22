# Does a Godot physical-bone ragdoll work on Jolt here, and how does its pose best reach a Guest?

Asked for: coop/02 (Q2225, Q2438), 2026-11-22. Engine 4.7.2.stable.official.ed1daf0bf, Jolt Physics
(`physics/3d/physics_engine`), physics interpolation on, 60 physics ticks a second.

## Answer

- **Yes, PhysicalBone3D works on Jolt in 4.7.2 for the 4-bone avatar.** A Skeleton3D with Root,
  Spine0, Spine1, Spine2, a PhysicalBoneSimulator3D and one PhysicalBone3D per bone, all authored in a
  scene (no node made in code), knocked by `apply_central_impulse` right after
  `physical_bones_start_simulation()`: it falls the way it was pushed, lies over (77 degrees from
  upright; four 0.3 m capsules do not lie flat), and rests within 2.5 s. Cone joints hold: the worst bend
  was 46.5 degrees against a 45 degree swing (Jolt's soft limit). The deepest a capsule went into the
  floor was 1.7 cm. Three runs gave the same numbers to the millimetre.
- **The sync that worked best: (b), one stamped pose the Guest eases towards at 12 per second**, as the
  old game did. Its largest jump on the Guest is 0.09-0.10 m a frame, close to the Host's own
  0.076 m (the ragdoll's fastest point moving between two 60 Hz frames). It costs about 1.9 kB/s per knocked
  player and trails the Host by about 100 ms at 0 ms and 155 ms at 50 ms one way.
- **(a), a synchronizer on the shown skeleton's bone poses, works with no code on the Guest** (the
  engine writes `bones/<i>/position` and `bones/<i>/rotation` itself, no error) but steps visibly: the
  pose arrives 20 times a second and is shown as it is, so the Guest's largest jump is 0.29 m a frame at
  0 ms and 0.32-0.48 m at 50 ms, 4 to 6 times the Host's. It lags less (15-20 ms, 70-80 ms) and costs
  more (about 2.8 kB/s: two Variants per bone with their headers against 20 packed bytes).
- **Recommendation for the knockdown ticket:** (b). One `PackedByteArray` property (a stamp, then
  4 bones x 20 bytes) on a Host-owned ragdoll node, a MultiplayerSynchronizer at
  `replication_interval` 0.05, the Guest's setter decoding into targets and `_process` easing at 12/s.
  If the 100 ms lag reads badly in play, the next thing to try is interpolating between the two newest
  stamped poses (smooth, about one interval of lag); not tested here.

## Numbers

From `tests/ragdoll_spike_test.gd`, three runs, each with real ENet machines in one process and the frames
paced to real time (150 frames in 2.50 s each). One way delays by `tests/support/lag_peer.gd` on both
machines. The jump is the largest distance any of five points (four bone heads and Spine2's tip at 1.7 m)
moved on the Guest between two frames. The lag is the delay that best fits the Guest's pose to the
Host's history over the first 1.5 s of the fall. Bytes are the Host's ENet total (headers, acks
and pings included) over the 2.5 s.

| Sync | One way | Largest Guest jump (m/frame) | Host's own (m/frame) | Lag (ms) | Worst gap Host-Guest (m) | Host sends (B/s) | Packets/s |
|---|---|---|---|---|---|---|---|
| (a) synchronizer on bone poses | 0 ms | 0.286-0.293 | 0.076 | 15-20 | 0.21-0.22 | 2,770-2,900 | 20.4-21.2 |
| (a) synchronizer on bone poses | 50 ms | 0.323-0.479 | 0.076 | 70-80 | 0.42-0.56 | 2,570-2,700 | 19.2-20.0 |
| (b) stamped, eased at 12/s | 0 ms | 0.091-0.100 | 0.076 | 100 | 0.43-0.47 | 1,963 | 20.8 |
| (b) stamped, eased at 12/s | 50 ms | 0.100-0.103 | 0.076 | 155-160 | 0.65-0.71 | 1,830-1,870 | 19.6-20.0 |

The Guest sends 48 B/s back in every case (ENet acks). The old game's stream was 4 bones x 20 bytes at
20 a second, the same as (b)'s payload.

Both ways end with the Guest's resting pose within 2 cm of the Host's.

## What was built

All in `tests/` (throwaway, nothing in `game/`):
- `tests/support/ragdoll_spike/ragdoll_spike.tscn`: `Floor` (StaticBody3D, layer 1); `Ragdoll`
  (Skeleton3D, the Host's hidden helper) with `Simulator` (PhysicalBoneSimulator3D) and four
  PhysicalBone3D; `Body` (Skeleton3D, the shown copy); `BonesSync` and `StampedSync`
  (MultiplayerSynchronizer, 0.05 s, `REPLICATION_MODE_ALWAYS`). Each instance keeps one of the two.
- `tests/support/ragdoll_spike/ragdoll_spike.gd`: `knock(push)` (collision exceptions between the bones,
  start the simulation, an impulse per bone of `push x 3.0 x height / 1.7`); on each Host physics tick it copies
  each body's transform times its inverse `body_offset` into `Body`'s bone poses and, for (b), encodes
  them. A Guest frees `Ragdoll` (it never simulates) and, for (b), eases `Body` towards the newest stamp.
- Bone set-up, from the old game (`docs/migration/m06-lists/04-knockdown.md` "How the old ragdoll is
  built"): bone heads at 0, 0.45, 0.80, 1.12 m; capsules from half a radius under a joint to half a
  radius over the next (Root from 0.03 m, Spine2 to 1.7 m), radius 0.3 (Root 0.285: its stretch is
  short); body at the capsule's middle (`body_offset` = (0, middle - head, 0)); cone joint at the
  bone's head (`joint_offset` = (0, head - middle, 0), rotated 90 degrees about Z so twist runs along
  the body), swing 45, twist 22.5; Root has none; friction 0.8, linear damp 0.4, angular damp 2.0, mass
  1, never sleeps; layer 8, mask 1 and 8.

## What the avatar model must provide

- **Bone names and chain:** a Skeleton3D with `Root` > `Spine0` > `Spine1` > `Spine2`, Root the only
  root. `PhysicalBone3D.bone_name` and the joint's parent body are found by these names and parents.
- **Rest pose:** upright, each bone's head on the body's axis at about 0, 0.45, 0.80, 1.12 m, Y along
  the body. The stand-in used identity rest rotations. The real avatar's rests are a degree or two off
  upright: `body_offset` is relative to the bone, so a tilted rest tilts the capsule and the joint frame
  with it unless `body_offset` and `joint_offset` are set to undo it. That is an inspector setting in
  the Looks scene, not a Blender change. Not tried with the real glb.
- **Collision shapes: none from the model.** The capsules, joints, layers and damping are
  PhysicalBone3D nodes authored in the Looks scene beside the imported skeleton. The glb needs only the
  skinned mesh and the four bones.
- **No limbs to add:** four bones fold in three places by 45 degrees at most, as the old game did. A
  floppier fall needs more bones, a new Blender step and the designer's word.

## Findings worth knowing

- **The shown skeleton is a copy.** The Host reads each PhysicalBone3D's `global_transform *
  body_offset.affine_inverse()` and writes the result into a second skeleton's bone poses. A
  MultiplayerSynchronizer can then sync those properties directly (Skeleton3D exposes
  `bones/<i>/position` and `bones/<i>/rotation` as properties; the path `Body:bones/0/rotation` works in
  a SceneReplicationConfig). Whether the simulator's own skeleton could be synced instead was not
  tried: PhysicalBoneSimulator3D is a SkeletonModifier3D, and how its result shows in the bone pose
  properties was not checked.
- **Bones of one ragdoll overlap** (each capsule reaches half a radius past its joints), so
  `add_collision_exception_with` between every pair is needed and works on Jolt (behaviour 47).
- **An impulse right after `physical_bones_start_simulation()` takes effect on the same tick** on
  Jolt: no wait for a physics frame was needed.
- **`REPLICATION_MODE_ALWAYS` sends every interval even when nothing moves:** the ragdoll node should
  exist only while a player is down (coop-structure section 3), or the stream should stop when it rests.
- **The test runs at `--fixed-fps 60` but the network runs in real time.** The sync cases pace each
  frame to 16.7 ms of wall time, so the fall and the network share one clock. On a machine too busy to
  keep up, the numbers drift but the checks (Guest shows a fall; ends within 2 cm; lag under 300 ms) still
  hold.
- **Not tested here:** physics interpolation of the shown bones at a render rate above the tick rate
  (`get_global_transform_interpolated`; headless shows no frames between ticks), packet loss, a late
  joiner arriving while a body is down, drag, the MATE capsule and the real avatar glb.
