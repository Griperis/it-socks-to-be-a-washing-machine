# Authoring scenes and props, and wiring them up in the editor

Research for maintenance/138 (feeds maintenance/131). Read-only; nothing in the repo changed.
Date 2026-11-19. Repo at `main` 3d8ea53f. Godot docs are `docs.godotengine.org/en/stable`, which
showed as **Godot 4.7** on every page fetched (checked 2026-11-19). "Unverified" marks what no page
I could fetch states; I did not fill those gaps from memory as fact.

## Summary (10 lines)

1. One scene per prop, with a typed root script and a `Model` child that is a plain instance of the glb
   (not an inherited scene). The docs say an inherited imported scene cannot drop base nodes and needs
   its subresources saved externally; a wrapper survives a re-export.
2. Colliders, hinge pivots, lamp lights and Sock spots become nodes inside the prop scene, so the
   1.2 MB `manifest.json` stops being the place they live.
3. Make interactions components: the thing the crosshair hits is an `Interactable` (a `StaticBody3D`,
   today's `Station`), authored with `@export` fields and children. A plain child `Node` cannot be the
   raycast target, so "component" here means a collider-node, plus plain `Node3D`/`Marker3D` helpers.
4. Wire by kind. Purely visual, inside one prop (switch toggles its own light): connect in the editor.
   Anything that touches Game, Commands, saves or the net: connect in code by one installer that walks
   a group, as `HouseInstaller.install_stations()` does today.
5. Reference by typed export (`@export var hopper: Interactable`) for required parts, `%UniqueName`
   for optional internals, groups for "all of a kind", NodePath only where a type cannot be named.
   Identity stays an exported `id: StringName`, never a node path.
6. Lean on `_get_configuration_warnings()` and `@export_tool_button` first. Add a gizmo plugin only for
   `RoomVolume` and door hinges. Skip inspector plugins. Every script a tool script touches must be
   `@tool`, so keep components thin (this is the real cost: `Station`/`Openable` pull in `Player`,
   `Prompt`, `Layers`).
7. The house: one `house.tscn`, one scene per floor, props under rooms. Room membership is geometry
   (a `RoomVolume` contains the prop's origin), as `_room_at` does now; the parent folder is only
   tidiness and a validator checks they agree.
8. The generated shell and hand-placed props never share a file: the generator owns `shell.glb` plus a
   generated read-only layout; hand scenes own props, lights, doors, devices. One shared `problems(root)`
   function backs the in-editor Validate button, config warnings and the headless contract test.
9. The node-free rules keep working: a loader (the "scene reader") walks the house scene once and writes
   the same dictionaries `HouseParts.assemble()` writes today, so `FlatLayout`, Game, SockWorld, saves
   and the snapshot see plain data. Note ADR-0005 is the baked-heap ADR; the node-free statement lives in
   ADR-0006 and `docs/architecture/layers.md`.
10. Eight designer questions at the end; the biggest are: is the scene or the JSON the source of truth,
    does the generated shell stay, and should rooms be authored or generated.

## 0. Where the code is today (evidence)

- Zero `@tool`, one `@export` in all of `game/` (grep `@tool\|@export` over `game/`: only
  `game/net/session_host.gd:14`). Seven `.tscn`, each one node; `game/core/main.tscn` is a lone
  `Main` node with `main.gd`.
- Three autoloads only: `Settings`, `UiSounds`, `Profily` (`project.godot:18-22`). No `[layer_names]`,
  no theme, no bus layout in `project.godot`.
- The house is built in `Room._ready()` (`game/house/room.gd:210-262`): light, model, colliders, then a
  `Cabinet.new()` per Collection, `_station(...)` for the washer, `_build_wardrobe`, `_build_devices`,
  `_build_openables`, doors, clock, mirror. `Room.stations()` (`room.gd:389`) hand-collects every
  Station into one list.
- Openables are made from layout records: `_build_openables` (`room.gd:702-726`) does
  `Openable.new()`, sets `title/kind/container/...`, finds the mesh with `model.find_child(door["node"])`,
  and `op.build(door, mesh)` (`game/house/openable.gd`, `build()` right after `_ready`) reads
  `hinge/axis/open_deg/open_m` and builds `BoxShape3D` children from `FlatLayout.door_boxes`.
- `Station` (`game/house/station.gd`) is a `StaticBody3D` with string/bool fields (`title`, `icon`,
  `kind`, `click_only`, `hint_only`, `quiet`, `prompter` Callable) and one signal `interacted`.
- Wiring is the installer: `HouseInstaller.install_stations()` loops `room.stations()` and does
  `station.interacted.connect(func(s): _rig_of(s.user).use(s))` (`game/house/house_installer.gd`).
- Aiming is a priority chain in `RigAim.aim()` (`game/player/rig_aim.gd:19-116`), one `aimed_*` field per
  kind, each compared by distance with the others. (Out of scope here; the `Interactable` idea in 131
  replaces it.)
- Furniture is data: `placements[]` in `house_layout.json` (73 rows: `name, piece, room, level, pos[x,z],
  yaw`, optional `y, rug, furn, decor, crawl, lamp, names, open_deg, apart`) plus
  `furniture/manifest.json` (67 pieces: `file, footprint, height, crawl_gap, hide, nodes, parts{pivot,
  axis, open_deg|open_m, boxes}, colliders[], containers[], tops[], spots[]` with up to 1,401 sample points,
  `lamp*`, `keys`). `HouseParts.assemble()` (`house_parts.gd:78`) turns them into the colliders,
  furniture, crawl_spaces, lights, openables and pianos records the game reads; `tops()` (`:245`) turns the
  sampled `spots` into resting rects; `_room_at()` (`:388`) finds a point's room by rect containment;
  `build_model()` (`:427`) instances each glb and flattens its meshes into one `Props` node.
- Layout top level (structure only): `units, bounds, levels(4), outline, rooms(17), doorways(16),
  front_door, windows(22), spawn, washer, cabinet_spots(8), clear_zones, colliders(692), ramps,
  furniture, lights(40), rugs, clock, wardrobe, mirror, devices, room_doors(8), locked_doors(3), parts,
  elevator, machines(2), props(1), grotto, laundry_bins(7), placements(73)`. `openables` and
  `crawl_spaces` are empty in the file; they are derived at load.
- The pairing machine already shows the "parts as children" shape, built by hand: `_part()`
  (`game/devices/pairing_machine.gd:127`) makes a child `Station`, tags it `set_meta("part", which)`, and
  `part_of(station)` reads that meta back. Constants like `BUTTON`, `HEAP_HALF`, `HEAP_DROP` are
  positions that belong in marker nodes.

## 1. Prop authoring

### 1.1 Wrapper scene, not an inherited scene

| | Wrapper scene (`Model` child = instance of the glb) | Inherited scene (base = glb) |
|---|---|---|
| Re-export from Blender | Node names inside `Model` may change; wrapper's own markers/colliders are untouched | Base nodes cannot be removed; renames in the base are the risky part |
| Subresources | Saved in the prop's `.tscn` or `.tres` as normal | Docs: "You can't edit subresources directly. You must save them externally." |
| Root type/script | Free: `StaticBody3D` or `Node3D` with your script | Root type comes from the glb unless you set one in import |
| Authoring colliders | Add `CollisionShape3D` anywhere | Allowed ("add new nodes anywhere") |

Checked 4.7: `tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html` says you cannot
remove nodes from an imported base scene, cannot edit subresources directly, can add nodes anywhere.
The manual page for scene inheritance and "Editable Children" was **not found** (a search of
docs.godotengine.org returned no such page; `getting_started/step_by_step/instancing.html` does not
cover inheritance): everything beyond the import page is unverified. This agrees with 131's rule
("inherited only where the glb is the part: Avatar, Cat"), and I keep that rule.

Instance overrides are documented (4.7, `instancing.html`): a changed property on an instance overrides
the packed scene's value, shows a revert arrow, and survives later edits of the packed scene.
Shared resource properties on an instance need **Make Unique** first. Applied to props: a lamp's light
colour is a node property, so a per-placement colour is a plain override; a shared
`StandardMaterial3D` is not (use `resource_local_to_scene` or Make Unique, see features-map section 1).

**Editable children**: leave off. Use the Model as a black box and put every tweak on the wrapper's own
nodes. API exists (`Node.set_editable_instance`, `is_editable_instance`, class reference 4.7 lists
both, descriptions not in the text I read); how `.tscn` stores it is unverified.

### 1.2 Folder layout and names

```
scenes/props/<category>/<piece>.tscn      # fridge.tscn, floor_lamp.tscn  (category = kitchen, living, ...)
scenes/props/_base/prop.tscn              # optional shared base: root script, group, layer
assets/house/furniture/<piece>.glb        # today's place; glbs stay generator output
resources/props/<piece>.tres              # only if a prop needs shared settings (see 2.5)
```

- Scene file `snake_case.tscn` = piece id from the manifest, so `placements[].piece` maps by name.
- Root node PascalCase (`Fridge`), `class_name` for the root script only when other scripts need the
  type. Children named by role: `Model`, `Colliders`, `Spots`, `Markers`.
- Keep scene, its script and its `.tres` in one folder only if you want self-contained props; the
  split above keeps the 135 files in `assets/house/furniture/` (glb + `.import`) generator-owned.
- Moves must carry `.uid` and `.import` (features-map "UIDs": `uid://` keeps references; 4.4+
  `@export_file` stores `uid://`).

### 1.3 Placing by hand: what the editor gives

Verified on 4.7 (`tutorials/3d/introduction_to_3d.html`): **Use Snap** toggle (`Y`), `Ctrl` snaps
temporarily, Transform menu has **Snap Object to Floor** and **Snap Settings** (translate, rotate
degrees, scale percent); modes Move `W`, Rotate `E`, Scale `R`, Local Space `T`, `F` frames the
selection. Instance overrides and revert arrows: `instancing.html`.

Not stated by any page I could fetch (unverified): dragging a `.tscn` from the FileSystem dock into
the 3D viewport, "Instantiate Child Scene" shortcut, scene thumbnails in the dock, a "scene palette". The
core editor has no scene palette or "scene collection" concept; the unit is the folder. Third-party
placement plugins exist; I did not evaluate any. If a palette matters (Question 6), the supported route is
a small `EditorPlugin` dock (docs: `making_plugins.html`, a dock root must be a `Control`).

### 1.4 GridMap and MeshLibrary: when they fit

Checked 4.7 (`tutorials/3d/using_gridmaps.html`): a GridMap places meshes from a MeshLibrary on a grid;
the library is a scene of `MeshInstance3D` children (materials must be on the mesh, not the node), optional
`StaticBody3D` collision and `NavigationRegion3D`, exported via Scene > Export As > MeshLibrary. "Only the
documented MeshLibrary format is recognized. Other node types ... are not exported." It is "not for
placing arbitrary nodes on a grid".

- **Fits:** walls, floor tiles, fences, modular dungeon pieces: many copies, no script, no per-piece
  state. Possibly the Drum's or Grotto's cave kit.
- **Does not fit:** props with scripts, lights, openables, Sock spots; our rooms (3.83 x 3.16 m, odd
  sizes, 17 of them, `house_layout.json` `rooms`) are not on one cell size; furniture yaw is free.
  The shell stays a glb.

### 1.5 How many nodes and scenes are too many

The 4.7 docs give no limit (`scenes_versus_scripts.html` gives no numbers: scenes are "processed in
batches", scripts are slower, node logic can be "several hundred lines"). Our own numbers: 73
placements; a prop of about 12 nodes (Model, body, 4-8 shapes, 2-3 markers) is about 900 nodes for all
furniture, which is small. The real costs are editor open time and `.tscn` diff noise, not the
runtime. The larger risk is node count in *code-built* parts (`Cabinet.build()` makes segments by
code). Rule of thumb for us (my judgement, not a doc): one scene per thing a designer places or swaps; no
scene for a single mesh; split a scene when two people edit it or it passes about 500 nodes.

### 1.6 MultiMesh for repeated dressing

4.7 (`using_multimesh.html`): one draw primitive for up to millions; **no per-instance
frustum culling** (split into several MultiMeshes by area); `visible_instance_count`. The page does
not cover lights, collisions or editor population (unverified). Class rules from `godot-rules.md` R6 stand
(set format and colours before `instance_count`). For us: hand-placed props stay scenes (selectable,
overridable, collidable); MultiMesh only for baked, never-individually-edited dressing (books on a shelf,
leaves, the Mess, which is already MultiMesh). A prop scene can contain a `MultiMeshInstance3D` for its
own repeated parts.

## 2. Interactions hooked up in the editor

### 2.1 Components as child nodes

The crosshair raycast returns a `CollisionObject3D`. So the interactable must be a collider node (today's
`Station`, layer `Layers.STATION`). Proposed small set (names are proposals):

| Node | Base | `@export` fields | Replaces |
|---|---|---|---|
| `Interactable` | `StaticBody3D` | `id: StringName`, `title: String`, `icon: StringName`, `prompt_mode` enum (key, click_only, hint_only, quiet), `priority: int` | `Station` strings/bools |
| `Openable` | extends `Interactable` | `door_kind` enum (hinge, slide), `axis: Vector3`, `open_deg`, `open_m`, `swing_time`, `cue: OpenKind` (Resource), `model: Node3D`, `partners: Array[Openable]` | `Openable.build()` + `CUE_STEMS` const table |
| `Container` | `Node3D` | `kind`, `interior: Node3D` (box), `shelf_levels: PackedFloat32Array`, `openables: Array[Openable]` | layout `openables[].interior/shelves_y` |
| `SockSpot` | `Marker3D` (or `Node3D` + size) | `kind` enum (top, crawl, hide), `size: Vector2`, `zone: StringName` | manifest `tops/spots/crawl_gap` |
| `RoomVolume` | `Node3D` (box) | `id: StringName`, `size: Vector3`, `level: StringName`, `open_to: Array[RoomVolume]` | `rooms[]`, `doorways[]` |

Why not a plain child `Node` "Interactable" next to a collider: the aim code would have to find it from the
collider (`collider.get_node("Interactable")` or meta), which is the `set_meta("part", ...)` problem
again. Collider-is-the-component keeps `collider as Interactable` one cast. A component that is not a
raycast target (`Container`, `SockSpot`, `RoomVolume`) is a plain `Node3D`.

**Pitfall that shapes the design:** `@tool` rules (4.7, `running_code_in_the_editor.html`): "Any other
GDScript a tool script uses must also be `@tool` to create instances or access its methods and members.
Static methods, constants, and enums can be used from non-tool scripts." A script extending a tool script
is not itself a tool. `Station`/`Openable` today reference `Player`, `Prompt`, `Layers`, `Json`. Make
the *authoring* base thin: exports, `_get_configuration_warnings()`, constants; push game behaviour
(prompt building, tweening) to non-tool code that takes the component as an argument, or guard with
`Engine.is_editor_hint()`. (Whether a typed `@export var d: Openable` still filters in the node picker when
`Openable` is non-tool: unverified.)

### 2.2 Signals: editor versus code, and what the `.tscn` stores

Verified 4.7 (`getting_started/step_by_step/signals.html`): connect via the node's Signals tab,
double-click a signal; simple mode needs a receiver with a script, advanced mode connects any node or
built-in method and can add binds/options; a connection icon shows in the script margin (editor-made
only); the page warns that automatic code generation may not work with an external editor (VS Code), in
which case connect in code. It says nothing about what `.tscn` stores or about inherited/instanced scenes.

From the file-format page (`engine_details/file_formats/tscn.html`, 4.7): it names `[connection ...]`
as a heading type but gives no fields; covers `node_paths=PackedStringArray("follow_node")` for exports
typed as Node (stored as NodePath), `index`, `unique_id` (only in scenes saved by 4.6+). So a stored
**editor connection format and its behaviour under inheritance are unverified**. What I would test in a
spike before relying on it: (a) a connection made in a prop scene survives dragging the prop into a
room scene; (b) a connection made in a room scene to an instanced child; (c) a connection in a base scene
is kept in an inherited scene.

Rule (matches `scene_organization.html`, 4.7: signals respond, calls start; the parent injects; siblings
go through an ancestor):

| Connect in the editor | Connect in code |
|---|---|
| Inside one prop scene, purely visual or local: switch -> its own light, button -> its AnimationPlayer, drawer `toggled` -> its sound | Anything that reaches Game, Commands, SockWorld, saves or the net (`interacted` -> `Rig.use`) |
| Parent-to-child inside one scene | Nodes created at run time (Cabinets by the plan), or across scenes (machine -> Game) |
| Short one-way effects a designer wants to retarget | Anything a test must assert (code is greppable; `[connection]` lines are not) |

Why the split: the net seam (ADR-0006) must see every state change as a Command, so the game's
signals stay wired by `HouseInstaller`-style code that walks `get_tree().get_nodes_in_group("interactables")`.
The editor wires *presentation*, never *state*.

### 2.3 Four ways to point at a node

| | Typed export `@export var hopper: Interactable` | `NodePath` / `@export_node_path` | `%UniqueName` | Group |
|---|---|---|---|---|
| Stored as | NodePath, listed in `node_paths=` (tscn page, 4.7) | NodePath | name string, `unique_name_in_owner` (Node ref, 4.7) | name string |
| Editor UX | Drag or pick; filtered by class (exports page: `@export var b: BaseButton`, `class_name` types allowed) | Same, weaker type check | Right-click > Access as Unique Name | Node dock > Groups; global groups in Project Settings (groups page) |
| Breaks when | Target deleted (null); renames inside the scene: editor behaviour on rename **unverified** | Same | Rename of the target, or another node of that name wins; invisible from another scene ("get_node("Hand/Sword").get_node("%Hilt")") | Typos |
| Cross-scene | Yes, from the owning scene up | Yes | No, one hop | Yes |
| Use for | Required parts (`hopper`, `button`, `door.model`) | Rare: where a type cannot be named | Optional or internal bits inside one scene (`%Grip`, `%Light`) | "all interactables", "all room lamps" |

Reading exports: not in `_init` (returns the annotation default); read in `_ready` (exports page, 4.7).
Exported Resources load with the scene; `@export_file` for on-demand (same page). Array of nodes:
the page covers typed arrays of Resources and ints only, so `Array[Openable]` exports are unverified;
test them (the scene tree shows them in features-map as "typed arrays").

Recommendation: typed exports for what the script cannot work without, `%` for internals, groups for
sets, **never a node path as identity** (saves and the snapshot use `id: StringName`, 131 rule).

### 2.4 Custom Resources as shared settings

Use when many instances share one set of values and a designer edits it in one place: `OpenKind`
(`stem`, `swing_time`, sound cues; replaces `Openable.CUE_STEMS`, `openable.gd:34-41`), `PropInfo`
(footprint, hide text, plan spot). Rules already in `godot-rules.md` R1-R4 and features-map: one load per
path = one shared instance; `_init` params need defaults; runtime state stays out. 4.7 note
(`running_code_in_the_editor.html`): a setter does not run when a property of an exported resource
changes; make the resource a tool, emit `changed`, connect in the owner's setter, and disconnect from the
old one. Keep Resources to definitions; if a field needs a live editor reaction, put it on the node.

### 2.5 `@tool`, warnings, buttons, gizmos, plugins

| Feature | For | Pitfalls (docs 4.7 unless noted) | Lean on? |
|---|---|---|---|
| `@tool` | Run script code in the editor | Other scripts it uses must be `@tool`; `extends` a tool script is not a tool; no undo; `queue_free` of editor-used nodes can crash; static var of a non-tool script reads `null` silently; breakpoints do not work; nodes you `add_child` need `owner = get_tree().edited_scene_root` to save; changes do not mark the scene unsaved (`EditorInterface.mark_scene_as_unsaved()`) | Thin only |
| `_get_configuration_warnings()` + `update_configuration_warnings()` | A warning triangle in the Scene dock ("Hopper not set"); this is the docs' own answer to "document the dependencies" (`scene_organization.html`) | Needs `@tool`; refresh when a value changes (call `update_configuration_warnings()` in setters) | **Yes, first** |
| `@export_tool_button("Snap to floor", "Callable")` | One-click inspector actions: snap to floor, bake Sock spots, validate room | Requires `@tool`; icon name must be a built-in editor icon, no project icons | **Yes** |
| Setters on `@export` | React when the inspector changes a value | Run only in tool mode; setters may run more than once (godot-rules G14); resource sub-property edits do not trigger | Sparingly |
| `EditorNode3DGizmoPlugin` | Draw `RoomVolume` boxes, door hinge arc, `SockSpot` rects in the viewport | Page is marked work in progress; handles need `_get_handle_name`, `_get_handle_value`, `_commit_handle`; the page does not say whether the gizmo script needs `@tool` (unverified); plugin must be an `EditorPlugin` that calls `add_node_3d_gizmo_plugin` | Later, for `RoomVolume` and hinges only |
| `EditorInspectorPlugin` | Custom inspector rows for a type | Called for every edited object (`_can_handle` must be cheap); returning `true` from `_parse_property` removes the default editor | Skip |
| `EditorPlugin` | Docks, the gizmo/inspector registration, a "Validate house" panel | Main script must be `@tool`; everything it uses must be `@tool` or it "will act like an empty file"; enable in Project Settings > Plugins | One plugin, small |
| `EditorScenePostImport` | Fix a glb at import (rename nodes, set root script) | Script needs `@tool extends EditorScenePostImport`; set path in the Import dock | Option for markers from Blender (see animation/Blender report) |
| `NOTIFICATION_EDITOR_PRE_SAVE` (Node, 4.7) | Run a check or bake just before save | Editor only | Good for auto-validate |

Tool-crash guardrails to write down: never free nodes in `_ready`/setters in a tool script; guard
runtime-only `_ready` work (building meshes, connecting to Game) with `if Engine.is_editor_hint(): return`;
headless tests do not set the editor hint, so editor code stays behind it (features-map caveat).

## 3. Sketches for our game

Common pieces for all five: the *scene reader* (`SceneLayoutReader`, a static function, node-free output)
instantiates `house.tscn` once at load (or in a test), walks it, writes the same dictionaries
`HouseParts.assemble()` builds (`colliders`, `furniture`, `crawl_spaces`, `lights`, `openables`,
`pianos`, `rooms`, `room_doors`, `machines`, `cabinet_spots`...), frees the instance, and hands them to
`FlatLayout._built(d, true)` (`flat_layout.gd:67`). Rules, Game, SockWorld, saves and the snapshot only ever
see the dictionaries and ids. Whether the reader can use `PackedScene.get_state()` (SceneState) to avoid
instancing is unverified (not fetched). The view side instantiates the same scene for display, so
guests load the same file as the host.

### 3.1 Door  (recommended: Interactable component, reader derives geometry)

```
Door_WorkshopLobby (Openable)           # StaticBody3D at the hinge; script Openable/RoomDoor
  Shape_Leaf (CollisionShape3D, BoxShape3D)   # replaces min/max boxes
  Model (instance of door.glb)                # the leaf mesh, or a swap
  %Latch (Marker3D)                           # optional: where the click sound sounds
exports: id=&"Door_WorkshopLobby", title="Door", door_kind=hinge, axis=Y, open_deg=90,
         swing_time=0.35, cue=door.tres(OpenKind), from_room: RoomVolume, to_room: RoomVolume,
         model: Model
connections: none needed in the editor. Code: installer connects `toggled` to the sound, `swung`/`stepped` to the Sock layout
```

JSON today (`room_doors[0]`): `name, node, room, other, level, hinge[x,y,z], axis, open_deg, min, max,
width, thickness, wall, along, into`. Mapping: `hinge` = node position, `axis` = export, `min/max` = the
shape (box = `position +/- size/2`), `width/thickness` = shape size, `into/along` = node basis, `room/other`
= the two exported `RoomVolume` ids, `level` = room's level, `node` = `id`. Reader writes the identical
record, so `FlatLayout.door_boxes()` and `Openable` rules do not change. The lambda
`op.swung.connect(...)` in `HouseInstaller` becomes a loop over group `"openables"`.

### 3.2 Cabinet with drawers  (recommended: spot marker in the room, `cabinet.tscn` instanced by the plan)

```
CabinetSpot_Hall (Marker3D, group "cabinet_spots")   # in the room; exports below
cabinet.tscn  (Cabinet)
  Model / Shell, Top, Segments/Seg0..Seg5            # authored visuals, max drawer modules
    Drawer_1 (CabinetDrawer : Openable)  title="Drawer", slide axis=Z, open_m
    ...
  %Dust (GPUParticles3D)  %Cue (AudioStreamPlayer3D)
exports on Cabinet: drawers: Array[CabinetDrawer] (in order), max_drawers=6
exports on CabinetSpot: spot_id=&"hall", default_collection=&"socks101", room: RoomVolume,
                        max_height=2.1, zone: SockSpot (the clear zone box)
```

JSON today: `cabinet_spots[i] {spot, collection, room, wall, pos[x,z], yaw, zone, max_height}` and `Room._ready`
loops `layout[i]` making `Cabinet.new()` at `flat.spot(at)` (`room.gd:210-262`). Mapping: marker
transform = `pos/yaw`; `spot_id` = `spot`; `default_collection` = `collection` (the run's `CabinetPlan`
overrides it, `cabinet_plan.gd`); `zone` box feeds `clear_zones`; the reader writes `cabinet_spots` so
`CabinetPlan.draw(flat, ...)` is untouched. The collection and drawer **count** are run state (stage growth,
`Cabinet.grow_to`, `show_rows`), so they stay in the rules; the scene only holds the maximum modules and
the view shows the first N. Why a marker and not a Cabinet in the room scene: which Collection stands at a spot is drawn
per run, and 9 of 17 are drawn, so Room instances `cabinet.tscn` at the markers it needs (as it does).
Wiring: `CabinetDrawer.interacted` stays code-wired (Rig.use -> shelve Command).

### 3.3 Lamp with a switch  (recommended: editor connection for local visual, Command for shared state)

```
FloorLamp (Prop root, Node3D)
  Model (floor_lamp.glb)
  Light (OmniLight3D)           # colour, energy, range, shadow set in the inspector
  Switch (Interactable)         # small shape at the switch; title="Switch", click_only
exports on root: light: OmniLight3D, switch: Interactable, on_by_day: bool, lit_level: RoomVolume (or derived)
editor connection (local visual): Switch.interacted -> FloorLamp._on_switch  (toggles Light.visible, plays a click)
code (if shared): installer connects Switch `used` -> Command "lamp_toggle(id)" -> Game state -> `FloorLamp.set_on(bool)`
```

JSON today: layout `lights[]` `{name:"LampLight_<piece>", kind:"lamp", room, pos}` written by `assemble()`
from the placement's `lamp` or the manifest `lamp, lamp_colour, lamp_energy, lamp_range`
(`house_parts.gd:78`); `Room._build_light()` (`room.gd:781`) creates the omnis and the day cycle drives them
(`_lamp_day`, `_lamp_level`, `light_cull_mask`). **No player switch exists today**, so this is new play:
the lamps follow the hour and the reveal of floors. The design fork is Question 5: a switch that only
changes the look needs no Command; a shared on/off needs Game state in the save and snapshot. Mapping: the
light's transform = `pos`; its `colour/energy/range` = node properties; the reader writes the same
`lights` record, and Room's day cycle iterates group `"room_lamps"` instead of `_lamps[]`.

### 3.4 Furniture with Sock spots  (recommended: authored markers plus an editor "Bake spots" button)

```
Sofa (Prop root, StaticBody3D?)         # or Node3D with a Colliders child
  Model (sofa.glb)
  Colliders (StaticBody3D) / Shape_* (CollisionShape3D x N)    # replaces manifest colliders
  Spots
    Top_Seat (SockSpot kind=top, size=1.6x0.5)                 # resting rect on the seat
    Crawl (SockSpot kind=crawl, gap=0.18, zone=&"under_sofa")  # Hiding spot under it
exports on root: piece: PropInfo (footprint, height, hide text, plan_spot), rug: bool, decor: bool
exports on SockSpot: kind, size, zone, baked: PackedVector3Array (written by the tool button)
tool button on root: "Bake sock spots" (sample the mesh, as tools/blender/house_furniture/tops.py does, into `baked`)
```

JSON today: `placements[i] {name, piece, room, level, pos[x,z], yaw}` plus manifest `footprint, height,
crawl_gap, hide, colliders[], tops[], spots[1401]`. `assemble()` writes `colliders` (boxes in house space),
`furniture` (footprint rects), `crawl_spaces`, `rugs`; `tops()` joins sampled spots into resting rects
(`house_parts.gd:245`). Mapping: placement = the instance's transform in the room scene (x,z,y,yaw);
`room/level` = containing `RoomVolume` (see 4.3, same rule as `_room_at`); `piece` = scene file name;
`rug/decor/furn/crawl` = exported bools/ids set per instance. Sock spots: either authored rects or the
sampled `baked` points; the tool button keeps today's automatic result but stores it in the scene next to
the mesh, ending the 1.2 MB manifest. Output records are unchanged; the reader emits them, SockWorld sees
rects and boxes.

### 3.5 Machine with hopper and button  (recommended: typed exports to part Interactables, markers for positions)

```
PairingMachine (Machine, Node3D)         # script: Machine (view); id for saves
  Body (Interactable)   title="Pick up the Sock pairing machine", click_only
  Model (pairing_machine.glb)
  Hopper (Interactable) title="Load the hopper"      shape 0.3 x 0.12 x 0.3
  StartButton (Interactable) title="Start", click_only   shape 0.09 x 0.09 x 0.05
  AutoButton (Interactable)  title="Auto"
  Markers
    %HeapFloor (Marker3D)  %DropFrom (Marker3D)  %HeapBounds (box Node3D)  %ButtonCap (Marker3D)
exports on Machine: id: StringName, body: Interactable, hopper: Interactable, button: Interactable, auto: Interactable,
                    heap_floor: Marker3D, drop_from: Marker3D, heap_bounds: Node3D, button_cap: Node3D, run_cap: float
editor connections: none that touch state. Visual: StartButton.interacted -> %ButtonAnim.play("press") only if purely cosmetic
code: Game.pairing state -> `Machine.show_state(...)` (call down); each part's `interacted` -> installer -> `Rig.use` -> Command
```

Today: `PairingMachine` builds `Station` parts by code (`_part`, `pairing_machine.gd:127`), tags them with
`set_meta("part", ...)`, and `part_of(station)` reads the meta (`:~150`); positions are constants
(`BUTTON`, `HEAP_HALF`, `HEAP_DROP`, `BUTTON_IN`). Replacing the meta with typed exports makes
`PairingMachine.of(station)` and `part_of()` a field comparison (`station == machine.hopper`). The
machine prototype the designer is building now can already follow this shape (parts are Interactables,
positions are markers). JSON: `machines[i] {kind, room, level, pos[x,y,z], yaw}` becomes the instance's
transform plus `kind` as the scene (`pairing_machine.tscn`, `vacuum.tscn`); `id` = index today, so keep a
stable `id` export because `saves.gd:76/96` rows pair with machines in order (check before switching
from index to id: a save compatibility question, Q7).

## 4. Level authoring

### 4.1 Scene structure

```
house.tscn (House root, Node3D, script: House)
  Shell (instance of shell.glb)           # generator-owned, not edited, not "editable children"
  Floors
    Basement (instance of floor_basement.tscn)
      Rooms (RoomVolume x N)
      Doors, Lights, Devices, Machines, Spawn, CabinetSpots
      Props/<RoomName>/... (instances of scenes/props/*)
    Ground (floor_ground.tscn), First, Attic, [Grotto/Drum]
  Exterior (instance), Elevator (instance)
```

One scene versus per floor versus per room: per floor is the middle. One scene is a merge-conflict
magnet (`.tscn` is text but one 70+-prop file churns); per room would make 17 files that are each
unique (nothing is reused) and lose the cross-room view (rooms link by `open_to`, doorways, lights'
`light_levels`). The rules already think in floors (`levels`, `level_at`, `LEVEL_LAYERS`, `reveal_level`,
`room.gd`), which matches. Open: whether the Grotto/Drum floors get their own scene (131 does this for
the Drum).

### 4.2 Walls versus props, and not overwriting each other

- Shell owner: Blender (`make_house.py`). It writes `shell.glb` and `generated/shell_layout.json`
  (levels, rooms, doorways, windows, the 692 colliders, ramps). A header string in the file and a
  `.gitattributes`/`README` say "generated".
- Hand owner: scenes for props, lights, doors' placement, devices, machines, spawn, cabinet spots.
  No scene stores a generated value; a generator never writes into a `.tscn`.
- Meeting point: the scene reader merges generated shell records and scene records. Overlap rules go in
  the validator: a prop's origin must lie inside a room; a prop's boxes must not intersect shell
  colliders beyond a margin; ids unique.
- If rooms move to `RoomVolume` nodes (phase 3 in 131), then Python stops writing `rooms` and
  doorways: one owner for each fact (Question 3).
- CLAUDE.md already says one agent at a time on each part of the house; scenes make this mechanical
  (one floor scene per agent, one prop scene per agent).

### 4.3 How room membership is found

Two options. **Geometry (recommended):** `RoomVolume` boxes (min/max/y/height as today); a prop's room is
the first volume containing its origin, same as `_room_at()` (`house_parts.gd:388`) and
`FlatLayout.room_at()` (`flat_layout.gd:439`). Parenting under `Props/<Room>` is just tree tidiness;
the validator errors when parent and containing volume differ. **Parenting:** the parent chain gives the
room; simpler to read in the tree but drifts silently when you drag a prop across a wall. The rules need
rect data at load either way (nodes are not rules), so volumes are flattened by the reader. Area3D
overlap is runtime physics and is not needed.

### 4.4 How the level designer checks their work

- **In the Scene dock:** configuration warnings on components ("Hopper not set", "Door has no Shape",
  "SockSpot has no size", "Prop outside every room").
- **One button:** `@export_tool_button("Validate house")` on the `House` root runs
  `HouseContract.problems(root) -> PackedStringArray` and prints to the Output dock; also run on
  `NOTIFICATION_EDITOR_PRE_SAVE` (4.7 Node reference) with `push_warning`.
- **Headless:** `tests/house_scene_test.gd` calls the same `problems()`, plus the diff test against
  today's JSON during the migration (131 phase 0). One function, three callers, so they never disagree.
- Checks: unique ids; every `@export` ref non-null and in the same house; every `piece` has a collider;
  every Openable has shape + model; every cue stem exists (what the sfx suite does now, `openable.gd:34-41`);
  each prop in a room; no two props overlap; save ids still resolve.

## 5. Hooking up in general: a short rule set

1. **Autoloads vs composition.** Autoload only a system that "tracks its own data, is globally accessible,
   and can exist in isolation" (`scene_organization.html`, 4.7). We have three (`Settings`, `UiSounds`,
   `Profily`): fine; do not add one for the house or the Game. Everything else is a scene or a node
   passed in by the parent. Installers become composition in `main.tscn` (131).
2. **Call down, signal up.** Parent sets or calls; child emits past-tense signals; siblings talk through
   an ancestor; use a Callable property instead of method-name strings (`scene_organization.html`).
3. **Groups for "all of a kind"**, stored in the scene (Node dock > Groups, 4.7 `groups.html`), global groups in
   Project Settings. Groups cannot be read by the node-free rules; the reader copies what rules need.
4. **Input Map** for every key (already `docs/llm/maintenance/issues/115`); no raw `KEY_*` in `_input`.
5. **Project Theme** `ui_theme.tres` (Project Settings > GUI > Theme) replaces `UiBits` overrides; per-control
   overrides stay for one-offs.
6. **Bus layout** `default_bus_layout.tres` replaces `Sfx.ensure_buses`; reverb and muffle in the layout.
7. **Project Settings** for global switches (layer names `[layer_names]` for `Layers`, GDScript warnings
   on, physics tick). Editor feature tags (`OS.has_feature("editor")`) gate debug-only nodes; the
   "Overrides" button in Project Settings makes per-feature overrides. I did not fetch the feature-tags page:
   treat the tag list and override behaviour as unverified here.
8. **Identity** is an exported `id: StringName`; tests check uniqueness; nothing saves a path.
9. **Authoring base classes are thin** (exports, warnings) and non-tool code does the work.
10. **Scene-contract test per part** (found by group), so a swapped model fails loudly.

## 6. What a reusable "nativize a Godot project" skill should say (<= 15 lines)

1. Wrap every model in a scene: typed root script, plain `Model` child instance; inherited scenes only when the model is the part.
2. Put colliders, pivots, lights, spots and attachment points in the scene as nodes or markers; generators write meshes only.
3. A thing the player aims at is a `CollisionObject3D` component with `@export` fields; plain helpers are `Node3D`/`Marker3D`.
4. Reference by typed `@export`, `%Unique` for internals, groups for sets; never rely on `find_child` or meta tags.
5. Editor-connect only presentation inside one scene; connect state and network in code from one installer.
6. Identity is an exported `id`; never a node path in saves or on the wire.
7. Rules and saves stay plain data; a scene reader flattens scenes to the same dictionaries at load.
8. `@tool` scripts are thin: every script they use must be `@tool`; guard runtime code with `Engine.is_editor_hint()`; set `owner` on nodes added in the editor.
9. Add `_get_configuration_warnings()` first, `@export_tool_button` second, gizmos last; skip inspector plugins.
10. One `problems(root)` function backs the Validate button, the warnings and the headless contract test.
11. Generated and hand-authored content never share a file; one owner per fact.
12. Geometry (volumes) decides membership; parenting is tidiness; the validator checks both agree.
13. Shared settings are Resources (definitions only); runtime state stays out of `.tres`.
14. Check the docs version and mark unverified claims; spike connections and inheritance before relying on them.
15. Migrate part by part with a diff test against the old data.

## 7. Questions for the designer

1. **Source of truth for the house.** (a) Scenes replace the JSON, read at load into the same data (recommended; 131's own lean); (b) scenes write JSON on save (two truths, drift); (c) keep JSON for the shell, scenes for props only (middle path, a good first step).
2. **Prop scene shape.** (a) Wrapper + plain `Model` child (recommended); (b) inherited from the glb (re-export changes can break it; keep for Avatar and Cat only).
3. **Who owns rooms and walls?** (a) Generator keeps the shell and rooms; scenes own everything else (recommended for phases 1 to 2); (b) rooms become `RoomVolume` nodes you edit and the generator keeps only walls and floors (phase 3).
4. **House split.** (a) One scene per floor under `house.tscn` (recommended); (b) one big scene; (c) one per room.
5. **The lamp switch.** (a) Only changes the look on the machine that clicks it (no Command, quick); (b) shared on/off saved and sent to everyone (recommended if lamps affect play, e.g. Cat or visibility; costs a Command and a save field).
6. **Placing props.** (a) FileSystem-dock drag plus a small catalogue folder structure (recommended; no code); (b) a custom palette dock plugin (nicer, code to maintain, the 4.7 docs I fetched do not describe a built-in palette).
7. **Ids and saves.** Machines pair with save rows by order today (`saves.gd:76`). (a) Add a stable `id` and migrate saves (recommended); (b) keep the order, which breaks the first time someone reorders machines in the editor.
8. **Sock spots.** (a) Bake from the mesh with a tool button and store in the scene (recommended; keeps today's result, drops the 1.2 MB manifest); (b) author every rect by hand (full control, much work); (c) leave computed at build time as now.

## Could not verify (from the 4.7 docs I could fetch)

- Manual page on scene inheritance and Editable Children: not found; the `.tscn` `[connection]` field
  format and what the editor stores for editable children, and behaviour of connections under
  instancing or inheritance: the `tscn.html` page lists headings only. Spike before relying on them.
- Dragging a `.tscn` into the 3D viewport, scene thumbnails in the FileSystem dock, "Instantiate Child
  Scene" shortcut, any scene palette: `using_the_viewport.html` is 404; not stated elsewhere.
- Whether the editor rewrites exported node references on rename or reparent.
- `Array[Node]`/`Array[Openable]` exports in the inspector; filtering of typed exports for non-tool classes.
- Whether the gizmo plugin script needs `@tool` (page silent; examples show it on the `EditorPlugin`).
- `PackedScene.get_state()` as an instance-free reader; MultiMesh editor population; lights and
  collisions with MultiMesh.
- Editor feature tags and Project Settings overrides (page not fetched).
- Node-count limits: no number in the docs; my figures are estimates from our placements.
- `autoloads_versus_internal_nodes.html` returned 404; autoload guidance is from `scene_organization.html`.

## Sources (Godot docs, `stable` = 4.7, fetched 2026-11-19)

- https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_exports.html
- https://docs.godotengine.org/en/stable/tutorials/plugins/running_code_in_the_editor.html
- https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html
- https://docs.godotengine.org/en/stable/getting_started/step_by_step/instancing.html
- https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html
- https://docs.godotengine.org/en/stable/tutorials/best_practices/scenes_versus_scripts.html
- https://docs.godotengine.org/en/stable/tutorials/scripting/scene_unique_nodes.html
- https://docs.godotengine.org/en/stable/tutorials/scripting/groups.html
- https://docs.godotengine.org/en/stable/classes/class_node.html (first 100,000 of 161,707 characters read)
- https://docs.godotengine.org/en/stable/tutorials/3d/using_gridmaps.html
- https://docs.godotengine.org/en/stable/tutorials/3d/introduction_to_3d.html
- https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html
- https://docs.godotengine.org/en/stable/tutorials/plugins/editor/3d_gizmos.html
- https://docs.godotengine.org/en/stable/tutorials/plugins/editor/inspector_plugins.html
- https://docs.godotengine.org/en/stable/tutorials/plugins/editor/making_plugins.html
- https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html
- https://docs.godotengine.org/en/stable/engine_details/file_formats/tscn.html
- Failed (404): `tutorials/editor/using_the_viewport.html`, `tutorials/best_practices/autoloads_versus_internal_nodes.html`
- Repo: `docs/research/godot-features-map.md`, `godot-rules.md`, `docs/llm/maintenance/issues/131-scenes-and-resources-plan.md`
