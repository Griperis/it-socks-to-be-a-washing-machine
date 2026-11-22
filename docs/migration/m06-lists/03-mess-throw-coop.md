> Draft behaviour list for M0.6 (Q2436), written from the reference on 2026-11-22; for the designer to approve. Answered 2026-11-22: question 6 by Q2439; 8 by Q2472; 1-5, 7 and 9 by Q2473-Q2479. Sections A-C approved (Q2472), D-M (Q2480).

# M0.6 piece 3: The Mess, Hands and Throw in co-op (behaviour list, draft)

Words follow `GLOSSARY.md`. Paths are in `reference/it-socks/` unless they start with `game/`, `docs/` or `data/` of the port
(a line says "port" then). "Old" is the game at tag v0.1.1. A line marked `(changed by Q####)` is changed by a later answer;
the later answer binds. `[backlog n]` is the n-th item of `docs/migration/m06-backlog.md` "Co-op" (list at the end of the
behaviour list). Core behaviours already ported in M0.5 are not repeated: only what differs or is added for a Guest, a late
joiner or a race. Q1596 and Q1597 are not in `decisions.md`; they are in `docs/migration/digests/digest-core-and-coop.md:178-179`.

## Behaviour list

### A. The join snapshot of the Mess (late joiner)

- A01. When a Guest passes the gate, then the Host sends it the whole state once, every Part's State by id, the Mess included. (ref: game/parts/session.gd:182-187; old game/net/session.gd:464 `_welcome`)
- A02. When the snapshot reaches the Guest, then every Part takes its state whole and shows it at once, with no sound and no animation (a Door that was open stands open). (ref: game/parts/parts.gd:157; game/parts/openable.gd:25; old core-loop M15, D03)
- A03. When the Guest has the Mess, then it holds the same Socks with the same ids, Designs, poses, mates, Pairs on the floor and Pairs on the shelf as the Host, and the count never changes because someone joined. (ref: docs/migration/behaviour-core-loop.md M23; old tests/net_join_test.gd `snapshot`)
- A04. When a Sock is HELD in someone's Hands at the moment of the snapshot, then the Guest has it HELD too and does not draw it in the Mess; it is drawn in the holder's Hands. (ref: game/mess/mess.gd:3-5; old I.1 in behaviour-core-loop.md)
- A05. When the snapshot comes while Socks are FLYING on the Host (woken, dropped, thrown), then the Guest shows each as a falling body from where it is now and it comes to rest with the others. Which poses the join writes for a moving Sock is not read yet (coop-structure section 8). (ref: docs/migration/coop-structure-for-the-port.md:211 "Mess join with Moving Socks"; old game/world/sock_record.gd:337 `sync_moving`) [see Question 8]
- A06. When a late Guest joins while a Throw is in the air, then it sees the body from the spawner's copy and the stamped stream; it never sees a body flash at the origin. (ref: docs/migration/coop-structure-for-the-port.md:77 point 8 "Put the position in the spawn values"; old docs 'welcome carries the pose')
- A07. When the snapshot is big (about 4,000 records with 2,000 poured, `add` and `rest` answers carry the whole arrays today), then the join and the answers must still reach the Guest without a visible stall; the size is measured with a real Guest. (ref: docs/migration/m06-backlog.md Co-op item 4 [backlog 4]; old tests: join about 40 KB for 1,000 Socks, docs/migration/digests/digest-core-and-coop.md:252)
- A08. When the Guest joins, then it never starts the Mess, never lays a batch and never adds Socks of its own; a Mess is the same size for any number of players. (ref: docs/migration/behaviour-core-loop.md M21, M23)
- A09. When a Guest's Mess is up, then no `wake`, `put`, `rest`, `fall`, `add` or `take_out` call exists on it: it is read-only, its records change only by the Host's answers and snapshots. (ref: docs/migration/coop-structure-for-the-port.md:111 "A Guest's Mess is read-only"; game/mess/mess.gd:461)
- A10. When a Guest joins, then it gets its own empty Hands (and the Guide card is not in this milestone) and starts where the Host's roster says; a returning player's held Socks lie where they stood. (ref: docs/migration/behaviour-core-loop.md H25, H26; old digest D "Spawns, saves, joining and leaving")

### B. Moving Socks and the settle stream (Q2222)

