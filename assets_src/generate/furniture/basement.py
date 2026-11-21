"""The basement's furniture (house/04): laundry, workshop, boiler room, storage.

Blender axes: z up, front -y, each piece built around x = 0, y = 0 (build.py centres it).
The washing machine is a Blender MCP asset (assets/washing_machine), not here.
"""

import math
import random

from fkit import (M, ball, box, bun_feet, cush, cyl, fab, face_out, handle_bar, lathe, peg_legs,  # noqa: F401
                  piece, stripes, tube)

ROOMS = ["Laundry", "Workshop", "Boiler room", "Garage"]


# --- Laundry ------------------------------------------------------------------------------

@piece("drying_rack", ["Laundry"], spot="Drying rack", crawl=0.55, hide="under the rails, between the legs",
       note="Open framed: give it thin colliders (legs, rails) or one box above the crawl gap.")
def drying_rack(P):
    st = M("white", 0.5)
    W, D = 1.2, 0.56
    top = 0.95
    # A gull-wing airer: a flat middle deck of rails and two wings dropping out front and back.
    for sx in (-1, 1):
        x = sx * (W / 2 - 0.02)
        # A-frame legs.
        P.add(tube("Leg", [(x, -D / 2, 0.0), (x, -0.12, top)], 0.012, st, n=6))
        P.add(tube("Leg", [(x, D / 2, 0.0), (x, 0.12, top)], 0.012, st, n=6))
        P.add(tube("Frame", [(x, -0.12, top), (x, 0.12, top)], 0.012, st, n=6))
        # Wings: from the deck edge out and down.
        P.add(tube("Wing", [(x, -0.12, top), (x, -0.45, top - 0.2)], 0.01, st, n=6))
        P.add(tube("Wing", [(x, 0.12, top), (x, 0.45, top - 0.2)], 0.01, st, n=6))
        for y in (-D / 2, D / 2):
            P.add(ball("Cap", 0.02, (x, y, 0.01), M("rubber", 0.9), seg=8, rings=5))
    for k in range(5):
        y = -0.12 + 0.24 * k / 4
        P.add(tube("Rail", [(-W / 2, y, top), (W / 2, y, top)], 0.006, st, n=5))
    for k in range(1, 5):
        t = k / 4
        for s in (-1, 1):
            P.add(tube("Rail", [(-W / 2, s * (0.12 + 0.33 * t), top - 0.2 * t),
                                (W / 2, s * (0.12 + 0.33 * t), top - 0.2 * t)], 0.006, st, n=5))
    P.add(tube("Brace", [(-W / 2 + 0.02, -0.2, 0.32), (W / 2 - 0.02, -0.2, 0.32)], 0.008, st, n=6))
    P.add(tube("Brace", [(-W / 2 + 0.02, 0.2, 0.32), (W / 2 - 0.02, 0.2, 0.32)], 0.008, st, n=6))
    # A towel hung over the deck, its two cream stripes near the hem.
    towel = fab("sage")
    tw = 0.5
    for s in (-1, 1):
        P.add(cush("Towel", (tw, 0.025, 0.42), (-0.25, s * 0.02, top - 0.42), towel, puff=(0.02, 0.5, 0.02), cuts=3))
        for z in (top - 0.36, top - 0.32):
            P.add(box("TowelStripe", (tw + 0.004, 0.03, 0.02), (-0.25, s * 0.02, z), fab("stripe"), r=0.003, seg=1))
    P.add(tube("TowelFold", [(-0.25 - tw / 2, 0, top + 0.01), (-0.25 + tw / 2, 0, top + 0.01)], 0.025, towel, n=8))


@piece("laundry_basket", ["Laundry", "Bathroom"], spot="Basket",
       note="Hollow: the game's basket container (COL_WALL) can use this as its look; inside 0.42 x 0.32, 0.36 deep.")
def laundry_basket(P):
    wick = M("cardboard", 0.85)
    # A soft oval wicker tub: a lathe stretched in y, woven ribs, rope handles.
    prof = [(0.0, 0.0), (0.2, 0.0), (0.225, 0.03), (0.24, 0.38), (0.255, 0.4), (0.255, 0.42), (0.235, 0.42),
            (0.222, 0.395), (0.21, 0.04), (0.0, 0.04)]
    b = lathe("Basket", prof, wick, n=24)
    b.scale = (1.0, 0.78, 1.0)
    P.add(b)
    # The Socks lie in it as drawn (physics/09: a trimesh of the tub); the ribs on its outside
    # would fill it as hulls.
    P.sock_skip("Basket", "Rib")
    P.sock_mesh(b)
    for z in (0.1, 0.18, 0.26, 0.34):
        r = 0.226 + 0.014 * z / 0.38
        rib = lathe("Rib", [(r, z - 0.012), (r + 0.012, z), (r, z + 0.012)], M("oak", 0.8), n=24)
        rib.scale = (1.0, 0.78, 1.0)
        P.add(rib)
    for s in (-1, 1):
        P.add(tube("Handle", [(s * 0.25, -0.06, 0.36), (s * 0.29, -0.04, 0.39), (s * 0.29, 0.04, 0.39),
                              (s * 0.25, 0.06, 0.36)], 0.012, fab("stripe"), n=6))
    # Colliders: its floor and four walls (hollow, as the flat's basket), and a wicker lid hinged at
    # its back edge (house/05): Socks hide inside.
    P.collide((-0.24, -0.19, 0.0), (0.24, 0.19, 0.04))
    for a, b in (((-0.27, -0.22, 0.0), (0.27, -0.155, 0.42)), ((-0.27, 0.155, 0.0), (0.27, 0.22, 0.42)),
                 ((-0.27, -0.22, 0.0), (-0.21, 0.22, 0.42)), ((0.21, -0.22, 0.0), (0.27, 0.22, 0.42))):
        P.collide(a, b)
    lid = lathe("Lid", [(0.0, 0.42), (0.262, 0.42), (0.27, 0.43), (0.262, 0.45), (0.0, 0.455)], wick, n=24)
    lid.scale = (1.0, 0.78, 1.0)
    knob = tube("LidKnob", [(-0.05, -0.12, 0.45), (-0.05, -0.12, 0.47), (0.05, -0.12, 0.47), (0.05, -0.12, 0.45)],
                0.01, fab("stripe"), n=6)
    # Hinged on its top back edge, opening 80 deg: it and its knob stay clear of the wall behind
    # (house/12).
    P.hinge("Lid", [lid, knob], (0, 0.21, 0.455), (-1, 0, 0), 80, boxes="each")
    P.container("Lid", ["Lid"], (-0.2, -0.145, 0.045), (0.2, 0.145, 0.41), "basket")


@piece("laundry_shelf", ["Laundry"], spot="Laundry shelf (new; plan has none)",
       note="Optional extra for the laundry's empty north wall.")
def laundry_shelf(P):
    wood = M("oak", 0.55)
    W, D, H = 0.8, 0.34, 1.5
    for sx in (-1, 1):
        P.add(box("Side", (0.03, D, H), (sx * (W / 2 - 0.015), 0, 0), wood, r=0.008))
    for z in (0.06, 0.52, 0.98, 1.46):
        P.add(box("Shelf", (W, D, 0.03), (0, 0, z), wood, r=0.008))
    P.add(box("Back", (W - 0.04, 0.012, H - 0.06), (0, D / 2 - 0.006, 0.03), M("white", 0.8), r=0))
    rng = random.Random(3)
    # Detergent bottles, a box of powder, pegs, folded towels with the cream stripe.
    cols = ["sky", "mustard", "sage", "pink"]
    x = -0.33
    for k in range(4):
        h = rng.uniform(0.22, 0.3)
        r = 0.05
        bt = lathe("Bottle", [(0, 0), (r, 0), (r + 0.004, 0.02), (r, h * 0.8), (r * 0.5, h * 0.92), (0.018, h * 0.95),
                              (0.018, h), (0, h)], M(cols[k], 0.4), n=12, loc=(x, -0.02, 0.995))
        P.add(bt)
        x += 0.12
    P.add(box("Powder", (0.2, 0.14, 0.26), (0.24, 0.0, 0.995), M("red", 0.6), r=0.01))
    P.add(box("PowderBand", (0.204, 0.144, 0.05), (0.24, 0.0, 1.12), M("paper", 0.6), r=0.008, seg=1))
    for k, c in enumerate(("sky", "pink", "sage")):
        z = 0.555 + k * 0.08
        P.add(cush("Towel", (0.34, 0.26, 0.08), (-0.18, 0, z), fab(c), puff=(0.08, 0.05, 0.3), cuts=3))
        P.add(box("Stripe", (0.012, 0.262, 0.02), (-0.33, 0, z + 0.03), fab("stripe"), r=0.003, seg=1))
    P.add(lathe("PegTub", [(0, 0), (0.08, 0), (0.09, 0.12), (0.082, 0.12), (0.072, 0.012), (0, 0.012)],
                M("sky", 0.5), n=14, loc=(0.2, 0, 0.555)))
    for k in range(5):
        a = k * 1.3
        P.add(box("Peg", (0.012, 0.012, 0.07), (0.2 + 0.035 * math.cos(a), 0.035 * math.sin(a), 0.63),
                  M(cols[k % 4], 0.5), r=0.003, seg=1))
    P.add(lathe("Bucket", [(0, 0), (0.12, 0), (0.15, 0.24), (0.14, 0.24), (0.11, 0.012), (0, 0.012)],
                M("sage", 0.5), n=16, loc=(0.0, -0.02, 0.09)))
    P.add(tube("BucketHandle", [(-0.15, -0.02, 0.24), (-0.1, -0.02, 0.36), (0.1, -0.02, 0.36),
                                (0.15, -0.02, 0.24)], 0.006, M("steel", 0.4, 0.6), n=5))


