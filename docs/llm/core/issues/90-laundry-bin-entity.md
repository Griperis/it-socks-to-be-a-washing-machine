---
type: ticket
status: done
kind: build
area: core
feature: laundry
priority: now
created: 2026-11-24
done: 2026-11-25
blocked_by: [core/78]
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: sonnet"]
terms: [Laundry bin, Hands]
---

# The Laundry bin

The carried hamper of laundry as an entity: build `docs/architecture/run-ends.md` "The Laundry bins (the entity)" without the draw (core/93):
`laundry_bin.tscn` (a `Carriable` with the bin's `HoldSlot` and the `LaundryBin` Part: `used`, `full`, `always`), a
graybox Looks with the contract `assets/13` keeps (`Contents` heap, blend shape `empty` as `1 - fill`, eased, the `tip`
animation turned toward the washer), readout words, hidden from the draw in cutscenes (core/88's hide list), and the
bins in the Laundry station.

Behaviour lines (`docs/migration/m4-lists/04-first-wash-and-laundry-day.md`): "The Laundry bins (the entity)" (all but the draw and the spots, core/93).

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

`LaundryTuning` (`bins_per_world` 3, `tip_seconds` 1.4, `pile_min` 0.4), placeholders; a bin spot is a placed
instance, never a list.

## Acceptance
- Real path: in the Laundry station the player left-clicks a bin, carries it and right-clicks the floor; it lies there at the held yaw and its readout says "Laundry bin, dirty".
- A full and an empty bin read "Laundry bin, dirty" and "Laundry bin, empty"; the heap follows `full`.
- core/42's Hand-off refuses the bin; right click at a Teammate hands it over.
- Placeholders: `LaundryTuning`.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- A carried bin does not slow its carrier (Q2628, 2026-11-24).

## Open follow-ups
- [later] core/88's Cutscene frame: call `LaundryBin.set_drawn(false/true)` on the group `laundry_bins` (the bin's hide hook, built here; carried or lying).
- [later] core/86's washer entity: join the group `washer` (`LaundryBin.WASHER_GROUP`), which `tip()` leans toward (the Laundry station's Washer is in it).
- [later] core/93: place the seven bins under `LaundryBins` in `house.tscn`, write `used` and `full` in the draw's and the load's answers, and call `tip()` on every machine from the load's answer (the zoo's Bin pillar shows how).

## Built log

### 2026-11-25
- Changed: `laundry_bin.tscn`: a `Carriable` (the bin's HoldSlot, `handable` on) and the `LaundryBin` Part (`used`, `full`, `always`); crosshair words "Laundry bin, dirty" / "Laundry bin, empty"; graybox Looks (`Contents` heap eased to `full` at 0.8 a second, hidden when empty; `tip` animation, 105 degrees over `tip_seconds`, turned toward the washer); unused bin hidden, solid-free, not aimed; `set_drawn()` for cutscenes. `LaundryTuning` placeholders. Laundry station: a full and an empty bin, the Bin pillar (empties or fills the full one, which tips), the Washer in group `washer`. Settled by the old game: three rows in batch-a-review.md.
- Files: game/entities/laundry_bin/*, game/laundry/laundry_tuning.gd, game/laundry/laundry_tuning.tres, game/zoo/laundry/bin_pillar.gd, game/zoo/stations/laundry.tscn, tests/laundry_bin_test.gd, docs/migration/batch-a-review.md
- Verified: `kit/tools/run.sh --touched` PASS (20722 checks); laundry_bin 35 checks.
- Merged: 87e785e8 (2026-11-25, branch core/90-laundry-bin-entity)
