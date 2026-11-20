---
type: ticket
status: needs-info
kind: build
area: core
feature: core
priority: now
created: 2026-11-20
done:
blocked_by: ["[[02-handling-socks]]"]
notes: []
terms: []
---

# The Throw

Milestone M0.5. Split from core/02 (Q2250). Holding the right button charges a Throw (a ring round the
crosshair); release throws the active item along the aim. Built on core/02's `Hands`, `Mess` and `Flight` body:
a `throw(dir, charge)` Command to `Hands`, the Host spawns the `Flight` with the Throw's speed. Co-op (the
Guest's ghost and blend, Q2221; watching a Throw, Q2226; hitting a teammate) is M0.6.

## Behaviour list
Approved with core/02's list (Q2243, 2026-11-20); the lines moved here unchanged.

**Throw**
- T01 When you hold the right button past 0.25 s with something in the Hands, then a ring fills round the crosshair
  (full in 1.2 s) and releasing throws the active item along the aim with a gravity arc; no cancel.
- T02 When a charge is released under 15%, then it is a short lob (3.5 m/s forward, 2 m/s up), not a drop.
- T03 When thrown with more charge, then it flies faster: 3 m/s at the tap to 5 m/s at full charge. The free Throw
  is weak (Long Arm and Quick Charge: M4).
- T04 When you press Q, then nothing happens.
- T07 When a loose Sock is thrown at a Cabinet, then it bounces off and lies loose again, never shelved. (With
  core/04's Cabinet.)
- T08 When a Sock is thrown, then it never ends inside a wall or furniture and always ends up lying loose.
- T11 When a Throw faster than 1.5 m/s hits lying Socks, then it wakes the Sock hit and at most 8 touching it; a
  slow drop wakes none.
- T13 When a thrown Sock comes to rest, then it lies where its body stopped; a flight that never settles is put
  down after 6 s.
- T14 When a thrown Sock leaves the playable space or goes above the ceiling, then it comes down at once and lies
  at a set return spot (in the old game, in front of the washer; in the zoo, the station's).

## Design
<Step 2: the charge timing on the player, the ring's look (a still first), the Flight's launch from the eyes, the
wake of lying Socks (T11), the out-of-bounds return (T14). Ask the open looks questions before building.>

## Acceptance
- The Throw goes through a `throw` Command answered by the Host of one; the flying Sock is the Host's body.
- Tests follow the behaviour lines above, one case each.
- One real-path case: in `game/zoo/stations/handling.tscn`, with real input, pick a Sock, hold the right button,
  release, and the Sock lands farther than a drop would.

## Answers

## Open follow-ups

## Built log