@piece("ironing_board", ["Laundry"], spot="Ironing board (new)", crawl=0.85, hide="under the board, between the X legs")
def ironing_board(P):
    st = M("steel", 0.4, 0.6)
    L, Wd, top = 1.25, 0.36, 0.86
    # The board: a flat plank (house/12), straight-sided with rounded tail corners and a rounded
    # pointed nose, a dusty pink cover with cream stripes.
    import bmesh
    import kit
    bm = bmesh.new()
    hw, rc, nose = Wd / 2, 0.05, 0.36
    pts = []
    for k in range(5):         # the tail's two rounded corners
        a = math.pi + math.pi / 2 * k / 4
        pts.append((-L / 2 + rc + math.cos(a) * rc, -hw + rc + math.sin(a) * rc))
    xs = L / 2 - nose
    for k in range(13):        # the nose: a quadratic curve from the straight side to the tip
        t = k / 12
        x = (1 - t) ** 2 * xs + 2 * (1 - t) * t * (L / 2) + t * t * (L / 2)
        y = (1 - t) ** 2 * -hw + 2 * (1 - t) * t * -hw
        pts.append((x, y))
    pts += [(x, -y) for x, y in reversed(pts[5:-1])]
    for k in range(5):
        a = math.pi / 2 + math.pi / 2 * k / 4
        pts.append((-L / 2 + rc + math.cos(a) * rc, hw - rc + math.sin(a) * rc))
    lo = [bm.verts.new((x, y, top - 0.025)) for x, y in pts]
    hi = [bm.verts.new((x, y, top)) for x, y in pts]
    bm.faces.new(list(reversed(lo)))
    bm.faces.new(hi)
    for i in range(len(pts)):
        j = (i + 1) % len(pts)
        bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bmesh.ops.triangulate(bm, faces=[f for f in bm.faces if len(f.verts) > 4])
    ob = kit.obj_from_bm("Board", bm, fab("pink"))
    P.add(ob)
    for x in (-0.2, -0.14):
        P.add(box("Stripe", (0.03, Wd + 0.004, 0.027), (x, 0, top - 0.026), fab("stripe"), r=0.003, seg=1))
    # X legs.
    for s in (-1, 1):
        for dy in (-0.13, 0.13):
            P.add(tube("Leg", [(s * 0.35, dy, 0.0), (-s * 0.3, dy, top - 0.03)], 0.011, st, n=6))
        P.add(tube("Foot", [(s * 0.35, -0.16, 0.012), (s * 0.35, 0.16, 0.012)], 0.016, M("rubber", 0.9), n=6))
    P.add(tube("Pivot", [(0.0, -0.14, top / 2 - 0.01), (0.0, 0.14, top / 2 - 0.01)], 0.01, st, n=6))
    # The iron, standing on its heel at the tail.
    iron = M("sky", 0.35)
    P.add(cush("Iron", (0.2, 0.11, 0.08), (-0.43, 0, top), iron, puff=(0.1, 0.3, 0.3), cuts=3))
    P.add(tube("IronHandle", [(-0.5, 0, top + 0.07), (-0.48, 0, top + 0.13), (-0.38, 0, top + 0.13),
                              (-0.36, 0, top + 0.07)], 0.014, M("white", 0.5), n=6))


# The Whiteboard's writing face (progression/01): its size and centre height, Blender metres.
BOARD_W, BOARD_H, BOARD_Z = 0.96, 0.72, 1.26


@piece("collection_board", ["Laundry"], spot="Whiteboard (progression/01, by the Upgrade station)",
       note="The Whiteboard (progression/01, Q639, Q667): a marker board on a wheeled easel. Node Board = the "
            "writing face only, 4:3 (0.96 x 0.72 m), material 'paper', UV u 0..1 left to right and v 0..1 top to "
            "bottom (glTF): the game draws the Collections' legend onto it (game/campaign/whiteboard_view.gd).")
def collection_board(P):
    import bmesh
    import kit
    alu = M("steel", 0.35, 0.7)
    W, H, zc = BOARD_W, BOARD_H, BOARD_Z
    fr = 0.03                      # the aluminium frame's width
    z0, z1 = zc - H / 2, zc + H / 2
    # The board: a white panel in a rounded aluminium frame, the writing face a quad of its own.
    P.add(box("Panel", (W + 0.01, 0.022, H + 0.01), (0, 0.004, z0 - 0.005), M("white", 0.4), r=0.004, seg=1))
    for z in (z0 - fr, z1):
        P.add(box("Frame", (W + 2 * fr, 0.034, fr), (0, 0.0, z), alu, r=0.008, seg=2))
    for s in (-1, 1):
        P.add(box("Frame", (fr, 0.034, H), (s * (W + fr) / 2, 0.0, z0), alu, r=0.008, seg=2))
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    y = -0.0075
    vs = [bm.verts.new((-W / 2, y, z0)), bm.verts.new((W / 2, y, z0)), bm.verts.new((W / 2, y, z1)),
          bm.verts.new((-W / 2, y, z1))]
    f = bm.faces.new(vs)
    for loop, (u, v) in zip(f.loops, ((0, 0), (1, 0), (1, 1), (0, 1))):
        loop[uv].uv = (u, v)
    bm.normal_update()
    if f.normal.y > 0:
        bmesh.ops.reverse_faces(bm, faces=[f])
    P.named("Board", [kit.obj_from_bm("Board", bm, M("paper", 0.25), smooth=False)])
    # The marker tray along the bottom, with three markers and a felt eraser on it.
    ty = -0.045
    P.add(box("Tray", (W * 0.8, 0.07, 0.012), (0, ty + 0.01, z0 - fr - 0.012), alu, r=0.004, seg=1))
    P.add(box("TrayLip", (W * 0.8, 0.008, 0.024), (0, ty - 0.021, z0 - fr - 0.012), alu, r=0.003, seg=1))
    for k, c in enumerate(("red", "navy", "sage_dark")):
        x = -0.3 + k * 0.07
        zt = z0 - fr + 0.012
        P.add(tube("Marker", [(x, ty, zt), (x + 0.12, ty, zt)], 0.009, M(c, 0.45), n=8))
        P.add(tube("Cap", [(x + 0.12, ty, zt), (x + 0.15, ty, zt)], 0.01, M(c, 0.35), n=8))
    P.add(box("Eraser", (0.11, 0.045, 0.03), (0.25, ty + 0.002, z0 - fr), M("charcoal", 0.6), r=0.006, seg=1))
    P.add(box("EraserFelt", (0.11, 0.045, 0.008), (0.25, ty + 0.002, z0 - fr - 0.0), fab("stripe"), r=0.003, seg=1))
    # The easel: two posts on caster feet, a crossbar, clamps holding the board.
    px = (W + 2 * fr) / 2 + 0.03
    top = z1 + fr + 0.12
    for s in (-1, 1):
        x = s * px
        P.add(tube("Post", [(x, 0.0, 0.09), (x, 0.0, top)], 0.016, alu, n=10))
        P.add(ball("PostCap", 0.02, (x, 0.0, top), M("charcoal", 0.5), seg=10, rings=6))
        for z in (z0 + 0.06, z1 - 0.06):
            P.add(box("Clamp", (0.06, 0.04, 0.04), (x - s * 0.02, 0.0, z - 0.02), M("charcoal", 0.5), r=0.008))
        P.add(tube("Foot", [(x, -0.27, 0.075), (x, 0.27, 0.075)], 0.02, alu, n=8))
        for fy in (-0.25, 0.25):
            P.add(box("Fork", (0.03, 0.04, 0.04), (x, fy, 0.035), M("charcoal", 0.5), r=0.006))
            P.add(tube("Wheel", [(x - 0.012, fy, 0.03), (x + 0.012, fy, 0.03)], 0.03, M("rubber", 0.9), n=12))
    P.add(tube("Crossbar", [(-px, 0.0, 0.32), (px, 0.0, 0.32)], 0.014, alu, n=8))
    # Collision: the board, the posts, the feet (Socks roll under the board between the feet).
    P.collide((-px, -0.08, z0 - fr - 0.03), (px, 0.03, z1 + fr))
    for s in (-1, 1):
        P.collide((s * px - 0.025, -0.025, 0.0), (s * px + 0.025, 0.025, top + 0.02))
        P.collide((s * px - 0.03, -0.29, 0.0), (s * px + 0.03, 0.29, 0.1))
    P.collide((-px, -0.02, 0.3), (px, 0.02, 0.34))


# --- Workshop -------------------------------------------------------------------------------

@piece("workbench", ["Workshop"], spot="Workbench", crawl=0.22,
       hide="under the bench: below the lower shelf (0.22) and between shelf and top")
