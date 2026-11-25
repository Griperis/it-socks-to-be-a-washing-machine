---
type: ticket
status: in-progress
kind: feature
area: core
feature: player
priority: now
created: 2026-11-25
done:
blocked_by: []
notes: ["suggested model: sonnet", "designer 2026-11-25: a fallback that puts back anyone who drops out of the map"]
terms: [Host, Guest]
---

# Anyone who falls out of the map is put back

The designer: "add fallback so if anyone would drop outside of map (some weird large number) it ports them back."
Today nothing catches a player who falls through the floor or is flung far away.

## What it does
- Each machine watches its own player's body (it owns that body; the synchronizer carries the result to the others).
  When the body is out of the map, the player is put back standing at the washer's `Spawns`, by the Roster's order,
  the same place and call the cutscene end uses (`CutscenePlayer._respawn`, `player.respawn_at`, Q745). With no
  washer (the zoo, a bare level), they go to the level's own player spawn.
- "Out of the map": below the level's lowest floor by a margin, or farther than a limit from the level's centre on
  any axis, or a position that isn't finite (NaN or inf). The numbers are a tuning Resource; placeholder values are
  50 m below and 1000 m away, and the ticket says what it picked.
- A ragdoll or knocked-down player is ended first, the same way the cutscene's respawn ends it.
- Logged once per catch as a warning, with where the body was, so a hole in the floor can be found later.
- Not in this ticket: things (Socks, Parts, held objects) that fall out. The report says whether the old game caught
  those and how many ways a thing can leave the map today, as a [later] follow-up.

## Acceptance
- Real path: in the house, the player's body is put at y = -500 (and in a second case at a NaN position). Within a
  second the player stands at a washer spawn and can move.
- Co-op: a Guest who falls is put back on the Guest's machine, and the Host sees them at the spawn.
- A player standing anywhere in the house, on any floor, on top of furniture or mid-jump is never caught. A case
  walks the floors' extremes.
- The full suite passes, nothing flaky.

## Open follow-ups
- [later] Co-op case not written: each machine runs the same Player check on its own body with its Roster place (`LevelRuntime.respawn_point`), but no two-house case proves a Guest's catch is seen by the Host.
- [later] A knocked-down player is not caught while down (their body follows the ragdoll and only the Host can end a knockdown); they are caught the moment they rise. A fall during a knockdown needs a Knockdowns command to end it.
- [later] A real NaN body makes the engine log render errors for a tick, so the case judges NaN/inf as values (`FallRescue`), and the real path uses y = -500, 5000 m away and -1e9.
- [later] Things (Socks, Parts, held objects) falling out: the old game could not be read (reference/it-socks is not checked out in the worktree); the Mess already returns a Sock that leaves `mess_bounds` to the return spot (mess.gd `bounds`).
- [later] The real-path case only checks the spawn within 0.5 m horizontally; the washer's turn on main was not in this branch, so rebase and recheck the player stands after the catch.

## Built log

### 2026-11-25
- Changed: a body out of the map (below the Mess volume's floor by 50 m, over 1000 m from its centre on any axis, or not finite) is stood at the washer's Spawns by its Roster place, else the level's Spawn, still and standing; logged as a warning with where it was. The cutscene's respawn now shares that spawn choice.
- Files: game/player/fall_rescue.gd, game/player/player.gd, game/player/move_tuning.gd (fall_depth, fall_reach), game/level/level_runtime.gd (respawn_point, map_frame), game/cutscene/cutscene_player.gd, tests/fall_rescue_test.gd, docs/migration/batch-a-review.md row.
- Verified: fall_rescue 22 checks pass; touched run otherwise green.
