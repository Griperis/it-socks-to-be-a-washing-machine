"""The Sock vacuum's model (assets/24), ported from the old game (reference/it-socks, tag v0.1.1):
tools/blender/make_sock_vacuum.py (the container and its nozzle), assets/vacuum_devices/make_nozzle_display.py (the
nozzle's clip-on pod, Q2173) and the hose the old game drew in code (game/devices/sock_vacuum_view.gd, Q936), here a
skinned tube with bones for core/168's rope.

The second of the retro appliance family (assets_src/generate/cabinet/appliance_family.py, unchanged): a pastel mint
pill-box canister with a cream top cap and fascia, chrome belt lines, a capsule window onto the load with the fill
gauge's dark slot beside it, the red round button and the chrome hose port on top, the chrome outlet spout and a vent
plate at the rear, the nozzle's chrome parking clip on the left side, a carry handle on the right and the family's
maker badge on the front. The nozzle: a chrome cuff, a mint grip, a chrome ring and a chrome head sweeping to a flat
capsule mouth; on its grip the cream pod with a chrome bezel round a 2:1 screen, held by two chrome bands.

Run from the repository root (Blender is the kit's pinned one, kit/tools/blender.sh):

    kit/tools/blender.sh -b -P assets_src/generate/sock_vacuum/make_sock_vacuum.py -- [--save] [--no-export] [--out <dir>]

It builds both from scratch, writes `assets/sock_vacuum/sock_vacuum.glb` and `assets/sock_vacuum/hose.glb` (under
`--out` when given) and with `--save` the sources `assets_src/blender/sock_vacuum/sock_vacuum.blend` and
`hose.blend`. Last line: `PASS sock_vacuum ...` or `FAIL ...`.

Blender metres, the front facing -Y (in Godot +Z), the origin at the bottom centre of the canister (the nozzle hangs
on the left, the spout stands out at the rear). Godot space = Blender (x, z, -y).

sock_vacuum.glb, under the root `sock_vacuum` (only its children are exported):
  Body        every still piece: the canister (cut hollow above the load's floor, the window cut through its
              front), the cap, the trims, the gauge's slot, the fascia and badge, the button and its bezel, the
              port, the spout, the vent plate, the feet, the handle, the parking clip
  Glass       the window's glass (the family's `glass`, see-through)
  Nozzle      the nozzle hanging in its clip: origin at the grip where the hose goes in, Godot (-0.31, 0.62, 0),
              the mouth 0.45 m below it (Godot -Y), the mouth's width front to back (Godot Z)
    Pod       the display pod round the grip; origin on the grip's axis 0.115 m below the Nozzle's
      PodScreen  the 92 x 46 mm screen (material `screen`), UV 0..1, the picture's top towards the mouth; origin at
                 its middle. The pod faces out of the vacuum's side (Godot -X) as it hangs.

hose.glb: the armature `HoseRig` (Godot's Skeleton3D) of HOSE_BONES bones `hose_00` .. in a chain from the origin
(the container's port end) along Blender +Y (Godot -Z), HOSE_LEN long, and its skinned mesh `Hose`: the cream ribbed
tube (every other ring 80 % wide) with the chrome cuffs at both ends; a shape key `tug` moves the tube's middle
0.05 m sideways (Godot +X), the ends still, as the old tug shook it.

Materials: the family's six (mint, cream, chrome, red, dark, glass), embedded as on the cabinets (the shared library
has none of them; Q2177), and `screen`, which the glb's import swaps for the library's `game/materials/screen.tres`.

What differs from the old scripts (technical only, Q2153): no collider box (collision is the entity scene's); the old
`mode_button` node is part of Body (the v0.1.1 game never moved or lit it); the pod is in the same glb as the
vacuum, parented to the Nozzle, turned half round about the grip as the old game turned it on import
(`sock_vacuum_view.gd:387`); the hose is a mesh with bones, not built in code each frame, with the old drawing's
numbers (`sock_vacuum_view.gd:62-73`: radius 0.022 m, grooves 0.8, eight sides, cuffs 0.03 m by 0.06 m; 12 rope
segments, 4 drawn pieces each); cream and chrome on the hose are the family's (the old code's own hose materials
were the same colours at roughness 0.55 and 0.2); the export is built in; the Blender line-up is left out (the
line-up is taken in Godot, tools/sock_vacuum_still.tscn).
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

ASSET = "sock_vacuum"
GLB = os.path.join("assets", "sock_vacuum", "sock_vacuum.glb")
HOSE_GLB = os.path.join("assets", "sock_vacuum", "hose.glb")
SOURCE = os.path.join("assets_src", "blender", "sock_vacuum", "sock_vacuum.blend")
HOSE_SOURCE = os.path.join("assets_src", "blender", "sock_vacuum", "hose.blend")

# --- The container (the old make_sock_vacuum.py's numbers) ---------------------------------------
W, D, H = 0.5, 0.42, 0.66
PLAN_R = 0.11                   # the body's corner radius in plan
FEET_H = 0.025                  # the body stands this high on its bullet feet
FLOOR = 0.19                    # the load's floor inside, and the lower belt line
CAP_Z = 0.59                    # the cream top cap's seam
FRONT = -D / 2                  # the front face (Blender y)
FASCIA_FRONT = FRONT - 0.012
WINDOW = (0.2, 0.355, 0.3875)   # the capsule window: width, height, middle height
WIN_X = 0.02                    # the window's middle (x), off centre to balance the gauge
GAUGE = (-0.12, 0.028, 0.36)    # the gauge slot: x, width, height (middle at the window's)
BUTTON = (0.13, -0.1)           # the button on top (x, y)
PORT = (0.0, 0.08)              # the hose port on top (x, y)
OUTLET = (0.0, 0.26, 0.12)      # the outlet's mouth at the rear
GRIP = (-0.31, 0.0, 0.62)       # the hung nozzle's grip (the hook less 0.04)
NOZZLE_LEN = 0.45
CLIP_R = 0.034                  # the parking clip's ring round the nozzle's grip
FASCIA = (0.3, FEET_H + 0.014, FLOOR - 0.022)  # width, bottom, top

# --- The pod (the old make_nozzle_display.py's numbers) ------------------------------------------
GRIP_R = 0.027
POD_Z = 0.115
BAND_DZ = 0.045
TILT = 0.3
SCREEN_W, SCREEN_H = 0.092, 0.046
SCREEN = ("#1C302B", 0.0, 0.2)  # the old vd_common EXTRA["screen"]

# --- The hose (the old sock_vacuum_view.gd's drawing and vacuum.json) ----------------------------
HOSE_LEN = 5.0                  # vacuum.json "hose"
HOSE_BONES = 12                 # vacuum.json "hose_segments"
HOSE_PIECES = 4                 # sock_vacuum_view.gd ROPE_SMOOTH: drawn pieces per segment
HOSE_R = 0.022
HOSE_GROOVE = 0.8
HOSE_SIDES = 8
CUFF_R = 0.03
CUFF_LEN = 0.06
TUG = 0.05                      # sock_vacuum_view.gd _mesh_hose: the tug's sideways reach (m)

ORDER = fam.ORDER + ["screen"]


def material(name):
    """The family's materials, and the pod's `screen`."""
    if name != "screen":
        return fam.material(name)
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    hexs, metal, rough = SCREEN
    col = fam.srgb(hexs)
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Base Color"].default_value = col
    b.inputs["Metallic"].default_value, b.inputs["Roughness"].default_value = metal, rough
    m.diffuse_color = col
    m.metallic, m.roughness = metal, rough
    return m


def part():
    return fam.Part(ORDER, material)


def _rx(a):
    return Matrix.Rotation(a, 4, "X")


def _ry(a):
    return Matrix.Rotation(a, 4, "Y")


def _rz(a):
    return Matrix.Rotation(a, 4, "Z")


def _t(x, y, z):
    return Matrix.Translation((x, y, z))


# --- The container ---------------------------------------------------------------------------------

def _shell():
    """The mint canister, hollow above the floor with the capsule window cut through its front."""
    p = part()
    p.rounded_box(W, D, FEET_H, CAP_Z + 0.003, PLAN_R, 0.04, 0.0, "mint", seg_round=5)
    shell = p.finish("shell_tmp")
    c = part()
    c.rounded_box(W - 0.024, D - 0.024, FLOOR, CAP_Z - 0.014, PLAN_R - 0.012, 0.0, 0.02, "cream")
    inner = c.finish("cut_inner")
    w = part()
    ww, wh, wz = WINDOW
    w.slab(fam.stadium(ww, wh), -0.03, 0.1, "cream", matrix=fam.front(WIN_X, FRONT + 0.02, wz))
    win = w.finish("cut_window")
    return fam.apply_booleans(shell, [inner, win])


def _static(body):
    """Everything that never moves, into `body`."""
    # The cream top cap and the chrome belt lines.
    body.rounded_box(W, D, CAP_Z - 0.002, H, PLAN_R, 0.0, 0.06, "cream", seg_round=5)
    for z in (FLOOR, CAP_Z):
        fam.trim_bead(body, fam.rounded_rect(W + 0.004, D + 0.004, PLAN_R + 0.002, 8),
                      matrix=Matrix.Translation((0, 0, z)))
    # The window's chrome bezel.
    ww, wh, wz = WINDOW
    fam.trim_bead(body, fam.stadium(ww + 0.004, wh + 0.004, 8), matrix=fam.front(WIN_X, FRONT - 0.001, wz))
    # The gauge: a dark capsule slot in a chrome bezel, left of the window (the Looks fills it).
    gx, gw, gh = GAUGE
    gm = fam.front(gx, FRONT, wz)
    body.slab(fam.stadium(gw, gh, 6), -0.004, 0.003, "dark", matrix=gm)
    body.sweep(fam.stadium(gw + 0.006, gh + 0.006, 6), 0.004, "chrome", matrix=gm, n=6)
    # The cream fascia under the belt with a thin chrome edge, the badge in the middle.
    fw, f0, f1 = FASCIA
    fm = fam.front(0, FRONT, (f0 + f1) / 2)
    body.rounded_box(fw, f1 - f0, -0.05, 0.012, 0.04, 0.0, 0.006, "cream", matrix=fm)
    body.sweep(fam.rounded_rect(fw, f1 - f0, 0.04, 6), 0.003, "chrome",
               matrix=fm @ Matrix.Translation((0, 0, 0.009)), n=6)
    fam.badge(body, fam.front(0, FASCIA_FRONT, (f0 + f1) / 2))
    # The round button on top: its bezel and its red cap (the old `mode_button`, never moved).
    bx, by = BUTTON
    fam.button_bezel(body, Matrix.Translation((bx, by, H)))
    fam.button_cap(body, Matrix.Translation((bx, by, H)), "red")
    # The hose port on top: a chrome collar with a dark throat.
    px, py = PORT
    prof = [(0.052, H - 0.006), (0.052, H + 0.008), (0.047, H + 0.016), (0.044, H + 0.036),
            (0.047, H + 0.042), (0.046, H + 0.049), (0.04, H + 0.05)]
    body.lathe(prof, "chrome", matrix=Matrix.Translation((px, py, 0)), n=24, cap_end="dark")
    # The outlet at the rear: a chrome capsule spout with a dark mouth and an inner rim.
    ox, oy, oz = OUTLET
    om = Matrix.Translation((ox, D / 2 - 0.015, oz)) @ _rx(-math.pi / 2)
    depth = oy - (D / 2 - 0.015)
    body.rounded_box(0.15, 0.085, 0.0, depth, 0.0425, 0.0, 0.012, "chrome", matrix=om)
    body.slab(fam.stadium(0.112, 0.052), depth - 0.002, depth + 0.0015, "dark", matrix=om)
    body.sweep(fam.stadium(0.116, 0.056), 0.0035, "chrome", matrix=om @ Matrix.Translation((0, 0, depth)), n=6)
    # A cream vent plate on the back above the outlet.
    back = Matrix.Translation((0, D / 2 - 0.002, 0.4)) @ _rx(-math.pi / 2)
    body.rounded_box(0.26, 0.13, 0.0, 0.006, 0.03, 0.0, 0.003, "cream", matrix=back)
    for k in range(3):
        body.slab(fam.stadium(0.2, 0.013), 0.005, 0.0075, "dark",
                  matrix=back @ Matrix.Translation((0, (k - 1) * 0.034, 0)))
    # Chrome bullet feet.
    for sx in (-1, 1):
        for sy in (-1, 1):
            fam.bullet_foot(body, sx * 0.17, sy * 0.13)
    # The carry handle on the right side.
    path = [Vector((W / 2 - 0.016 + 0.03 * math.sin(t), -0.075 * math.cos(t), 0.47))
            for t in (math.pi * k / 12 for k in range(13))]
    body.sweep(path, 0.008, "chrome", closed=False, n=8)
    # The nozzle's parking clip on the left side (Q941): a chrome C-clip, open to the outside, on a short arm from a
    # chrome mount plate; the nozzle's cuff rests above it, touching nothing.
    gx, gy, gz = GRIP
    hz = gz - 0.05
    arc = [Vector((CLIP_R * math.cos(a), CLIP_R * math.sin(a), 0))
           for a in (math.radians(-140 + 280 * k / 16) for k in range(17))]
    body.sweep(arc, 0.006, "chrome", matrix=Matrix.Translation((gx, gy, hz)), closed=False, n=8)
    for a in (-140, 140):
        end = Vector((gx + CLIP_R * math.cos(math.radians(a)), gy + CLIP_R * math.sin(math.radians(a)), hz))
        body.lathe([(0.0005, -0.0085), (0.006, -0.006), (0.0085, 0.0), (0.006, 0.006), (0.0005, 0.0085)],
                   "chrome", matrix=Matrix.Translation(end), n=10)
    body.sweep([Vector((-W / 2 + 0.004, gy, hz)), Vector((gx + CLIP_R + 0.004, gy, hz))], 0.007, "chrome",
               closed=False, n=8)
    body.rounded_box(0.05, 0.03, -0.002, 0.007, 0.012, 0.0, 0.003, "chrome",
                     matrix=Matrix.Translation((-W / 2 + 0.003, gy, hz)) @ Matrix.Rotation(-math.pi / 2, 4, "Y"),
                     seg=4, seg_round=2)


def _nozzle(root):
    """The nozzle hanging along the side (Q941): origin at the grip, the mouth NOZZLE_LEN below, its width along Y."""
    gx, gy, gz = GRIP
    n = part()
    down = Matrix.Translation((gx, gy, gz)) @ _rx(math.pi)  # local +Z points down
    # The chrome cuff where the hose goes in, a mint grip, a chrome ring.
    n.lathe([(0.02, -0.002), (0.034, 0.0), (0.035, 0.012), (0.033, 0.036), (0.026, 0.04)], "chrome",
            matrix=down, n=20, cap_start="dark")
    n.lathe([(0.026, 0.038), (0.027, 0.06), (0.027, 0.19), (0.026, 0.2)], "mint", matrix=down, n=20)
    n.sweep(fam.circle(0.028, 20), 0.005, "chrome", matrix=down @ Matrix.Translation((0, 0, 0.198)), n=6)
    # The head: a chrome sweep from the round neck to a flat capsule mouth.
    rings = []
    steps = 10
    for k in range(steps + 1):
        t = k / steps
        e = t * t * (3 - 2 * t)
        w = 0.054 + (0.12 - 0.054) * e
        h = 0.052 + (0.03 - 0.052) * e
        z = 0.2 + (NOZZLE_LEN - 0.012 - 0.2) * t
        rings.append([down @ Vector((p.x, p.y, z)) for p in fam.rounded_rect(h, w, min(w, h) / 2, 5)])
    n._strip(rings, "chrome")
    mz = NOZZLE_LEN - 0.012
    n.rounded_box(0.03, 0.12, mz, NOZZLE_LEN, 0.015, 0.0, 0.006, "chrome", matrix=down, seg=5, seg_round=2)
    n.slab(fam.stadium(0.014, 0.1, 5), NOZZLE_LEN - 0.001, NOZZLE_LEN + 0.001, "dark", matrix=down)
    return n.finish("Nozzle", root, location=GRIP)


# --- The pod (in the Nozzle's frame: origin at the grip, the mouth down -Z) -----------------------

def _screen_frame():
    """The screen's frame on the grip, tilted towards the hand, the picture's up towards the mouth; +Z out of the
    screen. The old pod sat on the frame's +X; the old game turned it half round about the grip (Godot's up, Blender
    Z) on import, so here it sits on -X: the turn is the first factor."""
    m = _t(GRIP_R - 0.006, 0, -POD_Z) @ _ry(math.pi / 2)
    return _rz(math.pi) @ m @ _ry(-TILT) @ _rz(-math.pi / 2)


def _screen_plane(name, w, h, matrix, round_r):
    """A flat screen (material `screen`), w x h in the XY plane of `matrix`, facing its +Z, UV 0..1; its mesh around
    its middle (vd_common.screen_plane)."""
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    outline = fam.rounded_rect(w, h, round_r, 4)
    loc = matrix.to_translation()
    vs = [bm.verts.new(matrix @ v - loc) for v in outline]
    f = bm.faces.new(vs)
    for loop, v in zip(f.loops, outline):
        loop[uv].uv = (v.x / w + 0.5, v.y / h + 0.5)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    me.materials.append(material("screen"))
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    return ob, loc


def _pod(nozzle):
    """The pod under the Nozzle: the housing, its bezel and the two bands (Pod), and the screen (PodScreen)."""
    s = _screen_frame()
    p = part()
    p.rounded_box(0.096, 0.112, -0.004, 0.022, 0.016, 0.006, 0.008, "cream", matrix=s @ _t(0, 0, -0.012), seg=5)
    p.sweep(fam.rounded_rect(0.1, 0.054, 0.008, 5), 0.003, "chrome", matrix=s @ _t(0, 0, 0.0105), n=6)
    for dz in (-BAND_DZ, BAND_DZ):
        p.sweep(fam.circle(GRIP_R + 0.003, 24), 0.0035, "chrome", matrix=_t(0, 0, -(POD_Z + dz)), n=6)
    pod = p.finish("Pod", nozzle, location=(0, 0, -POD_Z))
    scr, loc = _screen_plane("PodScreen", SCREEN_W, SCREEN_H, s @ _t(0, 0, 0.0108), 0.004)
    scr.parent = pod
    scr.location = loc - Vector((0, 0, -POD_Z))
    return pod


# --- The hose ---------------------------------------------------------------------------------------

def _ring(y, r):
    return [Vector((r * math.cos(2 * math.pi * k / HOSE_SIDES), y, r * math.sin(2 * math.pi * k / HOSE_SIDES)))
            for k in range(HOSE_SIDES)]


def _bone_weights(y):
    """[(bone index, weight)] of a point at `y` along the hose: blended between the two nearest bones' middles."""
    span = HOSE_LEN / HOSE_BONES
    b = y / span - 0.5
    i0 = int(math.floor(b))
    w1 = b - i0
    if i0 < 0:
        return [(0, 1.0)]
    if i0 >= HOSE_BONES - 1:
        return [(HOSE_BONES - 1, 1.0)]
    return [(i0, 1.0 - w1), (i0 + 1, w1)]


