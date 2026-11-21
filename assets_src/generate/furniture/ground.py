"""The ground floor's furniture (house/04): kitchen with dining, living room, hall (coat nook), WC.

Blender axes: z up, front -y, each piece built around x = 0, y = 0 (build.py centres it).
Openable hinge axes (Blender): a door hinged on its left edge turns about (0, 0, -1), on its right
edge about (0, 0, 1); a drop-down door (the oven) about (1, 0, 0); drawers slide along (0, -1, 0).
"""

import math

import bmesh

import kit
from fkit import (M, ball, box, bun_feet, bx, cush, cyl, fab, face_out, handle_bar, lathe, peg_legs,  # noqa: F401
                  piece, shell, stripes, tray_boxes, tube)

ROOMS = ["Kitchen & dining", "Living room", "Hall", "WC"]

TOP_H = 0.9          # kitchen worktop height
BASE_D = 0.62        # base unit depth (worktop)
PLINTH = 0.1


CT = 0.018         # carcass panel thickness


def _carcass(P, W, paint="sage", hollow=True, hole=None):
    """A kitchen base unit: plinth, a hollow carcass open at the front (house/05: Socks hide
    inside) and the oak worktop. `hole` (x0, y0, x1, y1): a hole through the worktop and the
    carcass's top (the sink's, house/12). Returns the front face's y and the carcass's inside
    (lo, hi)."""
    D = BASE_D
    P.add(box("Plinth", (W - 0.02, D - 0.1, PLINTH), (0, 0.02, 0), M("charcoal", 0.7), r=0.005, seg=1))
    P.collide((-W / 2 + 0.01, -D / 2 + 0.07, 0), (W / 2 - 0.01, D / 2 - 0.03, PLINTH))
    lo, hi = (-W / 2, -D / 2 + 0.04, PLINTH), (W / 2, D / 2, TOP_H - 0.04)
    if hollow:
        inside = shell(P, "Carcass", lo, hi, CT, M("white", 0.6), open=("front", "top") if hole else ("front",))
    else:
        P.add(bx("Carcass", lo, hi, M("white", 0.6), r=0.006))
        P.collide(lo, hi)
        inside = (lo, hi)
    oak = M("oak", 0.45)
    if hole is None:
        P.add(box("Worktop", (W, D, 0.04), (0, 0, TOP_H - 0.04), oak, r=0.012))
        P.collide((-W / 2, -D / 2, TOP_H - 0.04), (W / 2, D / 2, TOP_H))
        P.extra["tops"] = [_top((-W / 2 + 0.02, -D / 2 + 0.03), (W / 2 - 0.02, D / 2 - 0.02), TOP_H)]
    else:
        # The worktop in four strips round the hole.
        hx0, hy0, hx1, hy1 = hole
        for a, b in (((-W / 2, -D / 2), (hx0, D / 2)), ((hx1, -D / 2), (W / 2, D / 2)),
                     ((hx0, -D / 2), (hx1, hy0)), ((hx0, hy1), (hx1, D / 2))):
            P.add(bx("Worktop", (a[0], a[1], TOP_H - 0.04), (b[0], b[1], TOP_H), oak, r=0.006))
            P.collide((a[0], a[1], TOP_H - 0.04), (b[0], b[1], TOP_H))
    return -D / 2 + 0.04, inside


def _top(lo, hi, z):
    """A resting top: the Blender rect lo..hi at height z (Piece.finish() writes it as Godot)."""
    return (tuple(lo), tuple(hi), z)


def _rail(P, inside, z, m=None):
    """A board across the carcass's inside at height z (a divider, a shelf); collides."""
    lo, hi = inside
    a, b = (lo[0], lo[1], z), (hi[0], hi[1], z + CT)
    P.add(bx("Rail", a, b, m or M("white", 0.6)))
    P.collide(a, b)
    return z + CT


def _door(name, x0, x1, z0, z1, y, paint, hinge_left=True):
    """A shaker cupboard door with a recessed panel and a round knob; returns (objs, pivot, axis)."""
    w, h = x1 - x0, z1 - z0
    cx = (x0 + x1) / 2
    objs = [box(name, (w, 0.022, h), (cx, y - 0.011, z0), M(paint, 0.55), r=0.008)]
    objs.append(box(name + "Panel", (w - 0.12, 0.01, h - 0.12), (cx, y - 0.024, z0 + 0.06), M(paint + "_dark", 0.6)
                    if paint == "sage" else M(paint, 0.6), r=0.006, seg=1))
    kx = x1 - 0.05 if hinge_left else x0 + 0.05
    objs.append(ball(name + "Knob", 0.018, (kx, y - 0.035, z1 - 0.08 if h > 0.3 else (z0 + z1) / 2),
                     M("brass", 0.3, 0.8), seg=10, rings=6))
    pivot = (x0 if hinge_left else x1, y - 0.011, z0)
    return objs, pivot, (0, 0, -1) if hinge_left else (0, 0, 1)


def _drawer(P, name, x0, x1, z0, z1, y, paint, depth=0.45, open_m=0.38, sound="drawer"):
    """A drawer front with a bar handle plus an open tray behind it (house/05: Socks hide in it),
    sliding out by open_m; registers the part and its container. Returns the tray's inside."""
    w, h = x1 - x0, z1 - z0
    cx = (x0 + x1) / 2
    t = 0.012
    lo, hi = (cx - (w - 0.06) / 2, y, z0 + 0.02), (cx + (w - 0.06) / 2, y + depth, z0 + h - 0.03)
    wood = M("oak", 0.7)
    objs = [box(name, (w, 0.022, h), (cx, y - 0.011, z0), M(paint, 0.55), r=0.008),
            handle_bar(name + "Bar", cx - 0.08, cx + 0.08, y - 0.022, (z0 + z1) / 2, M("brass", 0.3, 0.8)),
            bx(name + "Floor", lo, (hi[0], hi[1], lo[2] + t), wood),
            bx(name + "BackW", (lo[0], hi[1] - t, lo[2]), hi, wood),
            bx(name + "SideL", lo, (lo[0] + t, hi[1], hi[2]), wood),
            bx(name + "SideR", (hi[0] - t, lo[1], lo[2]), hi, wood)]
    P.slide(name, objs, (cx, y, z0), (0, -1, 0), open_m, boxes=tray_boxes(lo, hi))
    inner = ((lo[0] + t, lo[1] + 0.005, lo[2] + t), (hi[0] - t, hi[1] - t, hi[2]))
    P.container(name, [name], inner[0], inner[1], sound)
    return inner


# --- Kitchen ----------------------------------------------------------------------------------

@piece("kitchen_cupboard", ["Kitchen & dining"], spot="Counter",
       note="Base unit 0.6 wide: a drawer over a door. Line them up along the plan's Counter runs.")
def kitchen_cupboard(P):
    W = 0.6
    y, inside = _carcass(P, W)
    _drawer(P, "Drawer_1", -W / 2 + 0.005, W / 2 - 0.005, TOP_H - 0.2, TOP_H - 0.045, y, "sage")
    objs, piv, ax = _door("Door", -W / 2 + 0.005, W / 2 - 0.005, PLINTH + 0.005, TOP_H - 0.21, y, "sage")
    P.hinge("Door", objs, piv, ax, 100)
    _rail(P, inside, TOP_H - 0.21)
    shelf = _rail(P, inside, 0.4)
    (lo, hi) = inside
    P.container("Door", ["Door"], (lo[0], lo[1] + 0.005, lo[2]), (hi[0], hi[1], TOP_H - 0.21), "cupboard", [shelf])
    # A tea caddy and a jar on the worktop.
    P.add(cyl("Caddy", 0.06, 0.16, (-0.15, 0.12, TOP_H), M("red", 0.4), n=14, bev=0.01))
    for z in (TOP_H + 0.1, TOP_H + 0.125):
        P.add(cyl("CaddyStripe", 0.062, 0.012, (-0.15, 0.12, z), M("stripe", 0.5), n=14))
    P.add(lathe("Jar", [(0, 0), (0.055, 0), (0.06, 0.15), (0.045, 0.17), (0.05, 0.19), (0, 0.19)], M("sky", 0.2),
                n=12, loc=(0.05, 0.15, TOP_H)))


