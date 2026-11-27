"""The Backpack vacuum's model (assets/25), ported from the old game (reference/it-socks, tag v0.1.1):
assets/vacuum_devices/make_backpack_vacuum.py and the helpers of assets/vacuum_devices/vd_common.py it uses.

The capsule tank the designer picked (old Q2171, variant b): the Sock vacuum's little sibling of the retro appliance
family (assets_src/generate/cabinet/appliance_family.py, unchanged). A round mint diver's-bottle tank on a cream skirt
with a cream dome, two chrome belt lines, a porthole in a bolted chrome ring on the front, the family's badge low on
the front, a chrome elbow out of the dome turned to the right shoulder (the hose port), a cream saddle plate on the back
held by two chrome bands; strap-webbing hoops round the wearer's body (worn) or two loose shoulder loops against the
plate (lying); the hand nozzle parked upright in two chrome clips on the tank's right: a chrome cuff, a mint grip, a
chrome ring and head to a flat mouth, with a round dial gauge (chrome cup, cream face, five ticks, a red needle) on
its grip.

Run from the repository root (Blender is the kit's pinned one, kit/tools/blender.sh):

    kit/tools/blender.sh -b -P assets_src/generate/backpack_vacuum/make_backpack_vacuum.py -- [--save] [--no-export] [--out <dir>]

It builds from scratch, writes `assets/vacuum_devices/backpack_vacuum.glb` (the old game's path; under `--out` when
given) and with `--save` the source `assets_src/blender/backpack_vacuum/backpack_vacuum.blend`. Last line:
`PASS backpack_vacuum ...` or `FAIL ...`.

Blender metres, the front facing -Y (in Godot +Z), the origin on the floor under the tank's axis (the nozzle stands
out on the right, the straps round the wearer: the footprint is off centre). Godot space = Blender (x, z, -y).

backpack_vacuum.glb, under the root `backpack_vacuum` (only its children are exported; every node unrotated):
  Body         every still piece: the tank, skirt, dome, belt lines, porthole ring and bolts, badge, the elbow port,
               the saddle plate and its bands, the two nozzle clips (the old `body`)
  Glass        the porthole's glass (the family's `glass`; the old `window`)
  Straps       the two strap hoops round the wearer's body with their four buckles, shown while worn (old `straps`)
  StrapsLoose  the two shoulder-strap loops against the back plate, shown lying (old `straps_loose`)
  Nozzle       the hand nozzle in its clips: origin at its cuff, Godot (0.18, 0.5, 0.02), the mouth 0.30 m below
               (Godot -Y), its width front to back, the dial on its +X side (old `nozzle`)
    Dial       the dial's red needle, origin on the dial's centre; at rest on the empty end; a fill f in 0..1 turns
               it -120 degrees * f about its local +X (old `gauge_needle`)

Materials: the family's six (mint, cream, chrome, red, dark, glass), embedded as on the Sock vacuum and the cabinets,
and the old `strap` webbing (#6B5A4E, roughness 0.85), embedded beside them.

What differs from the old script (technical only, Q2153): the node names are the Looks contract's (Body, Glass,
Straps, StrapsLoose, Nozzle, Dial); no collider box (collision is the entity scene's); the empties `nozzle_rest` and
`hose_port` are Marker3Ds in the Looks (NozzleRest, Port) at the same places; the export is built in; the Blender
review still is left out (the line-up is taken in Godot, tools/backpack_vacuum_still.tscn). Every number is the old
script's.
"""

import math
import os
import sys

import bpy
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, os.path.join(REPO, "assets_src", "generate", "cabinet"))
sys.path.insert(0, os.path.join(REPO, "assets_src", "generate", "avatar"))
import appliance_family as fam  # noqa: E402
import make_avatar as av  # noqa: E402  (the body's surface, so the hoops fit the wearer)

ASSET = "backpack_vacuum"
GLB = os.path.join("assets", "vacuum_devices", "backpack_vacuum.glb")
SOURCE = os.path.join("assets_src", "blender", "backpack_vacuum", "backpack_vacuum.blend")

# --- The old make_backpack_vacuum.py's numbers ------------------------------------------------------
WORN_Z = 0.52            # the tank's bottom above the Avatar's floor, worn
GAP = 0.004              # between the back plate and the body
R = 0.135                # the tank's radius
NOZ_LEN = 0.30
NEEDLE_SWEEP = 120.0     # degrees from empty to full
PORTHOLE_Z = 0.25
CLIP = (R + 0.045, -0.02)  # the nozzle clips' middle (x, y)
NOZZLE_Z = 0.5           # the parked nozzle's cuff
HOSE_PORT = (0.092, 0.0, 0.56)

