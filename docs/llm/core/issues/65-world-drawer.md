---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: frame
priority: next
created: 2026-11-23
done:
blocked_by: [core/63]
notes: ["M4's Lobby, design core/61: docs/architecture/lobby.md, list docs/migration/m4-lists/02-lobby.md", "Q2582, Q2586, Q2587", "suggested model: sonnet"]
terms: [Host, Guest, World, Part, Roster]
---

# The World drawer and its pages in the Lobby (M4)

Build "Core/65" of `docs/architecture/lobby.md` with the list's "World settings drawer" and "Worlds and Groups" lines:
the drawer sliding in over the Lobby, the rows, Choose, Delete with its question, New game, the full page; the Guest's read-only
view; `Worlds.pick_slot`, `row_details` and `display_name` (the one place a row's name is made).

## Acceptance
- The Host's drawer lists the Solo World first and the co-op Worlds newest first; Choose changes `LobbyState`'s World and clears
  Ready on every machine; Delete asks first and removes the file; a damaged World only deletes; New game takes the first free
  slot; with five used the full page asks to delete one first and goes on at once.
- A Guest sees the same list read-only with the chosen one ticked, every World, none limited to the Guest's (Q2587).
- The drawer slides 0.25 s (a typed number, placeholder), keeps the Lobby's layout and takes the clicks under it. No Pairs slider
  (Q2586).
- `display_name` is the only code that makes a row's name; its test pins the members' names.
- Real path: the Host opens the drawer, deletes a World and chooses another; a Guest's drawer follows.

## Answers
- The World can be chosen in the Lobby; the drawer comes back (Q2582, 2026-11-23). The slider waits for Stages (Q2586). One
  swappable row name, no Guest limited to their Worlds (Q2587).

## Open follow-ups

## Built log
