> Behaviour list for core/41 (player stacking and the soft push), written from the reference on 2026-11-23, for the designer to approve. Step 1 of the `migration-port` skill: nothing is built. The open choices are `[blocking]` Open follow-ups in `docs/llm/core/issues/41-player-stacking.md`.

# M3 piece 1: Player stacking (behaviour list, draft)

Words follow `GLOSSARY.md`. Paths are in `reference/it-socks/` (tag v0.1.1) unless they start with `game/` or `docs/` of the port (a line says "port" then). "Old" is the game at tag v0.1.1. A line is one thing the designer can keep or drop. Nothing is left out as minor. Abbreviations: **RS** `game/player/rig_stack.gd`, **PL** `game/player/player.gd`, **RIG** `game/player/rig.gd`, **T** `data/tuning/stacking.json` (placeholders all: max_high 3, carry_speed 0.5, back_radius 0.3, climb_reach 0.9, climb_clear 0.15, ride_sink 0.3) and `data/tuning/players.json` (push_apart 0.6, push_rate 8.0, gravity 20, jump_speed 5.5).

What it is: in co-op a player can walk or jump onto a Teammate's back and stand there, to reach what one player cannot (progression/10, Q652-Q656, Q670, Q671). The soft push between standing players (Q263) lives in the same old file and is listed here too (list 02 lines 102-103 point to it). Nothing in this piece is decided by the Host: it is each machine's own physics on the player's own body (see the co-op section).

Scope tags: **(zoo)** can be shown in the zoo with two players today; **(needs X)** waits for another piece.

## Behaviour list

### A. The back (what every player offers)

