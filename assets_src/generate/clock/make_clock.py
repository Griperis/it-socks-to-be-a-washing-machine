"""The wall clock's model (assets/23), ported from the old game (reference/it-socks, tag v0.1.1):
tools/blender/make_clock.py, assets/clock/clock.glb (kept by Q2709). The living room's round wall clock, whose hands
show the hour (core/161's WallClock, as the old Room._show_time). A deep oak drum with a softly rounded back edge, a
brass bezel round the front, a paper dial with a mustard chapter ring and dark minute ticks, terracotta batons at 12,
3, 6 and 9 and dark dots for the other hours, a little pink sock above 6, two charcoal spade hands and a brass centre
cap.

Run from the repository root (Blender is the kit's pinned one, kit/tools/blender.sh):

    kit/tools/blender.sh -b -P assets_src/generate/clock/make_clock.py -- [--save] [--no-export] [--out <dir>]

It builds the clock from scratch, writes `assets/clock/clock.glb` (under `--out` when given) and with `--save` the
source `assets_src/blender/clock/clock.blend`. Last line: `PASS clock ...` or `FAIL ...`.

Blender metres, the front facing -Y (in Godot +Z). The clock hangs on a wall, so its origin is the centre of its
back, on the wall: 0.36 across, 0.055 deep, the old model's size. Godot space = Blender (x, z, -y).

clock.glb, under the root `clock` (only its children are exported):
  body          the case, bezel, dial, marks and the brass cap
  hour_hand     origin on the dial centre, Godot (0, 0, 0.036); points up (12)
  minute_hand   the same; the game turns both about Godot z, a negative angle clockwise (the old _show_time)

Materials (eight): oak, brass, paper, mustard, terracotta, dark_wood, charcoal, pink: the old colours, which are the
shared library's (game/materials, the same names and colours); the glb's import swaps the library's in (Q2177).

What differs from the old script (technical only, Q2153): no collider (`case-convcolonly`, which the old game
dropped on import: the clock never collided); no asset_checks report (the kit's contract asks a standing asset's
bottom at the origin; a wall clock's origin is its back's centre); the export is built in; the Blender line-up is
left out (the line-up is taken in Godot, tools/wall_clock_still.tscn). The meshes are the old script's, unchanged.
"""

import math
import os
import sys

import bpy
import bmesh
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, os.path.join(REPO, "assets_src", "generate", "cabinet"))
import appliance_family as fam  # noqa: E402

ASSET = "clock"
GLB = os.path.join("assets", "clock", "clock.glb")
SOURCE = os.path.join("assets_src", "blender", "clock", "clock.blend")

# --- Size (the old model's, flat/28) -----------------------------------------------------------
R = 0.18                   # the case's radius
DEPTH = 0.055              # back (on the wall) to the bezel's front
DIAL_Y = -0.036            # the hands' pivot, on the dial (Godot z 0.036)
DIAL_FACE = -0.0352        # the dial's surface
DIAL_R = 0.1505
N = 36                     # segments round the case

MATS = ["oak", "brass", "paper", "mustard", "terracotta", "dark_wood", "charcoal", "pink"]
COLOURS = {  # sRGB, the house palette (house_furniture/fkit.py, style_trial/kit.py)
    "oak": ("#CC9157", 0.55, 0.0),
    "brass": ("#DBAD5C", 0.3, 0.85),
    "paper": ("#FAF5EA", 0.6, 0.0),
    "mustard": ("#F2B359", 0.5, 0.0),
    "terracotta": ("#CC734C", 0.5, 0.0),
    "dark_wood": ("#784A29", 0.6, 0.0),
    "charcoal": ("#333336", 0.4, 0.0),
    "pink": ("#EB998C", 0.8, 0.0),
}


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
    return out


def on_face(cx, cz, theta, y):
    """A frame on the clock's face: local x to the right, local y up, both turned clockwise by
    `theta` about (cx, cz); local z out of the front (Blender -Y), from depth y."""
    c, s = math.cos(theta), math.sin(theta)
    return Matrix(((c, s, 0, cx), (0, 0, -1, y), (-s, c, 0, cz), (0, 0, 0, 1)))


# --- Part: one mesh from pieces, each in one material -------------------------------------------

