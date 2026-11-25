---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: knockdown
priority: now
created: 2026-11-24
done:
blocked_by: [core/86, core/88]
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: sonnet"]
terms: [Teammate, Hands]
---

# The knockdown wash

A knocked-down Teammate dragged to the washer's door goes for a spin: build it with the old numbers (`docs/architecture/washer.md` "Numbers", Knockdown wash): a
body let go within 1.5 m of the `Door` marker slides in (0.35 s), the door shuts, they spin 3 s out of play (no body,
nothing to hit, grab or hand to) with their view spinning in the drum (1.2 turns a second), the HUD hidden and a
sloshing loop, fade out 0.4 s; the door bursts open (1 s), they tumble out head first (70 degrees, 2.5 m/s out, 1.5 m/s
up, 0.4 twist), knocked down 2 s, then get up, fade in 0.6 s; one at a time; a cutscene's end or a leaver ends it; not
saved; the washer is busy meanwhile.

Behaviour lines (`docs/migration/m4-lists/05-washer-and-voices.md`): "The knockdown wash" (all but the item loads, batch C).

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

The numbers in `washer_tuning.tres` (Knockdown wash group), placeholders; the drum slosh in the sound catalogue.

## Acceptance
- Every knockdown wash ends at core/88's respawn (left to this ticket by core/88).
- Real path: in the knockdown station with the washer, the player drags the knocked Teammate to the door and lets go; the Teammate's body is hidden, their view spins, and after 3 s they lie knocked down in front of the door.
- A second body let go meanwhile just lies there; a cutscene's end ends the wash.
- Placeholders: the knockdown wash numbers.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The knockdown wash is batch A, the washer's last ticket (Q2642, 2026-11-24).

## Open follow-ups

## Built log
