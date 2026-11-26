---
type: ticket
status: ready-for-human
kind: polish
area: content
feature: player
priority: now
created: 2026-11-26
done:
blocked_by: ["[[128-wardrobe-pieces-and-dressed-avatar]]"]
notes: ["batch B (Q2614); order: docs/migration/milestones.md Batch B, wave 3", "suggested model: sonnet", "look work: stops at its first strip"]
terms: [Trail, Wardrobe]
suites: [avatar]
---

# The Trails as particle scenes

The 17 Trails remade as particle scenes authored in the editor, not ported scripts (Q2680). Build
`docs/architecture/wardrobe.md` "Trails: particle scenes authored in the editor" for every Trail: Lint puffs (its first
pass from core/128, taken up again), Turf prints, Sprinkles, Bubblegum pops, Paw prints, Lightning sparks, Snowflakes,
Stardust, Juice drops, Falling leaves, Sprouting footprints, Fizz bubbles, Floating digits, Falling pixels, Tyre tracks,
Oil drips, Tumbling socks (held back with the Lost Socks, made all the same).

- Each `game/wardrobe/trails/<id>.tscn`: the `TrailMark` root with the old `life` and `max`, `GPUParticles3D` nodes
  (one shot, local coordinates, no shadow) whose process materials give the old motion, sub-emitters and an autoplay
  `mark` clip only where particles cannot stage it; the draw meshes from the old glb (assets/19) where it has merged,
  else stand-in meshes named alike so the swap is a mesh reference.
- Each Trail's piece file points its `looks` at its scene.
- No per-Trail script: a scene that needs code to move is a question for the lead, not a script.

Behaviour lines (`docs/migration/m4-lists/08-wardrobe-profile-achievements.md`): "Trails", each Trail's own line (its
shape, motion and numbers are the brief; the looks may shift, Q2680).

Batch B is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the
nearest) and goes under "Settled by the old game" in `docs/migration/batch-b-review.md` with this ticket's number
(Q2604). Every old detail of the behaviour lines named above is in the scene (Q2277); one left out goes to the lead
before the merge, never `[later]` on its own.

## How it is authored
In the editor only (Q2658, Q2680): particle nodes, their process materials and curves, and clips; numbers on the nodes
and `TrailMark` (`# placeholder:` the old `wardrobe.json` trail numbers).

## Acceptance
- Look work: stops at its first strip (`review-material`): every Trail's marks at three moments of their life (just
  laid, mid-life, fading) beside the old game's shot of the same Trail, in
  `builds/review-trails/`; then `ready-for-human`. Nothing past it until the designer's go.
- One data case: every Trail piece's scene instances with a `TrailMark` root and its marks are gone after `life`.
- No real-path case beyond core/128's (a look ticket, Q2421).
- Placeholders: every Trail's `life`, `max` and particle numbers.

## Answers
- The 17 Trails are remade as particle scenes authored in the editor, not ported scripts; the look is judged on stills
  (Q2680, 2026-11-25).

## Open follow-ups
- [later] First strip: `builds/review-trails/<id>.png` (old above, port below, three moments each). Stand-in meshes (assets/19 not merged), sizes eyeballed against the old shots; they shift with the glb meshes.
- [later] Particles that must land use `GPUParticlesCollisionBox3D` with world coordinates (`local_coords` off: Godot froze them with it on) and start off the floor; a collided particle stops its colour ramp and scale curve, so Snowflakes' melt does not play after landing. Needs the designer's eye, a sub-emitter, or a mesh swap.
- [later] Old staged motions only roughly matched, listed for Q2277: Tyre tracks' strip and dust by clip, Turf prints' tufts rising together not one after another, Falling leaves' pendulum sway (turbulence stands in), Lightning sparks' zigzag flip (a baked blink ramp).
- [later] "Settled by the old game" lines for `docs/migration/batch-b-review.md` (this ticket) are not written (outside the owned files): every Trail's `life` and `max_marks` are wardrobe.json's; `trails/graybox.tscn` is removed, no piece uses it.