def workbench(P):
    wood = M("oak", 0.6)
    dark = M("dark_wood", 0.6)
    W, D, top = 2.5, 0.65, 0.9
    P.add(box("Top", (W, D, 0.07), (0, 0, top - 0.07), wood, r=0.015))
    for x in (-W / 2 + 0.07, W / 2 - 0.07):
        for y in (-D / 2 + 0.07, D / 2 - 0.07):
            P.add(box("Leg", (0.08, 0.08, top - 0.07), (x, y, 0), dark, r=0.012))
    P.add(box("Shelf", (W - 0.1, D - 0.1, 0.03), (0, 0, 0.22), wood, r=0.008))
    P.add(box("Rail", (W - 0.1, 0.04, 0.08), (0, -D / 2 + 0.07, top - 0.15), dark, r=0.01))
    # Pegboard and tools.
    pb = M("cardboard", 0.85)
    P.add(box("Pegboard", (W - 0.1, 0.03, 0.75), (0, D / 2 - 0.015, top + 0.05), pb, r=0.01))
    P.add(box("PegboardTrim", (W - 0.06, 0.04, 0.04), (0, D / 2 - 0.02, top + 0.8), dark, r=0.01))
    y = D / 2 - 0.05
    red, steel = M("red", 0.45), M("steel", 0.35, 0.7)
    # Hammer.
    P.add(box("HammerHandle", (0.03, 0.025, 0.3), (-0.95, y, top + 0.3), M("mustard", 0.5), r=0.01))
    P.add(box("HammerHead", (0.14, 0.04, 0.045), (-0.95, y, top + 0.6), steel, r=0.01))
    # Screwdrivers.
    for k, c in enumerate(("red", "sky", "mustard")):
        x = -0.72 + k * 0.07
        P.add(cyl("Driver", 0.016, 0.1, (x, y, top + 0.45), M(c, 0.4), n=8, bev=0.006))
        P.add(cyl("Shaft", 0.004, 0.12, (x, y, top + 0.33), steel, n=6))
    # Wrenches, a saw, a coil of string.
    for k in range(3):
        x = -0.38 + k * 0.08
        P.add(box("Wrench", (0.025, 0.012, 0.2 + 0.04 * k), (x, y, top + 0.32), steel, r=0.006, seg=1))
    P.add(box("Saw", (0.42, 0.01, 0.14), (0.1, y, top + 0.42), steel, r=0.01, seg=1))
    P.add(box("SawHandle", (0.1, 0.03, 0.12), (-0.15, y, top + 0.42), red, r=0.02))
    coil = lathe("Coil", [(0.06, -0.025), (0.09, -0.02), (0.1, 0), (0.09, 0.02), (0.06, 0.025), (0.055, 0)],
                 fab("stripe"), n=14)
    coil.rotation_euler = (math.pi / 2, 0, 0)
    coil.location = (0.6, y - 0.02, top + 0.55)
    P.add(coil)
    # A vice at the left corner, a red toolbox and a jar of screws on the top.
    P.add(box("Vice", (0.16, 0.2, 0.1), (-1.05, -0.2, top), M("sage_dark", 0.4), r=0.015))
    P.add(box("ViceJaw", (0.18, 0.04, 0.08), (-1.05, -0.32, top + 0.02), steel, r=0.01))
    P.add(tube("ViceBar", [(-1.15, -0.36, top + 0.06), (-0.95, -0.36, top + 0.06)], 0.008, steel, n=6))
    P.add(box("Toolbox", (0.42, 0.22, 0.18), (0.75, -0.05, top), red, r=0.025))
    P.add(box("ToolboxLid", (0.44, 0.24, 0.03), (0.75, -0.05, top + 0.18), red, r=0.012))
    P.add(tube("ToolboxHandle", [(0.63, -0.05, top + 0.21), (0.66, -0.05, top + 0.26), (0.84, -0.05, top + 0.26),
                                 (0.87, -0.05, top + 0.21)], 0.01, M("charcoal", 0.5), n=6))
    P.add(lathe("Jar", [(0, 0), (0.05, 0), (0.055, 0.1), (0.04, 0.12), (0, 0.12)], M("sky", 0.2), n=12,
                loc=(0.3, 0.1, top)))
    # Wooden crates on the lower shelf.
    for x in (-0.7, 0.4):
        P.add(box("Crate", (0.5, 0.4, 0.26), (x, 0.0, 0.25), wood, r=0.01))
        P.add(box("CrateBand", (0.505, 0.405, 0.05), (x, 0.0, 0.41), dark, r=0.008, seg=1))


@piece("tool_shelves", ["Workshop"], spot="Tool shelves", crawl=0.18, hide="under the bottom shelf")
def tool_shelves(P):
    wood = M("oak", 0.6)
    st = M("grey", 0.5, 0.3)
    W, D, H = 1.9, 0.42, 1.8
    for x in (-W / 2 + 0.02, W / 2 - 0.02, 0):
        for y in (-D / 2 + 0.02, D / 2 - 0.02):
            P.add(box("Post", (0.035, 0.035, H), (x, y, 0), st, r=0.006, seg=1))
    zs = (0.2, 0.62, 1.04, 1.46)
    for z in zs:
        P.add(box("Shelf", (W, D, 0.03), (0, 0, z), wood, r=0.008))
    rng = random.Random(5)
    cols = ["red", "sky", "mustard", "sage", "navy"]
    for z in zs[:3]:
        x = -W / 2 + 0.08
        while x < W / 2 - 0.25:
            kind = rng.random()
            if kind < 0.45:
                w = rng.uniform(0.3, 0.42)
                h = rng.uniform(0.18, 0.3)
                c = rng.choice(cols)
                P.add(box("Tub", (w, D - 0.06, h), (x + w / 2, 0, z + 0.03), M(c, 0.5), r=0.02))
                P.add(box("TubLid", (w + 0.01, D - 0.05, 0.025), (x + w / 2, 0, z + 0.03 + h), M(c, 0.45), r=0.01))
            elif kind < 0.75:
                w = 0.13
                for k in range(rng.randint(2, 3)):
                    P.add(cyl("Tin", 0.055, 0.12, (x + w / 2 + k * 0.12, 0, z + 0.03), M(rng.choice(cols), 0.4), n=12,
                              bev=0.008))
                w = 0.36
            else:
                w = 0.4
                P.add(box("Box", (w, D - 0.08, 0.2), (x + w / 2, 0, z + 0.03), M("cardboard", 0.85), r=0.008))
                P.add(box("Tape", (0.06, D - 0.075, 0.204), (x + w / 2, 0, z + 0.03), M("sheet", 0.6), r=0.004, seg=1))
            x += w + 0.06
    # The top shelf: a coiled hose and a bucket.
    P.add(lathe("Hose", [(0.12, 1.49), (0.16, 1.5), (0.18, 1.54), (0.16, 1.58), (0.12, 1.59), (0.1, 1.54)],
                M("sage", 0.5), n=16, loc=(-0.5, 0, 0)))
    P.add(lathe("Bucket", [(0, 0), (0.11, 0), (0.14, 0.22), (0.13, 0.22), (0.1, 0.012), (0, 0.012)],
                M("red", 0.5), n=14, loc=(0.4, 0, 1.49)))


@piece("paint_tins", ["Workshop"], spot="Paint tins")
def paint_tins(P):
    rng = random.Random(9)
    st = M("steel", 0.35, 0.6)
    cols = ["sage", "pink", "white", "sky", "mustard", "wall"]
    P.add(box("Pallet", (0.7, 0.44, 0.08), (0, 0, 0), M("oak", 0.7), r=0.008))
    spots = [(-0.2, -0.08, 0.08, 0.13), (0.06, -0.1, 0.08, 0.11), (0.22, 0.08, 0.08, 0.13), (-0.12, 0.12, 0.08, 0.11),
             (-0.2, -0.08, 0.26, 0.11), (0.1, 0.1, 0.26, 0.09)]
    for k, (x, y, z, r) in enumerate(spots):
        h = 0.17 if r > 0.12 else 0.15
        if z > 0.1:
            z = 0.08 + (0.18 if r > 0.1 else 0.16)
        P.add(cyl("Tin", r, h, (x, y, z), st, n=16, bev=0.008))
        P.add(cyl("Label", r + 0.003, h * 0.55, (x, y, z + h * 0.2), M(cols[k % len(cols)], 0.6), n=16))
        P.add(cyl("Lid", r * 0.92, 0.012, (x, y, z + h), M(cols[k % len(cols)], 0.4), n=16, bev=0.004))
    # A drippy roller tray and a brush.
    P.add(box("Tray", (0.3, 0.38, 0.04), (0.0, -0.05, 0.0), M("charcoal", 0.6), r=0.01))
    P.add(box("Paint", (0.24, 0.16, 0.02), (0.0, -0.13, 0.025), M("sage", 0.3), r=0.008, seg=1))
    P.add(cyl("Brush", 0.015, 0.2, (0.18, -0.12, 0.27), M("oak", 0.5), n=8, bev=0.006))


# --- Boiler room --------------------------------------------------------------------------------

@piece("boiler", ["Boiler room"], spot="Boiler", crawl=0.12, hide="the narrow gap under the boiler's kick plate")
def boiler(P):
    wh = M("white", 0.45)
    st = M("steel", 0.3, 0.8)
    cu = M("brass", 0.35, 0.9)
    W, D, H = 0.62, 0.58, 1.5
    P.add(box("Plinth", (W - 0.06, D - 0.06, 0.12), (0, 0.02, 0), M("charcoal", 0.6), r=0.01))
    P.add(box("Casing", (W, D, H - 0.12), (0, 0, 0.12), wh, r=0.06, seg=3))
    P.add(box("Panel", (W - 0.14, 0.02, 0.24), (0, -D / 2, 1.05), M("grey", 0.5), r=0.02))
    for k, c in enumerate(("red", "mustard", "sky")):
        P.add(face_out(cyl("Dial", 0.028, 0.03, (0, 0, 0), M(c, 0.4), n=12, bev=0.01),
                       (-0.14 + k * 0.14, -D / 2 + 0.01, 1.17)))
    P.add(face_out(cyl("Gauge", 0.06, 0.02, (0, 0, 0), M("paper", 0.4), n=16, bev=0.008), (0, -D / 2 + 0.01, 1.38)))
    P.add(box("Needle", (0.005, 0.005, 0.045), (0.01, -D / 2 - 0.03, 1.36), M("red", 0.4), r=0, seg=1))
    P.add(box("Vent", (W - 0.2, 0.012, 0.18), (0, -D / 2 + 0.002, 0.2), M("grey", 0.6), r=0.01))
    for k in range(4):
        P.add(box("Slot", (W - 0.24, 0.02, 0.012), (0, -D / 2 - 0.003, 0.24 + k * 0.035), M("charcoal", 0.6), r=0, seg=1))
    # Copper pipes out of the top, bending into the wall, with a red valve wheel.
    for k, x in enumerate((-0.18, -0.06, 0.06, 0.18)):
        pts = [(x, 0.05, H - 0.02), (x, 0.05, H + 0.18), (x, 0.12, H + 0.28), (x, D / 2 + 0.02, H + 0.3)]
        P.add(tube("Pipe", pts, 0.018, cu, n=8))
        P.sock_tube(pts, 0.018)   # one hull a run: a bent one would roof the boiler's top (physics/09)
    P.sock_skip("Pipe")
    P.add(lathe("Valve", [(0.0, 0), (0.05, 0), (0.06, 0.01), (0.05, 0.02), (0, 0.02)], M("red", 0.4), n=12,
                loc=(0.06, 0.05, H + 0.12)))
    # A flue up the back.
    P.add(cyl("Flue", 0.07, 0.35, (0, D / 2 - 0.12, H - 0.02), st, n=16))


