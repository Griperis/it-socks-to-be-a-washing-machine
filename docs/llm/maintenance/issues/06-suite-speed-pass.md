---
type: ticket
status: done
kind: maintenance
area: maintenance
feature: tests
priority: now
created: 2026-11-25
done:
blocked_by: []
notes: ["suggested model: opus", "designer 2026-11-25 (Q2666): an agent does a speed pass", "runs when no other ticket edits tests/ in the same suites"]
terms: []
---

# The full suite under 120 s again, without weakening a test

The full run grew from about 129 s to 200-290 s during batch A (`SLOW the whole suite took ...` on every merge;
604 s under load). Every merge and every agent run pays for it: tests were about 45% of the agents' tool time
(13 h of 28 h, 23-25 Nov). maintenance/02 and 03 looked at this before; read them and their numbers first.

## What to do
1. Measure: per suite and per case, wall time and what it waits on (`kit/tools/run.sh --verbose`, the runner's
   saved times, `--jobs`). List the 20 slowest cases and where the time goes in each: scene loading, house
   generation, fixed waits, physics settling, two-machine co-op handshakes, frames waited for nothing.
2. Speed them up without weakening a check:
   - replace fixed frame or second waits with `_until(condition)`;
   - share an expensive fixture within a suite where cases don't change it;
   - load a lighter scene where the case doesn't need the house;
   - shorten a timer through its tuning in the test, not in the game;
   - split a huge suite so it spreads over the slots.
   A case may move to the on-demand `"stress": true` lane only when its check is covered elsewhere; name it.
3. Keep the real-path cases real (`kit/docs/TESTING.md` "The real path").

## Acceptance
- The full run (`kit/tools/run.sh`) on this machine with nothing else running: under 120 s, or the best reached
  with what stands in the way, measured three times. Before and after numbers in the report.
- Same check and case counts, or every removed or moved case named with where its check now lives.
- Nothing flaky: the suites that changed pass `--reverse` and `--seed=7` too.
- Game behaviour unchanged; only tests and test support change (a tuning hook for tests is fine).

## Answers
- Q2688 (designer, 2026-11-26): yes; kit 12dacfa holds the gate 0.2 s while a run is alone, 1 s while another
  is live. The question was: (kit, the lead's) The full run is start-limited, not test-limited: `kit/tools/run.py` holds the
  machine-wide start gate `START_GAP = 1.0` s per process, so 101 processes take at least ~116 s to start
  (suites phase 140 s at 719 s of process time, where 8 slots need ~90 s). Measured on this tree, idle,
  with START_GAP patched to 0.2 in the Python process (kit not edited): 120 s whole run (suites 98 s,
  check 8 s, timing lane 14 s) against 169 s unpatched. Under 120 s needs a shorter gap (or none
  within one run, whose own processes headroom_kb() already counts).

## Open follow-ups
- [later] (the lead) Each process costs ~1.4 s before its first case (engine boot ~1 s, then the
  runner's knob discovery loading every class); 96 suites are 96+ processes. Merging small suites would
  cut starts and boots, but renames case ids that tickets' `suites:` name: not done.
- Check count 23152 -> 23146: coop_stacking walks its carried loop once a process for carried_loop and
  carried_loop_seen (same numbers, each case still makes all its rule checks); the 6 set-up checks of
  the second walk ("the Host hosts", "B's jump is a climb onto A's back", "B rides A's back", at 0 and
  50 ms) are no longer repeated. Cases 767, unchanged; none moved to stress.

## Built log
