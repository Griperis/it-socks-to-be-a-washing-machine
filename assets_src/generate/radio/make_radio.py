"""The Radio's model (assets/28), ported from the old game (reference/it-socks, tag v0.1.1):
tools/blender/make_radio.py (pipeline/06; docs/art/radio/radio.md there).

A chubby 1950s tabletop set in the house's colours: a terracotta loaf body with soft corners on two dark rubber
runners, a cream carry handle on brass mounts, and a cream face plate ringed by a brass bead that holds the amber
tuning dial in its brass bezel with seven dark ticks and the red needle, the dark speaker cloth with the sock
creature's two pink stripes in a brass rim, two terracotta knobs with brass caps and a cream mark, and the red power
lamp in a brass ring. Four dark vent slots at the back. It borrows the retro appliance family's modelling helpers
(assets_src/generate/cabinet/appliance_family.py, unchanged) with its own palette.

Run from the repository root (Blender is the kit's pinned one, kit/tools/blender.sh):

    kit/tools/blender.sh -b -P assets_src/generate/radio/make_radio.py -- [--save] [--no-export] [--out <dir>]

It builds the radio from scratch, writes `assets/radio/radio.glb` (under `--out` when given) and with `--save` the
source `assets_src/blender/radio/radio.blend`. Last line: `PASS radio ...` or `FAIL ...`.

Blender metres, the front facing -Y (in Godot +Z), the origin at the bottom centre; 0.155 x 0.108 x 0.084 m, the old
modelled size (its Looks shows it 1.5 times bigger, R1). Godot space = Blender (x, z, -y).

radio.glb, under the root `radio` (only its children are exported):
  Body        every still piece
  Dial        the dial's face, 0.11 x 0.022 m centred at Godot (0, 0.072), one material `dial` (glows while on)
  Needle      its origin at the left end of its travel, Godot x -0.045, y 0.072; the `dial` clip slides it +x by
              up to 0.09 (the old Device.DIAL_TRAVEL); one material `needle`
  Speaker     the speaker cloth: the dark grille and its two pink stripes (its brass rim is Body's)
  PowerLight  the lamp's lens, one material `power_light` (glows while on)

Materials: `brass` is the shared library's (game/materials/brass.tres, the same colour and finish; the glb's import
maps it); terracotta, cream, dark, pink, dial, needle and power_light stay embedded with the old colours (the
library's terracotta and pink have other finishes).

What differs from the old script (technical only, Q2153): the node names are the Looks contract's (`body`, `dial`,
`needle`, `power_light` were snake_case); the speaker cloth is its own node `Speaker` (it was part of `body`); no
collider box (the entity's own box; the old game dropped it too); the export is built in; the Blender line-up is
left out (the line-up is taken in Godot, tools/radio_still.tscn).
"""

import math
import os
import sys

import bpy
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, os.path.join(REPO, "assets_src", "generate", "cabinet"))
import appliance_family as fam  # noqa: E402

ASSET = "radio"
GLB = os.path.join("assets", "radio", "radio.glb")
SOURCE = os.path.join("assets_src", "blender", "radio", "radio.blend")

# --- The old make_radio.py's numbers ---------------------------------------------------------------
W = 0.155                      # the body's width (x)
BODY_Y0, BODY_Y1 = -0.030, 0.042   # the body's front and back (Blender y)
FEET_H = 0.006                 # the rubber runners' height; the body stands on them
TOP = 0.098                    # the body's top
PLAN_R, TOP_R, BOT_R = 0.012, 0.012, 0.008
PLATE = (0.133, 0.074, 0.052, 0.010, 0.003)   # face plate: width, height, middle z, corner, depth
PLATE_FRONT = BODY_Y0 - PLATE[4]
DIAL = (0.0, 0.072, 0.11, 0.022)    # the dial's face: middle x, z, width, height
NEEDLE_X0 = -0.045                  # the needle's rest (Off); travel +0.09
GRILLE = (-0.026, 0.035, 0.068, 0.034)  # middle x, z, width, height
KNOBS = ((0.027, 0.033), (0.052, 0.033))
KNOB_R = 0.0105
LAMP = (0.0395, 0.050)
HANDLE_X, HANDLE_R = 0.056, 0.0045

