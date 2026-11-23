# The Lobby

**Status: proposal (core/61), for the designer's choices L1-L7 at the end.** Nothing here is built. Findings:
`docs/migration/m4-lists/02-lobby.md` (74 lines of the old Lobby). Written against core/58 as merged to `main`
(`docs/architecture/saves.md` "As built", `game/save/`, `game/ui/title/`, `game/level/`).

## What it owns

The screen where the players of a co-op game gather before the house: the places with each player's Avatar, name and
Ready, the Host's Start, the World's card, and everything that chooses and deletes a World (Q2561: "the World list,
Continue/New Game and Delete come with the Lobby"). It does not own saving (core/58), the Wardrobe or the Lifetime
tallies (not in the port yet), or Steam (the M4 Steam piece).

## Where things stand today (core/58)

- The title picks a `WorldSlot` (`Worlds.pick_solo()`, `pick_host()`: Continue, else a New Game in a free slot) and
  hands it to the house through `SceneChanger.change_to(path, heading, setup)`: `LevelRuntime.world`, `from_title`,
  `launch` (`--host`, `--join=<address>`). One loading screen, "Loading the house..." (Q2579).
- `Worlds` already has what a World list needs: `rows()` (`slot`, `name`, `details`, `damaged`, `last_played`; the Solo
  World first, co-op Worlds newest first), `delete(slot)`, `free_coop_slot()`, `FULL`, `row_name()` (the members' names or
  "No Group yet"), the rule that the Solo World played with a Guest becomes a co-op World. Nothing calls `rows()` or
  `delete()` yet.
- The `Session` (the one RPC node), the `Roster` Part, the `Avatars` spawner and the `LevelNet` start all live inside the
  house's `LevelRuntime`: a machine is in a Session only while the house is loaded. A Guest joins a running house with the
  join snapshot; a late joiner is the normal case.
- Players are named "Player" (Q2440) except where the title's Join page took a name; colours are the next free one
  (Q2441); there is no Wardrobe, no look, no Profile tallies.

## The shape (L1, the choice that decides the rest)

The old Lobby was a scene with a Session of its own, loaded before the house, handing over by reconnect (the Host
"listens again from its World", the Guests join again, a refusal window between). That cannot be copied: the port's Session
lives in the level and a second Session means a second gate, a second Roster and a second wire to keep right.

**Recommended: the Lobby is a screen over the loaded house.** The Host's World is chosen before (below), the house
loads as today behind its loading screen, and a full-screen Lobby (the title's backdrop, its own pedestal 3D view)
covers it until the Host presses Start. Guests join the running house exactly as they do now; while Start has not been
pressed they see the Lobby too. Start is a Command on a `LobbyState` Part; its answer sets `started`, every machine fades the
cover away (the loading screen's own fade, Q2575) and play begins. A Guest who connects after Start joins straight into
play, as a late joiner does today.

What the cover needs under it, all in `game/lobby/`:
- **`LobbyState`** (Part, scene part of `level_runtime.tscn`, State group: `ready: Array[String]` player ids,
  `started: bool`, `title`, `line`: the World's card as the Host says it). Guests may ask `ready` (their own id only, a
  bool) and nothing else; `start` is Host-only (not in `accepts()`), and `decide()` refuses unless every player in the
  Roster who is present is in `ready`. `save_state()` is `{}`: Ready is never saved; a load starts every player not Ready.
  A leaver is dropped from `ready` in the Part's `left()` rule (the old `keep()`); a joiner is not Ready.
- **`Lobby`** (a CanvasLayer in the runtime, a view only): shows `LobbyState` and `Roster`; a pressed key is
  `parts.ask(...)`, never a write. It exists only while `started` is false and the level was loaded from the title with a
  World chosen (F5, the zoo and `--scene=` start with `started = true`, so nothing changes for them).
- **The hold**: while `started` is false the local body takes no input (the group `local_input`, as the ESC menu does),
  nothing is drawn through the cover, and the house's own sounds are muted on the Sounds bus; Hands, Knockdowns and the Mess
  keep running (they have nothing to do), no Command from play is answered (`Parts.ask` refuses a verb of a Part other than
  `LobbyState` and the Roster while held: one line in `Parts`), and the Autosave does not save before Start except the
  Host's Back, which saves nothing new anyway (nothing changed).
- **Start**: the cover fades (placeholder: the loading screen's fade, 0.4 s), the bodies stand at their Roster spots (a New
  Game at the level's Spawn, a loaded World where each player was, as core/58 does), the sounds come back.
- **Back / Leave**: the Host's Back is the ESC menu's End session for a Host in the Lobby (everyone goes to their title with
  "The Host ended the session", Q250; the port already has this); a Guest's Leave is `Session.close()` then the title. Esc on
  the Lobby does Back; while a page is open it closes that page.

Why this and not the old way: no second Session, no hand-over, no refusal window, no "Joining..." between Start and play,
and the house is built once (the old game built it twice). The cost: the house's loading screen comes before the Lobby
(a New Game's Socks are laid a slice per frame behind it, as today, so the wait is the same as the Host's wait now), and
a Guest's wait for the join snapshot is before the Lobby too. The risk to settle in the build's first step: nothing of the
house may leak through the cover (a sound, a light, a toast): a test per leak.

**The other options** are in L1.

## The World pages (before the Lobby)

The Worlds are chosen on the title, not in the Lobby. This is the one thing the shape forces: a World cannot change under
Guests who are already in its house. It also removes the old drawer's work (Ready cleared on every change, Guests seeing
every World the Host keeps, the "full" page over the Lobby).

- **Solo** opens the **Solo page**: the Solo World's row (name "Solo World", details) with **Continue** (hidden with no
  save) and **New Game** (asks "Start a new game? The saved game is lost." when a save exists, the old wording). Back goes to
  the title's home.
- **Host** (Multiplayer, Host) opens the **Worlds page**: the Solo World first, then the co-op Worlds newest first, each row
  a cream panel: the members' colour swatches, the name (`Worlds.row_name()`), a Continue key, a red Delete (co-op Worlds
  only), and the details under it (`floor · played · last`). A damaged World shows "Damaged World" with only Delete. A
  **New Game** key under the rows takes the first free co-op slot; with all five used it opens the **full page** (the old
  wording: "All 5 co-op Worlds are used: delete one first", the rows with Delete, Back); deleting one goes on with the New Game
  at once. The Solo World with every co-op slot used asks the same (it would become a co-op World when a Guest comes, Q1738).
  Delete asks first: "Delete <name>? It cannot be brought back." with a red Delete and Cancel.
- The page is a scene on the one Theme (`game/ui/worlds/worlds.tscn`, a row scene `world_row.tscn`); code fills the rows
  from `Worlds.rows()` and reacts to presses. Pad focus as every menu; Esc is Back.
- **Continue and New Game** call what exists (`Worlds.pick_*` split: `pick_slot(slot, new_game)` beside the two, the title's
  Solo and Host keys now open the pages instead). `--host` and `--new-game` on the command line keep acting at once.
- A co-op World keeps its members' names as its row name (what core/58 has); where it has none the name is "Co-op World n"
  (L7).

## Host and Guest flow

1. The Host: title, Multiplayer, Host, picks a World (Continue or New Game): the loading screen, then the Lobby with
   `LobbyState.title/line` filled from the World's record and `Worlds.row_details()`.
2. A Guest: title, Multiplayer, Join (name and address as core/58), the loading screen ("Joining..."), then the Lobby. The
   place fills on every machine when the Roster says so (`Roster.changed`).
3. Everyone presses Ready (a toggle; the key ticks); Start greys until every present player is Ready; the Host presses
   Start; the cover fades; everyone is in the house.
4. A Guest who comes later joins into play.

**What a Guest sees while the Host is in a menu** (P73, I02): in the Lobby the Host has no menu but Back, and a Guest's view
is the same model; once playing, a Host in the ESC menu is as today (nothing pauses, Q253).

**What a Guest sees when the Host leaves:** the Lobby closes and the title says "The Host ended the session" (existing).

## The screen

A scene on the one Theme, `game/lobby/lobby.tscn`, made of scenes (a scene per kind of thing, no UI built in code):

| Scene | Owns | From the old |
|---|---|---|
| `lobby.tscn` (`Lobby`) | the layout, the bar, the status line, the World card, the pad route | `LobbyScreen` |
| `lobby_stage.tscn` | a `SubViewport` with its own `World3D`, one camera, four pedestals, the Avatars | `LobbyStage` |
| `lobby_place.tscn` | one place's box, label (HOST mark, name, Ready mark, "Waiting for a player"), focus | `LobbyPlace` |
| `who_page.tscn` | the "Who was in <World>" page over the Lobby | the `who` page |

- **The stage** shows the Avatar scene of the game (`game/parts/avatar/`, its Looks scene, idling by its AnimationPlayer) on
  a pedestal, a free place a flat grey silhouette made by one shared material. The pedestal is a placeholder cylinder
  (a modelled one is an asset ticket, as the old). Numbers (camera, spacing, pedestal, figure box, dim, silhouette) are a typed
  Resource `LobbyTuning` (`lobby_tuning.tres`, every field `# placeholder:`), the old `lobby.json` values.
- **The places** are positioned from the stage's marks every frame, as the old (`unproject_position`).
- **Ready and Start** exactly as the list; the Ready key's tick is `UiSounds.hover()`; no countdown.
- **The i key and page** list `WorldRecord.members` names (the Group is gone; L7).
- The drawer and its slide, the sidebar's Pairs slider, the Wardrobe key and the stats card are not in the first build
  (L1, L3, L5).

## Real path and tests (for the build tickets)

A real-path case per ticket in two zoos-in-one-process machines (`tests/coop_join` style, 0 and 50 ms): the Host's
click on Continue on the Worlds page through to the Lobby with its card; a Guest's join shows a second place; the Guest's
Ready press is seen by the Host; the Host's Start press fades both covers and both bodies stand in the house with input
enabled; Ready from a Guest never writes another player's Ready (guard case). Leak cases: no house sound, no toast while
held. Look work (pedestals, marks, the card) gets stills, not tests (Q2421).

## What core/58's code is reused and what changes

Reused as it is: `Worlds` (`rows`, `delete`, `free_coop_slot`, `row_name`, `FULL`), `WorldRecord`, `WorldSlot`, `Save`,
`SceneChanger`, the loading screen and its fade, `KeycapStyle` and the Theme, `UiSounds`, the title's pages pattern, the
`Roster`, `Avatars`, `Session`, the ESC menu's End session and the "Host ended the session" notice, `PlayerProfile`.
Changes: the title's Solo and Host keys open pages instead of going in (`title.gd` loses the direct `solo()`/`host()`
calls, keeps `--host`); `Worlds` gains `pick_slot(slot, new_game)` and `row_details()` (the old `world_details`) and a
`display_name(slot, record)` for L7; `LevelRuntime` gains the `LobbyState` and `Lobby` nodes and `started` for the cover;
`Parts` one line for the held refusal; `Roster` nothing (its `changed` signal is enough). Not touched: any save code, the
file format (Ready is not saved; `WorldRecord` needs no new field).

