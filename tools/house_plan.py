#!/usr/bin/env python3
"""The re-gridded plan of the old house (house/02, K01-K02, Q2343).

Holds the old house's numbers (reference/it-socks/tools/blender/make_house.py at v0.1.1) beside
the new ones on the kit's 0.5 m grid, checks the new ones against the plan's rules, and writes
the plan table (docs/architecture/house-kit-plan.md) and a plan still per floor plus a section,
old over new:

    python3 tools/house_plan.py --md docs/architecture/house-kit-plan.md --out <folder>

Coordinates: x east, z south, y up, metres. The old script's numbers are inside-face numbers
(x 0 is the west wall's inner face). Here they are moved by +0.1 m ("the frame") so the old outer
walls' centre lines sit on x 0 and z 0, where the new outer walls' centre lines are; every "move"
is new minus framed old. House/03 builds the house from the NEW numbers.
"""

import argparse
import math
import os

from PIL import Image, ImageDraw, ImageFont

FRAME = 0.1                 # old inside-face numbers -> the shared frame
EXT, PART = 0.2, 0.12       # wall thicknesses, old and new (K04)
CASING = 0.07               # the old door casing's width (make_flat.py CASING_W)
LATTICE = 0.25              # an opening's centre: the middle of a piece of 0.5 m steps

# --- Storeys (K02) -------------------------------------------------------------------------
# level: (old floor y, old clear height, new floor y, new clear height)
LEVELS = {
    "basement": (-2.9, 2.7, -3.0, 2.7),
    "ground": (0.0, 2.7, 0.0, 2.7),
    "first": (2.9, 2.6, 3.0, 2.6),
    "attic": (5.8, None, 6.0, None),
}
OLD_STOREY, NEW_STOREY = 2.9, 3.0
FLOOR_T = 0.1               # floor tile, old and new

# --- Wall centre lines ---------------------------------------------------------------------
# name: (axis the line is constant in, old inside-face range of the wall, new centre line)
LINES = {
    "outer W": ("x", (-0.2, 0.0), 0.0),
    "outer E": ("x", (10.1, 10.3), 10.5),
    "outer N": ("z", (-0.2, 0.0), 0.0),
    "outer S": ("z", (8.34, 8.54), 8.5),
    "partition x4 (kitchen / hall)": ("x", (3.83, 3.95), 4.0),
    "partition x6.5 (hall / living)": ("x", (6.28, 6.4), 6.5),
    "partition z3.5 (workshop / laundry, office / bedroom, bathroom / kids)": ("z", (3.16, 3.28), 3.5),
    "partition z2 (boiler / stair lobby)": ("z", (1.98, 2.1), 2.0),
}
X0, X4, X65, X1 = 0.0, 4.0, 6.5, 10.5
Z0, Z2, Z35, Z1 = 0.0, 2.0, 3.5, 8.5

# The new partitions per level: (axis, line, from, to) along the other axis.
NEW_PARTITIONS = {
    "basement": [("x", X4, Z0, Z1), ("x", X65, Z0, Z1), ("z", Z35, X0, X4), ("z", Z2, X4, X65)],
    "ground": [("x", X4, Z0, Z1), ("x", X65, Z0, Z1)],
    "first": [("x", X4, Z0, Z1), ("x", X65, Z0, Z1), ("z", Z35, X0, X4), ("z", Z35, X65, X1)],
    "attic": [],
}


def face(line: float, outer: bool, side: int) -> float:
    """A wall's face on `side` (+1 east/south, -1 west/north) of its centre line."""
    return line + side * (EXT if outer else PART) / 2


IN_W, IN_E = face(X0, True, 1), face(X1, True, -1)
IN_N, IN_S = face(Z0, True, 1), face(Z1, True, -1)

# --- The stair, the shaft (K10, K09) --------------------------------------------------------
OLD_STAIR = (3.95, 5.15, 6.28, 8.34)            # x0, z0 (the first riser), x1, z1
OLD_LANDING_D = 1.1
NEW_STAIR_Z0 = 5.5                              # the first riser, on a grid line
NEW_LANDING_D = 0.9                             # Q2350: 33.3 deg
STEPS = 16                                      # risers a storey, 7 goings a flight + the landing
OLD_SHAFT = (3.13, 4.45, 3.83, 5.15)
NEW_SHAFT = (face(X4, False, -1) - 0.7, NEW_STAIR_Z0 - 0.7, face(X4, False, -1), NEW_STAIR_Z0)
OLD_HATCH_Z = (4.53, 5.07)                      # CAR_Z: the first floor's hatch through x4
HATCH_SILL, HATCH_H = 0.8, 0.58
NEW_HATCH_Z = (NEW_SHAFT[1] + 0.08, NEW_SHAFT[1] + 0.62)
OLD_GROTTO = (2.325, 1.175, 3.075, 1.925)      # the Cellar hatch in the workshop floor
NEW_GROTTO_CENTRE = (2.75, 1.75)

# --- Doorways (K08): id, name, level, line axis, line, old s0, s1, new centre ---------------------
DOOR_W, DOOR_H = 0.9, 2.1
DOORS = [
    ("D1", "WorkshopLobby", "basement", "x", X4, 2.18, 3.08, 2.75),
    ("D2", "LaundryLobby", "basement", "x", X4, 3.38, 4.28, 4.1),
    ("D3", "BoilerLobby", "basement", "z", Z2, 4.65, 5.55, 5.25),
    ("D4", "LobbyGarage", "basement", "x", X65, 4.15, 5.05, 4.75),
    ("D5", "KitchenHall", "ground", "x", X4, 2.18, 3.08, 2.75),
    ("D6", "HallLiving", "ground", "x", X65, 4.15, 5.05, 4.75),
    ("D7", "OfficeLanding", "first", "x", X4, 2.18, 3.08, 2.75),
    ("D8", "BedroomLanding", "first", "x", X4, 3.38, 4.28, 4.1),
    ("D9", "BathroomLanding", "first", "x", X65, 2.18, 3.08, 2.75),
    ("D10", "KidsLanding", "first", "x", X65, 4.15, 5.05, 4.75),
    # The outer doors: width from the old numbers.
    ("D11", "FrontDoor", "ground", "z", Z0, 5.28, 6.18, 5.75),
    ("D12", "GarageDoor", "basement", "z", Z0, 7.05, 9.45, 8.25),
]
# Off the 0.25 m lattice, in an off-centre door piece (Q2351). The old place itself (3.48..4.38)
# would cut into the z3.5 partition, which moved 0.18 m south; the doorway keeps its old 0.1 m from
# the partition's face. id: the 1.5 m piece's start along its wall.
OFF_CENTRE = {"D2": 3.5, "D8": 3.5}

