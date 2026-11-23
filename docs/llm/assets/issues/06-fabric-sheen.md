---
type: ticket
status: done
kind: build
area: assets
feature: assets
priority: now
created: 2026-11-21
done:
blocked_by: []
notes: []
terms: []
---

# Fabrics get a soft sheen

A look change (designer, Q2390, 2026-11-21): the old fabric materials (`fab_*`) carried glTF sheen
(KHR_materials_sheen), which Godot's StandardMaterial3D has no field for and the old game's import dropped, so they
were ported without it (assets/04). This ticket gives fabrics a soft sheen (StandardMaterial3D rim, or a small shader)
in the shared material library. Its own ticket by Q2153; shaped with stills after assets/04 merges.

## Acceptance
- Every `fab_*` material in the shared library gets rim and rim tint, set from the old glTF sheen colour and roughness where the old file has them (write the mapping in the Built log), else one shared default (a placeholder).
- Nothing else in the library changes; `kit/tools/asset_lint.py` passes.
- A strip in `builds/review-assets-06/`: the sofa, a bed and a curtain under the zoo's light, before and after.

## Answers
- Q2501 (2026-11-23): StandardMaterial3D rim and rim tint on every `fab_*` material of the shared library; no custom shader.
- Q2504 (2026-11-23): built to the end with no stop at the first still; a before and after strip for the designer's batch review before the merge.

## Open follow-ups
- [later] Strength is my placeholder: rim 0.35 (white, rim_tint 0.0) reads a little bright on the cream fabrics (sheeted
  sofa, bed linen). A softer number (0.2-0.25) is one edit per file. There is no curtain piece in the game yet, so the
  strip shows the bed and the sheeted sofa; the cloth strip of the Materials station is in the Built log's note.

## Built log

### 2026-11-23
- Changed: the 14 `game/materials/fab_*.tres` got `rim_enabled = true`, `rim = 0.35`, `rim_tint = 0.0`. Mapping: every
  old file (all 67 furniture .glb, checked) has the same KHR_materials_sheen: sheenColorFactor (1,1,1), sheenRoughnessFactor 0.5
  (the generator's `sheen=0.1`). White colour -> rim_tint 0.0 (a white rim); roughness 0.5 -> rim 0.35 (0.7 x 0.5, a
  placeholder scale: Godot's rim has no roughness). No other material changed; no code, no test (a look number, Q2421).
- Files: `game/materials/fab_*.tres`, `tools/shots/sets/fabric-sheen.txt`, `docs/architecture/materials.md`.
- Strip: `builds/review-assets-06/strip.png` (bed and sheeted sofa, before and after).
- Verified: suite PASS (agent_finish), asset_lint and grep_rules below.
