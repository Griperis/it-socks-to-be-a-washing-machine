---
type: ticket
status: done
kind: build
area: core
feature: core
priority: next
created: 2026-11-21
done: 2026-11-23
blocked_by: []
notes: ["tracked, not planned (Q2430); the catalogue's milestone: M3", "triaged to M3, soon (Q2533, 2026-11-23)", "suggested model: opus (co-op, physics)"]
terms: []
---

# Player stacking

Port of the old game's stacking on a teammate's back (catalogue B07, `game/player/rig_stack.gd`; leftovers P27).

## Acceptance
- Built from `docs/migration/m3-lists/01-player-stacking.md` as answered (Q2590, Q2591).
- A BACK layer and a back disc per player: radius 0.3 m, 0.1 m thick, top 0.3 m under the top of the body, following crouch and stand; off while its player is knocked down, in the drum, or at the top of a stack of 3 (lines 1-8).
- Walking on from a surface as high as the back, and the climb jump within 0.9 m with room for a crouched body (lines 9-19, 12-17): clears the back by 0.15 m, tucks into a crouch, steers over the middle until landing.
- A rider moves with the disc, stays crouched, walks off the edge and falls, with the land sound (lines 20-26, 35-38); a carrier walks at 0.5 pace and stands up only with room for the stack (lines 28-34).
- The soft push between standing players (lines 45-50): 0.6 m, 8 per second, lower id steps aside, skipped at different heights.
- ~~No riding id or offset in the pose (Q2591)~~ replaced by Q2592: the pose carries whom the rider rides and where on the back; each machine still moves its own body on the disc.
- Climb and ride have no sound, look or animation of their own (lines 18, 44), as the old game.
- Real-path case (kit/docs/TESTING.md "The real path"): two players in the zoo station: player B's pressed jump action near player A's back, through the Player's own wiring, ends with B standing on A's disc (B's feet at A's back height) and moving with A when A walks; A's pace is halved.
- Co-op cases at 0 ms and 50 ms one way (two machines in one process): B climbs onto A and A walks a loop; on each machine B's drawn position stays within a typed bound of A's on-screen back, with no jitter step larger than a typed bound (at 50 ms too). If the 50 ms case shows the rider jittering, STOP and report: adding a riding offset goes to the designer first (Q2591).
- Small details kept (Q2277): every numbered line of the list is built, or named in the ticket as dropped by the designer; each carries a typed Resource number marked `# placeholder`. Look and feel numbers get no test (Q2421); its station shows them.
- A zoo station for the feature (the `zoo-design` skill), then it lands in the main scene; `kit/tools/run.sh --touched` ends PASS.

