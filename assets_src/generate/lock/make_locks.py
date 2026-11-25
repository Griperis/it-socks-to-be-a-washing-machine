"""The floor locks' models (assets/10): the plank door and the painted baby gate, each with its chain and
brass padlock, ported by examination from the old `tools/blender/make_house.py`:1051-1322 (v0.1.1:
torus_link, chain_part, sag, padlock_part, _lock_frames, make_locked_doors) and the helpers it used from
`make_flat.py` (Part, box, cyl, ellipsoid) and `make_house.py` (hexa). Meshes only (Q2152): no colliders,
no Sock boxes, no layout record; the floor lock scene (core/80) owns those.

What changed from the old, technical only (Q2153):
- One model per kind instead of three locks in the house model: built in the lock's own frame, the
  opening along x centred on the origin, the floor at y 0, the side players come from (the chain's and
  the padlock's) towards +z in glTF (Godot), which is Blender's -y: the asset's front.
- Fitted to the port's U stair flight: 1.13 m across (house_kit_sizes.tres: (stair_well.x - partition
  - newel) / 2), the old 1.105. The door's leaf keeps the old width (0.826 m, Q995: doors keep their
  size); the posts take the rest, as the old. The wall panel over the door goes up to the port's ceiling
  (2.7 m over the floor: storey 3.0 - floor 0.1 - ceiling 0.2), as the old's went to its own.
- The gate is built with the players' side towards +z like the door (the old gate's faced -z); its
  leaf is symmetric, so only the pin's side differs, and the scene turns it to fit.

Nodes under the root (`lock_door` or `lock_gate`), every origin a pivot; the root's origin is on the
opening's middle line at the floor, so the footprint is not centred (the chain stands out in front:
`origin_xy: false` in assets/blender_assets.json):
  frame    static: the posts (and the door's head), the chain's two eyes; the gate's oak caps and knobs.
  panel    the door's only: the wall panel over the head up to the ceiling (material `wall_hall`).
  leaf     the leaf, its origin on its pin (the s = 0 end, on the face it swings towards: players' side).
  chain    the chain across the players' side, origin at its lowest middle point.
  padlock  the padlock on the chain's middle, origin at its body's middle.

Run: `blender -b -P assets_src/generate/build.py -- lock` (assets_src/generate/README.md).
"""
import math

import bmesh
import bpy
from mathutils import Matrix, Vector

# --- The port's sizes (house_kit_sizes.tres) and the old lock numbers (make_house.py:131-240) -----
FLIGHT = (2.5 - 0.12 - 0.12) / 2      # the U stair's flight: (stair_well.x - partition - newel) / 2
CEILING = 3.0 - 0.1 - 0.2             # a storey's ceiling over its floor: storey - floor - ceiling
DOOR_H = 2.1                          # door_height (old DOOR_H)
LEAF_GAP = 0.017
LOCK_POST = 0.07
LOCK_LEAF_W = 0.826
LOCK_FRAME_D = 0.1
LOCK_LEAF_T = 0.045
GATE_H = 0.8
GATE_POST = 0.07
GATE_D = 0.07
GATE_LEAF_T = 0.035

KINDS = ("door", "gate")


def srgb(r, g, b):
    f = lambda c: c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4  # noqa: E731
    return (f(r), f(g), f(b), 1.0)


# The old materials (make_flat.py MATERIALS, make_house.py:319-320; wall_hall the stair hall's wall).
# In the game each name is the shared library's (Q2177, docs/architecture/materials.md).
MATERIALS = {
    "trim": (srgb(0.98, 0.96, 0.91), 0.55, 0.0),
    "oak": (srgb(0.80, 0.57, 0.34), 0.62, 0.0),
    "dark_wood": (srgb(0.47, 0.29, 0.16), 0.5, 0.0),
    "brass": (srgb(0.88, 0.68, 0.32), 0.32, 1.0),
    "steel": (srgb(0.78, 0.80, 0.82), 0.3, 1.0),
    "chain": (srgb(0.42, 0.43, 0.45), 0.35, 1.0),
    "lock_dark": (srgb(0.08, 0.07, 0.06), 0.6, 0.0),
    "wall_hall": (srgb(0.97, 0.86, 0.62), 0.9, 0.0),
}


