# Bring a new model into the game

## What this is for

You made a new model in Blender (a new prop, furniture piece, Cabinet front, or a Sock shape) and want it in the game, on an entity, and visible in a zoo station. The path is: Blender, `.glb`, import, Looks scene, entity, station. To change a model that is already in, read `models-update-a-model.md`.

## The pattern: behaviour plus a swappable Looks

An entity (a door, a cupboard, a drawer, a Cabinet) is one scene with two sides:

- **Behaviour:** the root, its collision for play, and `Part` nodes (such as `Openable`) that hold the state. No model in it.
- **`Looks`:** a child scene named exactly `Looks`. It only shows. To use your model you delete the child `Looks` and instance your Looks scene in its place, named `Looks`.

The rules, the tests and every placed copy stay as they are. The example is `game/entities/cupboard/`: `cupboard.tscn` plus `looks_graybox.tscn` and `looks_alt.tscn`.

## Step 1: model in Blender

1. Origin at the floor centre of the object, front toward +Z (furniture rule). One unit is one metre.
2. Name every part that moves for what it is (`Door`, `Drawer_1`, `Lid`, `Slide`, `Hinge`). Names are what the contract and the animation find.
3. Do not end any node name in an import hint (`-col`, `-colonly`, `-convcolonly`, `-wheel`, `-rigid`, `-loop`, `-cycle`, `-noimp`, `-navmesh`, `-occ`, `-vehicle`; any case; digits after are ignored). Godot would turn the node into something else. `kit/tools/asset_lint.py` finds it.
4. Give each mesh a material whose name is a name from the shared library (see Materials below), so Godot maps it.
5. Sock shapes only: use the bones `Cuff`, `Leg`, `Heel`, `Foot`, `Toe`. Hand-made LODs are named `<mesh>_lod1`, `<mesh>_lod2` beside `<mesh>`.
6. Keep the Blender script (if any) to meshes only. Where it stands, collision and spots are Godot's job.
7. Triangle budgets per class, from `kit/tools/blender/asset_checks.py`: prop 2000, furniture 8000, appliance 12000, large 20000; at most 8 materials, textures at most 2048 px and a power of two.

## Step 2: export and import

1. Put the source in `assets_src/blender/<name>.blend` and list it in `assets/blender_assets.json` (class and number of collider meshes). Today the file lists nothing.
2. Run `kit/tools/blender/export.sh --check <name>`, then `kit/tools/blender/export.sh <name>`. The `.glb` lands in `assets/<name>/<name>.glb`. A good run prints `EXPORT-OK`.
3. Open Godot. It imports the `.glb` and writes `<name>.glb.import` and a `.uid`. Both are kept in git.
4. In the import dock, use the family's settings (see `models-update-a-model.md`). For a Cabinet-like model: save meshes to `.res` files, turn LOD generation on. For a Sock-like model: set the import script `res://game/sock/model_lods_import.gd` and LOD generation off.

## Step 3: the Looks scene

1. In the file dock: right-click the `.glb`, New Inherited Scene, or make a Node3D and instance the `.glb` under it, named `Body`.
2. Add what the contract needs. Open `looks_contract.json` in the entity's folder: it lists the node names and animation names every Looks of that entity must have, for example the cupboard needs `DoorPivot`, `Outline` and the animation `open`.
3. Moving parts: the node the animation moves must itself be an **AnimatableBody3D** with its collision shape under it (like `DoorPivot`, `Hinge`, `Slide`). Put a **Node3D `Outline`** and an **AnimationPlayer** on the Looks. Set the AnimationPlayer's callback mode to physics. A body under a plain animated Node3D does not push things.
4. Animations: make `open` (and `shut` if the contract lists it) in the AnimationPlayer. The state is the truth and the animation only shows it; do not move the part from code.
5. Save it as `looks_<name>.tscn` in the entity's folder (`game/entities/<entity>/`). The file name must start with `looks`, or the contract check does not see it.
6. If the entity needs a new node name that is not in the contract yet, add it to `looks_contract.json` and add it to every other Looks of that entity too.

## Sock spots and slots