- B01. When a lying Sock is woken on the Host (a hit, a pick's column, a Door or drawer, a pour), then the Host's answer carries the new state to every Guest and each machine starts that Sock's body from the same record for looks. (changed by Q2222: "each machine simulates for looks and snaps to the Host's rest"; port has the Host start the body and a spawner copy only) (ref: docs/migration/decisions.md:103; game/mess/mess.gd:659; docs/migration/m06-backlog.md Co-op item 3 [backlog 3])
- B02. When a Sock on a Guest's machine moves under its own simulation, then it is drawn moving there exactly as on the Host (cloth, bounce sound) and never wakes, writes or rests anything in the shared Mess. (ref: old game/world/sock_flights.gd:264-266; docs/migration/coop-structure-for-the-port.md:109-113)
- B03. When a Sock comes to rest on the Host (still for `rest_time` 0.3 s, or Jolt asleep), then the Host writes it LYING and sends one batch of rows per tick in which any Sock rested, reliable, to every Guest. (ref: old game/net/streams/settle_stream.gd:17-30; game/world/sock_bodies.gd:687-700; port game/mess/mess_moving.gd:164-190)
- B04. When a batch has one row or none, then nothing is sent (`rows.size() <= 1`, the header only). (ref: old game/net/streams/settle_stream.gd:25-26)
- B05. When the Guest hears the Host's rest rows, then each Sock snaps to the Host's pose, whatever its own run made of it; a Sock still moving on the Guest is put at rest there at once, even when its own pose is near the Host's. (ref: old game/world/sock_record.gd:305-333; port: the `rest` answer, game/mess/mess.gd:461-474)
- B06. When the Guest's own run moved a Sock that the Host never moved, then that Sock goes back where it lay (`take_before`), because the two runs can wake different Socks. (changed by the rebuild: the Guest never writes the Mess, so only looks go back) (ref: old game/world/sock_record.gd:139, 313-321; docs/migration/coop-structure-for-the-port.md:27)
- B07. When the Guest's looks differ from the Host's rest by a few centimetres, then the Sock shows a small step at the snap and no other correction; the step is the approved look of Q2222. (ref: old docs/migration/digests/digest-core-and-coop.md:392 "Q291 ... snaps to the Host's poses, check it in the playtest"; docs/migration/coop-structure-for-the-port.md:48 F3)
- B08. When a snap happens, then no MultiMesh instance is drawn smeared between two places (a Sock that just rested was missing a whole tick, a row that changed its Sock smeared): the Mess's MultiMeshes are never physics-interpolated on any machine. (changed by Q2407) (ref: docs/architecture/mess.md "No MultiMesh of the Mess is physics-interpolated")
- B09. When the Host's rest is "put down" instead (out of bounds, in a wall, sunk, pushed out of a leaf), then the Guest gets the same final pose and a "pop" where a lost Sock came back, for everyone. (ref: game/mess/mess.gd:461-474 `POPPED`; game/audio/hearing.gd:13-18; old core-loop M19)
- B10. When a flight never settles, then the Host puts it down after 6 s (`release.max_age`; the body's clock past twice that also ends it) and the Guest hears it as a rest like any other. (ref: data/tuning/release.json:max_age; old game/world/sock_flights.gd:231-233)
- B11. When up to 512 Socks are Moving (32 kept for Throws and drops, 16 woken a tick nearest the players first), then the Host runs the budget; the Guest follows the answers, and a Guest's nearest-first order uses the players on this machine. (ref: docs/migration/behaviour-core-loop.md M17; game/mess/mess_moving.gd:211-255, 435-445; port `_player_spots` reads this machine's players only)
- B12. When a rest and a wake of one Sock happen in one tick on the Host, then the Guest finds the new body by its id and never loses or doubles it; Godot must not rename the new body `Flight<id>2`. (ref: docs/migration/m06-backlog.md Co-op item 7 [backlog 7]; game/mess/mess.gd:55-60, 880-900)
- B13. When a body leaves the flights, then a Guest forgets it, unless a new body of the same Sock already took its place. (ref: game/mess/mess.gd:828-838 `_on_flight_out`)
- B14. When a Guest looks at the heap sign (the Moving count), then it shows the Host's number of moving Socks, not 0. (ref: docs/migration/m06-backlog.md Co-op item 5 [backlog 5])
- B15. When a flying Sock is within the cloth's `flying_cap` nearest the Guest's camera, then it gets a Looks (cloth) on that machine; the choice is per machine, never sent. (ref: game/mess/mess.gd:746-790 `give_looks`; old core-loop; docs/architecture/mess.md "The tiers")
- B16. When a Guest's falling Sock is seen only as the untinted body, then it gets the same tint and Looks a Host's body has. (ref: docs/migration/m06-backlog.md Co-op item 1 [backlog 1], third clause)

### C. Doors and drawers sweeping Socks, seen by a Guest

- C01. When a Door, drawer or lid moves, then the Host sweeps its shapes over the lying Socks and wakes those in the way at once (at most 32 a tick, the rest wait). (ref: game/mess/mess_moving.gd:308-338; old game/world/sock_bodies.gd:733-746; core-loop M26, D04)
- C02. When a Door or drawer moves on a Guest, then the Guest sweeps it too on its own machine (every machine tracks the mover), so the woken Socks tumble on the Guest at the same moment; the Guest's sweep is looks only. (changed by Q2222) (ref: old docs/migration/coop-structure-for-the-port.md:121-122 "Doors that sweep Socks are tracked on every machine (`track_door`)"; docs/migration/m06-backlog.md Co-op item 3 [backlog 3])
- C03. When a drawer slides, then the Socks and sock balls in it ride out and back every frame on every machine. (ref: old docs/migration/behaviour-core-loop.md M15; port game/mess/mess_moving.gd:308)
- C04. When a Door sweeps a Sock that rests in a leaf, then the Sock is pushed flat out of the leaf to the side the leaf swept from, `leaf_clearance` past its face, and flies on at `leaf_push_speed`; a Guest sees the same push or its snap. (changed by Q2428) (ref: docs/architecture/mess.md "Pushed out of a leaf"; game/mess/mess_moving.gd:341-386)
- C05. When two players open and close the same Door at once, then both get what they asked (a toggle carries the wanted value) and both machines end alike. (ref: old docs/migration/digests/digest-core-and-coop.md:182 Q283; game/parts/openable.gd:74)
- C06. When a Door or drawer starts to move because a Guest asked, then the Guest hears and sees it only on the Host's answer (no ghost for Doors and drawers). (ref: docs/migration/coop-structure-for-the-port.md:21 note "Prediction today covers only pick, pick_pair, cycle, drop, Throw"; game/parts/openable.gd:74)
- C07. When a Sock a Guest sees woken by a sweep rests on the Host somewhere else than on the Guest, then it snaps like in B05. (ref: old game/world/sock_record.gd:313-321)

### D. A Guest's pick (Q2220: looks only)

- D01. When a Guest left-clicks an aimed Sock with a free place and the Guest's own check passes, then the Command goes up and a looks-only copy of the Sock flies to its Hands at once. (changed by Q2220: the old game also changed the Guest's Hands and the Mess at once) (ref: docs/migration/decisions.md:101; old game/hands/hands_rules.gd:147-161; game/player/player.gd:373-378)
- D02. When the ghost flies, then it leaves from where the Sock lay, at its Size, and goes to its place in the Hands on `pick_time` 0.3 s eased in and out, with a hop of `pick_hop` 0.18 m, as a Host's own pick does. (ref: game/hands/held_view.gd:261-275; old game/hands/drop_view.gd; port tuning hands_tuning `pick_time`)
- D03. When the ghost is in the air, then the Guest's Hands, the held count and the Mess do not change; the Sock is still LYING (or FLYING) in the Guest's copy of the Mess and a second click on it is a click on a Sock the Host may take from someone else. (changed by Q2220) (ref: docs/migration/decisions.md:101; game/parts/parts.gd:110-111 "Prediction ... never writes state")
- D04. When the Host's answer to the pick is granted, then the Hands and the count change on the Guest, the Sock leaves the Mess there, the ghost lands in its place with no pop; "pick" was already heard at the click (changed by Q2478), "pair" plays at the answer (Q2479). (ref: game/audio/hearing.gd:25-31; old game/core/game.gd:1454-1465 `pick_into`)
- D05. When the answer is refused (full, far, soon, gone), then the ghost is undone (see F) and, for "Hands full" only, the Guest sees the red "Hands full" and hears "refuse". (ref: game/player/player.gd:545-575; old game/hands/hands_rules.gd:164-182, 134-136)
- D06. When a click comes sooner than the grab interval (0.35 s on the Host's clock), then the Guest does nothing: no ghost, no message, no sound, exactly as on the Host. (ref: game/hands/hands.gd:133-140; docs/migration/behaviour-core-loop.md H02)
- D07. When the Guest's own copy says the Hands are full, then it shows "Hands full" and plays "refuse" at once, and asks nothing; when the Guest's copy is wrong (a lagging Hands copy), the Host's answer corrects it. (ref: game/player/player.gd:373-378; old behaviour-core-loop.md H04)
- D08. When a Guest picks a Sock that is the mate of a loose Sock it holds, then the ghost flies to the held one and the Pair forms only on the Host's answer; the pairing moment (fold, roll, pop, sparkle, ring, 0.5 s) starts on the answer, not on the click. (changed by Q2220) (ref: old game/hands/paired_moment.gd:1-10; behaviour-core-loop.md P01, P05)
- D09. When a Guest's pick takes the Sock under others, then the Host wakes the column (Socks that rested on it fall) and the Guest sees it fall, from the answer; no ghost of a fall. (ref: game/mess/mess_moving.gd:82-95, 118-125; old core-loop M16)
- D10. When a Guest picks a moving Sock (a dropped or thrown one in the air or a sliding woken one), then it flies to the Hands from the Guest's copy of that body, and the Host decides by where the Host's body is. (changed by Q2339) (ref: docs/migration/decisions.md:254; game/hands/hands.gd:133-137; game/mess/mess.gd:228-236)
- D11. When a Guest clicks Socks twice before the first answer (at 100 ms round trip), then the second waits until the first is answered; no second ghost (changed by Q2474). (ref: docs/migration/coop-structure-for-the-port.md:46 F1, 161-164 Q1)
- D12. When a Guest's pick targets a Sock out of the Guest's reach, then the Guest's own check refuses it as the Host's does; the Host uses the Guest's avatar pose plus `reach_slack`, a place that reaches the Host a little late. (ref: game/hands/hands.gd:133-144; game/hands/hands_tuning.gd:9-12)
- D13. When the Host reads a Guest's reach and capacity, then it uses the Guest's own `HandsTuning` (Upgrades), not the Host's and not a default; a Guest's tuning must be known on the Host. (ref: docs/migration/m06-backlog.md Co-op item 1 [backlog 1], first clause; game/hands/hands.gd:38, 84-97)
- D14. When a Guest leaves, then everything in its Hands stays HELD (not lost) and drops where it stood, a Pair as a ball, for everyone; the leaver's Socks lie again. (ref: docs/migration/m06-backlog.md Co-op item 1 [backlog 1], second clause; old behaviour-core-loop.md H24, P10; game/parts/parts.gd:131-137 `left`)
- D15. When a Guest's pick would take from a Teammate's Hands, then nothing is taken (no Command exists for it). (ref: old behaviour-core-loop.md H16, I.3)

### E. A Guest's drop and wheel

- E01. When a Guest right-taps with the crosshair white and something held, then the Command goes up with the point and normal, and an instant looks-only ghost falls from the hand and blends to the Host's result (changed by Q2473). (ref: docs/migration/coop-structure-for-the-port.md:151 step 7 "Guest ghosts: pick, drop, Throw"; old game/hands/hands_rules.gd:287-310)
- E02. When a ghost drop falls (if E01 is yes), then it leaves the hand's place, falls on a looks-only body on the ghost layer, touches only the static house (no lying Sock, no Moving Sock, no Cabinet), and has no handle to the Mess. (changed by Q2367: leaves from the hand, no 0.1 s flick, no 3 cm hold) (ref: game/hands/hands.gd:280-300; old game/core/layers.gd:18 `PREDICT`; docs/migration/decisions.md:282)
- E03. When the Host's answer to a drop is granted, then the Host's body (a Flight) falls from the same hand place to the same spot, the ghost blends onto it like a Throw's (G03), and it rests as a Mess Sock where the body stopped on every machine. (ref: old game/hands/hands_rules.gd:313-324; game/mess/mess_moving.gd:458-505)
- E04. When the Guest's red crosshair (a drop that would be refused) shows, then a click shows "Can't drop there" with "refuse" at once on the Guest and sends nothing; the Host also refuses a drop out of reach. (ref: game/player/player.gd:381-391; old behaviour-core-loop.md H08)
- E05. When the Host refuses a drop the Guest let go, then the ghost is undone (F), "Can't drop there" shows for "nowhere" or "far" only, and the item is back in the Hands in its place and active. (ref: game/player/player.gd:545-575; old game/hands/hands_rules.gd:325-334)
- E06. When a Guest turns the wheel (or LB/RB), then the held view turns at once (Q2475); a refused turn goes back silently. (ref: old game/hands/hands_rules.gd:300-304, 316-321; behaviour-core-loop.md H06)
- E07. When a hand-off is asked by a Guest (right-click on a Teammate), then nothing shows until the Host's answer (no ghost, as before); "Not their mate" shows only to the giver; a Pair at the feet of a Teammate with full Hands shows "Hands full" to the receiver only. (ref: old game/hands/hands_rules.gd:288-290; behaviour-core-loop.md H13-H15; not in this piece's scope, listed so no ghost is built for it)

