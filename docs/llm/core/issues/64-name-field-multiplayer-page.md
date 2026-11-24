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

### 2026-11-23
Changed: the "Your name" field moved from the Join page to the Multiplayer page above Host and Join; the name is kept on leaving the page, Host and Join; Join keeps the address only. `PlayerProfile.suggested_name()` (returns "") and `shown_name()` (typed name wins, an untouched suggestion is not kept as typed). The wire is unchanged (the gate already carried the name), so PROTOCOL stays. Shot action `name`, shot set `name-field`; stills in `builds/review-name-field/`.
Files: game/ui/title/title.gd, title.tscn, game/net/player_profile.gd, tests/menus_test.gd, tests/game_link_test.gd, tests/suggesting_profile.gd, tools/shot_hooks.gd, tools/shots/sets/name-field.txt.
Verified: PASS 18421 checks, 519 cases
- Merged: 928ec412 (2026-11-23, branch core/64-name-field-multiplayer-page)
