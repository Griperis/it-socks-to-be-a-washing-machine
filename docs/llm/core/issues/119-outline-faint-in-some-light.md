---
type: ticket
status: ready-for-agent
kind: bug
area: core
feature: outline
priority: now
created: 2026-11-25
done:
blocked_by: []
notes: ["suggested model: sonnet", "designer 2026-11-25, Windows build: 'outline is barely visible in some lighting conditions - why?'"]
terms: []
---

# The outline is barely visible in some light: find why, then fix it

The designer asks why the aim outline (`game/outline/`: a mask pass and shells, `outline.gdshader`, unshaded,
`blend_mix`, a soft warm-white `colour` with a pulse, styles `aim.tres` and `full.tres`) is barely visible in
some lighting.

## What to do
1. Reproduce: stills of the outline on a Sock, a drawer and the Door. Take them in the sunlit room, a dark room, a
   room with the lamps on, against a light wall and a dark floor, and at the pulse's trough.
2. Answer "why" plainly, with the evidence. Candidates:
   - the warm-white colour on light surfaces (no contrast);
   - the tonemapper and exposure, which also apply to unshaded output in Forward+, or glow and auto exposure
     squashing it;
   - the pulse's trough (`pulse_fade`) too faint;
   - fog;
   - the shell width in pixels at a distance;
   - a differing number from the old game (`reference/it-socks/game/ui/outline.gdshader` and its settings).
3. Propose the fix, and build the plain one when it's a port difference (a number or a render setting the old game
   had). A new look (a dark rim, a two-tone outline, a colour change) is the designer's call: give stills of up to
   two options and stop.

## Acceptance
- The "why" is in the report, with the stills, in `builds/review-core-119/`.
- Either the port difference fixed, with before and after stills, or options shown for the designer.
  `ready-for-human` either way. The outline suite passes.

## Open follow-ups

## Built log
