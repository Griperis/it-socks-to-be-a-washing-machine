---
type: ticket
status: ready-for-human
kind: bug
area: core
feature: outline
priority: now
created: 2026-11-25
done:
blocked_by: []
notes: ["suggested model: sonnet", "designer 2026-11-25, Windows build: 'outline is barely visible in some lighting conditions - why?'", "parked by the designer 2026-11-25: the branch waits, not merged"]
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
- [blocking] Designer's call: which fix? (A) a dark outline colour; (B) two-tone, warm-white inner shell and dark outer shells (needs a colour per shell in OutlineStyle); or keep warm white and make it opaque and wider. Stills: `builds/review-core-119/compare-drawer.png`, `compare-door.png`, `compare-sock.png` (now | A | B).

## Built log

### 2026-11-25
Changed: nothing in the game. Found why: the port is faithful (outline.gdshader, shells 0.003/0.006/0.0095 with opacity 0.9/0.45/0.2, colour (1,0.94,0.82), AgX 1.1 and the grade all equal the old game's). The outline is warm white and thin (a few px, outer two shells mostly transparent), and the furniture (drawers, cupboard, door) is cream/white: warm white on cream has almost no contrast, so it shows only against sky, floor and shadow. It is a design weakness of the original, not a port difference. Pulse is off for the aim outline, fog is not used, so neither is a cause (not separately shot: sunlit-vs-dark rooms are not in the zoo).
Files: none in the repo (stills only: before-*, optA-dark-*, optB-twotone-*, compare-* in builds/review-core-119/).
Verified: stills only, no code change; the temporary style edit for option shots was reverted.
