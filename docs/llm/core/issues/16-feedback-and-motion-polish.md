---
type: ticket
status: done
kind: build
area: core
feature: core
priority: now
created: 2026-11-21
done: 2026-11-21
blocked_by: ["[[11-outline]]", "[[23-flights-flip-and-throw-from-hand]]"]
notes: []
terms: []
---

# Feedback and motion polish: the small details of the core

M0.5 batch 5 (Q2279-Q2281, Q2286, Q2287, Q2291, Q2296, Q2315, Q2316). Every small motion, glide, fly, sway and pop of
the old core that the port lacks is listed here; only the designer drops one (Q2277). The old code:
`reference/it-socks/game/ui/hud.gd` (refusal, message), `game/ui/ui_bits.gd` (`size_box`), `game/world/sock_ball.gd`,
`game/hands/thrown_item.gd`, `game/hands/drop_view.gd`, `game/world/sock_actor.gd`, `game/hands/paired_moment.gd`,
`game/campaign/campaign_installer.gd:92`, `game/hands/landings.gd`, `data/tuning/{ball,paired,release,cloth,lost}.json`.

## How the old one works
- **The refusal** is a message in red that turns to and fro for 0.45 s, `sin(t * TAU * 5) * 0.07 rad` dying down
  linearly, about its middle, and stays 2 s (`hud.gd:22-24, 646-660, 689`). Same cue as the "refuse" sound.
- **"Paired!"** is an ordinary white message (28 pt, 2 s) sent when a pick completes a Pair (`game.gd:1461`).
- **The held Size box** is the same boxed letter as the aimed one, beside the active item, following it, the zoom and
  the sway (`hud.gd:452-500`, `held_view.gd:785-815`).
- **The ball's landing** (`sock_ball.gd:263-345`): it flies an arc to a spot `roll_distance` short of its rest, squashes
  (`squash` 0.28 over 0.16 s, `sin` curve, about its bottom, along world up), hops (`bounce_height` 0.04 over 0.2 s)
  while rolling `roll_distance` 0.12 to its rest, then squashes again. Used for a dropped Pair (`drop_view.gd:150`),
  a floor ball put back (`floor_balls.gd:56`) and a shelved one (`campaign_installer.gd:92`).
- **The drop flick** draws the dropped item from the hand to the spot in `flick` 0.1 s with `smoothstep`; a Throw's
  catch-up eased out quadratically over `catch_up` 0.1 s (`thrown_item.gd:180-228`, `release.json`).
- **Cloth** (`cloth.json`, `sock_actor.gd:318-350`): gravity minus the smoothed acceleration (smoothing 0.1 s, cap 12),
  so a steady walk hangs still and a start, stop, jump or turn bends it. Near ground `_ground_room()` halves the bend
  until no probe point is under the floor (`sock_actor.gd:388-420`). A flick or a catch-up holds it stiff
  (`bend_limit = 0`, `thrown_item.gd:233`).
- **Lost Socks** come back to a spot 0.65 m in front of the washer scattered within 0.2 m with a "pop" at each; one
  sunk 0.02 m or more into a floor slab is pushed up onto the floor, with a pop unless it was only pushed up
  (`lost.json`, `hands_rules.gd:490-510`).

## Behaviour list
- P01 When a refusal is said, then its red line turns to and fro 0.45 s, 5 swings a second, up to 0.07 rad, dying
  down, and stays 2 s (`hud.gd:646-660`, `hud.gd:22-24`).
- P02 When a pick completes a Pair, then "Paired!" shows in the message row for 2 s (`game.gd:1461`).
- P03 When something is held, then its Size letter shows boxed beside the active item, following it as it glides,
  zooms and sways; nothing when empty (`hud.gd:452-500`).
- P04 When a Pair lands from a drop or a shelve, then it squashes 0.28 for 0.16 s, hops 4 cm in 0.2 s while rolling
  12 cm to its rest (less than half the distance when short), and squashes again (`sock_ball.gd:263-345`, `ball.json`).
