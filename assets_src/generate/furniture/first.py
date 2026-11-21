"""The first floor's furniture (house/04): parents' bedroom, kids' room, bathroom, home office.

Blender axes: z up, front -y, each piece built around x = 0, y = 0 (build.py centres it).
Hinge axes (Blender): left-edge door (0, 0, -1), right-edge door (0, 0, 1), a lid hinged at its back
edge (-1, 0, 0); drawers slide along (0, -1, 0).
"""

import math
import random

import bmesh

import kit
from fkit import (M, ball, box, bun_feet, bx, cush, cyl, fab, face_out, handle_bar, lathe, peg_legs,  # noqa: F401
                  piece, shell, tray_boxes, tube)
from ground import _door, _drawer, _rail, _top

ROOMS = ["Parents' bedroom", "Kids' room", "Bathroom", "Home office"]


def arch_board(name, w, h, t, rise, loc, m, r=0.03):
    """A board with a soft arched top (the trial's headboard), no subdivision."""
    bm = bmesh.new()
    pts = [(-w / 2, 0.0)]
    n = 12
    for k in range(n + 1):
        x = -w / 2 + w * k / n
        pts.append((x, h + rise * math.sin(math.pi * k / n) ** 0.7))
    pts.append((w / 2, 0.0))
    lo = [bm.verts.new((loc[0] + x, loc[1] - t / 2, loc[2] + z)) for x, z in pts]
    hi = [bm.verts.new((loc[0] + x, loc[1] + t / 2, loc[2] + z)) for x, z in pts]
    bm.faces.new(lo)
    bm.faces.new(list(reversed(hi)))
    for i in range(len(pts)):
        j = (i + 1) % len(pts)
        bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    ob = kit.obj_from_bm(name, bm, m)
    kit.bevel(ob, r, 3, angle=30)
    return ob


def books(P, x0, x1, y, z, depth, seed, hmax=0.26, lean=True):
    """A row of books standing on a shelf from x0 to x1."""
    rng = random.Random(seed)
    cols = ["red", "navy", "sage", "mustard", "pink", "sky", "cardboard", "dark_wood"]
    x = x0
    while x < x1 - 0.03:
        t = rng.uniform(0.025, 0.05)
        h = rng.uniform(hmax * 0.7, hmax)
        if x + t > x1:
            break
        P.add(box("Book", (t, depth * rng.uniform(0.8, 0.95), h), (x + t / 2, y, z), M(rng.choice(cols), 0.6),
                  r=0.004, seg=1))
        x += t + 0.002
        if lean and rng.random() < 0.08 and x < x1 - 0.2:
            b = box("Book", (0.035, depth * 0.85, h), (0, 0, 0), M(rng.choice(cols), 0.6), r=0.004, seg=1)
            b.location = (x + 0.06, y, z)
            b.rotation_euler.y = math.radians(-22)
            P.add(b)
            x += 0.14


# --- Parents' bedroom ------------------------------------------------------------------------

@piece("double_bed", ["Parents' bedroom"], spot="Bed", crawl=0.3, hide="under the bed (0.30, the flat's BED_GAP)",
       note="The trial's stylised bed (Q404) with the subdivision dropped (Q405); dusty pink duvet (Q406). "
            "The head is the back (+y Blender, -z Godot): put it against the wall.")
def double_bed(P):
    P.sock_dev = 0.005   # its merged Sock colliders keep the tops Socks rest on (physics/09)
    oak = M("oak", 0.55)
    linen = fab("linen")
    duvet = fab("pink")
    pad = fab("pad")
    cream = fab("stripe")
    blue = fab("rug_blue")
    W, L, gap = 1.6, 2.05, 0.30
    y_head = L / 2
    P.add(bun_feet((-W / 2 + 0.06, W / 2 - 0.06), (-L / 2 + 0.06, y_head - 0.1), gap + 0.02, 0.09, oak))
    P.add(box("BedFrame", (W + 0.08, L, 0.16), (0, 0, gap), oak, r=0.05, seg=3))
    P.add(arch_board("Headboard", W + 0.2, 1.0, 0.12, 0.18, (0, y_head + 0.04, 0), oak))
    P.add(arch_board("Footboard", W + 0.2, 0.42, 0.1, 0.06, (0, -L / 2 - 0.02, 0), oak))
    P.add(cush("HeadPad", (W - 0.1, 0.12, 0.44), (0, y_head - 0.04, 0.66), pad, puff=(0.05, 0.6, 0.08), cuts=5))
    for sx in (-1, 1):
        P.add(lathe("Knob", [(0, 0), (0.05, 0.01), (0.075, 0.06), (0.05, 0.12), (0, 0.125)], oak, n=12,
                    loc=(sx * (W / 2 + 0.06), -L / 2 - 0.02, 0.4)))
    mt = gap + 0.16
    # Colliders: the frame and mattress up to the duvet's top (a resting top), head and foot boards.
    P.collide((-W / 2 - 0.04, -L / 2, gap), (W / 2 + 0.04, L / 2, mt + 0.26))
    P.collide((-W / 2 - 0.1, L / 2 - 0.02, 0), (W / 2 + 0.1, L / 2 + 0.1, 1.0))
    P.collide((-W / 2 - 0.1, -L / 2 - 0.07, 0), (W / 2 + 0.1, -L / 2 + 0.03, 0.42))
    P.extra["tops"] = [_top((-W / 2 + 0.05, -L / 2 + 0.05), (W / 2 - 0.05, L / 2 - 0.1), mt + 0.26)]
    P.add(cush("Mattress", (W - 0.04, L - 0.08, 0.2), (0, 0.0, mt - 0.02), linen, puff=(0.05, 0.03, 0.2), cuts=5))
    top = mt + 0.18
    dl = 1.45
    P.add(cush("Duvet", (W + 0.1, dl, 0.2), (0, -L / 2 + dl / 2 - 0.02, top - 0.12), duvet, puff=(0.12, 0.05, 0.5),
               cuts=7))
    fold_y = -L / 2 + dl - 0.02
    P.add(tube("DuvetFold", [(-W / 2 - 0.03, fold_y, top + 0.12), (W / 2 + 0.03, fold_y, top + 0.12)], 0.09, linen, n=12))
    for sx in (-1, 1):
        p = cush("Pillow", (0.7, 0.44, 0.2), (0, 0, 0), linen, puff=(0.1, 0.15, 0.9), pinch=0.5, cuts=6)
        p.location = (sx * 0.38, y_head - 0.3, top - 0.02)
        p.rotation_euler.x = math.radians(-14)
        P.add(p)
    P.add(cush("Throw", (W + 0.16, 0.5, 0.05), (0, -L / 2 + 0.4, top + 0.1), blue, puff=(0.05, 0.05, 0.6), cuts=6))
    for dy in (-0.08, 0.08):
        P.add(cush("ThrowStripe", (W + 0.165, 0.045, 0.052), (0, -L / 2 + 0.4 + dy, top + 0.101), cream,
                   puff=(0.02, 0.05, 0.4), cuts=3))


