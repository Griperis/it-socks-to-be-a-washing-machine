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

## Open follow-ups

## Built log
