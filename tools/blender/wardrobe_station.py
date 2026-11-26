"""The Wardrobe Station's model (assets/20), ported from the old game's tools/blender/make_wardrobe_station.py
(reference/it-socks, tag v0.1.1): the parents' oak wardrobe on the bedroom's west wall. An oak carcass on a dark-wood
plinth with an arched apron and turned feet, a stepped oak and dark-wood crown, two cream doors with two raised panels
each, brass bar handles at the meeting edges and brass hinge knuckles at the outer edges. Inside, pale birch: a shelf
of folded clothes and a hat box, a brass rail of hanging garments on wooden hangers, a pair of slippers on the floor.

Run from the repository root (Blender is the kit's pinned one, kit/tools/blender.sh):

    kit/tools/blender.sh -b -P tools/blender/wardrobe_station.py -- [--save] [--no-export] [--out <dir>]

It builds the wardrobe from scratch, writes `assets/wardrobe_station/wardrobe_station.glb` (under `--out` when given)
and with `--save` the source `assets_src/blender/wardrobe_station/wardrobe_station.blend`. Last line:
`PASS wardrobe_station ...` or `FAIL ...`.

Blender metres, the front facing -Y (in Godot +Z), the origin at the bottom centre of the carcass (the handles and the
crown stand out in front). 1.0 wide, 0.56 deep, 1.92 tall. Under the root `wardrobe_station` (only its children are
exported; Godot space = Blender (x, z, -y)):
  body          every still piece: carcass, plinth, crown, the inside and its clothes
  door_left     the left door seen from the front (-X); its origin is its hinge at Blender (-0.496, -0.258, 0.09),
                Godot (-0.496, 0.09, 0.258); it opens by turning -80 degrees about the up axis
  door_right    the right door (+X), hinge at Blender (0.496, -0.258, 0.09); it opens by +80 degrees
The Looks scene (game/entities/wardrobe_station/looks_wardrobe_station.tscn) turns the doors in its `open` and `shut`
clips.

Materials (six): oak, dark_wood, brass (the shared library's, game/materials, which the glb's import swaps in, Q2177),
cream (the doors), birch (the inside), fabric (the clothes: one 64 x 8 palette texture embedded in the glb, each
garment's faces mapped to one 8 px cell).

What differs from the old script (technical only, Q2153): no collider box (collision is the entity scene's,
assets_src/generate/README.md); the export is built in (the root's children only); the old Blender line-up render is
left out (the line-up is taken in Godot, tools/wardrobe_station_still.tscn); the loose fabric palette PNG the old export
wrote beside the glb is not written (nothing read it; the palette is embedded).
"""

import math
import os
import sys

import bpy
import bmesh
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, os.path.join(REPO, "assets_src", "generate", "cabinet"))
import appliance_family as fam  # noqa: E402

ASSET = "wardrobe_station"
GLB = os.path.join("assets", "wardrobe_station", "wardrobe_station.glb")
SOURCE = os.path.join("assets_src", "blender", "wardrobe_station", "wardrobe_station.blend")
# --- Size (the flat's, make_flat.py) ---------------------------------------------------------
W, D, H = 1.0, 0.56, 1.92
T = 0.025                  # board thickness
DT = 0.022                 # door thickness
PLINTH = 0.08              # the bottom board's underside
TOP = H - 0.07             # the top board's top; the crown sits on it
FY = -D / 2 + DT           # the carcass's front (the doors lie in front of it)
BACK = D / 2
DOOR_Z0, DOOR_Z1 = PLINTH + 0.01, TOP - 0.01
HINGE_X = W / 2 - 0.004    # the doors' outer edges (their hinges)
MEET = 0.002               # half the gap between the doors
SHELF = 1.5                # the shelf's top
RAIL_Z = SHELF - 0.09