@piece("kitchen_drawers", ["Kitchen & dining"], spot="Counter", note="Base unit 0.6 wide, three drawers.")
def kitchen_drawers(P):
    W = 0.6
    y, inside = _carcass(P, W)
    zs = [PLINTH + 0.005, PLINTH + 0.3, PLINTH + 0.55, TOP_H - 0.045]
    for k in range(3):
        z0, z1 = zs[2 - k], zs[3 - k] - 0.005
        _drawer(P, f"Drawer_{k + 1}", -W / 2 + 0.005, W / 2 - 0.005, z0, z1, y, "sage")
    # A fruit bowl.
    P.add(lathe("Bowl", [(0, 0), (0.08, 0), (0.14, 0.07), (0.13, 0.075), (0.07, 0.01), (0, 0.01)], M("mustard", 0.5),
                n=16, loc=(0, 0.05, TOP_H)))
    for k, c in enumerate(("red", "sage", "mustard", "red")):
        a = k * 1.6
        P.add(ball("Fruit", 0.04, (0.05 * math.cos(a), 0.05 + 0.05 * math.sin(a), TOP_H + 0.06 + 0.02 * (k == 3)),
                   M(c, 0.4), seg=10, rings=6))


@piece("kitchen_sink", ["Kitchen & dining"], spot="Counter", note="Base unit 0.8 wide: the sink over two doors.")
def kitchen_sink(P):
    W = 0.8
    # A deep white butler sink (house/12: a real basin) hung in a hole through the worktop.
    bx0, by0, bx1, by1 = -0.3, -0.23, 0.3, 0.23
    bz0, rim = TOP_H - 0.2, 0.03
    y, (lo, hi) = _carcass(P, W, hole=(bx0, by0, bx1, by1))
    # A drying cloth with the cream stripes, hung over the right door's top edge (it swings with it).
    dz = TOP_H - 0.06
    cloth = [cush("Cloth", (0.18, 0.02, 0.3), (0.2, y - 0.04, dz - 0.29), fab("sky"), puff=(0.05, 0.4, 0.02), cuts=3),
             tube("ClothFold", [(0.11, y - 0.02, dz + 0.004), (0.29, y - 0.02, dz + 0.004)], 0.012, fab("sky"), n=8)]
    for z in (dz - 0.23, dz - 0.2):
        cloth.append(box("ClothStripe", (0.182, 0.024, 0.014), (0.2, y - 0.04, z), fab("stripe"), r=0.003, seg=1))
    for name, x0, x1, left in (("Door_L", -W / 2 + 0.005, -0.0025, True), ("Door_R", 0.0025, W / 2 - 0.005, False)):
        objs, piv, ax = _door(name, x0, x1, PLINTH + 0.005, TOP_H - 0.06, y, "sage", hinge_left=left)
        if name == "Door_R":
            objs += cloth
        # 90 deg: further, the left door reaches over the oven's dropped door (house/12).
        P.hinge(name, objs, piv, ax, 90, boxes="each")
    P.container("Doors", ["Door_L", "Door_R"], (lo[0], lo[1] + 0.005, lo[2]), (hi[0], hi[1], bz0 - 0.02), "cupboard")
    st = M("steel", 0.25, 0.85)
    porc = M("porcelain", 0.2)
    inner = shell(P, "Sink", (bx0, by0, bz0), (bx1, by1, TOP_H + 0.01), rim, porc, open=("top",), r=0.008)
    # Its rolled rim over the worktop and a drain in the floor.
    for a, b in (((bx0 - 0.01, by0 - 0.01), (bx1 + 0.01, by0 + rim)), ((bx0 - 0.01, by1 - rim), (bx1 + 0.01, by1 + 0.01)),
                 ((bx0 - 0.01, by0), (bx0 + rim, by1)), ((bx1 - rim, by0), (bx1 + 0.01, by1))):
        P.add(bx("SinkRim", (a[0], a[1], TOP_H), (b[0], b[1], TOP_H + 0.02), porc, r=0.008))
    P.add(cyl("Drain", 0.03, 0.004, (0, 0, inner[0][2]), st, n=12))
    # Socks rest in the basin (its floor is the top; the worktop strips round it are too narrow).
    P.extra["tops"] = [_top((inner[0][0] + 0.02, inner[0][1] + 0.02), (inner[1][0] - 0.02, inner[1][1] - 0.02),
                            inner[0][2])]
    # A swan-neck brass tap behind it.
    P.add(cyl("TapBase", 0.025, 0.06, (0, 0.27, TOP_H), M("brass", 0.3, 0.85), n=10, bev=0.01))
    P.add(tube("Tap", [(0, 0.27, TOP_H + 0.05), (0, 0.27, TOP_H + 0.3), (0, 0.22, TOP_H + 0.34), (0, 0.13, TOP_H + 0.3),
                       (0, 0.13, TOP_H + 0.25)], 0.014, M("brass", 0.3, 0.85), n=8))
    for s in (-1, 1):
        P.add(ball("TapHead", 0.025, (s * 0.09, 0.27, TOP_H + 0.06), M("brass", 0.3, 0.85), seg=10, rings=6))


@piece("kitchen_oven", ["Kitchen & dining"], spot="Counter",
       note="Base unit 0.6 wide: a hob on top, the oven door drops down (hinge at its bottom edge).")
