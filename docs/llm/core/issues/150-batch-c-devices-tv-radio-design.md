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
terms: [Sock vacuum, Backpack vacuum, detector, Radio, TV]
suites: []
---

# Batch C: The vacuums, the detector, the TV and the Radio (design)

The behaviour list is written and answered: `09-vacuums-and-detector.md` and `13-tv-and-radio.md` in `docs/migration/m4-lists/` (core/148), and the designer's
answers Q2698-Q2706 in `docs/migration/decisions.md`. This ticket writes the proposal and the build tickets' drafts,
the way core/120-122 did for batch B. A design ticket: no game code.

## Do
1. Write `docs/architecture/devices.md` (the Sock vacuum, the Backpack vacuum, the nozzle and hose, the detector; the one whole-Hands rule and the one thrown-knock rule) and `docs/architecture/tv-and-radio.md` (the TV's four shows, the Radio as the music source and a carried thing). Cover how each piece is authored (Q2607):
   - what is a typed Resource edited in the inspector;
   - what a designer adds by dropping a file, with no code change;
   - which zoo station shows it, built from the data at load (Q2337);
   - what is authored in nodes (Q2658);
   - motion as AnimationPlayer clips in a Looks scene, not code (Q2697).

   Co-op is the scene-parts shape (`docs/migration/coop-structure-for-the-port.md`).
2. Write the seams with the other pieces: the Hands and `Carriable` (core/78), the book's one-slot Hands item (core/139), the knockdown (coop/10), the Upgrade grid's five vacuum Upgrades (core/129), the Old Tree's `tree_tip_vacuum`, the Elevator's carry rule (core/149), the music duck (batch A). Where another batch C design owns the other side, name it and
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
- The container rides the Elevator only with its nozzle on its hook (Q2710, 2026-11-26).
- A player holding the nozzle may climb into the car; the hose stretches between floors, as the old (Q2711, 2026-11-26).
- Batch C is designed as four tickets: the Elevator, day and exterior; the devices, TV and Radio; the Cat; the X-rays
  (Q2707).

## Open follow-ups

- (answered, see Answers) (for 150-N only) Q2699 says every carried thing rides the Elevator by one item rule; the Sock vacuum's
  container is carried, but its hose ties it to its nozzle. Does the container ride when it lies in the car?
  (a) As the old: it never rides (the old car carried Socks, Pairs, the Radio, the Guide card, the Cat and the book,
  not the vacuums: `elevator_rules.gd`:120-175); (b) it rides only with its nozzle on its hook, and stays put with the
  nozzle out; (c) it rides, and its nozzle goes back on its hook. Recommended: (b).
- (answered, see Answers) (for 150-N only) A rider keeps what is in their Hands (list 11). What happens when the player holding the
  nozzle climbs into the car? (a) As the old: no rule stops it; the nozzle rides with its holder and the hose stretches
  between floors (the old had no check, VA:383-450 measures only sucks and drops); (b) the nozzle goes back on its hook
  as they climb in; (c) the car refuses them with "The hose won't reach". Recommended: (c).