## Answers
- Tracked as a ticket, not planned yet (Q2430, 2026-11-21).
- Q2588-Q2589 do not touch this ticket. Q2590: every recommended answer stands: a rider stays crouched; no rider jump; the carrier may jump and a knockdown drops the rider; carry pace 0.5 and 3 players at most; no climb/ride look or sound; the rider's waddle as old; the disc has no soft edge; solo high spots stay in M6 (P27).
- Q2592: (b) the rider's pose carries the old game's riding offset (on whom, at what spot), so every machine draws the rider on the back (replaces Q2591's no-id; 2026-11-23).
- Q2593: the old jump and land sounds are ported for every jump, climbs included, on every machine (2026-11-23).
- Q2591: the stack is a plain collider (the back disc), each machine moving its own body on it; no riding id in the pose; an offset only if the 50 ms case shows jitter, and then the designer first (2026-11-23).

## Open follow-ups
- [answered, see Answers] The rider's crouch (list 01, line 22). Old: a rider stays crouched on a back even where the ceiling lets them stand. Options: (a) keep (recommended: stacks fit under 2.6-2.7 m ceilings, no new rule); (b) the rider stands where there is room; (c) a deeper crouch (a new avatar shape).
- [answered, see Answers] A rider's jump (line 22). Old: none (a crouched player cannot jump), so a rider walks off and cannot climb to a third. Options: (a) keep (recommended); (b) a rider may jump off, or climb onto a third back with the same rule.
- [answered, see Answers] The carrier's jump and a knockdown (lines 31-32). Old: the carrier may jump with a rider (they ride along), a knockdown drops the rider. Options: (a) keep (recommended); (b) forbid the carrier's jump while carrying.
- [answered, see Answers] Carry pace and stack size (lines 6, 28). Old: pace 0.5 for every carrier, at most 3 players. Options: (a) keep both numbers (recommended; typed Resource placeholders); (b) a slower pace for a taller stack; (c) two players at most.
- [answered, see Answers] Climb and ride look and sound (lines 18, 44). Old: only the jump and land sounds; no tuck, push-off, riding pose or cue (spec follow-up 0, never built). Options: (a) keep (recommended; a later look ticket may add); (b) add a tuck and a push-off sound now; (c) add a riding pose for the rider's avatar.
- [answered, see Answers] The rider's waddle while carried (line 43). Old: the avatar waddles on other machines. Options: (a) keep (recommended: as old); (b) hold the waddle still while riding.
- [answered, see Answers] The disc's edge (line 23). Old: a 0.6 m disc with no rim; riders walk off by accident. Options: (a) keep (recommended); (b) a wider disc for the rider's feet; (c) a soft edge that slows the rider.
- [answered, see Answers] Solo high spots, P27 (line 53). Old: none (Q664: alone the Sock is placed reachable). Options: (a) leave to M6 as the catalogue says (recommended); (b) add a jump Upgrade now.
- [answered, see Answers] How a stack is decided across machines (co-op section). Old: nothing is decided state; each machine runs its own body and the pose carries the riding id and offset. Options: (a) keep, as a pose property of the avatar's synchronizer (recommended: same feel, no new Command); (b) a Host-decided Stack Part (fixes the climb-onto-a-moving-Teammate lag, costs a trip and a refusal path).
- [answered, see Answers] The rider as the carrier's machine draws it (Q2591, the co-op case). Built as answered: no riding id or offset in the pose; each machine moves its own body on the disc. Measured (`coop_stacking:carried_loop`, A walking a loop at the carry pace 2 m/s): on the rider's own machine the rider stays on the carrier's drawn disc (0.01 m off its middle) with no jitter (0.000 m). On the carrier's machine the rider is drawn 0.44 m (0 ms) and 0.67 m (50 ms) behind the carrier's back, off the 0.6 m disc, floating beside its head while they walk (two eased glides plus both lags). There is no jitter of the stack's own: frame to frame the rider moves there as smoothly as the same player walking alone (0.0003 m at 0 ms, 0.009 m at 50 ms, against 0.006 and 0.009 m alone), so by Q2591's test no offset is due; the trail is the question. It does not slip: the carrier still counts the rider and keeps the half pace. Options: (a) keep as built (the rider trails the carrier on the carrier's screen); (b) add the old game's riding offset to the pose even so (the rider's place from the carrier's feet; the others draw the rider at the carrier's drawn body plus it), recommended: the rider then sits on the back on every screen, and it is the old game's way; one synchronized property, PROTOCOL up. The case `coop_stacking:carried_loop_seen` holds rule (b) and is off until the designer answers.
- [answered, see Answers] The ordinary jump has no sound in the port (the old game played "jump"; the catalogue has no `jump` event). A climb plays what the ordinary jump plays (line 18), so it is silent too. Found while building; not this ticket's to add.
- [later] Lines waiting for other pieces: 5 (no back in the drum) waits for the washing machine; 27 (no ladder while riding) waits for the Grotto ladder (M5); 50 (spawn 0.6 m apart) is the spawn piece's.
- [later] Seen on the carrier's machine only: when the carrier crouches or stands with a rider on, the rider's drawn body takes about 0.2 s to follow the back, and for that time the carrier does not count them (full pace, no load for the stand-up check). Small and short; goes with the offset question above.

## Built log
### 2026-11-23
- Changed: step 1 only, the behaviour list `docs/migration/m3-lists/01-player-stacking.md` (54 details, each with its old file:line, the weak points, the Host/Guest split, what is already in the port). The soft push (Q263, lines 45-50) is in the list too. Nine open choices. No game code.
- Files: `docs/migration/m3-lists/01-player-stacking.md`, this ticket.
- Verified: docs only, no suite run. The list is for the designer to approve; the ticket stays `needs-info` until the [blocking] questions are answered.

### 2026-11-23 (shaped)
- Changed: shaped for building after Q2588-Q2591: answers, checkable Acceptance, model, status ready-for-agent. Docs only.
- Files: this ticket.
- Verified: docs only.

