# Godot 4.7.1 high-level multiplayer nodes vs scene parts

1. **Late joiner, placed nodes:** a Guest that joins late does get the current values of a placed node's "always" and "on change" properties (about 50 ms on localhost) with no app code. Spawn-only properties on a placed node never arrive. There is no initial-state packet: a new peer has no delta history, so its first delta carries every watched property. (tested `a12`, read in source)
2. **Path mismatch:** a renamed, moved or missing node gives one error on the Guest and nothing on the Host. That node stays out of sync forever without a word, while every other node and RPC keeps working. A node at the right path but without the property is fully silent. (tested `a3`)
3. **Authority:** only the authority sends. Every receiver checks that the sender is the authority (sync, delta, spawn, despawn), drops the packet and prints one error per packet. A Guest can own its avatar while the Host owns everything else. Guest-to-Guest traffic goes through the Host's relay. (tested `a5`, read in source)
4. **Spawner:** a late joiner gets every existing spawn replayed, with the current spawn values, set before `_ready`. Names match on all machines. If a Guest already has a node with that name, the spawn is refused with one error and the machines silently disagree. Things added before `host()` (a loaded save) still replicate. Only nodes made from a scene file are auto-spawned. (tested `b`)
5. **No request/answer:** the nodes have no idea of a request. A Guest asks with an `any_peer` RPC and the Host writes the synchronized property. A refusal shows nothing unless you send your own answer. (tested `c`, read in source)
6. **Hybrid works:** player-owned avatars (spawner + synchronizer) and the kit's Parts/Session share one `SceneMultiplayer` with no errors and no dropped Commands. A late Guest gets the parts snapshot and every avatar in place. Tested at 0 ms and at 50 ms one-way delay. (tested `d`, `e`)
7. **Authority hand-over:** passing a carried thing from the Host to a Guest is clean. Passing it back prints about 12 to 14 harmless "Ignoring sync data from non-authority" errors at 50 ms delay. Under delay, a Guest's write before its grant arrives is lost. Set authority from the Part's state in `_show()`, which runs for answers and for snapshots. (tested `e`)
8. **Saving:** nothing in these nodes saves anything. A save must store each spawned thing's scene path, name and state, then add it back. (read in source; adding back tested in `b` B4)
9. **Cost of one bool change:** "on change" sends 18 B of payload, about 28 B on ENet, reliable. "Always" sends about 21 B per frame to each Guest even when nothing changes. One kit Session event costs about 300 to 400 B per Guest. (tested `a4`, `d`; source)
10. **Recommendation:** keep Parts, Commands, the snapshot and saves for discrete state. Use `MultiplayerSynchronizer` and `MultiplayerSpawner` for avatars and for things in motion. Gate the engine's replication with `SceneMultiplayer.auth_callback`, because replication starts at connect, before the Session's hello. (the gate is read in source, not tested)

Scope: Godot 4.7.1-stable source (`modules/multiplayer/*`, copies in `src/`). All runs were headless, in one process, over real ENet on localhost, at 60 fps. The official "High-level multiplayer" page (godot-docs master `high_level_multiplayer.rst`) does not mention the synchronizer or the spawner at all. The firewall blocked the godotengine.org scene replication blog post ("Approval required for godotengine.org:443").

## A. MultiplayerSynchronizer on placed nodes

Setup (`exp/a12_placed_modes.gd`): every machine has `Level/Thing` with a `Sync` child and three properties: `a_always` (always), `b_watch` (on change) and `c_spawn` (spawn only). The Host's copy starts at 10/20/30 and each Guest's at -1, so any value arriving from the Host shows.

**A1. A Guest connected from the start (tested)**

| Mode | Host's starting value (never changed) | A Host change |
|---|---|---|
| Always | arrives 33 ms after connect | arrives in 17 ms (1 frame) |
| On change | arrives 33 ms after connect | arrives in 17 ms |
| Spawn only | never | never |

