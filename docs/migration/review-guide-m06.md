# Review guide: the code of M0.6 (co-op)

For the designer's code review of M0.6 (coop/01 to coop/12). About 4,900 lines of co-op code in 25 files,
plus the co-op paths inside the Mess, the Hands and the Player. Read in this order: each step leans on the one
before. The map is `docs/architecture/coop.md`; the flows are "A change", "A join" and "A knockdown" in
`docs/architecture.md`.

## 1. The rule: only the Host decides (about 450 lines)
- `game/parts/part.gd` (126), `game/parts/parts.gd` (191), `game/parts/command.gd` (131).
- Look for: every change goes `ask` -> `decide()` -> `apply`; `decide()` only reads; nothing else writes a Part's
  State group. `Command.shape_error` and `args_error` check every value a Guest can send.
- Question to ask: can any path on a Guest write state without the Host's answer? (It should not; `went_alone()`
  is looks only.)

## 2. The link (about 800 lines)
- `game/parts/session.gd` (480): read the header first (the gate and the guards are described there), then
  `_refusal` (the gate), `_command` (the guards, in order), `_on_applied` (answers out), `close` (leaving).
- `game/net/net_transport.gd` (30), `enet_transport.gd` (72): the seam for Steam at M4; only this file names ENet.
- `game/net/roster.gd` (192), `player_profile.gd` (83), `level_net.gd` (174), `coop_tuning.gd` (34).
- Look for: no RPC but the three in Session; a Guest admitted only after the gate; every drop counted, never a
  kick; `PROTOCOL` bumped with each wire change.

## 3. Players seen (about 1,500 lines)
- `game/parts/avatar/avatars.gd` (122), `avatar.gd` (351): the pose and its checks in the setters (`_takes`).
- `avatar_looks.gd` (436): looks only (waddle, bend, squash, pupils); the longest file here, and only looks.
- `game/audio/hearing.gd` (91), `teammate_steps.gd` (63): a Teammate's sounds at their body.
- Look for: what the owner sends (four numbers) versus what every machine derives; the area check.

## 4. The Mess, Hands and Throw in co-op (about 820 lines here, plus the Mess's co-op paths)
- `game/hands/guest_ghosts.gd` (292), `throw_ghost.gd` (310): a Guest's guesses, matched by `seq`, looks only.
- `game/sock/flight_row.gd` (221): a Throw's stamped rows, played 0.1 s behind on a Guest.
- In `game/mess/mess.gd` and `mess_moving.gd` read only the co-op parts: `decides()`, `went_alone()`,
  `_on_flight_in`, `MessMoving._launch` (a Guest's body on `LAYER_LOOKS`), `tick_looks`, `take_over`.
- Look for: a Guest's own bodies never ask anything; the Host's `rest` snaps them; a leaver plays on alone.

## 5. Knockdown (about 1,010 lines)
- `game/knockdown/knockdowns.gd` (567): the Part (who is down, drags, struggles); `knock` and `release` are the
  Host's own verbs, so they are not in `accepts()`.
- `game/parts/avatar/ragdoll.gd` (376) and `ragdoll.tscn`: Godot's PhysicalBoneSimulator3D, simulated on the
  Host, a stamped 84-byte pose eased elsewhere.
- `game/player/player.gd`: only `_lie`, `_knocked_camera`, `_let_go_body` and the drag input.
- Look for: one writer of who is down; the pose checked by size; every machine plays the rise itself.

## 6. The tests (read one, skim the rest)
- Read `tests/coop_guard_test.gd` whole (short): what a modified Guest can try and what the Host does.
- Skim the real paths, each at 0 and 50 ms one way: `coop_join:join`, `teammates:walk_crouch`,
  `coop_mess:pour_real_path`, `coop_hands:guest_pick_throw_real_path`, `coop_knockdown:real_path`.
- `tests/support/lag_peer.gd`: the test's slow network (delay, loss, byte counts).

## What to look for everywhere
- A rule in one place: the Host's check in `decide()`, not repeated in the Player or the looks.
- Looks never write state; state never waits on looks.
- Numbers in typed Resources (`coop_tuning.tres`, `avatar_tuning.tres`, `ghost_tuning.tres`,
  `knockdown_tuning.tres`), placeholders marked.
- Code shape (Q2251-Q2253): inheritance one step from Part; one class per file; no inner classes.

## The cost, for the record
`docs/architecture/coop.md` "The cost": bytes a second each way and both machines' frame times with a Guest at
2,000 Socks, measured in two processes (`tools/coop_cost.sh`).
