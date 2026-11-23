---
type: ticket
status: ready-for-agent
kind: build
area: house
feature: house
priority: now
created: 2026-11-23
done:
blocked_by: [core/51-level-base-scene, core/52-sock-generator]
notes: ["Q2516"]
terms: [Mess, Sock, Pair, Cabinet, Hands]
---

# The Mess in the house: F5 plays the core loop

The main scene is a furnished house with no Socks (house/04). Bring the Mess in (Q2516), so a player picks, pairs,
throws and shelves in the house as in the zoo.

## Design
- The house inherits the level base (core/51), which brings the Mess and the co-op nodes.
- Sock areas (core/52) placed as the old game's generator had them for each floor of the house; counts as the old game.
- The Cabinets and anything else the core loop needs in the house that the zoo has (old placements, `layout.py`
  cabinet_spots).
- Floors thicker than 0.2 m where core/50 found Socks sinking, if the kit allows (core/50's note).

## Acceptance
- Real path: F5, the player picks a Sock in the kitchen, pairs it, shelves it in a Cabinet and earns Coins; a Guest
  joins and sees the same Mess.
- Strip for the designer: each floor with its Socks, beside the old game's same views (`builds/review-house-05/`).
