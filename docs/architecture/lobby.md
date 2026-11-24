# The Lobby

**Status: designed, as decided (Q2582-Q2587); core/62 (the game link) and core/63 (the Lobby scene, LobbyState) built, the rest not.** The saved id of the
Roster is `Runtime/Session/Roster` (the runtime instance is named `Runtime` in every level): the link's Parts prefix
their ids with `Runtime/` so it does not change. Findings: `docs/migration/m4-lists/02-lobby.md` (74
lines of the old Lobby). Written against core/58 as merged to `main` (`docs/architecture/saves.md` "As built",
`game/save/`, `game/ui/title/`, `game/level/`, `game/parts/session.gd`). The first ticket (core/62) changes the co-op
code; read its section first.

## What it owns

The Lobby scene where the players of a game gather before the house: the places with each player's Avatar, name and
Ready, the Host's Start, the World's card, the World drawer that chooses and deletes a World (Q2561), and the game-lifetime
link (Session and Roster) it stands on. It does not own saving (core/58), the Wardrobe and the stats card (Q2584: the
Wardrobe piece), Steam (the M4 Steam piece), or the "Pairs per Drawer" slider (Q2586: the Stages piece).

## Decided (designer, 2026-11-23)

- Q2582: the Lobby is its own scene; Session and Roster live for the whole game, so the connection carries from the Lobby
  into the house with no reconnect; Start has the Host load the house for everyone behind the one loading screen; the World
  is chosen in the Lobby (the drawer comes back).
- Q2583: Solo goes through the Lobby, one pedestal.
- Q2584: the Wardrobe page and the stats card are split out; the first Lobby shows Avatars in their colour.
- Q2585: the name is typed in one field on the Multiplayer page, built so a Steam name can fill it later.
- Q2586: the drawer's "Pairs per Drawer" slider waits for the Stages piece.
- Q2587: a co-op World's row name is made in one swappable place; first the members' names, with "World 1", "World 2" plus
  details of the World's state as the likely simpler form, judged at the Lobby look's first still; no Guest is limited to
  Worlds they belong to.

## Where things stand today (core/58)

- The title picks a `WorldSlot` (`Worlds.pick_solo()`, `pick_host()`) and hands it to the house through
  `SceneChanger.change_to(path, heading, setup)`: `LevelRuntime.world`, `from_title`, `launch` (`--host`, `--join=`).
- `Worlds` has what a World list needs and nothing calls it yet: `rows()` (`slot`, `name`, `details`, `damaged`,
  `last_played`; the Solo World first, co-op Worlds newest first), `delete(slot)`, `free_coop_slot()`, `FULL`, `display_name()` (was `row_name()`),
  the rule that the Solo World played with a Guest becomes a co-op World.