def kitchen_oven(P):
    W = 0.6
    y, inside = _carcass(P, W)
    blk = M("charcoal", 0.4)
    st = M("steel", 0.25, 0.85)
    P.add(box("Fascia", (W - 0.01, 0.02, 0.12), (0, y - 0.01, TOP_H - 0.17), M("white", 0.4), r=0.006))
    for k in range(4):
        P.add(face_out(cyl("OvenKnob", 0.022, 0.03, (0, 0, 0), blk, n=10, bev=0.008),
                       (-0.21 + k * 0.14, y - 0.015, TOP_H - 0.11)))
    # The cavity: dark lined, closed over the door by a rail, a wire rack across it (no collider:
    # the crosshair reaches through it; the heap bake rests Socks on it as a shelf).
    z0, z1 = PLINTH + 0.03, TOP_H - 0.18
    (lo, hi) = inside
    P.add(bx("OvenBack", (lo[0], hi[1] - 0.004, lo[2]), hi, blk, r=0))
    for sx in (lo[0], hi[0] - 0.004):
        P.add(bx("OvenWall", (sx, lo[1] + 0.01, lo[2]), (sx + 0.004, hi[1], z1), blk, r=0))
    P.add(bx("OvenFloor", (lo[0], lo[1] + 0.01, lo[2]), (hi[0], hi[1], lo[2] + 0.004), blk, r=0))
    top = _rail(P, inside, z1, blk)
    rack = 0.42
    for k in range(9):
        x = lo[0] + 0.03 + k * (hi[0] - lo[0] - 0.06) / 8
        P.add(tube("Rack", [(x, lo[1] + 0.03, rack), (x, hi[1] - 0.02, rack)], 0.003, st, n=4))
    P.add(tube("RackRim", [(lo[0] + 0.02, lo[1] + 0.03, rack), (hi[0] - 0.02, lo[1] + 0.03, rack)], 0.004, st, n=4))
    P.container("Door", ["Door"], (lo[0], lo[1] + 0.005, lo[2]), (hi[0], hi[1], z1), "oven", [rack])
    # The door: white with a dark window and a bar handle.
    door = [box("OvenDoor", (W - 0.02, 0.03, z1 - z0), (0, y - 0.015, z0), M("white", 0.4), r=0.012),
            box("OvenWindow", (W - 0.16, 0.012, (z1 - z0) * 0.5), (0, y - 0.032, z0 + (z1 - z0) * 0.25),
                M("screen", 0.1), r=0.02, seg=2),
            handle_bar("OvenHandle", -0.22, 0.22, y - 0.03, z1 - 0.05, st, r=0.01)]
    P.hinge("Door", door, (0, y - 0.015, z0), (1, 0, 0), 85)
    # The hob: four rings on a dark glass top.
    P.add(box("Hob", (W - 0.06, 0.5, 0.012), (0, 0.0, TOP_H), blk, r=0.004, seg=1))
    for x in (-0.13, 0.13):
        for yy in (-0.12, 0.12):
            P.add(lathe("Ring", [(0.06, TOP_H + 0.012), (0.08, TOP_H + 0.016), (0.1, TOP_H + 0.012)], M("grey", 0.4),
                        n=16, loc=(x, yy, 0)))
    # A kettle on the back ring.
    P.add(lathe("Kettle", [(0, 0), (0.09, 0), (0.1, 0.06), (0.085, 0.16), (0.04, 0.2), (0.02, 0.21), (0, 0.21)],
                M("mustard", 0.35), n=16, loc=(0.13, 0.12, TOP_H + 0.016)))
    P.add(tube("KettleHandle", [(0.08, 0.12, TOP_H + 0.17), (0.11, 0.12, TOP_H + 0.26), (0.17, 0.12, TOP_H + 0.26),
                                (0.2, 0.12, TOP_H + 0.17)], 0.01, M("charcoal", 0.5), n=6))


@piece("kitchen_corner", ["Kitchen & dining"], spot="Counter",
       note="The plain worktop block for the L's corner (0.62 square), no door.")
def kitchen_corner(P):
    W = BASE_D
    _carcass(P, W, hollow=False)
    P.add(box("CornerPanel", (W - 0.04, 0.02, TOP_H - PLINTH - 0.08), (0, -W / 2 + 0.03, PLINTH + 0.02),
              M("sage", 0.55), r=0.008))
    # A bread bin and a utensil pot.
    P.add(box("BreadBin", (0.36, 0.26, 0.2), (0.0, 0.1, TOP_H), M("sky", 0.4), r=0.06, seg=3))
    P.add(cyl("Pot", 0.06, 0.15, (-0.18, -0.12, TOP_H), M("porcelain", 0.3), n=12, bev=0.01))
    for k in range(3):
        a = k * 2.1
        P.add(tube("Spoon", [(-0.18 + 0.02 * math.cos(a), -0.12 + 0.02 * math.sin(a), TOP_H + 0.05),
                             (-0.18 + 0.05 * math.cos(a), -0.12 + 0.05 * math.sin(a), TOP_H + 0.3)], 0.008,
                   M("oak", 0.5), n=5))


@piece("kitchen_filler", ["Kitchen & dining"], spot="Counter",
       note="A plain worktop block 0.44 wide, no door: it spaces the east run's drawers clear of the sink's door (house/12).")
def kitchen_filler(P):
    W = 0.44
    _carcass(P, W, hollow=False)
    P.add(box("FillerPanel", (W - 0.04, 0.02, TOP_H - PLINTH - 0.08), (0, -BASE_D / 2 + 0.03, PLINTH + 0.02),
              M("sage", 0.55), r=0.008))


@piece("kitchen_wall_cupboard", ["Kitchen & dining"], spot="Counter (above)",
       note="Wall-hung: its origin is its own bottom; hang it with the bottom at about 1.45 m.")
def kitchen_wall_cupboard(P):
    W, D, H = 0.6, 0.33, 0.7
    inside = shell(P, "Carcass", (-W / 2, -D / 2 + 0.01, 0), (W / 2, D / 2 + 0.01, H), CT, M("white", 0.6))
    P.add(box("Cornice", (W + 0.02, D + 0.01, 0.04), (0, 0.0, H), M("oak", 0.5), r=0.01))
    P.collide((-W / 2 - 0.01, -D / 2, H), (W / 2 + 0.01, D / 2 + 0.01, H + 0.04))
    objs, piv, ax = _door("Door", -W / 2 + 0.005, W / 2 - 0.005, 0.005, H - 0.005, -D / 2 + 0.01, "sage")
    P.hinge("Door", objs, piv, ax, 105)
    # A shelf with two mugs at its end, room for Socks beside them.
    shelf = _rail(P, inside, H / 2)
    for k, c in enumerate(("pink", "sky")):
        P.add(cyl("Mug", 0.045, 0.1, (0.18 - k * 0.1, 0.05, shelf), M(c, 0.4), n=12, bev=0.008))
    (lo, hi) = inside
    P.container("Door", ["Door"], (lo[0], lo[1] + 0.005, lo[2]), hi, "cupboard", [shelf])


@piece("fridge", ["Kitchen & dining"], spot="Fridge",
       note="A rounded retro fridge-freezer; both doors hinge on the left edge (the wall side, house/12) and open 85 deg.")
def fridge(P):
    W, D, H = 0.68, 0.66, 1.85
    body = M("sky", 0.35)
    # A hollow cabinet (house/05): the freezer below, the fridge above, a divider between.
    inside = shell(P, "Cabinet", (-W / 2, -D / 2 + 0.05, 0.06), (W / 2, D / 2, H), 0.045, body, r=0.02)
    (lo, hi) = inside
    P.add(bx("Liner", (lo[0], hi[1] - 0.004, lo[2]), hi, M("white", 0.6), r=0))
    for x in (-W / 2 + 0.06, W / 2 - 0.06):
        for y in (-D / 2 + 0.1, D / 2 - 0.08):
            P.add(cyl("Foot", 0.03, 0.07, (x, y, 0), M("charcoal", 0.5), n=10, bev=0.01))
    y = -D / 2 + 0.03
    split = 0.62
    chrome = M("steel", 0.2, 0.9)
    for name, z0, z1 in (("Door_Bottom", 0.08, split - 0.01), ("Door_Top", split + 0.01, H - 0.02)):
        h = z1 - z0
        objs = [box(name, (W - 0.01, 0.05, h), (0, y - 0.025, z0), body, r=0.05, seg=3),
                box(name + "Seal", (W - 0.06, 0.012, h - 0.05), (0, y + 0.006, z0 + 0.025), M("white", 0.6), r=0,
                    seg=1)]
        # The handle on the free (right) edge, clear of the other door's (house/12).
        hz = z1 - 0.32 if name == "Door_Top" else z1 - 0.26
        hx = W / 2 - 0.07
        objs.append(tube(name + "Handle", [(hx, y - 0.05, hz), (hx, y - 0.08, hz + 0.02),
                                           (hx, y - 0.08, hz + 0.2), (hx, y - 0.05, hz + 0.22)],
                          0.014, chrome, n=8))
        # Hinged on the wall side, so the open door stands by the wall (85 deg: its handle clears
        # it), out of the way of the cupboard beside it (house/12).
        P.hinge(name, objs, (-W / 2 + 0.005, y - 0.025, z0), (0, 0, -1), 85, boxes="each")
    # Inside: the divider, two glass shelves in the fridge, the freezer under them.
    P.add(bx("Divider", (lo[0], lo[1], split - 0.02), (hi[0], hi[1], split + 0.02), body, r=0.004))
    P.collide((lo[0], lo[1], split - 0.02), (hi[0], hi[1], split + 0.02))
    shelves = []
    for z in (0.95, 1.3):
        a, b = (lo[0], lo[1] + 0.06, z), (hi[0], hi[1], z + 0.012)
        P.add(bx("Shelf", a, b, M("sky", 0.1), r=0))
        P.collide(a, b)
        shelves.append(z + 0.012)
    P.container("Door_Top", ["Door_Top"], (lo[0], lo[1] + 0.005, split + 0.02), hi, "fridge", shelves)
    P.container("Door_Bottom", ["Door_Bottom"], (lo[0], lo[1] + 0.005, lo[2]), (hi[0], hi[1], split - 0.02), "fridge")
    P.extra["tops"] = [_top((-W / 2 + 0.03, -D / 2 + 0.08), (W / 2 - 0.03, D / 2 - 0.03), H)]


