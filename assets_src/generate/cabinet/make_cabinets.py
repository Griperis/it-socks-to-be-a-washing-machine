"""The nine Collections' Cabinets (pipeline/04), remodelled through Blender MCP: one model per
Collection's Cabinet (simple, patterns, sport, winter, animals, superhero, food, space, lost, and the
eight of progression/51: nature, fruit, vegetables, drinks, math, tech, transport, machinery), each a kit
of four parts the game stacks into as many Rows as the Cabinet shows (progression/23). Their
fronts' printed art comes from cabinet_art.py (kept from the first kit, flat/02).

Ported from the old game's tools/blender/make_cabinets.py (assets/08): it builds meshes only, so the
two collider boxes the old build added (shell-convcolonly, drawer_front-convcolonly) are gone
(Q2152); the game's Cabinet scenes hold the collision. Everything else is the old code.

Headless, from the repository (assets_src/generate/README.md):

    blender -b -P assets_src/generate/build.py -- cabinet [--only food,space] [--out <dir>] [--save]

builds each Collection's Cabinet in a fresh scene, --save writes
assets_src/blender/cabinet/cabinet_<collection>.blend, and exports assets/cabinet/<collection>.glb.
In an open Blender, with assets_src/generate/cabinet on sys.path: `import make_cabinets as mc;
mc.build("space")` rebuilds one in the open file.

The old sources in assets_src/blender/cabinet/ still hold the two collider boxes (they were made
with them); the export takes them along, and the game ignores them.

Each source holds the root `cabinet_<collection>` (an Empty at the origin) and, under it, the kit
as a one-Row Cabinet stands (Blender metres, front to -Y, origin at the bottom centre):
  base      the plinth, z 0..0.10, footprint 1.5 x 0.5; origin at the floor
  segment   a 0.30 m carcass slice that tiles upwards (sides, back, the rails between Drawers),
            open front, top and bottom hidden by its neighbours; origin at its bottom, z 0.10
  drawer    the Drawer: front 1.44 x 0.28 x 0.04 (its face at y -0.25, the handle out to
            y -0.29) and an open tray behind it, floor top 0.04 over its origin, inner x +-0.68,
            y -0.19..0.20; origin 0.01 over the segment's (z 0.11), where the game's Drawer stands
  slot_01..slot_25  Empties under `drawer`: the centre of each sock ball (about 0.09 m) lying in
            the tray, in fill order (back row first, left to right), five staggered rows of five
  top       the lid, z 0..0.05 over its origin (x +-0.78, y +-0.27); a theme's crest may rise
            above; origin at its bottom, z 0.40
  shell-convcolonly, drawer_front-convcolonly  the contract's colliders. The game keeps its
            own collision (the shell box grows with the Rows, the front box rides the Drawer) and
            takes only the four meshes and the slots (game/campaign/cabinet.gd).
The game stacks base, one segment and drawer per Row (0.30 apart) and the top on them, and slides
each drawer out along +Z (Godot) = -Y (Blender).

Materials (at most six): body, trim (handles and metal), accent, dark (tray, feet, shadows),
front (the printed front art) and side (the Space Cabinet's printed sides).
"""

import math
import os
import random

import bpy
import bmesh
from mathutils import Matrix, Vector

import appliance_family as fam
import cabinet_art as art

# --- The kit's contract (metres, Blender axes) -------------------------------------------------

HALF_W, HALF_D = 0.75, 0.25
BASE_H, SEG_H, TOP_H = 0.10, 0.30, 0.05
TOP_W, TOP_D = 1.56, 0.54
SIDE_T = 0.025                       # carcass sides: the opening is x +-0.725
BACK_T = 0.02
RAIL_H = 0.01                        # the rail under and over each Drawer
CORNER_R = 0.02                      # the carcass's vertical corners
DRAWER_Z = 0.01                      # the drawer's origin over its segment's
FRONT_W, FRONT_H, FRONT_T = 1.44, 0.28, 0.04
FACE_Y = -HALF_D                     # the front's face
BACK_Y = FACE_Y + FRONT_T            # the front's back, where the tray starts
HANDLE_Z = FRONT_H / 2               # handle centre, drawer space
HANDLE_OUT = 0.04                    # handles reach y -0.29
TRAY_WALL = 0.015
TRAY_FLOOR = 0.04                    # floor top (CabinetDrawer.TRAY_FLOOR_Y)
TRAY_X = 0.68
TRAY_Y0, TRAY_Y1 = -0.19, 0.20       # inner, front to back
TRAY_TOP = 0.24
BALL_R = 0.045
SLOT_DX = 0.26

MATS = ["body", "trim", "accent", "dark", "front", "side"]

# Colours are sRGB hex: (colour, roughness, metallic). Kept from the first kit (flat/02).
THEMES = {
    "simple": dict(drawers=6, body=("#f2eee6", 0.55, 0.0), trim=("#b9bcc0", 0.3, 0.85),
                  accent=("#e4ded3", 0.6, 0.0), dark=("#8d877d", 0.7, 0.0),
                  front="shaker", handle="bar", top="cornice", base="plinth"),
    "patterns": dict(drawers=4, body=("#f6efe0", 0.6, 0.0), trim=("#c98a52", 0.5, 0.0),
                   accent=("#c98a52", 0.55, 0.0), dark=("#6b4a2f", 0.6, 0.0),
                   front="decal", handle="knobs", top="slab", base="legs"),
    "sport": dict(drawers=3, body=("#4f7fae", 0.42, 0.35), trim=("#d9dde2", 0.25, 0.9),
                  accent=("#e04545", 0.5, 0.0), dark=("#2c3440", 0.6, 0.2),
                  front="decal", handle="latch", top="slope", base="kick"),
    "winter": dict(drawers=3, body=("#6e4630", 0.6, 0.0), trim=("#c9a272", 0.55, 0.0),
                   accent=("#fbfbf7", 0.75, 0.0), dark=("#4a2f22", 0.7, 0.0),
                   front="decal", handle="toggle", top="snow", base="buns"),
    "animals": dict(drawers=2, body=("#f7d97c", 0.6, 0.0), trim=("#9a6b47", 0.55, 0.0),
                    accent=("#f4a9a8", 0.6, 0.0), dark=("#7a5236", 0.6, 0.0),
                    front="decal", handle="paws", top="ears", base="buns"),
    "superhero": dict(drawers=2, body=("#d8343a", 0.5, 0.0), trim=("#ffd23f", 0.45, 0.0),
                      accent=("#1f4fa8", 0.5, 0.0), dark=("#151515", 0.6, 0.0),
                      front="decal", handle="bolt", top="burst", base="kick"),
    "food": dict(drawers=2, body=("#d9b07a", 0.6, 0.0), trim=("#c79a3c", 0.3, 0.85),
                 accent=("#8faa86", 0.6, 0.0), dark=("#8a6a45", 0.65, 0.0),
                 front="pantry", handle="cups", top="gallery", base="plinth"),
    "space": dict(drawers=2, body=("#1e2b55", 0.5, 0.0), trim=("#c8ccd6", 0.3, 0.85),
                  accent=("#f0a050", 0.55, 0.0), dark=("#121a36", 0.6, 0.0),
                  front="decal", handle="planets", top="space", base="plinth"),
    # Lost Socks (house/38, Q1054): crystal teal, old brass, pale crystal knobs and crest.
    "lost": dict(drawers=2, body=("#2fa3a8", 0.5, 0.0), trim=("#c9a24a", 0.35, 0.85),
                 accent=("#9be7e3", 0.2, 0.0), dark=("#163f42", 0.6, 0.0),
                 front="decal", handle="gems", top="crystals", base="plinth"),
    # The eight new Collections (progression/51). `extra` is a fifth plain colour, carried by the
    # `side` material slot where a Cabinet has no printed sides.
    "nature": dict(drawers=2, body=("#b58350", 0.6, 0.0), trim=("#5e3f26", 0.6, 0.0),
                   accent=("#3f9142", 0.7, 0.0), dark=("#4a3423", 0.7, 0.0),
                   extra=("#d8483c", 0.5, 0.0),
                   front="decal", handle="acorns", top="toadstools", base="buns"),
    "fruit": dict(drawers=2, body=("#fbefd9", 0.6, 0.0), trim=("#4f8a34", 0.55, 0.0),
                  accent=("#e0405a", 0.4, 0.0), dark=("#8a5a3a", 0.65, 0.0),
                  extra=("#f2c14e", 0.45, 0.0),
                  front="decal", handle="cherries", top="apple", base="plinth"),
    "vegetables": dict(drawers=2, body=("#c99a5e", 0.65, 0.0), trim=("#3a7f2a", 0.6, 0.0),
                       accent=("#8cc63f", 0.6, 0.0), dark=("#5a3d22", 0.75, 0.0),
                       extra=("#f08a24", 0.5, 0.0), front_r=0.01,
                       front="decal", handle="carrot", top="planter", base="legs"),
    "drinks": dict(drawers=2, body=("#2ea6d9", 0.35, 0.0), trim=("#d9dde2", 0.25, 0.9),
                   accent=("#f4fbff", 0.4, 0.0), dark=("#1d5f7d", 0.6, 0.0),
                   extra=("#e8473f", 0.4, 0.0),
                   front="decal", handle="caps", top="cup", base="kick"),
    "math": dict(drawers=2, body=("#2f5d50", 0.6, 0.0), trim=("#c9a272", 0.55, 0.0),
                 accent=("#f3efe2", 0.7, 0.0), dark=("#1f3d35", 0.7, 0.0),
                 extra=("#e85d5d", 0.5, 0.0), lid="trim",
                 front="framed", handle="pi", top="solids", base="plinth"),
    "tech": dict(drawers=2, body=("#5b6b7c", 0.4, 0.3), trim=("#2b2f36", 0.3, 0.2),
                 accent=("#38e0d0", 0.3, 0.0), dark=("#22262c", 0.6, 0.0),
                 extra=("#c9d3dc", 0.3, 0.8), front_r=0.016,
                 front="decal", handle="slot", top="antenna", base="kick"),
    "transport": dict(drawers=2, body=("#f2c230", 0.45, 0.0), trim=("#262626", 0.7, 0.0),
                      accent=("#d9dde2", 0.25, 0.9), dark=("#2c2c2c", 0.6, 0.0),
                      extra=("#e04545", 0.45, 0.0),
                      front="decal", handle="wheels", top="car", base="wheels"),
    "machinery": dict(drawers=2, body=("#8a8f98", 0.4, 0.6), trim=("#f2b630", 0.5, 0.0),
                      accent=("#c9ced6", 0.3, 0.85), dark=("#2e3137", 0.6, 0.2),
                      extra=("#d9603a", 0.6, 0.0), front_r=0.012,
                      front="decal", handle="gears", top="cogs", base="kick"),
}