MATS = ["oak", "dark_wood", "cream", "birch", "brass", "fabric"]
COLOURS = {  # sRGB, the house style's (house_furniture/fkit.py, make_flat.py)
    "oak": ("#CC9157", 0.6, 0.0),
    "dark_wood": ("#784A29", 0.5, 0.0),
    "cream": ("#EDD6A8", 0.75, 0.0),
    "birch": ("#F2E3C6", 0.7, 0.0),
    "brass": ("#DBAD5C", 0.3, 0.85),
}
# The fabric palette: one 8 px cell each, left to right.
FABRIC = ["#8CB8D9", "#F2B359", "#7394B8", "#EB998C", "#99AD85", "#F7F0E0", "#9D7FA6", "#CC5747"]
FAB = {k: i for i, k in enumerate(["sky", "mustard", "blue", "pink", "sage", "linen", "plum", "red"])}


# --- Outlines ----------------------------------------------------------------------------------

def _area(pts):
    return sum(pts[i].x * pts[(i + 1) % len(pts)].y - pts[(i + 1) % len(pts)].x * pts[i].y
               for i in range(len(pts))) / 2


def ccw(pts):
    pts = [Vector((p[0], p[1], 0)) for p in pts]
    return pts if _area(pts) > 0 else list(reversed(pts))


def offset(pts, d):
    """A convex-ish outline moved out by d (in by -d), along the corners' bisectors."""
    out = []
    n = len(pts)
    for i in range(n):
        a, b, c = pts[i - 1], pts[i], pts[(i + 1) % n]
        e1 = (b - a).normalized()
        e2 = (c - b).normalized()
        n1 = Vector((e1.y, -e1.x, 0))
        n2 = Vector((e2.y, -e2.x, 0))
        m = (n1 + n2)
        m = m.normalized() if m.length > 1e-6 else n1
        out.append(b + m * (d / max(m.dot(n1), 0.3)))
    return out


# --- Part: one mesh from pieces, each in one material -------------------------------------------

