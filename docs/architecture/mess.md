# The Mess

Every loose Sock of a level as one Part (`game/mess/`, core/13). Read this before you change how
Socks lie, are drawn, move or wake.

## Who owns what

| File | Owns |
|---|---|
| `mess.gd` (`Mess`, the Part) | The records (designs, states, poses, throws, mates), the patches other Parts' answers use, the Host-only `rest`, `wake`, `fall`, `_show` (only the changed records, a split search over the packed arrays), lending a lying Sock its Looks, the flights' Looks and drawing |
| `mess_bodies.gd` (`MessBodies`) | Each lying Sock's static body in the physics server (no node), its RID to Sock id, and the queries over them through `PhysicsQueries` |
| `mess_drawing.gd` (`MessDrawing`) | The MultiMeshes: one per 8 m floor cell and shape for lying Socks, one per shape for flights without a Looks; a CPU copy of each buffer (never read back), flushed once a frame |
| `mess_moving.gd` (`MessMoving`) | The flights (`flight.tscn`, `ball_flight.tscn`): on the Host the budget, the wait queue, starts and rests, hits, picks' column wakes, Door and drawer sweeps; on a Guest its looks-only bodies and its own sweeps (`tick_looks`, coop/08) |
| `mess_tuning.gd` + `.tres` (`MessTuning`) | The numbers of the above |

- Records also come from a level's Sock generator at the start (`GeneratedSocks`, read in `_ready` after the
  SockSpots) and from its `regenerate` answer (`taken_out_patch`, `added_lying_patch`); `add` with `"lying": true`
  appends LYING records with no launch (core/52, Q2523). `docs/architecture/sock-generator.md`.

## The tiers

- LYING: a server body on `Mess.LAYER_LYING` (two boxes, leg and foot; a Pair a sphere) and one
  MultiMesh instance. The crosshair reads `RayCast3D.get_collider_rid()` and asks `Mess.sock_at(rid)`.
- A lying Sock someone needs as a scene (the aimed one) asks `looks_of(sock)`: its Looks is lent, the
  instance hides; `return_looks(sock)` gives it back.
