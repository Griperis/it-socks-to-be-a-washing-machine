---
type: ticket
status: ready-for-agent
kind: build
area: core
feature: core
priority: now
created: 2026-11-20
done:
blocked_by: []
notes: []
terms: []
---

# The picture and the theme

M0.5 batch 7 (Q2296), built ahead in its own worktree and parked ready (Q2317). The zoo gets the old game's picture at
a fixed noon (Q2299) and the old theme and crosshair (Q2300). What differs: `docs/migration/audit-core-looks-sound.md`
section 1 (lighting and post-processing) and its screen rows. Old code: `reference/it-socks/game/house/room.gd`
(environment, sky, sun), `game/house/day_cycle.gd` (noon values), `game/ui/ambient.gd` (vignette), the colour grade,
`data/tuning/graphics.json` (presets), `data/tuning/day.json`, the theme and `assets/fonts/`, the crosshair in `game/ui/`.

## Behaviour list
From the designer's answers (Q2299, Q2300, Q2322-Q2324).
- V01 The zoo is lit as the old game at noon: the old day HDRI sky, ambient light from it (0.7), reflections from it,
  the warm sun (1.0, 0.93, 0.82) at 2.4 with soft shadows (blur 1.5, 4 cascades, the old max distance).
- V02 The old post-processing: AgX tonemap at exposure 1.1, the old colour grade at noon, the vignette (0.5, tint (0.05,
  0.03, 0.06)), SSAO and glow as the old game set them.
- V03 Anti-aliasing MSAA 4x plus FXAA (at the high preset).
- V04 The old graphics presets low, medium and high, as a setting chosen by a project setting until the Options menu
  exists; high is the default (Q2323).
- V05 Every 2D screen text uses the old Patrick Hand theme, on one Theme; the zoo's 3D station signs keep a plain
  readable font (Q2324).
- V06 The crosshair is the old one: two crisp bars, 18 by 2 px (its colours and states as the old game had them).
- V07 Nothing else about play changes; the zoo's stations and Socks look as before apart from the light.

## Design
To be drafted by the agent here first (an Environment and sky resource for the zoo, the sun's settings, the presets as a
typed Resource and where they apply, the Theme file, the crosshair scene), then built. Look work: stop at the first
stills.

## Acceptance
- One test per behaviour line where a test can see it (settings applied, theme on every Control, the crosshair's size).
- Before and after stills of the same views (the handling station, the Cabinet, the every-Sock rows, a close-up of the
  crosshair and a message) in `builds/review-core-18/`, beside the old game's numbers; the ticket goes ready-for-human
  and the branch waits for batch 7.

## Answers
- Q2299, Q2300, Q2317, Q2322-Q2324 (2026-11-20).

## Open follow-ups

## Built log
- Model: Sonnet (lead): settings, resources and a Theme from a known reference.