def slot_positions():
    """The 25 ball centres in drawer space (Blender), back row first, left to right."""
    back = -(TRAY_Y1 - BALL_R - 0.005)     # Godot z -0.15 (CabinetDrawer.SLOT_Z_BACK)
    front = -(TRAY_Y0 + BALL_R + 0.005)    # Godot z +0.14
    out = []
    for r in range(5):
        shift = SLOT_DX / 4 * (1 if r % 2 else -1)
        gz = back + r * (front - back) / 4
        for c in range(5):
            out.append(((c - 2) * SLOT_DX + shift, -gz, TRAY_FLOOR + BALL_R))
    return out


# --- Outlines ----------------------------------------------------------------------------------

def _area(pts):
    return sum(pts[i].x * pts[(i + 1) % len(pts)].y - pts[(i + 1) % len(pts)].x * pts[i].y
               for i in range(len(pts))) / 2


def ccw(pts):
    pts = [Vector((p[0], p[1], 0)) for p in pts]
    return pts if _area(pts) > 0 else list(reversed(pts))


def offset(pts, d):
    """The outline (counter-clockwise) moved out by d (in, when d < 0), mitred, spikes clamped."""
    n = len(pts)
    out = []
    for i in range(n):
        a, p, b = pts[i - 1], pts[i], pts[(i + 1) % n]
        e1 = (p - a).normalized()
        e2 = (b - p).normalized()
        n1 = Vector((e1.y, -e1.x, 0))
        n2 = Vector((e2.y, -e2.x, 0))
        m = n1 + n2
        if m.length < 1e-6:
            m = n1
        m.normalize()
        s = min(1.0 / max(m.dot(n1), 1e-3), 3.0)
        out.append(p + m * d * s)
    return out


def star(cx, cy, ro, ri, n=5, rot=math.pi / 2, sx=1.0):
    return [Vector((cx + sx * (ro if k % 2 == 0 else ri) * math.cos(rot + k * math.pi / n),
                    cy + (ro if k % 2 == 0 else ri) * math.sin(rot + k * math.pi / n), 0))
            for k in range(2 * n)]


def arc(cx, cy, r, a0, a1, seg):
    return [Vector((cx + r * math.cos(math.radians(a0 + (a1 - a0) * k / seg)),
                    cy + r * math.sin(math.radians(a0 + (a1 - a0) * k / seg)), 0))
            for k in range(seg + 1)]


def side_frame(x, y, z):
    """A frame whose local Z points along world +X, local X out of the front (-Y), local Y up:
    a profile drawn as (out, up) and extruded across the Cabinet."""
    return Matrix.Translation((x, y, z)) @ Matrix(((0, 0, 1, 0), (-1, 0, 0, 0), (0, 1, 0, 0),
                                                  (0, 0, 0, 1)))


def along_x(x, y, z):
    """A frame whose local Z points along world +X (a lathe lying across the Cabinet)."""
    return Matrix.Translation((x, y, z)) @ Matrix.Rotation(math.pi / 2, 4, "Y")


# --- Part: one mesh object from pieces, each piece in a theme material ------------------------

class Part:
    def __init__(self):
        self.bm = bmesh.new()
        self.uv = self.bm.loops.layers.uv.new("uv")

    def _face(self, verts, mat, uvs=None):
        f = self.bm.faces.new(verts)
        f.material_index = MATS.index(mat)
        if uvs is not None:
            for loop, uv in zip(f.loops, uvs):
                loop[self.uv].uv = uv
        return f

    def strip(self, rings, mat, wrap=True, close_path=False, cap_start=None, cap_end=None,
              closed=False):
        """Quads between consecutive rings. Rings counter-clockwise and rising face out; a closed
        piece (`closed`) gets its normals recomputed, an open one keeps the winding given."""
        verts = [[self.bm.verts.new(p) for p in ring] for ring in rings]
        n = len(rings[0])
        faces = []
        pairs = list(zip(verts, verts[1:])) + ([(verts[-1], verts[0])] if close_path else [])
        for a, b in pairs:
            for i in range(n if wrap else n - 1):
                j = (i + 1) % n
                faces.append(self._face((a[i], a[j], b[j], b[i]), mat))
        if cap_start is not None and not close_path:
            faces.append(self._face(list(reversed(verts[0])), cap_start))
        if cap_end is not None and not close_path:
            faces.append(self._face(verts[-1], cap_end))
        if closed:
            bmesh.ops.recalc_face_normals(self.bm, faces=faces)
        return faces

    def rounded_box(self, w, d, z0, z1, r_plan, r_bot, r_top, mat, matrix=None, seg=6,
                    seg_round=3, cap=None):
        """A box rounded in plan, its bottom and top edges rounded, z0..z1 in `matrix`."""
        prof = []
        if r_bot > 0:
            for k in range(seg_round + 1):
                a = math.pi / 2 * k / seg_round
                prof.append((z0 + r_bot * (1 - math.cos(a)), r_bot * (1 - math.sin(a))))
        else:
            prof.append((z0, 0.0))
        if r_top > 0:
            for k in range(seg_round + 1):
                a = math.pi / 2 * k / seg_round
                prof.append((z1 - r_top * (1 - math.sin(a)), r_top * (1 - math.cos(a))))
        else:
            prof.append((z1, 0.0))
        m = matrix or Matrix()
        rings = [[m @ Vector((p.x, p.y, z)) for p in fam.rounded_rect(w - 2 * i, d - 2 * i, r_plan - i, seg)]
                 for z, i in prof]
        return self.strip(rings, mat, cap_start=cap or mat, cap_end=cap or mat, closed=True)

    def prism(self, outline, z0, z1, mat, matrix=None, chamfer=0.0):
        """An outline extruded z0..z1 in `matrix`, its edges chamfered by `chamfer`."""
        o = ccw(outline)
        m = matrix or Matrix()
        if chamfer > 0:
            inner = offset(o, -chamfer)
            layers = [(inner, z0), (o, z0 + chamfer), (o, z1 - chamfer), (inner, z1)]
        else:
            layers = [(o, z0), (o, z1)]
        rings = [[m @ Vector((p.x, p.y, z)) for p in ring] for ring, z in layers]
        return self.strip(rings, mat, cap_start=mat, cap_end=mat, closed=True)

    def lathe(self, profile, mat, matrix=None, n=16, cap_start=None, cap_end=None, closed=True):
        """Turns an (r, h) profile round local Z."""
        m = matrix or Matrix()
        rings = [[m @ Vector((r * math.cos(2 * math.pi * k / n), r * math.sin(2 * math.pi * k / n), h))
                  for k in range(n)] for r, h in profile]
        return self.strip(rings, mat, cap_start=cap_start, cap_end=cap_end, closed=closed)

    def ellipsoid(self, c, rx, ry, rz, mat, u=12, v=7, matrix=None):
        prof = [(math.sin(math.pi * k / v), -math.cos(math.pi * k / v)) for k in range(v + 1)]
        m = (matrix or Matrix()) @ Matrix.Translation(c) @ Matrix.Diagonal((rx, ry, rz, 1))
        return self.lathe(prof, mat, m, n=u)

    def sweep(self, path, radius, mat, normal=(0, 0, 1), matrix=None, n=8, loop=True):
        """A round tube along `path` (points in a plane with `normal`)."""
        m = matrix or Matrix()
        nv = Vector(normal).normalized()
        cnt = len(path)
        rings = []
        for i, p in enumerate(path):
            a = path[(i - 1) % cnt] if loop or i > 0 else p
            b = path[(i + 1) % cnt] if loop or i < cnt - 1 else p
            side = (b - a).normalized().cross(nv).normalized()
            rings.append([m @ (p + radius * (math.cos(2 * math.pi * k / n) * side
                                             + math.sin(2 * math.pi * k / n) * nv)) for k in range(n)])
        return self.strip(rings, mat, close_path=loop, cap_start=None if loop else mat,
                          cap_end=None if loop else mat, closed=True)

    def decal(self, outline, z, w, h, mat, matrix):
        """One flat face of a counter-clockwise outline at local z, mapped 0..1 over w x h."""
        m = matrix
        verts = [self.bm.verts.new(m @ Vector((p.x, p.y, z))) for p in outline]
        uvs = [((p.x + w / 2) / w, (p.y + h / 2) / h) for p in outline]
        return self._face(verts, mat, uvs)

    def finish(self, name, parent, location=(0, 0, 0), mats=None, sharp_deg=40.0):
        bmesh.ops.remove_doubles(self.bm, verts=self.bm.verts, dist=1e-6)
        loc = Vector(location)
        for v in self.bm.verts:
            v.co -= loc
        used = sorted({f.material_index for f in self.bm.faces})
        for f in self.bm.faces:
            f.material_index = used.index(f.material_index)
        me = bpy.data.meshes.new(name)
        self.bm.to_mesh(me)
        self.bm.free()
        for i in used:
            me.materials.append(mats[MATS[i]])
        for p in me.polygons:
            p.use_smooth = True
        me.set_sharp_from_angle(angle=math.radians(sharp_deg))
        ob = bpy.data.objects.new(name, me)
        bpy.context.scene.collection.objects.link(ob)
        ob.location = loc
        if parent is not None:
            ob.parent = parent
        return ob


