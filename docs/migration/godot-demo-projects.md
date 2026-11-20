# Godot demo projects: what they show for our approach

**Source.** `godotengine/godot-demo-projects`, `master`, commit `b761b4cd5718a7118f2c95eb55f181d0a5f004f1`, dated 2026-10-08. Every `project.godot` says feature `4.7`. The README says `master` tracks Godot's development branch (the next 4.x), not stable. Maintainers also keep per-release branches, so look for a 4.7 branch before copying exact API. The scenes use the Godot 4.6+ `unique_id=` node field and typed GDScript, so the repo is current, not an old port. License: MIT (see "Extra patterns").

**The five findings that matter most.**
1. **No demo covers our hard parts.** There is no request/refusal pattern beyond one small game, no placed-object ids, no level-state save and no join snapshot. There is no `EditorPlugin` that hooks scene save, no inspector plugin, no gizmo and no `_get_configuration_warnings`. Our design is ahead of the demos, not behind them. Confidence: high (full-repo grep, listed under points 1 and 11).
2. **The bomber confirms the earlier `hl-multiplayer` result.** It spawns avatars with `MultiplayerSpawner`, a spawn function and two `MultiplayerSynchronizer` nodes (position by host, inputs by owner). The 71 hand-placed rocks are addressed by node path (`Rock0..Rock70`). It has no late join and no save. This is the one good model for remote avatars (proposal 2). Confidence: high.
3. **`unique_id=` is already written into every `.tscn` node by 4.7.1, but no script can read it.** I confirmed that 4.7.1 writes `unique_id=` on save by packing and saving a scene headless. It exposes no getter on `Node`, `SceneState` or `PackedScene` (method lists checked). It could be the base for stable ids, read by parsing the `.tscn` text. Whether it survives duplicate, paste and instancing is not tested. Confidence: medium (the stability is the open part). I did not test the older built-in "scene unique node name" feature (`%Name`) as an id.
4. **`websocket_multiplayer` is the best match for our Commands up, answers down.** `request_action` runs only on the authority and checks the sender and the action. It refuses with a logged message. `on_peer_add` replays the whole state to a joiner with `rpc_id`, which is a hand-written join snapshot. It is small (147 lines) and our guard and snapshot templates could be tested against it.
5. **The demos are teaching samples, not an architecture.** Most use untyped dictionaries, `$"../../Score"` up-calls (35 `../` references outside xr and mono) and one autoload each. `physics_tests` is the exception worth copying: command-line test scene selection, step-once pause, and a test base class. Confidence: high.

Scope of my reading: the networking, loading, plugins, voxel, 3D character and physics demos and a few GUI and viewport ones. I did not read the audio, xr, mobile, mono, compute and most 2D demos beyond keyword greps. I did not run any demo.

## Inventory

All 135 demos target 4.7. "Net" means networking. The renderer is the project setting (gl = compatibility, mob = mobile, F+ = forward plus). The table is compact: related demos are grouped, and in each row the counts say how many demos carry that content. I counted these with keyword greps over `*.gd`, `*.tscn` and `*.cs`.

