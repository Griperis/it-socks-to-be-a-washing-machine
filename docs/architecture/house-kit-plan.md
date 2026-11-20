# The re-gridded plan of the old house

house/02, K01-K02 (Q2343). Written by `tools/house_plan.py` from the numbers it holds: change them
there and run it again, never by hand. The old numbers are `reference/it-socks/tools/blender/make_house.py`
(v0.1.1). House/03 builds the house from the **new** column.

**The frame.** x east, z south, y up, metres. The old script measures from the walls' inside faces;
here every old number is moved +0.1 m, so the old outer walls' centre lines sit on x 0 and z 0, where
the new ones are. *Move* is new minus old in that frame. The stills draw the old house in red over
the new one (`builds/review-house-02/`).

**The rules the plan keeps** (checked by the script):
- Every wall's centre line is on a 0.5 m grid line (the kit's convention). Outer walls 0.2 m,
  partitions 0.12 m, as in the old house.
- An opening sits in the middle of a wall piece 0.5 m steps long, so its centre is on a 0.25 m
  lattice; its width is the old one (the piece is longer, the opening is not).
- An opening's edge stays at least a casing (0.07 m) clear of a wall that meets its wall, so the
  casing fits; where a T's 0.5 m arm would cover an opening the meeting wall butts into a plain
  wall piece instead (no T there).
- Heights over a floor are the old ones.

## Footprint and storeys (K02)

| | old | new | move |
|---|---|---|---|
| outer walls' centre lines, x by z | 10.3 x 8.54 | 10.5 x 8.5 | +0.20 x -0.04 |
| outside, x by z | 10.5 x 8.74 | 10.7 x 8.7 | +0.20 x -0.04 |
| inside, x by z | 10.1 x 8.34 | 10.3 x 8.3 | +0.20 x -0.04 |
| storey, floor top to floor top | 2.9 | 3 | +0.10 |
| basement floor top y | -2.9 | -3 | -0.10 |
| ground floor top y | 0 | 0 | 0 |
| first floor top y | 2.9 | 3 | +0.10 |
| attic floor top y | 5.8 | 6 | +0.20 |
| basement clear height (floor to ceiling) | 2.7 | 2.7 | 0 |
| ground clear height (floor to ceiling) | 2.7 | 2.7 | 0 |
| first clear height (floor to ceiling) | 2.6 | 2.6 | 0 |
| basement ceiling tile under the next floor tile | 0.1 | 0.2 | +0.10 |
| ground ceiling tile under the next floor tile | 0.1 | 0.2 | +0.10 |
| first ceiling tile under the next floor tile | 0.2 | 0.3 | +0.10 |

The clear heights stay the old ones exactly; the extra 0.1 m of each storey goes into the ceiling
tile (0.2 m under the ground and basement ceilings, 0.3 m under the attic floor; house/01's tile is
0.1 m, which would give 2.8 m on every floor).

## Wall centre lines

| wall | old (inside faces) | old centre | new centre | move |
|---|---|---|---|---|
| outer W | x -0.2..0 | 0 | 0 | 0 |
| outer E | x 10.1..10.3 | 10.3 | 10.5 | +0.20 |
| outer N | z -0.2..0 | 0 | 0 | 0 |
| outer S | z 8.34..8.54 | 8.54 | 8.5 | -0.04 |
| partition x4 (kitchen / hall) | x 3.83..3.95 | 3.99 | 4 | +0.01 |
| partition x6.5 (hall / living) | x 6.28..6.4 | 6.44 | 6.5 | +0.06 |
| partition z3.5 (workshop / laundry, office / bedroom, bathroom / kids) | z 3.16..3.28 | 3.32 | 3.5 | +0.18 |
| partition z2 (boiler / stair lobby) | z 1.98..2.1 | 2.14 | 2 | -0.14 |
| the stair's first riser (z) | 5.15 | 5.25 | 5.5 | +0.25 |

## Rooms (inside, wall face to wall face)

