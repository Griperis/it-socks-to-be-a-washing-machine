---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: hands
priority: now
created: 2026-11-26
done:
blocked_by: ["[[170-vacuum-spit-and-pour]]", "[[125-collections-as-data]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 7", "suggested model: opus"]
terms: [Filter nozzle, Filter, Nozzle display, Sock vacuum, Collection, Size]
suites: [vacuum, save, coop_join, collections, ui_nodes, zoo]
---

# The Filter nozzle and the Nozzle display

The Sock vacuum's nozzle carries a little display: its fill from the start (Q2187), and once Filter nozzle is bought a
Size and a Collection the holder sets with the wheel, so the nozzle sucks only Socks matching both; a set Filter that
matches nothing in front of the nozzle blinks red. Build `docs/architecture/devices.md` "The Filter", draft 150-I:

- `VacuumFilter` (a Part, `size` and `collection`, saved and joined; `step {half, by}` from the holder's wheel, only
  with `filter_nozzle` bought; `accepts(design)`), the Collection list from the Collections with a loose Sock in the
  Mess now (Lost Socks when one lies loose), read from core/125's data; a set Collection stays set when it runs out and
  the next step starts from "any" (Q2121-Q2124);
- `nozzle_display.tscn` (the fill bar, the Size word, the Collection's icon and name, the red frame) in the pod's
  SubViewport, its `blink` clip each half second while a set Filter matches nothing in front;
- the word "Up: Size  Down: Collection".

Behaviour lines (`docs/migration/m4-lists/09-vacuums-and-detector.md`, V1-V53 in its order as `devices.md` numbers them): V23, V24, V25, V26, V27; V8's "filtered".

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
The display in nodes on the one Theme (Q2658), code fills it; the lists from the catalogue and the Collections (a new
Collection shows with no change); `blink` a clip.

## Acceptance
- Real path: in the vacuums station with Filter nozzle bought (the station's switch), the holder rolls the wheel up to
  a Size and down to a Collection; the pod shows both; holding the left button sucks only Socks matching both; aimed
  where nothing matches, the red frame blinks.
- Without the Upgrade the wheel does nothing and the pod shows only the fill.
- The Filter is saved and joined, shared by whoever holds the nozzle (co-op).
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The vacuums as the old (Q2698, 2026-11-26).

## Open follow-ups
