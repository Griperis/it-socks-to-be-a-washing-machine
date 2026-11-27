"""The Elevator's models (assets/21), ported from the old game's tools/blender/make_elevator.py
(reference/it-socks, tag v0.1.1; `assets/house/elevator.glb`) and the pieces the old game built in code:
the call button's brass cap (game/house/elevator_button.gd), the floor letters (elevator_letter.gd), the
padlock sign and the "OUT OF ORDER" plaque (game/campaign/lock_sign.gd). Those are modelled parts now
(Q2705). Meshes only (Q2152): no colliders (the entity's scenes own them), no layout record.

Run from the repository root (Blender is the kit's pinned one, kit/tools/blender.sh):

    kit/tools/blender.sh -b -P tools/blender/elevator.py -- [--save] [--no-export] [--out <dir>]
        [--lineup <dir> [--views a,b]]

It builds the four models from scratch, writes `assets/elevator/<asset>.glb` (under `--out` when given)
and with `--save` the one source `assets_src/blender/elevator/elevator.blend` (four roots). `--lineup
<dir>` renders the review line-up's tiles there instead (the old glb beside the port, the same views).
Last line: `PASS elevator ...` or `FAIL ...`.

Sizes are the old ones: the port's shaft is the old one moved (house-kit-plan K09: 0.7 x 0.7 m, the
hatch 0.54 x 0.58 at sill 0.8 m), so nothing needed refitting. The shaft's cream walls and the stainless
sill plate are the house kit's (game/house/kit/pieces/shaft_*.tscn, house/04), not built here.

Every model is written in glTF axes (x right, y up, z towards the viewer: Blender's -y, the asset's
front); only the root's children are exported. Each root stands on its lowest vertex (the kit's asset
contract), so the pivots named below sit at the offset given from the root, which the Looks places:

  elevator_stop    one hatch, the stop's Looks. Its pivot: the stop's floor, in the hatch's face plane
                   (the shaft wall's outer face), across the middle of the opening; the face looks +z,
                   the shaft is behind it, -z; the call button's column on the viewer's right, +x. The
                   root is 0.77 m over that floor (the jambs' foot, the sill's underside):
    frame            static: the stainless jambs either side of the opening, the header plate the
                     open panel slides up in front of, the cap over it, the button column's bezel and
                     the stainless back on the far wall (seen through the open hatch)
    hatch            the panel (stainless, its steel bar handle), origin on the shut panel's middle;
                     it slides up HATCH_OPEN (the `open` clip)
    call_b, call_g, call_1, call_a   one set per floor (an Empty each: the Looks shows its floor's;
                     the old built the stud and the lock at the own floor's step of the column):
      stud_<l>       the stainless stud in the bezel
      button_<l>     the brass cap and its printed letter, origin on the cap's back (the `press` clip)
      chain_<l>      the column's lock chain, origin at its apex over the button
      padlock_<l>    the padlock on it, origin at its body's middle (both drop at `unlock`)
  elevator_car     the car. Axes as the house's: open at -x and +x, the side walls at -z and +z, so the
                   letters' column hangs on the +z wall facing -z. The root is the floor plate's
                   underside, 0.03 m under the car's floor (the old origin, where riders and cargo lie):
    car              the floor and roof plates and the two side walls, stainless
    lamp             the caged brass lamp under the roof's middle, origin on the roof (Elevator Duet
                     flickers it, a Secret for later)
  elevator_letter  one floor letter, its face +z; the root is the ring's foot, 0.0455 m under the cap's
                   middle, every child's origin:
    cap              the round cap (`letter_cap`: the plain dark; `lit` and `locked` recolour it)
    ring             the red ring of a locked floor (shown by `locked`)
    glyph_b, glyph_g, glyph_1, glyph_a   the printed letter, one per floor (code shows its stop's)
  elevator_signs   the stop's two signs side by side, each origin on its back's middle, its face +z (the
                   stop's Looks hangs them on the hatch's face, where the old hung them: the padlock
                   sign's back 0.0018 m and the plaque's 0.005 m in front of the hatch's origin):
    lock_sign        the cream plaque with an ink padlock (a locked floor, drops at `unlock`)
    out_of_order     the cream plaque with "OUT OF / ORDER" printed in red (before Elevator Repair)

Materials: `stainless` (game/house/kit/materials/stainless.tres, the shaft's sill's), `brass` and
`steel` (the shared library's, Q2177); the old `chain`, `lock_dark` and `bulb` as the floor locks and
the old flat had them; the letters' and the signs' own colours from the old code (UiBits INK, CREAM,
REFUSE; ElevatorLetter PLAIN, the red ring, the cream ink). The printed letters are Inter, the font
Blender ships (the old drew them with Godot's default font, Open Sans, which is not in the game), at the
old capitals' height.

What differs from the old, technical only (Q2153): four models instead of one house-wide one (the
car, a stop placed per floor, a letter, the signs); the shaft's sheath and sill are the house kit's;
no collider meshes; the roots stand on their lowest vertex; the column's two chain eyes are left out (they sat inside the jamb, unseen); the
stop's set of its floor is chosen by the Looks rather than built per floor.
"""

