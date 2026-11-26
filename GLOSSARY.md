# It Socks

> **To review (stale or disputed entries, flagged by the 2026-11-19 digests; the designer decides, nothing here is changed yet).**
> Sources: `docs/migration/digests/` and `docs/migration/behaviour-core-loop.md` part 2.
> - **Play**: says the main menu's first entry holds Continue, New Game, Wardrobe. The menu now reads Solo / Multiplayer / Options / Quit (lobby/05).
> - **Mess**: "it only shrinks" is not what the code does: a dropped or thrown loose Sock rejoins the Mess and every Stage's Fix lays a new batch. The entry also leaves out Socks in flight, Pairs on the floor and Socks in a Hamper or vacuum.
> - **Throw**: called an Upgrade here; the code and Q1344 make it free from the start but weak. The digests disagree on what this file says, so check the entry.
> - **Carry capacity**: "starts at one" ignores the Guide card, which takes a place at a New Game.
> - **Shelving**: "thrown Pairs fill drawers bottom up" leaves out that a click and a Throw shelve differently, and that a refused Throw bounces without a message.
> - **Hand-off**: a refused right-click hand-off says "Not their mate"; a refused Throw says nothing.
> - **Door**: the laundry-to-garage Door never starts shut (progression/88, Q1865), unlike the rule written here.
> - **Design / Collection**: count nine Collections; the stage rules and Cabinet pools speak of 17.
> - **Cabinet**: flagged stale (feature catalogue X31).
> - **The house** (was "the flat"), **Simple** (was Basic) and **Patterns** (was Casual) were renamed on 2026-11-19 by the designer; old ticket text in the reference clone still says flat, Basic and Casual.

A first-person 3D incremental game: the player tidies **the house**, covered in a **Mess** of socks,
picking up two matching **Socks** to make a **Pair** in their **Hands**, shelving it in its **Cabinet**
and spending the **Coins** at the **Upgrade station**, until every **Pair** is shelved and the **Final wash** is done.

## Language

### Things in the house

**The house**:
Where the game is played: since house/03 a detached family house on four levels (basement,
ground floor, first floor, attic) joined by a U stair, its rooms by doorways with **Doors** (spec
docs/llm/house/spec.md; the term was renamed from "the flat" to "the house", Q1954). The player
starts next to the washing machine in the basement laundry.
_Avoid_: room (for the whole house), level, flat

**Sock**:
One sock of a **Design**. It is either part of the **Mess**, held by the player, or in a **Drawer** as half of a **Pair**.
_Avoid_: item, pickup

**Pair**:
Two **Socks** of the same **Design**, fused in the player's **Hands** the moment the second is picked up, and from then on a sock ball (two Socks rolled up, one cuff folded over) in the Hands, on the floor and in **Drawers**. A dropped or thrown Pair lies where it lands (the floor, a furniture top, a heap) until picked up again. Shelving a Pair in its **Cabinet** pays Coins.
_Avoid_: match (for the result), set

**Resting** / **Moving**:
A **Sock** lies either Resting (still, settled; it costs almost nothing and others can lie on it) or Moving (falling, tumbling, thrown, simulated). The game wakes Resting Socks into Moving ones only within a budget, and Moving Socks rest again as soon as they settle (ADR-0008, Q841).

**Mess**:
The finite spread of unpaired **Socks** across **the house**: it begins with the **First wash**: the Socks spray out of the washing machine's door and lie in **Heaps**, on furniture and in **Hiding spots** (**Crawl spaces** included); until then no Socks lie in the house. Any Sock the crosshair reaches can be picked, standing: there is no crouch rule. It only shrinks, and it is cleared when every Pair is shelved. Mess is the players' word for all the Socks lying in the house; no code module stands behind it (the code keeps every lying item in SockWorld, Q935).
_Avoid_: clutter, spawn

**Heap**:
A pile of **Socks** in the **Mess**, formed when they fell at New Game. Any Sock of it the crosshair reaches can be picked, standing; the Socks resting on a taken one settle down.
_Avoid_: pile, stack, clump

**Hiding spot**:
A place in **the house** where **Socks** of the **Mess** are hard to see: inside a **Heap**, in a **Crawl space** (under the bed, sofa, coffee table or kitchen table), on furniture tops, or inside the laundry basket, kitchen cupboards, oven or fridge (these open with a click).
_Avoid_: secret, stash

**Crawl space**:
The gap under a piece of furniture (the bed, sofa, coffee table or kitchen table) where **Socks** of the **Mess** lie. It is a **Hiding spot**, and a New Game's layout puts Socks near its open edges. They can be picked standing, whenever the crosshair reaches them; crouching is not needed.
_Avoid_: under-furniture zone

**Hands**:
Where the player holds anything they carry (Q930): loose **Socks**, **Pairs** and their **Guide card**, up to **Carry capacity** items; or one thing that takes the whole Hands, which only comes into empty Hands and lets nothing else in while carried: the Radio, a **Gift** box, a vacuum's nozzle or container, a pairing machine, a knocked-down **Teammate**'s feet (holding the left button on their lying **Avatar** drags them behind you at a slower walk; letting go drops them, or by the basement washing machine's door slides them into its drum, where they spin for a few seconds and then tumble out, one at a time; they slip free when they get up, or by mashing Space; one dragger each). One held item is active (the newest, unless the mouse wheel cycles to another). Left click picks a Sock up (and with a **Dirty Sock** active, a left click on the **Laundry bin**, lying or carried by a teammate, bins it instead; with empty Hands it picks the bin up); a right click drops the active item on release where the crosshair is: on a flat-enough top it can see within pick reach (the floor, a furniture top, a shelf, an open inside, a **Heap**, a lying Pair). Anywhere else (too far, a wall, a steep side, a ceiling, a gap behind furniture) the crosshair turns red while something is held, and the drop is refused. Holding the right button charges a Throw instead. Holding G zooms in a little; holding R turns the active item where it is held, to look it over, and letting go of R leaves it at the angle it reached.
_Avoid_: inventory, backpack

**Cabinet**:
A themed piece of furniture, one per **Collection**, named "<Collection> cabinet", standing at one of the house's nine Cabinet spots: two in the basement (laundry, garage), two on the ground floor (kitchen, living room; the hall's is cut, Q1438), two in the kids' room on the first floor, two in the attic and the Lost Socks' in the Grotto (progression spec, Q618, Q642). Each **New Game** draws which Collection stands at each spot from its room's **Cabinet pool** (progression/71, Q1437): only Collections the Host has **unlocked**, never one twice; an undrawn Collection has no Cabinet and none of its Socks are in play that **Run**. It is a stack of **Drawers**, and only **Pairs** of its Collection may be shelved in it. A floor starts with 2 **Rows** per Cabinet (2 Drawers; Q617); each completed **Stage** adds 1 Drawer to every unlocked Cabinet until it is full (its Designs / 25; Q641), and a newly unlocked Cabinet starts at 2. The basement's second Cabinet (the garage's) is hidden until the basement **Stage** completes (Q644). It carries no icon: the player learns which is which by refusal (the **Whiteboard** lists the Collections' icons).
_Avoid_: shelf, wardrobe (the **Wardrobe** dresses the Avatar), chest

