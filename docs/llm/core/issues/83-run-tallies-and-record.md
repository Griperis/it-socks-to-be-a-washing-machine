---
type: ticket
status: done
kind: build
area: core
feature: frame
priority: now
created: 2026-11-24
done: 2026-11-25
blocked_by: [core/76]
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: sonnet"]
terms: [Pair, Coins, Whiteboard, World]
---

# The run's tallies, record, Whiteboard and Tab

What a run counts per player, kept from the same answers that cause it: `RunTallies` (Pairs shelved, Pairs made,
Socks picked, Coins earned) and `RunRecord` (every Pair shelved: `[player id, Design, Coins paid]`, for the Final
screen), one ticket because both are a line in the Cabinet's shelve answer. Build `docs/architecture/stages.md` "The tallies, the Whiteboard
and Tab" and `docs/architecture/run-ends.md` "`RunRecord`": the board on `game/furniture/collection_board.tscn` (`whiteboard.gd`, the sheet in a
SubViewport, Patrick Hand, redrawn only on a change; the house scene is not touched), `tab_overlay.tscn` on the HUD and
the `whiteboard_overlay` action (Tab, the pad's Select: `python3 kit/tools/input_actions.py add`).

Behaviour lines: `docs/migration/m4-lists/03-stages-and-floors.md` "The Whiteboard and the Tab tallies" (all); `docs/migration/m4-lists/04-first-wash-and-laundry-day.md` "The Final screen": the record line.

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

`WhiteboardTuning` (1024 x 768, overlay 0.8, glow 0.2), placeholders. No station change: the board is the furniture scene's, seen
where the zoo already shows it.

## Acceptance
- Real path: in the Stages station the player picks a Sock (input) and holds Tab; the overlay's row reads 1 under Socks picked; the board's picture was redrawn once; shelving a Pair adds a `RunRecord` row with the player's id, the Design and the Coins paid.
- A Guest's pick and shelve count on both machines; a leaver keeps their row; saved and in the join snapshot.
- Tab never opens over a menu and closes when one opens.
- Placeholders: `WhiteboardTuning`.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- None beyond the design's (see the files named above).

## Open follow-ups

## Built log

### 2026-11-25
Changed: `RunTallies` and `RunRecord` (Parts on `run.tscn`, found by group within their Parts); the Hands' `pick` answer and the Cabinet's `_shelve` answer carry their patches; `Whiteboard` (`whiteboard.gd` on `collection_board.tscn`: sheet in a SubViewport on the face, drawn again only on a change); `WhiteboardSheet`, `TabOverlay` on the player's HUD; `whiteboard_overlay` action (Tab, pad Back/Select); `WhiteboardTuning` (placeholders); `Player.input_blocked()`; `shape.json` and `house_ids.txt`; four rows under "Settled by the old game".
Files: game/run/run_tallies.gd, run_record.gd, run.tscn; game/ui/whiteboard/*; game/furniture/whiteboard.gd, collection_board.tscn; game/hands/hands.gd; game/entities/cabinet/cabinet.gd; game/player/player.gd, player.tscn; project.godot; tests/run_tallies_test.gd, tests/saves/*; docs/migration/batch-a-review.md.
Verified: `--touched` ran every suite (project.godot changed): only save s11/s12 failed, fixed by committing the two lists; run_tallies PASS; grep_rules PASS. A Guest's counts and the leaver's row rest on the Part answer path (tested as a snapshot and a Roster listing, not on a second machine).
