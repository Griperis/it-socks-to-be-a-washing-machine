---
type: ticket
status: done
kind: design
area: core
feature: frame
priority: now
created: 2026-11-26
done: 2026-11-26
blocked_by: []
notes: ["suggested model: opus", "batch C design (Q2614, Q2707): one of four, written on the designer's answers Q2698-Q2706"]
terms: [Elevator, Upgrade]
suites: []
---

# Batch C: The Elevator, the day cycle and the exterior view (design)

The behaviour list is written and answered: `11-elevator.md`, plus Q2693 (the day) and Q2694 (the exterior view); the lamps rule Q2706 in `docs/migration/m4-lists/` (core/148), and the designer's
answers Q2698-Q2706 in `docs/migration/decisions.md`. This ticket writes the proposal and the build tickets' drafts,
the way core/120-122 did for batch B. A design ticket: no game code.

## Do
1. Write `docs/architecture/elevator.md` (the Elevator and its riders, the one carry rule for things in the car) and `docs/architecture/day-and-exterior.md` (the day cycle, the lamps by the clock over the floor locks, the exterior seen through the windows). Cover how each piece is authored (Q2607):
   - what is a typed Resource edited in the inspector;
   - what a designer adds by dropping a file, with no code change;
   - which zoo station shows it, built from the data at load (Q2337);
   - what is authored in nodes (Q2658);
   - motion as AnimationPlayer clips in a Looks scene, not code (Q2697).

   Co-op is the scene-parts shape (`docs/migration/coop-structure-for-the-port.md`).
2. Write the seams with the other pieces: the floor locks and `HouseLights` (core/80), the Upgrade grid's three Elevator Upgrades (core/129), the Old Tree's `tree_tip_elevator` (core/132, core/133), the things that ride (core/150's devices and Radio, core/151's Cat). Where another batch C design owns the other side, name it and
   write only this side.
3. The models are ported from the old game by the port rules (Q2705): one asset ticket per family, with its
   before-and-after strip, stopping at its first line-up. Core tickets build on graybox Looks and wait for no asset.
4. Split the build into tickets of one mergeable piece each, as `ready-for-agent` drafts in the doc (the lead files
   them). Each draft has:
   - its behaviour lines;
   - acceptance with its real-path case;
   - `suites:`;
   - a suggested model;
   - how it is authored.

   Give waves with the files they clash on.
5. Every answer Q2698-Q2706 that touches this piece lands in the doc. A choice the answers and the old game leave
   open goes under `## Open follow-ups` as `[blocking]`, with the old game's answer as (a). Do not decide it.

## Acceptance
- Docs only.
- Every behaviour line of the list is in a draft ticket, or named as dropped with its Q.
- Every draft has a real-path case.
- No two drafts in one wave edit the same file.

## Answers
- Batch C is designed as four tickets: the Elevator, day and exterior; the devices, TV and Radio; the Cat; the X-rays
  (Q2707).

## Open follow-ups
- [blocking] Q2693 says "nothing else of the old day is needed", but the old day had six small details beside the
  sun, skies, moon and lamps (`docs/architecture/day-and-exterior.md`, the lines marked "(ask)"). Only the designer
  drops a detail (Q2277). For each: (a) keep it as the old; (b) drop it.
  1. The lamps' click when they switch, flat: `lamp_on` at 19:30, `lamp_off` at 7:00 (sharing the X-ray's on and off
     sounds).
  2. The globe shades' paper glowing while the lamps are on.
  3. The window panes darkening to night blue at night.
  4. The colour grade following the hour (warmer at dusk, bluer at night) and the vignette closing in at night.
  5. The wall clock whose hands show the hour (its model is not ported yet: one more asset ticket).
  6. The outside's night glow: the neighbours' windows, the street lamps and their pools of light switching on with
     the house's lamps.
  Blocks only draft 149-H (and the glow's line of 149-I); 149-G, 149-I and every Elevator draft can be filed without
  it.
