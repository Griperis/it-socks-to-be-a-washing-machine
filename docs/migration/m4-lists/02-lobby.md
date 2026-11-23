> Draft behaviour list for M4's second piece, the Lobby (core/61), written from the reference on 2026-11-23; for the
> designer to approve. The proposal built on it: `docs/architecture/lobby.md` (choices L1-L7 there).

# M4 piece: the Lobby

Draft behaviour list (catalogue B61 Lobby, B62 Worlds and Groups as the Lobby shows them, B23 and P36 what the Lobby
offers after an ending, P73 leftovers, P40 and P75 Steam's part). Refs are in the old game (`reference/it-socks/`,
tag v0.1.1) unless they start with `port:`. Short forms: L = `game/lobby/lobby_screen.gd`, P = `game/lobby/lobby_place.gd`,
S = `game/lobby/lobby_sidebar.gd`, ST = `game/lobby/lobby_stage.gd`, C = `game/lobby/lobby_stats_card.gd`,
R = `game/lobby/lobby_ready.gd`, N = `game/net/lobby.gd`, TS = `game/ui/title_screen.gd`, W = `game/core/worlds.gd`,
TU = `data/tuning/lobby.json`, I05..I08 = `docs/llm/lobby/issues/05..08`. Every number under TU is a placeholder in
the old game too.
"(wardrobe)" marks a line that needs the Wardrobe or the Profile's Lifetime tallies (not in the port yet, see the
proposal's L3); "(steam)" a line of the Steam piece; "(ending)" a line of the ending's piece.
The old Lobby was a scene of its own with its own Session beside it, loaded before the house (N:1-34); the lines say
what the player sees, not that shape; where the proposal changes how a line comes about, it says so (proposal "The
shape").

## Behaviour list

### The screen and its backdrop
- When the Lobby shows, then it is a menu screen on the title's dark backdrop (`#2b211c`, the loading screen's BACK),
  with one 3D view of pedestals behind its keys; no room, no house in sight. (ref: L:130-134; N:1-6; Q1756, Q1767)
- When the Lobby shows, then it is laid out in 48 px margins: the World card at the top, the 3D view in the middle
  (the pedestals), a status line (accent, 24 px, centred) over a bottom bar, 24 px apart. (ref: L:143-164)
- When the Lobby shows, then the mouse is free and visible. (ref: N:92)
- When the Lobby shows, then no music plays and no sound plays of its own except the Ready tick and the menus' click
  and hover. (ref: grep of `Music` in game/lobby, game/net/lobby.gd)
- When the screen is narrower than 16:9, then the camera keeps the width it sees on a 16:9 screen, so the whole row of
  pedestals stays in (the figures get smaller); on 16:9 or wider it keeps the height. (ref: ST:396-402)
- When any key of the Lobby is pressed, then the menus' click plays, and the hover tick when the mouse comes over one;
  the Ready key is the exception (below). (ref: L:313; Q336)

### The World card and the i dialog
- When the Lobby shows, then the World card sits in the top middle: a cream panel with the World's name (40 px) and a
  line under it (24 px); the line is hidden when empty. (ref: L:195-224, L:418-420; Q1757)