import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, os.path.join(REPO, "assets_src", "generate", "lock"))
import make_locks as L  # noqa: E402  (the old flat's Part, box, cyl, chain and padlock, ported)

SOURCE = os.path.join("assets_src", "blender", "elevator", "elevator.blend")
GLB_DIR = os.path.join("assets", "elevator")
ASSETS = ("elevator_stop", "elevator_car", "elevator_letter", "elevator_signs")

# --- The old sizes (make_house.py SHAFT, SILL_H, CAR_Z, CAR_H, CAR_T; make_elevator.py) -------------
SHAFT_HALF = 0.35          # the shaft, 0.7 across (its outside)
HALF = 0.27                # the hatch's opening and the car's inside, 0.54 across (CAR_Z)
SILL = 0.8                 # the sill (the car's floor) over the stop's floor
CAR_H = 0.58               # the car's inside height
CAR_T = 0.03               # its floor and roof plates
CAR_DEEP = 0.6             # the car along the hatch's axis (CAR_X: the shaft less 0.05 each side)
TOP = SILL + CAR_H         # the opening's head
HATCH_OPEN = 0.64          # how far the panel slides up
HEAD = TOP + HATCH_OPEN + 0.04
BUTTONS = (0.1, 0.1)       # the column: its first step over the sill, the step up
BACK = 0.70                # the far wall's face behind the hatch's (the shaft's depth)
FLOORS = ("b", "g", "1", "a")    # ElevatorButton.LETTERS, bottom up
LETTERS = ("B", "G", "1", "A")


def _srgb_hex(h):
    h = h.lstrip("#")
    return L.srgb(*(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)))


def _lighter(h, by):
    h = h.lstrip("#")
    c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return L.srgb(*(v + (1 - v) * by for v in c))


# The old colours: (colour, roughness, metallic). Godot colours from the old code are sRGB.
L.MATERIALS.update({
    "stainless": (L.srgb(0.80, 0.81, 0.82), 0.32, 0.85),
    "bulb": (L.srgb(1.0, 0.90, 0.70), 0.3, 0.0),
    "button_ink": (L.srgb(0.12, 0.10, 0.06), 0.6, 0.0),
    "letter_cap": (L.srgb(0.14, 0.14, 0.15), 0.4, 0.0),
    "letter_ring": (L.srgb(0.75, 0.12, 0.10), 0.5, 0.0),
    "letter_ink": (L.srgb(0.95, 0.95, 0.92), 0.5, 0.0),
    "sign_ink": (_srgb_hex("#3b2a22"), 0.6, 0.0),
    "sign_cream": (_srgb_hex("#fff4e0"), 0.8, 0.0),
    "sign_metal": (_lighter("#3b2a22", 0.15), 0.35, 0.6),
    "sign_red": (L.srgb(0.95, 0.25, 0.20), 0.8, 0.0),
})
EMISSION = {"bulb": 6.0}   # the old flat's bulb (make_flat.py MATERIALS)


def material(name):
    m = L.material(name)
    if name in EMISSION:
        b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
        b.inputs["Emission Color"].default_value = L.MATERIALS[name][0]
        b.inputs["Emission Strength"].default_value = EMISSION[name]
    return m


# --- Helpers ---------------------------------------------------------------------------------------

def root(name):
    r = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(r)
    r.empty_display_size = 0.1
    return r


def empty(name, parent):
    e = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(e)
    e.parent = parent
    e.empty_display_size = 0.03
    return e


def put(part, name, parent, origin=(0.0, 0.0, 0.0)):
    """The part as the object `name` under `parent` (an Empty at the root's origin), its origin at
    `origin` (the asset's glTF axes)."""
    for m in part.mats:
        material(m)
    return part.to_object(name, parent, origin=origin)