# --- Windows (K06): id, name, side, old s0, s1, sill, head over its floor, frosted, new centre -----
# The width is the old one; the stair window's heights are over the half landing.
WINDOWS = [
    ("W1", "WorkshopWell", "basement", "N", 1.16, 2.36, 1.75, 2.45, False, 1.75),
    ("W2", "LaundryWellW", "basement", "W", 6.19, 7.19, 1.75, 2.45, False, 6.75),
    ("W3", "LaundryWellS", "basement", "S", 2.58, 3.58, 1.75, 2.45, False, 3.25),
    ("W4", "GarageWellE", "basement", "E", 3.11, 4.11, 1.75, 2.45, False, 3.75),
    ("W5", "KitchenN", "ground", "N", 2.55, 3.55, 1.1, 2.15, False, 3.25),
    ("W6", "KitchenW", "ground", "W", 6.64, 7.74, 0.9, 2.15, False, 7.25),
    ("W7", "KitchenS", "ground", "S", 0.76, 2.76, 0.9, 2.15, False, 1.75),
    ("W8", "HallN", "ground", "N", 4.25, 4.75, 1.3, 2.0, False, 4.5),
    ("W9", "LivingN", "ground", "N", 7.63, 8.83, 0.9, 2.15, False, 8.25),
    ("W10", "LivingE", "ground", "E", 4.01, 5.41, 0.9, 2.15, False, 4.75),
    ("W11", "LivingS", "ground", "S", 7.03, 9.43, 0.9, 2.15, False, 8.25),
    ("W12", "StairGround", "ground", "S", 4.35, 5.85, 2.35, 3.45, False, 5.25),
    ("W13", "OfficeN", "first", "N", 1.16, 2.36, 0.9, 2.1, False, 1.75),
    ("W14", "OfficeW", "first", "W", 1.05, 2.15, 0.9, 2.1, False, 1.75),
    ("W15", "BedroomW", "first", "W", 7.17, 7.97, 0.9, 2.1, False, 7.75),
    ("W16", "BedroomS", "first", "S", 1.39, 2.79, 0.9, 2.1, False, 2.25),
    ("W17", "LandingN", "first", "N", 4.55, 5.65, 0.9, 2.1, False, 5.25),
    ("W18", "Bathroom", "first", "N", 7.18, 8.18, 1.3, 2.0, True, 7.75),
    ("W19", "KidsS", "first", "S", 7.09, 8.59, 0.9, 2.1, False, 8.0),
    ("W20", "GableW", "attic", "W", 2.11, 2.81, 0.8, 1.7, False, 2.5),
    ("W21", "GableE", "attic", "E", 2.11, 2.81, 0.8, 1.7, False, 2.5),
    ("W22", "Dormer", "attic", "S", 7.19, 8.39, 0.9, 1.95, False, 8.0),
]
SIDE_LINE = {"N": ("z", Z0), "S": ("z", Z1), "W": ("x", X0), "E": ("x", X1)}

# --- Rooms: name, level, old rect (x0, z0, x1, z1), new rect from the faces ---------------------
P4W, P4E = face(X4, False, -1), face(X4, False, 1)
P65W, P65E = face(X65, False, -1), face(X65, False, 1)
P35N, P35S = face(Z35, False, -1), face(Z35, False, 1)
P2N, P2S = face(Z2, False, -1), face(Z2, False, 1)
ROOMS = [
    ("workshop", "basement", (0.0, 0.0, 3.83, 3.16), (IN_W, IN_N, P4W, P35N)),
    ("laundry", "basement", (0.0, 3.28, 3.83, 8.34), (IN_W, P35S, P4W, IN_S)),
    ("boiler", "basement", (3.95, 0.0, 6.28, 1.98), (P4E, IN_N, P65W, P2N)),
    ("stair lobby", "basement", (3.95, 2.1, 6.28, 5.15), (P4E, P2S, P65W, NEW_STAIR_Z0)),
    ("garage", "basement", (6.4, 0.0, 10.1, 8.34), (P65E, IN_N, IN_E, IN_S)),
    ("kitchen", "ground", (0.0, 0.0, 3.83, 8.34), (IN_W, IN_N, P4W, IN_S)),
    ("hall", "ground", (3.95, 0.0, 6.28, 5.15), (P4E, IN_N, P65W, NEW_STAIR_Z0)),
    ("living", "ground", (6.4, 0.0, 10.1, 8.34), (P65E, IN_N, IN_E, IN_S)),
    ("office", "first", (0.0, 0.0, 3.83, 3.16), (IN_W, IN_N, P4W, P35N)),
    ("bedroom", "first", (0.0, 3.28, 3.83, 8.34), (IN_W, P35S, P4W, IN_S)),
    ("landing", "first", (3.95, 0.0, 6.28, 5.15), (P4E, IN_N, P65W, NEW_STAIR_Z0)),
    ("bathroom", "first", (6.4, 0.0, 10.1, 3.16), (P65E, IN_N, IN_E, P35N)),
    ("kids", "first", (6.4, 3.28, 10.1, 8.34), (P65E, P35S, IN_E, IN_S)),
    ("loft", "attic", (0.0, 0.0, 10.1, 8.34), (IN_W, IN_N, IN_E, IN_S)),
]

# --- Roof and attic (K11) --------------------------------------------------------------------
KNEE = 0.4
OLD_RIDGE_H = KNEE + 3.8 * math.tan(math.radians(40.0))   # over the attic floor (house/37)
OLD_HALF = 8.34 / 2
NEW_HALF = (IN_S - IN_N) / 2
NEW_RIDGE_H = KNEE + NEW_HALF * math.tan(math.radians(40.0))   # Q2354: 40 deg
OLD_PITCH = math.degrees(math.atan((OLD_RIDGE_H - KNEE) / OLD_HALF))
NEW_PITCH = math.degrees(math.atan((NEW_RIDGE_H - KNEE) / NEW_HALF))
DORMER_H = 2.2
OLD_DORMER = (6.89, 8.69)                   # its inside, x; cheeks 0.2 outside it
NEW_DORMER_CHEEKS = (7.0, 9.0)              # the cheeks' centre lines
NEW_DORMER = (NEW_DORMER_CHEEKS[0] + EXT / 2, NEW_DORMER_CHEEKS[1] - EXT / 2)
OLD_POSTS = [(3.74, 1.71), (8.56, 1.71), (2.64, 6.64), (9.22, 6.64)]
NEW_POSTS = [(3.75, 1.75), (8.75, 1.75), (2.75, 6.75), (9.25, 6.75)]


def fr(v: float) -> float:
    """An old inside-face number in the shared frame."""
    return v + FRAME


def new_stair():
    """The new U stair's numbers: the flights' x ranges, the landing's z, rise, going, pitch."""
    newel = (P4E + P65W) / 2
    west = (P4E, newel - PART / 2)
    east = (newel + PART / 2, P65W)
    land_z = IN_S - NEW_LANDING_D
    going = (land_z - NEW_STAIR_Z0) / 7
    rise = NEW_STOREY / STEPS
    return {"west": west, "east": east, "newel": newel, "land_z": land_z, "going": going, "rise": rise,
            "pitch": math.degrees(math.atan(rise / going))}


def old_stair():
    x0, z0, x1, z1 = OLD_STAIR
    mid = (x0 + x1) / 2
    land_z = z1 - OLD_LANDING_D
    going = (land_z - z0) / 7
    rise = OLD_STOREY / STEPS
    return {"west": (fr(x0), fr(mid - 0.06)), "east": (fr(mid + 0.06), fr(x1)), "newel": fr(mid),
            "land_z": fr(land_z), "going": going, "rise": rise, "pitch": math.degrees(math.atan(rise / going))}


def dormer_z(half: float, ridge_h: float, inner_s: float) -> float:
    """Where the dormer's flat ceiling meets the main roof."""
    tan = (ridge_h - KNEE) / half
    return inner_s - (DORMER_H - KNEE) / tan


# --- The rules (the plan's own checks) -----------------------------------------------------

def crossing(level: str, axis: str, line: float):
    """The walls that meet a wall (axis, line) on `level`: [(position along it, half thickness)]."""
    out = []
    other = "z" if axis == "x" else "x"
    for a, l, s0, s1 in NEW_PARTITIONS[level]:
        if a == other and s0 - 1e-6 <= line <= s1 + 1e-6:
            out.append((l, PART / 2))
    for name, (a, _, l) in LINES.items():
        if name.startswith("outer") and a == other:
            out.append((l, EXT / 2))
    return out


