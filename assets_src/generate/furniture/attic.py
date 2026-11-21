"""The attic junk loft's furniture (house/04): trunks, a sheeted sofa (not placed, Q430), a rocking
horse, an old cot, a telescope (the boxes are basement.py's storage_boxes). The sheeted wardrobe and
its lifting dust sheet are gone (house/12).

Blender axes: z up, front -y, each piece built around x = 0, y = 0 (build.py centres it).
"""

import math
import random

import bmesh

import kit
from fkit import M, ball, box, bx, cush, cyl, fab, lathe, piece, shell, tube  # noqa: F401

ROOMS = ["Junk loft"]


@piece("trunk", ["Junk loft"], spot="Trunk (x2)",
       note="A domed travel trunk; the Lid hinges at its back edge. Used twice in the loft.")
def trunk(P):
    W, D, H = 0.9, 0.5, 0.36
    body = M("navy", 0.6)
    br = M("brass", 0.3, 0.85)
    leather = M("dark_wood", 0.6)
    t = 0.03
    P.add(box("Floor", (W, D, 0.03), (0, 0, 0.0), body, r=0.012))
    P.add(box("Front", (W, t, H), (0, -D / 2 + t / 2, 0), body, r=0.012))
    P.add(box("BackW", (W, t, H), (0, D / 2 - t / 2, 0), body, r=0.012))
    for s in (-1, 1):
        P.add(box("Side", (t, D, H), (s * (W / 2 - t / 2), 0, 0), body, r=0.012))
        P.add(tube("Handle", [(s * W / 2, -0.07, H - 0.12), (s * (W / 2 + 0.03), -0.05, H - 0.1),
                              (s * (W / 2 + 0.03), 0.05, H - 0.1), (s * W / 2, 0.07, H - 0.12)], 0.012, leather, n=6))
    for x in (-W / 2 + 0.06, W / 2 - 0.06):
        for y in (-D / 2, D / 2):
            P.add(box("Corner", (0.07, 0.012, 0.07), (x * 1.0, y - math.copysign(0.002, -y), 0.0), br, r=0.006, seg=1))
    # The straps run down the front and the back only: nothing crosses the open top (house/12).
    for x in (-0.25, 0.25):
        for sy in (-1, 1):
            P.add(box("Strap", (0.06, 0.012, H - 0.02), (x, sy * (D / 2 + 0.004), 0.0), leather, r=0.004, seg=1))
    # Inside: a folded quilt with the cream stripes; Socks hide on it (house/05).
    P.add(cush("Quilt", (W - 0.1, D - 0.1, 0.12), (0, 0, 0.03), fab("pink"), puff=(0.05, 0.05, 0.3), cuts=3))
    P.collide((-W / 2, -D / 2, 0), (W / 2, D / 2, 0.13))
    for a, b in (((-W / 2, -D / 2, 0), (W / 2, -D / 2 + 0.04, H)), ((-W / 2, D / 2 - 0.04, 0), (W / 2, D / 2, H)),
                 ((-W / 2, -D / 2, 0), (-W / 2 + 0.04, D / 2, H)), ((W / 2 - 0.04, -D / 2, 0), (W / 2, D / 2, H))):
        P.collide(a, b)
    P.container("Lid", ["Lid"], (-W / 2 + t, -D / 2 + t, 0.13), (W / 2 - t, D / 2 - t, H), "cupboard")
    # The domed lid: a half-cylinder top along x, its straps and the lock.
    bm = bmesh.new()
    n = 10
    rings = []
    for x in (-W / 2, W / 2):
        ring = [bm.verts.new((x, -D / 2 * math.cos(math.pi * k / n), H + 0.12 * math.sin(math.pi * k / n)))
                for k in range(n + 1)]
        rings.append(ring)
    for k in range(n):
        bm.faces.new((rings[0][k], rings[1][k], rings[1][k + 1], rings[0][k + 1]))
    bm.faces.new(rings[0])
    bm.faces.new(list(reversed(rings[1])))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    lid_ob = kit.obj_from_bm("Lid", bm, body)
    kit.bevel(lid_ob, 0.012, 2, angle=50)
    lid = [lid_ob]
    for x in (-0.25, 0.25):
        pts = [(x, -D / 2 * math.cos(math.pi * k / n) * 1.02, H + 0.123 * math.sin(math.pi * k / n)) for k in range(n + 1)]
        lid.append(tube("LidStrap", pts, 0.012, leather, n=5))
    lid.append(box("Lock", (0.08, 0.02, 0.07), (0, -D / 2 - 0.01, H - 0.04), br, r=0.008))
    P.hinge("Lid", lid, (0, D / 2, H), (-1, 0, 0), 100)


