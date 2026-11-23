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
- V01 Each opening part (19 furniture pieces have them; none has a sound set yet, and the catalogue has only drawer, door and cupboard) (door, drawer, lid, flap) plays the old open and shut sound for its container kind (the `kind`
  metadata assets/04 kept), through the sound catalogue.
- V02 The wall mirrors reflect as the old ones (`mirror.gd`, `mirror.json`): a planar reflection by a second camera, 256 px, every 3rd frame, within 4.5 m, off on the Low preset; teammates and the player's own full body in it, the first-person belly and held items and the Mess Socks not (Q2505).
- V03 The piano as old (`piano.json`, `assets/audio/piano/`): 88 keys each play their sampled note and dip when used (or hit), dip 0.04 s, rise 0.16 s, 12 voices, the lid with its own sound; anyone plays it and every player hears it (Q2508).
- V04 The dust sheet (old `dust_sheet.gd`): draped over a locked Cabinet, pulled off on the unlock (slides forward over the top edge, spills onto the floor, fades, 0.5 s); until Cabinet locks exist, a switch at the furniture station unlocks (Q2507). The sheeted sofa stays a model.
- V05 Out: the Old Tree stays as it is; its motion, flicker and voice wait for its rework (Q2506).

## Acceptance
- The behaviour list above is first expanded from the old code into every sound, motion and number (one line each, small details included, Q2277), written into this ticket; then built with one test per line.
- Each device is placed at the furniture station (`game/zoo/stations/furniture.tscn`) and works there: a door, a drawer, a lid and a flap each play their kind's open and shut sound; the mirror reflects; each piano key plays its note and dips; the dust sheet as old; the Old Tree unchanged.
- Sounds go through the sound catalogue with the old clips (plug and play, no code per sound).
- A strip in `builds/review-furniture-devices/`: the mirror, the piano, the dust sheet's pull-off, old beside new.

## Answers
- Q2505-Q2508 (2026-11-23): see V02-V05.
- Q2502 (2026-11-23): all five devices as the old game, the behaviour list written in full from the old code.
- Q2504 (2026-11-23): built to the end with no stop at the first still; a before and after strip for the designer's batch review before the merge.

## Open follow-ups

## Built log
