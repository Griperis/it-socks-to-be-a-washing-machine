---
type: ticket
status: ready-for-agent
kind: build
area: audio
feature: core
priority: next
created: 2026-11-22
done:
blocked_by: ["[[40-drop-look-only-tests]]"]
notes: []
terms: []
---

# The room is silent

The old game's room tone `amb_room` was silent (no pick). Ours plays a placeholder clip, `rubberduck_ambient1` at
-12 dB (core/17 S08). The designer wants it silent, as the old game.

## Acceptance
- No room tone plays in the zoo or the main scene: the `amb_room` entry in `game/audio/sound_catalogue.tres` has no
  clip (the event stays, so a pick can come back later in M1.1), and an event with no clip plays nothing and logs
  nothing.
- The placeholder clip and its `.import` go if nothing else uses them.
- The tests that asserted the room ambience loops are changed to assert it is silent.

## Answers
- The room ambience `amb_room` is silent, as the old game (Q2432, 2026-11-22).

## Open follow-ups

## Built log
