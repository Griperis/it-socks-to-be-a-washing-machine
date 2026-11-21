"""The four rigged Sock shapes with their LOD chain (pipeline/03, Q809, Q810), built into the
open Blender scene. Ported from the old game's tools/blender/make_socks.py unchanged but for this
header (assets/08).

Headless, from the repository (assets_src/generate/README.md):

    blender -b -P assets_src/generate/build.py -- sock [--only crew,ball_crew_plain] [--out <dir>] [--save]

builds the shapes (and the balls, make_sock_balls.py), --save writes assets_src/blender/sock/socks.blend,
and each shape is exported to its glb (assets/blender_assets.json sends sock_<shape> to
assets/sock/<shape>.glb). In an open Blender (the MCP), with assets_src/generate/sock on sys.path:
`import make_socks; print(make_socks.build_all())` rebuilds every shape in the scene.

Shapes (flat batch, see docs/llm/flat/spec.md; real proportions from
docs/research/sock-shapes.md): ankle (Simple), crew (Patterns, Animals, Superhero, Food, Space),
tube (Sport, heel-less), chunky (Winter, a thick knee sock with a fold-over cuff).

Objects per shape (the asset contract, with its LOD naming):
  sock_<shape>         Empty, the root, at the origin
    <shape>_rig        Armature: five connected bones Cuff -> Leg -> Heel -> Foot -> Toe
      <shape>          LOD0, the close-up: 12 vertices around the tube, 13 rings, 300 triangles
      <shape>_lod1     LOD1, the mid: every other vertex around, 7 of LOD0's rings, 78 triangles
      <shape>_lod2     LOD2, the far card: the tube's two side edges at 8 of LOD0's rings and the
                       toe tip, a flat strip at mid-height facing up, 15 triangles
Every LOD is skinned to the rig with the same weights, uses material `sock` and has both UV
maps. Every LOD vertex sits on a vertex of LOD0 (same position, its own normal), so a LOD never
reaches outside the close-up's box: the boxes, probes and bounds made from the mesh hold. The
rings are picked from a dense sampling of the shape, most deviating first (`simplify`), so the
silhouette keeps its heel cup, creases, welt and fold-over cuff where they show most.

Rest pose: the Sock lies flat on its side as a flattened knitted tube, the way a real sock lies:
the leg runs from the open cuff (at -X, raised toward +Y) down to the heel, turns through the
heel cup (bulging out on the -Y side, the back of the sock) and runs along the foot to a shaped
toe at +X, whose top (+Y, instep side) slopes down toward the sole. Flat side up, origin at the
centre of the footprint, bottom at height 0, X extent exactly `length` (the gameplay length).
Blender is Z-up; the glTF exporter converts to Y-up (flat side faces +Y in Godot).

UV0 `UVMap`: U = 0..1 cuff -> toe by arc length along the centreline, V = 0..1 around the tube
(one island): V = 0 on the +Y edge, 0.25 on top, 0.5 on the -Y edge, 0.75 underneath. The far
card spans V = 0 (its +Y edge) to 0.5 (its -Y edge): the top face's print.
UV1 `TrimMask`: U = 1 on the cuff band, heel patch and toe cap, falling smoothly to 0 elsewhere
(the tube sock has no heel, so no heel patch). V = 1 where the knit is ribbed (the cuff; the
tube sock's whole athletic-rib leg), else 0: the sock shader draws ribs there.

Rig (unchanged contract): bones along the centreline at mid-height, roll aligned so local Z is
the flat side's normal (bend the sock off the floor by rotating about a bone's local X). The Leg
bone follows the leg, Heel spans the heel turn, Foot the foot, Toe the toe cap. Each ring of
vertices is weighted to at most two neighbouring bones, blended across joints.
"""

import math

import bpy
import bmesh
from mathutils import Vector

BONES = ("Cuff", "Leg", "Heel", "Foot", "Toe")
BLEND_M = 0.02      # half width of the weight blend across a joint (metres)


def smoothstep(e0, e1, x):
    t = min(max((x - e0) / (e1 - e0), 0.0), 1.0)
    return t * t * (3 - 2 * t)


def bump(x, c, w):
    return math.exp(-((x - c) / w) ** 2)


