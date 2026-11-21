---
type: ticket
status: needs-triage
kind: build
area: assets
feature: assets
priority: later
created: 2026-11-21
done:
blocked_by: ["[[01-sock-models-and-prints]]"]
notes: []
terms: []
---

# Socks look like wool

A look change after the old look is ported (designer, Q2379, 2026-11-21): "Ideally the socks should get a wool textures
and normal mapping, so it doesn't look as flat, the shader didn't sell it that much, but that's followup." Its own
ticket by Q2153; shaped and asked when assets/01 has merged.

## Behaviour list (draft)
- W01 A Sock reads as knitted wool up close: a knit texture and normal map on every shape, the Design's colours,
  pattern and print still on top; it holds up in the lying tier's MultiMesh and at a distance (LOD, no shimmer).

## Open follow-ups
- [blocking] How the knit is made (a tiling knit normal and roughness, a detail map per shape, or the shader), its
  scale and strength, and the cost in the lying tier: asked with stills when the ticket is shaped.

## Answers
- Tracked as a follow-up after the old look is ported (Q2379, 2026-11-21).

## Built log