@piece("water_tank", ["Boiler room"], spot="Water tank")
def water_tank(P):
    jacket = fab("red")
    cu = M("brass", 0.35, 0.9)
    R, H = 0.33, 1.45
    # A copper cylinder in a padded red jacket, quilted in bands, the cream stripe at the top.
    P.add(cyl("Stand", R * 0.85, 0.1, (0, 0, 0), M("charcoal", 0.6), n=16, bev=0.01))
    prof = [(0, 0.1)]
    for k in range(6):
        z0 = 0.1 + (H - 0.25) * k / 6
        z1 = 0.1 + (H - 0.25) * (k + 1) / 6
        prof += [(R - 0.012, z0 + 0.005), (R, z0 + 0.04), (R, z1 - 0.04), (R - 0.012, z1 - 0.005)]
    prof += [(R - 0.03, H - 0.12), (R * 0.75, H - 0.04), (R * 0.4, H), (0, H)]
    P.add(lathe("Jacket", prof, jacket, n=24))
    for z in (H - 0.24, H - 0.19):
        P.add(lathe("Stripe", [(R - 0.005, z - 0.016), (R + 0.006, z - 0.012), (R + 0.006, z + 0.012),
                               (R - 0.005, z + 0.016)], fab("stripe"), n=24))
    P.add(cyl("Dome", 0.08, 0.06, (0, 0, H - 0.01), cu, n=12, bev=0.02))
    P.add(tube("Pipe", [(0, 0, H + 0.04), (0, 0, H + 0.15), (0, 0.15, H + 0.25), (0, R + 0.08, H + 0.25)], 0.018, cu, n=8))
    P.add(tube("Pipe", [(R - 0.02, 0, 0.3), (R + 0.08, 0, 0.3), (R + 0.1, 0.1, 0.3), (R + 0.1, R + 0.05, 0.3)],
               0.018, cu, n=8))


# --- Garage (house/11: the storage room became the garage) -----------------------------------------------------------------------------------

def _rack(P, W, D, H, seed, levels=4):
    wood = M("oak", 0.6)
    st = M("grey", 0.5, 0.3)
    for x in (-W / 2 + 0.02, W / 2 - 0.02):
        for y in (-D / 2 + 0.02, D / 2 - 0.02):
            P.add(box("Post", (0.035, 0.035, H), (x, y, 0), st, r=0.006, seg=1))
    zs = [0.2 + (H - 0.3) * k / (levels - 1) for k in range(levels)]
    for z in zs:
        P.add(box("Shelf", (W, D, 0.03), (0, 0, z), wood, r=0.008))
    rng = random.Random(seed)
    cols = ["mustard", "sky", "sage", "pink", "red", "navy"]
    for z in zs:
        x = -W / 2 + 0.06
        while True:
            w = rng.uniform(0.32, 0.5)
            if x + w > W / 2 - 0.04:
                break
            h = rng.uniform(0.2, min(0.36, (H - 0.3) / (levels - 1) - 0.08))
            if rng.random() < 0.55:
                P.add(box("Box", (w, D - 0.06, h), (x + w / 2, 0, z + 0.03), M("cardboard", 0.85), r=0.01))
                P.add(box("Tape", (0.05, D - 0.055, h + 0.004), (x + w / 2, 0, z + 0.028), M("sheet", 0.6), r=0.004, seg=1))
            else:
                c = rng.choice(cols)
                P.add(box("Tub", (w, D - 0.06, h), (x + w / 2, 0, z + 0.03), M(c, 0.45), r=0.025))
                P.add(box("TubLid", (w + 0.012, D - 0.048, 0.03), (x + w / 2, 0, z + 0.03 + h), M(c, 0.4), r=0.012))
            x += w + 0.05
    return zs


@piece("shelf_rack", ["Garage"], spot="Shelf rack, Wall shelving", crawl=0.17, hide="under the bottom shelf",
       note="Used twice in the garage, each against a wall (house/11; the third left for the Old Tree, house/45, Q1534).")
def shelf_rack(P):
    _rack(P, 1.8, 0.45, 1.9, 11)


@piece("storage_boxes", ["Garage", "Junk loft"], spot="Boxes, Xmas boxes",
       hide="the gap behind the stack")
def storage_boxes(P):
    P.sock_dev = 0.005   # its merged Sock colliders keep the tops Socks rest on (physics/09)
    card = M("cardboard", 0.85)
    tape = M("sheet", 0.6)
    rng = random.Random(4)
    stacks = [(-0.45, 0.1, 3), (0.12, 0.18, 2), (0.5, -0.12, 1), (-0.05, -0.3, 1)]
    for x, y, n in stacks:
        z = 0.0
        for k in range(n):
            w, d, h = rng.uniform(0.38, 0.5), rng.uniform(0.34, 0.44), rng.uniform(0.26, 0.36)
            ob = box("Box", (w, d, h), (0, 0, 0), card, r=0.012)
            t = box("Tape", (0.06, d + 0.006, h + 0.004), (0, 0, -0.002), tape, r=0.004, seg=1)
            yaw = rng.uniform(-0.12, 0.12)
            for o in (ob, t):
                o.location = (x, y, z)
                o.rotation_euler.z = yaw
                P.add(o)
            z += h
    # The festive one: red with a cream stripe, its flaps open.
    x, y = 0.5, -0.12
    P.add(box("Xmas", (0.4, 0.36, 0.3), (x, y, 0.3), M("red", 0.6), r=0.012))
    for z in (0.5, 0.54):
        P.add(box("XmasStripe", (0.404, 0.364, 0.018), (x, y, z), fab("stripe"), r=0.004, seg=1))
    for s in (-1, 1):
        f = box("Flap", (0.4, 0.17, 0.008), (0, 0, 0), M("red", 0.6), r=0.003, seg=1)
        f.location = (x, y + s * 0.18, 0.6)
        f.rotation_euler.x = s * math.radians(-60)
        P.add(f)
    P.add(ball("Bauble", 0.06, (x - 0.08, y - 0.02, 0.6), M("mustard", 0.2, 0.5), seg=10, rings=7))
    P.add(ball("Bauble", 0.05, (x + 0.08, y + 0.04, 0.6), M("sky", 0.2, 0.5), seg=10, rings=7))


def _wheel(P, x, y, z, R, rim, tyre):
    """A bicycle wheel in the xz plane centred at (x, y, z)."""
    t = lathe("Tyre", [(R - 0.035, -0.02), (R - 0.01, -0.024), (R, 0), (R - 0.01, 0.024), (R - 0.035, 0.02)],
              tyre, n=24)
    t.rotation_euler.x = math.pi / 2
    t.location = (x, y, z)
    P.add(t)
    hub = cyl("Hub", 0.03, 0.08, (0, 0, 0), rim, n=8)
    hub.rotation_euler.x = math.pi / 2
    hub.location = (x, y + 0.04, z)
    P.add(hub)
    for k in range(6):
        a = math.pi * k / 6
        P.add(tube("Spoke", [(x - math.cos(a) * (R - 0.03), y, z - math.sin(a) * (R - 0.03)),
                             (x + math.cos(a) * (R - 0.03), y, z + math.sin(a) * (R - 0.03))], 0.004, rim, n=4,
                   caps=False))


def _bike(P, x0, y, s, frame_c, seat_c):
    """A chunky bike side-on along x; s scales it (1 adult)."""
    tyre = M("rubber", 0.9)
    rim = M("steel", 0.35, 0.7)
    fr = M(frame_c, 0.4)
    R = 0.34 * s
    wb = 1.05 * s
    rear, front = (x0 - wb / 2, R), (x0 + wb / 2, R)
    _wheel(P, rear[0], y, R, R, rim, tyre)
    _wheel(P, front[0], y, R, R, rim, tyre)
    crank = (x0 - 0.05 * s, R * 0.95)
    seat = (x0 - 0.2 * s, R + 0.55 * s)
    head = (x0 + 0.35 * s, R + 0.5 * s)
    r = 0.022 * s
    for a, b in ((rear, crank), (crank, seat), (seat, rear), (seat, head), (crank, head), (head, front)):
        P.add(tube("Frame", [(a[0], y, a[1]), (b[0], y, b[1])], r, fr, n=8))
    P.add(cush("Saddle", (0.24 * s, 0.12 * s, 0.06 * s), (seat[0] - 0.02, y, seat[1] + 0.02), M(seat_c, 0.6),
               puff=(0.2, 0.3, 0.4), cuts=3))
    hb = (head[0] - 0.04 * s, head[1] + 0.18 * s)
    P.add(tube("Stem", [(head[0], y, head[1]), (hb[0], y, hb[1])], r, fr, n=8))
    P.add(tube("Bars", [(hb[0] - 0.08, y - 0.25 * s, hb[1]), (hb[0], y - 0.22 * s, hb[1]), (hb[0], y + 0.22 * s, hb[1]),
                        (hb[0] - 0.08, y + 0.25 * s, hb[1])], 0.014, rim, n=6))
    for sy in (-1, 1):
        P.add(cyl("Grip", 0.02, 0.1, (0, 0, 0), M(seat_c, 0.6), n=8, bev=0.008))
        g = P.body[-1]
        g.rotation_euler.x = math.pi / 2
        g.location = (hb[0] - 0.08, y + sy * (0.25 * s + (0.1 if sy > 0 else 0)), hb[1])
    P.add(cyl("Chainring", 0.09 * s, 0.01, (0, 0, 0), rim, n=12))
    c = P.body[-1]
    c.rotation_euler.x = math.pi / 2
    c.location = (crank[0], y - 0.03, crank[1])
    # A mudguard in the stripe colour over the back wheel.
    pts = [(rear[0] + math.cos(a) * (R + 0.03), y, R + math.sin(a) * (R + 0.03))
           for a in [math.radians(d) for d in range(20, 170, 25)]]
    P.add(tube("Guard", pts, 0.02 * s, fab("stripe"), n=6))