class Part:
    def __init__(self):
        self.bm = bmesh.new()
        self.uv = self.bm.loops.layers.uv.new("uv")

    def _face(self, verts, mat):
        """`mat` is a material name, or ("fabric", <palette key>)."""
        cell = None
        if isinstance(mat, tuple):
            mat, key = mat
            cell = FAB[key]
        f = self.bm.faces.new(verts)
        f.material_index = MATS.index(mat)
        uv = ((cell + 0.5) / len(FABRIC), 0.5) if cell is not None else (0.0, 0.0)
        for loop in f.loops:
            loop[self.uv].uv = uv
        return f

    def strip(self, rings, mat, close_path=False, cap_start=None, cap_end=None):
        verts = [[self.bm.verts.new(p) for p in ring] for ring in rings]
        n = len(rings[0])
        faces = []
        pairs = list(zip(verts, verts[1:])) + ([(verts[-1], verts[0])] if close_path else [])
        for a, b in pairs:
            for i in range(n):
                j = (i + 1) % n
                faces.append(self._face((a[i], a[j], b[j], b[i]), mat))
        if cap_start is not None and not close_path:
            faces.append(self._face(list(reversed(verts[0])), cap_start))
        if cap_end is not None and not close_path:
            faces.append(self._face(verts[-1], cap_end))
        bmesh.ops.recalc_face_normals(self.bm, faces=faces)
        return faces

    def rounded_box(self, x0, x1, y0, y1, z0, z1, r, mat, r_z=None, seg=2, seg_round=1, matrix=None):
        """An axis box x0..x1, y0..y1, z0..z1 rounded by r in plan and r_z (default r) at its bottom
        and top edges."""
        rz = r if r_z is None else r_z
        w, d = x1 - x0, y1 - y0
        rz = min(rz, (z1 - z0) / 2 - 1e-4)
        prof = []
        if rz > 1e-4:
            for k in range(seg_round + 1):
                a = math.pi / 2 * k / seg_round
                prof.append((z0 + rz * (1 - math.cos(a)), rz * (1 - math.sin(a))))
            for k in range(seg_round + 1):
                a = math.pi / 2 * k / seg_round
                prof.append((z1 - rz * (1 - math.sin(a)), rz * (1 - math.cos(a))))
        else:
            prof = [(z0, 0.0), (z1, 0.0)]
        m = (matrix or Matrix()) @ Matrix.Translation(((x0 + x1) / 2, (y0 + y1) / 2, 0))
        rings = [[m @ Vector((p.x, p.y, z)) for p in fam.rounded_rect(w - 2 * i, d - 2 * i, max(r - i, 0.0006), seg)]
                 for z, i in prof]
        return self.strip(rings, mat, cap_start=mat, cap_end=mat)

    def box(self, x0, x1, y0, y1, z0, z1, mat):
        return self.rounded_box(x0, x1, y0, y1, z0, z1, 0.0006, mat, r_z=0.0, seg=1)

    def prism(self, outline, z0, z1, mat, matrix=None, chamfer=0.0):
        o = ccw(outline)
        m = matrix or Matrix()
        if chamfer > 0:
            inner = offset(o, -chamfer)
            layers = [(inner, z0), (o, z0 + chamfer), (o, z1 - chamfer), (inner, z1)]
        else:
            layers = [(o, z0), (o, z1)]
        rings = [[m @ Vector((p.x, p.y, z)) for p in ring] for ring, z in layers]
        return self.strip(rings, mat, cap_start=mat, cap_end=mat)

    def lathe(self, profile, mat, matrix=None, n=12, cap_start=None, cap_end=None):
        m = matrix or Matrix()
        rings = [[m @ Vector((r * math.cos(2 * math.pi * k / n), r * math.sin(2 * math.pi * k / n), h))
                  for k in range(n)] for r, h in profile]
        return self.strip(rings, mat, cap_start=cap_start, cap_end=cap_end)

    def tube(self, path, radius, mat, normal=(0, 0, 1), n=8, loop=False):
        """A round tube along `path` (points in a plane with `normal`), capped when open."""
        nv = Vector(normal).normalized()
        path = [Vector(p) for p in path]
        cnt = len(path)
        rings = []
        for i, p in enumerate(path):
            a = path[(i - 1) % cnt] if loop or i > 0 else p
            b = path[(i + 1) % cnt] if loop or i < cnt - 1 else p
            side = (b - a).normalized().cross(nv).normalized()
            rings.append([p + radius * (math.cos(2 * math.pi * k / n) * side
                                        + math.sin(2 * math.pi * k / n) * nv) for k in range(n)])
        return self.strip(rings, mat, close_path=loop, cap_start=None if loop else mat,
                          cap_end=None if loop else mat)

    def turn_since(self, start, centre, angle):
        """Turns the vertices made since `start` about the vertical through `centre`."""
        self.bm.verts.ensure_lookup_table()
        m = Matrix.Translation(centre) @ Matrix.Rotation(angle, 4, "Z") @ Matrix.Translation(-centre)
        for v in self.bm.verts[start:]:
            v.co = m @ v.co

    def finish(self, name, parent, mats, location=(0, 0, 0), sharp_deg=40.0):
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
        ob.parent = parent
        return ob


# --- Materials ---------------------------------------------------------------------------------

def _palette_image():
    n = len(FABRIC)
    img = bpy.data.images.new("fabric_palette", 8 * n, 8, alpha=False)
    # Image pixels are stored in the image's colour space (sRGB): write sRGB values.
    px = []
    for _row in range(8):
        for i in range(n):
            h = FABRIC[i].lstrip("#")
            c = [int(h[k:k + 2], 16) / 255.0 for k in (0, 2, 4)] + [1.0]
            px += c * 8
    img.pixels[:] = px
    img.pack()
    return img


