"""The Laundry bin's model (assets/13), ported from the old game's tools/blender/make_laundry_bin.py
(reference/it-socks, tag v0.1.1): the classic white perforated plastic hamper, a tall rounded-square
tub with a grid of holes all round between a solid base band and a solid top band, a rolled rim and a
hand hole in each end. The holes are an alpha-clip texture on one cheap surface (`Shell`, material
`white_holes`, glTF alpha MASK, both faces drawn), so the heap inside shows through them. `Contents`
is the heap of dirty Socks: the game's real Sock meshes (their LOD1, from
assets_src/blender/sock/socks.blend), greyed with brown-stained toes, on a dirty fabric heap; one
shape key, `empty`.

Run from the repository root (Blender is the kit's pinned one, kit/tools/blender.sh):

    ~/tools/blender/blender -b -P tools/blender/laundry_bin.py -- [--save] [--no-export] [--out <dir>]

It builds the bin from scratch (build() is safe to re-run in an open file), writes
`assets/laundry_bin/laundry_bin.glb` (under `--out` when given) and with `--save` the source
`assets_src/blender/laundry/laundry_bin.blend`. Last line: `PASS laundry_bin ...` or `FAIL ...`.

Blender metres, the front toward -Y, the bottom's middle on the origin. Under the root `laundry_bin`
(only its children are exported, so in Godot they sit straight under the glb's root, which the Looks
instances as its `Tip` pivot; core/90's contract, run-ends.md "Looks"):
  Body      the bands, floor, rim and hand holes (materials `white`, `dark`)
  Shell     the perforated wall (UV map `UVMap`, the 64 px hole cell `hamper_holes` repeating)
  Contents  the heap; origin on the inside floor. Its blend shape `empty` (glTF morph target 0) sinks
            it to the floor: blend = 1 - fill (fill 0..1, a full heap a little over the rim); the
            game hides it while the bin holds nothing.

What differs from the old script (technical only, Q2153): the palette it needs from the old
washer_parts.py is here (white, dark, dirty, stain); the white plastic is the shared library's
`white` (game/materials/white.tres, Q2177), which the hole texture is coloured to match; no collider
box (collision is the entity scene's, assets_src/generate/README.md); the nodes are named for the
Looks contract (`Contents`, and `Body`, `Shell` alike); the export is built in.
"""

import math
import os
import sys

import bpy
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, os.path.join(REPO, "assets_src", "generate", "cabinet"))
import appliance_family as fam  # noqa: E402

ASSET = "laundry_bin"
GLB = os.path.join("assets", "laundry_bin", "laundry_bin.glb")
SOURCE = os.path.join("assets_src", "blender", "laundry", "laundry_bin.blend")
SOCKS_BLEND = os.path.join(REPO, "assets_src", "blender", "sock", "socks.blend")

W, D = 0.44, 0.34    # the tub's outside, in plan
CR = 0.07            # its plan corner radius
TOP = 0.5            # the wall's top (the rim rolls over it)
WALL = 0.012
FLOOR = 0.03         # the inside floor's height
SEG = 4              # corner segments
# The perforated wall runs between the solid bands, BAND_LO to BAND_HI: a grid of rounded-square
# holes, CELL apart, HOLE of a cell wide, cut by an alpha-clip texture.
BAND_LO, BAND_HI = 0.07, 0.41
CELL = 0.03
HOLE, HOLE_R = 0.62, 0.12          # of a cell
HOLES_IMAGE, HOLES_PX = "hamper_holes", 64
# The heap (above FLOOR): a column to COL_H, then a dome to COL_H + DOME_H.
INSET = 0.006
COL_H, DOME_H = 0.4, 0.11
EMPTY = 0.03         # the `empty` key keeps this fraction of the column's height
# The Socks on top: (shape, x, y, turn deg, flip). The real Socks' LOD1.
SOCKS = [("crew", -0.04, 0.03, 20, False), ("ankle", 0.08, -0.05, 150, True), ("crew", 0.05, 0.06, 200, True),
         ("ankle", -0.1, -0.06, 300, False), ("crew", 0.0, -0.01, 95, True)]
STAIN_FROM = 0.3     # the toe's last part of the Sock's length is stained

