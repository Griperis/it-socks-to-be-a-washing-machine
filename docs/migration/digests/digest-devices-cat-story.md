# Design digest: devices, Cat, Grotto, rogue machine, secrets, intro, questions, story

Source: docs/llm/{tools,cat,dungeon,rogue-machine,secrets,intro,questions,story}. Written 2026-11-19.
Words follow GLOSSARY.md. "(Qn)" = designer answer number. Numbers marked decided or placeholder.
Today (2026-11-19): tools/26 merged; tools/25 built but unmerged; tools/27-29 not started; tools/30 line-ups picked (models not yet built).

# PART A. TOOLS AND DEVICES (docs/llm/tools)

## A1. Sock vacuum (the game's CURRENT vacuum on main; becomes the "Smart Sock vacuum", see A2)

**What it is.** Two parts: a nozzle (held, aimed, on a hose) and a container the hose runs to. The nozzle sucks loose Socks into the container. Placed in the kitchen (ground floor) of the house in every Run.

**Rules that bind (built on main today; tools/25 will change the unloading, see A2)**
- Both parts are held in the Hands; the nozzle takes the whole Hands (Q720, Q732). Taking the nozzle drops held Socks and Pairs to the floor (Q736). A held Guide card also drops; taking it while carrying the Radio or a gift box is refused "Hands full" (built behaviour, tools/01 follow-up, not explicitly answered).
- Left click (held) sucks loose Socks in a short cone in front. Pairs in the Hands, shelved Socks and Gifts are never touched (Q721). Nearest Sock first.
- The container stands on the floor; the hose has a maximum length (Q724). To move the container, hang the nozzle on its hook and carry the container in the Hands; no vacuuming while carried (Q724).
- Container holds 24 Socks (placeholder, Q725; Big Bag raises it). A full container stops sucking; a full container blocks, nothing happens (Q725, Q738).
- Hose: 5 m, drawn as a sagging rope, taut at the limit with a tug; the nozzle stops pulling beyond it (Q733). The hose is a real rope that collides with the house and drapes over and around geometry, may snag round corners and limits reach, never passes through (Q1079, tools/08). Doors and Drawers (also furniture doors and drawers) push the hose; the Elevator car does not (Q1105, tools/09).
- Co-op: one nozzle per container; anyone can use the container's button, window and outlet (Q734). Two players may use one vacuum at once: one carries the container, a teammate holds the nozzle (designer 2026-11-06 "it should be possible to pick up the vacuum at the same time for multiple players if somebody holds the hose"; Q1135). At full hose length neither can walk farther; both are stopped with a tug, neither drags the other (Q1135). Sucking works while both are held.
- Interaction is by a dedicated button on each device, not the whole body: the whole vacuum is only picked up (Q742).
- Right click drops the nozzle where aimed; it stays on its hose, a click picks it up; dropped near the container's hook (0.6 m) it hangs itself (Q741).
- Window: transparent, shows the loaded Socks (blocks) and a count/gauge (Q735, Q737).
- Look while sucking: soft white air streaks into the nozzle mouth and small dust motes drawn in from the floor (Q1136). Sounds: vacuum events exist (motor loop, thwip per Sock, mode click, spit tick, spit out, nozzle hang, nozzle drop, lift, set down); one 1950s appliance family (soft retro motor, chunky clicks, friendly bell); per-Sock sounds rate-limited 0.09 s (Q1137; tools/06, tools/11).
- Spit (built, to be REPLACED by A2): spit mode holds the load 6 s then streams out a REAR outlet, one Sock per 0.1 s; sucking continues during the hold (Q744; supersedes Q726 button, Q730 "E blows out"). Spit is a gentle dribble 0.8 m/s (was 3.2) with rise and scatter scaled by 0.25 (Q1584); each spat Sock starts on the room's side of a wall and drops in front of it, nothing lands in the next room (Q1585).
- Performance: the vacuum view must cost only while a vacuum is in use (designer 2026-11-07 profile: about 2 ms of a 4 ms frame); the designer approved the review build "looks right; merge it" (tools/12).

**Numbers** (data/tuning/vacuum.json): capacity 24 (placeholder); hose 5.0 m (decided Q733); reach 2.0 m, cone 22 deg half angle (placeholder); suck interval 0.06 s via upgrades.house.suck_interval_*; spit_hold 6.0 s, spit_interval 0.1 s, spit_speed 0.8 (decided Q1584), spit_up 0.1125, spit_spread 0.0875; hang_reach 0.6; hose_segments 12, hose_iterations 6, hose_damping 0.96, hose_budget_ms 0.3 (placeholders, balance round); spit_bodies 24 (physics/36).

**Decided against / superseded**: E-spit (Q730, gone by Q744); spit button (Q726, Q744); E on a vacuum (nothing now, tools/04); hose without collisions (Q733 "Visual only" reversed by Q1079).

**Open (tools/01, 04, 10, 11; all unanswered, mostly about to be moot because tools/24/25 remove the mode button, take-one click and rear spit)**
- [later] (tools/10) Both orders are built: a teammate may also take the nozzle off a container someone already carries (the carrier's own click cannot). Keep, or only "carry while a teammate holds it"?
- [later] (tools/10) A nozzle dropped while its container is carried lies where it was dropped and the hose holds the carrier back from it; a lying nozzle's container still cannot be picked up. Or should a nozzle let go mid-carry hang itself on the carried container's hook?
- [later] (tools/10) The tug is only the hose's shake on the walker's machine, no camera nudge, no sound.
- [later] (tools/11) Should a full vacuum keep its motor on, strain, or give a refusal sound? Taking the nozzle plays the Hands' "pick" rustle: own unclip sound? Motor spin up/run down whine instead of a 0.12 s fade? The look's numbers are constants in main/vacuum_fx.gd (18 streaks, 0.28 s, 14 dust motes): tune after review? Is "vacuum_spit_out" the right sound for the hopper feed?
- [later] (tools/06/11) Should the vacuum's motor pitch rise as its container fills?
- (tools/01, tools/04 follow-ups, never answered, now mostly overtaken): hand mode gives last-in-first-out; spat Socks hit nobody; the hold shows only as the orange button blinking.

## A2. Smart Sock vacuum, filter, pour and spit-out (tools/24 decisions; tools/25 built but UNMERGED; filter Upgrade tools/29 NOT STARTED)

**What it is.** Today's two-part vacuum reused ("Reuse the original vacuum. It should work similarly with two players", Q2095), with filters added as an Upgrade and a new way to empty it. One compartment, no splitting ("no comparments, everything is still one compartment").

**Designer's words (2026-11-19)**: "A vacuum with the hose filters (cycle through them)"; "one filter is size"; "second is collection (only out of which ones can be found)"; "the size and filter is displayed on top of the hose as a gadget display, changing it with scrollwheel displays different collections and size"; "adding the filters is a upgrade to the vacuum".

**Rules that bind (decided; NOT in the game on main until tools/25 merges, tools/29 not started)**
- Two filters on the nozzle: Size and Collection. Wheel up steps the Size filter, wheel down steps the Collection filter (Q2087). Each list is "any", then the values, and wraps (Q2121). Both set: a Sock must match both; either can be "any" (Q2088). The nozzle picks the nearest matching Sock; the Host refuses a mismatch (tools/25 acceptance).
- The Collection list holds only Collections with a loose Sock in the Mess right now (resting or moving) (Q2089); Lost Socks are an entry of the list when one lies loose (Q2123). A set Collection stays set when it runs out; the list is rebuilt on the next scroll (Q2124).
- One Upgrade adds the display and both filters (Q2090). It sits at the end of the vacuum row in Quick Spit's old cell, no prerequisite, placeholder cost 2 Drawers (Q2126). Without it the wheel does nothing and the nozzle shows only the capacity gauge (tools/29). Until it exists tools/25 uses placeholder tuning flag `vacuum.filter_unlocked` (on by default).
- Nozzle display (clip-on pod, variant a, Q2173): the Size as a word, the Collection's icon and name, and a capacity indicator; no count of Socks left in the house ("1. without the number of socks left in house + capacity indicator.", Q2122). It blinks when a filter is set and nothing in front matches (the lead's reading of Q2122).
- Unloading (replaces hand mode and spit mode): the mode button, the take-one click, the rear-outlet spit with its hold clock, and the Quick Spit Upgrade with its tuning are REMOVED; the window stays as a view of the load (Q2119, Q2097 "Taking a Sock out by hand goes").
- Nozzle in the Hands: left click sucks; a TAP of right click hangs or drops the nozzle as today; HOLDING right click spits out (Q2111, Q2115). Spit-out is a stream while held, blows Socks out of the nozzle one after another where you aim (Q2096, Q2116), ignores the filter and empties in order (Q2117). The release after a hold does not drop the nozzle (tools/25).
- Pour ("stay" mode is the normal sucking mode): the container's carrier holds E; the container tips about 70 degrees forward (visible to teammates) and one Sock falls every 0.15 s in front of it until E is released, the carrier loses it or it is empty (Q2097, Q2098, Q2120). The carrier can pour at any time; a teammate's sucking pauses while it is tilted (Q2118). Designer's words: "when in stay mode, you can tilt (also visually) the vacuum and shake it up with E, so it drops the socks below on the ground". (The tools/23 stand variant used the same E-held pour: Q2076, Q2086 replaced hold-right-click Q2071; the pour came "straight down in front of the container", Q2084; "Whoever holds the container drops the load; it lands at the container", Q2069; "The load pours while the key is held", Q2070.)
- Big Bag, Strong Suction, Long Hose and Wide Nozzle apply to both vacuums (Q2125); exception: Long Hose does nothing for the backpack (Q2135).
- Sounds: spit-out reuses the old spit tick; the pour only the landing sounds, until the sound bench (Q2128).
- Model: the Smart Sock vacuum keeps today's model with the display added (Q2113, confirmed Q2174).
- Build rule: the filter (value, lists, stepping, matching) and the display are their own small classes reusable by the backpack and splitter; all three built in parallel after the shared piece has ONE owner (Q2114). The test row's other machines stay parked on their branches (Q2112). The game is unshipped: no save-compatibility code (tools/25).