# --- Materials ---------------------------------------------------------------------------------

def material(name, spec, image=None):
    colour, rough, metal = spec
    m = bpy.data.materials.new(name)
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    col = fam.srgb(colour)
    b.inputs["Base Color"].default_value = col
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    m.diffuse_color = col
    m.roughness, m.metallic = rough, metal
    if image is not None:
        tex = m.node_tree.nodes.new("ShaderNodeTexImage")
        tex.image = image
        tex.extension = "EXTEND"
        m.node_tree.links.new(tex.outputs["Color"], b.inputs["Base Color"])
    return m


# The front art's image name where it is not "<collection>_front_art": the Patterns Collection was
# "casual" when its source was made, and Godot names the picture it extracts from the glb after it
# (assets/cabinet/patterns_casual_front_art.png), so a re-export keeps the old name.
ART_NAMES = {"patterns": "casual_front_art"}


def theme_materials(name):
    t = THEMES[name]
    front = (art.DECALS[name]().to_image(ART_NAMES.get(name, name + "_front_art"))
             if name in art.DECALS else None)
    side = art.SIDE_DECALS[name]().to_image(name + "_side_art") if name in art.SIDE_DECALS else None
    return {"body": material("body", t["body"]), "trim": material("trim", t["trim"]),
            "accent": material("accent", t["accent"]), "dark": material("dark", t["dark"]),
            "front": material("front", ("#ffffff", 0.6, 0.0), front),
            "side": material("side", ("#ffffff", 0.6, 0.0), side) if side is not None
            else material("side", t.get("extra", ("#ffffff", 0.6, 0.0)))}


# --- The base ----------------------------------------------------------------------------------

def make_base(t):
    p = Part()
    style = t["base"]
    W, D = 2 * HALF_W, 2 * HALF_D
    if style == "buns":                  # squat bun feet under a soft-edged plinth
        p.rounded_box(W, D, 0.032, BASE_H, CORNER_R, 0.012, 0.0, "body")
        for sx in (-1, 1):
            for sy in (-1, 1):
                prof = [(0.044, 0.0), (0.052, 0.008), (0.054, 0.018), (0.048, 0.028), (0.036, 0.036)]
                p.lathe(prof, "dark", Matrix.Translation((sx * (HALF_W - 0.1), sy * (HALF_D - 0.08), 0)),
                        n=14, cap_start="dark", cap_end="dark")
    elif style == "legs":                # mid-century tapered legs under an apron
        p.rounded_box(W, D, 0.066, BASE_H, CORNER_R, 0.01, 0.0, "body")
        for sx in (-1, 1):
            for sy in (-1, 1):
                x, y = sx * (HALF_W - 0.08), sy * (HALF_D - 0.07)
                prof = [(0.011, 0.0), (0.013, 0.006), (0.016, 0.03), (0.022, 0.07)]
                p.lathe(prof, "accent", Matrix.Translation((x, y, 0)), n=10, cap_start="dark",
                        cap_end="accent")
    elif style == "wheels":              # toy-car tyres with yellow hubs, a plinth over them
        p.rounded_box(W, D, 0.07, BASE_H, CORNER_R, 0.008, 0.0, "body")
        p.rounded_box(W - 0.3, D - 0.12, 0.03, 0.072, 0.012, 0.0, 0.0, "dark", seg=3)
        for sx in (-1, 1):
            for sy in (-1, 1):
                x, y = sx * (HALF_W - 0.03), sy * (HALF_D - 0.115)
                prof = [(0.0, -0.022), (0.04, -0.022), (0.05, -0.014), (0.05, 0.014), (0.04, 0.022),
                        (0.0, 0.022)]
                p.lathe(prof, "trim", along_x(x, y, 0.05), n=16)
                p.lathe([(0.026, sx * 0.021), (0.022, sx * 0.026), (0.0, sx * 0.027)], "body",
                        along_x(x, y, 0.05), n=12, cap_start="body")
    elif style == "kick":                # a recessed dark kick plate, locker style
        p.rounded_box(W, D, 0.04, BASE_H, CORNER_R, 0.008, 0.0, "body")
        p.rounded_box(W - 0.06, D - 0.06, 0.0, 0.042, 0.012, 0.0, 0.0, "dark",
                      Matrix.Translation((0, 0.02, 0)), seg=3)
    else:                                # plinth over a shadow gap
        p.rounded_box(W, D, 0.024, BASE_H, CORNER_R, 0.006, 0.0, "body")
        p.rounded_box(W - 0.05, D - 0.04, 0.0, 0.026, 0.01, 0.0, 0.0, "dark",
                      Matrix.Translation((0, 0.01, 0)), seg=3)
    return p


# --- The segment (one Row's carcass slice) -----------------------------------------------------

def make_segment(t, name):
    p = Part()
    inner = HALF_W - SIDE_T
    out = [Vector((inner, -HALF_D, 0))]
    out += arc(HALF_W - CORNER_R, -HALF_D + CORNER_R, CORNER_R, -90, 0, 4)
    out += arc(HALF_W - CORNER_R, HALF_D - CORNER_R, CORNER_R, 0, 90, 4)
    out += arc(-HALF_W + CORNER_R, HALF_D - CORNER_R, CORNER_R, 90, 180, 4)
    out += arc(-HALF_W + CORNER_R, -HALF_D + CORNER_R, CORNER_R, 180, 270, 4)
    out += [Vector((-inner, -HALF_D, 0)), Vector((-inner, HALF_D - BACK_T, 0)),
            Vector((inner, HALF_D - BACK_T, 0))]
    p.prism(out, 0.0, SEG_H, "body")
    # The rails under and over the Drawer, set 4 mm back so the gaps read as shadow lines.
    for z0, z1 in ((0.0, RAIL_H), (SEG_H - RAIL_H, SEG_H)):
        p.prism([Vector((-inner, -HALF_D + 0.004, 0)), Vector((inner, -HALF_D + 0.004, 0)),
                 Vector((inner, -HALF_D + 0.03, 0)), Vector((-inner, -HALF_D + 0.03, 0))],
                z0, z1, "dark" if name == "sport" else "body")
    if name in art.SIDE_DECALS:          # the printed side panels
        y0, y1 = -HALF_D + 0.01, HALF_D - 0.01
        for sx in (-1, 1):
            x = sx * (HALF_W + 0.0012)
            pts = [(y0, 0.0), (y1, 0.0), (y1, SEG_H), (y0, SEG_H)]
            if sx < 0:
                pts.reverse()
            verts = [p.bm.verts.new((x, y, z)) for y, z in pts]
            uvs = [((y - y0) / (y1 - y0) if sx > 0 else (y1 - y) / (y1 - y0), z / SEG_H) for y, z in pts]
            p._face(verts, "side", uvs)
    if name == "sport":                  # locker: a chrome seam strip down each front edge
        for sx in (-1, 1):
            p.prism([Vector((sx * (HALF_W - 0.018) - 0.006, -HALF_D - 0.003, 0)),
                     Vector((sx * (HALF_W - 0.018) + 0.006, -HALF_D - 0.003, 0)),
                     Vector((sx * (HALF_W - 0.018) + 0.006, -HALF_D + 0.004, 0)),
                     Vector((sx * (HALF_W - 0.018) - 0.006, -HALF_D + 0.004, 0))],
                    0.0, SEG_H, "trim")
    return p


