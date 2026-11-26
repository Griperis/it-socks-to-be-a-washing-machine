---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: economy
priority: now
created: 2026-11-26
done:
blocked_by: ["[[132-old-tree-voice]]"]
notes: ["batch B (Q2614); order: docs/migration/milestones.md Batch B, wave 6", "suggested model: sonnet"]
terms: [Old Tree, Stage, Cabinet, Part, Fix, Final wash]
suites: [furniture_devices, house, stages, voice, cabinet, final_wash, fix_scene]
---

# The Old Tree's help

The rest of the tree's lines: grumbles, the Stage's progress, hints, tips, the Fix comments and the story beats.
Build `docs/architecture/economy.md` "The Old Tree talks", the triggers table's remaining rows:

- `tree_grumble` (an idle spell's chance 0.35, only while the washer is broken), the Stage thresholds `tree_stage_half`,
  `_most`, `_last` (0.5, 0.8, 0.95 of the bar, to a player near, once each per Stage).
- The hints (an idle spell's chance 0.35): `tree_cabinet_<room>` (a Cabinet with a Row of the bar to fill; a new
  `Cabinet.tree_hint` export set on the house's eight Cabinets in `house.tscn`) and `tree_hint_<floor>` (the floor of
  a loose Mate: with a loose Sock in the Hands its Mate's floor, else a loose Sock of a Collection the bar still needs;
  `Stage.tree_hint`); never a spot.
- The tips once per player per run: `tree_tip_throw` (from the start), `tree_tip_part` (once Stage 1 completes).
- The Fix comments: with chance 0.75, one `tree_part_<floor>` or `tree_floor_<floor>` line 120 to 420 s into the next
  Stage to a player near, lapsing after 120 s unheard (`Stage.tree_part_comment`, `Stage.tree_floor_comment`).
- The story beats `tree_final_wash` and `tree_peace` (`waits`, skipping the cooldown after `beat_gap` 20 s; the last
  Part's fitting is the peace line's).

Behaviour lines (`docs/migration/m4-lists/06-coins-drawers-upgrades.md`): "The Old Tree moves and talks": the idle
grumble and hint, the Stage thresholds, the hints, the first-time tips (the vacuum's and the Elevator's are batch C's,
named there), the Fix comments, the Final wash and peace beats.

Batch B is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-b-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
A new room, floor or tip is a trigger file, a recording, its JSON entry and the field on the Cabinet or Stage: no code.
The chances and times are `OldTreeTuning`'s (`# placeholder:` the old).

## Acceptance
- Real path: in the house, with Stage 1's bar filled past half (a test's fill), the player walks to the Old Tree and
  its "stage_half" subtitle shows.
- In the house, idle near the tree with a Cabinet's Row unfilled and `hint_chance` 1 gives that Cabinet's room line.
- The Throw tip is said once per player per run and again after a New Game.
- Placeholders: the chances and beat times in `OldTreeTuning`.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The Old Tree's voice comes in batch B (Q2670, 2026-11-25).

## Open follow-ups
