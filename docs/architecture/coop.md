# Co-op

What makes the game a Host and up to three Guests (M0.6). The flows "A change", "A join" and "A knockdown"
in `docs/architecture.md` say what happens in order; this file says who owns what. The rules behind it:
`docs/migration/coop-structure-for-the-port.md` (decided state on scene parts, the Host answers),
`docs/migration/coop-mess-sync.md` (the Mess), `docs/research/coop-flight-sync.md` and
`docs/research/coop-ragdoll-sync.md` (the two spikes).

## What it owns

| Piece | Files | Owns |
|---|---|---|
| The game link | `game/net/game_link.gd/.tscn` | Lives for the whole game beside the current scene (core/62, Q2582): holds the `Session`, its `Roster` and the link's `Parts` (ids prefixed `Runtime/`, so the Roster stays `Runtime/Session/Roster`). The title makes it beside itself (under the root in the game; SceneChanger leaves it alone) and frees it when the game is back at the title; a level with none (F5, the zoo, `--scene=`, tests) makes a private one, beside itself when it is the scene the machine runs (F5: the title's path, core/68), else under its runtime. Found with `GameLink.of(node)`; `LevelRuntime` hands its Session and Roster to the Net, Avatars, Autosave and ESC menu |
| The session | `game/parts/session.gd` and its helpers `session_peer.gd`, `session_gate.gd`, `session_house.gd`, `session_guard.gd`, `session_relay.gd` (maintenance/04) | The only node with RPCs: the gate (PROTOCOL, player id, name, and the layout hash when the Guest already has a level), the guards, Commands up, answers down, the link snapshot at connect (`linked`), the house handshake (`house_ready` with PROTOCOL and layout; the level snapshot once the Host's level is settled: `welcomed`), a leaver, the Host quitting. Works with the link's Parts and the attached level's (`attach_level`/`detach_level`; the level's read through to the link's). `session.gd` keeps the public calls, `PROTOCOL`, every `@rpc` (one line each) and the session's life; the work is in the helpers (see "The session's files") |
| The transport | `game/net/net_transport.gd`, `enet_transport.gd` | How a machine reaches the others; the only file that names ENet or reads an address (Steam comes as another transport at M4) |
| Start and words | `game/net/level_net.gd` | `--host`, `--join=`, `--profile=`; the HUD's toasts and mode line |
| Who plays | `game/net/roster.gd`, `player_profile.gd`, `coop_tuning.gd/.tres` | The Roster Part (by player id: peer, name, colour, place; alone too, the player in its own Roster through `Session.enter_alone()`, core/58, so Hands and Coins are keyed by player id); the long random id in `user://profile[_<tag>].json`; max players, colours, timeouts |
| The rules | `game/parts/part.gd`, `parts.gd`, `command.gd` | Every shared thing is a Part; `decide()` on the Host only; `Parts.apply` the one writer; the Command's wire shape and arg checks |
| Bodies seen | `game/parts/avatar/` | `Avatars` spawns one `Avatar` per Roster entry; the pose goes from its owner on a MultiplayerSynchronizer, checked in its setters; `AvatarLooks` derives every motion; `Ragdoll` the knockdown body |
| A Guest's guesses | `game/hands/guest_ghosts.gd`, `throw_ghost.gd`, `ghost_tuning.tres` | Looks only: a pick, drop, Throw or wheel shown at once and matched to the Host's answer by `seq`; a Throw or drop flies its own body from the hand the Host lets it go from, corrected once it parts (Q2573) |
| Throws in the air | `game/sock/flight_row.gd` | A Throw's body streams stamped rows to every Guest; the Guest plays them 0.1 s behind |
| The Mess in co-op | `game/mess/mess.gd`, `mess_moving.gd` | Every machine starts its own body for a flying Sock; a Guest's are looks only on `Mess.LAYER_LOOKS`; the Host's `rest` snaps them |
| Knockdown | `game/knockdown/knockdowns.gd` | Who is down, who drags whom, struggles; Host-only `knock`; the one hit test of every Throw at a body (a full charge knocks, a weaker one is a catch or a bounce) |
| Stacking | `game/stacking/` (`back.gd`, `player_stack.gd`, `stacks.gd`, `stacking_tuning.tres`) | Nothing decided: each Avatar's `Back` is a plain disc where the body is drawn on this machine; the local player's `Stack` meets, rides (moving its own body by what the back moved), climbs onto one, halves its pace while a Teammate's pose says they ride it; the soft push. The pose carries `pose_riding` and `pose_ride_offset` (Q2592): every other machine draws a rider at its carrier's drawn feet plus the offset, and `pose_jumps` (Q2593): each new one plays `jump` at the body (`TeammateSteps`) |
| The Hand-off | `game/hands/hands.gd` (`hand_off`, Host-only `catch`), `hand_off_tuning.gd/.tres`, `AimFinder.mate()` | The active item given to an aimed Teammate (core/42): a Pair always, a loose Sock only completing a Pair there; no room, it lies at their feet; never to a knocked-down one. A Guest guesses nothing and waits (2 s, then "refuse"); the receiver's HeldView flies the item in from the giver's hand as drawn on each machine (`HeldView.fly_from`) |
| Pings | `game/ping/` (`Pings`, `PingAim`, `PingMarks`, `PingMark`, `PingWheel`, `ping_tuning.tres`), `game/player/pinger.gd`, `game/ui/hint_arrows.gd` | One standing ping per player (core/43), a Part under the runtime (`Runtime/Pings`): any player's `ping` names a Mess Sock, a Teammate, a thing with an Outline by its path from the level, or a spot; the Host falls back to the spot for what is gone. Each machine counts it down on its own clock; not saved, not in the join snapshot (`whole_state()` empty; a standing ping first seen in a later answer never shows). A Guest guesses nothing (Q2590). `PingMarks` draws it on every machine (outline through walls, ring, bubble, the copy beside the pinger's head) and feeds the HUD's `HintArrows`, whose open source list takes the X-rays and Mate Radar in M4 |
| Teammates heard | `game/audio/hearing.gd`, `teammate_steps.gd` | A Teammate's cues and steps at their body (`Sounds.play_from`) |