# --- The top -----------------------------------------------------------------------------------

def make_top(t):
    p = Part()
    style = t["top"]
    lid_mat = t.get("lid") or ("accent" if style in ("slab", "gallery") else "body")
    # A reveal over the carcass, then the lid proper: the contract cap, z 0..0.05.
    p.rounded_box(2 * HALF_W - 0.01, 2 * HALF_D - 0.01, 0.0, 0.014, CORNER_R, 0.0, 0.0, "body")
    r_top = 0.02 if style == "slab" else 0.012
    p.rounded_box(TOP_W, TOP_D, 0.012, TOP_H, 0.035, 0.005, r_top, lid_mat)
    if style == "cornice":               # a stepped crown and a bead over the carcass
        p.rounded_box(TOP_W + 0.05, TOP_D + 0.05, TOP_H - 0.006, TOP_H + 0.024, 0.05, 0.01, 0.008,
                      "body")
        bead = fam.rounded_rect(2 * HALF_W + 0.006, 2 * HALF_D + 0.006, CORNER_R + 0.003, 6)
        p.sweep(bead, 0.006, "accent", matrix=Matrix.Translation((0, 0, 0.007)), n=6)
    elif style == "slope":               # locker: a sloped cap, low at the front
        prof = [(TOP_D / 2 - 0.004, 0.0), (TOP_D / 2 - 0.004, 0.025), (-TOP_D / 2 + 0.004, 0.14),
                (-TOP_D / 2 + 0.004, 0.0)]
        p.prism(prof, -TOP_W / 2 + 0.004, TOP_W / 2 - 0.004, "body",
                side_frame(0, 0, TOP_H - 0.004), chamfer=0.008)
        p.sweep([Vector((-TOP_W / 2, -TOP_D / 2 + 0.003, 0)), Vector((TOP_W / 2, -TOP_D / 2 + 0.003, 0))],
                0.005, "trim", normal=(0, 1, 0), matrix=Matrix.Translation((0, 0, TOP_H + 0.012)),
                loop=False, n=6)
    elif style == "snow":                # a soft cap of snow, drips over the front edge
        p.rounded_box(TOP_W + 0.02, TOP_D + 0.02, TOP_H - 0.012, TOP_H + 0.042, 0.06, 0.01, 0.03,
                      "accent", seg=6, seg_round=3)
        for x, r, dz in ((-0.62, 0.05, 0.05), (-0.3, 0.038, 0.04), (0.03, 0.058, 0.056),
                         (0.36, 0.044, 0.045), (0.64, 0.04, 0.04)):
            p.ellipsoid((x, -TOP_D / 2 - 0.006, TOP_H - 0.006), r, 0.024, dz, "accent", u=12, v=6)
    elif style == "ears":                # round bear ears with pink insides
        for sx in (-1, 1):
            f = fam.front(sx * 0.52, 0.02, TOP_H + 0.068)
            p.rounded_box(0.17, 0.17, -0.035, 0.035, 0.085, 0.014, 0.014, "body", f, seg=6)
            p.rounded_box(0.1, 0.1, 0.03, 0.042, 0.05, 0.0, 0.006, "accent", f, seg=5, seg_round=2)
    elif style == "burst":               # a comic burst crest (no text)
        f = fam.front(0, 0.0, TOP_H + 0.1)
        p.prism(star(0, 0, 0.15, 0.09, n=10, rot=0.2, sx=1.7), -0.03, 0.02, "dark", f, chamfer=0.005)
        p.prism(star(0, 0, 0.122, 0.074, n=10, rot=0.2, sx=1.45), 0.0, 0.034, "trim", f,
                chamfer=0.005)
        p.prism(star(0, 0, 0.065, 0.04, n=10, rot=0.45, sx=1.7), 0.02, 0.046, "body", f,
                chamfer=0.004)
    elif style == "gallery":             # a spindle gallery round the back and sides
        y0, y1 = TOP_H - 0.002, TOP_H + 0.09
        xs, yb, yf = TOP_W / 2 - 0.03, TOP_D / 2 - 0.03, -0.17
        rail = [Vector((-xs, yf, 0))] + arc(-xs + 0.03, yb - 0.03, 0.03, 180, 90, 3) \
            + arc(xs - 0.03, yb - 0.03, 0.03, 90, 0, 3) + [Vector((xs, yf, 0))]
        p.sweep(rail, 0.011, "accent", matrix=Matrix.Translation((0, 0, y1)), loop=False, n=8)
        for sx in (-1, 1):               # front posts with ball finials
            p.lathe([(0.016, y0), (0.016, y1 + 0.012), (0.01, y1 + 0.02)], "accent",
                    Matrix.Translation((sx * xs, yf, 0)), n=10, cap_start="accent", cap_end="accent")
            p.ellipsoid((sx * xs, yf, y1 + 0.036), 0.022, 0.022, 0.022, "accent", u=10, v=6)
            for k in range(4):
                p.lathe([(0.007, y0), (0.007, y1)], "accent",
                        Matrix.Translation((sx * xs, yf + 0.07 + k * 0.08, 0)), n=6,
                        cap_start="accent", cap_end="accent")
        for k in range(15):
            p.lathe([(0.007, y0), (0.007, y1)], "accent",
                    Matrix.Translation((-xs + 0.04 + k * (2 * xs - 0.08) / 14, yb, 0)), n=6,
                    cap_start="accent", cap_end="accent")
    elif style == "space":               # a silver rim and a ringed planet on a stand
        rim = fam.rounded_rect(TOP_W + 0.004, TOP_D + 0.004, 0.036, 6)
        p.sweep(rim, 0.006, "trim", matrix=Matrix.Translation((0, 0, 0.03)), n=6)
        cx, cy = 0.55, 0.05
        p.lathe([(0.05, TOP_H - 0.002), (0.05, TOP_H + 0.008), (0.03, TOP_H + 0.016),
                 (0.012, TOP_H + 0.03), (0.01, TOP_H + 0.06)], "trim",
                Matrix.Translation((cx, cy, 0)), n=14, cap_start="trim", cap_end="trim")
        p.ellipsoid((cx, cy, TOP_H + 0.11), 0.065, 0.065, 0.065, "accent", u=18, v=10)
        tilt = Matrix.Translation((cx, cy, TOP_H + 0.11)) @ Matrix.Rotation(math.radians(-22), 4, "X") \
            @ Matrix.Rotation(math.radians(12), 4, "Y")
        p.sweep(fam.circle(0.105, 32), 0.008, "trim", matrix=tilt, n=6)
    elif style == "crystals":            # a brass rim and a cluster of hexagonal crystals
        rim = fam.rounded_rect(TOP_W + 0.004, TOP_D + 0.004, 0.036, 6)
        p.sweep(rim, 0.006, "trim", matrix=Matrix.Translation((0, 0, 0.03)), n=6)
        for x, y, r, hgt, ax, ay in ((0.5, 0.05, 0.05, 0.22, 0, 0), (0.4, 0.0, 0.036, 0.15, -22, 8),
                                     (0.6, 0.1, 0.034, 0.14, 18, -12), (0.56, -0.05, 0.028, 0.1, 14, 24)):
            m = Matrix.Translation((x, y, TOP_H - 0.004)) @ Matrix.Rotation(math.radians(ax), 4, "Y") \
                @ Matrix.Rotation(math.radians(ay), 4, "X")
            p.lathe([(0.0, 0.0), (r, 0.0), (r, hgt * 0.75), (0.0, hgt)], "accent", m, n=6)
    elif style == "toadstools":          # a mossy mound with three red toadstools
        p.rounded_box(TOP_W - 0.03, TOP_D - 0.03, TOP_H - 0.006, TOP_H + 0.02, 0.06, 0.004, 0.012,
                      "accent", seg=6, seg_round=3)
        z = TOP_H + 0.018
        for x, y, s in ((0.5, 0.05, 1.0), (0.64, -0.06, 0.7), (0.36, 0.1, 0.55)):
            m = Matrix.Translation((x, y, z)) @ Matrix.Diagonal((s, s, s, 1))
            p.lathe([(0.02, 0.0), (0.024, 0.04), (0.019, 0.08), (0.0, 0.082)], "body", m, n=12,
                    cap_start="body")
            p.lathe([(0.0, 0.07), (0.03, 0.07), (0.068, 0.076), (0.07, 0.088), (0.055, 0.112),
                     (0.03, 0.126), (0.0, 0.13)], "side", m, n=18)
    elif style == "apple":               # a big red apple with its stalk and a leaf, a lemon by it
        cx, cy, z = 0.5, 0.04, TOP_H - 0.004
        prof = [(0.0, 0.012), (0.035, 0.0), (0.07, 0.02), (0.088, 0.062), (0.084, 0.105), (0.062, 0.134),
                (0.03, 0.14), (0.0, 0.128)]
        p.lathe(prof, "accent", Matrix.Translation((cx, cy, z)), n=20)
        stalk = Matrix.Translation((cx, cy, z + 0.125)) @ Matrix.Rotation(math.radians(14), 4, "Y")
        p.lathe([(0.006, 0.0), (0.005, 0.045), (0.0045, 0.05)], "dark", stalk, n=8, cap_end="dark")
        lf = Matrix.Translation((cx + 0.04, cy, z + 0.155)) @ Matrix.Rotation(math.radians(-25), 4, "Y")
        p.ellipsoid((0, 0, 0), 0.04, 0.018, 0.005, "trim", u=12, v=5, matrix=lf)
        p.ellipsoid((0.32, -0.02, TOP_H + 0.03), 0.055, 0.036, 0.034, "side", u=14, v=8)
        for sx in (-1, 1):
            p.ellipsoid((0.32 + sx * 0.055, -0.02, TOP_H + 0.03), 0.01, 0.01, 0.01, "side", u=8, v=4)
    elif style == "planter":             # a planter box of soil with sprouts and carrot tops
        bw, bd = TOP_W - 0.16, TOP_D - 0.2
        p.rounded_box(bw, bd, TOP_H - 0.004, TOP_H + 0.06, 0.012, 0.0, 0.006, "body", seg=3)
        p.rounded_box(bw - 0.03, bd - 0.03, TOP_H + 0.04, TOP_H + 0.064, 0.008, 0.0, 0.008, "dark",
                      seg=3)
        rnd = random.Random(51)
        for k in range(9):
            x = -bw / 2 + 0.08 + k * (bw - 0.16) / 8
            y = rnd.uniform(-0.03, 0.03)
            base = Matrix.Translation((x, y, TOP_H + 0.062))
            carrot = k % 3 == 1
            if carrot:                   # an orange shoulder under a feathery top
                p.ellipsoid((0, 0, 0.004), 0.022, 0.022, 0.016, "side", u=10, v=5, matrix=base)
            for a in ((-30, 0), (30, 0), (0, 25)) if not carrot else ((-18, 0), (0, 0), (18, 0), (0, 15)):
                m = base @ Matrix.Rotation(math.radians(a[0]), 4, "Y") @ Matrix.Rotation(math.radians(a[1]), 4, "X")
                ln = 0.07 if carrot else 0.05
                p.ellipsoid((0, 0, ln * 0.8), 0.014 if carrot else 0.022, 0.006, ln, "trim" if carrot
                            else "accent", u=6, v=4, matrix=m)
    elif style == "cup":                 # a big soda cup with a lid and a red-banded straw
        cx, cy, z = 0.5, 0.04, TOP_H - 0.004
        m = Matrix.Translation((cx, cy, z))
        p.lathe([(0.0, 0.0), (0.05, 0.0), (0.066, 0.17), (0.0, 0.17)], "accent", m, n=20)
        p.lathe([(0.0558, 0.05), (0.0598, 0.05), (0.0634, 0.11), (0.0594, 0.11)], "side", m, n=20)
        p.lathe([(0.0, 0.165), (0.07, 0.165), (0.071, 0.178), (0.052, 0.188), (0.0, 0.19)], "trim", m, n=20)
        straw = Matrix.Translation((cx + 0.012, cy, z + 0.18)) @ Matrix.Rotation(math.radians(12), 4, "Y")
        p.lathe([(0.008, 0.0), (0.008, 0.11)], "side", straw, n=8, cap_end="side")
        p.ellipsoid((-0.33, -0.02, TOP_H + 0.012), 0.03, 0.03, 0.012, "side", u=14, v=4)   # a cap
    elif style == "solids":              # geometry: a cube, a cone and a sphere, chalk and red
        z = TOP_H - 0.004
        rot = Matrix.Translation((0.34, 0.03, z)) @ Matrix.Rotation(math.radians(22), 4, "Z")
        p.prism([Vector((-0.045, -0.045, 0)), Vector((0.045, -0.045, 0)), Vector((0.045, 0.045, 0)),
                 Vector((-0.045, 0.045, 0))], 0.0, 0.09, "side", rot, chamfer=0.004)
        p.lathe([(0.0, 0.0), (0.055, 0.0), (0.0, 0.15)], "accent", Matrix.Translation((0.5, 0.06, z)), n=20)
        p.ellipsoid((0.64, -0.02, z + 0.05), 0.05, 0.05, 0.05, "body", u=16, v=9)
        p.prism([Vector((-0.07, 0, 0)), Vector((0.07, 0, 0)), Vector((-0.07, 0.12, 0))], -0.008, 0.008,
                "accent", fam.front(-0.48, 0.05, z), chamfer=0.003)     # a set square
    elif style == "antenna":             # a cyan light strip, a satellite dish and an antenna
        p.rounded_box(TOP_W - 0.2, 0.012, TOP_H - 0.002, TOP_H + 0.004, 0.004, 0.0, 0.002, "accent",
                      Matrix.Translation((0, -TOP_D / 2 + 0.03, 0)), seg=2, seg_round=1)
        z = TOP_H - 0.004
        p.lathe([(0.04, 0.0), (0.04, 0.012), (0.012, 0.02), (0.01, 0.07)], "trim",
                Matrix.Translation((0.5, 0.06, z)), n=14, cap_start="trim", cap_end="trim")
        dish = Matrix.Translation((0.5, 0.06, z + 0.09)) @ Matrix.Rotation(math.radians(40), 4, "X")
        p.lathe([(0.0, 0.0), (0.03, 0.004), (0.06, 0.016), (0.08, 0.032), (0.075, 0.034), (0.055, 0.02),
                 (0.03, 0.01), (0.0, 0.006)], "side", dish, n=20)
        p.lathe([(0.004, 0.0), (0.004, 0.07)], "trim", dish, n=6, cap_end="trim")
        p.ellipsoid((0, 0, 0.075), 0.01, 0.01, 0.01, "accent", u=8, v=5, matrix=dish)
        p.lathe([(0.016, 0.0), (0.016, 0.02), (0.004, 0.024), (0.003, 0.2)], "trim",
                Matrix.Translation((0.66, -0.02, z)), n=8, cap_start="trim", cap_end="trim")
        p.ellipsoid((0.66, -0.02, z + 0.21), 0.012, 0.012, 0.012, "accent", u=8, v=5)
    elif style == "car":                 # a toy car, seen side on, parked on the lid
        f = fam.front(0.46, 0.03, TOP_H - 0.004)
        body = [(-0.15, 0.03), (0.15, 0.03), (0.155, 0.075), (0.09, 0.085), (0.055, 0.13), (-0.06, 0.13),
                (-0.1, 0.085), (-0.155, 0.08)]
        p.prism([Vector(q + (0,)) for q in body], -0.05, 0.05, "body", f, chamfer=0.008)
        for win in ([(-0.088, 0.088), (-0.006, 0.088), (-0.006, 0.122), (-0.056, 0.122)],
                    [(0.006, 0.088), (0.078, 0.088), (0.05, 0.122), (0.006, 0.122)]):
            p.prism([Vector(q + (0,)) for q in win], 0.049, 0.052, "dark", f)
            p.prism([Vector((q[0], q[1], 0)) for q in reversed(win)], -0.052, -0.049, "dark", f)
        p.rounded_box(0.06, 0.03, -0.02, 0.02, 0.006, 0.0, 0.004, "dark", fam.front(0.46, 0.03, TOP_H + 0.13),
                      seg=2, seg_round=1)   # taxi roof sign
        p.rounded_box(0.05, 0.022, -0.021, 0.021, 0.004, 0.0, 0.004, "side", fam.front(0.46, 0.03, TOP_H + 0.136),
                      seg=2, seg_round=1)
        for wx in (-0.09, 0.09):
            for wz in (-0.04, 0.04):
                prof = [(0.0, -0.012), (0.03, -0.012), (0.034, -0.006), (0.034, 0.006), (0.03, 0.012),
                        (0.0, 0.012)]
                p.lathe(prof, "trim", f @ Matrix.Translation((wx, 0.032, wz)), n=14)
                hub = [(0.016, 0.0), (0.014, 0.004), (0.0, 0.005)]
                p.lathe([(r, h + 0.011) if wz > 0 else (r, -h - 0.011) for r, h in hub], "accent",
                        f @ Matrix.Translation((wx, 0.032, wz)), n=10, cap_start="accent")
    elif style == "cogs":                # two meshing cogs standing on a dark base
        z = TOP_H - 0.004
        p.rounded_box(0.42, 0.1, z, z + 0.02, 0.01, 0.0, 0.004, "dark", Matrix.Translation((0.5, 0.06, 0)),
                      seg=3)
        for cx, cz, r, n, mat, rot in ((0.42, 0.155, 0.13, 12, "trim", 0.0), (0.64, 0.105, 0.085, 8, "accent", 0.2)):
            f = fam.front(cx, 0.06, z + cz)
            p.prism(gear(r, r - 0.025, n, rot), -0.016, 0.016, mat, f, chamfer=0.003)
            p.lathe([(0.0, -0.022), (r * 0.32, -0.022), (r * 0.32, 0.022), (0.0, 0.022)], "dark", f, n=14)
            for k in range(4 if n > 8 else 3):
                a = rot + 2 * math.pi * (k + 0.5) / (4 if n > 8 else 3)
                p.lathe([(0.0, 0.016), (0.008, 0.016), (0.008, 0.02), (0.0, 0.02)], "dark",
                        f @ Matrix.Translation((math.cos(a) * r * 0.6, math.sin(a) * r * 0.6, 0)), n=8)
    return p


