---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: house
priority: now
created: 2026-11-26
done:
blocked_by: ["[[174-devices-in-the-house]]", "[[156-elevator-carry-rule]]", "[[157-elevator-riders]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 9", "suggested model: opus"]
terms: [Elevator, Sock vacuum, Backpack vacuum, Sock detector, Radio]
suites: [elevator, vacuum, carry, house]
---

# The devices and the Sock vacuum ride the Elevator

The carried devices ride the Elevator by core/156's one rule (Q2699), and the Sock vacuum meets the car as the designer
answered: its container rides only with its nozzle on its hook (Q2710); a player holding the nozzle may climb in with
the container outside, nothing stops it, and the hose stretches between floors, as the old (Q2711). Build
`docs/architecture/devices.md` "Seams" (core/149), drafts 150-M and 150-N (filed together):

- `Vacuum.may_ride()` (true only with `nozzle_at == INF`), read by `Carriable.rides_patch` (core/156's check), so the
  container with its nozzle out stays at its stop;
- the hose while its nozzle's holder rides, and while the nozzle is on another floor: drawn stretched from the
  container's cuff to the nozzle's through the shaft, its bones laid along the line with their collision off until the
  nozzle is back within the hose's length of the container (the old drew a straight tube, VV; check its cross-floor
  draw and VA:383-450 and build what the old did); no refusal, no auto-hang;
- the hose's mask leaving out the car's layer (the car never pushes it, V13);
- cases for the detector, the Radio (playing on the ride) and a lying Backpack riding.

Behaviour lines: `09-vacuums-and-detector.md` V45's ride (Q2699), V13's car half; `13-tv-and-radio.md` R30.

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
Nothing new to author: a carried thing rides as a `Carriable`.

## Acceptance
- Real path: in the house with Elevator Repair bought, the player puts the detector and the Radio into the car with the
  right click and clicks the call button on the other floor; both arrive lying in the car, the Radio still playing.
- A lying Backpack rides; the container with its nozzle hung rides; with the nozzle out it stays at its stop.
- A player holding the nozzle presses Space at the open car: they climb in and ride; the hose is seen stretched through
  the shaft on both machines; nothing is refused; at the arrival they climb out holding the nozzle.
- The car never pushes a lying hose.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- Every carried thing rides the Elevator by one item rule, the detector too (Q2699, 2026-11-26).
- The container rides only with its nozzle on its hook (Q2710, 2026-11-26).
- A player holding the nozzle may climb into the car; the hose stretches between floors, as the old (Q2711,
  2026-11-26).

## Open follow-ups