def _sheet_over(P, size, seed, folds=6, back=True):
    """A dust sheet draped over a block of size (w, d, h): a puffed box with a flared skirt and folds.
    Returns its objects (without `back`, the sheet hangs open behind)."""
    out = []
    w, d, h = size
    sheet = fab("sheet")
    rng = random.Random(seed)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=2.0)
    bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=7, use_grid_fill=True)
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.calc_center_median().z < -0.99
                               or (not back and f.calc_center_median().y > 0.99)], context="FACES")
    for v in bm.verts:
        u, s, t = v.co
        lift = (t + 1) / 2                      # 0 at the floor, 1 on top
        flare = 1 + 0.08 * (1 - lift) ** 2      # the hem flares out
        sag = 0.05 * (1 - u * u) * (1 - s * s) if t > 0.99 else 0.0
        wob = 0.012 * math.sin(u * 7 + seed) * math.sin(s * 5) * (1 - lift)
        v.co = ((u * w / 2) * flare + wob, (s * d / 2) * flare + wob, (lift * h) - sag * h * 0.3 + (0.01 if t > 0.99 else 0))
    ob = kit.obj_from_bm("Sheet", bm, sheet)
    kit.bevel(ob, 0.03, 2, angle=35)
    out.append(ob)
    for k in range(folds):
        side = rng.choice((-1, 1)) if back else -1
        if rng.random() < 0.5:
            x = rng.uniform(-w / 2 + 0.15, w / 2 - 0.15)
            pts = [(x, side * (d / 2 + 0.005 + 0.02 * (1 - t)), h * t) for t in (0.0, 0.3, 0.6, 0.9)]
        else:
            y = rng.uniform(-d / 2 + 0.1, d / 2 - 0.1)
            pts = [(side * (w / 2 + 0.005 + 0.02 * (1 - t)), y, h * t) for t in (0.0, 0.3, 0.6, 0.9)]
        out.append(tube("Fold", pts, [0.03, 0.025, 0.015, 0.006], sheet, n=6))
    return out


@piece("sheeted_sofa", ["Junk loft"], spot="Sofa under sheet", hide="behind it, in the sheet's hem",
       note="A sofa shape under a dust sheet (hangs to the floor: no crawl gap).")
def sheeted_sofa(P):
    w, d = 2.0, 0.85
    sheet = fab("sheet")
    P.add(_sheet_over(P, (w, d, 0.45), 3))
    P.add(cush("Back", (w - 0.1, 0.3, 0.42), (0, d / 2 - 0.17, 0.4), sheet, puff=(0.05, 0.3, 0.3), cuts=5))
    for s in (-1, 1):
        P.add(cush("Arm", (0.28, d, 0.22), (s * (w / 2 - 0.13), 0, 0.4), sheet, puff=(0.3, 0.05, 0.5), cuts=4))
    # The cream stripes on a cushion poking out from under the hem.
    P.add(cush("Cushion", (0.4, 0.12, 0.36), (0.55, -d / 2 - 0.04, 0.0), fab("mustard"), puff=(0.1, 1.0, 0.1), cuts=4))
    for z in (0.15, 0.2):
        P.add(box("Stripe", (0.39, 0.13, 0.02), (0.55, -d / 2 - 0.04, z), fab("stripe"), r=0.004, seg=1))


