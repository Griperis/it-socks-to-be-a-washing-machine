---
type: ticket
status: ready-for-human
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

### 2026-11-24 (stopped at the first still, for the designer)
- Reproduced: the Theme's `focus` style of KeycapButton and ExitButton was the hover face (a slightly lighter keycap), so a pad-selected button looked like any other (`pad-ring-before-crop.png`).
- Changed: `focus` of KeycapButton and ExitButton is now a ring (cream, 4 px, 5 px out, rounded; `StyleBoxFlat_focus_ring` in `game/look/theme.tres`, placeholder look). Note: a mouse-clicked button keeps focus too, so it shows the ring after a click.
- Still: `builds/review-lobby-details`-style, now `builds/review-lobby-pad-ring/pad-ring-after-first.png` (the "i" key selected).
- Not yet done: the focus-style-drawn assertion in the pad route's case, a drawer still with a selected drawer button, ChoiceButton/ChoiceOnButton (options screens) left as they are. Waits for the designer's go on the ring's look.
- Files: game/look/theme.tres
