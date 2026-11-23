---
type: ticket
status: done
kind: build
area: core
feature: frame
priority: next
created: 2026-11-23
done: 2026-11-23
blocked_by: [core/62]
notes: ["M4's Lobby, design core/61: docs/architecture/lobby.md, list docs/migration/m4-lists/02-lobby.md", "Q2582, Q2583, Q2584", "suggested model: opus"]
terms: [Host, Guest, World, Part, Roster]
---

# The Lobby scene and LobbyState (M4)

Build "Core/63" of `docs/architecture/lobby.md` and the lines of `docs/migration/m4-lists/02-lobby.md` that it names
(Ready, Start, Back and Leave, Solo, the card's line; the places as a plain list of names and colours: the look is core/66).
`game/lobby/lobby.tscn` on the one Theme; `LobbyState` Part on the link; the title's Solo, Host and Join go to the Lobby; Start
has every machine load the house behind the one loading screen; a Guest who connects after Start skips the Lobby.

## Acceptance
- Solo: title, Solo, the Lobby with one place and Continue (hidden with no save) and New Game (asks before overwriting), then the
  house. Host: title, Multiplayer, Host, the Lobby on the last-played co-op World or a New Game.
- A Guest's Ready is its own only (a guard case: another id, a non-bool, a flood); Start is Host-only and refused until every
  present player is Ready; a leaver is forgotten, a joiner is not Ready; Ready is never saved.
- Start: both machines show the loading card and the house; both players stand at their Roster spots; the Lobby does not come back.
- Back ends the session for everyone ("The Host ended the session"); a Guest's Leave leaves; Esc is Back; `--host` and `--join=`
  act at once.
- Real path (0 and 50 ms): Host and Guest, Ready from both, the Host's Start through to both in the house.

## Answers
- Solo through the Lobby, one pedestal (Q2583, 2026-11-23); the Wardrobe and stats card are split out (Q2584, 2026-11-23).

Assumption to confirm at the first still: Solo's bar is the old one (Continue, New Game) in place of Ready and Start.

## Open follow-ups
- [later] (from core/62, unchanged) With three or more players a Guest still loading its house is sent another
  Guest's avatar spawn: Start loads everyone at once but does not hold the spawns back; untested here (two players).
- [later] (from core/62, unchanged) A title-started Host and a Guest that F5'd the house with `--join=` have their
  Session at different paths; `--join=` from the title now goes through the Lobby (same path), F5 on the house does not.
- [later] A Guest who joins in the Lobby sends no Hands numbers (it has no Player yet, D13): the Host uses its own
  Hands' numbers for it in the house. Sending them with `house_ready` would mend it (a wire change).
- [later] The title's `--host` / `--join=` cannot be driven under `kit/tools/net_shot.sh` (its `--cmd=` makes
  GameCli's plan not "none"); the stills pressed the keys instead. A kit fault, for the lead.
- [later] Assumption at the first still (ticket): Solo's bar is the old one (Back, Continue, New Game) in place of
  Ready and Start. Stills in builds/review-lobby/.

## Built log
- 2026-11-23
  - Changed: `LobbyState` Part on the link (Ready by player id, Guest-only `ready` guarded by args and rate, Host-only
    `start` refused until everyone present is Ready, `world` clears Ready, leaver forgotten, never saved); `lobby.tscn`
    (`LobbyScreen`, plain stand-in on the Theme: card, places list, bar; Solo Back/Continue/New Game with the ask;
    co-op Back/Leave, Ready, Start or "Waiting for the Host to start"; Esc is Back; Guest's "Joining..." card; a
    Guest connecting after Start goes into the house at once); the title's Solo, Host, Join go to the Lobby;
    `Worlds.pick_slot()`; `Roster.placed()` and no spot for a Lobby join; `LevelNet` places everyone as the house
    comes in; `Session` keeps a `house_ready` that comes before the Host's house; `PROTOCOL` 15.
  - Files: game/lobby/lobby.gd(.uid), game/lobby/lobby.tscn, game/lobby/lobby_state.gd(.uid), game/net/game_link.gd,
    game/net/game_link.tscn, game/net/roster.gd, game/net/level_net.gd, game/parts/session.gd, game/save/worlds.gd,
    game/ui/title/title.gd, tests/lobby_test.gd(.uid), tests/game_link_test.gd (l06 through the Lobby),
    tests/menus_test.gd (m05), tests/save_test.gd (s01 through the Lobby), tests/wiring_scenes.txt,
    docs/architecture/lobby.md
  - Verified: PASS 18604 checks, 564 cases (--touched ran every suite)
- 2026-11-23 (lead's fix before the merge)
  - Changed: merged main; Solo's "New game" question has the shared ESC close key at its top right and no Cancel
    (Q2578, core/59): the key or Esc cancels; no other dialogue added (Back and Leave ask nothing). PROTOCOL stays 15
    (main 14).
  - Files: game/lobby/lobby.tscn, game/lobby/lobby.gd, tests/lobby_test.gd (k06), this ticket
  - Verified: PASS 18606 checks, 564 cases (--touched ran every suite)
- Merged: 78fa0560 (2026-11-23, branch core/63-lobby-scene-and-state)
