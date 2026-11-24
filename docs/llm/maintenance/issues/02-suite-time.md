---
type: ticket
status: ready-for-agent
kind: maintenance
area: tools
feature: maintenance
priority: next
created: 2026-11-24
done:
blocked_by: []
notes: ["suggested model: sonnet", "the SLOW procedure: the lead-integrator skill, step 9"]
terms: []
---

# The full suite takes 150-260 s; bring it back under 120 s

## What happens
- integrate.sh prints SLOW on every merge today: 257 s (core/41), 235 s (core/54), 228 s (core/68), 230 s
  (house/08), 151 s (core/65). It was about 160 s on 2026-11-23. Each merge waits on it, and agents' `--touched`
  runs grow with it.

## Acceptance
- The slowest suites and cases measured and listed in the Built log with their seconds (kit/tools/run.sh prints
  `slowest:`), and why each is slow (long settles, real time waits, loading the house, many machines).
- The time cut without losing what a case checks: shared setup, shorter waits that still prove the same thing,
  physics ticks over real time where the case allows. No case removed or loosened without the lead's yes.
- The full suite under 120 s on this machine, three runs in a row, no FLAKY line.
- If a cut needs a kit change (the runner, parallel suites), stop with a [blocking] follow-up: the kit is the lead's.

## Open follow-ups

## Built log
