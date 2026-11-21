"""The house's plants (house/04): the trial's stylised round-leaf plant (Q404) without subdivision,
plus a snake plant, a trailing pothos for shelves and a little cactus for sills. Pots wear the
sock creature's cream stripes (Q407).
"""

import math
import random

import bmesh
from mathutils import Matrix

import kit
from fkit import M, ball, box, cush, cyl, lathe, piece, tube  # noqa: F401

ROOMS = ["Plants"]


def _pot(P, R, H, colour, stripes=True, n=20):
    pot = M(colour, 0.75)
    prof = [(0, 0), (R * 0.72, 0.0), (R * 0.8, 0.02), (R * 0.95, H * 0.35), (R, H - 0.05), (R * 1.12, H - 0.04),
            (R * 1.15, H), (R * 1.08, H + 0.02), (R * 0.92, H + 0.02), (R * 0.9, H - 0.02), (0, H - 0.02)]
    P.add(lathe("Pot", prof, pot, n=n))
    if stripes:
        for z in (H * 0.33, H * 0.48):
            r = R * (0.8 + 0.15 * z / (H * 0.35)) if z < H * 0.35 else R * (0.95 + 0.05 * (z - H * 0.35) / (H * 0.65 - 0.05))
            P.add(lathe("PotBand", [(r - 0.004, z - 0.014), (r + 0.006, z - 0.011), (r + 0.006, z + 0.011),
                                    (r - 0.004, z + 0.014)], M("stripe", 0.7), n=n))
    P.add(lathe("Soil", [(0, H - 0.04), (R * 0.92, H - 0.04), (R * 0.92, H - 0.03), (0, H - 0.015)], M("soil", 0.95), n=n))


def _leaf(P, base, a, pitch, L, mat, shape, nl=5, nw=2, curl=0.6, thick=0.01):
    lb = kit.leaf_bm(L, L * 0.78, shape, nl=nl, nw=nw, fold=0.3, curl=curl)
    kit.transform_bm(lb, loc=base, yaw=a - math.pi / 2, pitch=pitch)
    leaf = kit.obj_from_bm("Leaf", lb, mat)
    sol = leaf.modifiers.new("Solid", "SOLIDIFY")
    sol.thickness = thick
    sol.offset = 0
    P.add(leaf)


ALL_ROOMS = ["Living room", "Kitchen & dining", "Hall", "Parents' bedroom", "Kids' room", "Bathroom", "Home office",
             "Laundry"]


@piece("plant_big", ["Plants", "Living room", "Hall", "Parents' bedroom", "Home office"], spot="Plant",
       note="The trial's floor plant: a chunky terracotta pot, round leaves on arcing stems.")
def plant_big(P):
    H = 0.4
    _pot(P, 0.2, H, "terracotta")
    stem = M("stem", 0.7)
    leaves = [M("leaf", 0.55), M("leaf_light", 0.55), M("leaf_dark", 0.55)]
    rng = random.Random(7)
    shape = lambda t: math.sin(math.pi * min(1.0, t ** 0.75)) ** 0.75   # noqa: E731
    n = 13
    for k in range(n):
        a = 2 * math.pi * k / n + rng.uniform(-0.2, 0.2)
        tall = k % 3 == 0
        h = rng.uniform(0.55, 0.85) if tall else rng.uniform(0.3, 0.55)
        reach = rng.uniform(0.12, 0.3) if tall else rng.uniform(0.22, 0.38)
        base = (0.04 * math.cos(a), 0.04 * math.sin(a), H - 0.03)
        pts = []
        for i in range(5):
            t = i / 4
            r = reach * t ** 1.5
            pts.append((base[0] + r * math.cos(a), base[1] + r * math.sin(a), base[2] + h * math.sin(t * math.pi / 2)))
        P.add(tube("Stem", pts, [0.014 - 0.005 * i / 4 for i in range(5)], stem, n=5))
        L = rng.uniform(0.26, 0.34)
        _leaf(P, pts[-1], a, math.radians(rng.uniform(15, 40)), L, leaves[k % 3], shape)


