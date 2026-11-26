---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: economy
priority: now
created: 2026-11-26
done:
blocked_by: []
notes: ["batch B (Q2614); order: docs/migration/milestones.md Batch B, wave 1", "suggested model: opus"]
terms: [Coins, Drawers, Drawer, Cabinet, Stage]
suites: [cabinet, cabinet_growth, drawer_details, pairing, stages, run_tallies, final_screen, save, coop_join, coop_hands, zoo]
---

# Coins and Drawers: the Bank, the payouts and the HUD counters

Both currencies as one decided Part, every payout of them and the two counters on the HUD. Build
`docs/architecture/economy.md` "The shape" (`Bank` only), "`Bank`'s state and verbs", "The HUD counters and the
flight", the `Currency`, `EconomyTuning`, `CoinFlightTuning` and `Stage.drawer_payout` of "How it is authored", and the
Economy zoo station's first half.

- `Coins` (`game/coins/coins.gd`) becomes `Bank` (`game/economy/bank.gd`) with `drawers`, `recent`, `welcome` and
  `cheat` (debug builds, the `debug_cheat_coins` action on F9 added by `python3 kit/tools/input_actions.py add`); the
  group `coins` becomes `bank`; every reference moves in this ticket (the Cabinet's export, `LevelRuntime`,
  `RunTallies`, the Final screen station, tests: economy.md "Gotchas").
- The drawer payout and the Cabinet bonus in `Cabinet._shelve` (`Cabinet.bonus_rows`, once per Rows count, again when
  a grown Cabinet's new Rows all fill); the floor bonus in `open_floor` and in the last Fix's answer; both bonuses into
  `RunTallies` coins (Q2667).
- A bonus shows as the old: no "+N" and no flying icons; its Coins land one by one in the counter over the payout's
  spread, `bonus_delay` later than a "+N"'s, the icon pulsing and `coins` playing per landing (Q2668).
- Spendable Coins are the landed ones: the Host keeps `recent` payouts and their landing times (Q2672); a load or a
  join lands them at once.
- The HUD: `money_counters.tscn` (two `money_counter.tscn`) at the top left, `coin_flight.tscn` with a pool of
  `flying_icon.tscn` and `money_pop.tscn`, the Drawer flight 80 px higher in the House blue, `coins` and
  `drawer_clack` (shares `drawer_close`) as SoundEvents, the pad's "done" buzz on a filled drawer.
- The Economy station `game/zoo/stations/economy.tscn` (its things under `game/zoo/economy/`, instanced by hand in
  `zoo.tscn`): a small Cabinet (drawer capacity 2, its own `CabinetTuning`) with a `SockGenerator` of its Pairs, the
  station's own Bank, the counters, the switches "+100 Coins" and "+5 Drawers".

Behaviour lines (`docs/migration/m4-lists/06-coins-drawers-upgrades.md`): "Two currencies" and "Coins and Drawers on the
HUD", all of them (the Collection-complete pop is named there as not ported; the refund's line is core/138's).

Batch B is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-b-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
- `Currency` Resources `coins.tres` and `drawers.tres` (name, icon, tint: Q2610's tunable names and icons);
  `EconomyTuning` (`floor_bonus` 100, `cabinet_bonus` 50, `cheat_coins` 1000), `Stage.drawer_payout` on the four Stage
  `.tres` (1, 1, 2, 3), `CoinFlightTuning` (economy.md "Numbers"): all `# placeholder:` the old values.
- The counters, the pop and the flying icon are scenes on the one Theme (Q2658); code instances them from a pool and
  never builds a Control. The flight's motion is tweens on those nodes' properties, its numbers in the tuning.

## Acceptance
- Real path: in the Economy station the player, holding the Pairs that fill a drawer, presses the pick key on that
  drawer; a Coins "+N" and a Drawers "+1" pop over it, fly, and the HUD counters then read the new totals.
- In the Stages station's mini run, opening a floor pays every player 100 with no "+N": the Coins counter counts up
  after the delay; filling a Cabinet's current Rows pays the filler 50 the same way.
- A purchase check of the Host (a test calling the Bank's spendable Coins) refuses Coins still flying and allows them
  once landed.
- Co-op: a Guest joining a saved World keeps its Coins; a new id gets the average of the present players' Coins,
  rounded down.
- F9 in a debug build gives the Host 1000 Coins with no flight and the message "Debug: +1000" with the Coins name; a
  Guest's F9 does nothing.
- The save shape (`shape.json`) changes from `Coins` to `Bank`; the Final screen's totals still read the tallies.
- Reachable in the main scene: the counters show in a house New Game.
- Placeholders: `EconomyTuning`, `CoinFlightTuning`, the four `drawer_payout`s.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- Stage Coins bonuses as the old: +100 to every player when a floor opens, +50 to whoever fills a Cabinet's current
  Rows (Q2667, 2026-11-25).
- A bonus shows as the old: the counter counts up, no "+N" (Q2668, 2026-11-25).
- Coins still flying are spendable only once landed (Q2672, 2026-11-25).
- Two currencies; names, icons and payouts tunable (Q2610, 2026-11-24).

## Open follow-ups