@piece("nightstand", ["Parents' bedroom"], spot="Stand", crawl=0.1, note="One drawer; a lamp and a book on top.")
def nightstand(P):
    oak = M("oak", 0.55)
    W, D, H = 0.46, 0.4, 0.55
    gap = 0.1
    P.add(bun_feet((-W / 2 + 0.06, W / 2 - 0.06), (-D / 2 + 0.06, D / 2 - 0.06), gap + 0.02, 0.05, oak))
    # A hollow case (house/05): closed below, the drawer's opening above a rail.
    inside = shell(P, "Case", (-W / 2, -D / 2, gap), (W / 2, D / 2, H), 0.02, oak, r=0.008)
    P.add(bx("Front", (-W / 2, -D / 2, gap), (W / 2, -D / 2 + 0.02, H - 0.22), oak, r=0.008))
    P.add(bx("Shelf", (-W / 2 + 0.03, -D / 2 - 0.004, gap + 0.04), (W / 2 - 0.03, -D / 2, gap + 0.2), M("dark_wood", 0.6),
             r=0))
    P.collide((-W / 2, -D / 2, gap), (W / 2, -D / 2 + 0.04, H - 0.22))
    _rail(P, inside, H - 0.22, oak)
    _drawer(P, "Drawer_1", -W / 2 + 0.03, W / 2 - 0.03, H - 0.2, H - 0.04, -D / 2 + 0.005, "pink", depth=0.3, open_m=0.25)
    P.extra["tops"] = [_top((0.0, -D / 2 + 0.03), (W / 2 - 0.03, D / 2 - 0.03), H)]
    P.add(lathe("LampBase", [(0, 0), (0.07, 0), (0.09, 0.07), (0.07, 0.15), (0.02, 0.18), (0, 0.18)], M("sage", 0.35),
                n=14, loc=(-0.08, 0.04, H)))
    P.add(lathe("LampShade", [(0.15, 0.0), (0.1, 0.16), (0.095, 0.15), (0.14, 0.005)], fab("stripe"), n=18,
                loc=(-0.08, 0.04, H + 0.15)))
    for rel in (0.03, 0.06):
        r = 0.15 - 0.3125 * rel
        z = H + 0.15 + rel
        P.add(lathe("ShadeBand", [(r - 0.003, z - 0.01), (r + 0.004, z), (r - 0.006, z + 0.01)], fab("pink"), n=18,
                    loc=(-0.08, 0.04, 0)))
    P.add(box("Book", (0.16, 0.22, 0.04), (0.12, -0.02, H), M("navy", 0.6), r=0.006, seg=1))
    P.add(cyl("Glass", 0.03, 0.09, (0.13, 0.12, H), M("sky", 0.1), n=10))


@piece("wall_mirror", ["Parents' bedroom"], spot="Mirror",
       note="Wall-hung oval; origin = its own bottom, hang at about 0.9 m. Node MirrorGlass = the glass only "
            "(0.56 x 1.06 oval, centre 0.58 m above the origin) for the game's mirror.")
def wall_mirror(P):
    oak = M("oak", 0.5)
    rx, rz = 0.3, 0.55
    n = 28
    pts = [(rx * math.cos(2 * math.pi * k / n), rz * math.sin(2 * math.pi * k / n)) for k in range(n)]
    P.add(tube("Frame", [(x * 1.06, 0, z * 1.04 + 0.58) for x, z in pts + pts[:1]], 0.035, oak, n=8, caps=False))
    bm = bmesh.new()
    vs = [bm.verts.new((x, 0.0, z + 0.58)) for x, z in pts]
    f = bm.faces.new(vs)
    bm.normal_update()
    if f.normal.y > 0:
        bmesh.ops.reverse_faces(bm, faces=[f])
    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    P.named("MirrorGlass", [kit.obj_from_bm("MirrorGlass", bm, M("sky", 0.05, 0.6), smooth=False)])
    P.add(box("Back", (0.1, 0.02, 0.1), (0, 0.03, 1.1), oak, r=0, seg=1))
    # A ribbon bow with the cream stripes on top.
    P.add(ball("Bow", 0.05, (0, -0.02, 1.18), fab("pink"), seg=8, rings=5, scale=(1.4, 0.5, 0.8)))


@piece("dresser", ["Parents' bedroom"], spot="Dresser (new; beside the Wardrobe Station)", crawl=0.12,
       note="Three drawers; a jewellery box, a photo and a plant spot on top.")
def dresser(P):
    oak = M("oak", 0.55)
    W, D, H, gap = 1.0, 0.48, 0.85, 0.12
    P.add(bun_feet((-W / 2 + 0.07, W / 2 - 0.07), (-D / 2 + 0.07, D / 2 - 0.07), gap + 0.02, 0.06, oak))
    shell(P, "Case", (-W / 2, -D / 2, gap), (W / 2, D / 2, H), 0.02, oak, r=0.008)
    P.add(bx("Plinth", (-W / 2, -D / 2, gap), (W / 2, -D / 2 + 0.02, gap + 0.04), oak, r=0.006))
    P.add(box("Top", (W + 0.04, D + 0.03, 0.035), (0, 0, H - 0.01), M("dark_wood", 0.5), r=0.015))
    P.collide((-W / 2 - 0.02, -D / 2 - 0.015, H - 0.01), (W / 2 + 0.02, D / 2 + 0.015, H + 0.025))
    zs = [gap + 0.04, gap + 0.27, gap + 0.5, H - 0.04]
    for k in range(3):
        _drawer(P, f"Drawer_{k + 1}", -W / 2 + 0.04, W / 2 - 0.04, zs[2 - k], zs[3 - k] - 0.01, -D / 2 + 0.005,
                "pad", depth=0.38, open_m=0.32)
    P.extra["tops"] = [_top((-W / 2 + 0.02, -D / 2 + 0.02), (W / 2 - 0.02, D / 2 - 0.02), H + 0.025)]
    P.add(box("JewelBox", (0.22, 0.14, 0.1), (-0.3, 0.05, H + 0.025), fab("pink"), r=0.02))
    for z in (H + 0.08, H + 0.1):
        P.add(box("JewelStripe", (0.224, 0.144, 0.012), (-0.3, 0.05, z), fab("stripe"), r=0.003, seg=1))
    f = box("Photo", (0.18, 0.02, 0.22), (0, 0, 0), M("brass", 0.3, 0.7), r=0.01)
    f.location = (0.2, 0.12, H + 0.025)
    f.rotation_euler.x = math.radians(-10)
    P.add(f)


