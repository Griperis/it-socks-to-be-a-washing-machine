---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: laundry
priority: now
created: 2026-11-24
done:
blocked_by: [core/88, core/94, core/95]
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: sonnet"]
terms: [Final wash, Laundry day]
---

# The Final wash

The run's end: build `docs/architecture/run-ends.md` "The Final wash and the end of the run": the Host's `final_wash` at the wait's end,
the door shut, `final_wash.tres` on the frame (the happy wash, the push-in, cutscene_6 whole with the drum easing),
no respawn, hold black, `LaundryDay.ended` and `WorldRecord.finished`, the Final screen opened on every machine over
the frozen game, play time stopped, a load or join after it began ending it at once; the washer's senses off.

Behaviour lines: `docs/migration/m4-lists/04-first-wash-and-laundry-day.md` "The Final wash" (all; the unvoiced look only as the frame's no-voice fallback); `docs/migration/m4-lists/05-washer-and-voices.md` "What
the face rig carries for others": the Final wash's spin and bubbles.

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

The sequence is `final_wash.tres`; the happy wash's numbers in `washer_tuning.tres` (placeholders).

## Acceptance
- Real path: in the house with one bin left (the Laundry station's knob or a short plan), the player clicks it into the washing machine; after the cutscene the Final screen is open on both machines and play time has stopped.
- A load or a join after the Final wash began goes straight to the Final screen.
- Reachable in the main scene.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- cutscene_6 plays whole (Q2629, 2026-11-24).
- A finished World is kept as a record (Q2631, 2026-11-24).

## Open follow-ups

## Built log