def check() -> list:
    """Every rule the plan keeps; returns the broken ones (empty when the plan holds)."""
    bad = []

    def on(v, step):
        return abs(v / step - round(v / step)) < 1e-6

    for name, (_, _, l) in LINES.items():
        if not on(l, 0.5):
            bad.append("%s: centre line %.2f is off the 0.5 m grid" % (name, l))
    if not on(NEW_STAIR_Z0, 0.5):
        bad.append("the stair's first riser is off the grid")
    openings = [(i, n, lv, a, l, (s0 + s1) / 2, s1 - s0, c) for i, n, lv, a, l, s0, s1, c in DOORS]
    for i, n, lv, side, s0, s1, _, _, _, c in WINDOWS:
        a, l = SIDE_LINE[side]
        openings.append((i, n, lv, a, l, (s0 + s1) / 2, s1 - s0, c))
        openings.append((i + " (grid width)", n, lv, a, l, (s0 + s1) / 2, rounded(s1 - s0), c))
    for i, n, lv, a, l, old_c, w, c in openings:
        if i in OFF_CENTRE:
            start = OFF_CENTRE[i]
            if not on(start, 0.5) or c - w / 2 < start + 0.05 or c + w / 2 > start + 1.5 - 0.05:
                bad.append("%s %s: not inside its off-centre piece from %.2f" % (i, n, start))
        elif not on(c, LATTICE):
            bad.append("%s %s: centre %.2f is off the %.2f m lattice" % (i, n, c, LATTICE))
        for pos, half in crossing(lv, a, l):
            gap = abs(c - pos) - w / 2 - half
            if gap < CASING - 1e-6:
                bad.append("%s %s: %.2f m from the wall at %.2f (casing needs %.2f)" % (i, n, gap, pos, CASING))
        move = c - fr(old_c)
        if abs(move) > 0.35:
            bad.append("%s %s moves %.2f m" % (i, n, move))
    # The stair: the doors at its side stop short of its first riser; the hatch too.
    for i, n, lv, a, l, s0, s1, c in DOORS:
        if a == "x" and l in (X4, X65) and c + DOOR_W / 2 + CASING > NEW_STAIR_Z0:
            bad.append("%s %s runs into the stair" % (i, n))
    if NEW_HATCH_Z[1] > NEW_STAIR_Z0 - 0.05:
        bad.append("the hatch runs into the attic flight's first step")
    for i, n, lv, a, l, s0, s1, c in DOORS:
        if lv == "first" and a == "x" and l == X4 and c + DOOR_W / 2 + CASING > NEW_HATCH_Z[0]:
            bad.append("%s %s runs into the elevator hatch" % (i, n))
    return bad


# --- The plan table --------------------------------------------------------------------------

def m(v: float) -> str:
    return ("%.2f" % v).rstrip("0").rstrip(".") if abs(v) > 1e-9 else "0"


def mv(v: float) -> str:
    if abs(v) < 0.005:
        return "0"
    return ("+" if v > 0 else "") + "%.2f" % v