def cyl_bevel(axis, ca, cb, t0, t1, r, n, bevel):
    bm = L.cyl(axis, ca, cb, t0, t1, r, n=n)
    caps = [f for f in bm.faces if len(f.verts) == n]
    L._bevel(bm, {e for f in caps for e in f.edges}, bevel, 1)
    return bm


def wire(points, r, n=6):
    """A thin round wire through `points`, open at its ends (the old make_elevator.wire)."""
    bm = bmesh.new()
    rings = []
    for i, pt in enumerate(points):
        a = Vector(points[max(i - 1, 0)])
        b = Vector(points[min(i + 1, len(points) - 1)])
        t = (b - a).normalized()
        u = t.orthogonal().normalized()
        w = t.cross(u)
        rings.append([bm.verts.new(Vector(pt) + (u * math.cos(2 * math.pi * k / n) + w * math.sin(2 * math.pi * k / n)) * r)
                      for k in range(n)])
    for ra, rb in zip(rings, rings[1:]):
        for k in range(n):
            bm.faces.new((ra[k], ra[(k + 1) % n], rb[(k + 1) % n], rb[k]))
    return bm


def torus(major, minor, n=20, m=8):
    """A round torus in the xy plane (facing z), as Godot's TorusMesh the old code used."""
    return L.torus_link(2 * (major + minor), 2 * (major + minor), minor, n=n, m=m)


# The printed letters' font: Inter, which ships with Blender (its datafiles), so the script builds the
# same anywhere. Blender's own Bfont draws "1" as a bare bar that reads as "I". Sized so its capitals
# stand as tall as the old's (Godot's default font, Open Sans: capitals 0.714 of the font's size;
# Inter's come out 0.51 of a Blender text size).
CAP_OLD, CAP_INTER = 0.714, 0.51


def _font():
    f = bpy.data.fonts.get("Inter Variable Regular")
    if f is None:
        f = bpy.data.fonts.load(os.path.join(bpy.utils.system_resource("DATAFILES", path="fonts"), "Inter.woff2"))
    return f


def text(body, em, centre, depth=0.0004, lines=1.0, res=3):
    """Printed letters as a mesh in Inter, `em` the font's size (the old TextMesh's
    font_size x pixel_size), centred on `centre`, the face towards +z, `depth` thick behind it."""
    cu = bpy.data.curves.new("_text", "FONT")
    cu.body = body
    cu.font = _font()
    cu.size = em * CAP_OLD / CAP_INTER
    cu.align_x = "CENTER"
    cu.align_y = "CENTER"
    cu.space_line = lines
    cu.resolution_u = res
    cu.extrude = depth / 2
    ob = bpy.data.objects.new("_text", cu)
    bpy.context.scene.collection.objects.link(ob)
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
    bpy.data.objects.remove(ob)
    bpy.data.curves.remove(cu)
    bm = bmesh.new()
    bm.from_mesh(me)
    bpy.data.meshes.remove(me)
    bmesh.ops.translate(bm, vec=Vector(centre) + Vector((0, 0, depth / 2)), verts=bm.verts)
    bmesh.ops.triangulate(bm, faces=[f for f in bm.faces if len(f.verts) > 4])
    return bm


# --- The stop ---------------------------------------------------------------------------------------

