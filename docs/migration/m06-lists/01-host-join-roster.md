> Draft behaviour list for M0.6 (Q2436), written from the reference on 2026-11-22; for the designer to approve. Answered 2026-11-22: questions 1-10 by Q2440-Q2449 (and Q2443 for 6).

# M0.6 piece: Host, join and roster

Draft behaviour list. Refs are in the old game (`reference/it-socks/`, tag v0.1.1) unless they start with `port:` or a doc name.
Short forms: S = `game/net/session.gd`, R = `game/net/roster.gd`, J = `game/net/join.gd`, PG = `game/net/packet_guard.gd`, M = `game/core/main.gd`.
"(lobby, M4?)" and "(outside the zoo?)" mean the designer decides whether the line is dropped.

## Behaviour list

### Hosting
- When the Host starts a Session, then it listens for Guests on UDP port 24680 over ENet, by address. (ref: S:65, S:215; data/tuning/net.json:3; address_backend.gd:240-246)
- When the Host listens, then it accepts up to `max_players * 2` ENet connections (8), though only 4 players fit. (ref: S:215)
- When the Host listens, then a port of 0 lets the system choose, and the real port is read back (tests use this). (ref: S:220-221)
- When the Host cannot listen, then it logs "session: cannot listen on port N (error)" and the Session does not open. (ref: S:216-218)
- When the Host listens, then its own roster entry exists from that moment (id 1, its name, its colour mod 8, its look). (ref: S:212, R:76-79)
- When the Host listens, then ENet's packet throttle is configured to (5000 ms, acceleration 2, 0) for each peer that connects, so a frame hitch never makes ENet drop the unreliable poses. (ref: address_backend.gd:232-233, :272-276; S:392-393)
- When the Host opens, then "hosting on port N" is printed; when a Guest enters, "N joined (player id, colour, snapshot bytes)" is printed. (ref: S:228, J:54)
- When the Host listens only after the world is ready (the old game listened only after the heap bake settled), then no Guest can join a half-built world. (ref: S:207-209; net_join_test.gd case_bake_first) (outside the zoo? the zoo has no bake)
- When the Host is in the Lobby or between Lobby and World, then a joining Guest is told so, or refused with "The game is starting: join again in a moment". (ref: S:55, S:350-352) (lobby, M4?)
- When the Host runs two copies of the game on one PC, then the second copy takes `profile_2.json` (ProfileLock) so it is a different player. (ref: game/player/profile_lock.gd; digest-core-and-coop.md:117) (outside the zoo?)
- When a test or the command line starts a Session, then `--profile=<tag>` picks another profile file so two Guests run on one PC (dev only). (ref: game/player/profile.gd:10-12; digest-core-and-coop.md:198)
- When the Host quits or ends the Session, then the Host's own ESC "End session" first asks "Everyone will be sent back to the menu." with End / Cancel; Cancel returns to the menu. (ref: game/net/session_menu.gd:3-4, :19-21) (outside the zoo? the zoo has no ESC menu)

