---
type: ticket
status: done
kind: build
area: tools
feature: core
priority: now
created: 2026-11-21
done:
blocked_by: []
notes: []
terms: []
---

# The game's command line, and the benchmarks in debug builds

The designer (Q2416, 2026-11-21): "could we have the benchmarks in the game debug builds? So it's easy to run it
anywhere - have a CLI for the game?" Today core/31's Mess benchmark is a scene that only `tools/mess_bench.sh` and
`.cmd` start, with the editor exe on the project folder. Afterwards the game itself takes a command line: the same
exe the designer plays (an editor run or any debug export) runs a benchmark and quits, with no project folder and no
script beside it.

## Behaviour list
- C1 One small boot node (an autoload, or the existing `ProfilerBoot` grown into it; one file, one class) reads the
  user arguments after `--` (`OS.get_cmdline_user_args()`) once at start. With none, the game starts as today.
  In a release build (`not OS.is_debug_build()`) every debug command is refused with one printed line and the game
  starts as today (the benchmarks never run there; Profily's rule, `CLAUDE.md` project values).
- C2 Commands, each a small entry (a Resource or a const table: name, scene, one-line help), so the next benchmark
  (the old game's graphics bench, a sound bench) is one more entry:
  - `--help` prints the commands and their options and quits;
  - `--bench=mess` runs core/31's Mess benchmark, with its existing options (`--only=`, `--list`, `--label=`,
    `--commit=`, `--out=`), then quits with exit code 0 on PASS and 1 on FAIL;
  - `--scene=<res path or station name>` starts that scene or zoo station instead of the main scene (the zoo
    stations by their file name: `--scene=heap`), for quick looks and repro.
  Unknown flags print the help and quit with code 2.
- C3 Where results go: by default `user://bench/<bench>/` (the report and results JSON), and the absolute folder is
  printed as the last line (`BENCH saved <path>`) so the player can find it; `--out=` overrides. On Windows that is
  `%APPDATA%\Godot\app_userdata\It Socks\bench\...` (or the project's user dir name), said in the help.
- C4 Run drawn or headless: drawn by default (a window: real frame times and draw calls on that machine's graphics
  card, which the designer's "laggy" needs); `--headless` (Godot's own) still works and the report says which.
  The worker-thread cap that `tools/mess_bench.sh` sets with an `override.cfg` is either applied from the command line
  (`--threads=4`, if Godot allows setting it at start) or written in the report as "uncapped" — say which.
- C5 `tools/mess_bench.sh` and `.cmd` become thin wrappers that start the game with `-- --bench=mess ...` (the mirror
  and the comparison of commits stay in the `.sh`); `docs/human/mess-benchmark.md` says first how to run it from the
  game exe: `"It Socks.exe" -- --bench=mess` (or the editor exe with `--path`), then the scripts.
- C6 Export: the benchmark's scenes and scripts in `game/debug/` are kept in a debug export and left out of a release
  export. No export preset exists yet (`export_presets.cfg` is the release-export skill's); write what a preset must
  include/exclude into `docs/architecture/mess.md` "Benchmark" so the preset ticket picks it up, and add it as a
  `[later]` follow-up here.

## Acceptance
- Real-path case: the game started with `-- --bench=mess --only=idle_500 --headless` (the suite's or a tool's own
  launch of the project) prints the `BENCH` line, the verdict and `BENCH saved <path>`, writes the report there and
  exits with code 0.
- Cases: no arguments start the main scene as before; `--help` lists `bench` and `scene`; an unknown flag exits 2;
  in a release-build stand-in (a static knob the test sets) `--bench` is refused and the game starts.
- `--scene=heap` starts the heap station.
- `tools/mess_bench.sh --only=idle_500` still works and gives the same numbers as before (within noise).

## Answers
- The benchmarks run from the game in debug builds, by a command line (Q2416, 2026-11-21).

## Open follow-ups
- [later] The export preset (release-export skill) must include/exclude `game/debug/` and the zoo as written in `docs/architecture/mess.md` "Benchmark" (C6); no preset exists yet.

## Built log
- Model: Sonnet: a boot node, a command table and wrappers.

- 2026-11-21: Changed: `GameCli` autoload (`GameCliBoot`; class and autoload names may not match) with a const `BENCHES` table, `--help`, `--bench=mess`, `--scene=`, exit 2 on an unknown flag, release refusal; it stays out of the way when the engine is given a scene or script (test runner, shots). `MessBench` default out `user://bench/mess`, prints `BENCH saved <path>`, needs the engine's `--fixed-fps 10` (the benchmark refuses to run without it, exit 2: nothing sets it at run time), report says threads capped/uncapped (the cap cannot be set from the command line). `tools/mess_bench.sh`/`.cmd` start `-- --bench=mess` (`--at=` starts the old commit's scene by path). Docs and export notes written.
  Files: game/debug/game_cli.gd, game/debug/mess_bench.gd, project.godot, tools/mess_bench.sh, tools/mess_bench.cmd, tests/game_cli_test.gd, docs/architecture/mess.md, docs/human/mess-benchmark.md.
  Verified: PASS 16766 checks, 393 cases; `bash tools/mess_bench.sh --only=idle_500` PASS (tick 0.009/0.015 ms). The zoo (main scene) still loads for one frame before a `--bench`/`--scene` start replaces it (Godot reads main_scene before autoloads); the get_node() ERROR it caused (the zoo's deferred start ran after the swap) is gone because the swap now waits a frame.
- 2026-11-21 (lead's fixes): Changed: the swap waits one frame, so the zoo's deferred start no longer hits a freed zoo (ERROR gone); the zoo itself still loads one frame (Godot reads main_scene before autoloads; only a boot scene as main scene or a re-exec would avoid it, both touch what the tools read as the main scene). Pacing: the engine hides its own flags from `OS.get_cmdline_args()`, and `Engine.time_scale` scales the physics delta (sim broken: lost 471) while `max_fps=10` is real time (hours), so nothing sets six ticks a frame at run time; `MessBench` counts its first frames' ticks and, under two a frame, prints one `FAIL mess bench: needs --fixed-fps 10 ...` line, exit 2. Exe form: `"It Socks.exe" --fixed-fps 10 -- --bench=mess`.
  Numbers (tick med/p95/worst ms): idle_500 exe 0.014/0.054/0.075, script 0.009/0.020/0.095; pour_500 exe 4.952/7.979/15.363, script 4.847/7.952/8.730 (both: flips 5, the counted-not-held fault of core/31, so pour_500 reads FAIL either way).
