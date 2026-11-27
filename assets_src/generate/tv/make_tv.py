"""The TV's model (assets/27), ported from the old game (reference/it-socks, tag v0.1.1):
tools/blender/make_tv.py (pipeline/08; docs/art/tv/tv.md there).

The living room's modern widescreen set on a mid-century walnut media console, walnut and cream. The console is a
soft-cornered walnut box on four tapered, slightly splayed walnut legs with brass ferrules, a brass bead under the
top's front edge, two cream sliding doors with the sock creature's two pink stripes and round brass pulls, and an
open dark niche in a walnut frame between them with five records (the last one leans). On top: the slim charcoal
panel on a brass pedestal (a charcoal hump at its back, the red standby lamp in a brass ring in its chin), a charcoal
soundbar with a dark cloth front and brass end caps, and a little cream vase with a pink band on the right end. It
borrows the retro appliance family's modelling helpers (assets_src/generate/cabinet/appliance_family.py, unchanged)
with its own palette, as the Radio does.

Run from the repository root (Blender is the kit's pinned one, kit/tools/blender.sh):

    kit/tools/blender.sh -b -P assets_src/generate/tv/make_tv.py -- [--save] [--no-export] [--out <dir>]

It builds the TV from scratch, writes `assets/tv/tv.glb` (under `--out` when given) and with `--save` the source
`assets_src/blender/tv/tv.blend`. Last line: `PASS tv ...` or `FAIL ...`.

Blender metres, the front facing -Y (in Godot +Z), the origin at the bottom centre; 1.5 x 0.446 x 1.22 m, the old
size (the entity's box, 1.5 x 0.46 x 1.22 m, is its own). Godot space = Blender (x, z, -y).

tv.glb, under the root `tv` (only its children are exported):
  Body        every still piece
  Glass       ONLY the glass, one quad facing the front, 16:9 (1.08 x 0.6075 m), its origin at its middle, Godot
              (0, 0.896, -0.0219); material `screen`; UVs u 0..1 left to right and v 0..1 top to bottom in glTF
              (the exporter flips Blender's v). TvScreen draws the picture on it; the outline leaves it out.
  PowerLight  the standby lamp's lens in the panel's chin, one material `power_light` (glows while on)

Materials: `brass` is the shared library's (game/materials/brass.tres, the same colour and finish; the glb's import
maps it); walnut, cream, charcoal, pink, dark, screen and power_light stay embedded with the old colours (the
library's charcoal and pink have other finishes, and has no walnut or cream).

What differs from the old script (technical only, Q2153): the node names are the Looks contract's (`body`, `screen`,
`power_light` were snake_case; the glass is `Glass`); the glass's origin is its middle (it was the TV's); no
collider boxes (the entity's own box; the old game dropped them too); it runs headless and the export is built in
(the old ran through MCP and `export.sh`).
"""

import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, os.path.join(REPO, "assets_src", "generate", "cabinet"))
import appliance_family as fam  # noqa: E402

ASSET = "tv"
GLB = os.path.join("assets", "tv", "tv.glb")
SOURCE = os.path.join("assets_src", "blender", "tv", "tv.blend")

# --- The old make_tv.py's numbers ----------------------------------------------------------------------
# The console (Blender: x right, -y front, z up).
CW, CY0, CY1 = 1.5, -0.200, 0.220      # width, front and back
LEG_H = 0.14                           # the gap under the console (the crawl space)
CH = 0.48                              # the console's top
DOOR_W, DOOR_H, DOOR_X = 0.5, 0.27, 0.48
DOOR_Z = (LEG_H + CH) / 2
NICHE_W, NICHE_H = 0.38, 0.27
# The panel: 1.14 x 0.66, its bottom 0.08 over the console, its front face at y PANEL_Y.
TW, TH = 1.14, 0.66
TZ0 = CH + 0.08
PANEL_Y, PANEL_D = 0.0225, 0.035
CHIN = 0.0325                          # the bezel under the glass (the lamp sits in it)
SW = 1.08                              # the glass's width; 16:9
SH = SW * 9 / 16
SZ = TZ0 + CHIN + SH / 2               # the glass's middle
LAMP = (0.0, TZ0 + CHIN / 2)
GLASS_Y = PANEL_Y - 0.0006               # the glass, a hair in front of the panel

