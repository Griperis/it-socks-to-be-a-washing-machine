# Can Godot's own SpringBoneSimulator3D do the old game's sock cloth, or does it need hand-written springs?

Asked for: core/09, 2026-11-20. Engine 4.7.2.stable.official.ed1daf0bf (`kit/tools/engine.sh --version`).

## Answer

- A mix, leaning on the node. `SpringBoneSimulator3D` can do D01 (heavy, no overshoot), D04 (blend flat through `influence`), D05 (ground, through a plane collision) and D07 (switch per Sock, about 2-3 us a Sock a tick). It cannot do D02 and D03 by itself.
- Why not alone: it reacts to the skeleton's velocity, not its acceleration. With the default world centre, a Sock carried at a steady 2 m/s stays bent at full length. The old game bends on gravity minus acceleration (`g - _accel + push`), so a steady walk leaves it hanging.
- The fix tried: set the centre to the skeleton itself (the node then ignores all movement) and feed `external_force` each tick from a small script that measures acceleration. That script is about 20 lines (the old `_measure`), against the old 485-line actor with its hand-written spring and ground probes.
- Keep per Sock in script: the acceleration measure, the ranking of the 4 nearest flying Socks (`active` on or off), the ground plane's pose each tick, and the `flat_speed` ramp that writes `influence`.
- Not equal to the old look without tuning: the node is a Verlet chain on bone tails, not the old per-bone balance-pose lag. `lag_time` 0.06 s and `max_pitch` 1.3 rad have no direct knobs, only `stiffness`, `drag`, `gravity` (see Findings 1 and 2).

## Findings

Chain on the stand-in: `game/sock/crew.glb`, in `game/sock/looks_graybox.tscn` under `Body/sock_crew/crew_rig/Skeleton3D` (a second copy sits under `Outline/`). 5 bones, one chain: `Cuff`(0, root, no parent) > `Leg`(1) > `Heel`(2) > `Foot`(3) > `Toe`(4). The old actor simulates `Leg, Heel, Foot, Toe` (`BONES` in `reference/it-socks/game/world/sock_actor.gd`, line 19). The Skeleton3D has three mesh children (`crew`, `crew_lod1`, `crew_lod2`) and the Looks has an `AnimationPlayer`. Tried on 4.7.2: instanced the Looks headless and printed `get_bone_name` / `get_bone_parent` / `get_bone_rest`.

**Setup that worked, tried on 4.7.2.** `SpringBoneSimulator3D` as a child of that Skeleton3D, `setting_count = 1`, root bone `Leg`, end bone `Toe`, `extend_end_bone = true` (Toe is a leaf, so without it Toe has no tail to simulate), end direction `+Y`, `end_bone_length` 0.05, skeleton `modifier_callback_mode_process = PHYSICS`. `get_joint_count(0)` returned 4 (Leg, Heel, Foot, Toe). Throwaway scripts in the scratchpad, run headless; the node and the model both work on this skeleton.

**1. Heavy, damped bend (D01). Tried on 4.7.2** with a step of gravity on the chain, 60 Hz physics, reading the Toe's tail:
- `drag` 1.0 gave no overshoot at any `stiffness` or `gravity` tried; `drag` 0.4 overshot by 5-10 percent (`stiffness` 2, `gravity` 1: peak 0.164 against final 0.147 m).
- With `drag` 1.0: time to 63 percent was 0.15 s (`stiffness` 0.5, `gravity` 1), 0.08 s (2, 1), 0.05 s (2, 3), 0.03 s (8, 1). So a lag near the old 0.06 s is reachable, e.g. `stiffness` 2, `gravity` 3 (final bend 0.208 m, t63 0.05 s).
- Settled bend is set by the ratio of `gravity` to `stiffness` (final 0.257 m at 0.5/1, 0.034 m at 8/1), not by a lag constant, so bend size and lag time are tuned together, not apart. The old game has them apart (`max_pitch` clamp, `lag_time`).
- Source: `_process_joints` in `scene/3d/spring_bone_simulator_3d.cpp` (4.7.2-stable): `next_tail = current_tail + (current_tail - prev_tail) * (1 - drag) + (stiffness*dt)*forward + gravity*dt*dir`. `drag` 1 throws the velocity away each step, which is why it cannot overshoot. Class reference (`doc/classes/SpringBoneSimulator3D.xml`): "gravity ... is not an acceleration, but a constant velocity of movement".
- Old numbers for comparison: `reference/it-socks/data/tuning/cloth.json` `lag_time` 0.06, `max_pitch` 1.3, `gravity_gain` 34, `stiffness` 160. The old step (`_step` in `sock_actor.gd`) is a first-order lerp towards a balance angle per bone (`lerpf(_pitch[i], to[i].x, follow)`), clamped per bone, so it cannot overshoot by construction.
- Read, not tried: frame rate. `drag` is applied per step, not per second, while `stiffness` and `gravity` are scaled by `delta`. Open issue godotengine/godot#103229 "SpringBoneSimulator3D Behaviour is tied to Framerate" (open). The kit ticks at 60 Hz, and only that was tried.

