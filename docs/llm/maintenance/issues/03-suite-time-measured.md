---
type: ticket
status: needs-info
kind: build
area: maintenance
feature: tests
priority: next
created: 2026-11-24
done:
blocked_by: []
notes: ["suggested model: sonnet", "follows maintenance/02", "the lead runs the idle measurement; a kit change goes to the designer first"]
terms: []
---

# The full suite under 120 s, measured on an idle machine

maintenance/02 ran `coop_knockdown` and `room_doors` at 2x (merged on the designer's word, 2026-11-24), but its
full runs (176 s, 230 s) waited 52-89 s for slots of the machine-wide pool of 8 that other agents' runs shared, so
the true suite time is unknown. The designer will make a pass of their own too (2026-11-24).

## Acceptance
- The lead measures the full suite with no agent running (`kit/tools/run.sh`, wall time and the slowest cases);
  the number goes in the Built log.
- If still over 120 s: the slowest cases named with their seconds and a plan per case, from maintenance/02's
  [later]: `coop_hands` and `coop_hand_off` failed at 2x (find why), `coop_stacking` (18.5 s, timed in wall
  seconds), `coop_mess`, `coop_flight`, `coop_respill` (measured per wall second).
- Kit changes, only with the designer's yes: `run.py` printing every case's seconds (today the 3 slowest of the run),
  and a bigger or per-checkout slot pool.

## Open follow-ups
- [blocking] The designer's own pass (the idle measurement is done, 140 s).

## Built log

### 2026-11-24 (the lead)
- Measured on a quiet machine (no agent running, main e2aa43e): 140 s for the whole suite (141 s wall), PASS 19770 checks,
  615 cases; 74 processes for 66 suites, 8 at a time; the longest process coop_hands part 1 of 3, 34 s. Slowest
  cases: coop_stacking carried_loop 18.6 s and carried_loop_seen 18.5 s, coop_hands guest_throw_ghost_on_host_flight
  17.6 s. Memory at most 3.6 GB of a 7.6 GB budget. The idle measurement follow-up is done; the designer's pass is next.