1. When a player exists, then they have a back: a flat disc (a cylinder 0.1 m high, radius `stacking.back_radius` 0.3 m) on its own collision layer BACK, that collides with nobody by itself (mask 0) and is met only by players. (zoo) (ref: RS:20-39; game/core/layers.gd:34; T back_radius)
2. When the physics frame runs, then the back sits `stacking.ride_sink` (0.3 m) below the top of the player's body, so standing it is 1.4 m over the feet and crouched 0.7 m. A rider therefore stands 0.3 m lower, in the cuff of the body under them, so stacks fit under the 2.6-2.7 m ceilings (Q670). (zoo) (ref: RS:46-48; T ride_sink; progression/19)
3. When the player under crouches or stands, then the back follows the new body height at once. (zoo) (ref: RS:46-48; progression/19 built log)
4. When a player is knocked down, then their back holds no one (the disc is switched off), so a rider falls. (needs coop/10's knockdown, which is built) (ref: RS:49; progression/10 follow-ups "a knockdown drops the rider")
5. When a player is inside the washing machine's drum, then their back holds no one. (needs the washing machine) (ref: RS:49)
6. When a player already stands at the top of a stack of `stacking.max_high` (3) players, then their back holds no one: three players is the most. The level is counted by walking down from the player through whom they ride (at most 4 steps). (zoo) (ref: RS:49, 55-65; T max_high)
7. When a player has no Teammate, then nothing can stand on them: solo play has no stacking. (zoo) (ref: progression/10 acceptance "Co-op only"; RS:99-111 loops over other Rigs)
8. When a player's own body moves, then it never collides with its own back. (zoo) (ref: RS:37)

### B. Getting on

9. When a player walks (or is carried) so that their feet are at or above the top of a Teammate's back minus 0.05 m, then their body meets the back and stands on it: any height does, stairs and furniture too. (zoo) (ref: RS:98-111)
10. When the feet are lower than that, then the body passes through the back (a collision exception per Teammate, made and lifted each frame), so walking into a Teammate is the soft push (section G), never a wall, and a climb passes up beside them. (zoo) (ref: RS:89-111)
11. When the player is already on a back, then that back always holds: it rises at once when the player under stands up. (zoo) (ref: RS:104)
12. When a player jumps on the floor, then an ordinary jump leaves at `players.jump_speed` 5.5 m/s under gravity 20, reaching 0.756 m: lower than any back (0.7 m crouched is reachable only at the very top, 1.4 m standing never). A crouched player cannot jump. (zoo) (ref: PL:538-541, 550; data/tuning/players.json)
13. When the jump is within `stacking.climb_reach` (0.9 m, centre to centre along the floor) of a Teammate's back, then it is a climb, if the back (a) holds riders (section A), (b) is higher over the jumper's feet than half the ordinary jump's reach (0.378 m), and (c) has room over it for a crouched body: a ray from 0.02 m over the top to 1.0 m + `stacking.climb_clear` 0.15 m meets no wall or furniture. The nearest such back wins. (zoo) (ref: RS:119-141; PL:73-77; T climb_reach, climb_clear)
14. When a climb is made, then the jump is as fast as it needs to clear the back by 0.15 m: `max(5.5, sqrt(2 * gravity * (back top - feet + 0.15)))`. (zoo) (ref: PL:545-547)
15. When a climb starts, then the player tucks into a crouch at once (the body 1.0 m tall), because a standing player on a standing one would not fit under the ceilings. (zoo) (ref: PL:548-550; progression/10 follow-ups)
16. When the climber is in the air, then they steer over the back's middle: the horizontal offset to the back times `climb_steer` 8 is added to their velocity every frame until they land. (zoo) (ref: PL:76-77, 409-412)
17. When the climber lands anywhere (on the back or off it), then the steering ends. (zoo) (ref: PL:591-596 `_climb_to = null` on the floor)
18. When a jump is a climb, then it plays the ordinary "jump" sound and nothing else (no tuck sound, no push-off dust). (zoo) (ref: PL:551)
19. When a third player wants on a stack of two, then the same rules decide: three high only where the ceiling is high enough for the room check (the attic, the stairwells; about 3.1 m with the placeholders). (zoo, if a room is high enough) (ref: RS:119-141; progression/19 follow-ups)

### C. Standing on a back

20. When a player stands on the floor of a Teammate's back (a collision with a BACK body, upward normal over 0.7, on the floor), then they are "riding" that player. A player in the air rides no one. (zoo) (ref: PL:586-599)
21. When a player rides, then they move with the back by exactly what it moved since the last frame, so the carrier's walking, crouching and jumping carry them. (zoo) (ref: PL:553-563)
22. When a player rides, then they stay crouched, even where the ceiling would let them stand, and cannot stand up by themselves until they step off. Because a crouched player cannot jump, a rider cannot jump off: they walk off. (zoo) (ref: PL:772-775, 540; progression/19 follow-ups)
23. When a rider walks, then they walk on the 0.6 m disc at crouch pace (half speed) with their own input; the disc has no rim or guard, so they walk off its edge and fall. (zoo) (ref: PL:405; RS:30-33)
24. When a rider falls from a back (1.4 m standing carrier, 0.7 m crouched), then they land with the "land" sound when the fall is over 3 m/s (a standing carrier's back: about 5.3 m/s, so it sounds). (zoo) (ref: PL:427-432; data/tuning/audio.json land_speed 3.0)
25. When a rider walks on the disc, then their footsteps are the floor's (`step_wood` or `step_tile` by the room under them), one every 1.4 m walked. A rider carried while standing still makes no step. (zoo) (ref: PL:435-444)
26. When a rider is on a back, then they still aim and use as usual (a rider aims the hatch from inside, picks Socks, throws). (zoo) (ref: PL:383)
27. When a rider is on the Grotto ladder's foot, then the ladder refuses: no player grabs a ladder while riding. (needs the Grotto ladder, M5) (ref: PL:472)

### D. Under the load (the carrier)

28. When any Teammate stands on a player's back, then that player's walking pace is multiplied by `stacking.carry_speed` 0.5, on top of the crouch pace and any drag. The middle player of a three-stack and the bottom one both get 0.5 (not 0.25). (zoo) (ref: RS:96; PL:405-406; progression/10 follow-ups; T carry_speed)
29. When the carrier is crouched and wants to stand up, then they stand only if there is room for their body plus the stack on their back: the tallest rider (their body height minus 0.3 m) and everything standing on that rider, counted over at most 4 levels, up to the ceiling or furniture. (zoo) (ref: RS:77-86; PL:782-788)
30. When the carrier crouches or stands with a rider on, then the rider keeps their hold and rides the new height. (zoo) (ref: progression/19 built log)
31. When the carrier jumps, then the rider rides along (the carrier's jump is allowed as built). (zoo) (ref: progression/10 follow-ups "the carrier may jump")
32. When the carrier is knocked down, then the back switches off and the rider drops; the carrier's own falling body slips them off if they land on it. (needs coop/10's knockdown; built) (ref: RS:49; PL:566-583 `_update_slip`, slip_speed)
33. When the carrier walks away, then the rider rides along without any input, at the carrier's slowed pace. (zoo) (ref: PL:553-563; RS:96)
34. When the carrier looks, picks, throws or drops, then nothing about the load changes: no weight bob, squash, sway or sound shows that someone stands on them. (zoo) (ref: no code found in RS, PL, avatar.gd)

### E. Getting off

35. When a rider walks off the edge, then they fall to the floor (or the next surface) and ride no one. (zoo) (ref: PL:586-599)
36. When a rider is knocked down (their own knockdown), then they fall as a ragdoll from where they stand, and the back under them is free again. (needs coop/10; built) (ref: RS:49 for the carrier; PL:106 for the knocked player)
37. When the carrier leaves the game, then the rider falls where they stand. (zoo) (ref: RS:72-74 `riders()` reads the live Rigs; not tested in the old game, to be checked in the build)
38. When a rider steps off a back onto another Teammate's back (two stacks side by side), then they ride that player: the back they touch is the one that holds them. (zoo) (ref: RS:98-111; PL:586-599)

### F. What the others see

39. When a player rides, then their pose carries who they ride (the player id, -1 for none) and where they stand from that player's feet (x, y, z). (zoo) (ref: RIG:544-555 `pose()`; docs/migration/coop-structure-for-the-port.md section 3 "The riding frame")
40. When a Teammate's pose says "riding player X" and X is known here, then the Teammate's drawn position is X's drawn position plus the sent offset, every frame, so they ride X's eased motion rigidly; yaw and pitch ease on their own at 12 per second. (zoo) (ref: RIG:561-570; docs/migration/m06-lists/02-teammates-seen.md lines 8-9; Q2450)
41. When X is not known on this machine, then the Teammate eases to the absolute sent position instead. (zoo) (ref: RIG:566-568)
42. When a Teammate rides, then their avatar is crouched (crouch weight eases at 6 per second), as sent in the pose. (zoo) (ref: RIG:572; PL:772-775)
43. When the carrier walks, then the rider's avatar also waddles on other machines, because the waddle measures the avatar's own displacement; no riding pose exists. Old weak point, never fixed. (zoo) (ref: progression/10 follow-ups; avatar.gd waddle)
44. When anybody stacks, climbs, rides or steps off, then there is no sound, rumble, message, sparkle or animation of its own for anyone; only the jump and land cues, the steps and the slowed pace show it. Spec follow-up 0 (a climb or ride animation, stack animation) was never built. (zoo) (ref: progression/10 follow-ups; progression/spec.md follow-up 0)

### G. The soft push between standing players (Q263)

45. When a Teammate stands nearer than `players.push_apart` (0.6 m) to this player, centre to centre along the floor, then this player is pushed away along the line between them at `(0.6 - gap) * players.push_rate (8)` m/s, added to their own velocity; several Teammates add up. Deeper overlap pushes faster. (zoo) (ref: RS:147-168; PL:407-408; data/tuning/players.json push_apart, push_rate)
46. When two players stand exactly on each other (gap under 1 mm), then the one with the lower player id is pushed one way (right) and the other the opposite way. (zoo) (ref: RS:165-166)
47. When each machine pushes, then it pushes only its own player; both bodies move apart, each by its own machine. (zoo) (ref: RS:144-146)
48. When the other player's feet are more than half a crouch (0.5 m) higher or lower, then there is no push: one stands on, or is climbing onto, the other. (zoo) (ref: RS:157-158)
49. When this player drags a knocked-down body, then that body does not push them (its feet are in their hands). (needs coop/10's drag; check what the port has) (ref: RS:159-160)
50. When players spawn at the washer spawn, then they stand `players.spawn_apart` (0.6 m) apart (Q285). (belongs to the spawn piece; listed in list 02 line 105) (ref: data/tuning/players.json spawn_apart)

### H. Other things stacking touches

51. When a Throw hits a Teammate on a back, then the Throw hits the body capsule as for anyone (the back is a layer only players meet). (zoo) (ref: RS:23-27 mask 0; RIG:687-692)
52. When the Sock generator places Socks for a high spot, then Socks "meant for high places" count like any others; alone the Sock is placed somewhere reachable, with two or more players it lies on the high spot (Q664). (outside this piece: the generator, core/52; listed so the designer sees it) (ref: progression/10 Answers Q664)
53. When a solo player wants the high spots, then there is no Upgrade for it (no jump Upgrade, Q664); a "solo way to reach high spots (an Upgrade such as a jump or long Throw)" is the catalogue's P27, proposed, milestone M6. (outside this piece) (ref: docs/migration/feature-catalogue.md P27, line 541)
54. When a hint of the old Sock-smarts or a prompt could name the climb, then none does: there is no key hint or prompt about stacking or climbing. (zoo) (ref: game/ui/prompts.gd:85-110 has none)

## Co-op: what the Host decides, what a Guest predicts (`docs/migration/coop-structure-for-the-port.md`)

- **The Host decides nothing here.** Nothing about a stack is decided state: no Command, no event, no Part. Each machine runs its own player's body (Godot's own physics and the player's own input); the pose carries the riding relation (id and offset) as plain pose properties of the avatar's synchronizer (section 3 of the structure file: "The riding frame", "sync `on` and the offset as properties; the receiver recomputes position from the carrier").
- **What each machine computes by itself:** the back disc of every player (placed from that player's drawn body), the climb target (from the drawn Teammates' backs), the collision exceptions, the carry factor and the load height, the soft push. Each machine computes them for its own player only.
- **What a Guest sees:** a Teammate's back is where the Teammate is drawn (eased at 12 per second, Q2450), not where they stand; at 100 ms a climb onto a moving Teammate can miss by the lag. This is the old behaviour (see weak points).
- **What can go wrong across machines:** the carrier's machine and the rider's machine disagree by their lag about where the back is; the rider's own body is the authority for its own position (Host takes it as truth within bounds, `packet_guard.gd:76`), so the rider is never snapped by the carrier's machine.
- **Prediction is looks only (Q2220 and the structure file):** nothing is predicted because nothing is shared state.
- **Save:** stacks are not saved (riders are free when a game loads; the old save keeps no ride, riders are only in the pose).

## Already in the port

- `game/parts/avatar/avatar.gd`, `avatars.gd`: an Avatar whose position and yaw sync from the owner at 20 a second; a Guest glides at 15 per second (a looks setting differing from the old 12). The pose has no riding id or offset yet.
- `game/player/player.gd`: movement, crouch (1.0 m), jump, gravity; `Player.radius` 0.35 against the old 0.3; no back, no `ride`, no `climb`, no `carry_factor`, no `load_height`, no push.
- `game/parts/avatar/avatar_looks.gd`, `looks_contract.json`: the `Head` and `HoldPoint` nodes exist; there is no riding pose.
- Layers: the port has no `Layers` class; layer numbers are constants on `Mess` and `Ragdoll` (`Ragdoll.MATE_LAYER`), the player scene's mask is 73, and there is no BACK layer, no back body and no slip off a ragdoll (checked by grep in `game/`).

## What was weak in the old game (for the designer to weigh)

- No sound, look or animation for a climb, a ride, a step-off or a carried load (spec follow-up 0, never done): lines 18, 34, 43, 44.
- A rider waddles while carried and has no riding pose (line 43).
- The disc has no rim: a rider walks off by accident (line 23).
- A rider is locked in a crouch even where the ceiling would let them stand (line 22), and cannot jump off or on to a third player (line 22).
- Footsteps on a back use the floor under it (line 25).
- The back and the climb check use the drawn, eased position of a Teammate (the co-op section).
- The room check for a climb only rays against `Layers.WORLD`; whether that includes the house's furniture was not verified (line 13).
- The "solo way to the high spots" was never built (line 53, P27).

## Questions for the designer

1. **The rider's crouch.** Old: a rider stays crouched all the time on a back, even in the attic where they could stand. Keep, let a rider stand where there is room, or crouch deeper?
2. **A rider's jump.** Old: none (a crouched player cannot jump), so a rider walks off and cannot climb to a third player. Keep, or let a rider jump (off, or onto a third back with the same climb rule)?
3. **The carrier's jump and a knockdown.** Old: a carrier may jump (the rider rides), a knockdown drops the rider. Keep, or forbid the carrier's jump while carrying?
4. **Carry pace and stack size.** Old: the pace is 0.5 for every carrier, up to 3 players. Keep both numbers, or change the slowdown for a taller stack or the stack size?
5. **Climb and ride look and sound.** Old: nothing but the jump and land sounds (lines 18, 44). Keep, or add a tuck, a push-off or a riding pose (an addition, its own look work)?
6. **The rider's waddle while carried (line 43).** Keep, or hold the waddle still while riding?
7. **The disc's edge (line 23).** Keep (a rider can walk off), or make the disc forgiving (a wider disc or a soft edge) so riders fall less by accident?
8. **Solo high spots (P27).** Old: none. Leave for M6 as the catalogue says, or add the Upgrade now?
9. **How the stack is decided across machines.** Old: each machine alone, the pose carries the riding relation. Keep that (cheap, same feel), or make the stack decided state on the Host (a Part), which fixes the lag at the cost of a trip and a refusal path?