def materials():
    out = {}
    for name, (hexs, rough, metal) in COLOURS.items():
        m = bpy.data.materials.new(name)
        b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
        col = fam.srgb(hexs)
        b.inputs["Base Color"].default_value = col
        b.inputs["Roughness"].default_value = rough
        b.inputs["Metallic"].default_value = metal
        m.diffuse_color = col
        m.roughness, m.metallic = rough, metal
        out[name] = m
    m = bpy.data.materials.new("fabric")
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    tex = m.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = _palette_image()
    tex.interpolation = "Closest"
    tex.extension = "EXTEND"
    m.node_tree.links.new(tex.outputs["Color"], b.inputs["Base Color"])
    b.inputs["Roughness"].default_value = 0.95
    m.diffuse_color = fam.srgb("#B9A9A0")
    out["fabric"] = m
    return out


# --- The carcass, plinth and crown ---------------------------------------------------------------

def carcass(p):
    yc0, yc1 = FY, BACK
    for s in (-1, 1):
        x0, x1 = sorted((s * W / 2, s * (W / 2 - T)))
        p.rounded_box(x0, x1, yc0, yc1, PLINTH - 0.004, TOP, 0.008, "oak", r_z=0.004)
        # The birch liner on the side's inside.
        lx = s * (W / 2 - T - 0.0015)
        p.box(min(lx, lx - s * 0.003), max(lx, lx - s * 0.003), FY + 0.012, BACK - 0.016,
              PLINTH + T, TOP - T, "birch")
    p.rounded_box(-W / 2 + T - 0.002, W / 2 - T + 0.002, BACK - 0.012, BACK, PLINTH, TOP, 0.003, "oak")
    p.box(-W / 2 + T, W / 2 - T, BACK - 0.0155, BACK - 0.012, PLINTH + T, TOP - T, "birch")
    p.rounded_box(-W / 2 + T, W / 2 - T, FY, BACK - 0.012, PLINTH, PLINTH + T, 0.004, "birch")
    p.rounded_box(-W / 2 + T, W / 2 - T, FY, BACK - 0.012, TOP - T, TOP, 0.004, "birch")
    # The face frame's thin oak lips round the opening (they show between and round the doors).
    p.rounded_box(-W / 2 + T, W / 2 - T, FY - 0.004, FY + 0.01, TOP - T - 0.012, TOP, 0.003, "oak")


def plinth(p):
    """A dark-wood plinth: a box set back under the carcass, an arched apron at the front and the
    sides, four short turned feet at the corners."""
    z_top = PLINTH
    p.rounded_box(-W / 2 + 0.03, W / 2 - 0.03, FY + 0.03, BACK - 0.02, 0.0, z_top, 0.01, "dark_wood")
    # The apron: a front board with an arched underside between two feet.
    fx = W / 2 - 0.012
    out = [(-fx, z_top), (-fx, 0.012)]
    span = 2 * (fx - 0.07)
    n = 14
    for k in range(n + 1):
        u = k / n
        x = -fx + 0.07 + span * u
        out.append((x, 0.022 + 0.02 * math.sin(math.pi * u)))
    out += [(fx, 0.012), (fx, z_top)]
    out = list(reversed(out))
    front = fam.front(0, FY + 0.004, 0)
    p.prism([(x, z) for x, z in out], -0.002, 0.018, "dark_wood", matrix=front, chamfer=0.004)
    # The feet: short turned dark-wood buns at the four corners.
    for sx in (-1, 1):
        for y in (FY + 0.03, BACK - 0.04):
            prof = [(0.0005, 0.0), (0.02, 0.002), (0.028, 0.014), (0.024, 0.028), (0.026, 0.034)]
            p.lathe(prof, "dark_wood", matrix=Matrix.Translation((sx * (W / 2 - 0.045), y, 0.0)), n=10,
                    cap_end="dark_wood")


