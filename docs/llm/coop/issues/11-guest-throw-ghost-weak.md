---
type: ticket
status: ready-for-agent
kind: bug
area: core
feature: coop
priority: now
created: 2026-11-22
blocked_by: []
notes: ["reported by the designer in play, 2026-11-22"]
terms: [Host, Guest, Throw, Flight]
---

# A Guest's own Throw looks weaker on the Guest's screen, then jumps

## What happens (the designer, in two windows)
When the Guest throws, the Guest's own screen shows the Sock flying weaker or shorter than the same
charge does on the Host, and then it jumps or snaps to another spot. The Host's window shows the Guest's
Throw correctly, and the Host's own Throws are fine. So the Host's real flight is right, and the
thrower's ghost (Q2221, coop/09) is launched differently from it. The jump is then the hand-over onto the
streamed body, which Q2481 meant as a 0.2 s ease of about 0.3 m, not a visible snap.

## Suspects, not checked
- The ghost's launch speed, charge or direction differs from what the Host computes. It may read
  another Hands' tuning, a default `HandsTuning`, the charge before the release frame, or no
  `max_speed` scaling.
- Gravity, damping or mass on the ghost's body differ from the Host's flight body.
- The ghost is ended or reset when the stream's first row arrives, instead of easing.

## Reproduce
Two processes (the designer's way), Host `-- --host`, Guest `-- --join=127.0.0.1 --profile=b`, plus a
headless case with two zoos at 0 and 50 ms one way. The Guest throws at full charge and at half charge
toward a fixed point. Record the ghost's path and the Host's body's path, as the Guest sees them, side by
side.

## Acceptance
- The cause is written in the Built log, with the two recorded paths before the fix.
- The ghost's path matches the Host's flight within a small tolerance until the hand-over: the same
  launch speed, direction, gravity and damping. Write the tolerance in the Built log.
- The hand-over is the 0.2 s ease of Q2481, with no jump larger than the Host's own motion in one frame.
- A case at 0 and 50 ms checks both, through the Guest's real input path (charge, release).
- coop/09's cases and budgets still pass.

## Answers
- Q2221, Q2481 (2026-11-22).

## Open follow-ups

## Built log