def write_md(path: str) -> None:
    ns, os_ = new_stair(), old_stair()
    L = []
    w = L.append
    w("# The re-gridded plan of the old house")
    w("")
    w("house/02, K01-K02 (Q2343). Written by `tools/house_plan.py` from the numbers it holds: change them")
    w("there and run it again, never by hand. The old numbers are `reference/it-socks/tools/blender/make_house.py`")
    w("(v0.1.1). House/03 builds the house from the **new** column.")
    w("")
    w("**The frame.** x east, z south, y up, metres. The old script measures from the walls' inside faces;")
    w("here every old number is moved +0.1 m, so the old outer walls' centre lines sit on x 0 and z 0, where")
    w("the new ones are. *Move* is new minus old in that frame. The stills draw the old house in red over")
    w("the new one (`builds/review-house-02/`).")
    w("")
    w("**The rules the plan keeps** (checked by the script):")
    w("- Every wall's centre line is on a 0.5 m grid line (the kit's convention). Outer walls 0.2 m,")
    w("  partitions 0.12 m, as in the old house.")
    w("- An opening sits in the middle of a wall piece 0.5 m steps long, so its centre is on a 0.25 m")
    w("  lattice; its width is the old one (the piece is longer, the opening is not).")
    w("- An opening's edge stays at least a casing (0.07 m) clear of a wall that meets its wall, so the")
    w("  casing fits; where a T's 0.5 m arm would cover an opening the meeting wall butts into a plain")
    w("  wall piece instead (no T there).")
    w("- Heights over a floor are the old ones.")
    w("")
    w("## Footprint and storeys (K02)")
    w("")
    w("| | old | new | move |")
    w("|---|---|---|---|")
    w("| outer walls' centre lines, x by z | %s x %s | %s x %s | %s x %s |"
      % (m(10.3), m(8.54), m(X1), m(Z1), mv(X1 - 10.3), mv(Z1 - 8.54)))
    w("| outside, x by z | 10.5 x 8.74 | %s x %s | %s x %s |" % (m(X1 + EXT), m(Z1 + EXT), mv(X1 + EXT - 10.5), mv(Z1 + EXT - 8.74)))
    w("| inside, x by z | 10.1 x 8.34 | %s x %s | %s x %s |" % (m(IN_E - IN_W), m(IN_S - IN_N), mv(IN_E - IN_W - 10.1), mv(IN_S - IN_N - 8.34)))
    w("| storey, floor top to floor top | %s | %s | %s |" % (m(OLD_STOREY), m(NEW_STOREY), mv(NEW_STOREY - OLD_STOREY)))
    for lv, (oy, oh, ny, nh) in LEVELS.items():
        w("| %s floor top y | %s | %s | %s |" % (lv, m(oy), m(ny), mv(ny - oy)))
    for lv, (oy, oh, ny, nh) in LEVELS.items():
        if oh is None:
            continue
        w("| %s clear height (floor to ceiling) | %s | %s | %s |" % (lv, m(oh), m(nh), mv(nh - oh)))
    for lv, (oy, oh, ny, nh) in LEVELS.items():
        if oh is None:
            continue
        w("| %s ceiling tile under the next floor tile | %s | %s | %s |"
          % (lv, m(OLD_STOREY - oh - FLOOR_T), m(NEW_STOREY - nh - FLOOR_T), mv(NEW_STOREY - nh - OLD_STOREY + oh)))
    w("")
    w("The clear heights stay the old ones exactly; the extra 0.1 m of each storey goes into the ceiling")
    w("tile (0.2 m under the ground and basement ceilings, 0.3 m under the attic floor; house/01's tile is")
    w("0.1 m, which would give 2.8 m on every floor).")
    w("")
    w("## Wall centre lines")
    w("")
    w("| wall | old (inside faces) | old centre | new centre | move |")
    w("|---|---|---|---|---|")
    for name, (a, (f0, f1), l) in LINES.items():
        oc = fr((f0 + f1) / 2)
        w("| %s | %s %s..%s | %s | %s | %s |" % (name, a, m(f0), m(f1), m(oc), m(l), mv(l - oc)))
    w("| the stair's first riser (z) | 5.15 | %s | %s | %s |" % (m(fr(5.15)), m(NEW_STAIR_Z0), mv(NEW_STAIR_Z0 - fr(5.15))))
    w("")
    w("## Rooms (inside, wall face to wall face)")
    w("")
    w("| room | level | old x0..x1, z0..z1 | old size | new x0..x1, z0..z1 | new size | edges moved |")
    w("|---|---|---|---|---|---|---|")
    for name, lv, o, n in ROOMS:
        of = [fr(v) for v in o]
        moves = [n[i] - of[i] for i in range(4)]
        w("| %s | %s | %s..%s, %s..%s | %s x %s | %s..%s, %s..%s | %s x %s | %s |"
          % (name, lv, m(of[0]), m(of[2]), m(of[1]), m(of[3]), m(o[2] - o[0]), m(o[3] - o[1]),
             m(n[0]), m(n[2]), m(n[1]), m(n[3]), m(n[2] - n[0]), m(n[3] - n[1]),
             " ".join(mv(v) for v in moves)))
    w("")
    w("## Doorways and outer doors (K08, K09)")
    w("")
    w("All 0.9 x 2.1 m but the garage door (2.4 x 2.1). *Along* is z on an x wall, x on a z wall.")
    w("")
    w("| id | name | level | wall | old along | old centre | new centre | new along | move | piece |")
    w("|---|---|---|---|---|---|---|---|---|---|")
    for i, n, lv, a, l, s0, s1, c in DOORS:
        wd = s1 - s0
        if i not in OFF_CENTRE:
            piece = piece_len(c, wd)
        else:
            st = OFF_CENTRE[i]
            piece = "1.5 m (%s..%s), off-centre: the opening %s..%s along it" % (m(st), m(st + 1.5), m(c - wd / 2 - st), m(c + wd / 2 - st))
        w("| %s | %s | %s | %s %s | %s..%s | %s | %s | %s..%s | %s | %s |"
          % (i, n, lv, a, m(l), m(fr(s0)), m(fr(s1)), m(fr((s0 + s1) / 2)), m(c), m(c - wd / 2), m(c + wd / 2),
             mv(c - fr((s0 + s1) / 2)), piece))
    w("")
    w("D2 and D8 keep their old place by the z3.5 partition (Q2351): the old 0.1 m from its face. The old")
    w("place itself (3.48..4.38) would cut into the partition, which moved 0.18 m south.")
    w("")
    w("## Windows (K06)")
    w("")
    w("Sill and head (over the floor) are the old ones. The stair window's are over the half landing")
    w("(old landing 1.45, new 1.5: 0.9..2.0 over it, so 2.4..3.5 over the ground floor, across the storey")
    w("line). The kit has both sets (Q2355): the old widths, and the widths rounded to 0.5 m steps")
    w("(*grid width*), each centred where the table says; the designer chooses on the comparison still.")
    w("")
    w("| id | name | level | wall | width | grid width | sill..head | old along | new along | move | piece (old width; grid width) |")
    w("|---|---|---|---|---|---|---|---|---|---|---|")
    for i, n, lv, side, s0, s1, sill, head, frosted, c in WINDOWS:
        wd = s1 - s0
        sh = "%s..%s" % (m(sill), m(head))
        if n == "StairGround":
            sh = "2.4..3.5 (old 2.35..3.45)"
        w("| %s | %s%s | %s | %s | %s | %s | %s | %s..%s | %s..%s | %s | %s; %s |"
          % (i, n, " (frosted)" if frosted else "", lv, side, m(wd), m(rounded(wd)), sh, m(fr(s0)), m(fr(s1)),
             m(c - wd / 2), m(c + wd / 2), mv(c - fr((s0 + s1) / 2)), piece_len(c, wd), piece_len(c, rounded(wd))))
    w("")
    w("The basement windows look into the light wells outside (`make_exterior.py` WELLS: 0.9 m out from")
    w("the wall, 0.25 m wider each side); the wells move with their windows.")
    w("")
    w("## The U stair (K10)")
    w("")
    w("| | old | new | move |")
    w("|---|---|---|---|")
    w("| stair well x (between the partitions) | %s..%s | %s..%s | %s %s |"
      % (m(fr(OLD_STAIR[0])), m(fr(OLD_STAIR[2])), m(P4E), m(P65W), mv(P4E - fr(OLD_STAIR[0])), mv(P65W - fr(OLD_STAIR[2]))))
    w("| first riser z, landing z0..z1 | %s, %s..%s | %s, %s..%s | %s, %s |"
      % (m(fr(OLD_STAIR[1])), m(os_["land_z"]), m(fr(OLD_STAIR[3])), m(NEW_STAIR_Z0), m(ns["land_z"]), m(IN_S),
         mv(NEW_STAIR_Z0 - fr(OLD_STAIR[1])), mv(ns["land_z"] - os_["land_z"])))
    w("| west flight x (up south to the landing) | %s..%s | %s..%s | |" % (m(os_["west"][0]), m(os_["west"][1]), m(ns["west"][0]), m(ns["west"][1])))
    w("| east flight x (up north to the next floor) | %s..%s | %s..%s | |" % (m(os_["east"][0]), m(os_["east"][1]), m(ns["east"][0]), m(ns["east"][1])))
    w("| flight width | %s | %s | %s |" % (m(os_["west"][1] - os_["west"][0]), m(ns["west"][1] - ns["west"][0]),
                                            mv(ns["west"][1] - ns["west"][0] - os_["west"][1] + os_["west"][0])))
    w("| newel wall centre x, 0.12 thick | %s | %s | %s |" % (m(os_["newel"]), m(ns["newel"]), mv(ns["newel"] - os_["newel"])))
    w("| risers a storey, rise | 16, %.4f | 16, %.4f | |" % (os_["rise"], ns["rise"]))
    w("| goings a flight, going | 7, %.3f | 7, %.3f | %s |" % (os_["going"], ns["going"], mv(ns["going"] - os_["going"])))
    w("| pitch | %.1f deg | %.1f deg | %+.1f deg |" % (os_["pitch"], ns["pitch"], ns["pitch"] - os_["pitch"]))
    w("| half landing height over the floor | %s | %s | %s |" % (m(OLD_STOREY / 2), m(NEW_STOREY / 2), mv((NEW_STOREY - OLD_STOREY) / 2)))
    w("")
    w("The first riser moved south (+0.25): the elevator shaft's south side lines up with it as in the old")
    w("house, and on the first floor the bedroom doorway (D8), the hatch and the attic flight's first step")
    w("follow each other along the x4 partition (with the riser at z 5.0 there would be 0.82 m for the")
    w("0.9 m doorway). The half landing is 0.9 m deep, so the flights are 33.3 deg (Q2350).")
    w("")
    w("## The elevator shaft, the hatches (K09)")
    w("")
    w("| | old | new | move |")
    w("|---|---|---|---|")
    w("| shaft inside x0..x1, z0..z1 (0.7 x 0.7, through every slab above the basement floor) | %s..%s, %s..%s | %s..%s, %s..%s | %s, %s |"
      % (m(fr(OLD_SHAFT[0])), m(fr(OLD_SHAFT[2])), m(fr(OLD_SHAFT[1])), m(fr(OLD_SHAFT[3])),
         m(NEW_SHAFT[0]), m(NEW_SHAFT[2]), m(NEW_SHAFT[1]), m(NEW_SHAFT[3]),
         mv(NEW_SHAFT[0] - fr(OLD_SHAFT[0])), mv(NEW_SHAFT[1] - fr(OLD_SHAFT[1]))))
    w("| first floor hatch through x4, z (sill 0.8, 0.58 high) | %s..%s | %s..%s | %s |"
      % (m(fr(OLD_HATCH_Z[0])), m(fr(OLD_HATCH_Z[1])), m(NEW_HATCH_Z[0]), m(NEW_HATCH_Z[1]), mv(NEW_HATCH_Z[0] - fr(OLD_HATCH_Z[0]))))
    gc = ((OLD_GROTTO[0] + OLD_GROTTO[2]) / 2, (OLD_GROTTO[1] + OLD_GROTTO[3]) / 2)
    w("| the Cellar hatch in the workshop floor, centre (0.75 square) | %s, %s | %s, %s | %s, %s |"
      % (m(fr(gc[0])), m(fr(gc[1])), m(NEW_GROTTO_CENTRE[0]), m(NEW_GROTTO_CENTRE[1]),
         mv(NEW_GROTTO_CENTRE[0] - fr(gc[0])), mv(NEW_GROTTO_CENTRE[1] - fr(gc[1]))))
    w("")
    w("The shaft and the Cellar hatch are not on the 0.5 m tile grid (0.7 and 0.75 m), so the kit has tiles")
    w("with the hole in them: the shaft's a 1 x 1 m floor and ceiling tile (x 3..4, z 4.5..5.5); the")
    w("Cellar hatch, 0.75 m square round x 2.75 z 1.75, needs a 1.5 x 1.5 m floor tile (x 2..3.5, z 1..2.5)")
    w("with it in the middle, as a 1 m tile cannot hold it there.")
    w("")
    w("## Roof and attic (K11)")
    w("")
    odz = fr(dormer_z(OLD_HALF, OLD_RIDGE_H, 8.34))
    ndz = dormer_z(NEW_HALF, NEW_RIDGE_H, IN_S)
    w("| | old | new | move |")
    w("|---|---|---|---|")
    w("| knee wall over the attic floor | 0.4 | 0.4 | 0 |")
    w("| ridge over the attic floor | %.2f | %.2f | %+.2f |" % (OLD_RIDGE_H, NEW_RIDGE_H, NEW_RIDGE_H - OLD_RIDGE_H))
    w("| ridge line z | %s | %s | %s |" % (m(fr(OLD_HALF)), m(IN_N + NEW_HALF), mv(IN_N + NEW_HALF - fr(OLD_HALF))))
    w("| ridge y | %.2f | %.2f | %+.2f |" % (5.8 + OLD_RIDGE_H, 6.0 + NEW_RIDGE_H, 0.2 + NEW_RIDGE_H - OLD_RIDGE_H))
    w("| pitch | %.1f deg | %.1f deg | %+.1f deg |" % (OLD_PITCH, NEW_PITCH, NEW_PITCH - OLD_PITCH))
    w("| dormer inside x | %s..%s | %s..%s | %s |" % (m(fr(OLD_DORMER[0])), m(fr(OLD_DORMER[1])), m(NEW_DORMER[0]), m(NEW_DORMER[1]), mv(NEW_DORMER[0] - fr(OLD_DORMER[0]))))
    w("| dormer cheeks' centre lines x (0.2 thick) | %s, %s | %s, %s | %s |" % (m(fr(OLD_DORMER[0]) - 0.1), m(fr(OLD_DORMER[1]) + 0.1),
                                                                            m(NEW_DORMER_CHEEKS[0]), m(NEW_DORMER_CHEEKS[1]), mv(NEW_DORMER_CHEEKS[0] - fr(OLD_DORMER[0]) + 0.1)))
    w("| dormer flat ceiling over the attic floor | 2.2 | 2.2 | 0 |")
    w("| dormer ceiling meets the roof at z | %.2f | %.2f | %+.2f |" % (odz, ndz, ndz - odz))
    for (ox, oz), (nx, nz) in zip(OLD_POSTS, NEW_POSTS):
        w("| roof post (0.16 square) at x, z | %s, %s | %s, %s | %s, %s |" % (m(fr(ox)), m(fr(oz)), m(nx), m(nz), mv(nx - fr(ox)), mv(nz - fr(oz))))
    w("")
    w("The roof is 40 deg (Q2354): the ridge is %.2f m over the attic floor, %.2f m higher than the old" % (NEW_RIDGE_H, NEW_RIDGE_H - OLD_RIDGE_H))
    w("one, and the dormer reaches further into the roof. The gable windows (W20, W21) are on the 0.25 m")
    w("lattice, not centred on the ridge, as the old ones were not.")
    w("")
    w("## The kit's pieces for this plan")
    w("")
    doors = {}
    for i, n, lv, a, l, s0, s1, c in DOORS:
        key = "off-centre 1.5 m" if i in OFF_CENTRE else piece_len(c, s1 - s0).split(" (")[0]
        doors.setdefault((round(s1 - s0, 2), key), []).append(i)
    w("- Door pieces:")
    for (wd, pl), ids in sorted(doors.items()):
        w("  - %s m wide in a %s piece: %s" % (m(wd), pl, ", ".join(ids)))
    sets = window_sets()
    for kind, title in (("old", "old widths"), ("grid", "widths rounded to 0.5 m")):
        rows = [r for r in sets if r[0] == kind]
        w("- Window pieces, %s (%d):" % (title, len(rows)))
        for _, wd, sill, head, frosted, stair, pl, ids in rows:
            w("  - %s m wide, sill..head %s..%s%s%s, in a %s m piece: %s"
              % (m(wd), m(sill), m(head), ", frosted" if frosted else "", ", two storeys high" if stair else "", m(pl), ", ".join(ids)))
    w("- Floor and ceiling tiles with the shaft's hole (1 m), a floor tile with the Cellar hatch (1.5 m).")
    w("- The U stair per storey (well 2.38 x 2.9 m inside), the attic's balustrade round the void.")
    w("")
    w("## Answers")
    w("")
    w("- The stair: a 0.9 m half landing, 33.3 deg (Q2350).")
    w("- D2 and D8: an off-centre door piece keeps both doorways in their old places (Q2351).")
    w("- The width: outer wall centre lines 10.5 m apart (Q2352).")
    w("- Storeys 3.0 m, the old clear heights 2.7 / 2.7 / 2.6 m kept through thicker ceiling tiles (Q2353).")
    w("- The roof: 40 deg, the ridge 3.88 m over the attic floor (Q2354).")
    w("- Openings: both sets, old widths and widths rounded to 0.5 m; the designer compares (Q2355).")
    w("- The Cellar hatch and the tiles with a hole are in (the designer, 2026-11-21).")
    w("")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(L))


