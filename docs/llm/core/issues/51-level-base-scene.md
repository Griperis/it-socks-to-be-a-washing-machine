---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: core
priority: now
created: 2026-11-23
done:
blocked_by: [assets/07-furniture-devices, house/04-shell-details]
notes: ["Q2517; start after the M1/M2 batch merges (both touch house.tscn, zoo.tscn and the player)"]
terms: [Host, Guest, Mess, Session, Part]
---

# One base level scene that every level inherits

The designer wants one base scene holding the full game setup, so a new level is authored by adding only its
geometry and content (Q2517). Today `game/house/house.tscn` and `game/zoo/zoo.tscn` each repeat the same top-level
nodes: Environment, Sun, Picture, Player, Players, Avatars (MultiplayerSpawner), Session, Net, Parts, Socks, Spots,
ReturnSpot, Lying, Flights, FlightSpawner.

## Design
- `game/level/level.tscn`: a Godot inherited-scene base (Scene > New Inherited Scene) with those nodes, their wiring
  (`node_paths`) and the `LevelNet` script (house/04's `game/net/level_net.gd`). Empty groups for what each level adds,
  e.g. `Shell`, `Furniture`, `Lights`, `Stations` and a `Spawn` marker.
- `house.tscn` and `zoo.tscn` become inherited scenes of it. Each keeps only what is its own: the house's shell,
  furniture, lights and spawn; the zoo's floor, grid note, stations and spawn. A level that needs a different net
  script (`ZooNet`) overrides the script on `Net`.
- Any code that finds these nodes by path or name finds them by the same paths as before (no behaviour change).
- How to make a new level is written in `docs/architecture.md` (or its level subsystem file): "New Inherited Scene
  from `game/level/level.tscn`, add geometry under Shell, place a Spawn". Add a tiny example: a test level of one
  floor box, used by the real-path case.
- Mind the known trap (lead memory): a Godot re-save of an inherited or instanced scene can drop overrides. Diff
  `house.tscn` and `zoo.tscn` semantically (node list, properties) before and after, and keep the editor's format.

## Acceptance
- Real path: the house (F5), the zoo (`-- --zoo`) and the one-box test level each start, the player walks, and a
  Host plus Guest join and see each other, with no node duplicated outside `level.tscn`.
- Every existing suite passes unchanged (`run.sh` full, since scenes change); co-op net shots still start.
- No look change: a before/after still of one house room and the zoo's spawn is identical.
