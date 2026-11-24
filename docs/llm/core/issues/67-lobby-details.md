---
type: ticket
status: done
kind: build
area: core
feature: frame
priority: next
created: 2026-11-23
done: 2026-11-24
blocked_by: [core/65, core/66]
notes: ["M4's Lobby, design core/61: docs/architecture/lobby.md, list docs/migration/m4-lists/02-lobby.md", "Q2277", "suggested model: sonnet"]
terms: [Host, Guest, World, Part, Roster]
---

# The Lobby details (M4)

Build "Core/67" of `docs/architecture/lobby.md`: the pad route over the Lobby and the drawer, the keys' captions and hints, the
wording from one place, the Ready tick, the narrower-than-16:9 camera, the status line, the "Invite friends" hook (hidden until a
transport can invite). Then walk the list `02-lobby.md` line by line and report each as built, dropped by a Q, or later.

## Acceptance
- The pad reaches every key and the drawer's rows and walks back; the first selection is the "i" key when there is one, else Back.
- Ready ticks and does not click; the captions show as the list says and keep their line.
- `NetTransport.can_invite()` is false for ENet and the key is hidden; a test transport that can shows it.
- A walkthrough note in the Built log: every line of `02-lobby.md`, its state.

## Open follow-ups
- No wire message changed: PROTOCOL stays 21.
- The pad's selection on a place only turns the pedestal gold (as the mouse does); the old Wardrobe key after the own figure is the Wardrobe piece's (Q2584).

## Answers
- Look work stops at its first still (project rule).
- Q2644: the captions stay at their size.
- Q2645: the pad's selection ring is a later follow-up, filed as core/75.
- Q2646: the status line stays hidden (`status_text()` empty until a reason exists).
- Merge go: designer, 2026-11-24

## Built log
- 2026-11-24 (stops at its first still, `ready-for-human`). Changed: `LobbyWords` is the one place of the Lobby's wording (no `text =` is left in
  a Lobby scene; each view sets its words in `_ready`); captions under Ready and Start (they fade, never hide, so the line is kept); the Ready
  key carries `no_ui_sound` and ticks through the new `UiSounds.hover()`; `LobbyPad` links the pad's route (the "i" and World settings keys,
  the figures, the bottom keys, the open drawer as a column; first selection the "i" key else Back; the first pad press selects it);
  `NetTransport.can_invite()` (false) and `invite()` with the drawer's "Invite friends" key, shown only for a Host whose transport can;
  `status_text()` seam. Files: game/lobby/lobby_words.gd, lobby_pad.gd, lobby.gd/tscn, world_drawer.gd/tscn, world_row.*, who_page.gd,
  lobby_place.*, game/net/net_transport.gd, game/audio/ui_sounds.gd, tests/lobby_test.gd (k11-k14), tests/support/inviting_transport.gd,
  tools/shot_lobby.gd, tools/shots/sets/lobby-look.txt. Stills: `builds/review-lobby-details/` (captions, pad-first, pad-drawer, narrow).
  Verified: `PASS 19770 checks, 615 cases` (`--touched` ran every suite), `PASS rules`.
- Walkthrough of `02-lobby.md` (B built, Q dropped by a Q, W another piece, L later, S an earlier ticket):
  - Screen and backdrop: dark backdrop, 3D view, 48 px margins, card top, status line over the bar, free mouse: S (core/63, 66). Narrower camera:
    S (core/66), now with a case (k14). No music, Ready tick and menu click and hover: B (k12). Every key clicks and hovers: B (UiSounds, k12).
  - Card and "i": S (core/66); follows the Host's World on every machine: S (core/63).
  - Places: four co-op, one Solo, Avatar, name row, Ready mark, free silhouette, join and leave, focus gold, follow the figure: S (core/66, k10).
    Trail sample, Wardrobe key beside the head, own-place mark: W (Wardrobe, Q2584). Click on an Avatar does nothing: B (it has no handler).
  - Stats card and Wardrobe key, tallies, colour row, Solo's Wardrobe: W (Q2584).
  - Ready, Start and leaving: bar, Ready toggle, Start, "Joining...", leaver and joiner, world change clears Ready, Back, Esc, window close: S (core/63).
    Captions and tick: B now. Wardrobe clears Ready: W. Host cannot remove a player: L (Steam lobbies). Pad route: B now (k11).
  - Drawer: key, slide, rows, Choose, New game, full page, Delete question, Guest list: S (core/65). "Your name" in the drawer: L (the name is on the
    Multiplayer page by Q2585). Pairs slider: W (Stages, Q2586). "Invite friends": B now (hidden for ENet, k13). Not dimmed and no close on outside click: S.
  - Solo: Continue, New Game and its question: S (core/63, k06); New Game page with the slider: W (Stages).
  - Worlds and Groups: S (core/58, 63, 65); the Group lock dropped by Q2554; row names Q2597.
  - After an ending, Steam's part: W (the ending's piece, the Steam piece). Words: B now (`LobbyWords`); refusals are the Session's (S).
- Merged: 0017da92 (2026-11-24, branch core/67-lobby-details)