@piece("plant_snake", ["Plants", "Living room", "Bathroom", "Home office", "Kitchen & dining"], spot="Plant",
       note="A tall snake plant in a sage pot.")
def plant_snake(P):
    H = 0.3
    _pot(P, 0.15, H, "sage")
    rng = random.Random(11)
    shape = lambda t: (1 - t) ** 0.6 * min(1.0, t * 6 + 0.4)   # noqa: E731
    for k in range(11):
        a = 2 * math.pi * k / 11 + rng.uniform(-0.3, 0.3)
        r = rng.uniform(0.0, 0.07)
        base = (r * math.cos(a), r * math.sin(a), H - 0.04)
        L = rng.uniform(0.45, 0.75)
        lb = kit.leaf_bm(L, 0.09, shape, nl=5, nw=1, fold=0.5, curl=rng.uniform(-0.2, 0.2))
        # Stand the blade up (pitch about x first), then turn it to its side (yaw).
        m = (Matrix.Translation(base) @ Matrix.Rotation(a - math.pi / 2, 4, "Z")
             @ Matrix.Rotation(math.radians(rng.uniform(72, 86)), 4, "X"))
        bmesh.ops.transform(lb, matrix=m, verts=lb.verts)
        leaf = kit.obj_from_bm("Blade", lb, M("leaf_dark" if k % 2 else "leaf", 0.5))
        sol = leaf.modifiers.new("Solid", "SOLIDIFY")
        sol.thickness = 0.012
        sol.offset = 0
        P.add(leaf)


@piece("plant_trailing", ["Plants", "Kitchen & dining", "Living room", "Home office", "Kids' room", "Bathroom"],
       spot="Shelf plant (new)", note="Small: for shelves, sills and the tops of units; its vines hang over the edge (-y).")
def plant_trailing(P):
    H = 0.14
    _pot(P, 0.085, H, "pad", n=16)
    rng = random.Random(5)
    leafm = [M("leaf", 0.55), M("leaf_light", 0.55)]
    shape = lambda t: math.sin(math.pi * min(1.0, t ** 0.8)) ** 0.8   # noqa: E731
    for k in range(5):
        a = -math.pi / 2 + rng.uniform(-1.0, 1.0)
        pts = []
        for i in range(6):
            t = i / 5
            out = 0.06 + 0.1 * min(1, t * 2)
            z = H - 0.02 + 0.05 * math.sin(t * 2) - 0.14 * t ** 1.6 * (k % 3)
            pts.append((out * math.cos(a), out * math.sin(a), max(0.015, z)))
        P.add(tube("Vine", pts, 0.004, M("stem", 0.6), n=4))
        for i in range(1, 6):
            _leaf(P, pts[i], a + rng.uniform(-1.2, 1.2), math.radians(rng.uniform(-10, 30)), 0.07, leafm[(i + k) % 2],
                  shape, nl=3, nw=1, curl=0.3, thick=0.004)
    for k in range(6):
        a = 2 * math.pi * k / 6
        _leaf(P, (0.02 * math.cos(a), 0.02 * math.sin(a), H - 0.02), a, math.radians(35), 0.09, leafm[k % 2], shape,
              nl=3, nw=1, curl=0.4, thick=0.004)


@piece("plant_cactus", ["Plants", "Kids' room", "Home office", "Kitchen & dining", "Laundry"], spot="Sill plant (new)",
       note="A little round cactus for window sills.")
def plant_cactus(P):
    H = 0.1
    _pot(P, 0.07, H, "terracotta", n=14)
    green = M("leaf_dark", 0.6)
    P.add(lathe("Cactus", [(0, H - 0.03), (0.05, H - 0.02), (0.065, H + 0.06), (0.055, H + 0.14), (0.03, H + 0.18),
                           (0, H + 0.19)], green, n=12))
    P.add(lathe("Arm", [(0, 0), (0.025, 0.0), (0.03, 0.05), (0.02, 0.08), (0, 0.085)], green, n=8,
                loc=(0.06, 0, H + 0.06)))
    P.add(ball("Flower", 0.022, (0, 0, H + 0.2), M("pink", 0.5), seg=8, rings=5, scale=(1, 1, 0.6)))