## The session's files
`Session` is one node and the only one with RPCs (Godot finds an RPC by node path and name). Its work is in
plain helper classes beside it (`RefCounted`, one per file, made by the Session with itself as `_s`); they read
and write the Session's own fields and call its RPCs, and nothing else holds them.

| File | Its one job |
|---|---|
| `session.gd` | Public calls (`host`, `join`, `close`, `enter_alone`, `attach_level`, `sees_house`, ...), signals, `PROTOCOL` and the gate's constants, every `@rpc` as one line into a helper, `_guests`, `_end`, `_note` |
| `session_peer.gd` (`SessionPeer`) | Opening (`host`, `join`) and closing the peer: the SceneMultiplayer signals, the auth callback, every helper's `clear()` on close |
| `session_gate.gd` (`SessionGate`) | The gate word both ways, the refusals, a Guest taken into the Roster with the link snapshot (`joined`), a leaver (`left`); `clamped_hands` and `own_hands` stay as calls that return nothing (core/130) until the session's callers drop them |
| `session_house.gd` (`SessionHouse`) | The house handshake both ways: `house_ready`, the level snapshot, who is in (`_houses`), a level attached or detached |
| `session_guard.gd` (`SessionGuard`) | A Guest's Command checked in the guards' order, then answered; `drop`/`count` (`Session.dropped`, `stats`), the rate |
| `session_relay.gd` (`SessionRelay`) | Which Parts the Session listens to, which Guests hear each answer (`on_applied`), a Guest's way up (`send_up`), `is_link_part` |

