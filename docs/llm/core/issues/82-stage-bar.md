---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: frame
priority: now
created: 2026-11-24
done:
blocked_by: [core/76]
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: sonnet"]
terms: [Stage, Collection, Laundry day]
---

# The Stage bar and its phases

The HUD's Stage bar: build `docs/architecture/stages.md` "The Stage bar" with its `StageBarPhase`s: the old panel and layout on the
Theme's `StagePanel`, the stacked Collection icons, "Stage %d: %s  %d/%d", the fill's moves, the drain and refill at a
new Stage with the icons popping in, full between completion and Fix; the goal phase "Wash the laundry" before the
First wash (Q2625), and the change to the Laundry day phase with the old fold (Q2621). The providers: `Stages` answers
`stage_rows`; core/93's `LaundryDay` answers `laundry_bins` (until then the station's stand-in provider).

Behaviour lines (`docs/migration/m4-lists/03-stages-and-floors.md`): "The Stage bar (HUD)" (all); `docs/migration/m4-lists/04-first-wash-and-laundry-day.md` "The Laundry day": the fold and the tally lines (the
words now the phase's).

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

The three phases are Resources on `StagePlan` (text, source, track, icons); `StageBarTuning` placeholders. A
later phase is a new Resource and a provider: no bar change. No station change: the phases are checked in the Stages
station by a case that sets the run's state with a test-side stand-in provider.

## Acceptance
- Real path: in the Stages station the player clicks a Pair into Cabinet A; the bar reads "Stage 1: Basement  1/4" (the mini plan's numbers) and its fill moves; after "Fit now" it drains and refills with Stage 2's icons.
- Set to each phase the bar shows "Wash the laundry" with no track, then the Stage, then the fold into "Wash clothes 0/3".
- The bar redraws only on a change; hidden in a level with no run.
- Placeholders: `StageBarTuning`; the phase texts are the designer's to change.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The bar stays full between completion and Fix; its text authorable per phase; the Laundry day's reads "Wash clothes N/M" (Q2621, 2026-11-24; the Laundry day as that phase is the lead's reading).
- Before the First wash a HUD goal line "Wash the laundry" in the Stage bar's place (Q2625, 2026-11-24).
- Floor names as the old (Q2622, 2026-11-24).

## Open follow-ups

## Built log
