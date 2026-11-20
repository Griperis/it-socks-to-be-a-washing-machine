# Digest: core loop and co-op (physics, multiplayer, lobby, knockdown, mvp)

Sources: docs/llm/physics, multiplayer, lobby, knockdown, mvp. Words follow GLOSSARY.md.
Order of this file (sections appear in this order): A. MVP loop (origin of the core loop), B. Knockdown, Drag, Wash, E. Lobby, Worlds and menus, D. Co-op (multiplayer), C. Physics (SockWorld, Hands drop and Throw, core-loop numbers), F. further decisions, Process lessons, Coverage.
Marker: `decided` = designer answer; `placeholder` = number the designer has not tuned; `built` = from a Built log.

---------------------------------------------------------------------
## A. The first playable (mvp/) and the core loop it set

**What it is.** The first build (2026-10-28): a grey-box room, Socks in a Mess, Hands, Pairs, Cabinets, an Upgrade station, autosave, an ending. Most of its numbers and looks were superseded by flat/ and house/ tickets (not in my folders). Its tickets carry few designer answers: the loop is the lasting part.

**Rules that bind (the loop, as the spec states it; later glossary wording wins where it differs)**
- Loop: walk, look, jump, crouch; aim at a Sock in the Mess; left click picks it up into the Hands; a second Sock of the same Design fuses into a Pair at once in the Hands; Pairs go to the Cabinet of their Collection; shelving pays Coins; Coins buy Upgrades at the Upgrade station. (mvp spec, 2026-10-28)
- Left click on a Sock: pairs with a matching loose Sock in the Hands; otherwise goes to a free place; otherwise it is refused and stays in the Mess (this is how "reject the second pick at once" reads at capacity 1). (mvp/04)
- Carry capacity starts at 1; a held Sock plus its mate fuses into one Pair, so a Pair still fits. (mvp spec, GLOSSARY)
- Right click drops the most recently picked item at the aimed ground position (the later `Hands` glossary rule: the active item, on release, with refusal where it cannot land). (mvp/04; superseded in detail by physics/35)
- A Cabinet takes only Pairs of its Collection, filling drawers bottom up; it refuses other Collections' Pairs without saying which Cabinet is right; a mixed hand shelves what fits; the drawer a Pair goes into slides open; an empty-handed click opens or closes a drawer. (mvp/11, mvp spec)
- Open drawers stay open until clicked (built); the designer may want them to close by themselves: open follow-up, never answered in this folder. (mvp/11)
- Drawer capacity is 25 Pairs per drawer (not the MVP's 10). (mvp/11 Answers; flat spec, GLOSSARY Drawer)
- Held Pair look: a sock ball in the Hands, on the floor and in Drawers. (Q59, Q60, Q92; mvp/04, mvp/14)
- Drop aimed at a wall, ceiling or Station: landed on the surface under the aim within about 1 m. (flat/32; mvp/04) Superseded by the later drop rules (physics/35: refused with a red crosshair if it cannot land).
- Cloth feel of held and dropped Socks: heavy, damped droop, settling in under 0.5 s. (Q53; mvp/14)
- Held layout: active item big and centred-right, others smaller lower-left. (Q61-Q64; mvp/14)
- Menus never pause the game; the player's own body freezes while a menu is open. (Q253; mvp/06)
- Sprint: bought once at the Upgrade station, hold Shift; before it is bought Shift does nothing; crouching cancels sprint (built: 1.6x, placeholder). (mvp/10, GLOSSARY Upgrade)
- Crouch: hold Ctrl, lowers the eyes, halves walk speed, no jumping, stays on while something is overhead (built, 2026-10-28; the later house may differ: unchecked). Jump is Space. E interacts; Esc frees the mouse. (mvp/01 built)
- New Game command is on the main menu's Play. (Q338, flat/46; mvp/07)
- Volume: Options has a volume per bus, kept per machine. (flat/46; mvp/08)
- Sound source: generated in code first, later CC0 clips and richer synth on the sound bench. (Q156, flat/22; mvp/08)
- Lighting: tonemapping, AO, shadows, glow and fabric sheen. (Q150, flat/19; mvp/12)
- Real doors in the house's rooms (the bedroom's door need not open). (Q401; mvp/12)

**Numbers (all placeholders from mvp built logs, long since moved to data/tuning.json and the balance round Q477, questions/06)**: carry capacity +1 per level, 5 levels; speed +10% and shorter pick cooldown per level, 8 levels; sprint 1.6x; payout 10 x Rarity multiplier 1/2/5 plus a 100-Coin Collection bonus; MVP drawers 10 Pairs (now 25). Rarity tiers 60/28/12% (MVP catalogue). (mvp/02, 05, 06, 10, 11)

**Decided against / superseded**
- A separate Pairing spot: dropped, pairing happens in the Hands. (mvp/01 design change, 2026-10-28)
- Per-Collection Drawers and a 20-Pair split: dropped, then replaced by four Cabinets. (mvp/05, mvp/11)
- Sock model L-bend with cuff slit, party sock, heel patch: superseded by flat/03, flat/44 (real Sock shapes, Q325), eight Collections (Q54-Q58, Q81-Q96, Q163).
- Mate distance curve, payout and bonus numbers, rarity tiers, upgrade prices: moved to the balance round (Q477, questions/06). Not decided in my folders.

**Open (verbatim)**
- mvp/06: "All prices, steps and level caps are placeholders in data/tuning.json: [[02-numbers-and-curves]]. *(upgrades batch, Q485: stays open)*"
- mvp/07: "Which stats the ending should show (placeholder: Pairs, time, Coins earned, Upgrade levels)."
- mvp/10: "Whether sprinting should also affect the grab cooldown (currently it doesn't). *(upgrades batch, Q485: stays open)*"
- mvp/11: "Open drawers stay open until clicked; the designer may want them to close by themselves." and "A full Cabinet can't happen (drawers cover the whole Collection); decide what the designer wants if Designs are added later."
- mvp/12: "The washing machine's door and dial could animate with the Upgrade menu: not built."
- mvp spec decisions still open: numbers and curves, rare-found-later, MVP collections (answered by later specs).

**Switched off / dropped**: Wardrobe/Winter/Sport/Party four-Cabinet bedroom (replaced by the house); the bedroom's washing machine as Upgrade station (now the Old Tree).

---------------------------------------------------------------------
## B. Knockdown, Drag and Wash (knockdown/)

**What it is.** A full-charge Throw that hits a Teammate knocks them down as a ragdoll; others may drag them by the feet and put them into the basement washing machine.

**Rules that bind**
- To drag someone you need empty Hands. Hold the left button on a knocked-down Avatar to grab them by the feet and walk; they slide behind you. Let go to drop them. (Q753)
- The knockdown timer keeps running while dragged; they slip out of the grip when they get up. (Q754)
- The dragged player can mash a key to struggle out sooner. (Q757) Struggling free ends the knockdown: the player gets up at once and cannot be grabbed again while they do. (Q986, 2026-11-05)
- The knockdown lasts 5.5 s (`knockdown.seconds`), the middle of the recommended 5-6 s. (Q985, 2026-11-05) The spec's Q757 said "keeps today's length".
- Knocked-down Avatars are full physical ragdolls: physics bones on the existing skeleton, replacing the scripted topple and slump. The body flops the way the hit pushed it, trails limply when dragged. The Host simulates it; guests get the pose synced. (Q756)
- Ragdoll collides with walls, furniture, teammates (built: layer `LAYER_MATE`); the knocked player's view rides the ragdoll's head, short of walls; getting up happens where the feet lie after a blend back up. (knockdown/01 acceptance, built)
- One dragger per player. The dragger walks slower; the drag breaks if the two get too far apart (stairs). (knockdown/02)
- A dragger can pull the dragged player into the Elevator car; both ride and the drag holds. (designer, 2026-11-05; built in house/35, Q836, Q984: merge drag without it)
- Releasing a dragged player near the open door of the basement washing machine slides them in. The door shuts; a blob in their Player colour spins in the drum while their camera spins. After about 3 s the door bursts open, they tumble out knocked down for a moment, then get up. (Q755)
- Only the basement laundry's washing machine washes, one player at a time. While it is busy a dropped player just lands at its door, silently. (Q758; silence recommended, not confirmed)
- The rogue-machine sequence ends every knockdown, drag and wash; everyone respawns. (Q759)
- Wash fade: fade from the spinning view back into play (the shared fade). (Q817, 2026-11-04)
- The washed player's HUD (crosshair, key hints) is hidden in the drum and returns when they come out. (Q991, 2026-11-05)
- The wash was accepted after review. (Q990)
- Sounds are placeholder synth sounds: a drag scrape, the door slam, drum sloshing. (Q760)
- Left click in reach: a knocked-down body wins the left click over a Sock or Station under the crosshair (built; "Keep that?" asked, not answered). (knockdown/02 open)
- Any thrown item at full charge knocks a teammate down: besides Socks, Pairs and the lantern, also the Radio, the Beeper (Sock detector), the Guide card and the Cat. Bins, the Hamper and Parts stay unthrowable. (Q1935, 2026-11-18)
- A weaker Throw of the Radio, Beeper, Guide card or Cat that hits a teammate bounces off and drops at their feet: no knockdown, no catch. (Q1936, 2026-11-18)
- Exemptions (built, knockdown/04): thrower, someone already down, someone in the drum, Elevator riders.

**Numbers**
- Knockdown 5.5 s: decided (Q985). Key `knockdown.seconds`.
- Struggle key Space, 10 presses (`drag.struggle_presses`): placeholder; Space chosen as built; no count shown.
- Drag: dragger walks at 0.6 of pace; feet held 0.4 m up, 0.6 m behind, spring 60; breaks when feet 2 m from hold; scrape every 0.5 m: placeholders (`drag`).
- Wash: 3 s in drum, drum turns 1.2/s, slide in 0.35 s, door opens 1 s after burst, 2 s knocked down after (last 0.6 s getting up), flung head first at 2.5 m/s out and 1.5 m/s up, fade out last 0.4 s, back in 0.6 s, door reach 1.5 m: placeholders (`wash`; `wash.door_reach`). (Q755 gave only "about 3 s")
- Ragdoll: `push_speed` 3 m/s, `spin` 3 rad/s, `joint_bend` 45 deg, `rise_time` 0.6 s: placeholders (`knockdown`).
- Guest sees ragdoll at the pose rate of 20 per second, smoothed (built).

**Decided against**: scripted topple/slump/bounce (removed). Q759 / Q758: no queueing in a busy machine.

**Open (verbatim, all `[later]` unless noted)**
- knockdown/01: "Ragdoll numbers. The new `knockdown` keys are placeholders ... Which want changing?"; "Getting up. It stands where its feet lie, facing the way the player faced before the hit. Should it rather face along the way it lay?"; "A wall right in front. ... Keep that, or should it always slump into the wall?"; "The knocked player's view. It rides the ragdoll's head and keeps the look's pitch from before the hit. Should it rather lock to the head?"; "Guests' smoothing. ... Good enough, or a higher rate for lying bodies?"
- knockdown/02 [later]: "The struggle key is Space ... Recommendation: keep Space and show the presses left in the hint"; "Feel numbers ... Which want changing?"; "A guest dragging sees the body follow at the pose rate ... Good enough, or should the guest's view pull a local copy?"; "The left click's order. A knocked-down body in reach wins the left click ... Keep that?"
- knockdown/03 [later]: "Near the door ... within 1.5 m ... keep it so"; feel numbers; "The blob is one squashed ball ... keep it plain"; "Washed again at once ... Recommendation: allow it (it is funny)"; "The rogue sequence during a wash keeps the washed player in the drum ... Recommendation: keep."; "A busy machine says nothing ... keep it silent."
- knockdown/04 [later]: "What the Cat does after knocking someone down (it lands as a thrown Cat lands today unless the designer says otherwise)."

