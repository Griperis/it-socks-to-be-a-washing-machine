---
type: ticket
status: done
kind: build
area: core
feature: core
priority: now
created: 2026-11-19
done: 2026-11-20
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
Built on core/02 (Mess, Hands), core/03 (Pairs as linked records, named by the lead Sock) and core/08 (the Throw's
Flight and its Host-side contacts). Old code: `game/campaign/cabinets.gd`, `drawers` rules, `house/openable.gd`,
the per-Collection models in `assets/cabinet/` (a `base`, stacked `segment`s, a `drawer` with `slot_01..25`).

**The entities** (the kit's pattern: behaviour Parts plus a swappable `Looks`; code shape Q2251-Q2253):
- `game/entities/drawer/drawer.tscn`: one drawer. Its only behaviour is the kit's `Openable` (open, locked); its
  `Looks` has the AnimationPlayer `open` (a slide) and the slot points `Slot01..Slot25` where shelved balls show.
  No script of its own.
- `game/entities/cabinet/cabinet.tscn`: the root (its collision is the footprint), a `Cabinet` Part, a `Looks`
  (base, segments, top), and `Drawer1..DrawerN` as instances of `drawer.tscn`, one per segment the model has.
  Contract (`looks_contract.json`): `Base`, `Segment1..N`, `Top`.

**State and who owns it**
| State | Part |
|---|---|
| The Collection, `locked`, `rows` (drawers in use, 2 to start), and the shelf: each drawer's shelved Pair leads in order | `Cabinet` |
| Each drawer open or shut | that drawer's `Openable` (the kit's, unchanged) |
| A shelved Pair's two Sock records | `Mess`, new state `SHELVED` (not drawn by the Mess; the drawer shows it) |
| Each player's Coins | a new `Coins` Part, keyed by player id (in M4 the Players Part with Personal upgrades) |

**Commands**
- `shelve(drawer)` to `Cabinet` (a left click on a drawer while holding Pairs): refused "locked", "wrong" (no held
  Pair of its Collection: "Wrong Cabinet"), "full" (no room in any row: "Cabinet full"), "far". Granted, one
  answer changes four kinds of Part: the held Pairs of its Collection leave the Hands in order (others stay, C02),
  their records become SHELVED (Mess), they join the aimed drawer then overflow to the nearest with room, the
  lower when two are as near (C03, Cabinet), each drawer used opens (Openable), and the shelver gets 10 x rarity
  per drawer used (Coins, C05).
- With empty Hands (or only loose Socks) the click is the drawer's own `Openable.use` (C04), unchanged.
- `thrown_shelve(sock, by)`, Host-only (nothing in `accepts()`): when a flying Pair's body touches its own
  Collection's Cabinet (core/08's contact report), the lowest drawer with room takes it, opens, and pays the
  thrower (T05). Another Collection's, a locked or a full Cabinet, or a loose Sock: nothing is asked and the body
  bounces as physics does (T06, T07).

**Capacity** (Q2256): `drawer_capacity` is a `CabinetTuning` field, 25 today. The model has 25 slot points; a
drawer holding more draws the first 25 and keeps the rest in the shelf state (shown when real models with more
slots arrive). Nothing in code assumes 25.

**Looks**: shelved balls are drawn in their slots by the drawer's Looks from the Cabinet's shelf state (`_show`);
the drawer slides by its AnimationPlayer (Q2213). No icon (C11). The stand-in look is the old `assets/cabinet/simple.glb`, copied unported (Q2265).

**The station** `game/zoo/stations/cabinet.tscn`: one Cabinet of the Simple Collection (Q2266), Socks of Simple and of
another Collection nearby (so "Wrong Cabinet" and the bounce can be tried), a Door (an `Openable` with a swinging Looks,
D02, D05), and room to throw.

**Numbers** (`CabinetTuning`, `# placeholder:`): drawer_capacity 25, start rows 2, coins per rarity 10 x (1, 2, 5),
reach 2.5 m, Door swing 0.6 s.