def material(name):
    m = bpy.data.materials.get(name)
    if m is not None:
        return m
    colour, rough, metal = MATERIALS[name]
    m = bpy.data.materials.new(name)
    bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = colour
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    m.diffuse_color = colour
    return m


# --- Geometry helpers, in glTF axes (x right, y up, z towards the players) ----------------------

class Part:
    """Accumulates primitives into one bmesh with material indices and box-projected UVs."""

    def __init__(self):
        self.bm = bmesh.new()
        self.uv = self.bm.loops.layers.uv.new("UVMap")
        self.mats = []

    def add(self, bm, mat):
        if mat not in self.mats:
            self.mats.append(mat)
        bm.normal_update()
        for f in bm.faces:
            f.material_index = self.mats.index(mat)
        me = bpy.data.meshes.new("tmp")
        bm.to_mesh(me)
        bm.free()
        before = set(self.bm.faces)
        self.bm.from_mesh(me)
        bpy.data.meshes.remove(me)
        for f in self.bm.faces:
            if f in before:
                continue
            n = f.normal
            for loop in f.loops:
                c = loop.vert.co
                if abs(n.x) >= max(abs(n.y), abs(n.z)):
                    loop[self.uv].uv = (c.z, c.y)
                elif abs(n.y) >= abs(n.z):
                    loop[self.uv].uv = (c.x, c.z)
                else:
                    loop[self.uv].uv = (c.x, c.y)

    def to_object(self, name, parent, origin=(0.0, 0.0, 0.0), smooth_angle=35):
        """The mesh object `name` under `parent`, its origin at `origin` (glTF axes), written in
        Blender axes (x, -z, y) so the exporter's Y-up turn brings it back."""
        bm = self.bm
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-6)
        ox, oy, oz = origin
        for v in bm.verts:
            x, y, z = v.co
            v.co = Vector((x - ox, -(z - oz), y - oy))
        bm.normal_update()
        me = bpy.data.meshes.new(name)
        bm.to_mesh(me)
        bm.free()
        for p in me.polygons:
            p.use_smooth = True
        me.set_sharp_from_angle(angle=math.radians(smooth_angle))
        for m in self.mats:
            me.materials.append(material(m))
        obj = bpy.data.objects.new(name, me)
        bpy.context.scene.collection.objects.link(obj)
        obj.parent = parent
        obj.location = (ox, -oz, oy)
        return obj


def _bevel(bm, edges, offset, segments):
    if edges and offset > 0:
        # As the old: bmesh's default affect (the corners' vertices, not the edges), at most two
        # segments (the old call's profile and affect sat inside a comment, make_flat.py:368).
        bmesh.ops.bevel(bm, geom=list(edges), offset=offset, offset_type="OFFSET",
                        segments=min(segments, 2), clamp_overlap=True)


def box(x0, x1, y0, y1, z0, z1, bevel=0.0, seg=2):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = Vector((min(x0, x1) if v.co.x < 0 else max(x0, x1), y0 if v.co.y < 0 else y1,
                       min(z0, z1) if v.co.z < 0 else max(z0, z1)))
    _bevel(bm, bm.edges[:], bevel, seg)
    return bm


def _axis_point(axis, a, b, t):
    return {"x": (t, a, b), "y": (a, t, b), "z": (a, b, t)}[axis]


def cyl(axis, ca, cb, t0, t1, r, n=12):
    bm = bmesh.new()
    rings = []
    for t in (t0, t1):
        rings.append([bm.verts.new(_axis_point(axis, ca + r * math.cos(2 * math.pi * k / n),
                                               cb + r * math.sin(2 * math.pi * k / n), t)) for k in range(n)])
    for k in range(n):
        j = (k + 1) % n
        bm.faces.new((rings[0][k], rings[0][j], rings[1][j], rings[1][k]))
    bm.faces.new(rings[0])
    bm.faces.new(rings[1])
    bm.normal_update()
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bm


