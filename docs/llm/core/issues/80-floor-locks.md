---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: frame
priority: now
created: 2026-11-24
done:
blocked_by: [core/76]
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: sonnet"]
terms: [Stage, Openable, Floor]
---

# Floor locks: the doors, the gate and the reveal

The locked ways up and their opening. Build `docs/architecture/stages.md` "The floor locks": `floor_lock.tscn` with the Door entity's
`Openable` leaf, `looks_lock_door.tscn` and `looks_lock_gate.tscn` (graybox until assets/10: the same node names and
the `unlock` and `open` animations keyed with the old numbers), the padlock as its own aim target with the hint
"Please the washing machine", the gate's blocker up to the ceiling, `Openable.quiet_when_locked` and
`keeps_open_on_load`, `HouseLights.reveal(floor)` and a locked floor's lamps off, the dust sheet's pull on unlock (it
exists: wire it to the Stage).

Behaviour lines (`docs/migration/m4-lists/03-stages-and-floors.md`): "The floor opens: locks and reveals" (all but the Elevator's, batch C).

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

`FloorLock.floor` on each placed lock; `FloorLockTuning` (pop 0.6 s, swing delay 0.8 s, swing 1.4 s, lamps fade 0.6
s, hold 6 s), placeholders; `padlock_pop`, `chain_drop`, `lock_door_open` in the sound catalogue with the old shares.
The Stages station gets a ground door and a gate with an Open/Lock pillar, and the gate on the mini run's platform.

## Acceptance
- Real path: in the Stages station the player aims at the gate's padlock and reads "Please the washing machine" with no key; presses E on "Fit now"; the padlock pops, the gate swings open, and the player walks through onto the platform.
- A locked leaf stops the player, Throws and the crosshair; a swinging leaf sweeps Socks as a room Door does.
- A load or a join shows every lock, sheet and lamp as the run has it, with no animation and no sound.
- Placeholders: `FloorLockTuning`.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- None beyond the design's (see the files named above).

## Open follow-ups

## Built log
