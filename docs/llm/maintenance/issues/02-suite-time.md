---
type: ticket
status: done
kind: maintenance
area: tools
feature: maintenance
priority: next
created: 2026-11-24
done: 2026-11-24
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
- -> maintenance/03 (designer, 2026-11-24: merge part, measure later) [blocking] The full run cannot be judged against 120 s while other agents' runs share the machine: the slot pool is
  machine-wide (8 slots), and my full runs printed `waited 52s..89s for a test slot` (176 s and 230 s walls). The
  per-suite times sum to about 600 s of process time, so 8 slots give a floor near 75 s only on an idle machine.
  Needs the lead: a measurement on an idle machine, and perhaps a bigger pool (half the cores = 8 of 16 today) - kit.
- -> maintenance/03 (designer, 2026-11-24: merge part, measure later) [blocking] `run.py` prints only the 3 slowest cases of the whole run; per-case seconds need a kit option (a
  `--slowest=N` or a times file with case ids).
- -> maintenance/03 (designer, 2026-11-24: merge part, measure later) [later] Not cut, needs a decision: coop_hands and coop_hand_off at 2x clock failed on wall-time-shaped checks
  (`refusals: it still flies before 2 s`, `guest_waits: nothing before 2 s`, `throw_drop_pour_real_path` no-pop
  step); coop_mess, coop_flight, coop_respill measure bytes or ticks per wall second, so a faster clock changes
  what they print; coop_stacking's loops are LOOP_S wall seconds (18.5 s a case, the slowest in the run).

## Built log

### 2026-11-24
Changed: measured, then ran the game clock at 2x (`Engine.time_scale = 2`, one frame per physics tick, paced at 1/120 s;
the runner puts the scale back after every case) in coop_knockdown and room_doors. coop_knockdown's pose_bytes
case keeps 1x (it prints bytes per wall second). coop_knockdown real_path 17.8 s to 5.9 s, drag_ends 13.9 s to 4.5 s,
the suite from about 77 s of process time to about 35 s (under contention); room_doors no case over 3.5 s.
Measured (full run, 176 s wall, whole run under slot contention): suite process seconds: coop_knockdown 77,
coop_hands 64, coop_stacking 46, mess_settle 41, coop_mess 39, house 34, coop_hand_off 32, game_link 21,
sock_generator 21, zoo 18, heap 17, coop_flight 17, coop_respill 15, game_cli 12, save 12. Slowest cases:
coop_stacking carried_loop(_seen) 18.5 s (4 s loops times lag rounds, wall seconds), coop_knockdown real_path 17.9 s
(two rounds of paced ticks at 60 Hz wall time, a 5.5 s stand-up in game time), coop_respill respill_0ms 14.5 s.
Why slow: the co-op suites are paced to 60 frames a wall second so ENet and the lag peer see real time.
Tried and reverted: coop_hands, coop_hand_off at 2x (3 FAIL, see follow-ups).
Files: tests/coop_knockdown_test.gd, tests/room_doors_test.gd
Verified: knockdown PASS 162 checks, 8 cases (x3); room_doors PASS 194 checks, 6 cases (x3). Full suite NOT under 120 s: see follow-ups.
- Merged: fa635d07 (2026-11-24, branch maintenance/02-suite-time)
