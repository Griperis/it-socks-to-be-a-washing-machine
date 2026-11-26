---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: gifts
priority: now
created: 2026-11-26
done:
blocked_by: ["[[132-old-tree-voice]]", "[[137-presents-under-the-old-tree]]"]
notes: ["batch B (Q2614); order: docs/migration/milestones.md Batch B, wave 5", "suggested model: sonnet"]
terms: [Old Tree, Gift]
suites: [furniture_devices, voice]
---

# The Old Tree's present lines

The tree says when presents wait under it. Build `docs/architecture/gifts.md` "The Old Tree's lines":

- The three triggers `presents_ready`, `presents`, `present_taken` (`game/voice/triggers/`, COMMENT, the Old Tree's
  speaker; their lines are in `old_tree.json` from core/132).
- `Presents.waiting_for(player_id)`, the signals `presents_dropped(players)` and `present_taken(by)`, and the tree's
  director reading them for a player near: "presents_ready" once, "presents" again after `presents_nag` 240 s near,
  "present_taken" on a pick near it; no house-wide call, no HUD hint.

Behaviour lines (`docs/migration/m4-lists/06-coins-drawers-upgrades.md`): "The Old Tree moves and talks", the presents
line.

Batch B is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-b-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
Trigger files and the lines' JSON entries (Q2640); `presents_nag` in `OldTreeTuning` (`# placeholder:` 240 s).

## Acceptance
- Real path: after a present drops (the Gifts station's "Drop presents" click) the player walks up to the tree and its
  subtitle shows a "presents_ready" line; taking the present near it gives a "present_taken" line.
- Placeholders: `presents_nag`.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The Old Tree's voice comes in batch B (Q2670, 2026-11-25).

## Open follow-ups
