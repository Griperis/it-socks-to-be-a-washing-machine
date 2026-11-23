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

## Acceptance
- The behaviour list above is first expanded from the old code into every sound, motion and number (one line each, small details included, Q2277), written into this ticket; then built with one test per line.
- Each device is placed at the furniture station (`game/zoo/stations/furniture.tscn`) and works there: a door, a drawer, a lid and a flap each play their kind's open and shut sound; the mirror reflects; each piano key plays its note and dips; the dust sheet as old; the Old Tree with its shader.
- Sounds go through the sound catalogue with the old clips (plug and play, no code per sound).
- A strip in `builds/review-furniture-devices/`: the mirror, the piano, the dust sheet and the Old Tree, old beside new.

## Answers
- Q2502 (2026-11-23): all five devices as the old game, the behaviour list written in full from the old code.
- Q2504 (2026-11-23): built to the end with no stop at the first still; a before and after strip for the designer's batch review before the merge.

## Open follow-ups

## Built log
