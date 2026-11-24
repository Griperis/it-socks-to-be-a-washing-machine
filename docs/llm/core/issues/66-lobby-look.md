---
type: ticket
status: ready-for-human
kind: build
area: core
feature: frame
priority: next
created: 2026-11-23
done:
blocked_by: [core/63]
notes: ["M4's Lobby, design core/61: docs/architecture/lobby.md, list docs/migration/m4-lists/02-lobby.md", "Q2584, Q2587, Look work", "suggested model: sonnet"]
terms: [Host, Guest, World, Part, Roster]
---

# The Lobby look (M4)

Look work: stop after the first still and set `ready-for-human`. Build "Core/66" of `docs/architecture/lobby.md` and the list's
places, marks and card lines: `lobby_stage.tscn`, `lobby_place.tscn`, `who_page.tscn`, `LobbyTuning`. No Wardrobe key and no stats
card (Q2584).

## Acceptance
- Four places, centred, pedestals; Avatars in their colour idling; a free place a grey silhouette on a dimmed pedestal with
  "Waiting for a player"; the name in the player's colour, the HOST mark, the Ready mark; the World card and the i page.
- Stills in `builds/review-lobby/`: four players, a free place, a long name, 16:9 and a narrower screen, the focused pedestal, the
  drawer open, and the row name in both forms (the members' names, and "World n" with details) for the designer to judge (Q2587).
- No test for a look number (Q2421); one real-path case: a Guest's join fills a place on both screens.

## Answers
- Look work stops at its first still (project rule).

## Open follow-ups
- [later] Members-form row names clip in the drawer ("Ada," for three names); the numbered form does not (Q2587 judgement).
- [later] A free place's silhouette is a flat dark grey (backdrop 35 % toward grey); the Ready tick on a yellow name sits close to the gold mark.
- `WorldRow` carries a new `members` list (the "i" page's names); no wire change, PROTOCOL untouched.

## Built log

### 2026-11-24 (first still, stops for the designer)
Changed: `LobbyStage` (SubViewport, own World3D, 4 pedestals, AvatarLooks, free silhouettes, camera 16:9 / narrower rule),
`LobbyPlace` (HOST mark, name in colour, Ready mark, "Waiting for a player", focus), `WhoPage`, `LobbyTuning` (placeholders), the "i" key
beside the World card; `Worlds.name_form` (MEMBERS or NUMBERED, L7) and `members` in rows; shot scene `tools/shot_lobby.tscn` and set `lobby-look`.
Files: game/lobby/lobby_*.gd/tscn/tres, who_page.*, lobby.gd/tscn, game/save/worlds.gd, tools/shot_lobby.*, tools/shots/sets/lobby-look.txt, tests/lobby_test.gd (k10).
Stills: builds/review-lobby/. Verified: see commit.
