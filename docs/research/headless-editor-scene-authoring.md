# Why did the 4.7 editor's re-save lose data, and can a headless editor be how agents write scenes?

Asked for: the lead, after the designer ran Project > Tools > Upgrade Project Files (121 lossy files), 2026-11-27.
Engine 4.7.2 (`Godot_v4.7.2-stable_linux.x86_64`, build ed1daf0bf).

## Answer
- **The ids were not the cause.** The editor dropped overrides because the instance they reach into was not
  marked "Editable Children" (`[editable path="..."]`). At runtime Godot still applies such an override, so the game
  worked. But `pack()` skips every node owned by an instance that is not editable, and every node under one. That
  is the cabinet `hands`/`bank` block, the `locked = true` lines, the switches' `act`/`text`, house.tscn's 34
  blocks and the avatar's NameTag. Agents wrote `unique_id`/`parent_id_path` correctly, wrongly or not at all, and
  it made no difference: 4.7 uses them only to find a node again when its name path has gone, and it rewrites
  them on save. `index=` has no part in it either.
- **The lists and `= null`** come from scripts without `@tool`. In the editor these run as placeholders, and the
  placeholder cannot hold a `Packed*Array` export declared with an array-literal default (`: PackedStringArray =
  []`). It reads back the default, so the saved value is dropped. That is credits `covers`/`game_lines`/
  `licence_*`, the options `labels`, and the same in 7 declarations in 5 scripts. A default built with a
  constructor (`PackedFloat32Array([...])`) is unknown to the placeholder, so a value left unset is written as `= null`.
  That is harmless at runtime: the default stays.
- **"Sizes changed" means the editor saved what its live tree worked out.** Most of it the engine works out again
  at runtime, so it does not matter: SubViewport size under a stretch container, `render_target_update_mode`,
  BoneAttachment `bone_idx`/transform, PhysicalBone `joint_offset`. Two kinds are real changes:
  - achievement_toast's Card was grown to its minimum size, `offset_bottom` 80 -> 323;
  - in the GUI only, one-shot GPUParticles had finished playing and were saved as `emitting = false` (17 in
    bubblegum_pops alone).
- **A headless editor works for authoring.** `--headless --editor --script` gives a real EditorNode and the
  `EditorInterface` singleton. `open_scene_from_path` + edits + `set_editable_instance` + `save_scene` writes the
  editor's own format. A second editor re-save then changes nothing, byte for byte. I tried adding a node,
  instancing a scene, an override on an instanced child, and a node under an instanced child.
- **Automatic repair works.** Re-save every file through the editor after marking each instance the file overrides
  into as editable. Run it twice, because child scenes get their ids and uids during pass 1. After that, a third
  plain re-save changes 0 files. A runtime dump of every node and sub-resource matches main in all 1127 game files,
  except values the engine works out again and the achievement Card. Each pass takes about 16 s for the whole
  project.
- **The merge-time drift check should be:**
  - a 0.3 s text lint (nodes without `unique_id`, ext_resource without `uid`, overrides under a non-editable
    instance, `= null` in a .tres, array-literal `Packed*Array` exports in non-tool scripts);
  - the touched files re-saved through the headless editor (about 5-8 s with a warm import), then
    `git diff --exit-code`.

## Findings

### 1. Causes, loss class by loss class

- **The editor's Upgrade tool re-saves scenes, not resources, through the editor.** It runs `open_scene` +
  `SCENE_SAVE_SCENE` + `SCENE_CLOSE` per scene. Resources are only `load(CACHE_MODE_REPLACE)` + `save`. It also
  reimports everything and sets `default_parent_skeleton_in_mesh_instance_3d=false`. Source:
  editor/project_upgrade/project_upgrade_tool.cpp `finish_upgrade()`, tag 4.7.2-stable. Read, not tried, for the
  GUI part. Tried on 4.7.2: `upgrade_like.gd` does the same thing headless through `EditorInterface` and gives the
  designer's output for 465 of 474 changed files once random `unique_id` values are ignored. The 9 that differ:
  - 8 trail scenes differ in the last float digit of transforms, and in `emitting` (see the class 4 bullet on
    one-shot GPUParticles);
  - mirror.tscn: shader uniforms come out `= null` under headless and as their values in the GUI.

