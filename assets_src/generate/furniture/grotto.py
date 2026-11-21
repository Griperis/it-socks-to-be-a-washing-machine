"""The Lost Sock Grotto's openable Hiding spots (house/38, Q1058): an old mine crate and a barrel,
each opening with a click like the kitchen cupboards. The Grotto's rock, timber, props and the
shrine are tools/blender/make_grotto.py's (a house part); these two are furniture pieces so that
the game places them from placements[] with their Openables, Sock colliders and resting tops.

Blender axes: z up, front -y, each piece built around x = 0, y = 0 (build.py centres it).
"""

import math

import bmesh

import kit
from fkit import M, PAL, box, cyl, lathe, piece  # noqa: F401

ROOMS = ["Grotto"]

PAL.update({
    "crate_wood": (0.42, 0.30, 0.18),
    "crate_dark": (0.28, 0.19, 0.11),
    "barrel_wood": (0.38, 0.25, 0.15),
    "hoop_iron": (0.16, 0.16, 0.17),
})


@piece("mine_crate", ["Grotto"], spot="Mine crate",
       note="An old plank crate; its Lid hinges at the back edge (Q1058).")
def mine_crate(P):
    W, D, H = 0.66, 0.46, 0.44
    wood = M("crate_wood", 0.85)
    dark = M("crate_dark", 0.85)
    iron = M("hoop_iron", 0.45, 0.6)
    t = 0.025
    P.add(box("Floor", (W, D, t), (0, 0, 0.0), dark, r=0.004, seg=1))
    # Plank walls: three boards a side with gaps the light shows through.
    for k in range(3):
        z = 0.01 + k * (H - 0.02) / 3
        h = (H - 0.02) / 3 - 0.012
        P.add(box("Plank", (W, t, h), (0, -D / 2 + t / 2, z), wood if k % 2 else dark, r=0.004, seg=1))
        P.add(box("Plank", (W, t, h), (0, D / 2 - t / 2, z), dark if k % 2 else wood, r=0.004, seg=1))
        for s in (-1, 1):
            P.add(box("Plank", (t, D - 2 * t, h), (s * (W / 2 - t / 2), 0, z), wood, r=0.004, seg=1))
    # Corner posts and a stencilled band (dark strip).
    for x in (-W / 2 + 0.03, W / 2 - 0.03):
        for y in (-D / 2 + 0.03, D / 2 - 0.03):
            P.add(box("Post", (0.05, 0.05, H), (x, y, 0), dark, r=0.004, seg=1))
    for s in (-1, 1):
        P.add(box("Band", (W + 0.008, 0.012, 0.04), (0, s * (D / 2 + 0.002), H * 0.5), iron, r=0.002, seg=1))
    # The Socks meet the crate as its floor and four walls (few shapes: the Grotto's budget).
    P.sock_skip("Floor", "Plank", "Post", "Band", "LidBatten", "Hasp")
    P.collide((-W / 2, -D / 2, 0), (W / 2, D / 2, t), sock=True)
    for a, b in (((-W / 2, -D / 2, 0), (W / 2, -D / 2 + t, H)), ((-W / 2, D / 2 - t, 0), (W / 2, D / 2, H)),
                 ((-W / 2, -D / 2, 0), (-W / 2 + t, D / 2, H)), ((W / 2 - t, -D / 2, 0), (W / 2, D / 2, H))):
        P.collide(a, b, sock=True)
    P.container("Lid", ["Lid"], (-W / 2 + t, -D / 2 + t, t), (W / 2 - t, D / 2 - t, H), "cupboard")
    lid = [box("Lid", (W + 0.02, D + 0.02, 0.03), (0, 0, H), wood, r=0.006, seg=1)]
    for x in (-W / 2 + 0.12, 0.0, W / 2 - 0.12):
        lid.append(box("LidBatten", (0.06, D - 0.04, 0.015), (x, 0, H + 0.03), dark, r=0.003, seg=1))
    lid.append(box("Hasp", (0.05, 0.015, 0.07), (0, -D / 2 - 0.015, H - 0.035), iron, r=0.004, seg=1))
    P.hinge("Lid", lid, (0, D / 2 + 0.01, H), (-1, 0, 0), 105)


@piece("mine_barrel", ["Grotto"], spot="Mine barrel",
       note="An iron-hooped barrel; its round Lid hinges at the back (Q1058).")
def mine_barrel(P):
    R, H = 0.27, 0.72
    wood = M("barrel_wood", 0.85)
    iron = M("hoop_iron", 0.45, 0.6)
    t = 0.025
    # The staves: a bulged lathe, open at the top (Socks lie inside on its floor).
    prof = [(R * 0.86, 0.0), (R * 0.97, H * 0.25), (R, H * 0.5), (R * 0.97, H * 0.75), (R * 0.86, H)]
    outer = [(r, z) for r, z in prof]
    inner = [(r - t, z) for r, z in reversed(prof)]
    shell = [(0.0, 0.0)] + outer + inner[:-1] + [(R * 0.86 - t, t), (0.0, t)]
    P.add(lathe("Staves", shell, wood, n=18, smooth=False))
    for zf in (0.12, 0.38, 0.62, 0.88):
        r = (R * 0.86 + (R - R * 0.86) * math.sin(math.pi * zf)) + 0.006
        P.add(lathe("Hoop", [(r - 0.01, H * zf - 0.022), (r, H * zf - 0.022), (r, H * zf + 0.022),
                             (r - 0.01, H * zf + 0.022)], iron, n=18, smooth=False))
    # The Socks meet the staves as four walls and the floor (few shapes: the Grotto's budget).
    P.sock_skip("Staves", "Hoop", "LidBatten")
    a = R * 0.62
    P.collide((-R, -R, 0), (R, R, t), sock=True)
    for lo, hi in (((-R, -R, 0), (R, -a, H)), ((-R, a, 0), (R, R, H)), ((-R, -R, 0), (-a, R, H)), ((a, -R, 0), (R, R, H))):
        P.collide(lo, hi, sock=True)
    P.container("Lid", ["Lid"], (-a, -a, t), (a, a, H), "cupboard")
    lid = [cyl("Lid", R * 0.88, 0.03, (0, 0, H), wood, n=18, bev=0.008)]
    lid.append(box("LidBatten", (0.05, R * 1.5, 0.014), (0, 0, H + 0.03), M("crate_dark", 0.85), r=0.003, seg=1))
    P.hinge("Lid", lid, (0, R * 0.88, H), (-1, 0, 0), 110)
