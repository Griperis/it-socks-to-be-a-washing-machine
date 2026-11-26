---
type: ticket
status: done
kind: design
area: core
feature: frame
priority: now
created: 2026-11-26
done:
blocked_by: []
notes: ["suggested model: opus", "batch C design (Q2614, Q2707): one of four, written on the designer's answers Q2698-Q2706"]
terms: [X-ray, Upgrade]
suites: []
---

# Batch C: The X-rays (design)

The behaviour list is written and answered: `10-x-rays.md` in `docs/migration/m4-lists/` (core/148), and the designer's
answers Q2698-Q2706 in `docs/migration/decisions.md`. This ticket writes the proposal and the build tickets' drafts,
the way core/120-122 did for batch B. A design ticket: no game code.

## Do
1. Write `docs/architecture/x-rays.md` (the Sock X-ray's Show pair and the Cabinet X-ray's Show Cabinet, Q2701; the eight Personal Upgrades, the outline, the screen tint, the hint arrows). Cover how each piece is authored (Q2607):
   - what is a typed Resource edited in the inspector;
   - what a designer adds by dropping a file, with no code change;
   - which zoo station shows it, built from the data at load (Q2337);
   - what is authored in nodes (Q2658);
   - motion as AnimationPlayer clips in a Looks scene, not code (Q2697).

   Co-op is the scene-parts shape (`docs/migration/coop-structure-for-the-port.md`).
2. Write the seams with the other pieces: the Upgrade grid (core/129, core/130's Personal Upgrades), the outline (core/11), Sole Mates' cue (core/131). Where another batch C design owns the other side, name it and
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
- [blocking] The Cabinet X-ray's new words (Q2701 renames the ability "Show Cabinet" and has the tooltip say the whole
  Cabinet glows; the exact sentence is not given). (a) The old sentences with "drawer" taken out: title "Cabinet
  X-ray: Show Cabinet", tooltip "Show Cabinet (key 2): the right Cabinet glows through walls."; (b) other words
  (which?). Blocks the words part of 152-A only.
- [later] For the lead, not the designer: GLOSSARY "Cabinet X-ray" still says "Show drawer" and "the front of the
  Cabinet drawer ... glow"; since Q1964 and Q2701 it is "Show Cabinet" and the whole Cabinet outlined in amber.
