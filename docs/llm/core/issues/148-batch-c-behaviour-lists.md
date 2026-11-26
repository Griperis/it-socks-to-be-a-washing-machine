---
type: ticket
status: ready-for-agent
kind: design
area: core
feature: frame
priority: now
created: 2026-11-26
done:
blocked_by: []
notes: ["suggested model: opus", "batch C (Q2614): behaviour lists first, for the designer to approve; the proposals follow as their own tickets"]
terms: [Elevator, Cat, X-ray, Upgrade, Old Tree]
suites: []
---

# Batch C: the behaviour lists

Batch C is the lived-in house (`docs/migration/milestones.md` "The rest of the port"): the exterior with the dusk and
night skies, the Elevator, the Cat and the litterbox, the X-rays, the vacuums, the detector, the TV and the Radio, and
the guide card. Before any design, each piece gets a behaviour list from the old game that the designer approves
(the `migration-port` skill, step 1; every motion, glide, sway, pop and sound is listed, Q2277). This ticket writes the
lists only. The proposals (architecture docs, draft tickets, waves) come after the designer's look, as their own
tickets, the way core/120-122 did for batch B.

## Do
1. Write one list per piece in `docs/migration/m4-lists/`, in the shape of `06-coins-drawers-upgrades.md`:
   - a header saying it is a draft for the designer;
   - the catalogue rows it covers;
   - the short forms for the old files;
   - the marks for lines of another piece or batch;
   - what is not ported and why, with its Q;
   - then the behaviour lines "When ..., then ..." with refs into `reference/it-socks/` (tag v0.1.1). Grep it; do not
     read big files whole.

   The pieces (rename or regroup if the old code says otherwise, and say why):
   - `09-vacuums-and-detector.md`: the Sock vacuum and the vacuum devices, the detector (catalogue B30, B32,
     P01-P07; the splitter, Hampers and pairing machine are not ported, Q2599).
   - `10-x-rays.md`: the Sock and Cabinet X-rays (B37).
   - `11-elevator.md`: the Elevator (B12).
   - `12-cat-and-litterbox.md`: the Cat (B40) and the litterbox (B16).
   - `13-tv-and-radio.md`: the TV and the Radio as the music source and a carried thing (B14, B71).
   - `14-exterior-skies-and-guide-card.md`: the outside of the house, the dusk and night skies (M1's leftovers), and
     the guide card (B26; it takes the "Wash the laundry" goal line's place, Q2625, and reuses the book's one-slot Hands
     item, Q2676).
2. In each list:
   - Name the Upgrades of the 16 that batch B shows as "Coming soon" (Q2669) which belong to the piece, by their node in
     `data/upgrades.json`, with what each does.
   - Mark every line that needs co-op (who sees what, the Host's answer) and every sound and rumble.
   - Mark what Secrets would hang on the piece (Duet in the Elevator, the Radio Dance and others) as "(Secrets,
     later, Q2682)", so nothing is lost.
3. Read the port's existing pieces each list touches and mark lines already built with `port:` refs. For example:
   - the Old Tree's `tree_tip_elevator` lines (batch B, core/132);
   - the greyed Upgrades (core/129);
   - the HUD goal line (batch A);
   - the models already ported in M1: `assets/cat/`, `assets/tv/`, `assets/radio/`, `assets/sock_vacuum/`,
     `assets/vacuum_devices/`, `assets/sock_detector/`, `assets/exterior/`.
4. End each list with `## Open questions for the designer`, each with the old game's answer as option (a), written as
   `designer-grilling` asks. Do not decide them.
5. One short index, `docs/migration/m4-lists/batch-c.md`:
   - the pieces and their line counts;
   - the cross-piece seams (for example the Cat riding the Elevator, the Radio carried into the Elevator, the
     vacuum's Upgrades in the grid);
   - a suggested grouping into design tickets (two to four, the way batch B had three).

## Acceptance
- Docs only: no game code, scene or asset changed.
- Every catalogue row named above is covered by a list, or named as not ported with its Q.
- Every line has a ref into the reference, or a `port:` ref.
- Each list ends with its open questions; none is answered by the agent.

## Answers
- The rest of the port runs as batches A-D; batch C is the lived-in house (Q2603-Q2605, Q2614).
- The 16 batch C Upgrades show greyed "Coming soon" until their features land (Q2669).
- Not ported: the splitter, the Grotto, Hampers, the pairing machine, the F1 menu (Q2599); Secrets come later together
  (Q2600, Q2682); wash cycles and proximity chat (Q2602).

## Open follow-ups