- **Class 1: an override on a child of an instance with no Editable Children is dropped.** In
  `SceneState::_parse_node` the first test is
  `if (p_node != p_owner && p_node->get_owner() != p_owner && !p_owner->is_editable_instance(p_node->get_owner())) return OK;`.
  That return comes before properties are saved and before children are visited. Source:
  scene/resources/packed_scene.cpp:799 (4.7.2-stable). Tried on 4.7.2, smallest case: a mini project with
  child.tscn (Child > Inner with script `locked`, `target: Node`; Head) and main.tscn instancing it. The main
  scene had an `Inner` override and a Label3D `Tag` under `Child/Head`. Each variant was opened and saved through
  `EditorInterface`:

  | Variant | Override | Tag | Ids after the save |
  |---|---|---|---|
  | no `[editable]` | dropped | dropped | - |
  | no `[editable]`, correct `unique_id=222 parent_id_path=(12)` | dropped | dropped | - |
  | with `[editable path="Child"]` | kept | kept | - |
  | with `[editable]`, wrong ids (777, (999)) | kept | kept | corrected to 222; `parent_id_path` removed from the override; `Tag` got `parent_id_path=(12, 333)` |

  The real file reproduces the same way. game/zoo/stations/cabinet.tscn from main, re-packed through an edit-state
  instance, lost exactly the `[node name="Cabinet" parent="Cabinet" ...]` block. Appending
  `[editable path="Cabinet"]` kept it.

- **NameTag is the same class.** It is added under `Body/Head`, and `Body` is avatar.glb with no `[editable]`.
  `_parse_node(Head)` returns early, so its children are never visited. Tried on 4.7.2: in the minimal case, `Tag`
  was lost in the same way and kept once the instance was editable. The repair kept NameTag.

- **ids are recovery data only.** `_recover_node_path_index` says "ID paths are only used for recovery". When the
  name path finds the node, a stored id that differs is overwritten with the node's real id (lines 290-307). Nodes
  without an id get a random one from `ResourceUID::create_id()` on save (lines 1099-1123). So a re-save of a file
  with missing ids is not deterministic. Source: packed_scene.cpp 4.7.2. Read; the overwrite was tried in the
  minimal case (777 -> 222).

- **Class 2: Packed*Array exports with an array-literal default lose their values in the editor.**
  - The mechanism: once the editor is up, `Script.get_property_default_value("s1")` for
    `@export var s1: PackedStringArray = []` returns an untyped `Array`. Reading a resource whose file sets
    `s1 = PackedStringArray("a", "b")` also returns `[]`: the value was never accepted. The saver then sees
    value == default and drops the line (scene/resources/resource_format_text.cpp:1986-1990).
  - Tried on 4.7.2, mini project `tun2.gd`/`tun3.gd`, one resource re-saved:

    | Declaration | Value set in the file | Value not set in the file |
    |---|---|---|
    | `: PackedStringArray = []` or `= ["d"]`, and `PackedVector3Array = []` | **lost** | - |
    | `= PackedStringArray()`, `:= PackedStringArray(...)` | kept | **written as `= null`** |
    | bare `: PackedStringArray` | kept | nothing written |
    | `Array[String] = [...]` | kept | nothing written |
    | any of these with `@tool` | kept, every value written out | - |

  - Runtime load of the `= null` file: the default stays and no error is printed.
  - Affected in main: credit_entry.gd `covers`; credits.gd `game_lines`, `licence_names`, `licence_links`;
    choice_row.gd `labels`; coop_tuning.gd `colour_names`; door_shut_rules.gd `keep_open`.
  - Engine issues: godotengine/godot#106965 (open: packed arrays from a constructor are null in the inspector) and
    #124452 (open, 4.7.2: the export text->binary conversion resets array-literal `Packed*Array` values to the
    script default). Read, not tried.
  - **The same root cause may already break exported builds.** #124452 suggests the exported game loses these
    values whenever `convert_text_resources_to_binary` is on (the default). Not tried here.

