> Draft behaviour list for M0.6 (Q2436), written from the reference on 2026-11-22; for the designer to approve. Answered 2026-11-22: question 1 by Q2437, question 9 by Q2438; the rest open (asked before batch 4).

# M0.6 piece: Knockdown (behaviour list, draft)

Reference paths are under `reference/it-socks/` (tag v0.1.1). Words follow `GLOSSARY.md`. "Host" and "Guest" are the co-op roles; "Teammate" is another player. A line is one thing the designer can keep or drop. Nothing is left out as minor.

Scope tags used below:
- **(zoo)** exists or can exist in the zoo today.
- **(needs the washing machine — outside the zoo?)** the old basement washing machine; the port has none yet.
- **(needs the Cat / lantern / Radio / Beeper / Guide card / drum)** a thrown thing the port does not have yet.

## Behaviour list

### A. What knocks a player down

1. When a player Throws with the charge at "knockdown.min_charge" (1.0, the full ring), then that Throw is a full-charge Throw and can knock a Teammate down. A weaker Throw never knocks down. (zoo) (ref: game/hands/thrower.gd:146; data/tuning/knockdown.json min_charge)
2. When a full-charge Throw of a loose Sock hits a Teammate, then they are knocked down. (zoo) (ref: game/world/flight_rules.gd:200-203)
3. When a full-charge Throw of a Pair hits a Teammate, then they are knocked down. (zoo) (ref: game/world/flight_rules.gd:200-203)
4. When a full-charge Throw of the lantern hits a Teammate, then they are knocked down. (needs the lantern, outside the zoo) (ref: game/world/flight_rules.gd:189-190; game/world/flight.gd:155-159)
5. When a full-charge Throw of the Radio, the Beeper (Sock detector), a Guide card or the Cat hits a Teammate, then they are knocked down (Q1935). (needs those things, outside the zoo) (ref: game/world/flight_rules.gd:189-192; game/world/flight.gd:155-159)
6. When a weaker Throw of the Radio, the Beeper, a Guide card or the Cat hits a Teammate, then it bounces off, drops at their feet, is never caught and knocks nobody down (Q1936). (needs those things) (ref: game/world/flight_rules.gd:300-306)
7. When a player tumbles out of the washing machine's drum, then they are knocked down too, for "wash.out_seconds" (2.0 s), with their own fall (see section H). (needs the washing machine — outside the zoo?) (ref: game/knockdown/washes.gd:222-249)
8. When the drum's shuffle spin runs (a later, undecided feature), then players tumble and are knocked down. Not built in the old game either. (outside M0.6; for the record) (ref: docs/migration/feature-catalogue.md P29)
9. When a thrown Sock or Pair is a Sock vacuum's spat Sock, a pairing machine's rolled Pair, or a falling Pair (a "pair_fall"), then it only falls and hits nobody. (needs those devices) (ref: game/world/flight_rules.gd:141-150; game/world/flight_rules.gd:181-182)
10. When a Bins, a Hamper or a Part is the thing, then it cannot be thrown, so it never knocks. (digest rule, Q1935) (ref: docs/migration/digests/digest-core-and-coop.md:73)
11. When a launched Pair or Sock from the kit's launcher is the thing, then it is a "spit" flight that hits no player (open W52/W58: should it knock?). (needs the launcher; the designer has not decided) (ref: docs/migration/feature-catalogue.md:361)

### B. The hit test and who is exempt

