---
type: ticket
status: done
kind: change
area: core
feature: controls
priority: now
created: 2026-11-25
done: 2026-11-25
blocked_by: []
notes: ["suggested model: sonnet", "designer 2026-11-25 (Q2663): Q zooms to the Sock, G freed; R stays turn"]
terms: []
---

# Q zooms to the held Sock; G is freed

The designer (Q2663): Zoom moves from G to Q. R stays Turn, and G is left unbound. The old game had zoom on G
(`reference/it-socks/game/core/controls.gd:26`); this is a change on purpose.

## Acceptance
- `project.godot` input `zoom`: Q (physical) and the pad binding as before. G is bound to nothing. Committed with
  `--allow-project`.
- Every hint that shows the zoom key shows Q: the HUD corner prompts, the held-Sock hints, the controls page and
  key remapping in Options. These read the InputMap, so check that none has G written in.
- Nothing else is on Q (check every action and the debug keys); say what you checked.
- Real-path case: holding a Sock, a Q press zooms it and a G press does nothing. The hands and settings suites pass.

## Open follow-ups

## Built log

- 2026-11-25. Changed: `zoom` in project.godot is Q (physical 81, was G 71); it had no pad binding, so none added. Hints, controls page and Options read the InputMap, so no code changed; hand-written G text fixed in the handling zoo station, aim_screen_test and ui_icons_test. Checked: Q (81) was on no other action in project.godot and in no key code in game/ or tools/ (profily F3 only). throw_test T04 used Q as an unbound key; now Y. New real-path case h21_keys in handling_test: a Q key event zooms a held Sock, a G event does not. Files: project.godot, tests/handling_test.gd, tests/throw_test.gd, tests/aim_screen_test.gd, tests/ui_icons_test.gd, game/zoo/stations/handling.tscn. Verified: see the commit suite line.
- Merged: ff2d09fa (2026-11-25, branch core/116-q-zooms)
