"""The encyclopedia book's model (assets/17), ported from the old game's tools/blender/make_encyclopedia_book.py
(reference/it-socks, tag v0.1.1): the house's one shared Sock encyclopedia, a small chunky hardback that lies on the
workshop's workbench and is carried in the Hands. Oxblood cloth boards with dark leather corners, a rounded leather
spine with brass bands, a brass frame and sock emblem on the front cover, a cream page block with a slightly hollow
fore-edge and a pink ribbon bookmark that hangs out at the bottom and lies on the table.

Run from the repository root (Blender is the kit's pinned one, kit/tools/blender.sh):

    ~/tools/blender/blender -b -P tools/blender/encyclopedia_book.py -- [--save] [--no-export] [--out <dir>]

It builds the book from scratch (build() is safe to re-run in an open file), writes
`assets/encyclopedia_book/encyclopedia_book.glb` (under `--out` when given) and with `--save` the source
`assets_src/blender/encyclopedia_book/encyclopedia_book.blend`. Last line: `PASS encyclopedia_book ...` or `FAIL ...`.

Blender frame: lying closed, front cover up (+Z), the spine on the left (-X), the book's foot (where the ribbon hangs
out) to the front (-Y), so in Godot the foot faces +Z. Under the root `encyclopedia_book` (only its children are
exported):
  binding       the back board, the spine and its brass bands
  front_cover   the front board with its corners, frame and emblem; its origin is the spine hinge
  pages         the page block
  ribbon        the bookmark

What differs from the old script (technical only, Q2153): the brass and the ribbon's pink are named `brass` and `pink`,
the shared library's materials (game/materials, Q2177), which the glb's import swaps in; no collider box (collision is
the entity scene's, assets_src/generate/README.md); the palette helpers it needs from appliance_family are the ones
here; the export is built in.
"""

import math

import bmesh
import os
import sys

import bpy
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, os.path.join(REPO, "assets_src", "generate", "cabinet"))
import appliance_family as fam  # noqa: E402

ASSET = "encyclopedia_book"
GLB = os.path.join("assets", "encyclopedia_book", "encyclopedia_book.glb")
SOURCE = os.path.join("assets_src", "blender", "encyclopedia_book", "encyclopedia_book.blend")
W = 0.19       # across, spine to fore-edge (x)
L = 0.25       # head to foot (y)
T = 0.05       # thickness, closed (z)
BOARD = 0.004  # a board's thickness
OVER = 0.004   # how far the boards stand out past the pages
BULGE = 0.012  # how far the rounded spine bulges out of the boards' line (x)
HINGE_X = -W / 2 + BULGE  # where the boards meet the spine

COLOURS = {
    "cloth": "#7A2E2A",    # oxblood cloth boards
    "leather": "#3B2620",  # dark brown spine and corners
    "brass": "#DBAD5C",    # the house's brass: frame, emblem, spine bands
    "paper": "#F2E6C9",    # cream page block
    "pink": "#EB998C",   # the sock creature's pink
}
FINISH = {"cloth": (0.0, 0.85), "leather": (0.0, 0.55), "brass": (0.8, 0.3),
          "paper": (0.0, 0.9), "pink": (0.0, 0.6)}


def material(name):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    col = fam.srgb(COLOURS[name])
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Base Color"].default_value = col
    b.inputs["Metallic"].default_value, b.inputs["Roughness"].default_value = FINISH[name]
    m.diffuse_color = col
    m.metallic, m.roughness = FINISH[name]
    return m


class Mesh:
    """Pieces gathered into one bmesh, each with a material index."""

    def __init__(self, name, mats):
        self.name, self.mats = name, list(mats)
        self.bm = bmesh.new()

    def prism_y(self, prof, y0, y1, mat, smooth=False):
        """A closed XZ profile (counter-clockwise seen from -Y) swept from y0 to y1."""
        bm = self.bm
        a = [bm.verts.new((x, y0, z)) for x, z in prof]
        b = [bm.verts.new((x, y1, z)) for x, z in prof]
        n = len(prof)
        faces = [bm.faces.new(a[::-1]), bm.faces.new(b)]
        for i in range(n):
            j = (i + 1) % n
            f = bm.faces.new((a[i], a[j], b[j], b[i]))
            f.smooth = smooth
            faces.append(f)
        idx = self.mats.index(mat)
        for f in faces:
            f.material_index = idx
        return faces

    def prism_z(self, prof, z0, z1, mat):
        """A closed XY outline (counter-clockwise from above) standing from z0 to z1."""
        bm = self.bm
        a = [bm.verts.new((x, y, z0)) for x, y in prof]
        b = [bm.verts.new((x, y, z1)) for x, y in prof]
        n = len(prof)
        faces = [bm.faces.new(a[::-1]), bm.faces.new(b)]
        for i in range(n):
            j = (i + 1) % n
            faces.append(bm.faces.new((a[i], a[j], b[j], b[i])))
        idx = self.mats.index(mat)
        for f in faces:
            f.material_index = idx

    def box(self, lo, hi, mat):
        (x0, y0, z0), (x1, y1, z1) = lo, hi
        self.prism_z([(x0, y0), (x1, y0), (x1, y1), (x0, y1)], z0, z1, mat)

    def finish(self, parent, location=(0.0, 0.0, 0.0)):
        bmesh.ops.recalc_face_normals(self.bm, faces=self.bm.faces[:])
        me = bpy.data.meshes.new(self.name)
        self.bm.to_mesh(me)
        self.bm.free()
        for m in self.mats:
            me.materials.append(material(m))
        ob = bpy.data.objects.new(self.name, me)
        bpy.context.scene.collection.objects.link(ob)
        ob.parent = parent
        ob.location = location
        return ob


