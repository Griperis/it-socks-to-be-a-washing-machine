---
type: ticket
status: done
kind: bug
area: core
feature: final-screen
priority: now
created: 2026-11-25
done: 2026-11-25
blocked_by: []
notes: ["suggested model: sonnet", "designer 2026-11-25: the patches covering the Socks on the Final screen look weird"]
terms: [Final screen]
---

# The Final screen's sparkles are the old soft specks, not square patches

The designer, looking at `builds/review-final-screen/`: "What's the patches in the final screen that cover the socks,
that looks weird." The patches are the sparkle and finale bursts (`game/ui/final_screen/final_spark.tscn`,
`final_column.gd` `_spark`/`burst`). core/95 ported the old `PairedMoment.burst`
(`reference/it-socks/game/.../paired_moment.gd:163-203`, `_speck()` :265-287) without most of it:

| Old burst | Port today |
|---|---|
| a soft round speck: radial `GradientTexture2D` (32 px), **additive** blend, unshaded, cull off, vertex colour as sRGB | a plain square quad, alpha blend: the squares |
| each speck **shrinks to nothing** over its life (`scale_amount_curve` 1 → 0), scale 0.6-1.2 | no shrink, one size |
| `damping` speed × 1.2-2.0, `gravity` down speed × 0.6: they stop and settle near the spot | no damping, no gravity: they drift far over the Socks |
| emitted from a sphere of radius `size`; the quad is `size` across | from a point; the quad is `size × 2` |
| colour mixed per speck from the tint toward white by `white` (0.5 here) | one colour |

The port already has this speck done right in `game/hands/mate_sparkle.tscn` (the material and the process numbers),
`pair_moment.tscn` and `machine_part.tscn`: reuse that look (share the material, or one speck-burst scene the three
use) rather than a fourth copy.

Also check every other place the old game called `PairedMoment.burst` and whether the port has it, and as the old:
`ending_screen.gd:556,611`, `part_view.gd:76,129,170`, `gift_view.gd` (batch B), `held_view.gd:507,653`,
`laundry_view.gd:69` (a Dirty Sock binned puffs in the bin's mouth), `splitter_view.gd:174`, `hamper_view.gd:217`.
List each as ported / ported differently / missing. Fix only the Final screen's here; anything missing or different
goes to the designer as a follow-up (small details are never dropped without them).

## Acceptance
- The Final screen's sparkle (a Pair popping, a rare Pair) and the finale's three bursts look like the old ones: soft
  round specks that shrink, slow and settle, at the old sizes and counts, in the player's colour mixed toward gold and white.
- Visuals authored in nodes (Q2658): the look is in a scene and its material; code only places, tints and emits.
- Look work stops at its first still: old beside port of the 2-player and 4-player popping screens and a strip of one
  burst, in `builds/review-core-112/`; `ready-for-human`.
- The final screen suite passes.

## Open follow-ups


- [later] Audit of the other `PairedMoment.burst` callers (a grep of the port for particle scenes, not a line-by-line check):
  held_view.gd:507 (mate sparkle) and :653 (pair burst): ported (`mate_sparkle.tscn`, `pair_moment.tscn`);
  part_view.gd:76,129,170: ported differently or unverified (`machine_part.tscn` has its own particles);
  gift_view.gd:92,211,334: missing (batch B, no gift view in the port);
  laundry_view.gd:69 (bin mouth puff), splitter_view.gd:174, hamper_view.gd:217: not found in the port, treat as missing.
  Each goes to the designer. `mate_sparkle.tscn`, `pair_moment.tscn` and `machine_part.tscn` still hold their own copies
  of the speck material; `game/hands/speck_material.tres` (new) is the shared one the Final screen uses; switching the
  three over is a small follow-up.
- [later] Old-beside-port stills: the old game cannot be run here, so the stills show the port only; the old numbers are
  matched from the code (`paired_moment.gd:163-203`).
- Changed without being asked: `final_screen_tuning` `confetti` 70 to 40 (the old burst's literal count in ending_screen.gd:611).
  Kept the port's 0.2 m lift of a burst above the Socks.

## Built log

### 2026-11-25
Changed: `final_spark.tscn` is now a soft round speck (shared `speck_material.tres`: radial texture, additive, billboard,
sRGB vertex colour), shrink curve, fade, spheres of emission, gravity; `_spark` sets size, speeds, damping, gravity and the
tint-to-white mix (0.5). Shot hook `final` takes `,burst`; shot set `final-sparkles`.
Files: game/ui/final_screen/final_spark.tscn, final_column.gd, final_screen_tuning.gd, game/hands/speck_material.tres,
tools/shot_hooks.gd, tools/shots/sets/final-sparkles.txt.
Verified: PASS 22906 checks, 719 cases (--touched). Stills in `builds/review-core-112/`; waits for the designer's go.
- Merged: f6b85dfe (2026-11-25, branch core/112-final-screen-sparkles)
