# Update a model that is already in the game

## What this is for

You want to change how a Sock, a ball, a Cabinet, a piece of furniture or a house kit piece looks: a new shape, a fix, a different mesh. This page tells you, for each family, where the source is, where the file goes, what to keep when Godot imports it, and which zoo station shows it. For a model that is not in the game yet, read `models-pipeline.md`.

## The rule for all families

- The model file is a `.glb`. Godot shows it through a **Looks scene** (a small `.tscn` named `looks_<something>.tscn`). The game's rules never touch the model, so you can swap it without breaking anything.
- Each Looks must keep the node names and animation names listed in the `looks_contract.json` in its folder. If you rename a node in Blender, the contract check fails.
- Blender scripts only build meshes. Where things stand, collision, Sock spots and settings live in Godot scenes you edit by hand.
- Do not name a node in Blender with an ending Godot reads as a command: `-col`, `-colonly`, `-convcolonly`, `-wheel`, `-rigid`, `-loop`, `-cycle`, `-noimp`, `-navmesh`, `-occ`, `-vehicle`. `kit/tools/asset_lint.py` finds these.
- Run `python3 kit/tools/asset_lint.py` after any model change. It prints `PASS asset_lint` or one line per problem. It also checks every Looks against its contract.

## Edit a model at its source (Socks, balls, Cabinets, furniture)

Every model of these four families has a Blender source in `assets_src/blender/<family>/` and a script in
`assets_src/generate/<family>/` that builds it. Both make the same `.glb` as the one in the game today (checked
for every model, `assets_src/generate/README.md`). Pick one way per change:

- **By hand in Blender:** open the `.blend`, change it, save. Then export it:
  `assets_src/generate/export.sh --out /tmp/check <asset>` writes the new `.glb` into a scratch folder, and
  `python3 assets_src/generate/glb_compare.py /tmp/check/assets/<family> assets/<family>` lists what changed.
  When it is what you meant, run it again without `--out` to write over the game's file. `<asset>` is its name in
  `assets/blender_assets.json` (`sock_crew`, `ball_crew_plain`, `cabinet_food`, `sofa`).
- **In the script:** change the numbers or the code in `assets_src/generate/<family>/`, then
  `blender -b -P assets_src/generate/build.py -- <family> --only <name> --out /tmp/check` and compare the same way.
  Add `--save` to also rewrite the `.blend` from the script. A hand edit in that `.blend` is lost when you do.

Blender is the kit's pinned one: `kit/tools/blender.sh --fetch` installs it. After the new `.glb` is in, carry on
with "Replace the file in the editor" below.

## Replace the file in the editor (all families)

1. Export the new `.glb` over the old one, same file name, same folder.
2. Switch to Godot. It re-imports on its own. Do not rename the file: the Looks scenes point at it by name and by uid.
3. Open the Looks scene. If a node you edited by hand (a Marker, a collision) is gone, put it back.
4. Run `python3 kit/tools/asset_lint.py`.
5. Look at the station (below) and run the suite (below).

## Socks and balls

- **Source:** the four shapes are in `assets_src/blender/sock/socks.blend` (roots `sock_ankle`, `sock_crew`, `sock_tube`, `sock_chunky`), the nine balls in `assets_src/blender/sock/sock_balls.blend` (roots `ball_<cuff>`). The scripts are `assets_src/generate/sock/make_socks.py` and `make_sock_balls.py`: `blender -b -P assets_src/generate/build.py -- sock`. Export one from the `.blend` with `assets_src/generate/export.sh sock_crew` (or `--family sock`). The 13 `.glb` are still the old game's files; both ways reproduce them.
- **The `.glb`:** `assets/sock/<shape>.glb` (`ankle`, `crew`, `tube`, `chunky`) and `assets/sock/ball_<cuff>.glb` (`ankle`, `chunky_fold`, `crew_cape`, `crew_ears`, `crew_plain`, `crew_rolled`, `crew_scallop`, `crew_stripe`, `tube_rib`). The prints picture is `assets/sock/prints.png` (12 by 18 cells of 256 px).
- **Import settings to keep:** in each `.glb.import`, `import_script/path="res://game/sock/model_lods_import.gd"` and `meshes/generate_lods=false`. The script folds your hand-made LODs into one mesh. Name them `<mesh>_lod1`, `<mesh>_lod2` beside the close-up mesh `<mesh>`. Budgets are 320 triangles for a Sock and 540 for a ball. Do not turn on Godot's own LOD generation.
- **Skeleton:** the four shapes share the bones `Cuff`, `Leg`, `Heel`, `Foot`, `Toe`. Keep those names: the cloth (`game/sock/sock_cloth.gd`) hangs on them.
- **Looks scenes:** `game/sock/looks_<shape>.tscn` (4) and `game/sock/looks_ball_<cuff>.tscn` (9). Each has `Body` (the instanced `.glb`), `Cloth`, `Outline`, `AnimationPlayer`.
- **Contract:** `game/sock/looks_contract.json`: nodes `Body`, `Outline`, `AnimationPlayer`; animations `lying`, `held`, `aimed`.
- **Which Design uses which shape or ball:** `game/sock/sock_looks.tres` (open it in the inspector). It also holds how the pattern shader fits each model (`fits`). If a new shape has another UV layout, adjust its fit there.
- **Material:** none from the library. The one shader `game/sock/sock_pattern.gdshader` paints every Sock from the Design (colour, pattern, print). Do not put materials on the model.
- **Collision:** none in the model. A lying Sock has two boxes made by the game, a flying one has `game/sock/flight.tscn`. A new shape does not change them (open follow-up: today every shape uses the crew box).
- **Zoo station:** `SockLooks` (`game/zoo/stations/sock_looks.tscn`). It shows every Collection's Sock, every pattern and every ball.
- **Suite:** `kit/tools/run.sh --only=sock_looks`.

