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

- [later] The Lobby's player plinth already lights gold for the focused place (`_sync_focus`, ported in core/66-67); left as is, not lifted.
- [later] The glow is a Panel the lit control carries as an internal child; if a screen's look needs a different glow shape, it is one tuning Resource.

## Built log

### 2026-11-24 (stopped at the first still, for the designer)
- Reproduced: the Theme's `focus` style of KeycapButton and ExitButton was the hover face (a slightly lighter keycap), so a pad-selected button looked like any other (`pad-ring-before-crop.png`).
- Changed: `focus` of KeycapButton and ExitButton is now a ring (cream, 4 px, 5 px out, rounded; `StyleBoxFlat_focus_ring` in `game/look/theme.tres`, placeholder look). Note: a mouse-clicked button keeps focus too, so it shows the ring after a click.
- Still: `builds/review-lobby-details`-style, now `builds/review-lobby-pad-ring/pad-ring-after-first.png` (the "i" key selected).
- Not yet done: the focus-style-drawn assertion in the pad route's case, a drawer still with a selected drawer button, ChoiceButton/ChoiceOnButton (options screens) left as they are. Waits for the designer's go on the ring's look.
- Files: game/look/theme.tres

### 2026-11-24 (second still round, stopped again for the designer)
- Changed: every focusable control type on the Theme (KeycapButton, ExitButton, EscButton, CloseButton, ChoiceButton, ChoiceOnButton, MenuField, MenuSlider, LicenceLink; CornerKey inherits) has one `focus` style, the new `FocusRingStyle` (`game/look/focus_ring_style.gd`): the cream ring (4 px, 5 px out, rounded) with a 2 px ink line outside it, because plain cream vanished on the cream panels. It shows only after a key or pad press and hides after a mouse button; `UiSounds` (the menus' autoload) feeds it the window's input, no new autoload. A slider draws no focus style of its own, so `SliderRow` draws the ring round its slider.
- Case: `lobby:k11_pad_route` checks the first pad press leaves the selected key with the ring style and `FocusRingStyle.shown`, and a mouse click clears it (the suite's `_key` and `_click` also tell the window's `window_input`, which a parsed event skips). Pixels are not drawn headless; the stills show it.
- Stills: `builds/review-lobby-pad-ring/ring-*.png` (title home, name field, join, options slider and choice, licence, licence key, ESC menu, lobby "i", drawer).
- Files: game/look/theme.tres, game/look/focus_ring_style.gd, game/audio/ui_sounds.gd, game/ui/options/slider_row.gd, tests/lobby_test.gd, tools/shot_lobby.gd, tools/shot_hooks.gd
- Verified: PASS 19773 checks, 615 cases; PASS rules.

### 2026-11-24 (third round: Q2647-Q2650, stopped again for the designer)
- Changed: the ring is gone (`FocusRingStyle` deleted; every Theme `focus` style is empty). The old lit look is ported: the selected control lifts 5 px, grows to 1.08 over 0.1 s, a gold glow (#f6c443, 0.85, size 16, radius 14) fades in behind it (`game/ui/pad_focus.gd`, numbers in `game/ui/pad_focus_tuning.gd` and `.tres`). A slider only glows. It holds across container re-layouts (re-applied after the parent's `sort_children`). Only a key or pad selection lights; a mouse click never does (Q2648).
- Nothing per screen or control: `UiSounds` feeds `PadFocus` the root viewport's `gui_focus_changed` and window input. Opt out with the meta `own_lit`. "How to add a button" is in `docs/architecture/saves.md` and the tuning's doc comment.
- Licence links take focus (`focus_mode = 2`, Q2649). The World row's Delete key now has its text ("Delete"), full width, and the name is cut with "..." (Q2650).
- Case: `lobby:k11_pad_route` checks the selected key is lit (`PadFocus.is_lit`) with an empty focus style, grows to 1.08, the light moves with the selection, holds across a re-layout, and a mouse click lights nothing.
- Stills: `builds/review-lobby-pad-ring/lit-*.png` (title home, name, join, options slider and choice, licence link, licence key, ESC menu, lobby "i", drawer, drawer Delete row).
- Files: game/ui/pad_focus.gd, pad_focus_tuning.gd/.tres, game/audio/ui_sounds.gd, game/look/theme.tres, game/lobby/world_row.gd, game/ui/licence/licence_link.tscn, tests/lobby_test.gd, tools/shot_lobby.gd, tools/shot_hooks.gd, docs/architecture/saves.md
- Verified: PASS 19777 checks, 615 cases; PASS rules.