@piece("bikes", ["Garage"], spot="Bikes", hide="between the wheels",
       note="Two bikes side by side, facing along x; collide as one box or per bike.")
def bikes(P):
    _bike(P, 0.0, 0.2, 1.0, "sage", "charcoal")
    _bike(P, 0.15, -0.25, 0.72, "red", "mustard")


@piece("ski_bag", ["Garage"], spot="Ski bag", crawl=0.75, hide="under the brackets",
       note="Wall-hung: the bag rests on two brackets; the back is the wall side.")
def ski_bag(P):
    bag = fab("navy")
    L = 1.75
    z = 0.95
    P.add(cush("Bag", (L, 0.22, 0.26), (0, 0, z), bag, puff=(0.03, 0.25, 0.2), cuts=6))
    for x in (-L / 2 + 0.25, -L / 2 + 0.31):
        P.add(box("Stripe", (0.035, 0.235, 0.272), (x, 0, z - 0.006), fab("stripe"), r=0.006, seg=1))
    P.add(tube("Strap", [(-0.3, -0.112, z + 0.05), (-0.25, -0.13, z + 0.3), (0.25, -0.13, z + 0.3),
                         (0.3, -0.112, z + 0.05)], 0.012, M("charcoal", 0.6), n=6))
    for x in (-0.55, 0.55):
        P.add(box("Bracket", (0.05, 0.28, 0.04), (x, 0.01, z - 0.04), M("grey", 0.4, 0.4), r=0.01))
        P.add(box("BracketPlate", (0.06, 0.02, 0.2), (x, 0.14, z - 0.15), M("grey", 0.4, 0.4), r=0.008))
    # A pair of poles leaning against the wall at the end.
    for dx in (0.0, 0.05):
        P.add(tube("Pole", [(L / 2 + 0.12 + dx, 0.1, 0.0), (L / 2 + 0.05 + dx, 0.12, 1.2)], 0.009,
                   M("steel", 0.35, 0.7), n=6))
        P.add(cyl("Grip", 0.016, 0.14, (L / 2 + 0.05 + dx, 0.12, 1.1), M("charcoal", 0.6), n=8, bev=0.005))


# --- Garage (house/10, Q431: the storage room becomes a garage) ------------------------------

def _bake(ob):
    """Applies ob's modifiers into its mesh."""
    import bpy
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.convert(target="MESH")
    return ob


def _cutter(size, loc, m):
    import kit
    return kit.obj_from_bm("Cutter", kit.cube_bm(size, loc), m, smooth=False)


def _bool(ob, cutter, op="DIFFERENCE"):
    """Applies an exact boolean of cutter on ob, then removes the cutter."""
    import bpy
    md = ob.modifiers.new("Bool", "BOOLEAN")
    md.operation = op
    md.object = cutter
    md.solver = "EXACT"
    _bake(ob)
    bpy.data.objects.remove(cutter)
    return ob


def _copy(ob, name):
    import bpy
    c = ob.copy()
    c.data = ob.data.copy()
    c.name = name
    bpy.context.scene.collection.objects.link(c)
    return c


def _smooth(ob, deg=35):
    import bpy
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.shade_smooth_by_angle(angle=math.radians(deg))
    return ob


def _pane(name, pts, m, t=0.01):
    """A flat pane through the 3D points pts (a convex polygon), t thick."""
    import bmesh
    import kit
    bm = bmesh.new()
    bm.faces.new([bm.verts.new(p) for p in pts])
    ob = kit.obj_from_bm(name, bm, m, smooth=False)
    md = ob.modifiers.new("Solid", "SOLIDIFY")
    md.thickness = t
    md.offset = 0.0
    return ob


def _glass():
    """The car's window glass: pale, alpha 0.3 (blended)."""
    import kit
    m = kit.mat("glass", (0.78, 0.88, 0.9), rough=0.05)
    m.node_tree.nodes["Principled BSDF"].inputs["Alpha"].default_value = 0.3
    m.diffuse_color = (*m.diffuse_color[:3], 0.3)
    m.surface_render_method = "BLENDED"
    return m


@piece("car", ["Garage"], spot="Car (house/11: the garage, Q431)", crawl=0.22,
       hide="inside on the floor, under the two front seats, under the rear bench, in the boot; under the car",
       note="Compact three-door hatchback, 1.62 m wide without the wing mirrors, its nose facing +z (the "
            "piece front), length along z. "
            "Door_L (the -x side) and Door_R hinge at their front edge about y and swing out; Boot (the "
            "tailgate with its glass) hinges at the roof's back edge about x and lifts. Hollow cabin: floor "
            "top 0.32 m, 0.14 m under the front seats, 0.12 m under the rear bench, a boot well about "
            "1.0 x 0.6 m behind it. Window glass is the material 'glass' (alpha 0.3). crawl_gap is the "
            "ground clearance between the wheels; crawl_box (Godot, local [x, z]) the clear rect under the "
            "car, inside the wheels (house/11). Containers: Cabin (both doors) and Boot; colliders: the "
            "floor pan, bonnet, sides, roof, wheel tubs and wheels (the seats have none: Socks lie under "
            "them).")