### Adding a verb
- **A verb on a Part** (nearly every one: a new action, the run's state): the Part declares it in `accepts()` (its
  args, a `"rate"` if 10 a second is wrong) and answers it in `decide()`; a Guest's `Parts.ask` reaches it through
  `SessionGuard.command` unchanged. Session needs no edit; bump `PROTOCOL` (a new Command shape) in `session.gd`,
  one line. A Host-only verb is left out of `accepts()`.
- **A new message that is not a Command** (rare: a handshake step, a one-off snapshot): one `@rpc` function in
  `session.gd`, one line calling a method on the helper whose job it is (or a new `session_<concern>.gd` helper
  for a new concern, made beside the others in `session.gd`), its packet checked in that helper before anything
  reads it (`_guard.drop` with a reason added to `Session.dropped`'s list), and `PROTOCOL` bumped.
- Never a second node with RPCs, and never an RPC's body in `session.gd` beyond its one line.

## Rules that hold everywhere
- **Only the Host decides.** A Guest's `Parts.ask` goes up through `Session._command`; nothing on a Guest
  writes a Part but the Host's answer (`_event`, an `authority` RPC Godot refuses from anyone else).
- **The guards, in order** (`Session._command`, worked in `SessionGuard.command`): sender admitted; wire shape (`Command.shape_error`); the
  target is a bound Part; the Part accepts the verb; the args match exactly (`Command.args_error`); the
  verb's rate (`"rate"` in `accepts()`, else `Session.RATE`, 10 a second). A drop is counted in `dropped`
  (per player and reason), logged at most once a second, and never kicks anyone. Host-only verbs (`knock`,
  `release`, the Mess's) are simply not in `accepts()`, so a Guest's is a `verb` drop.
- **A pose is checked where it lands.** An Avatar's setters drop a pose that is not finite or outside
  `AvatarTuning.area` on every receiving copy (`dropped` counts them); the owner's own copy is the only
  one that writes it. A Ragdoll pose of the wrong size is dropped (J134).
- **Prediction is looks only.** Ghosts and a Guest's Mess bodies never ask and never write; the Host's answer
  replaces them.
- **Leaving.** The Host: `Parts.left(peer)` drops the leaver's Hands where they stood and ends their drags.
  The leaver (or every Guest when the Host quits): `Session.close()` makes it a Host of one; `Parts.went_alone()`
  lets each Part take over what it showed as looks only (`Mess.went_alone`: each looks-only body and frozen
  Throw copy becomes its own body where it is, so every flying Sock rests; coop/12). `GuestGhosts` drops its
  guesses.
- **The house handshake** (core/62). Until a Guest's `house_ready` is handled the Host sends it nothing of the
  level: no answer about a level Part, no level synchronizer (LevelRuntime's visibility filter asks
  `Session.sees_house()`), no avatar (the Avatars spawn a Guest's only once it is in: Godot sends a spawn whose
  synchronizer belongs to another peer to everyone); a Command for a level Part is dropped as `not_ready`
  (counted, never printed). A wrong layout at `house_ready` is refused with "Another version of the game".
  A Guest joining from inside its level (the command line, the title's Join today) names its layout in its gate
  word: a different one is refused at the gate (it never enters the Roster), a matching one counts as its
  `house_ready`, so it gets the link and level snapshots together once the Host's level is settled.
  Every avatar carries a Host-owned `Gate` synchronizer under the same filter (core/68): Godot decides whom a spawn
  goes to only by the Host's own synchronizers on it, so without it a Guest still loading would get another Guest's
  avatar.
- **A player's Hands numbers are derived, never said (core/130).** Nobody sends capacity, reach, charge or
  Throw speed any more (D13's sent numbers and `HandsTuning.*_most` went): `Hands.tuning_of(by)` grows the four an
  Upgrade changes from the levels the level's `Upgrades` Part keeps for that player (synced, so every machine's
  guesses agree with the Host), starting from the player's own HandsTuning on its machine, from
  `Hands.teammate_tuning` for a Teammate the Roster names (the level's player numbers: the zoo's 3), from
  `Hands.tuning` for a stand-in. A Guest's own forged copy changes only its own guesses; the Host refuses.
  `house_ready` still carries an empty Hands slot until `session_house.gd` drops it.
- **The wire's version.** `Session.PROTOCOL` goes up with any change to an RPC, a synchronized property, a
  spawnable scene, or the shape of a Command, event, snapshot or gate word.

## Tests
Two or three zoos in one process, each a machine of its own (`SceneTree.set_multiplayer` per branch), real
ENet on 127.0.0.1, `tests/support/lag_peer.gd` for a one-way delay; frames paced to 60 a second of wall time
where the network matters. In a test every Host listens on a port the system picks (`Session.free_port`, set
by `tests/hooks.gd`), so parallel runs never clash. The real paths run at 0 and 50 ms one way:
`coop_join:join`, `teammates:walk_crouch`, `coop_mess:pour_real_path`, `coop_hands:guest_pick_throw_real_path`
and `guest_throw_ghost_on_host_flight`, `coop_knockdown:real_path`, `coop_hand_off:hand_off` and `catch`, `coop_pings:real_path` and `same_on_both`. The guards: `coop_guard` (bad shape, flood,
forged pose and knockdown), `scene_parts:guard`, `coop_knockdown:forged`, `teammates:forged`.

## The cost
`tools/coop_cost.sh`: a Host and a Guest as two headless processes, the Host pouring 2,000 Socks at the heap.
Measured 2026-11-23 on the agents' Linux machine (headless: no drawing in the frame time):

| Window | Host sends | Guest sends | Host frame (mean / 95th / worst) | Guest frame (mean / 95th / worst) |
|---|---|---|---|---|
| The pour (2,000 Socks added to the zoo's 2,151, 15.7 s) | 72.2 KB/s | 4.6 KB/s | 23.4 / 38.3 / 38.6 ms (36 frames/s) | 27.1 / 36.2 / 68.8 ms (60 frames/s) |
| At rest after (4,151 Socks, 5 s) | 3.7 KB/s | 3.7 KB/s | 4.5 / 8.1 / 9.9 ms | 7.2 / 17.1 / 17.1 ms |

Bytes are ENet's totals with its headers; a frame is the engine's process plus physics time. The Host's pour
frames are the Mess's own physics (it simulates every falling Sock); the Guest's are its looks-only bodies.

The heavy part is the pour (each rest batch is a reliable answer); at rest only the avatars' poses move.
The designer's two windows are the reference for frame times.

## Gotchas
- A `Back` is moved in `_physics_process` (priority -10, before any player) and also told to the physics
  server at once (`body_set_state`): a node's new transform reaches the server only at the next flush, so a
  rider moving the same tick would meet the disc where it was. A player standing still on a back gets no
  slide collision (it only snaps), so `PlayerStack` keeps the back while the feet are still on it.
- Every Throw and drop leaves the thrower's own first-person hand (`Hands.start_of`, from their eyes and aim) on
  every machine, so a Guest's ghost flies the Host's flight; Teammates see it drawn from the thrower's avatar's
  hand, easing onto the body in 0.2 s (`Mess._leads`; coop/13).
- `tools/coop_probe.sh` (coop/13): a Host and a Guest as two headless processes, as the designer's two windows;
  the Guest throws and drops by input, the Host pours; prints what both showed (the Guest's drawn Throw against
  the Host's arc, anything under the floor, each Guest body's snap at its rest, every Sock's record and drawn
  instance on both).
- A Guest finds a spawned Throw copy by its name (`Flight<id>`); every other body is its own (no spawner).
- ENet's packet throttle is held at full on every peer (`EnetTransport`); left alone it drops 31 of 32
  unreliable packets at 60 frames a second.
- In one process both machines poll in one frame, so at 0 ms an answer can come back within the click's
  own frame: a case judging "before the answer" uses a delay.
- `Session.close()` runs on `_exit_tree` too; then it writes nothing (`_leaving`).
- A helper's `await` (a level's `bound` or `settled`) checks the Session is still valid and in the tree when it
  resumes: the helper may outlive its node for that one step.
