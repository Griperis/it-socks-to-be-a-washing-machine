# What the port taught that the kit should carry

Asked for: the lead, 2026-11-25. Read-only survey of `docs/migration/decisions.md`, `docs/migration/journal.md`,
`docs/research/`, `docs/architecture/` (the Gotchas sections), the bug tickets in `docs/llm/*/issues/`,
`git log` of main, `tests/flaky/ledger.md`, `tests/support/`, `tests/hooks.gd`, `tools/shot_hooks.gd` and `game/`.
Each item was checked against the kit as it is today: `kit/skills/godot-game-dev/SKILL.md` and `reference.md`,
`kit/skills/multiplayer-game-dev/` (SKILL, `templates/`, `templates/scene_parts/README.md`), `kit/docs/TESTING*.md`,
`kit/skills/release-export/SKILL.md`, `kit/template/` and `kit/CHANGELOG.md`. What the changelog says was already
fed back (uid checks, import settings in mirrors, virtiofs object rename, foreground tests, one test gate) is left out.

Every proposal is generic: no game names, numbers or lists go into the kit. Sizes are rough: XS = a line or two,
S = under 50 lines or a short doc paragraph, M = a template or tool change of 50-300 lines with a case,
L = more. "Unsure" marks a claim that was not re-measured for this report.

## 1. Godot knowledge

Ranked by how much a next game would lose without it.

### G1. ENet's packet throttle drops 31 of 32 unreliable packets at 60 frames a second
- **Lesson.** Left at its defaults, ENet's throttle sinks to zero within a second of joining at 60 fps, and every
  unreliable stream (synchronizers, avatar poses) then arrives about twice a second. Hold it at full on every peer,
  at both ends, as each connects: `ENetPacketPeer.throttle_configure(5000, 32, 0)`. Tests at a free frame rate never
  show it; only frames paced to 60 a second of wall time do.
- **Evidence.** `docs/research/coop-flight-sync.md` (condition 1); `game/net/enet_transport.gd`; journal coop/01
  ("ENet's packet throttle drops 31 of 32 unreliable packets at 60 fps (any stream, avatars too)");
  `docs/architecture/coop.md` Gotchas.
- **Kit today: no.** Both `kit/skills/multiplayer-game-dev/templates/session.gd` and
  `templates/scene_parts/session.gd` make an `ENetMultiplayerPeer` and never configure the throttle, and the
  scene-parts avatar streams its pose unreliably 20 times a second (`scene_parts/avatar/avatar.tscn`), so **the
  kit's own template has this bug**.
- **Change.** Both session templates hold the throttle on `peer_connected` (Host) and on connect (Guest); one line in
  `multiplayer-game-dev/SKILL.md` saying why; a case in `scene_parts_test.gd` that paces frames to 60/s, joins, and
  counts avatar poses received over 2 s. Size S (about 15 lines plus a case).

### G2. Faults that only an exported build shows
- **Lesson.** Three faults passed every headless suite and the editor and broke only the export:
  (a) an anchored Control scene root saved without `layout_mode` (here hand-written by an agent) is laid out at
  size 0 in the export, so a SubViewport in it was 2x2 and nothing drew;
  (b) a `preload` cycle between scripts loaded in the editor but broke the exported build;
  (c) listing a folder of resources with `DirAccess` misses the remapped files of an export;
  `ResourceLoader.list_directory()` (4.4+) lists them.
- **Evidence.** (a) commit 6d8eacc, `docs/llm/core/issues/113-lobby-figures-missing-in-build.md`, case
  `lobby:k18`; (b) commit 9b829af; (c) `docs/architecture/economy.md` and `wardrobe.md` Gotchas.
- **Kit today: no.** `release-export` step 3 is a headless `--quit-after` run and a log read: it would catch (b) if
  it logs, never (a).
- **Change.** `godot-game-dev/SKILL.md` "Export": three lines (layout_mode, preload cycles, `list_directory`).
  A scene check (in `kit/tools/asset_lint.py` or `check.sh`): every `.tscn` whose root Control stores anchors also
  stores `layout_mode` (lift of `lobby:k18`). `release-export` smoke run: a still of the title and the first level
  from the exported binary under Xvfb, compared by eye with the editor's. Size S doc + S check + S skill step.

