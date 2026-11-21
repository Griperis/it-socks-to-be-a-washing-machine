---
type: ticket
status: needs-triage
kind: build
area: core
feature: core
priority: now
created: 2026-11-21
done:
blocked_by: []
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
- Q2279-Q2281, Q2286, Q2287, Q2291, Q2296 (2026-11-20). Q2315, Q2316 (a teammate's shelving flight and sparkle burst
  are M0.6). Q2332 (stiff during a catch-up; the catch-up goes with Q2356). Q2277 (every detail listed).
- The Cabinet's "+N" Coins pop, new Rows dropping in: M4. Pad stick curve: later (Q2235). Teammate's waddle, squash and
  stretch: M0.6 (`avatar.json`).

## Open follow-ups
- [blocking] Q-a: the old cloth bend and ground straightening against core/09's spring-bone node (Q2286, Q2287, built
  by the node). Options: 1) port the old springs and probes as they were (the old look, more code); 2) keep the node and
  tune it until a steady walk hangs still and the ground never crumples (Godot's own node first); 3) a hybrid: the node
  with the old acceleration input only (P06) and its own ground (P07 dropped).
- [blocking] Q-b: P05 and P09 after core/23 (Q2356): the Throw leaves from the hand on an arc, so its catch-up goes. Is
  the drop's flick kept with its ease and its stiff hold? Options: 1) yes, the flick stays as the old (recommended);
  2) the drop leaves from the hand on an arc too.
- [blocking] Q-c: the sunk Sock (P13) and the lost Sock's return (P12) in the zoo. Options: 1) the zoo's pad (Q2261) with
  the old numbers; 2) as 1 and a button in the station that sinks or loses a Sock to see them.
- [blocking] Q-d: P15's Door and cupboard timings: the port has the Door 0.4 s (Q2213 names 0.6) and the cupboard 0.4 s
  linear. Options: 1) the old: Door 0.6 s in-out, cupboard 0.35 s out; 2) keep the port's times and add the ease only.
- [blocking] Q-e: "Paired!" is a plain white 2 s line in the old game. Options: 1) as the old; 2) a short pop of the text
  as well (a look change, its own ticket per Q2153).

## Built log