class Part:
    def __init__(self):
        self.bm = bmesh.new()

    def _strip(self, rings, mats, close_path=False, cap_start=None, cap_end=None):
        """Quads between consecutive rings; `mats` one material, or one per band."""
        verts = [[self.bm.verts.new(p) for p in ring] for ring in rings]
        n = len(rings[0])
        faces = []
        pairs = list(zip(verts, verts[1:])) + ([(verts[-1], verts[0])] if close_path else [])
        for k, (a, b) in enumerate(pairs):
            mi = MATS.index(mats if isinstance(mats, str) else mats[k])
            for i in range(n):
                j = (i + 1) % n
                f = self.bm.faces.new((a[i], a[j], b[j], b[i]))
                f.material_index = mi
                faces.append(f)
        for vs, cmat, rev in ((verts[0], cap_start, True), (verts[-1], cap_end, False)):
            if cmat is not None and not close_path:
                f = self.bm.faces.new(list(reversed(vs)) if rev else vs)
                f.material_index = MATS.index(cmat)
                faces.append(f)
        return faces

    @staticmethod
    def orient(faces, good, sample=None):
        """Flips the piece's faces (they share one winding) if most of `sample` (default all)
        fail `good(face)`."""
        sample = faces if sample is None else sample
        bad = sum(1 for f in sample if not good(f))
        if bad * 2 > len(sample):
            for f in faces:
                f.normal_flip()
        return faces

    def lathe(self, profile, mats, n=N, cap_start=None, cap_end=None):
        """Turns a (radius, depth out of the front) profile round the clock's axis (Blender Y)."""
        rings = [[Vector((r * math.cos(2 * math.pi * k / n), -h, r * math.sin(2 * math.pi * k / n)))
                  for k in range(n)] for r, h in profile]
        return self._strip(rings, mats, cap_start=cap_start, cap_end=cap_end)

    def slab(self, outline, z0, z1, mat, matrix, bottom=False):
        """A flat prism of an outline (local x, y) from z0 to z1 in `matrix`, no bottom unless
        asked (it lies on the dial)."""
        rings = [[matrix @ Vector((p[0], p[1], z)) for p in outline] for z in (z0, z1)]
        faces = self._strip(rings, mat, cap_start=mat if bottom else None, cap_end=mat)
        centre = matrix @ Vector((sum(p[0] for p in outline) / len(outline),
                                  sum(p[1] for p in outline) / len(outline), (z0 + z1) / 2))
        side = faces[0]
        good = (side.calc_center_median() - centre).dot(side.normal) > 0
        if not good:
            for f in faces:
                f.normal_flip()
        return faces

    def quad(self, pts, mat):
        """One flat face (on the dial) facing the front."""
        f = self.bm.faces.new([self.bm.verts.new(p) for p in pts])
        f.material_index = MATS.index(mat)
        f.normal_update()
        if f.normal.y > 0:
            f.normal_flip()
        return f

    def finish(self, name, parent, mats, location=(0, 0, 0), sharp_deg=35.0):
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


def ngon(r, n, start=0.0):
    return [(r * math.cos(start + 2 * math.pi * k / n), r * math.sin(start + 2 * math.pi * k / n)) for k in range(n)]


def stadium(w, h, seg=2):
    return [(p.x, p.y) for p in fam.rounded_rect(w, h, min(w, h) / 2, seg)]


# --- The case and the dial -----------------------------------------------------------------------

def case(p):
    """The oak drum (the back closed, on the wall), the brass bezel round the front lip, and the
    oak inner wall down to the dial."""
    prof = [(0.166, 0.0), (0.176, 0.0035), (R, 0.012), (R, 0.035), (0.1765, 0.0425),
            (0.1705, 0.0485), (0.1635, DEPTH), (0.1555, 0.0545), (0.1515, 0.0495), (DIAL_R - 0.0005, 0.0345)]
    mats = ["oak", "oak", "oak", "oak", "brass", "brass", "brass", "brass", "oak"]
    faces = p.lathe(prof, mats, cap_start="oak")
    # The outer wall's faces point away from the axis.
    p.orient(faces, lambda f: Vector((f.calc_center_median().x, 0, f.calc_center_median().z)).dot(f.normal) > 0,
             sample=faces[:N * 3])