**2. Following the node's movement (D02, D03). Tried on 4.7.2**, with a holder Node3D carrying the Looks:
- Default centre (`CENTER_FROM_WORLD_ORIGIN`): the holder moved at 2 m/s for 1 s. The Toe's offset from its settled place rose to 0.262 m (the chain's full reach) and stayed there for the whole second, then fell to zero within 0.3 s of stopping. So it follows velocity, not acceleration: a Sock carried at a steady speed stays bent. D02 as written ("lags a little, then settles again") is not what this gives.
- Turning (holder rotating 4 rad/s for 0.5 s, Looks 0.5 m off the pivot, like a Sock in front of the head): offset rose to 0.105 m, stayed while turning, fell to near zero 0.3 s after stopping. So D03 (dragged back against the turn) comes without code, but it holds for as long as the turn lasts, and the old game deliberately removed turn swing from the acceleration (`motion_source` is the camera origin, `push` adds a separate drag; docs in `sock_actor.gd` lines 50-60).
- Centre = the skeleton (`set_center_from(0, CENTER_FROM_NODE)`, `set_center_node(0, <path to the Skeleton3D>)`): the holder moved at 2 m/s and the Toe's offset changed by 0.000 m at every sample. The node then ignores all movement.
- `external_force` ("equal to the result when the parent Skeleton3D moves at this speed in the opposite direction", class reference) moves the settled pose: with `gravity` 1, `stiffness` 2, `drag` 1, forces of 0.5 along +x, -x, +y, -y moved the Toe by about 0.03-0.05 m each, in the matching direction. So script-fed `-accel` in `external_force` is the route to the old `g - accel`. Only direction and size order were checked; the scale to the old `max_accel` 12 m/s2 is not tuned.
- Source for the centre: `_init_joints` and `_process_modification` in `spring_bone_simulator_3d.cpp` (centre transform per setting, `get_global_transform_interpolated`).
- The held Sock as a child of a real Camera3D was not tried; a plain Node3D holder was used.

**3. Blending back to rest under 0.6 m/s (D04). Tried on 4.7.2**
- `SkeletonModifier3D.influence` blends linearly: with the chain settled at 0.165 m, influence 0.5 gave 0.085 m, 0.25 gave 0.042 m, 0.0 gave 0.000 m; ramping it 1 to 0 over 18 ticks fell about 0.009 m a tick, evenly, to exactly 0. Read from `Skeleton3D.skeleton_updated`, after the blend.
- Pitfall: `get_bone_pose_*` and `get_bone_global_pose` read from outside return the unmodified pose (0.0 offset), because the skeleton restores the poses after it has built the skin. Read modifier results inside `SkeletonModifier3D.modification_processed` (before the influence blend) or `Skeleton3D.skeleton_updated` (after it). Source: `Skeleton3D::_process_modifiers` and the bone backup in `scene/3d/skeleton_3d.cpp` (4.7.2-stable).
- The simulation keeps running at influence 0 (still called: 2 of 2 ticks) and keeps following the movement; with influence set to 1 again after a 5 m move the Toe sat 0.41 m off and took about 8 ticks to come back to 0.23 m. A blend by influence is therefore a look blend, not a saving; to save cost use `active` (below).
- Not tried: the lie-flat pose the Mess draws is the model's rest pose, which is what influence 0 gives (rest pose = flat). Whether `crew.glb`'s rest pose is the Mess's flat pose was not checked.