| room | level | old x0..x1, z0..z1 | old size | new x0..x1, z0..z1 | new size | edges moved |
|---|---|---|---|---|---|---|
| workshop | basement | 0.1..3.93, 0.1..3.26 | 3.83 x 3.16 | 0.1..3.94, 0.1..3.44 | 3.84 x 3.34 | 0 0 +0.01 +0.18 |
| laundry | basement | 0.1..3.93, 3.38..8.44 | 3.83 x 5.06 | 0.1..3.94, 3.56..8.4 | 3.84 x 4.84 | 0 +0.18 +0.01 -0.04 |
| boiler | basement | 4.05..6.38, 0.1..2.08 | 2.33 x 1.98 | 4.06..6.44, 0.1..1.94 | 2.38 x 1.84 | +0.01 0 +0.06 -0.14 |
| stair lobby | basement | 4.05..6.38, 2.2..5.25 | 2.33 x 3.05 | 4.06..6.44, 2.06..5.5 | 2.38 x 3.44 | +0.01 -0.14 +0.06 +0.25 |
| garage | basement | 6.5..10.2, 0.1..8.44 | 3.7 x 8.34 | 6.56..10.4, 0.1..8.4 | 3.84 x 8.3 | +0.06 0 +0.20 -0.04 |
| kitchen | ground | 0.1..3.93, 0.1..8.44 | 3.83 x 8.34 | 0.1..3.94, 0.1..8.4 | 3.84 x 8.3 | 0 0 +0.01 -0.04 |
| hall | ground | 4.05..6.38, 0.1..5.25 | 2.33 x 5.15 | 4.06..6.44, 0.1..5.5 | 2.38 x 5.4 | +0.01 0 +0.06 +0.25 |
| living | ground | 6.5..10.2, 0.1..8.44 | 3.7 x 8.34 | 6.56..10.4, 0.1..8.4 | 3.84 x 8.3 | +0.06 0 +0.20 -0.04 |
| office | first | 0.1..3.93, 0.1..3.26 | 3.83 x 3.16 | 0.1..3.94, 0.1..3.44 | 3.84 x 3.34 | 0 0 +0.01 +0.18 |
| bedroom | first | 0.1..3.93, 3.38..8.44 | 3.83 x 5.06 | 0.1..3.94, 3.56..8.4 | 3.84 x 4.84 | 0 +0.18 +0.01 -0.04 |
| landing | first | 4.05..6.38, 0.1..5.25 | 2.33 x 5.15 | 4.06..6.44, 0.1..5.5 | 2.38 x 5.4 | +0.01 0 +0.06 +0.25 |
| bathroom | first | 6.5..10.2, 0.1..3.26 | 3.7 x 3.16 | 6.56..10.4, 0.1..3.44 | 3.84 x 3.34 | +0.06 0 +0.20 +0.18 |
| kids | first | 6.5..10.2, 3.38..8.44 | 3.7 x 5.06 | 6.56..10.4, 3.56..8.4 | 3.84 x 4.84 | +0.06 +0.18 +0.20 -0.04 |
| loft | attic | 0.1..10.2, 0.1..8.44 | 10.1 x 8.34 | 0.1..10.4, 0.1..8.4 | 10.3 x 8.3 | 0 0 +0.20 -0.04 |

## Doorways and outer doors (K08, K09)

All 0.9 x 2.1 m but the garage door (2.4 x 2.1). *Along* is z on an x wall, x on a z wall.