@piece("dining_table", ["Kitchen & dining"], spot="Dining table", crawl=0.68,
       hide="under the table (the runner does not hang down)")
def dining_table(P):
    oak = M("oak", 0.5)
    S, top = 1.2, 0.76
    P.add(box("Top", (S, S, 0.06), (0, 0, top - 0.06), oak, r=0.025, seg=3))
    P.collide((-S / 2, -S / 2, top - 0.14), (S / 2, S / 2, top))
    for x in (-S / 2 + 0.1, S / 2 - 0.1):
        for y in (-S / 2 + 0.1, S / 2 - 0.1):
            P.collide((x - 0.04, y - 0.04, 0), (x + 0.04, y + 0.04, top - 0.14))
    P.extra["tops"] = [_top((-S / 2 + 0.03, -S / 2 + 0.03), (S / 2 - 0.03, S / 2 - 0.03), top)]
    P.add(box("Apron", (S - 0.16, S - 0.16, 0.08), (0, 0, top - 0.14), M("dark_wood", 0.5), r=0.01))
    for x in (-S / 2 + 0.1, S / 2 - 0.1):
        for y in (-S / 2 + 0.1, S / 2 - 0.1):
            P.add(lathe("Leg", [(0, 0), (0.035, 0), (0.04, 0.03), (0.03, 0.08), (0.045, 0.5), (0.04, top - 0.06),
                                (0, top - 0.06)], M("dark_wood", 0.5), n=10, loc=(x, y, 0)))
    # A runner with the cream stripes, a jug of flowers.
    P.add(box("Runner", (0.38, S + 0.06, 0.008), (0, 0, top), fab("sage"), r=0.003, seg=1))
    for x in (-0.15, -0.12, 0.12, 0.15):
        P.add(box("RunnerStripe", (0.014, S + 0.062, 0.009), (x, 0, top), fab("stripe"), r=0, seg=1))
    P.add(lathe("Jug", [(0, 0), (0.06, 0), (0.08, 0.08), (0.05, 0.18), (0.055, 0.22), (0, 0.2)], M("porcelain", 0.3),
                n=14, loc=(0, 0, top + 0.008)))
    for k, c in enumerate(("pink", "mustard", "pink", "white", "mustard")):
        a = k * 1.25
        tip = (0.08 * math.cos(a), 0.08 * math.sin(a), top + 0.36 + 0.03 * (k % 2))
        P.add(tube("Stem", [(0, 0, top + 0.15), tip], 0.005, M("stem", 0.6), n=4))
        P.add(ball("Bloom", 0.035, tip, M(c, 0.6), seg=8, rings=5, scale=(1, 1, 0.7)))


@piece("dining_chair", ["Kitchen & dining"], spot="Dining table (4 chairs)", crawl=0.42, hide="under the seat",
       note="Four round the dining table.")
def dining_chair(P):
    oak = M("oak", 0.5)
    seat = 0.46
    W, D = 0.44, 0.44
    for x in (-W / 2 + 0.04, W / 2 - 0.04):
        for y in (-D / 2 + 0.04, D / 2 - 0.04):
            P.add(lathe("Leg", [(0, 0), (0.018, 0), (0.024, seat - 0.04), (0, seat - 0.04)], oak, n=8, loc=(x, y, 0)))
    P.add(box("Seat", (W, D, 0.04), (0, 0, seat - 0.04), oak, r=0.015))
    P.collide((-W / 2, -D / 2, seat - 0.04), (W / 2, D / 2, seat + 0.05))
    P.collide((-W / 2, D / 2 - 0.06, seat), (W / 2, D / 2, seat + 0.44))
    for x in (-W / 2 + 0.04, W / 2 - 0.04):
        for y in (-D / 2 + 0.04, D / 2 - 0.04):
            P.collide((x - 0.025, y - 0.025, 0), (x + 0.025, y + 0.025, seat - 0.04))
    P.extra["tops"] = [_top((-W / 2 + 0.04, -D / 2 + 0.03), (W / 2 - 0.04, D / 2 - 0.08), seat + 0.05)]
    P.add(cush("Pad", (W - 0.06, D - 0.06, 0.05), (0, -0.01, seat), fab("mustard"), puff=(0.06, 0.06, 0.4), cuts=4))
    for x in (-W / 2 + 0.04, W / 2 - 0.04):
        P.add(box("BackPost", (0.035, 0.035, 0.42), (x, D / 2 - 0.04, seat), oak, r=0.01))
    # A soft arched back rail and one spindle.
    arch = []
    for k in range(9):
        t = k / 8
        arch.append((-W / 2 + 0.04 + (W - 0.08) * t, D / 2 - 0.035, seat + 0.36 + 0.05 * math.sin(math.pi * t)))
    P.add(tube("BackRail", arch, 0.03, oak, n=8))
    P.add(box("Slat", (W - 0.1, 0.02, 0.06), (0, D / 2 - 0.04, seat + 0.18), oak, r=0.008))


@piece("kitchen_shelf", ["Kitchen & dining"], spot="Radio on shelf",
       note="Wall shelf; origin = its own bottom, hang at about 1.4 m. Leave the middle 0.3 m free: the Radio's spot.")
def kitchen_shelf(P):
    oak = M("oak", 0.5)
    W = 1.0
    P.add(box("Board", (W, 0.24, 0.035), (0, 0, 0.12), oak, r=0.012))
    P.collide((-W / 2, -0.12, 0.12), (W / 2, 0.12, 0.155))
    P.extra["tops"] = [_top((-W / 2 + 0.02, -0.11), (W / 2 - 0.02, 0.11), 0.155)]
    for x in (-0.38, 0.38):
        P.add(box("Bracket", (0.03, 0.2, 0.12), (x, 0.02, 0.0), M("dark_wood", 0.5), r=0.008))
    for k, c in enumerate(("sage", "mustard")):
        P.add(cyl("Jar", 0.05, 0.14, (-0.42 + k * 0.12, 0, 0.155), M("sky", 0.15), n=12, bev=0.008))
        P.add(cyl("JarLid", 0.052, 0.025, (-0.42 + k * 0.12, 0, 0.29), M(c, 0.4), n=12, bev=0.008))
    for k in range(3):
        P.add(box("Book", (0.035, 0.18, 0.2 - 0.02 * k), (0.3 + k * 0.04, 0, 0.155), M(("red", "navy", "sage")[k], 0.6),
                  r=0.005, seg=1))