@piece("rocking_horse", ["Junk loft"], spot="Rocking horse", crawl=None,
       note="Faces along x (side-on); the rockers touch the floor at their middle.")
def rocking_horse(P):
    wood = M("oak", 0.5)
    L = 1.0
    # Rockers: two curved runners and cross bars.
    for y in (-0.16, 0.16):
        pts = [(x, y, 0.025 + 0.3 * (x / L) ** 2 * 2) for x in [-L / 2 + L * k / 10 for k in range(11)]]
        P.add(tube("Rocker", pts, 0.025, M("dark_wood", 0.5), n=6))
    for x in (-0.3, 0.3):
        P.add(tube("Bar", [(x, -0.17, 0.08), (x, 0.17, 0.08)], 0.02, M("dark_wood", 0.5), n=6))
        for y in (-0.16, 0.16):
            P.add(tube("Post", [(x, y, 0.08), (x * 0.6, y * 0.4, 0.42)], 0.025, wood, n=6))
    # Body, neck, head: soft cream-dappled horse.
    hide = M("paper", 0.6)
    P.add(cush("Body", (0.62, 0.24, 0.24), (0, 0, 0.4), hide, puff=(0.3, 0.3, 0.3), cuts=4))
    P.add(tube("Neck", [(0.22, 0, 0.56), (0.3, 0, 0.72), (0.34, 0, 0.82)], [0.08, 0.07, 0.065], hide, n=10))
    P.add(cush("Head", (0.26, 0.12, 0.13), (0.42, 0, 0.78), hide, puff=(0.3, 0.3, 0.3), cuts=3))
    for s in (-1, 1):
        P.add(ball("Ear", 0.03, (0.33, s * 0.04, 0.92), hide, seg=6, rings=4, scale=(0.6, 0.6, 1.4)))
        P.add(ball("Eye", 0.014, (0.42, s * 0.06, 0.86), M("charcoal", 0.3), seg=6, rings=4))
        for x in (-0.22, 0.22):
            P.add(tube("Leg", [(x, s * 0.08, 0.42), (x * 1.15, s * 0.1, 0.2)], 0.035, hide, n=8))
    for k in range(5):
        t = k / 4
        P.add(ball("Mane", 0.04, (0.2 + 0.12 * t, 0, 0.64 + 0.26 * t), fab("stripe"), seg=8, rings=5, scale=(1, 0.6, 1)))
    P.add(tube("Tail", [(-0.3, 0, 0.55), (-0.4, 0, 0.52), (-0.45, 0, 0.38)], [0.04, 0.035, 0.02], fab("stripe"), n=6))
    P.add(cush("Saddle", (0.22, 0.28, 0.05), (0.0, 0, 0.62), M("red", 0.5), puff=(0.2, 0.2, 0.5), cuts=3))
    for s in (-1, 1):
        P.add(box("Spot", (0.08, 0.01, 0.06), (-0.15 + 0.15 * (s + 1), s * 0.121, 0.48), M("cardboard", 0.7), r=0.02))


