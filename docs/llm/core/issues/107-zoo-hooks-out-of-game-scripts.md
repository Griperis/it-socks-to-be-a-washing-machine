---
type: ticket
status: ready-for-agent
kind: refactor
area: core
feature: zoo
priority: now
created: 2026-11-25
done:
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

## Built log
