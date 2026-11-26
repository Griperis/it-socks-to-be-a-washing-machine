---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: ui
priority: now
created: 2026-11-26
done:
blocked_by: ["[[182-xrays-owning-and-clock]]"]
notes: ["batch C (Q2614); order: docs/migration/milestones.md Batch C, wave 5", "suggested model: sonnet"]
terms: [X-ray, Cabinet X-ray]
suites: [xray_hud, pings, ui_nodes, ui_icons]
---

# The X-rays on the HUD: the icons and the screen tint

Each owned X-ray shows a keycap icon at the bottom left with its key under it: greyed while nothing held fits, a sweep
while it cools down, pressed with a breathing halo and a ring while on, a pulse and a sound when it becomes ready with
a fitting item held; and a faint tint with an edge vignette over the screen while one is on. Build
`docs/architecture/x-rays.md` "The HUD", draft 152-D:

- `ability_icon.tscn` and `.gd` (`Halo`, `Keycap` with `Picture`, `Sweep`, `Ring`, `Key`; states HIDDEN, READY, GREYED,
  COOLDOWN, ON) and its clips `press`, `release`, `halo`, `ready_pulse`; the Theme variations `AbilityKeycap`,
  `AbilityKeycapGrey`, `AbilityKeycapOn` on `game/look/theme.tres`;
- `AbilityIcons` (an `HBoxContainer` bottom left, 24 px in and up, separation 28) and `XRayScreen` (`xray_screen.tscn`,
  `xray_screen.gdshader` ported, after the `Vignette` under every other HUD node, two slots) in `player.tscn`'s `Hud`;
- the icons in the HUD's `keep_clear()`; `xray_ready` with `ready_pulse` on `became_ready` (its SoundEvent is
  core/154's);
- stills of both icons in each state and of the tint with both on in `<main checkout>/builds/review-xrays/`.

Behaviour lines (`docs/migration/m4-lists/10-x-rays.md`, by heading): "The ability icons (HUD)" (all 5); "How they look" line 2 (the screen tint).

Batch C is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-c-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is built (Q2277); one left out goes to the lead before the
merge, never `[later]` on its own.

## How it is authored
The icon is nodes, Theme variations and clips (Q2658, Q2697); the tint's numbers (`tint` 0.06, `vignette` 0.45,
`vignette_start` 0.45) on its material in the inspector; its strength is the clock's value set from the Timer.

## Acceptance
- Real path: key 1 with a Sock held, through `XRay` and the HUD's wiring, to the icon's `press` clip played and the
  screen tint's slot 0 at strength 1.
- With neither Upgrade owned no icon shows; owning the X-ray shows its icon at the bottom left with "1" under it, the
  Cabinet X-ray's 28 px to its right; with empty Hands it is greyed (alpha 0.72); a Sock picked lights it with no
  pulse and no sound.
- The `Ring` falls from 1; the tint falls to 0 over the show's last 3 s; at the end `release` plays and the `Sweep`
  starts at 1; the cooldown ending with a Sock held plays `ready_pulse` and `xray_ready` once; ending with empty Hands
  plays neither, and a later pick only lights it; both on, both tint slots are set.
- A hint arrow at the bottom left slides clear of the icons.
- Placeholders: the tint's numbers.
- `kit/tools/run.sh --touched` ends PASS; the real-path case drives player input through the scene's own wiring.

## Answers
- The ready sound borrows the Sole Mates cue; no cue until it is usable (Q2701, 2026-11-26).
- Motion is clips, not code tweens (Q2697, 2026-11-26).

## Open follow-ups