def rounded(width: float) -> float:
    """A window's width rounded to 0.5 m steps (the second set, Q2355)."""
    return max(0.5, round(width / 0.5) * 0.5)


def window_sets() -> list:
    """Both window sets as the kit builds them: (set, width, sill, head, frosted, stair, piece length,
    the ids). The stair window spans two storeys."""
    out = {}
    for kind in ("old", "grid"):
        for i, n, lv, side, s0, s1, sill, head, frosted, c in WINDOWS:
            wd = round(s1 - s0, 2) if kind == "old" else rounded(s1 - s0)
            stair = n == "StairGround"
            if stair:
                sill, head = 2.4, 3.5
            pl = float(piece_len(c, wd).split(" ")[0])
            out.setdefault((kind, wd, sill, head, frosted, stair, pl), []).append(i)
    return [k + (v,) for k, v in sorted(out.items())]


def piece_len(c: float, width: float) -> str:
    """The shortest wall piece of 0.5 m steps that holds the opening centred, with 0.05 m jambs, and
    whose ends land on the grid."""
    n = 1
    while n < 40:
        length = n * 0.5
        start = c - length / 2
        if length >= width + 0.1 - 1e-6 and abs(start / 0.5 - round(start / 0.5)) < 1e-6:
            return "%s m (%s..%s)" % (m(length), m(start), m(start + length))
        n += 1
    raise ValueError("no grid piece holds an opening %.2f wide centred on %.2f" % (width, c))


# --- The stills ------------------------------------------------------------------------------

S = 100                      # pixels a metre
MARGIN = 110
OLD_C = (208, 52, 44)
NEW_WALL = (70, 70, 74)
ROOM_FILL = (246, 242, 233)
GRID_C = (222, 222, 226)
DOOR_C = (31, 111, 178)
WIN_C = (24, 140, 128)
TEXT = (30, 30, 34)


def font(size: int):
    return ImageFont.load_default(size=size)


class Plan:
    def __init__(self, w_m: float, h_m: float, x0: float, z0: float, title: str, extra_h: int = 170):
        self.x0, self.z0 = x0, z0
        self.img = Image.new("RGB", (int(w_m * S) + 2 * MARGIN, int(h_m * S) + 80 + extra_h), "white")
        self.d = ImageDraw.Draw(self.img)
        self.d.text((MARGIN, 24), title, fill=TEXT, font=font(30))

    def p(self, x: float, z: float):
        return (MARGIN + (x - self.x0) * S, 80 + (z - self.z0) * S)

    def rect(self, x0, z0, x1, z1, fill=None, outline=None, width=1):
        a, b = self.p(min(x0, x1), min(z0, z1)), self.p(max(x0, x1), max(z0, z1))
        self.d.rectangle([a, b], fill=fill, outline=outline, width=width)

    def line(self, x0, z0, x1, z1, fill, width=2):
        self.d.line([self.p(x0, z0), self.p(x1, z1)], fill=fill, width=width)

    def text(self, x, z, s, fill=TEXT, size=17, anchor="mm"):
        self.d.text(self.p(x, z), s, fill=fill, font=font(size), anchor=anchor)


