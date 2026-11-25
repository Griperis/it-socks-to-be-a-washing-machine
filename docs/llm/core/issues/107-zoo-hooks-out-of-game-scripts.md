---
type: ticket
status: done
kind: refactor
area: core
feature: zoo
priority: now
created: 2026-11-25
done: 2026-11-25
blocked_by: []
notes: ["suggested model: opus", "designer 2026-11-25: do it; Q2409 says nothing outside game/zoo/ refers to what only the zoo needs"]
terms: [zoo, station]
---

# Zoo-only code out of the batch A game scripts

Batch A put zoo-only flags, state, verbs and stand-ins inside game scripts. Q2409: what only the zoo needs lives
under `game/zoo/`, grouped per station, and nothing outside `game/zoo/` refers to it.

The places today (grep `zoo`, case-insensitive):
- `game/entities/washer/washer.gd` (49): `zoo`, `zoo_plan`, `zoo_mood`, `zoo_stage`, the zoo's `broken` switch,
  and the Commands `zoo_mood`, `zoo_stage`, `zoo_broken`, `zoo_cutscene`.
- `game/laundry/laundry_day.gd` (55): `zoo`, `zoo_fixed`, `zoo_held_designs`/`zoo_held_poses`, `ZOO_HELD*`, and the
  Commands `zoo_last_fix`, `zoo_final`, `zoo_first_wash`.
- `game/run/stages.gd` (11): the verbs `zoo_complete`, `zoo_fit_now` and their answers.
- `game/entities/machine_part/machine_part_slot.gd` (4): the zoo's box as an aim target (check whether this is
  general "aim the slot itself" behaviour, worded as zoo; if so only the wording changes).

## The way (a suggestion; the agent may find a better one and says so)
- Where the game script reads a link that is empty in the zoo (`stages`, the run), the station supplies a stand-in
  under `game/zoo/<station>/` that answers the same calls (the Stage, the Parts fitted, the last Fix, the held
  Socks), so the game script has one path and no `zoo` flag.
- The zoo's switches that must change decided state stay Host-decided: the stand-in (a Part under `game/zoo/`)
  answers their Commands and owns that state, or the switch asks a verb the game really has. No zoo verb stays in a
  game script.
- A setting the game also needs that was only named for the zoo (for example `cutscene` off for tests) stays, with
  a name that says what it does.

## Acceptance
- No zoo-only flag, export, constant, verb or Command in the four scripts above; their doc comments no longer
  describe the zoo except to say a link may be empty.
- Every station that used them (washer, laundry, stages, voice, final screen, any other) works as before: the
  same pillars and switches, the same results. Each station's suite still passes; its real-path case still drives
  the station's own wiring.
- The house runs as before: the full suite passes, nothing flaky, no new SLOW line.
- Co-op: the switches still go through the Host's answer to a Command.
- No look, feel, wording or sound changes. No game data moved.
- The report lists other game scripts outside `game/zoo/` with zoo-only hooks (for example `player.gd`,
  `held_view.gd`, `hands_tuning.gd`, `title.gd`, `game_cli.gd`) as a follow-up list with counts. It does not fix them.

## Open follow-ups
- [later] Other game scripts outside `game/zoo/` that name the zoo (case-insensitive `zoo` hits, many are doc comments
  only): `player/player.gd` 21, `hands/held_view.gd` 19, `ui/title/title.gd` 10, `hands/hands_tuning.gd` 9,
  `debug/game_cli.gd` 9, `net/level_net.gd` 6, `level/level_runtime.gd` 6, `ui/hud.gd` 4, `hands/hands.gd` 4,
  `ui/prompts.gd` 3, `mess/generated_socks.gd` 3, 2 each: `ui/hud_tuning.gd`, `parts/avatar/avatar.gd`, `mess/mess.gd`,
  `entities/washer/washer_tuning.gd` (`zoo_levels`, also read by the game's broken look: rename it for what it does),
  `debug/mess_watch.gd`; 1 each in 21 more (final_summary, stacks, design_catalogue, stage, player_upgrades, ping_marks,
  session, avatar_tuning, roster, game_link, coop_tuning, sock_preview, sock_generator, mess_tuning, mess_moving,
  picture, graphics_preset, washer_looks, laundry_bin, mess_checks, cutscenes).
- [later] Seen, not changed: in the whole zoo (one LevelRuntime) `LaundryDay.of()` and `Washer.of_level()` find the
  first of their kind, so the Laundry station's Laundry day reaches the washer station's real washer (its pile, its
  door, the load's reach). Scoping those lookups to the station would be its own ticket.

## Built log
- 2026-11-25
  - Changed: the washer and the Laundry day read their run through their `stages` link (now any Part with the Stages
    reads; `Stages` gains `under_way`, `is_fixed`, `part_total`, `parts_missing`, `comment_set`, `last_pair_in`); every
    zoo flag, export, state field and Command left `washer.gd` and `laundry_day.gd`. Each station has a run stand-in
    under `game/zoo/<station>/` (`WasherRun`: broken, mood, Stage, cutscene; `LaundryRun`: last Fix, Final wash, First
    wash with held Socks) that owns that state and answers the switches as Host-decided Commands. `Stages`'
    `zoo_complete`/`zoo_fit_now` are now `complete_now`/`fit_now`. `LaundryDay.opens_final_screen` (on; the station
    turns it off) replaces the zoo's "no Final screen"; its save is version 4 (the dropped fields go). The Stage bar
    reads `goal_pending` only in its run's level. `machine_part_slot.gd`: wording only (the general "aim the slot's own
    thing"). Two rows under "Settled by the old game".
  - Files: game/run/stages.gd, game/entities/washer/washer.gd, washer_senses.gd, game/laundry/laundry_day.gd,
    game/entities/machine_part/machine_part_slot.gd, game/ui/stage_bar.gd, game/zoo/washer/*, game/zoo/laundry/*,
    game/zoo/stages/stages_switch.gd, the two station scenes, tests (washer, washer_broken, first_wash, laundry_day,
    coop_cutscene, stages, fix_scene, machine_part, floor_lock, coop_fix_scene, house, save, saves/shape.json), docs.
  - Verified: `--touched` 87 of 93 suites, 22776 of 22777 checks (the save shape, then committed: `--only=save` PASS 101 checks, 17 cases); agent_finish re-runs `--touched`.
- Merged: 879268f5 (2026-11-25, branch core/107-zoo-hooks-out)
