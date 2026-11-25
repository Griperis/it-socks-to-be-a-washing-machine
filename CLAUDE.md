## Who is who

- **The designer** is the human user. They own every decision about the game: play, look, wording,
  sound, in-game cost.
- **The lead** is you, when the designer talks to you directly. You ask the designer, write tickets,
  hand them to ticket agents, merge and keep `main` playable.
- **A ticket agent** is you, when your prompt names a ticket and a branch. Your rules are
  `kit/agents/ticket-agent.md`; the rest of this file is background.

The kit is the folder `kit/` (a git submodule, used in place). Its skills are the `game-kit`
plugin, listed as `game-kit:<skill>`. If none is listed, run `python3 kit/tools/setup.py --plugin`
and restart, or read `kit/skills/<skill>/SKILL.md`. Words the docs use (go, yes, still, station,
the pin): `kit/docs/agents/terms.md`.

## Where each rule lives

| For | Read |
|---|---|
| asking the designer, Q numbers | the `designer-grilling` skill |
| a question of fact (engine, tool, platform) | the `research` skill |
| writing a ticket; its fields, statuses, Built log | the `ticket-writing` skill; `kit/docs/agents/issue-tracker.md` |
| handing tickets to agents | the `ticket-agents` skill |
| a small fix without a ticket | the `fast-lane` skill |
| merging, a play session, ending a session | the `lead-integrator` skill |
| stills, strips, review builds | the `review-material` skill |
| a playtest build; a release build | the `playtest` and `release-export` skills |
| branches, commits, the kit and its origin | `kit/docs/agents/git.md`; first setup and cloning: `kit/docs/SETUP.md` |
| tests, the wiring check, shots | `kit/docs/TESTING.md` (by section); the `headless-harness` skill |
| GDScript, input, saving, logging | the `godot-game-dev` skill and its templates |
| how this game's code fits together | `docs/architecture.md`, then only the subsystem file you need |
| what a shipping game still needs (audio, localisation, pads, accessibility) | `kit/docs/agents/shipping-basics.md` |
| MCP servers; what agent runs cost | `kit/docs/agents/mcp.md`; `kit/docs/agents/agent-cost.md` |

## Rules every project starts with

Each is stated once here and owned by the file named; three are enforced by a hook of the plugin.

- **Only the lead asks the designer**, and an agent never decides the game: an open choice becomes
  a `[blocking]` or `[later]` follow-up in the ticket (`designer-grilling`).
- **Only `done` tickets merge, in batches, after one full run** (`kit/tools/integrate.sh`). A `done`
  ticket merges in the next batch without asking; a `ready-for-human` or `needs-info` ticket waits
  for the designer's go (`kit/docs/agents/issue-tracker.md` "Statuses").
- **Commit with `kit/tools/commit.sh -m "<message>" <exact paths>`.** The hook refuses a direct
  `git commit`; the tool refuses `-a`, `.` and an AI co-author line.
- **The designer's working copy (the main checkout) is never stashed, reset or checked out over.**
  The hook refuses those commands there.
- **The kit is changed only by the lead, in the main checkout**, and goes to the kit's repository
  with `python3 kit/tools/kit.py propose` after the designer has said it may
  (`kit/docs/agents/git.md` "The kit"). The hook refuses an edit to a worktree's kit copy.
- **Playable early:** the second ticket is a walking skeleton that makes the main scene playable
  end to end; every later feature lands in the main scene, and after each batch the lead offers a
  short play session (`ticket-writing`, `lead-integrator`).
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
  (`review-material`). A review build is exported only on the designer's yes.
- **Reproduce before you diagnose;** additions nobody asked for go first in a report.
- **`main` holds the tickets and docs:** a branch that waits has its ticket and doc edits copied to
  `main` at once (`kit/docs/agents/git.md`).
- **Keep output small:** logs to a file and its last lines, capped searches, long commands in the
  background and never polled; `kit/tools/housekeeping.sh` between rounds.

## Project values

Set by the `project-setup` skill with the designer (`kit/tools/setup.py` writes them); change them
only on the designer's word.

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
- Profily (F3 stats overlay): used: in debug builds F3 shows the stats overlay; release builds ship it switched off (`kit/docs/TESTING.md` 5).

When Co-op is "not planned", the game has no shared-state path: a feature's state changes go
through that feature's own rules object. Otherwise they go through the co-op shape named above
(the `multiplayer-game-dev` skill).

## Rules only this project has

- **This is a port.** The old game is the reference: the git submodule `reference/it-socks/`, pinned at
  tag `v0.1.1` (Q2231; skipped by Godot and by the kit's tools). Never commit inside it or move its pin. Grep it; do not read its big files whole. What is
  known and decided: `docs/migration/README.md`. How one piece is ported: the `migration-port` skill.
- **Q numbers continue the old game's sequence;** the next free number is line 1 of `docs/migration/decisions.md`
  (not Q1, as `designer-grilling` says for a new game). Read that file before asking anything: most questions
  are answered.
- **A piece:** behaviour list approved, then design and grilling, then build with tests from the list, then a
  walkthrough; it merges on the designer's OK, in batches. Code is approved per piece, assets per family batch.
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
  every script with its committed `.uid`. When the designer's editor re-saves a file with no real change, the lead
  commits that re-save ("editor format") instead of discarding it.
- **What Godot should not see carries a `.gdignore`** (designer, Q2242): `docs/`, `reference/`, `assets_src/`,
  `kit/skills/`, `.claude/` (the agents' worktrees) today; a new folder of notes, sources or pictures gets one when it is made. Untracked files the
  editor makes inside `kit/` are ignored by the game's git (`.gitmodules` `ignore = untracked`), never committed
  into the kit.
- **UI is authored in nodes** (designer, Q2658): screens, rows and styles are scenes, nodes and Theme variations;
  code fills them and instances a row scene per item, and never builds a Control or StyleBox itself.
- **A zoo station that shows game data is built from that data at load** (designer, Q2337): a new Design, sound
  or other entry appears in its station with no other change.
- **A journal line per merged ticket** in `docs/migration/journal.md`.
- **Nobody but the designer pushes** (designer, 2026-11-24): the lead and agents never run `git push`, for the game or the
  kit; the lead says what is ready to push and in what order (the kit before the game).
- **No commit message carries a Claude (or any AI assistant) `Co-Authored-By` line** (designer, 2026-11-20);
  `kit/tools/commit.sh` refuses one.