COLOURS = {
    "walnut": "#6E4429",      # the console, legs, niche frame
    "cream": "#FAEBD1",       # the doors, the vase, a record
    "charcoal": "#2A2A2E",    # the panel, the soundbar, a record
    "brass": "#DBAD5C",       # pulls, ferrules, the pedestal, the soundbar's end caps; metallic
    "pink": "#EB998C",        # the sock creature's two stripes, the vase's band, a record
    "dark": "#2E2724",        # the niche, the soundbar's cloth
    "screen": "#1C2421",      # the glass (TvScreen draws on it)
    "power_light": "#D92619",  # the standby lamp (glows while on)
}
FINISH = {"walnut": (0.0, 0.5), "cream": (0.0, 0.5), "charcoal": (0.0, 0.35), "brass": (0.8, 0.3),
          "pink": (0.0, 0.8), "dark": (0.0, 0.8), "screen": (0.0, 0.15), "power_light": (0.0, 0.3)}
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


def rect(w, h):
    """A plain rectangle's outline in the XY plane, counter-clockwise, centred."""
    return [Vector((w / 2, -h / 2, 0)), Vector((w / 2, h / 2, 0)), Vector((-w / 2, h / 2, 0)),
            Vector((-w / 2, -h / 2, 0))]


def part():
    return fam.Part(ORDER, material)


def front(x, y, z):
    return fam.front(x, y, z)


def up(x, y, z):
    return Matrix.Translation((x, y, z))


def _console(p):
    mid_y = (CY0 + CY1) / 2
    p.rounded_box(CW, CY1 - CY0, LEG_H, CH, 0.03, 0.018, 0.022, "walnut", matrix=up(0, mid_y, 0), seg=3,
                  seg_round=2)
    # Four tapered legs, splayed a touch, with brass ferrules.
    for sx in (-1, 1):
        for sy in (-1, 1):
            x, y = sx * (CW / 2 - 0.11), mid_y + sy * 0.13
            m = up(x, y, 0) @ Matrix.Rotation(math.radians(5), 4, Vector((-sy, sx, 0)).normalized())
            p.lathe([(0.011, 0.0), (0.013, 0.03)], "brass", matrix=m, n=8, cap_start="brass")
            p.lathe([(0.013, 0.03), (0.022, LEG_H + 0.01)], "walnut", matrix=m, n=8)
    # The cream sliding doors with the two pink stripes and brass pulls.
    fz = front(0, CY0, 0)
    for s in (-1, 1):
        dm = fz @ Matrix.Translation((s * DOOR_X, DOOR_Z, 0))
        p.slab(fam.rounded_rect(DOOR_W, DOOR_H, 0.012, 2), -0.002, 0.010, "cream", matrix=dm)
        for z in (-0.085, -0.06):
            p.slab(rect(DOOR_W - 0.002, 0.012), 0.0095, 0.0115, "pink", matrix=dm @ Matrix.Translation((0, z, 0)))
        pm = dm @ Matrix.Translation((-s * (DOOR_W / 2 - 0.05), 0.03, 0.010))
        p.lathe([(0.008, -0.001), (0.006, 0.006), (0.012, 0.010), (0.012, 0.014), (0.008, 0.016)], "brass",
                matrix=pm, n=10, cap_end="brass")
    # The open niche between them: dark inside a walnut frame, a few records standing in it.
    nm = fz @ Matrix.Translation((0, DOOR_Z, 0))
    p.slab(fam.rounded_rect(NICHE_W, NICHE_H, 0.01, 2), -0.002, 0.001, "dark", matrix=nm)
    p.sweep(fam.rounded_rect(NICHE_W + 0.008, NICHE_H + 0.008, 0.012, 2), 0.006, "walnut", matrix=nm, n=4,
            squash=0.7)
    for k, (c, lean) in enumerate((("pink", 0), ("cream", 0), ("charcoal", 0), ("pink", 0), ("cream", -9))):
        x = -0.14 + k * 0.032 + (0.03 if lean else 0)
        rm = (nm @ Matrix.Translation((x, -NICHE_H / 2 + 0.005, 0.012))
              @ Matrix.Rotation(math.radians(lean), 4, "Z"))
        p.slab(rect(0.012, 0.21), -0.11, 0.0, c, matrix=rm @ Matrix.Translation((0, 0.105, 0)))
    # A brass bead under the top's front edge.
    p.sweep([Vector((-CW / 2 + 0.04, CY0 - 0.001, CH - 0.035)), Vector((CW / 2 - 0.04, CY0 - 0.001, CH - 0.035))],
            0.003, "brass", normal=(0, 1, 0), n=6, closed=False)