**Switched off / dropped**: none.

---------------------------------------------------------------------
## E. Lobby, Worlds, Groups and the menus (lobby/)

Checked: `game/ui/title_screen.gd` builds Solo / Multiplayer / Options / Quit; Multiplayer holds Host / Join; Host goes straight to the Lobby; `data/tuning/lobby.json` holds the pedestal view and the drawer slide time. So lobby/01-08 as amended below holds. GLOSSARY's **Play** entry ("Continue, New Game, Wardrobe") is stale against lobby/05.

**What it is.** Every game, Solo and co-op, starts on the Lobby screen (a menu screen on the title's backdrop, not a room). The Host chooses the World; players dress, Ready, the Host starts.

### Worlds, Group, saves
- A World is one saved game: the Solo World (one file) or one of the Host's co-op Worlds, kept newest first, at most 5 slots; each shows Group (names, colours), floor reached, play time, last played; deleted by hand with a confirm. (Q1647)
- A co-op World's Group is whoever is in the Lobby at that World's first Play; no seats, no adding later; only Group members may join it. (Q1645)
- The Solo World stays solo until a Play with at least one Guest in the Lobby; a Host or Solo Play alone keeps it the Solo World (changes the literal reading of Q1646). (Q1737, 2026-11-11) Taken into co-op, it becomes that Group's World and leaves the Solo slot empty. (Q1646)
- Solo into co-op with all 5 slots used: same rule and wording as a New Game: "All 5 co-op Worlds are used: delete one first" (`Worlds.SLOTS_FULL`), with the delete and confirm. (Q1738)
- All 5 slots used: New Game asks the Host to delete one first, with a confirm. (Q1650)
- A World whose header cannot be read shows "Damaged World", counts as used, can be deleted with the confirm; a World of another version shows as an empty slot (no migration). (Q1739)
- The Host may play a co-op World with Group members absent; they rejoin any time, their Coins, Upgrades and spot wait. (Q1648)
- A Group member joining a World in play skips the Lobby and lands beside a teammate. (Q1649) A Guest outside the Group is refused at join with a clear message. (Q1652)
- A Guest who leaves, crashes or times out drops their held items where they last stood. (Q1656)
- The Host quitting or crashing sends everyone back to the title with "<Host> ended the session". (Q1657)
- A Group stores text player keys (`steam:<id>` / `local:<id>`) with a small per-World id inside the World. (Q1677) Worlds stay in their build: Steam Worlds join through Steam, address Worlds by address; the Solo World works in both. (Q1678) Steam Cloud will sync the Profile and Worlds; keep World files small and self-contained. (Q1684)
- In Steam builds the Steam account is the player: id = Steam id, name = Steam name; a Group remembers Steam ids. (Q1664) Steam sits beside Join by address; address join stays for non-Steam builds, LAN, tests. (Q1662) The Steam peer is multiplayer/12 (the first round only put every Steam hook behind one seam, `NetBackend`). (Q1663)
- Autosave: every 2 s while anything changed, and on quit, for whichever World is played. (pitch 2026-11-11)
- Cosmetics and player-wide unlocks stay per player (the Profile).
- Two copies of the game on one PC share user://, so both loaded the same `profile.json` and were the same player (cause of "The host could not read your join"). Fix: `ProfileLock`; a second copy takes `profile_2.json`; the Host refuses a duplicate key with "That player is already in this game". (designer via coordinator, 2026-11-12; lobby/04)

### The Lobby screen (supersedes the greybox "sock drawer" room of lobby/02)
- The Lobby is a menu screen on the title screen's backdrop: the players' avatars side by side. Behind it: the title backdrop. (Q1756, Q1767) The room's extras all go: practice Socks and Cabinet, throw targets and hoop, the ready rug. (Q1760) **Reverses** Q1651 (greybox giant sock drawer), Q1654 (ready zone), Q1743 (shared rug), Q1744 (countdown tick), Q1653/Q1660 (5-second countdown) and Q1655 (practice kit).
- Co-op: always 4 places; free ones dimmed with a grey silhouette and "Waiting for a player". (Q1758, Q1772)
- Avatars stand in world space on placeholder pedestals (plain shapes; a modelled pedestal later); one 3D view; Solo shows one in the middle. (Q1768; lobby/06 acceptance)
- Under each avatar: the name in the player's colour, with a checkmark or a not-ready icon next to it, icon only, no text. (Q1770) A Host mark (placeholder: gold "HOST"). (Q1757)
- Lifetime tallies show in a card beside an avatar only while it is focused: mouse hover or the pad's selection; hides when focus leaves. (Q1769)
- A Wardrobe button floats beside your own avatar's head (only yours). (Q1773) It opens today's Wardrobe page over the screen. (Q1759) Opening the Wardrobe clears that player's Ready. (Q1764) Players dress only at the Lobby (no pre-join Colour & Wardrobe page; no Wardrobe button on the Solo page). (Q1661, Q1749)
- World card at the top with an "i" button; the "i" dialog lists everyone in the World's Group **by name only, no colours: a player's colour can change**. (Q1771)
- Ready toggles; pressing again un-readies; Start greys out again. (Q1762) The Host can press Start only when everyone is Ready. (Q1755) Start loads the World at once, no countdown. (Q1761) The Ready key plays the menus' hover tick. (Q1760)
- A Guest's bottom-left button says "Leave"; the Host's says "Back" and closes the Lobby (Guests go to the title with "The host ended the session"). (Q1765)
- The Host cannot remove a player for now (later, with Steam lobbies). (Q1763)
- Solo: the same style with only the player's own avatar, showing Continue or New Game (and the Wardrobe icon). (Q1754) Solo with no Solo World yet: Continue is hidden. (Q1766) Solo's New Game opens the Pairs-per-Drawer page and asks "Start a new game? The saved game is lost." before overwriting a Solo World.
- A New Game starts in the basement; a continued World keeps where the team was (each player where they quit). (Q1753)
- A New Game is sized by the players in the Lobby when Start is pressed; today that only decides the high-Socks share (2+ players); `mess.pairs_by_players` is the same for 1-4. (Q1750)
- Lobby review build: none; the designer plays the main build. (Q1751) The Lobby never touches a save; a Lobby of its own loaded before the World. (Q1642, Q1643, Q1644)

### Menus and the World settings sidebar
- Main menu: Solo · Multiplayer · Options · Quit (lobby/04, 2026-11-12). Multiplayer opens Host, Join, Back. Encyclopedia and Licence keys stay in the corner. Supersedes Q1658's "Solo · Host · Join · Options · Quit" (the designer later asked for one Multiplayer entry). Built.
- Host goes straight to the Lobby (2 clicks) on the last-played co-op World, or a New Game in a free slot when none. (lobby/07; Q1775 "cuts to the steps", narrowed by the designer 2026-11-12: "Only the World settings move, for multiplayer: choosing the save and the difficulty for a New Game, in a collapsible sidebar on the right of the Lobby; the Host sets them and the others can see them")
- Sidebar ("World settings"): the Solo World, co-op Worlds newest first, New game with the "Pairs per Drawer" slider (only while New game is chosen); Delete asks first; all 5 used asks to delete one first. Guests see it read-only; a change reaches them. Changing the World or the difficulty clears everyone's Ready. (lobby/07)
- The sidebar is an overlay drawer sliding in from the right, over the screen; it does not push the other content. (designer, 2026-11-12; lobby/08) Input under it does not reach covered keys (mouse only; the pad can still focus them).
- New Game's size is the "Pairs per Drawer" slider (1 to the full Drawer), not a player count; on New Game in every build, styled with the menus' shared Theme. (Q1659, Q1665)
- Join page: name and address. No connecting page with Cancel or timeout yet.

### Numbers (all placeholders unless noted)
- Pedestal view (`data/tuning/lobby.json`): camera 10 m away, 1.5 m up, look height 1.1, fov 30; spacing 2.1 m; pedestal radius 0.75, height 0.3; figure box 1.9 x 1.3; free place dim 0.45, silhouette 0.35; sidebar width 520 px; slide time 0.25 s (`lobby.slide_time`).
- Slots: 5 co-op (decided). Players: 4 (decided).
- Countdown 5 s and ready rug (rug 3.6 x 2.0 m): dropped with the room.

### Decided against
- Hiding Stage progress, currency and sock balls in the Lobby HUD: dropped, the Lobby became a menu screen. (designer, 2026-11-12; lobby/04)
- Player count choice for a New Game. (Q1659)
- One "Play" button title: narrowed away, never built. (Q1775)

### Open (verbatim, `[later]` unless noted)
- lobby/01: "Wording of the refusal for a non-member (Q1652): placeholder 'This World belongs to its Group: you are not in it'"; "Wording of the refusal for another build: placeholder 'The host is playing another version of It Socks'"; "Which teammate a rejoining member lands beside (Q1649): placeholder the Host, 'players.spawn_apart' to their side, facing as they face."; "multiplayer/12: ... a Guest still plays as its Profile number; the Host must tell the Guest its id ... and `key_of_peer` must come from the transport."; "deep-review N6 (a Command the Host drops is never undone on the Guest) ... still its own fix."
- lobby/02 (room-era; most moot): "What Guests see while the Host is in a menu"; "What a Guest sees between 'go' and the World"; wording "Opening the sock drawer..."; load time of building the house in the Lobby (moot after lobby/05).
- lobby/03: Host page row wording (moot, moved to sidebar); "A joining Guest's colour: their last colour when free, else the next free one (Q276)"; "`--players=<n>` is gone"; Steam seam items: "accepting an invite while in a game rule is still to decide"; no connecting page with Cancel / time-out for Steam's async joins (multiplayer/12).
- lobby/04: "A second copy on one PC starts with a fresh Profile ('Player', the default look). Should it start from the first copy's name and look instead?"; "Two copies on one PC still share the Worlds folder and Options"; Multiplayer page heading and icons placeholder.
- lobby/05: places are cream panels (moot after 06); "The World's title is still lobby/03's placeholder name ('Co-op World 2', 'New World'); ... Worlds have no names of their own yet."; "The Host's Back and a Guest's Leave return to the title's main menu, not the Multiplayer or Host page they came from."; "The Wardrobe's page lies over the Lobby with no veil: ... Dim the screen behind it, as Solo's New Game page does?"; "At 1280x720 the tallies, the HOST mark and the key captions are about 13 px high"; "A player whose colour is the yellow one has a gold name beside the gold 'Ready'"; "With every co-op slot used and a Guest in a hosted Solo World, Start stays greyed ..."; the Wardrobe opens without the in-game open/close sounds.
- lobby/06: "The focus mark: the focused Avatar's pedestal turns gold (the wireframe draws a gold glow round the Avatar). Which is wanted?"; Ready mark colour (tick in gold disc; wireframe draws green); "The Host mark is still lobby/05's gold 'HOST' before the name (the wireframe's crown is a placeholder too). What should it be?"; "The names keep the player's colour (Q1757); the wireframe draws them in one ink colour."; "Your own place has no mark of its own any more ... Enough?"; the "i" key look (orange keycap vs round gold badge); dialog wording "Who was in <World>" / "Close"; "A World with nobody to list (a New Game, the first Solo game) has no 'i' key. Should it show and say something instead?"; World card wording (Solo's title "Solo" vs "Solo World"); "Clicking an Avatar does nothing"; "The pad's first selection is the 'i' key when there is one, else Back ... Should it start on Ready, or on your own Avatar?"; "A wide hat on your own Avatar ... can reach behind the Wardrobe button."; "Does Solo's World card need the i?"
- lobby/07: "Where should [the name field] go: there, the Wardrobe, or the Join page only?"; "The sidebar starts open for the Host and shut for a Guest (placeholder). Which is wanted for each?"; "The title's One Play button (Q1775) was not narrowed in: drop it, or a later ticket?"; "A Guest in the Lobby who is not in the chosen World's Group: Start is held and the Host reads '<name> cannot play this World: not in its Group' (placeholder rule and wording). ... Wanted: this, the Guest sent out, such a World not choosable, or the Guest refused at the World's door?"; "Guests see every World the Host keeps, with their Group's names. Wanted, or only the chosen one?"; sidebar words placeholders ("World settings", "Choose", "Chosen", "New game", "Delete"); "A World has two names on one screen ... One name for both?"; sidebar look placeholder; "The Solo World, all 5 co-op Worlds and New game fill a 1080p screen's height; the list does not scroll."; deleting the chosen World falls back to last-played co-op World else a New Game (placeholder); "Every step of the Pairs per Drawer slider clears everyone's Ready"; "Invite friends" moved to the sidebar foot (Steam only, not built).
- lobby/08: "Dim the Lobby behind the open drawer? Close it on a click outside it, or Esc / B?"

### Switched off / dropped
- The lobby room: greybox sock drawer, ready zones, ready rug, countdown and ticks, practice Socks/Cabinet, hoop (lobby/02, deleted by lobby/05).
- The title's Host page, New Game page, "full" page and Delete question (moved to the sidebar, lobby/07).
- The pre-join Colour & Wardrobe title page (Q1661).

---------------------------------------------------------------------
## D. Co-op (multiplayer/): Host, Guests, what each player sees

**What it is.** Up to 4 players in one shared house; one Host (a listen server, ENet by address; Steam later) decides every pick, drop, Throw, buy; Guests send Commands and apply the Host's events. Spec decisions Q235-Q331 are listed in docs/llm/multiplayer/spec.md (some had no ticket; I took them from that spec).

### Shape and authority
- Co-op up to 4 players (Q236), one shared flat, host-authoritative listen server; ENet first, Steam later (Q237). The Host quitting ends the Session. (Q250) Only the Host saves. (Q249)
- First player to reach the Host wins a pick; the loser fizzles silently (no message, no sound). (Q245, Q282)
- A Guest's pick, wheel cycle and drop are predicted: the Sock flies to their Hands at once, and is undone (flies back to the winner or the Heap; Hands snap to the Host's) if the Host refuses. (Q269, Q288; Q494 "Hands snap on host correction: fine for now")
- A Guest's Throw is a predicted Command too: the Sock leaves the Hands and the Throw sounds at once; the Host's answer confirms or puts it back. (multiplayer/35 built)
- A Guest's own Throw: they keep seeing their own flight; where the Host's flight differs at the same moment the difference eases in over 0.2 s and it lands where the Host says; "no going back". (Q1596, 2026-11-11)
- When the Host's flight does something the prediction did not: a catch, a shelve or a bin shows at once; a knockdown's bounce eases in. (Q1597, 2026-11-11)
- Two players clicking one Openable or Drawer at once both get what they wanted: a toggle carries the state the clicker saw it turn to, never flip-flops. (Q283) Openables and Drawers stand shut after loading a co-op save. (Q284)
- Nobody takes from a Teammate's Hands; Hand-offs only. (Q244) A Guest's Command for anyone else is ignored.
- Hand-off into full Hands: drops at their feet and they see "Hands full" (kept, Q484). Later rule (GLOSSARY): a Hand-off is refused unless it completes a Pair in their Hands (Q658, progression) -- glossary wins.
- The Host's F9 debug Coins are a host-only command into the shared bank; a Guest's F9 does nothing. (Q292; Coins are per player since Q1221, so unchecked how F9 works now)
- Everything a Guest's RPC carries is validated by the Host (shape, finite numbers, bounds, rate; one hello per peer); bad packets dropped and counted; a hostile Guest must not crash the Host or take another player's saved Upgrades by sending their profile id (the Profile gets a per-player secret). (Q1187, 2026-11-07; multiplayer/33 built; the secret is NOT built, multiplayer/36 `ready-for-agent`)
- Crash loses guests' positions: OK. (Q487) Guest's dropped Hands land apart: OK. (Q495)
- Mess size: New Game's Mess is the same for any player count while `mess.pairs_by_players` is 500 for every count (Q297-Q299). Joining later never adds Socks. (Q247, Q264) The Mess grows by adding Designs later, not by a share of the catalogue. (Q293) Smaller Mess keeps a share of every Collection. (Q488) Later: "New Game's size is Pairs per Drawer, not a player count" (Q1659) and Q294's "New game for N players" is gone (lobby/03).

### Spawns, saves, joining and leaving
- Everyone starts at the washer spawn, slightly apart, solo and co-op (Q285, overrides Q268's front door). A loaded game starts each player where they quit; the washer spawn is for New Games and first-time joiners. (Q296, Q265)
- Drop on leave, always: a Guest who leaves drops their Hands where they stood (Q248, Q295); the Host's save keeps a Guest's Upgrades and position only (changes Q274); the Host keeps their own Hands. (Q295, Q296)
- Drop-in at any time. (Q247) A fifth player is refused. The heap bake never runs while a Guest is connected. (multiplayer/04)
- A teammate joining or leaving shows "<name> joined" / "<name> left" in their colour under the crosshair on the other machines (2 s built; later message replaces earlier). (Q492; multiplayer/14, 27)
- A colour taken is greyed out with the taker's name; a saved colour that is taken falls back to the next free one silently. (Q276, Q314, Q505) Colour picker and Q313's title pages are replaced by the Lobby (Q1661).
- Eight soft sock colours: coral, teal, mustard, lilac, mint, sky blue, rose, charcoal (placeholder values in `data/tuning.json` `players.colours`). (Q275)
- Host's End session asks "Everyone will be sent back to the menu." End / Cancel; a Guest's Leave is immediate. ESC menu: "Leave" (Guest), "End session" (Host), solo "Back to title" and "Quit game" as red exit keys (Quit game saves and closes at once). (Q289, Q315, Q491, Q372)
- One save shared by solo and co-op modes (Q504), superseded by Worlds (section E).
- The host-quit message: "The host ended the session". (Q250)
- Join screen names the UDP port (24680, `net.port`) the host's firewall must open; nothing more, keep the plain message. (Q493) `--profile` for two copies is dev-only. (Q481)
- Port: 24680. Players max: 4 (`players.max`).

### What each player sees and hears
- Own HUD messages are yours alone (Q246). A Teammate's shelving shows the "+N" pop, the flying Coins and the "coins" sound only to the shelver; others' bank counts just go up. (Q281) Teammates' cues (pick, pair, drop, shelve, complete, Throw, buy) play as 3D sounds where they happen. (Q290)
- Buying shows "<name> bought <Upgrade>" to everyone else; whether the buyer should see it too and name the level stays open. (Q243; upgrades batch Q485: stays open)
- A teammate's Throw is drawn leaving their Avatar's hand and glides onto the true flight from their eyes (0.2 s, `avatar.teammate_throw_blend`); your own Throw stays from the eyes so aiming is exact. (Q483)
- A teammate standing in front of a Station blocks your aim at it (no [E] target, no outline, no click); Socks and floor Pairs behind a teammate are still aimed and a ping still lands behind them. (Q508; built for every Station: "Keep it so?" unanswered)
- Crawling under furniture: no, reach in. (Q482)
- Held X-ray glow of a teammate's mate through walls: OK. (Q486)
- A held item aimed at a Teammate in hand-off reach outlines their Avatar (the Highlight; fits a crouched Avatar's squashed shape, Q537). Drawer "full" message: no, the red tint is enough. (Q507)
- Soft push: players push each other softly instead of colliding hard (Q263); numbers to the balance round.
- Held items on an Avatar show at true size, all clustered at the HoldPoint in front of the belly. (Q279, Q280, Q328) No arms.
- A riding player's look must stay synchronized like anywhere else (Q1134, 2026-11-06; fixed in multiplayer/32).
- Refusals are short red wobbling text with no instruction ("Hands full"); positive messages stay. (Q316, Q506) The refusal wording OK. (Q506)
- End summary: cream keycap look (Q489); team totals first, then a line per player in their colour: Pairs shelved, Pairs made, Coins earned (Q254, Q273); no line for leavers; co-op team totals kept (Q490). "Pairs made" counts two loose Socks rolled into a Pair in that player's Hands; Coins earned include Collection bonuses (built).

### Ping and Emoji wheel (Q256, Q262, Q272 replaced by Q300-Q303, Q537, Q551, Q552)
- Ping on middle mouse; only with Teammates in the flat; solo has no Ping and the [MMB] hint is hidden. (Q262; multiplayer/08, 19)
- A tap highlights what the crosshair points at (up to 30 m): the nearest Sock, floor Pair, Station or Teammate, outlined in the pinger's colour through walls for 4 s with a soft 3D blip; a bare floor or surface gets a small ring in their colour. It follows a pinged Sock. (Q300, Q303) One active ping per player: any new highlight or emoji replaces the last. (Q272, Q302)
- A hold opens a radial wheel round the crosshair; the mouse (which steers the wheel instead of the view) moves toward a slice; letting go places it on the aimed spot or thing; let go in the centre: cancel. (Q300)
- Five emojis: Here (eyes), Help, Yes, No, Nice, icons in the game's own style (built: two eyes, lifebuoy, green tick, red cross, star with sparkle). (Q301)
- A placed emoji shows on its target (a sticker bubble in the pinger's colour, through walls, following a Sock) and a small copy beside the pinger's Avatar head. (Q302) Revised: a speech bubble with the emoji icon (no text) beside the pinger's Avatar head for about 3 s plus at the pinged spot; **not through walls**. (Q552, 2026-11-01; later date wins over "through walls" for the emoji bubble)
- Ping marker is 2x bigger and never shrinks below a readable size at distance. (Q551) Icon sprites only, never 3D text (`ui:no_floating` rule).
- The ping blip is the `ping` sound (synth/ping_d, flat/60).
- Numbers (placeholders `data/tuning.json` `ping`): seconds 4; size 0.12; `min_ring` 0.04; `head_side` 0.35; `bubble_seconds` 3; `Pings.OUTLINE_WIDTH` 2.2x crosshair outline; wheel numbers go to the balance round (Q477).

### Avatar (the sock creature) and Wardrobe basics (Q277-Q280, Q304-Q311, Q328-Q331, Q360, Q496)
- The Avatar is a wonky sock creature: lumpy lopsided upright sock, heel bump, ribbed cuff, two big googly eyes, stubby feet; 1.7 m tall; the look signed off as modelled. (Q277, Q304; multiplayer/17) Plain white body tinted with the Player colour; the trim (cuff stripes, heel patch, feet) is a darker shade of the Player colour (`avatar.trim_darken` 0.35 placeholder), not cream. (Q496)
- Pupils look at the nearest player within range (`avatar.look_range` 6 m; max 28-30 degrees), idle with a slight wander otherwise; feet waddle when walking, body bobs. (Q305) A crouching teammate uses the Crouch shape key; attach points (pupils too) follow their crouch offsets. (Q278) Crouch scrunch OK; pupil wobble and lean keep. (Q502, Q503)
- In first person (solo too) a player sees only their own waddling feet and the belly's edge in their colour; cosmetics show on their Avatar for others. (Q310, Q329)
- The upper body bends with the look pitch: looking down the top (eyes, cuff, hat) curls forward over the belly, looking up it leans back; body turns with yaw, feet stay planted; eases over time; combines with Crouch; pupils, Head, HatPoint, HoldPoint and worn Hat/Clothes follow the bend. (Q360; multiplayer/21)
- Squash and stretch on the Avatar's jump (visual only, every machine): takeoff stretch and landing squish scaled by fall height with a small damped wobble. Approved at the review build and "more pronounced": stretch 12% -> 20%, squish 30% -> 45%. (designer, 2026-11-08; multiplayer/31; Q821) Built numbers: squish none under 0.15 m, max at 1.5 m fall, wobble 3 swings/s damping 0.35: placeholder.
- The waddle uses the smoothed speed (0.1 s) so it holds at any frame rate (a bug found by the designer: "The players feet and body no longer wobbles when moving", 2026-10-31).
- One hat slot and one clothes slot, each may be empty; 6 hats (beanie, cap, top hat, party hat, bobble hat, crown), 4 clothes (scarf, apron, bow tie, jumper); fixed piece colours (no piece takes the player colour). (Q330, Q331) Pieces free or unlocked by milestones (a data table: `wardrobe.unlocks`; milestones `pairs_shelved`, `coins_earned`, `collections_complete`, `game_finished`). (Q306, Q308) An unlock earned in a session unlocks for every player present, kept per player in their own Profile. (Q311; later GLOSSARY: unlocks come by Gift or lifetime milestone, Q893 -- glossary wins) The Wardrobe Station in the bedroom opens it in game: the player freezes, teammates see changes live. (Q309; modelled wardrobe in the parents' bedroom Q389, flat/48) Look is saved in the Profile, sent on join and synced when changed.
- Name tag floats over the hat's top (a top hat or party hat lifts it about 0.35 m): "OK, or keep the tag at one height?" open.
- Locked pieces are dimmed keycaps with a "Locked" tooltip (placeholder).
- A guest's look is not checked against their unlocks by the Host (placeholder; open).

### Knockdown basics before the ragdoll (superseded by section B)
- "if items are thrown at full strength it should knock off the player for some time" (designer, 2026-10-31). Only a Throw released at full charge (`knockdown.min_charge` 1.0) knocks down; weaker Throws hand over as today; a full-charge hit does not hand the item over, it falls and the body bounces it off at 5% of its speed (`knockdown.bounce`). (Q394, Q395) A full-charge Throw that bounced first still knocks down. (kept, 2026-10-31)
- The fall is "wonky, physics based", the way the hit pushes it; the knocked player's view follows (never into a wall). The knocked player alone reads "<name> knocked you down"; the thrower gets no line. (designer, 2026-10-31; multiplayer/23)
- The falling body collides ("It should collide"): walls, furniture, teammates. (designer, 2026-10-31; multiplayer/24) A lying body blocks walkers and stops another player's fall (Q421); against a wall or Cabinet the body slides or slumps sideways down to the floor instead of leaning and bouncing (Q422); the off-centre twist turns back while getting up (Q423). (multiplayer/25)
- While down nothing hits them: flights pass through; a teammate can still hand an item to a lying player (OK? asked); knocked while charging drops the charge; an open menu stays open. (built; asked) Throws still pass through a lying body, in effect until knockdown/04's rule for objects (Q1935 only covers hits when standing).
- Knockdown sound hunted on the sound bench (Q478, flat/64).

### Voice chat and Steam (waiting)
- Proximity 3D voice chat: built last, open mic by default with push-to-talk an option (Q256, Q259, Q260, Q261). `ready-for-agent`, priority later (Q1583). Open: voice codec, bandwidth, echo; whether voice works through Steam peer and ENet alike; mute per player. (deferred, Q479)
- Steam peer (multiplayer/12): **On hold: Steam work starts only when the designer says so.** (Q1957, 2026-11-18) Decided when it starts: lobby friends-only (Q1674); GodotSteam 4.24 `SteamMultiplayerPeer` with `server_relay = true`, a Steam lobby only for discovery and invites (Q1675); GDExtension on stock Godot 4.7.1 with binaries in Git LFS (Q1676); player key text `steam:<id>` / `local:<id>`, gameplay uses a per-World id (Q1677); Worlds stay in their build (Q1678); names: live Steam name cut to 16 characters with an ellipsis, missing glyphs fall back to a system font (Q1679); anyone in the game may invite, the Group rule decides who gets in, no refuse button (Q1680); rich presence "Sorting socks on the first floor · 3/4 players" / "In the Lobby" (wording placeholder, Q1681); lobby size exactly 4 members (Q1682); Steam Deck / Steam Input not a target (Q1683); Steam Cloud syncs the Profile and Worlds (Q1684); pose stream: measure first with simulated loss, change to unreliable + sequence only if it stutters (Q1685); designer sets up the partner account and pays the fee later; test on app 480 until then (Q1686); achievements wanted via a local store that Steam swaps in later (progression/81, 2026-11-11).
- **Conflict:** Q1662 (2026-11-11) "Steam sits beside Join by address" vs Q1687 (2026-11-11) "Join by address: hidden in Steam builds; shown in non-Steam and debug builds." Q1687 is the later number, so it holds; lobby/03's built note still reads Q1662 (a Steam build keeps address Join). Unchecked which is built.
- Guest FPS over the internet (multiplayer/37): the designer sees low FPS on a Guest over the internet (Q1815): the whole picture slowed down, the own camera too (Q1858); the Guest was on a different PC (Q1859); investigate everything, report by severity only, the designer chooses fixes (Q1814); no fix tickets yet, the designer measures on their PCs first with the report's tool `tools/guest_fps.sh` (Q1860). Not reproduced in the sandbox. The report is `docs/perf/guest-fps-report.md`.

### Numbers (placeholders unless marked)
- Port 24680, 4 players max, pose stream 20 per second, ping 4 s, bubble 3 s, ping reach 30 m (placeholders; decided: 4 players, 4 s ping per Q272).
- `net.pose_limit` 60 per second per peer, `net.pose_margin` 30 m x/z and -50..100 m y; the join snapshot about 40 KB for 1000 Socks (built), later 3.4-20 kB; Flight stream 80 bytes a body a tick (84-91 kB/s with 15-16 bodies in the air).
- Ping size, bend numbers, soft push, wheel numbers: moved to the balance round (Q477, questions/06): not decided here.

### Decided against
- A ping diamond with a label (replaced by outline Highlight and emoji, Q300-Q303).
- Spawning co-op players by the front door (Q268 reversed by Q285).
- Hands saved under the Guest's id in a save (Q274 reversed by Q295).
- Stealing from a Teammate's Hands (Q244). A refuse button on Steam invites (Q1680). Showing the Drawer-full message (Q507). A "teammate knocked you down" generic line (FYI: real game always names the thrower).
- Player-count prompts on a New Game (Q294, Q313 reversed by Q1659).

### Open (verbatim, from multiplayer tickets, tagged as in ticket)
- 07 (stays open, Q485): "Buy message (Q243): every other player sees '<name> bought <Upgrade>' ... Should the buyer see it too, and should it name the level?"
- 12: "Whether Steam replaces or sits beside Host/Join by IP. *(deferred until this ticket starts, Q479)*"; "How the saved random id maps to a Steam id. *(deferred ... Q479)*"
- 13: voice questions above.
- 15: "A predicted drop flies to where the guest's machine guesses it lands ... Worth a look over the internet."
- 19: "Through a wall the highlight shows only as the outline ... Wanted, or should a highlight also show a filled silhouette, or a small marker like the emoji sticker?"; "On the pinged teammate's own machine nothing is drawn on them ... Should they see something (a HUD line 'Hana pinged you', a screen-edge glow)?"; "The pinger sees no copy over their own head ... Wanted?"; "A pinged Sock that leaves the Mess (picked up) loses its outline ... Should it follow the Sock into someone's Hands instead (08's question, still open)?"; "An emoji outlines nothing: it is the sticker alone. Should an emoji on a thing also outline it?"; emoji icons "Pictures up for the designer."; "The blip is still 08's `ping` event ... A different sound per emoji?"
- 20: pupils look at the nearest player not the player looking at them ("Prefer the player looking at them, or the local player?"); first-person body shadow and clothes on the own belly; name tag height; more unlock milestones (days played, Throws, hand-offs); "Locked pieces ... Say what unlocks them?"; cosmetics trust; preview layout; `assets/avatar/feet.glb` unused: keep or drop.
- 21: bend while crouched ("Keep that, or bend less when crouched?"); where it bends (higher, like a neck, or lower); HoldPoint dips with the bend ("Keep that, or hold them still?"); pupils look down with a looking-down creature?; own belly curl enough to notice?
- 22/25: lying body hit-by-hand-off OK?; knocked while charging; frozen input only on the knocked player's machine; sideways slump suits straight walls only ("Should it slide off a ledge too?"); a lying teammate stops a fall and the fallen leans on it; getting up is not swept ("Should the one underneath wait, or push the other off?"); `knockdown.slide_keep` 0.5; "A lying body blocks walkers hard ... Throws still pass through a knocked-down body. Both OK?" (Q1935/knockdown/04 later changes what a Throw does to a standing body.)
- 24: "The get-up wobble's small overshoot back the other way is not swept ... Sweep it too?"
- 26: trim darkness 0.35 ("On charcoal the trim and feet come out nearly black"); teammate Throw glide look and 0.2 s; Stations blocked by a teammate "Keep it so?"
- 27: "Q1: ... Anything else to change there (e.g. a red exit key, or Back to title on the summary)?"; "Q2: ... Queue them, or keep it?" (join/leave lines); "Q3: Solo's 'Quit game' saves and closes at once, asking nothing. Should it ask first?"
- 29: "Should the bubble itself also shrink with distance? ... (Recommended: keep fixed.)"; ping minimum size; bubble look first pass.
- 30 (technical): "Should a script error mid-run fail the suite? Today it only warns."
- 31 [later]: placeholder squash numbers; "The squash scales the whole Avatar about its feet, so the own first-person belly and the mirror's body squash too ... Say if the own body should stay still."
- 32 [later]: "How a rider's look bend sits on the curl ... A cap, or a smaller share of the look while curled, is the designer's call."
- 33 [later]: secret not built; `net.pose_margin`; `net.pose_limit` 60; Throw `vel`/`from` and nozzle/drop position not range-checked ("Recommend the Host checks `from` is within arm's reach ... say if wanted"); Commands have no rate limit; refusal wording for a malformed hello.
- 35 [later]: "A teammate's Throw seen on a Guest stops at the release point for about 3 ticks (50 ms) after the blend from their hand ... Could the hand blend be stretched over the lag so it never stops?"
- 37 [blocking]: "Which of the report's findings become fix tickets (Q1814)?"; "When the Guest's frame rate looked low over the internet, was the camera itself smooth ... or did the whole picture slow down?" (answered Q1858: whole picture slowed); "Was the Guest on the same PC ...?" (answered Q1859: different PC) -- the follow-ups were not moved under Answers; "[later] Not measured: the Sock vacuum, the Radio and TV, drags and the Elevator ...; more than one Guest; real frame times on a GPU."

### Switched off / dropped
- Peg-doll capsule avatar (replaced by the sock creature); the ping diamond; the title's Singleplayer / Multiplayer page set with "You" (replaced by Lobby); offline "Play" on the Host/Join card (Q287); the front-door spawn.

---------------------------------------------------------------------
## C. Physics: how Socks fly, land, rest and wake (physics/), with Hands, Drop, Throw and Pair rules

**What it is.** The 2026-11-04 rewrite so the game can hold 5,000-10,000+ loose Socks, 4 players, a listen-server Host, a mid 4-core laptop Host with integrated graphics spending about 4 ms of physics a tick (Q762-Q765). Most of it is engineering; the rules that bind a player are below. The two big player-visible rules are: Sock states (Resting/Moving) and "a drop or Throw is one Jolt body from release to rest". Engine facts (Jolt, Godot 4.7.1) live in `docs/llm/physics/research.md` and `proposal.md`; I skimmed research.md (engine facts, no designer rules) and read proposal.md whole.

### Sock states and the Mess layout
- **Resting / Moving** are the glossary words. (Q841, 2026-11-04) A Resting Sock is still, drawn in bulk and costs almost nothing, and other Socks can lie on it; a Moving Sock is simulated. The game wakes Resting Socks into Moving ones within a budget; Moving Socks rest again as soon as they settle. (ADR-0008; Q775)
- A resting Sock is a static collider plus a drawn instance; held, contained (vacuum, hopper, Elevator car in transit) and shelved Socks are data only, no bodies. (Q775, Q798)
- **The Mess layout is computed per game from a seed**, not baked and not a live physics spill: planned spots (Heaps, a fan in front of the washer, inside the openables, under furniture, on tops, on the stairs), Mate distance (walked) and each level's share. A different seed every New Game, saved with the game; Guests get the rows from the Host, never the seed. (Q839, Q842, Q845)
- Rarer Designs prefer hiding spots and lie deeper in their Heap and further from their Mate; never told to the player. (Q839; tuning `mess.hiding_weight`, `mess.rarity_distance_factor`)
- Socks lean at most about 22 degrees; a floor Sock rolls down a Heap steeper than about 22 degrees, so a Heap is a slumped mound; a boxed-in Heap stops at 0.4 m (built; "OK, or flatter/taller?" unanswered). (physics/11)
- The washer's Socks lie in a fan heap in front of the washer, not thrown (built; "OK?" unanswered). A floor unlock's Socks are laid onto the Mess as it lies, during the cutscene (built).
- A Heap's top Sock taken wakes none; a pick wakes only the Socks resting on the taken one, up to 40. (ADR-0008, Q777; physics/06, physics/22)
- A Throw that hits a Heap scatters it: the hit Socks wake as Jolt bodies and the item's mass and speed push them, no extra force. (Q1203, Q1215, 2026-11-07; Q777: hit faster than about 1.5 m/s wakes that Sock plus up to 8 touching)
- Avatars walk over Heaps and never push Socks (Q778); a ragdoll lies on Heaps and does not plough through them or wake them (Q779). (Built: only the stress test's walkers stand on SOCK_REST; in the game players still walk through Heaps; "when" unanswered, physics/22.) The designer "wants to try pushing Pairs and Socks by walking in the near future" (Q1742, 2026-11-11): not now.
- A moving Sock can be picked at any time, in flight included. (Q783)
- Socks inside shut openables (fridge, oven, cupboards) keep their colliders. (Q796)
- Socks meet an unlocked floor's door leaf as it swings open, like a room Door; it pushes or wakes the Socks in its way. (Q852; physics/24) Keep the 9 cm gaps between the attic balustrade's spindles: Socks may fall into the stair void and count as inside the house. (Q853)
- A Moving Sock that leaves the house rests where it is so the lost-item rule puts it back (in front of the washer; maintenance/06).
- Windows are walls: a Sock or Pair is no longer thrown out of a window; the `lost:window` case is removed. (Q1250, 2026-11-08)
- Spawn clear: no Heap within about 1.5 m (`mess.spawn_clear`, placeholder) of a player's spawn spot. (Q959, 2026-11-05; physics/28 `ready-for-agent`, priority later; not built)
- Socks do not stand on their cuff in Heaps or on furniture such as the ironing board; the layout lays any Sock left on end (over 60 degrees) flat. (Q857; the live SockWorld rest does not do this yet: open)
- Sock collider: three boxes (the fitted thirds), 2.4 cm thick, one definition for resting and moving so nothing jumps; two boxes were tested and rejected because they stand on end twice as often. (Q781; physics/07 built)
- A **Pair** (sock ball) is a sphere with high linear and angular damping (`pair_linear_damp` 2.5, `pair_angular_damp` 8: placeholders) so it stops near where it lands: heavy damping, a few cm of roll, "a Pair stops quickly". (Q782, Q1213; "near enough, or should it stop dead?" asked)
- A **Gift** is one box. (physics proposal 4.1)
- Physics ticks 60 a second (30 let 194 Socks fall through in the stress run); physics interpolation on; a hitch catches up at most 3 ticks, then the world slows briefly. (Q830, Q801)
- CCD only on releases (Throw, spit) at 1 m/s or more, off under 0.5 m/s; falls stay discrete. (Q895, Q962; `SockWorld.CCD_ON`)
- Floor slabs in the Sock colliders are thick (0.2-0.3 m, the basement 0.5 m) so Socks cannot tunnel. (Q895)
- The cloth (SockActor bend) is capped: only Socks in Hands plus the nearest `cloth.flying_cap` (4) flying ones bend; the rest fly rigid. (Q858; physics/25) Cloth feel itself: heavy damped droop (Q53).
- Resting Pairs fall when what holds them goes: a stack of Pairs does not float when the bottom one is picked; the Pair becomes a Jolt body again and falls through the drop's path, and Pairs resting on it follow. (Q1741, 2026-11-11; physics/38 built) Loose Socks, Gifts, Parts and the bin lying on a picked Pair still float (open).
- Elevator car contents: at a stop with the hatch open the car's Socks are ordinary Resting/Moving Socks; as the car leaves they freeze as data (Contained) and ride; on arrival they are Resting again at the same poses. (Q849, revises Q816 and Q844) The car's colliders are solid when something lies in it or a player's or ragdoll's body overlaps its inside (the hatch does not matter, Q846-Q847); the empty car is visible to the crosshair only (Q848); the contents are checked on events only, no polling (Q850). (physics/10, physics/23 built; stress scenario S7 kept, Q851)

### Hands, drop and Throw as one motion (physics/35, physics/36, 37)
The designer saw items "visibly change between states" (put on a stair edge and it moves, then settles). Result:
- **Where Jolt can do it, use Jolt: no custom physics unless necessary.** (designer, Q1200, 2026-11-07; memory note "Prefer Jolt over custom physics")
- A **drop** is a Jolt body released at zero speed just above the crosshair's spot (the "middle option"); Jolt settles it; no glide; the Game no longer picks the exact lie. (Q1201, 2026-11-07) Released about 3 cm above the crosshair's spot (`release.drop_height` 0.03; Q1206). Hand to release point: a quick eased flick of about 0.1 s from the drawn hand keeping its turn, then Jolt takes over (`release.flick` 0.1; Q1207).
- A Sock dropped half over an edge: Jolt decides (tips or slides off, once); no nudge rule; the push-out at a riser stays and the release is not lifted. (Q1208, Q1251)
- The first build covers drops and Throws together, both one body from release to rest. (Q1205)
- The own Throw keeps starting from the eyes for exact aim (Q483, Q1202); the body flies from the eyes, only the drawn model starts at the hand and catches up over about 0.1 s (`release.catch_up`; Q1209).
- A flying or falling loose Sock keeps the cloth flop: the actor is posed from the Jolt body and flattens before rest so the swap to Resting shows no pop. (Q1210)
- Bounce matches the old: restitution 0.35, friction 0.6 (`upgrades.throw`). (Q1214)
- A Guest's own drop or Throw is predicted locally on its own body and blends to the Host's; a Guest draws a teammate's Throw from the Host's stream, smoothed, about 100 ms behind, no replay of its own and no slide at the end. (Q1211, Q1204) Review build approved: "Physics looking good." (designer, 2026-11-08)
- **Exactly two release systems** (designer, 2026-11-08): (1) **Physical**: Socks and Pairs, wherever they come from (hand drop, Throw, vacuum spit, the pairing machine's rolled Pairs) are one Jolt body from release to rest; (2) **Items**: the Radio, Parts (progression parts), Gifts, the Guide card, the lantern, the Beeper, the Encyclopedia book and the rest that are not Socks or the cat use one shared scripted arc; the **cat keeps its own system**. (Q1255, Q1256) Items are not Jolt bodies. Both systems share the same 0.1 s "put" animation when they leave the Hands; hand items grow from their in-hand size; Hand-offs have no put. (Q1322) Approved after the review build `builds/review-36`. (Q1319)
- Spat Socks as Jolt bodies: if too costly, slow the spit rate until the count stays in budget (Q1257); `vacuum.spit_bodies` stays 24 (Q1320); the spit rate stays 0.1 s (10 Socks a second). The pairing machine's rolled Pairs become Jolt bodies too (Q1321; they do not shelve themselves or get caught, built to keep today's behaviour: "Should it?" open).
- Hand-off Throw rule (GLOSSARY, restricted Hand-off Q658): a Throw that hits a Teammate with a mate in their Hands is caught; otherwise it bounces off (`hand_off.bounce` 0.25 of its speed, placeholder); a full-charge Throw knocks down (section B).

### Controls and numbers of the core loop (from GLOSSARY plus `data/tuning/*.json`; the tickets in my folders give few of them)
- Left click: pick up a Sock (pairs with a matching loose Sock in the Hands; else a free place; else refused). Right click release: drop the active item where the crosshair is, on a flat-enough top within pick reach (the floor, a furniture top, a shelf, an open inside, a Heap, a lying Pair); elsewhere the crosshair turns red while something is held and the drop is refused ("Can't drop there"). Hold right: charge a Throw; release to throw; a release just after the charge starts is a short lob; no cancel. Mouse wheel cycles the active item. Hold R turns the active item (it stays at the angle reached); hold G zooms the held item in a little. E uses a Station. Middle mouse pings. Space jumps; Ctrl crouch; Shift sprints once bought. (GLOSSARY Hands, Throw; mvp/01, 10)
- `data/tuning/hands.json`: start capacity 1; `drop_slope` 25 degrees (steepest top a drop may land on, borrowed from house/16); `drop_gap` 0.08 m (narrowest gap a drop sees into). (flat/66, Q522-Q523) placeholders.
- `data/tuning/upgrades.json` throw: `hold_to_charge` 0.25 s, `charge_time` 1.2 s, `tap_charge` 0.15, lob speed 3.5 and lift 2.0, `min_speed` 3, `max_speed` 5 m/s, `speed_per_level` 4 (Long Arm), `charge_drop_pct` 0.25 (Quick Charge), gravity 9.8, restitution 0.35, friction 0.6, `rest_speed` 0.6. Throw is free from the start but weak (Q1344). All placeholders (progression/63).
- `held.json`: active item scale 0.6 at (0.2, -0.13, -0.55); tucked items 0.3 at (-0.3, -0.3, -0.55); `turn_time` 2.0 s per turn; zoom (G) 1.6x at (0, -0.02, -0.4); a pair ball scale 1.6. (flat/53, Q374-Q378; flat/65; Q1868) placeholders.
- `paired.json` the paired moment: 0.5 s total: the picked Sock flies to the held one (40%), they line up and fold (30%), roll into the sock ball that pops with a sparkle (Q324, flat/43; mate burst 20 particles). placeholders.
- `payout.json`: base 10 x Rarity multiplier 1/2/5 (common/uncommon/rare); `drawers.json` pairs_per_drawer 25, Drawers (team currency) per filled Drawer 1/1/2/3/4 by floor (basement/ground/first/attic/grotto; Q1405 placeholders). `hand_off.json` bounce 0.25, Sole Mates glow 1.2 s. (Cabinet, Coins and Collection rules are in other digests.)
- Pick-reach and the drop highlight rules (red crosshair, "Can't drop there") come from flat/66; not in my folders: `unchecked`.

### Numbers: physics budgets (placeholders unless marked)
- Moving budget 512 Socks, 32 reserved for spit and Throws; promotions 16 a tick and demotions 8 a tick (calibrated in physics/06 from 64 / 128); woken by a pick 40, by an impact 8, swept by a mover 32 a tick. (Q774, Q786, Q777)
- Rest rule: a Sock turns Resting after `REST_TIME` 0.3 s below `REST_SPEED` (about 0.05 m/s); max Moving age 6 s (`release.max_age`). `release.wake_reach` 0.03 m, `wake_gap` 0.006 m; Pair at rest under 0.25 m/s (`flat_speed` 0.6 built).
- Jolt limits in the game: `max_bodies` 32,768; `max_body_pairs` and `max_contact_constraints` 65,536; step memory 128 MiB (Q1474, 2026-11-10, lowered from 262,144; the designer's try: saves about 740 MB per process). The stress run and the zoo's 5000-Sock rain raise them themselves. (Q961 narrowed by Q1193: the game uses the lowest limits that lose no Socks in its own biggest Mess)
- House collision: authored boxes and convex hulls, target raised to about 3,000 boxes and hulls (Q885); built 1,959; "Raise the target, not merge furniture further" (Q1097); to what: the agent measures and suggests, the designer confirms (Q1101); parked until the low-end PC bench numbers are in (Q1959, 2026-11-18). Resting-top bar: 0.5% of sampled points off, none over 2 cm; decor under 3.5 cm has no collider (Socks may sink 8 mm). (Q795, Q886)
- Reference machine: the designer's own PC (Ryzen 7 7800X3D, RTX 4070 Ti) with its headroom halved to stand in for a 4-core laptop. (Q793) Step budget 4 ms laptop / 2 ms PC; GDScript only, no C++ or C#. (Q765, Q794) Network: about 1 Mbps total Host upload. (Q788) Guest draws Moving Socks 100 ms behind. (Q789) Late-join loading may take longer than 3 s. (Q791) Saves use the compact encoding. (Q792) 14-bit Sock ids (16,384). (Q799)
- A pick used to freeze the game with 10,000 Socks (the autosave built the whole save on the main thread): fixed by copying rows and writing on a worker thread; the quit save stays synchronous. Guard test `mess:pick_hitch_big`: median worst frame under 16.7 ms. (Q912, Q913 designer, 2026-11-04: "if there are lot of socks, taking one sock out takes a lot of time.")
- The autosave is: every 2 s after a change and on quit (mvp/07; GLOSSARY).
- Physics space queries run in the physics tick; stickers and the camera's wall-clip may be one tick old; threaded physics is dropped (physics stays on the main thread). (Q1190, Q1494)
- Process: the stress test ships as an exe the designer runs (`stress.cmd`, release export, Q793, Q814); S1-S10 scenarios in docs/perf/tools.md; the 5000-Sock rain is on demand.

### Decided against / wontfix
- A prioritised snapshot stream per Guest (physics/15) and Host pose-history checks of Guest picks (physics/16): **wontfix**, replaced by the Command-plus-re-settle event design: "Close as replaced by the event design (Commands plus re-settle updates); a co-op desync in playtests gets a fresh bug." (Q1034, 2026-11-06)
- Live spill of 10,000 Socks at New Game and pre-baked layouts (Q776, Q780 reversed by Q842, Q845).
- Heap templates; "not Jolt determinism"; resting Socks as sleeping dynamic bodies.
- Jolt trials (slop, position steps, sleep) kept none; keep Jolt defaults (Q860).
- A two-box Sock; a rounded-box Pair (Q782: sphere).
- Dormant/Active words (Q841: Resting/Moving).
- Vacuum with forces (physics proposal; a scripted flow instead, Q784).
- Drop snaps: the glide, the actor hand-off, the Pair's skid (physics/35).

### Open (verbatim, tagged)
- physics/03 [later]: "At 30 Hz some things still move a tick at a time" (moot: 60 Hz chosen); "The cloth ... Is that worth a cheaper cloth" (answered Q858); "Keep Jolt's defaults, or try them again on the PC run?" (Q860 keep).
- physics/05 [later]: "Dormant Socks are drawn per room and Collection (91 MultiMeshes for the 10,000); ... Keep rooms?" (Q861: decided in physics/20, measured); "Pairs and Gifts are drawn as a plain coloured sphere and box (placeholders); their real looks in MultiMeshes ... are for physics/20".
- physics/06 [later]: pick wakes a column over the picked Sock (one query up to 2.5 m, lowest 40 first) ("Confirm."); "Socks a Throw knocks loose start at rest. ... Should they also take a share of its speed?" (answered by Q1215: no extra force); "A fast Sock in an avalanche or a fall wakes nothing it hits. Confirm."; "sweep() wakes only what the mover's shape overlaps ... a low Drawer could leave a Sock hanging over one it pushed away. OK?"; "The pressure rule ... does not weigh the time a Sock has been Moving ... OK?" (physics/06 answers moved to the balance round, Q967, questions/06.)
- physics/07 [later]: "Turned boxes ... Worth widening the Sock's box ... or keep the upright thirds?"; "S3 sinking is not the colliders ... Keep Jolt's defaults, or try more velocity steps only for the Active budget"; "Standing on a cuff live ... should SockWorld's rest do the same when a Sock comes to rest on end (length over 60 degrees)?"; "Pair drag ... Is that near enough, or should it stop dead?"
- physics/08 (answered Q852, Q853), physics/09 (answered Q885, Q886, Q963).
- physics/10: "What counts as 'someone inside' ... A different reach, only the open stop, or only once a player is in the car's box?"; "The empty car's floor still meets the crosshair ... Keep it, or switch the car off for the crosshair too?" (Q848 keep); "A Sock taken from the car: the Socks that lay on it are data and do not re-settle ... Should they drop to the floor or the Sock under them?"
- physics/11 [later]: Heap look taste; the washer fan heap; "A floor unlock's layout is laid during play ... A smaller slice for unlocks (slower, smoother)?"
- physics/14: "Is a MultiMesh worth it for the few Socks of a cutscene, or are MeshInstance3Ds enough? (designer)" (collected in physics/31).
- physics/21 [later]: CCD cost vs thicker floors "Keep CCD?" (answered Q895, Q962); "Socks pressed into a floor slab under heavy piles"; "S3 now pours onto the biggest Heap with room ... Is that the pile you want measured?"
- physics/22 [later]: "Players walk through Heaps in the game as before ... Adding SOCK_REST to the Player's mask changes how the game plays: when?"; "Keep both pushes (the Game's data push of a Door and the physics sweep) or let the physics alone push?"; "A rolled Pair is a sphere body of MessWorld's own" (since replaced by physics/37); Sock shadows per room (physics/20); lay-flat on SockWorld rest.
- physics/23 [later]: "A Sock still Moving when the car leaves freezes at its last Mess pose ... Should it fall the rest of the way on arrival instead?"
- physics/24 [later]: "make_house.py still authors the shut leaf as static Sock colliders ... Should the shell stop authoring them once physics/11 replaces the bake?"; "The leaf's bottom clears the flight's top step by about 0.16 m ... Is that the swing you want?"
- physics/25 [later]: "A Sock that loses its cloth keeps the bend it had ... should it straighten instead?"
- physics/27 [later]: renderer side of a pick not measured; pick still 4-10 ms of script; loading a 10,000-Sock save parses on the main thread.
- physics/28 `ready-for-agent`, priority later (Q1580). physics/29 `needs-info` priority next (Q1582): parked (Q1959). physics/30 `ready-for-agent`: what is left is the measured proof (the 5000-Sock rain loses no contacts; 2026-11-18 triage), priority next. physics/31 `ready-for-agent`: S4, S5 and S8 verdicts, rogue-spew MultiMesh (Q1145), priority next.
- physics/32 [later]: "The first bake still costs about 1.1 GB (option c of maintenance/57)". 
- physics/35 [later]: "A drop's flick carries the held pose, so a Sock held by a crouched player beside a table hangs through the table top for about 4 frames"; "Gift boxes, the Radio, the Guide card, the cat and the lantern onto Jolt bodies (Q1212)" (then settled by Q1255: items are not Jolt bodies); "Do drops share the 32 reserved Throw slots or use the general share?"; "The outline that shows on a Moving Sock and not on a Resting one (D3): was it meant?"
- physics/37 [later]: "A rolled Pair touching its own Collection's Cabinet does not shelve itself, and a teammate's body does not catch it ... Should it?"; a Guest who joins while a Pair is rolling.
- physics/38 [later]: Socks, Gifts, Parts and the bin on a picked Pair still float; a Pair on a Sock a Door pushes is not checked; pushing by walking: Q1742 its own ticket.

### Switched off / dropped
- Dormant/Active names; live 10k spill; the old Mess physics (`mess_physics.gd`, `mess_view.gd` deleted in physics/22); the heap bake (`heap_bake.gd`, deleted; physics/11 replaced it); the Guest snapshot stream (wontfix); `lost:window`; the pairing machine's own sphere body (replaced by Jolt bodies, physics/37). The pairing machine itself is switched off since 2026-11-19 (per brief); its physics rules (rolled Pairs, hopper feed 0.8 m `pairing.feed_reach` Q869, vacuum 24 container, 6 s hold, 10 Socks/s spit, cone suction) stay recorded above and in the tools digest.

---------------------------------------------------------------------
## F. Further decisions found in the tickets (compact list, earlier Q numbers; later dates win where noted)

- Q238: multiplayer after the balance round (overridden by Q267: tickets 01-11 built before the playtest). Q831 (2026-11-04): Steam peer deferred, built against Valve's test App ID 480; Q832: voice queued after multiplayer/12, still built last (Q261).
- Q239 shared Coin bank, Q240 per-player Upgrades, Q241 anyone spends: **Q239/Q241 are reversed by Q1221** (GLOSSARY: Coins are each player's own, paid to the shelver, saved per Profile id). Per-player Upgrades stand. Team currency is Drawers (Q1224).
- Q242: the Mess scales with player count (reversed in effect by Q297-Q299: 500 Pairs for every count, now Pairs per Drawer, Q1659/Q1750).
- Q251 avatar shows body, colour, name tag, held items; Q252 the Held X-ray makes a teammate's held loose mate glow in their Hands; Q255 right-click drop aimed at a teammate in reach is a Hand-off; Q257 name typed (Steam name later); Q258 menu Host/Join (now Multiplayer page); Q271 colour picked on the Host/Join screen (now at the Lobby's Wardrobe).
- Q286 Join steps straight in when the saved colour is free (replaced by Q313/Q314, then by the Lobby, Q1661). Q291 the Guest's re-settle snaps to the Host's poses, "check it in the playtest". Q298 new Designs into new or existing Collections: balance round. Q307 hats/clothes list. Q312 title with Singleplayer / Multiplayer entries (replaced by lobby/04: Solo · Multiplayer · Options · Quit). Q334 a Sock may not rest on its empty corner or stand on end (why the Sock collider is three boxes). Q342 Coop is one page then Colour & Wardrobe (replaced by lobby). Q534 riding the Elevator is data.
- Vacuum and hopper (tools spec, cited in physics proposal and research): cone suction every 0.06 s (16 Socks a second), container 24, a 6 s hold then a spit stream of 10 Socks a second from a rear outlet, oldest first (first in, first out: Q785; fix pop to the oldest, Q1033, 2026-11-06); a spit Sock tumbles and lands like any dropped Sock (Q730); the hopper holds 12 and is fed by hand or the stream (Q727, Q728); a full container stops (Q738); the pairing machine's loaded Socks are data (Q743, Q744); suction shows a short visible curve with a shrink (about 0.2 s), needs line of sight and may pull a Sock from under others (Q784, Q720, Q721). The vacuum "never pulls Socks with forces". (The Sock vacuum and pairing machine are not in the glossary's "Things in the flat" list; the pairing machine is switched off since 2026-11-19: **unchecked** whether the vacuum is still live. The designer's tools spec is in another folder.)
- Rogue machine (cutscene) Socks are decorative: drawn Socks on scripted arcs, local to each machine, seeded by the Host's start event, never bodies. (Q747, Q787) Floor unlock's real Socks land during its cutscene (Q747).
- Q763: up to 4 players; Q764 listen-server Host simulates; Q773: 30 or 60 Hz decided after the stress test (decided 60, Q830); Q790 the Guest's own Throw is predicted locally; Q797 a rendering ticket alongside (physics/20); Q800 the Elevator carries resting Socks (revised by Q816/Q849); Q812-Q814 the stress run raises Jolt's limits itself, worst case 10,000 Socks loose, the designer's PC run uses a release export; Q843 one switch ticket moves the game from the old Mess to SockWorld; Q859 leave per-tick movers at 60 Hz; Q894 stress-run Jolt limits (then lowered in game by Q1474); Q899 run the touched suites; Q929 a Flight decides nothing: it reports what it touched, and the game's rules decide whether that shelves a Pair, is a Hand-off or knocks a Teammate down (GLOSSARY Flight); Q956 a dropped or thrown Pair is a Jolt body then a fixed drawn ball when resting (physics/38); Q960 the seeded layout is accepted after the review build.
- Q1483, Q1489 the merged maintenance batch build is the review build for stickers and the falling-Ragdoll camera. Q1555 the name field stays the keyboard's on the pad route. Q1581 physics/33's priority next. Q1774 merge lobby/06 and give a review build after it is built.

---------------------------------------------------------------------
## Process lessons (how the designer wants work done; for the retrospective)

- Where Jolt can do it, use Jolt; custom physics only when necessary. (Q1200, 2026-11-07)
- Record first, then options: physics/35 was "record first; options for the designer before any change"; the designer then chose one option in a decision note with a plain-words comparison (docs/llm/physics/35-drop-rest-decision.md). (designer 2026-11-07; Q1201)
- A feel complaint ("on client (not host) the throw feel wrong and laggy", 2026-11-11; "if there are lot of socks, taking one sock out takes a lot of time", 2026-11-04; "in the elevator the look position of the character should still be synchronized, now it's glitching", 2026-11-06; "The players feet and body no longer wobbles when moving", 2026-10-31) is investigated by measuring first, then fixing the cause; any feel change that is a design choice goes to the designer as a question before it is built. (multiplayer/35, 27, 32, 28)
- Reports: "Investigate everything, report by severity only; the designer chooses the fixes"; then the designer measures on their PCs with the report's tool before any fix ticket. (Q1814, Q1860, 2026-11-13)
- Stress tests ship as an exe the designer runs on their own PC (a release export, not a debug build): the first run was a debug build and S10 crashed. (Q793, Q814, 2026-11-04)
- Review builds: no separate review build for the Lobby, the designer plays the main build (Q1751); the merged batch build counts as the review for stickers and the falling-Ragdoll camera (Q1489); "Merge and give a review build after the branch is built" (Q1774); a review build with the designer's quoted verdict "Physics looking good." (2026-11-08); "Review build approved, more pronounced: stretch 12% -> 20%, squish 30% -> 45%" (2026-11-08, multiplayer/31); the wash "is good to merge after the designer's review" (Q990).
- Schedule drag, wash and the Elevator ride right after the refactor (designer, 2026-11-05); merge the drag without the Elevator ride (Q984).
- Leftover work from audited tickets is collected into one ticket (Q1145) and stale tickets are closed as wontfix when replaced by a built design (Q1034).
- Steam work starts only when the designer says so (Q1957, 2026-11-18). Questions about a deferred feature (voice, Steam) are grilled when its ticket starts (Q479).
- The agent measures and suggests a number; the designer confirms (Q1101).
- If a built thing costs too much, slow the rate until the count stays in budget (Q1257), rather than redesign.
- Lowered Jolt limits: "the lead applies the `project.godot` lines on main at merge" because `project.godot` carries the designer's uncommitted edits (Q1474; physics/03 and /30 follow-ups).
- The test runner printed PASS when a case raised a script error mid-run: it only added a warning line, which let a Highlight bug through a full run (multiplayer/30, open question for the lead). Headless tests that run one frame per tick never saw frame-rate-dependent bugs such as the waddle (multiplayer/28). A flaky `mess:loading` / `zoo:spawner` pass alone and fail under load (physics/22, multiplayer/23).
- A 2-copy-on-one-PC bug (shared `user://profile.json`) was the designer's own test setup; fixed with ProfileLock (lobby/04).
- Triage priorities: `priority: next` / `later` given 2026-11-11 (Q1580-Q1583): physics/28 later, physics/29 next, physics/30 next, physics/31 next, multiplayer/12 and /13 later, multiplayer/33 next.
- Placeholder wording and looks are listed as `[later]` follow-ups rather than blocking; an agent never decides them (issue-tracker rule). Many lobby follow-ups ask "Which is wanted?" for placeholder looks.

---------------------------------------------------------------------
## Coverage

All 101 ticket files and the 6 other .md files in the five folders were read in number order (107 .md files). `research.md` (28 KB of Godot and Jolt engine facts) was skimmed for designer-quoted rules, not read line by line; `proposal.md` was read whole. Columns: "(Qnnn)" = distinct answers/lines ending in a `(Q...` marker in that file; "Q ids" = distinct Q numbers mentioned in the file (including cited ones).

| folder | file | status | title | answers with (Qnnn | Q ids mentioned |
|---|---|---|---|---|---|
| mvp | 01-first-person-room.md | done | First-person room and player | 0 | 0 |
| mvp | 02-sock-catalogue.md | done | Sock design catalogue (about 200 Designs, 3 Collections) | 1 | 6 |
| mvp | 03-sock-mess.md | done | The Mess: visible mass, live nearby Socks | 2 | 2 |
| mvp | 04-carry-and-pairing.md | done | Hands: picking up, pairing and dropping | 1 | 3 |
| mvp | 05-drawers-and-payout.md | done | The Drawer, payout and the Collection bonus | 1 | 1 |
| mvp | 06-upgrade-station.md | done | Upgrade station and the two Upgrades | 1 | 2 |
| mvp | 07-autosave-and-ending.md | done | Autosave and the ending | 1 | 1 |
| mvp | 08-sound-cues.md | done | Soft sound cues | 1 | 1 |
| mvp | 10-sprint-upgrade.md | done | Sprint Upgrade | 0 | 1 |
| mvp | 11-cabinets.md | done | Cabinets of drawers | 0 | 0 |
| mvp | 12-bedroom.md | done | Bedroom, washing machine and room models | 2 | 2 |
| mvp | 13-sock-variants.md | done | Four rigged Sock shapes, one per Collection | 0 | 3 |
| mvp | 14-cloth-motion.md | done | Cloth motion for held and dropped Socks | 3 | 6 |
| mvp | spec.md | done | MVP: the first playable build | 0 | 0 |
| knockdown | 01-ragdoll.md | done | Ragdoll for knocked-down Avatars | 1 | 1 |
| knockdown | 02-drag.md | done | Drag knocked-down players | 8 | 8 |
| knockdown | 03-wash.md | done | Wash a dragged player in the washing machine | 7 | 7 |
| knockdown | 04-knockdown-with-any-throwable.md | done | Knock players down with anything thrown | 2 | 2 |
| knockdown | spec.md | - | Knockdown: ragdoll, drag and wash | 0 | 8 |
| lobby | 01-worlds-and-groups.md | done | Worlds: the Solo World, five co-op slots and a fixed Group | 30 | 30 |
| lobby | 02-sock-drawer-lobby.md | done | The Lobby: a greyboxed giant sock drawer where everyone gets | 27 | 27 |
| lobby | 03-menu-flow.md | done | The main menu and the flow into a game | 30 | 31 |
| lobby | 04-lobby-fixes.md | done | Lobby fixes after the first play-test | 1 | 1 |
| lobby | 05-lobby-screen.md | done | The Lobby as a screen | 14 | 14 |
| lobby | 06-lobby-pedestals.md | done | The Lobby on pedestals | 9 | 9 |
| lobby | 07-world-sidebar.md | done | The Host's World settings in a Lobby sidebar | 4 | 5 |
| lobby | 08-sidebar-drawer.md | done | The World settings sidebar as an overlay drawer | 0 | 0 |
| multiplayer | 01-split-game-world-and-player.md | done | Split Game into a shared World and per-player state | 3 | 9 |
| multiplayer | 02-command-layer.md | done | Command layer: serialisable commands and host-assigned ids | 4 | 5 |
| multiplayer | 03-split-main-world-and-rig.md | done | Split Main into a world view and a local-player rig | 1 | 2 |
| multiplayer | 04-enet-listen-server.md | done | ENet listen server: Host/Join and join snapshot | 6 | 21 |
| multiplayer | 05-sync-picks-throws-openables.md | done | Sync picks, re-settles, throws and Openables | 5 | 13 |
| multiplayer | 06-avatars.md | done | Avatars: simple body, colour, name tag, visible held items | 6 | 12 |
| multiplayer | 07-co-op-interactions.md | done | Co-op interactions: hand-offs, X-ray mates, messages and sou | 7 | 9 |
| multiplayer | 08-ping.md | done | Ping on middle mouse | 2 | 6 |
| multiplayer | 09-multiplayer-saves.md | done | Saves: host save with guests' Upgrades and positions by play | 5 | 10 |
| multiplayer | 10-mess-scales-with-players.md | done | Mess scales with player count | 9 | 10 |
| multiplayer | 11-end-summary.md | done | End summary: team totals and a line per player | 3 | 4 |
| multiplayer | 12-steam-peer.md | needs-info | Steam peer (GodotSteam) | 18 | 21 |
| multiplayer | 13-proximity-voice-chat.md | ready-for-agent | Proximity 3D voice chat | 3 | 7 |
| multiplayer | 14-session-menus.md | done | Session menus: Play, straight-in Join, Leave and End session | 7 | 10 |
| multiplayer | 15-predict-cycle-drop.md | done | Guests predict the wheel and drops | 3 | 4 |
| multiplayer | 16-save-and-size-followups.md | done | Saves drop guests' Hands, a loaded game resumes in place, Ho | 5 | 13 |
| multiplayer | 17-sock-creature-avatar.md | done | Sock creature avatar and its first wardrobe | 10 | 11 |
| multiplayer | 18-menus-and-messages.md | done | Singleplayer and Multiplayer screens, refusal messages, hand | 11 | 13 |
| multiplayer | 19-ping-emoji-wheel.md | done | Ping emoji wheel and highlight | 3 | 5 |
| multiplayer | 20-avatar-wardrobe.md | done | Sock-creature avatar in game and the Wardrobe | 2 | 12 |
| multiplayer | 21-avatar-look-bend.md | done | The sock creature bends with its player's look | 2 | 2 |
| multiplayer | 22-throw-knockdown.md | done | A full-charge Throw knocks a teammate down | 1 | 3 |
| multiplayer | 23-knockdown-feel.md | done | Knockdown: a wonky physics fall, and who did it | 2 | 2 |
| multiplayer | 24-knockdown-collides.md | done | A knocked-down body collides | 2 | 2 |
| multiplayer | 25-lying-body.md | done | A lying body blocks; a fall by a wall slides down | 3 | 3 |
| multiplayer | 26-avatar-co-op-touches.md | done | Teammate throws from the hand, darker trim, teammates block  | 3 | 3 |
| multiplayer | 27-menus-and-session-messages.md | done | Keycap end summary, join/leave messages, solo ESC exits | 3 | 4 |
| multiplayer | 28-waddle-regression.md | done | The waddle stopped | 0 | 0 |
| multiplayer | 29-crouch-highlight-and-pings.md | done | Crouch Highlight, bigger Pings and emoji bubble | 0 | 3 |
| multiplayer | 30-highlight-primitive-mesh.md | done | multiplayer/30: Highlight on a primitive mesh | 0 | 0 |
| multiplayer | 31-avatar-jump-squash.md | done | Squash and stretch on the Avatar's jump | 1 | 1 |
| multiplayer | 32-elevator-look-sync.md | done | A riding player's look direction glitches in the Elevator | 1 | 1 |
| multiplayer | 33-validate-guest-rpc-payloads.md | done | The Host checks what a Guest's RPC carries before using it | 2 | 2 |
| multiplayer | 34-drop-row-out-of-bounds.md | done | A Guest's pick can hit an out-of-bounds save row on the Host | 0 | 0 |
| multiplayer | 35-guest-throw-feel.md | done | On a Guest the Throw feels wrong and laggy | 4 | 4 |
| multiplayer | 36-profile-secret.md | ready-for-agent | A per-player secret so a Guest cannot take another player's  | 1 | 1 |
| multiplayer | 37-guest-fps-investigation.md | ready-for-human | Low FPS on the Guest over the internet: find the cause | 5 | 5 |
| multiplayer | spec.md | needs-triage | Multiplayer: co-op in one shared flat | 6 | 52 |
| physics | 00-research.md | done | Research and a proposed architecture for Sock physics and ne | 5 | 6 |
| physics | 01-stress-test.md | done | Stress-test scene with our own measurement monitors and an e | 2 | 5 |
| physics | 02-baseline-run.md | done | The designer runs the baseline stress test on their PC | 3 | 4 |
| physics | 03-engine-settings.md | done | Engine settings: 30 and 60 Hz modes, physics interpolation,  | 2 | 8 |
| physics | 04-adr-two-tier-socks.md | done | ADR-0008: two-tier Socks, and the ADR amendments | 2 | 8 |
| physics | 05-sockworld-core.md | done | SockWorld core: Sock records, states, static rest colliders, | 8 | 11 |
| physics | 06-wake-and-rest.md | done | Waking and resting: the Active budget, impacts, movers and t | 7 | 7 |
| physics | 07-sock-and-pair-colliders.md | done | Sock and Pair colliders: two boxes versus three; the Pair sp | 4 | 4 |
| physics | 08-house-shell-collision.md | done | Authored collision for the house shell and layout | 1 | 3 |
| physics | 09-furniture-collision.md | done | Authored collision for every furniture piece | 3 | 5 |
| physics | 10-elevator-collision.md | done | Authored collision for the Elevator | 3 | 11 |
| physics | 11-live-spill.md | done | A seeded Sock layout per game in under 5 seconds | 6 | 7 |
| physics | 12-hands-drop-throw.md | done | Picks, drops and Throws on SockWorld | 1 | 1 |
| physics | 13-vacuum-and-machine.md | done | Sock vacuum and pairing machine on SockWorld | 3 | 4 |
| physics | 14-rogue-spew-arcs.md | done | The rogue machine's decorative Socks on scripted arcs | 3 | 3 |
| physics | 15-replication.md | wontfix | Sock replication: the snapshot stream, priority, interest an | 2 | 2 |
| physics | 16-guest-prediction-and-picks.md | wontfix | Guest prediction of their own Throws and drops; Host checks  | 3 | 3 |
| physics | 17-late-join-and-saves.md | done | One compact encoding for late join and saves | 3 | 3 |
| physics | 18-ragdolls-on-heaps.md | done | Ragdolls on the new collision layers | 2 | 2 |
| physics | 19-network-stress.md | done | Network stress through a lossy relay | 2 | 2 |
| physics | 20-rendering-10k-socks.md | done | Drawing 10,000 Socks on integrated graphics | 2 | 2 |
| physics | 21-socks-fall-through.md | done | Socks fall through the floor in the stress test | 3 | 3 |
| physics | 22-switch-to-sockworld.md | done | Switch the game from the old Mess to SockWorld | 4 | 5 |
| physics | 23-elevator-contents-rules.md | done | The Elevator car's contents: physics at a stop, data while r | 7 | 9 |
| physics | 24-unlocked-door-leaf.md | done | Socks meet an unlocked floor's door leaf as it swings | 0 | 1 |
| physics | 25-cloth-cap.md | done | Cap and cheapen the cloth animation | 2 | 3 |
| physics | 26-game-limits-and-fast-ccd.md | done | The game's Jolt limits, thicker floors, and CCD only for fas | 4 | 4 |
| physics | 27-pick-hitch-big-heaps.md | done | The game freezes briefly when a Sock is picked from a big He | 3 | 3 |
| physics | 28-spawn-clear.md | ready-for-agent | Keep the players' spawn spots clear of Heaps | 2 | 2 |
| physics | 29-house-collider-budget.md | needs-info | The house's collider budget | 5 | 5 |
| physics | 30-jolt-buffers-in-game.md | ready-for-agent | Jolt's contact buffers in the game | 3 | 3 |
| physics | 31-stress-verdicts.md | ready-for-agent | The SockWorld stress verdicts that are still missing | 2 | 3 |
| physics | 32-bake-spaces-pool.md | done | The Mess bake's tile spaces in a pool | 0 | 1 |
| physics | 33-no-space-queries-in-process.md | done | Physics space queries run in the physics tick, not in the re | 4 | 4 |
| physics | 34-jolt-limits-step-cost.md | wontfix | What the raised Jolt limits cost each step | 2 | 3 |
| physics | 35-drop-throw-one-motion.md | done | A dropped or thrown item moves as one motion | 22 | 24 |
| physics | 36-two-release-systems.md | done | Two release systems: physical (Socks, Pairs) and items | 7 | 8 |
| physics | 37-machine-pairs-jolt.md | done | The pairing machine's rolled Pairs as Jolt bodies | 2 | 2 |
| physics | 38-resting-pairs-wake.md | done | Resting Pairs fall when what holds them up goes | 2 | 3 |
| physics | 35-drop-rest-decision.md | - | Q1201: where does a dropped item come to rest? | 4 | 5 |
| physics | proposal.md | done | Physics and networking for 10,000 Socks: proposed architectu | 40 | 56 |
| physics | research.md | - | Physics and networking for 10,000 Socks: research | 4 | 10 |

**Counts.** Lines with a `(Q` marker: physics 231, multiplayer 155, lobby 145, knockdown 27, mvp 15 (573 lines, many repeated across tickets: the lobby answers Q1642-Q1665 are repeated in lobby/01, 02 and 03). Distinct Q numbers mentioned: 365 across the five folders (physics 128, multiplayer 155, lobby 60, knockdown 17, mvp 19 with overlap). Distinct designer answers marked `(designer, date)` without a Q number: about 21 lines. Of the 365 distinct Q numbers, 322 appear in this digest by number; the other 43 are in section F above (all 43 now cited). The brief's "600 answers" counts repeated lines; the distinct ones are about 365 plus about 15 unnumbered designer statements.
**Gaps and what I could not determine.**
- mvp/spec lists "Decisions still open" (02-numbers-and-curves, 03-rare-found-later, 04-mvp-collections, 05-sound-source) that are not in my folders; their answers (balance round Q477, questions/06) are not in this digest.
- Q477 / questions/06 (the balance round) holds many placeholder numbers cited as "moved to the balance round": not read here.
- Core-loop controls beyond what the glossary and my tickets give (pick reach, the exact drop highlight rule, sprint speed, jump height, crouch speed) live in flat/ and house/ tickets and `data/tuning/*`; not in my folders. Sprint 1.3x is the data value (`upgrades.json sprint.multiplier` 1.3; the MVP built 1.6x), so the data holds; unchecked beyond that.
- Whether the Sock vacuum is still live in the game and whether Q1687 or Q1662 holds for Steam address join: unchecked.
- Hand-off rule details (Q658 completes a Pair) come from the glossary, progression spec not in my folders.
- multiplayer/20 built log tail (the lines after "Shots mp20_360.png") was cut in my read; nothing rule-bearing is expected there.
