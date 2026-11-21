---
type: ticket
status: done
kind: build
area: core
feature: core
priority: now
created: 2026-11-20
done: 2026-11-21
blocked_by: ["[[09-hand-details]]"]
notes: []
terms: []
---

# The outline: one reusable component for everything you can use

The designer wants every interactable thing outlined as in the old game, through one generic component that works on
any mesh, with its colour, width and the rest set per use (2026-11-20; brings forward the soft outline of Q2280).
Today only a lying Sock or Pair has an outline: a hard 4 mm copy with a grown material, switched by the Looks'
`aimed` animation (core/02). The cupboard, the Cabinet's drawers and the Door have none.

The old code: `reference/it-socks/game/ui/highlight.gd` (265 lines), `game/ui/outline.gdshader`,
`game/ui/outline_mask.gdshader`; its users: `game/player/rig.gd` (the aim), `game/ui/pings.gd`,
`game/campaign/cabinet_xray_view.gd`, `game/campaign/sole_mates_view.gd`.

## How the old one works
- **Two passes in one material.** A mask pass writes the target's silhouette into the stencil buffer and draws
  nothing; then 3 shell passes draw the target grown along its normals, in the outline colour, only where the stencil
  is not set, so the outline lies outside the silhouette. Inner to outer: growth 0.003, 0.006, 0.0095 of the distance
  to the camera, opacity 0.9, 0.45, 0.2. That gives a soft edge that fades outwards.
- **Same width on screen at any distance.** Each shell's growth is multiplied by the distance to the camera in the
  vertex shader.
- **Any mesh.** It outlines every visible `MeshInstance3D` under the target, or the ones the target names
  (`highlight_meshes()`), minus anything in the group `no_highlight`. Each gets a child copy with the outline
  material. The copy's mesh has normals averaged across shared corners, cached per mesh, so a box's shells have no
  gaps. Copies keep the source's `skin`, so a skinned mesh's outline bends with its bones, and they follow its blend
  shapes.
- **Variants.** Warm white `(1.0, 0.94, 0.82)` for the aim. A red "full" tint on a drawer with no room for the held
  Pairs (Q221). Pings use the pinger's colour and are wider, and X-rays pulse (`pulse_hz`, `grow`, `bright`,
  `fade`) and fade out. Later features use these variants.
- **Who decides.** The aim says what is outlined; the outline only draws it. It never says right or wrong, except the
  "full" tint.

## Behaviour list
Approved (Q2292). The numbers are the old game's.
- O01 When the crosshair rests on something you can use within reach, then it gets a soft warm-white outline, drawn
  outside its shape. It is three shells fading outward and keeps the same width on screen near and far.
- O02 When the crosshair leaves it, or it goes out of reach, then the outline goes at once.
- O03 Things you can use today: a lying Sock, a lying Pair, a cupboard's door, a Cabinet's drawers, the Door. A new
  interactable gets the outline by adding the component, with no code change in the player.
- O04 The outline is the same for every target and never says right or wrong. The one exception: an aimed drawer
  with no room for the held Pairs has the red "full" tint (Q221).
