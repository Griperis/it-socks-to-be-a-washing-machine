---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: economy
priority: now
created: 2026-11-26
done:
blocked_by: ["[[171-filter-nozzle-and-display]]", "[[172-backpack-vacuum]]", "[[129-upgrades-and-menu]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 8", "suggested model: sonnet"]
terms: [Upgrade, Big Bag, Strong Suction, Long Hose, Wide Nozzle, Filter nozzle, Old Tree]
suites: [vacuum, upgrades, economy, furniture_devices, zoo]
---

# The five vacuum Upgrades take effect

Big Bag, Strong Suction, Long Hose, Wide Nozzle and Filter nozzle stop being "Coming soon" and change the vacuums.
Build `docs/architecture/devices.md` "How it is authored" (the five `UpgradeStat`s), draft 150-K:

- `big_bag` (ADD, base 24, step 12, "%d": the Sock vacuum's capacity; a Backpack adds the same over its 16),
  `suck_interval` (ADD, base 0.12, step -0.02, shown as Socks a second "%.1f/s" through a new `UpgradeStat.per_second`
  flag), `long_hose` (ADD, base 5, step 2, "%d m"; nothing for the Backpack), `wide_nozzle` (ADD, base 0, step 1: each
  level adds `wide_reach` 1 m and `wide_cone_deg` 10 to both vacuums), `filter_nozzle` (FLAG), in
  `game/economy/stats/`, set as `stat` on the five Upgrade files;
- `Vacuum` reads capacity, interval, hose, reach and cone through `Upgrades.value` when it uses them, never cached;
- the real Old Tree placed in the vacuums station beside its own `Upgrades` and `Bank`.

Behaviour lines (`docs/migration/m4-lists/09-vacuums-and-detector.md`, V1-V53 in its order as `devices.md` numbers them): V48-V52.

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
The stats are `.tres` (a new effect is a file plus one line in `Vacuum`); their prices and cells stay as core/129 set
them (`# placeholder:`).

## Acceptance
- Real path: in the vacuums station with 5 Drawers the player presses E on the Old Tree, clicks Big Bag (it reads
  "1/2"), closes the menu, takes the nozzle and holds the left button at 40 loose Socks: the Tank stops at 36 ("Sock
  vacuum   36/36"); a Backpack then fills to 28.
- The cards read "24 -> 36", "8.3/s -> 10.0/s", "5 m -> 7 m"; none of the five reads "Coming soon".
- Long Hose lets the walk go 7 m; Wide Nozzle takes a Sock 2.8 m away at 30 degrees; a bought Upgrade changes a vacuum
  already in use at once.
- Placeholders: the stats' bases and steps.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The vacuums as the old (Q2698, 2026-11-26).
- The batch C Upgrades are "Coming soon" until their pieces (Q2669).

## Open follow-ups