# The radio's palette (sRGB hex, the old colours) and Principled finish (metallic, roughness).
COLOURS = {
    "terracotta": "#CC734C",   # the body and the knobs
    "cream": "#FAEBD1",        # the face plate and the handle
    "brass": "#DBAD5C",        # bead, bezel, handle mounts, knob caps; the library's brass on import
    "dark": "#2E2724",         # rubber runners, cloth grille, ticks, vents
    "pink": "#EB998C",         # the sock creature's two stripes on the grille
    "dial": "#F5C773",         # the dial's face (glows while on)
    "needle": "#CC3326",
    "power_light": "#D92619",  # the lamp (glows while on)
}
FINISH = {"terracotta": (0.0, 0.45), "cream": (0.0, 0.5), "brass": (0.8, 0.3), "dark": (0.0, 0.75),
          "pink": (0.0, 0.85), "dial": (0.0, 0.4), "needle": (0.0, 0.4), "power_light": (0.0, 0.3)}
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


def back(x, y, z):
    """A frame facing the back: local +Z out of the back (+Y)."""
    return Matrix.Translation((x, y, z)) @ Matrix.Rotation(-math.pi / 2, 4, "X")


def _plate_frame():
    """The face plate's front surface: z = 0 there, heights in local y."""
    return fam.front(0, PLATE_FRONT, 0)


def _body(p):
    mid_y = (BODY_Y0 + BODY_Y1) / 2
    p.rounded_box(W, BODY_Y1 - BODY_Y0, FEET_H, TOP, PLAN_R, BOT_R, TOP_R, "terracotta",
                  matrix=Matrix.Translation((0, mid_y, 0)), seg=3, seg_round=3)
    # Two dark rubber runners.
    for x in (-0.05, 0.05):
        p.rounded_box(0.03, 0.056, 0.0, FEET_H + 0.002, 0.004, 0.0, 0.0, "dark",
                      matrix=Matrix.Translation((x, mid_y, 0)), seg=2, seg_round=1)
    # The face plate and its brass bead.
    pw, ph, pz, pr, pd = PLATE
    fp = fam.front(0, BODY_Y0, pz)
    p.slab(fam.rounded_rect(pw, ph, pr, 3), -0.001, pd, "cream", matrix=fp)
    p.sweep(fam.rounded_rect(pw, ph, pr, 3), 0.0016, "brass", matrix=fp @ Matrix.Translation((0, 0, pd * 0.5)),
            n=4)
    pf = _plate_frame()
    # The dial's brass bezel and ticks (the face itself is the Dial node).
    dx, dz, dw, dh = DIAL
    p.sweep(fam.rounded_rect(dw + 0.004, dh + 0.004, 0.003, 3), 0.0018, "brass",
            matrix=pf @ Matrix.Translation((dx, dz, 0.0005)), n=4, squash=0.8)
    for k in range(7):
        x = NEEDLE_X0 + k * 0.015
        th = 0.007 if k % 3 == 0 else 0.0045
        p.slab(rect(0.0014, th), 0.0008, 0.0013, "dark",
               matrix=pf @ Matrix.Translation((x, dz - dh / 2 + 0.002 + th / 2, 0)))
    # The speaker's brass rim (the cloth is the Speaker node).
    gx, gz, gw, gh = GRILLE
    gm = pf @ Matrix.Translation((gx, gz, 0))
    p.sweep(fam.rounded_rect(gw + 0.002, gh + 0.002, 0.006, 3), 0.0017, "brass", matrix=gm, n=4, squash=0.8)
    # Two chunky terracotta knobs with brass caps and a cream mark.
    r = KNOB_R
    prof = [(r - 0.0015, -0.001), (r, 0.0012), (r, 0.0045)]
    for k in range(1, 3):
        a = math.pi / 2 * k / 2
        prof.append((r - 0.0025 + 0.0025 * math.cos(a), 0.0045 + 0.0025 * math.sin(a)))
    for kx, kz in KNOBS:
        km = pf @ Matrix.Translation((kx, kz, 0))
        p.lathe(prof, "terracotta", matrix=km, n=12, cap_start="terracotta", cap_end="terracotta")
        p.lathe([(0.0052, 0.0068), (0.0052, 0.0074), (0.0042, 0.0078)], "brass", matrix=km, n=10,
                cap_end="brass")
        p.slab(rect(0.0016, 0.0036), 0.0065, 0.0072, "cream",
               matrix=km @ Matrix.Translation((0, 0.0075, 0)))
    # The power lamp's brass ring (the lens is the PowerLight node).
    p.sweep(fam.circle(0.0044, 12), 0.0011, "brass", matrix=pf @ Matrix.Translation((LAMP[0], LAMP[1], 0.0003)),
            n=5)
    # The carry handle: a cream arch on two brass mounts on the top.
    for sx in (-1, 1):
        p.lathe([(0.0075, -0.001), (0.0075, 0.0015), (0.006, 0.0035), (0.0035, 0.005)], "brass",
                matrix=Matrix.Translation((sx * HANDLE_X, (BODY_Y0 + BODY_Y1) / 2, TOP - 0.0005)), n=8,
                cap_end="brass")
    hy = (BODY_Y0 + BODY_Y1) / 2
    path = [Vector((HANDLE_X, hy, TOP - 0.001)), Vector((HANDLE_X, hy, TOP + 0.002))]
    for k in range(1, 5):
        a = math.pi / 2 * k / 4
        path.append(Vector((HANDLE_X - 0.0075 + 0.0075 * math.cos(a), hy, TOP + 0.002 + 0.0035 * math.sin(a))))
    path = path + [Vector((-v.x, v.y, v.z)) for v in reversed(path)]
    p.sweep(path, HANDLE_R, "cream", normal=(0, 1, 0), n=6, closed=False)
    # Vent slots at the back.
    for z in (0.044, 0.054, 0.064, 0.074):
        p.slab(fam.stadium(0.07, 0.0045, 1), -0.0006, 0.0006, "dark", matrix=back(0, BODY_Y1, z))


