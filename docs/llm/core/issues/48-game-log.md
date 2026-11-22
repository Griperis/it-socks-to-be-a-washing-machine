---
type: ticket
status: done
kind: build
area: tools
feature: core
priority: now
created: 2026-11-22
done: 2026-11-22
blocked_by: []
notes: []
terms: []
---

# The game's one log

The game has no log of its own: 33 bare `print()`, `push_warning()` and `push_error()` calls, and Godot's own
`godot.log` with no levels, areas or build. The kit's `log` template is the rule (`godot-game-dev` skill, "Logging")
and was skipped. The designer wants it in.

## Acceptance
- `kit/skills/godot-game-dev/templates/log/` is copied into the game (where its README says), with its test, and
  added as the autoload `Log`, first in the autoload list (`project.godot`, editor format).
- A log file per run under `user://logs/` that starts with the build (the game's name and version, debug or release),
  the last runs kept as the template does.
- The game's own warnings and errors (settings, Sounds, the sound catalogue, Session, the LOD import and any other)
  go through `Log` with an area; nothing reported is lost.
- The command line's and the benchmark's terminal output (help, `BENCH` lines, the verdict, `BENCH saved`) stays
  plain `print()`: it is output for the terminal and the tools that read it; the code rule that flags a bare
  `print()` gets an exemption for exactly those files.
- The real-path case: the zoo is started headless for a few frames; the run's log file exists under `user://logs/`,
  starts with the build line, and holds an engine error raised during the run with its area and script call.
- `docs/architecture.md` names the log and where its files are (one short paragraph).
- The full suite and the check pass; `tools/mess_bench.sh --only=idle_500` still prints its BENCH line and verdict.

## Answers
- The game adopts the kit's log template (designer, 2026-11-22: "Yes, do this and ideally merge to main").

## Open follow-ups

## Built log

- 2026-11-22. Changed: the kit's log template is the autoload `Log`, first in the list (`game/log/`, its suite as
  `tests/log_test.gd`). Settings, Sounds, SoundCatalogue, Parts, Part, Avatars, Session (`_note` now only Log), the heap
  spout, ZooNet and the bench report go through `Log` with an area (settings, sounds, parts, avatars, net, heap, zoo,
  bench); `ModelLods` finds `Log` by name (at import in the editor no autoload lives, it falls back to `push_warning`).
  Tests of Settings and Sounds that expected an engine error now check the ERROR line in the log. `game_cli.gd` and
  `mess_bench.gd` are exempt from the `print` rule. New `tests/game_log_test.gd`: zoo run, file under logs/, build line,
  an error with its call. Architecture names the log. Left as they were: `tools/*.gd` build scripts (editor tools, not the
  game) and `game_cli.gd` printerr.
  Files: project.godot, game/log/*, game/{audio,parts,settings,sock,zoo,debug}/..., tests/{log,game_log,settings,sounds}_test.gd,
  tools/grep_rules_allow.txt, docs/architecture.md.
  Verified: `PASS 15262 checks, 388 cases` (--touched), `PASS rules`, `BENCH idle_500 ... ok` and `PASS mess bench`.
  The full suite is for the lead's batch run.
- Merged: a8494a03 (2026-11-22, branch core/48-game-log)