def ellipsoid(c, rx, ry, rz, u=12, v=8):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=u, v_segments=v, radius=1.0)
    for vert in bm.verts:
        x, z, y = vert.co.x, vert.co.y, vert.co.z
        vert.co = Vector((c[0] + x * rx, c[1] + y * ry, c[2] + z * rz))
    bm.normal_update()
    return bm


def hexa(corners):
    """A six-faced solid from 8 corners, indexed by (sx, sy, sz) in {0, 1}."""
    bm = box(0, 1, 0, 1, 0, 1)
    for v in bm.verts:
        v.co = Vector(corners[(int(v.co.x > 0.5), int(v.co.y > 0.5), int(v.co.z > 0.5))])
    bm.normal_update()
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bm


def torus_link(length, width, wire, n=10, m=4):
    """One chain link: an oval ring along x (`length` and `width` outside) in the xy plane, `wire` its
    wire's radius; n segments round the ring, m round the wire."""
    bm = bmesh.new()
    a, b = length / 2 - wire, width / 2 - wire
    rings = []
    for i in range(n):
        t = 2 * math.pi * i / n
        c = Vector((a * math.cos(t), b * math.sin(t), 0.0))
        nrm = Vector((b * math.cos(t), a * math.sin(t), 0.0)).normalized()
        ring = []
        for j in range(m):
            s = 2 * math.pi * j / m + math.pi / 4
            ring.append(bm.verts.new(c + nrm * (wire * math.cos(s)) + Vector((0, 0, wire * math.sin(s)))))
        rings.append(ring)
    for i in range(n):
        r0, r1 = rings[i], rings[(i + 1) % n]
        for j in range(m):
            bm.faces.new((r0[j], r0[(j + 1) % m], r1[(j + 1) % m], r1[j]))
    bm.normal_update()
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bm


def chain_part(points, out, link=0.075, width=0.045, wire=0.009):
    """Links along the polyline `points`, the face it hangs on facing `out`: in turn flat on the face
    and standing out of it."""
    p = Part()
    pitch = link - 2 * wire - 0.006
    pts = [Vector(q) for q in points]
    k = 0
    for a, b in zip(pts, pts[1:]):
        seg = b - a
        n = max(1, int(round(seg.length / pitch)))
        tx = seg.normalized()
        for i in range(n):
            c = a + seg * ((i + 0.5) / n)
            o = Vector(out)
            flat = (o.cross(tx)).normalized() if (k % 2 == 0) else (o - tx * o.dot(tx)).normalized()
            z = tx.cross(flat)
            mat = Matrix((tx, flat, z)).transposed().to_4x4()
            mat.translation = c
            bm = torus_link(link, width, wire)
            bmesh.ops.transform(bm, matrix=mat, verts=bm.verts)
            p.add(bm, "chain")
            k += 1
    return p


def sag(a, b, drop, n=6):
    """Points from a to b hanging `drop` low in the middle (a parabola)."""
    return [(a[0] + (b[0] - a[0]) * (i / n), a[1] + (b[1] - a[1]) * (i / n) - drop * 4 * (i / n) * (1 - i / n),
             a[2] + (b[2] - a[2]) * (i / n)) for i in range(n + 1)]