def build_stop():
    r = root("elevator_stop")
    f = L.Part()
    # The jambs either side of the opening, out of the face; the header the open panel slides up over;
    # the cap over it all (make_elevator.py make_shaft()).
    for xa, xb in ((-SHAFT_HALF, -HALF), (HALF, SHAFT_HALF)):
        f.add(L.box(xa, xb, SILL - CAR_T, HEAD, 0.0, 0.025, bevel=0.004, seg=1), "stainless")
    f.add(L.box(-HALF, HALF, TOP, HEAD, 0.0, 0.005), "stainless")
    f.add(L.box(-SHAFT_HALF, SHAFT_HALF, HEAD, HEAD + 0.03, 0.0, 0.025, bevel=0.004, seg=1), "stainless")
    # The far wall's stainless back between the car's sides, seen through the open hatch.
    f.add(L.box(-HALF, HALF, SILL - CAR_T, TOP + CAR_T + 0.01, -BACK, -BACK + 0.04), "stainless")
    # The button column's bezel beside the hatch (Q512), on the viewer's right.
    bx0, bx1 = SHAFT_HALF, SHAFT_HALF + 0.14
    f.add(L.box(bx0, bx1, SILL + 0.02, SILL + BUTTONS[0] + 3 * BUTTONS[1] + 0.08, 0.0, 0.02, bevel=0.006, seg=1),
          "stainless")
    put(f, "frame", r)

    # The panel, shut, with its steel bar handle.
    h = L.Part()
    pz0, pz1 = 0.006, 0.016
    px = HALF + 0.012
    py0, py1 = SILL, TOP + 0.02
    h.add(L.box(-px, px, py0, py1, pz0, pz1, bevel=0.003, seg=1), "stainless")
    hz = 0.03
    h.add(L.cyl("x", py0 + 0.07, hz, -px + 0.12, px - 0.12, 0.008, n=8), "steel")
    for xx in (-px + 0.12, px - 0.12):
        h.add(L.box(xx - 0.006, xx + 0.006, py0 + 0.064, py0 + 0.076, pz1, hz), "steel")
    put(h, "hatch", r, origin=(0.0, (py0 + py1) / 2, (pz0 + pz1) / 2))

    bxc = (bx0 + bx1) / 2
    face = 0.02
    ytop, ybot = SILL + BUTTONS[0] + 3 * BUTTONS[1] + 0.06, SILL + 0.06
    ex, ez = SHAFT_HALF - 0.025, 0.012           # the chain's eyes (inside the jamb, not drawn)
    for k, l in enumerate(FLOORS):
        g = empty("call_" + l, r)
        by = SILL + BUTTONS[0] + 0.02 + k * BUTTONS[1]
        s = L.Part()
        s.add(L.cyl("z", bxc, by, face, face + 0.004, 0.03, n=16), "stainless")
        put(s, "stud_" + l, g, origin=(bxc, by, face))
        # The brass cap with the floor's letter printed on it (ElevatorButton: RADIUS 0.022,
        # PROUD 0.012, font 48 x 0.0005), standing on the stud.
        b = L.Part()
        z0 = face + 0.004
        b.add(L.cyl("z", bxc, by, z0, z0 + 0.012, 0.022, n=20), "brass")
        b.add(text(LETTERS[k], 48 * 0.0005, (bxc, by, z0 + 0.012 + 0.0003)), "button_ink")
        put(b, "button_" + l, g, origin=(bxc, by, z0))
        # The column's lock (progression/03, Q638, Q643): a chain from an eye over the column to one
        # under it, drawn out over its front to a padlock on the button.
        apex = (bxc + 0.02, by + 0.04, 0.05)
        hi, lo = (ex, ytop, ez), (ex, ybot, ez)
        ch = L.chain_part(L.sag(hi, apex, 0.0, 3) + L.sag(apex, lo, 0.0, 3)[1:], (0.0, 0.0, 1.0),
                          link=0.05, width=0.03, wire=0.006)
        put(ch, "chain_" + l, g, origin=apex)
        at = (apex[0], by - 0.035, apex[2] + 0.008)
        put(L.padlock_part(at, (0.0, 0.0, 1.0), 0.8), "padlock_" + l, g, origin=at)
    return r


# --- The car ----------------------------------------------------------------------------------------

def build_car():
    r = root("elevator_car")
    c = L.Part()
    dx = CAR_DEEP / 2
    zo = HALF + 0.02
    for ya, yb in ((-CAR_T, 0.0), (CAR_H, CAR_H + CAR_T)):
        c.add(L.box(-dx, dx, ya, yb, -zo, zo, bevel=0.004, seg=1), "stainless")
    for za, zb in ((-zo, -HALF), (HALF, zo)):
        c.add(L.box(-dx, dx, 0.0, CAR_H, za, zb), "stainless")
    put(c, "car", r)
    # The lamp (secrets/03): a brass rose on the roof, a frosted glass dome and a brass cage of two
    # crossed hoops and a ring (make_elevator.py car_lamp()), in the car's axes.
    p = L.Part()
    y = CAR_H
    p.add(cyl_bevel("y", 0.0, 0.0, y - 0.012, y, 0.045, 20, 0.003), "brass")
    p.add(L.cyl("y", 0.0, 0.0, y - 0.018, y - 0.012, 0.036, n=20), "brass")
    p.add(L.ellipsoid((0.0, y - 0.018, 0.0), 0.03, 0.036, 0.03, u=16, v=10), "bulb")
    R = 0.036
    for k in range(2):
        a = math.pi / 2 * k + math.pi / 4
        dx_, dz_ = math.cos(a), math.sin(a)
        pts = [(dx_ * R * math.cos(t), y - 0.016 - R * 1.1 * math.sin(t), dz_ * R * math.cos(t))
               for t in (math.pi * i / 10 for i in range(11))]
        p.add(wire(pts, 0.0025), "brass")
    pts = [(R * math.cos(2 * math.pi * i / 16), y - 0.03, R * math.sin(2 * math.pi * i / 16)) for i in range(17)]
    p.add(wire(pts, 0.0025), "brass")
    put(p, "lamp", r, origin=(0.0, y, 0.0))
    return r


