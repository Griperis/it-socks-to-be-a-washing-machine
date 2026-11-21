---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: core
priority: now
created: 2026-11-21
done:
blocked_by: []
notes: []
terms: [Sock, Mess, Door, Cabinet]
---

# A Sock caught by a shutting Door or drawer is pushed out

When a Door or a drawer of a Cabinet shuts onto lying Socks, a Sock that ends inside the leaf is today "lost": it
comes back at the return spot with a pop (the lost rule, T08). The benchmark's `sweep` shows 1 to 3 such Socks in
some runs (core/31 follow-up). The designer wants such a Sock pushed out of the leaf instead, to the side the leaf
came from, so it stays where the player left it, only moved clear.

## Acceptance
- A lying Sock that a shutting Door or drawer leaf would end inside is moved out of the leaf, to the open side (the
  side the leaf swept from), and rests there; it is not sent to the return spot and plays no lost pop.
- The lost rule (T08) stays for a Sock that leaves `bounds` or would lie inside a wall.
- The real-path case: in the Cabinet station (or the heap station's Door), the player drops Socks in a Door's swing,
  opens and shuts it with the use key; every Sock ends outside the leaf, none at the return spot.
- `tools/mess_bench.sh --only=sweep` (two runs): `lost` 0, and `inside` no worse than main's (2 to 3); the
  sweep's tick no worse than main's beyond noise. The numbers go in the Built log.
- How far out and how it moves (a slide, a flight with a small push, or put down at once) is a placeholder in
  `MessTuning`, until the designer plays it.

## Answers
- A Sock left inside a Door or drawer leaf when it shuts is pushed out of the leaf, not sent to the return spot with a
  pop (Q2428, 2026-11-21).

## Open follow-ups

## Built log