def gear(r_out, r_in, n, rot=0.0):
    """A cog's outline: n flat-topped teeth from r_in to r_out."""
    pts = []
    for k in range(n):
        a = rot + 2 * math.pi * k / n
        da = 2 * math.pi / n
        for t, r in ((0.0, r_in), (0.18, r_out), (0.5, r_out), (0.68, r_in)):
            pts.append(Vector((r * math.cos(a + t * da), r * math.sin(a + t * da), 0)))
    return pts


# --- The drawer --------------------------------------------------------------------------------

def _front_matrix(z=0.0):
    """Drawer space: local Z out of the front (-Y); local z 0 at the front's back, FRONT_T its face."""
    return fam.front(0, BACK_Y - z, HANDLE_Z)


def _face(x=0.0, out=0.0, up=0.0):
    """A front-facing frame on the front's face at x, `up` over the handle line, `out` in front."""
    return fam.front(x, FACE_Y - out, HANDLE_Z + up)


def make_tray(p):
    """The open-top tray behind the front: a closed shell, its floor top at TRAY_FLOOR."""
    bm = p.bm
    ox, oy0, oy1 = TRAY_X + TRAY_WALL, BACK_Y - 0.002, TRAY_Y1 + TRAY_WALL
    floor0 = TRAY_FLOOR - TRAY_WALL

    def ring(x, y0, y1, z):
        return [bm.verts.new(c) for c in ((-x, y0, z), (x, y0, z), (x, y1, z), (-x, y1, z))]
    ob = ring(ox, oy0, oy1, floor0)
    ot = ring(ox, oy0, oy1, TRAY_TOP)
    it = ring(TRAY_X, TRAY_Y0, TRAY_Y1, TRAY_TOP)
    ib = ring(TRAY_X, TRAY_Y0, TRAY_Y1, TRAY_FLOOR)
    faces = [p._face(list(reversed(ob)), "dark"), p._face(ib, "dark")]
    for i in range(4):
        j = (i + 1) % 4
        faces += [p._face((ob[i], ob[j], ot[j], ot[i]), "dark"),
                  p._face((ot[i], ot[j], it[j], it[i]), "dark"),
                  p._face((it[i], it[j], ib[j], ib[i]), "dark")]
    bmesh.ops.recalc_face_normals(bm, faces=faces)