# --- A floor letter ---------------------------------------------------------------------------------

LETTER_R = 0.035           # ElevatorLetter.RADIUS
LETTER_PROUD = 0.01


def build_letter():
    r = root("elevator_letter")
    c = L.Part()
    c.add(L.cyl("z", 0.0, 0.0, -LETTER_PROUD / 2, LETTER_PROUD / 2, LETTER_R, n=20), "letter_cap")
    put(c, "cap", r)
    g = L.Part()
    # The old TorusMesh: inner 1.05, outer 1.3 radii.
    inner, outer = LETTER_R * 1.05, LETTER_R * 1.3
    g.add(torus((inner + outer) / 2, (outer - inner) / 2, n=20, m=8), "letter_ring")
    put(g, "ring", r)
    for k, l in enumerate(FLOORS):
        t = L.Part()
        t.add(text(LETTERS[k], 48 * 0.0006, (0.0, 0.0, LETTER_PROUD / 2 + 0.0004)), "letter_ink")
        put(t, "glyph_" + l, r)
    return r


# --- The signs --------------------------------------------------------------------------------------

def build_signs():
    r = root("elevator_signs")
    # The padlock sign (LockSign: PLAQUE 0.2 x 0.22 x 0.012, an ink border behind it).
    # The old's origin was 0.6 of the plaque's thickness in front of the border's back; here the back.
    s = L.Part()
    pw, ph, pt = 0.2, 0.22, 0.012
    back = pt * 0.6
    s.add(L.box(-(pw + 0.016) / 2, (pw + 0.016) / 2, -(ph + 0.016) / 2, (ph + 0.016) / 2, 0.0, back), "sign_ink")
    z0 = back - pt * 0.3                       # the cream plaque stands pt * 0.7 proud of the border
    s.add(L.box(-pw / 2, pw / 2, -ph / 2, ph / 2, z0, z0 + pt), "sign_cream")
    face = z0 + pt
    # The padlock: a shackle (TorusMesh 0.032 .. 0.046) over an ink body with a cream keyhole.
    sh = torus(0.039, 0.007, n=24, m=6)
    bmesh.ops.translate(sh, vec=(0.0, 0.03, face + 0.004), verts=sh.verts)
    s.add(sh, "sign_metal")
    s.add(L.box(-0.055, 0.055, -0.07, 0.02, face, face + 0.02), "sign_ink")
    s.add(L.cyl("z", 0.0, -0.018, face + 0.019, face + 0.023, 0.011, n=12), "sign_cream")
    s.add(L.box(-0.004, 0.004, -0.048, -0.024, face + 0.019, face + 0.023), "sign_cream")
    put(s, "lock_sign", r).location.x = -0.2       # side by side in the file; the Looks hangs each
    # The "Out of order" plaque (LockSign._build_tag: 0.36 x 0.17 ink, 0.344 x 0.154 cream, the words in
    # REFUSE red, font 56 on a 154 px plaque: 0.056 m).
    o = L.Part()
    o.add(L.box(-0.18, 0.18, -0.085, 0.085, 0.0, 0.012), "sign_ink")
    o.add(L.box(-0.172, 0.172, -0.077, 0.077, 0.002, 0.014), "sign_cream")
    o.add(text("OUT OF\nORDER", 0.056, (0.0, 0.0, 0.0145), res=2), "sign_red")
    put(o, "out_of_order", r).location.x = 0.2
    return r


# --- Build, export ---------------------------------------------------------------------------------

def tris(obj):
    obj.data.calc_loop_triangles()
    return len(obj.data.loop_triangles)


def seat(r):
    """Stands the model on its root's origin (the kit's asset contract: the lowest vertex on z 0): the
    root's children move up or down together, each keeping its own pivot."""
    bpy.context.view_layer.update()
    low = min((o.matrix_world @ v.co).z for o in r.children_recursive if o.type == "MESH" for v in o.data.vertices)
    for c in r.children:
        c.location.z -= low
    SEATED[r.name] = low