def padlock_part(centre, out, size=1.0):
    """A padlock hanging at `centre` (its body's middle), its front facing `out`: a brass body with a
    keyhole, a steel shackle over it."""
    p = Part()
    s = size
    turn = Matrix.Rotation(math.atan2(out[0], out[2]), 4, "Y")
    turn.translation = Vector(centre)

    def put(bm, mat):
        bmesh.ops.transform(bm, matrix=turn, verts=bm.verts)
        p.add(bm, mat)

    bw, bh, bd = 0.06 * s, 0.065 * s, 0.024 * s
    put(box(-bw, bw, -bh, bh, -bd, bd, bevel=0.012 * s, seg=2), "brass")
    put(cyl("z", 0.0, -0.005 * s, bd - 0.002, bd + 0.003, 0.011 * s, n=10), "lock_dark")
    put(box(-0.004 * s, 0.004 * s, -0.03 * s, -0.008 * s, bd - 0.002, bd + 0.003), "lock_dark")
    r, w = 0.038 * s, 0.009 * s
    for x in (-r, r):
        put(cyl("y", x, 0.0, bh - 0.005, bh + 0.035 * s, w, n=8), "steel")
    arc = torus_link(2 * (r + w), 2 * (r + w), w, n=16, m=6)
    bmesh.ops.delete(arc, geom=[v for v in arc.verts if v.co.y < -1e-6], context="VERTS")
    bmesh.ops.translate(arc, vec=(0.0, bh + 0.035 * s, 0.0), verts=arc.verts)
    put(arc, "steel")
    return p


# --- The lock ------------------------------------------------------------------------------------

