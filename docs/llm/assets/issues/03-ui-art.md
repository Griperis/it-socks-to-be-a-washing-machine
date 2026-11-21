---
type: ticket
status: done
kind: build
area: assets
feature: assets
priority: now
created: 2026-11-21
done: 2026-11-21
blocked_by: []
notes: []
terms: []
---

# The UI art and keycaps

M1 (Q2378); the keycaps are needed by core/15's prompts (Q2362). Old: `assets/ui/` (107 svg: 34 upgrade, 20 pad, 14
key, 7 menu, 5 emoji, Collection and Sock icons, ...), made by `tools/gen_icons.py` (one style, 64x64), and how the
old HUD drew a key (`UiBits.icon`, 1.5x the font).

## Behaviour list
- U01 Every old icon is in the game as an imported svg with the old names, in `assets/ui/` (or the folder the theme
  uses), crisp at the sizes the old HUD used.
- U02 The keycaps: one icon per key the prompts name (LMB, RMB, wheel, E, R, G, Space, Ctrl, ...) and per pad button,
  read by a small lookup the prompts use (core/15 builds the prompts on it).
- U03 A zoo station or a screen shows all icons with their names, built from the folder at load (Q2337).

## Port rules (for every asset ticket)
- Ported by examination, technical improvements only (origins, scale, names, collision, shared materials, file size);
  a look change is its own ticket (Q2153). Blender scripts stay and build meshes only (`.glb`); placement, collision,
  spots and settings live in Godot scenes edited by hand (Q2151, Q2152). Each Looks passes `kit/tools/asset_lint.py`
  and its folder's `looks_contract.json`.
- Approved as a family: a before/after strip in `builds/review-<family>/`, old game beside new, stopped at the first
  still for the designer's go (Q2216). The old files: `reference/it-socks/` (see `docs/migration/assets-inventory.md`).

## Acceptance
- One test per behaviour line (the Looks contract, the station built from data, the real path where the player sees
  it); the strip in `builds/review-<family>/`, stopped at the first still for the designer's go.

## Answers
- Started beside M0.5 (Q2378, 2026-11-21).
- Q2385 (2026-11-21): the icons are approved (designer's go after the first still).

## Open follow-ups
- [later] Icons are imported at the old svg scale 1.0 (64 px; cursor 36). If the Upgrade menu draws them larger than 64 px
  they blur; a higher `svg/scale` is a technical choice for the designer's go.
- [later] The old `Icons.texture` swapped a key for the pad glyph while the pad was the last input (`Controls.pad_icon`).
  `UiIcons.keys_for_action(action, pad)` gives the glyph per action; the keyboard/pad switch belongs to core/15.

## Built log

- 2026-11-21 (stopped at the first still, designer's go awaited). Changed: the 111 old svgs copied byte-identical into
  `assets/ui/` (checked with cmp against v0.1.1); `UiIcons` (texture, aliases, all_keys from the folder, keys_for_action
  for keyboard and pad); `IconsStation` built from the folder; `tools/icons_still.tscn` and a `icons` action in
  shot_hooks. Files: assets/ui/*.svg, game/ui/ui_icons.gd, game/zoo/icons_station.gd, game/zoo/stations/icons.tscn,
  tests/ui_icons_test.gd, tools/icons_still.tscn, tools/shot_hooks.gd. Still: builds/review-ui-art/icons-all.png (new left, old right
  of each pair). Verified: PASS 4628 checks, 46 cases (--touched).

- 2026-11-21 (after Q2385). Changed: the station moved to `game/zoo/stations/icons.tscn` with a Pad and the wall raised,
  instanced in zoo.tscn as Icons at (-18, 0, -8); the editor import wrote the .uid and .import files. Files: game/zoo/stations/icons.tscn,
  game/zoo/zoo.tscn, tests/ui_icons_test.gd, tools/icons_still.tscn, the .uid and assets/ui/*.import files. Verified: see the commit's suite line.
- Merged: 0148a8d6 (2026-11-21, branch assets/03-ui-art)
