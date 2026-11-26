---
type: ticket
status: done
kind: build
area: core
feature: player
priority: now
created: 2026-11-26
done: 2026-11-26
blocked_by: ["[[127-profile-file-and-tallies]]", "[[141-looks-in-coop]]"]
notes: ["batch B (Q2614); order: docs/migration/milestones.md Batch B, wave 4", "suggested model: opus"]
terms: [Achievement, Profile, Lifetime tallies, Wardrobe]
suites: [game_link, menus, ui_nodes, stages, run_tallies]
---

# Achievements: the system, the toast and the station

A player earns Achievements in their own Profile. This ticket builds the system with no shipped list: which
Achievements batch B ships is core/146 (`needs-info`). Build `docs/architecture/wardrobe.md` "Achievements":

- `Achievement` (Resource: `id` by the Steam API rules, `title`, `description`, `icon` or the shared placeholder,
  `hidden`, `credit`, `tally` and `at`, an optional `reward: WardrobePiece`), `Achievements` (a Node in the game link,
  every machine: `check()` for the local player only, also at the game link's start; a reward through
  `profile.unlock_piece` and `Roster.own`, then the HUD message "Wardrobe: <name> unlocked"), `AchievementBackend`,
  `LocalAchievementBackend` (always on), the fake backend under `tests/`, `AchievementTuning`.
- The toast `achievement_toast.tscn` on the HUD's layer (a cream card top right: icon 48 px, "Achievement" caption,
  the title; slides in, stays `toast_seconds` 4 s, slides out; queued; held while a cutscene or the Final screen
  shows) and the `achievement` SoundEvent (the first synthesised candidate).
- Debug builds: `debug_achievement_grant_all` and `debug_achievement_reset` (`python3 kit/tools/input_actions.py add`);
  a reset never takes a piece away. Achievements count in every build.
- The Achievements station `game/zoo/stations/achievements.tscn` (instanced by hand in `zoo.tscn`): one pillar per
  file in `game/profile/achievements/` (built at load, Q2337), switches "Grant all", "Reset", "+100 Pairs"; with no
  files it shows an empty board.
- Tests use fixture Achievements under `tests/fixtures/`, not shipped files; a test checks the id rules on every file
  in the folder.

Behaviour lines (`docs/migration/m4-lists/08-wardrobe-profile-achievements.md`): "Achievements" (the system lines; the
list is core/146's; Steam's pop-up and mirror are batch D's, named there).

Batch B is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-b-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
A designer adds an Achievement by dropping a `.tres` into `game/profile/achievements/`: it shows on the page and in the
station. The toast is a scene in nodes; its slide is a clip or tween on its own nodes, its numbers in
`AchievementTuning` (`# placeholder:`).

## Acceptance
- Real path: on the Stages station's mini run, with a fixture Achievement "1 Pair shelved" on a fresh zoo profile, the
  player shelves a Pair by a left click: the toast slides in with its title and the profile records it with a time.
- A fixture with a reward puts the piece in the profile and on the Roster and shows "Wardrobe: <name> unlocked".
- Earned once, never again; a reset clears earned ones and keeps pieces.
- Placeholders: `AchievementTuning`.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- Achievements stay planned (Q2602) and are batch B (Q2614, 2026-11-24).
- The ten basic pieces are owned from the start, so no Achievement is needed to have them (Q2679, 2026-11-25).

## Open follow-ups