- P05 When a Sock is dropped, then its drawn model eases from the hand to the spot in 0.1 s, slow at both ends
  (`thrown_item.gd:180-228`, `release.json` flick).
- P06 When the Sock moves at a steady speed, then its cloth hangs still; it bends only when speed or direction
  changes (start, stop, jump, turn) (`sock_actor.gd:328-346`, Q2286).
- P07 When a cloth Sock is near the ground, then its whole bend straightens until no part dips below
  (`sock_actor.gd:388-420`, Q2287).
- P08 When a held Sock is thrown, then it leaves with the bend it had in the hand (Q2315).
- P09 When a held Sock is let go with a flick, then it is held stiff during the flick (`thrown_item.gd:233`, Q2332;
  the catch-up itself goes with core/23, Q2356).
- P10 When a shelved Pair arrives in its slot, then it lands with P04's squash, hop and roll (Q2316).
- P11 When a Pair is thrown into a drawer front, then its flight goes on to its slot (Q2316).
- P12 When a Sock or Pair is lost, then it returns in front of the washer (the zoo's return spot, Q2261) scattered
  within 0.2 m, and a "pop" plays at each (`lost.json`, `hands_rules.gd:497, 508`; sound: core/25).
- P12b When P12 brings a lost Sock or Pair back, then "pop" plays in 3D at each (moved from core/25 W15).
- P13 When a Sock is sunk 0.02 m or more into a floor slab, then it is pushed up onto that floor without the pop
  (`flat_layout.gd:280-297`, Q2291).
- P14 When two Socks fuse, then they curl along their cloth bones, curl 1.3, in the fold (`paired.json`, Q2281).
- P15 When a drawer slides, then it eases out both ways, 0.3 s; the room Door swings in 0.6 s with an ease in and out;
  a cupboard swings 0.35 s (`openable.gd:80-85`, `room_door.gd:66`; audit rules "Door and drawer ease"). Drawer ease
  is core/09's D12; the Door and cupboard are here.

## Design (draft)
- Looks only; the Hands, the Mess and the Cabinet decide. Each motion is an animation or a tween in the Looks scene or
  its HUD scene (`SizeBox` shared with core/15), numbers in typed Resources (`BallLanding`, refusal wobble).
- The ball's landing is an `AnimationPlayer` in `looks_ball.tscn`, played by the landing state; the wobble is a
  `Tween` on the `Message` label; the cloth changes go in `sock_cloth_tuning.tres` and `sock_cloth.gd`.
- Lost and sunk Socks: the Mess (Host) places them; the Looks scatter and pop play on the answer.
- Model: Opus (cloth, springs). One still per look: the landing strip, the refusal, the cloth bend at a steady walk and
  at a stop, the return scatter; each stops for the designer's go (review-material).

## Acceptance
- One test per behaviour line; the real-path case: in the handling station the player picks a Sock that pairs, is
  refused with full Hands, drops a Pair and shelves a Pair, and each effect is read from the scene.
- Strips and stills in `builds/review-core-16/`, stopped at the first still for the designer's go.

## Answers
- The cloth keeps the spring-bone node, tuned to flap less; P06 and P07 become "tune the node": a steady walk sways
  little, the ground never crumples it badly; the old springs are not ported (Q2366, 2026-11-21).
- The drop leaves from the hand (Q2367): P05 and P09 move to core/23 and drop out of this ticket.
- "Paired!" gets a short pop of the text, with its own still (Q2370, 2026-11-21).
- The old Door and cupboard timings (Q2368); a station button loses and sinks a Sock (Q2369) (2026-11-21).
- Q2279-Q2281, Q2286, Q2287, Q2291, Q2296 (2026-11-20). Q2315, Q2316 (a teammate's shelving flight and sparkle burst
  are M0.6). Q2332 (stiff during a catch-up; the catch-up goes with Q2356). Q2277 (every detail listed).
- The Cabinet's "+N" Coins pop, new Rows dropping in: M4. Pad stick curve: later (Q2235). Teammate's waddle, squash and
  stretch: M0.6 (`avatar.json`).

- The five looks (cloth, refusal wobble, "Paired!" pop, ball landing, lost return) merge as built; P03, P08, P10,
  P11, P14 and P15 move to their own ticket, core/27 (Q2398, 2026-11-21).

## Open follow-ups
- [later] Not built yet (stopped at the stills, the look-work rule): P03 the held Size box following the
  cloth sway; P08 a thrown Sock keeping its held bend (core/23 left the flying Looks straight); P10 a
  shelved ball's squash in its slot; P11 a Pair thrown at a drawer front flying on to its slot; P14 the
  fold's curl 1.3; P15 the Door's 0.6 s and the cupboard's 0.35 s swings. Each still needs its case.
- [later] The ball's landing plays on the falling body's first touchdown (the port's Pair falls as a body,
  the old one flew a scripted arc): the squash and the 4 cm hop are drawn on the Looks while physics rolls
  the body, so the old "roll 12 cm to its rest" is physics' own roll. A Pair drawn by the MultiMesh (more
  than `flying_cap` in the air) lands without it.