## Tickets (in order, one mergeable piece each)

| # | Ticket | Holds | Blocked by |
|---|---|---|---|
| core/62 | World pages | The Solo page and the Worlds page: rows, Continue, New Game, Delete with its question, the full page, damaged rows, `--host` / `--new-game` kept; pad and Esc; a station in the zoo with the real `Worlds` data; real path: a click through to the house, a delete through to the file gone | L1, L2, L7 |
| core/63 | Lobby state and cover | `LobbyState` Part, the cover over the loaded house with a plain stand-in view (the names, Ready, Start, Back/Leave on one list), the hold (input, sound, toasts, Commands), Start's fade, leaving flows, the guards; real path: Host and Guest, Ready, Start | core/62, L1, L4 |
| core/64 | Lobby look | The stage with Avatars on pedestals, silhouettes, places, HOST and Ready marks, focus gold, the World card, the i page, `LobbyTuning`; stops at its first still for the designer's go | core/63 |
| core/65 | Lobby details | The pad route, the keys' captions and hints, the wording, the Ready tick, the narrower-than-16:9 camera, the name field's place (L4), the "Invite friends" hook (hidden until a transport says it can) | core/64 |
| later | Wardrobe and stats card | The Wardrobe key, page and colour row, the stats card; with the Wardrobe and Profile pieces | L3 |
| later | Steam lobby | The friends-only lobby of four, Invite friends, the published header, no Join by address | the M4 Steam piece |
| later | After an ending | What the Lobby offers after a finished World | the ending's piece, L6 |

