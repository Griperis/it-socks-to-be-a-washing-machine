---
type: ticket
status: needs-info
kind: maintenance
area: tools
feature: maintenance
priority: next
created: 2026-11-25
done:
blocked_by: []
notes: ["kit change: the lead does it, in the main checkout (kit/CLAUDE.md); the kit stays generic", "source: docs/research/kit-lessons-from-the-port.md (27 items, G1-G14, C1-C13)"]
terms: []
suites: []
---

# What the port taught that the kit lacks

A research pass over this game's decisions, tickets, commits and code
(`docs/research/kit-lessons-from-the-port.md`) found 14 pieces of Godot knowledge and 13 pieces of code the kit
should carry for the next game. Each item there has its evidence, whether the kit covers it today, the proposed
kit change and a size. The designer picks which to build; the report's top five and tonight's editor re-save
finding are listed below.

## Acceptance
- **G1 + C1, a network bug in the kit's own templates:** both kit `session.gd` (scene parts, Command seam) hold
  ENet's packet throttle (`throttle_configure`) so unreliable packets are not dropped (31 of 32 at 60 fps today),
  behind a small transport seam like `game/net/enet_transport.gd`; a suite case proves a 60 fps unreliable stream
  arrives.
- **G2, faults only an exported build shows:** a scene check that refuses an anchored Control root saved without
  `layout_mode` (core/113); `godot-game-dev` lines on preload loops that break only the export and on
  `ResourceLoader.list_directory` instead of `DirAccess` for remapped files; the `release-export` smoke run takes
  one still of the exported build, not only a headless start.
- **G3 + G4 + G6, doc lines:** spawner and synchronizer traps (state before `add_child`, which peers a spawn
  reaches, the gate synchronizer); physics interpolation off for MultiMeshes and cameras; a Jolt section (thin
  floors, penetration slop, bodies made overlapping, results that depend on body order). One owner each.
- **C3, one multi-machine suite base:** paced frames and a byte-counting LagPeer in the kit's harness support, so a
  game's network suites stop copying `_branch` and its helpers (25 copies here).
- **C4 + C7, two small templates:** the save template gains the game's backup and damaged-file safety; a profile
  lock lets a second debug copy on one PC take its own profile and join (today the kit's gate refuses it as the
  same player).
- **G5, editor re-saves that lose data (seen again on 2026-11-25):** the designer's editor re-saved eight files;
  three lost data: `credits.tres` dropped every non-empty `covers` list, `washer_tuning.tres` set
  `no_voice_seconds = null`, `theme.tres` rewrote the Keycap styles. The editor had not loaded those scripts'
  current exported properties (an editor left open across merges, or another engine version). Kit change: a check
  (beside `kit/tools/scene_links.py`) that names a changed `.tres`/`.tscn` whose re-save drops a non-default
  property line or sets one to `null`, run before an "editor format" commit and by `integrate.sh` on a dirty
  working copy; one doc paragraph: reload the editor after merges, use the pinned engine version, diff every line
  of an editor-format commit.
- Every change generic (no game names), with its test, `kit/tools/selftest.sh` green, one CHANGELOG entry each.

## Answers

## Open follow-ups
- [blocking] For the designer: which items to build: the six above (recommended), the whole report, or a subset.
  The three items the report marks unsure (mass mesh re-imports, the generic `settle`, a timer grep rule) wait.
