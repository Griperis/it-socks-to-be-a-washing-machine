---
type: ticket
status: done
kind: build
area: core
feature: core
priority: now
created: 2026-11-21
done: 2026-11-22
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
- [later] How far out and how it moves are placeholders in `MessTuning` "Pushed out of a leaf" for the designer to
  play: `leaf_clearance` 0.02 m (the whole Sock clear of the leaf's face), `leaf_push_speed` 0.4 m/s (it flies on
  from there; 0 puts it down at once), `leaf_push_tries` 3.
- [later] Found while reproducing: most pops after a Door shut were not Socks inside the leaf but Socks the leaf
  pressed a few mm into the floor (middle under the floor's top by less than `sunk`), which `put_down` sent to the
  return spot. The old game kept those where they lay (`flat_layout.gd` `sunk_floor()`: within `sunk` of the floor is
  still in the room), so the port now does too. A port fix, not a new choice; the lead may want the designer told.
- [later] `game/mess/mess.gd` is 900 lines (grep_rules' "split it when next touched" note; 866 before this ticket).

## Built log

### 2026-11-22
- Changed: a resting Sock or Pair whose middle is inside a Door's or drawer's leaf (any leaf the Mess has swept,
  remembered with its place before its last step) is moved flat to the side the leaf swept from, wholly
  `leaf_clearance` past its face, and flies on from there (or is put down there); no pop, not at the return spot. A
  spot past the face inside a wall, or out of bounds, is lost as before (T08). A middle under a floor's top by less
  than `sunk` lies as it is (the old game's rule). Reproduced first on `main` in the Cabinet station: 13 Socks in the
  Door's swing, opened and shut, 6 seeds: 10 pops (1 from inside the leaf, 9 pressed into the floor); after: 0 from
  either over 16 seeds (one Sock pushed into the jamb, a wall, still pops, as it should).
- Bench `tools/mess_bench.sh --only=sweep` on this machine (it shows no `lost` here, on `main` either; the designer's
  PC did): `main` three runs tick median 0.575/0.582/0.582 ms, p95 1.40/1.22/1.36, lost 0, inside 1, sunk 5; branch
  two runs tick median 0.516/0.554 ms, p95 1.20/1.25, lost 0, inside 1, sunk 5.
- Files: `game/mess/mess.gd`, `mess_moving.gd`, `mess_tuning.gd`; `tests/leaf_push_test.gd`;
  `docs/architecture/mess.md`.
- Verified: `kit/tools/run.sh --touched`: PASS 16763 checks, 370 cases; rules PASS.
- Merged: 514776d9 (2026-11-22, branch core/39-pushed-out-of-a-shut-leaf)