def dial_marks(p):
    """The paper dial, the mustard chapter ring, the minute ticks, the hour marks and the sock."""
    face = [Vector((DIAL_R * math.cos(2 * math.pi * k / N), DIAL_FACE, DIAL_R * math.sin(2 * math.pi * k / N)))
            for k in range(N)]
    p.quad(face, "paper")
    # The chapter ring: a flat mustard band a hair above the paper.
    r0, r1, y = 0.1205, 0.1315, DIAL_FACE - 0.0004
    a = [Vector((r0 * math.cos(2 * math.pi * k / N), y, r0 * math.sin(2 * math.pi * k / N))) for k in range(N)]
    b = [Vector((r1 * math.cos(2 * math.pi * k / N), y, r1 * math.sin(2 * math.pi * k / N))) for k in range(N)]
    for i in range(N):
        j = (i + 1) % N
        p.quad((a[i], a[j], b[j], b[i]), "mustard")
    # The minute ticks across the band (not where an hour mark stands).
    for m in range(60):
        if m % 5 == 0:
            continue
        t = 2 * math.pi * m / 60
        M = on_face(0, 0, t, y - 0.0003)
        p.quad([M @ Vector(v) for v in ((-0.0011, 0.1225, 0), (0.0011, 0.1225, 0), (0.0011, 0.1295, 0),
                                        (-0.0011, 0.1295, 0))], "dark_wood")
    # The hour marks: terracotta batons at 12, 3, 6 and 9, round dark studs between.
    for h in range(12):
        t = 2 * math.pi * h / 12
        if h % 3 == 0:
            M = on_face(0, 0, t, DIAL_FACE) @ Matrix.Translation((0, 0.1005, 0))
            if h == 0:   # 12 is a pair
                for dx in (-0.0085, 0.0085):
                    p.slab([(x + dx, y) for x, y in stadium(0.0085, 0.03)], 0, 0.0022, "terracotta", M)
            else:
                p.slab(stadium(0.011, 0.026), 0, 0.0022, "terracotta", M)
        else:
            M = on_face(0.105 * math.sin(t), 0.105 * math.cos(t), 0, DIAL_FACE)
            p.slab(ngon(0.0058, 8, math.pi / 8), 0, 0.0018, "dark_wood", M)
    # A little pink sock above 6, the game's own mark: the leg, the foot with its toe to the right,
    # and a terracotta cuff band.
    sock = [(-0.0075, 0.0115), (0.0045, 0.0115), (0.0045, 0.002), (0.0100, -0.0005), (0.0140, -0.0045),
            (0.0145, -0.0095), (0.0110, -0.0130), (-0.0010, -0.0135), (-0.0060, -0.0115), (-0.0075, -0.0065)]
    cuff = [(-0.0085, 0.011), (0.0055, 0.011), (0.0055, 0.0175), (-0.0085, 0.0175)]
    at = on_face(-0.003, -0.060, 0, DIAL_FACE) @ Matrix.Scale(1.3, 4)
    p.slab(sock, 0, 0.0012, "pink", at)
    p.slab(cuff, 0, 0.0014, "terracotta", at)


def cap(p):
    """The brass centre cap over the hands' hub."""
    prof = [(0.0085, -DIAL_Y + 0.0072), (0.0085, -DIAL_Y + 0.0088), (0.0066, -DIAL_Y + 0.0112),
            (0.0028, -DIAL_Y + 0.0122)]
    faces = p.lathe(prof, "brass", n=16, cap_end="brass")
    p.orient(faces, lambda f: Vector((f.calc_center_median().x, 0, f.calc_center_median().z)).dot(f.normal) > 0,
             sample=faces[:16])


# --- The hands -----------------------------------------------------------------------------------

HOUR = [(0.0, -0.027), (0.0058, -0.0235), (0.0062, -0.0165), (0.0036, -0.0105), (0.0032, 0.050),
        (0.0115, 0.0635), (0.0, 0.090), (-0.0115, 0.0635), (-0.0032, 0.050), (-0.0036, -0.0105),
        (-0.0062, -0.0165), (-0.0058, -0.0235)]
MINUTE = [(0.0, -0.031), (0.0050, -0.0275), (0.0053, -0.0195), (0.0028, -0.0125), (0.0024, 0.094),
          (0.0074, 0.1055), (0.0, 0.126), (-0.0074, 0.1055), (-0.0024, 0.094), (-0.0028, -0.0125),
          (-0.0053, -0.0195), (-0.0050, -0.0275)]


def hand(p, outline, z0, z1):
    """A flat charcoal hand pointing at 12, from z0 to z1 out of the dial (closed, it turns)."""
    p.slab(outline, z0, z1, "charcoal", on_face(0, 0, 0, DIAL_Y), bottom=True)


# --- Build and export ---------------------------------------------------------------------------

def build():
    """Wipes the open file and builds the clock; returns its triangle count."""
    fam.wipe()
    mats = materials()
    root = fam.root(ASSET)
    body = Part()
    case(body)
    dial_marks(body)
    cap(body)
    body.finish("body", root, mats)
    for name, outline, z0, z1 in (("hour_hand", HOUR, 0.0018, 0.0038), ("minute_hand", MINUTE, 0.0046, 0.0064)):
        h = Part()
        hand(h, outline, z0, z1)
        h.finish(name, root, mats, location=(0, DIAL_Y, 0))
    bpy.context.view_layer.update()
    tris = 0
    for ob in root.children_recursive:
        if ob.type == "MESH":
            ob.data.calc_loop_triangles()
            tris += len(ob.data.loop_triangles)
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
    said = []
    bpy.ops.wm.read_factory_settings(use_empty=True)
    us = bpy.context.scene.unit_settings
    us.system, us.scale_length, us.length_unit = "METRIC", 1.0, "METERS"
    said.append("clock " + build())
    if "--no-export" not in argv:
        said.append("glb " + export(out_root))
    if "--save" in argv:
        path = os.path.join(REPO, SOURCE)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=path, compress=True)
        said.append("blend " + path)
    print("PASS clock " + " | ".join(said))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:  # a crash is a failure, never a silent pass
        import traceback
        traceback.print_exc()
        print("FAIL clock: %s" % e)
        sys.exit(1)
