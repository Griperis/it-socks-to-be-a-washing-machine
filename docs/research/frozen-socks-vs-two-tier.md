# Why not freeze a resting Sock's body and keep its full scene? What do frozen full Socks cost against the two tiers?

Asked for: designer, Q2349, 2026-11-20. Engine 4.7.2 (Jolt Physics, project settings as in `main`).

## Answer
- At rest, a frozen full Sock costs about the same as a sleeping one, and both cost far more than the lying tier at every size measured. Physics was not the difference: a frozen or sleeping body is 0 active bodies and 0 islands. The cost is the scene each Sock keeps.
- Node count: 22 nodes and about 24 objects a Sock, so 11,089 nodes at 500, 44,089 at 2,000 and 220,089 at 10,000. The two-tier Mess holds all of them in 99, 104 and 130 nodes.
- Static memory over an empty scene: +49 / +187 / +919 MB (full) against +8 / +12 / +33 MB (two-tier). Video memory on the sandbox's software GL: 55 / 88 / 267 MB against about 44 MB flat.
- Draw calls from the eye view: 947 / 3,804 / 18,695 (full, one per Sock-mesh, no visibility range) against 13 / 26 / 88 (two-tier, culled by cell and range). Primitives: 0.18 / 0.44 / 1.53 million against 1.8k / 3.6k / 7.8k.
- Physics tick (back-to-back ticks, 60 Hz): 0.16 / 0.60 / 3.8 ms for frozen full Socks (sleeping: 0.16 / 0.61 / 4.1) against 0.01 / 0.006 / 0.005 ms for the Mess. Leaving the game's cloth script running on every frozen Sock is the worst case: 3.2 / 16.8 / 110 ms a tick (a 60 Hz tick has 16.7 ms).
- Not measured: a real GPU (see below). The counts above (nodes, objects, memory, draw calls, primitives, tick) do not depend on the GPU; the frame times do, so none are claimed.

## The numbers
Setup: N Socks in a grid (0.5 x 0.4 m, yaw varied), on a 400 m floor, one shadowed sun, 1280x720, Xvfb. Median of 120 frames (the tick of 240 ticks), after 90 settle frames. "Eye" is a camera 1.7 m up at the edge of the field; "high" looks straight down at all of it.
Full Sock = `game/sock/flight.tscn` (RigidBody3D) with `SockDress.make(...)` as its `Looks` child, exactly what `Mess.give_looks` builds. "Frozen" = `freeze = true`, `FREEZE_MODE_STATIC`, cloth scripts and SpringBoneSimulator3D off. "Asleep" = `sleeping = true`, not frozen, cloth off. "Frozen + cloth script" = frozen with the game's `SockCloth` script left as the game has it. "Two-tier" = a real `Mess` Part with N lying records (MessBodies + MessDrawing), no scene per Sock.

Renderer for the table: Godot Compatibility (OpenGL 3) on Mesa llvmpipe (software), via xvfb-run; the same figures for Forward+ at 500 and 2,000 are in the findings.

| N | Variant | Nodes | Objects | Static mem over empty (MB) | Video mem (MB) | Process RSS (MB) | Tick median / p95 (ms) | Draw calls eye / high | Primitives eye / high |
|---|---|---|---|---|---|---|---|---|---|
| 500 | frozen | 11,089 | 13,971 | +48.9 | 54.8 | 494 | 0.158 / 0.63 | 947 / 2,004 | 183k / 187k |
| 500 | asleep | 11,089 | 14,471 | +49.9 | 54.8 | 500 | 0.159 / 0.61 | 947 / 2,004 | 183k / 187k |
| 500 | frozen + cloth script | 11,089 | 13,972 | +48.9 | 54.8 | 500 | 3.24 / 4.27 | 947 / 2,004 | 183k / 187k |
| 500 | two-tier Mess | 99 | 2,934 | +8.4 | 43.7 | 430 | 0.012 / 0.08 | 13 / 20 | 1.8k / 1.2k |
| 2,000 | frozen | 44,089 | 49,971 | +187.2 | 88.3 | 783 | 0.596 / 2.20 | 3,804 / 6,003 | 435k / 444k |
| 2,000 | asleep | 44,089 | 51,971 | +190.3 | 88.3 | 793 | 0.605 / 2.23 | 3,804 / 6,003 | 435k / 444k |
| 2,000 | frozen + cloth script | 44,089 | 49,972 | +187.6 | 88.3 | 783 | 16.8 / 19.8 | 3,804 / 6,003 | 435k / 444k |
| 2,000 | two-tier Mess | 104 | 2,944 | +12.1 | 43.8 | 490 | 0.006 / 0.08 | 26 / 30 | 3.6k / 2.0k |
| 10,000 | frozen | 220,089 | 241,971 | +919.3 | 267.2 | 2,125 | 3.76 / 11.7 | 18,695 / 30,003 | 1.53M / 1.86M |
| 10,000 | asleep | 220,089 | 251,971 | +934.8 | 267.2 | 2,191 | 4.14 / 11.7 | 18,695 / 30,003 | 1.53M / 1.86M |
| 10,000 | frozen + cloth script | 220,089 | 241,972 | +919.5 | 267.2 | 2,126 | 110 / 121 | 18,695 / 30,003 | 1.53M / 1.86M |
| 10,000 | two-tier Mess | 130 | 2,996 | +32.7 | 44.6 | 545 | 0.005 / 0.07 | 88 / 108 | 7.8k / 7.8k |

