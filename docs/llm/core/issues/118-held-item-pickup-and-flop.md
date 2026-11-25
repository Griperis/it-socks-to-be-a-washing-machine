---
type: ticket
status: ready-for-agent
kind: bug
area: core
feature: hands
priority: now
created: 2026-11-25
done:
blocked_by: []
notes: ["suggested model: opus", "designer 2026-11-25, Windows build"]
terms: [Hands]
---

# Picking up an item in mid-air, and the flop in the hand

Two things the designer saw in the Windows debug build:

1. **An item picked up in mid-air sits differently in the Hands.** "You can pickup items (e.g. the laundry bin)
   in mid-air and it will have different transform in hands." Picked up while flying or falling (thrown, knocked,
   falling off a ledge), the item ends up in the Hands at a different pose than one picked up lying still. Find
   where the held pose takes the item's current rotation or velocity (the carry, `game/hands/`, the Carriable)
   and make a mid-air pickup end in the same held pose as a resting one. Check whether the old game allowed a
   mid-air pickup at all (`reference/it-socks/game/hands/`, `game/player/rig_*.gd`). If it didn't, say so and do
   what it did.
2. **The flop in the hand flickers.** "The flop in hand still doesn't look like in the previous game, it's too
   flickery." The held Sock's flop (its sway and droop as the player moves and turns) is jittery compared with the
   old game. Compare frame by frame with the old `held_view.gd` (the flop's spring or smoothing, its numbers in
   `data/tuning/`, which frame it runs in: process or physics, interpolation). Look for a physics/process mismatch,
   a missing smoothing step, a number that differs, or a target that jumps each frame.

## Acceptance
- A mid-air pickup and a resting pickup of the bin and of a Sock end in the same held pose (a real-path case
  with a thrown bin caught mid-flight).
- The flop matches the old game's motion: a strip of old beside port, walking, turning and stopping, at 60 fps and
  at a low frame rate (30), in `builds/review-core-118/`. Look work stops there: `ready-for-human`.
- Numbers stay in their tuning Resource. The hands suites pass, nothing flaky.

## Open follow-ups

## Built log
