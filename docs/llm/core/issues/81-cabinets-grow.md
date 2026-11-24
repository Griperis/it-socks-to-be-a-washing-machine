---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: frame
priority: now
created: 2026-11-24
done:
blocked_by: [core/76, assets/11]
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: sonnet"]
terms: [Cabinet, Row, Drawer, Stage]
---

# The Cabinets grow: six Drawers and the drop

When a floor opens every unlocked Cabinet gains its Rows: build `docs/architecture/stages.md` "Rows and Cabinets": the Cabinet scene
holds six Drawer modules and shows `rows` of them (the rest hidden, collision off, locked), and the drop: each new
module falls in with the old timings, `drawer_thunk` at its seam and `dust_puff.tscn` from it, at once on the opening,
seen or not (Q2620; no reveal check).

Behaviour lines (`docs/migration/m4-lists/03-stages-and-floors.md`): "Rows and Drawers": the shown Rows, the drop, the thunk and dust, the Drawer above the Rows.

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

`CabinetTuning`'s new group "Drawer drop" (delay 0.8 s, time 0.35 s, height 0.8 m, gap 0.25 s, dust `#cbbfa8`, 24
puffs), placeholders; `drawer_thunk` in the sound catalogue (the oven-close share). No station change: the mini run's Cabinet A grows
at "Fit now".

## Acceptance
- Real path: in the Stages station the player completes Stage 1 and presses E on "Fit now"; Cabinet A's third Drawer drops in; the player clicks a Pair into it.
- A load or join shows the grown Cabinet at its height with no drop.
- Placeholders: the Drawer drop group.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- A new Drawer appears at once when its floor opens, seen or not; replaces Q824 (Q2620, 2026-11-24).

## Open follow-ups

## Built log