# --- Kids' room --------------------------------------------------------------------------------

@piece("bunk_bed", ["Kids' room"], spot="Bunk bed", crawl=0.25, hide="under the lower bunk",
       note="The ladder is on the front (-y Blender, +z Godot) at the right end.")
def bunk_bed(P):
    P.sock_dev = 0.005   # its merged Sock colliders keep the tops Socks rest on (physics/09)
    oak = M("oak", 0.55)
    W, L = 0.98, 1.98
    H = 1.62
    low, high = 0.25, 1.05
    for x in (-L / 2 + 0.04, L / 2 - 0.04):
        for y in (-W / 2 + 0.04, W / 2 - 0.04):
            P.add(box("Post", (0.08, 0.08, H), (x, y, 0), oak, r=0.025, seg=2))
            P.add(ball("PostKnob", 0.05, (x, y, H + 0.02), oak, seg=10, rings=6))
    for z in (low, high):
        for y in (-W / 2 + 0.03, W / 2 - 0.03):
            P.add(box("Rail", (L - 0.08, 0.04, 0.14), (0, y, z), oak, r=0.015))
        P.add(box("Slats", (L - 0.08, W - 0.08, 0.03), (0, 0, z + 0.04), M("dark_wood", 0.6), r=0, seg=1))
    for x in (-L / 2 + 0.04, L / 2 - 0.04):
        for z in (0.55, 1.4):
            P.add(box("EndRail", (0.04, W - 0.08, 0.18), (x, 0, z), oak, r=0.015))
    # Guard rail on the top bunk (front), leaving the ladder gap.
    P.add(box("Guard", (L - 0.6, 0.04, 0.12), (-0.25, -W / 2 + 0.03, high + 0.36), oak, r=0.015))
    for x in (-L / 2 + 0.1, 0.0, 0.48):
        P.add(box("GuardPost", (0.04, 0.04, 0.3), (x, -W / 2 + 0.03, high + 0.14), oak, r=0.01))
    # Ladder.
    lx = L / 2 - 0.3
    for dx in (-0.16, 0.16):
        P.add(box("LadderSide", (0.045, 0.045, high + 0.4), (lx + dx, -W / 2 - 0.03, 0), oak, r=0.012))
    for k in range(4):
        P.add(cyl("Rung", 0.018, 0.32, (0, 0, 0), M("dark_wood", 0.5), n=8))
        r = P.body[-1]
        r.rotation_euler.y = math.pi / 2
        r.location = (lx - 0.16, -W / 2 - 0.03, 0.32 + k * 0.26)
    # Mattresses, duvets (lavender below, sky above) with the cream stripes, pillows, a teddy.
    for z, c in ((low, "lavender"), (high, "sky")):
        mt = z + 0.07
        P.add(cush("Mattress", (L - 0.12, W - 0.1, 0.14), (0, 0, mt), fab("linen"), puff=(0.03, 0.05, 0.2), cuts=4))
        P.add(cush("Duvet", (1.3, W - 0.04, 0.1), (-0.3, 0, mt + 0.12), fab(c), puff=(0.05, 0.1, 0.5), cuts=5))
        for x in (0.2, 0.25):
            P.add(box("DuvetStripe", (0.025, W - 0.03, 0.105), (x, 0, mt + 0.125), fab("stripe"), r=0.006, seg=1))
        P.add(cush("Pillow", (0.38, 0.6, 0.14), (L / 2 - 0.32, 0, mt + 0.12), fab("linen"), puff=(0.15, 0.1, 0.8),
                   pinch=0.5, cuts=4))
    # Teddy on the top bunk.
    tx, tz = 0.5, high + 0.33
    P.add(ball("TeddyBody", 0.09, (tx, 0.1, tz + 0.08), M("cardboard", 0.9), seg=10, rings=7, scale=(1, 0.9, 1.1)))
    P.add(ball("TeddyHead", 0.07, (tx, 0.1, tz + 0.22), M("cardboard", 0.9), seg=10, rings=7))
    for s in (-1, 1):
        P.add(ball("TeddyEar", 0.03, (tx + s * 0.05, 0.1, tz + 0.28), M("cardboard", 0.9), seg=8, rings=5))


@piece("toy_chest", ["Kids' room"], spot="Toy chest", note="Openable lid hinged at the back edge.")
def toy_chest(P):
    W, D, H = 0.9, 0.55, 0.48
    body = M("sky", 0.5)
    P.add(bun_feet((-W / 2 + 0.07, W / 2 - 0.07), (-D / 2 + 0.07, D / 2 - 0.07), 0.06, 0.05, M("oak", 0.5)))
    # A hollow box: a floor and four walls, so the lid opens on a real inside.
    t = 0.035
    P.add(box("Floor", (W, D, 0.04), (0, 0, 0.05), body, r=0.015))
    P.add(box("Front", (W, t, H - 0.05), (0, -D / 2 + t / 2, 0.05), body, r=0.015))
    P.add(box("BackW", (W, t, H - 0.05), (0, D / 2 - t / 2, 0.05), body, r=0.015))
    for s in (-1, 1):
        P.add(box("Side", (t, D, H - 0.05), (s * (W / 2 - t / 2), 0, 0.05), body, r=0.015))
        P.add(tube("Grip", [(s * W / 2, -0.08, H - 0.12), (s * (W / 2 + 0.04), -0.06, H - 0.1),
                            (s * (W / 2 + 0.04), 0.06, H - 0.1), (s * W / 2, 0.08, H - 0.12)], 0.012, M("mustard", 0.5),
                   n=6))
    # The cream stripes are bands round the outside only, so the inside stays open (house/12).
    for z in (0.17, 0.22):
        for sy in (-1, 1):
            P.add(box("Stripe", (W + 0.004, 0.006, 0.03), (0, sy * (D / 2 - 0.001), z), M("stripe", 0.5), r=0.002, seg=1))
        for sx in (-1, 1):
            P.add(box("Stripe", (0.006, D + 0.004, 0.03), (sx * (W / 2 - 0.001), 0, z), M("stripe", 0.5), r=0.002, seg=1))
    # Star stickers.
    for x, c in ((-0.25, "mustard"), (0.0, "pink"), (0.25, "mustard")):
        P.add(ball("Sticker", 0.04, (x, -D / 2 - 0.002, 0.34), M(c, 0.4), seg=8, rings=4, scale=(1, 0.2, 1)))
    # A ball in a corner; the rest of the inside is for Socks (house/05).
    P.add(ball("Ball", 0.08, (-W / 2 + 0.13, D / 2 - 0.13, 0.17), M("red", 0.4), seg=12, rings=8))
    P.collide((-W / 2, -D / 2, 0.0), (W / 2, D / 2, 0.09))
    for a, b in (((-W / 2, -D / 2, 0.05), (W / 2, -D / 2 + 0.04, H)), ((-W / 2, D / 2 - 0.04, 0.05), (W / 2, D / 2, H)),
                 ((-W / 2, -D / 2, 0.05), (-W / 2 + 0.04, D / 2, H)), ((W / 2 - 0.04, -D / 2, 0.05), (W / 2, D / 2, H))):
        P.collide(a, b)
    lid = [cush("Lid", (W + 0.03, D + 0.03, 0.07), (0, 0, H), body, puff=(0.02, 0.03, 0.4), cuts=4)]
    # Hinged on its top back edge, up to upright: it stays clear of the wall behind (house/12).
    P.hinge("Lid", lid, (0, D / 2 + 0.015, H + 0.07), (-1, 0, 0), 90)
    P.container("Lid", ["Lid"], (-W / 2 + t, -D / 2 + t, 0.09), (W / 2 - t, D / 2 - t, H), "cupboard")