def wall_rect(axis: str, line: float, a: float, b: float, t: float):
    if axis == "x":
        return (line - t / 2, a, line + t / 2, b)
    return (a, line - t / 2, b, line + t / 2)


def draw_floor(level: str, path: str) -> None:
    oy, oh, ny, nh = LEVELS[level]
    title = "%s floor: new (grey walls on the 0.5 m grid) over old (red)" % level.capitalize()
    pl = Plan(12.0, 9.6, -0.55, -0.55, title)
    # The grid.
    g = -0.5
    while g <= 11.0 + 1e-6:
        pl.line(g, -0.5, g, 9.0, GRID_C, 1)
        g += 0.5
    g = -0.5
    while g <= 9.0 + 1e-6:
        pl.line(-0.5, g, 11.0, g, GRID_C, 1)
        g += 0.5
    for v in range(0, 11):
        pl.text(v, 8.92, str(v), fill=(150, 150, 150), size=14)
    for v in range(0, 9):
        pl.text(11.2, v, str(v), fill=(150, 150, 150), size=14)
    # New rooms.
    for name, lv, o, n in ROOMS:
        if lv == level:
            pl.rect(*n, fill=ROOM_FILL)
    ns = new_stair()
    stair_levels = ("basement", "ground", "first")
    if level in stair_levels:
        pl.rect(P4E, NEW_STAIR_Z0, P65W, IN_S, fill=(236, 226, 206))
        go = ns["going"]
        for k in range(8):
            z = NEW_STAIR_Z0 + k * go
            pl.line(ns["west"][0], z, ns["west"][1], z, (170, 150, 120), 1)
            pl.line(ns["east"][0], z, ns["east"][1], z, (170, 150, 120), 1)
        pl.line(P4E, ns["land_z"], P65W, ns["land_z"], (150, 130, 100), 2)
        pl.rect(ns["newel"] - PART / 2, NEW_STAIR_Z0, ns["newel"] + PART / 2, ns["land_z"], fill=NEW_WALL)
        pl.text((P4E + ns["newel"]) / 2, NEW_STAIR_Z0 + 1.0, "up", size=15)
        pl.text((P4E + P65W) / 2, (ns["land_z"] + IN_S) / 2, "landing +1.5", size=15)
    if level == "attic":
        pl.rect(P4E, NEW_STAIR_Z0, P65W, IN_S, fill=(236, 226, 206), outline=(150, 130, 100), width=3)
        pl.text((P4E + P65W) / 2, 7.0, "stair void", size=15)
        # Knee walls and the ridge line, the dormer.
        pl.line(IN_W, IN_N + NEW_HALF, IN_E, IN_N + NEW_HALF, (120, 90, 60), 2)
        pl.text(1.5, IN_N + NEW_HALF - 0.2, "ridge", size=15)
        pl.rect(NEW_DORMER[0], dormer_z(NEW_HALF, NEW_RIDGE_H, IN_S), NEW_DORMER[1], IN_S, fill=(232, 236, 240))
        for c in NEW_DORMER_CHEEKS:
            pl.rect(*wall_rect("x", c, dormer_z(NEW_HALF, NEW_RIDGE_H, IN_S), Z1, EXT), fill=NEW_WALL)
        pl.text(8.0, 7.0, "dormer", size=15)
        for x, z in NEW_POSTS:
            pl.rect(x - 0.08, z - 0.08, x + 0.08, z + 0.08, fill=NEW_WALL)
    # Shaft (all levels; its slab hole above the basement floor).
    pl.rect(*NEW_SHAFT, fill=(205, 210, 215), outline=NEW_WALL, width=2)
    pl.text((NEW_SHAFT[0] + NEW_SHAFT[2]) / 2, (NEW_SHAFT[1] + NEW_SHAFT[3]) / 2, "lift", size=14)
    if level == "basement":
        gx, gz = NEW_GROTTO_CENTRE
        pl.rect(gx - 0.375, gz - 0.375, gx + 0.375, gz + 0.375, fill=(215, 205, 190), outline=NEW_WALL, width=2)
        pl.text(gx, gz, "hatch", size=14)
    # New walls.
    walls = [("x", X0, -EXT / 2, Z1 + EXT / 2, EXT), ("x", X1, -EXT / 2, Z1 + EXT / 2, EXT),
             ("z", Z0, -EXT / 2, X1 + EXT / 2, EXT), ("z", Z1, -EXT / 2, X1 + EXT / 2, EXT)]
    walls += [(a, l, s0, s1, PART) for a, l, s0, s1 in NEW_PARTITIONS[level]]
    for a, l, s0, s1, t in walls:
        pl.rect(*wall_rect(a, l, s0, s1, t), fill=NEW_WALL)
    # New openings: cut out of the wall, coloured, labelled.
    for i, n, lv, a, l, s0, s1, c in DOORS:
        if lv != level:
            continue
        wd = s1 - s0
        t = EXT if l in (X0, X1, Z0, Z1) and n in ("FrontDoor", "GarageDoor") else PART
        r = wall_rect(a, l, c - wd / 2, c + wd / 2, t + 0.02)
        pl.rect(*r, fill="white", outline=DOOR_C, width=3)
        lx, lz = ((l + 0.38, c) if a == "x" else (c, l + (0.32 if l != Z0 else -0.32)))
        if n in ("FrontDoor", "GarageDoor"):
            lz = l - 0.3
        pl.text(lx, lz, i, fill=DOOR_C, size=17)
    for i, n, lv, side, s0, s1, sill, head, frosted, c in WINDOWS:
        if lv != level:
            continue
        a, l = SIDE_LINE[side]
        wd = s1 - s0
        r = wall_rect(a, l, c - wd / 2, c + wd / 2, EXT + 0.02)
        pl.rect(*r, fill=(200, 236, 230), outline=WIN_C, width=3)
        off = {"N": (0, -0.32), "S": (0, 0.32), "W": (-0.36, 0), "E": (0.36, 0)}[side]
        lx, lz = (c, l) if a == "z" else (l, c)
        pl.text(lx + off[0], lz + off[1], i, fill=WIN_C, size=17)
    # Room labels.
    for name, lv, o, n in ROOMS:
        if lv != level:
            continue
        cx, cz = (n[0] + n[2]) / 2, (n[1] + n[3]) / 2
        if name == "loft":
            cx, cz = 2.2, 5.6
        if name in ("hall", "landing", "stair lobby"):
            cz = (n[1] + n[3]) / 2 - 0.6
        if name == "workshop":
            cz += 0.75
        pl.text(cx, cz - 0.2, name, size=20)
        pl.text(cx, cz + 0.08, "%s x %s" % (m(n[2] - n[0]), m(n[3] - n[1])), size=15)
        pl.text(cx, cz + 0.32, "old %s x %s" % (m(o[2] - o[0]), m(o[3] - o[1])), fill=OLD_C, size=15)
    # The old house, framed, in red outlines: rooms' inside faces, its openings, stair, shaft.
    for name, lv, o, n in ROOMS:
        if lv == level:
            pl.rect(fr(o[0]), fr(o[1]), fr(o[2]), fr(o[3]), outline=OLD_C, width=2)
    pl.rect(-0.1, -0.1, 10.4, 8.64, outline=OLD_C, width=2)          # the old outside faces
    os_ = old_stair()
    if level in stair_levels:
        pl.rect(fr(OLD_STAIR[0]), fr(OLD_STAIR[1]), fr(OLD_STAIR[2]), fr(OLD_STAIR[3]), outline=OLD_C, width=2)
        pl.line(fr(OLD_STAIR[0]), os_["land_z"], fr(OLD_STAIR[2]), os_["land_z"], OLD_C, 2)
        pl.rect(os_["newel"] - 0.06, fr(OLD_STAIR[1]), os_["newel"] + 0.06, os_["land_z"], outline=OLD_C, width=2)
    pl.rect(fr(OLD_SHAFT[0]), fr(OLD_SHAFT[1]), fr(OLD_SHAFT[2]), fr(OLD_SHAFT[3]), outline=OLD_C, width=2)
    if level == "basement":
        pl.rect(*[fr(v) for v in OLD_GROTTO], outline=OLD_C, width=2)
    if level == "attic":
        pl.line(fr(0), fr(OLD_HALF), fr(10.1), fr(OLD_HALF), OLD_C, 2)
        pl.rect(fr(OLD_DORMER[0]), fr(dormer_z(OLD_HALF, OLD_RIDGE_H, 8.34)), fr(OLD_DORMER[1]), fr(8.34), outline=OLD_C, width=2)
        for x, z in OLD_POSTS:
            pl.rect(fr(x) - 0.08, fr(z) - 0.08, fr(x) + 0.08, fr(z) + 0.08, outline=OLD_C, width=2)
    for i, n, lv, a, l, s0, s1, c in DOORS:
        if lv == level:
            old_opening(pl, a, l, fr(s0), fr(s1), n in ("FrontDoor", "GarageDoor"))
    for i, n, lv, side, s0, s1, sill, head, frosted, c in WINDOWS:
        if lv == level:
            a, l = SIDE_LINE[side]
            old_opening(pl, a, l, fr(s0), fr(s1), True)
    if level == "first":
        pl.rect(P4W, NEW_HATCH_Z[0], P4E, NEW_HATCH_Z[1], fill=(205, 210, 215), outline=DOOR_C, width=2)
        pl.text(P4E + 0.32, (NEW_HATCH_Z[0] + NEW_HATCH_Z[1]) / 2, "hatch", fill=DOOR_C, size=13)
        hz = (fr(OLD_HATCH_Z[0]), fr(OLD_HATCH_Z[1]))
        pl.line(fr(3.95) + 0.03, hz[0], fr(3.95) + 0.03, hz[1], OLD_C, 4)
    # Legend.
    y = pl.p(0, 9.25)[1]
    lg = [
        (NEW_WALL, "new walls: centre lines on grid lines; outer 0.2 m, partitions 0.12 m"),
        (OLD_C, "old house (v0.1.1): rooms' inside faces, outside faces, openings (bars), shifted +0.1 m"),
        (DOOR_C, "new doorways D1-D12 (0.9 m; garage 2.4 m)"),
        (WIN_C, "new windows W1-W22 (old widths)"),
    ]
    for k, (c, s) in enumerate(lg):
        yy = y + 8 + k * 30
        pl.d.rectangle([MARGIN, yy, MARGIN + 36, yy + 16], fill=c)
        pl.d.text((MARGIN + 50, yy - 2), s, fill=TEXT, font=font(18))
    stamp = "floor top y %s (old %s), clear height %s (old %s); grid 0.5 m; plan: docs/architecture/house-kit-plan.md" % (
        m(ny), m(oy), m(nh) if nh else "to the roof", m(oh) if oh else "to the roof")
    pl.d.text((MARGIN, y + 8 + 4 * 30), stamp, fill=(90, 90, 90), font=font(16))
    pl.img.save(path)