# --- Living room -------------------------------------------------------------------------------

@piece("sofa", ["Living room"], spot="Sofa", crawl=0.2, hide="under the sofa (0.20, the flat's SOFA_GAP)",
       note="The trial's stylised sofa (Q404) with the subdivision dropped (Q405).")
def sofa(P):
    P.sock_dev = 0.005   # its merged Sock colliders keep the tops Socks rest on (physics/09)
    body = fab("sofa")
    cream = fab("stripe")
    w, d = 2.2, 0.92
    gap = 0.20
    # Its colliders: the base and seat, the back and the arms; the seat is a resting top.
    P.collide((-w / 2 + 0.05, -d / 2, gap), (w / 2 - 0.05, d / 2, gap + 0.42))
    P.collide((-w / 2 + 0.1, d / 2 - 0.3, gap), (w / 2 - 0.1, d / 2, gap + 0.74))
    P.collide((-w / 2 - 0.02, -d / 2, gap), (-w / 2 + 0.3, d / 2, gap + 0.6))
    P.collide((w / 2 - 0.3, -d / 2, gap), (w / 2 + 0.02, d / 2, gap + 0.6))
    P.extra["tops"] = [_top((-w / 2 + 0.3, -d / 2 + 0.03), (w / 2 - 0.3, d / 2 - 0.3), gap + 0.42)]
    P.add(bun_feet((-0.9, 0.9), (-0.3, 0.3), gap + 0.02, 0.085, M("oak", 0.6)))
    P.add(cush("SofaBase", (w - 0.1, d, 0.26), (0, 0, gap), body, puff=(0.04, 0.12, 0.25), cuts=6))
    back = cush("SofaBack", (w - 0.2, 0.28, 0.62), (0, d / 2 - 0.14, gap + 0.12), body, puff=(0.04, 0.35, 0.12), cuts=6)
    P.add(back)
    for sx in (-1, 1):
        x = sx * (w / 2 - 0.15)
        P.add(cush("SofaArm", (0.28, d - 0.02, 0.4), (x, 0, gap + 0.04), body, puff=(0.15, 0.06, 0.1), cuts=5))
        P.add(cush("SofaArmRoll", (0.33, d + 0.02, 0.24), (x + sx * 0.015, 0, gap + 0.36), body, puff=(0.4, 0.04, 0.4),
                   cuts=6))
    seat_z = gap + 0.22
    for sx in (-1, 1):
        cx = sx * 0.4
        P.add(cush("SofaSeat", (0.8, d - 0.2, 0.2), (cx, -0.08, seat_z), body, puff=(0.08, 0.08, 0.45), cuts=6))
        P.add(tube("SofaSeatPiping", [(cx - 0.37, -d / 2 + 0.03, seat_z + 0.19), (cx + 0.37, -d / 2 + 0.03, seat_z + 0.19)],
                   0.02, cream, n=8))
        bc = cush("SofaBackCushion", (0.8, 0.24, 0.46), (0, 0, 0), body, puff=(0.06, 0.5, 0.1), cuts=6)
        bc.location = (cx, d / 2 - 0.32, seat_z + 0.16)
        bc.rotation_euler.x = math.radians(-12)
        P.add(bc)
    for sx, c, rot in ((-1, "mustard", 18), (1, "pink", -14)):
        p = cush("SofaPillow", (0.42, 0.14, 0.42), (0, 0, -0.21), fab(c), puff=(0.1, 1.2, 0.1), pinch=0.6, cuts=5)
        p.location = (sx * 0.62, 0.12, seat_z + 0.43)
        p.rotation_euler = (math.radians(-18), math.radians(rot), math.radians(sx * 12))
        P.add(p)


@piece("armchair", ["Living room"], spot="Armchair", crawl=0.18, hide="under the armchair")
def armchair(P):
    body = fab("mustard")
    cream = fab("stripe")
    w, d, gap = 0.86, 0.84, 0.18
    P.collide((-w / 2, -d / 2, gap), (w / 2, d / 2, gap + 0.4))
    P.collide((-w / 2, d / 2 - 0.26, gap), (w / 2, d / 2, gap + 0.72))
    for sx in (-1, 1):
        P.collide((min(sx * w / 2, sx * (w / 2 - 0.2)), -d / 2, gap), (max(sx * w / 2, sx * (w / 2 - 0.2)), d / 2, gap + 0.54))
    P.extra["tops"] = [_top((-w / 2 + 0.2, -d / 2 + 0.03), (w / 2 - 0.2, d / 2 - 0.26), gap + 0.4)]
    P.add(bun_feet((-0.33, 0.33), (-0.3, 0.3), gap + 0.02, 0.07, M("oak", 0.6)))
    P.add(cush("Base", (w - 0.06, d, 0.24), (0, 0, gap), body, puff=(0.08, 0.1, 0.25), cuts=5))
    P.add(cush("Back", (w - 0.12, 0.26, 0.6), (0, d / 2 - 0.13, gap + 0.12), body, puff=(0.1, 0.35, 0.15), cuts=6))
    for sx in (-1, 1):
        x = sx * (w / 2 - 0.1)
        P.add(cush("Arm", (0.2, d - 0.04, 0.36), (x, 0, gap + 0.06), body, puff=(0.2, 0.06, 0.15), cuts=4))
        P.add(cush("ArmRoll", (0.24, d, 0.2), (x + sx * 0.01, 0, gap + 0.34), body, puff=(0.45, 0.04, 0.45), cuts=5))
    seat = gap + 0.2
    P.add(cush("Seat", (w - 0.38, d - 0.22, 0.2), (0, -0.08, seat), body, puff=(0.08, 0.08, 0.45), cuts=5))
    P.add(tube("Piping", [(-0.22, -d / 2 + 0.04, seat + 0.19), (0.22, -d / 2 + 0.04, seat + 0.19)], 0.02, cream, n=8))
    # A knitted throw over the arm with the cream stripes.
    P.add(cush("Throw", (0.26, 0.5, 0.04), (w / 2 - 0.1, -0.05, gap + 0.54), fab("sofa"), puff=(0.3, 0.1, 0.6), cuts=4))
    for y in (-0.15, -0.1):
        P.add(box("ThrowStripe", (0.265, 0.025, 0.042), (w / 2 - 0.1, y, gap + 0.54), cream, r=0.006, seg=1))