# The palette (sRGB hex) and Principled finish (metallic, roughness). `white` is the shared library's
# (game/materials/white.tres: albedo 0.95, 0.93, 0.88, roughness 0.6; the glb's copy is not drawn);
# the rest are the old washer_parts.py values.
COLOURS = {
    "white": "#F2EDE0",
    "dark": fam.COLOURS["dark"],   # the hand holes' inset
    "dirty": "#9A9384",            # the dirty Socks: greyed
    "stain": "#7A5A3C",            # ... and stained brown (Q1005)
}
FINISH = {"white": (0.0, 0.6), "dark": (0.0, 0.35), "dirty": (0.0, 0.9), "stain": (0.0, 0.9)}
ORDER = list(COLOURS)


def material(name):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    col = fam.srgb(COLOURS[name])
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Base Color"].default_value = col
    b.inputs["Metallic"].default_value, b.inputs["Roughness"].default_value = FINISH[name]
    m.diffuse_color = col  # Workbench previews
    m.metallic, m.roughness = FINISH[name]
    return m


def part():
    return fam.Part(ORDER, material)


def _ring(w, d, r, z, m=None):
    m = m or Matrix()
    return [m @ Vector((p.x, p.y, z)) for p in fam.rounded_rect(w, d, r, SEG)]


def _tub(p):
    """The solid parts: the base band and floor, the top band rolled into the rim, the hand holes.
    The perforated wall between the bands is the `Shell` (_shell)."""
    wi, di, ri = W - 2 * WALL, D - 2 * WALL, CR - WALL
    # The base band: the rounded foot up to BAND_LO, a ledge in, down the inside to the floor.
    rings = [_ring(W - 0.03, D - 0.03, CR - 0.015, 0.0), _ring(W - 0.008, D - 0.008, CR - 0.004, 0.006),
             _ring(W, D, CR, 0.02), _ring(W, D, CR, BAND_LO), _ring(wi, di, ri, BAND_LO),
             _ring(wi, di, ri, FLOOR)]
    p._strip(rings, "white", cap_start="white", cap_end="white")
    # The top band, from BAND_HI up the outside, over the top and back down the inside.
    rings = [_ring(wi, di, ri, BAND_HI), _ring(W, D, CR, BAND_HI), _ring(W, D, CR, TOP),
             _ring(wi, di, ri, TOP), _ring(wi, di, ri, BAND_HI)]
    p._strip(rings, "white")
    p.sweep(fam.rounded_rect(W - WALL, D - WALL, CR - WALL / 2, SEG), 0.011, "white",
            matrix=Matrix.Translation((0, 0, TOP + 0.003)), n=6, squash=0.9)
    # A hand hole in the top band at each end (a dark inset, both faces).
    hz = (BAND_HI + TOP) / 2
    for sx in (-1, 1):
        for x, s in ((W / 2, 1), (wi / 2, -1)):
            fm = Matrix.Translation((sx * x, 0, hz)) @ Matrix.Rotation(sx * s * math.pi / 2, 4, "Y") \
                @ Matrix.Rotation(sx * math.pi / 2, 4, "Z")
            p.slab(fam.stadium(0.12, 0.036, 3), -0.001, 0.0006, "dark", matrix=fm)


def _holes_image():
    """The hole grid's cell: white, a rounded-square hole (alpha 0) in the middle; packed."""
    import numpy as np
    img = bpy.data.images.get(HOLES_IMAGE)
    if img is not None:
        bpy.data.images.remove(img)
    n = HOLES_PX
    img = bpy.data.images.new(HOLES_IMAGE, n, n, alpha=True)
    c = (np.arange(n) + 0.5) / n - 0.5
    x, y = np.meshgrid(c, c)
    h, r = HOLE / 2, HOLE_R
    dx, dy = np.maximum(np.abs(x) - (h - r), 0), np.maximum(np.abs(y) - (h - r), 0)
    hole = (dx ** 2 + dy ** 2) < r ** 2
    px = np.ones((n, n, 4), dtype=np.float32)
    px[..., :3] = [int(COLOURS["white"][i:i + 2], 16) / 255 for i in (1, 3, 5)]  # sRGB bytes
    px[hole, 3] = 0.0
    img.pixels[:] = px.ravel()
    img.pack()
    return img