- The first values take about 2 frames because a placed synchronizer is named by a path-cache id. The Host waits for the Guest to confirm the path first (`_verify_synchronizer`, `send_object_cache`).
- Spawn properties only travel inside a spawn packet (`_make_spawn_packet`), and a placed node is never spawned.
- If a Guest writes its own copy (it is not the authority):
  - an "always" value is overwritten on the next tick;
  - an "on change" value stays different until the Host changes it again;
  - the Host never hears of it.

**A2. A late joiner (the key question)**

The Host changed the values, waited 0.5 s, then the late Guest connected, and the Host changed nothing more.

| Mode | Current value on the late Guest |
|---|---|
| Always | arrived after 50 ms |
| On change | arrived after 50 ms |
| Spawn only | never arrived in 2 s |

A further "on change" change reached both the late and the early Guest within a frame. All of this is tested.

How it works (read in source, and the test agrees):
- There is no separate first-state transfer. `on_peer_change` only adds the synchronizer to the new peer's send list.
- "Always" sends every value each tick, so the next tick brings the new peer up to date.
- "On change": `_send_delta` reads a per-peer "last sent" time, which is 0 for a new peer. Every watched value got a nonzero change time the first time it was read (`_watch_changes`). So the first delta to a new peer carries every watched property, changed or not.

**A3. Path mismatch (`exp/a3_mismatch.gd`, tested)**

| Guest's scene | Result |
|---|---|
| Node renamed, moved or missing | One error on the Guest: `Node not found: "Level/Thing/Sync"` (`process_simplify_path`). Nothing on the Host. The values never arrive and no later error appears. |
| Node at the right path, but its script lacks the properties | No error at all. `set_state` uses `set_indexed` without checking the result. |

- In every case the other node kept syncing, an RPC to another node still arrived, and nothing crashed.
- The Host stays quiet because the Guest never confirms the path, so the Host skips that node forever.
- The path that must match is the synchronizer node's own path (`Level/Thing/Sync`). Renaming only the `Sync` child should break it too; that comes from the source and was not run separately.

**A4. Types and cost (`exp/a4_types_cost.gd`)**

- **Arrive equal (tested):** bool, int, 64-bit int, float, String, StringName, Vector2, Vector3, Transform3D, Color, Array, typed `Array[int]`, Dictionary, PackedByteArray, PackedVector3Array, NodePath.
- **Do not arrive:** a Resource and a Node arrive as `null`, and a Callable arrives empty. No error is printed for any of them. The class doc says Object properties are not supported.
- **In-place changes are noticed (tested):** `Array.append`, a new Dictionary key, and setting `vector.x`. "On change" keeps a deep copy and compares it.
- **Packet layout (read in source):**
  - "On change" delta, reliable: a 17 B header plus the values. One bool is 1 B, so one change is 18 B. At most 64 watched properties per synchronizer.
  - "Always", unreliable: an 11 B header plus all values. One bool is 12 B.
  - Size caps: a sync packet holds at most 1350 B, and a single state bigger than that is not sent. A delta holds at most 65535 B.
- **Measured** on the Host with ENet's sent-bytes counter (ENet headers included, UDP/IP not), one Guest, 60 fps:

| Case | Host sent |
|---|---|
| On change, nothing changes, 1 s | 44 B (pings only) |
| On change, bool flipped every frame for 120 frames | 3400 B, about 28 B per change |
| Always, interval 0, nothing changes, 1 s | 1364 B / 64 packets |
| Always, interval 0.1 s, nothing changes, 1 s | 242 B / 13 packets |

- **Settings:** `replication_interval` and `delta_interval` both default to 0, which means every network frame (class docs). There is no smoothing: received values are written directly.

**A5. Authority (`exp/a5_authority.gd`, tested)**

