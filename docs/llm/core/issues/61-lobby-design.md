---
type: ticket
status: done
kind: design
area: core
feature: frame
priority: next
created: 2026-11-23
done: 2026-11-23
blocked_by: []
notes: ["designer 2026-11-23: prepare the Lobby while M3's lists are written", "Q2561: the World list, Continue/New Game and Delete come with the Lobby"]
terms: [Host, Guest, World, Group, Part]
---

# M4's second piece: the Lobby (design)

core/58 put the title, Options, saves and one loading screen on main; Solo and Host go straight into the house
(Q2561). The Lobby is next in M4: where Worlds are chosen and players gather before the house. A design ticket:
findings and a proposal, no game code.

## Step 1: findings
By examination of `reference/it-socks` (grep; never commit there): the Lobby (catalogue B61: `game/lobby/`,
`game/net/lobby.gd`; pedestals, ready state, countdown, the Wardrobe page, stats card, the World settings sidebar
drawer, the greyboxed giant sock drawer scene), Worlds and Groups as the Lobby shows them (B62: the World rows,
Continue / New Game / Delete, the Group lock the designer dropped, Q2553-Q2563), what the Lobby offers after an
ending (B23, P36), its leftovers (P73) and Steam's part (P40, P75: friends-only lobby of 4, "Invite friends"; Steam
itself stays later). Write `docs/migration/m4-lists/02-lobby.md` in the shape of `01-main-menu-and-saves.md`: every
line, every motion, glide, pop and sound (Q2277), with its old file:line; what was weak.

## Step 2: proposal (stop for the designer)
`docs/architecture/lobby.md` (proposal): the Lobby as a scene on the one Theme; how it sits between the title,
core/58's `Worlds`/`SaveStore` and the house's loading screen; the Host / Guest flow in the co-op shape (scene Parts,
the Host authoritative; ready and countdown as Part state; what a Guest sees while the Host is in a menu); how a
World row is shown and deleted; the Wardrobe and stats card (port now, or split out). Say what core/58's code is
reused and what changes. Split the build into tickets of one mergeable piece each, in order. End with the choices
for the designer, 2-3 options each with a recommendation; read `docs/migration/decisions.md` first and do not ask
what is answered.

## Acceptance
- `docs/migration/m4-lists/02-lobby.md` and `docs/architecture/lobby.md` exist; every old detail is listed or
  named as dropped with its Q.
- The choices are `[blocking]` Open follow-ups here, each with options and a recommendation.
- No game code changed.

## Answers
- L1: the Lobby is its own scene; Session and Roster live for the whole game (no reconnect); Start has the Host load the house
  for everyone behind the one loading screen; the World is chosen in the Lobby, the drawer comes back (Q2582, 2026-11-23).
- L2: Solo goes through the Lobby, one pedestal (Q2583, 2026-11-23).
- L3: the Wardrobe and the stats card are split out (Q2584, 2026-11-23).
- L4: the name is typed in one field on the Multiplayer page, a Steam name can fill it later (Q2585, 2026-11-23).
- L5: the "Pairs per Drawer" slider waits for the Stages piece (Q2586, 2026-11-23).
- L7: one swappable row name, the members' names first, judged at the look's first still; no Guest limited to their Worlds
  (Q2587, 2026-11-23).

## Open follow-ups
- [later] L6 What the Lobby offers after an ending (a finished World, only New Game, a mark on the row; keep tidying): decide with
  the ending's piece.

## Built log
### 2026-11-23 (ticket agent)
Changed: step 1 and step 2 as a design, docs only. 74 old lines listed with their file:line (11 sections: the Lobby, its
drawer, Worlds, Solo, ending, Steam, words) and the old Lobby's weak points. The proposal: a Lobby screen over the loaded house
(LobbyState Part, cover, hold, Start's fade), the World pages before it, four build tickets (core/62 World pages, core/63 Lobby
state and cover, core/64 Lobby look, core/65 Lobby details) and three later ones (Wardrobe and stats card, Steam lobby, after an
ending). Read core/58 as merged on main.
Files: docs/migration/m4-lists/02-lobby.md, docs/architecture/lobby.md, this ticket.
Verified: docs only; no game code changed.
### 2026-11-23 (rework to Q2582-Q2587)
Changed: `docs/architecture/lobby.md` reworked to the decided shape: the first ticket moves Session and Roster into a game-lifetime
`GameLink` (the Part ids, the join snapshot at the house handshake, a late joiner after Start, the tests that stay green), then the
Lobby scene and `LobbyState`, the name field, the drawer and World pages, the look, the details. Tickets written: core/62 game
link, core/63 Lobby scene and state, core/64 name field, core/65 World drawer, core/66 Lobby look, core/67 Lobby details.
Verified: docs only; no game code changed.
