---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: core
priority: now
created: 2026-11-20
done:
blocked_by: ["[[13-two-tier-mess]]"]
notes: []
terms: []
---

# Rules back to the old game

M0.5 batch 3. The differences of `docs/migration/audit-core-rules.md` that the designer sent back to the old game, one
by one (Q2297, Q2303, Q2304, Q2312). Kept as ours (not in this ticket): no 3 cm aim forgiveness, our zoom slow-down, a
drop lands square (no R turn), the same spin each Throw, a thrown Pair's drag; the pad differences wait (Q2302).

## Behaviour list
Each line names the approved line it changes, if any; the audit row gives the old file and number.
- R01 The click that captures the mouse does nothing else; while the mouse is free (after Esc), clicks, G, R and the
  wheel do nothing in the game (L03; a bug, Q2297).
- R02 With a lying Sock and a lying Pair both under the crosshair, the nearer one is aimed (the ball's surface against
  the Sock's), as the old `rig_aim.gd:30-40` (Q2303).
- R03 A woken or moving Sock can be aimed and picked mid-slide, as the old game (ADR-0008 Q783, `sock_picks.gd`
  `SOCK_LIVE`) (Q2303).
- R04 After two Socks fuse, the Pair moves to the end of the Hands and becomes the active item, as the old
  `hands.gd try_pick` (Q2304).
- R05 A drop onto a lying Sock or Pair is allowed anywhere on it, with no slope test, as the old `rig_drop.gd:88-100`
  (Q2304; changes core/02's slope rule for that case only).
- R06 A thrown Pair shelves only when it touches a drawer front, as the old `sock_flights.gd:_touch_stations`; landing
  on the Cabinet's top or sides does not shelve (Q2312).
- R07 Only a drawer takes a shelve by click (or E); the Cabinet's frame does not (Q2312).

## Acceptance
- One test per line, on the real path where the player's input matters (R01, R02, R03, R07); existing cases that
  asserted the old behaviour of ours are changed, each named in the report.

## Answers
- Q2297, Q2303, Q2304, Q2312 (2026-11-20).

## Open follow-ups

## Built log
- Model: Sonnet (lead): rule changes with known old code and tests.
