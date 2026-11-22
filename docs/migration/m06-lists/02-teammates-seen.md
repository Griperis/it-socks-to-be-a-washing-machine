> Draft behaviour list for M0.6 (Q2436), written from the reference on 2026-11-22; for the designer to approve. Answered 2026-11-22: questions 1-5 and 7 by Q2450-Q2455; 6, 8, 9 open.

# M0.6 piece: Teammates seen

Everything a player sees and hears of another player (a Teammate, drawn as their Avatar). Draft for the designer; the designer drops lines.
Old game = `reference/it-socks/` at v0.1.1. Paths under `game/` and `data/` in refs are inside it unless they start with `port:`.
Short refs: AV = `game/player/avatar.gd`, RIG = `game/player/rig.gd`, HV = `game/hands/held_view.gd`, HA = `game/hands/hold_anchor.gd`, PL = `game/player/player.gd`, SI = `game/audio/sound_installer.gd`, AJ = `data/tuning/avatar.json`.
Excluded: the knockdown ragdoll (another agent; its hooks are at the end of the list), the first-person own body and the mirror body (the local player's own view), the Ping and the wheel (only the hooks they need from the Avatar), the lobby and name entry.

## Behaviour list

### A. The pose a teammate sends and how it is drawn

1. When a player moves, then every other machine learns their position (x, y, z), yaw, pitch, crouch, the id of the player they stand on, the offset from that player, climbing and suction: 12 numbers. (ref: game/player/rig.gd:544-553)
2. When a Guest sends its pose, then it goes at 20 a second, unreliable, ordered on channel 1; the Host relays everyone's poses to every Guest. (ref: data/tuning/net.json:4, game/net/streams/pose_stream.gd:71-84) (changed by Q2223: the new avatar updates every frame, not 20 a second)
3. When a teammate's pose arrives for the first time, then their body stands there at once, with no glide from the spawn point, and their crouch is set at once. (ref: game/player/rig.gd:532-535)
4. When a late joiner arrives, then every other avatar is already where its player stands (no flash at the origin). (ref: docs/migration/coop-structure-for-the-port.md section 3 item 8; old: game/net/session.gd `_welcome` carries the pose)
5. When a teammate stands or walks, then their body eases toward the newest pose every frame; position, yaw (shortest way round) and pitch each move `min(1, 12 * delta)` of the way. (ref: game/player/rig.gd:564-570) (changed by Q2223: every frame, light easing, an intended difference; the number is the designer's, see Questions)
6. When a teammate crouches or stands, then their crouch weight moves toward 0 or 1 at 6 a second (not 12). (ref: game/player/rig.gd:572)
7. When a teammate is far from their last pose by a jump (a respawn, a lift), then the old body glides across the whole distance; nothing snaps. (ref: game/player/rig.gd:564-570; AV:45 TELEPORT only guards the waddle and squash)
8. When a teammate is on another player's back, then their position is that player's drawn position plus the sent offset every frame, so they ride the carrier's eased motion rigidly; yaw and pitch still ease on their own. (ref: game/player/rig.gd:566-570, 718-724) (needs the stacking piece)
9. When the player they stand on is no longer known on this machine, then the avatar eases to the absolute sent position instead. (ref: game/player/rig.gd:566-568)
10. When a rider stands on a back, then they stay crouched (the rider stands lower) and the back disc sits 0.3 m under the carrier's top. (ref: game/player/player.gd:771-779, data/tuning/stacking.json ride_sink) (needs the stacking piece)
11. When a teammate's pose says climbing, then their avatar plays the climbing pose and `climbing` follows the pose flag (pose[10] above 0.5). (ref: game/player/rig.gd:303, 429-430) (needs the Grotto ladder)
12. When a teammate's pose says their vacuum suction is on, then every machine shows and hears the suction at their nozzle. (ref: game/player/rig.gd:556-558, game/devices/sock_vacuum_view.gd:1165-1171) (needs the Sock vacuum, hook only: the pose carries the flag)
13. When a player's body is drawn on another machine, then it is not physics-interpolated; its parts move every frame on the body the player draws between ticks. (ref: AV:152-154) (the old body glided between physics ticks, game/player/player.gd:741-751)
14. When a teammate's body is drawn, then it never reads input and never aims on this machine; it is a puppet. (ref: game/player/player.gd:118, 375-376; RIG:386-393)
15. When a player's own machine draws their avatar, then it is not drawn there (the own view is the eyes, hands and, below the eyes, the belly). (ref: AV:22-25) (the own belly body is another piece)
16. When a teammate leaves, then their avatar goes at once and their Hands drop where they stood (Q248, Q295). (ref: docs/migration/digests/digest-core-and-coop.md "Spawns, saves, joining and leaving"; Hands is another piece, this line only removes the avatar)
17. When a cutscene plays, then teammates' avatars are not drawn on this machine. (ref: game/player/rig.gd:133, 352-357, 391) (needs cutscenes, M4)
18. When a teammate is inside the washing machine's drum, then their avatar is hidden (a blob tumbles instead). (ref: game/player/rig_wash.gd:26-28) (needs Wash, hook only)
19. When a teammate rides in the Elevator car, then their avatar is curled forward (`set_curl`) and shrunk, and the look still bends it on top. (ref: AV:547-554, data/tuning/ride.json curl 70, scale 0.33) (needs the Elevator, hook only)

### B. The avatar's body and what is derived locally (nothing of this is sent)

20. When an avatar is made, then its parts (body, pupils, points, clothes) are children of a Body node that bobs and sways; the two feet are children of the avatar and stay on the floor. (ref: AV:59-61, 162-184)
21. When a teammate walks, then the speed along the floor is measured from how far the drawn body moved this frame (x and z only), smoothed over 0.1 s, so the waddle holds at any frame rate. A move over 1 m in one frame counts as a teleport (zero speed). (ref: AV:41-45, 763-771)
22. When the smoothed speed rises, then `walk` (0 still, 1 full waddle) moves toward `speed / 3.0` (clamped 0..1) at 4 per second. (ref: AV:772, AJ walk_speed 3.0)
23. When a teammate walks, then the waddle phase advances by `speed * delta / 0.9 * TAU` (one full waddle per 0.9 m walked). (ref: AV:773, AJ stride)
24. When the waddle turns, then the left foot rocks about x by `22 deg * walk * sin(phase)` and about z by `8 deg * walk * sin(phase)`; the right foot rocks the other way about x and the same way about z. (ref: AV:781-784, AJ foot_swing, foot_roll)
25. When a teammate walks, then the Body rises `0.035 m * |sin(phase)| * walk` with each step. (ref: AV:785, AJ bob)
26. When a teammate walks, then the Body rocks side to side about z by `3 deg * sin(phase) * walk`. (ref: AV:786, AJ sway)
27. When the rocking turns over (a foot comes down), then it counts as a step, but only if `walk` is above 0.3 and it is not the first half-cycle seen. (ref: AV:775-780) (the step only feeds the Trail footprint; the old teammate made no step sound, see D)
28. When a teammate stands still, then `walk` falls to 0 and the feet settle flat. (ref: AV:772, 781-785)
29. When a teammate crouches, then the Crouch shape key on the body (and on the worn clothes) goes to the crouch weight, and the pupils, HoldPoint, Head and HatPoint move by their `crouch_offset` times that weight. (ref: AV:529-537, 589-598) (needs the avatar model: shape key Crouch and the extras)
30. When a teammate crouches, then the feet do not crouch. (ref: tools/blender/make_avatar.py:30-31) (needs the avatar model)
31. When a teammate looks down or up, then the top of the sock bends: straight down curls `36 deg` forward over the belly, straight up leans back `24 deg`, in between by the pitch share (pitch / 85 deg). (ref: AV:557-561, AJ bend_down 36, bend_up 24, PL:37 PITCH_LIMIT)
32. When the look pitch changes, then the bend eases toward it: `lerp(at, want, min(1, delta * 8))` per frame, and does not run when within 0.001 deg. (ref: AV:751-756, AJ bend_speed 8)
33. When the bend runs, then the three spine joints each turn a third of the bend about the creature's x, pivoting where the Crouch took each joint, so crouch and bend combine; the feet stay planted. (ref: AV:564-574, 578-586) (needs the avatar model: Armature Root, Spine0-2, extras `bend_crouch_offset`)
34. When the bend runs, then the pupils, HoldPoint, Head (the name tag) and HatPoint, and the worn hat and clothes, ride the bones their `bend_weights` name. (ref: AV:589-620) (needs the avatar model: extras `bend_weights`)
35. When a teammate's pitch is read, then it is the eased pitch, so the bend never snaps on a pitch packet. (ref: game/player/rig.gd:302, 569-570)
36. When a teammate jumps (rises over 3 m/s, measured from the drawn height smoothed over 0.05 s), then the whole avatar stretches tall by 20 % at takeoff, keeping its volume (narrower as it is taller: width = 1/sqrt(height)), scaled about the feet. (ref: AV:703-737, AJ squash_stretch 0.2, squash_takeoff_speed 3.0, squash_smooth 0.05)
37. When a teammate falls and stops, then the avatar squishes flat on landing by `45 % * clamp(fall height / 1.5 m, 0, 1)`; no squish under a 0.15 m fall; the fall height is `fall speed squared / (2 * gravity)` with gravity 20 m/s2; a "stopped" is the smoothed rise above -1 m/s. (ref: AV:717-725, AJ squash_squish 0.45, squash_full_fall 1.5, squash_min_fall 0.15, data/tuning/players.json gravity 20)
38. When the stretch or squish is set, then it springs back as a damped spring: 3 swings a second, damping 0.35. Integration is `speed += (-w*w*squash - 2*damping*w*speed) * delta`, `w = TAU * 3`. (ref: AV:726-730, AJ squash_freq 3.0, squash_damping 0.35)
39. When a squash is under 0.0005, then the scale is exactly 1. (ref: AV:733-737)
40. When a teammate climbs the ladder, then the squash resets (rungs are not jumps). (ref: AV:704-706) (needs the Grotto ladder)
41. When a teammate is a ragdoll, then no waddle, bend, climb or squash runs and the squash is reset; the pupils still run. (ref: AV:686-696)
42. When the avatar scales for the squash, then the teammate's held items scale with it (they hang from the HoldPoint). (ref: AV:733-736, HV:120-129) (derived; list so the designer can drop it)

### C. Eyes, pupils, idle

43. When another player is within 6 m of a teammate's body, then their two pupils turn to that player's eyes (the player's feet plus the body height minus 0.1 m); the nearest wins; the teammate looks at every other player, including the local one. (ref: RIG:470-485, 301, AJ look_range 6.0, game/player/player.gd:36 EYE_BELOW_TOP 0.1)
44. When that target is behind the creature (further than 100 deg off the pupil's rest), then it is not looked at and the idle drift runs. (ref: AV:49, 926-929)
45. When a pupil turns, then it stays within 28 deg of its rest (the model allows about 30). (ref: AV:916, 930-933, AJ look_max 28)
46. When a pupil follows, then its look slerps toward the aim at `min(1, delta * 6)` per frame. (ref: AV:918, 934, AJ look_speed 6.0)
47. When nobody is near, then the pupils drift: every `1.6 s * random(0.6 to 1.4)` a new idle offset is drawn, up to +-8 deg sideways and +-4 deg up or down. (ref: AV:912-915, AJ wander_time 1.6, wander 8.0)
48. When an avatar is made, then its idle random numbers are seeded from the player's name, so the same player idles the same way each time, two players differently. (ref: AV:161)
49. When the avatar bends, then the pupils turn with the bend and their own look is turned inside it. (ref: AV:922, 935)
50. When a teammate is the only other player, then the pupils look at the local player; when two others stand near, then the nearest one, not the one looking at them. (ref: RIG:472-485; open question multiplayer/20 in docs/migration/digests/digest-core-and-coop.md, line 268)
51. When no player is a teammate (solo), then the pupils drift only. (ref: RIG:472-485)
52. Eyes do not blink and the googly eyes do not wobble apart from the pupil drift; there is no other idle animation (no breathing, no yawn, no look-around). (ref: AV:686-696, whole file) (kept as the old; a "pupil wobble" is the drift above, Q502, Q503)

### D. What a teammate holds, drawn at their HoldPoint

53. When a teammate holds items, then their Hands hang from the avatar's HoldPoint (a HeldView worn instead of the camera), true size, no arms. (ref: HV:11-13, 118-130, RIG:392, HA:11-16, docs/migration/digests/digest-core-and-coop.md line 210 Q279, Q280, Q328)
54. When a teammate holds several items, then the active one hangs exactly at the HoldPoint and the others cluster close round it: each further one a step `[0.07, 0.02, 0.05]` times its tucked index plus one, to the left, then right, then left (x sign alternates by tucked index). (ref: HV:338-344, data/tuning/held.json worn_step)
55. When a teammate holds a loose Sock, then it hangs by its cuff, toe down, its side to the front: `Basis(UP, 90 deg) * Basis(BACK, -90 deg)`, at the slot plus `hang.x * half` where half is the Sock footprint x times its size scale. (ref: HV:449-453)
56. When a teammate holds a Pair, then the ball (true size, no 1.6 ball scale of the own view) hangs just under the slot: `slot + DOWN * ball radius`. (ref: HV:444-448)
57. When a teammate's held items change (a pick, a drop, a cycle, a hand-off), then each item glides to its new place with `1 - exp(-14 * delta)` per tick (the follow rate). (ref: HV:478-481, data/tuning/held.json follow_rate 14)
58. When a Hands is first worn (a teammate appears or the avatar is rebuilt), then every item is placed at once, no glide. (ref: HV:121-129)
59. When a teammate picks a Sock, then it flies up from where it lay to their HoldPoint over 0.3 s, smoothstep eased, on a hop of `0.18 * 4u(1-u)` metres, turned from a random flat yaw to its place. (ref: HV:285-296, 483-492, RIG:281-283, data/tuning/cloth.json pick_time 0.3)
60. When a teammate's pick makes a Pair, then no paired moment plays (the ball is at their hand at once, once it has flown in) and a small sparkle burst plus a ring plays at their hand when it arrives: 20 particles, size 0.035, speed 1.0, 0.55 s, ring 0.3, ring width 0.18, ring 0.35 s, ring alpha 0.8, white share 0.35, in the Design's tint. (ref: HV:279, 289-290, 503-512, data/tuning/paired.json mate_*, burst_white, ring_*)
61. When a teammate's Sock is held and they move, then its cloth swings with their movement (the actor's motion source is the avatar). (ref: HV:266)
62. When a teammate turns the held item (R) or zooms (G), then others see nothing: the turn spin stays 0 and the zoom factor is none for a worn Hands. (ref: HV:404, 463-464, 523-526) (open old question P100 "turn shown to a teammate"; Questions Q-b)
63. When a teammate crouches, then every body-frame held kind goes down with the whole crouch and never lower than `floor_clearance` 0.25 m over the feet; the HoldPoint itself goes down by its `crouch_offset`. (ref: HA:111-114, data/tuning/hold.json floor_clearance; Q1104)
64. When a teammate holds a thing of a body-frame kind (a gift box, a Part, a bin, a hamper, a vacuum container, the cat, a pairing machine), then it is drawn in front of the body at the kind's `at`, turned as the body faces, not at the HoldPoint. (ref: HA:110-114, data/tuning/hold.json gift, part, bin, hamper, vacuum, cat, machine) (needs those pieces; M4 and M5)
65. When a teammate holds a view-frame kind (the vacuum nozzle, a hand), then it is drawn at the HoldPoint with the kind's facing ("aim" toward their aimed point). (ref: HA:115-125, hold.json nozzle, hand) (needs the Sock vacuum)
66. When a teammate holds a hand-frame kind (Guide card, lantern, Radio, Beeper, book), then it is drawn at the HoldPoint at the kind's `worn` and `worn_turn` (lantern with a pivot and a pendulum swing, lit for everyone who sees it). (ref: HV:348-355, hold.json guide, lantern, radio, beeper, book) (needs those pieces; later milestones)
67. When a teammate holds a Sock whose mate is held by the local player, then the Held X-ray shows both mates through walls. (ref: RIG:515-525, Q252, Q486) (needs the X-ray, M4)
68. When a teammate aims a pairing machine, then their held machine faces their aim. (ref: HA:121-124) (needs the pairing machine)

### E. Releases and throws as others see them

70. When a teammate charges a Throw, then others see and hear nothing (no ring, no wind-up, no charge sound; `throw_charge` is not a teammate cue). (ref: game/hands/thrower.gd:111-117, SI:10) (the avatar has no Throw pose and no arm; none existed in the old game)
71. When a teammate Throws, then the item model starts from the avatar's HoldPoint as drawn and catches up to the true flight (which flies from their eyes) over `avatar.teammate_throw_blend` = 0.2 s; the flight itself is the true one. (ref: game/world/flights.gd:147-158, AJ teammate_throw_blend 0.2) (kept by Q2226)
72. When a teammate Throws, then the Host's flight shows on a Guest about 0.1 s behind the Host's newest rows. (ref: game/world/flight.gd:38 STREAM_LAG 0.1) (the flight is another piece)
73. When a teammate Throws on a Guest, then the model stops at the release point for about 3 ticks (50 ms) after the blend from the hand, before the flight shows. (ref: docs/migration/feature-catalogue.md line 440 X22) (kept by Q2226: "the short pause at release included")
74. When a teammate Drops, then the item flicks from their drawn hand to the release point in 0.1 s, smooth, keeping its turn, before the body takes over. (ref: game/world/flights.gd:147-157, data/tuning/release.json flick 0.1)
75. When a teammate shelves a Pair, then it flies from their HoldPoint into the drawer and a sparkle burst plays (a teammate's shelving flight and sparkle burst: M0.6). (ref: game/player/rig.gd:698-707 `item_transform`, game/core/main.gd:1159, docs/migration/decisions.md Q2283, Q2316)
76. When a teammate hands an item to the local player (a Hand-off), then it flies from the giver's drawn hand into the receiver's Hands. (ref: game/ui/teammate_news_installer.gd:38-43, RIG:281-283) (needs the Hand-off piece)
77. A teammate's Throw does not move their avatar (no lunge, no recoil, no squash, no lean). (ref: AV whole file: no throw state)
78. When a teammate's Throw is full charge and hits a player, then a knockdown follows. (ref: game/hands/thrower.gd:141-147) (the knockdown agent)

### F. Look, colour, name

79. When an avatar is made, then the `player` surface takes the player's colour (a plain white base tinted) and the `trim` surface (cuff stripes, heel patch, feet) takes that colour darkened by 0.35; the eyes and pupils keep their colours. (ref: AV:364-382, data/tuning/avatar.json trim_darken 0.35, Q496) (needs the avatar model)
80. When a player picks another colour, then their avatar and their name tag change at once on every machine. (ref: AV:386-390, game/core/main.gd:574-582)
81. When a colour is taken, then nobody else may have it; eight colours: coral `#f08a7a`, teal `#4fb3a9`, mustard `#e3b448`, lilac `#b49ad8`, mint `#8fd6a8`, sky blue `#86bfe8`, rose `#e89ab4`, charcoal `#55595f`; up to 4 players. (ref: data/tuning/players.json colours, max) (the roster and colour choice are another piece; the tint is here)
82. When an avatar is made, then a name tag floats over the head: a billboard Label3D, font size 40, pixel size 0.004, outline size 10, colour the player colour lightened by 0.35, outline `UiBits.OUTLINE`. (ref: AV:201-212)
83. When an avatar is made, then the tag sits 0.25 m above the Head empty and is a child of the Head, so it crouches and bends with the body. (ref: AV:36, 211-212)
84. When a teammate wears a hat, then the tag lifts to `0.25 m + the hat mesh's top height`, so a tall hat never hides the name. (ref: AV:437-439) (needs the wardrobe, M4?) (open old question: keep the tag at one height? name tag height, P105)
85. When a teammate has no name, then no tag is made. (ref: AV:201)
86. When a teammate is far, then the name tag is a world-space billboard (pixel size 0.004): it shrinks with distance and is hidden by walls. (ref: AV:204-207)
87. When a teammate joins or leaves, then everyone else sees "<name> joined" / "<name> left" in that player's colour under the crosshair, 2 s, a later message replacing an earlier one. (ref: game/core/main.gd:1060-1065, Q492)
88. When a teammate wears a hat or clothes piece, then the hat sits on the HatPoint in its own fixed colours (no piece takes the player colour) and the clothes are skinned to the avatar's bones, with the Crouch shape key following the crouch. (ref: AV:393-440, Q330, Q331) (needs the wardrobe, M4?)
89. When a look changes, then every machine's copy changes at once; one hat slot, one clothes slot, one socks slot, one trail slot, each may be empty. (ref: AV:400-440, game/player/wardrobe.gd:29) (needs the wardrobe, M4?)
90. When a teammate wears Socks, then a little sock sits over each stubby foot, under the Foot node, so it waddles with the foot and stays planted when the body crouches. (ref: AV:448-472) (needs the wardrobe, M4?)
91. When a teammate wears a tail or wings or floppy hat, then it swishes: walking, with each step, a little behind the sway (`sin(phase * rate - 0.9) * walk * 1.0`); standing, slowly (`sin(clock * 1.8) * (1 - walk) * 0.3`); Bee wings flap 4 times a waddle. (ref: AV:796-820, AJ swish 1.0, swish_idle 0.3, swish_idle_speed 1.8, swish_rate bee_wings 4) (needs the wardrobe, M4?)
92. When a teammate wears a rare piece, then its small touch plays on every machine (a bob, a sway, a glow, a few drops). (ref: game/player/piece_touch.gd:1-20, AV:492) (needs the wardrobe, M4?)
93. When a teammate wears a Trail, then each step leaves a mark on the floor under the foot, 6 mm above the floor, at the avatar's yaw, drawn on every machine from the steps (nothing is sent but the look). (ref: AV:864-885, 778) (needs the wardrobe, M4?)
94. When a teammate's colour or look changes while they ride, then it changes for riders and carriers alike (a riding player's look stays in sync, Q1134). (ref: digest line 211)
95. Teammates cast shadows like any body; the own belly does not. (ref: AV:225-226) (the own belly is another piece)

### G. Outline, aim and blocking

96. When the local player holds an item and aims a teammate within hand-off reach, then that teammate's avatar is outlined (the Highlight): every visible mesh of the avatar except the held items, the Trail and the outline's own copies. (ref: game/player/rig_aim.gd:163-170, AV:497-511, Q507) (needs the Hand-off piece)
97. When the line from the local player's eyes meets a teammate within reach (2.5 m, shortened by the first wall), then the teammate is "aimed": the closest approach of the aim line to the segment from `feet + 0.1 m` to `feet + body height` is within the body radius 0.3 m, and the entry point counts, not the middle. (ref: game/player/rig_aim.gd:232-253, data/tuning/players.json body_radius 0.3, reach 2.5)
98. When a teammate stands in front of a Station, then the local player has no [E] target, no outline and no click on it; Socks and floor Pairs behind them are still aimed, and a ping lands behind them. (ref: digest line 205, Q508) ("Keep it so?" is still open; the zoo's Stations are Cabinet, drawers, doors)
99. When two players are in the Elevator car, then neither blocks the other's aim. (ref: game/player/rig_aim.gd:238-240) (needs the Elevator)
100. When a thrown or dropped item touches a teammate's body (a sphere against the body cylinder: feet minus radius to feet plus height plus radius, within 0.3 m + radius), then it counts as a hit. (ref: game/player/rig.gd:687-692) (the hit rules belong to Throw/Hand-off/knockdown)
101. When a player is pinged, then the pinger's Head gets a speech bubble beside it (`head_side` 0.35 m, `head_lift` 0.45 m, 3 s) and a pinged teammate is outlined in the pinger's colour through walls for 4 s; on the pinged teammate's own machine nothing is drawn on them. (ref: game/ui/pings.gd:1-12, 176-190, data/tuning/ping.json) (needs Pings, M5; hook: a `Head` node on the avatar)

### H. Standing, pushing and stacking bodies (what the others can see them do)

102. When two standing players are nearer than 0.6 m, then each machine pushes its own player out, `(0.6 - gap) * 8` m/s deeper the overlap, so avatars never stand inside each other and never bump hard; exactly on each other, the lower id goes one way, the other the other. (ref: game/player/rig_stack.gd:144-168, data/tuning/players.json push_apart 0.6, push_rate 8.0, Q263)
103. When one stands on another's back or climbs, then the push is skipped (their heights differ by more than half a crouch). (ref: game/player/rig_stack.gd:157-158) (needs stacking)
105. Players spawn slightly apart at the washer spawn (`spawn_apart` 0.6 m). (ref: data/tuning/players.json spawn_apart, Q285) (the spawn point is another piece)

### I. What a teammate sounds like

106. When a teammate picks, pairs, drops, throws, shelves or buys, then the same sound as the own cue plays in 3D where they are: at their feet plus 1.2 m up, except shelving which plays at the drawer; teammate cues are exactly `pick`, `pair`, `drop`, `shelve`, `throw`, `buy`. (ref: SI:10, 41-52, game/audio/sfx.gd:251, Q246, Q290)
107. When a teammate's cue plays, then it is muffled behind a shut Door like any 3D sound (`bus_at`). (ref: game/audio/sfx.gd:214-217, 256-257)
108. When a teammate's cue plays, then it fades with distance: full inside 3 m, gone at 20 m (unit size, max distance); pitch jitter +-5 %. (ref: data/tuning/audio.json world_unit_size 3.0, world_max_distance 20.0, pitch_jitter 0.05)
109. When a teammate cycles, refuses, charges, pops a Pair, or opens the Upgrade menu, then others hear nothing (`cycle`, `refuse`, `throw_charge`, `pop`, `menu_open` are the player's own). (ref: SI:8-10, RIG:258-268)
110. When a teammate's step lands, jump, crouch or land happens, then the old game plays nothing for them: the footsteps, `land`, `jump`, `crouch` cues come only from the local player's body (a puppet's tick returns early and its cues are not connected). (ref: PL:375-376, RIG:258; game/player/player.gd:430-438, 551, 778) (changed by Q2376 and the backlog: "Footsteps ... Guests' footsteps must play spatially at their body": this is new in M0.6)
111. When a teammate walks on the floor, then a step plays every 1.4 m walked, `step_wood` or `step_tile` by the floor under them, spatial at their body. (ref: PL:436-438, data/tuning/audio.json step_distance 1.4; port: game/audio/footsteps.gd) (new, Q2376; the distance is measured from their drawn motion on the receiving machine, or from the pose)
112. When a teammate lands from a fall of 3 m/s or more, then `land` plays spatial at their body; a landing zeroes the stride. (ref: PL:428-431, data/tuning/audio.json land_speed 3.0) (new, Q2376)
113. When a teammate's jump leaves the floor, then `jump` is silent (the event has no pick) and crouching is silent (`crouch` is marked silent). (ref: data/sounds.json jump picks [], crouch silent true)
114. When a teammate is on a ladder, then the `climb` sound plays in 3D at their body plus 0.6 m as they grab it and at every 0.3 m they move up or down; picks `synth/climb_a`, `synth/climb_c`, -6 dB. (ref: RIG:406-426, data/sounds.json climb, data/tuning/grotto.json rung_gap 0.3, Q1120) (needs the Grotto ladder)
115. When a teammate wears a Trail or a glowing piece, then there is no sound for it. (ref: AV:864-885) (nothing to list; stated so the designer sees it)
116. A teammate has no voice lines; the only voices in the game are the talking washing machine's and the Old Tree's. (ref: data/sounds.json has no player voice event; data/tuning/voice.json)
117. When a teammate is knocked down, then others hear the `knockdown` event (no picks yet) and the pad rumbles "knock" on that player only. (ref: data/sounds.json knockdown, game/player/pad_rumble.gd:5-8) (the knockdown agent; Q2376 puts it in M0.6)
118. When a teammate's vacuum suction is on, then every machine hears it at the nozzle (`vacuum_motor`). (ref: game/devices/sock_vacuum_view.gd:1165-1171, data/sounds.json vacuum_motor, tools/11) (needs the Sock vacuum)
119. When a Guest hears a bounce, then it plays for them too (today only the Host plays them). (ref: docs/migration/old-details-backlog.md line 16) (not a teammate sound; listed because it is under M0.6 Co-op)

### J. Off-screen and through walls

120. When a teammate is off-screen, then nothing points to them: there is no marker, arrow or list for a plain teammate. (ref: game/ui/teammate_news_installer.gd:18-22, 25-36)
121. When the local player has Sole Mates with Mate Radar and a teammate holds the mate of their active Sock, then a hint arrow points to that teammate in their colour (arrow 34 px, margin 56 px, outline 3 px, at most 4). (ref: game/ui/teammate_news_installer.gd:25-36, data/tuning/hint_arrows.json) (needs Sole Mates, M4)
122. When the local player has the Held X-ray and a teammate holds the mate of a Sock, then that held mate glows through walls. (ref: RIG:515-525, Q486) (needs the X-ray, M4)
123. When a teammate is hit hard, then the local player sees "<name> knocked you down" only if it is the local player; nobody else gets a line. (ref: game/ui/teammate_news_installer.gd:56-60) (knockdown agent)
124. When a teammate buys an Upgrade, then everyone else sees "<name> bought <Upgrade>". (ref: game/ui/teammate_news_installer.gd:46-53, Q243) (needs Upgrades, M4)

### K. Hooks the knockdown ragdoll needs from the avatar (the ragdoll itself is another agent's)

125. The avatar offers `set_ragdoll(bones)`: with bone transforms (one per skeleton bone, Root and Spine0-2) it lays the creature there; with none it stands again. (ref: AV:627-654)
126. When the avatar is a ragdoll, then the waddle, the bend, the climb and the squash stop, the Body returns to rest and the feet return to rest. (ref: AV:637-646, 689-696)
127. The avatar offers `topple()` (degrees lying over), `toppled_toward()` (which way the head lies) and `height()` (the Head's height). (ref: AV:659-683)
128. The pupils, HoldPoint, Head (tag), HatPoint, hat and clothes ride along on the ragdoll's bones (`_place_points`); the held items stay at the HoldPoint. (ref: AV:589-598, 650-654)
129. A standing player has an upright capsule on the MATE layer (radius 0.3, height at least 2 radius, centred at the body height) that only ragdolls collide with; off while knocked down or in the drum. (ref: game/player/rig_knockdown.gd:190-199, game/core/layers.gd:23-35)
130. The owner's body stays at the ragdoll's feet while down, so the avatar's synchronizer never changes authority. (ref: docs/migration/coop-structure-for-the-port.md section 3 "Knockdown ragdoll")
131. The knocked-down state (`down`, `dragged_by`, `drum`) is decided state (a Part), not part of the pose. (ref: docs/migration/coop-structure-for-the-port.md section 3, game/knockdown/knockdown_poses.gd)
132. The avatar's skeleton has four bones (Root, Spine0, Spine1, Spine2); a physical-bone ragdoll made from it has four bodies. (ref: game/player/ragdoll.gd:1-5, 118-127; Q2225) (the model must keep these names; see model section)

## Invariants

- Only the owner writes their avatar's pose; the Host checks the sender and, in a setter on its copy, that every number is finite and inside the house bounds (30 m margin) before relaying. (ref: data/tuning/net.json pose_margin 30; docs/migration/coop-structure-for-the-port.md section 3 item 4)
- The pose rate limit of 60 a second per peer was the old guard; a synchronizer does not enforce it. (ref: data/tuning/net.json pose_limit 60; docs/migration/coop-structure-for-the-port.md section 2 note "Packet guard")
- Animation (waddle, bend, squash, pupils, steps, crouch weight) is derived on each machine from the drawn pose; nothing of it is sent. (ref: AV:7-12, 702)
- Decided state is not in the pose: Hands, down, drag, colour, look and name come from Parts or the roster. (ref: docs/migration/coop-structure-for-the-port.md section 3 items 5, 6)
- An avatar looks only: it never writes shared state and has no rule of play. (ref: CLAUDE.md "Decided state lives on scene parts")
- A teammate's held items are the Hands Part's state for that player; the avatar only draws them. (ref: docs/migration/coop-structure-for-the-port.md section 2 row "Hands and what a player carries")
- The creature stands on its feet, faces -z and is a child of the player's body; it turns with it. (ref: AV:5)
- Standing height 1.7 m, crouched 1.0 m, eyes 0.1 m under the top; the body radius is 0.3 m. (ref: PL:34-36, players.json body_radius)
- Teammates never speak, never emote with the body, never hold their arms out: no arms. (ref: AV:3, Q328)
- The same colour and look is shown to every machine, and a taken colour is refused by the Host. (ref: Q276, Q314)
- No teammate sound plays flat: a teammate's sounds are spatial from their body (Q246, Q290, Q2376).
- A flaky or per-machine-different look is not allowed to change play: teammate looks cannot move a shared body. (ref: docs/migration/coop-structure-for-the-port.md section 4 "ghost")

## Numbers

All old values, with their source. "Placeholder" in the old files means the old designer had not tuned it.

| Number | Old value | Source |
|---|---|---|
| Pose rate (old) | 20 per second | data/tuning/net.json:4 |
| Pose rate (new, Q2223) | every frame | Q2223; port avatar.tscn replication_interval is 0.05, to change |
| Pose limit per peer | 60 per second | data/tuning/net.json:5 |
| Pose margin outside the house | 30 m | data/tuning/net.json:6 |
| Pose follow (position, yaw, pitch) | `min(1, 12 * delta)` | RIG:564 |
| Port's follow | exponential, 15 per second (placeholder) | port: game/parts/avatar/avatar.gd:12-14 |
| Crouch follow | 6 per second, `move_toward` | RIG:572, 306 |
| Teleport threshold (waddle, squash) | 1.0 m in one frame | AV:45 |
| Waddle smoothing | 0.1 s | AV:43 |
| Walk full at | 3.0 m/s | AJ walk_speed |
| `walk` rise rate | 4 per second | AV:772 |
| Stride | 0.9 m per full waddle | AJ stride |
| Foot swing (x) | 22 deg | AJ foot_swing |
| Foot roll (z) | 8 deg | AJ foot_roll |
| Bob | 0.035 m | AJ bob |
| Sway | 3 deg | AJ sway |
| Step counted when `walk` over | 0.3 | AV:778 |
| Pupil range | 6.0 m | AJ look_range |
| Pupil max turn | 28 deg | AJ look_max |
| Pupil follow speed | 6 per second | AJ look_speed |
| Pupil look cone | 100 deg | AV:49 |
| Pupil idle drift | 8 deg (and 4 deg vertical) | AJ wander |
| Pupil idle period | 1.6 s times 0.6 to 1.4 | AJ wander_time, AV:913 |
| Eye height used (constant, not read) | 1.35 m | AV:47 |
| Look target height | body height minus 0.1 m | RIG:480, PL:36 |
| Bend down | 36 deg | AJ bend_down |
| Bend up | 24 deg | AJ bend_up |
| Bend speed | 8 per second | AJ bend_speed |
| Pitch limit | 85 deg | PL:37 |
| Squash stretch | 0.20 (placeholder) | AJ squash_stretch |
| Squash squish | 0.45 (placeholder) | AJ squash_squish |
| Squash full at fall | 1.5 m | AJ squash_full_fall |
| Squash min fall | 0.15 m | AJ squash_min_fall |
| Squash takeoff speed | 3.0 m/s | AJ squash_takeoff_speed |
| Squash smoothing | 0.05 s | AJ squash_smooth |
| Squash wobble | 3 per second | AJ squash_freq |
| Squash damping | 0.35 | AJ squash_damping |
| "Stopped falling" rise | above -1 m/s | AV:720 |
| Gravity (for the fall height) | 20 m/s2 | data/tuning/players.json gravity |
| Climb step share | 0.25 | AJ climb_step_share |
| Climb foot lift | 0.12 m | AJ climb_step |
| Climb toe tip | 20 deg | AJ climb_toe |
| Climb sway | 5 deg | AJ climb_sway |
| Climb blend | 5 per second | AJ climb_blend |
| Rung gap | 0.3 m | data/tuning/grotto.json rung_gap |
| Trim darken | 0.35 | AJ trim_darken |
| Name tag lift | 0.25 m over Head, plus hat top | AV:36, 439 |
| Name tag font size / pixel size / outline | 40 / 0.004 / 10 | AV:206-208 |
| Name tag colour | player colour lightened 0.35 | AV:209 |
| Belly cut / belly back (own view only) | 0.8 m / 0.22 m | AJ belly_cut, belly_back |
| Swish (walking / idle / idle speed) | 1.0 / 0.3 / 1.8 rad/s | AJ swish, swish_idle, swish_idle_speed |
| Swish rate | Bee wings 4 | AJ swish_rate |
| Swish phase offset | -0.9 rad | AV:814 |
| Trail mark lift | 0.006 m | AV:878 |
| Held follow rate | 14 per second | data/tuning/held.json follow_rate |
| Worn step | [0.07, 0.02, 0.05] | data/tuning/held.json worn_step |
| Pick fly time | 0.3 s | data/tuning/cloth.json:13 |
| Pick hop | 0.18 m | HV:490 |
| Mate burst amount / size / speed / time | 20 / 0.035 / 1.0 / 0.55 s | data/tuning/paired.json mate_burst_* |
| Mate ring size / width / time / alpha | 0.3 / 0.18 / 0.35 s / 0.8 | paired.json mate_ring_size, ring_width, ring_time, ring_alpha |
| Burst white | 0.35 | paired.json burst_white |
| Floor clearance (held body frame) | 0.25 m | data/tuning/hold.json floor_clearance |
| Teammate throw blend | 0.2 s | AJ teammate_throw_blend |
| Throw catch-up (own model) | 0.1 s | data/tuning/release.json catch_up |
| Drop flick | 0.1 s | release.json flick |
| Guest predict blend | 0.2 s | release.json predict_blend |
| Stream lag of a Host flight on a Guest | 0.1 s | game/world/flight.gd:38 |
| Pause at release (observed) | about 50 ms (3 ticks) | feature-catalogue X22 |
| Standing / crouched height | 1.7 / 1.0 m | PL:34-35 |
| Body radius | 0.3 m | players.json body_radius |
| Reach | 2.5 m | players.json reach |
| Push apart / push rate | 0.6 m / 8 | players.json |
| Spawn apart | 0.6 m | players.json spawn_apart |
| Players max | 4 | players.json max |
| Stacking: back radius / ride sink / climb reach / max high / carry speed | 0.3 / 0.3 / 0.9 / 3 / 0.5 | data/tuning/stacking.json |
| Elevator rider curl / scale | 70 deg / 0.33 | data/tuning/ride.json |
| Step distance | 1.4 m | data/tuning/audio.json |
| Land speed | 3.0 m/s | audio.json |
| World sound unit size / max distance | 3.0 / 20.0 m | audio.json |
| Pitch jitter | 0.05 | audio.json |
| Teammate cue height | 1.2 m over feet | SI:51 |
| Climb sound height | 0.6 m over feet | RIG:425 |
| Climb sound level | -6 dB | data/sounds.json climb |
| Teammate cues | pick, pair, drop, shelve, throw, buy | SI:10 |
| Ping head side / head lift / bubble | 0.35 m / 0.45 m / 3 s | data/tuning/ping.json |
| Ping highlight | 4 s, 30 m | ping.json |
| Joined / left message | 2 s | digest line 192 |
| Hint arrow size / margin / outline / max | 34 / 56 / 3 / 4 | data/tuning/hint_arrows.json |
| Trail, glow, touch numbers | per piece | data/tuning/wardrobe.json (needs the wardrobe) |

## Already in the port

- Avatar scene, one per player id, made by a spawner on every machine, the late joiner included: exists. (port: game/parts/avatar/avatars.gd, avatar.tscn)
- Position and yaw synced (20 a second, `replication_interval` 0.05, unreliable): exists; must become every frame (Q2223). (port: avatar.tscn:12-21)
- Glide to the newest pose, exponential 15 per second, position and yaw: exists as a placeholder; no pitch, crouch, riding, climbing or suction fields. (port: game/parts/avatar/avatar.gd:12-14, 47-50)
- Finite check on the incoming pose: exists in `_process`; the Host-side setter bounds check and relay guard: missing. (port: avatar.gd:41-43)
- Snap at spawn so a late joiner's avatars do not flash at the origin: exists. (port: avatar.gd:27-29, 56-61)
- Own avatar hidden and copying the local body: exists. (port: avatars.gd:63-66, avatar.gd:32-38)
- Avatar model: missing; the avatar is an orange capsule (radius 0.3, height 1.7). `assets/avatar/` does not exist in the port. (port: avatar.tscn:8-14; assets-inventory.md Avatar row)
- Colour tint, name tag, wardrobe, name from the roster: missing (no roster yet).
- Pitch, crouch weight, bend, squash, waddle, pupils, climbing pose, swish, trail: missing (need the model).
- HoldPoint, Head, HatPoint empties: missing (need the model; a capsule can carry plain Marker3Ds at first).
- Held items drawn on a teammate (worn HeldView): missing. HeldView draws only the local camera view (`hands.items_of(me)`, camera child), with no `wear()`. (port: game/hands/held_view.gd:1-60, 92)
- Per-player Hands state keyed by player id: exists (`items_of(by)`, `active_index(by)`). (port: game/hands/hands.gd:64-76)
- Throw hand for a teammate: `Hands.hand_of(by, dir)` builds the pose from `eyes_of(by)`, which for a Guest uses `eyes_fallback` 1.5 m, not their avatar; missing the HoldPoint-based start and the 0.2 s blend. (port: game/hands/hands.gd:352-373; docs/migration/m06-backlog.md "Co-op")
- Footsteps and land: exist for the local body only, flat. `Footsteps` is a child of the Player and calls `Sounds.play`; a spatial version at a teammate's body is missing. (port: game/audio/footsteps.gd; m06-backlog.md "Sound")
- Teammate cues: `Hearing.applied` plays `pick`, `pair`, `drop`, `throw`, `cycle` flat only for the player they are answered to (`own`); `shelve` plays at the drawer for everyone. A teammate's pick, pair, drop and throw in 3D is missing. (port: game/audio/hearing.gd:18-37)
- A `pick`, `pair`, `drop`, `throw` event is flat; `Sounds.play_at` refuses a flat event, so a spatial teammate version is needed (a new event or a second flag). (port: game/audio/sounds.gd:211-217, sound_catalogue.tres)
- World sound fade 3 / 20 m and 5 % pitch jitter: exist. (port: sound_catalogue.gd:12-17)
- Muffling behind a shut Door: exists in `Sounds.is_muffled`. (port: sounds.gd:153)
- `step_wood`, `step_tile`, `land`, `shelve` events: exist; `climb`, `jump`, `crouch`, `knockdown`, `vacuum_motor`, `buy`: missing. (port: game/audio/sound_catalogue.tres)
- Soft push between players, stacking back disc, ride: missing (port: game/player/player.gd has crouch and jump only).
- Highlight of a teammate for a hand-off, aim at a teammate, body-radius aim: missing; the outline exists for Socks and Stations. (port: game/outline/)
- Co-op zoo harness (`--host`, `--join`), Session gate with PROTOCOL 9: exists. (port: game/zoo/zoo_net.gd, game/parts/session.gd:30-34)
- Test that two avatars exist: partial (scene parts test). (port: tests/scene_parts_test.gd, tests/zoo_test.gd)
- Pose-based savepoint of each player's position: missing. (old: game/net/streams/pose_stream.gd:107-113)
- Joined / left message: missing.

## What the avatar model must provide

For the asset port of `avatar.glb` (old script `tools/blender/make_avatar.py`, 648 lines, no .blend; 4,048 tris; assets-inventory says 5 materials, the script lists 4: check on import).

Nodes, at the standing pose, creature faces -z, origin at the feet, centred, 1.7 m to the cuff rim:
- `Avatar`: mesh with surfaces in this order: `player` (white, roughness 0.85; the tinted body), `trim` (cream 0.98/0.92/0.82, roughness 0.8; cuff stripes and heel patch; tinted darker by code), `eye` (0.98/0.97/0.95, roughness 0.25; the domes). Shape key `Crouch` 0..1 squashes the body to 1.0 m, plumper in the middle; the eye domes ride down rigidly.
- `PupilL`, `PupilR`: meshes (surface `pupil`, 0.09/0.07/0.07, roughness 0.2). Node at the centre of the eye's sphere; at rest its -z points straight out of the eye; turned within about 30 deg.
- `FootL`, `FootR`: meshes (trim surface), pivot at the ankle, identity rotation; rock about x and z; they do not crouch. (They are in the first-person `feet.glb` too, same places.)
- `HoldPoint`: empty in front of the belly, right of centre.
- `Head`: empty at the top of the cuff (name tag, emoji bubble above).
- `HatPoint`: empty at the centre of the cuff's rim, tilted with the lopsided top.
- `Armature/Skeleton3D` with bones `Root` (still), `Spine0`, `Spine1`, `Spine2`, chained bottom up; the `Avatar` mesh skinned to it (every vertex by its rest height; eye domes rigid on `Spine2`). Shape keys first, skinning after.
- glTF extras on every node but the feet and body: `crouch_drop`, `crouch_offset` [x, y, z], `bend_weights` [Root, Spine0, Spine1, Spine2]. On the Armature: `bend_crouch_offset` [[x, y, z] per bone].
- No arms. No face animation.
- The knockdown ragdoll (Q2225) builds PhysicalBone3D capsules on these four bones (radius 0.3, cone joints); keep the bone names and rests; a finer rig is the ragdoll agent's decision.

Animations: none in the file. The old game does everything in code from the drawn motion (waddle, bob, sway, bend, squash, pupils, climb, swish). CLAUDE.md says state plays an AnimationPlayer in Looks; the waddle and bend are continuous from speed and pitch, so they may be an AnimationTree blend or stay as a small script on the Looks. That is the lead's call when the avatar scene is designed.

Other assets a teammate needs: the wardrobe pieces (hats on HatPoint in the HatPoint's frame; clothes skinned to the avatar bones with `Crouch`, `SwishL`, `SwishR`, `Touch` shape keys; leg socks `sock_l`, `sock_r` in the foot's frame) (needs the wardrobe, M4?), the sock and ball models for held items (exist in the port), name tag font (`UiBits.OUTLINE`).

## Questions for the designer

Only choices not already answered in `decisions.md`.

1. Easing of a teammate's body (Q2223 says "light easing"): keep the old `12 per second` (about a fifth of the way each 60 Hz tick), keep the port's placeholder `15`, or another number? The crouch follows at `6 per second`. (recommended: 12, as the old game, then judge by the strip)
2. A teammate who jumps far in one packet (a respawn, a lift, leaving the Elevator): glide across the house as the old game did, or snap when the jump is over about 1 m? (recommended: snap over 1 m, as the waddle already treats it as a teleport)
3. A teammate's steps and landing (new, nothing in the old game): the same sounds as the local player at full level, fading 3 m to 20 m, a step every 1.4 m? Or quieter than the own, or only the land? Jump and crouch stay silent as now.
4. Should a teammate's pick, pair, drop and throw be as loud as your own, or quieter? (old: same clip and level, in 3D at 1.2 m over their feet; recommended: same)
5. Should others see a teammate's held-item turn (R) and zoom (G)? The old game showed neither (open as P100). (recommended: no)
6. Name tag height: lift it over a tall hat (old), or keep one height? (decided as open in the old game; with no hats until the wardrobe, ask when M4 lands)
7. Pupils look at the nearest player (old). Prefer the player who looks at them, or the local player? (open in the old game, multiplayer/20)
8. Additions nobody asked for, for a report, not built: a wind-up cue on a teammate while they charge a Throw (a lean, a sound); a small squash at release; a blink; a wave or emote.
9. A teammate far away or behind a wall: nothing marks them (old). Keep, until Mate Radar and the X-ray (M4)?
