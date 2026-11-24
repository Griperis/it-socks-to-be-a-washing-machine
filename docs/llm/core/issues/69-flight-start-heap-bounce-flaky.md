---
type: ticket
status: done
kind: bug
area: core
feature: mess
priority: next
created: 2026-11-24
done: 2026-11-24
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
- [later] For the lead, not checked: the case's ticks show Jolt putting a heap Sock 0.22 m into the zoo floor in one step,
  and the Mess putting it back (core/50) in its next tick. If a frame is drawn between the two, the player could see the
  Sock under the floor for one frame. To check: a strip of the heap's pour, frame by frame, at the pushed-in tick.

## Built log

### 2026-11-24
- Changed: reproduced with `kit/tools/run.sh --only=flight_start` (the suite alone, its earlier cases first: it fails
  every time; `--only=flight_start:t01_heap` passes). No state is left behind: the earlier cases' bodies change Jolt's
  order, and in that order Sock 2161 of the pour is pushed by Jolt's position solve from y 0.172 to y -0.051 in one
  step (tick 416); the Mess puts the step back 0.01 higher (core/50) in its next tick. The case sampled heights
  before the Mess's tick, so it read that repair as a 0.233 m bounce. Now each tick's heights count one tick
  later, and not when the Mess put a push back in between (`MessMoving.pushed_in`). The fail line names the count.
  No game number changed.
- Files: tests/flight_start_test.gd
- Verified: `--only=flight_start` 10 runs, each `PASS 48 checks, 7 cases`; touched `PASS 123 checks, 16 cases`
- Merged: 725b4997 (2026-11-24, branch core/69-flight-start-heap-bounce-flaky)