12. When a Flight is inside a player's body capsule while in the air, then the Host asks the rules whether that is a catch, a knockdown or nothing. The test runs after every physics tick for every Flight and every player's body. (zoo) (ref: game/world/flights.gd:283-297)
13. When a ball of radius R is at a point, then it touches a body if it is no lower than R under the feet, no higher than R over the body's height, and within "players.body_radius" (0.3 m) plus R of the body's axis, sideways. (zoo) (ref: game/player/rig.gd:688-692)
14. When a body's height is asked, then it is the avatar's current height (standing or crouched). (zoo) (ref: game/player/rig.gd:681-684)
15. When the push is worked out, then the reach used for `side` is `players.body_radius` plus the Flight's radius. (zoo) (ref: game/world/flight_rules.gd:202)
16. When the hit is on the thrower, then nothing happens (you cannot knock yourself down). (zoo) (ref: game/world/flight_rules.gd:197)
17. When the hit player is already down, then nothing happens (no second knockdown, no timer reset). (zoo) (ref: game/world/flight_rules.gd:197, 338)
18. When the hit player is inside the washing machine's drum, then nothing happens and the Flight flies on. (needs the washing machine) (ref: game/world/flight_rules.gd:197, 338)
19. When the hit player is a rider curled in the Elevator's car, then nothing happens. (needs the Elevator) (ref: game/world/flight_rules.gd:303, 338)
20. When a Flight has already hit one body (hit_body), then it hits nobody else. (zoo) (ref: game/world/flight_rules.gd:195, 172)
21. When a Flight is done (landed), then it hits nobody. (zoo) (ref: game/world/flight_rules.gd:195)
22. When only one player is in the game (fewer than two rigs), then the hit test is skipped. (zoo) (ref: game/world/flights.gd:288-289)
23. When a hit lands, then only the Host decides it; a Guest never decides a knockdown. The Guest sends a "thrown_knock" Command; the Host's answer is applied everywhere. (zoo) (ref: game/world/flight_rules.gd:195, 333-360)
24. When the hit is decided, then three numbers say how the body falls: `push` (the way the Flight flew along the floor, unit; forward if it fell straight down), `high` (how far up the body it hit, 0 feet to 1 top, clamped) and `side` (how far off centre, -1 to 1, + turns the body anticlockwise seen from above). (zoo) (ref: game/world/flight_rules.gd:208-217)
25. When the Host receives the Command, then it re-normalises `push` along the floor, clamps `high` to 0..1 and `side` to -1..1 (a Guest's numbers are not trusted as given). (zoo) (ref: game/world/flight_rules.gd:342-348)
26. When the Command's target is not a Teammate of the sender, then it is refused (no event). (zoo) (ref: game/core/game.gd:1123-1124; game/world/flight_rules.gd:338)

### C. What the hit does to the thrown item

27. When a full-charge hit knocks someone down, then the Throw's item is not handed over and not caught: it bounces back off the body from where it hit, at the old velocity times "knockdown.bounce" (0.05), reversed sideways and with no vertical part, and falls. (zoo) (ref: game/world/flight_rules.gd:200-203, 168-174; data/tuning/knockdown.json bounce)
28. When the Flight bounces, then its model is drawn from where it hit, not gliding there. (zoo) (ref: game/world/flights.gd:300-310)
29. When a Guest's own predicted Throw bounced off a body on the Host, then the bounce eases in from where the Guest's copy is drawn, over "release.predict_blend" (0.2 s). (zoo) (ref: game/world/flights.gd:311-313)
30. When the bounced item stops, then it lands by the Host's word like any Flight. (zoo) (ref: game/world/flight_rules.gd:166-167)
31. When a Throw at full charge knocks, then the event carries an event cue "knockdown" at the hit point, which plays the sound (section M). (zoo) (ref: game/world/flight_rules.gd:359)

### D. What the knocked player drops or loses

32. When a player is knocked down mid-charge of a Throw, then the charge is cancelled and nothing is thrown. (zoo) (ref: game/hands/thrower.gd:74-75, 119)
33. When a knocked player wears or carries a Backpack vacuum, then it drops beside them with its load, worn and carried by nobody, at a landing spot chosen by the Host with a random turn. (needs the Backpack vacuum) (ref: game/world/flight_rules.gd:345, 356; game/devices/backpack_vacuums.gd:14, 330-341, 345-359)
34. When a knocked player carries a Hamper, then it spills (a "hamper_spill" at their feet). (needs the Hamper) (ref: game/devices/hampers.gd:236)
35. When a knocked player holds the Cat, then it wriggles free and jumps down by their feet. (needs the Cat) (ref: game/cat/cat.gd:680)
36. When a knocked player holds Socks or Pairs in the Hands, then they keep them (nothing in the old code drops them). Open: keep? (zoo) (ref: game/world/flight_rules.gd:333-349, no drop of Hands; see Questions)
37. When a knocked player was dragging a Teammate, then that drag ends ("knocked") and the body lies where it is. (needs the drag) (ref: game/knockdown/drags.gd:106-111)
38. When a knocked player was standing on or being stood on in a stack, then see the stack rule: a knocked player holds no one (stack off). (outside M0.6) (ref: game/player/rig_stack.gd:49)

### E. The ragdoll itself

39. When the knockdown is applied, then every machine sets `down` = 5.5 s ("knockdown.seconds") and stores the fall numbers on the player. (zoo) (ref: game/world/flight_rules.gd:352-358; data/tuning/knockdown.json seconds)
40. When `down` is above zero, then a ragdoll exists for that player on every machine; it is made on the first tick it is seen, not on the event. (zoo) (ref: game/player/rig_knockdown.gd:36-37)
41. When the ragdoll is made, then it is a skeleton copy of the avatar's (Root, Spine0, Spine1, Spine2), one physical bone per bone. (zoo, after the avatar rig port) (ref: game/player/ragdoll.gd:1-6, 54-110)
42. When the ragdoll is made, then it is never drawn; the avatar's bones copy its pose every frame. (zoo) (ref: game/player/ragdoll.gd:5; game/player/avatar.gd:623-651)
43. When each bone is made, then its body is a capsule of radius "players.body_radius" (0.3 m, shrunk if the stretch is short) along its stretch of the body, from half a radius under its joint to half a radius over the next joint; the top bone ends at 1.7 m (TOP); the lowest starts no lower than 0.03 m (FOOT_GAP) over the floor so it never starts inside it. (zoo) (ref: game/player/ragdoll.gd:17-19, 74-83)
44. When each bone is made, then its body sits at the capsule's middle, upright in the creature, and its joint is at the bone's head with the twist axis along the body. (zoo) (ref: game/player/ragdoll.gd:87-93)
45. When a bone has a parent, then it is joined by a cone joint: swing at most "knockdown.joint_bend" (45 degrees), twist at most half of that (22.5). Root has no joint. (zoo) (ref: game/player/ragdoll.gd:91-96; data/tuning/knockdown.json joint_bend)
46. When a bone is made, then friction 0.8, linear damping 0.4, angular damping 2.0, mass left at Godot's default 1.0 per bone, and it can never sleep. (zoo) (ref: game/player/ragdoll.gd:99-102)
47. When the bones are made, then no two bones of one ragdoll collide with each other. (zoo) (ref: game/player/ragdoll.gd:108-110)
48. When the ragdoll collides, then it is on its own physics layer (RAGDOLL, 8) and meets the house (WORLD), furniture and stations (STATION), other lying ragdolls (RAGDOLL) and standing Teammates (MATE). (zoo) (ref: game/player/rig_knockdown.gd:60-61; game/core/layers.gd:15, 29-30)
49. When a Teammate walks into a body lying on the floor, then they bump into it instead of walking through. Once the body stands again the way is free. (zoo) (ref: game/player/ragdoll.gd:9-11; tests/net_knockdown_test.gd:665)
50. When a ragdoll falls onto another ragdoll, then it lands on it instead of through it (on the Host, and as a Guest draws it). (zoo) (ref: tests/net_knockdown_test.gd:709-710)
51. When a ragdoll falls on a Heap of resting Socks, then it does not lie on them (known gap X19: players walk through Heaps). (outside M0.6) (ref: docs/migration/feature-catalogue.md:437)
52. When a player stands, then an invisible upright capsule of "players.body_radius" and the body's height stands on layer MATE where they stand, so a falling ragdoll bumps it; only ragdolls collide with it. It is off while that player is knocked down or in the drum. (zoo) (ref: game/player/rig_knockdown.gd:174-199)
53. When a Teammate already stands inside the knocked body when it is hit (within 2 body radii sideways and the body height up, so on its back or pressed against it), then the falling body does not collide with that Teammate's capsule: it falls through them. (zoo) (ref: game/player/rig_knockdown.gd:73-80)
54. When the ragdoll is made, then the player's own walking body ignores its bones (collision exception), so it never bumps its own ragdoll. (zoo) (ref: game/player/rig_knockdown.gd:64-65)
55. When the Host starts the ragdoll, then it stands at the player's feet (or at the fall's own place, yaw and tilt for the drum) and every bone is set moving the way the hit pushed. (zoo) (ref: game/player/rig_knockdown.gd:68-72, 88-90; game/player/ragdoll.gd:151-162)
56. When the push is set, then each bone moves along `push` at `push_speed` (3.0 m/s) times its height over the body's (0 at the feet, 1 at the top, 1.7 m). (zoo) (ref: game/player/ragdoll.gd:160-161; data/tuning/knockdown.json push_speed)
57. When the push is set, then a hit high on the body pushes harder: a factor from 1 - high_kick (0.5) at the feet to 1 + high_kick (1.5) at the top, by where it hit. (zoo) (ref: game/player/ragdoll.gd:158; data/tuning/knockdown.json high_kick)
58. When a hit is off centre, then every bone also turns about the up axis at "knockdown.spin" (3.0 rad/s) times `side`: less near the middle, the other way on the other edge. (zoo) (ref: game/player/ragdoll.gd:162; data/tuning/knockdown.json spin)
59. When a Throw knocks a Teammate towards a wall just in front of them, then the ragdoll meets the wall; neither it nor the knocked player's own view ever ends inside the wall. (zoo) (ref: tests/net_knockdown_test.gd:263-265)
60. When a full-charge Throw bounced off a wall first and then hits, then the Teammate falls the way it came back, away from the wall, on both machines. (zoo) (ref: tests/net_knockdown_test.gd:196-197)
61. When the ragdoll is falling, then it lies over past a surely-fallen angle (the topple test reads the line from feet to head against upright; flat is about 90 degrees). (zoo) (ref: game/player/avatar.gd:654-658; tests/net_knockdown_test.gd:41-43)
62. When the bones fall, then they move on physics ticks and are drawn between ticks by physics interpolation, so a ragdoll at 30 ticks a second moves smoothly. (zoo) (ref: game/player/ragdoll.gd:57-58, 246-259)
63. When the ragdoll's pose is read each frame, then each bone is the body's transform times the inverse of its body offset, orthonormalised (the bone's head at the joint). (zoo) (ref: game/player/ragdoll.gd:262-269)
64. When the avatar copies the ragdoll, then the lowest bone (Root) places the whole creature and the others bend it, so the hat, clothes, eyes and the name ride along. The creature's walk, squash, climb and foot positions are reset at the start. (zoo) (ref: game/player/avatar.gd:623-651)
65. When the ragdoll ends, then the avatar stands again (identity transform, normal pose). (zoo) (ref: game/player/avatar.gd:628-634)
66. When an Avatar or the player's own body or the mirror body is shown, then all three copy the same ragdoll pose. (zoo: the mirror body is not in the port) (ref: game/player/rig_knockdown.gd:146-148)
67. When a body is knocked down in the Elevator's car, then the rules differ (riders are exempt from hits); the ragdoll is hidden while "in_car". (needs the Elevator) (ref: game/player/rig_knockdown.gd:144, 149; game/house/elevator_ride_view.gd:323, 388, 401)

### F. The knocked player's own view

68. When the player is knocked down, then their input is frozen as by a menu (no walking, jumping, picking, using, pinging, throwing) until they stand; the look still follows the ragdoll, not the mouse. (zoo) (ref: game/player/player.gd:104-109; game/player/rig.gd:328, 342; game/player/rig_click.gd:33-34)
69. When the player is knocked down, then their camera rides the ragdoll's head: the standing eye height (1.6 m, EYE) over the feet on the top bone, turned with it, still looking up or down by the pitch they had. (zoo) (ref: game/player/ragdoll.gd:21, 281-283; game/player/player.gd:686-697)
70. When the camera rides the head, then it stops "knockdown.wall_gap" (0.3 m) short of a wall or furniture between the body's middle and the eyes, using a ray from the body's middle to the eyes against WORLD and STATION. (zoo) (ref: game/player/player.gd:700-712; data/tuning/knockdown.json wall_gap)
71. When the wall test is run, then it runs in the physics tick (never a render frame), and the camera reads the answer a tick old at most. (zoo) (ref: game/player/rig_knockdown.gd:128-136; game/player/player.gd:693, 700-702)
72. When the camera is drawn, then it follows the ragdoll's pose as drawn between ticks (interpolated), not the raw tick pose. (zoo) (ref: game/player/rig_knockdown.gd:141-152)
73. When the ragdoll is in the car, or this is a Teammate's machine view, then the eye clip is cleared. (needs the Elevator for the car) (ref: game/player/rig_knockdown.gd:132-133)
74. When the knockdown ends, then the camera returns to the standing head, at the standing eye height. (zoo) (ref: game/player/rig_knockdown.gd:104-105; game/player/player.gd:726-729)
75. When the player is knocked down, then the view does not fade, blur or get an overlay in the old game. The only fade in the whole feature is the wash's (section H). (zoo) (ref: no fade or overlay in game/player/rig_knockdown.gd; game/knockdown/screen_fade.gd is used by the wash and the rogue sequence only)
76. When the player is knocked down, then the HUD stays shown (the crosshair and hints remain). Only the washed player's HUD is hidden (Q991). (zoo) (ref: game/player/rig_wash.gd:34-35)
77. When the player is knocked down, then their view's roll can be any amount (the camera tips over with the head). (zoo) (ref: game/player/player.gd:732-735)
78. When the player is knocked down, then they see a message "<name> knocked you down" (the thrower's roster name, "A teammate" when unknown). Only the knocked player sees it; the thrower and others get no line. (zoo, with names from the roster) (ref: game/ui/teammate_news_installer.gd:54-59)

### G. How long, and getting up

79. When a knockdown lasts, then `down` counts down from 5.5 s on every machine's own clock (one number, decided Q985); it is not saved in a save game. (zoo) (ref: game/core/game.gd:1244; game/knockdown/knockdown_poses.gd:1-3; data/tuning/knockdown.json seconds)
80. When `down` reaches "knockdown.rise_time" (0.6 s, clamped to the knockdown's length), then the Host stops the physics and the body blends from the pose it lies in to the standing pose. (zoo) (ref: game/player/rig_knockdown.gd:42-51; game/knockdown/drags.gd:82-84)
81. When the body blends up, then every bone interpolates (position and rotation) with a smoothstep of the rise's progress (0 to 1 over the 0.6 s). (zoo) (ref: game/player/rig_knockdown.gd:47-51)
82. When the body blends up, then it stands where its feet lie, the feet dropped onto the floor or stairs under them (ray from 0.5 m above to 1.0 m below the feet; else the player's own height), never inside the floor. (zoo) (ref: game/player/rig_knockdown.gd:46, 113-125)
83. When the body blends up, then it faces the way the player faced (their own yaw, which a knockdown never changed because input is frozen). (zoo) (ref: game/player/rig_knockdown.gd:46)
84. When the body blends up, then every machine plays the blend itself; the Host's pose is ignored during it. (zoo) (ref: game/player/rig_knockdown.gd:155-163)
85. When the ragdoll lies, then the player's own walking body (the capsule) stays at the ragdoll's feet each tick on the player's own machine, so the player gets up where they lie. (zoo) (ref: game/player/rig_knockdown.gd:52-53, 26-29)
86. When `down` reaches 0, then the ragdoll is freed, the avatar stands, the view returns to the head, and the player can move again. No bounce, hop or squash is played at standing. (zoo; "getting up facing, bounce" is open in P105) (ref: game/player/rig_knockdown.gd:32-35, 97-105; docs/migration/feature-catalogue.md:263)
87. When the player stands up, then there is no immunity: they can be hit again at once. The only protection is during the rise, when a dragged player cannot be grabbed (below). Open: is that right? (zoo) (ref: game/knockdown/drags.gd:56; no immunity timer in game/ or data/tuning/knockdown.json)
88. When the player starts getting up, then they cannot be grabbed to drag ("standing"). (needs the drag) (ref: game/knockdown/drags.gd:56)
89. When the rogue sequence ends, then every knockdown, drag and wash ends and everyone respawns (Q759). (needs the rogue machine, outside the zoo) (ref: game/house/house_rules.gd:105-118)
90. When a player leaves the game while down, then their ragdoll goes with them and any drag or wash of theirs ends. (zoo, with leave) (ref: game/knockdown/drags.gd:113-119; game/hands/hands_rules.gd:416-418)

### H. Drag (a Teammate pulls the knocked player)

91. When a Teammate stands near a knocked-down body with empty Hands and aims at it within reach, then the body is outlined (highlighted) and the hint "Hold: Drag [left button]" shows. (needs the drag) (ref: game/player/rig_aim.gd:172-174; game/ui/prompts.gd:54)
92. When the aim line passes within one body radius of a lying body's bent middle line, then that body is the aimed one. (needs the drag) (ref: game/player/rig_aim.gd:255-275)
93. When the dragger presses the left button on a knocked body, then a knocked body wins the click over a Sock or a Station under the crosshair. Open: keep? (needs the drag) (ref: game/player/rig_click.gd:39-40; docs/migration/digests/digest-core-and-coop.md:72)
94. When the grab is asked, then the Host grants it unless: gone, the dragger is down, the target is not down or is already rising, someone drags them, they ride the Elevator, the dragger drags already, or the dragger's Hands are not empty. (needs the drag) (ref: game/knockdown/drags.gd:51-67)
95. When the grab is granted, then the dragger's Hands carry the body (nothing else comes in) and the dragger walks at "drag.speed" 0.6 of their pace. (needs the drag) (ref: game/knockdown/drags.gd:1-5, 70-72; game/player/rig.gd:340)
96. When the dragger lets go of the left button, then the body drops where it lies. If the button comes up before the Host grants it, then it lets go at once on the grant. (needs the drag) (ref: game/player/rig_drag.gd:131-139, 148-153)
97. When a menu or cutscene opens on the dragger, then they let go of the body (its button-up never comes). (needs the drag) (ref: game/player/rig.gd:343-345)
98. When the body is dragged, then the dragger's feet-hold point is 0.4 m ("drag.hold_height") above their feet and 0.6 m ("drag.hold_behind") behind their middle. (needs the drag) (ref: game/player/rig_drag.gd:110-118)
99. When the body is dragged, then on the Host the ragdoll's Root bone (the feet) is pulled to the hold point by a critically damped spring of strength 60 ("drag.pull") per second squared per metre for the whole body's mass; the rest of the body trails on its joints. (needs the drag) (ref: game/player/ragdoll.gd:201-204, 225-233; game/player/rig_drag.gd:78-80)
100. When the dragger walks through the body they pull, then the dragger's body and standing capsule pass through that ragdoll (collision exceptions, on every machine), so they do not trip on it. (needs the drag) (ref: game/player/rig_drag.gd:95-107)
101. When the feet lie further than 2.0 m ("drag.break_distance") from the hold point after having been within it once, then the Host ends the drag ("apart": stuck on a wall, the stairs). (needs the drag) (ref: game/knockdown/drags.gd:87-95; game/player/rig_drag.gd:81-85)
102. When the drag crosses an Elevator ride, then it holds through it (Q984). (needs the Elevator) (ref: game/knockdown/drags.gd:93-94)
103. When the body's feet move 0.5 m ("drag.scrape_every") along the floor, then a "drag_scrape" sound plays at the feet. (needs the drag) (ref: game/player/rig_drag.gd:86-92; data/tuning/drag.json scrape_every)
104. When the knockdown timer runs while dragged, then it is not paused (Q754): the dragged player slips out of the grip as the rise starts (`down` at or under 0.6 s), on every machine. (needs the drag) (ref: game/knockdown/drags.gd:98-104)
105. When a dragged player presses Space (the jump action), then one struggle press goes up as a Command. The key hint "Mash: Struggle [Space]" shows to the dragged player. (needs the drag) (ref: game/player/rig.gd:346-347; game/ui/prompts.gd:75-76)
106. When a dragged player's presses reach 10 ("drag.struggle_presses"), then they are freed on every machine and `down` is cut to the rise time: they get up at once and cannot be grabbed again while rising (Q986). (needs the drag) (ref: game/knockdown/drags.gd:187-207; data/tuning/drag.json struggle_presses)
107. When a struggle press lands, then everyone gets a "struggled" signal with presses and needed, but no count is shown anywhere in the old game. Open in P105: show a count? (needs the drag) (ref: game/core/game.gd:166-167; game/knockdown/drags.gd:200-201; docs/migration/digests/digest-core-and-coop.md:70 ("no count shown"))
108. When a drag ends, then the reason is one of: "drop", "struggle", "up", "apart", "knocked", "leave", "rogue", "wash"; the body lies where it is. (needs the drag) (ref: game/knockdown/drags.gd:16-17, 129-139)
109. When a drag starts or ends, then the dragger's and the dragged player's prompts are re-synced. (needs the drag) (ref: game/player/rig_drag.gd:148-163)
110. When a dragged player gets grabbed or dragged, then a knock rumble buzzes on their pad. (needs the drag) (ref: game/player/rig_drag.gd:63-64)
111. When a body is dragged, then the hold stops others from stacking on the body being dragged. (outside M0.6) (ref: game/player/rig_stack.gd:159-160)
112. When one dragger drags, then no second dragger can drag the same body, and one dragger drags one body ("taken", "busy"). (needs the drag) (ref: game/knockdown/drags.gd:58-63)

### I. Wash (a dragged body let go at the washing machine's door)

113. When a dragged body is let go with its feet on the washing machine's floor, in front of it and within 1.5 m ("wash.door_reach") of its door front (and within 1.0 m up or down), then the body is washed: it slides into the drum and the drag ends ("wash"). (needs the washing machine — outside the zoo?) (ref: game/knockdown/washes.gd:127-146; data/tuning/wash.json door_reach)
114. When the machine is already washing someone, a load, or the rogue sequence plays, then a body let go by the door just lies there, silently (Q758). (needs the washing machine — outside the zoo?) (ref: game/knockdown/washes.gd:138-146; docs/migration/digests/digest-core-and-coop.md:66)
115. When the body goes in, then it slides in over 0.35 s ("wash.slide") as a blob in the player's colour, squared in speed (f*f) from the door to the porthole, and the door slams shut with the "wash_slam" sound. (needs the washing machine — outside the zoo?) (ref: game/knockdown/wash_view.gd:155-171, 211-238; data/tuning/wash.json slide)
116. When the door slams, then it shuts in 0.08 s (SHUT_TIME) and bursts open in 0.05 s (BURST_TIME), swings 80 degrees (DOOR_OPEN_DEG), and closes after the burst in 0.5 s (CLOSE_TIME). (needs the washing machine — outside the zoo?) (ref: game/knockdown/wash_view.gd:67-72)
117. When a player is in the drum, then their `down` is 0, their avatar and own body are hidden everywhere, their capsule is held at the washer's position with zero velocity, and nothing can hit, grab or hand to them. (needs the washing machine — outside the zoo?) (ref: game/knockdown/washes.gd:3-5, 151-165; game/player/rig_wash.gd:24-39)
118. When the washed player is in the drum, then they spin there for 3.0 s ("wash.seconds"); a blob in their colour tumbles at 1.2 turns a second ("wash.spin") behind the porthole, 0.085 m in radius, squashed (1.0, 0.8, 0.55), glowing a little (emission 0.35). (needs the washing machine — outside the zoo?) (ref: game/knockdown/washes.gd:151-156; game/knockdown/wash_view.gd:63-66, 100-114)
119. When the washed player looks, then their view sits inside the drum (offset 0, 0.42, 0.12 in the machine's frame) looking out through the porthole, turning with the drum at 1.2 turns a second and lolling a little (a tilt of 0.12 times the sine of half the spin). (needs the washing machine — outside the zoo?) (ref: game/player/rig_wash.gd:9, 43-51)
120. When the washed player is in the drum, then the HUD (crosshair, key hints) is hidden and returns when they come out (Q991). (needs the washing machine — outside the zoo?) (ref: game/player/rig_wash.gd:34-35)
121. When the drum sloshes, then the "wash_slosh" loop plays at the washing machine while anyone spins (not for the finale's spit-out inside the machine). (needs the washing machine — outside the zoo?) (ref: game/knockdown/wash_view.gd:350-357; data/tuning/drum.json sound.machine_sound_inside)
122. When the wash is at its last 0.4 s ("wash.fade_out"), then the washed player's own screen fades to black. (needs the washing machine — outside the zoo?) (ref: game/knockdown/wash_view.gd:271; data/tuning/wash.json fade_out)
123. When the drum runs out, then the Host sends "wash_out": the door bursts open (with "wash_slam" again), the body comes out of the porthole head first, tipped forward 70 degrees ("wash.out_tilt"), and every bone is flung out of the door at 2.5 m/s ("out_speed") and up at 1.5 m/s ("out_lift"). (needs the washing machine — outside the zoo?) (ref: game/knockdown/washes.gd:222-249; game/player/rig_knockdown.gd:68-72, 91-95; data/tuning/wash.json)
124. When they tumble out, then they twist a little (`side` 0.4 times the spin), no push grows with height (speed 0), and they lie knocked down for 2.0 s ("wash.out_seconds", never under the rise time plus 0.05 s). (needs the washing machine — outside the zoo?) (ref: game/knockdown/washes.gd:230-233; data/tuning/wash.json out_seconds, out_side)
125. When they tumble out, then their screen fades back in over 0.6 s ("wash.fade_in") (Q817). (needs the washing machine — outside the zoo?) (ref: game/knockdown/wash_view.gd:217-219; data/tuning/wash.json fade_in)
126. When the door has burst open, then it stands open 1.0 s ("wash.door_open") and swings shut. (needs the washing machine — outside the zoo?) (ref: data/tuning/wash.json door_open; game/knockdown/wash_view.gd:296)
127. When a body is washed again at once after tumbling out, then it is open whether that should be allowed ("washed again at once", P105). (needs the washing machine) (ref: docs/migration/feature-catalogue.md:263)
128. When the washing machine is "busy" for a drum finale or a load (Gift, Radio, Cat), then no body is washed. (needs the washing machine) (ref: game/knockdown/washes.gd:81)

### J. Teammates and the late joiner

129. When a Teammate is knocked down, then everyone sees their ragdoll as the avatar's bent body, flopping and falling the same way as the Host's. (zoo) (ref: game/player/rig_knockdown.gd:1-3; game/player/ragdoll.gd:7-12)
130. When a Guest's machine shows a ragdoll, then it never simulates it: its bones follow the Host's pose, smoothed toward it at 12 per second, and still block walkers. The first pose snaps. (zoo) (ref: game/player/ragdoll.gd:10-12, 49, 175-183, 234-240)
131. When a Guest's ragdoll is made before the Host's pose arrives, then it stands at the fall place until the pose comes. (zoo) (ref: game/player/rig_knockdown.gd:81-87)
132. When the Host's ragdoll is simulating, then it sends every bone's world pose to every Guest, with everyone else's pose, in the same unreliable ordered stream on channel 1, at 20 a second ("net.pose_rate"). It stops sending during the rise. (zoo) (ref: game/player/rig_knockdown.gd:166-171; game/core/main.gd:982-991; game/net/session.gd:488-492; data/tuning/net.json pose_rate)
133. When a pose is packed, then each bone is position and rotation in 20 bytes (WorldCodec.POSE), 4 bones is 80 bytes per knocked player per send. (zoo) (ref: game/player/ragdoll.gd:309-314; game/world/world_codec.gd:30)
134. When a pose arrives with the wrong size (not the avatar's bone count times 20 bytes), then it is ignored. (zoo) (ref: game/player/ragdoll.gd:318-321)
135. When a Teammate is down, then the hit player's own machine also receives its own body's pose from the Host and its view rides that ragdoll. (zoo) (ref: game/net/streams/pose_stream.gd:93-104)
136. When a late joiner joins while someone lies down, then the Host puts in that player's roster entry: how long they are down for, the ragdoll's pose and who drags them. The joiner sees them lying at once and everyone stands them up at the end. (zoo) (ref: game/knockdown/knockdown_poses.gd:10-31; tests/net_knockdown_test.gd:319-321)
137. When a late joiner joins while someone is in the drum, then the roster entry carries the drum time left. (needs the washing machine) (ref: game/knockdown/knockdown_poses.gd:17-19, 29-30)
138. When a knockdown is saved, then it is not: a knocked player is not in a save game and not in the join snapshot's world. (zoo) (ref: game/knockdown/knockdown_poses.gd:1-3)
139. When a Teammate is knocked down, then the knocked-down body's collision stays on every machine, so walkers bump it on Guests too. (zoo) (ref: game/player/ragdoll.gd:10-12)
140. When a Teammate lies, then their name tag and held item follow the bone pose (hat, clothes, eyes, name ride the bones). The held item is drawn from the Hands state at the HoldPoint. Open: what does a Teammate's held item do while they lie? (zoo) (ref: game/player/avatar.gd:623-626; docs/migration/coop-structure-for-the-port.md:67)

### K. Co-op ownership

141. When a ragdoll is made, then the Host owns and simulates it, on the Host's machine, for every player including a Guest. (zoo) (ref: game/player/rig_knockdown.gd:88-90; game/player/ragdoll.gd:7)
142. When the player is a Guest, then their own body (the capsule) stays at their ragdoll's feet, so the avatar's synchronizer authority never changes. (zoo) (ref: game/player/rig_knockdown.gd:26-29; docs/migration/coop-structure-for-the-port.md:81)
143. When the knockdown is a separate Host-owned node, then it is spawned on the hit and freed on getting up. (the port's plan, not old behaviour) (changed by Q2225; ref: docs/migration/coop-structure-for-the-port.md:81)
144. When a Guest sends a hit, then the Host trusts only the shape of it (finite, clamped) and decides. The hit test itself uses which pose of the body (smoothed or raw) is not checked yet. (zoo) (ref: docs/migration/coop-structure-for-the-port.md:209)

### L. Getting hit mid-action

145. When a player is knocked down, then a Throw charge in progress is cancelled (line 32). Held items stay. They cannot pick, use, ping, drop or throw until they stand. (zoo) (ref: game/hands/thrower.gd:74-75; game/player/rig_click.gd:33-34)
146. When a player is knocked down, then the Sock vacuum and Backpack vacuum views do not respond to them. (needs the vacuums) (ref: game/devices/sock_vacuum_view.gd:1104, 1179; game/devices/backpack_vacuum_view.gd:351, 360)
147. When a player is knocked down, then they cannot ride the Elevator or climb in. (needs the Elevator) (ref: game/house/rides.gd:60, 100)

### M. Sounds and pad rumble (Q2376: the knockdown rumble and teammates' sounds come in M0.6)

148. When a knockdown happens, then the "knockdown" sound plays at the hit point (3D, SFX bus, volume 0 dB). It is a placeholder: three synthesised candidates, none picked, the first plays. (zoo; old sound is a placeholder) (ref: game/audio/sound_bank.gd:88; data/sounds.json:430-434; game/world/flight_rules.gd:359)
149. When the knocked player's machine starts the ragdoll, then a "knock" pad rumble buzzes: weak 0.6, strong 1.0, 0.5 s, on every connected pad, unless Options "pad rumble" is off (always on, kept as a setting, Q2375). Only on the knocked player's own machine. (zoo) (ref: game/player/rig_knockdown.gd:38-39; game/player/pad_rumble.gd:1-27; data/tuning/pad.json:12-14; docs/migration/decisions.md Q2375)
150. When a player is grabbed by the feet and dragged, then the same "knock" rumble buzzes for the dragged player. (needs the drag) (ref: game/player/rig_drag.gd:63-64)
151. When a dragged body scrapes, then "drag_scrape" plays (3D, SFX, -4 dB, picks from "pick" sharing, placeholder CC0 cloth sound `cc0/owlish_cloth5`). (needs the drag) (ref: game/audio/sound_bank.gd:89; data/sounds.json:435-441)
152. When the washing machine's door slams and bursts, then "wash_slam" plays (3D, SFX, 0 dB, placeholder synth). (needs the washing machine — outside the zoo?) (ref: game/audio/sound_bank.gd:90; data/sounds.json:442-446; game/knockdown/wash_view.gd:211, 238, 296)
153. When the drum spins, then "wash_slosh" loops (3D, SFX, 0 dB, placeholder synth). (needs the washing machine — outside the zoo?) (ref: game/audio/sound_bank.gd:91; data/sounds.json:447-451)
154. When a Teammate is knocked down, then the Throw's own sounds (throw release, bounce) are the Throw piece's; this piece adds only the sounds above. (zoo) (ref: docs/migration/old-details-backlog.md:15-17)
155. When a Guest's machine plays the knockdown sound, then it plays at the event's point from the Host's event (every machine plays the cue). (zoo) (ref: game/world/flight_rules.gd:359)
156. When a knock rumble is asked for with no pad plugged in, then nothing buzzes but the last buzz is still noted for tests. (zoo) (ref: game/player/pad_rumble.gd:18-27)

## Invariants

1. Only the Host decides a knockdown, a drag, a wash and a struggle's outcome. (ref: game/world/flight_rules.gd:195, 333)
2. `down` is one number per player, counted down by every machine's own clock; a Guest does not wait for the Host to stand up. (ref: game/core/game.gd:1244)
3. The ragdoll is never drawn; the avatar copies its pose. (ref: game/player/ragdoll.gd:5)
4. The player's own body stays at the ragdoll's feet, so the avatar's synchronizer authority never changes. (ref: game/player/rig_knockdown.gd:28-29)
5. A knocked-down player cannot be knocked down again, nor hit by a second flight; the first Flight stops. (ref: game/world/flight_rules.gd:195-197)
6. A Guest's ragdoll is looks only; the Host's decides. (ref: game/player/ragdoll.gd:10-12)
7. A getting-up body is played by every machine itself, not synced. (ref: game/player/rig_knockdown.gd:155-163)
8. A body in the drum has no avatar, no capsule for a falling ragdoll, no hit, no grab. (ref: game/player/rig_knockdown.gd:188-192)
9. The knockdown never carries across a save. (ref: game/knockdown/knockdown_poses.gd:1-3)
10. Decided state lives on scene Parts; only the Host's answer to a Command writes it; prediction is looks only (project rule, port-only). (ref: CLAUDE.md "Rules only this project has")
11. A ragdoll has 1 bone per avatar bone; its bone count must equal the avatar's or a pose is ignored. (ref: game/player/ragdoll.gd:318-321)
12. A flaky knockdown test is a defect to rework (project rule). (ref: CLAUDE.md)

## Numbers

| Key | Value | Meaning | Ref |
|---|---|---|---|
| knockdown.min_charge | 1.0 | Throw charge that knocks | data/tuning/knockdown.json |
| knockdown.seconds | 5.5 | down time (decided, Q985) | same |
| knockdown.push_speed | 3.0 m/s | top of the body pushed | same |
| knockdown.high_kick | 0.5 | push factor from 0.5 (feet) to 1.5 (top) | same |
| knockdown.spin | 3.0 rad/s | turn at the body's edge | same |
| knockdown.joint_bend | 45 deg | swing; twist is half | same |
| knockdown.rise_time | 0.6 s | blend up | same |
| knockdown.wall_gap | 0.3 m | view stops short of a wall | same |
| knockdown.bounce | 0.05 | share of speed an item keeps | same |
| players.body_radius | 0.3 m (port Player.radius is 0.35) | capsule radius for hit and bones | data/tuning/players.json:8 |
| Ragdoll TOP / FOOT_GAP / EYE | 1.7 / 0.03 / 1.6 m | head top, lowest capsule gap, eyes | game/player/ragdoll.gd:17-21 |
| bone friction / linear damp / angular damp | 0.8 / 0.4 / 2.0 | game/player/ragdoll.gd:99-101 |
| bone mass | 1.0 each (default) | pull weight is the sum | game/player/ragdoll.gd:228-230 |
| guest smoothing | 12 per second | game/player/ragdoll.gd:49 |
| net.pose_rate | 20 per second | data/tuning/net.json:4 |
| layers | RAGDOLL 8, MATE 64, WORLD 1, STATION 2 | game/core/layers.gd |
| mate capsule | radius body_radius, height body height | rig_knockdown.gd:197-198 |
| inside-body check | 2 radii sideways, body height up | rig_knockdown.gd:78 |
| floor ray | 0.5 m up to 1.0 m down | rig_knockdown.gd:120 |
| drag.speed | 0.6 | data/tuning/drag.json |
| drag.hold_height / hold_behind | 0.4 / 0.6 m | same |
| drag.pull | 60 | same |
| drag.break_distance | 2.0 m | same |
| drag.struggle_presses | 10 (Space) | same |
| drag.scrape_every | 0.5 m | same |
| wash.door_reach | 1.5 m | data/tuning/wash.json |
| wash.seconds / slide / spin | 3.0 s / 0.35 s / 1.2 turns/s | same |
| wash.out_seconds / out_tilt / out_speed / out_lift / out_side | 2.0 s / 70 deg / 2.5 m/s / 1.5 m/s / 0.4 | same |
| wash.door_open / fade_out / fade_in | 1.0 / 0.4 / 0.6 s | same |
| door swing | 80 deg, shut 0.08 s, burst 0.05 s, close 0.5 s | wash_view.gd:67-72 |
| drum eye / blob | (0, 0.42, 0.12) / radius 0.085 | rig_wash.gd:9; wash_view.gd:63-66 |
| rumble knock | weak 0.6, strong 1.0, 0.5 s | data/tuning/pad.json:12-14 |
| sounds | knockdown 0 dB; drag_scrape -4 dB; wash_slam 0 dB; wash_slosh 0 dB loop | data/sounds.json:430-451 |
| release.predict_blend | 0.2 s | used for a Guest's bounce |
| All values | "placeholders" in the old tuning notes except knockdown.seconds | data/tuning/*.json `_note` |

## How the old ragdoll is built

- **Bodies.** One PhysicalBone3D per avatar bone, made in code. The avatar's bones are four: Root (the base over the feet, at 0), Spine0 (0.45 m up), Spine1 (+0.35), Spine2 (+0.32); chained Root-Spine0-Spine1-Spine2 (read from `assets/avatar/avatar.glb`; `tools/blender/make_avatar.py:39-42, 90`). The body has no limbs: feet (FootL, FootR) are separate nodes.
- **Shapes.** Each bone is a capsule, radius 0.3 m, from half a radius under its joint to half a radius over the next; the top bone ends at 1.7 m. So the ragdoll is four stacked capsules, about 1.7 m tall.
- **Skeleton.** The old code builds a new Skeleton3D copy (names, parents, rests read once from the avatar scene) and a PhysicalBoneSimulator3D under it. It is a hidden helper, not the avatar's own skeleton. The avatar copies its bones' world poses every frame.
- **Joints.** Cone joints with swing 45 degrees, twist 22.5, one per non-root bone. Root has none. Joint rotation (0, 0, 90 degrees) so twist runs along the body.
- **Who simulates.** The Host only, with physics_bones_start_simulation. Layers: its own layer, mask WORLD, STATION, RAGDOLL, MATE.
- **What is sent.** Per knocked player: 4 bones x 20 bytes, world position and rotation, from the Host to every Guest, with the avatar poses, 20 times a second, unreliable ordered, channel 1. Nothing is sent during the rise. A joiner's roster entry carries the same bytes once, plus `down`, `dragged_by`, `drum`.
- **Guest side.** Bones are teleported to a target pose and eased at 12 per second; never simulated.
- **Pull.** A drag applies a central impulse to Root each physics tick, spring 60 and damping 2 times its square root, times the summed mass times delta.
- **Cost.** The old knockdown code is about 1,840 lines (catalogue B35).

### What Godot 4.7's PhysicalBoneSimulator3D / PhysicalBone3D would need from the avatar skeleton

(Written from the old code and Godot's node set; none of this was run in 4.7 here. Test before building, as Q2225 says.)
- A Skeleton3D with the four bones and a PhysicalBoneSimulator3D child. The old code already used both, but hand-made in code. Q2225 asks for the Godot-native way: author the PhysicalBone3D nodes in the Looks scene (editor "Create Physical Skeleton"), with capsule shapes and cone joints set in the inspector and the numbers in a typed Resource.
- Only four bones means a stiff spine: the body folds in at most three places by 45 degrees each. It cannot flail limbs. If the designer wants a floppier fall, the avatar needs more bones (a new Blender step). Four bones and 3 joints are the same as the old game.
- The imported avatar's Skeleton3D must keep the bone names Root, Spine0, Spine1, Spine2 and the rests; the rest rotations are a degree or two off upright (the old code puts bodies upright and ignores that).
- The bones are skinned already (every vertex has up to two bone weights). A physical simulation drives the bones directly, so the avatar needs no extra skin work.
- Jolt supports cone-twist joints; limits are set by swing_span and twist_span on each PhysicalBone3D. Bone sync needs a plan: either a MultiplayerSynchronizer property carrying the 4 world transforms (a packed array, well under the 1,350 B cap) with the setter driving the Guest's follow, or Godot's sync of the bones themselves. Not tested (coop-structure section 8).
- The ragdoll must not change the avatar's authority: keep it a separate Host-owned node spawned on the hit (coop-structure section 3), or a Looks child that only the Host simulates while the avatar's synchronizer keeps the player's pose.
- Physics interpolation of bones (the old code reads `get_global_transform_interpolated`) must be kept so 30 ticks does not look jerky.
- The old collision exceptions (own capsule, other bones, MATE capsule of an overlapping Teammate, the dragger) have to be re-made.

## Already in the port

- `game/parts/avatar/avatar.gd`, `avatar.tscn`, `avatars.gd`: an Avatar is a capsule mesh (radius 0.3, height 1.7) whose position and yaw sync from the owner at 20 a second (`replication_interval` 0.05); a Guest glides at 15 per second. No skeleton, no bones, no ragdoll, no `down` state.
- `game/player/player.gd`: movement, crouch, charge ring (`charge_time` 1.2 s, `tap_charge` 0.15), `_throw()`. No full-charge flag, no `frozen` for a knockdown, no `down`. `Player.radius` is 0.35 against the old 0.3.
- `game/hands/`: Hands, HeldView, HandsTuning with the charge numbers; the Throw sends a charge to Hands. There is no hit test against a player body and no thrown Pair or Sock hitting an Avatar.
- `game/parts/session.gd`, `command.gd`, `part.gd`, `carriable.gd`: the Command seam and the Host. No Down, Drag or Wash Part.
- `game/zoo/zoo_net.gd`, `game/zoo/stations/`: no knockdown station.
- `assets/avatar/avatar.glb` is not in the port yet (there is no `assets/avatar/`); the avatar's rig "moves to the front of the asset port" (Q2225).
- Pad rumble, the sound events `knockdown`, `drag_scrape`, `wash_slam`, `wash_slosh`: not in the port (M1.1 sound; Q2376 puts the knock rumble and teammates' sounds in M0.6).

## Questions for the designer

1. **Scope of drag and wash in M0.6.** Q2225 says "full knockdown". Drag needs only the avatar and a second player (zoo-ready). Wash needs the basement washing machine, the door and the porthole view, which the port does not have. Options: (a) knockdown only; drag and wash at M5 with the machine; (b) knockdown and drag, no wash (recommended: drag and struggle are all zoo-able); (c) all three, with a small stand-in machine in the zoo.
2. **Who can knock down in the zoo.** Only Socks and Pairs exist in the port. Do the Cat, lantern, Radio, Beeper and Guide card knock when they arrive, or only at their own milestone?
3. **Who cannot be hit.** Keep the old exemptions (the thrower, someone already down, someone in the drum, an Elevator rider)?
4. **Does the knocked player keep what they hold?** The old game keeps Hands but drops a worn backpack and spills a Hamper. Keep (Socks stay in the Hands), or drop them too?
5. **Immunity after getting up.** The old game has none (you can be hit again the moment you stand; a dragged player cannot be grabbed during the 0.6 s rise). Keep, or add a short immunity (a number)?
6. **Getting-up look.** Old: a 0.6 s smoothstep blend, facing the way the player faced, no bounce or hop (P105 lists "getting up facing, bounce" as open). Add a hop or bounce, or turn them to face where the knocking Throw came from, or keep?
7. **Struggle count display.** Old: Space, 10 presses, hint "Mash: Struggle [Space]", no count shown (P105). Show a count or a bar to the dragged player, or keep none?
8. **Knocked view.** Old: the camera rides the head, no fade or overlay, HUD stays. Add a fade, a vignette or dizzy tilt, or keep?
9. **Ragdoll body feel.** Four stiff capsules with 45 degree joints is what the old game had (all values are placeholders). Keep, or does the designer want a floppier body (more bones means a new avatar from Blender)?
10. **Knock sound.** The old "knockdown" sound is three synth candidates, none picked. Pick a sound now in M0.6, or keep the first placeholder until M1.1?
11. **Rumble for a Teammate's knockdown.** Old: only the knocked player buzzes (and the dragged one). Keep? Also should the thrower get a "hit" buzz?
12. **A left click on a lying body wins over a Sock or Station under the crosshair.** The old game asks "Keep that?" and was never answered. Keep?
13. **Message "X knocked you down".** Keep the old line, reword, or drop?
14. **The mirror body and the own body.** The old game drew a mirror body and an own body for the local player, all in the ragdoll pose. Does the port's local player see their own body when knocked down (looking down at themselves)?