## Cabinets

- **Source:** `assets_src/blender/cabinet/cabinet_<collection>.blend`, one per Collection, root `cabinet_<collection>` with `base`, `segment`, `drawer` (and its `slot_01` to `slot_25`) and `top`. The script is `assets_src/generate/cabinet/make_cabinets.py`, with the front art painted by `cabinet_art.py`: `blender -b -P assets_src/generate/build.py -- cabinet --only <collection>`. Export from the `.blend` with `assets_src/generate/export.sh cabinet_<collection>`. The old `.blend` files still hold two collider boxes (`shell-convcolonly`, `drawer_front-convcolonly`) that the game ignores; the script no longer makes them. The 17 `.glb` are the old game's; both ways reproduce them, front art included.
- **The `.glb`:** `assets/cabinet/<collection>.glb` with its meshes saved as `assets/cabinet/<collection>_<part>.res` and the front art `assets/cabinet/<collection>_<name>_front_art.png`.
- **Import settings to keep:** `meshes/generate_lods=true`, no import script. The `.glb.import` saves each mesh to its `.res`; do not undo that.
- **Looks scenes:** two sets, one file per Collection. The Cabinet: `game/entities/cabinet/looks_<collection>.tscn` with `Base`, `Segment1`, `Segment2`, `Segment3`, `Top`. The drawer: `game/entities/drawer/looks_<collection>.tscn` with `Slide` (an AnimatableBody3D, front plus collision `Front`), `Outline`, and `Slot01` to `Slot25` (Marker3D points where Pairs are shelved), animations `open` and `shut`.
- **Contracts:** `game/entities/cabinet/looks_contract.json` and `game/entities/drawer/looks_contract.json`. Never delete or rename a `Slot`.
- **The Collection picks its Looks by name:** a Cabinet takes `looks_<collection>.tscn` from its Collection. A Collection with no file keeps the Looks in the scene.
- **Collision:** the drawer's `Front` and the animation moving `Slide`. Keep `Slide` an AnimatableBody3D and the AnimationPlayer on physics frames. The Cabinet's own footprint is in `game/entities/cabinet/cabinet.tscn`, not in the model.
- **Materials:** the model's own, inside the `.glb` (the shared library is not mapped on them in `main`).
- **Zoo station:** `Cabinet` (`game/zoo/stations/cabinet.tscn`): one real Cabinet per Collection, made from the catalogue at load.
- **Suite:** `kit/tools/run.sh --only=cabinet_looks`.

## Furniture

The 67 pieces and the shared material library (`docs/architecture/furniture.md`).

