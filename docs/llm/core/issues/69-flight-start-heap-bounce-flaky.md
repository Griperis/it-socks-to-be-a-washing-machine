---
type: ticket
status: ready-for-agent
kind: bug
area: core
feature: mess
priority: next
created: 2026-11-24
done:
blocked_by: []
notes: ["suggested model: opus (debugging)", "ledger: tests/flaky/ledger.md, flight_start:t01_heap"]
terms: [Sock, Heap]
---

# flight_start:t01_heap fails in the full suite, passes alone

## What happens
- Since core/54 merged (2026-11-24), the full suite fails `flight_start:t01_heap` and then passes it when rerun alone:
  three merges in a row (house/08, core/65 and the run between them). Each time the same message: "none bounces back
  up off the heap or the floor (most 0.233 m)". The identical number points to something the earlier suites leave
  behind (a static, a setting, a Resource changed at run time), or to core/54's numbers (`push_slack` 0.02,
  `pressure_spin` 1.5 rad/s, the woken tipping Sock) meeting this case's limit.
- A flaky test is a defect to rework, never to switch off or loosen without the cause (kit/docs/TESTING.md
  "Flaky cases").

## Acceptance
- Reproduced first: the suite order that fails it, found and written down (kit/tools/run.sh with the suites before
  it), or the shared state named.
- The cause fixed (state reset between suites, or the case measuring what it means); if a game number must change
  that is look or feel, stop with a [blocking] follow-up for the lead.
- `flight_start` passes in the full suite 10 runs in a row; no FLAKY line.

## Open follow-ups

## Built log
