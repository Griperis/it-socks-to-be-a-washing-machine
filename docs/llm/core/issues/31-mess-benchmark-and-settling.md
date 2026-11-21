---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: core
priority: now
created: 2026-11-21
done:
blocked_by: []
notes: []
terms: []
---

# The Mess benchmark, and why it settles wrong and lags

The designer, playing `main` after core/23 and core/27 (Q2405, 2026-11-21): the Socks Mess "still doesn't settle
correctly, some socks glitch out and it's much laggier than before". Two jobs, in this order:

1. **A Mess performance benchmark**, modelled on the old game's (Q2406): read `reference/it-socks/tools/stress.sh`,
   `reference/it-socks/game/debug/physics_stress.gd`, `reference/it-socks/docs/perf/tools.md` and
   `reference/it-socks/docs/perf/low-end-report.md` for how it was done (named scenarios, headless in a mirror,
   worker threads capped, one `STRESS` line per run, a markdown report, a Windows `.cmd` for the designer's PC),
   and keep the new code well structured: scenarios as data (a typed Resource per scenario or one list), one
   runner, one report writer; no copy of the old file's shape where a cleaner one does.
2. **Reproduce, then diagnose and fix** the settling faults, the glitching Socks and the lag, using the benchmark.

## Behaviour list
- B1 `tools/mess_bench.sh` (and `tools/mess_bench.cmd` for the designer's Windows PC) runs named scenarios on the
  real Mess in a scene of its own, headless, and prints one `BENCH` line per scenario and a verdict line; the
  report goes to `builds/mess-bench/report.md` (or `OUT=`). Scenarios at least: idle with N lying Socks
  (500, 2,000, 10,000); a heap pour of N; settling after a pour until every Sock lies; a burst of 16 throws into
  a heap; a door and a drawer sweeping through lying Socks. Per scenario: physics tick ms (median, p95, worst),
  render-frame ms where it can be measured, moving count over time, time to settle, Socks lost, Socks that never
  settle, wakes per second, node and draw-call counts.
- B2 The same scenarios can run on an older commit, so "laggier than before" is measured, not guessed: run the
  bench (or its nearest equivalent) at the commits before core/23 (`git log --oneline -- game/mess`) and on
  `main`, and put the table in the report. Compare with the old game's own numbers where the old reports have
  matching scenarios.
- B3 "Settles correctly" and "glitches" are pinned down as checks the bench (and the suite) can count: e.g. a Sock
  that rests with a turn rate above a threshold, a Sock that jitters between lying and moving more than k times,
  a Sock inside another Sock or below the floor, a Sock that flips on landing, a heap that never reaches zero
  moving Socks. Record what you saw in a strip or stills in `builds/review-core-31/` (`review-material` skill).
- B4 Fix the causes you find. Start from the review's Mess findings, which are yours here:
  - `mess_drawing.gd:213-226` `draw_flying` allocates and uploads a buffer per shape every frame, even with no
    flights;
  - `mess.gd:226, 752-759` `moving_body` walks every child and builds a String per call (from `is_moving`,
    `where_of`, `sock_of_hit`, `HeldView._grow` each frame; `_launch` calls `give_looks` per start); keep a
    `_flight_by_sock` Dictionary and call `give_looks` once per tick;
  - `flight.tscn` `max_contacts_reported = 4` with `mess_moving.gd:228`: a hit may miss the Sock it struck (raise
    to 8 if the bench shows missed wakes);
  - whatever core/23's rigid-board physics (`MessTuning.turn_weight` = 3, pours as woken Socks, CCD) costs.
  A fix that changes how the Socks look or move (a tuning number, the rest rule) stops at its first strip and
  waits for the designer's go (`CLAUDE.md` "Look and feel work stops at its first still"); a fix that only
  removes cost or a plain bug goes in.
- B5 The Mess stays the one bulk system it is (the two tiers, the Host-only Commands, `PROTOCOL` unchanged); the
  whole-array patches are core/32's, not this ticket's.

## Acceptance
- The bench runs here and prints its lines; the report holds the before/after table (older commit vs `main` vs
  this branch).
- Each fault the designer named is either reproduced with a count in the report and fixed, or reported as not
  reproduced with what was tried.
- Real-path case: in the zoo's heap station the player presses the pour button; the heap pours, settles to zero
  moving Socks within the bench's limit, with none lost or glitching by B3's checks.
- Suite cases for B3's checks on a small heap (fast enough for the suite); the bench itself is not in the suite.
- `docs/architecture/mess.md` gains a "Benchmark" section (how to run it, what each scenario measures);
  `docs/human/` gains a short page on running it on the designer's PC.

## Answers
- The Mess settles wrongly, glitches and lags; one Fable agent reproduces it and builds the benchmark
  (Q2405, 2026-11-21).
- The benchmark is modelled on the old game's stress test, kept well structured (Q2406, 2026-11-21).

## Open follow-ups

## Built log
- Model: Fable, on the designer's word (Q2405): hard physics debugging and a new tool.
