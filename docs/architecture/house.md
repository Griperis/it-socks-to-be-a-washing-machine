# The house level

`game/house/house.tscn` (house/04, Q2503, Q2509-Q2512): the game's level and the project's main scene
until menus exist. Shell, furniture, Cabinets and the starting Mess: F5 plays the core loop (house/05).

## What it holds

- `Shell`: `game/house/shell.tscn` at the origin, the house's frame (x east, z south, the outer walls'
  centre lines on x 0..10.5, z 0..8.5, floors at y -3, 0, 3, 6). Written by `tools/house_shell_build.gd`
  (`docs/architecture/house-kit.md`). Nothing outside the house: no ground, lawn or street (Q2503, Q2511).
- `Furniture/<Name>`: the old house's 66 placements of its four floors (the old layout's `placements`,
  repeats numbered as the old game did: `Chair2`), each an instance of `game/furniture/<piece>.tscn`.
- `Lights/Ceiling_<room>`: a ceiling light per old room light marker (18), and `Lights/Lamp_<piece>` for
  the floor lamp's and the nightstand's lamps. The old values (room.gd `_build_light`): colour
  (1, 0.88, 0.7); ceiling lights energy 1, range 6, shadow on (blur 2, bias 0.05), 8 cm under the marker;
  lamps energy 0.7, range 3, no shadow. `Lights` carries `house_lights.gd` (`HouseLights`, house/06): each
  light's metadata `lit_levels` (level indices; a stair room's light its own and the next) sets its cull mask
  (render layers 16-20, one per level); at load it puts each drawn thing of the Shell, Furniture, Cabinets
  and Doors that lies within one level on that level's layer (things spanning levels, Socks and players stay
  on layer 1, lit by all). By day (`night` false) only the lights that light the basement alone are visible;
  `night = true` shows all. The old day cycle (the hour, dusk fade, shades' glow) is not ported.
- `Doors/FrontDoor`, `Doors/GarageDoor`: `shut_front_door.tscn` and `shut_garage_door.tscn`, plain leaves (a
  StaticBody3D, no Part) in the doorways' wall line, so nothing can open them and nobody walks out (Q2514), until
  the exterior ticket brings the door entities. Their leaves are the old front door's (teal, two raised panels, a
  brass knob inside) and the old garage door's (ribbed, steel handle, stiffening frame), made by `tools/door_build.gd`
  with the room Doors' leaf (house/08, Q2571).
- `Doors/<Doorway>`: the eight room Doors of the old house (house/08, Q2568: none in the ground floor's two open
  doorways): `WorkshopLobby`, `LaundryLobby`, `BoilerLobby`, `LobbyGarage` (basement), `OfficeLanding`,
  `BedroomLanding`, `BathroomLanding`, `KidsLanding` (first floor). Each is `game/entities/door/room_door.tscn` or
  `room_door_flipped.tscn` (the Door entity with the real leaf, `looks_leaf*.tscn`; `door.tscn` keeps its graybox Looks for the zoo's other stations) (the two hands: the hinge at the leaf's low or high end along its wall), turned to its doorway
  and standing flush with its room's face of the 0.12 m wall, the leaf 0.866 x 2.075 x 0.04 m in the kit's 0.9 x 2.1 m
  opening. Placed `open = true` (an override on each `Openable`). `Doors/DoorShuts` (`DoorShuts`, the last child,
  with `door_shut_rules.tres`: share 0.333, `keep_open` LaundryLobby and LobbyGarage, `seed` 1, `new_seed_each_start`)
  sets `open = false` on the picked third (3 of 8: a Fisher-Yates shuffle of the names not kept open from the seed)
  when the level enters, before the Mess lays and before anything binds, on every machine; a Guest's snapshot then
  replaces each Door's state whole. They stand shut with no swing and no sound (Q2570).
- The zoo's noon light: `Environment` (`game/look/noon_environment.tres`), `Sun`, `Picture`.
- `Cabinets/<Spot>`: the old eight Cabinet spots (the old layout's `cabinet_spots`, moved to the plan as a piece
  is), each its old default Collection, wired to the runtime's `Hands` and `Coins` (house/05); each unlocks with its
  `unlock_stage` (core/91: the laundry 1; the garage, under its `DustSheet`, the kitchen and the living room 2; the kids'
  3; the loft's 4).
- `Run` (core/91, `docs/architecture/stages.md`): the run with `house_stage_plan.tres` and the four Machine Parts under
  `Run/MachineParts`; `FloorLocks/Ground`, `First` (doors) and `Attic` (the gate) shut the floors not open yet; the
  washer's `PartSlot` takes a Part.
- `Washer`: the washing machine (core/86) at the old washer, with its `PartSlot` (core/91).
- `SockGenerators/<Floor>`: the places of each floor's Socks (house/05, `docs/architecture/sock-generator.md`), with
  their `floor` (0 to 3) and `lays_at_start` off: the run's Stages lay each floor's Socks (core/77, core/91); the
  tests' `SockGenerator.start_all` lays the old starting Mess (the stage's Pairs in Heaps and the stair trails).
- `Spawn` at the old spawn (room.gd `spawn_pos`, `spawn_yaw`: the laundry, facing its doorway);
  `ReturnSpot` there too (unturned).
- `Runtime`, the one instance of the level runtime (`game/level/level_runtime.tscn`, core/51, Q2517;
  `docs/architecture.md` "A level"): the player, the shared-state path (`Socks/Mess`, `Hands`, `Knockdowns`,
  `Coins`, `Parts`, `Players`, `Avatars`, `Session/Roster`, `Spots`, `Lying`, `Flights`, `FlightSpawner`) and
  `Net`, a `LevelNet` (`--host`, `--join=`, `--profile=`; alone it is a Host of one). The house sets only
  its `mess_bounds` and `load_screen` (house/09: its Socks laid a slice per frame behind the `LoadingScreen`) on it.

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