- O05 A skinned or bending mesh keeps its outline on its moving shape: a cloth Sock (core/09) and a sliding drawer.
- O06 A box or any hard-edged mesh is outlined without gaps at its corners.
- O07 A part that should not be outlined (a drawer's shelved balls, say) is left out by a group, and a thing may name
  exactly which of its meshes are outlined.
- O08 A woken Sock sliding or flying under the crosshair (pickable since Q2339) is outlined like a lying one
  (Q2341).

## Design (draft)
- **`Outline`** (`game/outline/outline.gd`, `class_name Outline extends Node3D`, one class) is a component dropped
  as a child of any entity or Looks. It has three exports:
  - `style: OutlineStyle`;
  - `meshes: Array[NodePath]`, where empty means every visible mesh under its parent;
  - `shown: bool`.
  It builds its copies only when first shown, so 10,000 lying Socks cost nothing. Static `Outline.of(collider)` gives
  the nearest `Outline` at or above a collider, so the player's aim finds it without knowing the thing. That replaces
  the Sock-only path in `player.gd:_outline()`.
- **`OutlineStyle`** (`game/outline/outline_style.gd`, a typed Resource edited in the inspector) holds the colour,
  the width (a factor of the shells), the shells (growth and opacity each), the pulse (hz, grow, bright, fade) and
  the render priority. Styles: `aim.tres` (warm white), `full.tres` (red; the shade is a placeholder, as it was in the
  old game). Pings and X-rays add their own `.tres` later.
- **Shaders:** `outline_mask.gdshader` and `outline.gdshader`, ported as they are. Godot 4.7 has `stencil_mode`.
- **The Sock** drops its hard `Outline` copy and its grown material. Its Looks gets an `Outline` component, and the
  `aimed` state shows it. The contract keeps the name `Outline`.
- **The cupboard, the Cabinet's drawers and the Door** each get an `Outline`. The Cabinet sets `full.tres` on an
  aimed drawer with no room.
- **A zoo station**, `outline.tscn`: a Sock, a Pair, a box, a cupboard and a skinned Sock at near and far
  distances, to see the outline as one feature.
- **Tests:** one per line; the real path is the player aiming at each interactable in the zoo. The first still stops
  for the designer's go: the outline near and far on a Sock, a drawer and the Door, beside the old game's.
- Model: Opus (shaders, the stencil, skinned copies).

## Acceptance
- One test per behaviour line; the real-path case through the player's aim in the outline station.
- A line-up still in `builds/review-core-11/`, stopped at the first still for the designer's go.

## Answers
- The behaviour list and design are approved (Q2292, 2026-11-20).
- Built in the polish pass, not in M0.5 (Q2293, 2026-11-20); it starts when the designer calls the polish pass.
- O08, a moving Sock under the crosshair is outlined, added (Q2341, 2026-11-20).
- The first still: make it stronger for now. The old shape stays (warm white, three shells fading outward, one
  width near and far), the inner shells a little wider and more opaque so it reads on the bright graybox; the
  numbers in `aim.tres` are placeholders, "stronger for the graybox, recheck on the M1 models" (Q2374, 2026-11-21).

## Open follow-ups
- [later] The baseline has no old still of an aimed Sock or Door, only drawers (`cab-simple`, `c-cupboard`).
  Old-game stills of those two need the old game's capture tour with new views (not done: it runs in the
  reference clone).
- [later] O08: a moving Sock is outlined only while its flight has a Looks (the `flying_cap` nearest the camera,
  core/09); a flight drawn by the flying MultiMesh has nothing to outline. Lending an aimed flight a Looks is
  `game/mess/` (`mess.gd` `give_looks`, `mess_moving.gd`), which core/23 holds now.
- [later] The outline station has no lying Pair: a SockSpot cannot place one (the O03 case pairs and drops one).
- [later] `full.tres` keeps the old game's shells (only the aim style was made stronger, Q2374): the red tint on a
  full drawer is a little narrower than the warm white. Same shells for both?

## Built log
### 2026-11-21
- Changed: one `Outline` component (`game/outline/outline.gd`) with an `OutlineStyle` Resource (`aim.tres` warm
  white, `full.tres` red, placeholder shade) and the old stencil mask and shell shaders, ported as they were.
  Copies are made on first show, keep skin and blend shapes, normals averaged. `Outline.of(collider)` lets the
  player's aim show the outline of any thing that has one (O03); an aimed drawer above the Rows or full, with a
  Pair held, takes the red tint (`Cabinet.has_room`). The Sock and Pair Looks lose their hard grown copy for the
  component (`aimed` sets `Outline:shown`). The drawer (its front only), the Door and both cupboard Looks have
  one. A zoo station `outline.tscn`; the shot set `outline`. Stopped at the first still (look work).
- Files: game/outline/, game/player/player.gd, game/sock/looks_*.tscn, game/entities/{drawer,door,cupboard}/,
  game/entities/cabinet/cabinet.gd, game/zoo/stations/outline.tscn, tools/shot_hooks.gd, tools/shots/sets/outline.txt
- Verified: `kit/tools/run.sh --touched`: PASS 7217 checks, 208 cases; stills in `builds/review-core-11/`.
### 2026-11-21 (Q2374)
- Changed: the aim style's shells are stronger for the graybox (0.005/0.009/0.013 at 1.0/0.75/0.35, placeholders
  marked Q2374); `tests/outline_test.gd`: one case per O line and the real path (the player's aim in the outline
  station shows a lying Sock's, a drawer's and the Door's outline in turn).
- Files: game/outline/aim.tres, tests/outline_test.gd, this ticket
- Verified: `kit/tools/run.sh --touched` (verdict in the commit report); `--only=outline` PASS 48 checks, 9 cases,
  also `--reverse`; before/after `builds/review-core-11/outline-stronger-before-after.png`.