@piece("coffee_table", ["Living room"], spot="Coffee table", crawl=0.33, hide="under the coffee table")
def coffee_table(P):
    oak = M("oak", 0.5)
    W, D, top = 1.2, 0.6, 0.42
    P.collide((-W / 2, -D / 2, top - 0.06), (W / 2, D / 2, top))
    for x in (-W / 2 + 0.14, W / 2 - 0.14):
        for y in (-D / 2 + 0.12, D / 2 - 0.12):
            P.collide((x - 0.05, y - 0.05, 0), (x + 0.05, y + 0.05, top - 0.06))
    P.extra["tops"] = [_top((-W / 2 + 0.04, -D / 2 + 0.04), (W / 2 - 0.04, D / 2 - 0.04), top)]
    # A soft rounded top on bun feet with a magazine shelf low between them.
    bm = bmesh.new()
    n = 10
    pts = []
    r = 0.18
    for cx, cy, a0 in ((W / 2 - r, D / 2 - r, 0), (-W / 2 + r, D / 2 - r, 90), (-W / 2 + r, -D / 2 + r, 180),
                       (W / 2 - r, -D / 2 + r, 270)):
        for k in range(n + 1):
            a = math.radians(a0 + 90 * k / n)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    lo = [bm.verts.new((x, y, top - 0.06)) for x, y in pts]
    hi = [bm.verts.new((x, y, top)) for x, y in pts]
    bm.faces.new(list(reversed(lo)))
    bm.faces.new(hi)
    for i in range(len(pts)):
        j = (i + 1) % len(pts)
        bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    t = kit.obj_from_bm("Top", bm, oak)
    kit.bevel(t, 0.02, 3, angle=40)
    P.add(t)
    for x in (-W / 2 + 0.14, W / 2 - 0.14):
        for y in (-D / 2 + 0.12, D / 2 - 0.12):
            P.add(lathe("Leg", [(0, 0), (0.05, 0), (0.06, 0.04), (0.04, 0.1), (0.035, top - 0.06), (0, top - 0.06)],
                        oak, n=12, loc=(x, y, 0)))
    # A stack of books, a mug, a knitted coaster.
    for k, c in enumerate(("navy", "pink", "sage")):
        P.add(box("Book", (0.28 - 0.03 * k, 0.2, 0.035), (-0.3, 0.02, top + 0.035 * k), M(c, 0.6), r=0.006, seg=1))
    P.add(cyl("Coaster", 0.06, 0.008, (0.25, -0.05, top), fab("stripe"), n=14))
    P.add(cyl("Mug", 0.045, 0.1, (0.25, -0.05, top + 0.008), M("red", 0.4), n=12, bev=0.008))
    P.add(tube("MugHandle", [(0.295, -0.05, top + 0.08), (0.33, -0.05, top + 0.07), (0.33, -0.05, top + 0.035),
                             (0.295, -0.05, top + 0.03)], 0.01, M("red", 0.4), n=6))


@piece("floor_lamp", ["Living room"], spot="Floor lamp (new; by the sofa or armchair)")
def floor_lamp(P):
    oak = M("oak", 0.5)
    # A tripod lamp with a fat drum shade in cream with the sock stripes.
    H = 1.55
    for k in range(3):
        a = math.radians(90 + 120 * k)
        P.add(tube("Leg", [(0.28 * math.cos(a), 0.28 * math.sin(a), 0.0), (0.03 * math.cos(a), 0.03 * math.sin(a), 1.1)],
                   0.016, oak, n=6))
    P.add(cyl("Pole", 0.014, H - 1.05, (0, 0, 1.05), M("brass", 0.3, 0.8), n=8))
    shade = fab("stripe")
    P.add(lathe("Shade", [(0.2, 0.0), (0.21, 0.01), (0.2, 0.3), (0.17, 0.32), (0.165, 0.31), (0.19, 0.02),
                          (0.18, 0.0)], shade, n=24, loc=(0, 0, H - 0.24)))
    for z in (H - 0.2, H - 0.16):
        P.add(lathe("ShadeBand", [(0.2, z - 0.012), (0.212, z), (0.198, z + 0.012)], fab("pink"), n=24))


@piece("living_rug", ["Living room"], spot="Rug (new; under the coffee table)",
       note="Flat (2 cm): no collider needed.")
def living_rug(P):
    P.add(cush("Rug", (2.0, 1.4, 0.02), (0, 0, 0), fab("rug_blue"), puff=(0.01, 0.01, 0.1), cuts=3))
    P.add(box("Border", (1.8, 1.2, 0.022), (0, 0, 0), fab("stripe"), r=0.004, seg=1))
    P.add(box("Field", (1.7, 1.1, 0.024), (0, 0, 0), fab("rug_blue"), r=0.004, seg=1))
    P.add(box("Centre", (1.0, 0.5, 0.026), (0, 0, 0), fab("pink"), r=0.004, seg=1))


@piece("side_table", ["Living room"], spot="Side table (new; by the armchair)", crawl=0.38)
def side_table(P):
    oak = M("oak", 0.5)
    P.add(cyl("Top", 0.24, 0.04, (0, 0, 0.5), oak, n=20, bev=0.015))
    P.collide((-0.24, -0.24, 0.5), (0.24, 0.24, 0.54))
    P.collide((-0.17, -0.17, 0.0), (0.17, 0.17, 0.05))
    P.collide((-0.04, -0.04, 0.05), (0.04, 0.04, 0.5))
    P.add(lathe("Stem", [(0, 0), (0.16, 0), (0.17, 0.02), (0.06, 0.05), (0.035, 0.1), (0.03, 0.45), (0.06, 0.5),
                         (0, 0.5)], oak, n=14))
    P.add(lathe("LampBase", [(0, 0), (0.07, 0), (0.09, 0.08), (0.06, 0.16), (0.02, 0.18), (0, 0.18)], M("sage", 0.4),
                n=14, loc=(0, 0, 0.54)))
    P.add(lathe("LampShade", [(0.14, 0.0), (0.09, 0.14), (0.085, 0.13), (0.13, 0.005)], fab("pink"), n=18,
                loc=(0, 0, 0.66)))


# The piano's keyboard (house/28): 88 keys, A0 (MIDI 21) to C8 (108); PIANO_PLAYABLE are their own
# nodes (Key_<note>) that dip on a press, the rest is drawn in the Body (house/33: every key plays).
PIANO_LOW, PIANO_HIGH = 21, 108
PIANO_PLAYABLE = range(PIANO_LOW, PIANO_HIGH + 1)   # every key, A0 to C8 (house/33)
WHITE_PCS = (0, 2, 4, 5, 7, 9, 11)
KEY_W = 0.0235                          # a white key's pitch (a real piano's)
KEY_TOP = 0.72                          # the white keys' tops
KEY_FRONT, KEY_BACK = -0.28, -0.13      # the keys' front and where they go under the nameboard
KEY_DIP_DEG = 3.0                       # how far a pressed key turns down about its back


def _piano_keys(P, ivory, ebony):
    """The keyboard: each white key a slab, each black key a raised bar between two whites."""
    n_white = sum(1 for m in range(PIANO_LOW, PIANO_HIGH + 1) if m % 12 in WHITE_PCS)
    x0 = -n_white * KEY_W / 2
    i = 0
    keys = {}
    for m in range(PIANO_LOW, PIANO_HIGH + 1):
        if m % 12 in WHITE_PCS:
            xc = x0 + (i + 0.5) * KEY_W
            ob = bx("Key", (xc - KEY_W / 2 + 0.0007, KEY_FRONT, KEY_TOP - 0.03), (xc + KEY_W / 2 - 0.0007, KEY_BACK, KEY_TOP),
                    ivory, r=0.0015)
            i += 1
        else:
            xc = x0 + i * KEY_W
            ob = bx("Key", (xc - 0.0068, -0.225, KEY_TOP - 0.015), (xc + 0.0068, KEY_BACK, KEY_TOP + 0.012), ebony,
                    r=0.002)
        if m in PIANO_PLAYABLE:
            name = "Key_%d" % m
            P.hinge(name, [ob], (xc, -0.07, KEY_TOP - 0.03), (1, 0, 0), KEY_DIP_DEG)
            keys[name] = m
        else:
            P.add(ob)
    P.extra["keys"] = keys
    return x0


@piece("piano", ["Living room"], spot="Piano (new, house/28; against a wall)", crawl=0.6,
       hide="under the keyboard, between the legs; on top; in the key well under the shut lid",
       note="Upright piano (Q542). Lid: the key lid, an openable hinged at its back (kind piano_lid; the key "
            "well under it is a small container). Key_<note>: the playable keys, all 88 (A0-C8, MIDI 21-108, house/33), each a "
            "hinge part that dips by open_deg about its back; keys maps node -> MIDI note. crawl_box: the open "
            "space under the keyboard between the legs.")
