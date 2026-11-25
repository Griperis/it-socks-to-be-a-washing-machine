---
type: ticket
status: ready-for-agent
kind: change
area: core
feature: controls
priority: now
created: 2026-11-25
done:
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
