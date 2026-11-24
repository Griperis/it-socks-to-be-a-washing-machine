---
type: ticket
status: ready-for-agent
kind: bug
area: core
feature: frame
priority: later
created: 2026-11-24
done:
blocked_by: []
notes: ["suggested model: sonnet", "from core/67's first still (Q2645)"]
terms: []
---

# The pad's selection ring does not show in the Lobby

core/67 added the Lobby's pad route, but in its stills (`builds/review-lobby-details/lobby-look-pad-first.png`,
`-pad-drawer.png`) the selected button shows no ring: it looks the same as with a mouse.

## Acceptance
- Reproduced first: a still with a pad-focused button and no ring.
- The focused button shows the Theme's focus ring on the pad route (Lobby buttons and the World drawer); a still shows it.
- The pad route's case checks the focus style is drawn, not only that focus moved.

## Open follow-ups

## Built log