# --- Variant specs ------------------------------------------------------------
# Lengths are arc lengths along the centreline in real metres for an adult
# sock (docs/research/sock-shapes.md); widths are stylised a little wider than
# real (ADR-0003, and so prints keep their aspect). The finished sock is scaled
# uniformly in the floor plane so its X extent is exactly `length`; thickness
# stays as given.
#   length          final X extent (m, gameplay, unchanged from flat/03)
#   cuff            ribbed cuff band (m, from the cuff edge); rib: ribbed span
#                   (default = cuff) for UV1 V
#   leg             straight leg incl. the cuff (m)
#   turn, rc        heel turn: angle between leg and foot (deg off straight) and
#                   the centreline's bend radius (m)
#   foot, toe       straight foot (m) and the toe box (m)
#   w               half width of the flattened tube (m); calf: extra half width
#                   at the top of a long leg (m)
#   heel            heel cup: how far it bulges out behind the turn (m), 0 = none
#   thickness       flattened tube height (m); segs: vertices around the tube (LOD0)
#   toe_shape       "wedge" (top slopes to the sole) or "square" (tube sock seam)
#   feature         "lip" (ankle welt), "crew", "rib" (tube), "fold" (fold-over cuff)
VARIANTS = {
    "ankle": dict(
        length=0.22, cuff=0.014, leg=0.030, turn=56, rc=0.070, foot=0.120, toe=0.060,
        w=0.046, heel=0.026, thickness=0.022, segs=12,
        toe_shape="wedge", feature="lip"),
    "crew": dict(
        length=0.30, cuff=0.040, leg=0.150, turn=40, rc=0.062, foot=0.140, toe=0.058,
        w=0.057, heel=0.030, thickness=0.022, segs=12,
        toe_shape="wedge", feature="crew"),
    "tube": dict(
        length=0.32, cuff=0.060, rib=0.20, leg=0.200, turn=12, rc=0.40, foot=0.120,
        toe=0.035, w=0.068, heel=0.0, thickness=0.022, segs=12,
        toe_shape="square", feature="rib"),
    "chunky": dict(
        length=0.40, cuff=0.075, leg=0.290, turn=28, rc=0.080, foot=0.150, toe=0.062,
        w=0.074, calf=0.010, heel=0.032, thickness=0.046, segs=12,
        toe_shape="wedge", feature="fold"),
}


class Path:
    """The centreline: a straight leg, a circular heel turn, a straight foot and toe."""

    def __init__(self, spec):
        self.spec = spec
        phi = math.radians(spec["turn"])
        self.phi = phi
        self.s_bend0 = spec["leg"]
        self.s_bend1 = spec["leg"] + spec["rc"] * phi
        self.s_toe = self.s_bend1 + spec["foot"]
        self.total = self.s_toe + spec["toe"]

    def at(self, s):
        """(point, direction) at arc length s; the cuff is at s = 0."""
        sp = self.spec
        phi, rc = self.phi, sp["rc"]
        d0 = Vector((math.cos(phi), -math.sin(phi), 0.0))
        if s <= self.s_bend0:
            return d0 * s, d0
        p0 = d0 * self.s_bend0
        left = Vector((-d0.y, d0.x, 0.0))
        centre = p0 + left * rc
        if s <= self.s_bend1:
            a = (s - self.s_bend0) / rc
            ang = -phi + a
            d = Vector((math.cos(ang), math.sin(ang), 0.0))
            return centre - Vector((-d.y, d.x, 0.0)) * rc, d
        d = Vector((1.0, 0.0, 0.0))
        p1 = centre - Vector((0.0, 1.0, 0.0)) * rc
        return p1 + d * (s - self.s_bend1), d


def toe_taper(spec, path, s):
    """(front, back, height) width factors over the toe box: 1 before it, 0 at the tip."""
    t = max(0.0, (s - path.s_toe) / spec["toe"])
    if spec["toe_shape"] == "square":
        f = (max(0.0, 1 - t ** 5)) ** 0.5
        return f, f, 0.6 + 0.4 * f
    # Wedge toe: the top of the toes slopes down early, the sole runs on nearly
    # straight to a rounded tip, so the tip sits toward the sole side.
    front = max(0.0, 1 - t ** 1.6) ** 0.6
    back = max(0.0, 1 - t ** 3.0) ** 0.5
    return front, back, 0.45 + 0.55 * max(0.0, 1 - t ** 2.2) ** 0.5


def heel_cup(spec, path, s):
    """Extra half width behind the turn: the flattened heel cup."""
    if not spec["heel"]:
        return 0.0
    # Centred a little toward the leg: the cup sits behind the ankle.
    mid = 0.55 * path.s_bend0 + 0.45 * path.s_bend1
    span = 0.5 * (path.s_bend1 - path.s_bend0) + 0.018
    return spec["heel"] * bump(s, mid, span)