def piano(P):
    W, D, H = 1.40, 0.60, 1.25
    hw = W / 2
    wood = M("dark_wood", 0.32)
    trim = M("oak", 0.45)
    brass = M("brass", 0.3, 0.8)
    ivory = M("linen", 0.35)
    ebony = M("charcoal", 0.3)
    yb = D / 2                       # the back
    yc = -0.04                       # the upper case's front
    kz0 = 0.60                       # the keybed's underside
    # Plinth and the lower case with two recessed panels.
    P.add(bx("Plinth", (-hw + 0.01, -0.03, 0.0), (hw - 0.01, yb - 0.01, 0.045), M("charcoal", 0.6)))
    P.add(bx("LowerCase", (-hw, -0.03, 0.04), (hw, yb, kz0), wood, r=0.006))
    P.collide((-hw, -0.03, 0.0), (hw, yb, kz0))
    for sx in (-1, 1):
        P.add(bx("LowerPanel", (sx * 0.06, -0.036, 0.13), (sx * 0.56, -0.03, 0.52), M("dark_wood", 0.45), r=0.004))
        P.add(bx("LowerPanelBead", (sx * 0.075, -0.04, 0.145), (sx * 0.545, -0.034, 0.505), wood, r=0.003))
    # The pedals on their rail.
    P.add(bx("PedalRail", (-0.16, -0.06, 0.03), (0.16, -0.03, 0.1), wood, r=0.008))
    P.collide((-0.16, -0.06, 0.0), (0.16, -0.03, 0.1))
    for x in (-0.07, 0.07):
        P.add(bx("Pedal", (x - 0.02, -0.15, 0.055), (x + 0.02, -0.05, 0.075), brass, r=0.006))
    # The legs: toe blocks on the floor and turned columns up to the keybed's cheeks.
    for sx in (-1, 1):
        a, b = sorted((sx * (hw - 0.09), sx * (hw - 0.01)))
        P.add(bx("Toe", (a, -0.29, 0.0), (b, -0.03, 0.05), wood, r=0.01))
        P.collide((a, -0.29, 0.0), (b, -0.03, 0.05))
        x = sx * (hw - 0.05)
        P.add(lathe("Leg", [(0, 0), (0.034, 0), (0.034, 0.03), (0.024, 0.07), (0.028, 0.16), (0.02, 0.34),
                            (0.026, 0.48), (0.034, 0.52), (0.034, kz0 - 0.05), (0, kz0 - 0.05)], wood, n=12,
                    loc=(x, -0.25, 0.05)))
        P.collide((x - 0.035, -0.285, 0.05), (x + 0.035, -0.215, kz0))
    # The keybed, the key slip in front of the keys, the cheeks either side, the nameboard felt.
    kw = 52 * KEY_W / 2              # half the keyboard
    P.add(bx("Keybed", (-hw, -0.3, kz0), (hw, yc, KEY_TOP - 0.03), wood, r=0.006))
    P.add(bx("KeySlip", (-kw - 0.002, -0.3, kz0 + 0.04), (kw + 0.002, KEY_FRONT, KEY_TOP - 0.018), wood, r=0.004))
    P.collide((-hw, -0.3, kz0), (hw, KEY_FRONT, KEY_TOP - 0.018))
    P.collide((-kw, KEY_FRONT + 0.005, kz0), (kw, -0.07, KEY_TOP - 0.005))
    for sx in (-1, 1):
        a, b = sorted((sx * kw, sx * hw))
        P.add(box("Cheek", (b - a, 0.27, 0.22), ((a + b) / 2, -0.165, kz0), wood, r=0.02, seg=3))
        P.collide((a, -0.3, kz0), (b, yc, kz0 + 0.22))
    P.add(bx("Nameboard", (-kw, -0.085, KEY_TOP - 0.03), (kw, KEY_BACK + 0.012, KEY_TOP - 0.005), fab("red")))
    P.add(bx("FallRail", (-kw, -0.075, KEY_TOP - 0.03), (kw, yc + 0.005, kz0 + 0.225), wood, r=0.004))
    x0 = _piano_keys(P, ivory, ebony)
    # The upper case, its top (overhanging a little) and two recessed panels on its front.
    lz = kz0 + 0.22                  # the shut lid's top (the cheeks' tops)
    P.add(bx("UpperCase", (-hw, yc, lz), (hw, yb, H - 0.03), wood, r=0.006))
    P.collide((-hw, yc, kz0), (hw, yb, H - 0.03))
    P.add(bx("Top", (-hw - 0.012, -0.06, H - 0.03), (hw + 0.012, yb, H), wood, r=0.012, seg=2))
    P.collide((-hw - 0.012, -0.06, H - 0.03), (hw + 0.012, yb, H))
    for sx in (-1, 1):
        P.add(bx("UpperPanel", (sx * 0.05, yc - 0.006, lz + 0.27), (sx * 0.6, yc, H - 0.08), M("dark_wood", 0.45),
                 r=0.004))
    # The music desk: a bare ledge on the case (house/33: no book of music, nothing on the top).
    dz = lz + 0.245
    P.add(bx("MusicDesk", (-0.42, -0.11, dz), (0.42, yc, dz + 0.02), trim, r=0.006))
    P.add(bx("MusicLip", (-0.42, -0.115, dz), (0.42, -0.105, dz + 0.04), trim, r=0.004))
    P.collide((-0.42, -0.115, dz), (0.42, yc, dz + 0.04))
    # The key lid, hinged at its back: a top board and a front flap over the keys' fronts.
    t = 0.018
    lid = [bx("Lid", (-kw + 0.002, KEY_FRONT - 0.015, lz - t), (kw - 0.002, -0.07, lz), wood, r=0.005),
           bx("LidFlap", (-kw + 0.002, KEY_FRONT - 0.015, KEY_TOP - 0.012), (kw - 0.002, KEY_FRONT - 0.001, lz),
              wood, r=0.005),
           cyl("LidKnob", 0.012, 0.012, (0, 0, 0), brass, n=10, bev=0.004)]
    lid[-1].rotation_euler = (math.radians(90), 0, 0)      # its axis along -y, out of the flap
    lid[-1].location = (0, KEY_FRONT - 0.016, (KEY_TOP + lz) / 2)
    P.hinge("Lid", lid, (0, -0.07, lz), (-1, 0, 0), 92, boxes="each")
    for x in (-0.4, 0.4):
        hinge = cyl("LidHinge", 0.005, 0.06, (0, 0, 0), brass, n=8)
        hinge.rotation_euler = (0, math.radians(90), 0)    # along x
        hinge.location = (x - 0.03, -0.07, lz)
        P.add(hinge)
    P.container("Lid", ["Lid"], (-kw + 0.01, KEY_FRONT + 0.005, KEY_TOP + 0.013), (kw - 0.01, -0.075, lz - t),
                "piano_lid")
    # Socks hide under the keyboard, between the legs (Godot, local [x, z]).
    P.extra["crawl_box"] = {"min": [round(-(hw - 0.09), 3), 0.04], "max": [round(hw - 0.09, 3), 0.28]}
    assert abs(x0 + kw) < 1e-6


# --- Hall and WC ----------------------------------------------------------------------------

@piece("coat_nook", ["Hall"], spot="Coat nook", crawl=0.33, hide="under the bench, among the shoes",
       note="Bench, hook rail and coats in one; the back is the wall side.")
