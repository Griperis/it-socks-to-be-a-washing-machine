# The house level

`game/house/house.tscn` (house/04, Q2503, Q2509-Q2512): the game's level and the project's main scene
until menus exist. Shell and furniture only: no game functions yet (M3 brings the core loop in).

## What it holds

- `Shell`: `game/house/shell.tscn` at the origin, the house's frame (x east, z south, the outer walls'
  centre lines on x 0..10.5, z 0..8.5, floors at y -3, 0, 3, 6). Written by `tools/house_shell_build.gd`
  (`docs/architecture/house-kit.md`). Nothing outside the house: no ground, lawn or street (Q2503, Q2511).
- `Furniture/<Name>`: the old house's 66 placements of its four floors (the old layout's `placements`,
  repeats numbered as the old game did: `Chair2`), each an instance of `game/furniture/<piece>.tscn`.
- `Lights/Ceiling_<room>`: a ceiling light per old room light marker (18), and `Lights/Lamp_<piece>` for
  the floor lamp's and the nightstand's lamps. The old values (room.gd `_build_light`): colour
  (1, 0.88, 0.7); ceiling lights energy 1, range 6, shadow on (blur 2, bias 0.05), 8 cm under the marker;
  lamps energy 0.7, range 3, no shadow. All lit: the old day cycle (lamps off by day but the
  basement's) and the per-floor light layers are not ported.
- `Doors/FrontDoor`, `Doors/GarageDoor`: `shut_front_door.tscn` and `shut_garage_door.tscn`, plain leaves (a
  StaticBody3D, no Part) in the doorways' wall line, so nothing can open them and nobody walks out (Q2514), until
  the exterior ticket brings the door entities.
- The zoo's noon light: `Environment` (`game/look/noon_environment.tres`), `Sun`, `Picture`.
- `Spawn` at the old spawn (room.gd `spawn_pos`, `spawn_yaw`: the laundry, facing its doorway);
  `ReturnSpot` there too (unturned).
- `Runtime`, the one instance of the level runtime (`game/level/level_runtime.tscn`, core/51, Q2517;
  `docs/architecture.md` "A level"): the player, the shared-state path (`Socks/Mess`, `Hands`, `Knockdowns`,
  `Coins`, `Parts`, `Players`, `Avatars`, `Session/Roster`, `Spots`, `Lying`, `Flights`, `FlightSpawner`) and
  `Net`, a `LevelNet` (`--host`, `--join=`, `--profile=`; alone it is a Host of one). The house sets only
  its `mess_bounds` on it.

## Where it came from

`tools/house_from_old.py` wrote it once from the old layout (run it with `--print` to see the numbers;
`--force` writes it again and loses hand edits). The move to the re-gridded plan: each old room's inside
faces to the plan's; a piece keeps its distance to the nearer wall of its room on each axis, a ceiling
light its place across the room in proportion; heights over a floor are the old ones. From then on the
scene is edited by hand in the editor.

## Gotchas

- Nothing in it may refer to `game/zoo/` (Q2409): `tests/house_test.gd` h01 walks its dependencies.
- The zoo stays playable: `-- --zoo` (GameCli) or F6 on `zoo.tscn`. Shots default to the zoo; a house shot
  gives `--scene=res://game/house/house.tscn` (the `house` set).
- The old openables' names (`names` in the old placements: the fridge's `Fridge` and `Freezer`) are not
  carried over: the openings keep the furniture scenes' node names.