def build_hose():
    """The hose's armature and skinned mesh; returns its triangle count."""
    fam.wipe()
    for a in list(bpy.data.armatures):
        bpy.data.armatures.remove(a)
    arm = bpy.data.armatures.new("HoseRig")
    rig = bpy.data.objects.new("HoseRig", arm)
    bpy.context.scene.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")
    span = HOSE_LEN / HOSE_BONES
    prev = None
    names = []
    for i in range(HOSE_BONES):
        eb = arm.edit_bones.new("hose_%02d" % i)
        eb.head = (0, i * span, 0)
        eb.tail = (0, (i + 1) * span, 0)
        eb.roll = 0.0
        if prev is not None:
            eb.parent = prev
            eb.use_connect = True
        prev = eb
        names.append(eb.name)
    bpy.ops.object.mode_set(mode="OBJECT")

    p = part()
    n_rings = HOSE_BONES * HOSE_PIECES + 1
    ys = [HOSE_LEN * k / (n_rings - 1) for k in range(n_rings)]
    tube = [_ring(y, HOSE_R * (1.0 if k % 2 == 0 else HOSE_GROOVE)) for k, y in enumerate(ys)]
    p._strip(tube, "cream")
    # The chrome cuffs: short sleeves at both ends, along the hose (the old [CUFF_R, CUFF_R, HOSE_R * 1.1] rings).
    for end, inward in ((0.0, 1.0), (HOSE_LEN, -1.0)):
        cuff = [_ring(end - inward * 0.005, CUFF_R), _ring(end + inward * CUFF_LEN * 0.85, CUFF_R),
                _ring(end + inward * CUFF_LEN, HOSE_R * 1.1)]
        p._strip(cuff, "chrome", cap_start="chrome" if inward > 0 else None, cap_end=None if inward > 0 else "chrome")
    hose = p.finish("Hose", rig)
    me = hose.data
    groups = [hose.vertex_groups.new(name=n) for n in names]
    for v in me.vertices:
        for bi, w in _bone_weights(v.co.y):
            groups[bi].add([v.index], w, "REPLACE")
    # The tug: the middle sideways, the ends still (sin(PI * s) along the hose, the old _mesh_hose).
    hose.shape_key_add(name="Basis")
    key = hose.shape_key_add(name="tug")
    for i, v in enumerate(me.vertices):
        s = min(max(v.co.y / HOSE_LEN, 0.0), 1.0)
        key.data[i].co = v.co + Vector((TUG * math.sin(math.pi * s), 0, 0))
    mod = hose.modifiers.new("HoseRig", "ARMATURE")
    mod.object = rig
    bpy.context.view_layer.update()
    return sum(len(pl.vertices) - 2 for pl in me.polygons)