SEATED = {}   # each root's children moved down by this (the line-up puts them back)


def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.unit_settings.system = "METRIC"
    roots = [build_stop(), build_car(), build_letter(), build_signs()]
    said = []
    for r in roots:
        seat(r)
        meshes = [o for o in r.children_recursive if o.type == "MESH"]
        mats = {s.material.name for o in meshes for s in o.material_slots}
        said.append("%s %d tris %d materials" % (r.name, sum(tris(o) for o in meshes), len(mats)))
    return roots, ", ".join(said)


def export(out_root):
    outs = []
    for name in ASSETS:
        r = bpy.data.objects[name]
        for o in bpy.context.view_layer.objects:
            o.select_set(False)
        for o in r.children_recursive:
            o.hide_viewport = False
            o.hide_set(False)
            o.select_set(True)
        out = os.path.join(out_root, GLB_DIR, name + ".glb")
        os.makedirs(os.path.dirname(out), exist_ok=True)
        bpy.ops.export_scene.gltf(
            filepath=out, export_format="GLB", use_selection=True, export_apply=True,
            export_yup=True, export_cameras=False, export_lights=False, export_animations=False,
            export_extras=False)
        outs.append(out)
    return outs


# --- The review line-up (not part of the assets) ----------------------------------------------------

def _old_glb():
    """The old model in the reference submodule; in an agent's worktree, where the submodule is empty,
    the main checkout's copy."""
    rel = os.path.join("reference", "it-socks", "assets", "house", "elevator.glb")
    here = os.path.join(REPO, rel)
    if os.path.exists(here):
        return here
    import subprocess
    common = subprocess.run(["git", "-C", REPO, "rev-parse", "--path-format=absolute", "--git-common-dir"],
                            capture_output=True, text=True).stdout.strip()
    return os.path.join(os.path.dirname(common), rel)



OLD_FACE = (3.13, -4.8)    # the old ground stop's hatch face (SHAFT x0) and the opening's middle, Blender
CAR_AT = (0.0, BACK / 2, SILL)   # the car's floor middle behind a stop, Blender (the shaft's middle)
# The views: (name, camera, target), Blender, the stop's face on y 0 looking -y, its floor on z 0.
VIEWS = (
    ("front_shut", (0.15, -2.2, 1.35), (0.08, 0.0, 1.2)),
    ("front_open", (-0.5, -1.6, 1.5), (0.04, 0.3, 1.05)),
    ("button", (0.44, -0.32, 1.07), (0.42, 0.0, 1.02)),
    ("column", (0.75, -0.75, 1.2), (0.3, 0.0, 1.02)),
    ("letters", (-0.2, 0.30, 1.02), (0.3, 0.35, 1.08)),
    ("lamp", (-0.22, 0.12, 0.95), (0.0, 0.35, 1.36)),
)


def _bl(p):
    """glTF axes to Blender's."""
    return Vector((p[0], -p[2], p[1]))


def _mat(name, rgb, rough=0.5, metal=0.0, emit=0.0):
    m = bpy.data.materials.new(name)
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    col = L.srgb(*rgb)
    b.inputs["Base Color"].default_value = col
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    if emit:
        b.inputs["Emission Color"].default_value = col
        b.inputs["Emission Strength"].default_value = emit
    return m


def _copy(obj, parent, over=None, loc=None, rot_z=None):
    """A linked copy of `obj` and everything under it, under `parent`; `over` maps a material name to
    the one this copy wears."""
    c = obj.copy()
    c.parent = parent
    if loc is not None:
        c.location = loc
    if rot_z is not None:
        c.rotation_euler = (0.0, 0.0, rot_z)
    c.hide_render = False
    bpy.context.scene.collection.objects.link(c)
    for slot in c.material_slots:
        name = slot.material.name if slot.material else ""
        if over and name in over:
            slot.link = "OBJECT"
            slot.material = over[name]
    for k in obj.children:
        _copy(k, c, over)
    return c