- **Class 3: `= null` in washer_tuning.tres and old_tree_tuning.tres** is the constructor row of the table above:
  `no_voice_seconds: PackedFloat32Array = PackedFloat32Array([...])` and
  `stage_thresholds := PackedFloat32Array([...])`, neither set in its .tres. Tried on 4.7.2: reproduced headless.
  The runtime value is the script default, so nothing is lost. On a node, the same declaration left unset writes
  nothing (house_lights `floors`: tried, nothing written).

- **Class 4: values the editor's live tree computes and then saves.** Tried on 4.7.2: I took a runtime dump of
  every stored property of every node and sub-resource after `instantiate()`, for main against the designer's
  files.
  - **39 of the 120 files differ when they run. The other 81 changed only in format,** or lost lines that were
    equal to their defaults (`emitting = true`, `scale_max = 1.0`, `covers = PackedStringArray()`, ...).
  - Of the 39, besides classes 1 and 2:

  | What | Example | At runtime | Source |
  |---|---|---|---|
  | SubViewport `size` under a stretch container | 1280x720 -> 1920x1080; 300x400 -> 2x2 | recomputed on resize | subviewport_container.cpp:83-96 (read) |
  | SubViewport `render_target_update_mode` | 4 -> 0 for a hidden container | reset on enter-tree and on visibility change | subviewport_container.cpp:118-131 (read) |
  | BoneAttachment3D `bone_idx`/transform | -1 -> 1, etc. | resolved again from `bone_name` | not read |
  | PhysicalBone3D `joint_offset` | origin clamped to `-body_offset` | `_fix_joint_offset` runs from `update_bone_id` on bind | physical_bone_3d.cpp:940-946, 1300-1320 (read) |
  | root Control `layout_mode = 3` removed | `anchors_preset` dumps as 0 | anchors and offsets unchanged | runtime dump |
  | Control not in a container, grown to its minimum size | achievement_toast `Slot/Card` `offset_bottom` 80 -> 323 | **kept: a real change** | tried; reproduced headless |
  | one-shot GPUParticles3D that finished playing | saved as `emitting = false` | **a real change** | GUI only: headless saves at once and keeps `true` (tried) |

- **The headless editor and the GUI disagree in two places** (tried on 4.7.2):
  - mirror.tscn: the dummy renderer saves `shader_parameter/* = null` for 4 uniforms, where the GUI saved their
    values;
  - one-shot particles (the last row of the table above).

  Floats differ in the last digit in 8 trail files, probably arithmetic across platforms (not settled).

- **Re-save order matters.** A file saved before its child scene or resource has a uid or ids keeps
  `ext_resource` without `uid=`, or overrides without `unique_id`; the next pass fills them in. Tried on 4.7.2:
  pass 2 of the repair changed 49 files, with 155 uid fills, `unique_id` on overrides, and `layout_mode = 2` on
  instances of close_button.tscn whose root lost its `layout_mode`. Pass 3 changed 0. The designer's single pass
  is not a fixed point either.

### 2. Can agents author scenes through a headless editor?

- **In `--headless --editor --script` mode the editor is really there.** Tried on 4.7.2:
  - `Engine.is_editor_hint()` is true;
  - `root` holds an `EditorNode`;
  - `EditorInterface` is a global singleton;
  - `EditorScript.new()` works, and its `_run()` can be called by hand. `get_scene()` returns the edited root but
    is deprecated: use `EditorInterface.get_edited_scene_root()`.
  - Wait for `EditorInterface.get_resource_filesystem().is_scanning()` to turn false before opening a scene.
  - `open_scene_from_path` returns void, so check that `get_edited_scene_root().scene_file_path` is the path asked
    for.