def creases(path):
    """(arc position, depth) of the soft creases at the instep, either side of the turn."""
    return ((path.s_bend0 - 0.01, 0.10), (path.s_bend1 + 0.015, 0.07))


def ring_params(spec, path, s):
    """Half widths front/back, height and the cross-section tweak at arc length s."""
    u = s / path.total
    w = spec["w"]
    front, back, hf = toe_taper(spec, path, s)
    wf = w * front
    wb = (w + heel_cup(spec, path, s)) * back
    if spec.get("calf"):
        # A knee sock is a little wider at the calf than at the ankle.
        k = 1 - smoothstep(spec["cuff"], path.s_bend0, s)
        wf += spec["calf"] * k
        wb += spec["calf"] * k
    h = spec["thickness"] * hf
    # The heel cup holds more fabric: a little puffier.
    if spec["heel"]:
        h *= 1 + 0.18 * bump(s, 0.5 * (path.s_bend0 + path.s_bend1), 0.04)
    f = spec["feature"]
    cuff = spec["cuff"]
    if f in ("crew", "lip", "rib"):
        # The ribbed cuff draws in a little when the sock is off the foot; its top
        # welt is a touch fuller.
        draw = 1 - 0.06 * (1 - smoothstep(cuff * 0.6, cuff * 1.3, s))
        welt = bump(s, 0.0, 0.006 if f != "rib" else 0.008)
        wf *= draw * (1 + 0.05 * welt)
        wb *= draw * (1 + 0.05 * welt)
        h *= 1 + (0.25 if f == "lip" else 0.15) * welt
    elif f == "fold":
        # The fold-over cuff: two layers of thick knit, three soft ridges, a
        # rolled edge where it folds back.
        if s <= cuff + 0.002:
            ridge = 0.5 + 0.5 * math.cos(2 * math.pi * 3 * s / cuff)
            fold_edge = bump(s, cuff, 0.006)
            wf *= 1.10 + 0.03 * ridge + 0.03 * fold_edge
            wb *= 1.10 + 0.03 * ridge + 0.03 * fold_edge
            h *= 1.28 + 0.08 * ridge + 0.10 * fold_edge
    # Soft creases at the instep: the inner corner of the turn bunches up.
    crease = 0.0
    if spec["heel"]:
        for c, depth in creases(path):
            crease += depth * bump(s, c, 0.008)
    return wf, wb, h, crease, u


def ring(spec, path, s, segs=None):
    segs = segs or spec["segs"]
    c, d = path.at(s)
    n = Vector((-d.y, d.x, 0.0))      # in-plane normal toward +Y (front, instep)
    wf, wb, h, crease, _ = ring_params(spec, path, s)
    pts = []
    for i in range(segs):
        th = 2 * math.pi * i / segs   # 0 on the +Y edge, over the top
        cs, sn = math.cos(th), math.sin(th)
        sx = math.copysign(abs(cs) ** 0.55, cs)  # boxy in-plane profile
        z = 0.5 * h * (1 + math.copysign(abs(sn) ** 0.45, sn))  # flat top/bottom
        w = wf if sx >= 0 else wb
        # Creases pinch the front (instep) edge and dip its top.
        front = max(cs, 0.0)
        w *= 1 - crease * front * 0.6
        z = h * 0.5 + (z - h * 0.5) * (1 - crease * front)
        pts.append(c + n * (sx * w) + Vector((0, 0, z)))
    return pts


def trim_mask(spec, path, s, th):
    u = s / path.total
    cuff_u = spec["cuff"] / path.total
    cuff = 1 - smoothstep(cuff_u - 0.01, cuff_u + 0.01, u)
    back = smoothstep(-0.2, 0.5, -math.cos(th))
    heel = 0.0
    if spec["heel"]:
        mid = 0.5 * (path.s_bend0 + path.s_bend1)
        span = 0.5 * (path.s_bend1 - path.s_bend0) + 0.035
        heel = smoothstep(0.3, 0.7, bump(s, mid, span) * back)
    toe = smoothstep(path.s_toe - 0.006, path.s_toe + 0.004, s)
    return max(cuff, heel, toe)


def rib_mask(spec, path, s):
    return 1 - smoothstep(spec.get("rib", spec["cuff"]) - 0.004, spec.get("rib", spec["cuff"]) + 0.004, s)


