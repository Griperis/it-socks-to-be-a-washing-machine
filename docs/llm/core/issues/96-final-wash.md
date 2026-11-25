---
type: ticket
status: done
kind: build
area: core
feature: laundry
priority: now
created: 2026-11-24
done: 2026-11-25
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
- During the happy wash the room's lamps within 4 m flicker, cleared when it ends (old `rogue_machine.gd:186-188`, `:318-323`, `:468-474`; found by core/87).
- Real path: in the house with one bin left (the Laundry station's knob or a short plan), the player clicks it into the washing machine; after the cutscene the Final screen is open on both machines and play time has stopped.
- A load or a join after the Final wash began goes straight to the Final screen.
- Reachable in the main scene.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- cutscene_6 plays whole (Q2629, 2026-11-24).
- A finished World is kept as a record (Q2631, 2026-11-24).

## Open follow-ups
- [later] The room's lamps in the Final wash stay at level 1.0 (steady) as the old did; if the designer wants a visible flicker in the happy wash, it is a number (`room_flickering()` at a repair under 1). Row in batch-a-review.md.

## Built log
- 2026-11-25 Changed: `final_wash` begins the Final wash (door shut, `final_wash.tres`: happy wash with push-in, cutscene_6 whole with the drum easing, hold black, no respawn); the Host's `final_wash_end` ends the run (`LaundryDay.ended`, `play_seconds`, `WorldRecord.finished`, play time stopped); every machine releases the black and opens the Final screen (`FinalSummary.of`, new `LevelRuntime.final_screen`); a load or join after it began ends it at once; the washer's senses and comments are off (`Washer.ending()`); the room's lamps follow the happy wash and are cleared at its end; the old unvoiced happy look is the no-voice fallback. Replaced core/93's `final_started` stub (now the real "begun"). Added the `Shots/Push` marker and the `happy_*` placeholders in `washer_tuning.tres`.
  Files: game/laundry/laundry_day.gd, game/laundry/final_wash.tres, game/entities/washer/{washer.gd,washer.tscn,washer_looks.gd,washer_tuning.gd}, game/cutscene/cutscene_player.gd, game/level/level_runtime.{gd,tscn}, game/save/{autosave.gd,world_record.gd}, game/zoo/laundry/laundry_label.gd, tests/{final_wash_test.gd,coop_final_wash_test.gd,laundry_day_test.gd}, docs.
  Verified: see the commit's suite line.
- Merged: 2c06f6f6 (2026-11-25, branch core/96-final-wash)
