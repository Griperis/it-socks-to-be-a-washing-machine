---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: frame
priority: now
created: 2026-11-24
done:
blocked_by: [core/79, core/87, core/88, core/89, core/91]
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: sonnet"]
terms: [Fix, Part, Stage, Voice line]
---

# The Fix scene: a Part's cutscene and the next floor

A Part fitted into the washer plays its Fix as a cutscene: `Stage.fix_cutscene` (a CUTSCENE `VoiceTrigger`:
`cutscene_fix_1..4`, cutscene_2..5, all whole, Q2634), `part_fitted` starts the Stage's `CutsceneScript` on the frame
with the washer at its new, calmer mood, `open_floor` asked at the fade so the new Socks land under its black, the
spray after the Fixes that open a floor (1-3; the fourth is the last Fix: no floor, no spray), the respawn by the
washer; the slot waits for the scene because the Stage names a `fix_cutscene` (set on the house plan's four Stages;
the zoo's mini plan names none and opens at once): no `house.tscn` change. Design: `docs/architecture/stages.md` "Its verbs" and
"Signals", `docs/architecture/washer.md` "Cutscenes: the washer's part", `docs/architecture/run-ends.md` seam S5.

Behaviour lines: `docs/migration/m4-lists/03-stages-and-floors.md` "A Stage completes": the Fix, the scene's end, the load mid-Fix, the mood, the spit lines;
`docs/migration/m4-lists/05-washer-and-voices.md` "Its cutscenes": which run each belongs to.

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

Each Stage names its Fix cutscene trigger and script in the inspector: a new Stage with a new cutscene is a new
trigger, a recording and the Stage's fields (`docs/architecture/voice.md` "Triggers").

## Acceptance
- Real path: in the house (the Stage completed by the station knob or a short plan) the player carries the New filter to the washing machine and clicks; cutscene_2 plays on the frame; at its end the ground floor's door opens, the Stage bar shows Stage 2, the spray has played and the Stage 2 Socks lie on the open floors.
- The fourth Fix plays cutscene_5 whole, opens no floor, plays no spray, and sets the machine fixed (`machine_fixed`).
- A load between the fit and the fade opens the floor after the load; a Guest sees the same scene and floor.
- "The washing machine is busy" while a cutscene plays or someone is in its drum.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- cutscene_5 plays whole at the fourth Fix (Q2634, 2026-11-24).

## Open follow-ups

## Built log