### G3. Physics interpolation: where it must be off
- **Lesson.** With `physics/common/physics_interpolation` on: (a) a MultiMesh's instances are drawn between the
  buffer of the tick before and this one, so a reused or newly written row is smeared or missing for one tick (the
  "teleport at every rest"); switch interpolation off on a MultiMesh whose rows are rewritten. (b) A camera moved
  per frame (mouse look, a top-level follow camera) must have `physics_interpolation_mode` off. (c) A camera still
  interpolating on its first frame gives a degenerate projection (`unproject_position` errors). None of this is
  visible headless (no frames between ticks).
- **Evidence.** `docs/architecture/mess.md` ("No MultiMesh of the Mess is physics-interpolated"), Q2407, Q2414
  (core/31); journal core/01 ("left Godot's own interpolation on the top-level camera ... headless tests cannot see
  it"), commit 0ef6020; commit 6d8eacc (stage camera).
- **Kit today: partly.** `SKILL.md` has `reset_physics_interpolation()` after a teleport; nothing on cameras or
  MultiMesh. `kit/template/project.godot` does not switch interpolation on, so a game that does meets these cold.
- **Change.** Three lines in `SKILL.md` "Physics and animation"; decide (designer) whether the template turns it on.
  Size XS.

### G4. MultiplayerSpawner and MultiplayerSynchronizer ordering and visibility
- **Lesson.** (a) The spawn packet is built inside `add_child`, so a spawned body's pose and first synced value must
  be set before `add_child` or the Guest's copy starts at the origin. (b) Unreliable sync for a node whose spawn has
  not arrived is dropped by Godot; heavy reliable traffic delays spawns. (c) Whom a spawn goes to is decided only by
  the Host's own synchronizers on the spawned node: a spawn whose synchronizer belongs to another peer goes to
  everyone, so a peer still loading a level got avatars it could not place. A Host-owned "gate" synchronizer with a
  visibility filter fixes it. (d) A spawned thing's state (in an RPC or snapshot) can arrive before its node: wait
  by id.
- **Evidence.** `docs/research/coop-flight-sync.md` conditions 2-3; `docs/architecture/coop.md` "The house
  handshake" (core/62, core/68); `docs/architecture/gifts.md` Gotchas.
- **Kit today: no.** `scene_parts/README.md` explains which Godot node to use for what, not these traps;
  `scene_parts/avatar/avatars.gd` has no visibility filter.
- **Change.** A short "Godot multiplayer traps" list in `multiplayer-game-dev/SKILL.md` (or the scene-parts README,
  one owner); a gate synchronizer and filter hook in the avatar template (see C2). Size S doc, S template.

### G5. Editor re-saves that lose data, and import churn
- **Lesson.** (a) Project > Tools > Upgrade Project Files dropped every old-style override on nodes inside instanced
  scenes; the suite caught 3 of 6. (b) An editor left open across merges re-saved a `.tres` and dropped values for
  properties its script had gained after the editor loaded it. (c) The editor's "detect 3D" switches a texture used
  in 3D to VRAM compression on first use, re-writing `.import` files that a headless import never touches.
  (d) A direct `--import` or a suite run re-wrote 250-300 imported mesh `.res` files (cause not pinned down: unsure).
- **Evidence.** (a) commit cf4b0cb; (b) commits 319d6ff, 4745b96, 1877358; (c) c8ac0f5, 221b094, 864354c (and the
  working copy's modified `.png.import` today); (d) journal coop/02 and house/09.
- **Kit today: partly.** `kit/tools/scene_links.py` warns only on lost NodePath links in `.tscn`;
  `kit/tools/uid_check.py` covers hand-written uids. No doc says "reload the editor after a merge" or what a
  re-save may lose.
- **Change.** Extend `scene_links.py` (or a sibling) to warn on any removed property line in a changed
  `.tscn`/`.tres` whose new text does not carry it, uids and ids ignored; a doc paragraph (`kit/docs/agents/git.md`
  or `godot-game-dev/SKILL.md`, one owner): reload the editor after merges, diff every line of an "editor format"
  commit, set `detect_3d/compress_to` (or the compress mode) explicitly on textures meant for 3D. Size M tool,
  S doc.

### G6. Jolt behaviours a physics-heavy game meets
- **Lesson.** (a) A fast, thin body can be pushed through a thin static floor (0.2 m) in one step; floors 0.4 m or
  thicker, `speculative_contact_distance` 0 or `collision_margin_fraction` 0.5 each stopped it in a replay.
  (b) The default penetration slop (0.02 m) is visible on small objects resting on a floor or on each other.
  (c) Two bodies created overlapping keep the deep contact and never part: a spawner must test its new places
  against each other, since a physics query sees only bodies already made. (d) Results depend on body creation
  order: a case that passes alone fails in the full suite after earlier cases shift ids (four flaky tickets).
- **Evidence.** `docs/llm/core/issues/50-heap-sock-sinks-under-floor.md`; Q2412, Q2499; core/49
  (`docs/architecture/mess.md`); core/69, core/100, journal core/49 ("it changed the ids and Jolt's order");
  `tests/flaky/ledger.md`.
- **Kit today: no.** `reference.md` has only `position_steps`/`velocity_steps`.
- **Change.** A "Jolt" section in `godot-game-dev/reference.md` (about 8 lines), and one line in
  `kit/docs/TESTING.md` "Flaky cases": physics outcomes depend on body order, so assert with margins or build the
  case's own world. Size S.

### G7. When a physics change becomes visible
- **Lesson.** A node's transform set in `_physics_process` reaches the physics server only at the next flush; a body
  that others must meet in the same tick is also told to the server (`PhysicsServer3D.body_set_state`). Conversely a
  body's place after a step is written to its node only at the next tick's sync, so a correction made right after
  that sync is never drawn.
- **Evidence.** `docs/architecture/coop.md` Gotchas (the moving back); `docs/llm/core/issues/70-sock-under-floor-frame.md`.
- **Kit today: no.**
- **Change.** Two lines in `reference.md`. Size XS.

### G8. Headless runs, fixed step and the exported binary
- **Lesson.** A headless run without a fixed step paces itself in real time (a benchmark ran for hours);
  `--fixed-fps` is an engine argument and must come before `--`: it cannot be set at runtime, so a game-side
  command checks for it and refuses without it.
- **Evidence.** commit 4b34275 (core/35); journal core/35 ("Godot cannot fix its step at runtime").
- **Kit today: partly.** `kit/docs/TESTING.md` and `kit/tools/shot.gd` use `--fixed-fps` for shots and tours; the
  rule for a game's own command line is not written.
- **Change.** One line in `SKILL.md` (or with C6's template). Size XS.

### G9. Network tests in one process
- **Lesson.** Two machines in one process poll in the same frame, so at 0 ms an answer can come back inside the
  click's own frame: a case judging "before the answer" needs a delay. Frames must be paced to wall time for anything
  rate-dependent (G1). Parallel runs need a system-picked port.
- **Evidence.** `docs/architecture/coop.md` Gotchas and Tests; core/101, core/103 (flaky real paths: the click came
  before the Host heard the Guest's move); journal coop/12 (ENet port clash broke a merge).
- **Kit today: partly.** Port 0 in tests is in `templates/session.gd`; `_until` waits in real time; pacing and the
  same-frame answer are not written.
- **Change.** Three lines in `multiplayer-game-dev/SKILL.md` "Tests" (or `TESTING-more.md`), plus C3. Size XS.

### G10. Code that resumes after its node is gone
- **Lesson.** A helper (`RefCounted`) awaiting a node's signal, or a `SceneTreeTimer` callback, runs after the node
  was freed. Check `is_instance_valid(owner) and owner.is_inside_tree()` after every `await`; prefer a `Timer` child
  for a node's own delays.
- **Evidence.** `docs/architecture/coop.md` Gotchas; journal maintenance/04 ("helpers resuming after an await now check
  the Session still exists") and core/76 ("a dust_sheet timer fired on a freed Cabinet").
- **Kit today: no.**
- **Change.** One line in `SKILL.md` "Writing a script". A grep rule for `create_timer(...).timeout.connect` in game
  code is possible but noisy (unsure it is worth it). Size XS.

### G11. Focus, containers and pushed input in UI
- **Lesson.** (a) A mouse click gives a button focus too, so a Theme `focus` style also shows after clicks; a
  pad/keyboard-only highlight needs to know the last input device. (b) A container re-applies its children's
  position and scale on every re-layout, so animating a child's own position/scale is overwritten: keep the
  animated amount and re-apply it after the parent's `sort_children`, or animate an inner node. (c) Input pushed
  with `Input.parse_input_event` does not reach `Window.window_input`; a test that drives a listener there emits it
  too.
- **Evidence.** `docs/llm/core/issues/75-lobby-pad-ring.md`; `game/ui/pad_focus.gd` header; `tests/lobby_test.gd`
  around line 788-800; Q2647-Q2654.
- **Kit today: partly.** `SKILL.md` says menus are reachable by focus alone; nothing on these three.
- **Change.** Three lines in `reference.md` "UI feel"; the code is C5. Size XS.

### G12. Bones and ragdolls over the network
- **Lesson.** A MultiplayerSynchronizer on a Skeleton3D's `bones/<i>/rotation` works with no code but steps visibly
  (4-6 times the Host's motion); a pose packed into one property on a Host-owned node, played a little behind, reads
  smoothly. Godot's own PhysicalBone3D ragdoll on Jolt is enough; a dragged ragdoll needs the dragger excepted from
  its collisions or it is flung (about 20 m/s).
- **Evidence.** `docs/research/coop-ragdoll-sync.md`; journal coop/02 and core/98 ("without letting the dragger
  through, the ragdoll flew off").
- **Kit today: no.**
- **Change.** Two lines in `reference.md` (or `multiplayer-game-dev/SKILL.md` for the sync half). Size XS.

### G13. Small GDScript and editor traps
- **Lesson.** (a) A `@tool` script reading a Resource whose script is not `@tool` gets a placeholder in the editor;
  read non-tool code only through static functions and constants. (b) A Packed array taken out of a Dictionary or
  Array is a copy: write it back. (c) The `TIME_PHYSICS_PROCESS` monitor is not a tick's cost (it stayed flat while
  ticks went from 40 ms to 3 ms); time from the first `_physics_process`.
- **Evidence.** (a) `docs/architecture/sock-generator.md`; (b) `docs/architecture/mess.md`; (c) mess.md and journal
  core/12-13.
- **Kit today: no.**
- **Change.** (a)(b) in `SKILL.md` "Writing a script", (c) in `reference.md` "Profile before optimising". Size XS.

### G14. GDExtension leftovers
- **Lesson.** The Windows editor makes `~<name>.dll` copies of GDExtension libraries; they belong in `.gitignore`.
- **Evidence.** commit a86b2da (with GodotSteam, Q2459).
- **Kit today: no** (`kit/template/.gitignore`).
- **Change.** One line in `kit/template/.gitignore`. Size XS.

## 2. Code to lift into the kit

Ranked by reuse for a next co-op or menu-driven game.

### C1. A transport seam in the session templates
- **What.** `game/net/net_transport.gd` (the abstract seam) and `enet_transport.gd` (the one file that names ENet or
  reads an address; holds the throttle, G1). A Steam or relay transport is one more file; a test transport
  (`tests/support/inviting_transport.gd`) stands in for invites.
- **Kit today: no.** Both kit `session.gd` templates build ENet inline.
- **Change.** Template: `NetTransport` + `EnetTransport` beside `scene_parts/session.gd` (and the Command seam's),
  session takes a transport. Size M (about 110 lines plus a case). Carries the G1 fix.

### C2. Scene-parts template upgrades the game made
- **What.** In `game/parts/`: a per-Part `save_version()`/`upgrade_save()` and `save_state()` vs `whole_state()`;
  `Parts.went_alone()` (the Host left: each Part takes over what it showed as looks only) and `Parts.left(peer)`;
  `settle()`/`unsettle()`/`is_settled()` for a level still building; `Session` split into one-job helpers
  (`session_peer`, `session_gate`, `session_guard`, `session_relay`) with every `@rpc` one line in `session.gd`
  (842 to 337 lines); `close()` safe from `_exit_tree`; a Host-owned gate synchronizer and visibility filter so a
  loading peer gets no level spawns (G4).
- **Kit today: partly.** The kit has `part.gd`, `parts.gd`, `session.gd` (96/170/309 lines); the game's are
  170/301/337 plus 1,000 lines of helpers.
- **Change.** Port the generic parts back into `templates/scene_parts/` with cases in `scene_parts_test.gd`; leave
  game verbs, Hands numbers, house handshake details out. Needs a careful examination of what is game-specific
  (unsure on `settle`). Size L (do in two kit changes: saves and leaving first, then the session split).

### C3. A multi-machine suite base and a richer LagPeer
- **What.** 25 game suites each re-define `_branch()` (a machine: Node with its own `SceneMultiplayer`, a SubViewport
  with `own_world_3d`), `_drop_branches()`, `_in_branch()`, `_lag()`; 14 re-define `_paced()`/`_paced_ticks()`
  (frames held to 60/s of wall time) and `_press()`. `tests/support/lag_peer.gd` adds sent bytes and packets per
  transfer mode to the kit's copy.
- **Kit today: partly.** `templates/tests/net_helpers.gd` and `scene_parts_test.gd` each have their own `_machine`;
  no pacing helper; the kit `lag_peer.gd` lacks the byte counters.
- **Change.** One base `tests/support/machines.gd` in the scene-parts template (extends the kit suite): machine per
  branch, paced frames, lag and loss, teardown; take the game's byte counters into `lag_peer.gd`. Size M.

### C4. Save template: the safety the game added
- **What.** `game/save/save.gd` and `save_store.gd`: the old file becomes the backup only when it reads (so a broken
  file never replaces a good backup; the game's header calls this "the kit template's follow-up, fixed here"); a file
  that reads neither way is kept as `<name>.damaged` and the answer says so; `write_later()` writes on a worker
  thread from a copied snapshot; every call answers `{ok, reason}` instead of asserting; a `SaveStore` seam
  (`LocalFileStore`, `MemoryStore` for tests, room for a cloud store) whose synced names follow one pattern.
- **Kit today: partly** (`godot-game-dev/templates/save/save.gd`, 190 lines, files only).
- **Change.** Template upgrade with cases in `templates/tests/save_test.gd`; `MemoryStore` reset from `tests/hooks.gd`
  as the game does. Size M.

### C5. Pad and keyboard focus highlight
- **What.** `game/ui/pad_focus.gd` (125 lines) with `focus_glow.tscn` and a tuning Resource: one autoload feeds it the
  window's input and the viewport's focus changes, so every focusable control lights with no per-button code; Tab or
  a pad press turns it on, a mouse click off; the lit amount is re-applied after a container re-layout (G11); a meta
  opts a control out.
- **Kit today: no.** The `options` and `pause` templates are focus-reachable but show the Theme's default focus.
- **Change.** Template `godot-game-dev/templates/focus/` with a graybox glow scene and a case (pad press lights,
  click clears); the look (lift, scale, glow colour) stays in the game's tuning `.tres`. Size M.

### C6. A debug-build command line
- **What.** `game/debug/game_cli.gd`: an autoload reading user arguments after `--` once (`--bench=`, `--scene=`,
  `--help`); a pure `plan()` (arguments in, action out) tested without running; a release build refuses every command
  with one line; a benchmark refuses to run without `--fixed-fps` (G8). Benchmarks are const table entries.
- **Kit today: no.**
- **Change.** Template `godot-game-dev/templates/cli/` with a case; `--scene=` opening a zoo station fits the zoo
  skill. Size S-M.

### C7. A second local copy takes its own profile
- **What.** `game/net/profile_lock.gd` (84 lines): in a debug build, a copy started while another holds the profile
  takes `profile_2`, `profile_3`, ... by a lock file (pid and stamp, renewed every 2 s, free after 30 s, removed on
  quit), and shows "(Player N)" in the window title; `--profile=` wins; release builds never do it. Two copies on one
  PC then join each other with no arguments.
- **Evidence.** commit 23c8e5f, `docs/llm/core/issues/114-second-copy-joins-on-one-pc.md`.
- **Kit today: no** (the scene-parts gate refuses a duplicate player id, so any kit co-op game hits this the first
  time the designer runs two copies).
- **Change.** Template file beside `scene_parts/session.gd` with a case. Size S.

### C8. Rules that guard "UI authored in nodes" and anchored roots
- **What.** `tests/ui_nodes_test.gd` greps game scripts for `Label.new()`, `TextureRect.new()`, box containers,
  `Panel`, `ColorRect`, `StyleBoxFlat` made in code (Q2658); `tests/lobby_test.gd` k18 checks anchored Control roots
  store `layout_mode` (G2).
- **Kit today: no.** `kit/tools/grep_rules.py` has nine rules, none for UI built in code.
- **Change.** A `ui_new` rule in `grep_rules.py` (game code only, the game's allow-list for exceptions), and the
  layout_mode check in the scene lint. Whether "UI in nodes" is a kit default is the next designer's call, so the
  rule could be opt-in. Size S each.

### C9. Shot hooks one file per feature
- **What.** `tools/shot_hooks.gd` reached 1,416 lines (one `act()` match for every feature; grep_rules flags it).
- **Kit today: no.** `kit/tools/shot.gd` loads the single `res://tools/shot_hooks.gd`. The kit 5 changelog already
  deferred "shot actions as one file per feature".
- **Change.** `shot.gd` also loads every `tools/shot_hooks/*.gd` (each `static func act(...) -> bool`), first that
  answers wins; the single file keeps working. Size S plus a harness case.

### C10. The game log's errors fail tests too
- **What.** Once a game moves to the log template, `Log.error()` writes a line but raises no engine error, so the
  runner's "a case fails on any logged error" no longer sees it (the game's Settings and Sounds tests had to read the
  log line instead).
- **Evidence.** journal core/48 ("since `Log.error` raises no engine error"); `kit/skills/godot-game-dev/templates/log/log.gd`
  `error()`.
- **Kit today: no.**
- **Change.** Either the runner reads `Log` ERROR lines written during a case (when the autoload exists) and treats
  them like engine errors, with `_expect_error` consuming them, or `Log.error` also calls `push_error` in debug. The
  first keeps one stream; pick with the designer. Size S.

### C11. An out-of-map fallback for the player template
- **What.** `game/player/fall_rescue.gd`: out of the map is a non-finite position, below the lowest floor by a depth,
  or beyond a reach from the centre; the player is put back at a spot with `reset_physics_interpolation()`.
- **Kit today: no** (`kit/skills/zoo-design/templates/player/player.gd`).
- **Change.** About 20 lines in the graybox player and a case. Size S.

### C12. Two-process measurement of a co-op session
- **What.** `tools/coop_cost.sh` (Host and Guest as two headless processes: bytes each way and frame times during a
  load) and `tools/coop_probe.sh` (input-driven Guest, both sides' view printed).
- **Kit today: partly.** `kit/tools/net_shot.sh` runs real multi-process sessions for stills, not for numbers.
- **Change.** A `--measure` mode of `net_shot.sh` printing ENet totals and frame times per window. Size M; lower
  priority.

### C13. Zoo stations placed by hand
- **What.** The designer asked to move stations in the editor, so the game instances each station by hand under
  `Stations` (Q2359) instead of the kit's runtime collector.
- **Kit today: partly.** `kit/skills/zoo-design/SKILL.md` and `templates/stations.gd` still collect the folder at
  runtime (journal noted the skill describes the collector).
- **Change.** Offer hand placement as the default (or a setup choice) in `zoo-design`. Size S. A design choice:
  ask the designer before proposing.

## Top 5 to do first

1. **G1 + C1: hold ENet's throttle in both session templates** (behind a transport seam). The kit's own avatar
   stream is hit today. S, then M.
2. **G2: export-only faults**: the layout_mode scene check, three `SKILL.md` lines, and a still from the exported
   build in the `release-export` smoke run. S.
3. **G4 + G3 + G6 doc lines**: multiplayer spawner/synchronizer traps, physics interpolation off for MultiMesh and
   cameras, and a Jolt section in `reference.md`. Mostly doc, S together.
4. **C3: one multi-machine suite base** with paced frames and the byte-counting LagPeer, replacing 25 copies in a
   game. M.
5. **C4 + C7: the save template's backup and damaged-file safety, and the second-copy profile lock.** Both small,
   both bit the designer directly. M and S.
