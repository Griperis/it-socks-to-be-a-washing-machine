---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: house
priority: now
created: 2026-11-26
done:
blocked_by: ["[[178-cat-swat-and-fetch]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 9", "suggested model: sonnet"]
terms: [Cat, Sock, Mess]
suites: [cat, furniture, cupboard, mess, sounds, menus]
---

# The Cat's litterbox visit

About every 4 minutes the Cat walks to the litterbox, noses its flap open, steps in, scratches for 6 s with its own
clip and sound, walks out and the flap shuts behind it; on 1 visit in 3 it first carries the nearest loose Sock there in
its jaws and leaves it on the litter. Build `docs/architecture/cat.md` "The litterbox visit", draft 151-D:

- `LitterVisit` (`game/furniture/litter_visit.gd`, a Part with no state, a child of `litterbox.tscn`, in `cat_places`)
  with its markers `CatFront`, `CatSill`, `CatInside`, `CatDrop`; the visit's steps as the Cat's errand `litter` (the
  flap's Openable patched in the answers: a shut flap opened, pushed open again if a player shut it on the Cat, shut by
  the Host behind it, Q2009); the hiding visit (`litter_hide_chance` 0.33, a Sock within 5 m, taken within 0.6 m); the
  scratch with `scratch` and `litter_scratch`; `holds_cat` while BOXED; a visit that cannot start tries again in 15 s;
- **the scratch's sound (Q2712):** three licence-checked recordings of a cat scratching litter, each copied into
  `assets/audio/` with its `SOURCES.md` row and credit and added to `litter_scratch` as candidates on the Sounds station
  for the designer to pick (until the pick the swat's clips stay its placeholder).

It does not edit `cat.gd`: it calls the Cat's patch functions core/176-178 built. L1, L2, L3 (the litterbox, its Socks
by the Sock generator, Q2600, its flap's sounds) are built (assets/07) and checked again here.

Behaviour lines (`docs/migration/m4-lists/12-cat-and-litterbox.md`, by `cat.md`'s heading letters): L4, L5, L6, L7.

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
The spots are markers in the litterbox scene (moving the litterbox moves the visit); the numbers are `CatTuning`'s
(240 +- 45 s, 6 s, 1 in 3 as placeholders, Q2703); the candidates are clips on the SoundEvent, picked on the Sounds
bench with no code.

## Acceptance
- Real path: the player shuts the flap with a left click before the visit; at the visit the flap the player sees opens
  and shuts again; the player's left click opens it and the hidden Sock lies inside, picked through the flap into
  their Hands.
- With the zoo tuning's `litter_every` the Cat walks to the flap, a shut flap opens (`litter_flap_open`), it steps in,
  scratches 6 s with `scratch` and `litter_scratch`, walks out and the flap shuts behind it even if a player opened it.
- Inside it cannot be petted, picked up or swat; the watchdog leaves it alone; a visit with no way there tries again in
  15 s; a Guest sees the same.
- The three recordings play on the Sounds station under `litter_scratch`, each with its licence and credit
  (`menus` l02).
- Placeholders: the visit's numbers, `litter_scratch`'s pick.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The litterbox every 240 +- 45 s, 6 s, 1 in 3; the scratch gets its own clip and sound (Q2703, 2026-11-26).
- Three licence-checked recordings to the Sounds station for the designer to pick (Q2712, 2026-11-26).

## Open follow-ups