### F. A refused Guest Command (the "it flies back" look)

- F01. When the Host refuses a Guest's pick, then the ghost flies back out of the Guest's Hands to where the Sock lay, shown again there once it lands. (ref: old game/hands/drop_view.gd:196-211; game/core/game.gd:1446-1448)
- F02. When the flying-back ghost goes, then it takes `cloth.flight_time` 0.45 s on an arc of `cloth.flight_arc` 0.22 and then the Sock is drawn lying again with no pop. (ref: data/tuning/cloth.json:11-12; old game/hands/drop_view.gd:196-211; port: held_view pick_time 0.3 for the way in, none yet for the way back)
- F03. When the Sock the Guest tried to pick was taken by a Teammate first (the race loser), then the ghost flies back out to that Teammate's Hands, not to where the Sock lay. (ref: old game/hands/drop_view.gd:218-236 `landings.taken_by`; docs/migration/digests/digest-core-and-coop.md:176)
- F04. When the race loser's pick is refused as "gone", then there is no message and no sound: the grab fizzles (Q245, Q282). (ref: old game/hands/hands_rules.gd:131-133; digest D line 175)
- F05. When a refused pick would have made a Pair, then the Pair is never made (the Guest never changed its Hands), so no split back. (changed by Q2220: the old game split the Pair back) (ref: old game/hands/hands_rules.gd:175; docs/migration/decisions.md:101)
- F06. When "Hands full" is the refusal, then the red text wobbles for `wobble_time` 0.45 s, turning `wobble_turn` 0.07 rad each way at `wobble_rate` 5 per second, dying down linearly, and stays up `refusal_time` 2.0 s; "refuse" plays flat. (ref: old game/ui/hud.gd:22-25, 174-180; port game/ui/hud_tuning.gd:15-20, game/hands/hands_tuning.gd:47; game/player/player.gd:424-427)
- F07. When a refusal is for a Guest, then only that Guest sees and hears it; nobody else is told. (ref: old game/audio/sound_installer.gd:8-9, 41-52; docs/migration/digests/digest-core-and-coop.md:174 Q246)
- F08. When the Host's answer to a Throw or a drop is refused, then the ghost is gone and the item is back in the Hands at once, no fly-back (Q2476). (ref: old game/hands/hands_rules.gd:381-392, game/world/flights.gd:241-247; docs/migration/coop-structure-for-the-port.md:151 "refused: it flies back")
- F09. When the Host's answer never reaches the Guest (a lag spike or a lost link), then after 2 s with no answer the ghost goes back to the Hands with the refusal look and "refuse" (changed by Q2477). (ref: none in the old game: `CommandGuest._picks` waits with no limit, old game/core/command/command_guest.gd:8-12)
- F10. When a Guest's Command is the wrong shape, over the rate (picks 10 a second, Throws 5 a second, Cabinet shelves 5 a second, Doors 5 a second) or names a verb the Part does not accept, then the Host drops it, counts it and answers nothing; the Guest's ghost then times out as F09. (ref: game/hands/hands.gd:120-130; game/parts/session.gd:190-217; game/entities/cabinet/cabinet.gd:327-328)

### G. A Guest's Throw (Q2221)