- **The authoring probe** (tried on 4.7.2) ran on the repaired cabinet station:
  - it added a Marker3D owned by the root;
  - it set `rows = 5` on `Cabinet/Cabinet` after `root.set_editable_instance(cab, true)`. The script is a
    placeholder, and `set()` still works;
  - it instanced drawer.tscn with `instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)`, `add_child`, `owner = root`,
    then made it editable and set `Openable.locked`;
  - it added a Label3D under `Cabinet/Looks`;
  - it set `locked` on `Cabinet/Drawer1/Openable` without marking `Drawer1`.
  - **What `save_scene()` wrote:** a new ext_resource with `uid=` and a generated id like `11_030r0`, `unique_id`
    on every new node, `parent_id_path` on the node under the instance, `[editable path="ProbeDrawer"]`, and the
    overrides. The unmarked `Drawer1/Openable` change was dropped, as class 1 predicts. A following plain re-save
    of that file was **byte-identical** (4.5 s wall).
- **A hand-written scene can be brought to the editor's format in one pass.** Tried on 4.7.2: mini `a_plain.tscn`
  had no ids, no uids, no `[editable]`, an override and a node under an instance. `repair_resave.gd` turned it
  into the editor's format, with the override and node kept. A second plain re-save was identical.
- **Plain `instantiate(GEN_EDIT_STATE_MAIN)` + `pack()` + `ResourceSaver.save()` without EditorInterface is close
  but not the same.** Tried on 4.7.2: it differs from the EditorInterface path in 27 of 1164 files. The difference
  is the class 4 live-tree values, because the scene never enters the editor's tree. Use EditorInterface.
- **Placeholders mean `get()` on a non-tool export can return the wrong value** in a headless editor script (class
  2). An authoring script should set values, not read them back.

### 3. Repairing the 121 files automatically

- **The tool**, tried on 4.7.2:
  1. Load each scene's `SceneState` from main and open the scene through EditorInterface.
  2. For each node in that state, if the node, or the parent of an added node, is owned by an instance, call
     `set_editable_instance` up the owner chain to the scene root.
  3. `save_scene`, then load+save each .tres.
  4. Run it twice. A third run with the plain editor-style re-save changes 0 of 1164 files.

  Run on a copy of main 7331341. That is the designer's base: `patch` of the designer's full.diff onto main gives
  exactly the 121 copies.
- **It marked 75 instances in 20 files.** These are exactly the 20 files the text lint flags for an override under
  a non-editable instance (89 places): house.tscn (27), stages.tscn (13), cabinet.tscn, economy.tscn,
  gifts.tscn, wardrobe.tscn and the other stations, looks_present.tscn, looks_avatar.tscn, wardrobe_page.tscn,
  crate_switch.tscn, gift_switch.tscn.
  - No `VANISHED` node was reported: no override in main points at a renamed or moved node.
  - The editor also writes nested editable paths it inherits. For example the station gained
    `[editable path="Cabinet/Drawer3"]` from cabinet.tscn's own `[editable]`. They stay stable.
- **The 7 array-literal declarations must be changed in the scripts before the re-save.** In the experiment:
  - `= []` became bare `: PackedStringArray`;
  - the two non-empty ones became `:= PackedStringArray([...])`. Their .tres files leave them unset, so they then
    came out as `colour_names = null` and `keep_open = null`.

  So for non-empty defaults use `Array[String]`, or a constructor plus the value written into the .tres.
- **What was checked on the result** (tried on 4.7.2, runtime dump of all 1127 game .tscn/.tres against main):
  - **What stays different:**
    - only class 4 values: `joint_offset`, `bone_idx`, BoneAttachment transforms, SubViewport `size`,
      `render_target_update_mode`, `anchors_preset`;
    - the achievement Card `offset_bottom` (80 -> 323);
    - one `icon` that resolves only after the re-save adds its uid.
  - The wardrobe_station subtree differs only because main's copy could not load there. It needs the untracked
    `wardrobe_station_fabric_palette.png` that the glb import makes.
  - **Spot checks all kept their data:**
    - cabinet station `hands`/`bank` (with `[editable path="Cabinet"]`);
    - cabinet.tscn's 4 `locked = true`;
    - 32 `covers` lines in credits.tres;
    - 8 `labels` in options.tscn;
    - NameTag (with `[editable path="Body"]`).
