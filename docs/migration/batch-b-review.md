# Batch B review sheet

What the designer plays at the end of batch B (progression: Coins and Drawers, the Old Tree and the Upgrade grid,
Stage presents and Gifts, the Wardrobe, Collections unlocking, the Profile and encyclopedia, Achievements; Q2614), in
one session (Q2605), and what the agents settled on their own along the way (Q2604). The build order:
`docs/migration/milestones.md` "Batch B". The designs: `docs/architecture/economy.md`, `gifts.md`, `wardrobe.md`.

## How to use it
Play a house New Game from the title, Solo first, then with a Guest, through at least Stage 2 (the first presents,
Q2678) and on to the Final screen (the debug "Pairs per Drawer" slider at 1 makes the run short; F9 gives the Host
1000 Coins for the Upgrade grid). Then open the Wardrobe, the encyclopedia and the Profile from the title and the
Lobby. For each line say yes, or what to change; a change becomes a ticket. The asset line-ups are in
`builds/review-assets-<NN>/`, the Trails' strip in `builds/review-trails/`.

## What you play, by ticket

| Ticket | What to look for |
|---|---|
| core/124 Coins and Drawers | the two counters at the top left; a shelved Pair's "+N" over the drawer and its flight; a filled drawer's Drawers "+1" in the House blue; a floor's +100 and a Cabinet's +50 counting up with no "+N" (Q2667, Q2668); Coins still flying not yet spendable (Q2672) |
| core/125 Collections as data | the Collections station: every Collection's colours, Cabinet name and wrapping; the Lost Socks held back (Q2675) |
| core/126 Spawned Parts | nothing to see on its own: presents ride on it (a crate in the Gifts station) |
| core/127 Profile and tallies | the five Lifetime tallies count in your profile (see them on the Profile page, core/147) |
| core/128 Pieces and the Avatar | the Wardrobe station: every piece worn, the swish, the hat lifting the name tag, Lint puffs behind the steps; the ten basic pieces yours from the start (Q2679) |
| core/129 Upgrades and the menu | E at the Old Tree; the grid of icon buttons, levels, prices, locks, MAX, the tip card, the shake on a refusal; the batch C Upgrades greyed "Coming soon" (Q2669) |
| core/130 Personal Upgrades | Footwork, Sprint (Shift), Quick Grab, Big Hands, Long Arm, Quick Charge change play; a Guest's Big Hands |
| core/131 Sole cues | with a Guest: Sole Mates' outline in their colour and the `match` sound, Sole Hands, Mate Radar through walls (Q2671) |
| core/132 Old Tree's voice | its call after the First wash, first and greet lines, affordable and bought; heard only near it; nothing on the tree moves (Q2670) |
| core/133 Old Tree's help | grumbles, the Stage's half/most/last, room and floor hints, the two tips, the Fix comments, the Final wash and peace lines |
| core/134 Encyclopedia record and unlocks | a finished game unlocks the next Collection on the Final screen's strip |
| core/135 Pools and the draw | each New Game draws the Cabinets' Collections from their rooms' pools |
| core/136 Encyclopedia pages | the title's encyclopedia key; collected Designs and "???"; no Lost Socks page |
| core/137 Presents | presents drop under the Old Tree after a Stage that completed a Collection (none after Stage 1, Q2678), labelled, turning; "[LMB] Pick up", "[LMB] Open" (Q2677); a Teammate's box not aimable; the Machine Part popping clear of lying presents (batch A's question 4) |
| core/138 Opening | the shake, hop and pop seen by everyone; the reveal of the piece; "Already yours: +75 Coins" only when you own every piece (Q2673); the pieces on the Final screen |
| core/139 The book | the book on the workshop's workbench: one Hands slot, E reads your pages |
| core/140 Present lines | the tree says presents are waiting and comments on a taken one |
| core/141 Looks in co-op | a Teammate sees your look and colour; a colour already taken is refused |
| core/142 Wardrobe page and station | the wardrobe in the parents' bedroom: the doors, the page, the colour row, "N/M unlocked" without the Lost Socks' six (Q2683) |
| core/143 Lobby key and card | the Wardrobe key by your figure clears Ready; a Teammate's stats card |
| core/144 Trails | the strip: all 17 Trails remade as particles, judged on stills (Q2680) |
| core/145 Achievements | the system only: no list ships in batch B (Q2687); its station shows the toast with test entries |
| core/147 Profile page | the title's Profile key and the ESC menu's entry; the tallies on top, the Achievements under them (Q2681) |
| assets/16-20 | the line-ups: the present box, the book, the hats and clothes, the Socks pieces and Trail meshes, the Wardrobe station |

