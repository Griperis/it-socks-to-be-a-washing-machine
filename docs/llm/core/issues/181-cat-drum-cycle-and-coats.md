---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: washer
priority: now
created: 2026-11-26
done:
blocked_by: ["[[177-cat-petting-holding-throwing]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 8", "suggested model: opus"]
terms: [Cat, washing machine]
suites: [cat, wash, washer, knockdown, coop_knockdown, save]
---

# The Cat's drum cycle and coats

Set down by the washer's door, the Cat goes into the drum for a short cycle and comes out dizzy in its next coat: black,
grey, ginger, white, calico, then black again (Q2703: now, without the other Secrets). Build `docs/architecture/cat.md`
"The drum cycle and the coats", draft 151-F:

- `WasherWash`'s `load: NodePath` and `load_left` (State; one thing at a time with a washed player, Q758; neither starts
  while a cutscene plays), its `takes_cat` (set down standing within `wash_reach` of the washer's `Door`, aimed at the
  washer, the machine free) and `holds_cat`; `Washer.busy()` reading the load;
- the end answer: the Cat stands 0.2 m out of the door, DIZZY for `dizzy_seconds` 2.5 (the `dizzy` clip) with a meow,
  in the folder's next coat, then runs 2 m off; the coat saved; a New Game's Cat black;
- `WashView`: the blob in the coat's colour sliding in, `wash_slam`, `wash_slosh`, the drum and the face's `spin` at
  `cat_spin` 0.45 turns a second, the door bursting open;
- `WasherTuning.cat_seconds` 4 and `cat_spin` 0.45; `tests/saves/shape.json` (the wash's two fields).

It does not edit `cat.gd` (core/178 has it in the same wave): it calls the Cat's patch functions. A save or a join while it spins does not keep the load: a load stands the Cat in front of the door in its old coat
(the old `drum_cleared`). The other loads (the Radio, a Gift box) stay with the Secrets (Q2699).

Behaviour lines (`docs/migration/m4-lists/12-cat-and-litterbox.md`, by `cat.md`'s heading letters): D1.

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
Coats are files in the folder (a dropped `.tres` joins the cycle in file-name order); the cycle's numbers are
`WasherTuning`'s (`# placeholder:` the old `wash.json`); the blob's colour is the coat's.

## Acceptance
- Real path: the player carrying the Cat right-clicks aimed at the washer standing by its door; the Cat the player sees
  is gone into the drum, and after the cycle it stands by the door in the grey coat.
- The blob slides in, the door slams, the drum turns at 0.45; after 4 s the door bursts open and the Cat stands out of
  it dizzy for 2.5 s with a meow, then runs off.
- Five washes go black, grey, ginger, white, calico, black; a coat `.tres` dropped into the folder joins the cycle.
- A body let go at the door while the Cat spins just lies there; the Cat is not taken while a player spins.
- A save while it spins loads it in front of the door in its old coat; a Guest sees the same.
- Placeholders: `cat_seconds`, `cat_spin`.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- Its drum cycle and coat change are ported now, without the other Secrets (an exception to Q2699) (Q2703,
  2026-11-26).

## Open follow-ups
