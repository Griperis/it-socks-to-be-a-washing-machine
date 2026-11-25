## Who is who

- **The designer** is the human user and owns every decision about the game: play, look, wording,
  sound, in-game cost.
- **The lead** is you when the designer talks to you directly: read `kit/docs/agents/lead.md`, then
  `docs/lead.md` (this game's lead-only rules), at the start of a session.
- **A ticket agent** is you when your prompt names a ticket and a branch: your rules are
  `kit/agents/ticket-agent.md`; the rest of this file is background.

The kit is the folder `kit/` (a git submodule, used in place). Its skills are the `game-kit`
plugin, listed as `game-kit:<skill>`; if none is listed, run `python3 kit/tools/setup.py --plugin`
and restart, or read `kit/skills/<skill>/SKILL.md`. Words the docs use: `kit/docs/agents/terms.md`.

## Rules every project starts with

Each is owned by the file named; three are enforced by a hook of the plugin.

- **Only the lead asks the designer**, and an agent never decides the game: an open choice becomes
  a `[blocking]` or `[later]` follow-up in the ticket (`designer-grilling`).
- **Commit with `kit/tools/commit.sh -m "<message>" <exact paths>`.** The hook refuses a direct
  `git commit`; the tool refuses `-a`, `.` and an AI co-author line.
- **The designer's working copy (the main checkout) is never stashed, reset or checked out over.**
  The hook refuses those commands there.
- **The kit is changed only by the lead, in the main checkout.** The hook refuses an edit to a
  worktree's kit copy.
<!-- opt:zoo -->
- **A feature is built in its zoo station first** (`game/zoo/stations/<feature>.tscn`, one file per
  station, instanced by hand under `Stations` in `zoo.tscn`, Q2359; not collected by code) and then lands in the main
  scene (the `zoo-design` skill). What only the zoo needs lives under `game/zoo/`, grouped per station; nothing outside
  `game/zoo/` refers to it (Q2409).
<!-- /opt:zoo -->
- **Every build ticket has one real-path case:** player input through the scene's own wiring to
  what the player sees (`kit/docs/TESTING.md` "The real path"). A visual tweak (a look or feel number) gets no
  test: its stills or strip and the designer's eye judge it (Q2421).
- **A flaky test is a defect to rework**, never to tolerate or switch off (`kit/docs/TESTING.md`
  "Flaky cases").
- **Look and feel work stops at its first still** and waits for the designer's go
  (`review-material`).
- **Reproduce before you diagnose;** additions nobody asked for go first in a report.
- **Keep output small:** logs to a file and its last lines, capped searches; tests in the foreground
  (`kit/agents/ticket-agent.md`), never a loop that polls.

## Project values

Set with the designer (`kit/docs/agents/lead.md`).

- Game: It Socks
- Platforms: Windows and Linux desktop
- Renderer: Forward+ (desktop GPUs).
- Parallel agents: at most 5 at once.
- Models: sonnet by default; opus for Blender, hard netcode or debugging, big refactors
- Save compatibility starts at: the first outside play-test
- Co-op: planned. Before the first netcode ticket the `multiplayer-game-dev` skill asks the mode; the templates of the shape below (README there) are the starting code.
- Co-op shape: scene parts: each thing's state lives on Part nodes in its scene, Parts syncs and saves it, Session is the one RPC node (`kit/skills/multiplayer-game-dev/templates/scene_parts/`).
- Zoo: used: `game/zoo/zoo.tscn`, one station per feature, each its own scene in `game/zoo/stations/`, instanced by hand in `zoo.tscn` (Q2359; the `zoo-design` skill); the example entity is `game/entities/cupboard/`.
- Blender: used.
- Profily (F3 stats overlay): used: in debug builds F3 shows the stats overlay; release builds ship it switched off (`kit/docs/TESTING-more.md` "Exporting").

When Co-op is "not planned", the game has no shared-state path: a feature's state changes go
through that feature's own rules object. Otherwise they go through the co-op shape named above
(the `multiplayer-game-dev` skill).

## Rules only this project has

- **This is a port.** The old game is the reference: the git submodule `reference/it-socks/`, pinned at
  tag `v0.1.1` (Q2231; skipped by Godot and by the kit's tools). Never commit inside it or move its pin. Grep it; do not read its big files whole. What is
  known and decided: `docs/migration/README.md`. How one piece is ported: the `migration-port` skill.
- **Ported by examination, never copied unexamined.** "Improve" means technical only; a look change is its own
  ticket (Q2153).
- **The small details are always explored** (designer, Q2277): every motion, glide, fly, sway, pop and sound of the
  old piece is in its behaviour list. Only the designer drops one: a detail an agent or the lead left out, or
  noted as `[later]`, goes to the designer at once, before the merge (the `migration-port` skill, step 1).
- **Decided state lives on scene parts** and only the Host's answer to a Command writes it. A player's body and
  things in the air use Godot's synchronizers; things created during play use Godot's spawner; the Mess is one
  bulk system that is one Part. Prediction is looks only (`docs/migration/coop-structure-for-the-port.md`).
- **An entity is behaviour plus a swappable Looks child scene**; state plays an AnimationPlayer in Looks, not
  code animation. A new feature is first a station in the zoo, with the game's real entities.
- **Numbers are typed Resources edited in the inspector; screens are scenes on one Theme; Jolt and Godot's own
  nodes wherever they can do the job** (the ragdoll included).
- **Code shape** (Q2251-Q2253): inheritance one step (Part, then Openable; nothing extends Openable); one class per
  file, named alike, no inner classes; a thing gets a script only when no Part can do the job.
- **Files are kept in the Godot editor's own format** (Q2268): scenes and resources with their `uid=` references,
  every script with its committed `.uid`.
- **What Godot should not see carries a `.gdignore`** (designer, Q2242): `docs/`, `reference/`, `assets_src/`,
  `kit/skills/`, `.claude/` (the agents' worktrees) today; a new folder of notes, sources or pictures gets one when it is made. Untracked files the
  editor makes inside `kit/` are ignored by the game's git (`.gitmodules` `ignore = untracked`), never committed
  into the kit.
- **UI is authored in nodes** (designer, Q2658): screens, rows and styles are scenes, nodes and Theme variations;
  code fills them and instances a row scene per item, and never builds a Control or StyleBox itself.
- **A zoo station that shows game data is built from that data at load** (designer, Q2337): a new Design, sound
  or other entry appears in its station with no other change.
- **Nobody but the designer pushes** (designer, 2026-11-24): the lead and agents never run `git push`, for the game or the
  kit; the lead says what is ready to push and in what order (the kit before the game).
- **No commit message carries a Claude (or any AI assistant) `Co-Authored-By` line** (designer, 2026-11-20);
  `kit/tools/commit.sh` refuses one.