@piece("play_rug", ["Kids' room"], spot="Play rug", note="Flat (2 cm): no collider needed.")
def play_rug(P):
    for r, c, z in ((0.7, "lavender", 0.0), (0.62, "stripe", 0.002), (0.56, "lavender", 0.004), (0.36, "stripe", 0.006),
                    (0.3, "mustard", 0.008)):
        P.add(cyl("Ring", r, 0.014 + z, (0, 0, 0), fab(c), n=32, bev=0.006))


@piece("kids_shelf", ["Kids' room"], spot="Kids' shelf (new)", crawl=None,
       note="A low cube shelf with toys; the plan's kids' room has room for it on the south wall.")
def kids_shelf(P):
    W, D, H = 1.1, 0.36, 0.76
    white = M("white", 0.55)
    P.add(box("Case", (W, D, 0.03), (0, 0, 0.0), white, r=0.01))
    for z in (0.37, 0.73):
        P.add(box("Shelf", (W, D, 0.03), (0, 0, z), white, r=0.01))
    for x in (-W / 2 + 0.015, 0, W / 2 - 0.015):
        P.add(box("Side", (0.03, D, H), (x, 0, 0), white, r=0.01))
    P.add(box("Back", (W, 0.01, H), (0, D / 2 - 0.005, 0), M("pad", 0.7), r=0, seg=1))
    # Fabric bins with the cream stripes.
    for x, c in ((-0.27, "pink"), (0.27, "sage")):
        P.add(cush("Bin", (0.46, D - 0.04, 0.3), (x, 0, 0.03), fab(c), puff=(0.06, 0.06, 0.02), cuts=4))
        for z in (0.24, 0.28):
            P.add(box("BinStripe", (0.462, D - 0.035, 0.018), (x, 0, z), fab("stripe"), r=0.003, seg=1))
    # Top shelf: blocks, a rocket, books.
    for k, c in enumerate(("red", "mustard", "sky")):
        P.add(box("Block", (0.08, 0.08, 0.08), (-0.4 + k * 0.09, 0, 0.4 + (0.08 if k == 1 else 0) * 0), M(c, 0.5),
                  r=0.015))
    P.add(box("Block", (0.08, 0.08, 0.08), (-0.31, 0, 0.48), M("sage", 0.5), r=0.015))
    P.add(lathe("Rocket", [(0, 0), (0.05, 0), (0.05, 0.18), (0.03, 0.25), (0, 0.29)], M("white", 0.4), n=12,
                loc=(0.05, 0, 0.4)))
    for s in (-1, 1):
        P.add(box("Fin", (0.06, 0.015, 0.08), (0.05 + s * 0.05, 0, 0.4), M("red", 0.4), r=0.004, seg=1))
    books(P, 0.2, 0.52, 0, 0.4, 0.22, 21, hmax=0.25, lean=False)
    # A teddy on top.
    P.add(ball("TeddyBody", 0.1, (0.3, 0.0, 0.85), fab("pink"), seg=10, rings=7, scale=(1, 0.9, 1.1)))
    P.add(ball("TeddyHead", 0.075, (0.3, 0.0, 1.0), fab("pink"), seg=10, rings=7))


# --- Bathroom ---------------------------------------------------------------------------------

@piece("bathtub", ["Bathroom"], spot="Bathtub", crawl=0.12, hide="under the tub between its feet",
       note="A roll-top tub on brass feet; hollow inside.")
