---
type: ticket
status: needs-triage
kind: build
area: assets
feature: assets
priority: later
created: 2026-11-21
done:
blocked_by: ["[[04-furniture-and-materials]]"]
notes: []
terms: []
---

# Fabrics get a soft sheen

A look change (designer, Q2390, 2026-11-21): the old fabric materials (`fab_*`) carried glTF sheen
(KHR_materials_sheen), which Godot's StandardMaterial3D has no field for and the old game's import dropped, so they
were ported without it (assets/04). This ticket gives fabrics a soft sheen (StandardMaterial3D rim, or a small shader)
in the shared material library. Its own ticket by Q2153; shaped with stills after assets/04 merges.

## Open follow-ups
- [blocking] How it is made (StandardMaterial3D rim and rim tint, or a shader), its strength, and which materials get it:
  asked with a before/after still when shaped.

## Built log