def _speaker(p):
    """The speaker cloth: dark with the two pink stripes (the old grille, less its rim)."""
    gx, gz, gw, gh = GRILLE
    gm = _plate_frame() @ Matrix.Translation((gx, gz, 0))
    p.slab(fam.rounded_rect(gw, gh, 0.005, 3), -0.0005, 0.0008, "dark", matrix=gm)
    for sz in (0.003, -0.006):
        p.slab(rect(gw - 0.004, 0.0038), 0.0008, 0.0016, "pink",
               matrix=gm @ Matrix.Translation((0, sz, 0)))


# --- Build and export ----------------------------------------------------------------------------------

def build():
    """Wipes the open file and builds the radio; returns its triangle count."""
    fam.wipe()
    root = fam.root(ASSET)
    root.empty_display_size = 0.08
    p = part()
    _body(p)
    p.finish("Body", parent=root)
    pf = _plate_frame()
    dx, dz, dw, dh = DIAL
    p = part()
    p.slab(fam.rounded_rect(dw, dh, 0.0015, 2), -0.0002, 0.0006, "dial", matrix=pf @ Matrix.Translation((dx, dz, 0)))
    p.finish("Dial", parent=root)
    p = part()
    p.slab(fam.rounded_rect(0.0022, dh - 0.002, 0.0008, 1), 0.0016, 0.0026, "needle",
           matrix=pf @ Matrix.Translation((NEEDLE_X0, dz, 0)))
    p.finish("Needle", parent=root, location=(NEEDLE_X0, PLATE_FRONT, dz))
    p = part()
    _speaker(p)
    gx, gz = GRILLE[0], GRILLE[1]
    p.finish("Speaker", parent=root, location=(gx, PLATE_FRONT, gz))
    p = part()
    lr = 0.0033
    p.lathe([(lr, -0.001), (lr, 0.0)] + [(lr * math.cos(math.radians(a)), lr * 0.8 * math.sin(math.radians(a)))
                                          for a in (30, 60)],
            "power_light", matrix=pf @ Matrix.Translation((LAMP[0], LAMP[1], 0)), n=8, cap_start="power_light",
            cap_end="power_light")
    p.finish("PowerLight", parent=root, location=(LAMP[0], PLATE_FRONT, LAMP[1]))
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
    said.append("radio " + build())
    if "--no-export" not in argv:
        said.append("glb " + export(out_root))
    if "--save" in argv:
        said.append(_save(SOURCE))
    print("PASS radio " + " | ".join(said))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:  # a crash is a failure, never a silent pass
        import traceback
        traceback.print_exc()
        print("FAIL radio: %s" % e)
        sys.exit(1)
