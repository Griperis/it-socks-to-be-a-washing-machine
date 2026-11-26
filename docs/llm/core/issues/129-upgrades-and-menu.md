---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: economy
priority: now
created: 2026-11-26
done:
blocked_by: ["[[124-coins-and-drawers]]"]
notes: ["batch B (Q2614); order: docs/migration/milestones.md Batch B, wave 2", "suggested model: opus"]
terms: [Upgrade, Personal, House, Old Tree, Upgrade station, Coins, Drawers, Sock Smarts, Sock Sense]
suites: [player, aim_screen, outline, save, coop_join, ui_nodes, menus, furniture, zoo]
---

# The Upgrades and the menu at the Old Tree

The Old Tree opens the old grid of Upgrades (Q2611, Q2613), each Upgrade a Resource. Build
`docs/architecture/economy.md` "`Upgrades`' state and verbs", "How it is authored" (`Upgrade`, `UpgradeStat`, the 27
files, `UpgradeMenuTuning`, the menu scenes), "The Old Tree, the station" and "The Upgrade menu":

- `Upgrade`, `UpgradeStat`; the 27 `.tres` in `game/economy/upgrades/` with the old cells, prices, needs, tooltips and
  key hints: Sock Smarts and Sock Sense with their stats set (`PlayerUpgrades` reads the flags), the other six Personal
  ones and the three Sole ones with `stat` empty until core/130 and core/131 set it, the 16 batch C ones with `stat`
  empty (greyed "Coming soon", seen and not buyable, Q2669); the House prices re-scaled (Q1405) with the total test.
- The `Upgrades` Part beside the Bank in `level_runtime.tscn`: `buy` (refusals "Co-op only", "Maxed out", "Coming soon",
  "Locked", "Need <coins> %d" / "Need <drawers> %d"; spendable Coins are the landed ones, Q2672), `set_level`,
  `value`, `of`, the `bought` and `affordable` signals; the teammate line "<name> bought <Upgrade>".
- `OldTree` Part on `old_tree.tscn` (prompt "The Old Tree" with E, the outline round the tree's mesh, `use` opens this
  machine's menu); the menu freezes the player, frees the mouse, the world runs on; Esc or Close shuts it;
  `menu_open`, `menu_close`, `buy`, `refuse` SoundEvents.
- The menu: `upgrade_menu.tscn`, `upgrade_section.tscn`, `upgrade_button.tscn`, `upgrade_tip.tscn`, the header's
  `money_counters.tscn` (core/124's), Theme variations, the pad route (the old true grid), the tip card, the shake.
- The Economy station gets an Old Tree that opens the real menu, the Upgrades board listing every file from the folder
  (Q2337), and the switches "Reset levels" and "Co-op".

Behaviour lines (`docs/migration/m4-lists/06-coins-drawers-upgrades.md`): "The Old Tree, the Upgrade station" (not the
tree's call and the Doors on the way, core/132's), "The Upgrade menu", "Buying", "The Upgrades" (their data; the
effects are core/130's and core/131's), "Saves and co-op", "Words".

Batch B is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-b-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
A designer adds an Upgrade by dropping a `.tres` into `game/economy/upgrades/` (found by
`ResourceLoader.list_directory`, export-safe); its place is its `cell`. A new kind of effect is an `UpgradeStat` file
plus one line in the feature that reads it. The menu is scenes on the one Theme (Q2658): code instances one button per
Upgrade at its cell and a spacer per empty cell, and never builds a Control or a StyleBox. `UpgradeMenuTuning` and the
prices `# placeholder:` the old.

## Acceptance
- Real path: in the Economy station with 30 Coins the player presses E on the Old Tree and clicks Sock Smarts' button;
  it reads "1/1" and MAX and the Coins counter reads 0; a second click shakes it and the refusal reads "Maxed out".
- A batch C Upgrade's button is greyed and reads "Coming soon"; a click is refused "Coming soon".
- A co-op-only Upgrade is hidden in Solo and shown for a Host before anyone joins (Q1399).
- A Guest's purchase is decided by the Host; a save and a join keep the levels.
- The House prices total within 2 of 0.9 x the Drawers the house pays.
- Reachable in the main scene: E on the Old Tree in a house New Game opens the menu.
- Placeholders: the prices, `UpgradeMenuTuning`.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- Upgrades are bought at the Old Tree, which opens the Upgrade menu (Q2611, 2026-11-24).
- The Upgrade menu stays the old grid of icon buttons with levels and prerequisites; each Upgrade a Resource (Q2613,
  2026-11-24).
- The 16 Upgrades whose features come in batch C show greyed "Coming soon" until then (Q2669, 2026-11-25).
- Coins still flying are spendable only once landed (Q2672, 2026-11-25).

## Open follow-ups