- **A Guest can own its avatar.** Every machine sets the avatar's authority to Guest A; the call also covers the `Sync` child. A's moves reached the Host and Guest B in 34 ms. B's copy came through the Host's relay (`send_command`).
- **The Host writing a Guest-owned node:** the position is overwritten by A's next tick. An "on change" field stays at the Host's local value. Nothing is sent.
- **A Guest writing a Host-owned node:** the write stays local and is never sent, because a peer only sends synchronizers it owns. The engine does not reject anything; there is simply nothing to reject.
- **A modified Guest B** made itself authority of a Host-owned node on its own side only and wrote 666:
  - the Host and A kept their value;
  - each receiver printed one `Ignoring delta for non-authority` line per packet;
  - from then on B ignored the Host's real updates, because it thinks it owns the node.
- Every receive path checks that the sender is the authority (`on_sync_receive`, `on_delta_receive`, `on_spawn_receive`, `on_despawn_receive`). The Host's relay forwards Guest-to-Guest packets without looking; the receiving Guest does the check.
- Nothing counts or rate-limits these errors: each forged packet prints one line on each receiver.

**A6. Visibility (docs and source, not tested)**

`public_visibility`, `set_visibility_for` and visibility filters decide which peers a synchronizer sends to, and for a spawned node whether it exists on that peer at all. They are for interest management, such as hiding far-away or secret things. They also limit RPCs: an RPC on a node with synchronizers only goes to peers that can see it (`is_rpc_visible`).

## B. MultiplayerSpawner (`exp/b_spawner.gd`, tested)

- **B1, connected Guest:** got all 3 balls with the same names and values, already set when `_ready` ran. After the spawn, a changed spawn-only value did not follow, while the "on change" position did.
- **B1, late Guest:** got every existing ball replayed, with the current spawn values set before `_ready` (tint 10 at 5,5,5, not the original ones). Spawn packets read the values when they are sent.
- **B2, despawn:** `queue_free()` on the Host removed the ball on both Guests.
- **B2, a Guest freeing its own copy:** the Host is not told, and each later Host change prints `Ignoring delta` on that Guest.
- **B2, custom spawn:** `spawn(data)` with a `spawn_function` runs the function on every peer with the same data. A late joiner gets the data as first given (read in source). The spawn values are applied after the function runs, so the late Guest still saw the current values at `_ready`.
- **B3, identity:** a spawned node is named by a Host-assigned `net_id` plus its node name. Names matched, including the engine's `Green2` for a second node added with a taken name. The `net_id` counter restarts every session.
- **B3, name clash:** the Guest already had a local child `Green`. The spawn was refused with `parent->has_node(name)`, the Guest kept its own node, and every later Host change printed `Ignoring delta`. The machines silently disagree.
- **B4, saving:** neither node writes anything to disk. A save needs, per spawned thing, its scene path (or custom-spawn data), its name and its state. On load, the Host adds each one with `add_child(n, true)` under the spawn path.
  - Tested: a ball added before `host()` reached a Guest after hosting.
  - A node made with `.new()` has no scene file and is never auto-spawned; use `spawn(data)` for those.

## C. Requests and refusals (`exp/c_request.gd`, `scenes/door.gd`)

- No request concept exists (read in source):
  - synchronizers only send from the authority;
  - `spawn()` fails unless called on the authority;
  - spawn packets from anyone else are refused.
  - The only way up from a Guest is an RPC (or raw bytes).
- **The smallest pattern, tested:** `@rpc("any_peer", "call_remote", "reliable") func request_open(want)` on the door. Only the Host acts: it checks `locked` and `want == open`, then sets `open`, which an "on change" synchronizer owned by the Host carries back to everyone.
- **Between asking and the change:** the Guest's door stays shut until the delta arrives; there is no "pending" state. On localhost that took 1 frame. At 50 ms each way, the kit's own Command took 116 ms, and an RPC plus synchronizer is the same one round trip.
- **On a refusal:** nothing at all for 1 s. An explicit answer RPC arrived in 1 frame.
- **Forged answer:** a Guest calling the Host's authority-only answer is refused by the engine (`Mode is "authority"`).
- **Direct write:** a Guest writing `door.open` itself: never sent.