| id | name | level | wall | old along | old centre | new centre | new along | move | piece |
|---|---|---|---|---|---|---|---|---|---|
| D1 | WorkshopLobby | basement | x 4 | 2.28..3.18 | 2.73 | 2.75 | 2.3..3.2 | +0.02 | 1.5 m (2..3.5) |
| D2 | LaundryLobby | basement | x 4 | 3.48..4.38 | 3.93 | 4.25 | 3.8..4.7 | +0.32 | 1.5 m (3.5..5) |
| D3 | BoilerLobby | basement | z 2 | 4.75..5.65 | 5.2 | 5.25 | 4.8..5.7 | +0.05 | 1.5 m (4.5..6) |
| D4 | LobbyGarage | basement | x 6.5 | 4.25..5.15 | 4.7 | 4.75 | 4.3..5.2 | +0.05 | 1.5 m (4..5.5) |
| D5 | KitchenHall | ground | x 4 | 2.28..3.18 | 2.73 | 2.75 | 2.3..3.2 | +0.02 | 1.5 m (2..3.5) |
| D6 | HallLiving | ground | x 6.5 | 4.25..5.15 | 4.7 | 4.75 | 4.3..5.2 | +0.05 | 1.5 m (4..5.5) |
| D7 | OfficeLanding | first | x 4 | 2.28..3.18 | 2.73 | 2.75 | 2.3..3.2 | +0.02 | 1.5 m (2..3.5) |
| D8 | BedroomLanding | first | x 4 | 3.48..4.38 | 3.93 | 4.25 | 3.8..4.7 | +0.32 | 1.5 m (3.5..5) |
| D9 | BathroomLanding | first | x 6.5 | 2.28..3.18 | 2.73 | 2.75 | 2.3..3.2 | +0.02 | 1.5 m (2..3.5) |
| D10 | KidsLanding | first | x 6.5 | 4.25..5.15 | 4.7 | 4.75 | 4.3..5.2 | +0.05 | 1.5 m (4..5.5) |
| D11 | FrontDoor | ground | z 0 | 5.38..6.28 | 5.83 | 5.75 | 5.3..6.2 | -0.08 | 1.5 m (5..6.5) |
| D12 | GarageDoor | basement | z 0 | 7.15..9.55 | 8.35 | 8.25 | 7.05..9.45 | -0.10 | 2.5 m (7..9.5) |

## Windows (K06)

Width, sill and head (over the floor) are the old ones. The stair window's are over the half
landing (old landing 1.45, new 1.5: 0.9..2.0 over it, so 2.4..3.5 over the ground floor).

| id | name | level | wall | width | sill..head | old along | new along | move | piece |
|---|---|---|---|---|---|---|---|---|---|
| W1 | WorkshopWell | basement | N | 1.2 | 1.75..2.45 | 1.26..2.46 | 1.15..2.35 | -0.11 | 1.5 m (1..2.5) |
| W2 | LaundryWellW | basement | W | 1 | 1.75..2.45 | 6.29..7.29 | 6.25..7.25 | -0.04 | 1.5 m (6..7.5) |
| W3 | LaundryWellS | basement | S | 1 | 1.75..2.45 | 2.68..3.68 | 2.75..3.75 | +0.07 | 1.5 m (2.5..4) |
| W4 | GarageWellE | basement | E | 1 | 1.75..2.45 | 3.21..4.21 | 3.25..4.25 | +0.04 | 1.5 m (3..4.5) |
| W5 | KitchenN | ground | N | 1 | 1.1..2.15 | 2.65..3.65 | 2.75..3.75 | +0.10 | 1.5 m (2.5..4) |
| W6 | KitchenW | ground | W | 1.1 | 0.9..2.15 | 6.74..7.84 | 6.7..7.8 | -0.04 | 1.5 m (6.5..8) |
| W7 | KitchenS | ground | S | 2 | 0.9..2.15 | 0.86..2.86 | 0.75..2.75 | -0.11 | 2.5 m (0.5..3) |
| W8 | HallN | ground | N | 0.5 | 1.3..2 | 4.35..4.85 | 4.25..4.75 | -0.10 | 1 m (4..5) |
| W9 | LivingN | ground | N | 1.2 | 0.9..2.15 | 7.73..8.93 | 7.65..8.85 | -0.08 | 1.5 m (7.5..9) |
| W10 | LivingE | ground | E | 1.4 | 0.9..2.15 | 4.11..5.51 | 4.05..5.45 | -0.06 | 1.5 m (4..5.5) |
| W11 | LivingS | ground | S | 2.4 | 0.9..2.15 | 7.13..9.53 | 7.05..9.45 | -0.08 | 2.5 m (7..9.5) |
| W12 | StairGround | ground | S | 1.5 | 2.4..3.5 (old 2.35..3.45) | 4.45..5.95 | 4.5..6 | +0.05 | 2.5 m (4..6.5) |
| W13 | OfficeN | first | N | 1.2 | 0.9..2.1 | 1.26..2.46 | 1.15..2.35 | -0.11 | 1.5 m (1..2.5) |
| W14 | OfficeW | first | W | 1.1 | 0.9..2.1 | 1.15..2.25 | 1.2..2.3 | +0.05 | 1.5 m (1..2.5) |
| W15 | BedroomW | first | W | 0.8 | 0.9..2.1 | 7.27..8.07 | 7.35..8.15 | +0.08 | 1.5 m (7..8.5) |
| W16 | BedroomS | first | S | 1.4 | 0.9..2.1 | 1.49..2.89 | 1.55..2.95 | +0.06 | 1.5 m (1.5..3) |
| W17 | LandingN | first | N | 1.1 | 0.9..2.1 | 4.65..5.75 | 4.7..5.8 | +0.05 | 1.5 m (4.5..6) |
| W18 | Bathroom (frosted) | first | N | 1 | 1.3..2 | 7.28..8.28 | 7.25..8.25 | -0.03 | 1.5 m (7..8.5) |
| W19 | KidsS | first | S | 1.5 | 0.9..2.1 | 7.19..8.69 | 7.25..8.75 | +0.06 | 2 m (7..9) |
| W20 | GableW | attic | W | 0.7 | 0.8..1.7 | 2.21..2.91 | 2.15..2.85 | -0.06 | 1 m (2..3) |
| W21 | GableE | attic | E | 0.7 | 0.8..1.7 | 2.21..2.91 | 2.15..2.85 | -0.06 | 1 m (2..3) |
| W22 | Dormer | attic | S | 1.2 | 0.9..1.95 | 7.29..8.49 | 7.4..8.6 | +0.11 | 2 m (7..9) |