def bathtub(P):
    por = M("porcelain", 0.15)
    L, W, H, gap = 1.75, 0.76, 0.62, 0.12
    # Outer shell (sage), inner porcelain bowl: two lathes stretched to an oval.
    outer = lathe("Shell", [(0, gap), (0.3, gap), (0.36, gap + 0.06), (0.38, H - 0.04), (0.4, H), (0.39, H + 0.03),
                            (0.36, H + 0.03), (0.35, H - 0.02), (0.33, gap + 0.12), (0.0, gap + 0.1)],
                  M("sage", 0.35), n=28)
    outer.scale = (L / 0.8, W / 0.8, 1.0)
    P.add(outer)
    inner = lathe("Bowl", [(0.0, gap + 0.105), (0.32, gap + 0.125), (0.345, H - 0.02), (0.355, H + 0.025)], por, n=28)
    inner.scale = (L / 0.8 * 0.995, W / 0.8 * 0.995, 1.0)
    P.add(inner)
    P.add(lathe("Rim", [(0.355, H + 0.02), (0.395, H + 0.025), (0.4, H + 0.04), (0.36, H + 0.04)], por, n=28))
    P.body[-1].scale = (L / 0.8, W / 0.8, 1.0)
    for x in (-L / 2 + 0.25, L / 2 - 0.25):
        for y in (-W / 2 + 0.15, W / 2 - 0.15):
            P.add(lathe("Foot", [(0, 0), (0.05, 0), (0.06, 0.03), (0.035, 0.08), (0.05, gap + 0.06), (0, gap + 0.06)],
                        M("brass", 0.3, 0.85), n=10, loc=(x, y, 0)))
    for z in (H - 0.18, H - 0.13):
        b = lathe("Stripe", [(0.383, z - 0.014), (0.39, z), (0.383, z + 0.014)], M("stripe", 0.4), n=28)
        b.scale = (L / 0.8, W / 0.8, 1.0)
        P.add(b)
    # Taps at the foot end, bubbles, a rubber duck.
    br = M("brass", 0.3, 0.85)
    for s in (-1, 1):
        P.add(tube("Tap", [(-L / 2 + 0.06, s * 0.08, H + 0.03), (-L / 2 + 0.06, s * 0.08, H + 0.18),
                           (-L / 2 + 0.14, s * 0.08, H + 0.18)], 0.015, br, n=8))
        P.add(ball("TapHead", 0.025, (-L / 2 + 0.06, s * 0.08, H + 0.2), br, seg=8, rings=5))
    # A rubber duck on the rim; the tub is empty for Socks (house/05).
    P.add(ball("Duck", 0.05, (L / 2 - 0.12, 0.0, H + 0.08), M("mustard", 0.3), seg=10, rings=6))
    P.add(ball("DuckHead", 0.032, (L / 2 - 0.08, 0.0, H + 0.14), M("mustard", 0.3), seg=8, rings=6))
    # Colliders: the bowl's floor and four walls (hollow), a resting top on the floor inside.
    hl, hw, wall = L / 2, W / 2, 0.07
    P.collide((-hl + 0.1, -hw + 0.1, gap), (hl - 0.1, hw - 0.1, gap + 0.11))
    for a, b in (((-hl, -hw, gap), (hl, -hw + wall, H + 0.04)), ((-hl, hw - wall, gap), (hl, hw, H + 0.04)),
                 ((-hl, -hw, gap), (-hl + wall + 0.06, hw, H + 0.04)), ((hl - wall - 0.06, -hw, gap), (hl, hw, H + 0.04))):
        P.collide(a, b)
    P.extra["tops"] = [_top((-hl + 0.2, -hw + 0.14), (hl - 0.2, hw - 0.14), gap + 0.11)]
    # The Socks (physics/09): the tub, its bowl and rim as one trimesh lathe on the drawn one's
    # corners (the outside out to the stripes, the rim's top, the bowl the Socks lie in), not drawn;
    # the stripes round its outside would fill it as hulls. Under 500 triangles (Q795).
    P.sock_skip("Shell", "Bowl", "Rim", "Stripe")
    tub = lathe("SockTub", [(0, gap), (0.3, gap), (0.36, gap + 0.06), (0.39, H - 0.18), (0.39, H - 0.13),
                            (0.4, H + 0.04), (0.355, H + 0.04), (0.345, H - 0.02), (0.32, gap + 0.125),
                            (0.0, gap + 0.105)], por, n=28)
    tub.scale = (L / 0.8, W / 0.8, 1.0)
    P.sock_mesh(tub)


@piece("vanity", ["Bathroom"], spot="Vanity", crawl=0.12,
       note="Basin on a two-door cupboard; a round mirror goes on the wall above (the game's mirror spot).")
def vanity(P):
    W, D, H, gap = 0.8, 0.48, 0.82, 0.12
    P.add(peg_legs((-W / 2 + 0.06, W / 2 - 0.06), (-D / 2 + 0.06, D / 2 - 0.06), gap + 0.02, 0.022,
                   M("brass", 0.3, 0.85)))
    y = -D / 2 + 0.02
    lo, hi = shell(P, "Case", (-W / 2, y, gap), (W / 2, D / 2, H - 0.04), 0.018, M("white", 0.55), r=0.006)
    for name, x0, x1, left in (("Door_L", -W / 2 + 0.005, -0.0025, True), ("Door_R", 0.0025, W / 2 - 0.005, False)):
        objs, piv, ax = _door(name, x0, x1, gap + 0.01, H - 0.05, y, "sage", hinge_left=left)
        P.hinge(name, objs, piv, ax, 100)
    P.container("Doors", ["Door_L", "Door_R"], (lo[0], lo[1] + 0.005, lo[2]), hi, "cupboard")
    P.add(box("Top", (W + 0.02, D + 0.02, 0.04), (0, 0, H - 0.04), M("oak", 0.4), r=0.012))
    P.collide((-W / 2 - 0.01, -D / 2 - 0.01, H - 0.04), (W / 2 + 0.01, D / 2 + 0.01, H))
    P.extra["tops"] = [_top((-W / 2 + 0.02, D / 2 - 0.12), (-0.22, D / 2 - 0.01), H)]
    b = lathe("Basin", [(0, 0), (0.15, 0.0), (0.2, 0.08), (0.21, 0.13), (0.19, 0.135), (0.16, 0.06), (0, 0.04)],
              M("porcelain", 0.15), n=20, loc=(0, 0, 0))
    b.location = (0, -0.02, H)
    b.scale = (1.0, 0.8, 1.0)
    P.add(b)
    P.sock_skip("Basin")   # the Socks lie in it as drawn (physics/09)
    P.sock_mesh(b)
    P.add(tube("Tap", [(0, 0.2, H), (0, 0.2, H + 0.22), (0, 0.13, H + 0.25), (0, 0.08, H + 0.2)], 0.013,
               M("brass", 0.3, 0.85), n=8))
    for k, c in enumerate(("pink", "sky")):
        P.add(cyl("Cup", 0.035, 0.1, (-0.3 + k * 0.08, 0.14, H), M(c, 0.3), n=10, bev=0.006))
    P.add(tube("Brush", [(-0.3, 0.14, H + 0.06), (-0.31, 0.15, H + 0.2)], 0.006, M("mustard", 0.4), n=5))


@piece("towel_rail", ["Bathroom"], spot="Towel rail (new)", crawl=None, note="Wall-standing rail with two towels.")
def towel_rail(P):
    st = M("brass", 0.3, 0.85)
    W, H = 0.6, 1.0
    for s in (-1, 1):
        P.add(tube("Upright", [(s * W / 2, 0, 0.1), (s * W / 2, 0, H)], 0.016, st, n=8))
        P.add(tube("Foot", [(s * W / 2, -0.12, 0.0), (s * W / 2, 0, 0.1), (s * W / 2, 0.1, 0.0)], 0.014, st, n=6))
    for z in (0.45, 0.65, 0.85, H):
        P.add(tube("Bar", [(-W / 2, 0, z), (W / 2, 0, z)], 0.012, st, n=6))
    for x, c in ((-0.12, "pink"), (0.15, "sage")):
        for s in (-1, 1):
            P.add(cush("Towel", (0.26, 0.025, 0.45), (x, s * 0.02, H - 0.45), fab(c), puff=(0.03, 0.5, 0.02), cuts=3))
            for z in (H - 0.38, H - 0.34):
                P.add(box("Stripe", (0.262, 0.03, 0.018), (x, s * 0.02, z), fab("stripe"), r=0.003, seg=1))
        P.add(tube("Fold", [(x - 0.13, 0, H + 0.01), (x + 0.13, 0, H + 0.01)], 0.026, fab(c), n=8))