- When the Lobby is co-op, then the card's title is the World's name ("Co-op World n", or what the World's row says) and
  its line is where the team was: floor, play time, last played; for a New Game "New World" and an empty line. (ref:
  N:162-207; I05)
- When the Lobby is Solo, then the card's title reads "Solo" and its line "Solo World · <floor> · played ... · last
  ...". (ref: N:38, N:194-207; I06)
- When a World has people to list (the Group in the old game), then an orange "i" keycap (56 px) sits beside the card;
  the card stays centred (an invisible balance of the same width on the other side). A World with nobody to list has no
  "i". (ref: L:225-231, L:421-423; Q1771)
- When "i" is pressed, then a cream page lies over the Lobby (which stays on show behind it, veiled at 0.8): the heading
  "Who was in <World name>", one centred name per line (28 px, names only, no colours because a colour can change),
  and the ESC-style "Close" keycap at the left; Esc or the pad's B closes it. (ref: L:613-621; Q1771)
- When the Host chose another World, then the card and the i dialog follow at once, on every machine. (ref: N:546-554)

### The places (pedestals)
- When the Lobby is co-op, then there are four places in a row, centred, 2.1 m apart; in Solo one, in the middle.
  (ref: L:424-437; ST:405-430; TU:spacing; Q1758, Q1754)
- When a place has a player, then their Avatar stands on its pedestal, in their Player colour and Wardrobe look,
  idling as an Avatar does, with a sample of their Trail under the feet (wardrobe). The Avatar has no name tag: the
  name is under the pedestal. (ref: P:184-201; ST:433-435; Q1767, Q1768)
- When a player is shown, then under the pedestal, 10 px below, one row is centred: the HOST mark (gold, 20 px, only
  the Host's), the name (34 px, in the player's colour) and, in co-op only, the Ready mark. (ref: P:236-237,
  P:203-212; Q1757, Q1770)
- When a player is Ready, then the mark is a gold disc (34 px, ink ring 3 px) with a tick; when not, an empty cream-shade
  ring with a dash; icon only, no words. (ref: P:105-113, P:209-212; Q1770)
- When a place is free, then its pedestal is dimmed toward the backdrop (45 % of the way), a flat grey silhouette of the
  bare creature stands on it (35 % of the way from the backdrop to grey, unshaded, one shared material) and the label
  reads "Waiting for a player" (24 px, thin); the silhouette idles as an Avatar does. A free place takes neither mouse
  nor pad focus. (ref: P:149-179; ST:437-451; TU:free_dim, silhouette_show; Q1772)
- When a player joins or leaves, then their place fills or empties on every machine at once, with no sound and no
  toast; someone who stays keeps their Avatar (it is redressed or recoloured only when that changed). (ref: N:759-769;
  P:184-201)
- When the mouse is over a figure's box (head to base, 1.3 m wide), or the pad's selection is on it, then that place is
  focused: its pedestal turns gold and the stats card shows (wardrobe, below). Focus leaves when the mouse does, and
  while a page lies over the Lobby. (ref: P:131-134, P:218-222; L:496-511; ST:352-353; Q1769; I06 follow-up "which mark")
- When a place is shown, then its box and label follow where the figure falls on the screen, every frame (the camera
  10 m away, 1.5 m up, looking at 1.1, 30 degrees; figure 1.9 m high). (ref: L:470-493; ST:471-479; TU)
- When an Avatar is clicked, then nothing happens (the own one does not open the Wardrobe). (ref: I06 follow-up)
- When the place shown is this machine's own, then nothing marks it except the Wardrobe key beside the head (wardrobe).
  (ref: I06 follow-up)

### The stats card and the Wardrobe key (wardrobe)
- When a place is focused, then a cream card (280 px wide) shows beside the figure at 20 % of its height, on its right
  or, where the right would leave the screen (48 px margin), on its left: the name (28 px) and five Lifetime tallies,
  22 px, caption left and number right with thousands apart: Pairs, Coins, Collections, Floors, Games. It never takes the
  mouse. (ref: C:480-549; L:475-493; P:28-30, P:116-123; Q1769)
- When this machine's own place is focused, then the card also clears the Wardrobe key. (ref: L:488-490)
- When a Guest's tallies are shown, then they are what the Guest told the Host when it entered the Lobby (clamped: only
  the five tallies, each a finite count from 0 to 999,999,999, anything else reads 0), and the Host tells everyone.
  (ref: R:334-341; N:380-389, N:751-756, N:346-353; Q1757)
- When the Lobby shows this machine's own player, then a Wardrobe key (84 px, orange keycap, hanger icon, tooltip
  "Wardrobe") floats beside the own Avatar's head, at 82 % of the figure's width; no other player's. (ref: L:172-180,
  L:481-484; Q1773)
- When the Wardrobe key is pressed, then the Wardrobe's page opens over the Lobby (the Lobby's keys rest and a clear
  blocker takes the mouse); opening it clears this player's Ready; closing it shows the new look to the others. (ref:
  N:681-699; L:61-68; Q1759, Q1764)