The basement windows look into the light wells outside (`make_exterior.py` WELLS: 0.9 m out from
the wall, 0.25 m wider each side); the wells move with their windows.

## The U stair (K10)

| | old | new | move |
|---|---|---|---|
| stair well x (between the partitions) | 4.05..6.38 | 4.06..6.44 | +0.01 +0.06 |
| first riser z, landing z0..z1 | 5.25, 7.34..8.44 | 5.5, 7.3..8.4 | +0.25, -0.04 |
| west flight x (up south to the landing) | 4.05..5.16 | 4.06..5.19 | |
| east flight x (up north to the next floor) | 5.27..6.38 | 5.31..6.44 | |
| flight width | 1.11 | 1.13 | +0.03 |
| newel wall centre x, 0.12 thick | 5.21 | 5.25 | +0.04 |
| risers a storey, rise | 16, 0.1812 | 16, 0.1875 | |
| goings a flight, going | 7, 0.299 | 7, 0.257 | -0.04 |
| pitch | 31.3 deg | 36.1 deg | +4.8 deg |
| half landing height over the floor | 1.45 | 1.5 | +0.05 |

Why the first riser moved south (+0.25), not north (-0.25, which would give a 29.7 deg stair, nearer
the old 31.3): the elevator shaft's south side lines up with the first riser in the old house, and
on the first floor the bedroom doorway (D8), the hatch and the attic flight's first step follow
each other along the x4 partition. With the riser at z 5.0 there would be 0.82 m between the
z3.5 partition and the hatch for a 0.9 m doorway. The price is a steeper stair (see the follow-ups).

## The elevator shaft, the hatches (K09)

| | old | new | move |
|---|---|---|---|
| shaft inside x0..x1, z0..z1 (0.7 x 0.7, through every slab above the basement floor) | 3.23..3.93, 4.55..5.25 | 3.24..3.94, 4.8..5.5 | +0.01, +0.25 |
| first floor hatch through x4, z (sill 0.8, 0.58 high) | 4.63..5.17 | 4.88..5.42 | +0.25 |
| the Cellar hatch in the workshop floor, centre (0.75 square) | 2.8, 1.65 | 2.75, 1.75 | -0.05, +0.10 |