@piece("bath_mat", ["Bathroom"], spot="Bath mat (new)", note="Flat: no collider needed.")
def bath_mat(P):
    P.add(cush("Mat", (0.75, 0.48, 0.025), (0, 0, 0), fab("sage"), puff=(0.03, 0.04, 0.3), cuts=4))
    for x in (-0.28, -0.24, 0.24, 0.28):
        P.add(box("Stripe", (0.02, 0.44, 0.027), (x, 0, 0), fab("stripe"), r=0.003, seg=1))


# --- Home office -------------------------------------------------------------------------------

@piece("desk", ["Home office"], spot="Desk", crawl=0.7, hide="under the desk (the knee space)",
       note="One drawer on the right; a lamp, a mug and papers on top.")
def desk(P):
    P.sock_dev = 0.005   # its merged Sock colliders keep the tops Socks rest on (physics/09)
    oak = M("oak", 0.5)
    W, D, top = 1.4, 0.7, 0.75
    P.add(box("Top", (W, D, 0.04), (0, 0, top - 0.04), oak, r=0.015))
    P.collide((-W / 2, -D / 2, top - 0.04), (W / 2, D / 2, top))
    for x in (-W / 2 + 0.06, W / 2 - 0.06):
        for y in (-D / 2 + 0.06, D / 2 - 0.06):
            P.collide((x - 0.03, y - 0.03, 0), (x + 0.03, y + 0.03, top - 0.04))
    P.extra["tops"] = [_top((-W / 2 + 0.03, -D / 2 + 0.03), (W / 2 - 0.03, D / 2 - 0.03), top)]
    for x in (-W / 2 + 0.06, W / 2 - 0.06):
        for y in (-D / 2 + 0.06, D / 2 - 0.06):
            P.add(lathe("Leg", [(0, 0), (0.022, 0), (0.03, top - 0.04), (0, top - 0.04)], M("dark_wood", 0.5), n=10,
                        loc=(x, y, 0)))
    P.add(box("Apron", (W - 0.14, 0.02, 0.1), (0, D / 2 - 0.06, top - 0.14), oak, r=0.006, seg=1))
    # A hanging drawer box under the right side.
    shell(P, "DrawerCase", (0.21, -D / 2 + 0.06, top - 0.17), (0.63, D / 2 - 0.06, top - 0.04), 0.012, oak,
          open=("front", "top"))
    _drawer(P, "Drawer_1", 0.22, 0.62, top - 0.155, top - 0.045, -D / 2 + 0.06, "sage", depth=0.4, open_m=0.3)
    # Lamp, papers, mug, a pot of pens.
    st = M("mustard", 0.4)
    P.add(cyl("LampBase", 0.08, 0.025, (-0.5, 0.18, top), st, n=14, bev=0.01))
    P.add(tube("LampArm", [(-0.5, 0.18, top + 0.02), (-0.46, 0.2, top + 0.3), (-0.32, 0.12, top + 0.42)], 0.012, st, n=6))
    sh = lathe("LampShade", [(0, 0.1), (0.04, 0.1), (0.08, 0.0), (0.075, -0.004), (0, 0.06)], st, n=14)
    sh.location = (-0.3, 0.1, top + 0.33)
    P.add(sh)
    for k in range(3):
        p = box("Paper", (0.21, 0.297, 0.003), (0, 0, 0), M("paper", 0.8), r=0, seg=1)
        p.location = (0.05 + k * 0.02, -0.02, top + k * 0.003)
        p.rotation_euler.z = 0.1 * (k - 1)
        P.add(p)
    P.add(cyl("Mug", 0.045, 0.1, (0.4, 0.15, top), M("pink", 0.4), n=12, bev=0.008))
    P.add(cyl("PenPot", 0.04, 0.11, (-0.2, 0.25, top), M("sky", 0.4), n=10))
    for k, c in enumerate(("red", "navy", "mustard")):
        P.add(tube("Pen", [(-0.2 + 0.01 * (k - 1), 0.25, top + 0.05), (-0.2 + 0.03 * (k - 1), 0.25, top + 0.17)], 0.006,
                   M(c, 0.4), n=5))
    # A laptop, closed.
    P.add(box("Laptop", (0.34, 0.24, 0.02), (0.05, 0.2, top), M("grey", 0.35, 0.5), r=0.008))


@piece("office_chair", ["Home office"], spot="Office chair", crawl=0.38, hide="under the seat")
def office_chair(P):
    blk = M("charcoal", 0.4)
    seat = 0.47
    for k in range(5):
        a = 2 * math.pi * k / 5 + math.pi / 2
        x, y = 0.3 * math.cos(a), 0.3 * math.sin(a)
        P.add(tube("Spoke", [(0, 0, 0.1), (x, y, 0.07)], 0.022, blk, n=6))
        P.add(ball("Caster", 0.035, (x, y, 0.035), blk, seg=8, rings=5))
    P.add(cyl("Gas", 0.03, seat - 0.15, (0, 0, 0.08), M("steel", 0.3, 0.8), n=10))
    P.add(cush("Seat", (0.5, 0.48, 0.1), (0, 0, seat - 0.06), fab("mustard"), puff=(0.08, 0.08, 0.4), cuts=5))
    P.add(tube("BackArm", [(0, 0.12, seat - 0.05), (0, 0.26, seat), (0, 0.27, seat + 0.2)], 0.02, blk, n=6))
    bk = cush("Back", (0.46, 0.08, 0.46), (0, 0, 0), fab("mustard"), puff=(0.1, 0.5, 0.1), cuts=5)
    bk.location = (0, 0.27, seat + 0.12)
    bk.rotation_euler.x = math.radians(-8)
    P.add(bk)
    for z in (seat + 0.44, seat + 0.48):
        s = box("BackStripe", (0.44, 0.09, 0.02), (0, 0, 0), fab("stripe"), r=0.004, seg=1)
        s.location = (0, 0.27 + (z - seat - 0.12) * math.sin(math.radians(8)), z)
        s.rotation_euler.x = math.radians(-8)
        P.add(s)
    for sx in (-1, 1):
        P.add(tube("Arm", [(sx * 0.25, 0.08, seat - 0.04), (sx * 0.27, 0.05, seat + 0.18), (sx * 0.27, -0.15, seat + 0.18)],
                   0.016, blk, n=6))
        P.add(box("ArmPad", (0.06, 0.24, 0.03), (sx * 0.27, -0.05, seat + 0.17), blk, r=0.012))


