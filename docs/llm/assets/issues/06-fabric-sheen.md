---
type: ticket
status: ready-for-agent
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

## Built log
