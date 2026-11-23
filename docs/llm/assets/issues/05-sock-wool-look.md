---
type: ticket
status: done
kind: build
area: assets
feature: assets
priority: now
created: 2026-11-21
done: 2026-11-23
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
- [later] The knit's numbers are placeholders for the designer's eye on the strip (`game/sock/sock_knit.tres`):
  stitch size per cloth (cotton 4.5 x 4 mm, wool 9 x 8 mm, fuzzy 7 x 6 mm), strength (cotton 0.6, wool 1.0,
  fuzzy 0.35), cavity 0.5, fade 3 to 8 m. The wool on the close heap reads strong.
- [later] The tile's stitch: a V pointing toward the toe (reads upright with the cuff up), 8 x 8 stitches in
  256 px, round yarn with a three-turn ply twist (`assets_src/generate/sock/make_knit.py`). The designer's call.
- [later] The texture replaces the shader's procedural wool stitch (wool keeps its heathered yarn); the fuzzy
  pile now shows faint stitches under its nap, and the ribbed cuffs carry the knit under their ribs.
- [later] Frame cost on a real GPU: this machine renders in software, so the bench counts draws and CPU only;
  the designer's PC run (`tools/mess_bench.cmd --only=idle_2000,idle_10000`) gives the GPU number.
- [later] `tools/shot_hooks.gd` is 726 lines, over the 600 note of grep_rules: split it when next touched.

## Answers
- Q2500 (2026-11-23): one tiling knit normal and roughness texture over every Sock shape in the Sock shader, under the Design's colours, pattern and print, faded with distance.
- Q2504 (2026-11-23): built to the end with no stop at the first still; a before and after strip for the designer's batch review before the merge.
- Tracked as a follow-up after the old look is ported (Q2379, 2026-11-21).

## Built log

### 2026-11-23
- Changed: one seamless knit tile (normal, roughness, cavity; 256 px, 8 x 8 stitches) made in Blender by a new
  script, tiled by the sock shader over every Sock shape and tier (held, ball, flying cloth, the lying
  MultiMesh) under the Design's colours, pattern and print, a whole number of tiles round the tube, flattened by
  its mipmaps and faded out between two distances; it replaces the procedural wool stitch. The numbers are a
  typed Resource, SockKnit, handed to every sock material by SockLook. A shot set `sock-wool` and two shot
  actions (`held_zoom`, `heap_view`).
- Bench (`tools/mess_bench.sh --window`, software renderer, CPU only): idle_2000 before draws 374, frame 0.012 ms,
  tick p95 2.21 ms; after draws 374, frame 0.012 ms, tick p95 0.83 ms. idle_10000 before draws 1169, frame 0.011
  ms, tick p95 3.03 ms; after draws 1169, frame 0.011 ms, tick p95 1.34 ms. No draw or CPU step: the knit adds one
  texture fetch per pixel and no draw (the tick differences are this machine's noise). GPU time: the designer's PC.
- Strip: `builds/review-assets-05/sock-wool-before-after.png` (held, heap close, heap at 5 m), and
  `sock-wool-held-closeup.png`.
- Files: assets_src/generate/sock/make_knit.py, assets_src/generate/README.md, assets/sock/knit.png(.import),
  game/sock/sock_knit.gd(.uid), game/sock/sock_knit.tres, game/sock/sock_look.gd, game/sock/sock_pattern.gdshader,
  tests/sock_looks_test.gd (w01, w01_real_path), tools/shot_hooks.gd, tools/shots/sets/sock-wool.txt
- Verified: PASS 16302 checks, 411 cases
- Merged: 96840ee7 (2026-11-23, branch assets/05-sock-wool-look)