- `Session` (the one RPC node), `Roster` (a Part, saved id `Session/Roster`), `Avatars`, `LevelNet`, `Autosave`, `EscMenu`
  are nodes of `level_runtime.tscn`; a machine is in a Session only while a house is loaded. `Session` exports `parts`
  (the level's `Parts`) and `roster`; the gate compares the hash of the level's Part ids (`layout_of`); a joiner gets
  `parts.snapshot()` once `parts.is_settled()` (the starting Socks laid, house/09).
- Names are "Player" except a Join page's field (core/58); colours are the next free one (Q2441); no look, no tallies.

## Core/62: Session and Roster out of the level (the first ticket)

### The object

**`GameLink`** (`game/net/game_link.gd`, scene `game_link.tscn`): a node that lives for the whole game, beside the current
scene, not inside it. It holds, as children, **`Session`** and its **`Roster`** (so the Roster's id stays
`Session/Roster`, and no save breaks: `tests/saves/house_ids.txt`, `shape.json` S11 and S12 keep passing as they are), and
a **link `Parts`** that binds the Parts that outlive a scene: the Roster now, `LobbyState` in core/63. It is not an
autoload: a test runs two or three machines in one process (`SceneTree.set_multiplayer` per branch), so the link is made
and owned by whoever starts a game and found with `GameLink.of(node)` (as `LevelRuntime.of`).

- **Made** by the title when Solo, Host or Join is pressed (a Solo player is a Host of one, `Session.enter_alone()`), kept
  by the `SceneChanger` across `change_to` (it is added under the tree's root, which a scene change leaves alone), freed
  when a game ends: Back to title, End session, Leave, the Host quitting (`Session.ended`), the window closing.
- **No link yet** (F5 on a level, the zoo, `--scene=`, every existing test): `LevelRuntime` makes a private one under the
  level, exactly the nodes it has today. So a level is never without one and `level_runtime.tscn` loses only the two
  nodes it hands over.

### What changes in the coop code

| Piece | Today | After |
|---|---|---|
| `Session` | child of the runtime; `@export parts, roster` | child of the link; `parts` becomes `link_parts` plus `level_parts` (null in the Lobby); `roster` is its sibling |
| Part ids | one `Parts`, ids are paths from the level | two `Parts`; ids stay as they are (the link's are paths from the link: `Session/Roster`); a Command's target is looked up in both (`Parts.of` on each, link first); the snapshot is two dictionaries |
| The gate | PROTOCOL, build layout hash of the level's Part ids, player id, Hands numbers | PROTOCOL and the player id at connect (the Lobby has no level); the layout hash moves to the house handshake below; `PROTOCOL` goes up |
| The welcome | one snapshot after `parts.is_settled()` | at connect: the link snapshot (Roster, later `LobbyState`); at house load: the level snapshot (below) |
| `Avatars`, `Autosave`, `EscMenu`, `LevelNet`, `Hands`, `Coins` | `@export` paths to `Session` and `Roster` | one `GameLink.of(self)` in `_ready` or the runtime's `_enter_tree` (an export cannot name a node outside its scene) |
| `Roster` | state saved whole, restored by `load_save` | `save_state()` unchanged, but `loaded()`/restore **merges** into the live Roster (present players stay, absent players' saved entries come back with their spot, colour, Hands) instead of overwriting it; the save is read at the house load, never in the Lobby |
| `Autosave.collect()` | `parts.save_snapshot()` | the two `Parts`' snapshots merged into the same `"parts"` dictionary: the file's shape is unchanged |

### The house handshake (the join snapshot at house load)

1. Start (core/63) or, for a late joiner, the link snapshot saying the house is in play: each machine loads the house
   scene the Host named (`LobbyState.level`) with `SceneChanger` behind the loading screen; the machine's `Session` keeps
   its peer.
2. When a machine's house is bound (Parts bound, Socks laid on the Host: `parts.is_settled()`), a Guest sends `house_ready`
   (reliable RPC on `Session`) with the hash of its level's Part ids and `PROTOCOL`.
3. The Host answers a mismatch with the existing `WRONG_BUILD` refusal and the Guest goes to its title; otherwise it waits
   for its own house to be settled, then sends `parts.snapshot()` of the level (what `_on_peer_joined` sends today) and the
   Guest shows the house at once (`load_snapshot`, `_show(now = true)`).
4. A Guest that arrives after Start (the link snapshot already says in-play) loads the house straight away and takes the
   same steps: it is today's late joiner with a new first step.
5. While a house is loading nothing is answered from it: the Host's `Session._command` drops a Command whose target is a
   level Part until that Guest's `house_ready` was handled (counted in `dropped`, reason `not_ready`, never logged
   loudly).

### What stays the same

`Parts.apply`/`ask`/`answer`, `Command` shapes and guards, the Avatars spawner (it starts after the house handshake), the
Mess, Hands, Throws and Knockdown streams, ENet's settings, `Session.close()` (it frees the link's connection;
`went_alone` runs on the level's `Parts` when there is one), the `HOST_QUIT` notice.

### Tests that must stay green (and what moves)

`coop_join`, `coop_guard`, `coop_flight`, `scene_parts` (guard), `teammates`, `avatar`, `own_body`, `piano`, `level`, `house`,
`save`, `menus`: their expectations do not change. `_session(zoo)` in the co-op suites finds the Session through
`GameLink.of`; the machines are still zoos or levels in one process, each with a private link. New cases (real path, 0 and
50 ms): a link that outlives a scene change (a Guest stays connected across `change_to` and its Roster entry stays); the
house handshake (a Guest's `house_ready` is what releases its snapshot; a wrong layout is refused); a late joiner after
the link says "in play"; a Command for a level Part before `house_ready` is dropped; the save's Roster merge (present
players kept, absent ones restored); `PROTOCOL` raised.

## Core/63: the Lobby scene and `LobbyState`

**The scene** `game/lobby/lobby.tscn`: a Control on the one Theme over the title's backdrop, no house. It is a view of
`LobbyState` and `Roster`; a key is `parts.ask(...)`, never a write. Solo and co-op are the same scene: Solo has one place,
no Ready, and Continue and New Game where co-op has Ready and Start (the old Solo bar; read from Q2583's "one pedestal").

**`LobbyState`** (a Part of the link's `Parts`; State group): `ready: Array[String]` (player ids), `started: bool`, `level`
(the house scene), `title` and `line` (the World's card as the Host says it), `world` (the chosen slot). Guests may ask
`ready` (their own id, a bool, rate-limited by `accepts()`) and nothing else; `start` and the World's changes are Host-only
(not in `accepts()`). `decide(start)` refuses unless every present player in the Roster is in `ready`. A leaver is dropped
from `ready` in the Part's `left()` (the old `keep()`); a joiner is not Ready; every change to the chosen World clears
`ready`. `save_state()` is `{}`: Ready is never saved.

**Start:** the Host's answer sets `started` and `level`; every machine (Host included) calls `SceneChanger.change_to(level,
"Loading the house...", ...)` with the World slot on the Host only; the house handshake above does the rest; the Lobby's keys
lock as it starts. A Guest who connects when `started` is true skips the Lobby.

**Back and Leave:** the Host's Back ends the session as the ESC menu's End session does (every Guest to its title with "The
Host ended the session", Q250); a Guest's Leave is `Session.close()` then the title; Esc is Back; the window closing as the
Host ends it too. The title's Solo, Host and Join keys now go to the Lobby (`--host` and `--join=` on the command line act at
once: Host into a Lobby, Join into the Host's Lobby or house).

**While the Host is in the Lobby, a Guest sees** the same Lobby (the same model) and the loading card "Joining..." until the
link snapshot arrives; **between Start and play** the loading card, as the Host.

### As built (core/63)

- `game/lobby/lobby_state.gd` (`LobbyState`, the link's `LobbyState` node, id `Runtime/LobbyState`): the Ready list is
  `readied` (a `PackedStringArray` of player ids; `ready` is Node's own signal). Verbs: `ready` {"on": bool} (the
  only Guest verb, rate 5), `start` and `world` {level, title, line, world} (the Host's). `PROTOCOL` 15.
- `game/lobby/lobby.tscn` (`LobbyScreen`): mode SOLO, HOST or JOIN set by the title's setup with the WorldSlot or the
  address; the Lobby starts the session itself (`enter_alone`, `host`, `join`) and hands `go_into` on from the title.
  The places are a plain list (HOST mark, name in colour, "✓ Ready" or "-"); a Guest shows the loading card
  "Joining..." until the link snapshot. Solo's New Game uses `Worlds.pick_slot(slot, hosting, fresh)`.
- Spots: a player who joins in the Lobby has no `at` in the Roster (nobody stands there); as the house comes in the
  Host's `LevelNet` answers `Roster.placed()` (the Host where its body stands, the others beside it), so each stands
  at its Roster spot at the welcome.
- A Guest's `house_ready` that arrives while the Host's house is still loading after Start is kept and answered when
  the Host's level attaches (`Session._house_early`).

## Core/64: the name field

One field "Your name" on the Multiplayer page (above Host and Join), kept in the profile; Join's own field goes. The field
fills from a `PlayerProfile.suggested_name()` seam (returns "" now; Steam's persona name later, Q2585) and a typed name wins
(`name_set`). The Roster takes the name at the gate (as now). Solo has none. Real path: type a name, Host, a Guest joins; the
Guest's Lobby place says it.

## Core/65: the World drawer, in the Lobby

The old drawer comes back as in the list ("The World settings drawer"), minus the Pairs slider (Q2586): a "World settings" key
top right, a 520 px cream panel sliding 0.25 s (cubic ease-out) over the right; the Host's holds "World" with every World as a
row (Solo World first, co-op Worlds newest first): colour swatches, the row name (L7 below), the Host's **Choose** and a red
**Delete** (co-op only), the details line; **New game** (first free co-op slot; with all five used the "full" page over the
Lobby asks to delete one first, "All 5 co-op Worlds are used: delete one first"; deleting goes on with the New Game); Delete
asks "Delete <name>? It cannot be brought back." with a red Delete and Cancel. The Solo World with every slot used asks the same
(Q1738). A Guest's drawer is the same list read-only with a tick on the chosen one (every World shown: Q2587 limits no Guest).
Choosing writes `LobbyState.world/title/line` through the Host; `ready` clears. Deleting the chosen World puts the Lobby on the
last-played co-op World, else a New Game. Solo's drawer-less bar: New Game asks "Start a new game? The saved game is lost."
before overwriting.

It uses `Worlds` as it is (`rows`, `delete`, `free_coop_slot`, `FULL`) plus `pick_slot(slot, new_game)` beside `pick_solo`/
`pick_host` and `row_details()`; the World loads from the slot the Host chose at Start. The old drawer's open questions (dim
behind it, close on a click outside, Esc) are `[later]` for the look ticket's still.

**L7 a World's name:** `Worlds.display_name(slot, record)` is the one place that makes a row's name (and the card's title);
today it returns the members' names ("No Group yet" while none). Changing it to "World <n>" plus the World's
state details is one function and its test; the look ticket's first still shows both and the designer judges.

## Core/66: the Lobby look (look work)

The stage, the places, the World card and the i page; stops at its first still. `lobby_stage.tscn` (a `SubViewport` with its
own `World3D`, one camera, four pedestals, the game's Avatar scene idling by its AnimationPlayer; a free place a flat grey
silhouette on a dimmed pedestal, "Waiting for a player"), `lobby_place.tscn` (box, label: HOST mark, name in the player's
colour, the Ready mark), `who_page.tscn`; numbers in a typed `LobbyTuning` (`lobby_tuning.tres`, each field `# placeholder:`;
the old `lobby.json` values). Places follow the figures through `unproject_position` every frame; the focused place's pedestal
turns gold; the Wardrobe key and stats card are not here (Q2584). Stills: four players, a free place, a long name, 16:9 and a
narrower screen, the focus; the row name's two forms (L7); the drawer open.

## Core/67: the Lobby's details

The pad route (the i key, the settings key, the figures, the bottom keys, the drawer as a column), the keys' captions and hints
("press again to un-ready", "when everyone is Ready"), the wording of the whole screen from one place, the Ready tick
(`UiSounds.hover()`), the narrower-than-16:9 camera, the status line, the click-and-hover sounds on every key, an
"Invite friends" hook shown only when the transport says it can (`NetTransport.can_invite()`, false for ENet; the Steam piece
fills it).

## What core/58's code is reused and what changes

Reused as it is: `Worlds`, `WorldRecord`, `WorldSlot`, `Save`, `SceneChanger`, the loading screen and its fade, `KeycapStyle` and
the Theme, `UiSounds`, the title's page pattern, `PlayerProfile`, the ESC menu's End session and the host-ended notice.
Changed: the Session/Roster move (core/62); the title's Solo/Host/Join go to the Lobby (`title.gd`); `Worlds` gains
`pick_slot`, `row_details`, `display_name`; `Roster` gains the merge restore; `LevelRuntime` takes the link from `GameLink.of`
or makes one. The save file's shape and `WorldRecord` do not change.

## Tickets (in order)

| # | Ticket | Blocked by |
|---|---|---|
| core/62 | Game link: Session and Roster out of the level | none |
| core/63 | The Lobby scene and `LobbyState` (Solo and co-op, Ready, Start, the house handshake, Back and Leave) | core/62 |
| core/64 | The name field on the Multiplayer page | none |
| core/65 | The World drawer and its pages in the Lobby | core/63 |
| core/66 | The Lobby look (stops at its first still) | core/63 |
| core/67 | The Lobby's details | core/65, core/66 |

Later, not tickets yet: the Wardrobe key, page and colour row with the stats card (the Wardrobe piece, Q2584); the Steam lobby and
Invite friends (the M4 Steam piece); what the Lobby offers after an ending (the ending's piece; the old game never decided).
core/64 can run beside core/62.
