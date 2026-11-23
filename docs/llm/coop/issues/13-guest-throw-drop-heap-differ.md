---
type: ticket
status: ready-for-agent
kind: bug
area: core
feature: coop
priority: now
created: 2026-11-23
done:
blocked_by: []
notes: ["the designer's M0.6 co-op zoo run, 2026-11-23; Q2573"]
terms: [Host, Guest, Throw, Mess, Sock, Hands]
---

# On a Guest: the own Throw has no arc, a put-down Sock sinks under the floor, heaps stack differently

From the designer's two-window co-op run on main (2026-11-23), after coop/09, coop/11 and coop/12:
1. **The Guest's own Throw looks wrong:** it has no arc; the Sock "just sways down". The Host's Throw is right.
   The designer asks for prediction on the Guest with the Host authoritative (Q2573): the Guest flies its own Throw with
   full physics (the same Jolt body, shape, mass, material and launch numbers as the Host's), and is corrected
   smoothly to the Host's stamped stream when the two part (a threshold and an ease, typed Resource numbers), ending
   on the Host's rest record. Teammates' Throws stay on the stream, played 0.1 s behind (Q2439).
2. **On the Guest, a Sock put down goes below the ground.** (Compare core/50: Jolt pushed a Sock through the 0.2 m floor
   on the Host; the Guest's looks-only bodies and the drop ghost may lack that fix, or the snap puts it at a wrong
   height.)
3. **On the Guest, Socks stack much differently than on the Host.** The Guest's looks-only bodies (Q2222) should end
   where the Host's rest batch says (snapped at rest); the designer sees different heaps.

## Reproduce first
Two processes (Host and Guest, `-- --zoo --host` / `--join`), at 0 and 50 ms, driven by input, logging per Sock the
Host's and the Guest's poses over time: a Guest Throw, a Guest drop at the handling station, a heap pour. Measure
before you diagnose: the Guest's flight path against the Host's (height over time), the Guest's resting heights against
the floor, and every Sock's final pose on both machines. Write each cause in the Built log (coop/11 found three
causes for an earlier version of item 1: read it).

## Acceptance
- Item 1: the Guest's own Throw follows the Host's arc: its path within a small error of the Host body's (a number in
  the Built log) at 0 and 50 ms, with the hand-over to the Host's rest record invisible (no pop over a set distance).
- Item 2: no Sock on the Guest ever rests under a floor (a case over drops and a pour).
- Item 3: after a pour settles, every Sock on the Guest lies where the Host's does (within 1 mm and 1 degree), a case.
- Real path: two zoos at 50 ms, the Guest throws, drops and the Host pours; all three hold.
- coop/07-coop/12's cases and the cost budgets still pass.
