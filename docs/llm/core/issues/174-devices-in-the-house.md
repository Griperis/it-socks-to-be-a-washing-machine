---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: house
priority: now
created: 2026-11-26
done:
blocked_by: ["[[172-backpack-vacuum]]", "[[167-sock-detector]]", "[[165-tv-and-test-card]]", "[[164-radio-channels]]", "[[139-encyclopedia-book]]", "[[133-old-tree-help]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 8", "suggested model: sonnet"]
terms: [Sock vacuum, Backpack vacuum, Sock detector, TV, Radio, Old Tree, Stage]
suites: [house, floor_lock, voice, old_tree_voice, furniture_devices, stages, save]
---

# The devices in the house

Every device stands in the house from a New Game (Q2698, Q2704): the Sock vacuum and two Backpack vacuums in the
kitchen behind the ground floor's lock, the Sock detector on the workshop's workbench beside the encyclopedia book, the
TV in the living room in front of the north window, the Radio on a kitchen shelf playing Theme; and the Old Tree's
vacuum tip. Build `docs/architecture/devices.md` "Seams" (core/139, core/132-133), draft 150-L:

- in `house.tscn`: the three vacuums in the kitchen, the detector 0.35 m beside the book's placed spot turned 20
  degrees, the TV and the Radio (static Parts in the layout hash: their names and places are part of the save);
- a New Game puts each back;
- `tree_tip_vacuum`'s trigger file (its three recordings copied by core/132) and its field on the ground floor's Stage
  `.tres`: due once per player per run when the ground floor opens, said when they are near.

Behaviour lines: `09-vacuums-and-detector.md` V1, V2, V3; `13-tv-and-radio.md` R1's spots and R15's New Game.

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
Placed by hand in the editor; the tip is data (a trigger file, its JSON entry, the Stage's field).

## Acceptance
- Real path: in the house at a New Game the player walks to the workbench and left-clicks the detector beside the book;
  it is in their Hands.
- With the ground floor locked the kitchen's vacuums are behind its lock; once it opens and the player walks near the
  Old Tree, the vacuum tip's subtitle shows once, not again that run.
- The Radio plays Theme from the New Game; the TV stands off in front of the living room's north window.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- All the devices in the house from a New Game, the vacuums behind the ground floor's lock; the detector on the
  workbench beside the book (Q2698, 2026-11-26).
- The TV's spot (Q2704, 2026-11-26).

## Open follow-ups
