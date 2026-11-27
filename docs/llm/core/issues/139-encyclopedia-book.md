---
type: ticket
status: done
kind: build
area: core
feature: gifts
priority: now
created: 2026-11-26
done:
blocked_by: ["[[136-encyclopedia-pages]]"]
notes: ["batch B (Q2614); order: docs/migration/milestones.md Batch B, wave 7", "suggested model: opus"]
terms: [Sock encyclopedia, Hands, Carry capacity]
suites: [carry, coop_carry, handling, hand_details, house, aim_screen, save, menus]
---

# The encyclopedia book in the house

One shared book on the workshop's workbench, read in the Hands (Q2676). Build `docs/architecture/gifts.md` "In the
house" and "The book":

- `Carriable.one_slot` (a new export): the book is a Hands item in one slot instead of the whole Hands, listed and
  cycled with the Socks and Pairs by the wheel (the seam batch C's guide card reuses).
- `game/entities/encyclopedia_book/encyclopedia_book.tscn`, placed by hand on the workbench in `house.tscn`: a
  `Carriable` (title "Sock Encyclopedia", `handable` on, never thrown) with graybox Looks until assets/17 lands; saved
  and in the snapshot; a New Game puts it back on the bench.
- `encyclopedia_menu.tscn` (a CanvasLayer, the cream panel, core/136's pages showing the reader's own profile) opened by
  E while the book is the active item; the player frozen, the mouse free, the world running; arrows, A / D, Left /
  Right turn; E or Esc closes; it closes when the book leaves the Hands.
- Prompts: "Sock Encyclopedia [LMB]" aimed, "Read [E]" and "Drop [RMB]" held.

Behaviour lines (`docs/migration/m4-lists/07-gifts-and-collections.md`): "The encyclopedia", the book's lines.

Batch B is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-b-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
The book is an entity with a swappable Looks (graybox, then assets/17's on the designer's yes); the menu is a scene in
nodes on the Theme (Q2658).

## Acceptance
- Real path: in the house the player left-clicks the book on the workbench into a free Hands slot, presses E, and the
  pages show their own profile; A turns back, Esc closes; a right click puts it down.
- With Socks in the Hands the book takes one slot beside them; the wheel cycles to it.
- Co-op: a Teammate sees the book carried; each reader sees their own pages.
- Placeholders: none.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The encyclopedia book stands in the house in batch B, as the old; batch C's guide card reuses its one-slot Hands
  item (Q2676, 2026-11-25).
- The designer said yes to assets/17's book model (Q2696): swapping `game/entities/encyclopedia_book/looks_encyclopedia_book.tscn` in for the graybox Looks is this ticket's job; its graybox Looks root must be named `EncyclopediaBookLooks` (or rename one of the two so they match).

## Open follow-ups
- [later] An old detail left out, reported to the lead (Q2277): while a Sock is active the old drew the book tucked small
  (`tucked_scale` 0.35, `tucked_turn`) among the other tucked items in the camera's space; the port hides it (a Carriable
  is drawn at a body-frame slot, core/78). Drawing it tucked needs the HeldView to draw the book, a design call.
- [later] `hold_slot_book.tres` (0.1, 0.95, -0.5; stood up 1.35 rad) is a placeholder: the old drew the book in the hand
  frame at (0.13, -0.13, -0.45); judge it by eye with the real glb.
- [later] A knocked-down reader's spill is covered with a stand-in Teammate (`knockdown:book_spill`), not the local
  player (a solo player has no ragdoll); whole-Hands carried things do not yet let go on a knock-down (core/150).
