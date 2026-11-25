---
type: ticket
status: done
kind: build
area: assets
feature: assets
priority: now
created: 2026-11-24
done: 2026-11-25
blocked_by: []
notes: ["batch A (Q2606, Q2614); order: docs/migration/milestones.md Batch A", "suggested model: opus"]
terms: [Laundry bin]
---

# The Laundry bin model

The old hamper ported by the Blender skill as `tools/blender/laundry_bin.py` from the old
`make_laundry_bin.py`: white perforated plastic (0.44 x 0.52 x 0.34 m), the Sock-mesh heap with its blend shape
`empty`, built to core/90's Looks contract (`Contents`, the `tip` pivot). Design: `docs/architecture/run-ends.md` "Looks".

Batch A is built unattended (Q2603): an open choice this ticket does not settle takes the old game's answer (or the nearest) and goes under "Settled by the old game" in `docs/migration/batch-a-review.md` with this ticket's number (Q2604). Every old detail of the lines named below is built (Q2277); one left out goes to the lead before the merge, never `[later]` on its own.

## How it is authored

Built by its script (build() safe to re-run); the shared materials (Q2177).

## Acceptance
- Look work: a line-up (old and port, full and empty) in `builds/review-assets-13/`, `ready-for-human`.
- No real-path case (Q2421); core/90's contract holds on the model.

## Answers
- None beyond the design's (see the files named above).

## Open follow-ups
- [later] The designer's look at the line-up (batch A's end): `builds/review-assets-13/laundry-bin-old-vs-port.png` (Blender, EEVEE; rows top to bottom: old side, port side, old above, port above; columns full, half, empty) and `laundry-bin-in-game.png` (the zoo's Laundry station: full, empty, from above full and empty). The port's white is the library's (a touch creamier and less glossy than the old; batch-a-review.md "Settled by the old game").
- [later] `coop_knockdown:real_path` was FLAKY in this branch's run (failed, then passed alone; ledger in tests/flaky/ledger.md); this ticket touches no knockdown code.

## Built log

### 2026-11-25
- Changed: the old `make_laundry_bin.py` ported as `tools/blender/laundry_bin.py` (build() re-runnable, the needed bits of the old `washer_parts.py` inside it, exports the root's children so the glb's root is the Looks' `Tip` pivot, `--save` writes the source); the same meshes as the old glb (Body 844 tris, Shell 40, Contents 666 with the blend shape `empty`); no collider (the entity's box); the white mapped to `game/materials/white.tres`, the other four materials kept in the glb. `laundry_bin_looks.tscn` instances the glb as `Aim/Tip`, so `Aim/Tip/Contents` is the model's heap (core/90's contract; the graybox scale fallback stays for a Looks without the shape). A shot action `laundry_bin` and the set `laundry-bin`.
- Files: tools/blender/laundry_bin.py, assets/laundry_bin/ (glb, hole texture, imports), assets_src/blender/laundry/laundry_bin.blend, assets/blender_assets.json, game/entities/laundry_bin/laundry_bin_looks.tscn, game/entities/laundry_bin/laundry_bin.gd (doc line), tools/shot_hooks.gd, tools/shots/sets/laundry-bin.txt, assets_src/generate/README.md, docs/migration/batch-a-review.md.
- Verified: `PASS 20986 checks, 617 cases` (run.sh --touched, 68 suites; laundry_bin passes on the model); PASS rules; PASS asset_lint; the kit asset check: only the advisory snake_case names (`Body`, `Shell`, `Contents`, as the furniture, README "Known gaps").
- Merged: 41accb23 (2026-11-25, branch assets/13-laundry-bin-model)
