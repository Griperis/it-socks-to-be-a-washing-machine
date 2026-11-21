# Backlog after M0.5

Work found while building the core (M0.5), moved here from the `[later]` follow-ups of the core tickets on
2026-11-21 (the M0.5 close-out, Q2425). One line each, with its source ticket and its milestone where the
catalogue or `milestones.md` names one. Nothing here is decided as play; a play question is asked first.

## Mess
- Lend the aimed moving Sock a Looks so it can be outlined (today `give_looks` picks the flight nearest the camera, up to `flying_cap`). Source: core/11. Milestone: M3.

## Hands and Throw
- Remove the unread `HandsTuning` fields `settle_limit`, `wake_reach` and `wake_gap` (nothing reads them since core/13). Source: core/13. Milestone: with the next edit of `game/hands/hands_tuning.gd`.
- Show the "Sprint [Shift]" hint in the corner when sprint exists. Source: core/15. Milestone: M4 (Upgrades).

## Cabinet
- A hollow cupboard entity of its own (the zoo station hollows the solid box by overrides). Source: core/02. Milestone: M1 (the furniture port, assets/07).

## Sock looks
- (nothing moved here)

## Screens
- Keycap buttons, keycap panels, sliders, fields and upgrade rows (`ui_bits.gd`), with a KeycapStyle that respects Q2253 (no inner class). Source: core/18. Milestone: M4 (menus).

## Sound
- The old sound details not built: about 80 other events (UI clicks and hover, piano, voices, vacuum, radio, cat, fridge), `shares`, the sound bench, the `silent` flag, `layers` and `playlist` modes, window ambience and its fade, UI sound jitter, the music duck in cutscenes, the piano voice pool, pad rumble. Source: core/17. Milestone: M1.1 (Sound); the designer drops any of them, not an agent.
- Coins sound and the "done" rumble (M4); the knock rumble and teammates' sounds (M0.6, Q2376). Source: core/25. Milestone: M4 and M0.6.
- One sound tuning pass by ear: min gaps (bounce 0.05 s, pop and shelve 0.05, refuse and the drawer, door and cupboard sounds 0.1 s), the bounce's soft end (-15 dB, pitch 0.9 to 1.15) and hard speed (8 m/s), and the bounce speed measured along the surface normal as the old game did (today the body's whole speed, so a glancing slide over 1.5 m/s still bounces). Source: core/25. Milestone: M1.1.

## Zoo
- The heap station's other pour modes: a heap where the crosshair aims, rain over every room, a count set by hand, clear all; `SockPour.stop()` resting every falling Sock at POUR_MAX; the `poured` signal and a "Last pour" line. Source: core/20. Milestone: none; the designer chooses when needed.
- `Mess.count_of()` counts GONE records too, so the heap station's count of a Design may be too high after a respill. Source: core/20. Milestone: none.
- A label per Sock rather than per Design at the every-Sock station. Source: core/12. Milestone: none.
- A lying Pair in the outline station (a SockSpot cannot place one). Source: core/11. Milestone: none.

## Tools and tests
- Drop `tests/main_test.gd` (it runs the kit's placeholder `main/main.tscn`) once the game has a real start. Source: core/01. Milestone: M3 (the walking skeleton lands in the main scene).
- Split `tests/handling_test.gd` (668 lines) and `game/mess/mess.gd` (866 lines) when next touched (grep_rules notes over 600). Source: core/02, core/20. Milestone: with the next edit of each.
- Old-game looks-baseline stills of an aimed Sock and a Door (need the old game's capture tour with new views, run in the reference clone). Source: core/11. Milestone: none.
- `docs/architecture.md` (the zoo paragraph) to say that the zoo owns the one Mess, Hands and Coins. Source: core/10. Milestone: the code map update of the M0.5 close-out (Q2425).
- `tools/furniture_build.gd` does not compile in a `--script` run (it preloads `openable.gd`, which names `Sounds`); `LAYER_HOUSE` in it and in `tools/house_kit_build.gd` stays a literal `1` for the same reason. Source: core/30. Milestone: before the next furniture or house rebuild (M1, M2).
- `tools/mess_bench.cmd` was never run on Windows. Source: core/31. Milestone: M3 (the Mess bench); before the first Windows build.
- The export preset (release-export skill) must exclude `game/debug/` and the zoo as `docs/architecture/mess.md` "Benchmark" (C6) says; no preset exists. Source: core/35. Milestone: the first playtest build (`release-export` skill).
- The kit's `zoo-design` skill and its templates still describe the folder collector (Q2359 replaced it); the lead proposes the change upstream with `kit.py propose` after the designer's say. Source: core/26. Milestone: none.

## Co-op
- A Guest's capacity and reach (Hands read the `HandsTuning` of a player on this machine, else their own), a leaver's Hands (their Socks stay HELD), a falling Sock seen by a Guest only as the untinted body. Source: core/02. Milestone: M0.6.
- A Guest's Throw leaves from `EYES_FALLBACK` (1.5 m), and only the local body lets its own thrown Sock through (`Mess._spare_thrower`); both need the Guest's eyes and avatar. Source: core/08. Milestone: M0.6.
- Woken flights are spawned nodes (up to 512 over the spawner on a big wake) with no synchronizer yet; Doors and drawers sweep on the Host only. Source: core/13. Milestone: M0.6.
- Co-op cost: every `add` and `rest` answer carries the Mess's whole arrays (about 4,000 records with 2,000 poured); measure with a Guest. Source: core/20. Milestone: M0.6.
- The heap sign's Moving count is the Host's flights; a Guest shows 0 moving. Source: core/20. Milestone: M0.6.
- `Footsteps` plays `land` and `step_*` flat at full level; Guests' footsteps must play spatially at their body. Source: core/28. Milestone: M0.6.
- A Guest finds a flight's spawned copy by its name (`Flight<id>`); a rest and a wake of one Sock in one tick makes Godot rename the new body. Source: core/31. Milestone: M0.6.