## The lead's readings to confirm
- Q2673's "another unlocked Collection": the Host's unlocked set (the one the New Game's draw used), since the Host
  knows no other; a Guest with a different unlocked set gets pieces from the Host's.
- A present holding a piece of another Collection keeps the wrapping of the Collection the Stage completed.
- The Old Tree's lines are copied unchanged and play at the old +12.5 dB, applied at playback as the old player's volume (`OldTreeTuning.voice_db`), so they clip only where the old clipped, up close: baked into 16-bit copies it clipped 2.3 % of every recording (core/132; the lead's reading of Q2638 for a faithful port).
- Batch B ships no Achievement (Q2687): the Profile page shows the tallies and "0 / 0 earned".

## Questions for the designer (end of batch B)
Collected while the batch builds unattended. Each is answered in play or here; a change becomes a ticket.

## Settled by the old game (Q2604)
Each agent adds a line here for an open choice it met and settled by the old game's answer (or the nearest): the
ticket, the choice, what it did, the old file:line. The designer confirms or changes each in play.

| Ticket | The choice | What was done (the old answer) | Designer |
|---|---|---|---|
| assets/17 | Which materials does the book share with the library? | `brass` (the old's brass, same colour) and `pink` (the ribbon, same colour) are the library's; the cloth, leather and cream paper stay the book's own (the library's `paper` is near-white, the old's cream); no collider (the entity's box) (old `make_encyclopedia_book.py`) | |
| core/124 | Does the Cabinet bonus pay in a level with no run (a zoo station's Cabinet)? | Only in a level with a run: the bonus is the campaign's (the old `cabinet_batch` paid from the campaign's Rows only) | |
| core/124 | Does a zoo or test fill pay Drawers? | Yes, every drawer filled to the Pairs per Drawer pays (the old CBS:290 paid for the zoo's and tests' fills too); 1 Drawer with no run | |
| core/124 | A floor opened by a load cut short during its Fix (the floor opens after the load) | Pays the floor bonus then, as any opening (the old step() opened it the same way, CA:348-353) | |
| core/124 | The corner's network line ("Playing alone", "Hosting on port ...") sat where the counters go | Moved below the counters (the old HUD had the counters top left, HUD:132-138) | |
| core/129 | How the House prices are re-scaled to 0.9 x the 33 Drawers the house pays (Q1405) | 30 in all, the old proportions: each old price x 30/21 by largest remainder (every 2 becomes 3); of the eleven 1s the four ties that go up to 2 are the second levels of Big Bag, Long Hose and Strong Suction and its third (Elevator Repair, the gate, stays 1). Elevator Repair 1, Fast Elevator 3/3, Roomy Car 3, Big Bag 1/2, Strong Suction 1/2/2, Long Hose 1/2, Wide Nozzle 1, Filter nozzle 3, Sole Mates 3, Sole Hands 1, Mate Radar 1 (the old D Numbers rule; UJ:365-812) | |
| core/129 | "Need {coins} 120": the old HUD drew the currency's icon inline | The port's message row is text: "Need Coins 120" / "Need Drawers 2", as the cheat's "Debug: +1000 Coins" (core/124) (the old UP:409-424, HUD:615) | |
| core/132 | How many Old Tree recordings to copy ("162 less" the unported ones) | The old folder holds 161; less `tip_dirty` (1), `tip_pairing` (3) and the three Grotto groups (12): 145 copied, every one with its old text and segment times (the old `data/voiceover/old_tree/`) | |
| core/132 | A call's level and reach | The same level as every line (the old `call_db` 12.5 = `voice_db` 12.5), carrying 16 m and subtitled within 16 m with no level band (OTV:427, OTV:465) | |
| core/132 | An Upgrade newly affordable on a first visit | Said in place of the greeting, so the player is not met yet and the next greeting is the "first" line (the old order, OTV:274) | |
| core/132 | The lines of core/133's, core/140's and batch C's moments | Copied with no trigger (the JSON's note names the owner and the trigger id); `final_wash` and `peace` marked `waits` (story beats) | |
| core/132 | The Old Tree's subtitle icon | None: the Theme's plain disc (the old row had no icon); a drawn icon is a look ticket | |
| core/129 | The close key: the old "[ESC] Close" at the bottom right | The port's close key at the panel's top right, as every dialogue (Q2578); Esc and a pad's B shut it (the old UM:14) | |
| core/129 | menu_open, menu_close: which sound | Silent, as the old (the designer's "No sound" in the old sounds.json); `buy` is the old pick cc0/kenney_coins, `refuse` the existing one | |
| core/129 | Big Hands' icon (the old `upgrade_carry`, no file) | The HUD's carry icon (`assets/ui/carry.svg`), the old Icons fallback for it | |
| core/129 | Whether a menu click predicts the refusal | No: the click asks the Host and the answer shakes the button and says why (the old shook at once on its own check, UM:399-425); alone or on the Host the answer is the same frame | |
| core/129 | The X-ray titles | "X-ray: Show pair (key 1)", "Cabinet X-ray: Show drawer (key 2)" as the old menu titles (UM:18-20), so "Needs:" and the teammate line read "X-ray: Show pair" | |
| core/135 | A Cabinet with no pool in a level that draws (a spot kept as placed) | Keeps its placed Collection and no other spot draws it (the old pools listed every spot, CPO:193-262; the port empty pool is the zoo stations way) | |
| core/135 | The order spots are solved in | Fewest choices first, then in tree order, a seeded shuffle of each pool first (the old _order and _solve, CPO:216-262) | |
| core/134 | Is the start set always unlocked beside the profile's own list? | Yes: the draw uses the start set plus the profile's `collections` (a version 1 profile stores none; the old read its start set into every profile, CP start) | |
| core/134 | What counts for the encyclopedia when a Guest's snapshot arrives or the level is not settled? | Nothing: only applied answers record (the old recorded on its own shelve events, PR:111-121) | |
| core/134 | The unlock reveal's timings | The old's 0.6 s delay, 0.25 s gap and 0.5 s pop with overshoot (the clip in `unlock_cell.tscn`); delay and gap are `FinalScreenTuning`'s, placeholders (ES:655-731) | |
| core/145 | The Achievement chime | The old never made one (designed, Q1695); the nearest synthesised clip of the old bench, `part_pop__c` ("two rising chimes, something new found"), is the first candidate, at -6 dB on the UI bus (old `tools/gen_sounds.py` `_part_pop_c`) | |
| core/145 | How long the HUD says "Wardrobe: <name> unlocked", and several at once | 2 s, every piece of one check named in one line, ", " between (old `hud.gd:676`, `profile_installer.gd:104-105`) | |
| core/145 | The debug keys for grant all and reset (Q1696 names none) | F7 grants all, F8 resets (beside F3 stats and F9 Coins; the old had none) | |
| core/145 | The toast's slide | 0.35 s in from the right edge, eased, and out the same way (the old never built one; `AchievementTuning`) | |
| core/145 | The toast's card look | The Theme's existing cream keycap card `UpgradeTipPersonal`, caption `InkLabel`, title `UpgradeTipTitle` (no new Theme entry) | |
| assets/20 | Which of the wardrobe's materials are the library's? | `oak`, `dark_wood` and `brass` (the old's colours; the library's roughness 0.6 for dark wood against the old 0.5, metallic 0.8 for brass against 0.85); cream, birch and the fabric palette stay the wardrobe's own; no collider (the station's box) (old `make_wardrobe_station.py:65-71`) | |
| assets/20 | The doors' easing and how long they take to shut | `open` 0.7 s in-out (key easing -2, the port's door ease), `shut` 0.7 s ease out (key easing 0.56, the port's sine ease out); the old swung both ways in the same swing_time with TRANS_SINE (old `game/player/wardrobe_station.gd:24,37`, `openable.gd:171-172`) | |
| assets/20 | What the outline draws | The two doors only, an `Outline` in the Looks with their paths (old `wardrobe_station.gd` highlight_meshes: the doors) | |
| core/147 | What does the Profile key show, how is an earned date written, how does the ESC menu hold the page? | The key is a gold star (`game/profile/profile_key.svg`, no old icon exists: the old game never built the page); the date is ISO "2026-11-26"; the page opens over the ESC menu, whose own panel steps aside while it shows (the old pause menu shows one panel at a time) | |