def export_hose(out_root):
    for o in bpy.context.view_layer.objects:
        o.select_set(o.name in ("HoseRig", "Hose"))
    out = os.path.join(out_root, HOSE_GLB)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=out, export_format="GLB", use_selection=True, export_apply=False,
        export_yup=True, export_cameras=False, export_lights=False, export_animations=False,
        export_skins=True, export_morph=True, export_def_bones=False, export_extras=False)
    return out


# --- Build and export ----------------------------------------------------------------------------------

def build():
    """Wipes the open file and builds the vacuum; returns its triangle count."""
    fam.wipe()
    root = fam.root(ASSET)
    body = part()
    shell = _shell()
    body.add_mesh(shell.data)
    m = shell.data
    bpy.data.objects.remove(shell, do_unlink=True)
    bpy.data.meshes.remove(m)
    _static(body)
    body.finish("Body", root)
    ww, wh, wz = WINDOW
    g = part()
    g.slab(fam.stadium(ww + 0.006, wh + 0.006), 0.0, 0.003, "glass", matrix=fam.front(WIN_X, FRONT + 0.008, wz))
    g.finish("Glass", root)
    nozzle = _nozzle(root)
    _pod(nozzle)
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
    said.append("vacuum " + build())
    if "--no-export" not in argv:
        said.append("glb " + export(out_root))
    if "--save" in argv:
        said.append(_save(SOURCE))
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.unit_settings.system = "METRIC"
    said.append("hose render_tris=%d" % build_hose())
    if "--no-export" not in argv:
        said.append("glb " + export_hose(out_root))
    if "--save" in argv:
        said.append(_save(HOSE_SOURCE))
    print("PASS sock_vacuum " + " | ".join(said))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:  # a crash is a failure, never a silent pass
        import traceback
        traceback.print_exc()
        print("FAIL sock_vacuum: %s" % e)
        sys.exit(1)
