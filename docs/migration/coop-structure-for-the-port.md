# Co-op structure for the It Socks rebuild

## 1. Head

| Old mechanism | New bucket |
|---|---|
| Doors, Drawers, Cabinets, Hands, shelf, Coins, Upgrades, bins, devices, Elevator, Cat plan | Part + Command; the Host decides; answers carry who and why |
| Avatars, one per player | Spawner + synchronizer owned by the player; smoothing by hand |
| Thrown or dropped Socks and Pairs, a ragdoll | Body owned by the Host, one synchronizer per body; the Guest's own Throw is a looks-only ghost |
| Scripted-arc items (Radio, Cat, Guide card), cart-less hand-offs | The Command answer only; each machine replays the arc |
| The Mess, floor Pairs | ONE bulk system = ONE Part; own bulk snapshot and settle stream; no Godot nodes |
| Version check, roster, profile id | Gate at connect (`auth_callback`: protocol, 128-bit id, token) + a roster Part |
| Join snapshot and save | `Parts.snapshot()` / `load_snapshot()`, one format; per-player state keyed by player id |
| Guest prediction | Looks only, in a ghost that cannot write shared state |

- **Not carried over: the Guest guessing shared state.** Today a Guest's pick writes its own Hands and holds the Sock out of the Mess (`game/hands/hands_rules.gd:147`). Its Moving Socks are simulated on its own machine and corrected by snap and undo (`game/world/sock_record.gd:27`, `:305`). The rebuild has one writer, the Host. Prediction draws a ghost and changes nothing.
- **Not carried over: the hand-built transport and the "hello after connect" gate.** There are 17 hand-written RPCs and two streams for avatars and bodies (`game/net/session.gd`). Join identity is a client-chosen int with no token (`game/net/local_identity.gd:25`). Godot's replication starts at connect, before any hello (REPORT D1), so the gate must move into `auth_callback`.
- **Not carried over: routing Commands by kind, family prefix and variant marks through one table into one 1,601-line `Game`.** The kit addresses a Command to a Part (`to`). Each Part then owns its own save, leave and carry rules, which `Carriables` and `CommandTable` do centrally today (`game/hands/carriables.gd`, `game/core/command/command_table.gd`).

## 2. Mechanism by mechanism

Line counts are rough and cover rules plus transport, not views, unless noted. "Change" means player-visible change. F1 to F4 are flags; they are listed under the table.

