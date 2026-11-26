---
type: ticket
status: done
kind: build
area: ui
feature: player
priority: now
created: 2026-11-26
done:
blocked_by: ["[[142-wardrobe-page-and-station]]"]
notes: ["batch B (Q2614); order: docs/migration/milestones.md Batch B, wave 6", "suggested model: sonnet"]
terms: [Lobby, Wardrobe, Colour & Wardrobe, Lifetime tallies]
suites: [lobby, menus, ui_nodes, game_link]
---

# The Lobby's Wardrobe key and stats card

In the Lobby a player dresses before the run and sees a Teammate's tallies. Build `docs/architecture/wardrobe.md`
"The Lobby":

- `lobby_place.tscn`'s Avatar takes the Roster's `look` and steps its Trail's demo under its feet.
- A Wardrobe key (84 px orange keycap, the hanger icon from the UI icons, tooltip "Wardrobe") beside this machine's own
  figure's head at 82% of its width (`LobbyTuning`); pressing it opens core/142's page in the Lobby's page layer and asks
  `LobbyState.ready(false)` (Q1764).
- A stats card `lobby_stats_card.tscn` (280 px, cream, the name 28 px, five rows 22 px "Pairs", "Coins",
  "Collections", "Floors", "Games", thousands apart) beside the focused figure from the Roster's `tallies`, flipping
  left near the screen's edge (48 px), never taking the mouse.

Behaviour lines (`docs/migration/m4-lists/08-wardrobe-profile-achievements.md`): "The Lobby (lobby)".

Batch B is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-b-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
The key and the card are scenes on the Theme (Q2658); their numbers in `LobbyTuning` (`# placeholder:` the old).

## Acceptance
- Real path: in the Lobby the player clicks the Wardrobe key beside their own figure, steps the Socks row with a click,
  closes; their figure wears the Socks and their Ready is cleared.
- Hovering a Guest's figure shows the card with the Guest's tallies.
- Placeholders: the key's and card's numbers.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- UI is always authored in nodes (Q2658, 2026-11-25).

## Open follow-ups
