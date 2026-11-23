---
type: ticket
status: done
kind: build
area: house
feature: house
priority: now
created: 2026-11-23
done: 2026-11-23
blocked_by: []
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
- The stair pieces get step-shaped landing places so the stair trail's Socks lie flat on each tread; the player still
  walks the ramp collision (Q2530).
- Measure how long laying a whole floor (about 1200 Socks) takes in one frame (core/52's [later]); if it hitches, say so.
- Floors thicker than 0.2 m where core/50 found Socks sinking, if the kit allows (core/50's note).

## Acceptance
- Real path: F5, the player picks a Sock in the kitchen, pairs it, shelves it in a Cabinet and earns Coins; a Guest
  joins and sees the same Mess.
- Strip for the designer: each floor with its Socks, beside the old game's same views (`builds/review-house-05/`).

## Open follow-ups
- [later] Counts: each floor lays its old stage's Pairs (stages.json: basement 50, ground 160, first 150, attic 130,
  990 Socks with the 12 on the stairs), of its floor's two Cabinets' Collections, all floors at once (Stages are M4).
  The old New Game without the campaign laid 605 Pairs (1210 Socks) over the house; say if the house should hold that.
  The washer's fan (160 Socks) waits for the machine, as Q2528 parks it.
- [later] Laying time: the whole house's 990 Socks take about 1.7 s in the start-up frame (headless test run, debug
  engine): a hitch at load. Slicing or a worker thread (old row 6) is its own ticket.
- [later] The attic gets no Socks inside furniture: the trunk's `Inside` box (game/furniture/trunk.tscn) floats 10 cm
  over its collision floor, so every try is "off_surface" and its share goes to open floor (the old game hid 5 in each
  trunk). A furniture fix.
- [later] Hidden share kept at the designer's 0.3 (Q2521); the old house hid about 14% (173 of 1210).
- [later] The old "on_stairs" 6 (single steps anywhere) are laid as short trails (3 on the basement's stair, 3 on the
  first floor's), the old trail of 6 on the ground floor's stair; the old game drew both at random.
- [later] Only the trail sees the treads: a woken, thrown or dropped Sock still lands on the stair's walking ramp, and a
  trail Sock woken under the ramp would be pushed up onto it.
- [later] Floors thicker than 0.2 m (core/50's note): the kit's floor tiles are 0.1 m (`floor_thickness`); core/50 left a
  0.4 m floor to the designer. Not changed; the generated Socks appear at rest (no fall), so the sink does not start.
- [later] The garage Cabinet stood hidden until the basement's stage completed (stages.json); here all eight are open,
  2 Rows each, their Collections the old layout's defaults (the old game drew them from cabinet_pools.json).
- [later] The house shot set's "room-kitchen" view starts with the camera in the fridge's door (as in house/04's stills);
  the strip uses "room-kitchen-b".

## Built log
- 2026-11-23
  - Changed: the house gets its Mess and Cabinets. `SockGenerators/<Floor>`: one SockGenerator per floor with one
    `Floor` SockArea (the old stage's Pairs, Heaps on, hidden share 0.3), the floor's Cabinets' Collections, the
    `Washer` marker for the thinning, stair trails (6 on the ground floor's stair, 3 on each other) and its
    GeneratedSocks Part on the runtime's Mess. `Cabinets/<Spot>`: the old eight cabinet_spots moved to the plan, each
    its old Collection, wired to the runtime's Hands and Coins. Q2530: every stair piece has a `Treads` body (a 2 cm
    box per step and landing, layer 128, `SockTrail.LAYER_TREADS`), written by tools/house_kit_build.gd; a trail Sock
    over a tread lies flat on it (`SockLaying._rest_on_tread`, the stair's own Body left out of its house test,
    `PhysicsQueries.overlap_colliders` gained `exclude`); the player keeps the ramp. Laying the house measured: 990
    Socks in about 1.7 s in one frame. Shot set `house-mess`.
  - Files: game/house/house.tscn; game/house/kit/pieces/stair_full.tscn, stair_half.tscn, stair_u.tscn,
    stair_u_solid.tscn; tools/house_kit_build.gd; game/mess/sock_laying.gd, sock_trail.gd; game/hands/physics_queries.gd;
    tests/house_test.gd, tests/sock_generator_test.gd; tools/shots/sets/house-mess.txt; docs/architecture/house.md,
    house-kit.md, sock-generator.md.
  - Stills: builds/review-house-05/ (house-mess-room-*.png per floor; house-05-old-beside-new.png: the old baseline
    views beside the new, two rooms a floor and the ground floor's stair).
  - Verified: PASS 17807 checks, 456 cases (`kit/tools/run.sh --touched`; FLAKY mess_settle:real_path_4, core/54's known flake); PASS rules