def old_opening(pl: Plan, axis: str, line: float, a: float, b: float, outer: bool) -> None:
    """An old opening: a thick red bar along the old wall's inside face."""
    if axis == "x":
        # The old inside face: for an outer wall the inside of the old wall; for a partition its centre.
        x = line + (0.1 if line == X0 else -0.1 if line == X1 else 0.0)
        if line == X1:
            x = 10.2
        pl.line(x, a, x, b, OLD_C, 5)
    else:
        z = line + (0.1 if line == Z0 else 0.0)
        if line == Z1:
            z = 8.44
        if not outer and line == Z2:
            z = fr(2.04)
        pl.line(a, z, b, z, OLD_C, 5)


def draw_section(path: str) -> None:
    """A north-south section through the hall and the stair (x about 5): the storeys, the
    ceilings, the roof, old over new; the dormer's outline from x 8."""
    pl = Plan(9.6, 13.9, -0.55, -10.0, "Section north to south through the hall and the stair: new over old (red)", 130)

    def P(z, y):
        return pl.p(z, -y)

    def rect(z0, y0, z1, y1, **kw):
        pl.d.rectangle([P(min(z0, z1), max(y0, y1)), P(max(z0, z1), min(y0, y1))], **kw)

    def line(z0, y0, z1, y1, fill, width=2):
        pl.d.line([P(z0, y0), P(z1, y1)], fill=fill, width=width)

    def text(z, y, s, fill=TEXT, size=16, anchor="mm"):
        pl.d.text(P(z, y), s, fill=fill, font=font(size), anchor=anchor)

    yy = -3.5
    while yy <= 10.0 + 1e-6:
        line(-0.5, yy, 9.0, yy, GRID_C, 1)
        yy += 0.5
    zz = -0.5
    while zz <= 9.0 + 1e-6:
        line(zz, -3.5, zz, 10.0, GRID_C, 1)
        zz += 0.5
    # New: outer walls, slabs (floor tile + ceiling tile), roof.
    ny_att = LEVELS["attic"][2]
    knee_y = ny_att + KNEE
    rect(-EXT / 2, -3.1, EXT / 2, knee_y, fill=NEW_WALL)
    rect(Z1 - EXT / 2, -3.1, Z1 + EXT / 2, knee_y, fill=NEW_WALL)
    for lv, (oy, oh, ny, nh) in LEVELS.items():
        if lv == "basement":
            rect(-EXT / 2, ny - FLOOR_T, Z1 + EXT / 2, ny, fill=NEW_WALL)
        elif lv in ("ground", "first", "attic"):
            below = {"ground": "basement", "first": "ground", "attic": "first"}[lv]
            ceil = LEVELS[below][2] + LEVELS[below][3]
            for z0, z1 in ((IN_N, NEW_STAIR_Z0), ):
                rect(z0, ny - FLOOR_T, z1, ny, fill=NEW_WALL)
                rect(z0, ceil, z1, ny - FLOOR_T, fill=(150, 150, 156))
        if nh:
            text(2.0, ny + nh / 2, "%s: clear %s (old %s)" % (lv, m(nh), m(oh)), size=17)
            line(2.0, ny + 0.05, 2.0, ny + nh - 0.05, (90, 90, 90), 1)
        text(-0.2, ny, "%s" % m(ny), size=14, anchor="rm")
    # The new stair, west flights (solid) and landings.
    ns = new_stair()
    for lv in ("basement", "ground", "first"):
        ny = LEVELS[lv][2]
        land = ny + NEW_STOREY / 2
        line(NEW_STAIR_Z0, ny, ns["land_z"], land, (150, 120, 80), 4)
        rect(ns["land_z"], land - 0.2, IN_S, land, fill=(150, 120, 80))
        line(ns["land_z"], land, NEW_STAIR_Z0, ny + NEW_STOREY, (190, 165, 120), 2)
    # Roof (new): underside from the knee over each inner face up to the ridge.
    rz = IN_N + NEW_HALF
    ry = ny_att + NEW_RIDGE_H
    line(IN_N, knee_y, rz, ry, NEW_WALL, 6)
    line(IN_S, knee_y, rz, ry, NEW_WALL, 6)
    dz = dormer_z(NEW_HALF, NEW_RIDGE_H, IN_S)
    line(dz, ny_att + DORMER_H, IN_S, ny_att + DORMER_H, (120, 130, 140), 3)
    line(IN_S, knee_y, IN_S, ny_att + DORMER_H, (120, 130, 140), 3)
    text((dz + IN_S) / 2, ny_att + DORMER_H + 0.18, "dormer ceiling 2.2 (at x 7-9)", fill=(100, 110, 120), size=14)
    text(rz, ry + 0.3, "ridge %.2f over the attic floor, pitch %.1f deg (old %.1f)" % (NEW_RIDGE_H, NEW_PITCH, OLD_PITCH), size=16)
    # Old, framed, in red: floor tops, ceilings, outside faces, roof, landings.
    old_att = LEVELS["attic"][0]
    o_knee = old_att + KNEE
    for z in (-0.1, 0.1, 8.44, 8.64):
        line(z, -3.0, z, o_knee, OLD_C, 2)
    for lv, (oy, oh, ny, nh) in LEVELS.items():
        line(0.1, oy, fr(OLD_STAIR[1]), oy, OLD_C, 2)
        line(0.1, oy - FLOOR_T, fr(OLD_STAIR[1]), oy - FLOOR_T, OLD_C, 1)
        if oh:
            line(0.1, oy + oh, fr(OLD_STAIR[1]), oy + oh, OLD_C, 2)
    os_ = old_stair()
    for lv in ("basement", "ground", "first"):
        oy = LEVELS[lv][0]
        land = oy + OLD_STOREY / 2
        line(fr(OLD_STAIR[1]), oy, os_["land_z"], land, OLD_C, 2)
        line(os_["land_z"], land, fr(8.34), land, OLD_C, 2)
    orz, ory = fr(OLD_HALF), old_att + OLD_RIDGE_H
    line(0.1, o_knee, orz, ory, OLD_C, 2)
    line(fr(8.34), o_knee, orz, ory, OLD_C, 2)
    odz = fr(dormer_z(OLD_HALF, OLD_RIDGE_H, 8.34))
    line(odz, old_att + DORMER_H, fr(8.34), old_att + DORMER_H, OLD_C, 2)
    # Windows on the south wall in section: the stair window (new and old).
    rect(Z1 - 0.12, 2.4, Z1 + 0.12, 3.5, outline=WIN_C, width=3)
    line(8.44, 2.35, 8.44, 3.45, OLD_C, 5)
    text(Z1 + 0.25, 2.95, "W12", fill=WIN_C, size=15, anchor="lm")
    text(-0.35, -3.3, "N", size=18)
    text(8.85, -3.3, "S", size=18)
    pl.d.text(P(0.5, -3.2), "z: north (left) to south (right); y up; grid 0.5 m", fill=(90, 90, 90), font=font(15))
    y = P(0, -3.55)[1]
    lg = [(NEW_WALL, "new: outer walls, floor tiles (0.1) over ceiling tiles (grey), roof underside"),
          (OLD_C, "old (v0.1.1): floor tops and ceilings, outside and inside faces, roof underside, landings"),
          ((150, 120, 80), "new west flight and half landing (east flight lighter)")]
    for k, (c, s) in enumerate(lg):
        yk = y + 10 + k * 30
        pl.d.rectangle([MARGIN, yk, MARGIN + 36, yk + 16], fill=c)
        pl.d.text((MARGIN + 50, yk - 2), s, fill=TEXT, font=font(18))
    pl.img.save(path)


