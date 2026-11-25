---
type: ticket
status: ready-for-human
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
- [blocking] The flop's look: does the port's flop now match the old one (`builds/review-core-118/`:
  `flop-plot.png` is the clearest, the old flop rebuilt from its code beside the port before and after;
  `flop-now-60fps.png`, `flop-now-30fps.png` and the `flop-before-*` strips are frames, old left,
  port right)? `max_accel` (20 m/s², a placeholder matched to the old flop's size on the plot) is the
  knob for how far it flops on a start or a stop; `accel_smooth` (0.1 s, the old number) for how long.
- [later] Old details of the held Sock's flop the port still draws differently (each is the
  designer's to keep or drop): the old flop's tail is longer (it eases back over about 0.3 s, the
  port's over about 0.15 s, plot); the old bend was limited to half its flying range in the Hands
  (held.json bend_limit 0.5), the port's spring has no limit; the old turn button (R) dragged the
  cloth back against the spin by a set pull (turn_drag 3.0), the port's cloth now sees the spin itself
  in the view's frame; the old Sock hangs a little more bent at rest (strips).
- [later] The port's bin is never thrown (core/78: put down or handed over), so the "thrown bin caught
  mid-flight" of the acceptance is the bin clicked again while its put still eases its Looks down from
  the Hands (the bin's only mid-air in the port, and the fault: its Looks stayed off the thing, so it
  was held at another pose). The old ItemPut ended a put the same way when picked (ItemPut.stop()).
  Whether the old game threw the bin was not settled here.
- [later] Kit: a shot set line may hold only one --shots, so a frame strip of one run (motion) has no
  set file; the strips here were taken with kit/tools/shot.sh --shots=<frames> --do='30:flop_compare:60'
  (and :30), cropped 0,0,340,200 of --crop=560,385,900,585 at 1280x720.

## Built log

### 2026-11-25
- Changed: a carried thing clicked again while its put still eases its Looks down is held exactly as
  one picked lying still (its Looks stayed off the thing, 0.6 m in the test); a Sock picked out of the
  air flies up from where it is drawn, not from where it left the hand. The held Sock's cloth is
  simulated in its HeldView's frame and pulled against the eyes' smoothed acceleration (the old
  motion source): turning the view no longer whips it (it zig-zagged every frame), walking no longer
  trails it, and 30 fps no longer judders it. New knobs in sock_cloth_tuning: max_accel, accel_smooth.
- Files: game/parts/carriable.gd, game/sock/sock_cloth.gd, game/sock/sock_cloth_tuning.gd,
  game/hands/held_view.gd, game/player/player.gd, tests/carry_test.gd, tests/hand_details_test.gd,
  tools/old_flop.gd, tools/shot_hooks.gd (flop_compare)
- Verified: run.sh --touched "PASS 22921 checks, 722 cases"; grep_rules PASS; carry:pick_mid_put fails on the old carriable.gd; builds/review-core-118/
