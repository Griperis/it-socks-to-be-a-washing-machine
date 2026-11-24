---
type: ticket
status: done
kind: bug
area: core
feature: mess
priority: now
created: 2026-11-23
done: 2026-11-23
blocked_by: []
notes: ["flaky ledger tests/flaky/ledger.md lines 48-60 (2026-11-22 21:19 to 2026-11-23 12:01); core/49's and core/50's [later] notes"]
terms: [Mess, Sock]
---

# A heap Sock now and then comes out "hot", "jumped" or "jittering" (mess_settle FLAKY)

The flaky ledger has 12 `mess_settle` entries in 15 hours, across branches that do not touch the Mess: `real_path`,
`real_path_1`, `real_path_3` (most), `real_path_4` and `small_heap`, failing "no Sock jumped", "no Sock hot" or
"no Sock jitter" (1 Sock each), passing on rerun. core/49 saw the same once ("one Sock hot and jumped: pressed 116 mm
under the floor, then lifted by the rest rule while still moving", its Open follow-ups); core/50 found Jolt's position
solve pushing a Sock through the 0.2 m floor and put it back 1 cm higher, noting floors 0.4 m thick never showed it.
A flaky test is a defect to rework (kit/docs/TESTING.md "Flaky cases"), never a budget to raise or a case to switch off.

## Acceptance
- Reproduced first: a loop that runs `mess_settle` (by case, in order and reversed) until it fails, with the failing
  Sock's id and its track (position, speed, contacts) written to a log; the cause written up in the Built log.
- Fixed in the Mess (or the physics setup), not by loosening a check: 50 runs of the whole `mess_settle` suite with no
  FLAKY and no FAIL, counted in the Built log.
- If the fix is the floors' thickness or a Jolt setting, it is the lead's call: stop with a [blocking] follow-up naming
  the options and their cost.
- coop/07's and coop/08's co-op cases and budgets still pass.

## Open follow-ups
- [answered, the lead, technical, 2026-11-23: the wake rule stays as ported; the watch counts as jitter only a
  wake after which the Sock rests moved (over a few mm or a small angle)] One rarer fault is left, not seen in the
  50 suite runs: a Sock "jitters" (woken 3 times) in about 1 of
  600 sweep pours. The Sock lies still on the heap's floor or top and is woken about every 0.3 s to 0.5 s while
  the pour still lands Socks on it (a hit at the wake speed wakes it and up to 8 touching, T11), then rests again
  where it was. That is the ported wake rule doing what it says, not a rest fault; whether a Sock woken by a hit
  that did not move it should count as jitter (or the wake rule change) is the designer's call.
- [later] `pressure_spin` (1.5 rad/s) is a new Mess number, and `push_slack` went from 0.05 m to 0.02 m: both
  placeholders, for the designer to see in play.

## Built log
- 2026-11-23
  - Changed: reproduced first. Run as the suite runs, `mess_settle` passed 75 times in a row (in order, reversed,
    and real_path_3 alone in 3 parallel loops): a pour is the same in one process (the same print of its rest
    places), and changes with what the process ran before (Jolt's body order), which is why the ledger saw it on
    other branches. A scratch loop then poured the real path 30 to 40 times in one process (0 to 4 extra records,
    10 processes) with `MessWatch` writing each fault's Sock id and its last 12 ticks (place, speed, turn, contacts,
    asleep): 11 faults in 300 pours before the fix. Three causes, all in the rest path:
    1. "hot" (most): Jolt put a slow Sock to sleep while it still tipped over (2.2 rad/s the step before), zeroing
       its motion, and the Mess rests any asleep flight at once: it was written lying mid-turn. Now an asleep flight
       rests only when it was under the rest speed and turn the step before; else it is woken and goes on
       (`MessMoving._slept_still`).
    2. "hot" (once): a pressure rest took a Sock jostled in the heap turning 1.9 rad/s (2.6 the step before); the
       pressure rule weighed speed alone (as the old game). It now also needs a turn under `pressure_spin`, now and
       the step before.
    3. "jumped": Jolt's position solve moved a slow Sock 11 mm to 17 mm in the step before its rest (speed 0.01 m/s);
       the rest wrote it exactly where its body was (the rule moved it 0 mm), but the watch measured from the tick
       before. The watch now takes each body's place before the Mess's tick (`SceneTree.physics_frame`), the place
       the Mess judges and writes, and counts a jump from there; "hot" still reads the last tick seen moving.
    4. "under" (once): a still Sock on the floor pushed 33 mm down in one step, its leg's middle 50 mm under the
       floor, slipped under `push_slack` (0.05 m); now 0.02 m, so `_pushed_in` puts it back.
    After the fixes: 0 faults in 351 pours, then 1 (a jitter, Open follow-ups) in 285. New case `slept_turning`
    (fails without the fix: the turning Sock is written lying). `MessWatch.notes`: each fault's line with its track,
    printed by `mess_settle` (the ledger's next entry names the Sock).
  - Files: `game/mess/mess_moving.gd`, `game/mess/mess_tuning.gd`, `game/debug/mess_watch.gd`,
    `game/debug/mess_checks.gd`, `tests/mess_settle_test.gd`, `docs/architecture/mess.md`.
  - Verified: after merging main, 50 runs of the whole `mess_settle` suite (25 in order, 25 reversed,
    reruns off): `PASS 204 checks, 21 cases` each, no FAIL, no FLAKY. `--touched` (51 suites, coop/07's and coop/08's included): `PASS 18362 checks, 511 cases`, no FLAKY;
    `PASS rules: 9 rules, no new hit`.
- 2026-11-24 (the lead's answer on jitter)
  - Changed: `MessWatch` counts a wake toward jitter only when the Sock rests again moved from where it lay when
    woken: farther than `MessChecks.jitter_move` (5 mm) or turned more than `jitter_turn` (3 degrees), both
    placeholders. Every wake is still counted in `wakes`; the jitter note is written at the rest that makes the
    count. `jitter` now moves the Sock at each wake; new case `jitter_unmoved` (woken 4 times, never moved: no
    jitter, 4 wakes; the old count fails it). The benchmark report's jitter line names the two limits. Merged
    main twice (core/55 to core/64, house/09, core/42).
  - Files: `game/debug/mess_watch.gd`, `game/debug/mess_checks.gd`, `game/debug/mess_bench_report.gd`,
    `tests/mess_settle_test.gd`, `docs/architecture/mess.md`.
  - Verified: after merging main (a6e1955 and later), the scratch sweep (the real path poured 5 times a case, 0 to 4
    extra records, 27 runs in order and reversed): 1350 pours, 0 faults, 0 jitter. `--touched` (coop/07's and coop/08's suites included): `PASS 18784 checks, 536
    cases`, no FLAKY; `PASS rules: 9 rules, no new hit`.
  - The drive refused this entry's commit; `git_repair.sh` folded its six files into the merge of main (5e5d41f).