- [later] Lost Socks come back lying at once at the return spot (a random turn, within 0.2 m), not falling
  "like a drop" onto what is there as the old did, so two may overlap (see the still).
- [later] The pop of a returned Sock is a new catalogue event `lost_pop` (same clips and +3 dB as `pop`,
  but spatial and no min gap so each of several plays); `pop` itself is flat for the pairing moment.
- [later] The squash is put on the Body each physics tick from the ball's turn then; a ball still spinning
  fast (10 rad/s) as it lands is drawn up to about 5 mm off its bottom for a tick.
- [later] "Paired!" is white on the handling station's cream wall and reads weakly there (the old colour; see
  paired-full-frame.png).
- [later] `sound_wiring:w10_gap` printed FLAKY on the `--touched` run (already in the ledger from earlier
  runs; not touched here).

## Built log
- Model: Opus.
- 2026-11-21 (stopped at the first stills, look work). Changed: the cloth stiffer (stiffness 2 to 5, so a
  steady walk sways little) and its whole bend straightening within `ground_room` 0.15 m of the ground
  (`SockCloth.ground_gap`, Q2366); the Hud's message row says a refusal in red with the old wobble
  (0.45 s, 5/s, 0.07 rad, dying down) and "Paired!" in white with a pop (0.6 to 1.25 to 1, Q2370),
  2 s (`refusal_time` 1.5 to 2, the old); `Player.say_paired()` on a pick that pairs; `BallLanding` on a
  falling Pair's Looks (an AnimationPlayer built from `BallLandingTuning`: squash 0.28 / 0.16 s, hop
  0.04 / 0.2 s, second squash) on its first touchdown; the Host's `Mess.put_down()` (lost: back at the
  return spot scattered within `return_scatter` 0.2 with a `lost_pop` in 3D at each; sunk 0.02 to 0.3 m
  in a floor: pushed up, no pop) used by every rest; the handling station's Lose and Sink buttons
  (`LoseButton`, Q2369). throw_test and zoo_test read the return spot within the scatter.
  Files: game/sock/sock_cloth.gd, sock_cloth_tuning.gd, looks_{ankle,crew,chunky,tube}.tscn,
  ball_landing.gd, ball_landing_tuning.gd/.tres (+ .uid), game/ui/hud.gd, hud_tuning.gd,
  game/player/player.gd, game/hands/hands_tuning.gd, game/mess/mess.gd, mess_moving.gd, mess_tuning.gd,
  game/audio/hearing.gd, sound_catalogue.tres, game/ui/prompts.gd, game/zoo/lose_button.gd (+ .uid),
  game/zoo/stations/handling.tscn, tests/feedback_polish_test.gd (+ .uid), tests/throw_test.gd,
  tests/zoo_test.gd, tools/shot_hooks.gd (landing_cam, lose_socks).
  Verified: see the commit's suite line. Stills: builds/review-core-16/.
- Merged: 2b4fddcf (2026-11-21, branch core/16-feedback-and-motion-polish)