def _holes_material():
    """`white_holes`: the white plastic, cut by the hole grid (alpha clip, glTF MASK)."""
    m = material("white")
    hm = bpy.data.materials.get("white_holes") or bpy.data.materials.new("white_holes")
    nt = hm.node_tree
    b = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Metallic"].default_value, b.inputs["Roughness"].default_value = FINISH["white"]
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = _holes_image()
    tex.interpolation = "Closest"
    rnd = nt.nodes.new("ShaderNodeMath")
    rnd.operation = "ROUND"
    nt.links.new(tex.outputs["Color"], b.inputs["Base Color"])
    nt.links.new(tex.outputs["Alpha"], rnd.inputs[0])
    nt.links.new(rnd.outputs[0], b.inputs["Alpha"])
    hm.diffuse_color = m.diffuse_color
    hm.use_backface_culling = False
    try:
        hm.surface_render_method = "DITHERED"
    except (AttributeError, TypeError):
        hm.blend_method = "CLIP"
    return hm


def _shell(root):
    """The perforated wall between the bands, mid-wall: one surface, both faces drawn, UVs in
    hole-grid cells (the texture repeats), a whole number of cells round and up."""
    import bmesh
    outline = fam.rounded_rect(W - WALL, D - WALL, CR - WALL / 2, SEG)
    outline = outline + [outline[0]]
    s = [0.0]
    for a, b in zip(outline, outline[1:]):
        s.append(s[-1] + (b - a).length)
    nu = max(round(s[-1] / CELL), 1)
    nv = max(round((BAND_HI - BAND_LO) / CELL), 1)
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    rows = [[bm.verts.new((q.x, q.y, z)) for q in outline] for z in (BAND_LO, BAND_HI)]
    for i in range(len(outline) - 1):
        f = bm.faces.new((rows[0][i], rows[0][i + 1], rows[1][i + 1], rows[1][i]))
        for loop, (u, v) in zip(f.loops, ((s[i], 0), (s[i + 1], 0), (s[i + 1], 1), (s[i], 1))):
            loop[uv].uv = (u / s[-1] * nu, v * nv)
    me = bpy.data.meshes.new("Shell")
    bm.to_mesh(me)
    bm.free()
    me.materials.append(_holes_material())
    for poly in me.polygons:
        poly.use_smooth = True
    ob = bpy.data.objects.new("Shell", me)
    bpy.context.scene.collection.objects.link(ob)
    ob.parent = root
    return ob


def _dome_h(x, y):
    """The heap's surface height (above FLOOR) at (x, y)."""
    u = min((x / ((W - 2 * WALL) / 2 - INSET)) ** 2 + (y / ((D - 2 * WALL) / 2 - INSET)) ** 2, 1.0)
    return COL_H + DOME_H * math.sqrt(1.0 - u)


def _sock_meshes():
    """The LOD1 meshes (`<shape>_lod1`) of the Sock shapes SOCKS uses, from socks.blend: {shape: (co, faces)}.
    Imports them, copies their geometry and removes everything imported."""
    shapes = sorted({s[0] for s in SOCKS})
    kinds = ("objects", "meshes", "materials", "armatures", "images", "actions")
    before = {k: set(getattr(bpy.data, k)) for k in kinds}
    with bpy.data.libraries.load(os.path.normpath(SOCKS_BLEND), link=False) as (src, dst):
        dst.objects = [n for n in src.objects if n in [sh + "_lod1" for sh in shapes]]
    out = {}
    for ob in dst.objects:
        me = ob.data
        out[ob.name[:-len("_lod1")]] = ([v.co.copy() for v in me.vertices], [tuple(f.vertices) for f in me.polygons])
    for k, old in before.items():
        coll = getattr(bpy.data, k)
        for item in [i for i in coll if i not in old]:
            coll.remove(item)
    missing = set(shapes) - set(out)
    if missing:
        raise RuntimeError("socks.blend has no %s" % ", ".join(sorted(s + "_lod1" for s in missing)))
    return out


