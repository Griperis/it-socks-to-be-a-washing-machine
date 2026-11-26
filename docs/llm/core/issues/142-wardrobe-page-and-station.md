---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: player
priority: now
created: 2026-11-26
done:
blocked_by: ["[[141-looks-in-coop]]", "[[125-collections-as-data]]"]
notes: ["batch B (Q2614); order: docs/migration/milestones.md Batch B, wave 5", "suggested model: opus"]
terms: [Wardrobe, Wardrobe Station, Colour & Wardrobe, Player colour, Hat, Clothes, Socks piece, Trail]
suites: [house, mess, sock_generator, menus, ui_nodes, save, coop_join, openables]
---

# The Wardrobe page and the station in the house

A player dresses at the wardrobe in the parents' bedroom. Build `docs/architecture/wardrobe.md` "The Wardrobe page"
and "The station in the house":

- `wardrobe_page.tscn` (Heading "Colour & Wardrobe", the `PreviewStage` from core/128 with an `AvatarLooks` turning one
  turn per `spin_time` 8 s, pupils watching while it faces the camera, the worn Trail's demo beside it; the `Colours`
  HFlow of `colour_swatch.tscn` per CoopTuning colour, taken ones greyed with their holder's name; four
  `wardrobe_row.tscn` with "None" and the owned listed pieces of the slot, `"%d/%d unlocked"` of listed pieces only,
  "<" / ">" and A / D on a focused arrow, wrapping, each step asking `wear`; Close), `wardrobe_menu.tscn` (a CanvasLayer,
  the cream panel 900 px; the player frozen, the mouse free, the world running; `menu_open` / `menu_close`; Esc, E or
  Close shuts it), the same freeze as core/129's menu (no new player code).
- `game/entities/wardrobe_station/wardrobe_station.tscn` (a `StaticBody3D` 1.0 x 1.92 x 0.56 m on the station layer,
  `WardrobeStation` Part with `inside`, `use` and `leave`; graybox Looks with two door leaves and the `open` (80 degrees,
  0.7 s, ease in-out) and `shut` (ease out) clips; `wardrobe_open` / `wardrobe_close` 1 m up; a whole state shows
  without sound), prompt "Wardrobe" with the doors outlined, placed by hand in `house.tscn` at the old spot (parents'
  bedroom, west wall).
- Sock places keep clear in front of it: `SockPlaces` reads a `sock_clear` group (a node with `clear_box`) beside its
  Cabinet check; the station joins it with the old 1.25 x 1.09 m zone.
- The station in the Wardrobe zoo station beside a wall mirror.

Behaviour lines (`docs/migration/m4-lists/08-wardrobe-profile-achievements.md`): "The Wardrobe in the house", "The
Wardrobe page" (the Lost Socks' six neither listed nor counted, Q2683; the basic pieces offered from the first game,
Q2679; the lock icon is gone, wardrobe.md "Changed technically"), "Words".

Batch B is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-b-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
The page, the rows, the swatch and the menu are scenes in nodes with Theme variations (Q2658): code only fills them
and instances a swatch per colour. The station is an entity with a swappable Looks (graybox until assets/20's on the
designer's yes); the doors are clips in its Looks. `spin_time` in `WardrobeTuning` (`# placeholder:`).

## Acceptance
- Real path: in the house the player walks to the wardrobe and presses E; the doors swing open and the page shows them
  in their colour; a click on the Hats ">" puts an owned hat on the preview and (co-op) on their Avatar for the
  Teammate; Esc shuts it and the doors close.
- A colour another player has is greyed with their name; clicking it is refused and the swatch springs back.
- No Sock lies in the station's clear zone at a New Game.
- Reachable in the main scene.
- Placeholders: `spin_time`, the clear zone.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The ten basic pieces are owned from the start (Q2679, 2026-11-25).
- The Lost Socks' six pieces are hidden from the Wardrobe and its "N/M" until the Drum (Q2683, 2026-11-25).
- UI is always authored in nodes (Q2658, 2026-11-25).

## Open follow-ups
