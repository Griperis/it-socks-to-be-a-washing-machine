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
notes: ["M4's Lobby, design core/61: docs/architecture/lobby.md, list docs/migration/m4-lists/02-lobby.md", "Q2585", "suggested model: sonnet"]
terms: [Host, Guest, World, Part, Roster]
---

# The name field on the Multiplayer page (M4)

Build "Core/64" of `docs/architecture/lobby.md`: one "Your name" field on the Multiplayer page, above Host and Join, kept in
the profile; Join's own field goes; `PlayerProfile.suggested_name()` returns "" now and is where a Steam name fills it later.

## Acceptance
- A typed name reaches the Roster at the gate for a Host and for a Guest; an empty name stays "Player"; a name is cut at 16.
- A suggested name fills an empty field and a typed name wins (a case with a made-up suggestion).
- Real path: type a name on the Multiplayer page, press Host, a Guest joins: the Guest sees the Host's name in the Roster.

## Answers
- The name is typed in one field on the Multiplayer page, for Host and Join, built so a Steam name can fill it later (Q2585, 2026-11-23).

## Open follow-ups

## Built log
