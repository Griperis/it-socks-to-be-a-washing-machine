---
type: ticket
status: done
kind: content
area: content
feature: coop
priority: now
created: 2026-11-22
done: 2026-11-22
blocked_by: []
notes: ["M0.6 batch 2 (Q2436); an asset piece (migration-port step 5); the avatar's rig first (Q2225)"]
terms: [Avatar]
---

# The avatar model, ported as is

The old avatar (`reference/it-socks/assets/avatar/avatar.glb` and `feet.glb`, made by
`tools/blender/make_avatar.py`, no .blend) ported by the asset rules: technical improvements only
(origin, scale, names, collision, shared materials, file size), a look the same as the old.
4 bones as the old: Root, Spine0, Spine1, Spine2 (Q2438).

## What it must provide
`docs/migration/m06-lists/02-teammates-seen.md` section "What the avatar model must provide": the
`Avatar` mesh with surfaces `player`, `trim`, `eye` and the `Crouch` shape key; `PupilL`, `PupilR`;
`FootL`, `FootR` pivoting at the ankle; the empties `HoldPoint`, `Head`, `HatPoint`; the skeleton with
the four bones, rest poses kept; the glTF extras (`crouch_drop`, `crouch_offset`, `bend_weights`,
`bend_crouch_offset`) as they are or as typed values beside the Looks; facing -z, origin at the feet,
1.7 m to the cuff rim.

## Acceptance
- `assets/avatar/avatar.glb` and `feet.glb` imported; a Looks scene `game/parts/avatar/looks_avatar.tscn`
  (behaviour plus a swappable Looks child, `zoo-design`) with a `looks_contract.json` naming the nodes above;
  it passes `kit/tools/asset_lint.py`.
- The capsule avatar's Looks is swapped for it in `avatar.tscn`, tinted by the player's colour on the
  `player` surface (white until coop/03's colour is merged; a placeholder colour export is fine).
- A before and after strip in `builds/review-avatar/` (old game's avatar beside the new import, the same
  views), for the designer's family approval (Q2216). No look change: anything that differs is listed.
- The coop/02 spike stand-in skeleton's bone names and rests match the import (note any difference in the
  Built log for the knockdown ticket).
- No test for the look itself (Q2421); the import and contract checks run.

## Answers
- Port as is, 4 bones (Q2438, 2026-11-22); the rig first in the asset port (Q2225).

## Open follow-ups

## Built log
- 2026-11-22 lead: model opus (Blender and import, CLAUDE.md "Models").
- 2026-11-22 agent (coop/04-avatar-model):
  - Changed: the old `make_avatar.py` ported unchanged but its header to `assets_src/generate/avatar/` and run
    through `build.py -- avatar` (Blender 5.3.0); its `avatar.glb` and `feet.glb` are MESH-SAME as the old game's
    (`glb_compare.py`: nodes, transforms, materials, skin, every vertex), so no technical change was needed:
    origin at the feet, scale 1, facing -z, 1.7 m to the cuff rim, no collision (the player's capsule is the
    body). 4 materials (`player`, `trim`, `eye`, `pupil`), not 5 as the inventory says; 3,600 triangles
    (Avatar 2,832, pupils 2 x 160, feet 2 x 224), not 4,048. The extras import as node metadata `extras`.
    `looks_avatar.tscn` (an `AvatarLooks` root, the glb as `Body`) replaces the capsule as the Avatar's `Looks`;
    its `colour` export (white, placeholder for coop/03's Roster colour) tints a copy of the `player` surface,
    as the old `avatar.gd` did. The old game also darkens the trim by the colour (0.35, behaviour 79): left to
    coop/05, which owns that line.
  - Spike rig (for the knockdown ticket): `tests/support/ragdoll_spike/` has the import's bone names, parents
    and rest origins (within 0.2 mm: import 0.450012 / 0.350074 / 0.320159 vs 0.45 / 0.35 / 0.32). The rests
    differ in rotation: the import's bones carry the lopsided lean, 0.58 / 1.04 / 0.87 / 1.17 deg (Root to
    Spine2) about y and z; the stand-in's are identity.
  - Files: `assets/avatar/` (glbs and imports), `assets_src/blender/avatar/avatar.blend`,
    `assets_src/generate/avatar/make_avatar.py`, `assets_src/generate/build.py` (family `avatar`),
    `assets_src/generate/README.md`, `game/parts/avatar/` (`avatar.tscn`, `avatar_looks.gd`, `looks_avatar.tscn`,
    `looks_contract.json`), `tests/avatar_test.gd` (model, colour, spike_rig, seen: real path, the Host walks
    forward and the Guest sees the sock creature there). Strip: `builds/review-avatar/avatar-before-after.png`
    (old beside new, 6 views incl. crouched; no differing pixel).
  - Verified: PASS 8339 checks, 212 cases (`run.sh --touched`); PASS asset_lint; PASS rules.
