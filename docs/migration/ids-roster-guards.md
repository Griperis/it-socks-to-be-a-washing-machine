# Research: stable ids, roster identity, guarding client input

Recommendations (confidence):
1. IDS: bake an exported `part_id` (short random string, written once by an editor tool, checked by a lint) for placed things. Use host-assigned ints for spawned things. Do not build on Godot's node `unique_id`: it exists in 4.6+ `.tscn` files but is NOT readable from GDScript in 4.7.1 (verified in source and by a run). Keep a rename map as the migration path. (high on "unique_id not usable"; medium on the exact id design)
2. ROSTER: key players by a profile-made random id (128-bit) plus a host-issued secret token, never by the Godot peer id. The peer id is chosen by the client in ENet and is random per session. On Steam builds the SteamID can replace the token. (high on peer id facts; medium on the token design, it is a pattern, not an engine feature)
3. GUARD: each part declares per verb a shape, a reach/state check and a rate; drop-and-count on failure, never disconnect in friends-only co-op. Godot's own docs say: validate RPC args, rate limit, host is truth. (high)

Single most uncertain point: whether Godot will expose node `unique_id` to scripts (open proposal godot-proposals#13745, not merged as of 4.7.1). It would remove the need for our baked id.

Method: web fetch and the GitHub API/raw files, Godot tag 4.7.1-stable. Items marked "unconfirmed" were not verified against a primary source.
Local run: I ran Godot 4.7.1 headless (script in a scratch dir) to check `unique_id` behaviour. Marked "RUN".

---

## 1. Stable ids for placed and spawned things

| System | What it uses | How the id is made | What breaks it | Source |
|---|---|---|---|---|
| Godot RPC / path cache | Node path relative to `SceneMultiplayer.root_path`, plus a small int cache id chosen by the sender | Sender assigns `last_send_cache_id++`, sends a `SIMPLIFY_PATH` packet (rpc checksum, cache id, relative path). Receiver resolves the path, stores `recv_nodes[id]`, replies `CONFIRM_PATH`. If the node is gone the receiver falls back to a path lookup | Different path or name on two peers (an RPC then fails). Docs: sender and receiver "need to have the same NodePath"; use `add_child(node, true)` | github.com/godotengine/godot `modules/multiplayer/scene_cache_interface.cpp`: `make_object_cache`, `send_object_cache`, `_send_confirm_path`, `process_simplify_path`, `process_confirm_path`, `get_cached_object`. Docs: docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html (RPC section) |
| Godot `MultiplayerSpawner` (spawned nodes) | Host-assigned `net_id` (uint32) per spawned node, sent in the spawn packet with scene index and node name | `SceneReplicationInterface::_make_spawn_packet`: `tnode->net_id = ++last_net_id`. Scene is sent as an index into the spawner's list (`find_spawnable_scene_index_from_object`), not a path | Not stable across sessions (counter restarts, `last_net_id = 0` on clear). Node name must be a valid node name (`on_spawn_receive` checks `validate_node_name`) | `modules/multiplayer/scene_replication_interface.cpp`: `_make_spawn_packet`, `on_spawn_receive`; `multiplayer_spawner.cpp`: `instantiate_scene` |
| Godot `MultiplayerSynchronizer` | Placed (not spawned): path cache id with high bit set (`0x80000000`). Spawned: its own `net_id` from the spawn packet | `_verify_synchronizer` and `_find_synchronizer` | Placed synchronizers inherit the path-id weakness | `scene_replication_interface.cpp`: `_verify_synchronizer`, `_find_synchronizer` |
| Godot saving doc | Group "Persist" plus `scene_file_path` plus `get_parent().get_path()` | Tutorial code stores each node's scene file path, parent path, and properties | Doc states: nodes must be instanced scenes; "no Persist objects are children of other Persist objects. Otherwise, invalid paths would be created"; nested ones "the NodePath will likely be invalid". Groups are one choice, "other methods are certainly possible" | docs.godotengine.org/en/stable/tutorials/io/saving_games.html (read via fetch tool, paraphrase-checked) |
| Godot scene unique name `%Name` | A name, unique within one scene owner | Flag `unique_name_in_owner`; `get_node("%Name")` | Only scoped to the owner scene; not an id; two instances of one scene have the same `%Name` | docs.godotengine.org/en/stable/tutorials/scripting/scene_unique_nodes.html; `Node` class docs (`unique_name_in_owner`) |
| Godot node `unique_id` (a.k.a. unique scene id) | int32 stored in `.tscn` node headers: `[node name="A" type="Node" parent="." unique_id=1380342942]` | Made on save: `PackedScene` calls `ResourceUID::create_id()` masked to positive 31 bits when a node has none or the id clashes in the file | See detail below | PR github.com/godotengine/godot/pull/106837 (merged 2025-10-06, milestone 4.6). Code: `scene/resources/packed_scene.cpp` (`SceneState::pack`, `instantiate`, `_find_node_by_id`), `scene/main/node.h` `unique_scene_id`, `resource_format_text.cpp` |
| Godot `ResourceUID` / `.uid` | `uid://...` for resources (scripts, scenes, textures) | `ResourceUID.create_id()` random, unique among loaded UIDs | Files only. Not nodes. Does not give per-placed-thing identity | `doc/classes/ResourceUID.xml` (4.7.1): "keep references between resources intact, even if files are renamed or moved" |
| Godot `get_instance_id()` | Runtime object id | Engine counter | Not stable | `doc/classes/Object.xml`: "only useful during the current session. It won't correspond to a similar object if the ID is sent over a network, or loaded from a file at a later time" |
| Unreal replication | `FNetworkGUID`. Stably named objects (placed in a level, loaded from assets) are referred to by path name; dynamic actors get a server-assigned GUID | Server assigns on first replication | Renaming a placed actor changes its stable name | UNCONFIRMED. From memory; dev.epicgames.com and the engine repo (404 without login) were blocked |
| Unreal saves | `FSoftObjectPath` for references to placed things; `FGuid` actor guid in World Partition (`ActorGuid`); `SaveGame` UPROPERTY flag; redirectors / CoreRedirects for renames | Guid made once in the editor and saved with the actor | Rename is handled by redirectors; deleting breaks | UNCONFIRMED. From memory. Same blocked hosts |
| Unity NGO placed objects | `NetworkObject.GlobalObjectIdHash` (uint) | Editor `OnValidate`: `GlobalObjectId.GetGlobalObjectIdSlow(this)` then `globalId.ToString().Hash32()`. Skipped in play mode, and when the identifier type is 0 | Doc comment in source: in-scene ids "are only unique to the scene asset itself (and not per scene instance loaded)". Needs re-save when it changes | github.com/Unity-Technologies/com.unity.netcode.gameobjects branch `develop-2.0.0` `Runtime/Core/NetworkObject.cs`: `OnValidate`, `k_GlobalIdTemplate`, `UpdateForSceneChanges` remarks |
| Unity NGO spawned objects | `NetworkObjectId` (ulong) | `NetworkSpawnManager.GetNetworkObjectId()`: `++counter + LocalClientId * 10000` | Not stable across sessions | `Runtime/Spawning/NetworkSpawnManager.cs` |
| Unity NGO late join | Scene sync sends in-scene placed objects keyed by `GlobalObjectIdHash` and scene handle, plus a list of despawned in-scene objects | `SceneEventData` | n/a | `Runtime/SceneManagement/SceneEventData.cs` (lines about despawned in-scene placed objects) |
| Mirror | `NetworkIdentity.sceneId` (ulong): low 32 bits random, high 32 bits = hash of lower-cased scene path (`GetStableHashCode`) | Edit time only (`Application.isPlaying` check); duplicates detected via a `sceneIds` dictionary; scene must be re-saved or the build throws | Moving a scene file changes the hash part; duplicating a scene is handled by the path-hash part. Source comment: scene objects "have no persistent unique ID in Unity" | github.com/MirrorNetworking/Mirror `Assets/Mirror/Core/NetworkIdentity.cs`: `sceneId`, `AssignSceneID`, `SetSceneIdSceneHashPartInternal` (long design comment above them) |
| Fish-Net | `NetworkObject.SceneId` (ulong) for placed; `ObjectId` (int) for runtime | Editor `CreateSceneId`, skipped in play mode; build throws "missing a SceneId" with a reserialize menu; `SetSceneId` public | Missing id at build time | github.com/FirstGearGames/FishNet `Assets/FishNet/Runtime/Object/NetworkObject/NetworkObject.Serialized.cs`: `SceneId`, `CreateSceneId`; `NetworkObject.cs`: `ObjectId` |
| Source engine / Bethesda / Factorio / Minecraft | Entity index plus serial; form/ref ids; `unit_number`; UUID | n/a | n/a | UNCONFIRMED. developer.valvesoftware.com, lua-api.factorio.com, minecraft.wiki, en.uesp.net were blocked. Not used below |

### Detail: Godot node `unique_id` (matters most)

What is confirmed:
- **Introduced:** PR #106837 "Add unique Node IDs to support base and instantiated scene refactorings" by reduz, merged 2025-10-06, milestone 4.6. (GitHub API: `repos/godotengine/godot/pulls/106837`.) 4.6-stable and 4.7.1-stable tags exist, so 4.7.1 has it.
- **Purpose, from the PR text:** keep scene inheritance and instancing working when a base scene renames, moves or re-adds nodes. The ids are "USED AS A FALLBACK" to names when instantiating a scene. It "should not break any current existing scene". It supersedes #86960 and closes many old inheritance bugs. Not meant as a game-facing id.
- **Not readable from GDScript in 4.7.1.** `Node::get_unique_scene_id`/`set_unique_scene_id` exist in C++ (`scene/main/node.h`), but there is no `ClassDB::bind_method` for them in `scene/main/node.cpp` at tag 4.7.1-stable. `SceneState::get_node_unique_id` exists in C++ and is not bound either (`packed_scene.cpp` binds get_node_count/type/name/path/groups/... only). RUN: `has_method("get_unique_scene_id")` returned false. Not in the `Node` class docs either. A reviewer in the PR said "It's good that this is not exposed to the public API".
- **Exposure is a proposal only:** godot-proposals#13745 "Expose unique Node IDs to scripting" (open; asks for a getter, and a setter for tool scripts). #11044 "Expose Unique Network ID to GDScript" (open, older). Maintainer (Ivorforce) in the PR asked for proposals rather than comments.
- **Readable from the `.tscn` text.** The field is `unique_id=<int>` in each `[node ...]` header (parsed in `resource_format_text.cpp`). A tool or an `@tool` script can read it by parsing the file.
- **Scope:** an id is unique within one scene file, not globally. RUN: a scene `s1.tscn` instanced twice into `s4.tscn` gave the first instance root the inner root's id (823624896) and the second a new id (1924266563). The code says clashes "will always happen with instantiated scenes" and are re-assigned on save (`SceneState::pack`). A global identity would need the chain of ids from the owner (the engine builds such an `id_path` in `pack`).
- **Rename / reparent:** RUN: renaming `A` to `Renamed` and reparenting `B` under it, then saving again from the same live nodes, kept both ids. Loading `s1`, renaming a node in memory and saving again kept ids too.
- **Duplicate:** RUN: `Node.duplicate()` gave the copies new ids on save (`@Node@2` got 374212257, its child 1683662140). Source agrees: nothing copies `unique_scene_id` on duplicate.
- **Runtime nodes:** `Node.new()` has id 0 (unassigned); per the proposal text and `UNIQUE_SCENE_ID_UNASSIGNED = 0`. Only nodes saved in a scene get one.
- **Instancing:** `instantiate()` sets each node's id from the file (`node->set_unique_scene_id(ids[i])`).
- **Inherited scenes:** this is what the feature is built for. The PR thread says older inherited scenes saved before the PR keep separate ids until re-saved, and one edge case (rename with a name collision) was still buggy when the PR merged. Behaviour in 4.7.1 for all inheritance cases: unconfirmed beyond the PR thread.
- **Edge cases not tested:** editor Ctrl+D, "Make Local", copy-paste between scenes, scene merge in version control. Unconfirmed.

### Community patterns (secondary evidence only)
- An exported id filled by an `@tool` script or an EditorPlugin, or a UUID addon. Examples in search results: github.com/JBSnippets/godot4-unique-id, asset library "Unique ID Node". Not read in depth. The proposal thread (#13745) comments describe people doing this with metadata or node paths today.

### Options for this framework

| Option | Cost | What it breaks / risks |
|---|---|---|
| A. Exported `part_id` baked by an editor tool (string or int), checked by a lint | One small editor tool plus a lint; ids are visible in the `.tscn` diff; same pattern as Mirror `sceneId`, Fish-Net `SceneId`, NGO `GlobalObjectIdHash` (all edit-time, random, scene must be re-saved) | Copy-paste or Ctrl+D of a part copies the exported value, so the lint must catch duplicates (Mirror tracks duplicates in a dictionary; Fish-Net regenerates on clash). Two instances of one scene share the id, so the key must be scope id + part id (see below) |
| B. Godot's node `unique_id` | Zero authoring | Not readable from scripts in 4.7.1; only by parsing `.tscn`. Not meant as an id (a "fallback"). Scoped per scene file, with re-assignment on clash. Could change on any re-save in rare clash cases. Only worth it if proposal #13745 lands. |
| C. Node path plus a rename map (old path -> new path) in save migration | Small; no new field | Every rename needs a map entry by hand or a tool; Godot's own saving doc warns about nested paths; path-only ids also tie networking to names (docs: same NodePath on all peers) |
| D. Host-assigned ints for spawned things | Free; this is what the engine does (`net_id`, NGO `NetworkObjectId`) | Not stable across sessions: a save must store the spawnable scene plus its own saved id or index, and ids are re-issued on load |

---

## 2. A roster: lasting identity versus the connection id

| System | What it uses | How the id is made | What breaks it | Source |
|---|---|---|---|---|
| Godot peer id | `multiplayer.get_unique_id()`: server is 1, clients get "a random positive integer" | `MultiplayerPeer::generate_unique_id()` hashes tick and time; ENet client sends it as connection data (`create_client`: `unique_id = generate_unique_id()`) | New number every session. The server only rejects `< 2` or a duplicate of a connected peer: `if (event.data < 2 || peers.has(event.data)) event.peer->reset()` (comment: "probably trying to exploit us"). So the client picks its own id; it is not an identity | docs `high_level_multiplayer.html` ("clients are assigned a random positive integer"); `scene/main/multiplayer_peer.cpp` `generate_unique_id`; `modules/enet/enet_multiplayer_peer.cpp` `create_client`, `_poll` (server branch) |
| Godot auth hook | `SceneMultiplayer.auth_callback` (Callable), `send_auth(id, data)`, `complete_auth(id)`, `auth_timeout`, signals `peer_authenticating`, `peer_authentication_failed` | Empty callback = peers accepted at connect. With a callback, `peer_connected` fires only after both sides call `complete_auth` | Auth data is opaque bytes; Godot checks nothing about it. Your game decides what proves identity | class docs `SceneMultiplayer` (`doc/classes` and docs.godotengine.org/en/stable/classes/class_scenemultiplayer.html); `scene_multiplayer.cpp` `pending_peers`, `send_auth`, `complete_auth`; `high_level_multiplayer.rst` text "As soon as both the client's and the server's complete_auth() methods have been called ... peer_connected ... fire" |
| Steam | `CSteamID`: "The globally unique identifier for all Steam accounts, Steam groups, Lobbies and Chat rooms." Lobbies are "uniquely identified by Steam ID"; one lobby owner arbitrates rules | Steam | Needs Steam. Page does not say "persistent" or "64-bit" in the text I got; the page also does not cover owner migration (said so in the fetch) | partner.steamgames.com/doc/api/steam_api ; partner.steamgames.com/doc/features/multiplayer/matchmaking. GodotSteam MultiplayerPeer mapping of Steam id to Godot peer id: unconfirmed (repo moved to Codeberg; not read) |
| Unreal | `FUniqueNetId` in `APlayerState`; inactive PlayerStates kept for reconnect; seamless travel carries PlayerStates | Online subsystem | n/a | UNCONFIRMED. Blocked hosts: dev.epicgames.com, docs.unrealengine.com, forums.unrealengine.com; engine source 404 |
| Unity NGO | `ClientId` (ulong, transport-level) is the connection id. `ConnectionApprovalRequest` carries `Payload` (bytes the client sends) and `ClientNetworkId` | Approval callback is where a game checks its own identity or token | Client id is per connection | `Runtime/Core/NetworkManager.cs` `ConnectionApprovalRequest`. Docs on session and reconnect (Authentication service, Multiplayer Services): blocked, unconfirmed |
| Mirror | `connectionId` per connection; `NetworkAuthenticator` base class runs in the connect phase, with events when a client is authenticated | Your authenticator | n/a | `Assets/Mirror/Core/NetworkAuthenticator.cs` (summary: "component-based authentication during the Connect phase"). Mirror docs host blocked |
| Offline / LAN without accounts | A locally generated id in the profile file | Not found in a primary source | Two players can claim one id, copy a profile, or play on two machines | UNCONFIRMED as engine practice. It is a design pattern |

How co-op games return a player's things: they key stored per-player state by a stable id (account id, or a profile id) and map it to the current connection at join. Godot gives only the join hook (`auth_callback`) and the opaque data channel; the rest is ours. I found no Godot doc on reconnects.

What stops two players claiming one id (design reasoning, not a quoted source):
- The host is the only judge. If an id is already in the roster (connected), refuse the second one. Godot does the same at the peer level.
- A profile id alone is a claim, not a proof. Add a host-issued secret token: first join, the host makes a random token and sends it; the guest stores it in its profile and sends it at later joins (over `send_auth`); the host stores token hash next to the id in the save. Someone who copies only the public id fails.
- Friends-only: the token also guards against accidents (a copied profile), not attackers.

---

## 3. Guarding what a client sends to the host

| System | What it does | On failure | Source |
|---|---|---|---|
| Godot `@rpc` | Modes: `authority` (default, only the authority may call), `any_peer`, `disabled` internally. Options `call_local` / `call_remote`, transfer mode, channel (last). `multiplayer.get_remote_sender_id()` gives the sender | Receiver logs "RPC ... is not allowed on node ... from: N. Mode is ..." and drops it (`ERR_FAIL_COND_MSG(!can_call...)`) | docs `high_level_multiplayer.rst` (RPC section); `scene_rpc_interface.cpp` `process_rpc` (the `switch (config.rpc_mode)`) |
| Godot docs: secure design | Section "Secure multiplayer design": treat client input as untrusted; do not let clients decide positions, combat, inventory; "Validate RPC arguments before applying them"; "Avoid trusting client-reported positions, timers, cooldowns, or resource values without checks"; "Add safety checks and rate limits to actions that can be triggered frequently"; the server stays "the source of truth" | n/a | docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html (verified in the rst source, godot-docs master `tutorials/networking/high_level_multiplayer.rst`, lines ~729-760). Also a top warning: networking "may lead to cheats or exploits" |
| Godot object decoding | `SceneMultiplayer.allow_object_decoding`, default false. Doc: "Warning: Deserialized objects can contain code which gets executed." "Do not use this option if the serialized object comes from untrusted sources." RPC docs: "RPCs will not serialize Objects or Callables." | With it off, objects in RPC args are not decoded | class docs SceneMultiplayer; `scene_rpc_interface.cpp`: `decode_and_decompress_variants(..., multiplayer->is_object_decoding_allowed())`. Custom spawn args are decoded with objects not allowed (`decode_and_decompress_variant(v, ..., nullptr, false)` in `on_spawn_receive`) |
| Godot spawner | Spawn packets are accepted only from the spawner's authority: `ERR_FAIL_COND_V(p_from != spawner->get_multiplayer_authority(), ERR_UNAUTHORIZED)`. Scene index must be in the spawnable list (`ERR_FAIL_UNSIGNED_INDEX_V` in `instantiate_scene`). `spawn_limit` caps count ("Spawn limit reached!"). Name must pass `validate_node_name`; no duplicate name under parent | Packet dropped with an error | `scene_replication_interface.cpp` `on_spawn_receive`; `multiplayer_spawner.cpp` `instantiate_scene` |
| Godot synchronizer | Sync flows from the authority to the others; visibility via `set_visibility_for`, `add_visibility_filter`, `public_visibility`. A node spawned by a spawner is also spawned/despawned by its synchronizer's visibility | n/a | `MultiplayerSynchronizer` class docs (4.7.1 `modules/multiplayer/doc_classes/MultiplayerSynchronizer.xml`). Whether the receiver checks the sender is that property's authority: not read; unconfirmed |
| Unreal | `UFUNCTION(Server, Reliable, WithValidation)` with `_Validate`; a failed validation disconnects the sender; owning-connection rule for server RPCs | Disconnect | UNCONFIRMED (docs blocked; from memory) |
| Unity NGO | `[Rpc(SendTo.Server, InvokePermission = Everyone/Owner/Server)]` (enum `RpcInvokePermission`). Old `[ServerRpc(RequireOwnership=...)]` deprecated; the code generator defaults a ServerRpc to Owner, `[Rpc]` to Everyone | At the call site the generated code logs "Only the owner can invoke a ServerRpc that requires ownership!". Receiver-side behaviour: unconfirmed | `Runtime/Messaging/RpcAttributes.cs`; `Editor/CodeGen/NetworkBehaviourILPP.cs` (default permission near line 1499, log string near line 2350) |
| Mirror | `[Command]` requires authority by default (`requiresAuthority`); a command from a non-owner is dropped with a warning ("received for ... without authority"); commands from a non-ready client are ignored | Warn and return, no disconnect | `Assets/Mirror/Core/NetworkServer.cs` `OnCommandMessage` (`requiresAuthority`, `identity.connectionToClient != conn`) |

General practice for friends-only listen-server co-op (my synthesis; Godot's doc above is the only primary support for the first four):
- Do: shape and type check (a dictionary with known keys, finite numbers, bounded lengths), a per-peer rate limit, and a semantic check by the target (in reach, holds the thing, the state allows the verb). The sender id comes from `get_remote_sender_id()`, never from the payload.
- Usually not done: signed packets, anti-cheat, lag compensation, interest management, disconnect-on-bad-packet. Drop, count, and log once per second per peer.
- Keep `allow_object_decoding` false.

### Join snapshot and late join
- **Godot:** when a peer connects, `SceneReplicationInterface::on_peer_change(id, true)` runs `_update_spawn_visibility` for every spawned node and the sync setup for every synchronizer. So the spawner re-sends spawn packets to a late joiner, and a spawn packet can carry initial state (properties marked for spawn in the replication config; `_make_spawn_packet` encodes "spawn state"). Placed nodes are expected to exist in both scenes. Source: `scene_replication_interface.cpp` `on_peer_change`, `_make_spawn_packet`.
- **Unreal:** initial replication of each relevant actor's state when a client's connection first sees it. UNCONFIRMED (docs blocked).
- **NGO:** `SceneEventData` serializes the current scene's spawned objects, and lists in-scene placed objects that were despawned, so the new client matches the host (`Runtime/SceneManagement/SceneEventData.cs`). Details of ordering: not read.
- None of these three ties the snapshot to the save format; that equality is this framework's own choice.

---

## What this means for scene parts

Fields and checks, each tied to evidence above.

1. **Two ids on every part, baked, not path-derived.**
   - `@export var part_id: String` (read-only in the inspector), a random 8-12 char base32 string, written by an editor tool (`EditorPlugin` on scene save, or a menu "Fix part ids") the first time a part has none.
   - The key on the wire and in saves is `scope + "/" + part_id`, where `scope` is the owning scene's own baked id (a level or a placed prop scene root). Reason: Godot's `unique_id` is scoped per scene file and an instanced scene repeats it (RUN: two instances shared an id until re-assigned); NGO's own source says in-scene ids are "only unique to the scene asset itself".
   - Evidence: Mirror `sceneId`, Fish-Net `SceneId`, NGO `GlobalObjectIdHash` all do "random at edit time, never at runtime, re-save needed".
2. **The lint** (runs in the headless test suite and on scene save):
   - every `Part` under a scene has a non-empty `part_id`;
   - no two parts in one scope share one (Mirror keeps a duplicate dictionary; Fish-Net regenerates on clash). Ctrl+D copies the exported value, so this is the main catch;
   - each scope root has an id; two placed instances of one prop scene differ in the level's scope, not in the prop's parts;
   - the id never changes between commits unless a rename-map entry exists (diff against the last committed `.tscn`).
3. **Do not use `unique_id` as the key.** If proposal #13745 ships a getter, `part_id` could be filled from it by the same tool; keep the string so saves survive. Worth reading `unique_id=` from the `.tscn` text only as a hint to detect "this node was duplicated" (id differs, `part_id` same).
4. **Rename map as migration, not as the design.** Old saves (path keyed) load through a one-time table `old_path -> part_id`, generated by the tool from the current tree. After that, saves store `part_id`. (Evidence: Godot's saving doc says path-based ids break for nested nodes and renames; Unreal solves the same with redirectors.)
5. **Spawned things:** host-assigned int `net_id` for the wire (what `MultiplayerSpawner` and NGO do). In saves store `{scene_key, spawn_seq, state}` where `spawn_seq` is a saved counter, so loading re-issues ids in order. Do not store the live int.
6. **Roster stores:** `player_id` (128-bit random from the profile, as in the kit's `roster.gd`), `token_hash` (host side, from first join), `name`, `colour`, and the per-player state keyed by `player_id` (what the returning player gets back). The current peer id is a field of the live connection only, never saved. At join: `auth_callback` receives `{protocol, player_id, token, name...}`, the host verifies, refuses a second live entry with the same `player_id` (Godot's own server also resets a duplicate peer id), then calls `complete_auth`. On Steam builds, `player_id` is derived from the SteamID and the token is skipped. (Evidence: `SceneMultiplayer` auth API; ENet accepts any client-chosen id >= 2.)
7. **What a part declares for the guard** (small table on the part, read by the guard, no RPC code in the part):
   - per verb: `shape` (key -> type, like the kit's `PacketGuard` shapes), `reach` (max distance or "any"), `needs` (holder / free / unlocked: a state check by name), `rate` (calls per second per peer, default low);
   - the Session checks shape and rate first, then asks the part: `can(verb, by, args)` returns a grant or a refusal with a reason (the kit's Command flow already does this);
   - sender comes from `get_remote_sender_id()`, mapped to `player_id` by the roster;
   - failure: drop, increment a counter, one log line per peer per second; no kick.
   - Evidence: Godot docs "Secure multiplayer design" (validate arguments, rate limits, host is truth); Mirror `requiresAuthority` and NGO `InvokePermission` are the same idea as a per-verb ownership flag. Add `owner_only: bool` per verb to cover it.
8. **Session RPC surface:** one `@rpc("any_peer", "reliable")` entry for Commands to the Host, everything else `authority`. Keep `allow_object_decoding` false (default); send plain values only (Godot docs say RPCs do not serialize Objects or Callables).
9. **Join snapshot equals save:** keep as designed. Godot's spawner replays spawns on peer connect, NGO sends scene objects and a despawned-in-scene list. Our part snapshot keyed by `scope/part_id` needs a "removed placed things" list the same way NGO sends despawned in-scene objects (a placed part that was destroyed must not reappear for a late joiner or after a load).

---

## Unconfirmed and blocked

Blocked by network policy ("Approval required for <host>:443"):
- dev.epicgames.com
- docs.unrealengine.com
- forums.unrealengine.com
- docs-multiplayer.unity3d.com
- docs.unity3d.com
- mirror-networking.gitbook.io
- fish-networking.gitbook.io
- developer.valvesoftware.com
- lua-api.factorio.com
- minecraft.wiki
- en.uesp.net
- steamworks.github.io

Other:
- github.com/EpicGames/UnrealEngine returned 404 (private repo). All Unreal rows are from memory, unverified: `FNetworkGUID`, stable names, `FSoftObjectPath`, `ActorGuid`, redirectors, `WithValidation`/`_Validate` disconnect, `FUniqueNetId`, inactive PlayerStates, initial replication.
- godotengine.org/releases/4.6 returned 403 (not tested with curl); I used the PR milestone and tags instead.
- godotsteam.com/tutorials/lobbies returned 403 via the fetch tool (home pages worked by curl). GodotSteam MultiplayerPeer moved to Codeberg; Steam-id to peer-id mapping unconfirmed.
- Godot node `unique_id`: behaviour with Ctrl+D, paste between scenes, "Make Local", inherited scenes older than 4.6, and version-control merges is untested. Whether 4.8 will expose it: unknown.
- Whether `MultiplayerSynchronizer` receive checks the sender is the synchronizer's authority: not read.
- NGO receiver-side enforcement of `InvokePermission`, and NGO reconnect guidance: not read.
- The roster token design and the "what is not done in friends-only co-op" list are synthesis, not quoted from a primary source.
- The Steam docs fetch tool summaries (CSteamID quote, lobby quotes) came through a small summarising model; wording unverified against the raw page. The Godot `saving_games` summary was likewise summarised; the high_level_multiplayer and SceneMultiplayer facts were checked against raw rst/XML/C++.