Where each number came from:
- Nodes, objects, static memory, tick: the same in every renderer (the Compatibility run above; headless static memory at 10,000 was +692 MB frozen / +708 MB asleep / +29 MB Mess, because no GPU copies are made).
- Draw calls, primitives, video memory, RSS: Compatibility on llvmpipe only. Headless reports 0 for draws and video.
- Forward+ (Vulkan on llvmpipe, the project's renderer) for 500 and 2,000, shadows on: draw calls and primitives identical for the full Socks (947 / 3,804 eye); two-tier 13 / 29 eye, 20 / 30 high. Video memory 135 / 151 MB full, 129-130 MB Mess (this one has a large fixed part). Tick 0.28 / 0.55 ms (frozen), 0.28 / 0.58 (asleep), 3.3 / 16.6 (cloth script), 0.009 / 0.005 (Mess), at 500 / 2,000.
- Active bodies and islands (Jolt monitors): 0 and 0 for frozen and for asleep, at every N, after settling.
- Frame and process time: measured but not used; see "Not found".

## Findings
- A frozen body is not cheap because of the body: with `freeze = true` (STATIC) or asleep, Jolt reports 0 active objects and 0 islands, yet the node, object, memory and draw-call counts above are all unchanged by freezing. Source: the table. tried on 4.7.2: bench scene spawning `flight.tscn` plus `SockDress.make` Looks, `freeze`/`sleeping` set, `PHYSICS_3D_ACTIVE_OBJECTS` and `PHYSICS_3D_ISLAND_COUNT` read after 90 frames, at 500, 2,000 and 10,000.
- Frozen and asleep are indistinguishable at rest in these numbers (tick 0.158 against 0.159 ms at 500; 3.76 against 4.14 at 10,000; the 10,000 asleep object count is 10,000 higher, one more object a body). tried on 4.7.2: the same bench, variants `frozen` and `asleep`. Not tried: what wakes an asleep body (a neighbour's contact, a thrown Sock landing); frozen bodies cannot be woken by contact, asleep ones can (read in the RigidBody3D class reference, not tried).
- A full Sock is 22 nodes (the RigidBody3D, its shape, the Looks, two imported skeletons and meshes with LODs, the AnimationPlayer, the SpringBoneSimulator3D and its ground plane) and about 90 KB of static memory, so 10,000 are 220,089 nodes and 0.9 GB. The Mess's lying tier keeps the 10,000 in 130 nodes, because a lying Sock is a physics-server body and one MultiMesh instance (`docs/architecture/mess.md`, "The tiers"). tried on 4.7.2: `OBJECT_NODE_COUNT`, `OBJECT_COUNT`, `MEMORY_STATIC` read after settling, minus an empty-scene baseline read at start-up.
- Drawing is the bigger gap. A full Sock is about 2 draw calls (eye view) to 3 (from above, counting the shadow pass) and about 370 primitives a frame, with no visibility range, so the camera's view at 10,000 Socks is 18,695 draw calls (30,003 from above) against 88 / 108. The MultiMesh cells cull by cell and range (`MessDrawing`, 8 m cells). The full-Sock scenes carry no visibility range here either, because the game's flights do not: a full Sock with a range would draw less, but each would still be 22 nodes. tried on 4.7.2: `RENDER_TOTAL_DRAW_CALLS_IN_FRAME` and `RENDER_TOTAL_PRIMITIVES_IN_FRAME`, median of 120 frames at each of two cameras, Compatibility and Forward+ on llvmpipe.
- The cloth script must be switched off on a frozen Sock to keep it cheap. `SockCloth` takes any Looks under a RigidBody3D for a flying Sock (`game/sock/sock_cloth.gd`, `_role`), adds it to the `sock_cloth` group and runs its `_physics_process`; with the script as the game has it, every frozen Sock's cloth costs a tick: 3.2 ms at 500, 16.8 at 2,000, 110 at 10,000, i.e. a 60 Hz tick is overrun from about 2,000. Only `flying_cap` Socks bend; the rest still run the script's check each tick. tried on 4.7.2: variant `frozen_cloth` (scripts untouched); the cost of the script's per-tick work is not split from the ranking.
- A tick of 3.8 ms for 10,000 frozen bodies is not only Jolt: the project has `physics_interpolation = true` and 10,000 RigidBody3D nodes (plus 2 skeletons each) are still in the scene tree's interpolation and `_physics_process` pass. The split between Jolt, the interpolation pass and the tree was not measured. tried on 4.7.2: consecutive `physics_frame` signals inside one process frame (`Engine.time_scale = 100`, `max_physics_steps_per_frame = 16`, so the 60 Hz step is unchanged and ticks run back to back); read, not tried, for the split.
- `Performance.TIME_PHYSICS_PROCESS` is not a tick's cost (as `docs/architecture/mess.md` "Gotchas" says): the same runs read 0.7-0.8 ms at 500 frozen under Forward+ against 0.28 ms from the tick timing, and read 12 ms at 10,000 frozen against 3.8 ms. It was recorded in the raw files but is not in the table. tried on 4.7.2: both read in the same runs.
- Forward+ on the software Vulkan driver crashed (signal 11 inside `libvulkan_lvp.so`) with 10,000 full Socks, with the sun's shadows on and off, for frozen, asleep and frozen + cloth script, a few seconds in; the Mobile renderer crashed the same way. The two-tier Mess at 10,000 ran under Forward+ and Compatibility. Compatibility ran all of them. tried on 4.7.2: `kit/tools/shot.sh`'s driver (`--rendering-driver vulkan`, xvfb-run, lavapipe) with the bench scene; the crash is a sandbox driver limit not shown on a real GPU.
- Process (frame) time did not separate the variants in the sandbox: a 1280x720 frame on a software rasteriser is 70-290 ms and is mostly fill of the floor and shadow pass (the Mess at 10,000 reads 255-265 ms, the same as full Socks at 10,000, 250-290 ms). The CPU-side cost without drawing is in the headless runs: process time at 10,000 settled 4.7 ms (frozen), 4.8 (asleep), 6.2 (cloth script) against 0.1 ms (Mess); at 2,000 1.3-1.4 / 0.9 against 0.1; at 500 0.2-0.3 against 0.1. tried on 4.7.2: `--headless`, same bench; the first sample after the settle frames is higher in headless (53-69 ms at 2,000 and 10,000) because the Looks' skeletons are still initialising after 90 frames, and is left out.

## Not found, or uncertain
- A real GPU. All draw, video and frame numbers came from llvmpipe (software Vulkan and software OpenGL), 1280x720. Draw-call and primitive counts are the engine's own and carry over; frame time and video memory do not. A GPU would likely make 18,695 draw calls from the eye view (many of them in view cones that the Mess culls) cost a few milliseconds of CPU submission, not the sandbox's 290 ms; a run on the designer's machine (Windows, D3D12 or Vulkan) with the same bench would settle it.
- The Forward+ 10,000 full-Socks case: it crashed in the sandbox driver, so its draw and video numbers are Compatibility's. The counts matched Forward+ at 500 and 2,000 and are expected to match at 10,000.
- Visibility range or LOD on full scenes: not tried, since the question was freezing. Godot's imported mesh LODs are in the Looks (`crew_lod1`, `crew_lod2`); the screen-space LOD at the eye view was not separated from the draw counts.
- Whether the sandbox's Jolt build wakes asleep bodies as the game's would (a Sock thrown into a field). Not tried.
- The bench's floor is one 400 m box, the Mess's own bodies are server bodies against it; the game's real house (walls, Doors, drawers) was not in the scene. The measured Mess is the real `Mess` Part but with no Hands, no player, no `Parts` Host traffic.
- A full Sock's object count of about 24 and node count of 22 are of the graybox `crew.glb` Looks (`looks_graybox.tscn`). M1's real Looks (ankle, tube, chunky, patterns) will differ.

## Open for the designer
- The numbers say a frozen full scene keeps its cost (nodes, memory, draws) and a cloth script left running grows it past a tick's budget by about 2,000 Socks. Which scale does the game need to support: a few hundred (a full-scene freeze would hold on a GPU, to be confirmed on the designer's machine), a couple of thousand, or the 10,000 the Mess is sized for? Options: (a) keep the two tiers as built; (b) freeze-in-place for Socks near the player only (more full scenes) and keep the tier beyond; (c) ask for the same bench to run on the designer's own machine first, before choosing.