# The old vd_common EXTRA beside the family's six (sRGB hex, metallic, roughness).
STRAP = ("#6B5A4E", 0.0, 0.85)
ORDER = fam.ORDER + ["strap"]


def material(name):
    """The family's materials, and the straps' webbing."""
    if name != "strap":
        return fam.material(name)
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    hexs, metal, rough = STRAP
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


def _back(x, y, z):
    """A frame facing the back (+Y): local +Z out of the back, local +Y up (vd_common.back)."""
    return _t(x, y, z) @ _rz(math.pi) @ _rx(math.pi / 2)


# --- The old vd_common helpers this model uses ------------------------------------------------------

def _tube(p, path, radii, mat, n=10, cap=True, ref=Vector((0, 0, 1))):
    """A tube along `path` with a radius per point."""
    rings = []
    cnt = len(path)
    for i, pt in enumerate(path):
        a = path[max(i - 1, 0)]
        b = path[min(i + 1, cnt - 1)]
        t = (b - a).normalized()
        r0 = ref if abs(t.dot(ref)) < 0.95 else Vector((1, 0, 0))
        s = t.cross(r0).normalized()
        u = s.cross(t).normalized()
        rings.append([pt + radii[i] * (math.cos(2 * math.pi * k / n) * s + math.sin(2 * math.pi * k / n) * u)
                      for k in range(n)])
    return p._strip(rings, mat, cap_start=mat if cap else None, cap_end=mat if cap else None)


def _band(p, path, width, thick, mat, ref=Vector((0, 0, 1))):
    """A flat strap along `path`: `width` across (along ref x tangent), `thick` the other way."""
    rings = []
    cnt = len(path)
    for i, pt in enumerate(path):
        a = path[max(i - 1, 0)]
        b = path[min(i + 1, cnt - 1)]
        t = (b - a).normalized()
        s = t.cross(ref).normalized()
        w = ref - t * ref.dot(t)
        w.normalize()
        rings.append([pt + w * dx + s * dz for dx, dz in
                      ((-width / 2, -thick / 2), (width / 2, -thick / 2), (width / 2, thick / 2),
                       (-width / 2, thick / 2))])
    return p._strip(rings, mat, cap_start=mat, cap_end=mat)


def _bezier(p0, p1, p2, p3, n=24):
    out = []
    for k in range(n + 1):
        t = k / n
        a = (1 - t) ** 3
        b = 3 * (1 - t) ** 2 * t
        c = 3 * (1 - t) * t * t
        d = t ** 3
        out.append(Vector(p0) * a + Vector(p1) * b + Vector(p2) * c + Vector(p3) * d)
    return out


# --- The straps -------------------------------------------------------------------------------------

def _hoop(p, plate_y, z_back, z_front, x_half, mat="strap", width=0.04, thick=0.008):
    """A strap hoop from the back plate round the Avatar's body and back (asset space)."""
    zw_b, zw_f = z_back + WORN_Z, z_front + WORN_Z
    pts = []
    n = 28
    a0 = math.asin(min(x_half / (av.radius_at(zw_b) + 0.012), 0.99))
    for k in range(n + 1):
        t = k / n
        a = -math.pi / 2 - a0 - t * (2 * math.pi - 2 * a0)     # from the back plate round the front
        zw = zw_b + (zw_f - zw_b) * (0.5 - 0.5 * math.cos(2 * math.pi * t))
        r = av.radius_at(zw) + 0.012
        cy = plate_y + av.radius_at(zw_b) * av.OVAL + GAP
        x = r * math.cos(a)
        y = cy + r * av.OVAL * math.sin(a)
        pts.append(Vector((x, y, zw - WORN_Z)))
    pts[0].y = plate_y - 0.004    # the ends tuck into the plate
    pts[-1].y = plate_y - 0.004
    _band(p, pts, width, thick, mat)


def _buckle(p, at, w=0.05):
    p.rounded_box(w * 0.5, 0.014, -0.022, 0.022, 0.005, 0.003, 0.003, "chrome", matrix=_t(*at), seg=3,
                  seg_round=2)


