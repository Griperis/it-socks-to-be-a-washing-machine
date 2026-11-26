---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: house
priority: now
created: 2026-11-26
done:
blocked_by: ["[[176-cat-walks-the-house]]", "[[163-radio-carried-and-thrown]]", "[[168-sock-vacuum-nozzle-hose]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 7", "suggested model: opus"]
terms: [Cat, Hands, Throw, Teammate]
suites: [cat, carry, coop_carry, knockdown, coop_knockdown, throw]
---

# Petting, holding and throwing the Cat

E pets the Cat: it stops, purrs and little hearts float up. A left click with empty Hands picks it up, held in the world
at the holder's hands, tipped and wriggling, and after 3 s it jumps down and runs off; a right click sets it down; a
Throw makes it hiss, fly paws out and land on its four paws. Build `docs/architecture/cat.md` "Petting and holding",
draft 151-B:

- the verb `pet` and its refusals (silent: no prompt when HELD, FLYING, BOXED, in the DRUM, or in a shut or riding
  car); a napping Cat woken by it; `petted(by)` driving the hearts and `cat_purr`;
- the `Hold` member on `cat.tscn`: a `Carriable` by core/163's and core/168's rules (`handable` off,
  `hold_slot_cat.tres`, title "Cat", `throwable` on), with the five needs of the doc (its owner's pick refusal; the owner
  told of a pick, a set-down, a hand-off and a Throw in the same answer; the Host-only `free` after `hold_seconds`; the
  flight told to the owner and its pose left to the `fall` clip; the thrown knock applied to it). If a rule lacks one,
  this ticket adds it to `carriable.gd` or `knockdowns.gd` and says so in its report;
- `free` and `landed` (it stands at the nearest spot of its map, then runs 2 m off; on the stairs it stays on its step);
  the calls of `takes_cat` at a set-down, a free and a landing (no member yet: core/180, core/181);
- the pick plays `pick` and a meow; the Throw `cat_hiss` and the thrower's "throw" buzz; the landing `cat_land`;
- the crosshair words "Pet" (E) and "Pick up" (left click).

Behaviour lines (`docs/migration/m4-lists/12-cat-and-litterbox.md`, by `cat.md`'s heading letters): P1, P3; H1, H2, H3 (with the run-off, the stairs step and the places' `takes_cat` first: CAT:358-364,
CAT:831-845), H4, H5 (the Cat's side of Q2700); Wo1.

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
No new numbers (`CatTuning`'s); the hold slot a `.tres`; the held tip and wriggle are the `held` clip, the flight the
`fall` clip (Q2697); the hearts a `GPUParticles3D` in the Looks; the words in the crosshair rows.

## Acceptance
- Real path: the player presses E aimed at the Cat in the Cat station and the hearts and purr the player sees and hears
  start; then the left click with empty Hands, and the Cat the player sees is at their hands until it jumps down 0.5 m
  in front of them and runs 2 m off.
- With a Sock in the Hands the pick reads "Hands full"; a Teammate cannot take it from the holder; the right click
  sets it down at the crosshair and it runs off; on the stairs it stays on its step.
- A Throw hisses, it flies with `fall`, lands upright with `cat_land` and runs off; a full-charge Throw at a Teammate
  knocks them down and bounces off, a weak one drops at their feet and is not caught, a rider is not hit (co-op: the
  Host and a Guest each throwing).
- Boxed, in the drum or flying it cannot be petted or picked (the prompt hides); a holder who leaves lays it where
  they stood; a save with the Cat held loads it standing there.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- Held in the world at the hands (Q2703, 2026-11-26).
- A thrown Cat that hits a Teammate: full charge knocks down, weaker bounces to their feet, never caught; a rider is
  never hit (Q2700, 2026-11-26).

## Open follow-ups
