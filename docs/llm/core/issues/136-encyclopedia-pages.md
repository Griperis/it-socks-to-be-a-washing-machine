---
type: ticket
status: done
kind: build
area: ui
feature: gifts
priority: now
created: 2026-11-26
done: 2026-11-26
blocked_by: ["[[134-encyclopedia-record-and-unlocks]]"]
notes: ["batch B (Q2614); order: docs/migration/milestones.md Batch B, wave 4", "suggested model: sonnet"]
terms: [Sock encyclopedia, Design, Collection, Size]
suites: [menus, ui_nodes, ui_icons, main]
---

# The encyclopedia pages and the title's key

A player reads their Sock encyclopedia on the title. Build `docs/architecture/gifts.md` "The pages" and "On the
title":

- `encyclopedia.tscn` (a Control in nodes on the Theme): the header (`Prev` "<" and `Next` ">" 80 px, wrapping; the
  Collection's `Icon` 48 px; `Title` "Simple (1/3)"; `Count` "37 / 130") and a `Page` with a `SockStage` (a SubViewport,
  orthographic camera, 400 px a metre) under a 10-column `Cells` GridContainer; one `encyclopedia_cell.tscn` (150 x 124:
  the name Label 14 px, the existing `size_box.tscn`) per Design, its Sock fitted to 0.34 m behind the cell; collected
  in its own look, uncollected with `silhouette.tres` and "???"; one page per unlocked, not held-back Collection, 50 a
  page, sorted small, medium, large then catalogue order.
- On the title a 72 x 72 corner key (`menu_encyclopedia`, tooltip "Sock encyclopedia") left of the Licence key opens
  it as a title page (`title.tscn`).
- An Encyclopedia pillar on the Collections station opens the pages on the zoo's profile.

Behaviour lines (`docs/migration/m4-lists/07-gifts-and-collections.md`): "The encyclopedia", the pages and the
title's key (the book is core/139's).

Batch B is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-b-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
UI in nodes (Q2658): the page, the cell and the silhouette material are scenes and resources edited in the editor;
code instances one cell per Design and fills it. Pad and keyboard focus per `docs/architecture/ui.md` (Q2647, Q2654).

## Acceptance
- Real path: on the title a click on the encyclopedia key opens the pages; a Design in the profile shows its Sock and
  name, the others "???"; a click on ">" turns to the next Collection; a locked Collection and the Lost Socks have no
  page.
- Esc or Close shuts it; Tab and the pad reach the arrows.
- Placeholders: none.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The Lost Socks are left out of the encyclopedia until the Drum (Q2675, 2026-11-25).
- UI is always authored in nodes (Q2658, 2026-11-25).

## Open follow-ups