- HELD: nothing of the Mess (the HeldView draws it).
- FLYING: a RigidBody3D on every machine (coop/08), drawn by the flying MultiMesh, or with a `Looks` child
  (cloth) for the `flying_cap` nearest the camera. A Throw's body is the Host's, under `flights` (the
  spawner's path); every other (woken, fallen, poured, swept, dropped) is started by each machine from the
  record under the Mess's own `Bodies` holder, which no spawner sees. A Guest's is looks only, on
  `Mess.LAYER_LOOKS` (it touches the house, lying Socks and its other looks bodies), and never wakes, rests
  or writes anything shared; the Host's rest batch lies it, its drawing gliding from the body's place onto the
  rest pose over `MessTuning.rest_glide` (Q2577, `Mess._glides`; its lying body is there at once).

## Flows

- A pick: the Hands' answer writes HELD; `_show` notes the picked box; next tick `MessMoving` queries
  the column over it and queues what lay on it; they start as `fall` within the budget.
- Nothing under it (core/55, Q2531): the Host notes every Sock a generator lays (its start in
  `_add_generated`, a reseed's or any `add` "lying" in `added_lying_patch`) and, in `_show`, the box of every
  lying Sock taken out or cut off; next
  tick `_fall_unsupported` checks those and what lay over the boxes (`MessBodies.supported`: a slab of
  each leg and foot box's footprint, `support_reach` deep, under it meets the house or a lying Sock) and
  starts the ones with nothing under them as `fall`. No Sock stays frozen in the air.
- A hit: a flight at `wake_speed` or more touching a lying body (read from its body state's contacts)
  queues that Sock and up to `wake_count` touching it; they start as `wake`. A thrown flight (not dropped,
  poured or woken) first looks ahead (core/46, Q2431, the old `SockFlights._impact_wakes`): a `hit_reach`
  sphere `hit_lead_ticks` ticks along its motion wakes what it is about to meet, so their bodies exist
  before the contact and it pushes them (Jolt alone, no extra force, Q1215).
- A Door or drawer: every `Openable` is in the group `openables`; while it animates, the Host sweeps
  its AnimatableBody3D shapes over the lying bodies and wakes those at once. A Guest sweeps its own the
  same way (`Mess.lift`), records as they are; one the Host never woke goes back where it lay once still
  (`Mess.lie_again`).
- A rest: still for `rest_time` (or Jolt asleep) is noted, and at the tick's end every flight noted is
  asked as one `rest` (coop/07: one answer, one reliable message a tick, none when nothing rested, as the
  old game's settle stream); out of bounds or inside a wall, at the
  return spot (`Mess.put_down`). Its middle under a floor's top by less than `sunk`, it lies as it is (the
  old `sunk_floor`); deeper, up to `sunk_depth`, pushed up onto the floor.
- Pushed into the floor (core/50): Jolt's position solve can move a falling Sock 0.17 m to 0.24 m into
  a 0.2 m floor in one step (no velocity explains it; on a 0.4 m or 2 m floor it did not happen in the trials);
  past the floor's middle its bottom face then holds the Sock under it. Each tick, before anything else
  is judged of a flight, `MessMoving._pushed_in` compares its place with the tick before: moved farther
  than its speed and turn explain by more than `push_slack`, with the middle of its leg or foot inside
  the house, it goes back there `push_lift` higher (at the very same place Jolt pushes it again), its
  fall and turn stopped. A pressure rest (`_relieve`) never moves a Sock: one that `put_down` would lift
  or push flies on, and one moving at the pressure speed or turning at `pressure_spin`, now or the step
  before, is not taken (core/54).
- Put to sleep mid-turn (core/54): Jolt can put a slow Sock to sleep while it still tips over (2 rad/s the
  step before), zeroing its motion. An asleep flight rests at once only when it was under the rest speed
  and turn the step before (`MessMoving._slept_still`); otherwise it is woken and goes on.
- Pushed out of a leaf (core/39, Q2428): `MessMoving` remembers each Door and drawer leaf it sweeps (its
  place before its last step and now). A resting Sock whose middle is in such a leaf is moved, flat, to the
  side the leaf swept from, wholly `leaf_clearance` past its face (`out_of_leaf`, `Mess._reach`); a flight
  then flies on from there at `leaf_push_speed` (at most `leaf_push_tries` times, then it is put down at
  once). No pop. A spot past the face that is in a wall is lost as before.

## Gotchas

- **An answer carries only the records it changed** (coop/07, `docs/migration/coop-mess-sync.md`): a rows
  patch (`Mess.ROWS` and the `ROW_*` keys: each changed Sock's whole record in packed arrays, the new count
  when records are added or cut off, the launches of the rows that fly). Make one with the `*_patch`
  functions, chaining several Socks through their `onto` argument (`lose_button.gd`, `Hands.left`); never
  hand-build `states`/`poses` arrays into an answer. `Mess.write` applies a rows patch the same on every
  machine. A snapshot (a late Guest, a save) is `Part.whole_state()`: for the Mess the State fields packed and
  zstd-compressed (`PACKED`), exact, with each body in flight's place and motion (`MOTION` bytes, half floats:
  looks only), read back by `Mess.unpacked()` (a test reads a saved field through it). A listener reads a patch
  with `Mess.row_states()`.
- A Throw's body streams (coop/09, coop/01 Option A): `MessMoving._launch` gives it a `FlightRow` ("Row") and a
  `MultiplayerSynchronizer` ("Sync") before it enters the tree, so the spawn carries the first row
  `[position, rotation, velocity, spin, the Host's tick]`; then one row a network frame, unreliable, about
  5.6 KB/s a body. A Guest's spawned copy (no `SOCK_META`) is frozen (kinematic, on the looks layer) and gets
  its Row as it enters (`_on_flight_in`); the Row plays it `GhostTuning.stream_lag` (0.1 s) behind the Host's
  clock, mapped by the smallest delay seen (`Mess.stream_offset`). Only Throws come over the spawner.
- A Guest's own pick, drop, Throw and wheel are looks-only guesses (`GuestGhosts`, a child of the Player,
  `ThrowGhost` on `Mess.LAYER_GHOST` touching the house only, the HeldView's pick ghost): every Command carries a
  `seq` the answer echoes; while a ghost draws a Sock, `Mess.hold_back(sock, true)` keeps the Mess from drawing
  it (lying or flying, body and record as they are). A Throw or drop ghost flies its own body from the
  thrower's first-person hand, where the Host lets it go too (`Hands.start_of`, coop/13, Q2573), and is drawn on
  it until it parts from the Host's body at the same moment of the flight (`FlightRow.flight_time`) by more than
  `part_distance` or `part_turn`; from then the difference eases in over `predict_blend`. It eases onto the
  Host's rest. Its body undoes a push into the floor as a flight does (`MessMoving.undo_push`, core/50).
- A Teammate's Throw or drop (any let-go Sock whose thrower plays on another machine) is drawn from where their
  avatar holds it (`Hands.worn_start_of`, through `Mess.worn_start`), easing onto its body over
  `GhostTuning.hand_over_time` (`Mess._leads`, the MultiMesh row or the body's Looks; coop/13, Q2439).
- A flight flies as the same leg and foot boxes it lies on (`MessBodies.parts_at`), with
  `MessTuning.turn_weight` times its flat box's inertia (a 50 g board's own spins to Jolt's cap on an
  edge landing), and sweeps (CCD) only from 1 m/s (core/23). Poured and dropped Socks fly as woken ones.
- A drop and a Throw leave from the hand (`Hands.start_of`, Q2356, Q2367) on an arc solved by `Arc`;
  a drop's launch is in `throws` with `"drop": true` (never shelved, wakes nothing).

- A Mess needs its `tuning` (HandsTuning: a Throw's drag, the hit's wake) set in its scene; `_ready` asserts it
  (core/30). Every number of the tiers is in `MessTuning`, none in code (the sweep's CCD speeds, the touch margin,
  the boxes' least thickness, read once a run by the first Mess).
- **A new body must not be made inside another** (core/49): two Socks made overlapping fall and rest stuck
  together (Jolt keeps the contact and never parts them). A physics query sees only bodies already made, so a
  caller that picks several places for one `add` (the heap's spout) also tries each against its own earlier
  picks (`MessBodies.boxes_meet`); `MessWatch` counts a new Sock made inside a moving one as `made_inside`, a fault.
  Jolt's `penetration_slop` (20 mm) is close to a Sock's 26 mm, so a heap's weight presses Socks up to 20 mm into
  each other: accepted and only counted (Q2499; the floor's the same, Q2412): `pressed`, and `inside` for the few
  the sharp boxes measure deeper at a slanted edge.
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
"It Socks.exe" --fixed-fps 10 -- --bench=mess --only=idle_500   # a debug export, or
godot --path <project> --fixed-fps 10 -- --bench=mess          # the editor exe
... -- --help                                         # the commands; unknown flag: help and exit code 2
... -- --scene=heap                                   # start a zoo station (or a res:// scene) instead of the main scene
```

- Release build (`not OS.is_debug_build()`): every command is refused with one printed line and the game starts.
- Results go to `user://bench/mess/` (Windows `%APPDATA%\Godot\app_userdata\It Socks\bench\mess\`); the last
  line printed is `BENCH saved <absolute folder>`; `--out=` overrides. Exit code 0 on PASS, 1 on FAIL.
- Drawn by default (real frame times and draw calls on that card); the engine's `--headless` before the `--` still
  works, and the report's machine line says which.
- Pacing: a tick is timed between two ticks of one frame, so the run needs several ticks a frame, which only the
  engine's own `--fixed-fps 10` gives (six ticks a frame, as fast as the CPU goes). Nothing sets that at run time:
  `Engine.time_scale` also scales the physics delta (the sim breaks), and `Engine.max_fps = 10` runs in real time
  (hours). The engine hides its own flags from the script, so `MessBench` counts the ticks of its first frames and, with fewer than two a frame, prints one `FAIL mess bench` line that names the flag and quits with 2. The scripts pass it:
  `"It Socks.exe" --fixed-fps 10 -- --bench=mess`. 
- The zoo (the project's main scene) is instanced before an autoload can swap the main scene (Godot reads
  `application/run/main_scene` before the autoloads), so a `--bench` or `--scene` start loads it for one frame, then
  `GameCli` replaces it (after that frame, so the zoo's own deferred start-up has run).
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
while turning or moving fast at its last tick seen moving), jumped (snapped at its rest, from its body's place
the tick the Mess rested it, core/54), flips (turned faster than `flip_spin`), jitter (woken
`jitter_wakes` times or more, each time resting moved past `jitter_move` or `jitter_turn`; a wake that left it where it
lay is none, core/54), sunk (lowest point under the floor), inside (its leg or foot overlapping another
Sock's deeper than `inside`, 22 mm; from `pressed`, 6 mm, it is counted as pressed, Q2499), made_inside (a new Sock
made overlapping a moving one, core/49), under (a moving Sock's leg or foot middle more than `under`, 50 mm,
under the floor, core/50). Each fault leaves a line in `MessWatch.notes` (the Sock and its last ticks), which
`mess_settle` prints. A scenario with one, or with its 95th-percentile tick over the budget, fails the run.