def ellipse_arc(cx, cz, rx, rz, a0, a1, n):
    return [(cx + rx * math.cos(a0 + (a1 - a0) * i / n), cz + rz * math.sin(a0 + (a1 - a0) * i / n))
            for i in range(n + 1)]


def spine_profile(grow=0.0, thick=BOARD, n=10):
    """The spine's C section round the left side, `grow` out of the leather, `thick` deep."""
    outer = ellipse_arc(HINGE_X, T / 2, BULGE + grow, T / 2, math.pi / 2, 3 * math.pi / 2, n)
    inner = ellipse_arc(HINGE_X, T / 2, BULGE + grow - thick, T / 2 - thick, 3 * math.pi / 2,
                        math.pi / 2, n)
    # outer runs top -> left -> bottom, inner back up; it never grows past the boards' faces
    return outer + inner


def sock_outline(cx, cy, h):
    """The emblem: a sock standing on its heel, toe to +X, `h` tall, centred at (cx, cy)."""
    pts = [(0.0, 1.0), (0.0, 0.32), (0.03, 0.14), (0.12, 0.03), (0.26, 0.0), (0.66, 0.0),
           (0.78, 0.03), (0.84, 0.11), (0.83, 0.2), (0.76, 0.27), (0.56, 0.32), (0.45, 0.39),
           (0.42, 0.5), (0.42, 1.0)]
    w = 0.84
    return [(cx + (x - w / 2) * h, cy + (y - 0.5) * h) for x, y in pts]


def front_board(m, z0, hinge):
    """The front board and its trim, in the hinge's frame (origin at (HINGE_X, 0, z0))."""
    x0, x1 = 0.0 - 0.002, W / 2 - HINGE_X
    t = BOARD
    m.box((x0, -L / 2, 0.0), (x1, L / 2, t), "cloth")
    top = t
    # leather corners on the fore-edge side
    c = 0.032
    for sy in (-1, 1):
        y = sy * L / 2
        tri = [(x1 + 0.0006, y + sy * 0.0006), (x1 + 0.0006, y - sy * c), (x1 - c, y + sy * 0.0006)]
        if sy > 0:
            tri = tri[::-1]
        m.prism_z(tri, -0.0006, top + 0.0007, "leather")
    # brass frame, inset
    ins, bw, bh = 0.013, 0.0028, 0.0006
    fx0, fx1 = x0 + 0.012, x1 - ins
    fy0, fy1 = -L / 2 + ins, L / 2 - ins
    m.box((fx0, fy0, top), (fx1, fy0 + bw, top + bh), "brass")
    m.box((fx0, fy1 - bw, top), (fx1, fy1, top + bh), "brass")
    m.box((fx0, fy0 + bw, top), (fx0 + bw, fy1 - bw, top + bh), "brass")
    m.box((fx1 - bw, fy0 + bw, top), (fx1, fy1 - bw, top + bh), "brass")
    mid_x = (fx0 + fx1) / 2
    # the emblem and two title lines under it
    m.prism_z(sock_outline(mid_x, 0.03, 0.075), top, top + 0.0009, "brass")
    # two cloth stripes across the emblem's cuff, read as tooled lines
    sx = mid_x - 0.42 * 0.075  # the leg's left edge
    for v in (0.78, 0.88):
        y = 0.03 + (v - 0.5) * 0.075
        m.box((sx - 0.0004, y - 0.0018, top + 0.0009), (sx + 0.42 * 0.075 + 0.0004, y + 0.0018, top + 0.001),
              "cloth")
    m.box((mid_x - 0.04, -0.036, top), (mid_x + 0.04, -0.031, top + bh), "brass")
    m.box((mid_x - 0.026, -0.05, top), (mid_x + 0.026, -0.046, top + bh), "brass")


def back_board(m):
    x0, x1 = HINGE_X - 0.002, W / 2
    m.box((x0, -L / 2, 0.0), (x1, L / 2, BOARD), "cloth")
    c = 0.032
    for sy in (-1, 1):
        y = sy * L / 2
        tri = [(x1 + 0.0006, y + sy * 0.0006), (x1 + 0.0006, y - sy * c), (x1 - c, y + sy * 0.0006)]
        if sy > 0:
            tri = tri[::-1]
        m.prism_z(tri, 0.0, BOARD + 0.0006, "leather")


