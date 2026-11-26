---
type: ticket
status: done
kind: polish
area: content
feature: player
priority: now
created: 2026-11-26
done: 2026-11-26
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
- The strips were close; the gaps were closed: every colour of a two-colour mesh, tumble, lean, rocking and sway back,
  each mark varied as the old did, Lightning's blink and Tumbling socks' timing varied like the old's (Q2716).
- The final strips (`builds/review-trails/`, old above, port below) are approved (Q2717).

## Open follow-ups
- [later] Motion that particles cannot give (tumble, lean, rocking, pendulum sway, a hinge, two-colour meshes) is a MeshInstance3D keyed by the Layout's `Clip` AnimationPlayer (keys sampled from the old formulas, no code); the rest is one-shot GPUParticles3D. Sprinkles, Falling leaves, Stardust, Sprouting footprints, Floating digits and Tumbling socks are clip-only (no particle node). Each Trail scene holds three Layouts (group `variant`, each its own random placing and timing, as the old drew a new one per step): `TrailMark` keeps one at random (its `layout` export, -1), the others are freed.
- [later] Lightning's blink and Tumbling socks' phase: the old drew a new random one per mark (its rng is unseeded, seed 7 only in the demo), so there is no single pattern to match; the three Layouts vary them as the old did. Small old wobbles kept as approximations: Fizz bubbles' wobble.
- [later] Strips: `builds/review-trails/<id>.png` (old above, port below; the port shows the real assets/19 meshes, each moment held at the old shot's age). No collision is used: a landing is a second particle (a flight node, then a landed node at the landing point), so melt, fade and pop play after landing.