| Mechanism | Today (file:line) | Lines | Bucket | Change | Risk |
|---|---|---|---|---|---|
| Session and RPCs | `session.gd`: 17 `@rpc`; `_command` `:358`, `_pose` `:383`, `_settled` `:377`, `_released_are` `:548`, `_welcome` `:464` | about 950 (net/ 2,583 with the lobby) | One thin Session (kit `session.gd`) for Commands up and events down. Avatars, bodies and the Mess leave it | none | Medium |
| Version check and join | `_hello` `:336` checks `PROTOCOL`=5 (`:50`), then `Join.hello` `join.gd:20`, then `Saves.snapshot` (`saves.gd:54`) | about 250 | Gate: `auth_callback` carries protocol, player id and token. Then the kit's hello + snapshot. Include a scene-contract hash, because a path mismatch is silent (REPORT A3) | none; the refusal texts stay | Medium (gate not yet tested) |
| Roster and profile ids | `roster.gd:90` (`refusal`), `:103` (`admit`); `LocalIdentity` key `local:<n>`; ids are a 31-bit int (`packet_guard.gd:88`) | about 580 | Roster Part keyed by `player_id` (128-bit) + host-held `token_hash`. Peer id is a live field only | none; a copied profile now fails | Low |
| Packet guard | `packet_guard.gd`: shape, finite, bounds, 60 poses/s. Commands get shape only (`:170`) | 176 | The kit's per-verb `accepts()` (args, rate, reach). Avatar values are validated in a setter on the Host's copy, because the engine checks the sender but never the values | none | Low |
| Command table | `core/command/` 621 lines, 82 `CommandKind` in 29 Part files, `Game.take_command` `game.core/game.gd:1433` | about 620 + 1,601 `Game` | Part + Command (`Command.to` = the Part's id) | none | Medium (the volume of re-addressing) |
| Door, Cabinet, Drawer state | `house/openable.gd`, `door_rules.gd`, `campaign/cabinets.gd`; a toggle carries the wanted value (Q283); Guests do not predict it (`architecture/net.md` 2.4) | about 1,700 | `Openable` and Cabinet Parts. The shelf is Cabinet state | none | Low |
| Hands and what a player carries | `hands_rules.gd`, `hands.gd`, `hold_anchor.gd`. A carried thing is drawn at the carrier's HoldPoint, nothing streams | about 1,950 | Per-player Hands state in the Players Part. A carried device is a Part with `holder`. A leaver drops where they stood (Q248) | **F1** | Medium |
| Throw and Flights | `flights.gd:107` (`_launch`), `:200` (`launch_predicted`), `sock_flights.gd:194`, `flight_stream.gd:33`, `flight.gd:195` | about 2,260 | Host-owned Jolt body + synchronizer, spawner for the body, ghost for the thrower (Section 4) | **F2** | High |
| The Mess | `sock_world.gd` and parts, `settle_stream.gd:17`, `world_codec.gd`, `sock_draw_group.gd` | about 4,400 (+ the 1,726-line layout bake) | One bulk system = one Part; own snapshot and settle stream (Section 5) | **F3** | High |
| Pairs on the floor and shelved | `floor_balls.gd` (121), `pair_wakes.gd` (136); `Game.floor_pairs` dict. Shelved: `Cabinets.shelf` | about 400 | Floor Pairs join the Mess system (same id space). Shelved Pairs are Cabinet state | none | Low |
| Devices: Sock vacuum, Backpack vacuum, Splitter, Hampers, pairing machine | `vacuums.gd` (700), `backpack_vacuums.gd` (407), `splitters.gd` (591), `hampers.gd` (579), `pairing.gd` (726) | about 3,200 | One Part each (state, Host timers, Host-only Commands). A machine bought during play is a spawned Part. Spat Socks and rolled Pairs are Host-owned bodies. The hose stays local (`devices-knockdown.md` line 60s) | none | Medium |
| Laundry bins | `campaign/laundry.gd` (855): `bin_pick`, `bin_sock`, `final_wash` | 855 | Part per bin: `holder`, filled, loaded | none | Low |
| Elevator ride | `house/elevator.gd`, `rides.gd`, `elevator_rules.gd`; riders are not saved; `elevator_arrive` is a Host timer | about 790 | Elevator Part + a `riders` list; riders' avatars frozen in the car by decided state | none | Low |
| Cat | `cat/cat.gd` (2,057 of 3,434): the Host plans a path, `cat_walk` carries it, every machine walks it at the same pace (`cat.gd:46`) | about 3,400 | One Part. Its walk is decided state (path + start time); no body stream | none | Medium (size) |
| Knockdown, Drag, Wash | `rig_knockdown.gd:30`, `drags.gd`, `washes.gd`, `knockdown_poses.gd`; the Host simulates the ragdoll, a Guest's bones follow (`ragdoll.gd:10`) | about 1,840 | `Down`, `Drag`, `Wash` Parts. The ragdoll is a separate Host-owned body (Section 3) | none | High |
| Lobby and returning players | `net/lobby.gd` (799), `game/lobby/` (1,617), `world_meta.gd` (Group keys), `Join` | about 2,500 | Roster Part (colours, Ready) + World settings. Later milestone (Q2161: no lobby in the first loop) | none | Low now |
| Saves and late join | `saves.gd:27` (`to_dict`) + 10 `Carriable` kinds, `WorldCodec` (259) | about 1,260 | `Parts.snapshot()` = save = join. Spawned things store `{scene, spawn_seq, state}` | none | Low |
| Upgrades and Coins | `upgrades.gd` (450, `decide_buy` `:386`), `coin_bank.gd` (93); Personal in the player's state, House in `Game.house_levels` | about 600 | Players Part (Personal, Coins) + House Part (House levels, Drawers). Events say who | none | Low |

- **F1 (Hands, prediction):** see Q1. The old Guest's Hands are guessed, then reconciled (`core/command/command_guest.gd:76`). "Looks only" means Hands change on the answer. On LAN this is invisible. At 100 ms a second pick before the first answer has to wait or stack as a ghost.
- **F2 (Throw):** the same feel only if the ghost and blend are kept (Section 4).
- **F3 (Mess):** moving Socks on a Guest look slightly different from today if the Guest no longer simulates them (Q3).
- **F4 (avatar, rate and smoothing):** a default synchronizer sends every frame and writes values with no smoothing (REPORT A4). That changes the look of a Teammate. Keep today's 20/s and the 12/s follow (see Section 3, Q4).

Notes:
- **Prediction today** covers only pick, pick_pair, cycle, drop, Throw and the pairing machine's load (`architecture/net.md` 2.4). Doors, Drawers, devices and buying already wait for the Host. They keep that, so no change.
- **Spawner uses:** avatars, Flights, and devices bought during play (`pairing_place` is Host-only). Not Socks.
- **Scripted-arc items** (`Flight.is_item`, `flights.gd:134-158`) need only the throw answer (`from`, `vel`). They get no synchronizer.
- **A carried thing never has a stream today.** It rides the carrier's HoldPoint. So "owner follows the holder" is needed for nothing in the old game except bodies released into the air. A Part with `holder` plus the avatar's synchronizer covers carrying.
- **Packet guard:** the rate limits for avatar values are lost with a synchronizer. Not tested whether a modified client can exceed `replication_interval` (Section 8).

## 3. The avatar

**Today.**
- Each machine runs its own body. No prediction is needed: it is the player's own and the Host takes it as truth, within bounds (`packet_guard.gd:76`).
- `Rig.pose()` (`game/player/rig.gd:544`) builds 12 numbers: position, yaw, pitch, crouch, the id of the player they stand on and the offset from that player, climbing, suction.
- A Guest sends it at `net.pose_rate`=20 (`data/tuning/net.json:4`), unreliable ordered on channel 1 (`session.gd:383`). The Host guards it (`packet_guard.gd:37`), then sends everyone's poses and the ragdoll bones to every Guest (`session.gd:490`).
- On a Teammate's machine `Rig._follow` (`rig.gd:561`) eases to the last pose: position, yaw and pitch at `k = min(1, 12·dt)`, crouch at 6/s. When they ride another player it uses `under.position + offset`.
- Animation is derived locally from motion, not sent: waddle speed from displacement, smoothed (`avatar.gd:763`), squash from vertical speed.
- A held item is drawn at the HoldPoint from the Hands state (`hold_anchor.gd`).
- Look and colour travel on reliable RPCs (`session.gd:503`, `:508`).
- The knockdown ragdoll is simulated by the Host. Guests' bones follow `bodies` in the same stream. `down`, `dragged_by` and `drum` ride a joiner's roster entry (`knockdown_poses.gd`).

**A synchronizer with the player as authority replaces:** `_pose` and `_poses_are` (2 of the 17 RPCs), `PoseStream` (113 lines), the pose half of the guard, and the pose part of the join entries (the spawner replays avatars to a late joiner, REPORT B1). The 12 values fit under the 64-property limit. One avatar scene, one spawner, about 15 lines on the Host (REPORT E table).

**Must be kept by hand:**
1. **Smoothing.** The engine writes values directly. Sync into plain properties and let a child node run the existing 12/s follow.
2. **Rate.** Set `replication_interval` to 0.05 to match 20/s. Guest-to-Guest packets go through the Host's relay, as they already do.
3. **The riding frame.** Sync `on` and the offset as properties. The receiver recomputes position from the carrier. Keep the crouch, climbing and suction flags too.
4. **Validation.** The engine checks the sender is the authority, never the numbers. Add finite and bounds checks in a setter on the Host's copy, and drop the packet.
5. **Animation, HoldPoint and held-item attachment.** Unchanged. They read Hands state (a Part) and the synced pose.
6. **Look and colour.** A Part or spawn properties on the Players Part. Not Godot sync.
7. **Save positions.** `note_positions` (`pose_stream.gd:107`) must read the Host's copy of each avatar.
8. **Late join.** Others' avatars arrive in about 33 ms at 0 delay and about 300 ms at 50 ms delay (REPORT D1). Put the position in the spawn values so nobody flashes at the origin. Today it is immediate (`_welcome` carries the pose).

**Knockdown ragdoll.** Keep it a separate node owned by the Host (spawned on the hit, freed on getting up). The player's own body stays at the ragdoll's feet today (`rig_knockdown.gd` header), so the avatar's synchronizer never changes authority. That avoids the clean-then-noisy hand-over of REPORT D2 (Guest to Host prints 12 to 14 harmless errors at 50 ms). Bone sync with Godot is untested and the bone count was not read (Section 8).

## 4. The Throw

**Today.**
1. On a Guest, the Throw is a predicted Command (`predict_throw`, `hands_rules.gd:359`). The Sock leaves the Hands and the sound plays at once. Its own Jolt body (layer `PREDICT`) flies from the eyes (`flights.gd:200`). The Guest picks the spin and sends it.
2. The Host's event brings the Host's body, a `stream` Flight with no body on the Guest. It is played 0.1 s behind (`flight.gd:38`) from rows `[id, pos, rot, vel, clock]` every tick (`flight_stream.gd:33`). The clock stamp keeps jitter from stalling the flight.
3. The Guest keeps drawing its own flight. The difference to the Host's body eases in over `release.predict_blend` 0.2 s and ends on the Host's rest pose (Q1596). A catch, shelve or bin ends it at once (Q1597).
4. Measured at 100 ms round trip (`multiplayer/35`): own Throw tick 0, no step back, largest jump 0.003 m, the ghost leads the Host's body by about 3 ticks.

**Option A: the Host owns the body, one synchronizer per body, the thrower flies a looks-only ghost.**
- The Throw Command goes up. The Host's answer is the event: who, what, why, sounds. The Host spawns a `Flight` body node from the decided answer and a synchronizer carries its pose.
- Carry the stamp: sync one property `row = [pos, rot, vel, clock]` whose setter calls `Flight.feed_pose`. Keep `play_stream` (0.1 s behind) and the blend. A raw synchronizer has no stamp and no smoothing, so it would bring back the 0.153 m stalls measured in `multiplayer/35`.
- One synchronizer per body, not one array property. A `PackedByteArray` of 32 rows at 46 B is 1,472 B, over the 1,350 B cap (REPORT A4). `vacuum.spit_bodies` is 24 of 32 (`SockWorld.RESERVED`).
- Feel: the same as today for the thrower and for others. Cost: keep about 600 lines of ghost and blend (`thrown_item.gd`, parts of `flights.gd`). Delete `flight_stream.gd` and `_released_are`. Ownership rule: fits. The body's authority never changes (no holder).
- Untested: Jolt bodies on synchronizers, and the order of the spawn packet and the answer (both reliable, different paths).

**Option B: the thrower owns the body until it rests, then it goes to the Host.**
- Feel: perfect for the thrower, and no blend. Others see it after Guest to Host to Guests, one extra hop. The Host cannot decide a catch or knockdown from a body it does not run. It must trust a client-reported flight and rest pose, against the docs' "do not let clients decide positions" (ids-roster-guards, section 3).
- Ownership following decided state: the grant arrives one trip late, and a Guest's early writes are lost under delay (REPORT D2). Handing back to the Host prints errors. A Pair resting at a client-chosen pose then joins the Mess.
- Cost: a Host proxy that wakes the Mess, plus a rest-pose check. Not recommended.

**Option C: keep the custom stream.**
- Same feel and same ghost as A. Cost: `FlightStream` (48 lines), `_released_are` and the join handling stay, plus the "hello after connect" hole stays (a Guest of another build still gets the stream). It is the least change and the most tested path. It does not use the engine's spawn and despawn. The bodies are not created from a spawner, so a late joiner needs the old event replay.

**Which the evidence favours:** A, with the stamp kept (an `A-with-stamp`, one synchronizer per body). Reasons: the findings back synchronizers for things in motion; the 100 ms numbers tie the feel to the stamped playback and the 0.2 s blend, which A keeps; B moves a decision onto the client. C is the safe fallback if the Jolt spike fails (Section 6).

**The 2026-11-19 bug** (a predicted body woke resting Socks only on the Guest; fixed with collision exceptions in `SockFlights._impact_wakes`, `sock_flights.gd:267`). What makes the class impossible is one rule, not the transport:
- The Mess has one writer, the Host. A Guest's Mess is read-only: no `wake`, `put` or `rest` call exists on a Guest.
- The ghost lives on its own layer and has no handle to the Mess. It collides with the static house only.
- With that, A and C make it impossible. B does not: a thrower-owned body runs on the Guest's own Mess copy and wakes Socks there. Today's fix is a guard written by hand in a rule; it protects only this one path.

## 5. The Mess

**Confirmed from the code.**
- **Late join:** one reliable RPC `_welcome` (`session.gd:464`) with the gzip of `var_to_bytes(WorldCodec.pack(to_dict))` (`saves.gd:54`). The Mess is `game.world.to_array()` (`saves.gd:40`) as `WorldCodec` records: 25 bytes each, plus 12 if it moves (`world_codec.gd` header). About 30 KB raw for 1,200 Socks. The old ticket measured about 40 KB for 1,000 Socks (the whole snapshot, `multiplayer/04`). I did not re-measure.
- **Running:** there is NO moving-Sock stream. The ADR-0008 stream (priority, interest by room, about 1,100 B a tick) was never built; the designer closed it (`physics/15`, Q1034: "replaced by the event design"). What travels:
  - Host events about single Socks (a pick, drop, spill, vacuum, spit, shelve), reliable, ids assigned by the Host.
  - `_settled`: reliable WorldCodec rows of every Sock that came to rest on the Host (`sock_bodies.gd:687` -> `settle_stream.gd:17`). One batch per tick that any Sock rested.
  - The Host's released bodies in the air, 1 row per body per tick, unreliable (the Flight stream).
- **How a Guest copes:** each machine runs the Moving Socks itself from the same events, for looks. When the Host's rest rows arrive the Socks snap to them (`sock_record.gd:305`). A Sock the Guest moved and the Host did not goes back (`take_before`, `keep_before`, `sock_world.gd:204`). Doors that sweep Socks are tracked on every machine (`track_door`).
- **Drawing:** per room and look, one MultiMesh of Resting Socks; per look, one for Moving ones (`sock_draw_group.gd:1`). Purely local; nothing of it travels.

**New structure.** One `Mess` system holding plain records (state, pose, design, holder) in packed arrays. It appears as one Part: one id, `snapshot()` = the WorldCodec rows (chunked, since it is bulk), `load_snapshot()`. It emits `rested(ids)` and the Host streams the settle rows. A Command that touches a Sock names its id (`pick`, `shelve`). Floor Pairs are in the same id space and the same snapshot. The room MultiMeshes are the Part's Looks.

**Godot's nodes do not apply, for three reasons from the findings.**
1. A node or synchronizer per Sock is excluded by the rule. Even as arrays, a synchronizer holds at most 64 watched properties and one state of at most 1,350 B (REPORT A4). That is about 36 records. 1,200 Socks would need about 33 synchronizers or far too many packets.
2. "Always" resends unchanged data every frame (1,364 B/s idle for a trivial case). "On change" keeps a deep copy and compares it each frame. For a 30 KB array that is a poor fit.
3. No stamps, no smoothing, no snapshot semantics; the bulk snapshot for a late joiner already exists (`Saves.snapshot`).

## 6. Order of work

**M0.5, Host of one (single-player core, written co-op-ready).**
1. Kit: `Parts`, `Command`, `Part`; a Players Part keyed by `player_id` (1 for the Host).
2. Mess: records, bodies, MultiMesh drawing, `snapshot()` / `load_snapshot()`, `rested(ids)`; one-writer API (no Guest paths, no `keep_before`).
3. Hands Part: pick, drop, cycle, Hand-off, refusals; HoldPoint drawing.
4. Pairing: two matching Socks in Hands make a Pair; floor Pairs in the Mess system.
5. Throw: Host-owned Jolt body, `Flight` node with the stamp property, catch/shelve/land answers; ghost interfaces designed but not used yet.
6. One Cabinet + Drawer + Openable Parts (shelve, thrown_shelve, Coins).
7. The avatar as a scene with the 12 pose properties and the 12/s follow, even with no network.
8. Each Part declares `accepts()` (args, rate, reach) from the start, as if a Guest sends.
9. Save and load through `Parts.snapshot()`; per-player state keyed by `player_id`.

**M0.6, the co-op zoo base.**
1. Plain host and join (no lobby) with the gate: `auth_callback` + protocol + `player_id` + token + scene-contract hash.
2. Roster Part: max 4, colour, name, refusals (full, already in); a leaver drops what they hold where they stood.
3. Avatar spawner + player-owned synchronizer; Host validation; late-joiner test.
4. Join snapshot: Parts + the Mess bulk snapshot; late Guest test.
5. Settle stream for the Mess; `Guest Mess` is read-only.
6. Flight bodies: spawner + synchronizer per body; Guest `stream` playback 0.1 s behind.
7. Guest ghosts: pick, drop, Throw, with the 0.2 s blend and the "refused: it flies back" look.
8. Openable and Drawer from a Guest and a late Guest; a refused Command.
9. Tests at 0 ms and 50 ms one-way (the findings' harness): a Throw measured as in `tests/net_throw_test.gd`.
10. Guard tests: bad shape, bad rate, a forged avatar write.

Later (M5, each first a zoo station): devices, Elevator, Cat, knockdown and Drag and Wash, Laundry, Upgrades menu, lobby.

## 7. Questions for the designer

1. **Header: Guest picks**
   - Question: When a Guest picks up a Sock, should their Hands change only after the Host answers?
   - Options:
     - (recommended) Looks only: the Sock flies to their Hands at once; the Hands and the count change when the Host answers. On LAN you will not notice. At 100 ms a second pick waits for the first answer.
     - Guess the Hands, as today: a Guest can chain picks at once, and refused ones are undone. This keeps the old feel but lets a Guest's own machine hold a state the Host never agreed to.
2. **Header: Guest Throw**
   - Question: How should a Guest's own Throw behave?
   - Options:
     - (recommended) Host owns the body, the thrower sees an instant ghost: same feel as today; the ghost blends over 0.2 s to the Host's flight.
     - Thrower owns the body until it rests: perfect for the thrower, others see it a hop later, and a Guest decides where a Pair rests.
     - No ghost: the Sock leaves the Hands after a round trip. It feels laggy, as before the 2026-11-11 fix.
3. **Header: Moving Socks**
   - Question: Should a Guest still simulate Moving Socks themself and snap to the Host's rest?
   - Options:
     - (recommended) Keep today's event design (Q1034): Guests run Moving Socks for looks; a Sock may rest a few cm elsewhere, then snap.
     - The Host streams every Moving Sock to Guests: Guests see exactly the Host's Socks about 100 ms late, no snap; costs bandwidth (not designed).
     - Guests wait for the Host's rest rows: Socks hit by a Throw appear to move only when they rest, which looks wrong.
4. **Header: Avatar rate**
   - Question: Should a Teammate's avatar move exactly as today, or use Godot's default smoothness?
   - Options:
     - (recommended) Keep today's: 20 updates a second, eased at 12 per second. It looks identical.
     - Godot per-frame sync (60/s): a little smoother, three times the avatar traffic.
5. **Header: Join token**
   - Question: Build the secret that stops a copied profile joining as another player in M0.6?
   - Options:
     - (recommended) Yes, with the roster: ids are 128-bit now, and changing them later breaks saves. A copied profile is refused.
     - Later, with the lobby: M0.6 uses the id alone, so anyone with the number can play as that player.
     - Never (friends only): the simplest; a copied profile can take a Teammate's Upgrades (Q1187 wanted this blocked).
6. **Header: Teammate hit**
   - Question: Does M0.6 include a Throw hitting a Teammate?
   - Options:
     - (recommended) Catch and plain bounce only; knockdown, Drag and Wash come at M5 (the ragdoll is about 1,840 lines and needs a bone-sync spike).
     - Full knockdown in M0.6: more of the real co-op feel early; it adds a Host-owned ragdoll body to the base.
     - No Teammate hit in M0.6: simplest; Throws only hit things.
7. **Header: Mate Throw look**
   - Question: Keep the Teammate's Throw start exactly as today?
   - Options:
     - (recommended) Keep: model blends from their hand over `avatar.teammate_throw_blend`; the 50 ms pause at release stays (an old open question).
     - Stretch the blend over the 0.1 s lag so the model never stops.

## 8. Unsure / not read

- **Mess join with Moving Socks:** I did not check whether the join snapshot writes velocities for Socks mid-spill (`sync_moving()` `sock_record.gd:337`, `MOVES` flag), or writes them at rest at their current pose.
- **The 40 KB snapshot figure** is from `multiplayer/04`. The digest also says "later 3.4 to 20 kB". Neither was measured today.
- **Gate, spawner and synchronizer claims** come from the findings, which read the `auth_callback` gate in source and did not test it. Jolt bodies on synchronizers, a ragdoll's bone sync and the bone count, and visibility filters were not tested.
- **Spawn packet versus answer order** for a `Flight` (both reliable, possibly different ordering) is untested. The ghost should match by the `flight` id when either arrives.
- **Rate on a synchronizer:** I did not check whether a modified Guest can send faster than `replication_interval`. Godot counts nothing (REPORT A5).
- **Tests:** I read the 100 ms numbers from `docs/llm/multiplayer/issues/35-guest-throw-feel.md`, not from a rerun. I did not run any suite.
- **Not read in full:** `cat.gd` (read headers and `Command.new` sites only), `washes.gd`, `drags.gd`, `lobby.gd` and `session_menu.gd` beyond the architecture notes. Device internals were read from file headers.
- **Catch and knockdown:** I did not check which pose the Host uses for hit tests (the smoothed `_pose` or the raw one).
- **Pings and the emoji wheel:** a Command (`house_rules.gd:39`); I did not map them beyond that.
- **Heap bake:** "the heap bake never runs while a Guest is connected" (digest) is not in the new design's scope; not re-checked.
