# Run the Mess benchmark on your PC

## What this is for

The Mess benchmark measures what the Socks cost and whether a heap settles cleanly: Socks lying still (500, 2,000, 10,000), a pour from the spout, the heap coming to rest, 16 Throws into a heap, a Door and a drawer pushed through lying Socks. The numbers from the sandbox are a slow CPU with nothing drawn. Your PC is the reference: it has the real graphics card, so only your run says what a frame costs.

## Run it from the game

The game itself runs the benchmark in a debug build (the editor, or a debug export), with the same exe you play and no project folder:

```
"It Socks.exe" -- --bench=mess
"It Socks.exe" -- --bench=mess --only=idle_500,sweep --label=my-pc
"It Socks.exe" -- --help
```

(With the editor exe: `Godot_v4.7.x-stable_win64.exe --path <project folder> -- --bench=mess`.) The window shows the run and the frame times and draw calls are your graphics card's. When it ends, the last line is `BENCH saved <folder>`: the report (`report.md`) and the results are there, by default in `%APPDATA%\Godot\app_userdata\It Socks\bench\mess\`. `--out=<folder>` puts them elsewhere. A run this way takes as long as the game seconds it simulates (it is paced at 10 frames a second), and Godot's worker threads are not capped (the report says "uncapped"). A release build refuses the command and starts the game.

## Run it with the script

These scripts start the same command with the engine's own `--fixed-fps 10` (faster) and cap the threads at 4:


1. You need the Godot 4.7 editor for Windows as two files: `Godot_v4.7.x-stable_win64.exe` and `Godot_v4.7.x-stable_win64_console.exe`. Put both in the project's `extras\` folder. Or set the environment variable `GODOT` to the console exe's path.
2. Shut the Godot editor if this project is open in it.
3. Double-click `tools\mess_bench.cmd`. A window opens and runs the scenarios one after another. It takes a few minutes. Leave the PC alone while it runs.
4. When it says `PASS mess bench ...` or `FAIL mess bench ...`, press a key. The report is `builds\mess-bench\report.md`.

From a terminal in the project folder you can pass options:

```
tools\mess_bench.cmd --list                    the scenarios
tools\mess_bench.cmd --only=pour_500,settle_500
tools\mess_bench.cmd --label=my-pc-after-fix   the run's name in the report
```

## Read the report

- **Side by side:** one row per scenario, one group of columns per run kept in `builds\mess-bench\`. A run with a new `--label` adds a group; a run with the same label replaces its own. So "before" and "after" stand next to each other.
- **Tick ms** is what one physics tick costs: every script's physics work plus the physics step. At 60 ticks a second a tick has 16.7 ms; the benchmark fails a scenario over 8 ms (95th percentile).
- **Whole frame ms** and **Draw calls** are filled only in a windowed run like yours.
- **Faults** are counted, not judged by eye: Socks that never settle, are lost, rest while still turning, jump when they rest, flip, jitter between lying and moving, sink under the floor or end inside another Sock. The limits are in `game/debug/mess_checks.tres`; open it in the inspector to change one.

## Change or add a scenario

Open `game/debug/mess_bench_plan.tres` in the inspector. `Scenarios` is the list. A scenario has a `Kind` (idle, pour, burst, sweep), how many Socks lie there before it starts, how many it pours or throws, which part is timed, and its time limit. Add an element, give it a new `Id`, save. No code changes.

## What bites

- The script writes an `override.cfg` beside `project.godot` for the run (it caps Godot's worker threads at 4, as the old game's stress test did) and deletes it afterwards. If you stop the run by closing the terminal, delete `override.cfg` yourself.
- Send back `builds\mess-bench\report.md` (and the `results-*.json` beside it): `builds\` is not in git.
- A debug editor build is slower than an exported release build. Compare runs made the same way.