## D. Hybrid with the kit (`exp/d_hybrid.gd`; `exp/e_latency.gd` repeats it with 50 ms delay)

The kit is copied unchanged into `kit/`. Each machine has the kit test's level plus a Crate, Parts, Session, a Players node and an avatar spawner. Each avatar is named by its peer id, and that player is its authority (set in `_enter_tree`). Its `Sync` carries position and yaw. The Host adds an avatar for itself and for each peer that connects.

**D1. Avatars beside Parts (tested)**

Avatars moved both ways, and A's door Command and box pick landed, with no engine errors and 0 bad packets.

| Late Guest gets | 0 ms delay | 50 ms delay |
|---|---|---|
| Parts snapshot equal to the Host's | yes | yes |
| Host's avatar in place | at once | at once |
| A's avatar in place (A did not move) | 33 ms | 283 to 316 ms |
| Its own avatar on all machines | yes | yes |
| Its own moves seen by A | yes | yes |

- A's avatar is slower because its place comes from A, not the Host. A first hears of the new peer through the Host's relay, then confirms the path, then sends its first delta: about 3 relayed round trips.
- **Gap (read in source, not tested):** the engine starts replicating at connect, before the Session's hello and version check, so a Guest on another build still gets spawns and syncs. `auth_callback` would hold back the connection until both sides finish their own check.
- **Cost:** one kit Session event (a 192 B Dictionary) cost about 300 to 400 B per Guest. That number is noisy because the crate's "always" sync ran at the same time.

**D2. Thing in motion: the holder is a Part, the motion is a synchronizer (tested)**

The crate has a kit `Carriable` part and a `Motion` synchronizer on its position. An experiment-only subclass sets the crate's authority to its holder (or the Host) in `_show()`. That runs both for answers and for snapshots, so late joiners get it right too. Each machine switches when it applies the Host's answer; no extra RPC is needed.