def _straps(root, plate_y, top, bottom, x_half):
    """Straps (the hoops, worn) and StrapsLoose (the loops against the back plate, lying)."""
    s = part()
    _hoop(s, plate_y, top[0], top[1], x_half)
    _hoop(s, plate_y, bottom[0], bottom[1], x_half)
    for z in (top[0], bottom[0]):
        for sx in (-1, 1):
            _buckle(s, (sx * x_half, plate_y + 0.006, z), w=0.05)
    s.finish("Straps", root)
    lo = part()
    for sx in (-1, 1):
        x = sx * x_half * 0.8
        pts = _bezier((x, plate_y - 0.004, top[0]), (x + sx * 0.02, plate_y + 0.09, top[0] + 0.03),
                      (x + sx * 0.04, plate_y + 0.07, bottom[0] - 0.02), (x, plate_y - 0.004, bottom[0]), 20)
        _band(lo, pts, 0.042, 0.008, "strap", ref=Vector((1, 0, 0)))
        _buckle(lo, (x + sx * 0.03, plate_y + 0.07, bottom[0] + 0.06), w=0.05)
    lo.finish("StrapsLoose", root)


# --- The nozzle -------------------------------------------------------------------------------------

def _nozzle_frame(origin, axis, top):
    z = Vector(axis).normalized()
    x = (Vector(top) - z * Vector(top).dot(z)).normalized()
    y = z.cross(x)
    return Matrix(((x.x, y.x, z.x, origin[0]), (x.y, y.y, z.y, origin[1]), (x.z, y.z, z.z, origin[2]),
                   (0, 0, 0, 1)))


def _gauge_frame(P):
    """The dial's frame on the grip's top (+X of the nozzle frame P), 0.095 m from the cuff: local +Z out of the dial
    face, local +Y towards the mouth."""
    return P @ _t(0.024, 0, 0.095) @ _ry(math.pi / 2) @ _rz(math.pi / 2)


def _nozzle(root, P):
    """The nozzle in its frame P (origin at the cuff, +Z towards the mouth, +X its top, the mouth's width along Y) with
    the dial on its grip; returns (Nozzle, Dial)."""
    n = part()
    n.lathe([(0.018, -0.002), (0.03, 0.0), (0.031, 0.01), (0.029, 0.03), (0.023, 0.034)], "chrome",
            matrix=P, n=20, cap_start="dark")
    n.lathe([(0.023, 0.032), (0.024, 0.05), (0.024, 0.15), (0.023, 0.158)], "mint", matrix=P, n=20)
    n.sweep(fam.circle(0.025, 20), 0.0045, "chrome", matrix=P @ _t(0, 0, 0.156), n=6)
    rings = []
    for k in range(9):
        t = k / 8
        e = t * t * (3 - 2 * t)
        w = 0.048 + (0.1 - 0.048) * e
        h = 0.046 + (0.026 - 0.046) * e
        z = 0.158 + (NOZ_LEN - 0.01 - 0.158) * t
        rings.append([P @ Vector((q.x, q.y, z)) for q in fam.rounded_rect(h, w, min(w, h) / 2, 5)])
    n._strip(rings, "chrome")
    n.rounded_box(0.026, 0.1, NOZ_LEN - 0.01, NOZ_LEN, 0.013, 0.0, 0.005, "chrome", matrix=P, seg=5,
                  seg_round=2)
    n.slab(fam.stadium(0.012, 0.084, 5), NOZ_LEN - 0.001, NOZ_LEN + 0.001, "dark", matrix=P)
    # The dial: a round chrome cup, a cream face and five ticks over the needle's sweep.
    G = _gauge_frame(P)
    n.lathe([(0.012, -0.008), (0.024, -0.002), (0.026, 0.012), (0.024, 0.018), (0.02, 0.018)],
            "chrome", matrix=G, n=24)
    n.slab(fam.circle(0.0205, 24), 0.0, 0.016, "cream", matrix=G)
    for k in range(5):
        a = math.radians(-NEEDLE_SWEEP / 2 + NEEDLE_SWEEP / 4 * k)
        n.slab(fam.rounded_rect(0.0018, 0.005, 0.0008, 1), 0.0, 0.0008, "dark",
               matrix=G @ _rz(a) @ _t(0, 0.015, 0.0162))
    nz = n.finish("Nozzle", root, location=P.to_translation())
    # The needle at rest on the empty end (fill 0), its hub on the dial's centre.
    d = part()
    a0 = math.radians(NEEDLE_SWEEP / 2)
    d.slab(fam.rounded_rect(0.0024, 0.016, 0.001, 1), 0.0164, 0.0172, "red", matrix=G @ _rz(a0) @ _t(0, 0.008, 0))
    d.lathe([(0.003, 0.0164), (0.003, 0.0175)], "red", matrix=G, n=10, cap_end="red")
    centre = G.to_translation()
    nd = d.finish("Dial", nz, location=centre)
    nd.location = centre - nz.location
    return nz, nd


# --- Build and export -----------------------------------------------------------------------------

