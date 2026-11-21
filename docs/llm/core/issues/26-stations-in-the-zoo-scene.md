---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: zoo
priority: now
created: 2026-11-21
done:
blocked_by: []
notes: []
terms: []
---

# The stations are placed in zoo.tscn by hand

The designer wants to arrange the zoo's stations in the editor like any node (Q2359, 2026-11-21: "why the stations are
placed by code and not directly in the scene, so I can move them around?"). Today `game/zoo/stations.gd` instances
every `*.tscn` in `game/zoo/stations/` at run time and puts a station left at the origin on a grid, so `zoo.tscn`
shows no station in the editor and a station is moved only in its own scene. The designer chose to put every station
in `zoo.tscn` by hand, knowing branches that add stations will meet in that file.

## Behaviour list
- Z05 Every station scene in `game/zoo/stations/` is an instance under `Stations` in `zoo.tscn`, seen in the editor;
  the designer moves it by dragging, on the 0.5 m grid. Today's places are kept (each station where it stands now).
- Z06 Nothing places a station by code: the folder collector and the grid placement go. The station scenes are not
  edited (other branches own them): a station whose root already stands where it should keeps that; one the grid
  placed gets its place as the instance's transform in `zoo.tscn`.
- Z07 The zoo still has one Mess, Hands and Coins: `ZooStations._join_socks()` still hands each station's Socks to the
  zoo's (core/10), now for the instances already under `Stations` (it runs before their `_ready`).
- Z08 A station file in the folder that is not instanced in `zoo.tscn` fails the zoo suite with its name (so a new
  station is never forgotten); a station's root name stays its id (Part ids unchanged, no PROTOCOL change unless an id
  moves).
- Z09 The existing rules still hold: pads never overlap (the zoo test), every station runs alone (`zoo:alone`, the
  wiring check), two zoos hold the same stations in the same order.

## Acceptance
- One case per line; the real-path cases of every station suite still pass.
- `docs/architecture.md` (the zoo paragraph) and this project's `CLAUDE.md` say a new station is its own scene file
  plus one instance in `zoo.tscn` (the lead edits `CLAUDE.md`; the agent writes the architecture line).
- A still of `zoo.tscn` as the editor would show it is not needed; a top-down shot of the zoo with every station.

## Answers
- The stations are instanced by hand in `zoo.tscn`; the folder collector goes (Q2359, 2026-11-21).

## Open follow-ups
- [later] The kit's `zoo-design` skill and its templates still describe the folder collector; changing them upstream
  needs the designer's permission (the lead asks).

## Built log
- Model: Sonnet (lead): a scene and script change with known tests.
