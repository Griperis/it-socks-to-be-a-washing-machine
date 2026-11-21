---
type: ticket
status: needs-triage
kind: build
area: assets
feature: assets
priority: now
created: 2026-11-21
done:
blocked_by: ["[[04-furniture-and-materials]]"]
notes: []
terms: []
---

# Furniture devices: opening sounds, mirror, piano, dust sheet, Old Tree

The small details of furniture pieces that are devices in the old game (designer, Q2395, 2026-11-21: all four kinds,
now). Old code: `reference/it-socks/game/house/openable.gd` (the cue table by container kind), `mirror.gd`
(`MirrorGlass`), house/28's piano (88 `Key_<midi>` parts), `dust_sheet.gd`, `old_tree.gdshader`.

## Behaviour list (draft, to approve)
- V01 Each opening part (door, drawer, lid, flap) plays the old open and shut sound for its container kind (the `kind`
  metadata assets/04 kept), through the sound catalogue.
- V02 The wall mirror reflects the room as the old one did.
- V03 The piano's 88 keys each play their note and dip 3 degrees when used (or hit), as the old game.
- V04 The sheeted sofa's dust sheet looks and behaves as the old one.
- V05 The Old Tree has its own shader, as the old one.

## Open follow-ups
- [blocking] The behaviour list's details from the old code, approved by the designer before building.

## Built log