def _stage():
    scene = bpy.context.scene
    try:
        scene.render.engine = "BLENDER_EEVEE"
    except TypeError:
        scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x, scene.render.resolution_y = 560, 560
    world = bpy.data.worlds.new("_world")
    scene.world = world
    if world.node_tree is None:
        world.use_nodes = True
    bg = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs[0].default_value = (0.42, 0.45, 0.5, 1.0)
    bg.inputs[1].default_value = 0.8
    L.MATERIALS["_floor"] = (L.srgb(0.80, 0.57, 0.34), 0.62, 0.0)
    floor = L.Part()
    floor.add(L.box(-3.0, 3.0, -0.02, 0.0, -3.0, 3.0), "_floor")
    floor.to_object("_floor", None)
    for name, energy, rot in (("_sun", 3.0, (0.9, 0.2, -0.6)), ("_fill", 1.0, (1.2, -0.3, 2.6))):
        ld = bpy.data.lights.new(name, "SUN")
        ld.energy = energy
        lo = bpy.data.objects.new(name, ld)
        lo.rotation_euler = rot
        scene.collection.objects.link(lo)
    ld = bpy.data.lights.new("_room", "POINT")   # the kitchen light reaching into the open car
    ld.energy = 8.0
    lo = bpy.data.objects.new("_room", ld)
    lo.location = (-0.7, -1.0, 2.0)
    scene.collection.objects.link(lo)
    cam = bpy.data.objects.new("_cam", bpy.data.cameras.new("_cam"))
    cam.data.lens = 35
    cam.data.clip_start = 0.01
    scene.collection.objects.link(cam)
    scene.camera = cam
    return cam


def _old():
    """The old glb, its ground stop's face on the port's (turned so its hatch looks -y)."""
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=_old_glb())
    new = [o for o in bpy.data.objects if o not in before]
    pivot = bpy.data.objects.new("_old", None)
    bpy.context.scene.collection.objects.link(pivot)
    turn = Matrix.Rotation(math.pi / 2, 3, "Z")
    pivot.rotation_euler = (0.0, 0.0, math.pi / 2)
    pivot.location = turn @ -Vector((OLD_FACE[0], OLD_FACE[1], 0.0))
    for o in new:
        if o.parent is None:
            mw = o.matrix_world.copy()
            o.parent = pivot
            o.matrix_parent_inverse.identity()
            o.matrix_basis = mw
    return pivot, {o.name: o for o in new}


def _port():
    """The port's four models put together as the house would: the stop, the car standing there, the
    letters on its +z wall (B plain, G lit, 1 locked, A plain), the signs on the hatch, and a stand-in of
    the house kit's shaft wall and sill (cream and stainless; not these models)."""
    grp = bpy.data.objects.new("_port", None)
    bpy.context.scene.collection.objects.link(grp)
    o = bpy.data.objects
    stop = _copy(o["elevator_stop"], grp, loc=(0.0, 0.0, SEATED["elevator_stop"]))
    car = bpy.data.objects.new("_car_at", None)
    bpy.context.scene.collection.objects.link(car)
    car.parent = grp
    car.location = Vector(CAR_AT) + Vector((0.0, 0.0, SEATED["elevator_car"]))
    car.rotation_euler = (0.0, 0.0, math.pi / 2)   # the car's axes are the house's; this stop looks -x there
    for c in o["elevator_car"].children:
        _copy(c, car)
    lit = {"letter_cap": _mat("_lit", (1.0, 0.78, 0.35), 0.4, 0.0, 1.5),
           "letter_ink": _mat("_lit_ink", (0.25, 0.15, 0.05))}
    locked = {"letter_cap": _mat("_locked", (0.32, 0.30, 0.30), 0.4)}
    for i, l in enumerate(FLOORS):
        holder = bpy.data.objects.new("_letter_" + l, None)
        bpy.context.scene.collection.objects.link(holder)
        holder.parent = car
        holder.location = _bl((0.0, 0.12 + 0.12 * i, HALF - 0.006)) + Vector((0.0, 0.0, SEATED["elevator_letter"]))
        holder.rotation_euler = (0.0, 0.0, math.pi)          # facing -z, into the car
        state = {1: lit, 2: locked}.get(i, {})
        _copy(o["cap"], holder, state)
        _copy(o["glyph_" + l], holder, state)
        if i == 2:
            _copy(o["ring"], holder)
    hatch = next(c for c in stop.children if c.name.startswith("hatch"))
    # The signs on the hatch's face at the panel's middle, as the old hung them (EH build_hatch): the
    # padlock sign's back 0.0128 and the plaque's 0.016 in front of the hatch's origin plane.
    signs = {"lock_sign": _copy(o["lock_sign"], hatch, loc=(0.0, -(0.0128 - 0.011), 0.0)),
             "out_of_order": _copy(o["out_of_order"], hatch, loc=(0.0, -(0.016 - 0.011), 0.0))}
    L.MATERIALS["_shaft_wall"] = (L.srgb(0.96, 0.93, 0.87), 0.5, 0.0)
    shell = L.Part()
    for xa, xb, ya, yb in ((-SHAFT_HALF, -HALF, 0.0, 2.6), (HALF, SHAFT_HALF, 0.0, 2.6), (-HALF, HALF, 0.0, SILL),
                           (-HALF, HALF, TOP, 2.6)):
        shell.add(L.box(xa, xb, ya, yb, -0.04, 0.0), "_shaft_wall")
    for xa, xb in ((-SHAFT_HALF, -SHAFT_HALF + 0.04), (SHAFT_HALF - 0.04, SHAFT_HALF)):
        shell.add(L.box(xa, xb, 0.0, 2.6, -BACK, -0.04), "_shaft_wall")
    shell.add(L.box(-HALF - 0.04, HALF + 0.04, SILL - CAR_T, SILL, -0.06, 0.07), "stainless")
    shell.to_object("_kit_shaft", grp)
    return grp, stop, hatch, signs


