# Batch A review sheet

What the designer plays at the end of batch A (the run and the washer, Q2606), in one session (Q2605), and what the
agents settled on their own along the way (Q2604). The build order: `docs/migration/milestones.md` "Batch A". The
designs: `docs/architecture/stages.md`, `run-ends.md`, `washer.md`, `voice.md`.

## How to use it
Play a house New Game from the title, Solo first, then with a Guest, through to the Final screen and back to the Lobby
(the debug "Pairs per Drawer" slider at 1 makes the run short). For each line say yes, or what to change; a change
becomes a ticket. The asset line-ups are in `builds/review-assets-<NN>/`.

## What you play, by ticket

| Ticket | What to look for |
|---|---|
| core/76 Stages | a New Game starts at Stage 1, only the basement's Cabinets unlocked; the garage Cabinet sheeted; the World's row in the Lobby names the floor |
| core/77 A Stage's Socks | only the basement holds Socks at first; after each Fix the new Socks lie over every open floor in even shares (Q2617); with two players a few lie on high spots |
| core/78 Carrying | a Part and a bin take the whole Hands, ride steady in front, go down at the crosshair turned as held, into a Teammate's empty Hands |
| core/79 Machine Parts | the Part pops out of the Cabinet that took the last Pair, turns and bobs with its glow; the readout names it |
| core/80 Floor locks | the door and the gate, the padlock's hint "Please the washing machine", the pop, the chain, the swing, the lamps |
| core/81 Cabinets grow | the new Drawers drop in at once with a thunk and dust (Q2620) |
| core/82 Stage bar | "Wash the laundry" before the First wash; "Stage 2: Ground  83/175"; full until the Fix; the fold into "Wash clothes n/3" (wording: the lead's reading of Q2621, the old was "Laundry bins loaded: n/3") |
| core/83 Tallies | the Whiteboard and Tab: Pairs shelved, Socks picked, Coins earned per player |
| core/84, core/85 Voice | every washer line's subtitle, timing and mouth in the Voice station; the muffle behind a shut Door; the music duck in cutscenes |
| core/86 Washer | where it stands, the stare comments (silent before the First wash, Q2636), the comment sets by Stage, Stage 4's in the Laundry day (Q2635) |
| core/87 Broken looks | sparks, smoke, buzz and the drum light's flicker by mood, calmer each Fix |
| core/88 Cutscene frame | the shots and cuts, the fades, nothing but the washer drawn, the Host's skip, the respawn |
| core/89 Spray | the spray of Socks out of the door at the First wash and after Fixes 1-3 |
| core/90, core/93 Laundry bins and Laundry day | the seven bin spots (placed by eye), the tip, the pile behind the porthole, the refusals |
| core/91 The house's run | the whole run in the house, Stage by Stage |
| core/92 Fix scene | cutscene_2 to cutscene_5, each whole (cutscene_5 mentions the cave system: Q2634) |
| core/94 First wash | the calm wash, the break, cutscene_1, the spray, the bin still full in the Hands |
| core/95 Final screen | columns of the players at the end (Q2630), the Pairs popping in, the totals, the skip; stills of 1, 2 and 4 players and a long name in `builds/review-final-screen/` |
| core/96 Final wash | the happy wash, the push-in, cutscene_6 whole, the Final screen on every machine |
| core/97 Back to the Lobby | Continue from a Guest; the finished World as a record; Start asks before replacing it |
| core/98 Knockdown wash | drag a knocked Teammate to the door: the spin, the burst out |
| assets/10-15 | the line-ups: floor locks, Cabinets at six Drawers, the Parts, the Laundry bin, the washing machine, its subtitle icon |

## The lead's readings to confirm
- Voice level (Q2638): no game gain, so every line plays at 0 dB; the old comments were +6 dB because the clips are
  quiet. They will sound quieter than the old until the recordings are fixed at the source.
- The Laundry day's bar text "Wash clothes n/m" (Q2621's example taken as batch A's wording).
- The Machine Part goes into a Teammate's Hands by core/42's Hand-off too; the bin does not (core/71's proposal).

## Settled by the old game (Q2604)
Each agent adds a line here for an open choice it met and settled by the old game's answer (or the nearest): the
ticket, the choice, what it did, the old file:line. The designer confirms or changes each in play.

| Ticket | The choice | What was done (the old answer) | Designer |
|---|---|---|---|
| core/100 | Jolt penetration slop (Socks under a heap sink up to about 1 cm) | kept Jolt's default 0.02 m, the watch counts only pushes | reference/it-socks/project.godot:257-260 (no slop set) |
| core/78 | What `Carriable.handable` switches (the docs say the bin refuses core/42's Hand-off, yet its behaviour line says a right click at a Teammate puts it in their Hands) | built as the switch of that right click: on, into their empty Hands or at their feet ("Hands full" for them); off, a plain drop at the crosshair. On by default and on the stand-in crate, since the old game handed both a bin and a Part over that way (`game/campaign/laundry.gd:507-513` decide_drop, `game/player/rig_drop.gd:47-52`); core/72 sets the bin's | |
| core/78 | A carried thing's crosshair row and corner hint | carried: its name with no key; lying: its name with the left-click key only for empty Hands; the corner says "Drop" with the right button (no Zoom, Turn, Throw) (`game/ui/prompts.gd:24-26`, `:101`) | |
| core/78 | Which way a thing laid at a full Teammate's feet or by a leaver turns | at the turn it last lay, as the old (`game/campaign/laundry.gd:530-536`, `:746-755`) | |
| core/78 | Where a thing put down rests | at the crosshair's point on the top (the drop's own place check); the old found the highest top under the thing's whole footprint (`game/world/landings.gd:190-223` landing_of) | |
