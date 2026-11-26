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
- The Old Tree's lines are copied with the old +12.5 dB baked into the recordings once (the game adds no gain, Q2638).
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
| core/129 | The close key: the old "[ESC] Close" at the bottom right | The port's close key at the panel's top right, as every dialogue (Q2578); Esc and a pad's B shut it (the old UM:14) | |
| core/129 | menu_open, menu_close: which sound | Silent, as the old (the designer's "No sound" in the old sounds.json); `buy` is the old pick cc0/kenney_coins, `refuse` the existing one | |
| core/129 | Big Hands' icon (the old `upgrade_carry`, no file) | The HUD's carry icon (`assets/ui/carry.svg`), the old Icons fallback for it | |
| core/129 | Whether a menu click predicts the refusal | No: the click asks the Host and the answer shakes the button and says why (the old shook at once on its own check, UM:399-425); alone or on the Host the answer is the same frame | |
| core/129 | The X-ray titles | "X-ray: Show pair (key 1)", "Cabinet X-ray: Show drawer (key 2)" as the old menu titles (UM:18-20), so "Needs:" and the teammate line read "X-ray: Show pair" | |
| core/135 | A Cabinet with no pool in a level that draws (a spot kept as placed) | Keeps its placed Collection and no other spot draws it (the old pools listed every spot, CPO:193-262; the port empty pool is the zoo stations way) | |
| core/135 | The order spots are solved in | Fewest choices first, then in tree order, a seeded shuffle of each pool first (the old _order and _solve, CPO:216-262) | |