@piece("old_cot", ["Junk loft"], spot="Old cot", crawl=0.3, hide="under the cot")
def old_cot(P):
    wood = M("white", 0.6)
    L, W, H = 1.2, 0.62, 0.92
    for x in (-L / 2, L / 2):
        for y in (-W / 2, W / 2):
            P.add(box("Post", (0.05, 0.05, H), (x, y, 0), wood, r=0.015))
            P.add(ball("Knob", 0.035, (x, y, H + 0.015), wood, seg=8, rings=6))
    for z in (0.28, H - 0.06):
        for y in (-W / 2, W / 2):
            P.add(box("Rail", (L, 0.035, 0.04), (0, y, z), wood, r=0.01))
        for x in (-L / 2, L / 2):
            P.add(box("EndRail", (0.035, W, 0.04), (x, 0, z), wood, r=0.01))
    for k in range(13):
        x = -L / 2 + 0.08 + (L - 0.16) * k / 12
        for y in (-W / 2, W / 2):
            P.add(cyl("Spindle", 0.012, H - 0.36, (x, y, 0.3), wood, n=6))
    for k in range(6):
        y = -W / 2 + 0.07 + (W - 0.14) * k / 5
        for x in (-L / 2, L / 2):
            P.add(cyl("Spindle", 0.012, H - 0.36, (x, y, 0.3), wood, n=6))
    P.add(cush("Mattress", (L - 0.06, W - 0.06, 0.1), (0, 0, 0.32), fab("linen"), puff=(0.03, 0.05, 0.3), cuts=4))
    P.add(cush("Blanket", (0.55, W - 0.04, 0.05), (-0.2, 0, 0.42), fab("lavender"), puff=(0.05, 0.05, 0.5), cuts=4))
    for x in (-0.06, -0.02):
        P.add(box("Stripe", (0.02, W - 0.03, 0.052), (x, 0, 0.42), fab("stripe"), r=0.004, seg=1))
    # A mobile hanging off the head post.
    P.add(tube("MobileArm", [(L / 2, 0, H), (L / 2, 0, H + 0.3), (L / 2 - 0.3, 0, H + 0.3)], 0.01, wood, n=5))
    for k, c in enumerate(("pink", "mustard", "sky")):
        x = L / 2 - 0.12 - 0.08 * k
        P.add(tube("String", [(x, 0, H + 0.3), (x, 0, H + 0.16)], 0.002, M("charcoal", 0.6), n=3))
        P.add(ball("Star", 0.03, (x, 0, H + 0.14), M(c, 0.4), seg=6, rings=4, scale=(1, 0.4, 1)))


@piece("telescope", ["Junk loft"], spot="Telescope", note="On a tripod, pointing up out of the dormer window (+x).")
def telescope(P):
    wood = M("oak", 0.5)
    br = M("brass", 0.3, 0.85)
    top = 1.05
    for k in range(3):
        a = math.radians(90 + 120 * k)
        P.add(tube("Leg", [(0.32 * math.cos(a), 0.32 * math.sin(a), 0.0), (0.03 * math.cos(a), 0.03 * math.sin(a), top)],
                   0.018, wood, n=6))
    P.add(cyl("Mount", 0.05, 0.06, (0, 0, top), br, n=10, bev=0.01))
    tilt = math.radians(32)
    d = (math.cos(tilt), 0, math.sin(tilt))
    c = (0, 0, top + 0.1)
    a = (c[0] - d[0] * 0.4, 0, c[2] - d[2] * 0.4)
    b = (c[0] + d[0] * 0.45, 0, c[2] + d[2] * 0.45)
    P.add(tube("Tube", [a, c, b], [0.04, 0.05, 0.06], M("navy", 0.4), n=14))
    P.add(tube("Hood", [b, (b[0] + d[0] * 0.1, 0, b[2] + d[2] * 0.1)], 0.068, br, n=14))
    P.add(tube("Eyepiece", [a, (a[0] - d[0] * 0.12, 0, a[2] - d[2] * 0.12)], 0.02, br, n=8))
    for t in (-0.2, 0.15):
        p = (c[0] + d[0] * t, 0, c[2] + d[2] * t)
        P.add(tube("Band", [(p[0] - d[0] * 0.015, 0, p[2] - d[2] * 0.015), (p[0] + d[0] * 0.015, 0, p[2] + d[2] * 0.015)],
                   0.055, fab("stripe"), n=14))
    P.add(tube("Finder", [(c[0] - 0.05, 0, c[2] + 0.08), (c[0] + 0.15, 0, c[2] + 0.08 + 0.12)], 0.015, br, n=6))