**4. Ground (D05). Tried on 4.7.2**
- Built-in shapes (`scene/3d/spring_bone_collision_*_3d.cpp`, 4.7.2-stable): `SpringBoneCollisionSphere3D`, `SpringBoneCollisionCapsule3D`, `SpringBoneCollisionPlane3D`, all children of the `SpringBoneSimulator3D` (or listed with `set_collision_path`; `enable_all_child_collisions` is true by default). Optional `bone` attachment, `position_offset`, `rotation_offset`. The class reference warns a scaled collision "will likely not behave as expected".
- Plane: `_collide` pushes a tail up out of the plane by `normal * -(distance - bone_radius)`; it is one dot product a joint. The plane is infinite and takes its pose from the node, so the script moves it to the ground each tick (a slope is a rotated plane).
- Tried: plane 0.03 m below the Toe's rest height, `gravity` 3: without the plane the Toe tail settled at y = -0.197; with it, y = -0.019 (the plane height, radius 0).
- What it does not do: it only moves the joints' tails (the bone ends, `radius` being one number a joint, or per joint with `set_config_individual`), not the skinned mesh. The old game probed up to 8 rings of 12 mesh points per Sock so that "no part dips below" (`_probes_of`, `PROBE_RINGS`, `_ground_room`). With the node the Sock's thickness comes only from `radius`; a flat Sock bent over the ground can still show cloth through the surface where its width is more than `radius`. Not looked at in a render.
- Different in kind: the old game scales the whole bend down (`_room`) so the bend gives way; the node pushes tails out of the plane one at a time, so the Sock slides and may crumple at the contact instead of straightening.
- Issue godotengine/godot#125026 (closed 2026-10-31, "collisions are misplaced when the center is a Node other than the skeleton"): with the centre = the Skeleton3D, as above, the collision tried at the right height; with another centre node it was reported misplaced. Whether the fix is in 4.7.2 was not checked (the report is against 4.7.2).

**5. Switching per Sock and cost (D07). Tried on 4.7.2**
- `active = false` stops the node processing (`SkeletonModifier3D::process_modification` returns at once if not active, in `scene/3d/skeleton_modifier_3d.cpp`), and the Sock draws in its rest pose.
- Cost, headless (no skinning on screen), 60 Hz, `Performance.TIME_PHYSICS_PROCESS` averaged over 240 ticks, one 4-joint chain a Sock: with the node inactive 100 Socks cost 0.185 ms a tick (1.9 us a Sock), 400 cost 1.06 ms (2.7 us); active 0.512 ms (5.1 us a Sock) and 1.81 ms (4.5 us). So the simulation adds about 2-3 us a Sock a tick; 6-8 live Socks cost nothing worth measuring. The GPU skinning cost of a skinned mesh is separate and was not measured.
- Turning it on again after being off while the Sock moved 5 m: the first simulated tick showed the Toe 0.42 m off its rest place (more than the chain's reach, then 0.02 m the tick after), with and without `reset()` called in the same frame. That is a one-tick pop; hiding it (influence 0 for the first tick, or reset one tick later) was not tried. The class reference says to call `reset()` to "prevent the simulation result getting violent".
- Read, not tried: freeing or re-parenting. Issue godotengine/godot#125673 (open, reproduced on 4.7.2): freeing a `SpringBoneSimulator3D` that has processed leaks about 300 bytes. Issue #122049 (open): an error when re-parenting it. Pooling the nodes (toggling `active`) avoids both.

## Not found, or uncertain

- Whether a held Sock under a real Camera3D under physics interpolation behaves the same as the plain holder tried; there is a closed issue #110975 (jitter on a CharacterBody3D with physics interpolation), not read.
- Tick rate: only 60 Hz tried; `drag` below 1 is frame-rate dependent (#103229, open).
- No rendered look: nothing was drawn, so how the 4-joint chain bends the real skinned `crew` mesh (folds, thickness at the plane) is not seen; poses were read as numbers.
- No numeric match to the old `cloth.json` was attempted; the node's knobs differ in kind, so equal feel needs a tuning session with the designer.
- Whether the first-tick pop after re-enabling is a bug or a call-order effect of the headless test.
- Whether `crew.glb`'s bone axes suit `BONE_DIRECTION_PLUS_Y`; the rest transforms shown (`Heel` and `Foot` are tilted about 20 degrees in rest) suggest the chain bends in the sock's plane; not checked against the future M1 models.
- The docs.godotengine.org class page was reachable; the class reference was read from the `4.7.2-stable` tag's `doc/classes/SpringBoneSimulator3D.xml` and `SpringBoneCollision3D.xml` instead.

## Open for the designer

- If the Sock may bend with the node's own motion (a chain dragged by its own speed, which also swings while walking at a steady pace), then D02 needs no script and the node does it alone; the old game's look (bend only on speeding up or slowing down) needs the small script. This decides whether the cloth is "mostly the node" or "node plus a feed".
- If, at the ground, the Sock may slide and crumple at the contact (the node) rather than straighten as the old game does (D05).
