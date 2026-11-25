---
type: ticket
status: ready-for-human
kind: bug
area: core
feature: washer
priority: now
created: 2026-11-25
done:
blocked_by: []
notes: ["suggested model: sonnet", "designer 2026-11-25, Windows build: the washer's broken-look sparks are broken"]
terms: []
---

# The washing machine's broken-look sparks are broken

The designer, playing the Windows debug build from main (2026-11-25): "spark particles are broken", and asked which:
the broken washing machine's sparks (core/87's `Damage`: sparks, smoke, flash, buzz, bursting on a fixed clock).
They didn't say how they look broken.

Since core/87, assets/14 put the real model's Looks (`looks_washer.tscn`) in place of the graybox. The Damage
nodes may not have come across whole, or may be placed for the graybox's size.

## What to do
1. Reproduce: stills or a strip of the broken washer in the house and in the washer station, at mood 1 and at the
   angriest, real Looks and graybox side by side. Compare with the old game's `washer_damage.gd` (the burst, the
   sparks' look and their spray) and core/87's stills if any are in `builds/`.
2. Name what is broken (missing, wrong place, wrong material, square specks, never emitting, emitting forever) and
   fix it in the Looks scenes. The real and graybox Looks both carry it, as the contract says.
3. If the sparks use the soft speck look, share it with core/112's (`mate_sparkle.tscn`'s material), not a new copy.

## Acceptance
- The sparks look like the old game's on the real washer, in the house and the station. Strip in
  `builds/review-core-117/`. Look work stops there: `ready-for-human`.
- The washer broken suite passes. If the cause was a missing node in the real Looks, add a check that every Damage
  node of the contract is in both Looks.

## Open follow-ups

- [later] The old sparks per burst per spot were `sparks * spark_every / 2` (about 7 at mood 1 to 10 at the top); the port's
  `sparks_min`/`sparks_max` (6 to 40) are per burst, so the top bursts are about four times as full as the old game's.
  Left as is (a tuning choice); tell me if the strip reads too busy.
- [later] The stills are the Looks alone on a floor (the station and the house use the same scene); the pale blue reads
  washed out against the bright sky in the headless renderer.

## Built log

### 2026-11-25
Changed: cause found and reproduced (strip before: no sparks, no smoke on the real washer): `looks_washer.tscn`'s Damage emitters
(`SparksBack`, `SparksCable`, `Smoke`) were bare nodes with no process material, draw pass, amount or lifetime. The graybox had
them, but as round blue balls, not the old game's streaks. Both Looks now take one shared set of resources beside the
scene (`damage_spark_back/cable.tres`, `damage_spark_mesh.tres` (the old 1.2 x 9 cm emissive streak, aligned to its
flight, fading blue-white), `damage_smoke.tres`, `damage_smoke_mesh.tres`, the old puff growing 0.4 to 1.6), with the old
game's lifetime 0.35, explosiveness 0.9, fixed seeds, spray and speed. Not the soft speck of `mate_sparkle`: the old sparks are
streaks, not specks. New case `damage_nodes` (both Looks have every contract Damage node and each emitter can show). Shot hook
`washer_beat` gains `set,<property>,<float>`; shot set `washer-sparks`.
Files: game/entities/washer/looks_washer.tscn, looks_graybox.tscn, damage_*.tres, tests/washer_broken_test.gd,
tools/shot_hooks.gd, tools/shots/sets/washer-sparks.txt.
Look work: strip in builds/review-core-117/washer-sparks-strip.png (real and graybox, angriest and mild).
