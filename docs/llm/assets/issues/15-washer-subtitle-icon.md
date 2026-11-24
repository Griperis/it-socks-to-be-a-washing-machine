---
type: ticket
status: ready-for-agent
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