| Group (folder) | What it shows | Renderer | Content |
|---|---|---|---|
| `networking/multiplayer_bomber` | 2D bomberman, lobby, spawner, synchronizers | gl | Net, anim; 1 autoload |
| `networking/multiplayer_pong` | 2-player pong, RPC sync | gl | Net |
| `networking/websocket_multiplayer` | turn game with host checks | gl | Net |
| `networking/webrtc_*`, `websocket_chat/minimal` | signaling, lobbies, chat | gl | Net only |
| `loading/serialization`, `runtime_save_load` | ConfigFile/JSON saves, runtime file loading | gl | Saving |
| `loading/autoload`, `scene_changer`, `load_threaded`, `threads` | scene change, background load | gl, mob | Loading |
| `plugins` | 4 editor plugins | gl | Editor plugin |
| `3d/ik`, `misc/2.5d`, `mono/2.5d` | plugins with `@tool` nodes (IK, 2.5D main screen) | F+, gl | Editor plugin, 3D |
| `3d/voxel` | first-person voxel game, settings, pause | F+ | 3D, FPS, ray, saving settings |
| `3d/kinematic_character`, `rigidbody_character`, `platformer`, `squash_the_creeps` | 3D characters, small games | F+ | 3D character, anim |
| `3d/physics_tests`, `2d/physics_tests` | engine tests, pause/step | gl, mob | `@tool`, anim, test tricks |
| `3d/physics_interpolation`, `truck_town` | smoothing, vehicles, loading screen | gl, F+ | 3D |
| `2d/platformer`, `physics_platformer`, `role_playing_game`, `finite_state_machine` | 2D games, anim, state machine | gl | Anim |
| `gui/input_mapping`, `control_gallery`, `theming_override`, `translation`, `graphics_settings`-like, `multiple_resolutions`, `accessibility` | UI | gl | Settings, theme |
| `misc/pause`, `custom_logging`, `hdr_output`, `joypads` | pause, Logger, settings file | gl, mob | Utilities |
| `viewport/*` | screen capture, split screen, 3D in 2D | gl, F+ | Viewport |
| `audio/*`, `compute/*`, `mobile/*`, `xr/*`, other `2d/*` and `3d/*` | rendering, audio, input features | mixed | not relevant |

Counts across the repo: `MultiplayerSpawner` and `MultiplayerSynchronizer` in 1 demo (bomber). `@rpc` in 4. `AnimationPlayer` in 38 demos, `AnimationTree` in 3. `EditorPlugin` in 4 projects (7 `plugin.cfg`). `@tool` in 17. `extends Resource` as game data in 3 (voxel `TerrainGenerator`, rhythm `PlayStats`, plugin `SillyMaterialResource`). A project-wide Theme (`gui/theme/custom`) in 1 (`misc/hdr_output`).

