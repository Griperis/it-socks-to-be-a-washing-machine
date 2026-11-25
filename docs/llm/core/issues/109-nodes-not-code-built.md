---
type: ticket
status: done
kind: refactor
area: core
feature: ui
priority: now
created: 2026-11-25
done: 2026-11-25
blocked_by: []
notes: ["suggested model: sonnet", "designer 2026-11-25: particles and fixed nodes are scene nodes, not built in code"]
terms: []
---

# Particles and fixed nodes as scene nodes, not built in code

Two places build things in code that are fixed in number and look, so they belong in scenes, where the designer
can tune them in the inspector.

- `game/ui/final_screen/final_column.gd` `_spark()`: builds a `CPUParticles3D`, its `QuadMesh`, a
  `StandardMaterial3D` and a fade `Gradient` per sparkle or burst. Make it one small scene, for example
  `game/ui/final_screen/final_spark.tscn`, with the particles and the material set in the inspector at today's values.
  Code instances it, sets what really varies per burst (position, count, size, spread, tint), emits it, and frees
  it when done. Use `GPUParticles3D` only if it looks the same; otherwise keep CPU.
- `game/lobby/lobby_stage.gd` `_ready()`: builds the pedestals (`MeshInstance3D`, `CylinderMesh`, materials) for a
  fixed `PLACES`. Make them nodes in the Lobby stage scene, sized from the same numbers. Code keeps only what
  changes at play: the colour per place and the silhouette.

Left in code on purpose (the ticket does not touch them): the Sock MultiMeshes (counts come from data), the sound
and voice player pools, the Whiteboard's viewport-texture material, the outline copies, and the mirror's quad.

## Acceptance
- No `CPUParticles3D.new()`, `QuadMesh.new()`, `CylinderMesh.new()` or `Gradient.new()` left in the two scripts.
- Same look: a before/after still of the Final screen's sparkle and burst and of the Lobby row, in
  `builds/review-core-109/`. No look number changes.
- The final screen and lobby suites and the full suite pass, nothing flaky.

## Open follow-ups

## Built log

- 2026-11-25: Changed: the spark is `final_spark.tscn` (CPUParticles3D, unit quad, unshaded billboard material, fade
  Gradient, today's values); `_spark()` instances it and sets amount, scale_amount (size), lifetime, velocity, tint.
  The four Lobby pedestals are `Pedestal0..3` nodes in `lobby_stage.tscn` (cylinder 0.75 x 0.3, own material each);
  code keeps the colour per place and the silhouette. The pedestal size is now the scene's, no longer read from
  `LobbyTuning.pedestal_radius/height` (those two now only feed `box_of`). Files: game/ui/final_screen/final_column.gd,
  final_spark.tscn, game/lobby/lobby_stage.gd, lobby_stage.tscn, docs/migration/batch-a-review.md. Stills before/after in
  builds/review-core-109/ (lobby-look and final-screen sets: 0 differing pixels on four, focus and popping).
  Verified: PASS 22772 checks, 712 cases.
- Merged: 6c27943d (2026-11-25, branch core/109-nodes-not-code-built)
