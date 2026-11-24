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
- [blocking] The idle measurement (the lead) and the designer's own pass.

## Built log