- When a player dresses, then the look is kept in the Profile and shown on their own place at once. (ref: N:701-705)
- When the Wardrobe has a colour row, then the player picks a Player colour there: Solo at once, in co-op the Host checks
  no one else has it. (ref: N:708-731; Q343)
- When the Solo page shows, then it has no Wardrobe key before the Lobby: players dress only in the Lobby. (ref: Q1661,
  Q1749)

### Ready, Start and leaving
- When the Lobby is co-op, then the bottom bar reads, left to right: Back (the ESC keycap, 240 px, left), then in the
  middle Ready (300 px) and the Host's Start (300 px, orange, play icon); a Guest sees "Waiting for the Host to start"
  (24 px, thin, as tall as a key) in Start's place. (ref: L:298-344; Q1755, Q1762, Q1765)
- When Ready is pressed, then it toggles this player's Ready; the key reads "Ready" or "✓ Ready"; the caption under it
  "press again to un-ready" shows only while Ready (it keeps its line, so nothing jumps); the key ticks (the hover tick)
  instead of clicking. The Host's machine keeps the rule; a Guest asks. (ref: L:311-316, L:448-450; N:361-377; Q1760,
  Q1762)
- When not everyone is Ready, then Start is greyed with the caption "when everyone is Ready"; when everyone is, the caption
  hides and Start is pressable. (ref: L:318-323, L:451-453; R:306-318; Q1755)
- When Start is pressed with everyone Ready, then the game starts for everyone at once: no countdown, no room (the 5 s
  countdown, the ready rug and the zones are gone); the Lobby's keys lock, the sidebar goes, and the World loads, behind the
  loading screen. A second Start does nothing. (ref: N:425-466; L:572-579; R:321-326; Q1655, Q1761)
- When a Guest hears "go", then it shows the loading card "Joining..." and follows once the Host listens again from the
  World. (ref: N:411-418; I05 follow-up)
- When anyone leaves the Lobby, then they are forgotten as Ready; when someone comes, they are not Ready; a Host alone is
  never able to start (nobody in the Lobby counts as not Ready). (ref: R:299-313; N:335-340)
- When the Host changes the World or a New Game's size, then everyone's Ready is cleared (they readied for another
  World). (ref: N:546-566; R:290-297)
- When the Wardrobe opens, then this player's Ready is cleared; dressing is not Ready. (ref: N:364, N:687-691; Q1764)
- When the Host presses Back, then the Lobby closes for everyone: every Guest goes to its title with "The Host ended the
  session" (Q250), the Host to its title with no notice; a Guest's Back reads "Leave" and only that Guest leaves. (ref:
  N:646-676, L:446; Q1765, Q250)
- When the Host closes the game window in the Lobby, then it closes the Lobby for everyone as Back does. (ref: N:674-676;
  Q250)
- When Esc or the pad's B is pressed on the Lobby, then it does Back (Leave); on a page it does that page's Back; while
  the Wardrobe or the loading is on, nothing. (ref: L:707-717)
- When the Host cannot remove a player, then that stays so for now (later with Steam lobbies). (ref: Q1763)
- When the pad is used, then the route is: the "i" key and the World settings key; the figures left to right (the
  Wardrobe key after the own one); the bottom keys; Right of the last figure goes into the drawer. The first selection is
  the "i" key when there is one, else Back. (ref: L:514-569; I06 follow-up)

### The World settings drawer (co-op)
- When the Lobby is co-op, then a "World settings" keycap sits in the top right corner (48 px in); it opens and shuts a
  drawer, a cream panel 520 px wide, from the right edge over the Lobby, which keeps its layout; the drawer's inside
  takes the clicks. (ref: L:234-258; TU:sidebar_width; I08; designer 2026-11-12)
- When the drawer opens or shuts, then it slides 0.25 s with a cubic ease-out (from where it is, so a reversal is
  smooth); it starts open for the Host and shut for a Guest. (ref: L:260-290, L:410-413; TU:slide_time)