def bone_weights(spec, u, joints, total):
    """Weights per bone for a ring at u: membership blended across joints."""
    starts = (0.0,) + tuple(joints)
    b = BLEND_M / total
    w = []
    for k in range(len(BONES)):
        lo = 1.0 if k == 0 else smoothstep(starts[k] - b, starts[k] + b, u)
        hi = 1.0 if k == len(BONES) - 1 else 1 - smoothstep(starts[k + 1] - b, starts[k + 1] + b, u)
        w.append(lo * hi)
    tot = sum(w)
    return [x / tot for x in w]


def joints_of(spec, path):
    """u of the Leg, Heel, Foot and Toe bone heads."""
    T = path.total
    leg = max(spec["cuff"], 0.02) / T
    heel = max(path.s_bend0 - 0.02, spec["cuff"] + 0.015) / T
    foot = (path.s_bend1 + 0.02) / T
    toe = path.s_toe / T
    if spec["heel"] == 0.0:
        # The tube sock: spread the bones evenly like a heel-less tube.
        heel, foot = 0.42, 0.62
        leg = 0.20
    return (leg, heel, foot, toe)


# --- The LOD chain (pipeline/03, Q809) ----------------------------------------------
LOD0_RINGS = 13     # 2 * 12 * 12 + 12 = 300 triangles
LOD1_RINGS = 7      # every other vertex around: 2 * 6 * 6 + 6 = 78
LOD2_RINGS = 8      # the card: 2 * 7 + 1 = 15
TRIM_WEIGHT = 0.015  # m of deviation one unit of TrimMask counts as, when picking rings


def last_station(spec, path):
    return path.s_toe + spec["toe"] * 0.985


def dense_stations(spec, path):
    """Candidate ring positions: every 1.5 mm, plus the shape's marks."""
    end = last_station(spec, path)
    out = [i * 0.0015 for i in range(int(end / 0.0015) + 1)]
    out += [0.006, spec["cuff"], path.s_bend0, path.s_bend1, path.s_toe, end]
    return sorted(set(round(x, 5) for x in out if 0.0 <= x <= end))


def _sample(spec, path, s, segs):
    pts = ring(spec, path, s, segs)
    trims = [trim_mask(spec, path, s, 2 * math.pi * i / segs) for i in range(segs)]
    return pts, trims, rib_mask(spec, path, s)