def crown(p):
    """The stepped crown: an oak lip over the carcass, a dark-wood band, a soft dark-wood cap."""
    p.rounded_box(-W / 2 - 0.02, W / 2 + 0.02, FY - 0.03, BACK, TOP - 0.004, TOP + 0.026, 0.012, "oak",
                  r_z=0.008)
    p.rounded_box(-W / 2 - 0.008, W / 2 + 0.008, FY - 0.018, BACK - 0.005, TOP + 0.024, H - 0.04, 0.008,
                  "dark_wood", r_z=0.004)
    p.rounded_box(-W / 2 - 0.035, W / 2 + 0.035, FY - 0.045, BACK, H - 0.045, H, 0.02, "dark_wood",
                  r_z=0.012, seg=4, seg_round=3)


# --- The inside --------------------------------------------------------------------------------

def inside(p):
    yc = (FY + BACK) / 2
    # The shelf, and its front lip in oak.
    p.rounded_box(-W / 2 + T, W / 2 - T, FY + 0.012, BACK - 0.016, SHELF - 0.02, SHELF, 0.004, "birch")
    p.rounded_box(-W / 2 + T, W / 2 - T, FY + 0.006, FY + 0.016, SHELF - 0.024, SHELF, 0.003, "oak")
    # The rail, on round brass brackets on the sides.
    p.tube([(-W / 2 + T, yc, RAIL_Z), (W / 2 - T, yc, RAIL_Z)], 0.011, "brass", normal=(0, 1, 0), n=10)
    for s in (-1, 1):
        x = s * (W / 2 - T - 0.002)
        p.lathe([(0.0005, 0.0), (0.024, 0.0), (0.024, 0.006), (0.014, 0.012)], "brass",
                matrix=Matrix.Translation((x, yc, RAIL_Z)) @ Matrix.Rotation(-s * math.pi / 2, 4, "Y"),
                n=12, cap_end="brass")
    garments = (( -0.36, "sky", 0.62, "shirt"), (-0.22, "mustard", 0.86, "dress"),
                (-0.07, "blue", 0.70, "coat"), (0.08, "pink", 0.56, "shirt"),
                (0.22, "sage", 0.84, "dress"), (0.36, "linen", 0.64, "shirt"))
    for i, (x, key, length, kind) in enumerate(garments):
        # Each turned a little on the rail, alternately, so the clothes read from the front.
        start = len(p.bm.verts)
        hanger(p, x, yc)
        garment(p, x, yc, RAIL_Z - 0.06, length, key, kind)
        p.turn_since(start, Vector((x, yc, 0)), math.radians(16 if i % 2 else -16))
    # Folded clothes on the shelf: three stacks, the right one striped; and a round hat box.
    for sx, keys in ((-0.31, ("linen", "linen", "sky")), (-0.05, ("blue", "blue")), (0.17, ("pink", "plum"))):
        for k, key in enumerate(keys):
            z = SHELF + 0.044 * k
            folded(p, sx, yc - 0.04, z, key)
    hat_box(p, 0.36, yc - 0.03, SHELF)
    # A pair of slippers on the floor, in red with linen cuffs.
    for dx, turn in ((-0.27, 0.12), (-0.15, -0.08)):
        slipper(p, dx, FY + 0.15, PLINTH + T, turn)


def hanger(p, x, y):
    """A wooden hanger on a brass hook: the hook over the rail, the shoulders sloping down."""
    hook = [(x, y + 0.0, RAIL_Z - 0.03), (x, y + 0.0, RAIL_Z - 0.005)]
    for k in range(7):
        a = math.pi * k / 6
        hook.append((x, y - 0.016 * math.cos(a), RAIL_Z + 0.004 + 0.016 * math.sin(a)))
    p.tube(hook, 0.0028, "brass", normal=(1, 0, 0), n=4)
    zs = RAIL_Z - 0.035
    path = [(x, y - 0.19, zs - 0.05), (x, y - 0.1, zs - 0.012), (x, y, zs), (x, y + 0.1, zs - 0.012),
            (x, y + 0.19, zs - 0.05)]
    p.tube(path, 0.0085, "dark_wood", normal=(1, 0, 0), n=6)


