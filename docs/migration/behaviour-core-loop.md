# Core loop: behaviours to approve before the first port

Read-only survey of `main` (2026-11-19). Words follow `GLOSSARY.md`. "Today's value" means the number the code uses now (tuning key given), not a decision. Test ids are `suite:case` from `tests/`. "Untested" means I found no case asserting it in the suites I read. Co-op is read three ways in every row: a Guest (a second machine, the Host decides), a race (two players at once, the Host takes the first to arrive), a late joiner (joins from the Host's snapshot).

How a Guest plays, in one paragraph, because most co-op notes depend on it: the Host runs every rule. A Guest's pick, wheel, drop and Throw show at once on their machine and are confirmed or undone by the Host's answer. A Guest's shelve, hand-off, Door and drawer clicks wait for the Host's answer. Contact outcomes of a Throw (shelved, caught, knocked down, landed) are the Host's alone and every machine plays the same result.

Rows are grouped: Mess (M), Hands (H), Throws and catching (T), Pairs (P), Cabinets and Drawers (C), Doors (D). Door and openable rows are kept with Cabinets because the click that opens a drawer is the same click that opens a Door.
# Core loop: behaviours to approve before the first port

Read-only survey of `main` (2026-11-19). Words follow `GLOSSARY.md`. "Today's value" means the number the code uses now (tuning key given), not a decision. Test ids are `suite:case` from `tests/`. "Untested" means I found no case asserting it in the suites I read. Co-op is read three ways in every row: a Guest (a second machine, the Host decides), a race (two players at once, the Host takes the first to arrive), a late joiner (joins from the Host's snapshot).

How a Guest plays, in one paragraph, because most co-op notes depend on it: the Host runs every rule. A Guest's pick, wheel, drop and Throw show at once on their machine and are confirmed or undone by the Host's answer. A Guest's shelve, hand-off, Door and drawer clicks wait for the Host's answer. Contact outcomes of a Throw (shelved, caught, knocked down, landed) are the Host's alone and every machine plays the same result.

Rows are grouped: Mess (M), Hands (H), Throws and catching (T), Pairs (P), Cabinets and Drawers (C), Doors (D). Door and openable rows are kept with Cabinets because the click that opens a drawer is the same click that opens a Door.

## 1. Behaviours per feature

### Mess (M)

The Mess is the players' word for every Sock lying in the house; the code keeps them in one World record (no Mess module exists). Laying, hiding, picking-by-aim and the rest rules are here; what a click does with a Sock is under Hands.

| id | When ... | then ... | co-op note (Guest / race / late joiner, or "same") | where it is tested today | kind |
|---|---|---|---|---|---|
| M01 | When a normal New Game begins | then no Sock lies anywhere in the house until a player clicks the first dirty bin into the washing machine; the machine then breaks and the first batch of Socks sprays out of its door and lies in Heaps, on furniture and in Hiding spots. (With the campaign off, the Mess is simply there at the start.) | A Guest can start it; every machine plays it; a joiner who arrives mid-cutscene sees the finished state | first_wash:start, play, no_cutscene, once, coop | rule |
| M02 | When the Mess is laid (New Game or a later batch) | then every Design in play has exactly two Socks, so every Sock has its mate somewhere. | same | mess:bake; players:small_bake; spawning:bake, grotto_spawn | safety |
| M03 | When a New Game's first batch lies | then it holds only Socks of the basement's Cabinet (Basic; today's value 50 Pairs), and a lesson Pair lies flat on the washing-machine top, pickable from the spawn. | same (Guests spawn at the washer too) | spawning:new_game; mess:lesson | rule |
| M04 | When a floor's Fix completes | then a new batch of Socks (the Designs of the Cabinets that floor unlocks, enough to fill their new Rows; today's batch sizes 160, 150, 130, 50 after the first 50) is laid over the unlocked floors, onto the Mess and never inside a Sock already lying. | Guest sees the same Socks with the Host's ids and poses; a joiner is told what is still due | spawning:designs, spawn, land, zoo, spawn_paced; mess:spawn_onto | rule |
| M05 | When a Fix's cutscene ends (every Fix but the one before the drum) | then the new batch flies out of the machine's door in front of it and lands, with no Sock falling through the floor. | every machine plays it | first_wash:spit, spit_stages, spit_timeline | look/sound |
| M06 | When a batch is laid | then Socks lie in Heaps (many under others, standing up off the floor), on furniture tops, under the bed, sofa, coffee table and kitchen table near their open edges, inside the openables (fridge, cupboards, drawers, oven, laundry basket, toy chest...), about 3 on the litterbox litter, and thickest by the washer. | same | mess:bake, under, basket, litterbox | layout pin |
| M07 | When a batch is laid | then each level holds about its tuned share of the Socks (tuning mess.spill.level_shares; today's values, not a decision). | same | mess:levels | feel |
| M08 | When a batch is laid | then rarer Designs hide more often (inside openables, under furniture, deeper in Heaps): weights today common 1, uncommon 1.5, rare 3 (mess.hiding_weight). | same | mess:rare_hide | feel |
| M09 | When you look for a Sock's mate | then it lies a walking distance away (through doorways and stairs, never through walls) that grows with progress (today 0.4 m to 6 m) and with rarity (x1, x1.4, x2); half of the rare Designs have their mate on another level, a trip up or down the stairs. | same | mess:distance, walk, across | feel |
| M10 | When the Mess is laid | then every Sock rests on what is drawn: none floats, none sinks into furniture, walls or floors, none is shut inside a piece of furniture, none lies in front of a Cabinet. | same | mess:rest_fit, bake | safety |
| M11 | When a New Game starts | then it picks its own random layout and the save keeps it; the same layout seed lays the same Mess. | Guest gets the Host's Mess | mess:seeded; world_codec:snapshot | rule |
| M12 | When the crosshair rests on a Sock within reach (today 2.5 m) while standing | then it is outlined and a left click can pick it; the first Sock on the aim line wins; the floor beside a Sock and a Sock out of reach pick nothing. | Guest: the pick shows at once and the Host confirms (see H17) | mess:pick; sockworld:aim; hands:pick_sweep | rule |
| M13 | When a Sock is covered by another Sock but its tip sticks out | then aiming at the tip picks the lower Sock and the Socks on it stay; a Sock under furniture is pickable standing, no crouch rule. | same | mess:covered, under | rule |
| M14 | When a wall (or a shut Door) lies between you and a Sock | then the Sock is not outlined and cannot be picked, not even a little way past the wall (3 cm of slack today). | same | sockworld:pick_walls, aim_walls | rule |
| M15 | When a fridge, oven, cupboard or drawer is shut | then the Socks inside cannot be aimed at; one click opens it and they can be picked; another click shuts it. A drawer carries its Socks and sock balls out and back every frame it slides. | Guest sees the Socks ride out on the drawer; a joiner sees an open fridge open | mess:openables, oven, drawer, drawer_ride; net_devices:drawer_ride; net_join:snapshot | rule |
| M16 | When a Sock is taken from a Heap | then the Socks that rested on it come loose and settle again close by (at most 40 wake; the Sock beside it does not); they stay Resting once settled. | Host decides the wake; the Guest sees the same settling | mess:resettle; sockworld:pick_wakes, rest_per_sock; net_commands:drop_settle | rule |
| M17 | When many Socks are Moving at once | then at most 512 Socks are Moving in all (32 kept for Throws and drops), 16 are woken per tick nearest the player first, and a Throw wakes at once (today values). | Host runs the budget | sockworld:budget, impact, sweep | feel |
| M18 | When you walk over Resting Socks | then they do not wake or move; a ragdoll lies on them without waking them. | same | sockworld:walk_lie | feel |
| M19 | When a Sock or Pair ends up outside the flat (below the floor by 0.3 m, above the ceiling, past walls) | then it lies scattered in front of the washing machine with a pop; one sunk into a floor slab is pushed up onto that floor where it was, with no pop; a Sock dropped on a high shelf, the fridge or into the basket stays. | Host decides; both machines lay it at the same spot; a leaver's Hands too | lost:rule, let_go, slab, settle, ceiling, walls, stays, load; net_commands:lost; net_devices:slab | safety |
| M20 | When a drawn Mess is shown | then every Sock is drawn and picking one shrinks the drawn Mess by one. | same | mess:drawn | look/sound |
| M21 | When a New Game or a load starts | then a loading screen hides the flat while the Mess is laid over several frames (a paced bake lays the same Mess as an unpaced one); you can move once it is gone. | Host listens for Guests only after the bake settled; a bake never starts with Guests connected | mess:loading, paced; net_join:bake_first | look/sound |
| M22 | When you pick from a big Heap (10,000 Socks in the house) | then no frame is visibly dropped, autosave included. | same | mess:pick_hitch, pick_hitch_big | feel |
| M23 | When a Guest joins | then they get the same Mess (same Socks, ids, poses, floor Pairs, shelf, open fridge) and the Mess does not grow or shrink because of them; a Mess is the same size for 1 to 4 players today (mess.pairs_by_players is 605 for all). | Late joiner: same | net_join:snapshot; commands:sized_join; players:mess_size, new_game_for; world_codec:snapshot | rule |
| M24 | When a batch is laid while 2 or more players are in the game | then about 5% of it (stages.high_share) lies on high spots 1.7 m or more up that need a teammate's back to reach; with one player none do. | Counted when the batch is laid, so a late joiner or a leaver changes it | spawning:spawn, bake (spawn only) | rule |
| M25 | When the game is saved and loaded | then every Sock and floor Pair lies exactly where it lay; a Guest's held Socks lie where they stood; the save keeps one row per Sock after every pick, drop and shelve. | Host saves; guests never save | world_codec:save_exact; save:roundtrip; net_join:churn_rows; players:save_keeps_rows, save_three | safety |
| M26 | When a Sock is lying and a mover (Door, drawer, lid) sweeps through it | then the Sock is pushed along (up to 32 woken a tick). | same | sockworld:sweep; doors:push | rule |

### Hands: pick up, hold, drop, hand over (H)

Items are loose Socks, Pairs and the Guide card, up to Carry capacity. Carried things that take the whole Hands (Radio, gift box, Part, bin, vacuum, machine, a dragged Teammate) are other features; only their effect on Socks is listed.

| id | When ... | then ... | co-op note (Guest / race / late joiner, or "same") | where it is tested today | kind |
|---|---|---|---|---|---|
| H01 | When you left-click an aimed Sock and have a free place | then it goes into your Hands, leaves the Mess and becomes the active item. | Guest: shows at once, the Host confirms; refused, it flies back out | hands:clicks, capacity1; commands:predict; net_commands:commands | rule |
| H02 | When you click Socks faster than the grab interval (today 0.35 s; Quick Grab shortens it 8% a level) | then the extra clicks do nothing, with no message. | same | upgrades:effects (shortening only); the interval itself untested | feel |
| H03 | When you start the game | then your Hands hold 1 item (Pair counts as one); Big Hands adds 1 per level (4 levels). | each player has their own | hands:capacity1, capacity2; upgrades:effects; players:own_upgrades | rule |
| H04 | When your Hands are full and you click a Sock that is not the mate of a held Sock | then it stays in the Mess and you see "Hands full". | Guest: Host decides, Guest told | hands:capacity1; commands:predict | rule |
| H05 | When a New Game starts | then every player (and each joiner) already holds a Guide card in a Hands place, so at capacity 1 a Sock is refused until the card is dropped; at 2 a Sock fits. | joiner gets one too | guide:hand_out, slot; net_join (JOIN_ADDS in carried) | rule |
| H06 | When you hold several items | then the newest is active (drawn big, right of centre; others tucked small to the left); the wheel (or LB/RB) steps through them and wraps; with one item nothing changes. | Guest: the wheel turns at once, undone if the Host refuses | hands:active, wheel; commands:predict_hands | rule |
| H07 | When you tap the right button (shorter than 0.25 s) with the crosshair white | then the active item is dropped where the crosshair is, within reach, on a flat-enough top (slope up to 25 degrees), the floor, a table, a shelf, the top of a Heap or a lying Pair. | Guest: leaves the Hands at once and falls on its own body, the Host's body takes over | hands:drop_aimed, bindings, drop_heap; throw:rmb_click; commands:predict_hands | rule |
| H08 | When the crosshair is red (too far, a wall, a steep side, the ceiling, a gap behind furniture narrower than 8 cm, outside the flat) and you release | then nothing is dropped, "Can't drop there" shows and the item stays; with empty Hands the crosshair stays white everywhere. | Guest: refused on their machine without asking; the Host also refuses a drop out of reach | hands:drop_refused, drop_gaps; net_commands:drop_aim | rule |
| H09 | When the crosshair sees into an open drawer, cupboard or the fridge | then a drop lands there. | same | hands:drop_insides | rule |
| H10 | When a loose Sock is dropped | then it is let go 3 cm over the spot (after a 0.1 s flick from the hand), falls as one physical body and joins the Mess where it settles; it is not drawn, aimed or pickable while it flies. A dropped Pair lies as a sock ball after it settles. | Host's body is the truth; every machine lays it at the same rest spot | hands:drop, drop_bed, drop_pair_bed; throw:drop_fall, on_bed; commands:ids; net_commands:drop_settle | rule |
| H11 | When you drop on a Heap | then it rests on top; beside it, on the floor; half over a Heap or a table's edge, it settles or falls and never floats; on the bed it rests on top; under the bed it stays under the frame; over the open basket it lands inside. | same | hands:drop_heap, drop_settles, drop_edge, drop_surfaces; mess:basket | safety |
| H12 | When you aim at a Pair lying on the floor and click | then it goes back into your Hands as a Pair if there is a free place, else it stays. | Guest: predicted, as a Sock | hands:floor_pair; throw:floor_pair | rule |
| H13 | When you right-click aimed at a teammate within reach with an item that would complete a Pair in their Hands (a loose Sock whose mate they hold, or any Pair they have room for) | then it goes into their Hands (a Hand-off); their avatar is outlined while it would. | Guest: waits for the Host's word (not shown at once) | net_hands:handoff, handoff_outline; players:restricted_hand_off | rule |
| H14 | When the hand-off would not complete a Pair | then the giver is told "Not their mate", the Sock stays and nobody else is told. | only the giver hears | players:restricted_hand_off; net_hands:handoff | rule |
| H15 | When you hand a Pair to a teammate whose Hands are full | then it lies at their feet and they see "Hands full" (you do not). | same on both machines | net_hands:handoff_full; players:restricted_hand_off | rule |
| H16 | When anyone tries to take from another player's Hands | then nothing is taken; only a hand-off, a catch or a drop gives an item over. | race-safe | net_commands:no_stealing | safety |
| H17 | When two players click the same Sock at once | then exactly one gets it; the other's grab fizzles with no message and the Sock is out of every Mess. | Race: the first to reach the Host wins; the loser's shown pick is undone (flies back out) | net_commands:race, predict; commands:race, predict | safety |
| H18 | When a Guest picks, wheels, drops or throws | then it shows at once on their machine and the Host's answer confirms it; if refused, the Guest's Hands become the Host's. | Guest | commands:predict, predict_hands, predict_throw; net_commands:predict_hands | safety |
| H19 | When you carry the Radio, a gift box, a Part, or a machine part | then no Sock or Pair comes into your Hands and a Pair handed to you lands at your feet. | same | hands:carry_rules (Radio, pairing machine) | rule |
| H20 | When you pick a Sock lying on the washing machine | then it goes into the Hands and the Upgrade menu stays shut. | same | hands:pick_on_station | rule |
| H21 | When you hold G | then the view eases in (fov 50 in 0.15 s) and the active item comes close and large, tucked items keep their screen size, nothing is dropped; letting go puts it back. | local | hands:zoom, zoom_held_size, zoom_held_instant, zoom_turn | feel |
| H22 | When you hold R | then the active item turns where it hangs (a Sock about its long axis, a Pair side to side, one turn per 2 s) and stays at the angle when you let go; looking, walking, clicking and the wheel still work. | local | hands:turn, turn_cloth, turn_controls | feel |
| H23 | When a Sock is held | then its Size letter shows (a readout with Design name and icon needs Sock Smarts; the aimed Sock's readout needs Sock Sense, both Upgrades). | local | hands:held_size_letter, sock_smarts, sock_sense, info_sway | look/sound |
| H24 | When a Guest leaves or loses connection | then everything in their Hands drops where they stood (Socks lie, a Pair as a ball), for everyone still in the game. | Guest leaves | net_join:leaver, leave_end; worlds:crash_drops; carried:sock, pair | safety |
| H25 | When the Host saves | then a Guest's held items are laid where that Guest stands and they come back empty-handed with their Upgrades; the Host's own Hands stay held. | Host saves | net_join:returning; players:save_three; carried:sock, pair | rule |
| H26 | When a player joins for the first time | then they spawn at the washer spawn, slightly apart, with empty Hands (but the Guide card); a returning player spawns where they left; a fifth player is refused. | Late joiner | net_join:spawn, returning, full | rule |
| H27 | When you are knocked down | then you cannot pick, use or throw until you stand. | knocked player | untested for picking (code: rig click returns while down) | rule |
| H28 | When you press the right button with empty Hands | then nothing happens. | same | hands:drop | rule |
| H29 | When a player holds a Sock whose mate a teammate holds and picks | then a match cue is signalled to the picker; with Sole Mates the teammate's matching Sock keeps an outline in their colour and a soft sound plays once. | Teammate | players:match_cue, match_glow, sole_cues; net_hands:sole_mates, sole_cues | look/sound |
| H30 | When a teammate stands between you and a Station | then you cannot aim at or use the Station. | co-op | net_hands:mate_blocks_station | rule |

### Throws and catching (T)

A Throw and a drop share the right button. Both are one physical body from release to rest; the Host owns every contact.

| id | When ... | then ... | co-op note (Guest / race / late joiner, or "same") | where it is tested today | kind |
|---|---|---|---|---|---|
| T01 | When you hold the right button past 0.25 s with something in your Hands | then a ring fills round the crosshair (full in 1.2 s; Quick Charge shortens it 25% a level) and releasing throws the active item along the aim with a gravity arc; there is no cancel. | Guest: leaves the Hands at once, flies on its own body for about 100 ms before the Host's body takes over without a jump | throw:charge, rmb_hold_throw, upgrade; commands:predict_throw; net_throw:guest_throw_feel | feel |
| T02 | When you tap-release a charge (below 15% of the charge) | then it is a short lob (3.5 m/s plus 2 m/s up), not a drop. | same | throw:charge | feel |
| T03 | When you throw with more charge | then it flies faster: today 3 to 5 m/s from tap to full charge; Long Arm adds 4 m/s per level (3 levels). The free Throw is weak. | same | throw:upgrade | feel |
| T04 | When you press Q | then nothing happens (no throw action is bound to it). | same | throw:q_nothing | rule |
| T05 | When a Pair you threw touches its own Collection's Cabinet | then it shelves itself into the lowest drawer with room, that drawer pops open, you are paid as for a normal shelving and nothing lies on the floor. | Host decides the touch; Guest's flying Pair ends the moment the shelving arrives | throw:right_cabinet; drawers:throw_bottom_first; stages:complete, full; net_commands:scripted | rule |
| T06 | When a Pair touches another Collection's Cabinet, or a locked or full one | then it bounces off with a sound where it hit and lies on the floor as a sock ball, with no message. | same | throw:wrong_cabinet; stages:start, full | rule |
| T07 | When a loose Sock is thrown at a Cabinet | then it bounces off and rejoins the Mess (never shelved). | same | throw:loose | rule |
| T08 | When a Sock is thrown | then neither end is ever inside a wall or Cabinet, and it always ends up back in the Mess; one lobbed onto the bed stays on the mattress top and is drawn once settled. | same | throw:walls, on_bed | safety |
| T09 | When your Throw hits a teammate | then it is caught into their Hands if it completes a Pair there (a Pair with room is caught), else it bounces off at about a quarter of its speed and drops at their feet, nobody told; with full Hands it lands at their feet. Never hits the thrower or a teammate already down or in the drum. | Host decides; the thrower's flying copy ends on catch | throw:flight_rules; players:restricted_throw; net_hands:handoff_throw; net_throw:guest_throw_caught; throw_knock:exempt | rule |
| T10 | When a full-charge Throw hits a teammate | then they are knocked down for a moment and the item bounces off and falls; a weaker Throw never knocks down. (Own feature: knockdown, listed here as the hook.) | Host runs it; a Guest's full Throw knocks the Host down on both machines | throw:flight_rules; throw_knock:full, weak, guest; net_knockdown:knockdown_guest | rule |
| T11 | When a Throw faster than 1.5 m/s hits a pile of Socks | then it wakes the Sock hit and at most 8 touching it; a slow drop wakes none. | Host | sockworld:impact, fast_ccd | feel |
| T12 | When you throw and another player watches | then they see it leave your hand, join the true flight from your eyes, and play about 100 ms behind the Host's stream, smoothly and with no jump. | Guest watching the Host / a teammate watching either | net_hands:throw_from_hand, throw_one_motion; net_throw:guest_sees_host_throw, host_throw_feel | feel |
| T13 | When a thrown Sock or Pair comes to rest | then it lands as a Mess Sock (or a Pair as a floor ball) where its body stopped, on the floor, a table, a heap or the bed, the same on every machine; a flight that never settles is put down after 6 s (today). | same | throw:flight_rules, drop_fall; net_hands:throw_one_motion; 6 s limit untested | safety |
| T14 | When a thrown Sock or Pair flies out of the flat or above the ceiling | then it comes down at once and lies in front of the washer. | same | lost:ceiling, let_go; net_commands:lost | safety |
| T15 | When a Guest's Throw spin is sent | then the Host limits it to the allowed spin so both bodies tumble alike. | Guest | net_guard:guard_spin | safety |
| T16 | When the Throw ring shows | then it hides on release; a throw plays its charge and throw sounds; the pad's rumble buzzes on a throw. | local | throw:charge; pad:rumble | look/sound |

### Pairs (P)

A Pair exists only in one player's Hands, on the floor as a sock ball, in a Cabinet drawer, or in flight. The pairing machine is switched off in the shipped game (tools/26) and is not part of this port.

| id | When ... | then ... | co-op note (Guest / race / late joiner, or "same") | where it is tested today | kind |
|---|---|---|---|---|---|
| P01 | When you pick up a Sock and hold its loose mate (same Design) | then the two fuse at once into one Pair in your Hands, which becomes the active item and takes one place. | Guest: shows at once; undone (splits back) if the Host refuses | hands:clicks, capacity1, capacity2; commands:predict; net_commands:predict | rule |
| P02 | When your Hands are otherwise full and you pick the mate of a held Sock | then it still fuses (the Pair uses the mate's own place). | same | hands:capacity1, capacity2 | rule |
| P03 | When a Sock is not the mate (another Design) | then it never fuses; a held Pair never takes a third Sock. | same | hands:capacity1, floor_pair; players:own_hands | rule |
| P04 | When two players each hold one half | then nothing pairs between them; only your own Hands pair, or a hand-off or a catch that completes the Pair in the receiver's Hands. | co-op core | players:own_hands, mate_paired, restricted_hand_off | rule |
| P05 | When a Pair forms | then the picked Sock flies to the held one, they line up, fold and roll into a sock ball that pops with a sparkle burst in the Collection's colour and a ring (0.5 s today), once per pairing; picking up a whole Pair plays none; dropping a Pair mid-moment ends it. | A teammate sees a small burst at your hand, not the full moment; a hand-off that pairs plays the full moment for the receiver | hands:paired_moment; players:mate_paired | look/sound |
| P06 | When a Pair is held | then it is drawn as one sock ball, in the Hands and on a teammate's avatar. | Teammate | hands:clicks, wheel; players:mate_paired | look/sound |
| P07 | When you drop or throw a Pair | then it lies as a sock ball where it lands, pickable again once it has settled; a Sock dropped on it rests on top or beside it, never inside. | same | hands:clicks, item_bodies, drop_heap; throw:floor_pair | rule |
| P08 | When the thing a floor Pair rests on is taken away (the bottom of a stack picked, the Sock under it picked) | then the Pairs over it fall like drops and land; a Pair beside them stays. | Host wakes; Guest sees them fall as dropped Pairs; both lay the same rest spots | pair_wake:stack, on_sock; net_hands:pair_wake | rule |
| P09 | When a Pair or Sock is picked or caught by one player | then it is no longer anywhere else; a Pair split by a refused prediction goes back to two Socks, none lost or made. | race | commands:predict; carried:pair; net_join:churn_rows | safety |
| P10 | When a player holds a Pair and leaves | then it lies as a sock ball where they stood. | leaver / crash | carried:pair; net_join:leaver | safety |
| P11 | When a Pair is shelved | then it pays Coins by its Design's rarity (see C06). | same | drawers:shelve | rule |
| P12 | When a Dirty Sock is picked | then it never fuses (boundary; Dirty Socks belong to the laundry feature). | same | not tested in the files read | rule |

### Cabinets and Drawers (C)

Cabinet, Drawer and Collection words as in the glossary. Stage and Row growth (progression) is listed only where it decides whether a Pair may go in.

| id | When ... | then ... | co-op note (Guest / race / late joiner, or "same") | where it is tested today | kind |
|---|---|---|---|---|---|
| C01 | When you left-click a drawer of a Cabinet while holding Pairs of its Collection | then every held Pair of that Collection goes into that drawer, in the order you hold them; Pairs of another Collection stay in your Hands; the drawer slides open to show them. | Guest: waits for the Host's word, then sees the drawer open | drawers:shelve, click, click_aimed; commands:replica; net_commands:commands | rule |
| C02 | When you hold only Pairs of another Collection and click | then "Wrong Cabinet" shows and nothing moves; with a mixed hand, what fits is shelved and the rest is kept. | Guest told | drawers:reject | rule |
| C03 | When a drawer holds 25 Pairs (today's value) | then it is full; the next Pair aimed at it goes to the nearest drawer with room (the lower one when two are as near); each drawer used pays and slides open; the bottom drawer fills first when you aim at it. | same | drawers:fill, aimed, overflow | rule |
| C04 | When you click a drawer with an empty hand (or holding only loose Socks, today) | then it opens or shuts; the click sets the target state so two players clicking at once leave it as clicked. | Guest: sent to the Host, both machines match | drawers:click; net_devices:toggles | rule |
| C05 | When your Pairs go into the drawers | then you are paid 10 Coins times the rarity (common 1, uncommon 2, rare 5), once per drawer used, each at its own drawer; the Coins are yours alone and land in your bank after they fly. | The shelver sees the +N; everyone's bank follows the Host | drawers:shelve, paid_per_drawer; players:shared_shelf; commands:coin_timer; net_campaign:own_payout | rule |
| C06 | When a Cabinet drawer fills | then the whole team earns Drawers (the team currency): 1 in the basement and ground floor, 2 first floor, 3 attic, 4 grotto (today). | Team | drawers:team_drawers | rule |
| C07 | When a Collection is complete | then its bonus counts once and shelving again pays no second bonus (it pays no Coins now). | same | drawers:bonus | rule |
| C08 | When a Cabinet is locked or its Rows are full | then a click says "Cabinet locked" or "Cabinet full" and the Pairs stay; its Drawers stay shut; a Cabinet starts with 2 Rows and every completed Stage adds 1 until its Designs are all housed. | Host decides | stages:start, growth, full, aimed_locked; (toggle refusal untested) | rule |
| C09 | When the last Pair of a floor's open Rows is shelved (by hand or by Throw) | then the Stage completes once and pays the Cabinet batch (+50) and, when the floor's door opens, the floor's Coins (+100) to every player. | every machine sees it once | stages:complete, reset, replica | rule |
| C10 | When a New Game starts | then each Cabinet spot draws its Collection from its room's pool of unlocked Collections, never one twice; a Guest plays the Host's draw even if the Guest's own unlocks differ. | Guest/joiner | stages:draw, draw_kept, pools_solver; net_join:cabinets_join, cabinets_host_profile | rule |
| C11 | When you look at a Cabinet | then it shows no icon: you learn which is which by the refusal. | same | untested (glossary only) | look/sound |
| C12 | When Pairs are shelved | then they stay in the same drawer and slot after save and load; one shelf is shared by all players. | Host saves; joiner sees shelved Pairs in the right drawers | drawers:drawers_save; players:shared_shelf; net_join:snapshot; stages:save | safety |
| C13 | When two players shelve into the same drawer in the same moment | then the Host takes them in the order they arrive and the second overflows to the next drawer or is refused full. | Race | untested | safety |
| C14 | When a Cabinet stands in the house | then every Collection's Cabinet is built from its model's parts (3 segments, 25 slots a drawer, a handle within 4 cm) and stands against a wall facing into its room. | same | drawers:models; room:boots, walls | layout pin |
| C15 | When all Pairs of the run are shelved with the campaign off | then the run ends; with the campaign on the Final wash ends it. (Boundary.) | everyone sees the ending | save:ending; stages:final | rule |

### Doors (and the openables that share their click) (D)

Room Doors and the openable containers (fridge, cupboards, oven, drawers) are separate things in code but share the click, the replica rule and the Socks they push or carry.

| id | When ... | then ... | co-op note (Guest / race / late joiner, or "same") | where it is tested today | kind |
|---|---|---|---|---|---|
| D01 | When you enter any room whose doorway has a Door | then the Door is there: 8 doorways have Doors; the open-plan kitchen, dining room, living room and hall do not. | same | doors:which, world | layout pin |
| D02 | When you click an open Door | then it swings shut (0.6 s today) with its sound; click a shut one and it opens; clicking a Door already in the state asked does nothing; no Door ever moves by itself. | Guest: the click goes to the Host and both end alike; two players opening at once both get it open | doors:open_close, world, replica; net_devices:toggles, doors | rule |
| D03 | When a New Game starts | then about a third of the Doors (3 of 8) stand shut, picked at random each New Game, except the way from the laundry to the garage, which starts open; the save keeps which stand shut. | A joiner gets shut Doors shut | doors:start, save, new_game; net_devices:doors | rule |
| D04 | When a Door swings | then every Sock, Pair and the lying Radio in its way is pushed out of it and lies still on the floor it was on; Socks clear of the swing stay; a Sock in the doorway goes out in front of it. A player in the swing is nudged out. | Both machines end with the Door and what it pushed alike | doors:push, replica, world | rule |
| D05 | When a Door is shut | then it stops the player, the crosshair and light and shadows like a wall; open, the doorway is clear. | same | doors:world | rule |
| D06 | When a Door is shut | then sounds from the other side (Radio, TV, fridge, clock, house sounds) are muffled (-9 dB, 900 Hz low-pass today); pings and X-rays show through. | local | doors:muffle, new_game | look/sound |
| D07 | When you aim at a Door | then its prompt offers to shut or open it. | same | doors:world; prompt:stations | look/sound |
| D08 | When a fridge, cupboard, oven or drawer is clicked | then it opens or shuts for everyone (openables); a covered Cabinet's drawers refuse "Cabinet locked". | Guest's click goes to the Host; a joiner sees the open ones open | mess:openables; net_devices:toggles; net_join:snapshot | rule |

## 2. Where code, glossary and tests disagree

1. **Mess only shrinks (glossary) versus code.** The glossary says the Mess "only shrinks". In play a dropped or thrown loose Sock rejoins the Mess (hands:drop, throw:loose) and every Stage's Fix lays a new batch (spawning:designs). The word "Mess" in the glossary also leaves out Socks that are flying, held as a Pair on the floor, or in a Hamper or vacuum; the glossary's **Sock** entry lists only Mess, Hands and Drawer.
2. **Throw is an Upgrade (glossary) versus free (code).** `Upgrades.throw_unlocked()` always returns true; Q1344 and throw:upgrade say Throw is free from the start but weak. The refusal "Throw not bought" and the header of tests/throw_test.gd ("any click without Throw drops on release") describe a state that cannot happen.
3. **The washer lesson.** mess:lesson expects one Basic and one Animals Design on the washer top; spawning:new_game expects the New Game Mess to be Basic only and the lesson's Design to be Basic. Two cases describe different New Games (the first likely with the campaign off); I did not run them.
4. **Drawer click.** Glossary: an empty-handed click opens or closes. Code (`RigClick.use`): holding only loose Socks does the same; the refusal "Pair socks first" exists in `Cabinets.decide_shelve` but a normal Cabinet never reaches it (only the Drum hatch does).
5. **Click versus Throw shelving.** A click shelves every held Pair of the Collection, aimed drawer first, nearest drawer with room next, and says "Wrong Cabinet", "Cabinet locked" or "Cabinet full" when it cannot. A Throw shelves one Pair, bottom drawer first whatever drawer it hit, and when it cannot (wrong, locked, full) it bounces with no message. The glossary says only "thrown Pairs fill drawers bottom up".
6. **Hand-off refusal.** A right-click hand-off without a mate says "Not their mate" to the giver; a Throw at the same teammate bounces and tells nobody (players:restricted_throw). The glossary says both are refused/bounce without noting the difference.
7. **Capacity starts at one but the Guide card takes a place.** Glossary: Carry capacity "starts at one: a held Sock plus its mate fuse into one Pair, so a Pair still fits". Code also puts a Guide card in every player's Hands at a New Game and for every joiner (guide:hand_out, slot), so at capacity 1 the first Sock is refused until the card is put down.
8. **Mess size in co-op.** players:mess_size is titled "the tuning's number of Pairs for the players at its start", but `mess.pairs_by_players` is 605 for 1, 2, 3 and 4 players (the whole catalogue), and in the staged game the New Game Mess is the basement's 50 Pairs (stages.pairs [50, 160, 150, 130, 50]). I did not trace whether the staged game reads the table at all (`Game.designs_for`, game.gd:815).
9. **Collections.** The glossary's Design and Collection entries count nine Collections (555 plus 50 Lost Socks) while stages:unlock_rule and the Cabinet pools speak of 17. Outside the core loop, but the Cabinet draw rows depend on it.
10. **Doors.** Glossary: every room's doorway has a Door except the open-plan ground floor; tests say 8 doorways have Doors and the laundry-to-garage Door never starts shut (progression/88, Q1865); the glossary does not mention that exception. Architecture 2.2 lists a Door among the movers that sweep Socks awake; `DoorRules.push_from` moves them at once, in one step (I did not trace whether a sweep also runs).
11. **Architecture 2.13** says the Radio, a Guide card and a gift box dropped are "not yet Flights"; the same file later says the Radio and Guide card fly on a shared script arc (release:systems). Stale text, no player impact.

## 3. Not carried over (tests that assert internals with no player-visible meaning)

Pure internals, to be replaced by whatever the new project needs, not by a behaviour row:
- sockworld: layers, records (14-bit ids, 16,384 items, the 16,385th refused), resting, switch, data_states, kept_sets, draw_slots, support, pair_gift, load, fast_ccd (and the rest of rest_per_sock's bookkeeping). The only visible product is rows M16, M17, M18.
- mess: shell_colliders, furniture_colliders (house shapes under 2,000 shapes and 10,000 triangles); the 3,000 ms bake budget in mess:bake.
- hold (all 9 cases): where each carried model sits (specs, body frame, steadiness at 24 ticks to 60 frames, Crouch, Teammate facing, lantern swing, machine, book). Kept only as the look of H21 to H22.
- world_codec: records, resettle, ragdoll, one_id_space; commands: roundtrip, ids, seeded; command_table (4); net_guard: guard_shapes, guard_settings, guard_pose, guard_command, guard_hello (a Guest's malformed message never breaks the Host: one safety line, I.15); net_join: tick_order, space_in_tick; freed (3); release: systems, item_put, item_throw_hand; throw:flight_rules (the Game-versus-Flight split is internal; its player-visible part is T09 and T10).
- carried: 17 of 19 cases are other kinds (gift, part, bin, Radio, cat ...). Only `sock` and `pair` (each: host and Guest carrier; save, quit, join) are carried over, as H24, H25, P10 and invariant I.1.
- Whole features outside this port: pairing_machine (14 cases) and pairing_off (2) (machine is switched off in the shipped game), cabinet_xray (9), xray (9) (Upgrades; `use` of drawers is unaffected), the wardrobe, laundry bin and Hamper cases.

## 4. (a) Invariants of the core loop: what must always hold

- **I.1 No Sock is lost or doubled.** At any moment every Sock is in exactly one place: lying in the Mess, in one player's Hands, in flight, as half of a floor Pair, or in a drawer as half of a Pair. The count per Design is two, through every pick, drop, Throw, pairing, shelving, save and load, Guest leaving and joining (carried:sock, pair; net_join:churn_rows; commands:replica).
- **I.2 Every Design in play has exactly two Socks**, so every Sock can find its mate.
- **I.3 One holder, no stealing.** An item is in at most one player's Hands; nobody takes from another player's Hands; items change hands only by a hand-off or catch that completes a Pair there (a Pair needs room).
- **I.4 Pairs form only in one player's Hands** and only from two Socks of one Design.
- **I.5 Only a Pair of the Cabinet's Collection is ever shelved**, never a loose Sock, never into a locked Cabinet or a full Row; a Row never holds more than its capacity.
- **I.6 Every resting item lies on what is drawn and inside the flat.** Never in a wall, floor, furniture or in front of a Cabinet; outside the flat it goes back in front of the washer; a Sock in a shut container cannot be aimed at.
- **I.7 A drop or Throw is accepted only where it would rest**, within reach (2.5 m today); otherwise refused and the item stays.
- **I.8 Nothing flies through walls or Cabinets**; every flight ends exactly once: landed, caught, shelved or binned.
- **I.9 The Host decides and every machine converges** on the same World: Mess, Hands, shelf, drawers, Doors, floor Pairs (commands:replica, scripted).
- **I.10 A race has one winner**; the loser's grab fizzles with no message, and the shown pick is undone.
- **I.11 Predicted Guest actions are undone exactly** when the Host refuses; afterwards the Guest's Hands equal the Host's.
- **I.12 Coins go to the shelver alone**, once per drawer used, never doubled; Drawers (team) once per drawer filled.
- **I.13 A Guest leaving or crashing loses nothing:** their Hands drop where they stood; a save lays guests' items down and keeps one row per Sock.
- **I.14 Save and load restore exactly:** every Sock, floor Pair, drawer content, Door and open container.
- **I.15 A Guest cannot break or cheat the Host:** malformed or Host-only messages are dropped and counted; a Guest cannot mint Coins; a Guest's spin and pose are clamped.

## 5. (b) Controls of the core loop today (project Input Map)

| What | Mouse and keyboard | Pad |
|---|---|---|
| Pick up a Sock or floor Pair; shelve into a drawer; open or shut a Door, drawer or container (E does the same on the aimed thing unless its prompt shows only the left click) | left click (E for stations) | A (Y for E) |
| Drop the active item; hand it to the aimed teammate (tap shorter than 0.25 s) | right click, tap | B, tap |
| Charge and Throw (hold past 0.25 s, release throws; no cancel) | right click, hold | B, hold |
| Next / previous held item (wraps) | mouse wheel down / up | RB / LB |
| Zoom the held item (hold) | G | D-pad up |
| Turn the held item (hold; leaves the angle on release) | R | L3 |
| Ping / highlight (a teammate must be in the flat; hold opens the emoji wheel) | middle click | R3 |
| Look, walk, jump, crouch, sprint (sprint needs the Sprint Upgrade) | mouse, W A S D, Space, Ctrl, Shift | right stick, left stick, X, LT, RT |
| Show pair / Show drawer (Upgrades) | 1 / 2 | D-pad left / right |
| Q | does nothing | none |

Source: `docs/llm/maintenance/issues/115-project-input-map.md`, `game/player/rig_click.gd`, `game/player/player.gd`, pad:bindings and pad:triggers. Wheel up is "previous" (`cycle_hands(-1)`), wheel down "next".

## 6. (c) Questions for the designer

Each has 2 or 3 options in plain words; my recommendation is first.

### Mess
1. **Does the Mess grow with the players?** Today the Mess is the same size for 1 to 4 players, and a share (5%) of each floor's batch is put on high spots only if two or more players are in the game at the moment the batch lands. So a late joiner or a leaver changes what the next floor holds. Options: (a) fix it by the Group's size when the World is first played; (b) keep it as today (whoever is in the game when the batch lands); (c) add more Pairs for each extra player.
2. **Should the first port start with the Mess already lying, and add the first-wash intro later?** Today a normal New Game has no Socks until the first bin goes into the washing machine, which breaks and sprays the first batch. Options: (a) port the core loop with the Mess lying at the start and port the intro as its own later feature; (b) port the intro with the core loop; (c) never show the Mess before the intro, even in tests.
3. **Where does a Sock go when it ends up outside the flat or sunk into a floor?** Today it is put in front of the washing machine, scattered, with a pop; one sunk in a slab is pushed up onto that floor with no pop. Options: (a) keep both; (b) always back where it was dropped from; (c) refuse the drop earlier so it cannot happen.
4. **How is a Sock's mate hidden?** Today rare Designs hide more, lie farther away, and half the rare mates are on another level. Options: (a) keep, tune later (numbers are placeholders); (b) all Designs hide equally in the first port; (c) mates always on the same level.

### Hands
1. **Should the Guide card take the player's only Hands place?** Today every player starts holding it, so with one place a Sock is refused until it is put down. Options: (a) the card is not a Hands item (it lives on its own key); (b) start with two places; (c) keep as today.
2. **What should a refusal say?** Today clicks that fail say a short line ("Hands full", "Can't drop there", "Not their mate"), a Throw that is not caught bounces with no line, and a click sooner than the 0.35 s grab interval does nothing. Options: (a) clicks say a line, physical outcomes (a bounce) and too-quick clicks stay silent; (b) everything says a line; (c) nothing says a line, only sounds.
3. **Should a Guest's hand-off show at once like their pick, drop and Throw?** Today it waits for the Host's answer, so with a laggy line it feels slower than everything else. Options: (a) keep it waiting (it needs the receiver's Hands); (b) show the item leaving the Hands at once and undo if refused; (c) make a hand-off a Throw only.
4. **What if your Hands are full and you click a Sock that is not a mate?** Today it is refused ("Hands full"). Options: (a) refuse, as today; (b) swap it with the active item; (c) drop the active item and take the new one.
5. **Is the 0.25 s right-button tap the right line between a drop and a Throw?** Someone who holds a little long throws by accident. Options: (a) keep 0.25 s; (b) longer hold (0.4 s); (c) a separate key for Throw.

### Throws and catching
1. **Is Throw free from the start?** The glossary calls it an Upgrade; the game and tests make it free and weak (3 to 5 m/s today), Long Arm and Quick Charge only improve it. Options: (a) free from the start, fix the glossary; (b) locked until bought; (c) free but only at a short range until bought.
2. **Where does a thrown Pair shelve and what does a failed shelve say?** Today it goes into the lowest drawer with room whatever drawer it hit, and a wrong, locked or full Cabinet bounces it with no message. Options: (a) as today; (b) into the drawer it hit; (c) as today plus a short line for locked or full.
3. **Is the full-charge knockdown part of the first port?** Today a full-charge Throw at a teammate knocks them down for a moment. Options: (a) no: port Throws with catch and hand-off only, knockdown later as its own feature; (b) yes, with Throws; (c) remove it.
4. **Should a charge be cancellable?** Today there is no cancel: releasing always throws. Options: (a) keep; (b) a left click cancels; (c) moving the crosshair to red cancels.

### Pairs
1. **Should a Hand-off or catch only ever complete a Pair?** Today a loose Sock is only given or caught if its mate is in the receiver's Hands ("Not their mate"); a Pair always goes if there is room. Options: (a) keep; (b) any Sock may be handed over; (c) only Pairs may be handed over.
2. **Can a held Pair be split back into two Socks?** Today never (only an undone prediction does it). Options: (a) no; (b) a key splits it; (c) a drop splits it.
3. **Should Pairs on the floor fall when what they lie on is taken away?** Today they do, as drops do (physics/38). Options: (a) keep; (b) only for stacks of Pairs, not a Pair on a Sock; (c) a Pair stays put.
4. **Should a teammate see the full pairing moment?** Today only the player sees the full 0.5 s moment; others see a small burst at the hand. Options: (a) keep; (b) everyone sees it; (c) nobody, only the sound.

### Cabinets, Drawers, Doors
1. **Should a click shelve every held Pair or only the active one?** Today a click shelves all held Pairs of the Collection, a Throw one. Options: (a) keep; (b) a click shelves only the active Pair; (c) a click shelves the held Pairs of that drawer's Collection but only to the aimed drawer, no overflow.
2. **What does a click on a drawer say when you hold only loose Socks?** Today it silently opens or shuts it ("Pair socks first" exists but is never shown). Options: (a) keep opening; (b) say "Pair socks first"; (c) nothing, keep it shut.
3. **Cabinets carry no icon (you learn by the refusal). Keep?** Options: (a) keep; (b) a small plate; (c) a colour trim per Collection.
4. **Which Doors start shut?** Today about a third at random each New Game, except the laundry-to-garage way. Options: (a) keep; (b) a fixed set each time; (c) all open.
5. **When a Door swings, Socks in its way jump out of it at once (the same on every machine) instead of being swept along.** Options: (a) keep, because it is identical for everyone; (b) sweep them physically; (c) block the Door while something lies in the way.

## 7. (d) Counts and what I could not determine

**Read.** For every suite the case name and title; for each of the suites below every assertion message, and the full body of a case only where its message was unclear. Core suites (18 files, 225 cases): sockworld 20, mess 27, hands 34, hold 9, throw 14, throw_knock 4, pair_wake 2, pairing_machine 14, pairing_off 2, doors 9, drawers 13, cabinet_xray 9, carried 19 (two relevant), net_hands 12, net_throw 4, net_join 15, net_commands 12, net_guard 6. Adjacent suites (21 files, 235 cases, titles plus assertion lines): release 3, spawning 8, first_wash 9, lost 9, players 19, commands 10, stages 16, upgrades 19, save 9, world_codec 6, command_table 4, guide 9, net_campaign 12, net_devices 18, worlds 7, sfx 12, xray 9, room 19, pad 28, prompt 6, freed 3. Code read: `game/hands/hands.gd`, `hands_rules.gd`, `thrower.gd`, `game/campaign/cabinets.gd`, `game/house/door_rules.gd`, `house_rules.gd` (toggle), `game/player/rig_click.gd`, `rig_drop.gd`, parts of `rig_aim.gd`, `game/world/flight_rules.gd` (declarations and comments), `upgrades.gd` (carry, throw), tuning files `hands, release, drawers, doors, mess, knockdown, hand_off, payout, paired, lost, view, held, upgrades, stages`.

**Behaviours listed:** 107 rows. Per feature: Mess 26, Hands 30, Throws 16, Pairs 12, Cabinets and Drawers 15, Doors 8. Per kind: rule 62, safety 17, feel 14, look/sound 11, layout pin 3 (M06, C14, D01).

| feature | rule | safety | feel | look/sound | layout pin | total |
|---|---|---|---|---|---|---|
| Mess | 12 | 4 | 6 | 3 | 1 | 26 |
| Hands | 20 | 5 | 3 | 2 | 0 | 30 |
| Throws | 6 | 4 | 5 | 1 | 0 | 16 |
| Pairs | 8 | 2 | 0 | 2 | 0 | 12 |
| Cabinets and Drawers | 11 | 2 | 0 | 1 | 1 | 15 |
| Doors | 5 | 0 | 0 | 2 | 1 | 8 |

**Untested (no case found):** H27 (cannot pick while knocked down), C11 (no icon), C13 (two shelvers racing for the last place), P12 (a Dirty Sock never fuses). Partly untested: H02 (the 0.35 s grab interval itself), T13 (the 6 s limit on a flight), C08 (the locked-Cabinet refusal on a drawer click), M24 (only the spawn side, not a late joiner's effect). Also untested: any Sock in the air when a Guest joins (see below), a Guest's hand-off or shelve under lag, and a race between two Guests for the last place in a drawer.

**Could not determine.**
- Whether a Sock or Pair that is in flight on the Host at the moment a Guest joins reaches that Guest exactly once. The join snapshot is `Saves.to_dict`, not the laying-down `save_dict`; the Host's landing event should lay it, but no case covers it (carried:sock and pair cover held items only). I make no claim it is a bug; it is the one place I would add a test for "no Sock doubled or lost" in the rebuild.
- Whether the staged game reads `mess.pairs_by_players` (see section 2, item 8).
- Whether a Door's swing also sweeps Socks awake (section 2, item 10).
- Exact pick-up timing (grab interval 0.35 s) and the tap-versus-hold boundary in real play; only the tuning values are read, not tried.
- The 12 net_knockdown, 18 net_devices and 12 net_campaign cases were read by title and assertion lines only, for the rows that name them.
- I ran nothing: no tests, no game, no `tools/suites.sh`. I created helper files in the scratchpad (`cases.py`, `checks.py`, `*.chk`, `part_rows.txt`, `head.md`, `tail.md`, `body.md`, `counts.json`, `untested.json`) to extract case titles and assertion messages; the only deliverable is this file.
