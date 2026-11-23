---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: frame
priority: next
created: 2026-11-23
done:
blocked_by: []
notes: ["M4's Lobby, design core/61: docs/architecture/lobby.md, list docs/migration/m4-lists/02-lobby.md", "Q2582", "suggested model: opus"]
terms: [Host, Guest, World, Part, Roster]
---

# Game link: Session and Roster out of the level (M4)

Build "Core/62" of `docs/architecture/lobby.md`: `GameLink`, a node that lives for the whole game beside the current
scene, holding `Session`, `Roster` (its id stays `Session/Roster`, so no save breaks) and a link `Parts`; the house handshake
(`house_ready`, the layout hash, the level snapshot after it); the Roster's merge restore; `LevelRuntime` takes the link from
`GameLink.of(self)` or makes a private one (F5, the zoo, `--scene=` and every test keep working). No Lobby scene yet: the title
still goes straight into the house, now through a link it makes.

## Acceptance
- A link survives a scene change: a Guest stays connected across `SceneChanger.change_to` and keeps its Roster entry.
- The house handshake: a Guest's snapshot is sent only after its `house_ready` and the Host's own house is settled; a wrong layout
  hash is refused with `WRONG_BUILD`; a Command for a level Part before `house_ready` is dropped (`not_ready`); a late joiner
  takes the same steps. `Session.PROTOCOL` is raised.
- The saved ids and shape are unchanged: `tests/saves/house_ids.txt`, `shape.json` and every `sample_v*.json` still pass; a save
  loads with the Roster merged into the live one (present players stay, absent players' entries come back).
- Every test the doc lists stays green without a changed expectation (`coop_join`, `coop_guard`, `coop_flight`, `scene_parts`,
  `teammates`, `avatar`, `own_body`, `piano`, `level`, `house`, `save`, `menus`).
- Real path (0 and 50 ms): title Host, a Guest joins by address, the house loads for both through the link, both see each other's
  avatar and a Guest's pick lands on the Host.
- `docs/architecture/coop.md` and `saves.md` say where the link is.

## Answers
- Q2582 (2026-11-23): Session and Roster live for the whole game; no reconnect between the Lobby and the house.

## Open follow-ups

## Built log