def garment(p, x, y, z_top, length, key, kind):
    """A garment on its hanger, seen edge-on from the front: soft rings, narrow at the neck,
    out at the shoulders, flaring for a dress, square for a coat."""
    mat = ("fabric", key)
    half = {"shirt": 0.2, "dress": 0.18, "coat": 0.22}[kind]
    thick = {"shirt": 0.035, "dress": 0.03, "coat": 0.055}[kind]
    flare = {"shirt": 1.0, "dress": 1.3, "coat": 1.05}[kind]
    prof = [(0.0, 0.25, 0.4), (0.02, 0.7, 0.8), (0.06, 1.0, 1.0), (0.35, 0.95, 1.0),
            (0.75, 0.5 + 0.5 * flare, 1.0), (0.97, 0.5 + 0.5 * flare, 0.95), (1.0, 0.45 + 0.45 * flare, 0.6)]
    rings = []
    for u, wf, tf in prof:
        z = z_top - u * length
        ring = fam.rounded_rect(2 * thick * tf, 2 * half * wf, thick * tf * 0.95, 3)
        rings.append([Vector((x + v.x, y + v.y, z)) for v in ring])
    p.strip(rings, mat, cap_start=mat, cap_end=mat)


def folded(p, x, y, z, key):
    """One folded piece of clothing: a soft slab with a rounded front fold."""
    mat = ("fabric", key)
    p.rounded_box(x - 0.11, x + 0.11, y - 0.15, y + 0.15, z + 0.001, z + 0.043, 0.02, mat, r_z=0.016)


def hat_box(p, x, y, z):
    p.lathe([(0.0005, 0.0), (0.09, 0.0), (0.092, 0.002), (0.092, 0.1)], ("fabric", "mustard"),
            matrix=Matrix.Translation((x, y, z)), n=20)
    p.lathe([(0.097, 0.095), (0.098, 0.126), (0.094, 0.13), (0.0005, 0.13)], ("fabric", "plum"),
            matrix=Matrix.Translation((x, y, z)), n=20)


def slipper(p, x, y, z, turn):
    m = Matrix.Translation((x, y, z)) @ Matrix.Rotation(turn, 4, "Z")
    rings = []
    for u, w, h in ((-0.12, 0.03, 0.02), (-0.1, 0.042, 0.045), (-0.02, 0.045, 0.05), (0.06, 0.04, 0.04),
                    (0.11, 0.028, 0.026), (0.125, 0.012, 0.012)):
        ring = fam.rounded_rect(2 * w, h, min(w, h / 2) * 0.95, 3)
        rings.append([m @ Vector((v.x, u, v.y + h / 2)) for v in ring])
    p.strip(rings, ("fabric", "red"), cap_start=("fabric", "red"), cap_end=("fabric", "red"))
    p.lathe([(0.032, 0.0), (0.036, 0.004), (0.032, 0.012)], ("fabric", "linen"),
            matrix=m @ Matrix.Translation((0, -0.07, 0.045)), n=12)


# --- The doors -----------------------------------------------------------------------------------

