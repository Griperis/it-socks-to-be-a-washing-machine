---
type: ticket
status: done
kind: feature
area: core
feature: player
priority: now
created: 2026-11-25
done: 2026-11-25
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
- [later] A real NaN body makes the engine log render errors for a tick, so the case judges NaN/inf as values (`FallRescue`), and the real path uses y = -500, 5000 m away and -1e9.
- [later] Things falling out, by the old game (read in reference/it-socks): it caught things, not players. Its host's lost-item rule (maintenance/06) puts a settled Mess Sock or floor Pair outside the flat (`FlatLayout.is_lost()`: through a wall, out of a window, under or above a floor) back in front of the washer, and pushes one sunk into a floor slab up onto its floor (`sunk_floor`); it also runs on load (saves.gd), for the Radio, the Beeper and Guide cards, and for a Flight in the air (`flight_rules.check_flights`, put down). Ways a thing leaves the map today here: a Sock thrown or dropped through a hole in a floor, a Part or held object released out of a window or wall, a Flight that never lands. Here only the Mess returns a Sock that leaves `mess_bounds`; Parts, Flights and held objects have no catch. A ticket for them would port the lost-item rule.
- [later] A Guest's poses are dropped by `AvatarTuning.holds` outside x -50..50, z -90..50 (area plus margin, a zoo-sized placeholder). If the house reaches past that, a Guest there is not drawn on the Host (the case moves the washer station inside it). Not checked against the house's extents.
- [later] The Host takes a Guest's `stand` Command on trust that they are down (no check that their ragdoll is out of the map); the worst a forged one does is end the sender's own knockdown early.
- [later] The single-machine house has no ragdoll for the player (alone it has none, so it cannot be knocked), so the knocked-down catch is proven in co-op only (`tests/coop_fall_test.gd`).

## Built log

### 2026-11-25
- Changed: a body out of the map (below the Mess volume's floor by 50 m, over 1000 m from its centre on any axis, or not finite) is stood at the washer's Spawns by its Roster place, else the level's Spawn, still and standing; logged as a warning with where it was. The cutscene's respawn now shares that spawn choice.
- Files: game/player/fall_rescue.gd, game/player/player.gd, game/player/move_tuning.gd (fall_depth, fall_reach), game/level/level_runtime.gd (respawn_point, map_frame), game/cutscene/cutscene_player.gd, tests/fall_rescue_test.gd, docs/migration/batch-a-review.md row.
- Verified: fall_rescue 22 checks pass; touched run otherwise green.

### 2026-11-25 (second pass)
- Changed: merged main (the washer turned 90 degrees; the catch still stands the player at a spawn in the laundry room and they walk on). A knocked-down player whose ragdoll falls out of the map asks the Host for the new `Knockdowns.STAND` Command, answered as a leave is (knockdown and drags end, why "fell"), so the ragdoll stands at once on every machine as at a cutscene's end; the player is then put back by the usual check. `Knockdowns.left` takes the why. Co-op: a Guest at y = -500 is put back on its own machine and the Host's Avatar of it stands at the spawn; a knocked-down Guest whose ragdoll (the Host simulates it) falls out is ended and put back the same.
- Files: game/knockdown/knockdowns.gd, game/player/player.gd, tests/coop_fall_test.gd (+ .uid), docs/migration/batch-a-review.md row.
- Verified: fall_rescue and coop_fall pass; touched run otherwise green.
