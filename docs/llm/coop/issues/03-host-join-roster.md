---
type: ticket
status: done
kind: build
area: core
feature: coop
priority: now
created: 2026-11-22
done: 2026-11-22
blocked_by: []
notes: ["M0.6 batch 1 (Q2436); ready for Steam (Q2456-Q2458)"]
terms: [Host, Guest, Session, Teammate, Player colour]
---

# Host, join and roster, behind a transport seam ready for Steam

A second player can join the zoo, be told why when they cannot, show up beside the Host with their own
colour, and leave cleanly. The code assumes no IP address and no ENet type, so Steam's peer, lobby and
ids replace ENet at M4 without rework.

## Behaviour list
`docs/migration/m06-lists/01-host-join-roster.md` (approved, Q2460), with these answers applied over it:
names "Player" (Q2440), next free colour (Q2441), toasts as old with "Joined <Host>'s zoo" (Q2442),
4 players and "The game is full (4 players)" (Q2443), the old refusal texts with "Host" capitalised
(Q2444), a scene-layout check refused as "Another version of the game" (Q2445), a leaver's things drop
where they stood (Q2446), "Could not reach <ip>" after 10 s (Q2447), a new joiner 0.6 m beside the Host,
a returning id where they left (Q2448), no token until M4 (Q2449). Lines marked "(lobby, M4?)" or
"(outside the zoo?)" for things the zoo lacks (bake, Lobby, Group, Wardrobe, drum, Radio, saves) are not
built; the ESC "End session" menu is not built (no ESC menu yet, Q2300).

## Design
- **Transport seam** (`docs/research/steam-multiplayer.md` "The seam"): a small `NetTransport` (one class
  per file, inheritance one step) that makes the peer: `host(port)` and `join(where: String)`, where `where`
  is opaque ("ip:port" for ENet; a lobby or Steam id later). `EnetTransport` is the only one now; it holds
  ENet's packet throttle at full on every peer (`throttle_configure(5000, 32, 0)`, coop/01's condition 1).
  `Session` keeps a plain `MultiplayerPeer`; nothing outside the transport names ENet or an IP.
- **Identity:** a player profile in `user://profile.json` with the long random player id (128 bit as 32 hex
  characters, Q2224) and the name "Player" (Q2440); `--profile=<tag>` picks `profile_<tag>.json` so two
  copies on one PC are two players (dev). The id is one String field: Steam's id goes in it at M4 (Q2458).
  The peer id is a live field only, never saved, never a key.
- **Gate** (in `Session._gate`, `auth_callback`): the Guest's gate message carries the protocol, the scene
  layout hash and the player id. The scene layout hash is a hash of the sorted Part paths the scene
  declares (the contract both machines must share). The Host refuses with a reason code mapped to the old
  texts: "Another version of the game" (protocol or layout), "The game is full (4 players)",
  "You are already in this game". `auth_timeout` stays above a Steam ticket round trip (a named number).
- **Roster Part** (decided state, written only by the Host's answers; `coop-structure-for-the-port.md`
  section 2 "Roster"): entries keyed by player id: peer, name, colour index into the 8 old colours (coral,
  teal, mustard, lilac, mint, sky blue, rose, charcoal, as typed Resource data), last position. Host is
  entry 1 with the first colour; each joiner takes the next free. It is in the join snapshot. The Avatars
  spawner keeps spawning by it.
- **Join and leave:** a joiner spawns 0.6 m beside the Host facing the same way; a returning player id at
  its last position (kept for the Session). A leaver's Hands drop at their last position for everyone in one
  Host answer, the drop sound once. The 2 s toasts under the crosshair in the player's colour ("Player
  joined", "Player left", and on the joiner "Joined Player's zoo") go through the HUD's message line; a later
  one replaces an earlier one.
- **Client timeout:** a join with no answer ends after 10 s with "Could not reach <where>" and the player
  stays a Host of one.

## Acceptance
- Real path: start the zoo with `--host`, start a second copy with `--join=127.0.0.1` and another
  `--profile=`; the Guest sees "Joined Player's zoo" and stands 0.6 m beside the Host; the Host sees
  "Player joined" in the Guest's colour (the second colour). A case drives this through the zoo's own
  wiring (`ZooNet`, the HUD), not a test button.
