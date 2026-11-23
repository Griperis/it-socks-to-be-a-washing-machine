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
