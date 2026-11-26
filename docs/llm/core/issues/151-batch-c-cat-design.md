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
terms: [Cat]
suites: []
---

# Batch C: The Cat and the litterbox (design)

The behaviour list is written and answered: `12-cat-and-litterbox.md` in `docs/migration/m4-lists/` (core/148), and the designer's
answers Q2698-Q2706 in `docs/migration/decisions.md`. This ticket writes the proposal and the build tickets' drafts,
the way core/120-122 did for batch B. A design ticket: no game code.

## Do
1. Write `docs/architecture/cat.md` (the Cat's moods, navigation, petting and the fetch, being held and thrown, the litterbox visit, the drum cycle and its coats now, Q2703). Cover how each piece is authored (Q2607):
   - what is a typed Resource edited in the inspector;
   - what a designer adds by dropping a file, with no code change;
   - which zoo station shows it, built from the data at load (Q2337);
   - what is authored in nodes (Q2658);
   - motion as AnimationPlayer clips in a Looks scene, not code (Q2697).

   Co-op is the scene-parts shape (`docs/migration/coop-structure-for-the-port.md`).
2. Write the seams with the other pieces: the Elevator (core/149: it naps in the car, rides, opens a hatch), the whole-Hands and thrown-knock rules (core/150), the washer's drum and its door (batch A's washer), the floor locks (the couch until the ground floor opens). Where another batch C design owns the other side, name it and
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
- [blocking] (before 151-D is built) The litterbox scratch's own sound (Q2703 asks for one; neither the answer nor
  the old game names it). (a) The old: the swat's sound ("cat_swat", Q2008), kept under its own event
  `litter_scratch` until the designer swaps it on the Sounds bench; (b) 151-D brings three candidate recordings
  (licence-checked) of a cat scratching litter to the Sounds bench for the designer to pick; (c) another sound
  (which?).