def make_front(p, t, name):
    style = t["front"]
    m = _front_matrix()
    if style in ("shaker", "pantry", "framed"):   # a moulded frame round a recessed panel
        fmat = {"shaker": "body", "pantry": "accent", "framed": "trim"}[style]
        p.rounded_box(FRONT_W, FRONT_H, 0.0, FRONT_T - 0.01, 0.02, 0.0, 0.004, fmat, m)
        fw, fh, b = FRONT_W, FRONT_H, art.PANEL_INSET
        rr = fam.rounded_rect
        prof = [(rr(fw, fh, 0.02, 6), FRONT_T - 0.012), (rr(fw, fh, 0.02, 6), FRONT_T - 0.006),
                (rr(fw - 0.012, fh - 0.012, 0.014, 6), FRONT_T),
                (rr(fw - 2 * b + 0.012, fh - 2 * b + 0.012, 0.016, 6), FRONT_T),
                (rr(fw - 2 * b, fh - 2 * b, 0.01, 6), FRONT_T - 0.006),
                (rr(fw - 2 * b, fh - 2 * b, 0.01, 6), FRONT_T - 0.011)]
        p.strip([[m @ Vector((q.x, q.y, z)) for q in ring] for ring, z in prof], fmat)
        if style in ("pantry", "framed"):   # the gingham (or the chalkboard) in the panel
            p.decal(fam.rounded_rect(art.PANEL_W, art.PANEL_H, 0.01, 6), FRONT_T - 0.0095,
                    art.PANEL_W, art.PANEL_H, "front", m)
    else:                                # a cushioned slab with its printed art
        r = 0.06 if name == "animals" else t.get("front_r", 0.03)
        p.rounded_box(FRONT_W, FRONT_H, 0.0, FRONT_T, r, 0.0, 0.012, "body", m, seg=6)
        if style == "decal":
            dw, dh = art.DECAL_W, art.DECAL_H
            p.decal(fam.rounded_rect(dw, dh, max(0.02, r - 0.01), 6), FRONT_T + 0.0008, dw, dh,
                    "front", m)