- **Source:** `assets_src/blender/furniture/<piece>.blend`, root `<piece>` with `Body` and its moving parts (`Door`, `Drawer_1`, ...), written by the script; the old game kept no `.blend` for them. The script is `assets_src/generate/furniture/`: `fkit.py` (the piece builder), `kit.py` (the look) and one function per piece in the group files (`basement.py`, `ground.py`, `first.py`, `attic.py`, `plants.py`, `grotto.py`; search for `@piece("<piece>"`). Run `blender -b -P assets_src/generate/build.py -- furniture --only <piece>`, or export the `.blend` with `assets_src/generate/export.sh <piece>`. The `.glb` in the game came from the old exports, cleaned by `tools/furniture_from_old.py` (collision nodes taken out); both ways reproduce them.
- **The `.glb`:** `assets/furniture/<piece>.glb`. The `.glb.import` saves each mesh to `assets/furniture/meshes/<piece>_<node>.res` and maps each material to a file in `game/materials/` (`use_external`). Keep that mapping: it is how the shared colours reach the piece. A material name that is new to the library gets its own `.tres` in `game/materials/`.
- **Scene per piece:** `game/furniture/<piece>.tscn`, a StaticBody3D on the house layer. The scene is yours to edit; do not run the build script again over a piece you changed (it skips existing scenes unless forced).
- **Looks:** `game/furniture/looks/looks_<piece>.tscn`, contract `game/furniture/looks/looks_contract.json`. Doors and drawers have their own Looks in `game/furniture/parts/looks_<piece>_<opening>.tscn`, contract `game/furniture/parts/looks_contract.json`, with `open` and `shut` animations.
- **Collision:** the `Shape<n>` nodes under the root, made from the old collision. After a shape change, adjust the `Shape` nodes by hand. The Sock spots (`Spots/Top<n>`) and the `Inside` box are Godot nodes, not part of the model.
- **Materials:** the shared library `game/materials/<name>.tres`. Edit a colour once in the inspector and every piece with that name changes. The zoo station `Materials` shows them all on spheres.
- **Zoo stations:** `Furniture` (`game/zoo/stations/furniture.tscn`, every scene of `game/furniture/` in rows) and `Materials`.
- **Suites:** `kit/tools/run.sh --only=furniture` and `--only=materials`.
- The furniture's devices (the old moving or electric parts) are a later ticket, not built.

## House kit pieces

- **Source:** no Blender. The pieces are made from numbers by `tools/house_kit_build.gd` using `game/house/kit/house_kit_sizes.tres`. There is no `.glb` for them.
- **Files:** `game/house/kit/pieces/*.tscn` (85 pieces), their meshes in `game/house/kit/meshes/*.tres`, the colour library in `game/house/kit/materials/*.tres`, the plank and tile pictures in `game/house/kit/textures/`.
- **Never edit a piece, a mesh or a room file by hand.** Change the sizes (or the build script) and rebuild. See `house-kit.md`.
- **Materials you may edit by hand:** the files in `game/house/kit/materials/`. The build script never overwrites one that exists.
- **LODs:** none.
- **Collision:** a `Body` of boxes on layer 1 (the house layer), made by the script.
- **Zoo station:** `HouseKit` (`game/zoo/stations/house_kit.tscn`), a line-up of every piece in `pieces/`; the two old-house stations `old_house_a.tscn` and `old_house_b.tscn` show the pieces in a whole house.
- **Suites:** `kit/tools/run.sh --only=house_kit` and `--only=old_house`.

## Checking it worked

- `python3 kit/tools/asset_lint.py` prints `PASS asset_lint`.
- Open the zoo (`game/zoo/zoo.tscn`), walk to the station of the family and see the model in its place, not black, not pink, not at the wrong size.
- The suite of the family ends with `PASS`.
- To see the old and new side by side, ask for a still (the shot sets live in `tools/shots/sets/`, for example `cabinets.txt`).

## Gotchas

- Renaming the `.glb`, or a node a contract names, breaks the Looks. If you must rename, change the contract and every Looks of the family together.
- Sock `.glb` imports must keep `model_lods_import.gd`. A test run mirrors the project without `.import` files, so in a test or a shot the Sock LODs are folded at run time instead and print detail looks softer. That is expected.
- Godot re-saving a scene with no real change is fine; say so when you hand the work over, so it is saved as an "editor format" change.
- Look changes (a new look for an old model) are their own piece of work and wait for your go on a still.
- Export with `assets_src/generate/export.sh`, not `kit/tools/blender/export.sh`: the kit's one looks for `assets/blender_assets.json` in the wrong folder today and does not know the Sock budgets (open follow-up of `docs/llm/assets/issues/08-model-sources.md`).
- `export.sh` prints the kit's contract report for each model. For furniture it lists the node names (`Body`, `Door_L`: the kit wants lower case) and, for 18 old pieces, more than 8 materials. That is advice only; the export goes ahead.
- The old house shell's scripts are in `assets_src/generate/house/` to read, not to run (its `README.md` says why). The house kit pieces have no Blender source.

Sources: Q2151, Q2152, Q2153 (port rules), Q2400 (the sources); tickets `docs/llm/assets/issues/01` to `04` and `08`, `assets_src/generate/README.md`, `docs/llm/house/issues/01` to `03`; `docs/architecture/furniture.md`, `materials.md`, `house-kit.md`.
