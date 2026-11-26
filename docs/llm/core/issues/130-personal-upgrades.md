---
type: ticket
status: done
kind: build
area: core
feature: economy
priority: now
created: 2026-11-26
done:
blocked_by: ["[[129-upgrades-and-menu]]"]
notes: ["batch B (Q2614); order: docs/migration/milestones.md Batch B, wave 5", "suggested model: opus"]
terms: [Upgrade, Personal, Footwork, Quick Grab, Big Hands, Long Arm, Quick Charge, Carry capacity, Throw, Hands]
suites: [player, handling, hand_details, throw, flight_start, coop_hands, coop_flight, coop_guard, aim_screen]
---

# The Personal Upgrades take effect

Footwork, Sprint, Quick Grab, Big Hands, Long Arm and Quick Charge change play. Build `docs/architecture/economy.md`
"The Personal effects" (the six rows) and "The Hands numbers in co-op":

- Their six stats set on their Upgrade files and read by the player's walk (`walk_speed`), the new `sprint` action
  (Shift, pad RT, `python3 kit/tools/input_actions.py add`; x `MoveTuning.sprint_multiplier` 1.3 while held, only once
  bought) and its corner hint "Sprint [Shift]" once bought, the Hands' pick gap (`grab_interval`), capacity (`carry`,
  1 to 5), a full Throw's speed (`throw_speed`) and charge (`charge_time`). Features read `Upgrades.value()` when they
  use it, never cached at ready; a level without an Upgrades Part keeps its own tuning.
- The Host derives each player's Hands numbers from the levels it keeps: D13's sent numbers and `HandsTuning.*_most`
  go (`session_gate.gd`); `docs/architecture/coop.md` updated.

Behaviour lines (`docs/migration/m4-lists/06-coins-drawers-upgrades.md`): "The Upgrades", the lines of these six
(their effects and numbers).

Batch B is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-b-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
Each effect is its `UpgradeStat` file (kind, base, step, least, format), `# placeholder:` the old
`data/tuning/upgrades.json` numbers; the feature holds the stat as a typed export (a missing file is a load error).

## Acceptance
- Real path: in the Economy station the player buys Big Hands I in the menu by a click, closes it, presses pick on two
  loose Socks and both are in the Hands (the readout "2/2" with Sock Smarts).
- Co-op: a Guest with Big Hands I picks two Socks on the Host; a Guest cannot claim a capacity its levels do not give.
- With Sprint bought, holding Shift walks 1.3 times faster and the corner shows "Sprint [Shift]"; before it, Shift does
  nothing.
- Placeholders: the six stats.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- Upgrades as Resources with their effects as data (Q2607, Q2613, 2026-11-24).

## Open follow-ups
