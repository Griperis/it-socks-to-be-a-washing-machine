---
type: ticket
status: ready-for-human
kind: build
area: assets
feature: assets
priority: now
created: 2026-11-24
done:
blocked_by: [core/85]
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: sonnet"]
terms: [Voice line]
---

# The washing machine's subtitle icon

The washer's icon on its subtitle row (V6, Q2550): a flat drawn icon in the UI icons' style (assets/03,
`UiIcons`), the porthole and brows read at subtitle size, set as `washer.tres`'s `icon` in place of core/85's plain
disc. Design: `docs/architecture/voice.md` "Decided".

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the lines named below is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

An SVG in the UI icons' folder, imported as the others; nothing else.

## Acceptance
- Look work: stops at its first still (the icon beside a subtitle row at 1080p, and among the UI icons) in `builds/review-assets-15/`, `ready-for-human`.
- No real-path case (Q2421).

## Answers
- The washer's subtitle icon is a flat drawn icon in the UI icons' style, its own look ticket (Q2641, 2026-11-24).

## Open follow-ups

## Built log

- 2026-11-25: Changed: `assets/ui/washer.svg` (64x64, the UI icons' outline and palette: cream body, red knob, blue porthole,
  two thick angry brows), set as `washer.tres`'s `icon`. Files: assets/ui/washer.svg(.import), game/voice/speakers/washer.tres,
  tools/washer_icon_still.gd/.tscn (the still scene). Still: `builds/review-assets-15/washer-icon-lineup.png` (subtitle rows at
  1080p, the washer's beside a no-icon row, and the icon among coins/dirty/drawers/carry/animals/check/key at 128 and 44 px),
  `washer-icon-zoom.png` (8x). Stopped at the first still. The zoo Icons station lists it by itself (group "other").
  Verified: suite PASS (ui_icons and voice cases updated: the folder lists "washer", the row has an icon); rules, asset_lint PASS.