Each build ticket is a build ticket: a real-path case, a station or the main scene, `kit/tools/run.sh --touched`. core/64 is
look work and stops at its first still.

## The choices for the designer

**L1 [blocking] The Lobby's shape and the World's choice.** The old Lobby had its own Session and a reconnect at Start; the
port's Session lives in the house.
- **(a, recommended) A screen over the loaded house**, the World chosen before on the title's World pages (above). Drops,
  by shape and only if you agree: the World settings drawer (its key, slide, "Pairs per Drawer", name field place moves,
  L4, L5), Ready cleared on a World change, a Guest seeing the Host's other Worlds, the "full" page over the Lobby (it moves to
  the World pages), "Joining..." between Start and play, "The game is starting: join again in a moment". Kept: the screen, the
  pedestals, Ready, Start, Back/Leave, the card, the i dialog, every key and number.
- (b) The old shape: a Lobby scene with a Session of its own, the World chosen on the drawer, the Guests reconnecting at Start.
  Keeps every old line as it was; costs a second Session mode, a second house build or a Part-less Session, and a reconnect
  that the old game never made reliable (a frozen Guest, a refusal window). About twice the work and the netcode risk.
- (c) No Lobby for co-op: the World pages, then straight into the house as today (Guests join live). Drops the pedestals,
  Ready, Start and the card, the Lobby's heart; only you may drop those.