def make_handles(p, t):
    h = t["handle"]
    if h == "bar":                       # an arched steel D-pull on two round roses
        y = FACE_Y
        path = [Vector((-0.2, y + 0.004, 0)), Vector((-0.2, y - 0.012, 0))]
        path += arc(-0.185, y - 0.012, 0.015, 180, 270, 3)[1:]
        path += arc(0.185, y - 0.012, 0.015, 270, 360, 3)[:-1]
        path += [Vector((0.2, y - 0.012, 0)), Vector((0.2, y + 0.004, 0))]
        p.sweep(path, 0.0075, "trim", normal=(0, 0, 1), matrix=Matrix.Translation((0, 0, HANDLE_Z)),
                loop=False, n=8)
        for sx in (-1, 1):
            p.lathe([(0.014, -0.002), (0.014, 0.002), (0.009, 0.006)], "trim", _face(sx * 0.2), n=12,
                    cap_end="trim", cap_start="trim")
    elif h == "knobs":                   # two turned wooden knobs
        prof = [(0.011, -0.003), (0.011, 0.012), (0.024, 0.018), (0.031, 0.024), (0.03, 0.03),
                (0.022, 0.036), (0.011, 0.039)]
        for sx in (-1, 1):
            p.lathe(prof, "trim", _face(sx * 0.4), n=14, cap_start="trim", cap_end="trim")
    elif h == "latch":                   # a locker lift latch: dark pocket, chrome lever
        p.rounded_box(0.19, 0.11, -0.003, 0.006, 0.022, 0.0, 0.004, "dark", _face(), seg=4)
        p.lathe([(0.012, 0.0), (0.012, 0.024), (0.008, 0.028)], "trim", _face(-0.055), n=10,
                cap_start="trim", cap_end="trim")
        p.rounded_box(0.15, 0.028, 0.018, 0.036, 0.014, 0.004, 0.006, "trim", _face(0.0, 0.0, -0.004),
                      seg=4, seg_round=2)
    elif h == "toggle":                  # a leather strap with a wooden toggle
        p.rounded_box(0.044, 0.2, -0.002, 0.008, 0.01, 0.0, 0.003, "dark", _face(), seg=3, seg_round=2)
        p.lathe([(0.007, 0.0), (0.007, 0.024)], "dark", _face(), n=8, cap_start="dark", cap_end="dark")
        prof = [(0.0, -0.05), (0.009, -0.047), (0.015, -0.038), (0.017, -0.025), (0.017, 0.025),
                (0.015, 0.038), (0.009, 0.047), (0.0, 0.05)]
        p.lathe(prof, "trim", along_x(0, FACE_Y - 0.022, HANDLE_Z), n=10)
    elif h == "paws":                    # paw knobs: a pad, four toe beans and a pink pad
        for sx in (-1, 1):
            x = sx * 0.33
            p.lathe([(0.012, -0.003), (0.012, 0.016)], "trim", _face(x), n=8,
                    cap_start="trim", cap_end="trim")
            f = _face(x)
            p.ellipsoid((0, -0.008, 0.022), 0.031, 0.026, 0.013, "trim", u=14, v=6, matrix=f)
            for dx, dy in ((-0.034, 0.02), (-0.013, 0.038), (0.013, 0.038), (0.034, 0.02)):
                p.ellipsoid((dx, dy, 0.02), 0.011, 0.013, 0.01, "trim", u=8, v=5, matrix=f)
            p.ellipsoid((0, -0.01, 0.032), 0.017, 0.012, 0.006, "accent", u=10, v=4, matrix=f)
    elif h == "bolt":                    # a lightning-bolt pull over the comic burst
        bolt = [(0.02, 0.07), (-0.035, -0.005), (-0.002, -0.005), (-0.025, -0.07),
                (0.04, 0.012), (0.006, 0.012), (0.03, 0.07)]
        p.lathe([(0.01, -0.003), (0.01, 0.016)], "dark", _face(), n=8, cap_start="dark", cap_end="dark")
        p.prism([Vector((x * 1.1, y * 1.1, 0)) for x, y in bolt], 0.012, 0.03, "dark", _face(),
                chamfer=0.003)
        p.prism([Vector((x * 0.86, y * 0.86, 0)) for x, y in bolt], 0.024, 0.04, "trim", _face(),
                chamfer=0.003)
    elif h == "cups":                    # brass cup pulls
        for sx in (-1, 1):
            x = sx * 0.4
            p.rounded_box(0.12, 0.062, -0.002, 0.004, 0.012, 0.0, 0.002, "trim", _face(x, 0, 0.004),
                          seg=3, seg_round=1)
            band = arc(0.0, -0.012, 0.04, 90, -5, 8) + arc(0.0, -0.012, 0.033, -5, 90, 8)
            p.prism(band, x - 0.048, x + 0.048, "trim", side_frame(0, FACE_Y, HANDLE_Z), chamfer=0.002)
    elif h == "planets":                 # ringed-planet knobs
        for sx in (-1, 1):
            x = sx * 0.33
            f = _face(x)
            p.lathe([(0.01, -0.003), (0.01, 0.014)], "trim", f, n=8, cap_start="trim", cap_end="trim")
            p.ellipsoid((0, 0, 0.017), 0.021, 0.021, 0.021, "accent", u=14, v=8, matrix=f)
            ring = f @ Matrix.Translation((0, 0, 0.017)) @ Matrix.Rotation(math.radians(-25), 4, "Z") \
                @ Matrix.Rotation(math.radians(38), 4, "X")
            p.sweep(fam.circle(0.033, 24), 0.0045, "trim", matrix=ring, n=6)
    elif h == "gems":                    # a brass collar under a pointed hexagonal crystal
        prof = [(0.0, 0.01), (0.032, 0.013), (0.032, 0.026), (0.0, 0.038)]
        for sx in (-1, 1):
            f = _face(sx * 0.33)
            p.lathe([(0.012, -0.003), (0.012, 0.008), (0.02, 0.011)], "trim", f, n=12,
                    cap_start="trim", cap_end="trim")
            p.lathe(prof, "accent", f, n=6)
    elif h == "acorns":                  # acorn knobs: a bark cup and a wooden nut, pointing out
        for sx in (-1, 1):
            f = _face(sx * 0.33)
            p.lathe([(0.007, -0.003), (0.007, 0.01)], "trim", f, n=8, cap_start="trim")
            p.lathe([(0.0, 0.008), (0.016, 0.009), (0.023, 0.014), (0.024, 0.019), (0.0, 0.02)],
                    "trim", f, n=14)
            p.lathe([(0.0, 0.018), (0.019, 0.018), (0.019, 0.027), (0.013, 0.034), (0.005, 0.039),
                     (0.0, 0.04)], "body", f, n=14)
    elif h == "cherries":                # a pair of cherries on their stalks under a leaf
        for sx in (-1, 1):
            f = _face(sx * 0.33)
            p.lathe([(0.006, -0.003), (0.006, 0.016)], "trim", _face(sx * 0.33, 0, 0.026), n=8,
                    cap_start="trim", cap_end="trim")
            for dx in (-0.022, 0.022):
                p.sweep([Vector((0.0, 0.034, 0.016)), Vector((dx * 0.5, 0.02, 0.018)),
                         Vector((dx, 0.004, 0.02))], 0.003, "trim", normal=(0, 0, 1), matrix=f,
                        n=6, loop=False)
                p.ellipsoid((dx, -0.01, 0.02), 0.021, 0.021, 0.019, "accent", u=14, v=8, matrix=f)
            lf = f @ Matrix.Translation((0.018, 0.04, 0.018)) @ Matrix.Rotation(math.radians(30), 4, "Z")
            p.ellipsoid((0, 0, 0), 0.022, 0.009, 0.003, "trim", u=10, v=4, matrix=lf)
    elif h == "carrot":                  # a carrot pull on two posts, its leaves to one side
        for sx in (-1, 1):
            p.lathe([(0.006, -0.003), (0.006, 0.02)], "dark", _face(sx * 0.05), n=8,
                    cap_start="dark", cap_end="dark")
        prof = [(0.0, -0.11), (0.004, -0.1), (0.01, -0.05), (0.015, 0.03), (0.016, 0.06),
                (0.012, 0.072), (0.0, 0.075)]
        p.lathe(prof, "side", along_x(0, FACE_Y - 0.022, HANDLE_Z), n=12)
        for a in (-30, 0, 30):
            m = _face(0.078, 0.022) @ Matrix.Rotation(math.radians(a), 4, "Z")
            p.ellipsoid((0.035, 0, 0), 0.04, 0.009, 0.005, "trim", u=10, v=4, matrix=m)
    elif h == "caps":                    # crimped bottle caps on chrome stems
        for sx in (-1, 1):
            f = _face(sx * 0.33)
            p.lathe([(0.009, -0.003), (0.009, 0.016)], "trim", f, n=10, cap_start="trim", cap_end="trim")
            p.prism(star(0, 0, 0.028, 0.025, n=21, rot=0.0), 0.014, 0.03, "side", f, chamfer=0.002)
            p.lathe([(0.0, 0.03), (0.02, 0.03), (0.018, 0.032), (0.0, 0.032)], "accent", f, n=16)
    elif h == "pi":                      # a wooden pi sign as the pull
        f = _face()
        p.prism([Vector(q) for q in ((-0.075, 0.024, 0), (0.07, 0.024, 0), (0.075, 0.03, 0),
                                     (0.07, 0.042, 0), (-0.06, 0.042, 0), (-0.08, 0.034, 0))],
                0.014, 0.032, "trim", f, chamfer=0.003)
        p.prism([Vector(q) for q in ((-0.044, -0.05, 0), (-0.028, -0.05, 0), (-0.024, 0.03, 0),
                                     (-0.04, 0.03, 0))], 0.014, 0.032, "trim", f, chamfer=0.003)
        p.prism([Vector(q) for q in ((0.022, 0.03, 0), (0.038, 0.03, 0), (0.036, -0.03, 0),
                                     (0.052, -0.044, 0), (0.044, -0.054, 0), (0.022, -0.036, 0))],
                0.014, 0.032, "trim", f, chamfer=0.003)
        for x in (-0.034, 0.03):
            p.lathe([(0.008, -0.003), (0.008, 0.016)], "trim", _face(x, 0, 0.0), n=8,
                    cap_start="trim", cap_end="trim")
    elif h == "slot":                    # a dark pocket with a slim bar and a cyan light strip
        p.rounded_box(0.32, 0.06, -0.003, 0.005, 0.012, 0.0, 0.002, "trim", _face(), seg=3)
        for sx in (-1, 1):
            p.lathe([(0.007, 0.0), (0.007, 0.016)], "side", _face(sx * 0.11), n=8,
                    cap_start="side", cap_end="side")
        p.rounded_box(0.27, 0.024, 0.012, 0.026, 0.01, 0.003, 0.004, "side", _face(), seg=4, seg_round=2)
        p.rounded_box(0.22, 0.006, 0.025, 0.029, 0.003, 0.0, 0.001, "accent", _face(), seg=2, seg_round=1)
    elif h == "wheels":                  # little steering wheels
        for sx in (-1, 1):
            f = _face(sx * 0.33)
            p.lathe([(0.008, -0.003), (0.008, 0.022)], "accent", f, n=8, cap_start="accent")
            p.sweep(fam.circle(0.03, 24), 0.0065, "trim", matrix=f @ Matrix.Translation((0, 0, 0.026)), n=8)
            p.ellipsoid((0, 0, 0.026), 0.012, 0.012, 0.008, "side", u=10, v=5, matrix=f)
            for k in range(3):
                a = math.pi / 2 + k * 2 * math.pi / 3
                rot = f @ Matrix.Translation((0, 0, 0.026)) @ Matrix.Rotation(a, 4, "Z")
                p.prism([Vector((0.008, -0.004, 0)), Vector((0.028, -0.004, 0)), Vector((0.028, 0.004, 0)),
                         Vector((0.008, 0.004, 0))], -0.003, 0.003, "trim", rot)
    elif h == "gears":                   # cog knobs in hazard yellow on steel hubs
        for sx in (-1, 1):
            f = _face(sx * 0.33)
            p.lathe([(0.01, -0.003), (0.01, 0.016)], "accent", f, n=10, cap_start="accent", cap_end="accent")
            p.prism(gear(0.034, 0.026, 10), 0.014, 0.03, "trim", f, chamfer=0.002)
            p.lathe([(0.0, 0.029), (0.011, 0.029), (0.011, 0.036), (0.0, 0.036)], "accent", f, n=12)