def build():
    """Wipes the open file and builds the Backpack vacuum; returns its triangle count."""
    fam.wipe()
    root = fam.root(ASSET)
    t = part()
    prof = [(0.0, 0.035)]
    for k in range(1, 7):  # the rounded bottom
        a = math.pi / 2 * k / 6
        prof.append((R * math.sin(a) * 0.98, 0.035 + 0.06 * (1 - math.cos(a))))
    prof += [(R, 0.12), (R, 0.38)]
    t.lathe(prof, "mint", n=36)
    top = [(R * math.cos(math.pi / 2 * k / 8), 0.38 + 0.1 * math.sin(math.pi / 2 * k / 8)) for k in range(9)]
    top[-1] = (0.0, 0.48)
    t.lathe([(R + 0.001, 0.375)] + top[1:], "cream", n=36)
    # The cream skirt it stands on, the chrome bands.
    t.lathe([(0.0, 0.0), (0.105, 0.0), (0.112, 0.006), (0.112, 0.04), (0.1, 0.05), (0.06, 0.06)], "cream", n=36)
    for z in (0.13, 0.375):
        t.sweep(fam.circle(R + 0.002, 36), fam.TRIM_R, "chrome", matrix=_t(0, 0, z), n=8)
    # The porthole: a round window in a bolted chrome ring on the front.
    pm = fam.front(0, -R + 0.01, PORTHOLE_Z)
    t.slab(fam.circle(0.058, 28), -0.012, 0.004, "cream", matrix=pm)
    t.sweep(fam.circle(0.062, 28), 0.008, "chrome", matrix=pm @ _t(0, 0, 0.006), n=8)
    for k in range(6):
        a = 2 * math.pi * k / 6 + math.pi / 6
        t.lathe([(0.006, 0.0), (0.005, 0.006), (0.0, 0.008)], "chrome",
                matrix=pm @ _t(0.075 * math.cos(a), 0.075 * math.sin(a), -0.004), n=8)
    fam.badge(t, fam.front(0, -R - 0.003, 0.08) @ _rx(math.radians(-8)))
    # The port: a chrome elbow out of the top dome, turned to the right shoulder.
    elbow = _bezier((0.0, 0.0, 0.47), (0.0, 0.0, 0.53), (0.03, 0.0, 0.56), (0.08, 0.0, 0.56), 8)
    _tube(t, elbow, [0.032] * len(elbow), "chrome", n=18)
    t.lathe([(0.034, 0.0), (0.034, 0.01), (0.028, 0.012)], "chrome", matrix=_t(0.08, 0, 0.56) @ _ry(math.pi / 2),
            n=18, cap_end="dark")
    # The saddle on the back: a curved cream plate on two chrome straps round the tank.
    plate_y = R + 0.03
    t.rounded_box(0.25, 0.34, -0.003, 0.02, 0.06, 0.0, 0.01, "cream", matrix=_back(0, plate_y - 0.02, 0.265))
    for z in (0.17, 0.35):
        t.sweep(fam.circle(R + 0.006, 36), 0.006, "chrome", matrix=_t(0, 0, z), n=6, squash=0.6)
    # Two clips on the right side for the upright nozzle.
    cx, cy = CLIP
    for z in (0.43, 0.25):
        arc = [Vector((0.028 * math.cos(a), 0.028 * math.sin(a), 0)) for a in
               (math.radians(-140 + 280 * k / 14) for k in range(15))]
        t.sweep(arc, 0.0045, "chrome", matrix=_t(cx, cy, z), closed=False, n=8)
        t.sweep([Vector((R - 0.01, cy, z)), Vector((cx - 0.028, cy, z))], 0.0055, "chrome", closed=False, n=8)
    t.finish("Body", root)
    g = part()
    g.slab(fam.circle(0.06, 28), 0.0, 0.004, "glass", matrix=pm @ _t(0, 0, 0.004))
    g.finish("Glass", root, location=(0, -R + 0.01 - 0.008, PORTHOLE_Z))
    _straps(root, plate_y, (0.42, 0.32), (0.12, 0.14), 0.1)
    P = _nozzle_frame((cx, cy, NOZZLE_Z), (0, 0, -1), (1, 0, 0))
    _nozzle(root, P)
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
    said.append(build())
    if "--no-export" not in argv:
        said.append("glb " + export(out_root))
    if "--save" in argv:
        said.append(_save(SOURCE))
    print("PASS backpack_vacuum " + " | ".join(said))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:  # a crash is a failure, never a silent pass
        import traceback
        traceback.print_exc()
        print("FAIL backpack_vacuum: %s" % e)
        sys.exit(1)