def car(P):
    import bmesh
    import kit
    from mathutils import Vector
    L, W, CL, BELT, ROOF = 3.5, 1.62, 0.22, 0.92, 1.42
    WS_Y, WSR_Y, RB_Y, RR_Y = -0.78, -0.2, 1.65, 1.45     # windscreen and rear glass: bottom and top y
    XB, XR = W / 2 - 0.11, W / 2 - 0.25                   # side glass x at the belt and at the roof
    DF, DB = -0.78, 0.42                                  # the doors' front and back edge
    WY, WR, FLOOR = 1.15, 0.32, CL + 0.1                   # wheel centres at y +-WY, wheel radius, floor top
    paint = M("red", 0.35)
    cream = M("stripe", 0.4)
    steel = M("steel", 0.3, 0.8)
    glass = _glass()
    seat = fab("sofa")

    # The lower body: a rounded tub, the bonnet sloping down to the nose.
    bm = kit.cube_bm((W, L, BELT - CL), (0, 0, CL))
    bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], plane_co=(0, WS_Y, 0),
                           plane_no=(0, 1, 0))
    for v in bm.verts:
        if v.co.y < -L / 2 + 1e-4 and v.co.z > BELT - 1e-4:
            v.co.z -= 0.2
    body = kit.obj_from_bm("Shell", bm, paint, smooth=False)
    kit.bevel(body, 0.15, 3, harden=False, angle=30)
    _bake(body)
    for y in (-WY, WY):        # the wheel arches
        for sx in (-1, 1):
            c = lathe("Cutter", [(0, -0.3), (WR + 0.07, -0.3), (WR + 0.07, 0.3), (0, 0.3)], paint, n=20, smooth=False)
            c.rotation_euler.y = math.pi / 2
            c.location = (sx * (W / 2 + 0.04), y, WR)
            _bool(body, c)
    y0, y1 = WS_Y + 0.06, L / 2 - 0.07                    # the cabin and boot hollow
    _bool(body, _cutter((W - 0.14, y1 - y0, 1.0), (0, (y0 + y1) / 2, FLOOR), paint))
    # The openings: each part is the shell inside its box; the shell loses the box plus a gap.
    boxes = {"Door_L": ((0.4, DB - DF, BELT + 0.3 - FLOOR), (-W / 2 - 0.08, (DF + DB) / 2, FLOOR)),
             "Door_R": ((0.4, DB - DF, BELT + 0.3 - FLOOR), (W / 2 + 0.08, (DF + DB) / 2, FLOOR)),
             "Boot": ((W + 0.4, 0.4, BELT + 0.3 - 0.52), (0, L / 2 + 0.1, 0.52))}
    shells = {}
    for name, (size, loc) in boxes.items():
        shells[name] = _bool(_copy(body, name), _cutter(size, loc, paint), "INTERSECT")
    g = 0.012
    for name, (size, loc) in boxes.items():
        _bool(body, _cutter((size[0] + g, size[1] + g, size[2] + g), (loc[0], loc[1], loc[2] - g / 2), paint))
    for o in [body] + list(shells.values()):
        _smooth(o)
    P.add(body)
    for sx in (-1, 1):         # the rear wheel tubs inside (the arches open the walls)
        P.add(box("Tub", (0.26, 0.8, 0.5), (sx * (W / 2 - 0.18), WY, FLOOR - 0.04), paint, r=0.05))

    # The greenhouse: glass panes, pillars, a cream roof.
    zb = BELT - 0.02

    def side(y, z, sx):
        t = (z - zb) / (ROOF - zb)
        return (sx * (XB + (XR - XB) * t), y, z)
    P.add(_pane("Windscreen", [(-XB, WS_Y, zb), (XB, WS_Y, zb), (XR, WSR_Y, ROOF), (-XR, WSR_Y, ROOF)], glass))
    door_glass = {}
    for sx, name in ((-1, "Door_L"), (1, "Door_R")):
        door_glass[name] = _pane("DoorGlass", [side(DF + 0.02, zb, sx), side(DB - 0.01, zb, sx),
                                               side(DB - 0.05, ROOF, sx), side(WSR_Y + 0.02, ROOF, sx)], glass)
        P.add(_pane("Quarter", [side(DB + 0.04, zb, sx), side(RB_Y - 0.02, zb, sx), side(RR_Y, ROOF, sx),
                                side(DB, ROOF, sx)], glass))
        for a, b in (((WS_Y, zb), (WSR_Y, ROOF)), ((DB + 0.02, zb), (DB - 0.02, ROOF)),
                     ((RB_Y, zb), (RR_Y, ROOF))):
            P.add(tube("Pillar", [side(a[0], a[1] - 0.02, sx), side(b[0], b[1], sx)], 0.045, paint, n=8))
    P.add(box("Roof", (2 * XR + 0.14, RR_Y - WSR_Y + 0.14, 0.1), (0, (WSR_Y + RR_Y) / 2, ROOF - 0.04), cream,
              r=0.05, seg=3))
    P.add(tube("Header", [(-XR, WSR_Y, ROOF - 0.01), (XR, WSR_Y, ROOF - 0.01)], 0.04, paint, n=8))

    # The nose and tail: round headlamps, a grille, bumpers, a plate.
    for sx in (-1, 1):
        lamp = lathe("Lamp", [(0, 0.03), (0.08, 0.025), (0.11, 0.0), (0.12, -0.03), (0, -0.03)], M("paper", 0.15),
                     n=16)
        P.add(face_out(lamp, (sx * 0.5, -L / 2 + 0.01, 0.64)))
        rim = lathe("LampRim", [(0.11, 0.0), (0.135, 0.0), (0.135, -0.04), (0.11, -0.04)], steel, n=16)
        P.add(face_out(rim, (sx * 0.5, -L / 2 + 0.03, 0.64)))
    P.add(box("Grille", (0.42, 0.06, 0.12), (0, -L / 2 + 0.01, 0.48), M("charcoal", 0.6), r=0.03))
    for k in range(3):
        P.add(box("GrilleBar", (0.36, 0.064, 0.012), (0, -L / 2 + 0.01, 0.505 + k * 0.032), steel, r=0.004, seg=1))
    for ys in (-1, 1):
        ye = ys * (L / 2 + 0.04)
        P.add(tube("Bumper", [(-W / 2 + 0.02, ys * (L / 2 - 0.25), 0.38), (-W / 2 + 0.1, ye - ys * 0.03, 0.38),
                              (-0.4, ye, 0.38), (0.4, ye, 0.38), (W / 2 - 0.1, ye - ys * 0.03, 0.38),
                              (W / 2 - 0.02, ys * (L / 2 - 0.25), 0.38)], 0.05, steel, n=8))
    P.add(box("Plate", (0.4, 0.02, 0.1), (0, -L / 2 - 0.01, 0.24), M("paper", 0.5), r=0.008, seg=1))

    # The cabin: carpet, two front seats on runners, a rear bench on feet, a dashboard and a wheel.
    P.add(box("Carpet", (W - 0.16, y1 - y0, 0.012), (0, (y0 + y1) / 2, FLOOR), fab("charcoal"), r=0))
    for sx in (-1, 1):
        x = sx * 0.36
        for rx in (-0.17, 0.17):
            P.add(box("Runner", (0.035, 0.5, 0.14), (x + rx, -0.08, FLOOR), steel, r=0.01, seg=1))
        P.add(cush("Seat", (0.5, 0.5, 0.13), (x, -0.08, FLOOR + 0.14), seat, puff=(0.06, 0.06, 0.3), cuts=3))
        back = [cush("Back", (0.48, 0.13, 0.55), (0, 0, 0), seat, puff=(0.05, 0.25, 0.08), cuts=3)]
        for z in (0.36, 0.42):
            back.append(box("Stripe", (0.49, 0.14, 0.03), (0, 0, z), fab("stripe"), r=0.006, seg=1))
        back.append(cush("Headrest", (0.26, 0.1, 0.16), (0, 0, 0.6), seat, puff=(0.1, 0.2, 0.2), cuts=3))
        for o in back:
            o.rotation_euler.x = math.radians(-12)
            o.location = (x, 0.2, FLOOR + 0.2)
        P.add(back)
    for x in (-0.42, 0.42):
        for y in (0.42, 0.82):
            P.add(box("BenchFoot", (0.06, 0.06, 0.13), (x, y, FLOOR), steel, r=0.01, seg=1))
    P.add(cush("Bench", (1.0, 0.5, 0.13), (0, 0.62, FLOOR + 0.12), seat, puff=(0.04, 0.06, 0.3), cuts=4))
    bench = [cush("BenchBack", (1.0, 0.12, 0.52), (0, 0, 0), seat, puff=(0.03, 0.25, 0.06), cuts=4)]
    for z in (0.34, 0.4):
        bench.append(box("Stripe", (1.01, 0.13, 0.03), (0, 0, z), fab("stripe"), r=0.006, seg=1))
    for o in bench:
        o.rotation_euler.x = math.radians(-8)
        o.location = (0, 0.92, FLOOR + 0.12)
    P.add(bench)
    P.add(box("Dash", (W - 0.18, 0.26, 0.2), (0, WS_Y + 0.1, BELT - 0.22), cream, r=0.05))
    dial = cyl("Dial", 0.06, 0.03, (0, 0, 0), M("charcoal", 0.4), n=12, bev=0.008)
    P.add(face_out(dial, (-0.36, WS_Y + 0.22, 0.83), front=1))
    wc, wr = Vector((-0.36, -0.42, 0.86)), 0.17
    ez = Vector((0, 0.42, 0.91)).normalized()
    ring = [wc + (Vector((1, 0, 0)) * math.cos(a) + ez * math.sin(a)) * wr
            for a in [2 * math.pi * k / 16 for k in range(17)]]
    P.add(tube("Wheel", ring, 0.018, M("charcoal", 0.5), n=6, caps=False))
    P.add(tube("Column", [wc, (-0.36, WS_Y + 0.2, 0.76)], 0.025, M("charcoal", 0.5), n=6))
    P.add(tube("Spoke", [wc - Vector((wr, 0, 0)), wc + Vector((wr, 0, 0))], 0.012, M("charcoal", 0.5), n=5))
    P.add(tube("Gear", [(0, -0.3, FLOOR), (0, -0.25, FLOOR + 0.3)], 0.012, steel, n=6))
    P.add(ball("GearKnob", 0.035, (0, -0.25, FLOOR + 0.32), cream, seg=8, rings=6))

    # The wheels: soft tyres with cream hub caps.
    for y in (-WY, WY):
        for sx in (-1, 1):
            tyre = lathe("Tyre", [(WR * a, b) for a, b in ((0.57, -0.09), (0.83, -0.1), (0.96, -0.075), (1.0, 0.0),
                                                           (0.96, 0.075), (0.83, 0.1), (0.57, 0.09))],
                         M("rubber", 0.9), n=20)
            hub = lathe("Hub", [(0, 0.1), (0.07, 0.098), (0.15, 0.085), (0.18, 0.06), (0.18, -0.06), (0, -0.06)],
                        cream, n=16)
            for o in (tyre, hub):
                o.rotation_euler.y = sx * math.pi / 2
                o.location = (sx * (W / 2 - 0.13), y, WR)
                P.add(o)

    # The doors: the shell's door panel, its glass, a handle and a wing mirror.
    for sx, name in ((-1, "Door_L"), (1, "Door_R")):
        x = sx * W / 2
        objs = [shells[name], door_glass[name],
                box("Handle", (0.03, 0.16, 0.03), (x + sx * 0.006, DB - 0.2, 0.8), steel, r=0.01, seg=1),
                tube("MirrorArm", [(x, DF + 0.12, BELT - 0.02), (x + sx * 0.09, DF + 0.14, BELT + 0.04)], 0.015,
                     paint, n=6),
                ball("Mirror", 0.07, (x + sx * 0.12, DF + 0.16, BELT + 0.07), paint, seg=10, rings=6,
                     scale=(0.9, 0.6, 0.7))]
        # Its collision: the panel below the belt and the glass above it (not the wing mirror).
        P.hinge(name, objs, (x, DF + 0.02, FLOOR), (0, 0, -sx), 70,
                boxes=[_sx_box(sx, (W / 2 - 0.075, DF + 0.02, FLOOR), (W / 2 + 0.01, DB - 0.01, BELT)),
                       _sx_box(sx, (XR + 0.02, DF + 0.04, BELT), (XB + 0.02, DB - 0.03, ROOF - 0.04))])
    # The boot: the tailgate panel, the rear glass and its frame, tail lamps, a plate, a handle.
    bt = [shells["Boot"],
          _pane("RearGlass", [(-XB, RB_Y, zb), (XB, RB_Y, zb), (XR, RR_Y, ROOF - 0.02), (-XR, RR_Y, ROOF - 0.02)],
                glass),
          tube("BootFrame", [(-XB, RB_Y + 0.01, zb), (-XR, RR_Y + 0.01, ROOF - 0.02), (XR, RR_Y + 0.01, ROOF - 0.02),
                             (XB, RB_Y + 0.01, zb)], 0.035, paint, n=8),
          box("Plate", (0.4, 0.02, 0.1), (0, L / 2 + 0.005, 0.6), M("paper", 0.5), r=0.008, seg=1),
          box("Handle", (0.18, 0.03, 0.03), (0, L / 2 + 0.01, 0.75), steel, r=0.01, seg=1)]
    for sx in (-1, 1):
        bt.append(box("TailLamp", (0.12, 0.04, 0.2), (sx * 0.6, L / 2 - 0.005, 0.62),
                      M("terracotta", 0.2), r=0.02))
        bt.append(box("TailLampCap", (0.124, 0.044, 0.06), (sx * 0.6, L / 2 - 0.005, 0.62), M("mustard", 0.2),
                      r=0.015, seg=1))
    P.hinge("Boot", bt, (0, RR_Y, ROOF - 0.02), (1, 0, 0), 85,
            boxes=[((-W / 2 + 0.01, L / 2 - 0.08, 0.52), (W / 2 - 0.01, L / 2 + 0.04, BELT)),
                   ((-XB, RR_Y, BELT), (XB, RB_Y, ROOF - 0.04))])

    # The car's own colliders (house/11): what the Socks and the player meet, the seats left out.
    P.collide((-W / 2, -L / 2 - 0.05, CL), (W / 2, L / 2 + 0.05, FLOOR))              # floor pan
    P.collide((-W / 2, -L / 2 - 0.05, FLOOR), (W / 2, y0, 0.8))                       # bonnet
    P.collide((-W / 2 + 0.07, y0, 0.66), (W / 2 - 0.07, y0 + 0.2, BELT))             # dashboard
    P.collide((-XB, WS_Y, BELT), (XB, WS_Y + 0.3, (BELT + ROOF) / 2))                # windscreen, low
    P.collide((-XR, WS_Y + 0.28, (BELT + ROOF) / 2), (XR, WSR_Y + 0.04, ROOF))       # windscreen, high
    P.collide((-XR - 0.05, WSR_Y, ROOF - 0.08), (XR + 0.05, RR_Y + 0.05, ROOF + 0.06))  # roof
    P.collide((-W / 2, L / 2 - 0.08, FLOOR), (W / 2, L / 2 + 0.05, 0.52))            # tail under the boot
    for sx in (-1, 1):
        lo, hi = _sx_box(sx, (W / 2 - 0.075, DB, FLOOR), (W / 2, L / 2 - 0.08, BELT))
        P.collide(lo, hi)                                                             # rear flank
        lo, hi = _sx_box(sx, (XR, DB + 0.02, BELT), (XB + 0.02, RB_Y - 0.02, ROOF - 0.04))
        P.collide(lo, hi)                                                             # quarter glass
        lo, hi = _sx_box(sx, (W / 2 - 0.31, WY - 0.4, FLOOR), (W / 2 - 0.075, WY + 0.4, FLOOR + 0.46))
        P.collide(lo, hi)                                                             # wheel tub
        for y in (-WY, WY):
            lo, hi = _sx_box(sx, (W / 2 - 0.24, y - 0.3, 0.0), (W / 2 - 0.02, y + 0.3, CL))
            P.collide(lo, hi)                                                         # wheel
    # Where Socks hide: the cabin's floor (under the seats too), opened by both doors; the boot well.
    P.container("Cabin", ["Door_L", "Door_R"], (-W / 2 + 0.09, y0 + 0.2, FLOOR + 0.012),
                (W / 2 - 0.09, WY - 0.42, BELT), "cupboard")
    P.container("Boot", ["Boot"], (-W / 2 + 0.32, WY - 0.2, FLOOR + 0.012), (W / 2 - 0.32, y1 - 0.02, BELT - 0.05),
                "cupboard")
    # The Socks (physics/09): the hollow shell as the hulls of its bonnet, floor, side walls behind
    # the doors and tail, so the cabin and the boot stay hollow; the seats, dash, glass and wheels
    # as drawn, the bumpers and the boot's frame not at all (thin tubes round the outside).
    P.sock_skip("BootFrame", "Bumper")
    P.sock_split(body, [((-W, -L, 0), (W, y0, 2)), ((-W, y0, 0), (W, y1, FLOOR)),
                        ((-W, DB, FLOOR), (-W / 2 + 0.072, y1, 2)), ((W / 2 - 0.072, DB, FLOOR), (W, y1, 2)),
                        ((-W, y1, 0), (W, L, 2))])
    # The clear floor under the car, inside the wheels (Godot, local [x, z]).
    P.extra["crawl_box"] = {"min": [-(W / 2 - 0.27), -(WY + 0.45)], "max": [W / 2 - 0.27, WY + 0.45]}


