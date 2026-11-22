---
type: ticket
status: done
kind: build
area: core
feature: core
priority: now
created: 2026-11-20
done: 2026-11-20
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
- V05 (Q2331 replaces Q2324) 2D screen text keeps Godot's default font as in the old game, on one Theme file (outline variations); Patrick Hand waits for the whiteboard. The zoo's 3D station signs keep a plain
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
- Q2331 (2026-11-20, replaces Q2324): the HUD and messages keep Godot's default font as in the old game; Patrick Hand waits for the whiteboard and the screens that used it. The Theme file stays (outline variations, no font). Noon ambient is the old 0.75 (the 0.7 in V01 was the lead's error).

## Open follow-ups
- [closed 2026-11-21] The HUD's Message and Size labels stay at the default 16 px (old: 28 pt, row at 70 percent height) and the Message is still red by modulate; position and size are the other audit rows, not this ticket. — Q2363 and Q2387: the HUD rows are at the old places and sizes, built in core/15
- [moved 2026-11-21] Not built (waits for menus): keycap buttons, keycap panels, sliders, fields, upgrade rows of `ui_bits.gd`; they need the KeycapStyle custom StyleBox (an inner class in the old code, against Q2253). — to docs/migration/m06-backlog.md

## Built log
- 2026-11-20: Changed: `game/look/` (day_sky shader, noon_environment.tres, graphics_preset.gd + low/medium/high .tres, picture.gd/.tscn with the vignette, crosshair.gd/.tscn, theme.tres); zoo.tscn WorldEnvironment and Sun; the player's HUD uses the Crosshair scene and OutlinedLabel on Message/Size, blocked red now (0.95, 0.25, 0.2); project.godot: MSAA 4x, FXAA, `gui/theme/custom`, `it_socks/graphics/preset`; assets (day HDRI, Patrick Hand, licences). After Q2331 the Theme sets no font; ambient 0.75; the Patrick Hand file stays in assets/ unused. Stills in builds/review-core-18/. Files: game/look/*, tests/look_test.gd, tools/shot_hooks.gd, tools/shots/sets/look-picture.txt. Verified: kit/tools/run.sh --touched PASS 6233 checks (before the font fix; look suite PASS 1104 after).
- Model: Sonnet (lead): settings, resources and a Theme from a known reference.
- Merged: 1d946051 (2026-11-20, branch core/18-picture-and-theme)
- 2026-11-21 (core/40): cases V01, V02, V05, V06 (crosshair bars) of `look` removed (Q2429).