def simplify(cands, count, sample, edge_only=False):
    """Pick `count` of the candidate stations (the first and last always): each next one is the
    candidate deviating most from the straight blend of its picked neighbours (position, plus
    TrimMask and rib mask weighted by TRIM_WEIGHT). `sample(s)` gives (points, trims, rib).
    `edge_only` measures the two side edges only (the far card's outline)."""
    data = {s: sample(s) for s in cands}
    picked = [cands[0], cands[-1]]
    while len(picked) < count:
        best, err_best = None, -1.0
        sp = sorted(picked)
        for s in cands:
            if s in picked:
                continue
            k = next(i for i, x in enumerate(sp) if x > s)
            a, b = sp[k - 1], sp[k]
            t = (s - a) / (b - a)
            pa, ta, ra = data[a]
            pb, tb, rb = data[b]
            ps, ts, rs = data[s]
            idx = (0, len(ps) // 2) if edge_only else range(len(ps))
            err = 0.0
            for i in idx:
                d = (ps[i] - pa[i].lerp(pb[i], t)).length
                d += TRIM_WEIGHT * abs(ts[i] - (ta[i] + (tb[i] - ta[i]) * t))
                err = max(err, d)
            err = max(err, TRIM_WEIGHT * abs(rs - (ra + (rb - ra) * t)))
            if err > err_best:
                best, err_best = s, err
        picked.append(best)
    return sorted(picked)


def _tip(spec, path):
    c_tip, d_tip = path.at(path.total)
    off = Vector((d_tip.y, -d_tip.x, 0)) * (0.012 if spec["toe_shape"] == "wedge" else 0.0)
    return c_tip + off + Vector((0, 0, 0.5 * spec["thickness"] * 0.45))


def _new_mesh(name, bm, mat):
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    for p in mesh.polygons:
        p.use_smooth = True
    mesh.materials.append(mat)
    return mesh


def tube_mesh(name, spec, path, st, step, tf, mat):
    """The tube of rings at stations `st`, every `step`-th of LOD0's vertices around it, closed
    by a fan to the toe tip. Returns (mesh, {vertex index: u})."""
    segs = spec["segs"]
    idx = list(range(0, segs, step))
    bm = bmesh.new()
    uv0 = bm.loops.layers.uv.new("UVMap")
    uv1 = bm.loops.layers.uv.new("TrimMask")
    rings = []
    for s in st:
        pts = ring(spec, path, s, segs)
        rings.append([bm.verts.new(tf(pts[i])) for i in idx])
    tip = bm.verts.new(tf(_tip(spec, path)))
    us = [s / path.total for s in st]

    def set_loop(loop, s, v, i):
        loop[uv0].uv = (s / path.total, v)
        loop[uv1].uv = (trim_mask(spec, path, s, 2 * math.pi * (i % segs) / segs), rib_mask(spec, path, s))

    n = len(idx)
    for r in range(len(rings) - 1):
        s0, s1 = st[r], st[r + 1]
        for k in range(n):
            i, j = idx[k], idx[k] + step
            v0, v1 = i / segs, j / segs
            f = bm.faces.new((rings[r][k], rings[r + 1][k], rings[r + 1][(k + 1) % n], rings[r][(k + 1) % n]))
            for loop, (ss, vv, ii) in zip(f.loops, ((s0, v0, i), (s1, v0, i), (s1, v1, j), (s0, v1, j))):
                set_loop(loop, ss, vv, ii)
    last, s_last = rings[-1], st[-1]
    for k in range(n):
        i, j = idx[k], idx[k] + step
        v0, v1 = i / segs, j / segs
        f = bm.faces.new((last[k], tip, last[(k + 1) % n]))
        for loop, (ss, vv, ii) in zip(f.loops, ((s_last, v0, i), (path.total, 0.5 * (v0 + v1), i), (s_last, v1, j))):
            set_loop(loop, ss, vv, ii)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.verts.index_update()
    vert_u = {}
    for r, ring_v in enumerate(rings):
        for v in ring_v:
            vert_u[v.index] = us[r]
    vert_u[tip.index] = 1.0
    return _new_mesh(name, bm, mat), vert_u


def card_mesh(name, spec, path, st, tf, mat):
    """The far card: a flat strip between the tube's two side edges (LOD0's vertices on the +Y
    and -Y edges) at stations `st`, closed by the toe tip, facing up. UV V runs 0 -> 0.5 across
    it: the top face's print."""
    segs = spec["segs"]
    bm = bmesh.new()
    uv0 = bm.loops.layers.uv.new("UVMap")
    uv1 = bm.loops.layers.uv.new("TrimMask")
    a_side, b_side = [], []
    for s in st:
        pts = ring(spec, path, s, segs)
        a_side.append(bm.verts.new(tf(pts[0])))
        b_side.append(bm.verts.new(tf(pts[segs // 2])))
    tip = bm.verts.new(tf(_tip(spec, path)))

    def set_loop(loop, s, v, th):
        loop[uv0].uv = (s / path.total, v)
        loop[uv1].uv = (trim_mask(spec, path, s, th), rib_mask(spec, path, s))

    for r in range(len(st) - 1):
        f = bm.faces.new((a_side[r], b_side[r], b_side[r + 1], a_side[r + 1]))
        for loop, (ss, vv, th) in zip(f.loops, ((st[r], 0.0, 0.0), (st[r], 0.5, math.pi),
                                                (st[r + 1], 0.5, math.pi), (st[r + 1], 0.0, 0.0))):
            set_loop(loop, ss, vv, th)
    f = bm.faces.new((a_side[-1], b_side[-1], tip))
    for loop, (ss, vv, th) in zip(f.loops, ((st[-1], 0.0, 0.0), (st[-1], 0.5, math.pi),
                                            (path.total, 0.25, math.pi / 2))):
        set_loop(loop, ss, vv, th)
    bm.normal_update()
    for f in bm.faces:
        if f.normal.z < 0:
            f.normal_flip()
    bmesh.ops.triangulate(bm, faces=bm.faces)
    bm.verts.index_update()
    vert_u = {}
    for r, s in enumerate(st):
        vert_u[a_side[r].index] = s / path.total
        vert_u[b_side[r].index] = s / path.total
    vert_u[tip.index] = 1.0
    return _new_mesh(name, bm, mat), vert_u


def _remove_tree(name):
    root = bpy.data.objects.get(name)
    if root is None:
        return
    for o in list(root.children_recursive) + [root]:
        data = o.data
        bpy.data.objects.remove(o)
        if data is not None and data.users == 0:
            if isinstance(data, bpy.types.Mesh):
                bpy.data.meshes.remove(data)
            elif isinstance(data, bpy.types.Armature):
                bpy.data.armatures.remove(data)


def sock_material():
    mat = bpy.data.materials.get("sock") or bpy.data.materials.new("sock")
    mat.use_nodes = True
    bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = (0.8, 0.8, 0.8, 1)
    bsdf.inputs["Roughness"].default_value = 0.8
    return mat


def build(name):
    """Builds sock_<name> (its rig and three LODs) in the scene, replacing any earlier one."""
    spec = VARIANTS[name]
    path = Path(spec)
    _remove_tree("sock_" + name)
    segs = spec["segs"]
    cands = dense_stations(spec, path)
    st0 = simplify(cands, LOD0_RINGS, lambda s: _sample(spec, path, s, segs))
    st1 = simplify(st0, LOD1_RINGS, lambda s: _sample(spec, path, s, segs))
    st2 = simplify(st0, LOD2_RINGS, lambda s: _sample(spec, path, s, segs), edge_only=True)

    # Normalise on LOD0: footprint centre at the origin, bottom at z=0, exact X length, uniform
    # in the floor plane so the proportions hold. Every LOD gets the same transform.
    pts = [p for s in st0 for p in ring(spec, path, s, segs)] + [_tip(spec, path)]
    xs, ys, zs = [p.x for p in pts], [p.y for p in pts], [p.z for p in pts]
    k = spec["length"] / (max(xs) - min(xs))
    off = Vector(((max(xs) + min(xs)) / 2, (max(ys) + min(ys)) / 2, min(zs)))

    def tf(p):
        q = p - off
        return Vector((q.x * k, q.y * k, q.z))

    mat = sock_material()
    coll = bpy.context.scene.collection
    root = bpy.data.objects.new("sock_" + name, None)
    root.empty_display_size = 0.05
    coll.objects.link(root)

    arm = bpy.data.armatures.new(name + "_rig")
    rig = bpy.data.objects.new(name + "_rig", arm)
    coll.objects.link(rig)
    rig.parent = root
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")
    joints = joints_of(spec, path)
    heads = (0.0,) + tuple(joints) + (1.0,)

    def bone_pt(u):
        s = min(max(u, 0.0), 1.0) * path.total
        c, _ = path.at(s)
        h = ring_params(spec, path, min(max(s, spec["cuff"] + 0.01), path.total * 0.97))[2]
        return tf(c + Vector((0, 0, 0.5 * h)))

    prev = None
    for kb, bname in enumerate(BONES):
        eb = arm.edit_bones.new(bname)
        eb.head = bone_pt(heads[kb])
        eb.tail = bone_pt(heads[kb + 1])
        eb.align_roll(Vector((0, 0, 1)))
        if prev:
            eb.parent = prev
            eb.use_connect = True
        prev = eb
    bpy.ops.object.mode_set(mode="OBJECT")

    out = []
    for obj_name, (mesh, vert_u) in (
            (name, tube_mesh(name, spec, path, st0, 1, tf, mat)),
            (name + "_lod1", tube_mesh(name + "_lod1", spec, path, st1, 2, tf, mat)),
            (name + "_lod2", card_mesh(name + "_lod2", spec, path, st2, tf, mat))):
        obj = bpy.data.objects.new(obj_name, mesh)
        coll.objects.link(obj)
        obj.parent = rig
        groups = {b: obj.vertex_groups.new(name=b) for b in BONES}
        for idx, u in vert_u.items():
            for b, w in zip(BONES, bone_weights(spec, u, joints, path.total * k)):
                if w > 1e-4:
                    groups[b].add([idx], w, "REPLACE")
        mod = obj.modifiers.new("armature", "ARMATURE")
        mod.object = rig
        out.append("%s %d" % (obj_name, sum(len(p.vertices) - 2 for p in mesh.polygons)))
    width = (max(ys) - min(ys)) * k
    face = 2 * spec["w"] * k
    arc = path.total * k
    return ("sock_%s: %.3f x %.3f m, arc %.3f m, print aspect %.3f; tris %s"
            % (name, spec["length"], width, arc, face / arc, ", ".join(out)))


def build_all():
    return "\n".join(build(n) for n in VARIANTS)
