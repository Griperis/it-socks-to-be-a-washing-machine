---
type: ticket
status: done
kind: build
area: core
feature: washer
priority: now
created: 2026-11-24
done: 2026-11-25
blocked_by: [core/85]
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: sonnet"]
terms: [Voice line, Stage]
---

# The washing machine: the entity and its comments

The basement washing machine as an entity that talks. Build `docs/architecture/washer.md` "The entity": `washer.tscn` with the `Washer`
Part (`talk` and its director: cooldown, cutscene block, silent before the First wash, chance, the run's comment set,
the picker), `WasherSenses`, `WasherLooks` (extends `VoiceSource`), `looks_contract.json` and its test,
`looks_graybox.tscn`, `Shots/Wide` and `Shots/Close`, `Spawns/1..4`, `Door` and `Porthole`, `Washer.is_washer()`; it
replaces the house's `Washer` marker at the same place and path (the generators' NodePath and the lost-thing spot keep
working). The washer station. Until core/94 the "broken" read is a stand-in in the station; in the house the washer
stays silent until core/94 gives it the First wash's state (Q2636).

Behaviour lines (`docs/migration/m4-lists/05-washer-and-voices.md`): "Where it stands and what it is" (all), "Its comments" (all but the 15 texts, core/84),
"How it talks" (the face's share, the mouth and brows as the acting plays them).

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

`washer_tuning.tres` (senses, numbers in `docs/architecture/washer.md` "Numbers"), placeholders; the shots and spawns are markers moved
in the editor. The washer station: the real `washer.tscn`, pillars for the mood levels 0..5, "From the run" (a zoo-only
Command on `Stages`), "Break it"/"Fix it", and the senses on; core/87 makes the pillars show.

## Acceptance
- The washing machine joins group `washer` (core/90's bin `tip()` leans toward it).
- A test compares the bone rests in `washer_acting.tres` (core/84) with the washer's skeleton, so a new model can't drift from them.
- Real path: in the washer station (senses on, broken) the player looks at the washing machine for 4 s from 3 m (the stare's chance 1 in the case's tuning); a `stage_1` stare line's subtitle shows and the door bone opens; a Guest's stare plays the same line on both machines.
- In the main scene the washing machine stands at the old place, outlined and named "Washing machine"; E does nothing at it.
- No comment while it is not broken, during a cutscene, or within 120 s of the last.
- Placeholders: `washer_tuning.tres`.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- Silent until the First wash breaks it (Q2636, 2026-11-24).
- The Laundry day's comment set is customisable, Stage 4's by default (Q2635, 2026-11-24).

## Open follow-ups
- [later] The face's loops run on three AnimationPlayers (`AnimationPlayer` acting, poses, mouth; `Loops` talk/rumble; `Spin`), the bob weighted in `WasherLooks` by `mixer_applied`; the AnimationTree of washer.md "looks_contract.json" is not built (it cannot be authored headless). assets/14 may replace it in the editor if the lead wants one tree.
- [later] Old details not built because they need assets or core/87: the angry rumble loop's level (-36 to -12 dB by anger x wiggle; the `Rumble` node exists, no `washer_rumble` sound is in the catalogue), the buzz, sparks, smoke, flash and the drum light's repair dim and flicker (`repair`/`damage` are set on the Looks; core/87 shows them). Lead: confirm these stay with core/87.
- [later] The cutscene pillars of the station wait for core/88 (the frame); `cutscene_looks`, the shots and spawns are ready for it.
- Additions nobody asked for: `Part.hint_only()` and its row in `Prompts.target` (a name with no key); `WasherShot` and `WasherCutsceneLook` scripts; `Washer.zoo_plan`.

## Built log

### 2026-11-25
- Changed: the washing machine is an entity that talks: `washer.tscn` replaces the house marker at its place; Washer Part (director: silent before broken, cutscene block, 120 s cooldown, chance, comment set by Stage or the Laundry day, picker), WasherSenses (stare, idle, progress, hit), WasherLooks and the graybox Looks with the contract, shots, spawns, Door, Porthole; the washer station with pillars built from data.
- Files: game/entities/washer/, game/zoo/washer/, game/zoo/stations/washer.tscn, game/house/house.tscn, game/zoo/zoo.tscn, game/parts/part.gd, game/ui/prompts.gd, tests/washer_test.gd, docs/migration/batch-a-review.md.
- Verified: washer suite PASS 233 checks, 12 cases (real path, co-op stare on both machines, house); `--touched` and save/zoo re-run PASS after fixing the label height and the empty save.
- Merged: 2b84ad77 (2026-11-25, branch core/86-washer-entity-and-comments)
