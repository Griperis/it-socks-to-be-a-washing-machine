---
type: ticket
status: done
kind: build
area: core
feature: core
priority: now
created: 2026-11-21
done: 2026-11-21
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

**The designer pinned the glitch down (Q2407): "when socks settle - they teleport and there is a visible glitch".**
That is the switch from a moving Sock (RigidBody flight) to a lying Sock (server static body plus a MultiMesh
instance) in `mess_moving.gd` `_settle`/`_rest`, `mess.gd` `put_down`/`return_pose`/`_lie`/`_draw_lying`, and the
lying draw in `mess_drawing.gd`. core/21 (`21-rest-blip.md`, ready-for-human) studied this before and found the
switch pixel-identical in a still; the designer still sees it in play, so measure it in motion: record the drawn
transform of one Sock every frame across its rest (flight Looks, then MultiMesh row) and show any jump in position,
turn, scale, Design/look data or a frame where it is drawn twice or not at all, in a strip at full frame rate.
Suspects to rule in or out: `put_down` snapping the pose (`return_pose`, a lost-rule ray moving it), the size scale
written three ways (`Mess._scale`, `MessDrawing._size`, `mess_moving.gd:416`), a cell MultiMesh flushed a frame
after the flight is freed (or before), the flight's physics interpolation vs. the MultiMesh's none, the flight's
cloth bend vs. the straight lying mesh, LOD or material differences between the two tiers.

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
- Sunk Socks are left as they are (Q2412, 2026-11-21).
- Flips on edge-first hits accepted for now; turn_weight stays 3 (Q2413, 2026-11-21).
- Merges as built after its complexity report (Q2414, 2026-11-21).
- The Mess settles wrongly, glitches and lags; one Fable agent reproduces it and builds the benchmark
  (Q2405, 2026-11-21).
- The benchmark is modelled on the old game's stress test, kept well structured (Q2406, 2026-11-21).

## Open follow-ups
- [answered, Q2412: leave it] Sunk Socks. 3 to 5 of 500 poured Socks (3 of 2,000 on the benchmark's floor, 5 of 500 at the zoo's heap
  station) rest pressed up to 20 mm into the floor, a Sock being 26 mm thick. Cause: Jolt lets bodies overlap by its
  `penetration_slop`, 20 mm by default, and a Sock under the heap is written lying while pressed in. Trial
  (`BENCH_OVERRIDE`, `settle_500`): with the slop at 5 mm none sinks, the tick costs the same and the heap settles in
  4.0 s instead of 4.8. Which: (a) lower `physics/jolt_physics_3d/simulation/penetration_slop` to 5 mm in
  `project.godot` (every body of the game then settles tighter; a strip of the heap first), (b) the rest rule lifts a
  sunk Sock onto the floor as it comes to rest (a snap of up to 2 cm), (c) leave it? Until then the real-path case
  counts sunk Socks and does not hold them at none.
- [answered, Q2413: accepted for now, turn_weight stays 3] Flips. A Sock landing on its edge still turns faster than 25 rad/s for a tick or two: 7 of 500 poured
  from the spout's 2.6 m (fastest 31 rad/s), 10 of 16 thrown at 7 m/s into a heap (47 rad/s, Jolt's cap). Before
  core/23 it was 338 of 500, so `turn_weight` 3 did most of it (a trial at 1: 59 of 500). Is that rest good enough
  (then the limit in `game/debug/mess_checks.tres` goes up or the count is accepted), or should `turn_weight` rise
  further (a strip first: it also slows a Throw's spin and the topple flat)?
- [later] Jitter. Pouring onto Socks that already lie wakes the same Sock three times or more (50 to 62 of 2,000):
  each fast body wakes what it hits and up to `wake_count` round it. The old game's rule; before core/23 the count
  was the same (51 to 104). Is a pour meant to stir the heap so?
- [later] A Door or drawer shut onto lying Socks leaves some squeezed: in `sweep` (160 Socks) 3 sunk, 2 inside
  another, 2 lifted by the sunk rule (a 28 cm snap at most), and in some runs 1 to 3 "lost": resting inside the leaf
  they come back at the return spot with a pop, as the lost rule says (T08). Keep that rule for a Door, or push the
  Sock out of the leaf instead?
- [later] core/23's two boxes (leg and foot) cost about 15 % of a pouring tick against one box (4.3 against 3.7 ms
  median, and 480 more nodes); its CCD from 1 m/s and `turn_weight` cost nothing measurable. Not changed: one box
  brought lost Socks back (3 of 500).
- [later] `flight.tscn` `max_contacts_reported` stays 4: with 8 the benchmark found no more hits on lying Socks
  (241 against 245 in `burst_16` and `settle_2000`) and the same wakes a second, though the list is full on 4 of 5
  fast contacts.
- [later] The switch still differs by a hair of shading between a flight's Looks and its lying instance (one pixel
  over 8 levels, 17 at most, in a 26 by 53 pixel patch of a 960 by 540 frame): core/21's.
- [later] `tools/mess_bench.cmd` was not run on Windows (no Windows here); it runs the editor exe on the project in
  place. The benchmark's scripts are in `game/debug/` and must stay out of a release export (`release-export`).
- [later] The lead's suspect, the rest's `Basis.from_euler(rot)` round trip: measured, not the cause. Both sides use
  Godot's default order; over 200,000 poses, half within 1e-9 to 1e-2 rad of edge-on, a basis axis moves 0.0008 rad
  at most (0.1 mm at a Sock's tip); the scale is put on by the drawing, and the body's origin is the pose's.
- [later] A Guest's spawned copy of a flight is found by its name (`Flight<id>`); a rest and a wake of one Sock in
  one tick adds the new body while the old still waits to be freed, and Godot then renames it. For M0.6.
- [later] Kit: a new script's `.uid` is only made in a tool's mirror; I copied each from the check mirror by hand.
  A tool that copies them back (or a line in `ticket-agent.md` saying where they come from) would save the search.

## Built log
- Model: Fable, on the designer's word (Q2405): hard physics debugging and a new tool.

### 2026-11-21
- Changed: the Mess benchmark (`tools/mess_bench.sh`, `.cmd`): nine scenarios as data, one runner, one report with
  runs side by side. The designer's glitch reproduced in motion and fixed: the Mess's MultiMeshes were
  physics-interpolated, so a Sock coming to rest was not drawn for a whole tick and the flying rows smeared between
  Socks' places at every rest; they no longer are. Cost removed: no upload with nothing flying, a flight found by Sock
  id, `give_looks` once per change, the Host's tick and the flying rows trimmed. `pour_500` tick median: 3.89 ms
  before core/23, 4.52 on `main`, 3.41 here; a frame's scripts 1.20, 1.17, 0.83 ms. Not fixed, counted, waiting
  for the designer: sunk Socks, flips (Open follow-ups).
- Files: `game/mess/mess.gd`, `mess_drawing.gd`, `mess_moving.gd`; `game/debug/mess_bench*`, `mess_watch.gd`,
  `mess_checks.*`; `tools/mess_bench.sh`, `.cmd`; `tests/mess_settle_test.gd`; `docs/architecture/mess.md`,
  `docs/human/mess-benchmark.md`.
- Verified: `kit/tools/run.sh --touched`: PASS 16271 checks, 375 cases; rules PASS; `builds/review-core-31/rest-blink-thrown-sock-240fps.png`, `heap-rest-smear-120fps.png`,
  `mess-bench/report.md`.
