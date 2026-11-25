---
type: ticket
status: ready-for-agent
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

## Built log
