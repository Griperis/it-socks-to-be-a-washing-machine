---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: player
priority: now
created: 2026-11-26
done:
blocked_by: ["[[182-xrays-owning-and-clock]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 4", "suggested model: sonnet"]
terms: [Cabinet X-ray, Show Cabinet, Cabinet, Collection]
suites: [xray_cabinet, cabinet, outline, cabinet_growth]
---

# Show Cabinet: the Cabinet in amber

While Show Cabinet is on, the whole Cabinet that takes the active item (a loose Sock or a Pair) is outlined in amber
through walls, locked, sheeted or full alike, with an edge arrow off screen; no drawer mark and no box glow (Q1964,
Q1971, Q2040). Build `docs/architecture/x-rays.md` "Show Cabinet: `CabinetGlow`", draft 152-C:

- `CabinetGlow` (`cabinet_glow.tscn`, `.gd`): a second `Outline` of `cabinet_xray_outline.tres` (`#ffa826`, width 1.5,
  the pulse numbers) beside the Cabinet's own, remade when its `rows` change (read from `Parts.applied`, no edit to
  `cabinet.gd`);
- the arrows' source; `cabinet.tres`'s `view`;
- a still of a Cabinet through a wall in `<main checkout>/builds/review-xrays/`.

Behaviour lines (`docs/migration/m4-lists/10-x-rays.md`, by heading): "Show drawer" lines 1, 2 and 4; "How they look" line 1 (the Cabinet X-ray's) and line 3 (its arrows).

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
The outline style in the inspector; the pulse is the shader's.

## Acceptance
- Real path: key 2 with a Pair held (picked with a left click), through the scene's wiring, to the amber Outline shown
  on that Cabinet in the X-rays station.
- No other Cabinet has one; the sheeted, locked one shows when its Collection is held; "Grow a Row" while it shows puts
  the new drawer's mesh in the outline's copies.
- All-Hands Cabinet X-ray shows each held Collection's Cabinet once; cycling to empty Hands hides it; off screen an
  amber arrow points at it; the outline ends with the show.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The Cabinet X-ray's ability is "Show Cabinet" and the whole Cabinet glows (Q2701, 2026-11-26).

## Open follow-ups