def _render(cam, path, view):
    _n, at, look = view
    cam.location = at
    cam.rotation_euler = (Vector(look) - Vector(at)).to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return path


def lineup(out, only=()):
    """Renders old_<view>.png and port_<view>.png for each of VIEWS (or those named in `only`) into
    `out`; returns the paths. The software renderer may crash after a dozen renders: `--views` takes
    a comma list to render the rest in another run."""
    os.makedirs(out, exist_ok=True)
    cam = _stage()
    port, stop, hatch, signs = _port()
    for r in ASSETS:
        for o in [bpy.data.objects[r]] + list(bpy.data.objects[r].children_recursive):
            o.hide_render = True
    old, old_objs = _old()
    calls = {l: next(c for c in stop.children if c.name.startswith("call_" + l)) for l in FLOORS}
    old_hatch = old_objs["Hatch_Ground"]
    shut_old = old_hatch.location.copy()
    shut = hatch.location.copy()
    tiles = []

    def show(plaque, sign, chain, opened):
        hatch.location = shut + (Vector((0.0, 0.0, HATCH_OPEN)) if opened else Vector())
        signs["out_of_order"].hide_render = not plaque
        signs["lock_sign"].hide_render = not sign
        for l, g in calls.items():
            for c in g.children:
                c.hide_render = l != "g" or (not chain and c.name.startswith(("chain", "padlock")))

    def both(view, opened, **state):
        old_hatch.location = shut_old + (Vector((0.0, 0.0, HATCH_OPEN)) if opened else Vector())
        for o in old.children_recursive:
            o.hide_render = "convcolonly" in o.name
        for o in port.children_recursive:
            o.hide_render = True
        tiles.append(_render(cam, os.path.join(out, "old_%s.png" % view[0]), view))
        for o in old.children_recursive:
            o.hide_render = True
        for o in port.children_recursive:
            o.hide_render = False
        show(opened=opened, **state)
        tiles.append(_render(cam, os.path.join(out, "port_%s.png" % view[0]), view))

    # Each view's state: shut and out of order; open; locked (the sign and the column's lock).
    states = {"front_shut": (False, True, False, False), "column": (False, False, True, True)}
    for view in VIEWS:
        if only and view[0] not in only:
            continue
        opened, plaque, sign, chain = states.get(view[0], (True, False, False, False))
        both(view, opened, plaque=plaque, sign=sign, chain=chain)
    return tiles


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out_root = REPO
    if "--out" in argv:
        out_root = os.path.abspath(argv[argv.index("--out") + 1])
    _roots, report = build()
    said = [report]
    if "--lineup" in argv:
        out = os.path.abspath(argv[argv.index("--lineup") + 1])
        only = argv[argv.index("--views") + 1].split(",") if "--views" in argv else ()
        said.append("lineup %d tiles in %s" % (len(lineup(out, only)), out))
        print("PASS elevator " + " | ".join(said))
        return
    if "--no-export" not in argv:
        said.append("%d glbs in %s" % (len(export(out_root)), os.path.join(out_root, GLB_DIR)))
    if "--save" in argv:
        path = os.path.join(REPO, SOURCE)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=path, compress=True)
        said.append("blend " + path)
    print("PASS elevator " + " | ".join(said))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:  # a crash is a failure, never a silent pass
        import traceback
        traceback.print_exc()
        print("FAIL elevator: %s" % e)
        sys.exit(1)