### Joining
- When a Guest joins, then it types an address as "ip", "ip:port" (default port 24680); an empty text means this machine (127.0.0.1). (ref: address_backend.gd:279-286; S:65)
- When the Guest's address has more than one colon, then it is taken as no port. (ref: address_backend.gd:284; port: session.gd split_address handles bare and bracketed IPv6)
- When the Guest starts connecting, then the title says "Connecting to <ip>..." and there is no Cancel and no time limit. (ref: game/ui/title_screen.gd:559; digest-core-and-coop.md:141) (lobby, M4?)
- When ENet cannot even start the client, then the Guest sees "Could not connect (<error>)". (ref: title_screen.gd:555-557)
- When the Guest cannot reach the Host, then the Session ends with "Could not reach <ip>". (ref: S:559-560)
- When the Guest connects, then it asks the Host "who is here" (`_ask`) before entering. (ref: S:553-556, S:325-331)
- When the Host answers the ask, then it sends the colours taken, whether the game is full, who has each colour, the run's Cabinets and whether the Host is in the Lobby. (ref: R:83-85; S:441-442)
- When the answer says the game is full, then the Guest is refused at once on the Join page with "The game is full (4 players)". (ref: title_screen.gd:566-568; R:92)
- When the Guest's saved colour is taken, then it silently takes the next free one before entering. (ref: title_screen.gd:569; R:44-49)
- When the Guest enters the game, then it sends one hello: protocol, id, name, colour, look, owned pieces. (ref: S:454-459)
- When a hello arrives from a peer already in the game, then it is dropped and counted ("this peer is already in the game"). (ref: S:338-340)
- When a hello's protocol is missing, not an int or not 5, then the Host drops it, counts it, and refuses with "The host is playing another version of It Socks" before reading anything else. (ref: S:341-344, S:50-52)
- When a hello's shape is wrong (id not an int, id <= 1 or > 0x7fffffff, name not a String, colour not an int, look not a Dictionary, owned not an Array of at most 500 Strings), then it is dropped, counted, and refused with "The host could not read your join". (ref: PG:88-103, S:345-349)
- When the Host is not ready for the hello (no game yet), then it refuses with "The game is starting: join again in a moment". (ref: S:350-352)
- When the hello is fine, then the Host builds the player's key "local:<id>" from the id the hello says; ENet trusts the hello, there is no secret. (ref: local_identity.gd:25-27; docs/migration/coop-structure-for-the-port.md section 1)
- When the game is full (4 entries) at hello, then the Guest is refused "The game is full (4 players)". (ref: R:90-92)
- When the id is 1 or lower, or already in the roster, or its key matches a roster entry (a copy of the Host's own profile), then the Guest is refused "That player is already in this game". (ref: R:8, R:93-97)
- When the Guest is outside the World's Group, then it is refused "This World belongs to its Group: you are not in it" (placeholder). (ref: J:24-26; digest-core-and-coop.md:154) (lobby, M4?)
- When the World's id for the key differs from the hello's id, then it is refused "The host could not read your join". (ref: J:29-30) (lobby, M4?)
- When a Guest is refused, then the Host prints "refused <key> (<why>)" and sends the text; the Guest's Session ends with that text and it shows once on the title. (ref: J:31-34, S:468-470, title_screen.gd:578-580)
- When the Host admits the Guest, then the roster entry holds id, key, name (cleaned), colour (next free if taken), look (only known slots). (ref: R:103-109)
- When a name is cleaned, then it is trimmed, cut at 16 letters, and an empty one becomes "Player". (ref: game/player/profile.gd:16, :146-149)
- When a colour is wanted, then it is the wanted index if free, else the next free one after it, wrapping round the 8. (ref: R:44-49; tests/net_join_test.gd:251-256: three wanting 2 get 2, 3, 4)
- When a Guest has played before (the Host's Game has the id), then it keeps its saved Coins, Upgrades and spot; a new player gets the join Coins. (ref: J:41-45) (outside the zoo?)
- When a Guest enters, then the Host gives it a body in every machine's world at its spawn. (ref: J:43, M:888-902)
- When the Guest's id is new, then it spawns at the washer spawn, "slightly apart" (0.6 m steps, alternating sides: slot k = (slot+1)/2, sign by parity); a returning player stands where they left. (ref: M:878-883, M:891; data/tuning/players.json:5; Q285, Q265)
- When a Group member joins a World in play, then it lands beside a teammate (0.6 m to the side, facing the same way). (ref: M:797-800, M:894-895; Q1649) (lobby, M4?)
- When a Guest joins while the drum finale is on, then it spawns inside the drum. (ref: M:898-899; Q1892) (outside the zoo?)
- When the Host admits the Guest, then it sends the join snapshot (the whole World), everyone's roster entry with their pose, and the Guest's spawn. (ref: J:48-50)
- When the snapshot is sent, then its byte size is added to `stats.snapshot_bytes` and printed. (ref: J:49, J:54; digest-core-and-coop.md:252: about 40 KB for 1000 Socks)
- When the Guest hears the welcome, then it loads the snapshot, replaces its roster with the Host's, builds a body for every other player at their pose, then spawns itself. (ref: J:61-78)
- When the Guest finishes the welcome, then its own player is placed at the spawn, its own body is coloured (the Host may have given another colour), the doors and devices are shown, and its player is unfrozen. (ref: M:1004-1018)
- When the Guest has joined, then its HUD says "Joined <Host name>'s flat" for 2 s. (ref: M:1020-1021; hud.gd:676)
- While a Guest is joining, then its player is frozen and the ESC menu closing does not unfreeze it. (ref: M:317, M:401, M:1018)
- When a Guest joins, then every other machine gets the entry and the spawn (`_joined`) and builds the body. (ref: J:51-53, R:150-154)
- When a Guest joins, then the Host and every Guest read "<name> joined" under the crosshair, the name in the player's colour, for 2 s; a later message replaces an earlier one (no queue). (ref: R:153, M:1062-1065, hud.gd:619-628, hud.gd:676; Q492; tests/net_join_test.gd:405-406)
- When the player who joined is this machine's own, then no "joined" line shows for it. (ref: M:1063)
- When the Host listens, then a Guest may join at any time during play (drop-in). Joining never adds Socks. (ref: digest-core-and-coop.md:186, :191; Q247, Q264)
- When a fifth player tries, then it is refused (see "full" above). (ref: digest-core-and-coop.md:191; tests/net_join_test.gd:227-246)

### What a late joiner receives
- When a Guest joins late, then it gets the whole World state in one snapshot (Mess, shelf, Openables, floor Pairs, bonuses, Cabinets, Coins, ...). (ref: J:48-50; tests/net_join_test.gd case_snapshot)
- When a Guest joins late, then it gets the roster with each player's name, colour, look and pose. (ref: J:50, J:61-67)
- When a Guest joins late, then it gets the other players' knockdown state (down, dragged_by, drum) inside the roster entries. (ref: S:174-177) (outside the zoo? full knockdown is M0.6 per Q2225: its own piece)
- When a Guest joins late, then each teammate stands where they are, not at the origin. (ref: J:72-75; coop-structure-for-the-port.md section 3 "Late join": the new spawner shows others in about 33 ms at 0 delay, 300 ms at 50 ms, so the position goes in the spawn values)
- When a Guest joins late, then it sees held things (carried Radio, Beeper) at the holder. (ref: M:916-919)
- When a Guest joins late, then a Sock mid-flight is a known open case (does the snapshot carry velocities). (ref: coop-structure-for-the-port.md section 8; digest-core-and-coop.md:379)
- When a Guest joins late, then the Host's own Hands, Upgrades and Coins are in the snapshot; only the Host saves. (ref: digest-core-and-coop.md:174, :190)

### Roster
- When the Session runs, then the roster holds each player: id, key, name, colour, look; max 4 including the Host. (ref: R:10-13; data/tuning/players.json:3; Q236, Q763)
- When the colours are listed, then there are 8: coral #f08a7a, teal #4fb3a9, mustard #e3b448, lilac #b49ad8, mint #8fd6a8, sky blue #86bfe8, rose #e89ab4, charcoal #55595f. (ref: data/tuning/players.json:4; Q275)
- When two players want one colour, then the Host decides; no two share one. (ref: R:203-233; GLOSSARY.md "Player colour")
- When a player asks for a colour another player has, then the Host refuses and tells the asker the colour they still have; nothing changes. (ref: R:221-228; Q343) (outside the zoo? the Wardrobe station is M5)
- When a player asks for a free colour, then it goes to everyone and the roster. (ref: R:229-233, R:237-242)
- When a player changes look, then it goes to the Host, is kept in the roster for later joiners and is passed on. (ref: R:169-198; Q309, Q330) (outside the zoo? Wardrobe)
- When the Join page shows colours, then a taken colour is greyed with the taker's name. (ref: R:61-66; Q314) (lobby, M4?)
- When the roster changes, then `roster_changed` fires on every machine. (ref: S:33, J:55, R:154, R:135)
- When asked who is in the Session, then the answer is the roster; the Host is player 1. (ref: S:84-85; Game.HOST)
- When a Guest asks for anything on behalf of another player, then it is ignored (a Guest acts only for themselves). (ref: S:367; digest-core-and-coop.md:181)
- When a Guest sends a Command, then it is accepted only from a peer bound to a player id; the player is looked up from the peer id the engine gives, never from the packet. (ref: S:358-362, S:188-189)
- When a Guest sends a packet the Host cannot read, then it is dropped, counted in `stats.bad_packets` and one line per peer per second is printed; nobody is kicked. (ref: PG:57-66; S:339, S:365)
- When a Guest sends more than 60 poses a second, then the extra are dropped and counted. (ref: PG:44-50; net.json:5) (teammates seen / avatar piece?)
- When a pose is outside the house by more than 30 m on x/z, or y < -50 or > 100, or has 5-12 members that are not finite numbers, then it is dropped. (ref: PG:76-84; net.json:6) (avatar piece?)
- When a player has a name over their head, then it is in their colour; a teammate's name tag and a Host mark belong to "teammates seen" and the Lobby. (ref: M:912-913; digest-core-and-coop.md:123) (teammates seen / lobby, M4?)

### Leaving
- When a Guest closes the game or loses the connection, then the Host runs the same leave: `peer_disconnected` -> leave. (ref: S:396-408, S:397)
- When a Guest chooses Leave in the ESC menu, then there is no question; it goes at once. (ref: session_menu.gd:2-4; Q315) (outside the zoo?)
- When a Guest leaves, then their Hands drop where they last stood (their last pose), for everyone still there. (ref: R:119-122; hands_rules.gd:404-411; Q248, Q295)
- When a Guest leaves and no pose was ever heard (fewer than 5 values), then their things drop at the layout's spawn position. (ref: R:124-127)
- When a Guest leaves, then everything else they carry lets go where they stood: gift box, Part, bin, Radio, cat, beeper, lantern, book. (ref: hands_rules.gd:405-410; main.gd:932-940) (outside the zoo? only what the zoo has)
- When a Guest leaves, then their drag, Elevator ride and wash end, and the leaver's owned-pieces list is cleared. (ref: hands_rules.gd:416-420) (outside the zoo? knockdown/Elevator pieces)
- When a Guest leaves with a drop that holds items, then the drop sound ("drop") plays once for everyone. (ref: hands_rules.gd:423-424)
- When a Guest leaves, then the Host keeps their Upgrades and their last position (PlayerState.where) so they return to them. Their Hands are not saved (they dropped). (ref: R:112-122; digest-core-and-coop.md:190; Q295, Q296)
- When a Guest leaves, then their avatar body goes from every machine; a body that held the Radio or Beeper is not freed with it, the item is laid by the drop. (ref: R:132, M:923-941)
- When a Guest leaves while in the Wardrobe station, then the Host takes them out of it. (ref: M:927-928) (outside the zoo?)
- When a Guest leaves, then each other Guest is told (`_left`), the roster entry is erased, the pose cache is erased, the peer is unbound and the packet counters forgotten. (ref: R:128-135, R:158-163, S:406)
- When a Guest leaves, then "<name> left" shows in their colour for 2 s on the others (the roster still holds them while the line is made). (ref: R:130, M:1062-1065, S:320)
- When a Guest leaves, then "session: <name> left" is printed. (ref: R:129)
- When the Guest's own machine leaves, then its Session closes, it is online=false, and it plays as a Host of one if it stays. (ref: S:583-590; port: session.gd close())
- When a Guest leaves and comes back, then it gets the same id, so its Upgrades and spot return. (ref: tests/net_join_test.gd:163-227, :150-158)

### The Host quits
- When the Host closes the Session or quits, then every Guest's Session ends with "The host ended the session". (ref: S:43, S:563-564; Q250)
- When a Guest's Session ends, then its HUD shows the text, its player freezes, and it goes back to the title. (ref: M:1026-1030; tests/net_join_test.gd:336-352)
- When the Host ends the Session, then it saves first and Guests do not save. (ref: session_menu.gd:3; M:804-806; Q249) (outside the zoo? no save yet)
- When the Host ends the Session, then the Host's own machine goes back to the title/menu. (ref: session_menu.gd:3-4) (outside the zoo?)
- When the Host crashes, then the Guest hears `server_disconnected` the same as a quit and shows the same text. (ref: S:563-564; digest-core-and-coop.md:112)
- When the Host crashes, then Guests' positions are lost: accepted. (ref: digest-core-and-coop.md:185; Q487)

### Disconnect and timeouts
- When a connection is lost, then the old game relies on ENet's own timeout; it has no own heartbeat, no reconnect and no time limit on "Connecting to ...". (ref: S (no timeout code; grep `timeout` in game/net finds none); title_screen.gd:559)
- When a peer does not finish the gate in time, then the engine drops it after `SceneMultiplayer.auth_timeout` (the port; default 3 s). (ref: port: game/parts/session.gd:148)
- When a Guest is on the Join screen but sends no hello, then it stays a connected peer with no body and no roster entry; it counts against the ENet slots only. (ref: S:333-353; peer_count S:170-171)
- When a Guest's hello is refused, then the Host does not disconnect it explicitly; the Guest closes itself on hearing the text. (ref: S:468-470, S:593-598)
- When a Session ends, then the Guest's `ended(text)` signal fires once and later calls to end do nothing. (ref: S:593-598)

### Gate (port design, M0.6)
- When a peer connects, then nothing replicates and no RPC passes until the Host's `auth_callback` admits it, because Godot starts replication at connect, before any hello. (ref: docs/migration/coop-structure-for-the-port.md section 1; port: session.gd:148-170)
- When a peer's gate word is not 4 bytes holding PROTOCOL, then it is refused at the gate with one byte REFUSED, never admitted, and counted as "protocol". (ref: port: session.gd:149-160; old S:341-344)
- When a Guest hears REFUSED or anything but ACCEPTED, then it ends with "The Host is playing another version" (placeholder). (ref: port: session.gd:39, :149-160; old S:52)
- When the gate carries the player id, then it is the long random profile id (128 bit), not the peer id; the peer id is a live field only. (ref: Q2224; ids-roster-guards.md rec 2, section 6) (changed by Q2224: the old id is a 31-bit int, range 2..0x7fffffff, PG:15, profile.gd:81)
- When the gate carries a secret token, then the Host checks it; for M0.6 this is not built, the token comes with the lobby. (ref: Q2224) (changed by Q2224: the coop-structure doc's Q5 recommended the token in M0.6; Q2224 later puts it in M4)
- When the gate carries a scene-contract hash, then a path mismatch is caught at connect instead of silently. (ref: coop-structure-for-the-port.md section 2 row "Version check and join", REPORT A3) (not in decisions: ask)
- When the same player id is already live in the roster, then the second connection is refused (ENet itself also resets a duplicate id). (ref: ids-roster-guards.md section 6; old R:93-97)
- When the roster Part holds the player, then its per-player state is keyed by the player id, the peer id is never saved. (ref: coop-structure-for-the-port.md section 1 and 2 "Roster and profile ids"; m06 order item 2)
- When a copied profile joins as an existing player, then in M0.6 the id alone is taken as proof (no token): a copied profile is refused only while the original is live. (ref: Q2224)
- When the old local key "local:<n>" was kept by a World's Group, then the port keys everything by the long id; Steam id replaces it later. (ref: PlayerIdentity player_identity.gd:106-110; Q1664) (lobby, M4? / Steam, outside M0.6)
- When the Host decides who has an avatar, then it spawns one per admitted player and removes a leaver's. (ref: port: game/parts/avatar/avatars.gd:19-41; old R:132, J:43)

## Invariants
- Only the Host decides; a Guest's packet never writes shared state. (Q2146, Q2147, Q2212)
- Nobody is admitted before the gate has checked protocol (and, from M4, the token); an unadmitted peer gets no spawn, no synchronized value and no RPC.
- The roster is keyed by the player id, never by the peer id; the Host is player 1 and alone is a Host of one.
- At most 4 players in the roster at once; two live entries never share an id or a colour.
- A Guest acts only for the player its peer is bound to; the packet's own claim of who it is is never used.
- A bad packet is dropped, counted, logged at most once per second per peer and reason; no kick, no crash, no error inside an RPC handler.
- A Guest never saves; the Host's save keeps each player's Upgrades and last position by player id, never their Hands.
- A leaver's carried things are let go at their last position for everyone, in one Host answer, before their entry is erased.
- A returning player gets the same id, so their state returns.
- The join snapshot and the save use one format (`Parts.snapshot()`).
- Every Session end gives the player a text saying why; closing twice is safe.
- The Host's machine never refers to a peer id after its leave.

## Numbers
| Number | Old value | Source |
|---|---|---|
| Port (UDP) | 24680 | data/tuning/net.json:3; S:65 |
| Port in the port | 24565 | port: game/parts/session.gd:35 |
| Max players, Host included | 4 | data/tuning/players.json:3 |
| ENet max peers opened | max_players * 2 = 8 | S:215 |
| Max guests in the port | 3 (placeholder export_range 1..15) | port: session.gd:47 |
| Colours | 8 | data/tuning/players.json:4 |
| Player id range | 2 .. 0x7fffffff (1 = Host, 0 = everyone) | PG:15; profile.gd:81; PG:89 |
| Name length | at most 16, empty = "Player" | profile.gd:16, :146-149 |
| Owned-pieces list in a hello | at most 500 Strings | PG:17, :98 |
| Protocol | 5 (port: 9) | S:50; port: session.gd:31 |
| Pose members | 5 to 12 | PG:12-13 |
| Pose rate, Guest sends | 20/s (port: every frame, Q2223) | net.json:4; Q2223 |
| Poses accepted per peer | 60/s | net.json:5; PG:22 |
| Pose margin outside the house | 30 m on x/z; y -50..100 | net.json:6; PG:82 |
| ENet throttle | interval 5000 ms, acceleration 2, deceleration 0 | address_backend.gd:232-233, :276 |
| Join/leave line | 2 s, replaces the earlier line | hud.gd:676; Q492 |
| Join/leave name font | 28 px, in the player's colour | hud.gd:625 |
| Message row height | 0.70 of the screen | hud.gd:162 |
| Spawn apart | 0.6 m | players.json:5; M:878-883 |
| Join snapshot | about 40 KB for 1000 Socks (later 3.4 to 20 KB) | digest-core-and-coop.md:252 |
| Guard print rate | one line per peer per second | PG:62-64 |
| Dropped-packet reasons in port | protocol, not in the game, shape, no part, verb, args, rate | port: session.gd:51-52 |
| Per-verb Command rate in port | 10/s default | port: session.gd:37 |
| Auth timeout | engine default 3 s (SceneMultiplayer) | port: session.gd:148 |
| Join Coins | `coin_bank.join_coins()` (a new player's start, Q1249) | J:42 (outside the zoo?) |
| Knockdown rumble, teammates' sounds | M0.6, Q2376 | decisions.md Q2376 |
| Wording: full | "The game is full (%d players)" | R:92 |
| Wording: already in | "That player is already in this game" | R:8 |
| Wording: wrong build | "The host is playing another version of It Socks" | S:52 |
| Wording: starting | "The game is starting: join again in a moment" | S:55 |
| Wording: unreadable | "The host could not read your join" | S:348; J:30 |
| Wording: host quit | "The host ended the session" | S:43 |
| Wording: unreachable | "Could not reach <ip>" | S:560 |
| Wording: not in the Group | "This World belongs to its Group: you are not in it" (placeholder) | digest-core-and-coop.md:154 |
| Wording: joined | "Joined <Host name>'s flat" | M:1021 |
| Wording: teammate | "<name> joined", "<name> left" | M:1065 |
| Wording: connecting | "Connecting to <ip>..." | title_screen.gd:559 |
| Wording: could not connect | "Could not connect (<error>)" | title_screen.gd:557 |
| Wording: End session | "End session" / "Leave" / "Back to title"; "Everyone will be sent back to the menu." End / Cancel | session_menu.gd:19-21 |
| Wording: firewall help | "The host's firewall must let It Socks through on UDP port %d" | title_screen.gd:436 |
| Port wording today | "The Host is playing another version", "The Host ended the session" | port: session.gd:39-40 |

## Already in the port
- `game/parts/session.gd`: Host listens on 24565 (`host()`), Guest joins by address (`join()`, `split_address` with IPv6). Done.
- The gate: `auth_callback`, PROTOCOL 9 as 4 bytes, ACCEPTED/REFUSED, drop counted as "protocol", Guest ends with `WRONG_BUILD`. Done; auth timeout is the engine's.
- Gate carries NO player id, NO token, NO name, NO colour, NO scene-contract hash. Missing.
- Guard: Command shape, target part, verb accepted, args exact, rate (10/s default); drop counter and one print per second per player and reason. Done.
- Snapshot to a late Guest after the gate (`_welcome` with `parts.snapshot()`). Done; the Mess bulk snapshot is a later M0.6 item.
- Events relayed to admitted Guests only (`_guests`). Done.
- `Parts.left(by)` asks each part what a leaver does; `Carriable.left` lets a held thing go (`holder = 0`). Done for Carriables; position of drop is "where it last lay", not the leaver's position (check). The leaver's Hands (their Socks stay HELD) are listed as open in m06-backlog.md "Co-op".
- Host quit: `server_disconnected` -> `_end(HOST_QUIT)` -> `ended(text)`; `close()` makes the machine a Host of one. Done.
- `game/parts/avatar/avatars.gd`: Host spawns an avatar per admitted peer (`peer_connected`) and frees a leaver's (`peer_disconnected`); a late Guest gets the others from the spawner; `clear()` after the Host quits. Done. Position in the spawn values (no flash at the origin): missing.
- `game/zoo/zoo_net.gd`: `-- --host` and `-- --join=<ip[:port]>` flags, a corner label ("Hosting on port N: M player(s)", "Joined as player N", "Alone: <why>", "Could not join"). Done; the zoo has no lobby, no menu, no toasts.
- `game/debug/game_cli.gd`: passes `--host` and `--join=` through; debug builds only. Done.
- Player id: the peer id is used (`me()` = `get_unique_id()`; `Avatars._make` names by it). Long random profile id (Q2224): missing. No Profile or profile file at all in the port.
- Roster Part (players, name, colour, look, max 4, refusals full / already in, free_colour, `roster_changed`): missing. `max_guests` is 3 as a placeholder export, ENet refuses the fifth with no wording.
- Refusal wording for full and already-in: missing. Only WRONG_BUILD exists.
- Names and colours of players (name over the avatar, tint): missing; the avatar is a capsule with a Sync.
- Join/leave toast ("<name> joined" / "<name> left", 2 s, colour name) and "Joined <Host>'s flat": missing (the zoo corner label only).
- Teammates' spawn at the washer spawn, 0.6 m apart; returning player at their spot: missing (no spawn slots; one spawn).
- Per-player state keyed by player id (Hands, Coins, where): missing; the Players Part is not built.
- Guest packet guard for avatar poses (finite, bounds, rate): missing (m06 order item 10).
- Duplicate live id refusal: missing. Two copies on one PC sharing a profile: not an issue until a profile exists.
- Tests: `tests/scene_parts_test.gd`, `tests/zoo_test.gd`, `tests/support/lag_peer.gd` exist; a refusal-wording test, a full test, a leaver-drop test with positions: missing.

## Questions for the designer
Checked decisions.md Q2160-Q2226 and the Co-op section of the backlog first. Settled: Host-only decisions, 4 players (Q236), token later (Q2224), long id (Q2224), avatars every frame (Q2223), join/leave messages exist (Q492), leaver drops Hands where they stood (Q248), Host quit ends the Session (Q250), no lobby in M0.6 (Q2161).

1. **Names:** Without a lobby or a Wardrobe, where does a player's name come from in the zoo? Options: a `--name=<text>` flag plus a saved profile name (recommended: zoo is dev-driven); "Player" for everyone; the player id's first letters. Old default was "Player", max 16 letters.
2. **Colours:** Without the Wardrobe, who picks a colour in M0.6? Options: automatic, the next free one in order (recommended; old behaviour for a taken colour); a `--colour=<n>` flag; none until the Wardrobe (M5).
3. **Join/leave toast in the zoo:** Does the zoo show "<name> joined" / "<name> left" under the crosshair (old: 2 s, in the player's colour), or only the corner label? And does "Joined <Host>'s flat" (old, 2 s) become "Joined <name>'s zoo"?
4. **Wording:** The refusal texts are placeholders in the old game and the port ("full", "already in", "another version", "Host ended"). Keep the old texts, or word them anew? Note the old capital: "The host ..." versus the port's "The Host ...".
5. **Scene-contract hash:** The structure doc wants it in the gate (a wrong scene path is otherwise silent). Not in decisions. Build it in M0.6? What does a mismatch say: the same "another version" text, or its own?
6. **Max players in the zoo:** The port's placeholder is 3 Guests (4 players). Confirm 4 total; and is the fifth refused with a text ("The game is full (4 players)") or just a failed connection?
7. **Leaver's things in the zoo:** A leaver's held thing is let go where they last stood (old). The port's Carriable lets it go "where it last lay". Which is wanted? And a leaver who never sent a pose: drop at the spawn (old) or where it lay?
8. **Join with no answer:** The old game had no Cancel and no time limit on "Connecting to <ip>...". In the zoo, keep none, or print "Could not reach <ip>" after a time? How long?
9. **Late joiner's spawn in the zoo:** At the washer spawn 0.6 m apart (old, new player), beside a teammate (old, Group member joining play), or at one zoo spawn? A returning id: where they left (old).
10. **Token wording:** A copied profile joins as the player while the original is away (Q2224 accepts this until M4). Confirm that is acceptable for M0.6 playtests.
