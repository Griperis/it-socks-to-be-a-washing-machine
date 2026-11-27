"""The Sock detector's model (assets/26), ported from the old game (reference/it-socks, tag v0.1.1):
tools/blender/make_sock_detector.py (tools/15, Q1856, Q1857, Q1861), its numbers and colours unchanged.

A chunky handheld gadget, a hobby metal / stud detector crossed with a retro walkie-talkie, modelled lying flat on
its back as the game lays it: a mustard head whose cream face plate is almost all screen (the dark screen in a brass
bezel fills the face but for a thin cream border), a dark rubber grip with four ribs and a cream lanyard loop at its
end, a stubby dark rubber aerial on a brass collar with a red ball tip out of the nose, two rubber bumpers under the
head. It borrows the retro appliance family's modelling helpers (assets_src/generate/cabinet/appliance_family.py,
unchanged) with its own palette, as the old script did.

Run from the repository root (Blender is the kit's pinned one, kit/tools/blender.sh):

    kit/tools/blender.sh -b -P assets_src/generate/sock_detector/make_sock_detector.py -- [--save] [--no-export] [--out <dir>]

It builds from scratch, writes `assets/sock_detector/sock_detector.glb` (under `--out` when given) and with `--save`
the source `assets_src/blender/sock_detector/sock_detector.blend`. Last line: `PASS sock_detector ...` or `FAIL ...`.

Blender metres, Godot space = Blender (x, z, -y). The origin at the bottom centre of the head's footprint (the old
origin); it lies on its back, its screen up (Godot +Y), its nose (the aerial) towards Godot -Z, the grip towards +Z;
0.116 x 0.038 x 0.209 m. Under the root `sock_detector` (only its children are exported):
  Body        every still piece
  Screen      ONLY the flat screen surface, 0.080 x 0.070 m (Q1861), material `screen`, UV 0..1 with the picture's
              top towards the nose; its origin at its middle, Godot (0, SCREEN_TOP, -SCREEN_Y). core/167's
              SubViewport shows on it.

Materials: `mustard`, `cream`, `dark`, `red` stay embedded with the old values (the library's `mustard` and `red` are
other colours, it has no `cream` or this `dark`); `brass` and `screen` are swapped by the glb's import for the
library's `game/materials/brass.tres` (the same values as the old brass) and `screen.tres`.

What differs from the old script (technical only, Q2153): the nodes are `Body` and `Screen` (the Looks contract's
names); the screen is one flat face with UVs 0..1 instead of a 1.2 mm slab, its top where the slab's top was, so a
SubViewport can show on it (the old drew plain meshes over it); no collider box (collision is the entity scene's; the
old game dropped it too); the export is built in; the Blender line-up is left out (the line-up is taken in Godot,
tools/sock_detector_still.tscn).
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

ASSET = "sock_detector"
GLB = os.path.join("assets", "sock_detector", "sock_detector.glb")
SOURCE = os.path.join("assets_src", "blender", "sock_detector", "sock_detector.blend")

# --- The old make_sock_detector.py's numbers ------------------------------------------------------
# The head (the walkie-talkie part): width, its back and nose ends (Blender y), height.
HEAD_W, HEAD_Y0, HEAD_Y1 = 0.116, -0.034, 0.074
FEET = 0.003                      # the rubber bumpers under it
HEAD_TOP = 0.034
HEAD_R = 0.026                    # plan corner radius
# The grip: width, ends, height.
GRIP_W, GRIP_Y0, GRIP_Y1, GRIP_TOP = 0.07, -0.097, -0.024, 0.029
# The face plate on the head's top (width, length, centre y, corner, thickness): the head's whole flat top.
PLATE = (0.098, 0.088, 0.02, 0.016, 0.0022)
PLATE_TOP = HEAD_TOP + PLATE[4]
# The screen: centre y, width (x), length (y); its surface sits just above the plate.
# Q1861: almost the whole face plate, leaving a ~4 mm cream border round the brass bezel.
SCREEN_Y, SCREEN_W, SCREEN_L = 0.02, 0.080, 0.070
SCREEN_R = 0.007                  # its corner radius (the bezel follows it)
SCREEN_TOP = PLATE_TOP + 0.0008
AERIAL_X, AERIAL_Z = 0.034, 0.02  # the aerial's line along +y
AERIAL_Y0, AERIAL_TIP = HEAD_Y1 - 0.006, 0.1005

COLOURS = {
    "mustard": "#E3A83E",  # the head
    "cream": "#FAEBD1",    # the face plate, the lanyard loop
    "brass": "#DBAD5C",    # the screen's bezel, the aerial's collar; metallic (the library's brass)
    "dark": "#2E2724",     # the grip, bumpers, aerial, the screen's backing
    "red": "#D9463E",      # the aerial's tip
    "screen": "#1F2D29",   # the screen (the library's screen in the game)
}
FINISH = {"mustard": (0.0, 0.45), "cream": (0.0, 0.5), "brass": (0.8, 0.3), "dark": (0.0, 0.75),
          "red": (0.0, 0.35), "screen": (0.0, 0.25)}
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


def up(x, y, z):
    """A frame on the top: local +Z up, local +Y towards the nose."""
    return Matrix.Translation((x, y, z))


def along_y(x, y, z):
    """A frame whose local +Z points along +Y (towards the nose): lathes for the aerial."""
    return Matrix.Translation((x, y, z)) @ Matrix.Rotation(-math.pi / 2, 4, "X")


def _body(p):
    # The mustard head and the dark rubber grip, overlapping.
    p.rounded_box(HEAD_W, HEAD_Y1 - HEAD_Y0, FEET, HEAD_TOP, HEAD_R, 0.008, 0.009, "mustard",
                  matrix=up(0, (HEAD_Y0 + HEAD_Y1) / 2, 0), seg=4, seg_round=3)
    p.rounded_box(GRIP_W, GRIP_Y1 - GRIP_Y0, FEET + 0.002, GRIP_TOP, 0.022, 0.008, 0.011, "dark",
                  matrix=up(0, (GRIP_Y0 + GRIP_Y1) / 2, 0), seg=4, seg_round=3)
    # Rubber ribs across the grip.
    for k in range(4):
        y = GRIP_Y0 + 0.016 + k * 0.013
        p.sweep([Vector((-GRIP_W / 2 + 0.008, y, GRIP_TOP - 0.0005)), Vector((GRIP_W / 2 - 0.008, y, GRIP_TOP - 0.0005))],
                0.0022, "dark", normal=(0, 1, 0), n=5, closed=False)
    # Two rubber bumpers under the head, so it lies steady.
    for x in (-0.036, 0.036):
        p.rounded_box(0.026, 0.07, 0.0, FEET + 0.003, 0.006, 0.0, 0.0, "dark",
                      matrix=up(x, (HEAD_Y0 + HEAD_Y1) / 2 + 0.004, 0), seg=1, seg_round=1)
    # The cream face plate.
    pw, pl, py, pr, pd = PLATE
    p.rounded_box(pw, pl, HEAD_TOP - 0.002, PLATE_TOP, pr, 0.0, 0.0015, "cream",
                  matrix=up(0, py, 0), seg=4, seg_round=2)
    # The screen's brass bezel and its dark backing (the glass itself is the `Screen` node).
    p.sweep(fam.rounded_rect(SCREEN_W + 0.006, SCREEN_L + 0.006, SCREEN_R + 0.003, 3), 0.0021, "brass",
            matrix=up(0, SCREEN_Y, PLATE_TOP + 0.0003), n=5, squash=0.75)
    p.slab(fam.rounded_rect(SCREEN_W + 0.004, SCREEN_L + 0.004, SCREEN_R + 0.002, 3), PLATE_TOP - 0.0005,
           SCREEN_TOP - 0.0004, "dark", matrix=up(0, SCREEN_Y, 0))
    # The cream lanyard loop at the grip's end, lying flat.
    loop = [Vector((0.012 * math.cos(math.radians(a)), GRIP_Y0 + 0.002 + 0.0105 * math.sin(math.radians(a)) * -1, 0.0))
            for a in range(0, 181, 30)]
    p.sweep([Vector((0.012, GRIP_Y0 + 0.006, 0))] + loop + [Vector((-0.012, GRIP_Y0 + 0.006, 0))], 0.0028, "cream",
            normal=(0, 0, 1), matrix=up(0, 0, 0.016), n=6, closed=False)
    # The stubby aerial out of the nose: a brass collar, a tapering dark rubber stub, a red ball.
    am = along_y(AERIAL_X, AERIAL_Y0, AERIAL_Z)
    p.lathe([(0.0098, -0.001), (0.0098, 0.006), (0.008, 0.0085)], "brass", matrix=am, n=12, cap_end="brass")
    p.lathe([(0.0076, 0.006), (0.0071, 0.012), (0.0058, 0.022), (0.0052, AERIAL_TIP - AERIAL_Y0 - 0.012)],
            "dark", matrix=am, n=10, cap_end="dark")
    tip_r = 0.0078
    tip_c = AERIAL_TIP - AERIAL_Y0 - tip_r
    prof = [(tip_r * math.sin(math.radians(a)), tip_c - tip_r * math.cos(math.radians(a))) for a in range(15, 166, 30)]
    p.lathe(prof, "red", matrix=am, n=10, cap_start="red", cap_end="red")


def _screen(root):
    """The flat screen face, facing up, UV 0..1 with v rising towards the nose (the picture's top there after the
    glTF export's flip); its origin at its middle on the old slab's top."""
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    outline = fam.rounded_rect(SCREEN_W, SCREEN_L, SCREEN_R, 4)
    f = bm.faces.new([bm.verts.new((v.x, v.y, 0.0)) for v in outline])
    for loop, v in zip(f.loops, outline):
        loop[uv].uv = (v.x / SCREEN_W + 0.5, v.y / SCREEN_L + 0.5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    if f.normal.z < 0:
        f.normal_flip()
    me = bpy.data.meshes.new("Screen")
    bm.to_mesh(me)
    bm.free()
    me.materials.append(material("screen"))
    ob = bpy.data.objects.new("Screen", me)
    bpy.context.scene.collection.objects.link(ob)
    ob.location = (0.0, SCREEN_Y, SCREEN_TOP)
    ob.parent = root
    return ob


# --- Build and export ----------------------------------------------------------------------------------

def build():
    """Wipes the open file and builds the detector; returns its triangle count and size."""
    fam.wipe()
    root = fam.root(ASSET)
    root.empty_display_size = 0.08
    p = part()
    _body(p)
    p.finish("Body", parent=root)
    _screen(root)
    bpy.context.view_layer.update()
    tris = 0
    lo, hi = Vector((1e9,) * 3), Vector((-1e9,) * 3)
    for ob in root.children_recursive:
        if ob.type == "MESH":
            ob.data.calc_loop_triangles()
            tris += len(ob.data.loop_triangles)
            for v in ob.data.vertices:
                w = ob.matrix_world @ v.co
                lo = Vector(map(min, lo, w))
                hi = Vector(map(max, hi, w))
    size = hi - lo
    return "render_tris=%d size=%.3fx%.3fx%.3f materials=%d" % (tris, size.x, size.y, size.z, len(bpy.data.materials))


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


def _save(rel):
    path = os.path.join(REPO, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=path, compress=True)
    return "blend " + path


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out_root = REPO
    if "--out" in argv:
        out_root = os.path.abspath(argv[argv.index("--out") + 1])
    said = []
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.unit_settings.system = "METRIC"
    said.append(build())
    if "--no-export" not in argv:
        said.append("glb " + export(out_root))
    if "--save" in argv:
        said.append(_save(SOURCE))
    print("PASS sock_detector " + " | ".join(said))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:  # a crash is a failure, never a silent pass
        import traceback
        traceback.print_exc()
        print("FAIL sock_detector: %s" % e)
        sys.exit(1)