**Tests**: one case per line (C01-C05, C08, C11, T05-T07, D02, D05, D08, C14), the invariants I.5 and I.12, a
snapshot round trip with Pairs shelved (C12). Real path: in the station, with real input, pair two Socks, click
the Cabinet's drawer, see the Pair in its slot and the Coins; throw a second Pair at it.


## Acceptance
- The Cabinet is an entity: behaviour plus a Looks scene with a `looks_contract.json`; `kit/tools/asset_lint.py` passes.
- Shelving by click and by Throw both work and are tested; what is refused is tested.
- The designer plays the four stations in one run of the zoo.

## Answers
- The behaviour list is approved, with one change: the Pairs a drawer holds is configurable (a tuning field, 25
  today), not fixed by the model; the model keeps its 25 slots (Q2256, 2026-11-20).
- The design is approved (Q2264, 2026-11-20).
- The Cabinet's stand-in is the old `simple.glb`, unported, until M1 (Q2265, 2026-11-20).
- The zoo's Cabinet takes the Simple Collection (Q2266, 2026-11-20).
- Merged as built, with the left click that uses anything not a Sock (Q2282, 2026-11-20).
- The shelving flight and the old drawer slide ease go into core/09 (Q2283, 2026-11-20).
- The zoo gets one Mess and one Hands, so a Pair is carried between stations: core/10 (Q2284, 2026-11-20).
- The refusal order is the old game's: "Wrong Cabinet" before "Cabinet locked" (Q2285, 2026-11-20); fixed on main with
  the case `c08_wrong_before_locked`.
- Old details not built: the drawer and Door sounds go to M1.1 (Q2278); the "+N" Coins pop, a filled drawer's
  pay and the Rows dropping in are M4's (C06, `docs/migration/old-details-backlog.md`); "Pair socks first" is
  replaced by C04 (approved list).

## Open follow-ups
- [closed 2026-11-21] Drawer3 is above the 2 Rows: a click with empty Hands does nothing; with Pairs the search starts at the
  top Row (the old rule). — the old rule stands (the port keeps old rules, Q2153); nothing to change
- [closed 2026-11-21] A shelved Pair's lead is SHELVED and its mate stays IN_PAIR (the design said both SHELVED; IN_PAIR keeps
  "never drawn on its own" true for the mate). — IN_PAIR stays for the mate, it keeps "never drawn on its own" true; the design line is amended by this decision

## Built log
- Model: Opus (lead): a new entity with Openable drawers and a Part that spans the Mess and Hands.
- 2026-11-20 (agent): Changed: a `Cabinet` Part (Collection, locked, rows, shelf) with the `shelve`
  Command and the Host's `thrown_shelve` (a thrown Pair's contact, from the Mess's new
  `flight_touched` signal), `CabinetTuning` (capacity 25, 10 x rarity 1/2/5, reach 2.5, placeholders);
  `drawer.tscn` (the kit's Openable, Looks with `Slide`, `Slot01..25`, "open" 0.3 s) and `cabinet.tscn`
  (Base, Segment1..3, Top from the old `simple.glb`, its meshes saved by the importer); a `Coins`
  Part; the Mess's `SHELVED` state and `shelved_patch()`, the Hands' `taken_patch()`; a `door.tscn`
  (Openable, graybox swing 0.6 s); the player's left click uses a thing that is not a Sock and goes
  through the Cabinet for a drawer, says "Wrong Cabinet", "Cabinet locked", "Cabinet full", and uses
  the Hands of the station it stands in. Station `cabinet.tscn` off the grid at (9, 0, 5), pad 5 x 5.
  PROTOCOL 4. Shot hooks find the handling station by path.
  Files: game/entities/cabinet/, game/entities/drawer/, game/entities/door/, game/coins/,
  game/zoo/stations/cabinet.tscn, game/mess/mess.gd, game/hands/hands.gd, game/player/player.gd,
  game/parts/session.gd, tests/cabinet_test.gd, tests/handling_test.gd, tools/shot_hooks.gd
  Verified: PASS 833 checks, 127 cases (--touched); PASS rules; PASS asset_lint
- Merged: 70c275ed (2026-11-20, branch core/04-one-cabinet)