@piece("bookshelf", ["Home office", "Landing", "Living room"], spot="Bookshelf, Bookcase", crawl=0.08,
       note="Tall bookcase, full of books; also the landing's Bookcase.")
def bookshelf(P):
    oak = M("oak", 0.55)
    W, D, H = 0.9, 0.34, 1.9
    for x in (-W / 2 + 0.015, W / 2 - 0.015):
        P.add(box("Side", (0.03, D, H), (x, 0, 0), oak, r=0.01))
    P.add(box("Plinth", (W - 0.03, D - 0.03, 0.08), (0, -0.01, 0), oak, r=0.006, seg=1))
    P.add(box("Crown", (W + 0.04, D + 0.03, 0.04), (0, 0, H), oak, r=0.012))
    P.add(box("Back", (W - 0.03, 0.012, H), (0, D / 2 - 0.006, 0), M("dark_wood", 0.6), r=0, seg=1))
    zs = [0.08, 0.46, 0.84, 1.22, 1.58]
    for z in zs:
        P.add(box("Shelf", (W - 0.03, D - 0.02, 0.025), (0, 0, z), oak, r=0.006, seg=1))
    for k, z in enumerate(zs):
        x1 = W / 2 - 0.05 - (0.3 if k == 2 else 0)
        books(P, -W / 2 + 0.04, x1, -0.01, z + 0.025, D - 0.06, 31 + k, hmax=0.3 if z < 1.5 else 0.24)
    # A little plant and a box file on the middle shelf.
    P.add(lathe("Pot", [(0, 0), (0.06, 0), (0.07, 0.1), (0, 0.1)], M("terracotta", 0.7), n=12, loc=(0.27, 0, 0.865)))
    for k in range(5):
        a = k * 1.25
        P.add(ball("Leaf", 0.045, (0.27 + 0.04 * math.cos(a), 0.04 * math.sin(a), 0.99 + 0.02 * (k % 2)), M("leaf", 0.5),
                   seg=8, rings=5, scale=(1, 1, 0.6)))
    P.add(box("BoxFile", (0.1, 0.26, 0.3), (0.13, -0.01, 0.865), M("pink", 0.6), r=0.008))


@piece("printer", ["Home office"], spot="Printer", note="Desktop printer, static: its scanner lid stays shut (house/12).")
def printer(P):
    wh = M("white", 0.45)
    W, D, H = 0.52, 0.42, 0.2
    P.add(box("Body", (W, D, H - 0.03), (0, 0, 0), wh, r=0.03, seg=2))
    P.collide((-W / 2, -D / 2, 0), (W / 2, D / 2, H))
    P.add(box("Slot", (0.32, 0.02, 0.025), (0, -D / 2, 0.05), M("charcoal", 0.5), r=0.005, seg=1))
    P.add(box("Tray", (0.3, 0.16, 0.012), (0, -D / 2 - 0.07, 0.05), wh, r=0.004, seg=1))
    P.add(box("Paper", (0.21, 0.12, 0.004), (0, -D / 2 - 0.06, 0.062), M("paper", 0.8), r=0, seg=1))
    P.add(box("Panel", (0.1, 0.06, 0.012), (0.19, -D / 2 + 0.05, H - 0.03), M("charcoal", 0.4), r=0.004, seg=1))
    P.add(ball("Button", 0.008, (0.22, -D / 2 + 0.05, H - 0.017), M("sage", 0.4), seg=8, rings=4))
    P.add(box("Lid", (0.38, 0.33, 0.03), (-0.06, 0.035, H - 0.03), wh, r=0.012),
          box("LidStripe", (0.38, 0.012, 0.031), (-0.06, -D / 2 + 0.11, H - 0.03), M("sky", 0.4), r=0, seg=1))


@piece("filing_cabinet", ["Home office"], spot="Filing cabinet",
       note="Three drawers (Drawer_1 top) that slide out 0.45 m; each is a hollow tray with files.")
def filing_cabinet(P):
    body = M("sage", 0.4, 0.2)
    W, D, H = 0.46, 0.62, 1.02
    shell(P, "Case", (-W / 2, -D / 2 + 0.02, 0), (W / 2, D / 2, H), 0.02, body, r=0.008)
    P.add(box("Plinth", (W - 0.04, D - 0.06, 0.04), (0, 0.02, 0), M("charcoal", 0.6), r=0.006, seg=1))
    y = -D / 2 + 0.02
    zs = [0.06, 0.38, 0.7, H - 0.02]
    br = M("brass", 0.3, 0.85)
    for k in range(3):
        z0, z1 = zs[2 - k], zs[3 - k] - 0.01
        name = f"Drawer_{k + 1}"
        cx = 0.0
        h = z1 - z0
        dd = D - 0.08
        objs = [box(name, (W - 0.03, 0.025, h), (cx, y - 0.0125, z0), body, r=0.012),
                handle_bar(name + "Bar", -0.08, 0.08, y - 0.025, z1 - 0.08, br, r=0.009),
                box(name + "Label", (0.1, 0.006, 0.05), (cx, y - 0.026, z1 - 0.04), M("paper", 0.7), r=0, seg=1),
                # The tray: floor, sides and back, open at the top.
                box(name + "Floor", (W - 0.06, dd, 0.012), (cx, y + dd / 2, z0 + 0.02), M("grey", 0.6), r=0, seg=1),
                box(name + "BackW", (W - 0.06, 0.012, h - 0.06), (cx, y + dd, z0 + 0.02), M("grey", 0.6), r=0, seg=1)]
        for s in (-1, 1):
            objs.append(box(name + "SideW", (0.012, dd, h - 0.06), (s * (W / 2 - 0.036), y + dd / 2, z0 + 0.02),
                            M("grey", 0.6), r=0, seg=1))
        for j, c in enumerate(("mustard", "pink")):
            objs.append(box(name + "File", (W - 0.1, 0.012, h - 0.1 + 0.02 * (j % 2)), (cx, y + dd - 0.1 + j * 0.05,
                            z0 + 0.03), M(c, 0.7), r=0.002, seg=1))
        tlo, thi = (cx - (W - 0.06) / 2, y, z0 + 0.02), (cx + (W - 0.06) / 2, y + dd + 0.012, z0 + h - 0.04)
        P.slide(name, objs, (cx, y, z0), (0, -1, 0), 0.45, boxes=tray_boxes(tlo, thi, front=0.025))
        P.container(name, [name], (tlo[0] + 0.012, y + 0.005, tlo[2] + 0.012), (thi[0] - 0.012, y + dd - 0.11, thi[2]),
                    "drawer")