### 2026-11-23 (built)
- Changed: player stacking and the soft push, from the list as answered (Q2590, Q2591). Every Avatar has a `Back` (a static disc on its own BACK layer 256, 0.3 m round, 0.1 m thick, 0.3 m under the top of the body as drawn on this machine, crouched or standing at once; off while knocked down or on top of a full stack). The Player's new `Stack` (`PlayerStack`) meets a back only from above, rides it (moving its own body by what the back moved; a rider stays crouched, so cannot jump), climbs onto one with a jump within 0.9 m (clearing it by 0.15 m, tucked, steered over its middle until landing; no climb without room for a crouched body), walks at 0.5 pace with anyone on its own back, stands up only with room for the stack, slips off a lying body, and does the soft push (0.6 m, 8 a second, lower id goes right, none at different heights, none from a body it drags). Who stands on whom is read from where bodies are drawn (`Stacks`), nothing sent. A rider's steps sound by the floor under the stack. The Stacking zoo station (stand-in carrier that walks its loop and crouches while ridden, a ledge as high as a back, a stand-in under a low board, the numbers read from the tuning at load). It lands in the house through the same player and avatar scenes. PROTOCOL 14 (the avatar scene has a new child).
- Files: `game/stacking/` (back, player_stack, stacks, stacking_tuning), `game/player/player.gd`, `player.tscn` (mask 329, Stack), `game/parts/avatar/avatar.gd`, `avatar.tscn` (Back), `game/audio/footsteps.gd`, `game/parts/session.gd`, `game/zoo/stations/stacking.tscn`, `game/zoo/stacking/stack_stand_in.gd`, `game/zoo/zoo.tscn`, `tests/stacking_test.gd`, `tests/coop_stacking_test.gd`, `tests/coop_knockdown_test.gd` (its `inside` case turns the soft push off: two players 0.25 m apart), `tools/shot_stacking.gd`, `tools/shot_hooks.gd`, `docs/architecture/coop.md`. Strip: `builds/review-player-stacking/climb-and-carried-walk-strip.png` (main checkout).
- Verified: see the commit's `suite:` line. Stays `needs-info`: the [blocking] question on the rider as the carrier's machine draws it (the 50 ms case).

### 2026-11-23 (Q2592, Q2593)
- Changed: main merged in (core/62 game link). The riding pose (Q2592): the Avatar's synchronizer carries `pose_riding` (whose back, -1 none) and `pose_ride_offset` (from their feet, at most `ride_reach` 2.5 m, else dropped); the owner writes it from the back its body stands on; every other machine draws the rider at the carrier's drawn feet plus an offset easing to the sent one, so the rider sits on the back on every screen. Who rides whom (carry pace, load, stack height) now reads the pose; the two "seen" reach numbers are gone. Jump (Q2593): a `jump` event in the catalogue, played on every jump and climb by the player (flat) and at the body on every other machine (the pose's jump count, `TeammateSteps`); the old game's jump had no pick, so it is silent until a clip is added; land was already ported. `AvatarLooks`' squash spring steps at most 1/60 s a step (a slow frame blew it up in the two-process strip). The station's review helper (`StackStandIn.review()`) drives a two-process session. PROTOCOL 15 (main's 14 + 1).
- Files: `game/parts/avatar/avatar.gd`, `avatar.tscn`, `avatar_tuning.gd`, `avatar_looks.gd`, `game/audio/teammate_steps.gd`, `sound_catalogue.tres`, `game/player/player.gd`, `game/stacking/stacks.gd`, `player_stack.gd`, `stacking_tuning.gd`, `game/parts/session.gd`, `game/zoo/stacking/stack_stand_in.gd`, `tools/shot_stacking.gd`, `tests/coop_stacking_test.gd` (`carried_loop_seen` on, `jump_heard`), `tests/stacking_test.gd`, `docs/architecture/coop.md`. Strips (main checkout): `builds/review-player-stacking/climb-and-carried-walk-strip.png`, `carrier-and-rider-side-strip.png` (two processes: the carrier's machine, rows 1-2, and the rider's, row 3).
- Verified: measured on the carrier's machine B drawn 0.04 m off A's back at 0 and 50 ms, jitter 0.000 m; see the commit's `suite:` line.