- G01. When a Guest releases the Throw ring with a Sock or Pair active, then the Command goes up with the aim and the charge, the Sock leaves the Hands at once, "throw" plays flat and the pad rumbles at once. (changed by Q2221; the old game also sent `from`, `vel` and the Guest's own `spin`) (ref: docs/migration/decisions.md:102; old game/hands/hands_rules.gd:359-378; game/player/player.gd:349-353; game/audio/hearing.gd:38-41)
- G02. When the Throw's ghost leaves, then it starts from the hand's place at once (the body leaves from the hand on an arc aimed at the crosshair's point), flies on a looks-only body on its own layer, and passes through the Socks and bodies the Host's body would touch. (changed by Q2356: the old Throw started at the eyes and the model caught up from the hand in `release.catch_up` 0.1 s) (ref: docs/migration/decisions.md:271; game/hands/hands.gd:258-278; old game/world/flights.gd:200-225)
- G03. When the Host's answer arrives, then the Host's body (a Flight) exists on every machine and the ghost stays drawn on its own body all the way, moved only by how the Host's body differs at the same moment of the flight. (ref: old game/world/flights.gd:107-140; game/hands/thrown_item.gd:143-160; digest D:178 Q1596)
- G04. When the two differ, then the difference eases in over `release.predict_blend` 0.2 s: each frame the offset moves `1 - exp(-3 dt / 0.2)` of the way to the new difference (95 per cent in 0.2 s), position and turn both. (ref: old game/hands/thrown_item.gd:143-160; data/tuning/release.json:predict_blend)
- G05. When the two are compared, then the Guest's body is sampled at the Host's stream clock minus 0.1 s, so the same moment of the flight is compared, not the same wall time. (ref: old game/hands/thrown_item.gd:148-152; game/world/flight.gd:208-221)
- G06. When the ghost's body is flying, then it records its own poses with its own clock (`clock + lead_in`), keeping the last 90 rows, so they can be sampled. (ref: old game/world/sock_flights.gd:221-225; game/world/flight.gd:186-193)
- G07. When the thrower's Host body comes to rest (and the stream has played all its rows), then the ghost eases onto the Host's rest pose: it is drawn at the Host's pose less the difference left; the swap to the room's drawing waits until that is under 0.002 m (at most 2.0 s). (ref: old game/hands/thrown_item.gd:162-163; game/world/flights.gd:384-387)
- G08. When the ghost lies at the Host's rest, then the cloth lies flat first (the Mess Sock is held back meanwhile; waits at most 1.5 s for flat), the room draws the Sock the next frame and the model stays 3 more frames, no blank frame, no pop. (changed by Q2407's rest glitch rule) (ref: old game/world/flights.gd:388-407, 354-368; docs/architecture/mess.md Q2407)
- G09. When the ghost is a loose Sock, then its cloth lies flat once it is under `release.flat_speed` 0.6 m/s after its first impact, so it is flat when the body rests. (ref: old game/hands/thrown_item.gd:253-260; data/tuning/release.json:flat_speed)
- G10. When the ghost is drawn, then it never wakes, rests, puts or writes a Sock of the shared Mess, even one it passes through (the 2026-11-19 bug: a Guest-only wake left a Sock lying elsewhere for good). (ref: old game/world/sock_flights.gd:264-290; docs/migration/coop-structure-for-the-port.md:104-113)
- G11. When the Host's body does something the ghost did not (a bounce off a Teammate), then the bounce eases in from where the ghost is drawn over 0.2 s. (ref: old game/world/flights.gd:302-316; digest D:179 Q1597)
- G12. When the Host's flight is caught, shelved or binned, then the ghost and its model are gone at once, the item lies where the Host says, and nothing is left in the air on the thrower's machine. (ref: old game/world/flights.gd:410-416; digest D:179 Q1597; old tests/net_throw_test.gd:285-300)
- G13. When the Host lands the flight, then the ghost carries on to the exact rest: a Sock flies into its Mess place (0.18 s on an arc of 0.04) when it did not come as a body; a Pair's ball flies in on the same numbers. (ref: old game/world/flights.gd:318-352)
- G14. When a Guest's Throw spin matters, then the Host's body spins as the Host chose; both machines show the same tumble because the spin is a tuning number, not the Guest's pick. (changed by the rebuild: the old Guest picked a random spin and the Host clamped it to (6, 3, 6)) (ref: old game/hands/hands_rules.gd:24, 339-341; game/hands/hands_tuning.gd `spin`)
- G15. When a Guest's Throw leaves, then the place it leaves from uses the Guest's eyes, not a fixed 1.5 m above the feet; only the Guest's own body lets its thrown Sock through. (ref: docs/migration/m06-backlog.md Co-op item 2 [backlog 2]; game/hands/hands.gd:367-374, game/mess/mess_moving.gd:506-512)
- G16. When the Throw is a lob (a tap below 0.15 of the charge), then it is the lob; the charge is full in 1.2 s; both are the Host's numbers for the Guest's own tuning. (ref: game/hands/hands_tuning.gd:51-58; old behaviour-core-loop.md T01-T03)
- G17. When a Guest's Throw ghost and the Host's body disagree about a catch (the Host decides), then the Guest never shows a catch the Host did not make. (ref: old tests/net_throw_test.gd:285-300; docs/migration/coop-structure-for-the-port.md:109)
- G18. When the Host's measured result is the bar, then at a 100 ms round trip the thrower's Sock leaves the Hands at tick 1 at most, is seen moving within 3 ticks, never goes back along the throw except where the Host's body bounced back, its largest step change is under 0.08 m, and it is never drawn behind the Host's body. (ref: old tests/net_throw_test.gd:253-271)
- G19. When Throws are sent, then at most `throw_rate` 5 a second pass the Host's guard for a Guest. (ref: game/hands/hands_tuning.gd:72-73; game/hands/hands.gd:128)

### H. A Teammate's Throw seen by others (Q2226)

- H01. When a Teammate throws, then the others see the Sock leave the Teammate's avatar's hand and fly the Host's true flight; the model starts at their hand and joins the flight over `avatar.teammate_throw_blend` 0.2 s (smooth, position, turn and size). (ref: old game/world/flights.gd:148-165; data/tuning/avatar.json:teammate_throw_blend; digest D:204 Q483)
- H02. When the others see the Teammate's Throw, then the flight is played 0.1 s behind the Host's stream (`STREAM_LAG`), from stamped rows `[id, pos, rotation, velocity, clock]`, every tick, unreliable ordered, at 80 bytes a body; a pose older than the newest is dropped. (ref: old game/world/flight.gd:38, 186-193, 195-205; game/net/streams/flight_stream.gd:18-47; docs/migration/digests/digest-core-and-coop.md:252)
- H03. When the Teammate's Throw is seen, then it stops at the release point for about 3 ticks (50 ms) after the blend from their hand, then flies; Q2226 keeps this pause. (ref: old docs/migration/digests/digest-core-and-coop.md:279 "35 [later]"; docs/migration/decisions.md:107; changed by Q2356 in part: no eye-line start, see Question 6)
- H04. When the Teammate's Throw is seen, then no jump is drawn: no step back, no stall (the old measure was 0.153 m with jitter before the clock stamp; now each row carries the body's own clock, so it plays as evenly as on the Host). (ref: old tests/net_throw_test.gd:273-283)
- H05. When a Teammate's Throw is seen on a Guest, then the Throw's start look and the Host's own Throw look the same on the Host's machine (the Host's body is drawn from the hand on the Host). (ref: old docs/migration/coop-structure-for-the-port.md:100 "Feel"; game/world/flights.gd:148-165)
- H06. When the Teammate's Throw leaves, then everyone else hears "throw" at the Teammate's avatar's place in 3D (1.2 m above their feet), not flat, with no pad rumble. (ref: old game/audio/sound_installer.gd:10, 47-52; docs/migration/decisions.md:291 Q2376)
- H07. When a Teammate's Throw bounces, then every machine hears "bounce" where it hit, softer and lower the slower the hit (and at least `bounce_speed`), at the flight's own place; a Guest hears it, not only the Host. (ref: game/mess/mess_moving.gd:523-530; docs/migration/old-details-backlog.md "M0.6 Co-op: A Guest hears the bounces")
- H08. When a Teammate's Throw is a Pair or a loose Sock, then the others see the Pair as its ball and the Sock as cloth, as for the Host. (ref: game/mess/mess.gd:746-790; old game/hands/thrown_item.gd:42-95)
- H09. When the others see a Teammate hold Socks, then they see them at the Teammate's HoldPoint in front of the belly, at true size, all clustered, with no stream (drawn from the Hands state). (ref: old digest D:Q279-Q280; docs/migration/coop-structure-for-the-port.md:73 point 5; port has no HoldPoint: game/parts/avatar/avatar.gd, a capsule only)
- H10. When a Teammate's avatar is seen to throw, then the Teammate's own Throw ring and the charge sound are not shown or played for the others. (ref: game/audio/sound_installer.gd:10 `TEAMMATE_CUES` has no `throw_charge`; game/player/player.gd:338-346)

### I. Catch, shelve and land of a Guest's Throw

- I01. When a Guest's thrown Pair touches its own Collection's Cabinet drawer front, then the Host (only) shelves it: the lowest drawer with room, the drawer opens, the Guest is paid as for shelving, and the ghost is gone at once on the Guest. (ref: game/entities/cabinet/cabinet.gd:359-428; old docs/migration/behaviour-core-loop.md T05; digest D:179 Q1597)
- I02. When a thrown Pair touches another Collection's Cabinet, or a locked or full one, then it bounces off with a sound where it hit and lies on the floor as a ball, with no message; the Guest sees the bounce as the Host's. (ref: old behaviour-core-loop.md T06; game/entities/cabinet/cabinet.gd:359)
- I03. When a Guest's loose Sock is thrown at a Cabinet, then it bounces off and rejoins the Mess, never shelved. (ref: old behaviour-core-loop.md T07)
- I04. When a Guest's Throw hits a Teammate (catch, bounce), then the Host decides; a catch needs a mate in their Hands; this is the Throw-hits-Teammate row of the knockdown piece, not built in this piece. (ref: old behaviour-core-loop.md T09-T10; docs/migration/coop-structure-for-the-port.md:166 Q6)
- I05. When a Guest's flight is shelved, then the shelving shows the drawer opening and the ball flying into its slot on every machine; the shelver alone sees the "+N" Coins pop; others' bank counts go up (Coins are M4). (ref: docs/migration/decisions.md:227 Q2312, :230 Q2316; old digest D:174 Q281; docs/migration/old-details-backlog.md "Decided elsewhere")
- I06. When a Pair is shelved, then everyone hears "shelve" at the drawer in 3D, once per shelving. (ref: game/audio/hearing.gd:44-61; old game/audio/sound_installer.gd:41-48)
- I07. When a flight comes to rest, then it lies as a Mess Sock or a floor ball where its body stopped, the same on every machine (rest rows), after the 6 s limit if it never settles. (ref: old behaviour-core-loop.md T13; game/mess/mess_moving.gd:164-190)
- I08. When a flight leaves the flat or goes above the ceiling, then it comes down at once and lies in front of the washer (the return spot) with a pop for everyone. (ref: old behaviour-core-loop.md T14; game/mess/mess.gd:461-466)
- I09. When a Throw wakes lying Socks, then the Host wakes what the thrown Sock is about to meet, two ticks ahead in a 0.12 m sphere (at most 8 touching), so the thrown Sock shoves them; the Guest's ghost does not wake any. (changed by Q2431; Q2221: a ghost cannot touch the Mess) (ref: docs/architecture/mess.md "A hit"; game/hands/hands_tuning.gd:68-71; old game/world/sock_flights.gd:264-290)

### J. Pairing by a Guest

- J01. When a Guest picks the mate of a Sock it holds, then the Pair is formed on the Host's answer (Q2220), the Sock leads and its mate becomes IN_PAIR, and the Guest sees the Pair's ball as the active item. (ref: game/hands/hands.gd:185-198; game/mess/mess.gd:7-12)
- J02. When the Guest's pairing moment plays (answer), then the picked Sock flies to the held one, they line up, fold, roll into a ball that pops with a sparkle burst and a ring in the Collection's colour, once per pairing, 0.5 s; the Guest hears "pair" flat and the pad rumbles. (ref: old game/hands/paired_moment.gd:1-10, 20-28; game/audio/hearing.gd:21-24; port game/sock/pair_moment.gd)
- J03. When a Teammate pairs, then the others see only a small burst at the Teammate's avatar's hand (20 specks, size 0.035, speed 1.0, 0.55 s, ring 0.3), not the full moment; and hear "pair" in 3D. (ref: old game/hands/paired_moment.gd:9-11, 26-27; game/audio/sound_installer.gd:10; docs/migration/old-details-backlog.md "a teammate's burst")
- J04. When a hand-off or a catch completes a Pair in a receiver's Hands, then the receiver sees and hears the full moment. (ref: old digest D "P05 co-op note"; behaviour-core-loop.md P05)
- J05. When a Sock is picked or caught by one player, then it is nowhere else: a Pair split by a refusal can no longer happen (no Guest guess). (ref: old behaviour-core-loop.md P09; changed by Q2220)
- J06. When two players each hold one half, then nothing pairs between them. (ref: old behaviour-core-loop.md P04)
- J07. When the picker holds a Sock whose mate a Teammate holds, then a match cue is signalled to the picker; with Sole Mates the Teammate's matching Sock keeps an outline in their colour and a soft sound plays once (an Upgrade, M4, listed because the backlog names "the co-op match glow"). (ref: old behaviour-core-loop.md H29; docs/migration/old-details-backlog.md "M0.6 Co-op")

### K. A Guest shelving into a Cabinet drawer and Coins

- K01. When a Guest left-clicks a drawer holding Pairs of its Collection, then the Command goes up and nothing moves on the Guest until the Host's answer; then every held Pair of the Collection goes in, the drawer slides open, and the Guest hears "shelve" at the drawer. (ref: old behaviour-core-loop.md C01; game/entities/cabinet/cabinet.gd:315, 349-416; game/audio/hearing.gd:44-61)
- K02. When the Guest's click is refused ("Wrong Cabinet", "Cabinet locked", "Cabinet full"), then only that Guest sees the red text wobble and hears "refuse". (ref: game/entities/cabinet/cabinet.gd:26; game/player/player.gd:560-565)
- K03. When two players shelve into the same drawer in the same moment, then the Host takes them in the order they arrive: the second goes to the next drawer with room or is refused full. (ref: old behaviour-core-loop.md C13 (untested in the old game); game/parts/session.gd:190-217)
- K04. When Pairs are shelved, then the Coins (10 times rarity, once per drawer used) are the shelver's; the shelver alone sees the "+N" pop and the Coins fly; others' bank counts go up when they land; the "coins" sound is the shelver's alone. (ref: old digest D:174 Q281; game/campaign/coin_bank.gd:53-74; port game/coins/coins.gd:27; the pop and flight are M4)
- K05. When a Teammate shelves, then the others see the drawer open and a Teammate's shelving flight and sparkle burst; no "+N" pop. (ref: docs/migration/decisions.md:230 Q2316; old docs/migration/old-details-backlog.md)
- K06. When a Guest's thrown Pair is shelved, then the Host answers `thrown_shelve` with the Guest as the payee; the Guest is paid. (ref: game/entities/cabinet/cabinet.gd:359-428)
- K07. When a Cabinet is locked or its Rows are full, then a click says so and the Pairs stay; the drawers stay shut. (ref: old behaviour-core-loop.md C08)

### L. Races

- L01. When two players click the same Sock at once, then the Host takes the first Command to arrive; the other's pick is refused "gone" and fizzles silently, the other's ghost flies back to the winner's Hands. (ref: old behaviour-core-loop.md H17; game/parts/session.gd:190 "first to arrive wins"; old game/hands/drop_view.gd:218-236)
- L02. When a Guest and the Host click one Sock together, then the Host's own click is answered at once and the Guest's arrives a trip later: the Host usually wins. (ref: old digest D:175 Q245, Q282)
- L03. When a pick is granted to one player, then the Sock is out of every Mess and every other Guest's ghost of it is refused. (ref: old behaviour-core-loop.md P09, H17)
- L04. When two Guests pick Socks that are mates, each holding a half, then nothing pairs across; each pairs only in its own Hands. (ref: old behaviour-core-loop.md P04)
- L05. When two players pick one lying Sock under a Sock that is also being picked, then the Host answers them in turn; the second finds its Sock moving (woken) and may still pick it (Q2339). (changed by Q2339) (ref: game/hands/hands.gd:133-137)
- L06. When a thrown Pair is caught by a Teammate and the Guest's ghost is still in the air, then the ghost is gone at the answer. (ref: old tests/net_throw_test.gd:285-300)
- L07. When a Door, a pick and a Throw wake the same Sock in one tick, then the Host starts one body for it and the Guest shows one. (ref: game/mess/mess_moving.gd:98-102; docs/migration/m06-backlog.md Co-op item 7 [backlog 7])
- L08. When a Guest drops a Sock onto a spot another Guest takes the Sock under, then the Host's answer decides where it rests and the Guest's ghost blends to it. (ref: old docs/migration/behaviour-core-loop.md P08; game/hands/hands.gd:233-243)
- L09. When a Guest leaves while its ghost is in the air, then its ghost is gone and the Host drops what it held. (ref: old behaviour-core-loop.md H24; game/parts/parts.gd:131)

### M. What each player hears and sees (sounds, 3D, rumble)

- M01. When a player's own pick, pair, cycle, drop or throw is answered, then it plays flat and only for that player ("pick", "pair", "cycle", "drop", "throw"); "pair" and "throw" also rumble the pad. (ref: game/audio/hearing.gd:11-41; old game/audio/sound_installer.gd:41-48)
- M02. When a Teammate picks, pairs, drops, shelves or throws, then the others hear it in 3D at the Teammate's avatar 1.2 m up (shelving at the drawer), with no rumble; "buy" is in the old list. (ref: old game/audio/sound_installer.gd:10, 47-52; docs/migration/decisions.md:291 Q2376; docs/migration/old-details-backlog.md; game/audio/hearing.gd:5-8 says own moments only)
- M03. When a refusal is a Guest's, then only that Guest sees it and hears "refuse"; "Hands full" and "Can't drop there" are the words. (ref: game/player/player.gd:424-427; old game/core/game.gd:19-22)
- M04. When a body bounces, then every machine hears "bounce" at it, the Host and the Guests alike. (ref: docs/migration/old-details-backlog.md "A Guest hears the bounces"; game/mess/mess_moving.gd:523)
- M05. When Guests walk, then each Guest's footsteps and landing play in 3D at their body for the others, not flat at full level. (ref: docs/migration/m06-backlog.md Co-op item 6 [backlog 6]; game/audio/footsteps.gd)
- M06. When a lost Sock comes back, then everyone hears "lost_pop" at each place. (ref: game/audio/hearing.gd:13-18)
- M07. When a Door or drawer opens or shuts, then everyone hears it at the Door in 3D (the one toggled signal); a joiner's whole-state arrival is silent. (ref: game/parts/openable.gd:25; old game/audio/sound_installer.gd:62-69)
- M08. When the 3D sounds play, then each uses the world's voices, unit size 3.0 and max distance 20 m. (ref: docs/migration/audit-core-looks-sound.md:119-123; old data audio.json world_unit_size, world_max_distance)
- M09. When a Guest's own game plays a sound the Host's answer causes (pick, drop, throw), then the sound is played on the answer's arrival, not predicted, except the Throw's, which plays with the ghost at release; the pick's sound plays at the click with the ghost (changed by Q2478). (ref: old game/hands/hands_rules.gd:147-161 (cue at the answer, `settle_pick`); 359-378 (`cue.emit(by, "throw")` at once))

### Backlog Co-op items (each must be built here)

- Z1. [backlog 1] A Guest's capacity and reach (Hands read `HandsTuning` of a player on this machine, else their own): see D13; a leaver's Hands stay HELD: D14; a falling Sock seen by a Guest as the untinted body: B16. (ref: docs/migration/m06-backlog.md:46)
- Z2. [backlog 2] A Guest's Throw leaves from `EYES_FALLBACK` 1.5 m: see G15; only the local body lets its own thrown Sock through (`Mess._spare_thrower`): G15. (ref: docs/migration/m06-backlog.md:47; game/mess/mess_moving.gd:506-512)
- Z3. [backlog 3] Woken flights are spawned nodes (up to 512 over the spawner on a big wake) with no synchronizer yet: see B01, B05, H02; Doors and drawers sweep on the Host only: see C02. (ref: docs/migration/m06-backlog.md:48)
- Z4. [backlog 4] Co-op cost: every `add` and `rest` answer carries the whole arrays: see A07, B03. (ref: docs/migration/m06-backlog.md:49)
- Z5. [backlog 5] The heap sign's Moving count is the Host's flights; a Guest shows 0: see B14. (ref: docs/migration/m06-backlog.md:50)
- Z6. [backlog 6] `Footsteps` plays flat at full level: Guests' footsteps spatial: see M05. (ref: docs/migration/m06-backlog.md:51)
- Z7. [backlog 7] A Guest finds a flight's spawned copy by its name (`Flight<id>`); a rest and a wake in one tick renames the body: see B12, L07. (ref: docs/migration/m06-backlog.md:52)

## Invariants

- I1. One writer of the Mess: the Host. A Guest's Mess is read-only; it changes only by the Host's answers and snapshots. (ref: docs/migration/coop-structure-for-the-port.md:111; game/mess/mess.gd:461)
- I2. Prediction is looks only: a ghost has no handle to the Mess or the Hands, writes no state, and is gone or blended when the answer comes. (ref: docs/migration/decisions.md:100-102; game/parts/parts.gd:110)
- I3. A Guest's ghost body lives on its own physics layer and collides with the static house only: no lying Sock, no Moving Sock, no Cabinet, no Teammate. (ref: old game/core/layers.gd:18; docs/migration/coop-structure-for-the-port.md:112)
- I4. The Host owns every released body (drop, Throw, spit) from release to rest; a body's authority never changes. (ref: docs/migration/coop-structure-for-the-port.md:97; decisions.md:102)
- I5. Every Sock is in exactly one place on the Host at any time (lying, held by one player, flying, half of a Pair, shelved); a Guest's machine may show a ghost of a Sock that is also lying, but never counts it. (ref: old behaviour-core-loop.md I.1; game/mess/mess.gd:1-12)
- I6. Every Design keeps exactly two records through every pick, drop, Throw, pairing, shelving, join and leave. (ref: old behaviour-core-loop.md I.2; game/mess/mess.gd:7-12)
- I7. A Guest's Command is shape-checked, rate-limited and verb-checked on the Host before anything reads it; a bad one is dropped and counted. (ref: game/parts/session.gd:190-217)
- I8. Only the Host's rest rows put a Sock to rest; a Guest's own run is for looks and snaps to those rows. (ref: decisions.md:103; old game/world/sock_record.gd:305)
- I9. The Host's flight stream carries the body's own clock so jitter never stalls it; the Guest plays 0.1 s behind. (ref: old game/world/flight.gd:38, 186; tests/net_throw_test.gd:273)
- I10. Every flight ends exactly once: landed, caught, shelved or binned. (ref: old behaviour-core-loop.md I.8)
- I11. Nothing in the Mess is drawn smeared between two ticks: no MultiMesh of the Mess is physics-interpolated on any machine. (ref: docs/architecture/mess.md Q2407)
- I12. No Teammate steals from another player's Hands; items change hands only by hand-off or catch that completes a Pair. (ref: old behaviour-core-loop.md I.3)
- I13. A refusal is told to the asker alone. (ref: old digest D:174 Q246; game/player/player.gd:545-575)
- I14. A body one machine names `Flight<id>` is the same Sock on every machine; one Sock has one body on a machine at a time. (ref: game/mess/mess.gd:55-60, 880-900; backlog 7)
- I15. A Guest of another build receives no spawn, no synchronized value and no RPC (the gate). (ref: game/parts/session.gd:6-11)

## Numbers

| What | Value | Where |
|---|---|---|
| Blend of a Guest's own Throw onto the Host's flight | 0.2 s (`release.predict_blend`), 95 per cent of a difference in that time, `k = 1 - exp(-3 dt / fix_time)` | data/tuning/release.json:6; thrown_item.gd:155 |
| Guest plays the Host's body behind its stream | 0.1 s (`Flight.STREAM_LAG`) | game/world/flight.gd:38 |
| Rows kept in a feed | 90 | game/world/flight.gd:190 |
| Stream row | `[id, pos, rotation, velocity, clock]`, about 80 bytes, every tick, unreliable ordered channel 1, per body | game/net/streams/flight_stream.gd:2-4; digest D:252 |
| Teammate Throw's model joins the flight | 0.2 s (`avatar.teammate_throw_blend`) | data/tuning/avatar.json:32 |
| Teammate Throw's pause at release | about 3 ticks (50 ms) | digest D:279 |
| Own Throw's catch-up from the hand (old, gone by Q2356) | 0.1 s (`release.catch_up`) | data/tuning/release.json |
| A drop's flick (old, gone by Q2367) | 0.1 s; hold 3 cm | data/tuning/release.json |
| Ghost settled onto the Host's rest | under 0.002 m, wait at most 2.0 s; cloth flat wait at most 1.5 s; model kept 3 frames | thrown_item.gd:163; flights.gd:384-403 |
| Fly of a landed Sock into its Mess place | 0.18 s, arc 0.04 | flights.gd:335, 343 |
| Re-lay of a lander off by more than 0.005 m or 0.03 rad | 0.15 s, arc 0.02 | drop_view.gd:105-112 |
| A flight not settled | put down after 6 s (`release.max_age`) | data/tuning/release.json |
| Flat cloth | under 0.6 m/s after first impact (`release.flat_speed`) | data/tuning/release.json |
| Pick fly in (port) | 0.3 s, hop 0.18 m | game/hands/hands_tuning.gd (`pick_time`, `pick_hop`) |
| Refused pick flies back (old) | 0.45 s, arc 0.22 (`cloth.flight_time`, `flight_arc`) | data/tuning/cloth.json:11-12 |
| Refusal wobble | 0.45 s, 0.07 rad, 5 per s; text stays 2.0 s | hud.gd:23-25; hands_tuning.gd:47 |
| Grab interval | 0.35 s (Host's clock) | game/hands/hands_tuning.gd:14 |
| Reach | 2.5 m plus `reach_slack` | game/hands/hands_tuning.gd:9-12 |
| Guest's eyes fallback | 1.5 m (placeholder until M0.6) | game/hands/hands_tuning.gd:78 |
| Guest rates | picks 10 a s, Throws 5 a s, shelves 5 a s, Doors 5 a s, default per verb `RATE` | hands.gd:120; hands_tuning.gd:73; cabinet.gd:328; openable.gd:74; session.gd:36 |
| Throw charge | full in 1.2 s, tap under 0.15, speed 3 to 5 m/s, lob 3.5 plus 2 up | game/hands/hands_tuning.gd:51-58 |
| Throw spin | port `spin` (2, 1, 3); old Host clamp (6, 3, 6) | hands_tuning.gd; old hands_rules.gd:24 |
| Throw wake look-ahead | 0.12 m sphere, 2 ticks ahead, at most 8 touching, wake speed 1.5 m/s | game/hands/hands_tuning.gd:66-71 |
| Moving budget | 512, 32 kept for Throws and drops, 16 woken a tick, stop cap 8, sweep cap 32 | game/mess/mess_tuning.gd:10-34 |
| Rest | still 0.3 s (`rest_time`) | game/mess/mess_tuning.gd:44 |
| Teammate's cues | 3D at the avatar plus 1.2 m; flat for own | old sound_installer.gd:47-52 |
| 3D voices | unit size 3.0, max distance 20 m | audio.json |
| Teammate's pairing burst | 20 specks, size 0.035, speed 1.0, 0.55 s, ring 0.3 | old paired_moment.gd:26-27 |
| Own pairing moment | 0.5 s, 44 specks | old paired_moment.gd:22-24 |
| Snapshot size | about 40 KB for 1,000 Socks (old, with the whole state); port 4,000 records with 2,000 poured per answer | digest D:252; backlog 4 |
| Players | up to 4 (`max_guests` 3 in port) | session.gd:47 |
| Measured bar at 100 ms round trip | leave 1 tick, move within 3 ticks, largest step under 0.08 m, the ghost leads the Host's body about 3 ticks | old tests/net_throw_test.gd:253-271; coop-structure.md:90 |
| Avatar updates | every frame, light easing (Q2223) | decisions.md:104 |

## Already in the port

- Exists: Mess as one Part with a snapshot (every Part's State by id) and a late Guest's `load_snapshot`. (game/parts/parts.gd:149-160; game/parts/session.gd:182-187)
- Exists: the gate (protocol), Commands up with shape, verb, args and rate checks, answers down, `first to arrive wins`. (game/parts/session.gd:190-217)
- Exists: `Mess.decide` refuses any Command not by the Host for `rest`, `wake`, `fall`, `add`, `take_out`; no Guest call exists. (game/mess/mess.gd:461-466)
- Exists: the Host starts bodies only (`if _is_host(): _moving.start`) and Guests start none. (game/mess/mess.gd:659)
- Exists: bodies under the flights holder named `Flight<id>`, found by name on a Guest; the zoo has a `FlightSpawner` with two scenes. (game/mess/mess.gd:55-60, 880-900; game/zoo/zoo.tscn:149-152)
- Missing: a synchronizer on each flight and the stamped stream (the `row` property with `feed_pose`, `play_stream` 0.1 s behind). A Guest's copy is a spawned node with no motion. (docs/migration/m06-backlog.md:48)
- Missing: a Guest's own simulation of woken Socks and the snap to the Host's rest rows (B01, B05). Today a `rest` answer carries the whole arrays instead of rows. (game/mess/mess.gd:461-474; backlog 4)
- Missing: a Guest's sweep of Doors and drawers; `_sweep_movers` runs on the Host only. (game/mess/mess_moving.gd:308; `tick` called only if `_is_host()`, game/mess/mess.gd:684-690)
- Missing: any ghost: a looks-only pick ghost, a drop ghost, a Throw ghost on its own layer, `PREDICT` layer constant, a blend, `take_predicted` by `seq`. `Parts.ask` documents "Prediction ... looks only" but builds none. (game/parts/parts.gd:109-116)
- Missing: the "it flies back" look for a refused pick (and for a race loser flying to the winner). (game/player/player.gd:545-575 only shows the words)
- Missing: a `seq` on Commands to match an answer with a ghost; the Host's answer names `kind`, `by`, `to`, not a Guest's sequence. (game/parts/parts.gd:122-127)
- Missing: a Guest's eyes: `eyes_of` falls back to 1.5 m above the avatar's pose; the avatar has no eyes pose. (game/hands/hands.gd:367-374; game/hands/hands_tuning.gd:78)
- Missing: a HoldPoint on a Teammate's avatar (the avatar is a capsule), so a Teammate's held Socks and a Teammate's Throw leaving the hand have no place. (game/parts/avatar/avatar.gd)
- Missing: `_spare_thrower` reads only players on this machine; a Guest's avatar is not one. (game/mess/mess_moving.gd:506-512)
- Missing: Teammate sounds: `Hearing.applied` plays only `own` moments, 3D shelve aside. (game/audio/hearing.gd:20-41)
- Missing: a Guest hearing the bounces (`MessMoving._bounce` runs only on the Host). (game/mess/mess_moving.gd:523-530)
- Missing: the heap sign's Moving count on a Guest (reads the Host's flights). (docs/migration/m06-backlog.md:50)
- Missing: Guests' footsteps in 3D. (docs/migration/m06-backlog.md:51; game/audio/footsteps.gd)
- Missing: a Teammate's shelving flight and sparkle burst; a teammate's pairing small burst. (docs/migration/old-details-backlog.md; game/sock/pair_moment.gd has no teammate path)
- Missing: a Guest's `HandsTuning` on the Host (`tuning_of(by)` falls back to the Host's default for an unknown player). (game/hands/hands.gd:84-97; backlog 1)
- Exists: refusals and wobble (`Player.say`, `Hud`), the red crosshair, `Hands.pick_refusal` and `drop_refusal` the Guest runs on its own copy, `HandsTuning.throw_rate`. (game/player/player.gd:373-427; game/hands/hands.gd:133-176)
- Exists: the Throw's launch decided by the Host from `dir` and `charge` with `start_of` the hand's place (Q2356) and a drop from the hand (Q2367). (game/hands/hands.gd:258-352)
- Exists: Cabinet `shelve` for a Guest (rate 5) and the Host's `thrown_shelve`; `Hearing` plays "shelve" in 3D at the drawer for everyone. (game/entities/cabinet/cabinet.gd:315-428; game/audio/hearing.gd:44-61)
- Exists: `Part.write` shows a late Guest's Doors open with no sound. (game/parts/openable.gd:25)
- Exists: the Mess's MultiMeshes are not physics-interpolated (Q2407). (docs/architecture/mess.md)
- Not decided in the port: whether a drop and a wheel turn get a ghost (Questions 1, 3).
- No Guest test: no suite hosts a Guest and a late joiner (the zoo suite has no net case). (tests/zoo_test.gd)

## Questions for the designer

1. **A Guest's drop.** Q2221 gives the Throw an instant ghost; Q2220 gives the pick one. The drop is not answered. At 100 ms the old game let the Sock fall at once on a looks-only body that blended to the Host's. Should a Guest's drop fall at once (recommended, as the Throw and the old game), or should the Sock stay in the Hands until the Host answers?
2. **A second pick before the first answer.** At 100 ms a Guest may click twice before any answer. Should the second click wait until the first is answered (simple, nothing is hidden), or fly a second ghost at once (the old feel of chaining picks)? Q2220's recommended text said the second waits; the answer did not say.
3. **The wheel.** Old: the Guest's wheel turned at once and was undone on a refusal. With Q2220 only the pick is looks only. Should the wheel turn at once on the Guest (recommended; undone silently) or after the answer?
4. **A refused Throw or drop.** For a refused pick the Sock flies back (F01). For a refused Throw or drop (Hands empty on the Host, too far, no spot) the old game just removed the ghost and put the item back in the Hands. Keep that (recommended), or fly the ghost back to the Hands like a pick?
5. **A ghost that never gets an answer.** Nothing in the old game ended a Guest's waiting ghost. After how many seconds should an unanswered pick, drop or Throw go back to the Hands (recommended: 2 s, the refusal text time) with "refuse"? Or never?
6. **A Teammate's Throw start.** Q2226 keeps the old look "with the short pause at release". Q2356 (and Q2367) moved the body's start to the hand, so there is no hand-to-eyes blend left and the pause came from that blend plus the 0.1 s lag. Should the Teammate's Throw still blend its model from the avatar's hand over 0.2 s and still pause about 50 ms at release (the old look, kept literally), or leave from the hand at once and wait only the 0.1 s lag (recommended, nothing to blend)?
7. **When a Guest hears its own pick.** The old game played "pick" at the Host's answer (the sound is in `pick_into`); "throw" played at once. Should the Guest's pick sound play at the click, with the ghost (recommended, it feels instant), or at the answer?
8. **A Sock in the air when someone joins.** A late Guest can see a Sock that is mid-flight fly on from where it is (recommended), or see it only once it lies. Which?
9. **A refused pick that was a Pair.** Under Q2220 the Guest's Hands never change before the answer, so the old "Pair splits back" cannot happen. Confirm that the pairing moment starts only on the answer (a short wait at 100 ms), not at the click.