**L2 [blocking] Does Solo go through the Lobby?** The old Solo had the Lobby screen with one place, Continue and New Game, and
the Wardrobe key.
- **(a, recommended) No: the Solo page is Continue / New Game, then the house.** One place and nothing to wait for; the
  Wardrobe, when it comes, opens from the title's Solo page or the ESC menu (its own question then, Q1749 said "only in the
  Lobby").
- (b) Yes, as the old: the Solo page, then the loaded house with the Lobby screen and one pedestal, then Start. One more click and
  a Lobby that waits for nobody; the Wardrobe has its place.

**L3 [blocking] The Wardrobe and the stats card.** Neither can be built now: there is no Wardrobe, no look in the Roster and no
Lifetime tallies in the Profile (they come with progression).
- **(a, recommended) Split out:** the first Lobby has Avatars in their colour, no Wardrobe key, no stats card; the lines are on the
  list as "(wardrobe)" and become a ticket with the Wardrobe piece.
- (b) The stats card now with the tallies the port can count (Pairs shelved, Coins earned), the other three at 0; costs a Profile
  that keeps tallies and a line from the Parts to it that the Wardrobe piece may redo.
- (c) Both now: needs the Wardrobe built first; the Lobby waits for it.

**L4 [blocking] Where a player's name is typed.** Everyone is "Player" until the Lobby (Q2440). Today only the Join page has a field.
The old Host's field lived at the top of the drawer.
- **(a, recommended) One name field on the Multiplayer page,** above Host and Join, used by both (kept in the profile).
- (b) A field on the Lobby screen, under the own pedestal; a Guest's name is also set at Join as today.
- (c) Join page only (the Host stays "Player").

**L5 [blocking] "Pairs per Drawer", the New Game size slider (1 to 25).** The port has no Stage Pairs yet to scale (Stages come in M4).
- **(a, recommended) Wait for the Stages piece:** the New Game keys show no slider now; the line stays on the list for it (the
  old digests disagree whether it showed in every build, Q1659/Q1665, or only in debug, progression/15: asked then).
- (b) Port it now: a slider on the New Game question, a number in `WorldRecord`, unused until Stages.

**L6 [later] What the Lobby offers after an ending.** The ending is not ported. The old game never decided: a finished World, or
only New Game, or a note on the World's row; and whether a player may keep tidying. Recommended: decide with the ending's piece; the
World pages leave room for a "Finished" mark on a row.

**L7 [blocking] A World's name.** The old row said its Group's names ("Ada, Mia", "No Group yet") and the World card "Co-op World 1":
two names for one World. core/58's `row_name()` gives the members' names.
- **(a, recommended) One name everywhere: the members' names; "Co-op World n" while there are none.** The "i" key still lists who played
  it, with their colours dropped (Q1771); shown when the World has members, as the old.
- (b) The old two names (row: names; card: "Co-op World n").
- (c) Worlds get a name the Host can type (a new field and a rename; a new feature the old never had).
