---
type: ticket
status: done
kind: build
area: core
feature: core
priority: now
created: 2026-11-23
done: 2026-11-23
blocked_by: [assets/07-furniture-devices, house/04-shell-details]
notes: ["Q2517; start after the M1/M2 batch merges (both touch house.tscn, zoo.tscn and the player)"]
terms: [Host, Guest, Mess, Session, Part]
---

# One level runtime scene that every level instances

The designer wants one scene holding the full game setup, so a new level is authored by adding only its geometry
and content (Q2517), by composition, not an inherited scene. Today `game/house/house.tscn` and `game/zoo/zoo.tscn`
each repeat the same top-level nodes: Player, Players, Avatars (MultiplayerSpawner), Session, Net, Parts, Socks,
Spots, ReturnSpot, Lying, Flights, FlightSpawner (and Environment, Sun, Picture, which stay per level).

## Design
- `game/level/level_runtime.tscn`: those nodes, their wiring (`node_paths`) inside it, and the `LevelNet` script
  (house/04's `game/net/level_net.gd`). It is sealed: no level overrides a node inside it (no editable children).
- Each level instances it once as a child. The level keeps only its own: geometry (Shell, Furniture, Stations),
  look (Environment, Sun, Picture, Lights) and a `Spawn` marker. The runtime finds the spawn through an exported
  NodePath on the instance (falling back to a child named `Spawn` of its parent).
- A level that needs different net behaviour (the zoo's `ZooNet`) gets it by an exported setting or Resource on the
  runtime instance, not by overriding a script; fold ZooNet's differences into that if small.
- Any code that finds these nodes by path or name is updated to find them through the runtime (a group or a static
  accessor), with no behaviour change.
- How to make a new level is written in `docs/architecture.md` (or its level subsystem file): "a new scene, its
  geometry, a Spawn marker, one instance of `level_runtime.tscn`". Add a tiny example: a test level of one floor box,
  used by the real-path case.
- Mind the known trap (lead memory): a Godot re-save can drop instance overrides. Diff `house.tscn` and `zoo.tscn`
  semantically (node list, properties) before and after, and keep the editor's format.

## Acceptance
- Real path: the house (F5), the zoo (`-- --zoo`) and the one-box test level each start, the player walks, and a
  Host plus Guest join and see each other, with none of the runtime's nodes outside `level_runtime.tscn`.
- Every existing suite passes unchanged (`run.sh` full, since scenes change); co-op net shots still start.
- No look change: a before/after still of one house room and the zoo's spawn is identical.

## Open follow-ups
- [later] `game/debug/mess_bench_level.tscn` (the Mess bench, a debug level) still carries its own Socks and
  Mess: not one of the levels this ticket names; it could take the runtime too.
- [later] `mess_settle:real_path_3` came out FLAKY twice in this branch's runs ("no Sock hot"); the ledger has the same
  case failing on another branch the same morning ("no Sock jitter") and its family since 2026-11-22 (core/49):
  not this change's, but still open.

## Built log

### 2026-11-23
- Changed: the full game setup (Player, Players, Avatars, Session/Roster, Net, Parts, Socks with Mess, Hands,
  Knockdowns, Coins, Spots, Lying, Flights, FlightSpawner) is one sealed scene, `game/level/level_runtime.tscn`
  (`LevelRuntime`); the house, the zoo and a new one-box example level instance it once as `Runtime` and set only
  its exports (spawn, return spot, Mess bounds, the zoo's Hands tuning, Upgrades, the corner's word). ZooNet is
  folded into LevelNet (`place`, the PLACES_ITSELF group). Code and tests find the nodes with `LevelRuntime.of()`;
  `owner` checks read `LevelRuntime.level_of()`. Part ids of the runtime's Parts are now `Runtime/Socks/...`.
  The levels keep their own `Spawn` and `ReturnSpot` markers (a place is the level's).
- Files: game/level/, game/house/house.tscn, game/zoo/zoo.tscn, game/net/level_net.gd, game/zoo/stations.gd,
  tests/level_test.gd, tests/*, tools/shot_hooks.gd, tools/house_from_old.py, docs/architecture.md
- Verified: run.sh --touched (every suite): PASS 17673 checks, 483 cases (FLAKY mess_settle:real_path_3, see
  follow-ups); net_shot host and guest join in the house; before/after stills
  builds/review-level-runtime/level-runtime-before-after.png, 0 px differ in all three.
- Merged: 3231d4fe (2026-11-23, branch core/51-level-runtime-scene)