- A **SockSpot** (`game/mess/sock_spot.gd`, a Marker3D) is where a loose Sock lies when a level starts. You place it in the editor under the `Spots` node of a station or level. Set `design` to a Design id from `game/sock/designs.tres`. Put the marker's bottom on the surface, lying flat.
- A **slot** is a Marker3D inside a drawer Looks (`Slot01` to `Slot25`) where shelved Pairs show.
- Furniture pieces (branch `assets/04-furniture-and-materials`, not in `main` yet) carry `Spots/Top<n>` boxes: areas where a Sock may rest, on no collision layer.

## Collision layers

Set in the Inspector under Collision. The numbers are from `game/mess/mess.gd`:

| Layer | Value | What |
|---|---|---|
| 1 | `LAYER_HOUSE` | the house, furniture, kit pieces, floors, doors, drawer fronts |
| 2 | `LAYER_FLIGHT` | a Sock in the air |
| 4 | `LAYER_LYING` | a Sock lying (made by the game, not by you) |

A house thing sits on layer 1 with mask 0. Moving parts (AnimatableBody3D) the same. Spot and Inside areas are on no layer. Do not put a model's collision on layers 2 or 4.

## Materials

- House kit colours: `game/house/kit/materials/*.tres` (25 files, for kit pieces only).
- Furniture and everything else: the shared library `game/materials/<name>.tres`, one StandardMaterial3D per name. It is only on the branch `assets/04-furniture-and-materials`; not in `main` yet.
- A model uses a library material by its `.glb.import` mapping (`use_external`), not by a copy. To change a colour, edit the `.tres` in the inspector.
- Sock and ball models use none: the Sock shader paints them.

## Step 4: put it on the entity

1. Open the entity scene (for example `game/entities/cupboard/cupboard.tscn`).
2. Delete the child `Looks`. Instance your Looks scene and name it `Looks`.
3. Do not touch the root, the `Openable` or the collision for the footprint. Every Looks has to fit inside the entity's footprint.
4. A Cabinet or drawer picks its Looks by Collection name: `looks_<collection>.tscn`. Make that file and the Cabinet uses it.

## Step 5: a zoo station

Each feature has one station: one file `game/zoo/stations/<feature>.tscn`. Copy `game/zoo/stations/openables.tscn` for the shape: a Node3D root, `Pad`, a `Name` Label3D, then your entities as instances of the game's own scenes.

1. Make the file and put instances of the real entities on the pad. Variants are overrides on the instance.
2. Instance the station under `Stations` in `game/zoo/zoo.tscn` and drag it to a free spot on the 0.5 m grid. (The zoo suite fails for a station file nobody instanced.)
3. The root's name is the station's name. Do not rename it after others play your build.
4. A station that shows game data (every Sock, every Cabinet, every sound) builds itself from that data when it loads. Do the same: a new entry should appear with no other change.

## Checking it worked

- `python3 kit/tools/asset_lint.py` prints `PASS asset_lint`.
- Run the zoo, walk to your station, and use the thing: press E on a door or drawer and see it move and push.
- Run the entity's suite, for example `kit/tools/run.sh --only=cupboard`, `--only=cabinet_looks`, `--only=zoo`. Each ends with `PASS`.
- Before the first still is looked at, a new look waits for your go.

## Gotchas

- A Looks missing a node or animation of the contract fails `asset_lint`. Fix the Looks, or change the contract for every Looks of that entity.
- A moving part that is not an AnimatableBody3D shows the animation but does not push Socks or the player.
- The Looks file must be named `looks...` and sit in the entity's folder (or its `looks/` subfolder).
- A Sock that must be saved or shared lives on a Part, never in the Looks.
- Never hand-edit a file in `game/house/kit/pieces/`; see `house-kit.md`.
- Files stay in the Godot editor's own format with their `uid=` lines and `.uid` files; let the editor write them.

Sources: `kit/skills/zoo-design/SKILL.md` parts A and B; `kit/tools/asset_lint.py`; `kit/tools/blender/asset_checks.py`; Q2151, Q2152, Q2337.