The shaft and the Cellar hatch are not on the 0.5 m tile grid (0.7 and 0.75 m): each needs a floor
and ceiling piece with the hole in it (1 x 1 m) for house/03.

## Roof and attic (K11)

| | old | new | move |
|---|---|---|---|
| knee wall over the attic floor | 0.4 | 0.4 | 0 |
| ridge over the attic floor | 3.59 | 3.59 | 0 |
| ridge line z | 4.27 | 4.25 | -0.02 |
| ridge y | 9.39 | 9.59 | +0.20 |
| pitch | 37.4 deg | 37.5 deg | +0.1 deg |
| dormer inside x | 6.99..8.79 | 7.1..8.9 | +0.11 |
| dormer cheeks' centre lines x (0.2 thick) | 6.89, 8.89 | 7, 9 | +0.11 |
| dormer flat ceiling over the attic floor | 2.2 | 2.2 | 0 |
| dormer ceiling meets the roof at z | 6.09 | 6.06 | -0.03 |
| roof post (0.16 square) at x, z | 3.84, 1.81 | 3.75, 1.75 | -0.09, -0.06 |
| roof post (0.16 square) at x, z | 8.66, 1.81 | 8.75, 1.75 | +0.09, -0.06 |
| roof post (0.16 square) at x, z | 2.74, 6.74 | 2.75, 6.75 | +0.01, +0.01 |
| roof post (0.16 square) at x, z | 9.32, 6.74 | 9.25, 6.75 | -0.07, +0.01 |

The ridge keeps its old height over the attic floor, so the loft is as tall as before and the
pitch stays near the old house's (37.5 deg, old 37.4; the ticket's 40 deg was the pitch before
house/37 made the house deeper). The gable windows (W20, W21) are on the 0.25 m lattice, not
centred on the ridge, as the old ones were not.

## Pieces this plan asks for (for the second stop)

- Door pieces (house/01 has the 1 m one):
  - 0.9 m wide in a 1.5 m piece: D1, D2, D3, D4, D5, D6, D7, D8, D9, D10, D11
  - 2.4 m wide in a 2.5 m piece: D12
- Window pieces, one per width, piece length and sill/head:
  - 0.5 m wide, sill..head 1.3..2, in a 1 m piece: W8
  - 0.7 m wide, sill..head 0.8..1.7, in a 1 m piece: W20, W21
  - 0.8 m wide, sill..head 0.9..2.1, in a 1.5 m piece: W15
  - 1 m wide, sill..head 1.1..2.15, in a 1.5 m piece: W5
  - 1 m wide, sill..head 1.3..2, frosted, in a 1.5 m piece: W18
  - 1 m wide, sill..head 1.75..2.45, in a 1.5 m piece: W2, W3, W4
  - 1.1 m wide, sill..head 0.9..2.1, in a 1.5 m piece: W14, W17
  - 1.1 m wide, sill..head 0.9..2.15, in a 1.5 m piece: W6
  - 1.2 m wide, sill..head 0.9..2.1, in a 1.5 m piece: W13
  - 1.2 m wide, sill..head 0.9..2.15, in a 1.5 m piece: W9
  - 1.2 m wide, sill..head 1.75..2.45, in a 1.5 m piece: W1
  - 1.2 m wide, sill..head 0.9..1.95, in a 2 m piece: W22
  - 1.4 m wide, sill..head 0.9..2.1, in a 1.5 m piece: W16
  - 1.4 m wide, sill..head 0.9..2.15, in a 1.5 m piece: W10
  - 1.5 m wide, sill..head 0.9..2.1, in a 2 m piece: W19
  - 1.5 m wide, sill..head 2.4..3.5, in a 2.5 m piece: W12
  - 2 m wide, sill..head 0.9..2.15, in a 2.5 m piece: W7
  - 2.4 m wide, sill..head 0.9..2.15, in a 2.5 m piece: W11
  That is 18 window pieces.
- Floor and ceiling pieces with the shaft hole and with the Cellar hatch (1 x 1 m).
- The U stair per storey (well 2.38 x 2.9 m inside), the attic's balustrade round the void.