- **Timing** (16 cores, tried): a cold import takes 28 s (two `--import` runs); each whole-project repair pass
  takes about 16 s wall, of which about 10 s is the passes over 631 scenes and 533 resources.

### 4. The drift check at merge

The check, in order:
1. **Text lint (0.3 s for the whole game; tried).** It flags:
   - `[node]` without `unique_id`;
   - `ext_resource` without `uid=` whose target exists;
   - a header without `uid`;
   - an override, or an added node, under an instance with no `[editable path]`. It checks only the top level of
     nested instances; the editor pass catches the rest;
   - `<export> = null` in a .tres;
   - `@export ... : Packed*Array = [` in a script without `@tool`;
   - suggested: `one_shot = true` together with `emitting = true`, which the GUI would flip.

   On main it gave 2029 NOID, 939 NOUID, 404 NOHDRUID, 89 NOEDIT, 7 LITPACK. On the repaired copy it gave only the
   4 NULL lines from the experiment.
2. **Headless editor re-save of the touched .tscn/.tres** (EditorInterface open+save, no editable marking), then
   `git diff --exit-code`. Tried: 5 files including house.tscn took 7.7 s wall with a warm `.godot`, a single
   file 4.5 s, the whole game about 15 s. A cold worktree adds about 28 s of import.
   - **Scenes that instance a touched scene can change too.** For example, a root that loses `layout_mode` adds
     `layout_mode = 2` to its instances. Either re-save the scenes that depend on the touched ones as well, or run
     the whole game (about 15 s).
   - **The fix for a failed check is the repair tool, run until nothing changes.** Random `unique_id`s make a
     re-save of a file with missing ids differ every time, so a failure cannot be cleared by hand-editing ids.
3. **What the check cannot see:** the GUI-only rewrites (one-shot particles finished playing; shader uniform values
   under a real renderer). The lint covers the first. Mirror-like materials need a look by eye, or a GUI save.

The throwaway scripts used, in the lead's scratchpad `tools/`: `upgrade_like.gd`, `repair_resave.gd`,
`author_probe.gd`, `dumpsem.gd`, `scene_lint.py`, `semdiff.py`, `exp_repair.sh`.

## Not found, or uncertain
- **Why the GUI wrote mirror.tscn's 4 uniform values when headless wrote `null`.** Probably the shader compiles
  under the real renderer. Settle it by GUI-saving one ShaderMaterial scene whose uniforms are unset.
- **BoneAttachment3D recomputing `bone_idx`/transform at runtime** comes from a runtime dump, not from reading
  bone_attachment_3d.cpp.
- **The repair was checked by runtime dumps, not by playing.** The achievement Card at 323 px and
  `emitting = false` would need the game run to judge.
- **Whether exported builds already lose the array-literal values (#124452)** was not tried: no export was made.
- **The last-digit float differences in 8 trail files** between the designer's machine and Linux are not settled.
- **I did not open the GUI editor.** Every "GUI" claim comes from the designer's files and the engine source.

## Open for the designer
- None; the choices below are technical, for the lead.
  - **How to override a child of an instance:** keep Editable Children (`[editable path]`, no code; children show
    in the editor tree), or expose the value on the instanced scene's root and forward it with a setter (more
    script, survives without editable).
  - **The 7 array-literal exports:** bare `Packed*Array`, `Array[T]`, or `@tool` on those scripts.
  - **The repair:** whether to run it on main (two passes) before the next ticket batch, and whether agents author
    through the headless editor tool or hand-write and then normalise with it.
