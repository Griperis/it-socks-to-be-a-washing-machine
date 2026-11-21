# The Mess

Every loose Sock of a level as one Part (`game/mess/`, core/13). Read this before you change how
Socks lie, are drawn, move or wake.

## Who owns what

| File | Owns |
|---|---|
| `mess.gd` (`Mess`, the Part) | The records (designs, states, poses, throws, mates), the patches other Parts' answers use, the Host-only `rest`, `wake`, `fall`, `_show` (only the changed records, a split search over the packed arrays), lending a lying Sock its Looks, the flights' Looks and drawing |
| `mess_bodies.gd` (`MessBodies`) | Each lying Sock's static body in the physics server (no node), its RID to Sock id, and the queries over them through `PhysicsQueries` |
| `mess_drawing.gd` (`MessDrawing`) | The MultiMeshes: one per 8 m floor cell and shape for lying Socks, one per shape for flights without a Looks; a CPU copy of each buffer (never read back), flushed once a frame |
| `mess_moving.gd` (`MessMoving`) | The Host's flights (`flight.tscn`, `ball_flight.tscn`): the budget, the wait queue, starts and rests, hits, picks' column wakes, Door and drawer sweeps |
| `mess_tuning.gd` + `.tres` (`MessTuning`) | The numbers of the above |

## The tiers

- LYING: a server body on `Mess.LAYER_LYING` (two boxes, leg and foot; a Pair a sphere) and one
  MultiMesh instance. The crosshair reads `RayCast3D.get_collider_rid()` and asks `Mess.sock_at(rid)`.
- A lying Sock someone needs as a scene (the aimed one) asks `looks_of(sock)`: its Looks is lent, the
  instance hides; `return_looks(sock)` gives it back.