def build(kind):
    """Builds `lock_<kind>` (a root Empty and its nodes) into the open scene; returns a summary line.
    Safe to run again in a fresh scene (build.py empties it first)."""
    name = "lock_" + kind
    root = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(root)
    length = FLIGHT
    y0 = 0.0
    u, n = (1.0, 0.0), (0.0, 1.0)
    ox, oz = -length / 2, 0.0

    def at(s, t):
        return (ox + u[0] * s + n[0] * t, oz + u[1] * s + n[1] * t)

    def pt(s, y, t):
        x, z = at(s, t)
        return (x, y, z)

    def st_box(s0, s1, ya, yb, t0, t1, **kw):
        (xa, za), (xb, zb) = at(s0, t0), at(s1, t1)
        return box(min(xa, xb), max(xa, xb), ya, yb, min(za, zb), max(za, zb), **kw)

    def st_cyl(s, y, t0, t1, r, nseg):
        # a cylinder through the leaf's thickness (along n, which is +z here)
        (xa, za), (xb, zb) = at(s, t0), at(s, t1)
        return cyl("z", xa, y, min(za, zb), max(za, zb), r, n=nseg)

    nv = (n[0], 0.0, n[1])
    frame, panel, leaf = Part(), Part(), Part()
    if kind == "gate":
        door_h = GATE_H
        post = GATE_POST
        f0, f1 = -GATE_D / 2, GATE_D / 2
        ptop = y0 + door_h + 0.06
        for sa, sb in ((0.0, post), (length - post, length)):
            frame.add(st_box(sa, sb, y0, ptop, f0, f1, bevel=0.008, seg=1), "trim")
            frame.add(st_box(sa - 0.01, sb + 0.01, ptop, ptop + 0.02, f0 - 0.01, f1 + 0.01, bevel=0.005, seg=1), "oak")
            frame.add(ellipsoid(pt((sa + sb) / 2, ptop + 0.02 + 0.035, 0.0), 0.035, 0.035, 0.035, u=12, v=8), "oak")
        gap = 0.012
    else:
        door_h = DOOR_H
        head = y0 + door_h + LOCK_POST
        post = (length - LOCK_LEAF_W) / 2 - LEAF_GAP
        f0, f1 = -LOCK_FRAME_D / 2, LOCK_FRAME_D / 2
        for sa, sb in ((0.0, post), (length - post, length)):
            frame.add(st_box(sa, sb, y0, head, f0, f1, bevel=0.008, seg=1), "dark_wood")
        frame.add(st_box(0.0, length, y0 + door_h, head, f0, f1, bevel=0.008, seg=1), "dark_wood")
        # The wall panel over the head, up to the ceiling (the port's ceilings are flat over a flight).
        panel.add(st_box(0.0, length, head, y0 + CEILING, -0.03, 0.03), "wall_hall")
        gap = LEAF_GAP
    la, lb = post + gap, length - post - gap
    if kind == "gate":
        # A painted baby gate: two stiles, a bottom rail and round spindles under an oak handrail.
        ya, yb = y0 + 0.05, y0 + door_h
        ti, to = -GATE_LEAF_T / 2, GATE_LEAF_T / 2
        sw = 0.045
        for sa, sb in ((la, la + sw), (lb - sw, lb)):
            leaf.add(st_box(sa, sb, ya, yb - 0.05, ti, to, bevel=0.006, seg=1), "trim")
        leaf.add(st_box(la + sw, lb - sw, ya, ya + 0.05, ti, to, bevel=0.006, seg=1), "trim")
        leaf.add(st_box(la - 0.005, lb + 0.005, yb - 0.05, yb, ti - 0.008, to + 0.008, bevel=0.012, seg=2), "oak")
        inner = (lb - sw) - (la + sw)
        k = max(2, round(inner / 0.09))
        step = inner / k
        for i in range(1, k):
            x, z = at(la + sw + i * step, 0.0)
            leaf.add(cyl("y", x, z, ya + 0.05, yb - 0.05, 0.011, n=8), "trim")
    else:
        # Vertical planks with ledges both sides and a brace on the side players come from.
        ya, yb = y0 + 0.008, y0 + door_h - LEAF_GAP
        ti, to = -LOCK_LEAF_T / 2, LOCK_LEAF_T / 2
        planks = 5
        pw = (lb - la) / planks
        for k in range(planks):
            leaf.add(st_box(la + k * pw + 0.002, la + (k + 1) * pw - 0.002, ya, yb, ti, to, bevel=0.006, seg=1), "oak")
        for tf, sgn in ((to, 1), (ti, -1)):
            for ly in (0.25, 1.0, door_h - 0.3):
                leaf.add(st_box(la + 0.04, lb - 0.04, y0 + ly - 0.07, y0 + ly + 0.07,
                                *sorted((tf, tf + sgn * 0.025)), bevel=0.006, seg=1), "dark_wood")
        bw = 0.06
        t2 = to + 0.025
        lo, hi = y0 + 0.32, y0 + 0.93
        leaf.add(hexa({(0, 0, 0): pt(la + 0.06, lo, to), (1, 0, 0): pt(la + 0.06 + bw, lo, to),
                       (0, 1, 0): pt(lb - 0.06 - bw, hi, to), (1, 1, 0): pt(lb - 0.06, hi, to),
                       (0, 0, 1): pt(la + 0.06, lo, t2), (1, 0, 1): pt(la + 0.06 + bw, lo, t2),
                       (0, 1, 1): pt(lb - 0.06 - bw, hi, t2), (1, 1, 1): pt(lb - 0.06, hi, t2)}), "dark_wood")
        # A ring pull on both faces, near the latch edge.
        for tf, sgn in ((to + 0.025, 1), (ti - 0.025, -1)):
            leaf.add(st_cyl(lb - 0.09, y0 + 1.0, *sorted((tf, tf + sgn * 0.012)), 0.025, 10), "steel")
    # The chain across the players' side, eye to eye on the posts, the padlock on its middle.
    cy = y0 + (0.6 if kind == "gate" else 1.05)
    ct = f1 + 0.012
    ea, eb = pt(post / 2, cy, ct), pt(length - post / 2, cy, ct)
    for s in (post / 2, length - post / 2):
        frame.add(st_cyl(s, cy, f1, f1 + 0.02, 0.016, 10), "steel")
    mid = pt(length / 2, cy - 0.12, ct + 0.01)
    chain = chain_part(sag(ea, mid, 0.02, 4) + sag(mid, eb, 0.02, 4)[1:], nv)
    lock_at = pt(length / 2, mid[1] - 0.105, ct + 0.022)
    padlock = padlock_part(lock_at, nv, 1.15)

    frame.to_object("frame", root)
    if kind == "door":
        panel.to_object("panel", root)
    leaf.to_object("leaf", root, origin=pt(la, y0, to))
    chain.to_object("chain", root, origin=mid)
    padlock.to_object("padlock", root, origin=lock_at)
    tris = sum(len(p.vertices) - 2 for o in root.children for p in o.data.polygons)
    return f"{name}: {tris} triangles"