**Cabinet pool**:
The Collections a **Cabinet** spot may draw at a **New Game**, per room (progression/71, Q1437): laundry Simple; garage Machinery, Transport, Sport, Tech; kitchen Fruit, Vegetables, Drinks, Food; living room Patterns; kids' room (2 spots) Animals, Nature, Superhero, Space, Math; attic (2 spots) Winter, Space, Nature, Tech (the Grotto's Lost Socks spot is not ported, Q2599; the Lost Socks belong in the Drum, Q2675). A pool shares some Collections with another (Space, Nature, Tech); the draw still fills every spot, never with one twice. The pools, which spots stay hidden until a given **Stage** completes (Q1463; by default only the garage's, until the basement's, Q1467), the start set, the unlock rule and named modes (normal; Simple Socks Everywhere, every spot Simple, an example mode, Q1464) are data (`data/cabinet_pools.json`, Q1440).
_Avoid_: room set, spot list

**Unlocked Collection**:
A **Collection** a player may meet: drawn into a **Cabinet** when they host a **New Game**, and shown in their **Sock encyclopedia** (a locked one is hidden there entirely, Q1441). The first game has eight (Simple, Sport, Patterns, Animals, Superhero, Winter, Nature, Food; Q1439, the Lost Socks held back until the Drum, Q2675); each finished game (its **Final wash**) unlocks one more, in a fixed order: Space, Fruit, Machinery, Drinks, Tech, Vegetables, Transport, Math (Q1440, Q1465), named on the ending screen ("New Collection unlocked: <name>", Q1466). Kept in the player's **Profile** across games, never in the Run's save; in co-op the Host's decide the draw.
_Avoid_: owned Collection, available Collection

**Drawer**:
One slide-out drawer of a **Cabinet**, holding 25 **Pairs** as sock balls. Left clicking a drawer of a Cabinet while holding Pairs shelves every held Pair of its Collection into that drawer, overflowing to the nearest drawer with room; each drawer used slides open to show them. The outline on an aimed drawer takes a "full" tint when it has no room for held Pairs. Thrown Pairs fill drawers bottom up. An empty-handed click opens or closes a drawer.
_Avoid_: shelf, bin, slot

**Stage**:
One floor's campaign step (Q625): the basement is stage 1, and the other floors (ground, first, attic) stay behind a locked door until the stage before completes and its **Part** is fitted. A Stage is complete when every **Drawer** of every unlocked **Cabinet** that was not yet full when it began is full (Q624, Q633, Q999), from any **Pair** found anywhere in the house. Completing it pops the floor's **Part** out of the Cabinet where the last Pair went (Q1001) and drops each player a **Gift** under the **Old Tree** for each **Collection** completed during it (Q1588, Q1948, Q2678); its **Fix** opens the next floor's door, adds **Rows** to every unlocked Cabinet and spawns the **Socks** that fill them. A locked door reads "Please the washing machine" (Q1008). One HUD bar with stacked **Collection** icons shows the current Stage's progress and resets after each floor (Q627, Q633). When the final floor's Fix is done (**the Drum**'s, its softener, dungeon/04; the **Lost Sock Grotto**'s while it was the fifth floor), the machine is fixed; the run ends with the **Final wash** (progression/38, Q1006), no longer with the last Stage. The Drum's Stage has one Cabinet, the **Drum hatch** (the Lost Socks Cabinet), with one Row of 30: its bar counts the **Pairs** handed out through it (Q1900); the last Stage counts only its own floor's Cabinets. Co-op: the Rows are the same for any player count (Q631).
_Avoid_: level, floor (alone, for the campaign step), round

**Part**:
A replacement part for the broken washing machine, one per floor (Q1000, Q1003): basement the new filter, ground floor the new motor, first floor the drum belt, attic the detergent, the Lost Sock Grotto the softener. A floor's completed **Stage** pops it out of the **Cabinet** where the last **Pair** went (Q1001); it lies there turning and glowing until anyone picks it up, held in front of them like a **Gift**, so only with empty **Hands**. The detergent's Fix opens the fifth floor, **the Drum**: everyone is pulled in (dungeon/04). The softener appears glowing by the **Drum hatch** after the 30th Pair is handed out (Q1894, Q1897); clicked into the hatch, as a Part into the machine, it is the last Fix: everyone is spat out into the laundry and the machine is fixed. (With the **Lost Sock Grotto** switched on instead, the detergent opens its **Cellar hatch** and the softener appears on its shrine, Q996, Q1055.)
_Avoid_: piece (that is a Wardrobe word), item, component

**Dirty Sock**:
(Switched off for now, Q1817: none spawns, behind one tuning switch, ADR-0011; the code stays.) A Sock of the **Dirty Collection**, which only goes in the **Laundry bin** (Q1004): a reskin of a Sock (Q1042), the same item with the same physics, **Hands**, **Carry capacity**, pick, drop, **Throw** and **Hand-off**, but its **Design** greyed and stained brown, with a faint wavy stink wisp (Q1005), and it never pairs. Each **Stage** brings a few with its **Mess** (Q1043), about a tenth of that floor's Socks, lying loose, and each is binned on its own (Q1066), earning nothing (Q1068).
_Avoid_: smelly sock, laundry (for one Sock), mess sock

**Dirty Collection**:
(Switched off for now with the **Dirty Socks**, Q1817.) The **Collection** of the **Dirty Socks** (designer, 2026-11-06), with its own icon, a dirt stain (Q1069). It works like the other Collections, but its **Cabinet** is the **Laundry bin**, its Socks go in one at a time, and it counts toward no progression: no **Rows**, **Stages**, Collection-complete moment, Collection board or Coins. Its only goal is the full bin and the **Final wash**.
_Avoid_: dirty set, the ninth Collection

