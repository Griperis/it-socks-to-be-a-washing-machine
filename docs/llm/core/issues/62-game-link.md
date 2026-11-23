---
type: ticket
status: done
kind: build
area: core
feature: frame
priority: next
created: 2026-11-23
done: 2026-11-23
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
- [later] (core/63) With three or more players, a Guest still loading its level is sent the spawn of another Guest's
  avatar (Godot sends a spawn whose synchronizer belongs to another peer to everyone; the Avatars only hold back the
  loading Guest's own). Start should load every Guest before it matters, or the avatar needs a Host-owned gate.
- [later] A Host started from the title (link under the root) and a Guest that F5'd the house with `--join=` (a
  private link under the runtime) have their Session at different paths and cannot talk; both from the title, or
  both by F5, work.
- [later] `game/parts/session.gd` is 745 lines (grep_rules note): split it when next touched.

## Built log
- 2026-11-23
  - Changed: `GameLink` (game-lifetime node: Session, Roster, link Parts with ids prefixed `Runtime/`, so the Roster
    stays `Runtime/Session/Roster`); the title makes it beside itself on Solo/Host/Join and frees it when back at the
    title; `LevelRuntime` takes it from `GameLink.of()` or makes a private one, hands its Session/Roster to the Net,
    Avatars, Autosave and ESC menu, and gates every level synchronizer on `Session.sees_house()`; the level's Parts
    read through to the link's (`Parts.link`); Session works with link and level Parts (`attach_level`/`detach_level`),
    gate without a required layout (checked when the Guest already has a level), link snapshot at connect (`linked`),
    `house_ready`/`house_left`/`house_refused`, `not_ready` drops, events of the level only to Guests in the house,
    `PROTOCOL` 14; Avatars spawn a Guest's avatar only once it is in; Roster merges a save (`Part.restored()`);
    LevelNet resumes a session already online; coop.md, saves.md, lobby.md.
  - Files: game/net/game_link.gd(.uid), game/net/game_link.tscn, game/parts/session.gd, game/parts/parts.gd,
    game/parts/part.gd, game/net/roster.gd, game/net/level_net.gd, game/parts/avatar/avatars.gd,
    game/level/level_runtime.gd, game/level/level_runtime.tscn, game/save/autosave.gd, game/ui/esc_menu/esc_menu.gd,
    game/ui/title/title.gd, tests/game_link_test.gd(.uid), tests/hooks.gd, tests/house_test.gd (h01 finds the
    Session through the link), tests/wiring_scenes.txt, docs/architecture/coop.md, saves.md, lobby.md
  - Verified: PASS 18523 checks, 557 cases (every suite; --touched reached all through tests/hooks.gd)
- Merged: 4e7ac513 (2026-11-23, branch core/62-game-link)