**Looked at and used (17):** `networking/multiplayer_bomber`, `multiplayer_pong`, `websocket_multiplayer`, `loading/serialization`, `loading/autoload`, `loading/scene_changer`, `loading/load_threaded`, `plugins`, `3d/ik` (its `fps` scene and `sade` addon), `3d/voxel`, `3d/platformer`, `3d/squash_the_creeps`, `3d/physics_tests`, `gui/input_mapping`, `misc/custom_logging`, `misc/pause`, `viewport/screen_capture`.
**Looked at, small use:** `gui/theming_override`, `gui/translation`, `misc/2.5d`, `3d/truck_town`, `audio/rhythm_game` (PlayStats resource), `2d/platformer` (AnimatableBody2D), `viewport/dynamic_split_screen`.
**Rejected:** `webrtc_*` and `websocket_chat` (transport and matchmaking, not state), `loading/runtime_save_load` (loads media files at run time, not save state), `3d/kinematic_character` (clean but no network, near-identical to platformer), `mono/*` (C# ports), `xr/*`, `audio/*`, `compute/*` (off topic).

## The 13 points

### 1. Stable ids for placed things and an editor tool that bakes them
- **Demos do:** place things by hand and name them by index. Bomber `world.tscn` has `Rock0` to `Rock70` under `Rocks`, each an instance of `rock.tscn`. Rocks are addressed by path. `bomb.gd` calls `p.exploded.rpc(from_player)` on a body node, and `rock.gd` calls up to `$"../../Score"`. Each rock frees itself from an `AnimationPlayer` method track that calls `queue_free`. Nothing replicates which rocks are gone, so a late joiner would see all 71 again.
- **Editor tools:** none bake ids. No demo hooks scene save. A grep for `scene_saved`, `resource_saved`, `EditorExportPlugin`, `EditorScenePostImport` finds only the unrelated `material_creator` plugin and one `EditorScript` that writes LUT images (`3d/tonemap_color_correction/.../create_neutral_3d_luts.gd`).
- **New fact:** 4.7.1 writes `unique_id=NNN` on every node in the `.tscn` (verified by saving a packed scene; for example `3d/squash_the_creeps/Mob.tscn:45`). I found no getter for it in `Node`, `SceneState` or `PackedScene`.
- **Verdict:** no demo covers this. Ours is missing the tool, and the demos do not supply one. They do show the plain-name approach (path as id), which our earlier research already tested. The `unique_id` field is a lead worth a short experiment: parse it in the baker, or let the baker write our own id and keep `unique_id` as a cross-check.

### 2. A lasting player identity beside the connection id
- **Demos do:** use the connection id everywhere. Bomber keeps `players := {}` (id to name) in the `gamestate` autoload and names each avatar node `str(peer_id)`, then sets `$Inputs/InputsSync` authority from `str(name).to_int()` (`networking/multiplayer_bomber/player.gd:17-20`). Colour is a hash of the name (`gamestate.gd:150`). On disconnect during a game the bomber ends the game.
- **Verdict:** no demo covers a lasting identity. There is no reconnect, no player token and no save keyed to a player. Ours is missing nothing the demos have. Note the pattern "node name is the peer id" works only because players are dynamic. It cannot serve placed things.

### 3. Remote avatars with a synchronizer and spawner
- **Demos do:** this is the bomber's `player_spawner.gd` plus `player.tscn`.
```gdscript
# networking/multiplayer_bomber/player_spawner.gd:3-13
func _ready() -> void:
	set_spawn_function(spawn_player)

func spawn_player(data: Array) -> CharacterBody2D:
	if data.size() != 2 or typeof(data[0]) != TYPE_VECTOR2 or typeof(data[1]) != TYPE_INT:
		push_error("Invalid MultiplayerSpawner spawn parameter. ...")
		return null
	var player: CharacterBody2D = preload("res://player.tscn").instantiate()
	player.synced_position = data[0]
	player.name = str(data[1])
	return player
```
- **Two synchronizers on one avatar.** The root one replicates `synced_position` (`replication_mode = 1`, spawn on) and `label:text` (mode 0). A second one on a child `Inputs` node replicates `motion` and `bombing`, with its authority set to the owning peer. The host runs the body; every peer also runs `move_and_slide()` from the replicated input, so motion predicts between updates. The spawn function validates its data argument. `player_controls.gd` clamps `motion` in the setter ("This will be sent by players, make sure values are within limits"). The host spawns all avatars in `gamestate.begin_game` through `spawner.spawn([pos, id])`. A single call replicates to everyone.
- **Verdict:** confirms and extends `hl-multiplayer`. Copy two ideas: owner-authority input child plus host-authority position, and validation inside the spawn function and the setters. The bomber only runs at game start from a lobby, so it does not show spawning a joiner into a running level.

### 4. Late joiners
- **Demos do:** the lobby scheme avoids the problem: everyone is in the lobby, then the host does `load_world.rpc()` and spawns. `websocket_multiplayer/script/game.gd:122-129` is the one real join sync.
```gdscript
# networking/websocket_multiplayer/script/game.gd:122-129
func on_peer_add(id: int) -> void:
	if not multiplayer.is_server():
		return
	for i in _players.size():
		add_player.rpc_id(id, _players[i], get_player_name(i))
	add_player.rpc(id)
	set_turn.rpc_id(id, _turn)
```
- **Verdict:** no demo covers join into a running level. The websocket one confirms our principle in miniature (host sends the current state to the new peer with `rpc_id`, then announces the new peer to the others), but it is a hand-written list, not a snapshot. Our single-snapshot design is deliberate and stronger.

### 5. Saving and loading a level's state
- **Demos do:** `loading/serialization` saves a player plus a group of dynamic enemies, in two formats (`save_load_config_file.gd`, `save_load_json.gd`). Load clears the group and re-instantiates.
```gdscript
# loading/serialization/save_load_config_file.gd:22-26 and 46-55
var enemies := []
for enemy in get_tree().get_nodes_in_group(&"enemy"):
	enemies.push_back({ position = enemy.position })
config.set_value("enemies", "enemies", enemies)
...
get_tree().call_group(&"enemy", &"queue_free")
```
- **Details to know:** the JSON file converts integers to doubles and needs `var_to_str` for `Vector2`. The code comments warn that `ConfigFile` can store Objects and deserializing from an untrusted file can run scripts. This is the only place any demo mentions that risk. `voxel` stores no world; it saves only settings.
- **Verdict:** no demo covers saving placed state. The demos save "what was spawned" and never "what changed in a hand-built scene". Ours is deliberate: Part nodes plus ids plus snapshot is a different, harder problem. The `var_to_str` and trusted-file notes are worth a line in our save template.

### 6. AnimationPlayer-driven looks, state as the truth, animated colliders
- **State drives animation (good):** `3d/platformer/player/player.gd:169-176` computes values from velocity and writes them into the `AnimationTree` each physics frame.
```gdscript
_animation_tree[&"parameters/run/blend_amount"] = horizontal_speed / MAX_SPEED
_animation_tree[&"parameters/state/blend_amount"] = anim
_animation_tree[&"parameters/air_dir/blend_amount"] = clampf(-velocity.y / 4 + 0.5, 0, 1)
```
  The bomber's `player.gd:55-70` picks `walk_up/walk_down/stunned` from replicated input and calls `$anim.play` only when the name changes. Both confirm ours.
- **Animation drives state (the reverse):** bomber `stunned` is set false by a value track at 1 s inside the "stunned" animation (`player.tscn`, `tracks/1/path = NodePath(".:stunned")`). The rock frees itself from a method track. The 3D platformer coin sets `taken = true` and plays `take` (`coin/coin.gd`). These are convenient but make the animation the truth; with a host-decides model they would need the host to own the clock. Ours is deliberate here.
- **Animated colliders:** `2d/platformer/level/platforms/platform.tscn:15` and `3d/physics_tests/tests/functional/test_moving_platform.tscn:150` are `AnimatableBody` plus an `AnimationPlayer` child. No networking is involved, so how a moving collider behaves on a client is not shown.
- **Verdict:** confirms ours (derive the look from state). No demo shows the animated collider replicated.

### 7. First-person or 3D character controller, interaction by ray
- **Demos do:** `3d/voxel/player/player.gd` is the cleanest first-person graybox: a `CharacterBody3D`, a `Head` pivot, a `Camera3D` and a `RayCast3D` under the head (`player.gd:19-23`). Mouse motion is accumulated in `_input` and applied in `_process` (`player.gd:30-33`, `139-142`). Look is clamped by `clampf(_mouse_motion.y, -1560, 1560)`. Movement uses `Input.get_vector` and exponential friction. Interaction is read from `raycast.get_collision_point()` and `get_collision_normal()`, with a preview mesh shown at the hit cell.
- **Others:** `3d/ik/fps/example_player.gd` is the older untyped style with `Input.is_key_pressed(KEY_W)` (not mappable); skip it. `3d/platformer/player/player.gd` is a third-person controller. `squash_the_creeps/Player.gd` is the plain tutorial one.
- **Not shown:** the voxel player is a single-player node. No demo shows a first-person controller with a remote avatar, a ray that asks the host, or an interaction prompt.
- **Verdict:** confirms ours as a graybox. Copy `voxel/player/player.gd`'s head and ray structure as a reference, not its numbers (they are bare constants, not a Resource).

### 8. A one-run "capture tour" that saves a still per camera view
- **Demos do:** `viewport/screen_capture` does `get_viewport().get_texture().get_image()` then `ImageTexture.create_from_image` on a button press (`screen_capture.gd:11-14`). Nothing saves to disk; `save_png` appears only in the LUT `EditorScript`. `truck_town/car_select/car_select.gd:43` uses `await RenderingServer.frame_post_draw` to show a loading screen before a heavy instantiate.
- **My test:** I ran a headless script that awaited `RenderingServer.frame_post_draw` and read the root viewport texture. The script did not finish in two minutes and I stopped it. This fits the known fact that a headless display server draws nothing, but I did not capture the failure reason. I did not test with a window or a dummy renderer.
- **Verdict:** no demo covers a capture tour. The demos only give the primitive (`frame_post_draw`, `get_image`). Our `tools/shot.sh` harness already goes further.

### 9. Settings and options screens on one Theme, input remapping
- **Remapping:** `gui/input_mapping` is a good 95-line model. The `KeyPersistence` autoload copies `InputMap` events into a dictionary, saves it with `file.store_var(keymaps, true)` to `user://keymaps.dat`, and on load only restores actions that still exist.
```gdscript
# gui/input_mapping/KeyPersistence.gd:32-40
for action: StringName in keymaps.keys():
	if temp_keymap.has(action):
		keymaps[action] = temp_keymap[action]
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, keymaps[action])
```
  `ActionRemapButton.gd` is a toggle `Button` with an `@export var action` that listens in `_unhandled_key_input` and ignores Enter (so the keyboard can navigate). It remaps one event per action and keys only. A gamepad needs more. Note `store_var(..., true)` writes full objects; its own comment warns about untrusted data.
- **Settings files:** three different ways: JSON lines (`voxel/settings.gd`, an autoload, read in `_enter_tree`), `ConfigFile` (`misc/hdr_output/in_game_hdr_settings`), and a var dictionary (keymaps). Three demos, three formats: no recommended one.
- **Theme:** only `misc/hdr_output` sets a project-wide Theme. `voxel` and `squash_the_creeps` assign one `.tres` to each root `Control` (`theme = ExtResource(...)` in each scene). `theming_override` shows runtime overrides by duplicating the stylebox and calling `add_theme_stylebox_override`. `translation` uses CSV and PO with `TranslationServer.set_locale`.
- **Verdict:** remapping confirms we should copy this small pair (and extend it to gamepad). On Theme, ours (one Theme for all screens) is stricter than the demos and also valid.

### 10. Typed Resources for tuning data, custom resources in the Inspector
- **Demos do:** rarely. Of 135 demos, only `3d/voxel/world/terrain_generator.gd` (a `class_name` Resource used only for static functions), `audio/rhythm_game/game_state/play_stats.gd` (exported fields with a setter that calls `emit_changed()`) and the plugin `silly_material_resource.gd` extend `Resource`. Tuning numbers sit as `const` in the script (bomber `MOTION_SPEED = 90.0`, voxel `MOVEMENT_SPEED_GROUND`) or as `@export` on the node (`squash_the_creeps/Player.gd`, with doc comments `##`). Grouped exports (`@export_group`) appear in `audio/rhythm_game/game_state/conductor.gd`.
- **Verdict:** ours is deliberate and better. The demos do not teach typed tuning resources; only `PlayStats` shows the change-signal pattern (`emit_changed` in setters), which our templates may want so UI can listen.

### 11. Editor plugins and `@tool` scripts in general
- **Plugin demos** (`plugins/addons`): `custom_node` (13 lines; `add_custom_type`/`remove_custom_type` in `_enter_tree`/`_exit_tree`), `main_screen` (41 lines; `_has_main_screen`, `_make_visible`, `_handles`), `material_creator` (dock via `add_control_to_dock`, plus resource loader/saver/importers registered in `_enter_tree` and removed in `_exit_tree`), `simple_import_plugin` (an `EditorImportPlugin`).
- **Skeleton worth copying:**
```gdscript
# plugins/addons/custom_node/heart_plugin.gd
@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_custom_type("Heart", "Node2D", preload("res://addons/custom_node/heart.gd"), icon)

func _exit_tree() -> void:
	remove_custom_type("Heart")
```
- **`@tool` nodes:** `3d/ik/addons/sade/ik_look_at.gd` is a long `@tool` script whose exported setters do work in the editor (it warns that `get_node` fails on the first call and guards with a `first_call` flag, lines 4-11), and `Engine.is_editor_hint()` gates code in 6 places in `ik_fabrik.gd`. `misc/2.5d` adds an editor main screen with its own gizmo drawn in 2D.
- **Not covered:** scene-save hooks, `EditorInspectorPlugin`, `EditorNode3DGizmoPlugin`, `_get_configuration_warnings` and `_validate_property`. I grepped for each of them and found nothing outside the plugin skeletons above. They do not appear in the demos.
- **Verdict:** the demos give correct skeleton code only. For the id baker we write it from the Godot docs: `EditorPlugin` plus the `scene_saved` signal or `_save_external_data`, and `EditorInterface.get_edited_scene_root()` (the demos use only `get_selection()` and `get_editor_scale()`).

### 12. Loading screens, background loading, scene changes
- `loading/load_threaded` calls `ResourceLoader.load_threaded_request(path)` for six images, then `load_threaded_get(path)` when a button is pressed. It never calls `load_threaded_get_status`, so it shows no progress and does not handle failure.
- `loading/autoload/global.gd` shows the safe manual scene change: `call_deferred` into `_deferred_goto_scene`, free the old scene, load the new one, add it to `root` and set `get_tree().current_scene`. `scene_changer` uses `change_scene_to_file` and `change_scene_to_packed`.
- `truck_town/car_select/car_select.gd:42-44` shows the cheap loading screen: show the control, `await RenderingServer.frame_post_draw`, then do the heavy `instantiate()`.
- **Verdict:** no demo has a real loading screen with progress. The deferred scene change and the "paint one frame first" trick are the two small things to copy. Ours is missing a progress-aware loader and no demo gives one.

### 13. Project structure and naming
- **Autoloads:** 17 projects have one or two (the repo's own project list shows `auto1` or `auto2`; most have none). Examples: bomber `gamestate` (networking and player list), voxel `Settings`, input_mapping `KeyPersistence`, squash `MusicPlayer` (a scene), physics_tests `System` and `Log`. They are lowercase or CamelCase without a rule.
- **Signals and calls:** `58` `signal` declarations in all non-xr GDScript, `35` up-references through `$"../"` and `get_node("../")`, and `273` `%UniqueName` uses. So scenes reach other nodes mostly by unique name, and up-calls exist (the bomber's `$"../../Score"`). Groups appear in `13` files (`mob`, `enemy`, `reflection_probe`).
- **Typing:** new demos use typed GDScript (`@onready var raycast: RayCast3D`, `-> void`, `Dictionary[Vector3i, int]`); older ones (`squash_the_creeps`, `ik/fps`) are untyped.
- **Tooling:** CI is file-format checks only (`file_format.sh`: dos2unix, recode), a link check and a web export. There are no unit tests.
- **Verdict:** demos do not follow "signals up, calls down" strictly; ours is stricter on purpose. Our rule keeps scenes reusable and is not contradicted by anything here.

## Extra patterns worth a look

1. **`3d/physics_tests` test driver.** `tests.gd:63-100` reads `OS.get_cmdline_user_args()` (`--test-scene=...`, `--ticks-per-second=`, `--time-scale=`) and starts one scene. `utils/system.gd` is a small autoload with `process_mode = ALWAYS`, toggles for debug collision shapes, pause, and a `step_once` that unpauses for exactly one physics tick. `test.gd` is a base class with `wait_for_physics_ticks(n)`. Good for a deterministic harness. The step-once and tick-wait are small and copyable.
2. **`misc/custom_logging`.** A `Logger` subclass receives every message and error, with script backtraces, and the code warns it must be thread-safe (use `call_deferred`). A headless test run could use it to fail on any `push_error`. Also a debug overlay source.
3. **`misc/pause`.** Pause by `get_tree().paused`, with `process_mode = PROCESS_MODE_ALWAYS` on the unpause control. Our pause approach for a host game must ignore the network (a paused tree still receives RPCs), which the demo does not say.
4. **Spawn-function validation** in `player_spawner.gd` and `bomb_spawner.gd` and the clamp-in-setter in `player_controls.gd`. Cheap input hardening.
5. **`3d/voxel/settings.gd` plus `pause_menu.gd` plus `options.gd`.** A complete settings-and-pause loop in about 100 lines that matches our "screens on one Theme" rule (each root control gets the theme).
6. **`3d/physics_interpolation`.** Shows `get_tree().physics_interpolation` and `reset_physics_interpolation()` after a teleport (also in `platformer/player.gd:~45`). Needed when our host corrects a client position.
7. **`plugins/addons/material_creator`.** The pattern of registering a `ResourceFormatLoader`/`Saver` shows how to make a custom saved format, but it is heavy for us.
8. **`ik` `@tool` setter guards.** The `first_call` flag for `NodePath` exports is a real `@tool` pitfall.
9. **`gui/translation`.** CSV and PO workflow and `TranslationServer.set_locale` if the kit wants languages.
10. **Licence.** `LICENSE.md` is MIT: copyright "2014-present Godot Engine contributors" and "2007-2014 Juan Linietsky, Ariel Manzur". We may copy, modify and ship code if the notice and permission text travel with it. Third-party art and audio inside demos have their own terms; I did not check them. Copy only scripts and small scenes, and put the MIT text beside them.

## Concrete proposals (in priority order)

1. **Id baker (editor plugin skeleton), medium.** Start from `plugins/addons/custom_node/heart_plugin.gd` plus `plugin.cfg` (`_enter_tree`/`_exit_tree`, `@tool`). The demos give no save hook, so write the hook from the docs: on scene save, walk `Part` nodes in `EditorInterface.get_edited_scene_root()` and write an id. First run a 30-minute experiment on `unique_id=` (survives duplicate, paste, instance, rename?). If it holds, the baker may only need to read it from the `.tscn`. Replaces: path as id. Also use the `first_call` guard idea from `ik_look_at.gd` for exported node paths.
2. **Remote avatar template, medium.** Adapt `networking/multiplayer_bomber/player_spawner.gd`, `player_controls.gd` and the two-synchronizer layout in `player.tscn` into the scene-part avatar: owner-authority `Inputs` child, host-authority position, spawn-function validation, input clamped in setters. Replaces: nothing yet (the kit has no avatar template); extends `hl-multiplayer` findings. Name the avatar by a lasting player id, not `str(peer_id)`, to cover point 2.
3. **Guard and snapshot check, small.** Use `websocket_multiplayer/script/game.gd` (`request_action`, `on_peer_add`) as a worked comparison case for the guard and snapshot templates: same game, rewritten as a Part with our Session, to show the saving in code. Replaces: nothing.
4. **Test driver, small.** Copy the `OS.get_cmdline_user_args()` parser and `step_once`/`wait_for_physics_ticks` from `3d/physics_tests/tests.gd`, `utils/system.gd`, `test.gd` into the harness and zoo. Replaces: any ad-hoc scene selection in `tools/run.sh` and `tools/shot.gd` (not checked).
5. **Settings and remap, small.** Copy `gui/input_mapping/KeyPersistence.gd` and `ActionRemapButton.gd`, add gamepad events and a "reset to default"; save as JSON or `ConfigFile` rather than `store_var(..., true)`. Replaces: any existing remap code (not checked).
6. **First-person graybox player, small.** Compare `zoo-design`'s player with `3d/voxel/player/player.gd` (head pivot, ray under head, accumulated mouse, `Input.get_vector`) and adopt anything missing. Replaces: nothing, a cross-check.
7. **Deferred scene change and one-frame loading screen, small.** `loading/autoload/global.gd:~16-30` and `truck_town/car_select/car_select.gd:42-44`; then add `load_threaded_get_status` polling ourselves, since no demo has it.
8. **Logger capture for tests, small.** `misc/custom_logging/custom_logger_ui.gd` (`Logger` subclass, `call_deferred`) to make a headless run fail on `push_error`.
9. **Save template note, small.** Add the JSON-vs-`var_to_str` conversion note and the untrusted-file warning from `loading/serialization/*.gd` to the save docs.

## Not covered / unsure

- Not read in detail: `2d/role_playing_game`, `2d/finite_state_machine`, `viewport/gui_in_3d`, `3d/ragdoll_physics`, `audio/*`, `mobile/*`, `xr/*`. They did not match any point by name or keyword, but I did not open all.
- Counts for `AnimationPlayer`, `@tool` and others are "files that mention the word", not careful usage counts.
- I did not run any networked demo. Everything about the bomber and pong comes from reading code and scenes, so behaviour such as a joiner arriving mid-game is inferred.
- `unique_id` stability on copy or instance is untested; only that it is written, and that no script getter exists in 4.7.1.
- The headless capture test hung and was stopped; the reason is not captured.
- No demo covers: stable ids, a lasting player identity, join snapshots, level saves, scene-save hooks, inspector plugins, gizmos, configuration warnings, progress loading, capture tours or typed tuning resources.