| Step | 0 ms | 50 ms each way |
|---|---|---|
| A moves it before its pick is granted | kept: sent once A becomes authority | lost: the Host's ticks overwrite it during the round trip |
| Pick (Host to A) | clean | clean |
| A carries it for 30 frames | Host and late Guest follow | they follow |
| A drops it while still moving it | all at the drop point, authority back to the Host, no errors | same result, plus 12 to 14 `Ignoring sync data from non-authority` lines (A's in-flight packets) |
| A leaves while holding it | the Host's leave rule drops it, authority returns to the Host, A's avatar despawns | same, no errors |

- **Order:** the Host always switches first, because each machine switches when it applies the Host's answer. Host to Guest is safe. Guest to Host leaves a window of one one-way delay where the Guest's packets are ignored, with one log line each.
- **Races:** two Guests racing for the crate are settled by the Host's `decide()`. The engine adds no race of its own, since authority only follows decided state. A Guest's motion before its grant must be treated as looks only.
- Changing a synchronizer's authority resets it and redoes the path handshake (source).
- A Guest who leaves while carrying puts the crate back where it last lay (8,1,8 carried, back to 7,0,7). That is the kit's `Carriable.left()` rule; whether a leave should keep the carried position instead is a designer question.

## E. What to drop or adopt

| Job | Scene parts today | High-level nodes | Evidence | Recommendation |
|---|---|---|---|---|
| Identify placed things | Node path from the level | Path of the synchronizer node, with the same weakness; a mismatch is a silent desync | A3 | **Keep ours**, plus the baked `part_id` from the earlier research |
| Identify spawned things | None | Host `net_id` plus a matching name; a clash is refused silently | B1, B3 | **Godot's** on the wire; our own key for saves. Cost: a spawner per kind of thing, and binding Parts again when something spawns (not tested) |
| Send a discrete change | Command, `decide()`, one event to all (who, what, why); 300 to 400 B | The owner writes a property; 18 B delta; no who/why | D1, A4 | **Keep ours**: sounds, HUD and refusals need the event |
| Refuse a change | `refuse(reason)` | None | C | **Keep ours** |
| Bring a late joiner up to date | Hello, then the full snapshot (same as the save) | Replays spawns; placed values arrive by themselves; starts before any app check | A2, B1, D1 | **Mix**: our snapshot for Parts, Godot's for avatars and motion; gate both with `auth_callback` (small Session change, not tested) |
| Save and load | `snapshot()` / `load_snapshot()` | Nothing | B4 | **Keep ours**; adding spawned things back before `host()` works |
| Move avatars | None | Spawner plus a synchronizer owned by the player | A5, D1, E1 | **Godot's**: one avatar scene, one spawner, about 15 lines on the Host; smoothing is still ours |
| Move physics bodies | None | A synchronizer whose authority follows the holder | D2, E2 | **Mix**; Jolt bodies not tested |
| Create things during play | None | Spawner, automatic or `spawn(data)` | B | **Godot's**, with a `spawn_limit` and our own save key |
| Guard against bad packets | Shape, verb, args and rate checks, counted, no kicks | Authority checks, RPC modes, name checks, spawn limit, no object decoding; one log line per bad packet, not counted | A5, C | **Keep ours** for Commands; Godot's already covers replication |
| Test rules without a network | A Host of one, plain calls | Needs the scene tree, a peer and frames | all | **Keep ours** |

Plainly: Godot's nodes are better for continuous state owned by one machine and for creating things during play. They need much less code and cover late joiners by themselves. They are worse for discrete, decided, savable state: no refusal, no event, no save, and a silent desync on a path mismatch. Moving door-like state onto synchronizers depends on one thing: whether the game needs to know who changed it and why. If it does, keep Commands.

## How to rerun

```bash
cd docs/research/nativize/fresh/hl-multiplayer
./run_all.sh              # all experiments; writes run.log and prints the CHECK lines
./run_all.sh e_latency    # one experiment, by part of its name
/c/Users/Gripe/personal/repositories/it-socks/extras/Godot_v4.7.1-stable_linux.x86_64 --headless --path . --script res://exp/a12_placed_modes.gd
```

- `lib/lab.gd` builds the machines (a branch with its own `SceneMultiplayer`, as in the kit test), waits for frames, prints CHECK lines, and counts engine errors with `OS.add_logger`.
- `lib/lag_peer.gd` wraps a peer and delays received packets.
- `scenes/` holds the probe, door, avatar and ball; `kit/` is the unchanged kit copy; `src/` holds the engine source I read.

## Dead ends and unconfirmed

- **Blocked:** godotengine.org (the blog post); I did not work around it. The docs page has no section on these nodes, so everything comes from the source and the runs.
- **Delay model:** the wrapper only delays packets, keeping their order: no loss, no jitter, no reordering. "Always" packets are unreliable, so the "arrives at the next tick" results are unconfirmed under loss.
- **Timings:** localhost numbers are one-process numbers (1 to 3 frames); only the 50 ms rows say anything about real delay.
- **Bytes:** counts include ENet headers, acks and pings. The payload sizes come from the source. The Session event cost is noisy.
- **Not tested:**
  - visibility filters;
  - the `auth_callback` gate;
  - Parts inside spawned scenes;
  - nested spawns;
  - `spawn_limit`;
  - state over the 1350 B limit;
  - more than 64 watched properties;
  - renaming only the `Sync` child;
  - Jolt rigid bodies;
  - many synchronizers in one packet.
- **Harness note:** removing a branch's multiplayer before freeing its nodes prints `on_replication_stop` errors. The harness now frees the nodes first; a game that swaps its multiplayer object at runtime would hit the same errors.
- **Test fix:** in C, the forged-RPC check first called the Host's own door by mistake. It was fixed to call from the Guest, and the result above is from the fixed version.

The kit copy (`kit/`) and the engine source copies (`src/`) the experiments used are not kept here: copy the scene-part templates of starter kit 7 into `kit/` to rerun.
