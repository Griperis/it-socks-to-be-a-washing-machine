---
type: ticket
status: needs-info
kind: build
area: core
feature: core
priority: now
created: 2026-11-19
done:
blocked_by: ["[[03-pairing]]", "[[08-throw]]"]
notes: []
terms: []
---

# One Cabinet: Doors, Drawers, shelving a Pair

Milestone M0.5. A station with one Cabinet: its Doors and Drawers open (an AnimationPlayer in Looks, as the kit's example cupboard does), a Pair is shelved by a click and by a Throw. This closes the core: movement, handling Socks, pairing, one Cabinet (Q2208).

Port by the `migration-port` skill: behaviour list approved, design and grilling, a zoo station with the real
entity, tests from the list, walkthrough. `needs-info` until the designer has approved the behaviour list.

## Behaviour list
From `docs/migration/behaviour-core-loop.md` rows C01-C15, D01-D08, T05-T07 and the survey's Cabinet questions.
Ids are the survey's. Numbers are today's values, placeholders until the designer sets them. Built on core/02
(Hands, Mess), core/03 (Pairs) and core/08 (Throw); Doors and drawers use the kit's `Openable` (the zoo's example
cupboard already does).

**Shelving by click**
- C01 When you left-click a drawer of a Cabinet while holding Pairs of its Collection, then every held Pair of that
  Collection goes into that drawer, in the order held; Pairs of another Collection stay; the drawer slides open.
- C02 When you hold only Pairs of another Collection and click, then "Wrong Cabinet" shows and nothing moves; with a
  mixed hand what fits is shelved and the rest kept.
- C03 When a drawer holds its capacity (25 today; a tuning field, not fixed by the model, Q2256), then it is full; the next Pair aimed at it goes to the nearest drawer with room
  (the lower one when two are as near); each drawer used slides open.
- C04 When you click a drawer with empty Hands (or only loose Socks), then it opens or shuts; the click carries the
  state it asks for.
- C05 When your Pairs go into the drawers, then you are paid 10 Coins times the rarity (common 1, uncommon 2, rare
  5), once per drawer used; the Coins are yours alone. (The flying +N and the bank on screen: M4's HUD; here the
  number in the player's state.)
- C08 When the Cabinet is locked or its Rows are full, then a click says "Cabinet locked" or "Cabinet full" and the
  Pairs stay; a locked Cabinet's drawers stay shut. A Cabinet starts with 2 Rows (Stage growth: M4).
- C11 The Cabinet shows no icon: which Collection it takes is learned by the refusal.

**Shelving by Throw**
- T05 When a Pair you threw touches its own Collection's Cabinet, then it shelves itself into the lowest drawer with
  room, that drawer pops open, you are paid as for a click, and nothing lies on the floor.
- T06 When a Pair touches another Collection's Cabinet, or a locked or full one, then it bounces off and lies as a
  sock ball, no message.
- T07 When a loose Sock is thrown at a Cabinet, then it bounces off and lies loose, never shelved.

**Doors and openables** (the click shared with drawers)
- D02 When you click an open Door, then it swings shut (0.6 s); a shut one opens; a click asking the state it is
  already in does nothing; a Door never moves by itself.
- D05 When a Door is shut, then it stops the player and the crosshair like a wall; open, the doorway is clear.
- D08 When a cupboard or drawer is clicked, then it opens or shuts.

**The Cabinet itself**
- C14 The Cabinet is built from its model's parts (3 segments, 25 slots a drawer, a handle within 4 cm) and stands
  against a wall facing out. In the zoo: a graybox Looks with the same names (the model comes in M1).

**Invariants**
- I.5 Only a Pair of the Cabinet's Collection is ever shelved: never a loose Sock, never into a locked Cabinet or
  a full Row; a Row never holds more than its capacity.
- I.12 Coins go to the shelver alone, once per drawer used, never doubled.
- C12 Shelved Pairs stay in the same drawer and slot through a snapshot and load (`Parts.snapshot()`; saving to a
  file comes in M4).

**Not in this ticket**
- Progression, M4: the team's Drawers currency (C06), the Collection bonus (C07), Stages completing and paying (C09),
  drawing Collections for Cabinet spots (C10), the run's end (C15), Rows growing per Stage.
- Co-op, M0.6: two shelving into one drawer at once (C13); a Guest's click waiting for the Host.
- The house, M2 and M3: which doorways have Doors (D01), Doors shut at a New Game (D03), Socks pushed out of a
  swinging Door (D04, with the Mess), muffled sound (D06), the Door's prompt (D07).

## Design
<Step 2.>

## Acceptance
- The Cabinet is an entity: behaviour plus a Looks scene with a `looks_contract.json`; `kit/tools/asset_lint.py` passes.
- Shelving by click and by Throw both work and are tested; what is refused is tested.
- The designer plays the four stations in one run of the zoo.

## Answers
- The behaviour list is approved, with one change: the Pairs a drawer holds is configurable (a tuning field, 25
  today), not fixed by the model; the model keeps its 25 slots (Q2256, 2026-11-20).

## Open follow-ups

## Built log
