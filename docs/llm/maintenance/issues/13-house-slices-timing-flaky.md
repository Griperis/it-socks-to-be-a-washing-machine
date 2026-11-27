---
type: ticket
status: ready-for-agent
kind: maintenance
area: maintenance
feature: frame
priority: next
created: 2026-11-27
blocked_by: []
notes: ["suggested model: opus", "left by the lead, 2026-11-27: the timing lane missed in 2 of 3 whole runs at merge, and in core/160's --touched"]
terms: [Mess]
suites: [house]
---

# The house's laying-slice timing case misses under load

`house:h09_slices_within_budget` (`tests/house_test.gd`) is a timing case (`"perf": true`). It fails when one slice of
the house's sliced laying runs past `LoadingTuning.slice_ms` (14 ms) on the wall clock. It passes alone, and failed:
- in the whole run of 2 of the last 3 merges (2026-11-27: assets/23+26+28, core/154+assets/25; the third, assets/27,
  passed);
- in core/160's `--touched` run: 4 of 191 laying slices past 14 ms, with 8 test processes running at once.

The kit's timing lane runs one timing case at a time, best 2 of 3. The other agents' and suites' processes still share
the machine. A timing case that misses because the machine is busy is a flaky test, which is a defect
(`kit/docs/TESTING.md` "Flaky cases").

## Do
1. Reproduce: run the case under the load of a whole run (for example `kit/tools/run.sh` with `--jobs` at its default
   while the case runs) and record how many slices miss and by how much (the case's log line).
2. Find whether the misses are the laying's own work (a slice that does too much: a fix in `Mess.lay_step` or the
   screen's slicing, which would also help a player's slow machine) or the machine's scheduling (a slice whose CPU time
   is in budget but whose wall time is not: the case measures the wrong clock). Say which, with the numbers.
3. Fix it at that cause. If it is the clock, measure what the laying controls (its CPU time per slice, or a check a
   busy machine cannot fail) and keep the case's intent: no slice of laying is long enough for a player to see a
   hitch. Never widen the budget or drop the case to make it pass.

## Acceptance
- The case passes in 10 whole runs in a row at the merge's load (the runs' verdict lines in the report), and fails when
  one slice is made to do a whole frame's laying (the check still catches a real hitch; say how you tried it).
- `slice_ms` is unchanged, and the player's loading (the house's laying over frames, the reveal) looks and takes as long as before.
- The suites named pass.

## Answers
- A flaky test is a defect to rework, never to tolerate or switch off (`kit/docs/TESTING.md`).