**First wash**:
The intro cutscene of a New Game (progression/86, Q1846-Q1849), played once per World, for everyone, when a player first clicks a **Laundry bin** into the washing machine: part 1, the wash starts calmly, then the machine breaks (haywire, ending at its angriest mood); part 2, a separate effect, a burst of Socks flies out of the machine's door. When it ends the first **Stage**'s **Mess** lies in its usual places, the player still holds the bin (still dirty, still one to wash for the ending), and the **Guide card** gains its second page (today's content) and turns to it. A **Guest** who joins mid-cutscene sees the end state. The Host decides; a save keeps whether it has happened.
_Avoid_: tutorial, intro level

**Laundry bin**:
A carryable hamper of dirty laundry (not the laundry basket prop). The game's end goal is loading several of them into the washing machine (Q1817, Q1905): the house layout has seven candidate spots (one per room, Q1818; placeholders), and a World uses only some of them (Q1850, tuning `laundry.bins_per_world`, 3 for now): the bin by the basement machine always, the others drawn at random from the other six for each New Game and saved with the World (Q1851); the unused spots have no bin. Each used bin stands full. It is carried in both **Hands** like a **Part**: a left click on a lying bin with empty Hands picks it up, a right click puts it down. Only after the run's last **Fix** (Q1819, Q2643), in the **Laundry day**, a left click at the basement washing machine while carrying one loads it ("[LMB] Load the washing machine", Q1820, Q1905); before then the machine refuses with a hint. The bin tips toward the door and its Socks pour into the drum (there is no wash wait), the pile of laundry behind the porthole grows a step per bin, and the empty bin stays in the carrier's Hands to put away anywhere (Q1845). The HUD counts the bins loaded. With the **Dirty Socks** on, the old single bin by the machine is used instead (Controls like a **Drawer**: a left click with a **Dirty Sock** active bins it; a Sock thrown into its opening still bins, Q1050).
_Avoid_: basket, hamper (in UI text), bin alone where a Drawer is meant

**Laundry day**:
The time after the run's last **Fix** when the **Laundry bins** are washed (Q2643): the washing machine is fixed, each bin carried to it and clicked in loads it, the HUD counts the bins loaded, and the last one starts the **Final wash**.
_Avoid_: ending phase, wash day

**Hamper**:
A bought carrier for many **Socks** (progression/64, Q1351), not the **Laundry bin**. Each level of the House **Upgrade** Hamper stands one more beside the **Old Tree**, up to 4 (like presents under it, Q1511); Big Hamper makes every Hamper hold more. Socks go in dropped or thrown into it and sit frozen inside. Carrying it takes the whole **Hands**: its carrier walks slower (no Sprint, no jump), can ride the **Elevator** and puts it down with a right click. Holding left click pours its Socks out one by one at the crosshair (into a pairing machine's hopper or a vacuum too); a left click into a standing one's mouth takes one Sock out, on its side picks it up, and E tips it out. Put down from a height, or its carrier knocked down, it spills some Socks.
_Avoid_: basket, bin, Laundry bin (that is the Dirty Collection's Cabinet)

**Sock vacuum**:
The standing vacuum with a hose and a nozzle (tools/25; named Q2188). A player picks up its nozzle and sucks loose **Socks** into its **Tank**; it lets them out by **Spit** or **Pour**. Without the **Filter nozzle** it sucks every Sock in reach. Its **Nozzle display** is on the nozzle from the start (Q2187).
_Avoid_: Smart vacuum, vacuum alone where the **Backpack vacuum** could be meant, hoover

**Backpack vacuum**:
A vacuum a player carries in the **Hands** or wears on their back, the nozzle out while worn (tools/27; named Q2189). It has its own **Tank** and no **Filter**; it lets Socks out by **Spit** only. Carried or worn it takes the whole Hands; a knocked-down or leaving player drops it beside them with its load.
_Avoid_: backpack alone (the Wardrobe has backpack clothes), vacpack, portable vacuum

**Splitter**:
A carriable sorter (tools/28; named Q2190). Socks thrown or spat into its **Hopper** come out one at a time through the **Output** whose **Filter** they match and gather in that Output's **Pile**; a Sock that matches none comes out of the **Reject** mouth at the back. It has two Outputs, a third by Upgrade. Carrying it takes the whole **Hands**.
_Avoid_: sorter, sorting machine

**Filter**:
A **Size** and a **Collection**, each of which may be Any (named Q2195): what a **Sock vacuum** with the **Filter nozzle** sucks, and what each **Splitter** **Output** takes.
_Avoid_: Sock filter, sort rule, selector

**Filter nozzle**:
The House **Upgrade** that lets a player set a **Filter** on the **Sock vacuum**'s nozzle (tools/29; named Q2191). Until it is bought the nozzle sucks everything.
_Avoid_: Smart nozzle, Sock filter (as the Upgrade's name)

**Nozzle display**:
The small clip-on screen on the **Sock vacuum**'s nozzle (Q2173; named Q2191). It shows how full the **Tank** is from the start, and the **Filter** once the **Filter nozzle** is bought.
_Avoid_: display pod, pod, gadget, screen alone

**Tank**:
Where a vacuum keeps the Socks it sucked (named Q2193): the **Sock vacuum**'s standing container, the **Backpack vacuum**'s capsule. The Upgrade that enlarges it keeps its name, Big Bag.
_Avoid_: bag, container, canister

**Spit**:
A vacuum letting its Socks out as a held stream shot forward from the nozzle (named Q2192). Each Sock is in **Flight** until it rests.
_Avoid_: blow, shoot

**Pour**:
Tipping the **Sock vacuum**'s **Tank** so its Socks fall out one by one (named Q2192). The **Backpack vacuum** cannot Pour.
_Avoid_: empty, dump

**Hopper**:
The opening on top of a **Splitter** (and of the pairing machine) that Socks go into (named Q2194).
_Avoid_: funnel, slot

**Output**:
One of a **Splitter**'s mouths that sorted Socks come out of, each with its own **Filter** (named Q2194).
_Avoid_: chute, outlet

**Pile**:
The loose Socks lying in front of one **Splitter** **Output** (named Q2194).
_Avoid_: heap (that is the Mess's), stack

**Reject**:
The **Splitter**'s mouth at the back, where a Sock that matches no **Output**'s **Filter** comes out (named Q2194).
_Avoid_: overflow, bin

**Final wash**:
The game's ending (Q1006, changed by Q1817-Q1820): once the run's last **Fix** has fixed the washing machine (Q2643), in the **Laundry day** a player carries each prefilled **Laundry bin** to the machine and clicks it in, which loads it (its Socks pour into the drum); the last of the World's bins loaded is the Final wash (Q1906): the door shuts, everyone watches the happy-wash cutscene, then the ending. (With the **Dirty Socks** on it is as before: once every one is in the single bin.)
_Avoid_: last wash, big wash

**Fix**:
Clicking a carried **Part** into the washing machine (Q1002). Everyone watches the machine's cutscene, then everyone respawns by it and the next floor's door unlocks. The machine starts each **New Game** at its angriest and calms one mood per Fix: blue-white sparks off its back and cable, smoke puffs and an electric buzz, fewer each time, gone once fixed (Q1007). The softener's Fix leaves it fixed and calm.
_Avoid_: repair, upgrade (that is an **Upgrade**)

**Row**:
One **Drawer** of a **Cabinet**, counted as a unit of progress: 25 **Pairs** (Q617, Q632). A **Stage** is measured in Rows.
_Avoid_: shelf, line

**Gift**:
A **Stage** present under the **Old Tree** (progression/79; the Cabinet and Collection drops are gone, Q1590): a gift box, the only way to get **Wardrobe** pieces beyond the ten basic ones every player owns from the start (Q2679). A completed **Stage** drops, for each **Collection** the team completed during it, one present per player in the **Session** (solo: one; Q1588, Q1944, Q1948); a Stage that completed none drops none, so the first presents come after Stage 2 (Q2678). Each is labelled for its player, who alone can take it, lying in a loose heap by the tree, each turning on the floor with a sparkle (Q689, Q703-Q705). The box is wrapped in paper in its Collection's colours with its icon as a repeating pattern and a matching bow (Q1591), and holds one piece of that Collection's theme the player does not own yet, rare ones at a lower chance (as they collect more, the pool shrinks until a rare is certain, Q1590); a player who owns that Collection's pieces whole gets a piece of another unlocked Collection they lack (Q2673). Its player clicks it to pick it up, held in front of them like any item, so only with empty **Hands**, and clicks again to open it: the box shakes with a rattle, hops and pops open where it is, for everyone to see, and they alone see the real piece turning (a **Hat** or **Clothes** model, a **Socks piece** on a pair of feet, a **Trail**'s live sample) with its name, which any click skips once it shows (Q715-Q718, Q1592, progression/33). Each player picks up and opens their own whenever they like (Q2674). Unclaimed gifts do not vanish during the run; the run's end loses them (Q1601). A new piece goes to the **Wardrobe**; only a player who owns every piece gets **Coins** instead (75, a placeholder; Q2673, replacing Q1609).
_Avoid_: loot, drop (for the item). The designer says "present" for a Gift lying under the **Old Tree** (progression/79).

**Whiteboard**:
One hand-drawn marker board on a wheeled easel in the basement laundry by the washing machine (Q639, Q667). It is only a legend: it is not the **Upgrade station** (Q1508; it was, Q1013). It always explains the **Collections**' icons and the **Sock** sizes, one line per unlocked Collection: icon, name, a small Sock drawing, the **Size** chips, **Rows** filled over total; new lines are drawn in when a floor unlocks. The same legend opens as a HUD overlay with Tab (hold) (Q649).
_Avoid_: legend board, noticeboard

**Upgrade station**:
Where the player spends **Coins**: the **Old Tree** in the basement garage (Q1508; the **Whiteboard** was it before, Q1013). Interacting with it (E) opens the upgrade menu, titled "the Old Tree" (Q1516), with the sound the Whiteboard had (Q1518); the Whiteboard keeps only its legend. It works the same for a guest. The washing machine is no longer the Upgrade station: it is the broken machine the **Parts** fix (Q1012).
_Avoid_: shop, store

**Old Tree**:
A forgotten artificial X-mas tree pulled half out of its torn box in the basement garage's corner, a tangled light string with a few bulbs still glowing, the decorations box beside it (house/45; Q1509, Q1516). It looks the same all game (Q1510). It talks (an old, slow voice heard only near it, Q2670); its breathing and bulb flicker wait for its rework (Q2506). It is the **Upgrade station** (Q1508); the bought **Hampers** stand beside it like presents under it (Q1511); a completed **Stage**'s **Gifts** lie by its foot, clear of them (Q1588).
_Avoid_: Christmas tree, X-mas tree, shop

**Elevator**:
The small service elevator in the shaft beside the kitchen's Food cabinet, through all four levels: a stainless car about 0.6 m a side behind a metal hatch on each level, its sill at waist height. A click on the brass call button beside a hatch, or on the shut hatch itself, brings the car to that floor, about 2 s a floor; the last call wins. Where the car stands, a click on its hatch opens or shuts it. The hatch slides shut before the car leaves, pushing anything on the sill inside, and opens with a bell where it arrives. While a hatch is open, things dropped in fall into the car; once it shuts they are frozen and carried, nothing is seen moving on the way, and they arrive exactly where they lay. Whatever lies in it rides, by one rule for every thing (Q2699): **Socks**, **Pairs**, the **Radio**, the **Sock detector**, the encyclopedia book, a **Machine Part**, a lying **Backpack vacuum**, and the **Cat**; the **Sock vacuum**'s container only with its nozzle on its hook (Q2710). Anyone can pick them up there. It is out of order (a printed plaque) until **Elevator Repair** is bought, locked until the ground floor opens, then goes to open floors only (Q2702). Players ride it too: aiming into the open car, Space climbs in; the creature shrinks, climbs through the hatch and rides curled up, in first person, low and dim with a rumble, Hands and all. Two squeeze in together; a dragger pulls the body they drag in as the second, and the drag holds. The car is called from the other floors, and a rider sends it by the floor letters on its inside wall (the car's floor lit, a locked one marked); where it arrives every rider climbs out, and Space climbs out where it stands open. A locked level refuses the ride. A thrown thing never hits a rider (Q2700). A player holding the Sock vacuum's nozzle may ride with the container left outside: the hose stretches between floors (Q2711).
_Avoid_: Dumbwaiter, lift, shaft (for the whole thing)

**Lost Sock Grotto**:
(Hidden for now, Q1873: **the Drum** is the fifth floor; the Grotto stays in the house behind one tuning switch, ADR-0012, its **Cellar hatch** never opening, its code kept.) The fifth and last floor, a hidden cave under the basement where every lost Sock in the world ends up (Q997): a small maze of timbered mineshaft tunnels (a few branches, dead ends, a collapsed passage) that leads to the shrine's cave, where a glowing Sock-shaped crystal stands on an old stone shrine in soft blue light and low mist. Reached only by the ladder under the **Cellar hatch**, never by the **Elevator**. A floor like the others: its **Stage**, its **Mess**, the Lost Socks **Collection**'s **Cabinet** and **Rows** on the cave's north wall. Its **Socks** lie only there (no mates on other levels), more of them in **Hiding spots** than on the house's floors (crates and barrels that open with a click, niches, rock cracks seen only from the right angle, the rubble, under the plank benches), rarer the deeper in: Common near the ladder, Uncommon in the side tunnels, Rare in the dead ends, the collapse and the shrine's cave. One shared lantern hangs by the ladder's foot: anyone carries it in a **Hands** place, its light is real for everyone, and it goes anywhere.
_Avoid_: cave level, dungeon, cellar (for the whole floor)

**Cellar hatch**:
(Shut for good while the **Lost Sock Grotto** is hidden, ADR-0012.) The floor hatch in the workshop's floor over the **Lost Sock Grotto**'s ladder. No lock and no hint: it stays shut, without a word, until the attic's **Part** is fitted, then a click opens or shuts it for everyone. Players climb the ladder with forward and back and step off at the top and the foot.
_Avoid_: trapdoor; hatch alone (the **Elevator**'s)

**The Drum** (placeholder name, dungeon/04; the designer's pick is open):
The fifth and last floor (Q1873, ADR-0012): the inside of the washing machine's drum, lying on its side far under the house, about 14 m in radius (bigger on the inside, Q1877). It is the **Lost Socks** Collection's floor, a short finale, not a new mechanic. Right after the attic's **Part** is fitted and its cutscene plays, the washer sucks every player in at once, wherever they stand (anything held is dropped there, Q1893); the one **Sock detector** is moved in, lying by the landing spot (Q1891), and no other house tool comes in (Q1875). The drum stands still: ordinary gravity and walking, only on the lower band of its curved floor (invisible limits at its edges, the walls too steep to climb), with low baffle ridges across it, ankle-deep water in the lowest strip (Q1876) and the laundry seen through the door glass; dim but readable light (Q1896). 30 **Pairs** of Lost Socks lie spread over it, some hidden in the water, behind the ridges and in the nooks by the door and the back hub (Q1884, Q1887); they go out through the **Drum hatch**, and the washer comments from all around, with an echo (Q1885, Q1886). After the 30th the softener appears by the hatch; handed out, the drum spins, the door bursts open and everyone flies out into the laundry, briefly knocked down (Q1890), the machine fixed. Quitting inside and loading resumes there; a **Guest** joining inside spawns there (Q1892).
_Avoid_: dungeon, water drum (the prototype), drum alone for the washer's real drum in the knockdown wash

**Drum hatch**:
A round hole in **the Drum**'s door glass at its very foot, about player height across, reached from a small ledge of drum floor (Q1878, Q1888; dungeon/06, Q1916, Q1920, Q1922-Q1925): a clean, transparent opening in a thin chrome ring with a few bolts, the laundry seen straight through it and its warm light shining in. Each **Pair** handed out goes through the hole and falls onto the laundry floor outside, where the handed-out Pairs stay and pile up, so the pile seen through the glass shows the progress (Q1924). An invisible barrier in the hole stops players and loose **Socks**: only handed-out Pairs pass (Q1925). Only inside the drum: the machine's outside door is unchanged (Q1919). It is the Drum's **Cabinet**: the Lost Socks Cabinet, standing at the hatch (the designer, 2026-11-13: "the hand out box should work like a cabinet"). It is shelved like any Cabinet: a left click (or E) shelves every held **Pair**, a right click drops the active one in, and a thrown Pair touching it shelves itself; at the end it takes the softener as the washing machine takes a **Part**. A single **Sock** or anything else is refused with a **Refusal**. What differs: its Pairs fall out through the hole onto the pile outside instead of filling visible **Drawers**, it has one Row of 30 (the Stage bar), and it pays no **Coins** and no Drawers (Q1880); a Pair handed out counts in its player's usual stats (Pairs shelved, the end screen's record, the **Sock encyclopedia**).
_Avoid_: slot, chute, door (the glass's)

**Door**:
The door in a room's doorway: every room has one but the open-plan kitchen, dining, living room and hall (open arches). A click opens or shuts it, for everyone; it never moves by itself. About a third stand shut at New Game, picked at random each time, and the save keeps them. Swinging, it pushes **Socks**, **Pairs** and the **Radio** out of its way. Shut, it stops the player and the light like a wall and muffles the Radio, the TV and the house's sounds behind it; pings and X-rays still show through.
_Avoid_: gate, hatch (the **Elevator**'s), lid or door of a piece of furniture (those open its **Hiding spot**)

**Piano**:
The upright piano against a living-room wall. Its key lid opens and shuts with a click like a cupboard door; with it open, aiming at a key and left clicking plays that key (every one of its 88 keys, A0 to C8, from a sampled real piano; there is no play mode). Everyone hears it from the piano, muffled behind a shut **Door**, and sees the key dip; several keys ring at once. **Socks** rest on its top, hide under its keyboard and in the key well under the shut lid.
_Avoid_: keyboard (for the whole piano), instrument

**Wardrobe Station**:
The wardrobe in the bedroom where the player opens **Colour & Wardrobe**. The player stands still while it is open; its doors stand open while anyone is in it, and **Teammates** see each change on their **Avatar** at once.
_Avoid_: closet, changing room (and not a **Cabinet**)

**TV**, **Radio**:
The two devices in **the house**, both Stations: a retro TV on its stand in the living room, facing the sofa, and a small retro radio that starts on the kitchen shelf. E turns the knob to the next **Channel**, and after the last one back to Off. Everyone in the **Session** hears the same Channel, roughly in step. The TV is heard near it, from where it stands. The Radio is the game's only music: everyone hears it in every room, a little louder and from its side when near it. A playing TV never quiets the Radio.
_Avoid_: television set, stereo, music player, background music

**Carrying the Radio**:
A left click on the **Radio** with empty **Hands** picks it up; while it is carried the Hands hold nothing else, and E still turns its dial. A right click puts it down where aimed (the floor, a table, a shelf), with the drop's rules (**Hands**); with **Throw** it can be thrown, landing with a clunk and playing on. A **Teammate** gets it only by a **Hand-off** into empty Hands, never by grabbing, and sees it in the carrier's hands. A player who leaves carrying it drops it where they stood. Where it lies and its Channel are saved.
_Avoid_: holding the radio (for an item in the Hands), radio item

**Sock detector** (tools/15, Q1856; the code calls it the beeper, its one name constant is `BeeperRules.NAME`):
A shared handheld finder, one in the house, lying on the workshop's workbench beside the encyclopedia book from the New Game (Q2698). Picked up with a left click into empty **Hands** like the **Radio** (it takes the whole Hands while held), put down with a right click, thrown with **Throw** or handed to a **Teammate** by a **Hand-off**; a player who leaves carrying it drops it where they stood; a full-charge Throw that hits a **Teammate** knocks them down, a weaker one bounces off to their feet, never caught (Q2700); lying in the **Elevator**'s car it rides (Q2699). It always works: it beeps towards the nearest loose **Sock** in the **Mess** on any floor (Socks in the Hands, in the air or shelved do not count), faster the closer it is, heard by the holder and nearby Teammates. Its small screen shows a distance band (near, mid, far) and an up or down arrow when that Sock lies on another floor, nothing when on the holder's floor. Early on so many Socks lie around that it hardly helps; it pays off late, when few are left (Q1822-Q1827). At the pull into **the Drum** it is moved in, lying by the landing spot, the only house item there; at the spit-out it comes out with whoever holds it, or lands in the laundry (Q1891).
_Avoid_: beeper (the code's word only), radar, tracker, sock finder

**Cat**:
The house's black cat (cat/01), with no part in the game's goal yet. It roams the unlocked floors (rooms and stairs, never through a shut Door), naps on the sofa, the beds or a sunny patch under a window, sits a while and meows now and then. E pets it: it purrs and little hearts float up. A left click with empty **Hands** picks it up; held, it wriggles and jumps down after a few seconds, and while held the Hands hold nothing else. A right click sets it down; with **Throw** it can be thrown, hissing, and it always lands on its four paws and runs off; a full-charge Throw that hits a **Teammate** knocks them down, a weaker one bounces off (Q2700). It sits on the living room's couch until the ground floor opens, fetches the nearest Pair now and then when petted, visits the litterbox, naps in the open **Elevator** car and rides it. Set down by the washer's door it goes through a drum cycle and comes out dizzy in its next coat (black, grey, ginger, white, calico; Q2703). The Host decides where it goes; where it is, what it does and its coat are saved.
_Avoid_: pet (for the cat itself), kitty

**Secret**:
A hidden thing to find in the house that gives its finder a **Wardrobe** piece (Q1014, Q1015): a cat Secret (the **Cat** on the **Piano**'s keys, dancing by the playing **Radio**, staring by the clock, thrown into the empty laundry basket), a washing machine Secret once it is fixed, or a co-op Secret that takes two players (riding the **Elevator** together, one holding the Cat while the other pets it, playing the Piano at once), which gives the piece to both. Each Run turns a few on, shuffled (5, or 4 alone, when the co-op ones cannot be found, Q1048), and each is found once a Run. Nothing counts or lists them; only small tells hint at them, never text (Q1016, Q1017). Finding one plays a gold-ribbon gift box over the finder's **Avatar** for everyone, then the piece turns in a spotlight. The piece stays in the finder's **Profile** across Runs. The Secrets can be switched off as a whole. (Not ported yet: designed later, after the run and progression, the eight and their pieces together; none in batch B, Q2600, Q2682.)
_Avoid_: achievement, easter egg, collectible, hidden Sock

**Guide card**:
A piece of cardboard with a white printed card glued on it. Page 1 (until the **First wash**) says the first goal, wash the laundry (placeholder wording); page 2 turns up after it, and the card turns to it at once; a held card turns between its pages with R (a placeholder key). Page 2 is four numbered line drawings with short captions that teach the game (Socks roll into a **Pair**; a Pair in its **Cabinet** pays **Coins** and a full **Drawer** pays the team's **Drawers**; spend Coins at the **Old Tree**; fill every Drawer of the floor and take the **Part** to the washing machine to open the next floor). Every player has one, in their **Hands** at New Game (a player who joins later gets one too), where it takes a place like any item. Active, it is held up close to read; G brings it closer. It can be dropped or thrown like a Sock and stays where it lands; anybody picks a lying card up, a **Teammate**'s too, but a pair of Hands holds one card (placeholder), and it is never handed to a Teammate. Where it lies, or that it is held, is saved.
_Avoid_: tutorial, manual, instructions (for the object)

**Channel**:
What the **TV** or the **Radio** plays. The TV has a sock puppet show, sock shopping (a real **Design** on a turntable), the weather and a test card, all made in the game. The Radio has music stations: the **Theme channel**, then Lo-fi, Jazz 78s, Funk, Metal, Rock. Static plays between Channels.
_Avoid_: station (a **Station** is what the player uses with E), programme

**Theme channel**:
The **Radio**'s first **Channel**, "Theme": the game's own cosy theme songs, one after another. Every New Game starts with the Radio on it.
_Avoid_: soundtrack, background music, menu music

### Socks

**Sock encyclopedia**:
A player's record, kept in their **Profile** across games, of every **Design** whose **Pair** was shelved in a game they were in (Q1153), page by page per **Collection** (not the Dirty Collection, Q1163; the Lost Socks only once they come with the Drum, Q2675); Designs not yet collected show as a silhouette and "???" (Q1161). Read on the title screen and from one shared book on the workshop's workbench in the basement (Q1195), which shows its reader's own pages (Q1158, Q1162; progression/53-54): picked up into empty **Hands**, read with E, put down anywhere.
_Avoid_: dex, album, catalogue (that is the code's list of all Designs)

**Design**:
One distinct sock look: colour and pattern (in the picture Collections a motif in a layout: one big, two, or a band), plus its **Size**, **Rarity**, **Collection** and a short name such as "Pizza duo". There are 605 (555 in the house's eight Collections, 50 Lost Socks), one Pair each.
_Avoid_: type, variant, skin

**Collection**:
A themed, authored set of **Designs** with its own Sock shape and colour. There are nine that count (the **Dirty Collection** stands apart): Simple (130 Designs, ankle), Patterns (100, crew), Sport (70, tube), Winter (55, chunky knee), Animals (50), Superhero (50), Food (50) and Space (50) (all crew), plus the Lost Socks (50), whose home is **the Drum** (batch D; held back until then, Q2675; the **Lost Sock Grotto** is not ported, Q2599). Completing one during a **Stage** pays no Coins (Q1602): it gives each player a **Gift** when the Stage ends. Each Collection has its own **Cabinet**.
_Avoid_: set, category, theme

**Size**:
How big a **Sock** is. It only makes matching harder, because similar Designs in different sizes act as decoys.
_Avoid_: scale

**Rarity**:
A tier on each **Design**, and on each cosmetic piece (common, uncommon, rare). Rarer Designs pay more and are found later; the whole-**Collection** gift draws the rare pieces first.
_Avoid_: quality, tier (alone)

### Economy and progress

**Coins**:
A player's own currency (Q1221): the **Pair**'s payout goes to the player who shelved it, is saved per player (by their Profile id) and joins nobody else's wallet. Coins buy the buyer's own **Personal** upgrades.
_Avoid_: money, cash, points, the bank (shared)

**Drawers** (the team currency):
What the whole team earns each time a Cabinet's **Drawer** fills (Q1224): 1 on the basement and ground floors, more the further into the house (2 first floor, 3 attic, 4 grotto; Q1405, placeholders); shared, saved and in the join snapshot. Always written with the team's icon, never confused with a **Drawer** of a **Cabinet** (that one holds Pairs); HUD wording is the designer's pick (progression/56). Drawers buy the **House** upgrades.
_Avoid_: Drawer points, team coins

**Upgrade**:
A purchase at the **Upgrade station**: one level of an entry in the one Upgrade list (data/upgrades.json; progression/57, progression/63), in two sections, **Personal** and **House**. Personal upgrades improve their buyer (**Footwork**, **Sprint**, **Quick Grab**, **Big Hands**, **Long Arm**, **Quick Charge**, **Sock Smarts**, **Sock Sense**, the X-rays and their All-Hands, Recharge and Lingering upgrades); House upgrades improve the free machines and the house for everyone (**Elevator Repair**, **Hamper**, **Big Bag**, **Strong Suction**, **Sole Mates**, ...). **Throw** and **Sprint**: Throw is free from the start but weak; Sprint starts locked (Q1343, Q1344). No Upgrade works without the player.
_Avoid_: power-up, helper

**Personal**, **House**:
The two sections of the Upgrade list (Q1216, Q1364, Q1368). Personal is each player's own, bought with their own **Coins**. House is one for the whole team, bought with the team's **Drawers** by anyone at the Whiteboard, in any order (Q1240); a House upgrade applies to every player, later joiners too. House is the name in solo and co-op alike (it replaces "Team tree"). Four House upgrades are co-op only (Sole Mates, Sole Hands, Mate Radar, Roomy Car) and hidden in single player (Q1357). An upgrade whose effect is not built yet shows greyed "Coming soon" in the menu: seen, not buyable (Q1272, Q2669).
_Avoid_: skill tree, tech tree, team tree

**Big Hands**:
One Personal upgrade with four levels that raises the **Carry capacity** of the **Hands** (Q1349). It replaces Hands I-II, Hands III and Deep Hands.
_Avoid_: Hands I, Deep Hands

**Sock Smarts**, **Sock Sense**:
Two Personal upgrades (Q1347, Q1348). **Sock Smarts** (cheap) makes a held Sock in the **Hands** show its readout; without it, a held Sock shows only its model. **Sock Sense** needs Sock Smarts and shows the readout for the Sock under the crosshair.

**Footwork**, **Quick Grab**:
The two halves of the old speed Upgrade (Q1234), Personal upgrades (4 levels each): Footwork makes walking faster, Quick Grab makes picking up and swapping quicker.

**Long Arm**, **Quick Charge**:
The two halves of the old extra **Throw** levels (Q1234), Personal upgrades with no prerequisite: **Long Arm** (3 levels) makes a Throw fly further and faster, **Quick Charge** (2 levels) makes it charge faster. Throw itself is free from the start but weak (Q1344).

**Sock Sense**:
An **Upgrade**, bought once (120 Coins, a placeholder), with which the loose **Sock** under the crosshair (the one with the **Highlight**) shows the same readout as an item in the **Hands**: its boxed Size, Collection icon, Design name, the sock icon and the count the Hands would then hold (a Pair icon when it would fuse with a held mate). It shows for that player only, nothing while not bought, and it shows no Pair lying on the floor.

**Sole Mates**:
A **House** upgrade (Q1223, co-op only), bought once with the team's **Drawers** and then every player's. It works on the **active** Sock: a **Teammate**'s active Sock keeps the **Highlight** outline in that Teammate's **Player colour** while it is the mate (same **Design**) of your active Sock, in line of sight only. When the match starts a soft sound plays once at the Teammate's Hands and your own Sock glows briefly. Without it there is no match cue at all (Q1115-Q1118, Q1361). Two House upgrades build on it (both need it, both co-op only): **Sole Hands** outlines the whole Teammate (their **Avatar**, in their colour) while your active Sock's mate is in any of their slots, not only the active one; **Mate Radar** makes both cues show through walls.

**Flight**:
An item on its way down after it leaves the **Hands** (Q932): every drop, every **Throw** (the Radio and the **Guide card** too) and every Sock a vacuum spits out. It moves until it rests. How it falls is per kind (Q956, Q957): a loose Sock tumbles along its length and then joins the **Mess**; anything else falls as one light body and lies still once it stops. A Flight decides nothing: it reports what it touched, and the game's rules decide whether that shelves a Pair, is a **Hand-off** or knocks a **Teammate** down (Q929).
_Avoid_: projectile, toss

**Throw**:
An **Upgrade**: hold the right button past a short moment to charge (a ring fills round the crosshair) and release to throw the active item from the **Hands** along the aim with a gravity arc; a release just after the charge starts is a short lob, and a shorter click is still a drop. There is no cancel: releasing a charge always throws. A **Pair** that touches its own **Cabinet** shelves itself and pays; anything else bounces off and falls (a loose **Sock** rejoins the **Mess**, a Pair lies on the floor). A Throw that hits a **Teammate** is a **Hand-off**, except one released at full charge: that knocks them down for a moment (their **Avatar** goes limp as a ragdoll and flops the way the hit pushed them, even off a bounce, colliding with walls, furniture and teammates, standing or lying; lying there they block teammates walking into them; their view rides their head; they can not move, pick or throw, and get back up where their feet lie; they are told who did it) and the item falls by them. **Long Arm** adds range and **Quick Charge** charge speed.
_Avoid_: toss, shoot

**X-ray**:
An **Upgrade**, bought once, that unlocks the Show pair ability: key 1 makes the mate of the active item in the **Hands** (a loose **Sock**) glow through walls, **Heaps** and furniture (in a **Teammate**'s Hands too) for 10 s, then it cools down for 50 s. The glow follows the mate as it moves: thrown, carried or fetched by the **Cat** (Q2714). Only the active item's mate shows; cycling the Hands moves the glow; only its user sees it. Its icon sits at the bottom left of the HUD with the keycap 1: hidden until bought, a radial sweep while it cools down, glowing while on. Each player has their own cooldown. There is no Size or Collection X-ray.
_Avoid_: vision, scanner, highlight (that is the crosshair's outline)

**Cabinet X-ray**:
An **Upgrade**, bought once (200 **Coins**), that unlocks the **Show Cabinet** ability: key 2 outlines the whole **Cabinet** that takes the active item in the **Hands** (a loose **Sock** or a **Pair**: its **Collection**'s Cabinet, locked, sheeted or full alike) in amber through walls and furniture, pulsing, for 10 s, then it cools down for 30 s (Q1964, Q2701). Its title is "Cabinet X-ray: Show Cabinet", its tooltip "Show Cabinet (key 2): the right Cabinet glows through walls." (Q2713). It follows the active item; nothing active, nothing glows. Only its user sees the glow. Its icon sits right of Show pair's at the bottom left of the HUD, with the keycap 2.
_Avoid_: drawer finder, cabinet vision, Show drawer (its old name)

**Show Cabinet**, **Show pair**:
The two X-ray abilities, on keys 1 and 2: Show pair is the **X-ray**'s (the active Sock's mate glows), Show Cabinet the **Cabinet X-ray**'s (the right Cabinet is outlined in amber; renamed from "Show drawer", Q2701, Q2713). Each runs for a while, then cools down; nothing happens, and nothing is spent, while nothing held fits.
_Avoid_: Show drawer


**Carry capacity**:
How many items (loose **Socks** or **Pairs**) the **Hands** hold. It starts at one: a held Sock plus its mate fuse into one Pair, so a Pair still fits. Upgrades raise it so one trip can shelve several Pairs.
_Avoid_: inventory, slots

**Mate distance**:
How far a **Sock** lies from its mate in the **Mess**, walking: through the doorways and up and down the stairs, never through a wall or a floor. It starts small and grows with progress, and is larger for rarer Designs. A share of the rarer Designs has its mate on another level, a trip up or down the stairs.
_Avoid_: spacing, spread

**New Game**:
A fresh start: the **Mess** is baked anew (it waits until the **First wash**), overwriting any save (the title asks first); the machine looks fine and the **Guide card** shows its first page. Everyone starts at the washer spawn; a loaded game starts each player where they quit.
_Avoid_: new run, reset

### Playing together

**Play**:
Playing alone and offline: one player, nothing listening for others. The main menu's first entry: Continue, **New Game**, **Wardrobe**.
_Avoid_: singleplayer, solo mode, offline mode

**Coop**:
Co-op for up to four players in one shared house, one **Host** and up to three **Guests**, joined by the host's address. The main menu's Multiplayer entry holds Host and Join: Host goes straight to the **Lobby**, where the Host chooses the **World** to play or a **New Game**; the Join page takes the address and leads to the Host's Lobby.
_Avoid_: multiplayer, online, versus

**Colour & Wardrobe**:
The page where a player picks their **Player colour**, **Hat** and **Clothes** beside a live preview of their **Avatar**: behind the **Lobby**'s Wardrobe key and at the **Wardrobe Station** in game (no title page since lobby/03, Q1661).
_Avoid_: character select

**Session**:
One co-op game in progress, from the moment the **Host** opens it until they end it. **Guests** drop in and leave at any time; when the Host ends the Session everyone goes back to the title. Only the Host saves it.
_Avoid_: match, room, server (for the game)

**World**:
One saved game: the **Solo World** (the one played alone) or one of the **Host**'s up to five co-op Worlds, kept newest first, each showing its **Group** (names and colours), the floor reached, the play time and when it was last played. Only the Host's machine keeps it. The Solo World can be taken into co-op: it then becomes that Group's co-op World and the Solo slot is left empty.
_Avoid_: save slot, run, profile (the **Profile** is the player's)

**Group**:
The players fixed to a co-op **World** at its first **Play** from the **Lobby**: whoever is in the Lobby then. No seats and no adding later; only Group members may join that World, any time, and one joining while it is in play lands beside a **Teammate** with their **Coins** and **Upgrades** as they left them.
_Avoid_: party, team, squad, crew

**Lobby**:
The screen every game starts on, Solo and co-op, before the **World** and never saved: a menu screen on the title's backdrop with the players' **Avatars** side by side on pedestals, four places in co-op (a free one shows a grey silhouette and waits for a player), each with the player's name and a Ready mark under it; a player's **Lifetime tallies** show while their Avatar is focused (the mouse over it, or the pad's selection on it), the **Wardrobe** is behind the button beside the player's own Avatar, and the **World**'s card at the top lists its **Group** by name. In co-op a sidebar on the right holds the World settings: the **Host** chooses the save there (the Solo World, a co-op World or a **New Game** with its Pairs per **Drawer**) and every **Guest** sees the choice; a change clears everyone's Ready. Each player toggles Ready and the Host starts the World for everyone once all are Ready; a **Guest** may Leave, and the Host's Back closes it. In Solo it shows only the player's own Avatar with Continue (the Solo World, where the player was) and **New Game** (which starts in the basement).
_Avoid_: waiting room, hub, room (the Lobby was a room until lobby/05)

**Host**:
The player whose machine runs the **Session** and keeps the save: they pick a **World** or start a **New Game** on the Host page, and decide every pick, drop and buy. Their "End session" (ESC menu) asks first, then sends everyone back to the title.
_Avoid_: server, owner, leader

**Guest**:
A player who joined the **Host**'s **Session** by its address. Their game is the Host's: they never save, and on Leave their **Hands** drop where they stand. Coming back, they keep their **Upgrades** and their spot.
_Avoid_: client, joiner, peer

**Teammate**:
Any other player in the same **Session**, seen as their **Avatar**. Teammates share one shelf and the team's **Drawers**; each has their own Hands, Upgrades and **Coins**. Nobody takes from a Teammate's Hands.
_Avoid_: ally, partner, other player

**Knockdown**:
A **Teammate** hit by a full-charge **Throw** falls as a ragdoll the **Host** simulates and can not move, pick or throw for 5.5 s (placeholder), then gets up. Others may **Drag** a knocked-down Teammate.
_Avoid_: stun, faint

**Drag**:
With empty **Hands**, holding the left button on a knocked-down **Teammate** grabs their feet (their Hands carry the body, so nothing else comes in) and the dragger walks slower, pulling them along. Letting go drops them; the dragged player mashes Space to struggle free, and the knockdown's timer runs on. One dragger each. Letting go at the basement washing machine's door is a **Wash**; climbing into the **Elevator** pulls the body in as the second rider.

**Wash**:
Letting go of a dragged **Teammate** at the basement washing machine's door slides them into the drum: a blob in their **Player colour** tumbles behind the porthole and their own view spins with it, with no crosshair. After 3 s (placeholder) the door bursts open and they fly out head first, knocked down briefly, and their screen fades back into play. One at a time.

**Avatar**:
A player's body in the house: a wonky sock creature with googly eyes and stubby feet, tinted in their **Player colour**, with their name over its head, their held items floating in front of its belly (it has no arms) and the **Hat**, **Clothes** and **Socks piece** they wear from the **Wardrobe**. Its eyes look at the nearest player, it waddles as they walk, it crouches when they crouch, and its top curls forward over its belly when they look down and leans back when they look up. A player sees only their own feet and the edge of their belly, looking down.
_Avoid_: character, puppet, capsule, skin

**Player colour**:
One of eight soft sock colours a player picks on **Colour & Wardrobe** at the **Wardrobe Station** (a Guest keeps their last one when it is free, else takes the next free one on joining); it tints their **Avatar**, their name and their **Ping**. No two players share one: a taken colour is greyed out with the name of who has it, and the **Host** refuses it.
_Avoid_: team colour, tint

**Hand-off**:
Giving the active item to a **Teammate**, only if it completes a **Pair** in their **Hands** (progression spec, Q658; otherwise it is refused): a right-click drop aimed at them within reach (their **Avatar** is outlined by the **Highlight** while it would hand off), or a **Throw** that hits them (otherwise it bounces; a full charge still knocks down). It goes into their **Hands**. Socks lying on the floor stay free for anyone, and a fused **Pair** may be handed over. With **Sole Mates**, a player sees and hears when they and a Teammate hold mates; without it there is no cue.
_Avoid_: give, trade, pass

**Ping**:
Middle mouse, marking what the crosshair points at for the **Teammates** in the pinger's **Player colour**, for a few seconds, with a soft blip: a tap **Highlights** it (a Sock, a floor **Pair**, a **Station** or a Teammate; a bare floor or surface gets a small ring), a hold opens the **Emoji wheel**. It shows through walls and follows a pinged Sock. One active Ping per player: a new one replaces the last. Only with Teammates in the flat.
_Avoid_: marker, flag, beacon

**Emoji wheel**:
The **Ping**'s wheel, open while middle mouse is held: five emoji keycaps round the crosshair (Here, Help, Yes, No, Nice). The mouse picks one; letting go places it as a sticker on what the crosshair points at, with a small copy over the pinger's **Avatar**. Let go in the centre and nothing is placed.
_Avoid_: emote menu, chat wheel

**Highlight**:
The soft outline round whatever the crosshair would act on: a Sock, a floor **Pair**, a **Drawer**, a **Station**, or a **Teammate**'s **Avatar** for a **Hand-off**. One warm white everywhere; its one variant is the red "full" tint on a drawer with no room for the held Pairs. A **Ping**'s highlight outlines the pinged thing in the pinger's **Player colour**, through walls; with **Sole Mates**, a **Teammate**'s Sock matching one in the **Hands** is outlined in their colour, in line of sight only.
_Avoid_: glow, selection, X-ray

**Refusal**:
The short red line under the crosshair, wobbling for a moment, when something can't be done: "Hands full", "Wrong Cabinet", "Need 150 Coins", "Maxed out", "Pair socks first", "Can't drop there". It says only what is wrong, never what to do; a soft "refuse" sound plays with it.
_Avoid_: error, warning, hint

**Wardrobe**:
Where a player dresses their **Avatar**: one **Hat**, one **Clothes** piece, one **Socks piece** and one **Trail**, any slot may be empty, beside a live preview of their creature in their **Player colour**. Opened at the **Wardrobe Station** in game (as **Colour & Wardrobe**), from **Play**'s Wardrobe, or as **Colour & Wardrobe** in **Coop**. The ten basic pieces (the six **Hats** and four **Clothes** below) are every player's from the start (Q2679, reversing Q696); every other piece unlocks by a **Gift** (or an **Achievement** that names it, Q1690) and stays unlocked: a **New Game** never locks it again. The Lost Socks' six pieces are hidden, neither listed nor counted, until the Lost Socks come with the Drum (Q2683). What a player wears and has unlocked stays with them (their own **Profile**, not the save) and goes with them into any game.
_Avoid_: closet, customisation, skins, cosmetics (and not a **Cabinet**)

**Hat**, **Clothes**:
The **Wardrobe**'s two slots, each piece in its own fixed colours. Hats sit on the head: beanie, cap, top hat, party hat, bobble hat, crown. Clothes go over the body and crouch with it: scarf, apron, bow tie, jumper.
_Avoid_: outfit, gear, item (an item is held in the **Hands**)

**Socks piece**, **Trail**:
The **Wardrobe**'s two gift slots. A Socks piece (a Socks look) is a pair of little socks over the **Avatar**'s stubby feet, its cuff up to the ankle, in its own colours (Odd pair: one grey, one white); it walks, crouches and falls with the feet, and the body stays in the **Player colour** (Q870). With none, the feet are bare. A Trail is an effect behind the Avatar's steps, each its own shape and motion (Q872; Lint puffs: grey fluff that drifts up and fades). Each **Collection** theme gives 2 **Hats**, 2 **Clothes**, a Socks look and a Trail.
_Avoid_: socks for the creature's skin or body colour (the body is never patterned)

**Profile**:
A player's own small file on their machine, apart from the save: their name, **Player colour**, player id and last address, what they wear in the **Wardrobe**, the pieces they have unlocked, their **Lifetime tallies**, their **Achievements**, their **Sock encyclopedia** and their **Unlocked Collections**. It goes with them into every game, as **Host** or guest; teammates never share one. The Profile page (from the title and the ESC menu) shows the Lifetime tallies on top and the Achievements under them (Q2681).
_Avoid_: account, save (the save is the **Game**'s), user

**Achievement**:
A named badge a player earns in their own **Profile** when a condition is met (Q1697): in batch B a **Lifetime tally** reaching a number. It may give a **Wardrobe** piece (Q1690); it is earned once and never taken away; a hidden one shows "???" until earned (Q1693). Earning one slides a small card in at the top right with its icon, title and a soft chime (Q1695). Each machine decides only for its own player; Steam's store is a mirror behind one seam, in batch D (ADR9). Which Achievements batch B ships is open (core/146).
_Avoid_: Secret (a hidden find in the house), trophy, milestone

**Lifetime tallies**:
A player's own progress over every game they play, as **Host** or guest, kept in their **Profile** (Q893): **Pairs** shelved, **Coins** earned, **Collections** completed, floors completed and games finished. Each machine counts what happens in its game into its own player's Profile, whoever did it; a loaded save or a join counts nothing that happened before. An **Achievement** is earned when its tally reaches its number (the old Wardrobe milestones are gone, Q1692). Shown on the **Profile** page, above the Achievements (Q2681).
_Avoid_: stats, score, achievements, XP

### Menus

**Studio intro**:
The Hudry Games intro played once per launch before the main menu: three turkeys run across, HUDRY's letters fall in behind the last one, GAMES slams down from the lens (about 5 s, any key or click skips it). It lives in `studio_intro/`, shared by every Hudry Games title (intro/01, intro/02).
_Avoid_: splash, logo screen, boot screen

**Options**:
This machine's settings, from the main menu and the ESC menu, applied at once and kept on this machine (never in the save or the profile): the graphics preset, a volume per sound bus (Master, Music, Effects, Ambience, UI), mouse speed and Invert Y, fullscreen or windowed, V-sync and the FPS cap.
_Avoid_: settings menu, preferences, config

**Licence**:
The main menu's page of credits and licences: who made the game, and every third-party work in it (the engine, the font, the sounds, the skies) with its author, source and licence.
_Avoid_: credits screen, about, legal
