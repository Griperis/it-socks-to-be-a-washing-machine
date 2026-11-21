"""The Cabinets' printed art (pipeline/04): the drawer fronts' decals and the Space Cabinet's side
panels, painted with numpy in metres and kept from the first kit (flat/02). make_cabinets.py maps
each onto its front (`DECAL_W` x `DECAL_H`, the front less `DECAL_INSET` all round) or panel.

Images come out power-of-two (the asset contract): a Canvas paints `w` x `h` metres into `px`
pixels, so a pixel need not be square.
"""

import math
import random

import bpy
import numpy as np


def hexc(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


# The drawer front these are painted for (metres): 1.44 x 0.28, the art 16 mm in from its edge.
FRONT_W, FRONT_H = 1.44, 0.28
HALF_D = 0.25
SEG_H = 0.30
DECAL_INSET = 0.016
DECAL_W = FRONT_W - 2 * DECAL_INSET
DECAL_H = FRONT_H - 2 * DECAL_INSET
# The pantry's gingham sits in the shaker frame's panel, this far in from the front's edge.
PANEL_INSET = 0.05
PANEL_W = FRONT_W - 2 * PANEL_INSET
PANEL_H = FRONT_H - 2 * PANEL_INSET
FRONT_PX = (1024, 256)

class Canvas:
    def __init__(self, w, h, px=FRONT_PX, ss=2):
        self.w, self.h = w, h
        self.W, self.H = px
        self.ss = ss
        nx, ny = self.W * ss, self.H * ss
        xs = (np.arange(nx) + 0.5) / nx * w
        ys = (np.arange(ny) + 0.5) / ny * h
        self.X, self.Y = np.meshgrid(xs, ys)
        self.img = np.zeros((ny, nx, 3))

    def put(self, mask, col):
        self.img[mask] = hexc(col) if isinstance(col, str) else col

    def fill(self, col):
        self.put(np.ones(self.X.shape, bool), col)

    def rect(self, x0, y0, x1, y1, col, r=0.0):
        cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        hx, hy = (x1 - x0) / 2 - r, (y1 - y0) / 2 - r
        dx = np.maximum(np.abs(self.X - cx) - hx, 0)
        dy = np.maximum(np.abs(self.Y - cy) - hy, 0)
        self.put(dx * dx + dy * dy <= r * r + 1e-12, col)

    def circle(self, cx, cy, r, col):
        self.put((self.X - cx) ** 2 + (self.Y - cy) ** 2 <= r * r, col)

    def poly_mask(self, pts):
        inside = np.zeros(self.X.shape, bool)
        n = len(pts)
        for i in range(n):
            x0, y0 = pts[i]
            x1, y1 = pts[(i + 1) % n]
            if y0 == y1:
                continue
            cond = (self.Y >= min(y0, y1)) & (self.Y < max(y0, y1))
            xint = x0 + (self.Y - y0) * (x1 - x0) / (y1 - y0)
            inside ^= cond & (self.X < xint)
        return inside

    def poly(self, pts, col):
        self.put(self.poly_mask(pts), col)

    def star(self, cx, cy, ro, ri, col, n=5, rot=math.pi / 2, outline=None, ow=0.0):
        def pts(a, b):
            return [(cx + (a if k % 2 == 0 else b) * math.cos(rot + k * math.pi / n),
                     cy + (a if k % 2 == 0 else b) * math.sin(rot + k * math.pi / n))
                    for k in range(2 * n)]
        if outline:
            self.poly(pts(ro + ow * 1.6, ri + ow), outline)
        self.poly(pts(ro, ri), col)

    def to_image(self, name):
        s = self.ss
        img = self.img.reshape(self.H, s, self.W, s, 3).mean(axis=(1, 3))
        rgba = np.concatenate([img, np.ones((self.H, self.W, 1))], axis=2)
        im = bpy.data.images.new(name, width=self.W, height=self.H, alpha=False)
        im.pixels.foreach_set(rgba.astype(np.float32).ravel())
        im.pack()
        im.filepath_raw = ""
        return im


def decal_patterns():
    """Colour blocks: coral with dots, mustard, teal with stripes, split by cream grooves."""
    c = Canvas(DECAL_W, DECAL_H)
    c.fill("#f6efe0")
    w, h = DECAL_W, DECAL_H
    g = 0.012
    edges = [0, w * 0.34, w * 0.66, w]
    cols = ["#ef7b63", "#f2c14e", "#3fa7a3"]
    for i in range(3):
        c.rect(edges[i] + (g if i else 0), 0, edges[i + 1] - (g if i < 2 else 0), h, cols[i], r=0.012)
    for ix in range(9):             # cream polka dots on the coral block
        for iy in range(4):
            x = 0.035 + ix * 0.054 + (0.027 if iy % 2 else 0)
            y = 0.035 + iy * 0.058
            if x < edges[1] - 0.03:
                c.circle(x, y, 0.012, "#fbe9dc")
    x0 = edges[2] + g
    for k in range(6):              # cream stripes on the teal block
        y = 0.022 + k * 0.042
        c.rect(x0, y, w, y + 0.014, "#e9f4f1")
    return c


def decal_sport():
    """Locker door: two banks of vent slits and a red and white varsity stripe."""
    c = Canvas(DECAL_W, DECAL_H)
    c.fill("#4f7fae")
    w, h = DECAL_W, DECAL_H
    for x0 in (0.08, w - 0.08 - 0.42):
        for k in range(5):
            y = h - 0.045 - k * 0.036
            c.rect(x0, y - 0.004, x0 + 0.42, y + 0.016, "#6f9cc7", r=0.008)
            c.rect(x0, y, x0 + 0.42, y + 0.016, "#1f2e44", r=0.008)
    c.rect(0, 0.022, w, 0.040, "#f4f4f2")
    c.rect(0, 0.040, w, 0.056, "#e04545")
    c.rect(0, 0.056, w, 0.066, "#f4f4f2")
    return c


def decal_winter():
    """A knitted front: V stitches in cream and red with a fair-isle band of diamonds."""
    w, h = DECAL_W, DECAL_H
    c = Canvas(w, h)
    cw, ch = 0.024, 0.021
    ncol = int(math.ceil(w / cw))
    nrow = int(math.ceil(h / ch))
    cream, red, green = np.array(hexc("#f3ead8")), np.array(hexc("#c23a3a")), np.array(hexc("#2f6b4f"))
    pat = np.zeros((nrow, ncol, 3))
    mid = nrow // 2
    for j in range(nrow):
        for i in range(ncol):
            col = cream
            d = abs(j - mid)
            if j in (0, nrow - 1):
                col = red
            elif j in (1, nrow - 2):
                col = green if i % 2 == 0 else cream
            elif d <= 3:
                k = (i % 8) - 4    # diamond motif, 8 stitches wide
                if abs(k) + d == 3 or (d == 0 and k == 0):
                    col = red
            pat[j, i] = col
    ci = np.clip((c.X / cw).astype(int), 0, ncol - 1)
    cj = np.clip((c.Y / ch).astype(int), 0, nrow - 1)
    u = c.X / cw - ci - 0.5        # -0.5..0.5 across the stitch
    v = c.Y / ch - cj - 0.5
    base = pat[cj, ci]
    # Each stitch is a V of two slanted leaves; distance from the leaf centre lines.
    side = np.sign(u)
    lu = np.abs(u) - 0.24
    ang = math.radians(28)
    a = lu * math.cos(ang) + v * math.sin(ang) * 1.0
    b = -lu * math.sin(ang) + v * math.cos(ang)
    leaf = (a / 0.21) ** 2 + (b / 0.58) ** 2
    shade = np.clip(1.05 - 0.45 * leaf, 0.0, 1.0)
    shade = np.where(leaf < 1.0, 0.72 + 0.33 * shade, 0.45)
    shade = shade * (1.0 + 0.06 * side)
    c.img = np.clip(base * shade[..., None], 0, 1)
    return c


def paw(c, x, y, s, col, rot=0.0):
    ca, sa = math.cos(rot), math.sin(rot)
    def at(dx, dy):
        return x + (dx * ca - dy * sa) * s, y + (dx * sa + dy * ca) * s
    px, py = at(0, -0.15)
    c.put(((c.X - px) / (0.42 * s)) ** 2 + ((c.Y - py) / (0.34 * s)) ** 2 <= 1, col)
    for dx, dy in ((-0.48, 0.28), (-0.17, 0.52), (0.17, 0.52), (0.48, 0.28)):
        tx, ty = at(dx, dy)
        c.circle(tx, ty, 0.16 * s, col)


def decal_animals():
    """Kids' dresser: a soft peach panel framed in cream with scattered paw prints."""
    w, h = DECAL_W, DECAL_H
    c = Canvas(w, h)
    c.fill("#fbe8a6")
    c.rect(0.02, 0.02, w - 0.02, h - 0.02, "#ffd2b8", r=0.05)
    rnd = random.Random(4)
    for k in range(9):
        x = 0.10 + k * (w - 0.2) / 8 + rnd.uniform(-0.02, 0.02)
        y = h * (0.32 if k % 2 else 0.68) + rnd.uniform(-0.02, 0.02)
        if abs(x - w / 2 + 0.33) < 0.08 or abs(x - w / 2 - 0.33) < 0.08:
            y = h * (0.82 if k % 2 == 0 else 0.2)
        paw(c, x, y, 0.07, "#f2b69a", rnd.uniform(-0.6, 0.6))
    return c


def decal_superhero():
    """Comic panels: bold black gutters, halftone dots, speed lines and a blank burst."""
    w, h = DECAL_W, DECAL_H
    c = Canvas(w, h)
    c.fill("#151515")
    g = 0.014
    a0, a1 = w * 0.30, w * 0.35     # slanted gutter 1 (bottom x, top x)
    b0, b1 = w * 0.70, w * 0.64     # slanted gutter 2
    p1 = [(g, g), (a0 - g, g), (a1 - g, h - g), (g, h - g)]
    p2 = [(a0 + g, g), (b0 - g, g), (b1 - g, h - g), (a1 + g, h - g)]
    p3 = [(b0 + g, g), (w - g, g), (w - g, h - g), (b1 + g, h - g)]
    # Panel 1: yellow with red halftone dots growing towards the bottom.
    m1 = c.poly_mask(p1)
    c.put(m1, "#ffd23f")
    cell = 0.02
    u = (c.X / cell) % 1 - 0.5
    v = (c.Y / cell) % 1 - 0.5
    rad = 0.12 + 0.30 * (1 - c.Y / h)
    c.put(m1 & (u * u + v * v < rad * rad), "#ef5a3c")
    # Panel 2: blue with white speed lines and a blank yellow burst behind the handle.
    m2 = c.poly_mask(p2)
    c.put(m2, "#2b62c7")
    cx, cy = w / 2, h / 2
    ang = np.arctan2(c.Y - cy, (c.X - cx) * 0.6)
    c.put(m2 & ((np.floor(ang / (math.pi / 14)) % 2) == 0), "#4a80e0")
    c.star(cx, cy, 0.12, 0.075, "#fff4c2", n=12, rot=0.13, outline="#151515", ow=0.009)
    c.star(cx, cy, 0.085, 0.055, "#ffd23f", n=12, rot=0.4)
    # Panel 3: red with a pale halftone.
    m3 = c.poly_mask(p3)
    c.put(m3, "#d8343a")
    rad3 = 0.10 + 0.28 * (c.Y / h)
    c.put(m3 & (u * u + v * v < rad3 * rad3), "#f27a6b")
    return c


def decal_food():
    """Pantry gingham for the inset panel of a pantry drawer."""
    w, h = PANEL_W, PANEL_H
    c = Canvas(w, h, px=(1024, 128))
    c.fill("#fbf6ee")
    sq = 0.028
    a = ((c.X / sq).astype(int) % 2) == 0
    b = ((c.Y / sq).astype(int) % 2) == 0
    c.put(a | b, "#f0a6a0")
    c.put(a & b, "#d9524a")
    return c


def space_scatter(c, seed, planets=True):
    w, h = c.w, c.h
    rnd = random.Random(seed)
    for _ in range(int(w * h * 260)):
        c.circle(rnd.uniform(0, w), rnd.uniform(0, h), rnd.uniform(0.002, 0.004), "#aab4dd")
    spots = []
    tries = 0
    while len(spots) < int(w * h * 70) and tries < 2000:
        tries += 1
        x, y = rnd.uniform(0.03, w - 0.03), rnd.uniform(0.03, h - 0.03)
        if any((x - a) ** 2 + (y - b) ** 2 < 0.09 ** 2 for a, b in spots):
            continue
        if planets and (abs(x - w / 2 - 0.33) < 0.09 or abs(x - w / 2 + 0.33) < 0.09):
            continue        # keep the knobs clear
        spots.append((x, y))
        r = rnd.uniform(0.016, 0.03)
        c.star(x, y, r, r * 0.45, rnd.choice(["#ffe27a", "#fff6d8", "#ffd04a"]),
               rot=rnd.uniform(0, 1.2))
    if planets:
        x, y = w * 0.5, h * 0.52            # ringed planet in the middle
        ring = ((((c.X - x) / 0.10) ** 2 + ((c.Y - y) / 0.026) ** 2) <= 1) & \
               ((((c.X - x) / 0.082) ** 2 + ((c.Y - y) / 0.014) ** 2) > 1)
        ball = (c.X - x) ** 2 + (c.Y - y) ** 2 <= 0.055 ** 2
        c.put(ring, "#c8ccd6")                  # back half shows above the planet
        c.put(ball, "#f0a050")
        c.put(ball & (c.Y < y - 0.02), "#e08a3a")
        c.put(ring & (c.Y < y), "#c8ccd6")      # front half crosses it
        mx, my = w * 0.08, h * 0.65         # crescent moon
        c.circle(mx, my, 0.045, "#ffe27a")
        c.circle(mx + 0.02, my + 0.012, 0.04, "#1e2b55")


def decal_space():
    c = Canvas(DECAL_W, DECAL_H)
    c.fill("#1e2b55")
    space_scatter(c, 7)
    return c


def side_space():
    c = Canvas(2 * HALF_D - 0.02, SEG_H, px=(256, 256))
    c.fill("#1e2b55")
    space_scatter(c, 11, planets=False)
    return c


def sock_uv(c, x, y, s, rot=0.0, flip=False):
    """Canvas coordinates in a Sock's own frame (`s` metres tall, cuff up, toe to +u)."""
    ca, sa = math.cos(rot), math.sin(rot)
    u = ((c.X - x) * ca + (c.Y - y) * sa) / s
    v = (-(c.X - x) * sa + (c.Y - y) * ca) / s
    return (-u if flip else u), v


def sock_mask(u, v):
    """A single Sock's silhouette: the leg, the rounded heel and the foot."""
    leg = (np.abs(u + 0.1) <= 0.19) & (v >= -0.12) & (v <= 0.5)
    foot = (np.maximum(np.abs(u - 0.08) - 0.2, 0) ** 2 + np.maximum(np.abs(v + 0.3) - 0.0, 0) ** 2
            <= 0.19 ** 2)
    heel = (u + 0.1) ** 2 + (v + 0.12) ** 2 <= 0.19 ** 2
    return leg | foot | heel


def decal_lost():
    """Lost Socks (house/38): odd Socks drifting over crystal teal, with crystal glints."""
    c = Canvas(DECAL_W, DECAL_H)
    c.fill("#2fa3a8")
    w, h = DECAL_W, DECAL_H
    rnd = random.Random(38)
    spots = []
    tries = 0
    while len(spots) < 9 and tries < 4000:
        tries += 1
        x, y = rnd.uniform(0.07, w - 0.07), rnd.uniform(0.1, h - 0.1)
        if any(abs(x - a) < 0.15 for a, b in spots):
            continue
        if abs(x - w / 2 - 0.33) < 0.11 or abs(x - w / 2 + 0.33) < 0.11:
            continue        # keep the knobs clear
        spots.append((x, y))
        u, v = sock_uv(c, x, y, rnd.uniform(0.15, 0.18), rnd.uniform(-0.5, 0.5), rnd.random() < 0.5)
        body, cuff, toe = rnd.choice([("#7fd3d2", "#c4f1ef", "#4ab5b8"), ("#5cc3c4", "#a9e8e6", "#3a9da1"),
                                      ("#9be7e3", "#e9fbfa", "#5cc3c4")])
        m = sock_mask(u, v)
        c.put(m, body)
        c.put(m & (v > 0.36), cuff)
        c.put(m & ((u > 0.3) | ((u + 0.1) ** 2 + (v + 0.12) ** 2 <= 0.11 ** 2)), toe)
    for _ in range(40):
        x, y = rnd.uniform(0.02, w - 0.02), rnd.uniform(0.02, h - 0.02)
        if any((x - a) ** 2 + (y - b) ** 2 < 0.08 ** 2 for a, b in spots):
            continue
        r = rnd.uniform(0.012, 0.022)
        c.star(x, y, r, r * 0.28, rnd.choice(["#e9fbfa", "#c4f1ef"]), n=4)
    return c


DECALS = {"patterns": decal_patterns, "sport": decal_sport, "winter": decal_winter,
          "animals": decal_animals, "superhero": decal_superhero, "food": decal_food,
          "space": decal_space, "lost": decal_lost}
SIDE_DECALS = {"space": side_space}


# --- The eight new Collections (progression/51) ------------------------------------------------

def _seg_dist(c, x0, y0, x1, y1):
    dx, dy = x1 - x0, y1 - y0
    t = np.clip(((c.X - x0) * dx + (c.Y - y0) * dy) / max(dx * dx + dy * dy, 1e-12), 0, 1)
    return np.hypot(c.X - (x0 + t * dx), c.Y - (y0 + t * dy))


def line(c, pts, wdt, col):
    """A stroke of width `wdt` through `pts` (round caps)."""
    m = np.zeros(c.X.shape, bool)
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        m |= _seg_dist(c, x0, y0, x1, y1) <= wdt / 2
    c.put(m, col)


def ellipse_mask(c, cx, cy, rx, ry, rot=0.0):
    ca, sa = math.cos(rot), math.sin(rot)
    u = (c.X - cx) * ca + (c.Y - cy) * sa
    v = -(c.X - cx) * sa + (c.Y - cy) * ca
    return (u / rx) ** 2 + (v / ry) ** 2 <= 1


def leaf(c, x, y, ln, rot, col, rib):
    """A pointed leaf `ln` long from its stalk at (x, y) along `rot`, with a midrib."""
    ca, sa = math.cos(rot), math.sin(rot)
    u = ((c.X - x) * ca + (c.Y - y) * sa) / ln
    v = (-(c.X - x) * sa + (c.Y - y) * ca) / ln
    m = (u >= 0) & (u <= 1) & (np.abs(v) <= 0.32 * np.sin(np.pi * np.clip(u, 0, 1)) ** 0.8)
    c.put(m, col)
    c.put(m & (np.abs(v) < 0.025) & (u < 0.9), rib)


def knob_clear(x, w, half=0.09):
    """True when x keeps clear of the knobs at the front's +-0.33."""
    return abs(x - w / 2 - 0.33) > half and abs(x - w / 2 + 0.33) > half


def decal_nature():
    """A forest canopy: leaves in four greens over deep green, a few small white flowers."""
    w, h = DECAL_W, DECAL_H
    c = Canvas(w, h)
    c.fill("#2d6a36")
    rnd = random.Random(51)
    for k in range(70):
        x, y = rnd.uniform(-0.03, w + 0.03), rnd.uniform(-0.03, h + 0.03)
        col, rib = rnd.choice([("#3f9142", "#2d6a36"), ("#5aa84a", "#3f9142"), ("#7cc25a", "#5aa84a"),
                               ("#4b8f3a", "#2f6b2f")])
        leaf(c, x, y, rnd.uniform(0.06, 0.095), rnd.uniform(0, 2 * math.pi), col, rib)
    for k in range(12):
        x, y = rnd.uniform(0.03, w - 0.03), rnd.uniform(0.03, h - 0.03)
        if not knob_clear(x, w):
            continue
        for a in range(5):
            ang = a * 2 * math.pi / 5
            c.circle(x + 0.009 * math.cos(ang), y + 0.009 * math.sin(ang), 0.0075, "#fbf6e8")
        c.circle(x, y, 0.005, "#f2c14e")
    return c


def cherry_pair(c, x, y, s):
    line(c, [(x - 0.35 * s, y), (x, y + 0.9 * s), (x + 0.4 * s, y + 0.05 * s)], 0.05 * s, "#4b7a2a")
    leaf(c, x, y + 0.9 * s, 0.45 * s, 0.4, "#5e9c3a", "#4b7a2a")
    for dx, dy in ((-0.35, 0.0), (0.4, 0.05)):
        c.circle(x + dx * s, y + dy * s - 0.22 * s, 0.25 * s, "#c8203e")
        c.circle(x + dx * s - 0.08 * s, y + dy * s - 0.15 * s, 0.06 * s, "#f6a0ae")


def citrus(c, x, y, r, peel, flesh):
    c.circle(x, y, r, peel)
    c.circle(x, y, r * 0.86, "#fff6dc")
    c.circle(x, y, r * 0.8, flesh)
    ang = np.arctan2(c.Y - y, c.X - x)
    near = np.hypot(c.X - x, c.Y - y) <= r * 0.8
    c.put(near & (np.abs(((ang / (2 * math.pi / 8)) % 1) - 0.5) > 0.44), "#fff6dc")
    c.circle(x, y, r * 0.1, "#fff6dc")


def decal_fruit():
    """A fruit stall: a red and cream awning band over cherries, citrus slices and strawberries."""
    w, h = DECAL_W, DECAL_H
    c = Canvas(w, h)
    c.fill("#fbefd9")
    sw = w / 24                     # the awning's scalloped stripes along the top
    for k in range(24):
        col = "#e0405a" if k % 2 == 0 else "#fbefd9"
        c.rect(k * sw, h - 0.05, (k + 1) * sw, h, col)
        c.circle((k + 0.5) * sw, h - 0.05, sw / 2, col)
    xs = [0.09, 0.27, 0.48, 0.70, 0.91, 1.13, 1.32]
    for i, x in enumerate(xs):
        y = 0.095 if i % 2 else 0.11
        kind = i % 3
        if kind == 0:
            cherry_pair(c, x, y - 0.01, 0.07)
        elif kind == 1:
            lemon = i % 4 == 1
            citrus(c, x, y, 0.05, "#f2b600" if lemon else "#f08a24", "#ffe066" if lemon else "#ffad42")
        else:                       # a strawberry
            c.poly([(x - 0.045, y + 0.035), (x + 0.045, y + 0.035), (x, y - 0.06)], "#e0405a")
            c.circle(x - 0.02, y + 0.03, 0.026, "#e0405a")
            c.circle(x + 0.02, y + 0.03, 0.026, "#e0405a")
            for dx, dy in ((-0.02, 0.025), (0.015, 0.03), (0.0, 0.0), (-0.012, -0.022), (0.022, -0.005)):
                c.circle(x + dx, y + dy, 0.004, "#ffe9a8")
            c.star(x, y + 0.058, 0.03, 0.012, "#4fa03a", n=5, rot=-math.pi / 2)
    return c


def decal_vegetables():
    """A veg crate: three wooden planks, a stencilled carrot, pea pod and tomato on each side."""
    w, h = DECAL_W, DECAL_H
    c = Canvas(w, h)
    c.fill("#5a3d22")
    ph = (h - 0.02) / 3
    rnd = random.Random(52)
    for k in range(3):
        y0 = 0.005 + k * (ph + 0.005)
        c.rect(0, y0, w, y0 + ph, ["#d2a66c", "#c99a5e", "#d8ae76"][k], r=0.004)
        for g in range(5):           # grain
            gy = y0 + rnd.uniform(0.01, ph - 0.01)
            x0 = rnd.uniform(0, w * 0.6)
            c.put((np.abs(c.Y - gy - 0.004 * np.sin(c.X * 30 + g)) < 0.0012) & (c.X > x0)
                  & (c.X < x0 + rnd.uniform(0.2, 0.6)), "#b8874e")
    for sx in (-1, 1):
        for i, kind in enumerate(("carrot", "pod", "tomato")):
            x = w / 2 + sx * (0.2 + i * 0.17)
            y = h / 2
            if kind == "carrot":
                c.poly([(x - 0.06, y + 0.02), (x - 0.06, y - 0.02), (x + 0.06, y)], "#f08a24")
                c.circle(x - 0.06, y, 0.02, "#f08a24")
                for a in (-0.5, 0.0, 0.5):
                    leaf(c, x - 0.075, y, 0.05, math.pi + a, "#4fa03a", "#3a7f2a")
            elif kind == "pod":
                c.put(ellipse_mask(c, x, y, 0.065, 0.026, 0.2), "#6fb43f")
                for k in range(-2, 3):
                    c.circle(x + k * 0.022 * math.cos(0.2), y + k * 0.022 * math.sin(0.2), 0.011, "#a3d65c")
            else:
                c.circle(x, y, 0.045, "#e8473f")
                c.circle(x - 0.015, y + 0.015, 0.01, "#f39a8f")
                c.star(x, y + 0.04, 0.026, 0.01, "#3a7f2a", n=5, rot=math.pi / 2)
    return c


def decal_drinks():
    """A soda: bubbles rising through blue under a white foam wave."""
    w, h = DECAL_W, DECAL_H
    c = Canvas(w, h)
    c.fill("#2ea6d9")
    c.put(c.Y < 0.06 + 0.012 * np.sin(c.X * 9), "#2390c2")
    rnd = random.Random(53)
    spots = []
    for _ in range(600):
        x, y = rnd.uniform(0.02, w - 0.02), rnd.uniform(0.02, h - 0.06)
        r = rnd.uniform(0.006, 0.02) * (0.6 + y / h)
        if any((x - a) ** 2 + (y - b) ** 2 < (r + rb + 0.006) ** 2 for a, b, rb in spots):
            continue
        if not knob_clear(x, w, 0.07):
            continue
        spots.append((x, y, r))
        c.circle(x, y, r, "#e9f8ff")
        c.circle(x, y, r * 0.72, "#7fd0f0")
        c.circle(x - r * 0.35, y + r * 0.35, r * 0.25, "#ffffff")
        if len(spots) > 70:
            break
    c.put(c.Y > h - 0.05 + 0.012 * np.sin(c.X * 14), "#f4fbff")
    return c


def decal_math():
    """A chalkboard in the frame's panel: a faint grid, chalk signs, a parabola and shapes."""
    w, h = PANEL_W, PANEL_H
    c = Canvas(w, h, px=(1024, 128))
    c.fill("#2a4d43")
    grid = (np.abs((c.X / 0.03) % 1 - 0.5) > 0.47) | (np.abs((c.Y / 0.03) % 1 - 0.5) > 0.47)
    c.put(grid, "#355a4f")
    chalk, wd = "#eef0e6", 0.006

    def stroke(*pts, col=chalk):
        line(c, pts, wd, col)

    def plus(x, y, s):
        stroke((x - s, y), (x + s, y))
        stroke((x, y - s), (x, y + s))

    def times(x, y, s):
        stroke((x - s, y - s), (x + s, y + s))
        stroke((x - s, y + s), (x + s, y - s))

    def divide(x, y, s):
        stroke((x - s, y), (x + s, y))
        c.circle(x, y + s * 0.7, wd * 0.8, chalk)
        c.circle(x, y - s * 0.7, wd * 0.8, chalk)

    def equals(x, y, s):
        stroke((x - s, y + s * 0.4), (x + s, y + s * 0.4))
        stroke((x - s, y - s * 0.4), (x + s, y - s * 0.4))
    plus(0.08, 0.12, 0.025)
    stroke((0.145, 0.06), (0.195, 0.06))
    times(0.30, 0.12, 0.02)
    divide(1.04, 0.11, 0.025)
    equals(1.26, 0.06, 0.025)
    plus(1.20, 0.13, 0.02)
    ax, ay = 0.40, 0.03              # a parabola on axes (left), a triangle and a circle (right)
    line(c, [(ax, ay), (ax + 0.17, ay)], 0.004, chalk)
    line(c, [(ax + 0.085, ay - 0.005), (ax + 0.085, ay + 0.14)], 0.004, chalk)
    pts = [(ax + 0.085 + float(t), ay + 0.012 + 80 * float(t) * float(t)) for t in np.linspace(-0.04, 0.04, 17)]
    line(c, pts, wd, "#f6d55c")
    stroke((0.82, 0.03), (0.94, 0.03), (0.86, 0.15), (0.82, 0.03))
    c.put(np.abs(np.hypot(c.X - 1.13, c.Y - 0.07) - 0.035) < wd / 2, "#f39a8f")
    return c


def decal_tech():
    """A circuit board: pale traces between chips and pads on slate, a few cyan LEDs."""
    w, h = DECAL_W, DECAL_H
    c = Canvas(w, h)
    c.fill("#3f4c5a")
    rnd = random.Random(54)
    for _ in range(26):              # right-angled traces
        x, y = rnd.uniform(0, w), rnd.choice([0.03, 0.06, 0.09, 0.12, 0.15, 0.18, 0.21])
        pts = [(x, y)]
        for _ in range(3):
            if rnd.random() < 0.5:
                x += rnd.uniform(-0.2, 0.2)
            else:
                d = rnd.uniform(-0.05, 0.05)
                x += d
                y = min(max(y + abs(d) * rnd.choice((-1, 1)), 0.01), h - 0.01)
            pts.append((x, y))
        line(c, pts, 0.005, "#8fa6ba")
        c.circle(pts[0][0], pts[0][1], 0.008, "#b9c8d6")
        c.circle(pts[-1][0], pts[-1][1], 0.008, "#b9c8d6")
    for x, y in ((0.16, 0.07), (0.42, 0.15), (1.0, 0.08), (1.25, 0.14)):    # chips, clear of the pull
        for k in range(6):
            px = x - 0.05 + k * 0.02
            c.rect(px - 0.003, y - 0.045, px + 0.003, y + 0.045, "#c9d3dc")
        c.rect(x - 0.06, y - 0.035, x + 0.06, y + 0.035, "#1c2128", r=0.005)
        c.circle(x - 0.045, y + 0.022, 0.004, "#3f4c5a")
    for _ in range(9):
        x, y = rnd.uniform(0.03, w - 0.03), rnd.uniform(0.03, h - 0.03)
        c.circle(x, y, 0.01, "#1c6f78")
        c.circle(x, y, 0.006, "#38e0d0")
    return c


def decal_transport():
    """A taxi: yellow with a black and white checker band and pinstripes."""
    w, h = DECAL_W, DECAL_H
    c = Canvas(w, h)
    c.fill("#f2c230")
    sq = 0.028
    y0 = h / 2 - sq
    band = (c.Y >= y0) & (c.Y < y0 + 2 * sq)
    chk = (((c.X / sq).astype(int) + ((c.Y - y0) / sq).astype(int)) % 2) == 0
    c.put(band, "#fbfbf7")
    c.put(band & chk, "#1e1e1e")
    for yy in (y0 - 0.02, y0 + 2 * sq + 0.012):
        c.rect(0, yy, w, yy + 0.008, "#1e1e1e")
    return c


def decal_machinery():
    """Steel tread plate with rivets round the edge and a hazard stripe along the bottom."""
    w, h = DECAL_W, DECAL_H
    c = Canvas(w, h)
    c.fill("#868b94")
    cell = 0.04
    u = (c.X / cell) % 1
    v = (c.Y / (cell * 0.5)) % 1
    row = (c.Y / (cell * 0.5)).astype(int) % 2
    uu = np.where(row == 1, (u + 0.5) % 1, u)
    sgn = np.where(((c.X / cell).astype(int) + row) % 2 == 0, 1, -1)
    a = (uu - 0.5) * math.cos(0.7) + (v - 0.5) * sgn * math.sin(0.7)
    b = -(uu - 0.5) * math.sin(0.7) * sgn + (v - 0.5) * math.cos(0.7)
    lens = (a / 0.36) ** 2 + (b / 0.12) ** 2 <= 1
    c.put(lens, "#a9aeb6")
    c.put(lens & (b > 0.04), "#c4c8cf")
    stripe = c.Y < 0.05
    c.put(stripe, "#1f2226")
    c.put(stripe & (((c.X + c.Y) / 0.05).astype(int) % 2 == 0), "#f2b630")
    c.rect(0, 0.05, w, 0.056, "#5d626b")
    for x in np.linspace(0.02, w - 0.02, 28):
        for y in (0.072, h - 0.018):
            c.circle(float(x), y, 0.0065, "#5d626b")
            c.circle(float(x) - 0.0015, y + 0.0015, 0.004, "#c4c8cf")
    return c


DECALS.update({"nature": decal_nature, "fruit": decal_fruit, "vegetables": decal_vegetables,
               "drinks": decal_drinks, "math": decal_math, "tech": decal_tech,
               "transport": decal_transport, "machinery": decal_machinery})