def pages(m):
    x0, x1 = HINGE_X - 0.004, W / 2 - OVER
    z0, z1 = BOARD, T - BOARD
    n = 6
    fore = [(x1 - 0.003 * math.sin(math.pi * i / n), z0 + (z1 - z0) * i / n) for i in range(n + 1)]
    prof = [(x0, z0)] + fore + [(x0, z1)]
    m.prism_y(prof, -L / 2 + OVER, L / 2 - OVER, "paper")


def ribbon(m):
    """From inside the page block's foot, out and down onto the table, with a V-cut end."""
    w, h = 0.009, 0.0007
    x = -0.035
    yf = -L / 2 + OVER
    path = [(yf + 0.01, T * 0.62), (yf - 0.004, T * 0.6), (yf - 0.012, T * 0.42), (yf - 0.017, T * 0.2),
            (yf - 0.021, 0.006), (yf - 0.028, 0.0), (yf - 0.05, 0.0)]
    bm = m.bm
    rows = []
    for i, (y, z) in enumerate(path):
        a = Vector(path[max(i - 1, 0)])
        b = Vector(path[min(i + 1, len(path) - 1)])
        t = (b - a).normalized()
        nrm = Vector((-t.y, t.x))  # up, for a path running toward -y
        if nrm.y < 0:
            nrm = -nrm
        tip = 0.006 if i == len(path) - 1 else 0.0
        row = []
        for dx, dy in ((-w / 2, -tip), (w / 2, -tip)):
            for k in (0.0, h):
                row.append(bm.verts.new((x + dx, y + dy + 0.0, z + nrm.y * k)))
        rows.append(row)
    # the V notch: pull the end's middle back in
    last = rows[-1]
    mid = [bm.verts.new((x, path[-1][0] + 0.002, k)) for k in (0.0, h)]
    idx = m.mats.index("pink")
    faces = []
    for r0, r1 in zip(rows, rows[1:]):
        # r: [left-bottom, left-top, right-bottom, right-top]
        faces.append(bm.faces.new((r0[1], r0[3], r1[3], r1[1])))  # top
        faces.append(bm.faces.new((r0[0], r1[0], r1[2], r0[2])))  # bottom
        faces.append(bm.faces.new((r0[0], r0[1], r1[1], r1[0])))  # left
        faces.append(bm.faces.new((r0[2], r1[2], r1[3], r0[3])))  # right
    f = rows[0]
    faces.append(bm.faces.new((f[0], f[2], f[3], f[1])))
    lb, lt, rb, rt = last
    mb, mt = mid
    faces += [bm.faces.new((lt, rt, mt)), bm.faces.new((lb, mb, rb)),
              bm.faces.new((lb, lt, mt, mb)), bm.faces.new((mb, mt, rt, rb))]
    for fc in faces:
        fc.material_index = idx


def binding(m):
    back_board(m)
    m.prism_y(spine_profile(), -L / 2, L / 2, "leather", smooth=True)
    # raised bands across the spine, and its brass rules near head and foot
    for y, mat in ((-0.085, "brass"), (-0.03, "leather"), (0.03, "leather"), (0.085, "brass"),
                   (-0.1, "brass"), (0.1, "brass")):
        hw = 0.0022 if mat == "brass" else 0.003
        m.prism_y(spine_profile(0.0012, BOARD + 0.0012, 7), y - hw, y + hw, mat, smooth=True)


def build():
    fam.wipe()
    asset_root = fam.root(ASSET)
    b = Mesh("binding", ["leather", "cloth", "brass"])
    binding(b)
    b.finish(asset_root)
    p = Mesh("pages", ["paper"])
    pages(p)
    p.finish(asset_root)
    r = Mesh("ribbon", ["pink"])
    ribbon(r)
    r.finish(asset_root)
    f = Mesh("front_cover", ["cloth", "leather", "brass"])
    front_board(f, T - BOARD, True)
    f.finish(asset_root, location=(HINGE_X, 0.0, T - BOARD))
    for ob in asset_root.children:
        if ob.name in ("binding", "front_cover"):
            bev = ob.modifiers.new("bevel", "BEVEL")
            bev.width, bev.segments, bev.limit_method = 0.0006, 1, "ANGLE"
    tris = 0
    dg = bpy.context.evaluated_depsgraph_get()
    for ob in asset_root.children:
        if ob.type == "MESH" and True:
            me = ob.evaluated_get(dg).to_mesh()
            me.calc_loop_triangles()
            tris += len(me.loop_triangles)
            ob.evaluated_get(dg).to_mesh_clear()
    return "render_tris=%d" % tris


def export(out_root):
    """The root's children (not the root) to the glb: +Y up, modifiers applied."""
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
    print("PASS encyclopedia_book " + " | ".join(said))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:  # a crash is a failure, never a silent pass
        import traceback
        traceback.print_exc()
        print("FAIL encyclopedia_book: %s" % e)
        sys.exit(1)