def _contents(p):
    """The heap, built in the asset's space; every vertex gets `drop`, how far the `empty` key
    lowers it (the column squashes to EMPTY, each Sock moves down whole with the surface)."""
    drop = p.bm.verts.layers.float.new("drop")
    wi, di, ri = W - 2 * WALL - 2 * INSET, D - 2 * WALL - 2 * INSET, CR - WALL - INSET
    rings = [_ring(wi, di, ri, FLOOR), _ring(wi, di, ri, FLOOR + COL_H)]
    for k in range(1, 6):
        a = math.pi / 2 * k / 6
        c = math.cos(a)
        rings.append(_ring(wi * c, di * c, ri * c, FLOOR + COL_H + DOME_H * math.sin(a)))
    made = p._strip(rings, "dirty", cap_start="dirty", cap_end="dirty")
    for ring in made:
        for v in ring:
            v[drop] = (1.0 - EMPTY) * (v.co.z - FLOOR)
    meshes = _sock_meshes()
    di_mat, st_mat = p.order.index("dirty"), p.order.index("stain")
    for shape, x, y, turn, flip in SOCKS:
        cos, faces = meshes[shape]
        h = _dome_h(x, y)
        m = Matrix.Translation((x, y, FLOOR + h - 0.01)) @ Matrix.Rotation(math.radians(turn), 4, "Z")
        if flip:
            m = m @ Matrix.Diagonal((1, -1, 1, 1))
        xs = [c.x for c in cos]
        x0, x1 = min(xs), max(xs)
        toe = x1 - STAIN_FROM * (x1 - x0)
        verts = [p.bm.verts.new(m @ c) for c in cos]
        for v in verts:
            v[drop] = (1.0 - EMPTY) * h
        for f in faces:
            vs = [verts[i] for i in f]
            if flip:
                vs.reverse()
            face = p.bm.faces.new(vs)
            face.material_index = st_mat if min(cos[i].x for i in f) > toe else di_mat


def _add_empty_key(ob):
    """Turns the `drop` attribute into the shape key `empty`, then removes the attribute."""
    me = ob.data
    att = me.attributes["drop"]
    drops = [d.value for d in att.data]
    ob.shape_key_add(name="Basis", from_mix=False)
    key = ob.shape_key_add(name="empty", from_mix=False)
    for v, d in zip(key.data, drops):
        v.co.z -= d
    me.attributes.remove(att)
    key.value = 0.0


def set_fill(fill):
    """Shows the bin `fill` full (0..1) in the open file (previews only; the game sets the blend)."""
    ob = bpy.data.objects["Contents"]
    ob.data.shape_keys.key_blocks["empty"].value = 1.0 - fill
    ob.hide_render = fill <= 0.0


def build(clean=True):
    """Rebuilds the bin in the open file (the heap full). Returns a one-line report."""
    if clean:
        fam.wipe()
    root = fam.root(ASSET)
    root.empty_display_size = 0.08
    p = part()
    _tub(p)
    body = p.finish("Body", parent=root)
    shell = _shell(root)
    p = part()
    _contents(p)
    contents = p.finish("Contents", parent=root, location=(0, 0, FLOOR), sharp_deg=180.0)
    _add_empty_key(contents)
    objs = (body, shell, contents)
    tris = {}
    for o in objs:
        o.data.calc_loop_triangles()
        tris[o.name] = len(o.data.loop_triangles)
    mats = {s.material.name for o in objs for s in o.material_slots}
    return "render_tris=%d (Body %d, Shell %d, Contents %d) materials=%d" % (
        sum(tris.values()), tris["Body"], tris["Shell"], tris["Contents"], len(mats))


def export(out_root):
    """The root's children (not the root) to the glb: +Y up, modifiers applied, shape keys kept."""
    root = bpy.data.objects[ASSET]
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    for o in root.children_recursive:
        o.hide_viewport = False
        o.hide_set(False)
        o.select_set(True)
    out = os.path.join(out_root, GLB)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=out, export_format="GLB", use_selection=True, export_apply=False,
        export_yup=True, export_cameras=False, export_lights=False, export_animations=False,
        export_morph=True, export_morph_normal=True, export_extras=False)
    return out


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out_root = REPO
    if "--out" in argv:
        out_root = os.path.abspath(argv[argv.index("--out") + 1])
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.unit_settings.system = "METRIC"
    report = build()
    said = [report]
    if "--no-export" not in argv:
        said.append("glb " + export(out_root))
    if "--save" in argv:
        path = os.path.join(REPO, SOURCE)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=path, compress=True)
        said.append("blend " + path)
    print("PASS laundry_bin " + " | ".join(said))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:  # a crash is a failure, never a silent pass
        import traceback
        traceback.print_exc()
        print("FAIL laundry_bin: %s" % e)
        sys.exit(1)
