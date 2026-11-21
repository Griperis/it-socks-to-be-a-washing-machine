---
type: ticket
status: ready-for-human
kind: build
area: core
feature: core
priority: now
created: 2026-11-21
done:
blocked_by: ["[[16-feedback-and-motion-polish]]"]
notes: []
terms: []
---

# The rest of the motion polish

M0.5 batch 5, split from core/16 on the designer's word (Q2398, 2026-11-21: "Rest can come as a separate ticket").
The behaviour lines are core/16's (approved there with Q2366-Q2370); read `16-feedback-and-motion-polish.md` for the
old code and numbers of each.

## Behaviour list
- P03 The held Size box follows the held Sock's cloth sway, as the old readout did (fitting core/15's held readout).
- P08 A thrown Sock leaves with the bend it had in the hand (core/23 left the flying Looks straight; Q2315).
- P10 A shelved Pair lands in its slot with P04's squash, hop and roll (Q2316).
- P11 A Pair thrown at a drawer front flies on to its slot (Q2316).
- P14 Two fusing Socks curl along their cloth bones, curl 1.3, in the fold (Q2281).
- P15 The Door swings 0.6 s eased in and out; the cupboard 0.35 s eased out (Q2368).
- F1 First: fix the FLAKY `sound_wiring:w10_gap` (a defect, `kit/docs/TESTING.md` "Flaky cases"): find the race and
  rework the case or the code; it must pass 20 runs in a row, also reversed.

## Acceptance
- One case per line; the real-path cases through the zoo's stations.
- A review sheet of P03, P08, P10, P11, P14 and P15 in `builds/review-core-27/`, stopped at it for the designer's go.

## Answers
- Split from core/16 (Q2398, 2026-11-21).

## Open follow-ups
- [later] For the designer (Q2277, a detail to keep or drop): P08 carries the hand's bend into a Throw only; a
  drop (Q2367, also from the hand) starts its flying Looks straight as before. Should a drop keep its bend too?
- [later] P15: the Door kept its core/04 curve (Godot's ease -2, a quadratic in and out) and the cupboard's
  0.35 s uses the drawer's ease 0.5 (a quadratic out), not the old TRANS_SINE; the sine is a little softer at
  both. Close by eye on the strip; the designer's call.
- [later] P03: the held Size box moves as far as the sway moves the Sock's middle, as the old did; walking off,
  that is up to about 50 px at 1080p (see the sway strip). The old number, not tuned.
- [later] P14: the curl's direction (sign of `PairMoment.curl`, +1.3) was set to the old number; check on the
  pairing strip that the Socks roll toward the ball, not away (negative rolls the other way).

## Built log
- Model: Opus (lead): cloth, flights and the pairing moment's animation.
- 2026-11-21 (stopped at the review sheet, look work). Changed: F1 `sound_wiring:w10_gap` fixed: the runner's
  scrub reset the sounds a frame before the suite freed the last case's level, and a Sock of it still bouncing
  noted a bounce for its min gap; the suite's `_before_case` now resets the sounds after freeing the level
  (20 runs in a row and 20 reversed, all PASS). P03: `HeldView.sway()` (the old info_sway: the nearest cloth bone
  carries the Sock's middle) moves the Hud's held readout. P08: `SockCloth.carry()` starts a thrown Sock's flying
  Looks with the hand's bend (read on `skeleton_updated`), easing out over `blend_time`; a drop does not. P10: the
  Cabinet's shelving flight lands `roll_distance` (new in `BallLandingTuning`, 0.12) short of its slot, plays a
  `BallLanding` there and rolls on in `bounce_time`, then the second squash, then the drawer's ball shows. P11:
  `Mess.drawn_flight_of()`: a Pair thrown into a drawer front flies on from where its body was. P14: `PairMoment`
  (pair_moment.gd) curls both Socks' cloth bones by `curl` 1.3 times `fold`, keyed in `pair` (0 at 0.2, 0.5 at 0.35,
  1 at 0.43). P15: the cupboard's Looks (graybox, alt) open and shut in 0.35 s eased out (own `shut`); the Door
  was already 0.6 s in and out (core/04), now tested. Shot actions `shelve_throw`, `swing_view`, `swing_use`.
  Files: game/hands/held_view.gd, game/ui/hud.gd, game/sock/sock_cloth.gd, game/sock/pair_moment.gd (+ .uid),
  game/sock/pair_moment.tscn, game/sock/ball_landing_tuning.gd, game/entities/cabinet/cabinet.gd, game/mess/mess.gd,
  game/entities/cupboard/looks_graybox.tscn, looks_alt.tscn, tests/motion_polish_rest_test.gd (+ .uid),
  tests/sound_wiring_test.gd, tests/cupboard_test.gd (reverse read on the pivot), tests/drawer_details_test.gd
  (the landing's time), tools/shot_hooks.gd, tools/shots/sets/motion-{sway,throw-bend,shelve-landing,thrown-shelve,swings}.txt.
  Verified: PASS 11390 checks, 320 cases (--touched). Review sheet: builds/review-core-27/sheet.png.
