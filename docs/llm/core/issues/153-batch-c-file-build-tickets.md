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
notes: ["suggested model: opus", "batch C (Q2614); answers Q2693-Q2714; the same job core/123 did for batch B"]
terms: [Elevator, Cat, X-ray, Sock vacuum, Backpack vacuum, detector, Radio, TV, Upgrade]
suites: []
---

# Batch C: the answers folded in, the build tickets filed

Batch C's four designs are on main:
- core/149: `docs/architecture/elevator.md` and `day-and-exterior.md`;
- core/150: `devices.md` and `tv-and-radio.md`;
- core/151: `cat.md`;
- core/152: `x-rays.md`.

Their questions are answered: Q2693-Q2714 in `docs/migration/decisions.md`. Some answers came after a design was
written. For example, Q2709 drops four of the day's details from drafts 149-H and 149-I, Q2710-Q2711 settle the
vacuum in the Elevator, and Q2712-Q2714 settle the Cat's scratch sound and the X-ray's words and glow. Read every Q in
that range. Batch C is built unattended after batch B (Q2603), the same way.

## Do
1. Bring the six architecture docs to the answers:
   - no "(ask)" or recommendation text left that an answer replaced;
   - no draft part an answer dropped;
   - the four docs' "Not filed yet" status lines say filed.

   `GLOSSARY.md` gets the new words (the Cabinet X-ray's "Show Cabinet", Q2713). `docs/architecture.md` gets one row
   per new doc.
2. Move every answered `[blocking]` item in core/149-152 under `## Answers` with its Q. All four tickets are `done`
   already.
3. File the build tickets from the drafts (149-A.., 150-A.., 151-A.., 152-A.., and the asset tickets for the ported
   models, Q2705), deduplicated across the four designs. Watch for:
   - one carry rule for things in the car (core/149's), the others writing only their side;
   - one whole-Hands rule and one thrown-knock rule (core/150's);
   - one groundwork ticket for the new sounds and zoo stations if more than one design proposes one (150-S).

   Numbering: core tickets as `docs/llm/core/issues/NN-*.md` from 154 on; asset tickets in `docs/llm/assets/issues/`
   from 21 on. Each ticket, in the shape of batch B's (core/124-147):
   - one mergeable piece;
   - its behaviour lines (every old detail, Q2277);
   - acceptance with its real-path case;
   - `blocked_by` with `[[NN-slug]]` links, including batch B tickets it needs (for example 150-A needs core/130,
     150-L needs core/139 and core/133);
   - `suites:`, naming the suites it can break. Include `menus` for any new file under `assets/` (credits, l02),
     `furniture_devices` for anything on the Old Tree, `save` for new saved state.
   - a suggested model;
   - how it is authored (Q2607, UI in nodes Q2658, motion as clips Q2697).

   Asset tickets stop at their first line-up; look tickets stop at their first still.
4. Write the build order in `docs/migration/milestones.md` as a "Batch C" table, in the shape of "Batch B":
   - waves of at most 5;
   - every clash the four designs name kept apart (`house.tscn`, `zoo.tscn`, `sound_catalogue.tres`, `carriable.gd`,
     `knockdowns.gd`, `mess.gd`, `player.gd`, `player.tscn`, `avatar.gd`, `tests/upgrades_test.gd`);
   - a zoo station's x given in each ticket that adds one, spaced 14 m apart from x=208 on, each with its own ground
     body (the zoo's floor ends before x=160).

   Batch C's first wave starts after batch B's last wave is merged. Set batch C's row to "answered (Q2693-Q2714),
   filed (core/153)".
5. Write a review sheet stub, `docs/migration/batch-c-review.md`, in the shape of `batch-b-review.md`.

## Acceptance
- Docs only.
- Every one of Q2693-Q2714 lands in the doc it changes.
- Every draft is a filed ticket, merged into one, or named as dropped by its Q.
- No two tickets in one wave edit the same file the designs list as a clash.
- `run.sh --touched` (the parse and wiring checks) passes.

## Answers
- Batch C answered: Q2693-Q2714 (designer, 2026-11-26).

## Open follow-ups
