---
type: ticket
status: done
kind: build
area: core
feature: gifts
priority: now
created: 2026-11-26
done:
blocked_by: []
notes: ["batch B (Q2614); order: docs/migration/milestones.md Batch B, wave 1", "suggested model: opus"]
terms: [Host, Guest, World]
suites: [scene_parts, save, coop_join, carry, coop_carry, main, zoo]
---

# Spawned Parts: things made during play

Presents (core/137) and batch C's bought devices are made during play, so they come through Godot's spawner (the
port's rule, `docs/migration/coop-structure-for-the-port.md`). Build `docs/architecture/gifts.md` "A present is a
spawned scene", the `SpawnedParts` half:

- `SpawnedParts` (`game/parts/spawned_parts.gd`, a Part under `Run` in `run.tscn` as `Run/Spawned`, with a
  `MultiplayerSpawner` child whose `spawn_function` builds a scene from `{scene, id, states}`): rows of what it spawned;
  its Host verbs' patches add or remove rows; the spawner creates or frees the node on every machine.
- `Parts.adopt(node)` and `Parts.release(node)` bind a spawned node's Parts by path (`Run/Spawned/<name><id>/...`) as
  `Parts.bind` does placed ones.
- The save and the join snapshot keep each row with its Parts' states; a load spawns the rows before the states are
  written; a state that reaches a Guest before its node waits for it by id (gifts.md "Gotchas").
- The Gifts station `game/zoo/stations/gifts.tscn` (instanced by hand in `zoo.tscn`) with a `PresentSpot` marker (a
  `Marker3D` in the group `present_spots`) and a zoo-only "Spawn a crate" switch (a plain Carriable crate scene under
  `game/zoo/gifts/`, a zoo-only Command there).

Behaviour lines: none of the old game's (the old Game held presents in its own dictionary); the coop-structure's
"spawned things store {scene, spawn_seq, state}" is the rule.

Batch B is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-b-review.md` with this ticket's number
(Q2604).

## How it is authored
A spawnable thing is a scene with its Parts; nothing registers it but the row's `scene` path. The Gifts station's
switch is a zoo-only node under `game/zoo/gifts/`; nothing outside `game/zoo/` refers to it (Q2409).

## Acceptance
- Real path: in the Gifts station a click on "Spawn a crate" puts a crate at the spot on the Host and a Guest; the
  player picks it up with a left click and puts it down with a right click; both machines see it carried and laid.
- A late joiner sees the crate where it lies; a save and load keeps it where it was laid.
- Co-op at 0 and 50 ms one way; a state arriving before its node is applied when the node comes.
- Placeholders: none.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- Decided state lives on scene parts; things created during play use Godot's spawner (CLAUDE.md, the port's rules).

## Open follow-ups