def _set(p):
    py = PANEL_Y + PANEL_D / 2
    # The brass pedestal and its charcoal neck.
    p.rounded_box(0.38, 0.2, CH - 0.002, CH + 0.012, 0.09, 0.0, 0.006, "brass", matrix=up(0, 0.04, 0), seg=4,
                  seg_round=2)
    p.rounded_box(0.08, 0.03, CH + 0.01, TZ0 + 0.2, 0.012, 0.0, 0.0, "charcoal", matrix=up(0, py + 0.03, 0),
                  seg=2)
    # The panel: soft-cornered, the glass flush in its front; a hump behind.
    pm = front(0, PANEL_Y + PANEL_D, TZ0 + TH / 2)
    p.rounded_box(TW, TH, 0.0, PANEL_D, 0.018, 0.004, 0.006, "charcoal", matrix=pm, seg=3, seg_round=2)
    hm = front(0, PANEL_Y + PANEL_D + 0.035, TZ0 + TH * 0.42)
    p.rounded_box(TW * 0.6, TH * 0.55, 0.0, 0.037, 0.04, 0.0, 0.015, "charcoal", matrix=hm, seg=3, seg_round=2)
    # A brass ring round the lamp.
    lm = front(LAMP[0], PANEL_Y, LAMP[1])
    p.sweep(fam.circle(0.0055, 10), 0.0012, "brass", matrix=lm @ Matrix.Translation((0, 0, 0.0004)), n=5)
    # The soundbar: charcoal, a dark cloth front, brass end caps.
    sy, sz = -0.1, CH + 0.034
    sm = Matrix.Translation((0, sy, sz)) @ Matrix.Rotation(math.pi / 2, 4, "Y")
    p.slab(fam.stadium(0.064, 0.074, 4), -0.33, 0.33, "charcoal", matrix=sm)
    for sx in (-1, 1):
        p.slab(fam.stadium(0.066, 0.076, 4), sx * 0.33, sx * 0.345, "brass", matrix=sm)
    p.slab(fam.rounded_rect(0.62, 0.036, 0.008, 2), -0.002, 0.0015, "dark",
           matrix=front(0, sy - 0.037, sz))
    # A little cream vase with a pink band on the right end.
    vm = up(0.6, 0.06, CH)
    p.lathe([(0.0, 0.0), (0.035, 0.0), (0.05, 0.05), (0.045, 0.1), (0.022, 0.14), (0.02, 0.17), (0.026, 0.18),
             (0.019, 0.18)], "cream", matrix=vm, n=14)
    p.lathe([(0.0505, 0.04), (0.0515, 0.05), (0.0505, 0.06)], "pink", matrix=vm, n=14)


def _glass():
    """The glass: one quad facing -Y, u left to right and v bottom to top in Blender; its origin at its middle."""
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    vs = [bm.verts.new((-SW / 2, 0.0, -SH / 2)), bm.verts.new((SW / 2, 0.0, -SH / 2)),
          bm.verts.new((SW / 2, 0.0, SH / 2)), bm.verts.new((-SW / 2, 0.0, SH / 2))]
    f = bm.faces.new(vs)
    for loop, (u, v) in zip(f.loops, ((0, 0), (1, 0), (1, 1), (0, 1))):
        loop[uv].uv = (u, v)
    bm.normal_update()
    if f.normal.y > 0:
        bmesh.ops.reverse_faces(bm, faces=[f])
    me = bpy.data.meshes.new("Glass")
    bm.to_mesh(me)
    bm.free()
    me.materials.append(material("screen"))
    ob = bpy.data.objects.new("Glass", me)
    ob.location = (0.0, GLASS_Y, SZ)
    bpy.context.scene.collection.objects.link(ob)
    return ob



# --- Build and export ----------------------------------------------------------------------------------

def build():
    """Wipes the open file and builds the TV; returns its triangle count."""
    fam.wipe()
    root = fam.root(ASSET)
    root.empty_display_size = 0.5
    p = part()
    _console(p)
    _set(p)
    p.finish("Body", parent=root)
    glass = _glass()
    glass.parent = root
    p = part()
    lr = 0.0042
    p.lathe([(lr, -0.001), (lr, 0.0)] + [(lr * math.cos(math.radians(a)), lr * 0.6 * math.sin(math.radians(a)))
                                          for a in (35, 70)],
            "power_light", matrix=front(LAMP[0], PANEL_Y, LAMP[1]), n=8, cap_start="power_light",
            cap_end="power_light")
    p.finish("PowerLight", parent=root, location=(LAMP[0], PANEL_Y, LAMP[1]))
    bpy.context.view_layer.update()
    tris = 0
    for ob in root.children_recursive:
        if ob.type == "MESH":
            ob.data.calc_loop_triangles()
            tris += len(ob.data.loop_triangles)
    return "render_tris=%d materials=%d" % (tris, len(bpy.data.materials))


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
    said.append("tv " + build())
    if "--no-export" not in argv:
        said.append("glb " + export(out_root))
    if "--save" in argv:
        said.append(_save(SOURCE))
    print("PASS tv " + " | ".join(said))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:  # a crash is a failure, never a silent pass
        import traceback
        traceback.print_exc()
        print("FAIL tv: %s" % e)
        sys.exit(1)