- When the drawer is open, then its heading is "World settings"; the Host's holds "Your name" (a field, 16 letters,
  placeholder "Player"; the name shows on every machine at once, kept in the Profile), then "World", the rows, a
  "New game" key, the "Pairs per Drawer: n" slider (1 to 25, only while New game is chosen), and "Invite friends"
  (steam; only when the transport can). (ref: S:55-115; N:569-579; Q1775, Q1659)
- When a World row shows, then it is a tinted panel (the chosen one gold at 0.4) with: a 14 px colour swatch for each
  Group member, the title (22 px, clipped with an ellipsis), the Host's "Choose" (reads "✓ Chosen" on the chosen one) and a
  red "Delete" (co-op Worlds only; the Solo World cannot be deleted), then the details under it (18 px: "Floor 2 ·
  played 5h 02m · last 2026-11-11 13:07"). A damaged World has only Delete. A Guest's drawer is the same list read-only
  with a tick on the chosen one; the Solo World and all co-op Worlds, the Solo World first, the co-op ones newest
  first. (ref: S:158-206; N:479-493; W:74-83; Q1647, Q1739)
- When the Host picks a World, then the card, the i dialog, the Ready and the rows follow; the Solo World with every
  co-op slot used asks to delete one first (a Guest would make it a co-op World). (ref: N:500-512; Q1738)
- When the Host picks New game, then a New Game in the first free co-op slot is chosen; with all five used the "full"
  page asks to delete one first. (ref: N:516-524; Q1650)
- When the "full" page shows, then it lies over the Lobby: heading "New game", the line "All 5 co-op Worlds are used:
  delete one first", each co-op World's row (name, details, Delete) and Back; deleting one goes on with the New Game
  (or the Solo World) at once. (ref: L:622-659; N:594-615; W:14)
- When Delete is pressed, then a page asks first: heading "Delete World", "Delete <name>? It cannot be brought back.", a red
  Delete and Cancel (back to the Lobby, or the "full" page). Deleting the chosen World puts the Lobby on the last-played
  co-op World, else on a New Game. A New Game keeps to the first free slot. (ref: N:581-615; L:662-677; TS:52; Q1647)
- When the Pairs per Drawer slider moves, then every step clears Ready (only while New game is chosen); a Guest's slider is
  not editable. (ref: S:107-110, S:133-139; N:557-566)
- When a Guest's drawer shows Worlds, then it shows every World the Host keeps, with their Groups' names. (ref: I07
  follow-up; N:303-311)
- When the drawer is open over the Lobby, then it is not dimmed behind it and does not close on a click outside it
  (the old open question; Esc closes nothing). (ref: I08 follow-up; P73)

### Solo
- When Solo is pressed on the title, then the Lobby opens with one place (the player's), no Ready, no Start, no World
  settings; Back, Continue and New Game. (ref: TS:478-486; L:448-456; N:617-642; Q1643, Q1754)
- When the Solo World has a save, then Continue shows with the World card; with none Continue is hidden. Continue loads
  the Solo World where the player was. (ref: L:455; N:272-275, N:619-625; Q1753, Q1766)
- When New Game is pressed in Solo, then a page replaces the screen (it does not lie over the places): heading "New game",
  the "Pairs per Drawer" slider, Start and Back; Start asks "Start a new game? The saved game is lost." (heading "New
  game", key "New game", Cancel) before the Solo World is overwritten; with no save it starts at once. (ref: L:605-612;
  N:627-642; Q1659, Q1665)
- When a New Game starts, then it starts in the basement; a continued World keeps where each player was. (ref: Q1753)

### Worlds and Groups as the Lobby shows them
- When Worlds are kept, then there is one Solo World and five co-op Worlds, each its own file. (ref: W:9-14; Q1647)
- When the Solo World is played with a Guest, then it becomes a co-op World in a free slot and the Solo slot empties; a
  Host alone leaves it Solo. (ref: W:97-125; Q1646, Q1737)
- When a World's file will not read, then its row says "Damaged World", counts as used and may be deleted. (ref: W:20-60;
  Q1739)
- When a co-op World is first played, then its Group is who is in the Lobby; only Group members may join it later (the
  old lock). The port drops this: anyone may join a co-op World. (ref: W:97-125; Q1645, Q1652; dropped by Q2554)
- When the Host chooses a World, then a Guest outside its Group makes Start held with "<names> cannot play this World: not in
  its Group". Dropped with the Group (Q2554). (ref: N:44-46, N:291-300; I07)
- When a row names a co-op World, then it lists the Group's names ("Ada, Mia"), or "No Group yet"; the World card says
  "Co-op World n": two names for one World (the old open question). (ref: TS:452-462; N:174-175; I07)
- When the title's Host key is pressed, then it goes straight to the Lobby on the last-played co-op World that reads, or a
  New Game in a free slot (all damaged: the Solo World or a New Game there, as `--host` does). (ref: TS:491-507; Q1775)
- When two copies of the game run on one PC, then they share the Worlds folder (the old open question; the port keeps each
  profile's own Worlds, Q2566). (ref: I04 follow-up)

### What the Lobby offers after an ending (ending)
- When the final screen's Continue is pressed after the ending, then everyone goes back to the Lobby. (ref:
  `game/ui/ending_screen.gd`; Q1836)
- When a World is finished, then the old game left open what the Lobby offers: a finished World, or only New Game, or a
  note on the World's card; and whether a player may stay in a finished World and keep tidying ("Keep tidying" is gone).
  (ref: progression/85 follow-up; P36)

### Steam's part (steam)
- When the game runs on Steam, then the lobby is friends-only, exactly four, and the Host's drawer has "Invite friends";
  Join by address is hidden in Steam builds. (ref: P40, P75; `game/net/net_backend.gd:64-75`; Q1662-Q1664, Q1684)
- When the Host chooses a World, then the transport publishes its header to the Steam lobby. (ref: N:551;
  `net_backend.gd:75`)
- When Steam has no connecting page, then a joining Guest sees no Cancel or time-out (the old open question). (ref:
  multiplayer/12 follow-up)

### Words and refusals
- When a Guest tries to join between "go" and the World, then it is refused with "The game is starting: join again in a
  moment". (ref: `Session.STARTING`; I02 follow-up)
- When a join is refused, then the wording is the Session's: "Another version of the game", "The game is full (n players)",
  "You are already in this game" (port: `game/parts/session.gd:51-55`).
- When the Lobby's wording is shown, then it is the old placeholder wording: "World settings", "Your name", "World",
  "Choose", "✓ Chosen", "New game", "Delete", "Who was in %s", "Close", "Waiting for a player", "Waiting for the Host to start",
  "when everyone is Ready", "press again to un-ready", "Leave". (ref: L:44-53; S:22-33; P:23-27)

## What was weak in the old Lobby
- Two lobbies in one history: the room (greybox drawer, rug, countdown, practice Socks) was built, then thrown away; the
  screen that replaced it still carries its machinery: a Session of its own beside the real one, a "practice" Game that is
  never saved, and a house built out of sight and again for the World (N:1-34; I02: "the Lobby builds the whole house out of
  sight before the World loads it again"). A Guest then stood frozen with no message until the Host listened again.
- Hand-over by reconnect: at "go" the Guests wait for the Host to open its World and join again (N:411-423): a refusal
  window ("The game is starting") and a second join gate to keep right.
- The World chosen in the Lobby: every change clears everyone's Ready, a Guest sees every World the Host keeps, and the
  drawer's states (open or shut, dim, close on outside click) were never settled (I07, I08).
- One World with two names ("Ada, Mia" on its row, "Co-op World 1" on its card); the first Solo game has no "i" key; the
  Solo World with a full set of slots asked to delete one even for a Host alone.
- The Wardrobe's page lies over the Lobby with no veil, so Ready and Start look pressable (I05 review); the stats card
  covers the neighbour's pedestal; at 1280 x 720 the tallies and captions are about 13 px high; a yellow player's name sits
  in gold beside the gold Ready mark (I05).
- Placeholders never settled: the pedestal (a plain cylinder) and its gold focus, the Ready mark's colour and shape, the
  HOST mark, the "i" key's look, the hanger icon, every number in TU.
- Leave and Back return to the title's main menu, not to the Multiplayer page they came from; a dev Guest launched with
  `--join=` who presses Leave joins again at once.