- Cases for each refusal: wrong protocol, wrong scene layout, a fifth player, the same player id twice;
  each shows its text on the Guest and admits nothing.
- A Guest leaving while holding Socks: they drop at the leaver's last position on the Host and on a third
  player, the drop sound plays once; the leaver's avatar goes; "Player left" shows.
- The same profile leaving and joining again stands where it left and keeps its colour if free.
- Joining an address with nobody there ends after 10 s with "Could not reach <where>" (the 10 s is a
  named number; the test may shorten it).
- Late joiner case: a third player joining sees both others at their positions with their colours.
- `grep` finds no `ENetMultiplayerPeer` and no IP parsing outside the transport.
- Numbers: the 8 colours, 0.6 m, 10 s, 2 s, the max of 4 are typed Resource values (decided); the auth
  timeout is a placeholder until the Steam lobby (M4).

## Answers
- Q2440-Q2449, Q2456-Q2460 (2026-11-22), as in the Behaviour list above.

## Open follow-ups
- [later] The Hands (and every other per-player Part state) are still keyed by the live peer id, as
  before; only the Roster is keyed by the player id. Keying the Players state by player id is the
  "per-player state" item of the co-op order, not this ticket.
- [later] A leaver's drop is heard as the flat "drop" on every machine; coop/05 (teammates' sounds in
  3D) may place it at their feet. `HandsTuning.leave_height` (1.0 m) is a placeholder for the play session.
- [later] The avatar is not tinted by the Roster colour yet (coop/04 adds the tint; `Roster.colour_of(peer)`
  gives it).

## Built log
- 2026-11-22 lead: model opus (netcode, CLAUDE.md "Models").
- 2026-11-22 agent (coop/03-host-join-roster):
  Changed: a transport seam (`NetTransport`, `EnetTransport`: the only file naming ENet or reading an
  address; holds ENet's throttle at full on every peer, both ends); `PlayerProfile` (32-hex player id,
  "Player", `user://profile[_<tag>].json`); the gate's word carries protocol, scene layout hash, player id
  and name, refused as "Another version of the game", "The game is full (4 players)", "You are already in
  this game" (PROTOCOL 10); the `Roster` Part (keyed by player id: peer, name, colour, place; next free
  colour; new joiner 0.6 m beside the Host facing its way, alternating sides; a returning id where it left,
  its colour if free); `Avatars` spawns by the Roster with the place in the spawn data; `Hands.left` drops
  a leaver's items where they stood in one answer (falling as a drop, spread round the feet as the old
  Landings.around) and `Hearing` plays "drop" once per machine; toasts "Player joined"/"Player left" (name
  in colour) and "Joined Player's zoo" via `Hud.say_named`/`Player.announce`; a join with no welcome
  gives up after 10 s with "Could not reach <where>"; `--profile=` through `ZooNet` and `GameCli`;
  `CoopTuning` (.tres) holds the 8 colours, 0.6 m, 4, 10 s, 2 s and the auth timeout (placeholder, 8 s).
  Files: game/net/{net_transport,enet_transport,player_profile,roster,coop_tuning}.gd, coop_tuning.tres,
  game/parts/session.gd, game/parts/avatar/avatars.gd, game/zoo/zoo_net.gd, game/zoo/zoo.tscn,
  game/ui/hud.gd, game/player/player.gd, game/hands/hands.gd, game/hands/hands_tuning.gd,
  game/audio/hearing.gd, game/debug/game_cli.gd, tests/coop_join_test.gd (new), tests/zoo_test.gd,
  tests/scene_parts_test.gd, tests/coop_flight_test.gd, tests/game_cli_test.gd, tools/grep_rules_allow.txt,
  docs/architecture.md.
  Verified: PASS 15589 checks, 402 cases (`run.sh --touched` ran every suite); coop_join 173 checks, 6 cases.
- Merged: 00aada56 (2026-11-22, branch coop/03-host-join-roster)