def door(p, s):
    """The door on side s (-1 left, +1 right), built where it stands shut: a cream slab with
    rounded edges, two raised panels framed by a fine bead, a brass bar handle by the meeting edge
    and two brass hinge knuckles at the outer edge."""
    xa, xb = s * MEET, s * HINGE_X
    x0, x1 = min(xa, xb), max(xa, xb)
    y0, y1 = FY - DT, FY
    p.rounded_box(x0, x1, y0, y1, DOOR_Z0, DOOR_Z1, 0.01, "cream", r_z=0.01)
    mid = DOOR_Z0 + (DOOR_Z1 - DOOR_Z0) * 0.36
    for a, b in ((DOOR_Z0 + 0.07, mid - 0.03), (mid + 0.03, DOOR_Z1 - 0.07)):
        cx, w = (x0 + x1) / 2, (x1 - x0) - 0.12
        # The raised panel, its edges chamfered, and an oak bead round it.
        out = fam.rounded_rect(w, b - a, 0.035, 4)
        f = fam.front(cx, y0, (a + b) / 2)
        p.prism([(v.x, v.y) for v in out], -0.002, 0.012, "cream", matrix=f, chamfer=0.006)
        bead = fam.rounded_rect(w + 0.02, b - a + 0.02, 0.045, 4)
        p.tube([f @ Vector((v.x, v.y, 0.0)) for v in bead], 0.0035, "oak", normal=(0, 1, 0), n=4, loop=True)
    # The bar handle: two round posts and a bar, by the meeting edge.
    hx = s * 0.06
    zl, zh = 0.86, 1.12
    for z in (zl, zh):
        p.lathe([(0.012, 0.0), (0.012, 0.004), (0.006, 0.008), (0.006, 0.026)], "brass",
                matrix=fam.front(hx, y0 + 0.001, z), n=10, cap_start="brass")
    p.tube([(hx, y0 - 0.033, zl - 0.02), (hx, y0 - 0.033, zh + 0.02)], 0.0095, "brass", normal=(0, 1, 0), n=10)
    # The hinge knuckles on the outer edge.
    for z in (DOOR_Z0 + 0.16, DOOR_Z1 - 0.16):
        p.lathe([(0.0055, -0.04), (0.0065, -0.036), (0.0065, 0.036), (0.0055, 0.04)], "brass",
                matrix=Matrix.Translation((xb + s * 0.002, y1 + 0.001, z)), n=8,
                cap_start="brass", cap_end="brass")
    if s > 0:
        # A brass keyhole escutcheon on the right door.
        f = fam.front(s * 0.06, y0, 0.78)
        p.prism([(0.011 * math.cos(2 * math.pi * k / 12), 0.016 * math.sin(2 * math.pi * k / 12))
                 for k in range(12)], -0.001, 0.003, "brass", matrix=f, chamfer=0.0008)


# --- Build ---------------------------------------------------------------------------------------

def build():
    """Wipes the open file and builds the Wardrobe Station; returns its triangle count."""
    fam.wipe()
    for im in list(bpy.data.images):
        bpy.data.images.remove(im)
    mats = materials()
    root = fam.root(ASSET)
    body = Part()
    carcass(body)
    plinth(body)
    crown(body)
    inside(body)
    body.finish("body", root, mats)
    for name, s in (("door_left", -1), ("door_right", 1)):
        d = Part()
        door(d, s)
        d.finish(name, root, mats, location=(s * HINGE_X, FY, DOOR_Z0))
    tris = sum(len(p.vertices) - 2 for ob in root.children if ob.type == "MESH" for p in ob.data.polygons)
    return "render_tris=%d" % tris


def export(out_root):
    """The root's children (not the root) to the glb: +Y up."""
    root = bpy.data.objects[ASSET]
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    for o in root.children_recursive:
        o.select_set(True)
    out = os.path.join(out_root, GLB)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=out, export_format="GLB", use_selection=True, export_apply=True,
        export_yup=True, export_cameras=False, export_lights=False, export_animations=False,
        export_extras=False)
    return out


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out_root = REPO
    if "--out" in argv:
        out_root = os.path.abspath(argv[argv.index("--out") + 1])
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.unit_settings.system = "METRIC"
    said = [build()]
    if "--no-export" not in argv:
        said.append("glb " + export(out_root))
    if "--save" in argv:
        path = os.path.join(REPO, SOURCE)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=path, compress=True)
        said.append("blend " + path)
    print("PASS wardrobe_station " + " | ".join(said))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:  # a crash is a failure, never a silent pass
        import traceback
        traceback.print_exc()
        print("FAIL wardrobe_station: %s" % e)
        sys.exit(1)
