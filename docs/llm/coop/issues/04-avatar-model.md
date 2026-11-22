---
type: ticket
status: ready-for-agent
kind: content
area: content
feature: coop
priority: now
created: 2026-11-22
done:
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
