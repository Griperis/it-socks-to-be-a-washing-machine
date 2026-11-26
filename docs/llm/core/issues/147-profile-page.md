---
type: ticket
status: ready-for-agent
kind: build
area: ui
feature: player
priority: now
created: 2026-11-26
done:
blocked_by: ["[[145-achievements-system]]", "[[136-encyclopedia-pages]]"]
notes: ["batch B (Q2614); order: docs/migration/milestones.md Batch B, wave 5", "suggested model: sonnet"]
terms: [Profile, Lifetime tallies, Achievement]
suites: [menus, ui_nodes, main]
---

# The Profile page

One page: the five Lifetime tallies on top, the Achievements under them (Q2681). Build `docs/architecture/wardrobe.md`
"The Profile page":

- `profile_page.tscn` (a Control on the Theme): the player's name, the five tallies in a row of captions and numbers
  ("Pairs", "Coins", "Collections", "Floors", "Games"), a `GridContainer` of `achievement_cell.tscn` (icon, title,
  description; earned in full colour with the date, unearned greyed, hidden unearned "???"), "%d / %d earned".
- Opened from a 72 x 72 corner key on the title beside core/136's encyclopedia key (tooltip "Profile", `title.tscn`)
  and from a "Profile" entry in the ESC menu (`esc_menu.tscn`); Esc or Close shuts it.

Behaviour lines (`docs/migration/m4-lists/08-wardrobe-profile-achievements.md`): "Achievements", the page's line
(Q1694: the title's entry beside the encyclopedia and the pause menu).

Batch B is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-b-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
UI in nodes (Q2658): the page and the cell are scenes with Theme variations; code instances one cell per Achievement
file and fills it. Pad and keyboard focus per `docs/architecture/ui.md`.

## Acceptance
- Real path: on the title a click on the Profile key opens the page with the five tallies; an earned (fixture)
  Achievement shows its title and date, an unearned one greyed; Esc shuts it; in the house Esc then "Profile" opens the
  same page.
- With no Achievement files the page shows the tallies and "0 / 0 earned".
- Placeholders: none.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- One Profile page: the five Lifetime tallies on top, the Achievements under them (Q2681, 2026-11-25).

## Open follow-ups