**Open (tools/24 and 25)**
- [later] (tools/24) Not asked yet, placeholders: where the third output sits; what E does while the splitter is carried; spit-out pace (today's 0.1 s); the pad bindings; whether the pause at 40 counts Socks by distance or by output.
- [later] (tools/24) The glossary needs Smart Sock vacuum, Backpack vacuum, Splitter, Filter, Spit-out, Pour.
- (tools/25) Pad bindings for spit, pour and the two wheel directions: proposed as placeholders, listed as follow-up.

## A3. Backpack vacuum (tools/27 NOT STARTED; all rules decided, none in the game)

**What it is.** A separate basic vacuum worn on the back: "basic vacuum - sucks everything, carried on back, no need of putting it in your hands to move it, you equip it, and vacuum until inventory full, you can dump it on the ground as well" (designer 2026-11-19).

**Rules that bind**
- Three final devices: backpack vacuum, Smart Sock vacuum, splitter (Q2091). Both vacuums available from the same moment (Q2100).
- Two backpack vacuums in a co-op game, whatever the player count; first come, put down to share (Q2101 "Two.", Q2132). They lie in the kitchen beside the Smart vacuum from a New Game (Q2136).
- Own tank, separate from the Hands: 16 Socks (placeholder, Q2131), grown by Big Bag (Q2125).
- Click picks one up into EMPTY Hands (it takes the whole Hands); E puts it on the back with the nozzle out, which takes the whole Hands; E again takes it off into the Hands; right click puts a carried one down (Q2129 "Carry it, then E wears it", Q2130 "With E to equip (click to carry), E to unequip, you have to have no socks in hand to carry, so it works."; the lead's reading: there is no worn state with free Hands). Nozzle out takes the whole Hands (Q2093).
- Worn: left click sucks every Sock in the cone (no filter), same reach and cone as the Smart nozzle, NO hose limit (Q2135); hold right click spits out where aimed (Q2096, Q2099, Q2111); NO pour (Q2099). Spit-out only, "It empties by spit-out only".
- Strong Suction and Wide Nozzle apply; Long Hose does not (Q2125, Q2135). A full backpack stops sucking.
- The wearer sees only the nozzle and its capacity gauge; teammates see the backpack on the wearer (Q2134). A worn Wardrobe backpack piece is hidden while the vacuum is worn (Q2094).
- Knocked down or leaving: it drops beside the wearer with its load (Q2133). Saved and in the join snapshot, worn state included.
- Model: variant b, the capsule tank (round tank, porthole, chrome elbow, dial gauge) (Q2171). Plain shapes until the model lands (tools/30, not built).

## A4. Splitter (tools/28 NOT STARTED; all rules decided)

**What it is.** Carriable device that sorts loose Socks into two heaps by filter. Designer: "this has the same filter mechanic, you can put any sock inside it"; "it has two outputs both with a filter"; "you can toggle the outputs and specify filters for them"; "you can dump the vacuum contents inside it, or put items in manually"; "it automatically (with a timer) processes the inputs and spits out two heaps behind it (filters the inputs to the outputs)".

**Rules that bind**
- Carriable like the Laundry bin, placed in the house, can have a set of upgrades ("Carriable - placed somewhere in the house, can have a set of upgrades.", Q2106). Stands on the pairing machine's old spot in the bathroom on the first floor from a New Game (Q2136).
- Picked up it keeps its Socks and pauses; it sorts again when set down (Q2141).
- Input: a click on the hopper puts in the active loose Sock, one per click; a Sock thrown into the hopper counts (Q2137). A vacuum's load gets in by the container's pour or by spit-out into the hopper (Q2109). Pairs are refused (Q2108).
- Two outputs, each with the nozzle's display; aim at an output and scroll (up Size, down Collection); Use toggles the output on/off (Q2104). Outputs are two loose piles on the floor behind it (Q2105).
- Every 0.5 s the Host sorts one Sock (placeholder, Q2138): the first output whose filter matches takes it (a Sock matching both goes to the first output, Q2107) and drops on that output's pile; a Sock matching neither drops back at the front (Q2103).
- An output's Collection list: Collections loose in the Mess plus those waiting in its hopper (Q2142). Until the Collection-filter Upgrade, the splitter starts with Size only (Q2110).
- An output pauses with a warning when about 40 Socks lie behind it, until some are taken (Q2140).
- Upgrades (placeholders, no prerequisites, in the pairing machine's old menu row, Q2110, Q2139): faster sorting 3 levels at 1, 1, 2 Drawers; bigger hopper 2 levels at 1, 1; Collection filter 1 level at 2; third output 1 level at 3.
- Numbers: 0.5 s per Sock, hopper 40 (placeholders, Q2138).
- Model: variant a, the tower with the paddle wheel (Q2172). Plain shapes until tools/30 models land.
- Saved and in the join snapshot: place, hopper load, each output's filter and on/off.

## A5. Pairing machine (SWITCHED OFF since 2026-11-19; tools/26 merged)

**What it was.** A hopper machine: load Socks, it runs and spits out Pairs. Code, tests and tuning kept behind one switch.
- Switched off: "Disable the pairing machine in the game right now." (designer 2026-11-19); behind one switch, code and tests kept (Q2102); Old Tree's pairing tip hidden (Q2127). Off means: none is placed at New Game, a save loads none, its four Upgrades (Big Hopper, Fast Run, Wide Funnel, Auto Pair) unlisted and unbuyable and the menu row closes, `tip_pairing` not spoken, zoo hides its buttons, nothing feeds a hopper. Switch: `pairing.enabled` false in data/tuning/pairing.json (checked on main, enabled false).
- Wording still naming it (left): Upgrade tooltips in data/upgrades.json; tree_tip_pairing_1..3 voiceover (tools/26 follow-up).

**Rules (kept, only if switched back on)**: pairs what can be paired (a Sock with its Mate inside), spits the rest loose; no chance, no failure (Q722). Held to carry; set down to run (Q720). Hopper 12 Socks, a Pair counts two (Q728); 8 s run (placeholder); full hopper or container blocks (Q738). Hands (own button): whole machine only picked up; one start button; click the hopper loads Socks (Q742). A made Pair comes out as ONE rolled-sock ball, one physics body, in the Pair's Design colours; clicking puts the whole Pair in the Hands; unmatched Socks come out loose (Q743, supersedes Q729 glow). Count lamps on the front; countdown ring. Vacuum spit into hopper: "near" is within 0.8 m with the rear outlet facing the hopper; when the hopper is running or full the vacuum stops spitting and keeps the rest (Q869, Q727). Placed in the bathroom, free once that floor's Stage is unlocked (designer 2026-11-06, Q1041). Sounds (tools/06, still ready-for-agent, priority later per Q1580 2026-11-11): events needed hopper drop, start click, running loop, count tick, Pair out, done bell, refusal; vacuum's moved to tools/11 (Q1137). Numbers (pairing.json): hopper 12, seconds 8.0, spit_interval 0.1, spit_speed 2.2, spit_up_deg 30, spit_spread_deg 15, roll_max 4.0, jiggle 0.006, feed_reach 0.8, feed_time 0.25, auto_idle 3.0 (placeholders except hopper/seconds as given by Q728).
- Open (tools/06, only if the machine returns): [later] Should the pairing machine's running loop change speed with the hopper's load?
- Open (tools/02, tools/05 follow-ups, never answered): loading rule (all or only active item), carrying into empty Hands only, no loading while running, spit order Pairs first, count shown as lamps, a leaving carrier's machine goes back, GLOSSARY entries.

## A6. Sock detector (built and merged 96b88a1f, 2026-11-13; in the game)

**What it is.** A handheld gadget that beeps towards the nearest loose Sock. Always works; early on so many Socks lie around that it hardly helps; pays off late (Q1825). Shared: ONE, lying in a placeholder spot from the New Game (the workshop workbench) (Q1822, Q1827). Name in the game: Sock detector (Q1856; "beeper" is the code's word only).
- Found in the house (Q1822). Picked up, dropped, thrown or handed to a Teammate like the Radio (tools/15 acceptance). Held like the vacuum nozzle: takes the Hands, drops held Socks and Pairs (Q1824).
- Target: the nearest loose Sock in the Mess on any floor; beeps faster when closer; its screen shows a distance band (1-3 bars far/mid/near) and an up or down arrow when the Sock is on another floor, nothing on the holder's floor (Q1823, Q1826).
- Model approved: the red push button and speaker slots are removed, the screen fills almost the whole face plate ("Could we remove the button and the thing below the screen and make the screen almost full size for the box?", Q1861); held pose bigger and closer so the screen reads at a glance without covering much of the view (Q1862); approved, merge (Q1863). Needed a proper model before merge (Q1857).
- Bug rule: holding it never pushes its carrier (collider must be stripped from carrier copies; same bug as the pairing machine and the Radio) (designer 2026-11-13, tools/17).
- Numbers (data/tuning/beeper.json, placeholders): near 3 m, far 10 m, close 0.5 m, beep_far 20 m, beep gap 1.6 s far to 0.12 s close, volume -6 dB, held pose in hold.json "beeper" pos (0.14,-0.125,-0.38) scale 0.8.
- Open: [later] exact New Game spot; placeholder numbers and beep sound for balance round/sound bench; a lying detector has no Mess collider, does not ride the Elevator and cannot go in the washing machine drum like the Radio.

## A7. Back-mounted devices (tools/16; PARKED)
- Idea sheet with five ideas (Vac-Pack, Catch Basket, Hamper Pack, Sweeper Tail, Pairing Pack) and stills in builds/review-back-devices/. The designer picked an idea sheet first (Q1828), relation to vacuum and Hampers decided after (Q1829), none to build yet, remind later (Q1852), and "back devices - park for now" (Q2060, 2026-11-19). The decided Backpack vacuum (A3) is the one back device that exists in plan.
- Open [blocking] (tools/16): Which idea to build, and the ten questions at the end of back-devices-ideas.md (one back slot or several; addition or replacement of standing machines; how got; slow walk or not; key for stash/pour since the wearer cannot click their own back; Catch Basket throw-at-back rules; Sweeper Tail steal rules; Hampers coming back first; numbers placeholders; look and first-person belly mark). Hampers are `enabled: false` (progression/78).

## A8. Machine prototype row (tools/18-23; test stands, NOT in the game; parked on branches except where noted)
- Designer's rules for machines (2026-11-19): grey-box as engine boxes with colour-coded ports (inputs one colour, outputs another, controls a third) (Q2020); all variants tried as zoo stands in one review build `builds/review-machines/` (Q2036); numbers marked placeholders in data/tuning, tuned by the designer after playing (Q2039); new machines may be fixed in a room, carried and set down, or worn or held, decided per machine (Q2018, Q2019); "New machines take over splitting a pile into groups" (Q2017).
- Sorter stands (tools/19): a sample Sock tells each output what to collect (Q2023); 3-4 groups plus one rest sack (Q2024); a Sock like the sample is one of the same Collection, Size too (Q2025); the Sorter is another iteration of the vacuum (Q2026), can be picked up (Q2027); three forms, three ways to key a sack (sample clip, cartridges, dial) (Q2029, Q2030); Size tried as switch, filter, grate (Q2031); rest sack; sacks can be taken and dumped on the ground (Q2032). Nozzle filter pre-pick: "The variant the designer likes is stand 5, the nozzle filter." (Q2065). tools/24 then picked what goes into the game and parked the rest (Q2112).
- Chute and clothesline (tools/20): house helpers "environment things in the house that could help" (Q2021); chute several openings, one exit, players can ride it (Q2028); graybox in zoo first then house, plain physics drop (Q2035); clothesline hang by hand, mates auto-pair on the line, 10 pegs (placeholder) (Q2033); Mate rack: "It's the same as clothesline." (Q2037).
- Launcher and Size grate (tools/21): Mate rack and Sock launcher to work out (Q2034); launcher fires sacks and Pairs aimed by hand, can be pre-set and then launches automatically (Q2038).
- tools/23 stand variants decided before tools/24 (stand 10 pour no spit Q2066; two filters in three modes Q2067; sample clip and switch on the nozzle Q2068; two-containers = two compartments dropped as two piles Q2072; each variant builds on the one before Q2073; added as stands 10-12 Q2074; unmatched Socks stay lying, no sample takes everything Q2075; nozzle holder cycles a filter with the wheel Q2077; empty filter ignored Q2078; matching both goes to A, empty filter's side stays empty Q2079; mode change leaves the load Q2080; no on/off button Q2081; shared capacity Q2082; mode switch on container Q2083; hand-mode window click goes Q2085). Only the pour-on-E, wheel and filter ideas carried into tools/24; compartments and the Sorter sacks were NOT chosen ("no comparments").
- Graybox kit (tools/18, merged 35409eb7): game/debug/graybox/; platform 34 x 34 m in the zoo (placeholders). Stands in the zoo only.
- Open blocking (tools/19, 21, 23), all unresolved and mostly moot because those stands are parked: thrown sacks; full/unclipped sack behaviour; dial and cartridge meaning; should launched Socks knock players; stand 12 wheel mapping; pour landing side. Full text kept in the tickets; [later] items about layout, models, numbers also unanswered. Q2022 (stair slide, fans and vents, tub or sink as a basin, marked sorting spots) was never answered.

## A9. Tools ticket status snapshot
tools/24 in-progress (spec); tools/25 ready-for-agent in the vault but built and unmerged per the lead; tools/26 done and merged; tools/27, 28, 29, 30 ready-for-agent, not started (models: variants picked Q2171-Q2174).

# PART B. THE CAT (docs/llm/cat)

## B1. The Cat: look, controls, behaviour

**What it is.** A black cat living in the house, a side job (designer 2026-11-05) with no gameplay role beyond petting, fetching Socks and being a Secret hook (see Part E). Host-authoritative; guests see the same.

**Rules that bind**
- Controls: E pets it (purr, little hearts); a left click grabs it into the Hands; held it wriggles and jumps down after a few seconds (Q1009, Q1010). A Throw throws it; it always lands on its four paws. Throw needs Throw bought, like the Radio (tools/cat/01 follow-up, built behaviour).
- Ways: roams the unlocked floors (rooms and stairs, all unlocked floors, never locked ones, Q1080), naps in spots (beds, sofa, floor patches under windows as "sunny sills"), meows now and then, purrs when petted, hisses when thrown (Q1010).
- New Game: the Cat sits on the ground-floor couch and stays until the ground floor's Stage is unlocked, then roams as before ("Starts sitting on the couch on the ground floor; you find it once you unlock the Stage.", designer 2026-11-06, cat/02).
- It swats loose Socks and Pairs it walks past, rarely (Q1081, Q1082): knocks 0.5-1 m, never from Cabinets or Hands; soft sound; every 60-120 s placeholder (cat/03).
- Never leaves the house floors: never through a shut or locked Door, never onto a locked floor, never into the Elevator shaft by walking (cat/08).
- Navigation (Q1901): a navmesh baked from the house at run time plus cat-like steering: round furniture and Heaps, smooth curved paths, eases in and out, turns before it sets off. It walks through players with no avoidance (Q1902); small Socks are walked over. Head turns toward a nearby player or moving Sock, not while napping (Q1903). Walks under furniture it fits under (navmesh body height 0.3 m).
- Look: stylised, cuter and more cartoon (rounder chubbier body, bigger head, shorter legs); sitting tail wraps round the paws; curled cat tucks paws in (Q1011). Eyes: shaped, clear pupils, bright catchlight; awake it looks content or curious, never sad: "The heavy lids looked sad" (designer 2026-11-06), so back to the step-2 eyes with more polygons; eyes_closed squashes the eyes to a sleepy line for naps; slightly glossy black with a soft rim. Triangle budget: creature class 3,000 (model about 2,860).
- Animations are real Blender animations in cat.glb played by AnimationPlayer/AnimationTree, not JSON keyframes (designer 2026-11-07 "for the animated poses we shouldn't use jsons (cat)", Q1168, Q1173): stand, sit, curl, fall, held, walk, run, swat, dizzy; 0.4 s cross-fades.
- Cat hiss: a real cat hiss, short and spitty (Q1126); Dan Knoflicek's Cat 8 clip (CC-BY) is the pick for `cat_hiss` (Q1133); designer judges on the sound bench (unaudited).
- Door sounds: the litterbox flap has its own cue kind `litter_flap` (shares the cupboard pool, -6 dB placeholder, Q2012: real pick on the sound bench); no openable kind may fall back silently to the room Door sound (a test fails on an unmapped kind) (cat/15; the designer reported "The door sounds are now weird... What changed? Track this.", 2026-11-18).

**Numbers** (data/tuning/cat.json, all placeholders unless noted): swat_min/max 60-120 s, swat_reach 0.55 m, knock 0.5-1 m; accel 1.2, run_accel 4.0, decel 1.5, turn_rate 150 deg/s, head_radius 2.5 m, head_angle 100 deg, head_turn 200 deg/s, head_max 70 deg; park_seconds 90 (Q2006, designer kept it at 90 s).

**Open (cat/01, 08)**: [later] held cat drawn in the world not HeldView; sunny sills are floor patches; a pet stops a walk at once (ease to a stop?); a navmesh bake may hitch (5-20 ms a room, loft about 70 ms); carried things lying about are not in the navmesh; calico/coat colour numbers (below); swat is baked at swat_seconds 1.0, swat_contact 0.45 (new contact means re-baking); cross-fades are linear 0.4 s (code's was ease-out).

## B2. Washed Cat coat cycle
- When the Cat comes out of the washing machine drum it wears the next coat: black, grey, ginger, white, calico, then black again (Q1127). It lasts until the next wash and is saved (Q1128). No Secret: just for fun (Q1129). The drum's blob takes the Cat's coat colour; calico's blob is white (Q1142). Whiskers light on black and grey, dark grey on white, ginger and calico (Q1143). An old save starts the Cat black: an explicit exception to "no save compat" (Q1144).
- Open [later]: exact coat colours (CatView.COATS, in warm basement light grey reads brownish), calico patch size/share, rim only on dark coats: placeholders.

## B3. Petted Cat brings Socks (fetch)
- After a pet, a chance sends the Cat fetching; then a cooldown (Q1830). It fetches two loose Socks of one Design from the Mess (nearest pair to the Cat, placeholder) and brings them as a ready Pair that counts exactly like a made Pair: Drawers, Coins, Stage (Q1831). It brings it to the player who petted it (solo: always you) (Q1832), drops it at their feet with a meow; if unreachable (shut Door, another floor) it drops it at the closest spot it can reach and meows (Q1833).
- Numbers: fetch_chance 0.6 and fetch_cooldown 45 s (decided Q1946, were 0.3 / 120 s). "Only when petted; no unasked fetching." (Q1947).
- Open [later]: which two Socks (nearest pair placeholder); look and sound (Sock in mouth drawn, meow on delivery, a tell before it goes); interaction with Cat Secrets, Sock Sense, swat; both Socks vanish together at the second Sock (fix: a take at each); a leaving petter: she sets the Pair down where she stands; a walking-off petter: she follows up to 6 re-aims.

## B4. Lost Cat watchdog (bug fix, decided)
- "Lost" meant players couldn't find the Cat in the house (Q1928). It was a bug, not a missing feature: find it automatically with a check or test that catches the Cat ending up somewhere it shouldn't be; the Cat already meows now and then (Q1932). `cat.park_seconds` stays 90 s (Q2006). A detector + soak test + a watchdog that puts a parked or faulted Cat back on the nearest walkable floor spot. The loft was a dead end once (cat/09, fixed: the Cat routes between every pair of floors both ways).
- Open [later]: Cat carried into the Grotto is put in the nearest house room after park_seconds (alternatives: refuse the drop, let it roam the Grotto, bring it up sooner); a Cat shut by Doors pads about the room; some nap spots are slivers of bunk rails.
- Open [ready-for-agent] (cat/16): the stress case `cat:lost_soak_long` fails at seed 8 (off the stairs' steps at stairs_ground after a pet, 1638 s); cause unknown. [later] Should the long soak run regularly (about 9 min, merge run skips stress cases)?

## B5. Litterbox (cat/11, 14; merged; ticket status ready-for-human, Q1993 approved step 2)
- In the bathroom, on the floor beside the toilet (Q1942); the spot is left of the toilet against the back wall (7.62, 2.91, yaw 180) (Q1993). Socks lie in it; the Cat visits it; the Cat sometimes hides a loose Sock in it (Q1943). About 3 Socks start in it at random like other hiding places (1 to 5 per seed built, Q1949). The Cat visits about every 4 minutes (walk there, scratch, leave); on about 1 in 3 visits she first carries a nearby loose Sock (within 5 m) and drops it in (Q1950; placeholders, tuned after play, Q1993).
- Model: a covered box with a flap door, the Cat walks in through the flap (Q1951). Simpler design (Q1980). Players reach the Socks through the flap only; the hood does not lift (Q1981). Keep the simpler model but bring back the paw print on the flap and the carry handle on top (Q1985); the flap swings in 85 degrees up under the roof so the doorway stays clear (Q1986); approved with the carry handle in the tray's dark sage (Q1990).
- After a visit she always shuts the flap behind her, whoever opened it (Q2009). The scratch reusing the swat paw animation and sound is fine for now (Q2008). The Sock she carries shows its real Design look, reusing the Socks' LODs (Q2011); "carried sock ok" across her jaws (Q2059).
- Numbers: visit every 240 +- 45 s, litter_hide_chance 0.33, scratch 6 s (cat.litter_seconds) (placeholders).
- Open [later]: the flap's own sound pick on the sound bench; inside the box she can't be petted or picked up.

## B6. Cat naps in the Elevator (cat/13, 14; merged)
- The car is a nap spot at the same weight as the others (Q1982). While she sleeps in it players can still call it and it travels with her; calling the car from another floor takes her with it and she wakes on that floor (Q1983). No player can board while she is in it; the refusal keeps the wording "Elevator full" (Q2003). She leaves after a normal nap; any interaction (pet, call) wakes her; she can be picked up out of the car (Q1984). A shut hatch: she opens it after some nap time and goes out, but not while riding asleep (Q2004; cat.car_shut_seconds 20 s placeholder). A Cat dropped or thrown into the car lands inside (Q2005). The hop in and out reuses her jump pose and sound (Q2007).
- Open [later]: hop pose also for beds/sofa? a drop into a rider's car is allowed; "Swat" as a way to wake her does not exist (nobody swats the Cat).



# PART C. THE DRUM FINALE (docs/llm/dungeon; built and merged 0fa59e84, 2026-11-13; `drum.on` true in data/tuning/drum.json)

**What it is.** The fifth and last floor is the inside of the washing machine's drum (ADR-0012), still the Lost Socks Collection, "a short finale and not a new mechanic". It replaces the Lost Sock Grotto as the last Stage (Q1873; earlier Q1442, Q1445). Designer note 2026-11-13: "the final level is the Lost Socks collection inside the washing machine's drum: a static drum, play only in its lower part, Pairs handed out through a hole, the washer comments, spat out at the end, then the laundry bins and the end screen". Run order: attic Stage done, its Part fitted, cutscene_5, the pull, 30 Pairs handed out, softener appears, spit-out, the laundry bins washed (the happy wash), the end screen.

**Rules that bind (built)**
- The pull: right after cutscene_5 EVERY player is pulled in at once, wherever they stand, using the suck-in cutscene, polished; skippable as before (Q1874, Q1889 "We had something already in the drum branch, that can be polished and reused."). Held things are dropped where the player stood: "Dropped. But they shouldn't have socks, pairs, ... those were claned up!." (Q1893); no Sock or Pair should be held by then; a Gift, the vacuum nozzle or the Radio may be.
- Only the Sock detector is brought inside: the one shared detector is moved into the drum by the landing spot; at the spit-out it comes out with whoever holds it or lands in the laundry; only one exists in the world; no other house tool comes in (Q1875, Q1891).
- The drum: large, about 14 m radius (placeholder, Q1877); lying on its side; STATIC (no wall-walking, ordinary gravity, normal Player); players walk only the lower band of the curved floor; walls too steep to climb, invisible limits; low baffle ridges in the band; greybox+ now, art in a later ticket (Q1899). "Remove the shrine. It appears by the hatch." (Q1897): no shrine.
- Shallow water to the ankles in the lowest part: splashes, ripples, Socks floating or lying under it in plain view; NORMAL movement (no slower walk or floaty jumps) (Q1876; supersedes Q1630 under-water movement). Dim but readable light: pale beams through the holes and door glass, the laundry seen outside, caustics on steel; no lantern needed (Q1896). Water caustics only on wet steel; waves clipped to where there is water (review fix).
- The Socks: 30 Pairs of Lost Socks Designs, fixed for any player count (Q1884), "Normal Lost Socks Designs" looking like Socks on earlier floors (Q1895), spread over the band, some hidden: in or floating on the water, behind or under baffle ridges, in nooks by the door and back hub (Q1887).
- The door hatch (Q1878, Q1879, Q1888): at the foot of the door glass, reached from a small ledge. "the hand out box should work like a cabinet logically, not a separate thing (in code!)": the Drum hatch IS a Cabinet in code (the drum floor's Lost Socks Cabinet, one Drawer). Only Pairs (and at the end the softener) go in, by the shelving click, E, right-click drop of the active Pair or a thrown Pair; they vanish outward. A single Sock or other item is refused with the usual Refusal ("Pair socks first" / "Only Pairs go out"). Prompt is the Cabinet Drawer's [E] "Hand out"; a click works too (placeholder wording).
- Hatch look (dungeon/06): "Make it look like a hole instead, transparent, the sock falls out on the ground through the hole." (designer 2026-11-13). A round hole in the big door glass at its foot, about player height across (~1.8 m, Q1920, placeholder), clean transparent opening (no glass, no flap), thin chrome ring with a few bolts like the door rim (Q1922, Q1923); warm laundry light shines in with a soft glow patch on the drum floor (Q1917); supersedes Q1916 porthole, Q1918 flap, Q1921 frosted glass. Only inside; the outside door stays as it is (Q1919). Each handed-out Pair falls through the hole onto the laundry room floor outside as seen through the glass, a growing pile shows progress (Q1924); only Pairs pass; players and loose Socks are stopped by an invisible barrier (Q1925).
- The pile lives only in the view behind the glass (a separate small world); the real laundry floor never gets a pile after the spit-out: designer accepted "Enough as is ... nothing to clean up. Closed." (Q1958, 2026-11-18). The designer's earlier wish (2026-11-13) was that handed-out Socks should not stay on the laundry floor ("Maybe they can just really disappear after a while."). The Q1958 answer closes dungeon/07; its three [blocking] follow-ups (when/how/seen) are moot.
- Counting: a Pair handed out counts in the player's usual stats (Pairs made and shelved, end screen) but NO Coins and NO Drawers ("Counts the typical stats for the player. No currency, no drawers...", Q1880). The Stage bar with the Lost Socks icon counts Pairs handed out n/30 (Q1900).
- Softener: after the 30th Pair it appears glowing by the hatch (as a Part does); a player picks it up with empty Hands and hands it out through the hatch (Q1894, Q1897); that triggers the spit-out. The machine is fixed by the softener's Fix.
- Spit-out: the drum spins (each player's view tumbles, reusing the knockdown wash's tumble view), the door bursts open and everyone flies out head first into the laundry, briefly knocked down; a relieved placeholder line plays (Q1890). Then the laundry bins are washed and the end screen shows (designer 2026-11-13).
- The washer comments from all around with the echo (Q1885, Q1886): triggers a Pair handed out, a refusal, idle (45 s); every refusal and the first Pair always comment; other Pairs about 1 in 3 with a 15 s cooldown (placeholders); the house's 2-minute cooldown does not apply inside. Existing stage_1..5 lines are placeholders; the designer records drum lines later and they drop in by file name. "Oh yeah, purrs like a kitten." (stage_3_voice_A) is spoken only at Stage 3 and once at the drum's spit-out, NOT for handed-out Pairs nor the last Pair (Q1926).
- Save/co-op: quitting inside and loading resumes in the drum with count, Socks and detector; a Guest joining mid-drum spawns inside; host-authoritative (Q1892).
- Review fixes by designer (2026-11-13): the click hand-out must work; the intro pull must not render players twice (own cut body and full body); disable the washing-machine sound while inside ("it's horrible", now `drum.sound.machine_sound_inside` false); lower the reverb and spaciness (room_size 0.85 -> 0.65, wet 0.4 -> 0.25).
- Rewards: with the drum a run pays 33 Drawers (the hatch pays none, Q1880) and the House upgrades keep their 37; the 0.9 rule (Q1398, Q1405) no longer holds with the drum on (Q1927).
- Review: held for review; built into the Run (Q1898).

**Numbers**: 30 Pairs (decided Q1884); radius ~14 m (placeholder Q1877); hole 1.8 m, ring 0.07, 6 bolts; fall 0.9 s; pile 7 per layer, cap 40 balls; spit seconds 2.5 and 0.35 s stagger; washer comment 1 in 3, cooldown 15 s, idle 45 s (placeholders in data/tuning/drum.json).

**Open (dungeon/04, 05, 06)**: [later] the drum's name in game and GLOSSARY (placeholder "the Drum"); art in Blender (separate ticket); the drum's washer lines (designer records; cutscene_5 still mentions "dung... eon, uh... cave system"); hatch height, ledge, band width judged in play; water look/sound (no water footsteps or splash sounds); the last Pair has no washer comment now (a line when lines are recorded); hatch wording "Hand out"/"Only Pairs go out" placeholders; suck-in polish beats `drum.intro`; Socks "floating" have no buoyancy; the hatch never completes the Lost Socks Collection; items left in the drum after spit-out stay there; the Pair grows from drum scale to house scale as it falls (designer may want another way); the hole's look in the dim drum (needs more to stand out?); no sound of a Pair landing on the pile outside.

## C2. Drum shuffle spin (dungeon/05; NOT BUILT, needs-info)
- "Lets keep this tracked, but don't do it now." (Q1881). Intended: now and then the washer spins and the Socks change places; players tumble and are knocked down, held items stay held (Q1882); every loose Sock and lying Pair goes to a new random spot on the walkable floor; the detector moves if lying (Q1883).
- Open [blocking]: When it spins: a timer with a warning, reacting to the players, both, or at progress steps (Q1881 left open).

## C3. Switched off / dropped (Grotto and dungeon prototypes)
- Lost Sock Grotto (Cellar hatch, ladder, mineshaft, shrine, lantern): "switched off behind one switch, so it can come back, as the Dirty Socks were" (Q1873); never opens; code and layout kept (`DrumRules.test_grotto` for tests). Earlier answer that "the mineshaft, hatch, ladder and shrine retire" (Q1442) is consistent. The cat never routes into the Grotto; a Cat carried there is put in a house room by the watchdog.
- dungeon/01 "Lost Socks dungeon" (wontfix 2026-11-18, Q1953, superseded by the drum): decided then but NOT in the game: players enter through the broken washing machine's door as a portal (Q1443); a UV lantern reveals a hidden mark (glowing symbol + stitched pattern) per Sock to tell identical gray/black/white/navy/beige generic Socks apart (Q1444, Q1446-Q1448); one UV lantern per player, lights about 3 m, no aiming (Q1447, Q1460); drum calm, no hazards (Q1451); wall-walking gravity, "bigger on the inside", hub, gap between drum and tub (Q1454); dim, foam, bubbles, big metal hall echo 3-4 s (Q1452, Q1456); treasure landmarks with no rules (Q1457); outside view spins visually only (Q1458); 50 Pairs growing to 100-200 (Q1459); prototype standalone, one player first (Q1461). Reused in the drum: the suck-in, door view and echo, the washer voice from all around, the Lost Socks Cabinet idea.
- dungeon/03 water drum (wontfix, Q1953): wall-walking in a drum full of water, blue-green murk, slower walk/higher floaty jumps/drifting throws (Q1630), exit rule every Pair shelved (Q1631), 20 Pairs (Q1632), cutscene sucks players in from the real laundry (Q1633), reuse drum parts but drop gap, landmarks, UV lanterns (Q1634), outside spins 1 turn per 8 s (Q1635), spat out into the laundry at the end (Q1636). Wall-walking, deep water and floaty moves were dropped by dungeon/04 (shallow water, normal movement, static drum).
- dungeon/02 mechanics and layout trials (needs-info, never run): Open questions carried over, unanswered: "Pairing (Q1478, unanswered): as in the house (mates fuse at the second pick, only Pairs shelve), or no fusing and the Cabinet checks the marks when shelved?" ; "The UV lantern: no Hands place (as now), a Hands item like the Grotto's lantern, or one for the team?" ; "Does shelving reveal a generic Pair's true Lost Socks Design?" ; "Does a Pair's sock ball show its UV mark?" ; "Which other mechanics and layouts to try (to ask)." (All moot with the drum finale.)

# PART D. THE ROGUE / TALKING WASHING MACHINE (docs/llm/rogue-machine)

**What it is.** A cutscene (everyone's view cuts to the basement washing machine) at New Game and each Part fitted; the machine is voiced, entitled, angry to calming. The designer's original request (2026-11-03): "When unlocking a new floor an animation should play: the washing machine starts being rogue and starts washing and then spits out socks, then you respawn with floors again. This should be an intro animation as well. But it should be slowly tweaked and the washing machine should be more aggressive between the levels."

**Rules that bind (built)**
- Cutscene frame (rogue/01): shared cinematic camera synced from the Host; every player loses control, input returns at the respawn (Q745, Q746). Changes no gameplay (Q747). Plays only in real games: at New Game and at floor unlocks of a staged game; not in the Zoo or debug starts (Q752). The Host can skip it for everyone, guests just watch (Q751); skip key Space with the usual keycap prompt "[Space] Skip" (Q862); every cutscene skip uses the styled keycap button (Q1395). The sequence ends every knockdown, drag and wash; everyone respawns standing at the laundry (Q759, Q745). Open menus close when it starts; a guest who joins mid-cutscene spawns after it at the laundry (Q864). The loading screen just says "Loading" (Q865). Fade: smooth fade out into the laundry respawn, not a hard cut (Q817).
- Voiced cutscenes (rogue/04): files `cutscene_1..5` one per stage, cutscene_1 angriest; `cutscene_6` after the wash; `stage_N_voice_A/B/C` occasional comments. The designer re-recorded all 20 lines (2026-11-09); the new recordings replace the old in `audio/voiceover/`. cutscene_1 plays in the New Game intro; cutscene_2-5 play each time a floor's Part is fitted (basement, ground, first, attic) (Q1371). cutscene_6 plays after the wash then the fade to the completion screen; NOTHING plays when the last item goes in (Q1413). The old rogue choreography (shake, hop, lunge, spat Socks, alarm, door slam, red pulse) was REMOVED; the voiced cutscenes alone carry it (Q1470; Q1471-Q1473 kept as built: camera cuts between wide shot and close-up at every line, wide shot stays where it is; the knockdown wash's door swings 40 degrees; stage_2_voice_A subtitle stays "Don't have enough money for a plumber?").
- Cutscene frame: players freeze, camera cuts to a framed shot, skippable (Q1375). "No Socks may be in a cutscene's shot" (Q1425: they are already collected; Socks near the machine are hidden while it plays); player avatars hidden during cutscenes (Q1426). The camera cuts are fine; when silent the machine keeps its basic pose (neutral brows, no mood pose); only while it speaks does it show the brows' acting and move its mouth (Q1436). The broken machine's sparks, smoke and buzz follow the cutscene's story and mood (Q1427).
- Comments (Q1373, Q1378, Q1379, Q1380, Q1384, Q1385): triggers staring at the machine (a 4 s stare, with a chance, not every time), hitting it with a thrown Sock or item, progress (a Pair into a Drawer, a Cabinet filling) and long idle. At most one comment every 2 minutes, never during a cutscene, A/B/C without repeating the last. The comment set follows the current Stage: the basement uses stage_1; stage_5 plays while the Grotto is open (now the drum, dungeon section). Each line is tagged with its triggers (stare, hit, progress, idle) in data/voiceover/; untagged lines fit any. Co-op: everyone hears it; comments are positional 3D sound from the machine with subtitles for players within earshot; cutscenes play for everyone.
- Volume and subtitles (rogue/06): washer comments +6 dB, Old Tree lines +3 dB (clipping) (Q1586, Q1598); positional falloff stays. A voice's subtitle shows only while the player can hear it: within earshot and on the same floor, checked every frame, appears and disappears as they walk (Q1587); cutscenes keep subtitles for everyone. Subtitles from checked transcripts (local Whisper, Q1370); a setting turns them off (Q1376). Subtitle fixes (Q1382): cutscene_3 "Thanks, still though"; cutscene_5 "dung... eon, uh... cave system"; stage_5_A "lost socks"; cutscene_6 keeps "two year warranty time window".
- Face and acting: no eye; the door is its mouth with a side hinge swinging sideways like a real washer door (not a jaw) (Q1392); thick dark chunky rounded 3D brows over the door: an angry V, calming flat, an entitled one-raised smirk (Q1374); brows the main acting channel and "much more dynamic": raise, furrow, tilt one at a time, flick on emphasis, big shapes on angry lines, settle on pauses (Q1410). While talking the body bounces and leans, the drum glow shifts with mood: red angry, warm/orange calm (Q1381), purple when entitled (Q1393); it wiggles (bounce, lean, rumble) ONLY while talking and is completely still in pauses (Q1412). The machine is broken: nothing inside washes or tumbles in cutscenes: laundry lies still, drum doesn't spin; the repair state shows in the drum light: cutscene_1 dim and flickering, steadier and warmer with each Part, healthy by the end; only after the wash may the drum turn (Q1411). The drum light is the lit drum: dark perforated drum lit from inside, laundry tumbling in silhouette (Q1400); drum's three paddles gone, clearer porthole glass (Q1401). Door lip sync baked from each wav's loudness (Q1372). Moods per cutscene (Q1383): 1 angry; 2 grudging and angry; 3 surprised, turning calm; 4 pleased and excited; 5 smug, then urgent; 6 relieved, then entitled, smug and warm.
- Review: animatics approved (Q1417); storyboards per cutscene in builds/review-washer/ (Q1377).
- Socks on top: Socks and items lying on top of the machine move with it as it moves (Q867; rogue/03 built; moot after Q1470 removed most motion but the kinematic body stays).
- Sleepy face at New Game: a drowsy half-open eye that wakes up grumpy (Q863; the eye was later removed by the face remodel: the door is the mouth, brows carry mood).

**Numbers (placeholders in data/tuning)**: intro about 5 s growing to about 10 s (Q750; now only `rogue.seconds` and camera keys remain); comment cooldown 2 min; voice.comment_db / old_tree.voice_db +6 dB (tree +3 dB per Q1598); level_band 2.0 m; broken.cutscene_scale 1, 0.8, 0.6, 0.4, 0.2, 0 for cutscene_1..6.

**Decided against / dropped**: rogue/02 "stronger sequence" (wontfix 2026-11-11, "the old choreography was removed (Q1470, ef7c0d1e) and the voiced cutscenes replace it"): bigger squash-and-stretch motion, stomping, foam/splash/steam effects, grin and glare face acting, a dozen tumbling Socks in the drum (Q820, Q822), spit burst (Q817 fade kept); iris glow (Q868) moot. The escalation list in the spec (Q749: spin faster, shake, hop, lunge, door slam, flicker, redder laundry, eyes/brows angrier) is no longer in the game except the brows and drum-light repair state. Sounds Q760 (rumble, slam, alarm) removed with the choreography.

**Open (rogue/04, 06)**: [later] clipping: tree files peak near full scale (26 of 29 above -6 dBFS); designer: normalise/trim the tree files or lower `old_tree.voice_db`? [later] the rogue sequence's wide shot looks through the decorative sock heap and a standing player; the designer may want the wide shot moved; [later] all "voice" tuning numbers are placeholders (glow strengths, repair_dim, flicker, wash_spin, after_spin, close_shot, close_up, rumble_db); [later] the "cutscene" Command stays though nothing plays a line alone since 6_part_1 went.

# PART E. SECRETS (docs/llm/secrets; built, `secrets.on` true in data/tuning/secrets.json)

**What it is.** Hidden things in the house that give Wardrobe items and make a second Run worth playing. One pluggable Secrets subsystem with one on/off switch; with it off the game plays exactly as without it (Q1018).

**Rules that bind**
- Kinds: cat Secrets, washing-machine Secrets (once fixed), co-op Secrets needing two players (Q1014). NO hidden Socks ("would be cool but could confuse the main game loop"). Reward: Wardrobe items plus replayability (Q1015).
- No counter or list anywhere (Q1016); only subtle visual tells, no text (Q1017). Each Run turns on a shuffled subset; unlocked items stay on the profile across Runs (Q1018). Finding one plays a special gift reveal (Q1019): a gold-ribbon Gift box with its own rattle shakes over the finder, then the item spins in a spotlight on the finder's Avatar for everyone; co-op Secrets give it to both (Q1048). The own-machine reveal sits at the Gift reveal's view level (same height and distance in front of the camera) and goes down with the camera when crouching, like held Gifts (designer 2026-11-06).
- 5 Secrets on per Run (co-op ones only with 2+ players; solo gets 4), shuffled from the Run seed (Q1048). Found once a Run, host-decided.
- Eight Secrets (names, tells and pieces):
  - Cat on the Piano: cat lands on the piano keys; tail flick, faint note; Cat-ear Headband (Q1045).
  - Radio Dance: cat sits about 2 m from the playing Radio for 10 s; head bob; Boombox Hat (Q1045).
  - Clock Stare: cat stays by the clock 15 s; its tail flicks once per clock tick (each game-clock second) (Q1071, replaces "eyes follow the pendulum"); Pocket-watch Chain (Q1045).
  - Fur Fetch: cat thrown into the empty laundry basket lands on its paws; basket twitches; Whisker Mask (Q1045). (Note: tools/secrets/01 says "7 of 8 Secrets trigger"; which one did not is not stated in the ticket. Unchecked.)
  - Rubber Duck Load (washer, after the fix): a Gift box dropped in the drum for a load; tiny squeak from the drum; Rubber Duck Hat (Q1046). Items may go into the drum "Players can go in drums, why couldn't items?" (Q1070). Only a Gift box finds it.
  - Elevator Duet (co-op): both ride standing still the whole ride; car lamp flickers gold; Bellhop Cap (Q1047).
  - Cat Cradle (co-op): one holds the cat while the other pets it; purr ripple; Purring Collar (Q1047). With Secrets on, a teammate may pet a held cat in any Run.
  - Piano Four Hands (co-op): two players play the piano at once (a key from each within 1 s); lid glints; Concert Tie (Q1047).
- Who finds a cat Secret nobody did on purpose (Radio Dance, Clock Stare): everyone within a radius of the cat gets the piece (4 m, placeholder) (Q1072). A repeat find (already owned) gives nothing at all, not even the reveal (Q1073).
- The washing machine's drum takes the Cat and the Radio too (not Socks, Pairs, the Guide card or the lantern) (Q1106): dropped by the door they spin one cycle. The Radio keeps playing, muffled, while it spins. The Cat spins a gentle cycle, comes out dizzy and runs off (secrets/02). One rule for the Gift box, the Radio and the Cat: they go into the drum only when aimed at the washer while standing by its door; otherwise a right click just puts them down (Q1125). One load at a time.
- Models: model all 8 pieces and the Elevator car's lamp (Q1107); go after first line-up (Q1121); keep the long Concert Tie (Q1122); Purring Collar red with gold studs and bell (Q1123); Cat-ear Headband's ears about 30% taller (Q1124). The lamp (caged brass bulb under the car roof) has no collider of its own; it rides the car (secrets/04).
- Numbers (data/tuning/secrets.json, placeholders): finder_reach 4 m, together 1 s, tell_every, reveal timings; secret_rattle and secret_squeak sound picks on the bench; wash.seconds 3, wash.cat_seconds 4, wash.cat_spin 0.45, wash.radio_db -4 dB, cat.dizzy_seconds 2.5.

**Open**: [blocking] (secrets/05, Q1837 "Polish later, ticket now"): What to polish (asked in Q1837): discovery (hints, a list), the moment of finding, Secrets that don't trigger, the pieces' models. [later] (secrets/01, 02) Elevator Duet counts any whole ride of two; slots of the pieces are the agent's reading of names (Whisker Mask uses the hat slot, the face has no slot); the Cat's dizzy walk and muffled Radio placeholders; a guest who joins mid-load sees the Radio already out; Radio waits hidden at the door.

# PART F. HUDRY GAMES STUDIO INTRO (docs/llm/intro; built, merged be76f0c9)

**What it is.** A short animated studio intro for Hudry Games, played before the title screen at every launch: turkeys run across the screen gobbling, the letters of HUDRY drop into place behind them, GAMES slams down. A self-contained folder `studio_intro/` that later games can copy; the player depends on nothing of It Socks and emits `finished`; the game decides what comes next.

**Rules that bind (current state after intro/02)**
- Plays at every launch before the title screen; any key or click skips it (Q1278). Not for --host/--join; the runner and shot tool never meet it. Hard cut from black to the title screen is fine (Q1313).
- Two outputs: an animated 3D glb played by a small player scene (the AnimationPlayer carries the sound on the same timeline), and a rendered video 1920x1080 at 30 fps for trailers (Q1279, Q1295); the designer renders the final video from studio_intro/blender/hudry_intro.blend (Q1309). Video has no audio (Q1306).
- Look: toy-like 3D, soft chunky low-poly (Q1280); background black (Q1288); camera fixed, straight on and slightly low (Q1294); letters white with thinner strokes and shallower extrusion, with an outline whose width scales with letter size (Q1296, Q1301); HUDRY has a bronze #9A6232 outline, GAMES none (Q1300); NO underline under GAMES (Q1299). The turkey is a chunky cartoon: round body, big fanned tail, red wattle, stubby legs (Q1293), tail fan faces the camera even running side-on (Q1297), about as tall as HUDRY's letters (Q1298), runs on GAMES' baseline (Q1302).
- THREE turkeys in a chase on the same line: brown leads (Q1304), silver-white second (same model, materials swapped, face still readable) (Q1303, Q1305), a purple turkey runs last (designer 2026-11-13; plumage #5B3A8C).
- Letters: each HUDRY letter falls from above and lands just as the PURPLE (last) turkey passes it, so the word builds up behind the whole flock (Q1908; replaces Q1307 and Q1282's leader). Landing: a soft wooden thud, a small toy-like dust puff and a tiny squash on impact, still no bounce (Q1909; replaces Q1286 "no thuds" and part of Q1291 "hard stop"). NO whoosh while letters fall (designer 2026-11-13, overrides Q1909 whoosh and Q1912).
- GAMES: starts huge right in front of the camera and drops away from the viewer onto its place under HUDRY, as if slammed onto a table; heavier thud, a dust ring and a small camera shake (Q1910; replaces the fade-in Q1283/Q1284).
- Sound: the gobble is the designer's own recording `studio_intro/hudry_intro.wav` (Q1306, Q1308, Q1310), one recording, plays ONCE, not per turkey (Q1311), trimmed with tail faded (Q1312). Picks: letter thud thud_a_breviceps_449955 (Q1913), GAMES slam slam_a_eggshellprodutions_718357 (Q1914). The intro stays self-contained (no game sound bank); CC0 candidates credited in the folder.
- Length: about 5 s from black to hand-over (Q1911; was about 4 s, Q1285). "The preview's look and timing are good; merge it" (Q1915).

**Open [later] (intro/01, 02)**: the video's container/codec for trailers; sounds' relative levels; in the Blender video the huge GAMES near the lens reads dark grey (area lights aim at the stage); GAMES has no squash of its own on the slam.

# PART G. QUESTIONS FOLDER (docs/llm/questions; early decision tickets and the live list)

- Core loop (questions/01, done 2026-10-28): one action: pick up a Sock, find its mate, make a Pair in the Hands (no Pairing spot), shelve it. The player sees the Mess shrink and the Drawers fill; earns Coins, spends them at the Upgrade station. "Always active, no helpers and no offline progress. The session ends when the Mess is gone." (no Q number; first grilling 2026-10-28; ADR-0001/0002).
- Numbers and curves (questions/02): Q164 "kept open for a dedicated balance round after playtests"; all numbers are placeholders in data/tuning (designer approved building and trying rather than simulating); length target moved to balance round (Q477); closed into questions/06 (Q838).
- Rare found later (questions/03, Q839, 2026-11-04): rarer Designs prefer hiding spots (inside openables, under furniture, high tops) and lie further from their Mate. It is an effect of placement, not a rule told to the player; weights tuned in the balance round. Each game has its own seed, so Socks lie in different places every game. `mess.hiding_weight` common 1, uncommon 1.5, rare 2.5 (measured hidden share 0.55-0.74).
- MVP collections (questions/04, wontfix): Q163 superseded by the eight Collections of the flat batch.
- Sound source (questions/05): cues were generated in code at first (synthesised tones, no files, no licences), real recorded sounds can replace them later (2026-10-28).
- Balance and feel round (questions/06, ready-for-human): "Run the balance round after the next full playtest." (Q1111, 2026-11-06); the designer plays it after the physics round (Q840, 2026-11-04). Contains a long list of placeholder values to tune in playtest (economy, Hands and Throw feel, graphics, UI/sound, limits, multiplayer). Values named there with figures: level shares 0.25 each (Q442 keep, judge in playtest); active budget 512 with 16 promotions/8 demotions a tick (Q793, Q794); first playable length target 20-30 minutes; hands.drop_slope 25 deg, drop_gap 0.08 m; on-end threshold 60 deg, at most 5 Socks on end; paired moment 0.5 s (40% flight, 30% fold, 30% roll), pop 125%, 24/12 specks; CCD_ON 1 m/s, CCD_OFF 0.5 m/s; held.bend_limit 0.5, cloth.max_accel 12, accel_smooth 0.1 s; Coin pops (bonus pop 0.35 s after, 90 px above; banner at 22% height for 2.5 s); mix levels buses SFX 1.0, Ambient 0.5, Music 0.35; window ambience call 4-8 s, gap 15-40 s, fade 1.5 s, -12 dB; Radio loudness about +7 dB; refusal red (0.95,0.25,0.2) wobble about 4 deg for 0.45 s; cloth.flying_cap 4; ping reach 30 m, lift 0.3 m, size 4.5% of screen height; ping wheel hold 0.25 s, dead zone 40 px, keycaps 150 px out; ping sticker 6%; waddle (foot swing 22 deg, roll 8, bob 3.5 cm, sway 3 deg per 0.9 m stride), pupils 28 deg, idle wander 8 deg every 1.6 s; look bend bend_down 36 deg, bend_up 24 deg, bend_speed 8/s; players.push_apart 0.6 m, push_rate 8/s; held.worn_step 7 cm aside, 2 up, 5 back; knockdown rise_spring 35, rise_damping 4; mirror 512 px, 12 m far, stops beyond 7 m, MSAA 2x; sky energy keyframes 0.9 noon, 0.6 at 18:48, 0.35 sunrise/sunset, 0.08 night; SUN_MAX_ELEVATION 28 deg; sky reflection 256/128/64 per preset; lamp shadow atlas 2048/1024; leaver's Hands drop in a 0.25 m ring. All of these are `placeholder` (none decided).
- Live questions list (questions/live.md): a sweep of open questions for other features, copied below verbatim for the receiving digests (they belong to house, multiplayer, flat, mvp, maintenance, upgrades, Steam/voice, not to this digest's features).

## G2. live.md content (verbatim open questions, all [unanswered] at the sweep 2026-10-31; later ones may be answered in their tickets, unchecked)
## House (6)

**[[06-mess-across-levels]]**
- Socks on the stairs: lay some on purpose, keep them off, or only what rolls there? (answered by Q441, recorded with house/16's build)
- Flight counts as its 7.6 m walk; upper levels sit almost flat on the washer gradient; OK?
**[[15-bathroom-mirror]]**
- Reflections read paler / lower-contrast than the room; keep, or tint/darken?
- make_house.py writes a "mirrors" list to the layout instead of the BATH_GLASS constants?
**[[16-sock-rest-fit]]**
- Mess Socks poke slightly into walls where the spill lays them close (from flat/11)
**[[17-dumbwaiter]]**
- Hatch sill height and which faces it has (from house/01)

## Multiplayer (33)

**[[11-end-summary]]**
- "Pairs made" and Coins earned counting rules
**[[15-predict-cycle-drop]]**
- predicted drop hops when the host's Mess differs; check over internet
**[[19-ping-emoji-wheel]]**
- highlight through a wall too small; filled silhouette or marker?
- should the pinged teammate see something on their own screen?
- pinger sees no copy over their own head; wanted?
- pinged Sock picked up: should the ping follow it into Hands?
- should an emoji on a thing also outline it?
- emoji icon pictures up for the designer
- only Stations outlined; other furniture gets the ring
- a different blip per emoji?
**[[20-avatar-wardrobe]]**
- pupils look at the nearest player, or the one looking at them / the local player?
- own first-person belly: shadow? clothes on it?
- name tag lifted over tall hats, or one height?
- unlock milestones (balance round, Q308); more milestones; unlock message enough?
- locked pieces: say what unlocks them?
- host doesn't check a guest's cosmetics against unlocks; fine for co-op?
- Wardrobe preview turn, layout and "None" text OK?
- keep or drop the unused feet.glb?
**[[21-avatar-look-bend]]**
- bend less when crouched?
- where it bends: neck-like, or whole-body lean?
- held items dip with the bend, or hold still?
- should pupils also look down when bent down?
- own belly curl enough to notice?
**[[22-throw-knockdown]]**
- while down nothing hits them; hand-offs still allowed; OK?
- knocked while charging drops the charge; OK?
- only the knocked machine freezes input; X-ray keys still toggle; enough?
- item bounces back at 5%; open menus stay open when knocked
**[[24-knockdown-collides]]**
- sweep the get-up wobble's overshoot too?
**[[25-lying-body]]**
- should a fall slide off a ledge too?
- roll off a lying teammate to the floor?
- getting up unswept: should the one underneath wait or push?
- slump side on a tie, slide_keep 0.5, rising straight up
- lying body blocks walkers; Throws pass through it; both OK?

## Flat (partly superseded by the house) (67)

**[[04-print-atlas]]**
- review the motif list (names and picks per Collection)
- VRAM compression for the 33 MB print atlas?
**[[08-xrays]]**
- how the Collection X-ray shows its icon (billboard on every Sock, near only, aimed only)
**[[09-ui-icons-highlight]]**
- Collection icons baked colour in SVG, or tinted from designs.json
**[[21-held-info]]**
- keep the generic cream sock icon or draw another
**[[28-polish-followups]]**
- re-judge day and night in the house, incl. lamps-on time
- neighbouring drawers' "+N" pops nearly touch; spread or stagger?
- Collection bonus pop over the last drawer or the Cabinet's top?
- which point of the Sock the held info follows, and the droop
- lamps snap or fade, switch sound, lamp colour, window falloff, music start/gap
**[[30-hdri-sky]]**
- which HDRIs (mixed places or a matched set)
- dusk crossfade reads as a double exposure; faster switch?
- should the sky light's tint follow the hour, and how much photo colour reaches the room
- 2k panoramas soft up close; 4k for day?
**[[32-drop-landing]]**
- thrown items stay on tops; should some tops (Cabinets, fridge) shed them?
- drop aimed at an out-of-range heap: hint or crosshair change?
- a Sock still flying in doesn't hold others up when its support is picked; leave?
**[[35-hollow-oven]]**
- wire rack without collider lets the crosshair through; keep?
- oven door window see-through glass?
**[[36-rmb-throw]]**
- should a tap lob still exist, and is the lob window right?
- nothing shows in the first 0.25 s of a hold; ring or sound earlier?
- menu opened during a held right button: charge throws, uncharged lets go; keep?
**[[37-washer-lesson]]**
- lesson Socks taken from the 1000 (total unchanged); confirm
- which picture Collection for the lesson (now Animals)?
**[[38-aimed-drawer]]**
- full aimed drawer with equal neighbours: lower takes overflow; right?
- full tint only while holding Pairs; also for other Collections' Pairs?
**[[42-windows-build]]**
- no game icon yet (Godot default)
**[[43-paired-moment]]**
- fold direction: sideways or roll towards the camera?
- sparkles read white over pale walls; warmer colour, star, non-additive?
- should a teammate's pairing play the pop?
- teammate sees flight and burst but no fold; enough?
**[[44-sock-meshes]]**
- cloth per Collection mapping (cotton/wool/fuzzy); jersey knit up close?
- heel turn vs footprint: crisper L, straighter, or as is?
- ball shape and size: fit the drawer grid, lump amount right?
- motif aspect per shape: check motifs on chunky and ankle Socks
- rig rest bones follow the turn; check paired-moment curl
**[[46-menus-options-licence]]**
- volume sliders scale the mix (100% = mix); OK or show the mix?
- which sounds go on the UI bus?
- a tick per slider step?
- option ranges and labels (mouse speed, FPS cap, graphics, display) OK?
- Licence credit wording; drop unpicked sound candidates from builds?
**[[47-tv-and-radio]]**
- enough radio tracks per channel, right picks?
- keycap hint shows current channel; show the next one instead?
- devices start Off after a load; should a save keep the channels?
- devices on the Music bus; own bus or volume?
- static lengths and switch-off feel right?
- TV show contents (puppets, shopping, weather, test card); rewrite any?
- shopping channel's Design reads small; bigger, closer, brighter?
- TV and radio channel order and names
**[[48-wardrobe-basket-mirror]]**
- Wardrobe door swing 80 deg, open while anyone inside; OK?
- own reflection; bigger or lower mirror?
**[[49-menu-cursor]]**
- text boxes use the arrow instead of the I-beam?
- cursor 36 px at any resolution, or scale?
**[[50-radio-music-source]]**
- new Theme tracks right picks; short loops play twice?
- "near the Radio": stop at its room's edge or reach further?
- held Radio size and position; held by its handle?
- "Hands full" refusal text for Radio cases
- a thrown Radio at a teammate: hand it over like a Sock?
- Socks on the Radio stay floating when it is picked; let them fall?
**[[53-turn-held-item]]**
- should your own reflection show the turn?
**[[57-sound-bench-picks]]**
- exported build can't save picks; user:// fallback?
**[[58-cc0-sound-hunt]]**
- keep 7 as the bench's candidate cap?
- TV music beds: mix gibberish voices over them?
- US public domain enough for the 78s where the game ships?
**[[62-widescreen-tv]]**
- TV spot in front of the window: keep, square it, or another wall?
- delete the old retro TV assets and script?
- TV picture 428x240, sharper?

## MVP (4)

**[[07-autosave-and-ending]]**
- Which stats the ending shows
**[[11-cabinets]]**
- Should open drawers close by themselves?
- Full Cabinet if Designs are added later
**[[12-bedroom]]**
- Washer door and dial animate with the Upgrade menu?

## Maintenance (17)

**[[03-sock-collision-and-loading]]**
- Loading screen content (tips, name, players, 3D sock)?
- Pool SockActors for the pick cost; now or later?
- Raise the bake speed-up behind the loading screen?
- Landing glide 0.15 s; OK or hide until settled?
- Thrown Sock starts along its throw; fine?
**[[04-graphics-presets]]**
- High's mesh detail: LOD 1.0 or none?
- Medium SSAO equals High's; change which?
- Medium dual-paraboloid lamp shadows; keep or cube?
- First-launch GPU mapping (unknown, Apple, mid list)
- Low sun shadow stair-stepping
**[[05-drop-floor-clip]]**
- Thrown Sock rides low; widen the flight capsule?
- Touchdown: quick slap or eased arc?
- Low start onto a higher surface flies straight; fine?
**[[06-respawn-lost-items]]**
- Returned items land on the spill heap; fine?
- Window-opening margin 0.1 m; right?
- Visible return trip for lost items?
- Solid window panes so Throws bounce?

## Deferred: upgrades batch (9)

Q485: "The upgrades will be improved in a separate batch." These stay open in their tickets, tagged "upgrades batch".

**[[07-throw]]** (flat/07)
- Throw Upgrade levels and how far a full throw goes
**[[29-upgrade-menu-style]]** (flat/29)
- menu text white with outline or ink-brown
- dim maxed rows too?
- hover tint on every row?
- show E beside ESC as a close hint?
**[[36-rmb-throw]]** (flat/36)
- Upgrade row "Throw (hold right click)" wording right?
**[[07-co-op-interactions]]** (multiplayer/07)
- buy message: should the buyer see it too, and name the level?
**[[06-upgrade-station]]** (mvp/06)
- Upgrade prices, steps and caps
**[[10-sprint-upgrade]]** (mvp/10)
- Should sprinting affect the grab cooldown?

## Deferred: Steam and voice (5)

Q479: deferred until those tickets start; they stay open there.

**[[12-steam-peer]]**
- Steam replaces or sits beside Host/Join by IP?
- how the saved random id maps to a Steam id
**[[13-proximity-voice-chat]]**
- voice codec, bandwidth and echo handling
- voice through the Steam peer and ENet alike?
- mute per player

# PART H. STORY NPC (docs/llm/story/issues/01-plot-npc.md; needs-info, not built)
- A talking NPC that tells the game's plot: "Track it; design in the future" (Q1838). It moves, or appears in later Stages (Q1839). The designer writes the plot (Q1840). Voice plus subtitles, a synthesised voice other than the Old Tree's (Q1841).
- Open [blocking]: Who the NPC is (Q1838 offered a new character or the Old Tree). [blocking] The plot text (the designer's, Q1840).

# SWITCHED OFF / DROPPED (summary list across all parts)
- Pairing machine: off since 2026-11-19 (A5). Pairing-machine Upgrades (Big Hopper, Fast Run, Wide Funnel, Auto Pair) hidden; Old Tree tip hidden.
- Hampers: `enabled: false` (progression/78); back-device idea 3 and sorter-sack throwing depended on them (A7). Not this digest's rules.
- Lost Sock Grotto (hatch, ladder, mineshaft, shrine): switched off behind `drum.on` (C3). Dungeon prototypes (UV lantern, wall-walking, deep water) wontfix.
- Vacuum's hand mode, spit mode, mode button, rear-outlet spit with 6 s hold, Quick Spit Upgrade: removed by tools/24 decisions (Q2119) when tools/25 merges; still in the game on main today.
- Machine prototype row stands (sorting container/separate/dial, cartridges, chute, clothesline, launcher, Size grate, compartments): parked on their branches, not in the game (Q2112). Mate rack: same as clothesline (Q2037).
- Back devices (Vac-Pack, Catch Basket, Hamper Pack, Sweeper Tail, Pairing Pack): parked (Q2060).
- Rogue machine choreography (shake, hop, lunge, spat Socks, alarm, door slam, red pulse) removed by Q1470; rogue/02 wontfix.
- Secrets hidden Socks: rejected (Q1014).

# PROCESS LESSONS (how the designer wants work done; from my folders)
- Grill with questions before building; designer owns look, play, wording and numbers: Q2039 numbers are marked placeholders in data/tuning, listed in the report, tuned by the designer after playing (tools/18).
- Build grayboxes first, art later: "wants every idea playable as a grey box before any art" (designer 2026-11-19, tools/18, Q2020); try all variants in one review build `builds/review-machines/` (Q2036); the designer then picks and the rest stays parked (Q2112).
- No merge before the designer's pick when a review build or blocking question exists: tools/19-23 "Ends ready-for-human; no merge before the pick"; dungeon/04 held for the designer's review build (Q1898); designer approves a review with "merge it" (tools/12, rogue/06 style, cat/06, intro/02 Q1915).
- Designer reviews by PLAYING review builds and reports bugs in plain words ("the hand out by clicking doesn't work", "renders players twice", "the door sounds are now weird... What changed? Track this."): fix the cause, reproduce first (cat/15: the lead's first suspect, a hinge cue kind, was wrong; the repro found the real cause).
- When the designer says a thing should work "like a cabinet logically, not a separate thing (in code!)": reuse the existing rule/code path rather than a parallel one (dungeon/04 hatch). Likewise "for the animated poses we shouldn't use jsons (cat)" (designer 2026-11-07): use real Blender animations.
- Do not declare a design impossible: the designer answered "Players can go in drums, why couldn't items?" (Q1070) to an agent's "can't be built as described".
- Blender models: first Workbench line-up checkpoint for the designer's go before export (Q992, Q1121); "A proper model before merging" (Q1857); several review rounds are normal (detector Q1861-Q1863, litterbox Q1980-Q1990); preview iterations cheap.
- Shared pieces get ONE owner, then consumers in parallel (Q2114); the lead's reading of terse designer answers ("2 + 3.", Q2113) is recorded and confirmed later (Q2174).
- A design question left open is tracked, not built: "Lets keep this tracked, but don't do it now." (Q1881); "Polish later, ticket now" (Q1837); "park for now" (Q2060); "None to build yet; remind the designer later" (Q1852); "Track it; design in the future" (Q1838).
- Bugs reported as "lost" are bugs to find automatically: "Find it automatically (a test or check that catches the Cat ending up somewhere it shouldn't be)" (Q1932); soak/stress tests, but stress cases skip the merge run (cat/16 asks if the long soak should run regularly).
- Tests: tests act through Commands and inputs, never zoo buttons (tools/25 brief); full suite is left to integrate.sh (Q992); agents run only their areas.
- The game is unshipped: no save-compatibility code, except explicit exceptions (cat coat fallback to black, Q1144).
- Network blocks: ask the orchestrator, never work around them (cat/04 brief).
- Switch rather than delete: Pairing machine (Q2102), Grotto (Q1873), Hampers: "behind one switch, code and tests kept", so they can come back.
- Copy tools for agents: a Debugger errors copy plugin so the designer can paste errors to an agent (tools/13, 2026-11-10).
- Cost: rare-event numbers deferred to a balance round after playtests (Q164, Q477, Q1111); upgrades "improved in a separate batch" (Q485).

# COVERAGE

Tickets read in full, in number order. "Answers used" counts distinct designer answers (Q numbers or dated designer quotes) carried into the digest.

| id | title | status | answers used |
|---|---|---|---|
| tools/spec.md | Tools spec (Q720-Q744) | done | 28 |
| tools/back-devices-ideas.md | Back devices idea sheet | ready-for-human | 0 (10 open questions kept) |
| tools/01 | Sock vacuum | done | 9 |
| tools/02 | Pairing machine | done | 4 (spec) |
| tools/03 | Synergy | done | 1 (Q869) |
| tools/04 | Vacuum rework | done | 3 |
| tools/05 | Pairing rework | done | 2 |
| tools/06 | Machine sounds | ready-for-agent | 2 |
| tools/07 | Machines in the house | done | 3 |
| tools/08 | Hose wraps geometry | done | 1 |
| tools/09 | Hose snags | done | 1 |
| tools/10 | Vacuum carried by two | done | 3 |
| tools/11 | Suck effect and sounds | done | 2 |
| tools/12 | Vacuum view cost | done | 1 (designer approval) |
| tools/13 | Copy debugger errors | done | 0 (process) |
| tools/14 | Spit gentle | done | 2 |
| tools/15 | Sock detector | done | 14 |
| tools/16 | Back devices ideas | needs-info | 4 |
| tools/17 | Detector pushes carrier | done | 1 |
| tools/18 | Graybox kit | done | 4 |
| tools/19 | Sorting vacuum grayboxes | ready-for-human | 10 |
| tools/20 | Chute and clothesline | ready-for-human | 5 |
| tools/21 | Launcher and Size grate | ready-for-human | 3 |
| tools/22 | Machines review | ready-for-human | 1 |
| tools/23 | Nozzle filter variants | ready-for-human | 22 |
| tools/24 | Vacuum devices spec | in-progress | 57 |
| tools/25 | Pour, spit-out, filter | ready-for-agent (built, unmerged per lead) | 0 own (spec in 24); acceptance used |
| tools/26 | Pairing machine off | done | 2 |
| tools/27 | Backpack vacuum | ready-for-agent | 0 own (acceptance) |
| tools/28 | Splitter | ready-for-agent | 0 own (acceptance) |
| tools/29 | Filter nozzle Upgrade | ready-for-agent | 0 own (acceptance) |
| tools/30 | Vacuum device models | ready-for-agent | 0 (picks Q2171-Q2174 are in tools/24) |
| cat/01 | Black cat | done | 7 |
| cat/02 | Cat on the couch | done | 1 (designer) |
| cat/03 | Cat swats | done | 3 |
| cat/04 | Real cat hiss | done | 2 |
| cat/05 | Washed cat coat | done | 6 |
| cat/06 | Cat animations from Blender | done | 3 |
| cat/07 | Petted cat brings Socks | done | 4 |
| cat/08 | Cat navigates | done | 3 |
| cat/09 | Cat stuck in attic | done | 0 (bug fix, acceptance) |
| cat/10 | Cat gets lost | done | 3 |
| cat/11 | Litterbox | ready-for-human (built, merged) | 11 |
| cat/12 | Cat fetches more often | done | 2 |
| cat/13 | Cat naps in Elevator | done | 3 |
| cat/14 | Cat follow-ups | done | 9 |
| cat/15 | Door sounds weird | done | 1 (designer report) |
| cat/16 | Long soak finds Cat off stairs | ready-for-agent | 0 |
| dungeon/01 | Lost Socks dungeon prototype | wontfix | 20 (Q1442-Q1461, Q1953) |
| dungeon/02 | Mechanics and layout trials | needs-info | 0 (5 open questions kept) |
| dungeon/03 | Water drum prototype | wontfix | 8 |
| dungeon/04 | Drum finale | done | 38 |
| dungeon/05 | Drum shuffle spin | needs-info | 3 |
| dungeon/06 | Drum hatch porthole | done | 10 |
| dungeon/07 | Handed-out pairs after the drum | done | 2 |
| rogue-machine/spec.md | Rogue spec (Q745-Q760) | n/a | 10 |
| rogue-machine/01 | Rogue sequence | done | 5 |
| rogue-machine/02 | Stronger sequence | wontfix | 1 |
| rogue-machine/03 | Socks ride the machine | done | 1 |
| rogue-machine/04 | Talking washing machine | done | 34 |
| rogue-machine/05 | Cutscene polish | done | 4 |
| rogue-machine/06 | Voices louder | done | 3 |
| secrets/01 | Secrets subsystem | done | 12 |
| secrets/02 | Drum loads Cat and Radio | done | 2 |
| secrets/03 | Secret piece models | done | 5 |
| secrets/04 | Car lamp collider | done | 0 (bug) |
| secrets/05 | Polish secrets | needs-info | 1 |
| intro/01 | Hudry Games intro | done | 33 |
| intro/02 | Purple turkey and drops | done | 10 |
| questions/01..06 | core loop, numbers, rare, MVP collections, sound source, balance round | done/wontfix/ready-for-human | 6 |
| questions/live.md | Live questions | spec | 0 answers (open list copied) |
| story/01 | Plot NPC | needs-info | 4 |

**Counts.** Tickets read: 30 tools + 16 cat + 7 dungeon + 6 rogue-machine + 5 secrets + 2 intro + 6 questions + 1 story = 73 ticket files, plus tools/spec.md, tools/back-devices-ideas.md, rogue-machine/spec.md and questions/live.md (77 files). `(Q` occurrences by grep in these folders: 611 (tools 218, cat 79, dungeon 130, rogue-machine 67, secrets 36, intro 63, questions 12, story 6); the line-count grep of the same pattern is 576 lines. Distinct Q numbers cited in the folders: 169 + 53 + 73 + 59 + 22 + 44 + 17 + 4 (some overlap across folders). Answers used in the digest: all distinct designer answers of the Answers sections (about 380 lines of answers carried), because each `(Qnnn)` appears several times (spec, ticket Answers, acceptance text and Built logs). The gap between 611 occurrences and the distinct answers is repeats (acceptance text and Built log lines citing an answer already in Answers) and references to other folders' Q numbers (e.g. Q164, Q477, Q838-Q840 in questions).

**Could not determine / unchecked**
- Which of the 8 Secrets did not trigger in the first build ("7 of 8"), and whether it does now (secrets/01); the Secret "Fur Fetch" is the likely one: unchecked.
- tools/25: vault status is `ready-for-agent` with empty Built log; the "built but unmerged" state comes from the lead's brief, not from the ticket.
- tools/11, 12, 20 Built logs are cut at long lines; nothing rule-bearing was lost, but exact file lists are not copied.
- Whether `drum.on` has since been disabled in the designer's uncommitted edits: data/tuning/drum.json on disk shows "on": true. Hampers `enabled` false and pairing `enabled` false were checked on disk.
- Live-question list (questions/live.md) is from 2026-10-31; many entries were answered later in their own tickets (other digests); unchecked.
- Controls on pad (gamepad bindings) for spit, pour, wheel: not decided (tools/25 follow-up).
- Cat/01-cat/15 numbers for tuning (cat.json) were not all read from the file, only from tickets.