def coat_nook(P):
    oak = M("oak", 0.5)
    W, D = 1.65, 0.4
    seat = 0.45
    for x in (-W / 2 + 0.05, W / 2 - 0.05):
        P.add(box("BenchEnd", (0.05, D, seat), (x, 0, 0), oak, r=0.012))
    P.add(box("BenchTop", (W, D, 0.04), (0, 0, seat - 0.04), oak, r=0.012))
    P.add(cush("BenchPad", (W - 0.1, D - 0.04, 0.07), (0, 0, seat), fab("sage"), puff=(0.03, 0.08, 0.4), cuts=5))
    for x in (-0.5, -0.46, 0.46, 0.5):
        P.add(box("PadStripe", (0.016, D - 0.03, 0.072), (x, 0, seat), fab("stripe"), r=0.004, seg=1))
    # Back board and hook rail.
    P.add(box("Board", (W, 0.025, 0.7), (0, D / 2 - 0.0125, seat + 0.05), M("white", 0.6), r=0.008))
    P.add(box("HookRail", (W, 0.04, 0.1), (0, D / 2 - 0.035, 1.6), oak, r=0.012))
    P.add(box("Hat shelf", (W, 0.3, 0.03), (0, D / 2 - 0.15, 1.85), oak, r=0.01))
    hooks = [-0.6, -0.3, 0.0, 0.3, 0.6]
    for x in hooks:
        P.add(tube("Hook", [(x, D / 2 - 0.05, 1.65), (x, D / 2 - 0.12, 1.65), (x, D / 2 - 0.14, 1.7)], 0.01,
                   M("brass", 0.3, 0.8), n=6))
    # Coats: soft hanging slabs, a scarf with the cream stripes.
    for x, c, L in ((-0.6, "navy", 0.85), (-0.3, "mustard", 0.6), (0.3, "red", 0.75)):
        co = cush("Coat", (0.36, 0.14, L), (x, D / 2 - 0.14, 1.66 - L), fab(c), puff=(0.15, 0.4, 0.02), cuts=4)
        P.add(co)
        P.add(cush("Shoulders", (0.4, 0.16, 0.12), (x, D / 2 - 0.14, 1.6), fab(c), puff=(0.3, 0.3, 0.3), cuts=3))
    P.add(cush("Scarf", (0.12, 0.05, 0.75), (0.0, D / 2 - 0.12, 0.9), fab("pink"), puff=(0.1, 0.4, 0.02), cuts=3))
    for z in (1.0, 1.05):
        P.add(box("ScarfStripe", (0.125, 0.055, 0.02), (0.0, D / 2 - 0.12, z), fab("stripe"), r=0.003, seg=1))
    P.add(cush("Hat", (0.26, 0.22, 0.1), (-0.4, D / 2 - 0.15, 1.88), fab("sage"), puff=(0.3, 0.3, 0.8), cuts=3))
    # Shoes and boots under the bench.
    for x, c in ((-0.55, "red"), (-0.35, "red"), (0.1, "navy"), (0.28, "navy")):
        P.add(cush("Shoe", (0.1, 0.25, 0.08), (x, -0.03, 0.0), M(c, 0.5), puff=(0.2, 0.15, 0.3), cuts=3))
    for x in (0.5, 0.64):
        P.add(cush("Boot", (0.11, 0.26, 0.08), (x, -0.03, 0.0), M("mustard", 0.6), puff=(0.2, 0.15, 0.3), cuts=3))
        P.add(cush("BootLeg", (0.11, 0.12, 0.22), (x, 0.03, 0.06), M("mustard", 0.6), puff=(0.2, 0.2, 0.05), cuts=3))


@piece("doormat", ["Hall"], spot="Doormat", note="Flat (2 cm): no collider needed.")
def doormat(P):
    P.add(cush("Mat", (0.8, 0.5, 0.02), (0, 0, 0), M("cardboard", 0.95), puff=(0.01, 0.01, 0.1), cuts=3))
    for y in (-0.16, -0.13, 0.13, 0.16):
        P.add(box("MatStripe", (0.7, 0.018, 0.022), (0, y, 0), M("red", 0.9), r=0, seg=1))


@piece("toilet", ["WC", "Bathroom"], spot="WC", crawl=None, note="Close-coupled; the back is the wall side.")
def toilet(P):
    por = M("porcelain", 0.15)
    # A rounded pedestal and bowl, a fat cistern, an oak seat and lid.
    P.add(lathe("Pedestal", [(0, 0), (0.15, 0), (0.15, 0.02), (0.12, 0.1), (0.13, 0.25), (0.18, 0.36), (0.19, 0.39),
                             (0, 0.39)], por, n=20, loc=(0, -0.05, 0)))
    bowl = P.body[-1]
    bowl.scale = (1.0, 1.25, 1.0)
    P.add(lathe("Rim", [(0.17, 0.0), (0.2, 0.01), (0.2, 0.025), (0.17, 0.03)], M("oak", 0.4), n=20,
                loc=(0, 0, 0.39)))
    P.body[-1].scale = (1.0, 1.25, 1.0)
    P.body[-1].location = (0, -0.0625, 0)
    P.sock_skip("Rim")     # the seat ring as drawn (physics/09): as a hull it would fill the bowl
    P.sock_mesh(P.body[-1])
    P.add(box("Cistern", (0.42, 0.18, 0.38), (0, 0.22, 0.4), por, r=0.05, seg=3))
    P.add(box("CisternLid", (0.44, 0.2, 0.04), (0, 0.22, 0.78), por, r=0.02))
    P.add(cyl("Flush", 0.02, 0.015, (0.12, 0.22, 0.82), M("brass", 0.3, 0.8), n=10, bev=0.006))
    P.add(box("Lid", (0.36, 0.06, 0.38), (0, 0.11, 0.42), M("oak", 0.4), r=0.04, seg=3))
    # A spare roll on the cistern with a cream stripe.
    P.add(cyl("Roll", 0.055, 0.1, (-0.12, 0.22, 0.82), M("paper", 0.8), n=12, bev=0.015))


@piece("hand_basin", ["WC"], spot="Hand basin (new)", crawl=None, note="Pedestal basin; the back is the wall side.")
def hand_basin(P):
    por = M("porcelain", 0.15)
    P.add(lathe("Pedestal", [(0, 0), (0.12, 0), (0.1, 0.05), (0.07, 0.3), (0.08, 0.66), (0, 0.66)], por, n=16,
                loc=(0, 0.06, 0)))
    b = lathe("Basin", [(0, 0.6), (0.18, 0.62), (0.24, 0.72), (0.25, 0.8), (0.23, 0.82), (0.2, 0.75), (0.08, 0.7),
                        (0, 0.7)], por, n=20)
    b.scale = (1.0, 0.8, 1.0)
    P.add(b)
    P.add(tube("Tap", [(0, 0.17, 0.82), (0, 0.17, 0.92), (0, 0.1, 0.94), (0, 0.06, 0.9)], 0.012, M("brass", 0.3, 0.85),
               n=8))
    P.add(lathe("Soap", [(0, 0), (0.035, 0), (0.035, 0.08), (0.012, 0.1), (0.012, 0.13), (0, 0.13)], M("pink", 0.3),
                n=10, loc=(0.17, 0.1, 0.82)))
    # A hand towel on a ring beside it, with the cream stripes.
    P.add(tube("TowelRing", [(-0.32, 0.18, 0.85), (-0.32, 0.12, 0.85)], 0.008, M("brass", 0.3, 0.85), n=6))
    P.add(cush("Towel", (0.22, 0.03, 0.34), (-0.32, 0.11, 0.48), fab("sage"), puff=(0.04, 0.4, 0.02), cuts=3))
    for z in (0.55, 0.59):
        P.add(box("TowelStripe", (0.224, 0.034, 0.018), (-0.32, 0.11, z), fab("stripe"), r=0.003, seg=1))
