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

# Socks look like wool

A look change after the old look is ported (designer, Q2379, 2026-11-21): "Ideally the socks should get a wool textures
and normal mapping, so it doesn't look as flat, the shader didn't sell it that much, but that's followup." Its own
ticket by Q2153; shaped and asked when assets/01 has merged.

## Behaviour list (draft)
- W01 A Sock reads as knitted wool up close: a knit texture and normal map on every shape, the Design's colours,
  pattern and print still on top; it holds up in the lying tier's MultiMesh and at a distance (LOD, no shimmer).

## Acceptance
- One seamless knit normal and roughness texture (made in Blender or by a kit tool, its source in `assets_src/`), tiled in the Sock shader on every Sock shape and tier (held, flying cloth, the lying MultiMesh), under the Design's colours, pattern and print.
- Its scale, strength and fade distance are typed numbers (placeholders for the designer's eye); no shimmer at a distance (mipmaps, fade).
- The Mess bench at 2,000 and 10,000 Socks is measured before and after in the Built log; the lying tier costs no more than a small step (write the numbers).
- A strip in `builds/review-assets-05/`: a held Sock, a lying heap up close and at 5 m, before and after.

## Open follow-ups

## Answers
- Q2500 (2026-11-23): one tiling knit normal and roughness texture over every Sock shape in the Sock shader, under the Design's colours, pattern and print, faded with distance.
- Q2504 (2026-11-23): built to the end with no stop at the first still; a before and after strip for the designer's batch review before the merge.
- Tracked as a follow-up after the old look is ported (Q2379, 2026-11-21).

## Built log
