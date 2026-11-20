# Godot's own rules: what the official docs forbid, call unsafe or discourage

Researched 2026-11-10 for maintenance/80 (designer: "compare whether we don't use anything that Godot
forbids, based on Godot's official documentation"). Official sources only: docs.godotengine.org
(stable, which is 4.7 here), class reference pages and the 4.4-4.7 upgrade guides. No request was
blocked (no HTTP 403); `autoloads_versus_internal_nodes.html` returned 404 and the autoload rules
come from `scene_organization.html` instead. Pages that were truncated by the fetcher (Node, RenderingServer,
ProjectSettings, Control, PhysicsServer3D) are marked "partial" under the rule.

Builds on, and does not repeat in full: maintenance/52 and 58, `docs/research/performance.md`,
`multiplayer.md`, `docs/llm/physics/research.md` and the `godot-game-dev` / `multiplayer-game-dev` skills.
Each rule has an id (`T1`, `P3` ...) that maintenance/80 uses.

Legend: **F** = forbidden or unsafe (the docs say it breaks, errors, or is undefined);
**D** = discouraged or a gotcha (works, but the docs warn).

Base URL: `https://docs.godotengine.org/en/stable/` (shortened to `~/` below).

## Threads (`~/tutorials/performance/thread_safe_apis.html`, `~/classes/class_workerthreadpool.html`)

| Id | | Rule | Reason | Source |
|---|---|---|---|---|
| T1 | **F** | Do not call node methods or set node properties of the active scene tree from a thread (`add_child` etc.); use `call_deferred` / `set_deferred`. | The active tree is not thread-safe. Building a chunk off-tree is fine; add it on the main thread. | thread_safe_apis |
| T2 | **F** | Physics simulation is not thread-safe unless "Run on Separate Thread" is on; do not use PhysicsServer from threads otherwise. | Servers need the setting to be thread-safe. | thread_safe_apis |
| T3 | **F** | Do not modify one Resource from several threads, or load the same resource from several threads at once. | Not supported. Safest: one thread loads and edits, the main thread adds to the scene. | thread_safe_apis |
| T4 | **F** | Resizing, adding or removing elements of an Array or Dictionary from several threads needs a mutex (reading and writing existing elements is fine). | Concurrent resize corrupts it. | thread_safe_apis |
| T5 | **F** | `AStar2D/3D/AStarGrid2D`: never two threads on one object. | Corrupts its data. | thread_safe_apis |
| T6 | **F** | Every `WorkerThreadPool` task must be waited for (`wait_for_task_completion` / `wait_for_group_task_completion`). | "Every task must be waited for completion" so resources are cleaned up. | class_workerthreadpool |
| T7 | **D** | Waiting for a task from inside another task can return `ERR_BUSY` (deadlock risk); distributing cheap work across threads can slow it. | Documented return code and note. | class_workerthreadpool |
| T8 | **D** | Instancing rendering nodes (Sprite, MeshInstance3D) off-thread, and GPU-direct work off-thread (textures, image data), is unsafe or stalls. | Rendering is not thread-safe by default; "Separate" render thread has known bugs. | thread_safe_apis |
| T9 | **D** | `Object._get()` overrides must be thread-safe. | Called from any thread. | class_object |

## Physics: queries, bodies, shapes (`~/tutorials/physics/*`, class pages)

| Id | | Rule | Reason | Source |
|---|---|---|---|---|
| P1 | **F** | Access `PhysicsDirectSpaceState` (rays, shape queries, `cast_motion`, `get_rest_info`) only from `_physics_process()`; `_input()` may run while the space is locked. | "the only time accessing space is safe is during the `Node._physics_process()` callback"; otherwise an error from a locked space, and physics may be threaded. | physics/ray-casting |
| P2 | **F** | Never scale collision shapes or collision objects; keep Scale (1,1,1) and resize the shape resource. A non-uniformly scaled `CollisionShape3D` "will likely not behave as expected". | Unexpected collision behaviour. | physics_introduction, class_collisionshape3d |
| P3 | **F** | Do not set `position`, `linear_velocity` or other physics properties of a `RigidBody` directly; apply forces or use `_integrate_forces()`. Do not set `linear_velocity` every frame. Same for a RigidBody that is a child of a constantly moving node. | Unpredictable; physics may run on another thread at another granularity. | physics_introduction, class_rigidbody3d |
| P4 | **F** | Do not set `position` of a `CharacterBody` to move it; use `move_and_slide()` / `move_and_collide()`, from `_physics_process()`. | Collision response is yours to code; teleporting skips it. | physics_introduction, class_characterbody3d |
| P5 | **F** | Do not multiply `CharacterBody3D.velocity` by `delta` before `move_and_slide()` (gravity is an acceleration: do multiply that). | "A common mistake"; `move_and_slide()` applies the step itself. | class_characterbody3d |
| P6 | **D** | Change `CollisionShape.disabled` (and an Area's `monitoring`) with `set_deferred()`. | The docs: "should be changed with `Object.set_deferred()`"; changing it while queries flush errors. | class_collisionshape3d |
| P7 | **D** | `Area3D.get_overlapping_*`, `overlaps_*` and `RigidBody.get_colliding_bodies()` update once per physics step, not on movement; use signals. | Stale lists. | class_area3d, class_rigidbody3d |
| P8 | **D** | `RigidBody` contacts are not recorded unless `contact_monitor` is on and `max_contacts_reported` > 0; `get_contact_count()` is 0 otherwise. | Defaults are off. | physics_introduction, class_rigidbody3d |
| P9 | **D** | Do not leave a body that is always frozen as a `RigidBody`; use `StaticBody3D` / `AnimatableBody3D`. | Cheaper and correct. | class_rigidbody3d |
| P10 | **D** | Trimesh (`ConcavePolygonShape3D`) shapes are hollow; split into convex or primitive shapes where possible. | "may give unexpected results". | class_area3d |
| P11 | **D** | Ray queries: use global coordinates; check for an empty result before reading keys; exclude the parent body; prefer a collision mask to a long `exclude` list; `collide_with_areas` is off by default. | Documented pitfalls. | physics/ray-casting |
| P12 | **D** | `intersect_ray` `face_index` is -1 unless the shape is concave and (Jolt) "Ray Cast Face Index" is on (+25% concave memory). | Jolt default. | class_physicsdirectspacestate3d, using_jolt_physics |
| P13 | **D** | `cast_motion` ignores shapes the query shape already overlaps; `collide_shape` / `get_rest_info` / `intersect_shape` ignore the query's `motion`. | Result semantics. | class_physicsdirectspacestate3d |
| P14 | **D** | Physics is not deterministic; do not rely on identical outcomes. | Documented warning. | physics_introduction |
| P15 | **D** | `move_and_slide()` collision normals are not always the surface normals (`get_floor_normal`, `get_wall_normal`). `get_platform_velocity()` is valid only after `move_and_slide()`. | Warnings in the class page. | class_characterbody3d |
| P16 | **D** | `Input.is_action_just_pressed` etc. in `_process`/`_physics_process` per frame, and key polling there, is discouraged; use `_input` / `_unhandled_input` for events; `is_physical_key_pressed()` over `is_key_pressed()` for game keys. | Polls every frame. | godot_notifications, class_input |

## Jolt (`~/tutorials/physics/using_jolt_physics.html`, `~/classes/class_physicsserver3d.html`; Jolt is the 4.6+ default and this project's engine)

| Id | | Rule | Reason | Source |
|---|---|---|---|---|
| J1 | **F** | These joint properties are ignored by Jolt, and non-default values print a warning: Pin (bias, damping, impulse_clamp), Hinge (bias, softness, relaxation), Slider (angular_*, limit softness/restitution/damping), **ConeTwist (bias, relaxation, softness)**, Generic6DOF (limit softness/restitution/damping/erp). `PhysicalBone3D` cone joints map to ConeTwist. | Jolt lacks them. | using_jolt_physics, class_physicsserver3d |
| J2 | **F** | `SHAPE_SOFT_BODY` through `PhysicsServer3D.shape_create` always errors; `SHAPE_CUSTOM` errors in Jolt and Godot Physics. | Unsupported. | class_physicsserver3d |
| J3 | **D** | Single-body joints: Jolt treats the body as `node_b` (Godot Physics `node_a`). | Behaviour difference; toggle `Joints > World Node`. | using_jolt_physics |
| J4 | **D** | `FREEZE_MODE_KINEMATIC` bodies report no contacts with static/kinematic bodies unless "Generate All Kinematic Contacts" is on; many large kinematic bodies over complex static geometry waste CPU/memory. | Jolt default. | using_jolt_physics |
| J5 | **D** | `get_contact_impulse()` is estimated; accurate only when the body touches nothing else. | Jolt estimate. | using_jolt_physics |
| J6 | **D** | `Area3D` reports overlaps with static bodies always (4.5) and with `SoftBody3D` (4.7); filter with layers/masks. The `areas_detect_static_bodies` setting is removed. | Behaviour changes. | upgrading_to_godot_4.5, 4.7, using_jolt_physics |
| J7 | **D** | `WorldBoundaryShape3D.plane.d` has the opposite sign in 4.7; its effective size is small in Jolt. `SoftBody3D` is 1 kg total in 4.7. | Upgrade notes. | upgrading_to_godot_4.7, using_jolt_physics |
| J8 | **D** | Jolt settings moved from `physics/jolt_3d/...` to `physics/jolt_physics_3d/...` with renames (`solver/position_iterations` -> `simulation/position_steps` etc.); `queries/use_legacy_ray_casting` removed. | Old keys silently do nothing. | using_jolt_physics |
| J9 | **D** | "Run On Separate Thread" with Jolt is lightly tested; treat as experimental. | Documented. | using_jolt_physics |
| J10 | **D** | Temporary allocations use a fixed stack (Temporary Memory Buffer Size); ghost-collision fixes (active edges) do not help between two different bodies. | Limits. | using_jolt_physics |

## Physics interpolation (`~/tutorials/physics/interpolation/*`; the project enables it)

| Id | | Rule | Reason | Source |
|---|---|---|---|---|
| I1 | **D** | Move interpolated objects and run their logic in `_physics_process()`, including indirect moves (moving a parent). | Moving in `_process` fights the interpolation. | physics_interpolation_quick_start_guide |
| I2 | **D** | After first positioning or teleporting an interpolated node call `reset_physics_interpolation()` (also after `reparent` with large changes). | Avoids a visual streak. | quick_start_guide, class_node |
| I3 | **D** | A parent On with a child Off still moves the child with the parent's interpolated transform; plan on/off for the whole branch. | Only the child's local transform is uninterpolated. | advanced_physics_interpolation |
| I4 | **D** | Cameras: interpolation off on the camera, move it in `_process` from `get_global_transform_interpolated()`, use that call only once or twice. | Performance and correct gameplay. | advanced_physics_interpolation, class_node3d |
| I5 | **D** | MultiMesh: per-instance `reset_instance_physics_interpolation()` and `set_buffer_interpolated()` when the instance order changes. `RenderingServer.instance_reset_physics_interpolation` / `instance_set_interpolated` were removed in 4.5. | API. | class_multimesh, upgrading_to_godot_4.5 |
| I6 | **D** | Interpolation shows objects 1-2 ticks in the past (input lag in fast games); the tick rate should be fixed at design time. | Documented trade-off. | physics_interpolation_introduction |

## Scene tree and node lifecycle (`~/classes/class_node.html` (partial), `class_object.html`, `class_scenetree.html`, `~/tutorials/best_practices/godot_notifications.html`)

| Id | | Rule | Reason | Source |
|---|---|---|---|---|
| N1 | **F** | `add_child` fails if the node already has a parent; `remove_child` first. | Documented. | class_node |
| N2 | **F** | Never delete `SceneTree.root`; do not set `current_scene` directly. | "Unstable behaviour and a crash". | class_scenetree |
| N3 | **F** | Use `is_instance_valid()` for freed objects; never compare against `null`. Using a freed reference is a runtime error. | Documented. | class_object |
| N4 | **F** | Do not override non-virtual engine methods (`queue_free`, `get_class`); `NATIVE_METHOD_OVERRIDE` is an error. | Unsupported. | gdscript_basics |
| N5 | **F** | Multiple inheritance is not allowed; a class without `extends` is `RefCounted`; abstract classes cannot be attached to nodes. | Language. | gdscript_basics |
| N6 | **D** | Prefer `queue_free()` to `free()` for a node in the tree: the node is deleted at once by `free()` and references/callbacks into it break; `queue_free` waits for the end of the frame. | The `queue_free` note. | class_node, class_object |
| N7 | **D** | `_ready` runs once per node and bottom-up (children first); `_enter_tree` runs top-down; re-adding does not call `_ready` again (`request_ready()`). `_init` runs before both. | Order. | godot_notifications, class_node |
| N8 | **D** | `_process` / `_physics_process` / `_input` are called only for nodes in the tree; overriding `_process` or `_physics_process` auto-enables processing. | Documented. | class_node |
| N9 | **D** | `call_deferred` runs at idle time and returns null; never defer a method from itself (infinite recursion); for a one-frame delay use `SceneTree.process_frame` / `physics_frame`. | Documented. | class_object |
| N10 | **D** | `get_node` with an absolute path works only inside the tree; hard-coded paths break scene reuse: inject dependencies from a parent instead. | Scene organization. | class_node, scene_organization |
| N11 | **D** | `change_scene_*`: the old scene leaves at once and `current_scene` is null until the end of the frame; `change_scene_to_node` frees the node on the next change. | Documented. | class_scenetree |
| N12 | **D** | `SceneTree.call_group` acts on all members at once and can stutter; `find_child` "can be very slow". | Performance. | class_scenetree, class_node |
| N13 | **D** | `NOTIFICATION_PREDELETE` and `EXIT_TREE` run in reversed order; `_notification` of the base is called automatically (no `super`). | Documented. | class_object, class_node |
| N14 | **D** | Node names: `. : @ / " %` are replaced by `_`; use `force_readable_name` for RPC nodes. | Documented. | class_node, high_level_multiplayer |
| N15 | **D** | `replace_by` removes but does not free the node (leak); `print_orphan_nodes` is debug-only. | Documented. | class_node |
| N16 | **D** | Autoloads: only for a system that tracks its own data, is globally needed and can exist alone; systems that modify other systems' data should be scripts/scenes. Autoload nodes survive scene changes. | Scene organization. | scene_organization |
| N17 | **D** | Signals respond to behaviour, calls start it; keep scenes dependency-free, a parent injects. A signal cannot connect to the same callable twice (error) unless `CONNECT_REFERENCE_COUNTED`; `disconnect` of a missing connection errors; `CONNECT_PERSIST` cannot be used with a lambda. | Documented. | class_object, scene_organization |
| N18 | **D** | `Node.owner` must be set after `add_child` for nodes meant to be saved/visible in the editor tree. | Documented. | class_node |
| N19 | **D** | `set_multiplayer_authority` is not replicated automatically and does not propagate to children added later. | Documented. | class_node |

## GDScript language, typing and style (`~/tutorials/scripting/gdscript/*`)

| Id | | Rule | Reason | Source |
|---|---|---|---|---|
| G1 | **F** | `@onready` together with `@export` on one variable is an error (`ONREADY_WITH_EXPORT`); `@export` / `@onready` cannot be applied to `static var`; local variables cannot be static; a `const` must be known at compile time. | Language. | gdscript_basics |
| G2 | **F** | `Array[Node2D]` cannot be assigned to `Array[Node]` (use `assign()`); no nested typed arrays/dictionaries; no per-element types in literals. | Language. | gdscript_basics, static_typing |
| G3 | **F** | Bracket access to a missing property on an Object is a script error; use `get()` / `set()`. | Language. | gdscript_basics |
| G4 | **F** | Calling a coroutine without `await` when you need its result is an error; `await` on a non-signal returns at once. | Language. | gdscript_basics |
| G5 | **D** | Integer `/` truncates; `%` is for ints (`fmod`/`posmod` otherwise); `==` may coerce (use `is_equal_approx`); assigning to a `for` variable does not change the array. | Gotchas. | gdscript_basics |
| G6 | **D** | Arrays, Dictionaries and packed arrays are shared by reference: `duplicate()` for a copy. A lambda captures locals by value once; assigning an outer local inside a lambda only shadows it. | Gotchas. | gdscript_basics |
| G7 | **D** | `as` yields `null` silently on a mismatch; prefer `is` + a typed variable where a silent null would hide a bug. Inference (`:=`) fails for Variant. | Safe vs unsafe lines. | static_typing |
| G8 | **D** | The typed-GDScript warnings (`UNTYPED_DECLARATION`, `INFERRED_DECLARATION`, `UNSAFE_*`) are off by default; enable them under Project Settings > Debug > GDScript; `@warning_ignore` to silence one. | Typing is only as good as the warnings. | static_typing, warning_system |
| G9 | **D** | Use typed math (`absf`, `clampi`, `lerpf`, ...) so lines stay "safe" and fast. | Untyped globals return Variant. | static_typing |
| G10 | **D** | Static variables keep a script in memory (`@static_unload` has a known bug); a `@tool` script reading a static of another script needs that one to be `@tool` too. | Documented. | gdscript_basics |
| G11 | **D** | `@tool` scripts run in the editor: freeing nodes there, especially their own owner, can crash the editor. | Documented. | gdscript_basics |
| G12 | **D** | Overridden methods with a typed return must `return` explicitly (4.7); setting a packed-array element no longer calls the property setter (4.7). | Upgrade notes. | upgrading_to_godot_4.7 |
| G13 | **D** | Style guide: tabs, 100 columns, `and/or/not`, double quotes, snake_case files/functions, PascalCase classes, CONSTANT_CASE, signals in past tense, code order (signals, enums, constants, statics, exports, vars, onready, virtuals, methods, inner classes), explicit types for `get_node`. | Style guide. | gdscript_styleguide |
| G14 | **D** | Setter order: default value without setter, `_init` assignment with setter, inspector value with setter again. | Setters may run more than once. | godot_notifications |
| G15 | **D** | `RefCounted` objects free themselves; cycles never free: use `WeakRef`. Data-only classes should extend `RefCounted`. | Memory. | gdscript_basics, class_object |

## Resources (`~/classes/class_resource.html`)

| Id | | Rule | Reason | Source |
|---|---|---|---|---|
| R1 | **D** | Resources loaded from the same path are one shared instance: changing it changes every user. Use `duplicate()` (shallow: nested resources/arrays/dicts still shared), `duplicate(true)` (4.5+: copies only internal subresources; `duplicate_deep(DEEP_DUPLICATE_ALL)` for the old behaviour) or `resource_local_to_scene`. | Cache sharing. | class_resource, upgrading_to_godot_4.5 |
| R2 | **D** | Custom resources whose `_init()` has required parameters cannot be duplicated or instantiated by the engine. | Documented. | class_resource, class_object |
| R3 | **D** | `resource_path` must not be set by hand when already loaded: `take_over_path()`; changing `resource_local_to_scene` at runtime does not affect copies already made. | Documented. | class_resource |
| R4 | **D** | Custom resource properties do not emit `changed`; add setters that call `emit_changed()`. | Documented. | class_resource |
| R5 | **D** | The loader cache keys on path; the entry is dropped when every reference goes. | Documented. | class_resource |
| R6 | **D** | `MultiMesh`: set `transform_format`, `use_colors`, `use_custom_data` before `instance_count`; changing `instance_count` clears the buffers; returned buffer arrays are copies; no per-instance culling (split into chunks or set `custom_aabb`); `visible_instance_count` does not resize; the whole MultiMesh is one object for lights; blend shapes ignored. | Documented. | class_multimesh, using_multimesh |

## Files, paths and export (`~/tutorials/io/data_paths.html`, `~/classes/class_fileaccess.html`, `class_diraccess.html`, `class_json.html`, `class_projectsettings.html` (partial))

| Id | | Rule | Reason | Source |
|---|---|---|---|---|
| E1 | **F** | Do not write to `res://` at runtime: it is read-only in an exported game. Saves and settings go to `user://`. | `user://` is guaranteed writable. | data_paths |
| E2 | **F** | Do not read project resources with `FileAccess` / `DirAccess` in an export unless the file is kept as is (import mode "Keep File" or an export filter such as `*.json`); use `ResourceLoader` and `ResourceLoader.exists()`. | Imported files are converted and sources are not in the PCK. | class_fileaccess, class_diraccess |
| E3 | **D** | `DirAccess` listing of `res://` differs in an export (remapped names, only files in the PCK); order is not deterministic: use `get_files()`; `ResourceLoader.list_directory()` for editor-like results. | Documented. | class_diraccess |
| E4 | **D** | `FileAccess.open` returns null on failure (check `get_open_error()`); `WRITE` truncates; `store_*` return bool and the position is undefined after an error; flush for crash safety; `get_var(allow_objects)` and `bytes_to_var_with_objects` can run code: never on untrusted data. | Documented. | class_fileaccess |
| E5 | **D** | `JSON.parse_string` returns null on failure; all numbers come back as float; non-finite floats break (`NAN` -> null); native types need `from_native()` / `to_native()`. | Documented. | class_json |
| E6 | **D** | `OS.get_executable_path()` is the only way to write beside the executable and needs a writable folder. | Documented. | data_paths |
| E7 | **D** | `--headless` disables rendering; most RenderingServer calls return dummy values. | Documented. | class_renderingserver (partial) |
| E8 | **D** | `Input.use_accumulated_input` is on by default; `parse_input_event()` does not move the OS cursor; `action_press()` does not call `_input`. | Documented. | class_input |

## Tween, Timer, Control and Node3D (`~/classes/class_tween.html`, `class_timer.html`, `class_scenetree.html`)

| Id | | Rule | Reason | Source |
|---|---|---|---|---|
| W1 | **F** | `Tween.new()` gives an invalid tween; create with `create_tween()`. A tween is not reusable: create a new one each time; `kill()` the old one first. | Reuse is undefined behaviour. | class_tween |
| W2 | **D** | `SceneTree.create_tween()` is not bound to a node (runs until nothing is left to animate); `Node.create_tween()` binds and dies with the node. Always `bind_node` an infinite loop. | Leaks and callbacks on freed nodes. | class_tween |
| W3 | **D** | Infinite `set_loops()` needs a duration or delay on every step (a zero-duration loop stops after a few iterations). | Warning. | class_tween |
| W4 | **D** | `Timer.start()` fails outside the tree; below about 0.05 s a Timer is unreliable; `stop()` does not emit `timeout`; timers follow `Engine.time_scale` unless `ignore_time_scale`. | Documented. | class_timer |
| W5 | **D** | `SceneTree.create_timer(time, process_always, ...)`: pauses with the tree unless `process_always`; updates after all nodes. | Documented. | class_scenetree |
| W6 | **D** | `Control` theme items are not Object properties (`add_theme_*_override`); `NOTIFICATION_THEME_CHANGED` arrives with `ENTER_TREE`, children may not be ready. | Documented. | class_control (partial) |
| W7 | **D** | `Node3D.look_at` fails when not in the tree, or when the direction is parallel to `up`; scale components must all be non-zero and share a sign (a scale tweened to exactly 0 loses the basis); `global_transform` outside the tree is identity. | Documented. | class_node3d |

## High-level multiplayer (`~/tutorials/networking/high_level_multiplayer.html`, `class_multiplayerapi.html`, `class_scenemultiplayer.html`, `class_multiplayersynchronizer.html`, `class_enetmultiplayerpeer.html`)

| Id | | Rule | Reason | Source |
|---|---|---|---|---|
| M1 | **F** | RPCs cannot carry Objects or Callables; RPC methods must be on Node-derived classes; sender and receiver nodes need the same NodePath. | Runtime errors. | high_level_multiplayer |
| M2 | **F** | Do not enable `allow_object_decoding` for untrusted peers: "Deserialized objects can contain code which gets executed." | Remote code execution. | class_scenemultiplayer |
| M3 | **F** | Use RPCs on a client only after `connected_to_server`. | Documented. | class_node (rpc) |
| M4 | **F** | Every `@rpc` function must exist on both ends with the same signature (annotation, name, return type, NodePath). | Mismatch gives misleading errors or undefined behaviour. | high_level_multiplayer |
| M5 | **D** | Treat all client input as untrusted: validate every `any_peer` RPC argument, keep the server the source of truth, do not trust client positions/timers/cooldowns/resources, rate-limit frequent actions, send intent not final state; use `get_remote_sender_id()`. | Cheats and exploits. | high_level_multiplayer |
| M6 | **D** | `get_remote_sender_id()` is 0 outside an RPC and "can be lost if execution is delayed, such as with `await`". | Documented. | class_multiplayerapi |
| M7 | **D** | `any_peer` for client-to-server calls only; `authority` by default (server); `call_local` when the server is also a player; `reliable` has a "major performance cost"; `unreliable_ordered` drops late packets; channel 0 is three channels; `transfer_channel` comes last. | Documented. | high_level_multiplayer |
| M8 | **D** | Shut a connection down by assigning an `OfflineMultiplayerPeer`; `create_server`/`create_client` return `ERR_ALREADY_IN_USE` if the instance is open (`close()` first). | Documented. | high_level_multiplayer, class_enetmultiplayerpeer |
| M9 | **D** | `MultiplayerSynchronizer`: no Object properties and no per-peer values (instance ids, RIDs); only `replication_config` properties; data flows authority to others only. `max_sync_packet_size` 1350, `max_delta_packet_size` 65535 by default. | Documented. | class_multiplayersynchronizer, class_scenemultiplayer |
| M10 | **D** | Changing `server_relay` with peers connected has unexpected effects. The protocol is not for non-Godot servers and may change. | Documented. | class_scenemultiplayer |
| M11 | **D** | ENet is UDP only; forward the UDP port; `max_clients` up to 4095; ports below 1024 may need privileges; add an `auth_callback` before public hosting; Android needs the `INTERNET` permission. | Documented. | high_level_multiplayer, class_enetmultiplayerpeer |
| M12 | **D** | Nodes added to a `MultiplayerAPI` root path: configure with `set_multiplayer` before the children are ready, not nested. | Documented. | class_scenetree |
| M13 | **D** | `MultiplayerAPI.rpc` (the generic call) is slower than `Node.rpc` / `callable.rpc`. | Documented. | class_multiplayerapi |

## Rendering and project (`~/tutorials/rendering/renderers.html`, `~/tutorials/migrating/upgrading_to_godot_4.4 ... 4.7.html`, `~/tutorials/performance/using_multimesh.html`)

| Id | | Rule | Reason | Source |
|---|---|---|---|---|
| X1 | **D** | Forward+ is desktop-only and not supported on the web; Compatibility is the only web renderer and lacks volumetric fog, SSR, SSIL, SDFGI, VoxelGI, decals, compute shaders, many post effects, and caps 8 omni/spot + 8 directional lights per mesh. This project is Forward+ (`config/features`). | Renderer limits. | renderers |
| X2 | **D** | 4.6: new projects default to Jolt and D3D12 on Windows; glow/volumetric fog defaults changed; `.tscn` drops `load_steps` and saves unique node ids (large diffs once). | Upgrade notes. | upgrading_to_godot_4.6 |
| X3 | **D** | 4.7: `AudioStreamPlayer` default `area_mask` changed to none; mouse/keyboard `device` ids are `DEVICE_ID_MOUSE/KEYBOARD`; `CanvasItem` lines are thinner (no feather); `LinearToSRGB` no longer clamps. | Upgrade notes. | upgrading_to_godot_4.7 |
| X4 | **D** | 4.5: `@export_file` stores `uid://`; `Resource.duplicate(true)` internal-only; `RenderingServer.instance_set_interpolated` removed; JSON-RPC `set_scope` removed; `Node.get_rpc_config` -> `get_node_rpc_config`. | Upgrade notes. | upgrading_to_godot_4.5, 4.6 |
| X5 | **D** | Typed-GDScript `NATIVE_METHOD_OVERRIDE`, `ONREADY_WITH_EXPORT` are errors by default; other warnings are only warnings. | Project setting defaults. | gdscript_basics |

## Count

114 rules: 29 forbidden/unsafe (every row marked F) and 85 discouraged/gotcha.