def draw_openings(path: str) -> None:
    """Two walls, each once with each window set, the old windows in red over each (Q2355): the
    ground floor's south wall (seen from outside, west left) and the first floor's north wall (the
    one that changes most; seen from inside, west left)."""
    S2 = 100
    panel_h = int(4.6 * S2)
    walls = (("ground", "S", "Ground floor, south wall, from outside"), ("first", "N", "First floor, north wall, from inside"))
    panels = [(lv, side, t, kind, kt) for lv, side, t in walls
              for kind, kt in (("old", "A: old widths"), ("grid", "B: widths rounded to 0.5 m"))]
    img = Image.new("RGB", (int(11.0 * S2) + 2 * MARGIN, 90 + len(panels) * panel_h + 90), "white")
    d = ImageDraw.Draw(img)
    d.text((MARGIN, 24), "The two window sets on two walls: old (red) over new", fill=TEXT, font=font(30))
    for k, (lv, side, wall_title, kind, title) in enumerate(panels):
        top = 90 + k * panel_h

        def P(x, y):
            return (MARGIN + (x + 0.25) * S2, top + 36 + (3.9 - y) * S2)

        d.text((MARGIN, top), "%s. %s" % (wall_title, title), fill=TEXT, font=font(22))
        d.rectangle([P(0, 3.8), P(10.5, 0)], fill=(240, 228, 200))
        g = 0.0
        while g <= 10.5 + 1e-6:
            d.line([P(g, 0), P(g, 3.8)], fill=GRID_C, width=1)
            d.text(P(g, -0.08), m(g), fill=(150, 150, 150), font=font(13), anchor="mt")
            g += 0.5
        ny = LEVELS[lv][3]
        d.rectangle([P(0, 3.0), P(10.5, ny)], fill=(200, 200, 204))        # the slab over the storey
        for x in (X4, X65):
            d.rectangle([P(x - PART / 2, 3.8), P(x + PART / 2, 0)], fill=NEW_WALL)
        if side == "S":
            d.rectangle([P(P4E, 3.8), P(P65W, 0)], fill=(236, 226, 206))   # the stair well: no slab
        for i, n, wl, ws, s0, s1, sill, head, frosted, c in WINDOWS:
            if wl != lv or ws != side:
                continue
            wd = round(s1 - s0, 2) if kind == "old" else rounded(s1 - s0)
            if n == "StairGround":
                sill, head = 2.4, 3.5
            fill = (225, 232, 234) if frosted else (200, 236, 230)
            d.rectangle([P(c - wd / 2, head), P(c + wd / 2, sill)], fill=fill, outline=WIN_C, width=3)
            if wd > 1.0:
                d.line([P(c, head), P(c, sill)], fill=WIN_C, width=2)
            pl = float(piece_len(c, wd).split(" ")[0])
            d.line([P(c - pl / 2, 0.05), P(c + pl / 2, 0.05)], fill=WIN_C, width=4)
            label = "%s %s m" % (i, m(wd)) + ("" if abs(wd - (s1 - s0)) < 1e-6 else " (old %s)" % m(s1 - s0))
            d.text(P(c, head + 0.1), label, fill=WIN_C, font=font(16), anchor="mb")
            osill, ohead = (2.35, 3.45) if n == "StairGround" else (sill, head)
            d.rectangle([P(fr(s0), ohead), P(fr(s1), osill)], outline=OLD_C, width=2)
        d.text(P(0.1, 3.7), "west", fill=(90, 90, 90), font=font(15))
        d.text(P(10.4, 3.7), "east", fill=(90, 90, 90), font=font(15), anchor="ra")
    y = 90 + len(panels) * panel_h + 4
    d.text((MARGIN, y), "Teal: the new window (a middle bar over 1.0 m), its wall piece as a bar on the floor line. Red: the old window,",
           fill=TEXT, font=font(17))
    d.text((MARGIN, y + 26), "shifted +0.1 m. Grey: partitions and the slab (none over the stair well). Metres over the storey's floor.",
           fill=TEXT, font=font(17))
    img.save(path)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--md", help="write the plan table here")
    ap.add_argument("--out", help="write the plan stills into this folder")
    ap.add_argument("--windows", action="store_true", help="print both window sets as the kit builds them")
    args = ap.parse_args()
    bad = check()
    for b in bad:
        print("FAIL plan:", b)
    if args.md:
        write_md(args.md)
    if args.out:
        os.makedirs(args.out, exist_ok=True)
        for k, lv in enumerate(LEVELS):
            draw_floor(lv, os.path.join(args.out, "plan_%d_%s.png" % (k + 1, lv)))
        draw_section(os.path.join(args.out, "plan_5_section.png"))
        draw_openings(os.path.join(args.out, "openings_two_sets.png"))
    if args.windows:
        for row in window_sets():
            print(row)
    print("house_plan: %s, %d rules broken" % ("FAIL" if bad else "PASS", len(bad)))
    raise SystemExit(1 if bad else 0)


if __name__ == "__main__":
    main()