# --- Bathroom: the Cat's litterbox (cat/11) ------------------------------------------------------

def _carve(ob, cutters):
    """Applies ob's modifiers, then cuts each cutter out of it (an exact boolean) and deletes the
    cutters: the hood's hollow and its doorway."""
    import bpy
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    for md in list(ob.modifiers):
        bpy.ops.object.modifier_apply(modifier=md.name)
    for c in cutters:
        md = ob.modifiers.new("Cut", "BOOLEAN")
        md.operation = "DIFFERENCE"
        md.solver = "EXACT"
        md.object = c
        bpy.ops.object.modifier_apply(modifier=md.name)
    for c in cutters:
        bpy.data.objects.remove(c, do_unlink=True)
    return ob


# The litterbox's measures (Blender, m): the Cat (about 0.25 m at the shoulder, make_cat.py) walks
# in through the flap and turns round inside.
LB_W, LB_D, LB_H = 0.58, 0.46, 0.48
LB_TRAY = 0.17          # the tray's height; the hood sits on its rim
LB_LITTER = 0.08        # the litter's top, where the Socks lie
LB_DOOR = (0.13, 0.40)  # the doorway's half width and top (it opens down to the tray's rim)


@piece("litterbox", ["Bathroom"], spot="Litterbox (new, cat/11)", crawl=None,
       hide="inside on the litter, through the flap",
       note="A covered litterbox, kept simple (Q1980, Q1985): a tray, a hood with a carry handle, a flap door with a paw print hinged at its top edge.")
def litterbox(P):
    W, D, H, T = LB_W, LB_D, LB_H, LB_TRAY
    dx, dtop = LB_DOOR
    t = 0.018
    # The tray: an open-topped box in one colour.
    shell(P, "Tray", (-W / 2, -D / 2, 0.0), (W / 2, D / 2, T), t, M("sage_dark", 0.45), open=("top",), r=0.008)
    # The litter, a plain sandy bed; the Socks lie on it (house/05).
    P.add(box("Litter", (W - 2 * t, D - 2 * t, LB_LITTER - t), (0, 0, t), M("cardboard", 0.95), r=0, seg=1))
    # The hood: a rounded shell in one colour, hollow, its doorway cut in the front. Its foot reaches
    # down inside the tray's walls, so its rounded bottom edge stays hidden.
    hm = M("sage", 0.35)
    hb = T - 0.07
    hood = box("Hood", (W - 0.012, D - 0.012, H - hb), (0, 0, hb), hm, r=0.07, seg=3)
    inner = box("HoodIn", (W - 0.052, D - 0.052, H - hb), (0, 0, hb - 0.04), hm, r=0.05, seg=2)
    door = box("DoorCut", (2 * dx, 0.1, dtop - hb + 0.02), (0, -D / 2, hb - 0.02), hm, r=0, seg=1)
    P.add(_carve(hood, [inner, door]))
    # The flap: a plain panel filling the doorway in the hood's wall, hinged at its top edge. It swings
    # in (+open_deg about +x: its foot into the box) up under the roof, so the doorway is clear and the
    # Socks inside can be seen. Players open it to reach them (Q1981); the Cat pushes through.
    fy = -(D - 0.012) / 2 + 0.01
    pz = dtop - 0.006
    fl = [box("Flap", (2 * dx - 0.01, 0.008, pz - T - 0.008), (0, fy, T + 0.004), M("sky", 0.25), r=0.003, seg=1)]
    # A cream paw print on its front (Q1985).
    pc = (0, fy - 0.004, (T + pz) / 2 - 0.02)
    fl.append(ball("Paw", 0.03, pc, M("stripe", 0.5), seg=10, rings=4, scale=(1.1, 0.12, 0.9)))
    for ox, oz in ((-0.034, 0.03), (-0.012, 0.048), (0.012, 0.048), (0.034, 0.03)):
        fl.append(ball("Toe", 0.012, (pc[0] + ox, pc[1], pc[2] + oz), M("stripe", 0.5), seg=8, rings=4,
                       scale=(1, 0.15, 1.15)))
    P.hinge("Flap", fl, (0, fy, pz), (1, 0, 0), 85, boxes=[((-dx + 0.005, fy - 0.006, T), (dx - 0.005, fy + 0.004, pz))])
    # The carry handle on the roof (Q1985), in the tray's colour (no new colour).
    hp = [(-0.1, 0.0, H - 0.01), (-0.09, 0.0, H + 0.04), (0.09, 0.0, H + 0.04), (0.1, 0.0, H - 0.01)]
    P.add(tube("Handle", hp, 0.014, M("sage_dark", 0.45), n=8))
    P.sock_skip("Handle")   # as a hull it would roof the space under its arch
    P.sock_tube(hp, 0.014)
    # Colliders: the tray (shell() above), the hood's walls and roof round the doorway; the Socks
    # meet the same boxes, not the hood as drawn (a hull would fill its inside).
    P.sock_skip("Hood")
    hw = 0.04
    fr = -(D - 0.012) / 2
    for a, b in (((-W / 2, D / 2 - hw, T), (W / 2, D / 2, H)),          # back
                 ((-W / 2, -D / 2, T), (-W / 2 + hw, D / 2, H)),        # left
                 ((W / 2 - hw, -D / 2, T), (W / 2, D / 2, H)),          # right
                 ((-W / 2, -D / 2, H - 0.025), (W / 2, D / 2, H)),      # roof
                 ((-W / 2, fr, T), (-dx, fr + hw, H)),                  # beside the doorway
                 ((dx, fr, T), (W / 2, fr + hw, H)),
                 ((-dx, fr, dtop), (dx, fr + hw, H))):                  # over it
        P.collide(a, b, sock=True)
    P.collide((-W / 2 + t, -D / 2 + t, 0.0), (W / 2 - t, D / 2 - t, LB_LITTER))     # the litter bed
    # The inside where the Socks lie: on the litter, under the roof, opened by the flap.
    P.container("Flap", ["Flap"], (-W / 2 + hw, -D / 2 + hw, LB_LITTER), (W / 2 - hw, D / 2 - hw, H - 0.025), "litter_flap")
