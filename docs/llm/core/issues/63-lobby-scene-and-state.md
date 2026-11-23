---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: frame
priority: next
created: 2026-11-23
done:
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

## Built log