def make_drawer(t, name):
    p = Part()
    make_front(p, t, name)
    make_tray(p)
    make_handles(p, t)
    return p


# --- Build -------------------------------------------------------------------------------------

def build_parts(name, root, mats):
    """The four meshes and 25 slots of `name`'s kit under `root`; returns the parts by name."""
    t = THEMES[name]
    parts = {
        "base": make_base(t).finish("base", root, mats=mats),
        "segment": make_segment(t, name).finish("segment", root, mats=mats),
        "drawer": make_drawer(t, name).finish("drawer", root, mats=mats),
        "top": make_top(t).finish("top", root, mats=mats),
    }
    # Each part is built in its own space (origin at its bottom): stand it at its place.
    parts["segment"].location = (0, 0, BASE_H)
    parts["drawer"].location = (0, 0, BASE_H + DRAWER_Z)
    parts["top"].location = (0, 0, BASE_H + SEG_H)
    for i, (x, y, z) in enumerate(slot_positions()):
        e = bpy.data.objects.new("slot_%02d" % (i + 1), None)
        e.empty_display_size = BALL_R
        e.empty_display_type = "SPHERE"
        e.location = (x, y, z)
        bpy.context.scene.collection.objects.link(e)
        e.parent = parts["drawer"]
    return parts


def build(name):
    """Wipes the open file and builds `name`'s Cabinet (meshes, materials, the front art and the
    slots; no colliders: the game keeps its own collision, Q2152); returns a one-line report."""
    fam.wipe()
    for im in list(bpy.data.images):
        bpy.data.images.remove(im)
    asset = "cabinet_" + name
    root = fam.root(asset)
    parts = build_parts(name, root, theme_materials(name))
    us = bpy.context.scene.unit_settings
    us.system, us.scale_length, us.length_unit = "METRIC", 1.0, "METERS"
    return "%s: %s" % (asset, ", ".join(sorted(parts)))


def build_all(src_dir, names=None):
    """Builds and saves <src_dir>/cabinet_<name>.blend for every theme (or `names`)."""
    out = []
    for name in names or THEMES:
        out.append(build(name))
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(src_dir, "cabinet_%s.blend" % name),
                                    compress=True)
    return "\n".join(out)


# --- Previews ----------------------------------------------------------------------------------

def _ball(rnd, loc):
    me = bpy.data.meshes.new("_ball")
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=14, v_segments=8, radius=BALL_R)
    bm.to_mesh(me)
    bm.free()
    for poly in me.polygons:
        poly.use_smooth = True
    col = tuple(rnd.uniform(0.25, 0.9) for _ in range(3)) + (1.0,)
    m = bpy.data.materials.new("_ball")
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Base Color"].default_value = col
    m.diffuse_color = col
    me.materials.append(m)
    ob = bpy.data.objects.new("_ball", me)
    ob.location = loc
    bpy.context.scene.collection.objects.link(ob)


def stage(names, gap=1.85, pulled=True, balls=True):
    """A throwaway scene (never saved): each named Cabinet stood at its full Rows, side by side,
    its top Drawer pulled out with 25 stand-in balls on the slots."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    rnd = random.Random(3)
    for k, name in enumerate(names):
        dx = (k - (len(names) - 1) / 2) * gap
        mats = theme_materials(name)
        root = bpy.data.objects.new("_kit", None)
        bpy.context.scene.collection.objects.link(root)
        parts = build_parts(name, root, mats)
        n = THEMES[name]["drawers"]

        def inst(src, z, y=0.0):
            o = bpy.data.objects.new(src.name + "_i", src.data)
            o.location = (dx, y, z)
            bpy.context.scene.collection.objects.link(o)
        inst(parts["base"], 0.0)
        for i in range(n):
            z = BASE_H + i * SEG_H
            inst(parts["segment"], z)
            out = -0.40 if pulled and i == n - 1 else 0.0
            inst(parts["drawer"], z + DRAWER_Z, out)
            if balls and pulled and i == n - 1:
                for sx, sy, sz in slot_positions():
                    _ball(rnd, (dx + sx, sy + out, z + DRAWER_Z + sz))
        inst(parts["top"], BASE_H + n * SEG_H)
        for o in list(parts.values()):
            for c in o.children:
                bpy.data.objects.remove(c, do_unlink=True)
            bpy.data.objects.remove(o, do_unlink=True)
        bpy.data.objects.remove(root, do_unlink=True)


def render(path, cam, target, size, lens=40, final=False):
    """Renders the open scene: Workbench (textures shown, back faces culled, so a flipped face
    shows as a hole), or EEVEE with a floor, a sun and a soft sky with `final`."""
    scene = bpy.context.scene
    c = bpy.data.objects.new("_cam", bpy.data.cameras.new("_cam"))
    c.data.lens = lens
    c.location = cam
    c.rotation_euler = (Vector(target) - Vector(cam)).to_track_quat("-Z", "Y").to_euler()
    scene.collection.objects.link(c)
    scene.camera = c
    r = scene.render
    r.resolution_x, r.resolution_y = size
    r.resolution_percentage = 100
    scene.view_settings.view_transform = "Standard"
    floor = bpy.data.meshes.new("_floor")
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=30)
    bm.to_mesh(floor)
    bm.free()
    fm = bpy.data.materials.new("_floor")
    fcol = fam.srgb("#d8c8b8")
    next(n for n in fm.node_tree.nodes if n.type == "BSDF_PRINCIPLED").inputs["Base Color"].default_value = fcol
    fm.diffuse_color = fcol
    floor.materials.append(fm)
    scene.collection.objects.link(bpy.data.objects.new("_floor", floor))
    if final:
        try:
            r.engine = "BLENDER_EEVEE"
        except TypeError:
            r.engine = "BLENDER_EEVEE_NEXT"
        world = bpy.data.worlds.new("_w")
        world.use_nodes = True
        bg = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
        bg.inputs[0].default_value = fam.srgb("#d9cfc4")
        bg.inputs[1].default_value = 0.9
        scene.world = world
        sun = bpy.data.objects.new("_sun", bpy.data.lights.new("_sun", "SUN"))
        sun.data.energy = 3.0
        sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(-35))
        scene.collection.objects.link(sun)
    else:
        r.engine = "BLENDER_WORKBENCH"
        sh = scene.display.shading
        sh.light = "STUDIO"
        sh.color_type = "TEXTURE"
        sh.show_backface_culling = True
    r.filepath = path
    bpy.ops.render.render(write_still=True)
    return "RENDER %s %dx%d" % (path, size[0], size[1])


NEW = ["nature", "fruit", "vegetables", "drinks", "math", "tech", "transport", "machinery"]


def lineup(path, final=False, size=(1200, 360), names=None):
    """All the Cabinets (or `names`) at their full Rows, the top Drawer pulled out, in a row."""
    if names is None:
        stage(list(THEMES))
        return render(path, (0.0, -17.0, 3.4), (0.0, 0.0, 0.85), size, lens=40, final=final)
    stage(names)
    dist = 1.85 * len(names) * 1.2
    return render(path, (0.0, -dist, dist * 0.16), (0.0, 0.0, 0.55), size, lens=40, final=final)


def front_view(name, path, final=False, size=(400, 300)):
    """One Cabinet closed, from a little right of the front and above: its handles and crest."""
    stage([name], pulled=False, balls=False)
    h = BASE_H + THEMES[name]["drawers"] * SEG_H + TOP_H
    return render(path, (0.7, -2.6, h + 0.75), (0.0, 0.0, h * 0.62), size, lens=40, final=final)


def closeup(name, path, final=False, size=(480, 540)):
    """One Cabinet from the front-right and above, its top Drawer out with stand-in balls."""
    stage([name])
    h = BASE_H + THEMES[name]["drawers"] * SEG_H + TOP_H
    n = THEMES[name]["drawers"]
    return render(path, (1.1, -2.2, h + 1.5), (0.0, -0.3, h * 0.55), size,
                  lens=30 if n > 3 else 36, final=final)