def _sx_box(sx, lo, hi):
    """A box given on the +x side (lo, hi), mirrored to the -x side when sx < 0."""
    if sx > 0:
        return lo, hi
    return (-hi[0], lo[1], lo[2]), (-lo[0], hi[1], hi[2])


# --- The Old Tree (house/45, Q1509, Q1510, Q1516, Q1517) ---------------------------------------

def _tree_mats():
    from kit import mat
    pine = mat("tree_pine", (0.24, 0.44, 0.30), rough=0.85)
    pine_dark = mat("tree_pine_dark", (0.17, 0.34, 0.23), rough=0.9)
    wire = mat("tree_wire", (0.12, 0.22, 0.14), rough=0.6)
    # The bulbs still lit (Q1517): warm and emissive, the same all game (Q1510).
    warm = mat("bulb_warm", (1.0, 0.78, 0.45), rough=0.3)
    bsdf = next(n for n in warm.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Emission Color"].default_value = (1.0, 0.62, 0.28, 1.0)
    bsdf.inputs["Emission Strength"].default_value = 4.0
    return pine, pine_dark, wire, warm


def _tier(P, name, at, z, r, h, m, lean, squash=(1.0, 1.0), teeth=7, n=21, lobes=7, phase=0.0):
    """One tier of the artificial tree: a cone of branch tips with a jagged (zigzag) rim, its base
    on the pole at height z, r wide, h tall; squash scales it in x and y (a half-open tier)."""
    prof = [(0.0, 0.0)]
    for k in range(teeth + 1):
        t = k / teeth
        prof.append((r * (1.0 - t) * (0.8 if k % 2 else 1.0), h * t * 0.9 + (0.03 if k % 2 else 0.0)))
    prof.append((0.0, h))
    ob = lathe(name, prof, m, n=n)
    # Lobes round the rim: the branch tips of an artificial tree, not a smooth cone.
    for v in ob.data.vertices:
        a = math.atan2(v.co.y, v.co.x)
        k = 0.9 + 0.18 * math.cos(lobes * a + phase)
        v.co.x *= k
        v.co.y *= k
    ob.scale = (squash[0], squash[1], 1.0)
    ob.rotation_euler = (lean[0], lean[1], 0.0)
    ob.location = at(z)
    P.add(ob)
    return ob


@piece("old_tree", ["Garage"], spot="The Old Tree (house/45: the Upgrade station, a garage corner)",
       hide="behind the torn box, in the decorations box",
       note="The Old Tree (Q1516): a forgotten artificial X-mas tree pulled half out of its torn box, the "
            "decorations box beside it, a tangled light string with a few bulbs still glowing warm "
            "(Q1509, Q1517; the material 'bulb_warm' is emissive). The same look all game (Q1510). Its "
            "back (-z) goes to a wall: the tree's box at -x, the decorations box at +x. lamp: the "
            "piece-local point of the one small warm light the game hangs by the lit bulbs.")
def old_tree(P):
    from mathutils import Vector
    pine, pine_dark, wire, warm = _tree_mats()
    card = M("cardboard", 0.85)
    tape = M("sheet", 0.6)
    rng = random.Random(45)
    # The tree's box: upright, 0.42 square, 0.95 tall, its front (-y) torn down to half height.
    bx, by, S, T = -0.32, 0.06, 0.42, 0.012
    Hb = 0.95
    P.add(box("Box", (S, T, Hb), (bx, by + S / 2 - T / 2, 0), card, r=0.004, seg=1))            # back
    for sx in (-1, 1):
        P.add(box("Box", (T, S, Hb), (bx + sx * (S / 2 - T / 2), by, 0), card, r=0.004, seg=1))  # sides
    P.add(box("Box", (S, S, T), (bx, by, 0), card, r=0.004, seg=1))                               # floor
    # The torn front: two ragged stubs of different heights, torn tongues, a strip hanging open.
    P.add(box("Box", (S * 0.55, T, 0.5), (bx - S * 0.225, by - S / 2 + T / 2, 0), card, r=0.004, seg=1))
    P.add(box("Box", (S * 0.45, T, 0.36), (bx + S * 0.275, by - S / 2 + T / 2, 0), card, r=0.004, seg=1))
    for k, (w, h, zt) in enumerate(((0.07, 0.09, 0.5), (0.06, 0.06, 0.36))):
        t = box("Tear", (w, T, h), (0, 0, 0), card, r=0.003, seg=1)
        t.location = (bx - S * 0.05 + k * 0.17, by - S / 2 + T / 2, zt - 0.02)
        t.rotation_euler.y = math.radians(25 - 50 * k)
        P.add(t)
    f = box("Flap", (S * 0.42, T, 0.42), (0, 0, 0), card, r=0.004, seg=1)
    f.location = (bx + S * 0.29, by - S / 2 - 0.01, 0.36)
    f.rotation_euler.x = math.radians(118)   # hangs out of the front, down
    P.add(f)
    # The top flaps splayed out, one torn off and lying on the floor.
    for sx, ang in ((-1, 125), (1, 140)):
        fl = box("TopFlap", (T, S, S * 0.48), (0, 0, 0), card, r=0.004, seg=1)
        fl.location = (bx + sx * S / 2, by, Hb - 0.01)
        fl.rotation_euler.y = sx * math.radians(ang)
        P.add(fl)
    fl = box("TopFlap", (S, T, S * 0.48), (0, 0, 0), card, r=0.004, seg=1)
    fl.location = (bx, by + S / 2, Hb - 0.01)
    fl.rotation_euler.x = math.radians(-150)
    P.add(fl)
    loose = box("TornFlap", (S * 0.9, S * 0.45, T), (0, 0, 0), card, r=0.004, seg=1)
    loose.location = (bx - 0.02, by - S / 2 - 0.12, 0.0)
    loose.rotation_euler = (0.0, 0.0, math.radians(-25))
    P.add(loose)
    # Tape over the top, and the print: a red band and a little tree on the side.
    P.add(box("Tape", (0.06, S + 0.004, 0.012), (bx, by, Hb - 0.012), tape, r=0.003, seg=1))
    P.add(box("Print", (T + 0.004, S * 0.9, 0.08), (bx + S / 2 - 0.004, by, 0.12), M("red", 0.6), r=0.003, seg=1))
    pr = lathe("PrintTree", [(0.0, 0.0), (0.07, 0.0), (0.0, 0.16)], M("leaf_dark", 0.6), n=3, smooth=False)
    pr.scale = (0.12, 1.0, 1.0)
    pr.location = (bx + S / 2 + 0.002, by, 0.4)
    P.add(pr)

    # The tree, pulled half out of the box (Q1539: nothing passes through the box's walls): the
    # pole stands straight inside the box with the folded lower tiers, narrower than its inside;
    # above the rim it leans forward and the upper tiers spring open (one half-open and lopsided),
    # a bent tip.
    lean = (math.radians(6), math.radians(-3))
    rim = Hb + 0.05

    def at(z):
        u = max(0.0, z - Hb)
        return (bx + math.sin(lean[1]) * u, by - math.sin(lean[0]) * u, z)

    P.add(tube("Pole", [at(0.05), at(Hb), at(1.58)], 0.014, M("charcoal", 0.6), n=6))
    for z in (0.15, 0.45):
        _tier(P, "Folded", at, z, 0.15, 0.34, pine_dark, (0.0, 0.0), teeth=5, n=15, lobes=5)
    for z, r, h, sq in ((rim, 0.4, 0.28, (1.0, 0.7)), (rim + 0.18, 0.34, 0.26, (0.9, 1.0)), (rim + 0.35, 0.26, 0.23, (1.0, 0.95)),
                        (rim + 0.5, 0.17, 0.19, (1.0, 1.0)), (rim + 0.62, 0.09, 0.13, (1.0, 1.0))):
        _tier(P, "Tier", at, z, r, h, pine, lean, squash=sq, phase=z * 5.0)
    # A few branches that won't fold back, above the rim: sprung out at odd angles, one snapped.
    for k in range(6):
        z = rim + 0.06 + 0.09 * k
        a = math.radians(rng.uniform(170, 370))   # out to the sides and front, never into the wall
        x, y, zz = at(z)
        L = rng.uniform(0.28, 0.42)
        drop = 0.1 if k == 0 else rng.uniform(-0.04, 0.05)
        P.add(tube("Branch", [(x, y, zz), (x + math.cos(a) * L * 0.6, y + math.sin(a) * L * 0.6, zz + 0.02),
                              (x + math.cos(a) * L, y + math.sin(a) * L, zz - drop)], 0.012, pine, n=5))
    tx, ty, tz = at(rim + 0.66)
    P.add(tube("Tip", [(tx, ty, tz), (tx + 0.04, ty - 0.03, tz + 0.07), (tx + 0.11, ty - 0.05, tz + 0.08)],
               [0.03, 0.02, 0.008], pine, n=6))

    # The light string: wound loosely round the tiers, slipping off the front, down into a tangle
    # on the floor. Most bulbs are dead; a few still glow warm (Q1517).
    pts = []
    for k in range(30):
        t = k / 29
        z = rim + 0.55 - 0.5 * t
        a = 6.5 * math.pi * t + 0.6
        rr = 0.1 + 0.27 * t
        x, y, _ = at(z)
        pts.append((x + math.cos(a) * rr, y + math.sin(a) * rr, z + 0.02 * math.sin(11 * t)))
    # Off the front of the tree, down outside the torn front, into the tangle on the floor.
    fy = by - S / 2 - 0.07
    pts += [(bx - 0.04, fy - 0.06, rim + 0.02), (bx - 0.08, fy, 0.62), (bx - 0.06, fy, 0.3), (0.0, -0.24, 0.03)]
    cx, cy = 0.02, -0.22
    for k in range(26):
        a = k * 0.95
        rr = 0.07 + 0.05 * math.sin(k * 1.7)
        pts.append((cx + math.cos(a) * rr + 0.004 * k, cy + math.sin(a) * rr * 0.7, 0.012 + 0.012 * (k % 3)))
    P.add(tube("Wire", pts, 0.005, wire, n=4, caps=False))
    dead = [M("red", 0.3), M("sky", 0.3), M("mustard", 0.3), M("sage", 0.3)]
    lit = {3, 9, 15, 21, 27, 41, 51}
    for i in range(1, len(pts) - 1, 2):
        a, b = Vector(pts[i]), Vector(pts[i + 1])
        n = (b - a).cross(Vector((0, 0, 1)))
        n = n.normalized() if n.length > 1e-4 else Vector((1, 0, 0))
        c = a + n * 0.012 + Vector((0, 0, -0.01))
        c.z = max(c.z, 0.02)
        on = i in lit
        P.add(ball("LitBulb" if on else "Bulb", 0.013, tuple(c), warm if on else dead[i % 4], seg=6, rings=4,
                   scale=(1, 1, 1.5)))
    # The game's one small warm light (house_parts.gd), by the lit bulbs on the tree.
    P.extra["lamp"] = tuple(Vector(at(rim + 0.1)) + Vector((0.0, -0.36, 0.0)))
    P.extra.update({"lamp_colour": [1.0, 0.66, 0.36], "lamp_energy": 0.45, "lamp_range": 2.0})

    # The decorations box: open, baubles inside, a tinsel garland over its rim, two baubles out.
    dx, dy, W, D, Hd = 0.36, -0.02, 0.46, 0.36, 0.28
    red = M("red", 0.7)
    P.add(box("DecoBox", (W, D, T), (dx, dy, 0), red, r=0.004, seg=1))
    for sy in (-1, 1):
        P.add(box("DecoBox", (W, T, Hd), (dx, dy + sy * (D / 2 - T / 2), 0), red, r=0.004, seg=1))
    for sx in (-1, 1):
        P.add(box("DecoBox", (T, D, Hd), (dx + sx * (W / 2 - T / 2), dy, 0), red, r=0.004, seg=1))
    for z in (0.08, 0.12):
        P.add(box("DecoStripe", (W + 0.004, D + 0.004, 0.018), (dx, dy, z), fab("stripe"), r=0.003, seg=1))
    for sy in (-1, 1):
        fl = box("DecoFlap", (W, D * 0.5, T), (0, 0, 0), red, r=0.003, seg=1)
        fl.location = (dx, dy + sy * (D / 2 + D * 0.2), Hd)
        fl.rotation_euler.x = sy * math.radians(-50)
        P.add(fl)
    P.add(box("Fill", (W - 0.03, D - 0.03, 0.17), (dx, dy, 0.01), M("cardboard", 0.9), r=0.01, seg=1))
    cols = ["mustard", "sky", "red", "pink", "sage", "lavender"]
    for k in range(9):
        r = rng.uniform(0.035, 0.05)
        P.add(ball("Bauble", r, (dx + rng.uniform(-W / 2 + 0.07, W / 2 - 0.07), dy + rng.uniform(-D / 2 + 0.07, D / 2 - 0.07),
                                 0.18 + r + rng.uniform(0.0, 0.03)), M(cols[k % 6], 0.2, 0.5), seg=10, rings=7))
    for (x, y, r, c) in ((0.66, -0.3, 0.045, "sky"), (0.12, -0.14, 0.04, "mustard")):
        P.add(ball("Bauble", r, (x, y, r), M(c, 0.2, 0.5), seg=10, rings=7))
    g = [(dx - W / 2 + 0.05, dy + 0.1, 0.25), (dx - 0.05, dy + 0.02, Hd + 0.03), (dx + W / 2, dy - 0.05, Hd + 0.01),
         (dx + W / 2 + 0.05, dy - 0.1, 0.16), (dx + W / 2 + 0.08, dy - 0.2, 0.02), (dx + W / 2 - 0.02, dy - D / 2 - 0.08, 0.02)]
    P.add(tube("Garland", g, 0.02, M("mustard", 0.4, 0.4), n=6))

    # Collision: the tree's box, its crown, the decorations box. The wire, bulbs, tinsel and the
    # loose flaps are too thin to block a player or a Sock.
    P.collide((bx - S / 2, by - S / 2, 0.0), (bx + S / 2, by + S / 2, Hb))
    P.collide((bx - 0.36, by - 0.4, Hb), (bx + 0.34, by + 0.3, rim + 0.75))
    P.collide((dx - W / 2, dy - D / 2, 0.0), (dx + W / 2, dy + D / 2, Hd))
    P.sock_skip("Wire", "Bulb", "LitBulb", "TornFlap", "Branch", "Tip", "Garland", "Tear", "PrintTree", "Print", "Tape")
    _check_tree_in_box(P)


def _check_tree_in_box(P):
    """Prints CLIP old_tree: the tree's parts (pole, tiers, branches, wire, bulbs) that pass through
    the walls of its box (Q1539); the build wants none."""
    import bpy
    import bmesh
    from mathutils.bvhtree import BVHTree
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()

    def bvh(o):
        bm = bmesh.new()
        bm.from_object(o, dg)
        bm.transform(o.matrix_world)
        t = BVHTree.FromBMesh(bm)
        bm.free()
        return t
    tree_parts = ("Pole", "Folded", "Tier", "Branch", "Tip", "Wire", "Bulb", "LitBulb")
    walls = [o for o in P.body if o.name.split(".")[0] in ("Box", "TopFlap", "Flap", "Tear")]
    parts = [o for o in P.body if o.name.split(".")[0] in tree_parts]
    wall_trees = [(w.name, bvh(w)) for w in walls]
    hits = []
    for o in parts:
        t = bvh(o)
        for wn, wt in wall_trees:
            if t.overlap(wt):
                hits.append(o.name + " x " + wn)
    print("CLIP old_tree: %d through the box %s" % (len(hits), hits[:8]))