- HELD: nothing of the Mess (the HeldView draws it).
- FLYING: a RigidBody3D under `flights` (the spawner's path), drawn by the flying MultiMesh, or with a
  `Looks` child (cloth) for the `flying_cap` nearest the camera.

## Flows

- A pick: the Hands' answer writes HELD; `_show` notes the picked box; next tick `MessMoving` queries
  the column over it and queues what lay on it; they start as `fall` within the budget.
- A hit: a flight at `wake_speed` or more touching a lying body (read from its body state's contacts)
  queues that Sock and up to `wake_count` touching it; they start as `wake`.
- A Door or drawer: every `Openable` is in the group `openables`; while it animates, the Host sweeps
  its AnimatableBody3D shapes over the lying bodies and wakes those at once.
- A rest: still for `rest_time` (or Jolt asleep) asks `rest`; out of bounds or inside a wall, at the
  return spot.

## Gotchas

- A flight flies as the same leg and foot boxes it lies on (`MessBodies.parts_at`), with
  `MessTuning.turn_weight` times its flat box's inertia (a 50 g board's own spins to Jolt's cap on an
  edge landing), and sweeps (CCD) only from 1 m/s (core/23). Poured and dropped Socks fly as woken ones.
- A drop and a Throw leave from the hand (`Hands.start_of`, Q2356, Q2367) on an arc solved by `Arc`;
  a drop's launch is in `throws` with `"drop": true` (never shelved, wakes nothing).

- Packed arrays in a Dictionary are values: take one out before writing it in place (`MessDrawing`).
- The instance buffer layout (transform rows, colour, custom) is the old game's; the custom data is
  `MessDrawing.look_data()`, read by the sock shader (`game/sock/sock_pattern.gdshader`, assets/01).
- A MultiMesh's shape is a Collection's (`shape_of()`: its model, or `ball:<collection>` for its sock
  ball), with that Collection's `SockLook.instance_material()`; shapes are added as first drawn. The
  lying boxes still fit the crew model for every shape (`BOX_LOOKS`).
- **No MultiMesh of the Mess is physics-interpolated** (`MessDrawing._new_instance`, core/31, Q2407). The project
  has physics interpolation on, and the engine then draws a MultiMesh's instances between the buffer of the tick
  before and this one: a Sock just come to rest was not drawn for a whole tick (its row was zeros before), and
  every row that changed its Sock (the flying rows closing up after a rest, a cell's last row moved into a freed
  one) was drawn for a tick smeared between two Socks' places: the "teleport" at every rest. Lying Socks do not
  move, and the flying rows are written each frame from poses already interpolated.
- The falling bodies are known by Sock id as they enter and leave `flights` (`Mess._flight_by_sock`, signals of
  the holder, so a Guest's spawned copies count); `moving_body()` is a lookup, never a walk over the children.
  `give_looks()` runs once per change that started bodies and once a tick, and leaves at once while the
  `flying_cap` nearest already have a Looks.
- With nothing flying, `Mess._process` builds and uploads nothing; each flying MultiMesh keeps its buffer.
- Godot's `TIME_PHYSICS_PROCESS` monitor is not a tick's cost (it stayed about 26 ms both before and
  after this rewrite while 124 ticks ran in 2 s); time a tick from its first `_physics_process`.

## Benchmark

`tools/mess_bench.sh` (core/31; on the designer's PC `tools/mess_bench.cmd`, `docs/human/mess-benchmark.md`) runs
named scenarios on the real Mess in a level of its own, headless in its own mirror with the worker pool capped at 4
threads, prints one `BENCH` line per scenario and a verdict line (`PASS mess bench ...` / `FAIL mess bench ...`),
and writes `builds/mess-bench/report.md` (or `OUT=<folder>`). Every run kept in that folder
(`results-<label>.json`) stands side by side in the report.

```bash
tools/mess_bench.sh                         # every scenario on this checkout (a few minutes)
tools/mess_bench.sh --only=pour_500,settle_500 --label=trial
tools/mess_bench.sh --at=<commit>           # the same scenarios on an older commit (a temporary worktree)
tools/mess_bench.sh --window                # under Xvfb: draw calls are counted
BENCH_OVERRIDE=$'[physics]\njolt_physics_3d/simulation/penetration_slop=0.005\n' tools/mess_bench.sh --only=settle_500
```

### From the game's command line (core/35, Q2416)

The benchmark is part of the game in debug builds: the `GameCli` autoload (`game/debug/game_cli.gd`, one const
table `BENCHES`, so the next benchmark is one more entry) reads the user arguments after `--` and starts it. The
same exe the designer plays runs it, with no project folder and no script beside it:

```
"It Socks.exe" -- --bench=mess --only=idle_500        # a debug export, or
godot --path <project> -- --bench=mess                # the editor exe
... -- --help                                         # the commands; unknown flag: help and exit code 2
... -- --scene=heap                                   # start a zoo station (or a res:// scene) instead of the main scene
```

- Release build (`not OS.is_debug_build()`): every command is refused with one printed line and the game starts.
- Results go to `user://bench/mess/` (Windows `%APPDATA%\Godot\app_userdata\It Socks\bench\mess\`); the last
  line printed is `BENCH saved <absolute folder>`; `--out=` overrides. Exit code 0 on PASS, 1 on FAIL.
- Drawn by default (real frame times and draw calls on that card); the engine's `--headless` before the `--` still
  works, and the report's machine line says which.
- Pacing: a tick is timed between two ticks of one frame, so the run needs several ticks a frame. `tools/mess_bench.sh`
  and `.cmd` pass the engine's `--fixed-fps 10` (as fast as the CPU goes). Started without it, `MessBench` sets
  `Engine.max_fps = 10` (six ticks a frame, in real time, so a run takes as long as its game seconds); the report says
  "paced at 10 frames a second" or "fixed 10 frames a second".
- Worker threads: the cap is an engine setting read at start and the command line cannot set it. The wrappers write an
  `override.cfg` (4 threads); started from the game exe the report says "worker pool uncapped".
- `tools/mess_bench.sh` and `.cmd` are thin wrappers over `-- --bench=mess` (the mirror, `--at=<commit>`, which starts
  an older commit's copied scene by its path because that commit has no `GameCli`, and the side-by-side report stay in
  the `.sh`).

**A debug export must keep, a release export must leave out** (for the release-export ticket's preset, which does not
exist yet): `res://game/debug/*` (`GameCli`, the benchmark's scenes, scripts and `.tres` plans, `mess_checks.tres`,
`mess_watch.gd`) and the zoo stations `--scene=` names (`res://game/zoo/*`). In a release preset exclude both folders
and remove the `GameCli` and `ProfilerBoot` autoloads (or keep `GameCli` alone, since it refuses in release; then the
`BENCHES` scenes it names must still load or its table must be emptied). `GameCli.plan()` already refuses in a release
build, so the exclusion is for size and for not shipping the benchmark, not for safety.

| File (`game/debug/`) | Owns |
|---|---|
| `mess_bench_plan.tres` (`MessBenchPlan`, `MessBenchScenario`) | The scenarios as data, the seed, the tick budgets. A new scenario is a new entry, no code |
| `mess_bench_level.tscn` (`MessBenchLevel`) | The level: floor, a pen under the heap station's spout, a Door, a drawer, one Mess and its Parts. It stacks the Socks that lie there from the start (by rule, no physics) and does a scenario's act through the game's seams (the spout's `more`, `Mess.thrown_patch`, `Openable.use`) |
| `mess_bench.gd` (`MessBench`) | The runner: a fresh level per scenario, the `BENCH` lines, the verdict |
| `mess_bench_clock.gd` (`MessBenchClock`) | A tick's cost (between two `physics_frame`s of one frame: the run is `--fixed-fps 10`, six ticks a frame), the scripts' share of it, a frame's scripts |
| `mess_watch.gd` (`MessWatch`), `mess_checks.tres` (`MessChecks`) | The faults, counted from the falling bodies only (the same cost at 500 and 10,000 Socks), and their limits. The suite uses it too (`tests/mess_settle_test.gd`) |
| `mess_bench_report.gd` (`MessBenchReport`) | `results-<label>.json` and `report.md` |

| Scenario | Measures |
|---|---|
| `idle_500`, `idle_2000`, `idle_10000` | A tick and a frame's scripts with that many Socks lying and nothing moving (the lying tier must cost nothing per tick) |
| `pour_500`, `pour_2000` | The spout pouring that many, timed while it pours: the moving budget full of falling bodies |
| `settle_500`, `settle_2000` | The same pour, timed from its last wave until every Sock lies: time to settle, and the heap's faults at rest |
| `burst_16` | 16 Throws in one tick into 500 stacked Socks: hits, wakes, the heap resting again |
| `sweep` | A Door and a drawer opened and shut through 160 lying Socks: the movers' sweeps and wakes |

Faults (`MessWatch`): never (still moving at the limit), lost (came back at the return spot), hot (written lying
while turning or moving fast), jumped (snapped at its rest), flips (turned faster than `flip_spin`), jitter (woken
`jitter_wakes` times or more), sunk (lowest point under the floor), inside (its leg's or foot's middle in another
Sock). A scenario with one, or with its 95th-percentile tick over the budget, fails the run.
