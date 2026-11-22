"""Generate the player avatar, the wonky sock creature (multiplayer/17, Q304), into assets/avatar/.

Ported from the old game's tools/blender/make_avatar.py unchanged but for this header (coop/04, Q2438):
built with Blender 5.3.0 its avatar.glb and feet.glb are MESH-SAME as the old game's
(assets_src/generate/glb_compare.py). The names below that point at the old game (game/player/player.gd,
game/player/avatar.gd, make_wardrobe.py) are the old game's files. Through the family runner:

    blender -b -P assets_src/generate/build.py -- avatar [--out <dir>] [--save]

(--save writes assets_src/blender/avatar/avatar.blend). Alone, with previews (cap the threads):
    LP_NUM_THREADS=4 blender -b -t 4 -P assets_src/generate/avatar/make_avatar.py -- <out_dir> [preview_dir]
        [--final] [--crouch] [--bend=<degrees>]

  <out_dir>  writes avatar.glb (the whole creature) and feet.glb (the first-person feet alone)
  --final    render the previews with EEVEE instead of the cheap Workbench ones
  --crouch   pose the preview at the Crouch shape key (checks the shape key and the drops)
  --bend=<degrees>  pose the preview bent by this much in all (+ forward, looking down; - back)

A lumpy, slightly lopsided upright sock: a heel bump at the back, a ribbed cuff with two stripes
at the top, two big googly eyes (the left one a bit bigger and higher) and two stubby feet. No
arms: held items cluster at the HoldPoint in front. Sized to the player in game/player/player.gd: the
cuff's rim is 1.7 m up (STAND_HEIGHT), the body stays inside the 0.35 m collision radius.
make_wardrobe.py imports this file for the body's surface, so the hats and clothes fit it.

Godot axes (glTF): y up, the creature faces -z (the way a Node3D looks), x is its right. Origin at
the feet, centred. Authored in Blender axes (z up, facing +y); the exporter converts.

Nodes (all children of the scene root, at the standing pose):
  Avatar     mesh, three surfaces in this order:
               0 player  the body: the one surface tinted with the player colour (plain white base)
               1 trim    the cuff's two stripes and the heel patch: warm cream, never tinted
               2 eye     the googly eyes' white domes
             Shape key "Crouch" (Godot "blend_shapes/Crouch", 0..1) squashes the body to
             CROUCH_HEIGHT (1.0 m), plumper in the middle; the eye domes ride down rigidly.
  PupilL, PupilR   mesh (surface "pupil"), one per eye. The node sits at the centre of its eye's
             sphere (inside the body) and at rest its -z (Godot forward) points straight out of
             the eye, so `look_at(target)` turns the pupil over the dome. Keep the turn within
             about 30 degrees of rest to stay on the white.
  FootL, FootR     mesh (surface "trim"), pivot at the ankle, identity rotation: waddle them by
             rotating about x (pitch) and z (roll). They do not crouch.
  HoldPoint  empty in front of the belly, right of centre: held items cluster here.
  Head       empty at the top of the cuff: the name tag / emoji bubble go above it.
  HatPoint   empty at the centre of the cuff's rim, tilted with the lopsided top: a hat glb from
             assets/avatar/wardrobe/ goes in as its child, unchanged.
  Armature   the look bend's spine (multiplayer/21, Q360), with the Avatar mesh skinned to it:
             Root (still, the base over the feet) and Spine0..2, one joint each at BEND_Z,
             chained bottom up. Turning each joint about the creature's x curls the top over the
             belly (or back). Every vertex goes with the bones of its rest height
             (bend_weights()); the eye domes ride rigidly on Spine2. Shape keys come first and
             skinning after, so the Crouch and the bend combine; crouched, each joint pivots
             where the Crouch took it (the Armature's "bend_crouch_offset" extras).
Every node but the feet and the body carries glTF extras for the crouch:
  crouch_drop    metres it goes down at full Crouch (as the old avatar)
  crouch_offset  [x, y, z] in Godot axes: the full move at Crouch (the drop plus the small
                 sideways/forward shift of the plumper body); move by offset * weight.
and for the bend:
  bend_weights   [Root, Spine0, Spine1, Spine2]: the share of each bone it goes with (at most two
                 are non-zero), as the body's surface under it does.
The Armature carries bend_crouch_offset: [[x, y, z] per bone], each joint's full move at Crouch.
feet.glb holds FootL and FootR alone, at the same places, for the first-person view (Q310).
If preview_dir is given, renders avatar_front.png, avatar_three_quarter.png and avatar_side.png.
"""

import math
import os
import sys

import bpy
import bmesh
from mathutils import Matrix, Vector

# --- Contract (metres, Blender axes: z up, the creature faces +y) --------------------------
STAND = 1.7               # player.gd STAND_HEIGHT: the cuff's rim
CROUCHED = 1.0            # player.gd CROUCH_HEIGHT
BASE_Z = 0.15             # crouched, the base below this keeps its shape...
TOP_Z = 1.19              # ...and the top above this (eyes, cuff) drops as one
BULGE = 0.13              # how much the scrunched middle bunches out when crouched
SEG = 40                  # around: even, so the cuff's ribs alternate (20 ribs)
OVAL = 0.92               # front-to-back over side-to-side
LEAN_X, LEAN_Y = 0.045, -0.015   # the top leans this far right and back
TOP_TILT = 0.025          # the cuff's rim drops this much towards the leaning side
CUFF_Z = (1.50, 1.70)
STRIPES = ((1.545, 1.565), (1.595, 1.615))
HEEL = (-math.pi / 2, 0.36)      # the heel bump: angle (back) and height
ANKLE_Z = 0.10
FOOT_X = 0.13
# (angle off the front, towards its left, height, radius) of the googly eyes; L is the creature's left (-x).
EYES = {"L": (0.43, 1.33, 0.118), "R": (-0.41, 1.30, 0.102)}
EYE_CAP = math.radians(52)       # the dome's half-angle
PUPIL_CAP = math.radians(25)
HOLD = (0.32, 0.92, 0.15)        # angle off the front (right), height, distance out
# The look bend (Q360): the spine's three joints, bottom up, each blending its two bones over
# BEND_BLEND either side. Below the first the base stands still; above the last (the eyes, the
# cuff) the top bends as one.
BEND_Z = (0.45, 0.80, 1.12)
BEND_BLEND = 0.10
BONES = ("Root", "Spine0", "Spine1", "Spine2")


def srgb(r, g, b, a=1.0):
    f = lambda c: c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return (f(r), f(g), f(b), a)


MATERIALS = {   # name: (colour, roughness); the first three are the Avatar's surfaces in order
    "player": (srgb(1.0, 1.0, 1.0), 0.85),
    "trim": (srgb(0.98, 0.92, 0.82), 0.8),
    "eye": (srgb(0.98, 0.97, 0.95), 0.25),
    "pupil": (srgb(0.09, 0.07, 0.07), 0.2),
}

# The body's profile: (height, radius), bottom up, then in over the top to the centre of the cap.
PROFILE = [(0.075, 0.0), (0.08, 0.10), (0.10, 0.19), (0.14, 0.255), (0.20, 0.295), (0.28, 0.318),
           (0.38, 0.328), (0.50, 0.326), (0.64, 0.314), (0.80, 0.296), (0.96, 0.278), (1.10, 0.264),
           (1.22, 0.256), (1.32, 0.253), (1.40, 0.252), (1.46, 0.252), (1.49, 0.262), (1.515, 0.272),
           (1.545, 0.276), (1.565, 0.277), (1.595, 0.278), (1.615, 0.278), (1.645, 0.279), (1.675, 0.279),
           (1.70, 0.268), (1.706, 0.245), (1.698, 0.2), (1.68, 0.11), (1.674, 0.0)]
_SIDE = [p for p in PROFILE if p[0] <= STAND and PROFILE.index(p) <= [q[0] for q in PROFILE].index(STAND)]   # up the side to the rim


def smooth(a, b, x):
    t = min(max((x - a) / (b - a), 0.0), 1.0)
    return t * t * (3 - 2 * t)


def radius_at(z):
    """The profile's radius at height z (up the side, linear between rings like the mesh)."""
    for (z0, r0), (z1, r1) in zip(_SIDE, _SIDE[1:]):
        if z0 <= z <= z1:
            return r0 + (r1 - r0) * (z - z0) / (z1 - z0)
    return _SIDE[-1][1] if z > _SIDE[-1][0] else 0.0


def angle_diff(a, b):
    return (a - b + math.pi) % (2 * math.pi) - math.pi


def body_point(theta, z, r=None, rib=0, off=0.0):
    """The body's surface at angle theta (0 = right, pi/2 = front) and profile height z.
    r overrides the profile's radius (the cap); rib is +1/-1/0 for the cuff's ribs; off pushes the
    point out along the surface (clothes)."""
    if r is None:
        r = radius_at(z)
    lump_w = 1.0 - smooth(1.40, 1.50, z)
    rr = r
    rr += lump_w * (r / 0.3) * (0.02 * math.sin(3 * theta + 4.1 * z + 0.6)
                                + 0.014 * math.sin(2 * theta - 6.3 * z + 2.0)
                                + 0.008 * math.sin(5 * theta + 9.0 * z))
    d = angle_diff(theta, HEEL[0])
    rr += 0.11 * (r / 0.3) * math.exp(-(d / 0.65) ** 2) * math.exp(-((z - HEEL[1]) / 0.15) ** 2)
    if CUFF_Z[0] + 0.01 < z < CUFF_Z[1] - 0.01:
        rr += 0.012 * rib
    rr += off
    x = rr * math.cos(theta)
    y = rr * math.sin(theta) * OVAL
    h = z / STAND
    zz = z - TOP_TILT * (x / 0.27) * smooth(1.40, 1.50, z)
    return Vector((x + LEAN_X * h * h, y + LEAN_Y * h * h, zz))


def surface_frame(theta, z, off=0.0):
    """Point and outward normal on the body (finite differences)."""
    p = body_point(theta, z, off=off)
    e = 1e-3
    dt = body_point(theta + e, z, off=off) - body_point(theta - e, z, off=off)
    dz = body_point(theta, z + e, off=off) - body_point(theta, z - e, off=off)
    n = dt.cross(dz).normalized()
    return p, n


def crouch_point(p):
    """Where a point on (or near) the body goes at full Crouch: the sock scrunches. The base over
    the feet (below BASE_Z) stays, the top with the eyes and cuff (above TOP_Z) drops rigidly by
    STAND - CROUCHED, and the middle squashes in between, bunching out by up to BULGE.
    Clothes use it for their own Crouch key, so they follow the body."""
    if p.z <= BASE_Z:
        return p.copy()
    drop = STAND - CROUCHED
    if p.z >= TOP_Z:
        return Vector((p.x, p.y, p.z - drop))
    t = (p.z - BASE_Z) / (TOP_Z - BASE_Z)
    z = BASE_Z + t * (TOP_Z - drop - BASE_Z)
    s = 1.0 + BULGE * math.sin(math.pi * t)
    return Vector((p.x * s, p.y * s, z))


def crouch_shift(p):
    """The rigid move of something riding on the body at p (eyes, pupils, attach points)."""
    return crouch_point(p) - p


def bend_weights(z):
    """The share of each bone (BONES) a point at rest height z goes with: the joints below it
    have turned, the one it straddles only partly."""
    s = [smooth(h - BEND_BLEND, h + BEND_BLEND, z) for h in BEND_Z]
    return [1.0 - s[0], s[0] - s[1], s[1] - s[2], s[2]]


def axis_point(z):
    """The body's leaning axis at height z (where the spine runs)."""
    return body_point(0.0, z, r=0.0)


def to_godot(v):
    return [round(v.x, 4), round(v.z, 4), round(-v.y, 4)]


# --- Mesh helpers ---------------------------------------------------------------------------

def lathe(profile, n=24):
    """Revolves (radius, z) points about z, from the bottom up so the normals face out."""
    bm = bmesh.new()
    rings = []
    for r, z in profile:
        if r < 1e-6:
            rings.append([bm.verts.new((0.0, 0.0, z))] * n)
        else:
            rings.append([bm.verts.new((r * math.cos(2 * math.pi * k / n), r * math.sin(2 * math.pi * k / n), z))
                          for k in range(n)])
    for a, b in zip(rings, rings[1:]):
        for k in range(n):
            j = (k + 1) % n
            uniq = []
            for v in (a[k], a[j], b[j], b[k]):
                if v not in uniq:
                    uniq.append(v)
            if len(uniq) >= 3:
                bm.faces.new(uniq)
    bm.normal_update()
    return bm


def sphere(r, steps=8, n=16):
    return lathe([(r * math.sin(math.pi * k / steps), -r * math.cos(math.pi * k / steps))
                  for k in range(steps + 1)], n)


def placed(bm, matrix):
    bmesh.ops.transform(bm, matrix=matrix, verts=bm.verts)
    return bm


def dome(radius, half_angle, steps=6, n=24, back=0.03):
    """A spherical cap of a sphere of `radius` centred at the origin, pointing up +z, closed at
    the back with a shallow cone."""
    base = radius * math.cos(half_angle)
    prof = [(0.0, base - back), (radius * math.sin(half_angle) * 0.97, base - back * 0.3)]
    for k in range(steps + 1):
        a = half_angle * (1 - k / steps)
        prof.append((radius * math.sin(a), radius * math.cos(a)))
    prof[-1] = (0.0, radius)
    return lathe(prof, n)


def frame_matrix(origin, forward):
    """Local +z along `forward`, at `origin`."""
    q = forward.to_track_quat("Z", "Y")
    return Matrix.Translation(origin) @ q.to_matrix().to_4x4()


def mesh_object(name, bm, mats, smooth_shade=True):
    for f in bm.faces:
        f.smooth = smooth_shade
    bm.normal_update()
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for m in mats:
        me.materials.append(bpy.data.materials[m])
    obj = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def append(dst, src, mat_index):
    """Merges bmesh src into dst, all its faces on mat_index; returns the new verts."""
    for f in src.faces:
        f.material_index = mat_index
        f.smooth = True
    me = bpy.data.meshes.new("tmp")
    src.to_mesh(me)
    src.free()
    before = len(dst.verts)
    dst.from_mesh(me)
    bpy.data.meshes.remove(me)
    dst.verts.ensure_lookup_table()
    dst.verts.index_update()   # from_mesh leaves the new verts with their indices in `src`
    return list(dst.verts[before:])


def add_crouch_key(obj, rigid=None):
    """A "Crouch" shape key: every vertex through crouch_point, except the groups in `rigid`
    ({vertex index: anchor point}) which move as one with their anchor."""
    rigid = rigid or {}
    obj.shape_key_add(name="Basis")
    key = obj.shape_key_add(name="Crouch", from_mix=False)
    for i, v in enumerate(obj.data.vertices):
        co = Vector(v.co)
        key.data[i].co = co + crouch_shift(rigid[i]) if i in rigid else crouch_point(co)
    key.value = 0.0          # new keys start at 1.0 in Blender 5; this is the export's default weight
    return key


def make_armature():
    """The bend's spine: Root up to the first joint, then Spine0..2 joint to joint, chained,
    up the leaning axis (rest = standing)."""
    data = bpy.data.armatures.new("Armature")
    arm = bpy.data.objects.new("Armature", data)
    bpy.context.scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    heads = (0.0,) + BEND_Z
    tails = BEND_Z + (STAND,)
    parent = None
    for name, z0, z1 in zip(BONES, heads, tails):
        b = data.edit_bones.new(name)
        b.head = axis_point(z0) if z0 > 0 else Vector((0.0, 0.0, 0.0))
        b.tail = axis_point(z1)
        b.roll = 0.0
        if parent is not None:
            b.parent = parent
            b.use_connect = False   # crouched, a joint pivots off its parent's tail
        parent = b
    bpy.ops.object.mode_set(mode="OBJECT")
    arm["bend_crouch_offset"] = [to_godot(crouch_shift(axis_point(z))) if z > 0 else [0.0, 0.0, 0.0]
                                 for z in heads]
    return arm


def add_bend_skin(obj, arm, rigid=None):
    """Skins `obj` to the bend's armature: every vertex by its rest height (bend_weights), except
    the groups in `rigid` ({vertex index: anchor point}) which go as their anchor does."""
    rigid = rigid or {}
    groups = [obj.vertex_groups.new(name=b) for b in BONES]
    for i, v in enumerate(obj.data.vertices):
        z = rigid[i].z if i in rigid else v.co.z
        for g, w in zip(groups, bend_weights(z)):
            if w > 1e-4:
                g.add([i], w, "REPLACE")
    mod = obj.modifiers.new("Bend", "ARMATURE")
    mod.object = arm
    obj.parent = arm


def set_bend_extras(obj, anchor):
    obj["bend_weights"] = [round(w, 4) for w in bend_weights(anchor.z)]


def empty(name, loc, rot=None):
    e = bpy.data.objects.new(name, None)
    e.empty_display_type = "PLAIN_AXES"
    e.empty_display_size = 0.08
    e.location = loc
    if rot is not None:
        e.rotation_euler = rot
    bpy.context.scene.collection.objects.link(e)
    return e


def set_crouch_extras(obj, anchor):
    shift = crouch_shift(anchor)
    obj["crouch_drop"] = round(-shift.z, 4)
    obj["crouch_offset"] = to_godot(shift)


def make_materials(table=MATERIALS):
    for name, (color, rough) in table.items():
        if name in bpy.data.materials:
            continue
        m = bpy.data.materials.new(name)
        bsdf = m.node_tree.nodes["Principled BSDF"]
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Roughness"].default_value = rough
        m.diffuse_color = color


# --- The creature ---------------------------------------------------------------------------

def body_mesh():
    bm = bmesh.new()
    rings = []
    for z, r in PROFILE:
        on_side = (z, r) in _SIDE
        if r < 1e-6:
            c = body_point(0.0, z, r=0.0)
            rings.append([bm.verts.new(c)] * SEG)
            continue
        ring = []
        for k in range(SEG):
            th = 2 * math.pi * k / SEG
            rib = (1 if k % 2 == 0 else -1) if on_side else 0
            p = body_point(th, z if on_side else min(z, 1.70), r=r, rib=rib)
            if not on_side:
                p.z += z - 1.70   # in over the rim: same tilt, lower by the profile
            ring.append(bm.verts.new(p))
        rings.append(ring)
    zs = [z for z, _ in PROFILE]
    for j, (a, b) in enumerate(zip(rings, rings[1:])):
        zmid = (zs[j] + zs[j + 1]) / 2
        up = zs[j + 1] >= zs[j]
        for k in range(SEG):
            m = (k + 1) % SEG
            uniq = []
            for v in (a[k], a[m], b[m], b[k]):
                if v not in uniq:
                    uniq.append(v)
            if len(uniq) < 3:
                continue
            f = bm.faces.new(uniq)
            th = 2 * math.pi * (k + 0.5) / SEG
            trim = up and any(lo <= zmid <= hi for lo, hi in STRIPES)
            trim |= up and (angle_diff(th, HEEL[0]) / 0.85) ** 2 + ((zmid - HEEL[1]) / 0.2) ** 2 < 1.0
            f.material_index = 1 if trim else 0
            f.smooth = True
    bm.normal_update()
    return bm


def eye_parts(side):
    """(white dome bmesh in body space, pupil bmesh in its node's space, the node's matrix,
    the surface anchor)."""
    off, z, r = EYES[side]
    theta = math.pi / 2 + off
    p, n = surface_frame(theta, z)
    rs = r / math.sin(EYE_CAP)
    lift = 0.35 * r                                      # how far the dome stands off the body
    centre = p + n * (lift - rs)
    m = frame_matrix(centre, n)
    white = placed(dome(rs, EYE_CAP, back=0.03), m)
    pupil = dome(rs + 0.004, PUPIL_CAP, steps=3, n=20, back=0.006)
    # Pupil node: local +y (Godot -z, forward) is the eye's axis, so the cap is built along +y.
    pupil = placed(pupil, Matrix.Rotation(-math.pi / 2, 4, "X"))
    node = Matrix.Translation(centre) @ n.to_track_quat("Y", "Z").to_matrix().to_4x4()
    return white, pupil, node, p


def foot_mesh():
    """A stubby foot: a squashed egg pointing forward, flat-ish underneath, ankle at the origin."""
    prof = []
    steps = 8
    for k in range(steps + 1):
        a = math.pi * k / steps
        prof.append((math.sin(a), -math.cos(a)))
    bm = lathe(prof, 16)
    for v in bm.verts:   # egg: fatter at the toe end (+z here, becomes +y)
        if v.co.z > 0:
            v.co.x *= 1.0 + 0.18 * v.co.z
            v.co.y *= 1.0 + 0.18 * v.co.z
    bm = placed(bm, Matrix.Rotation(-math.pi / 2, 4, "X"))   # long axis along +y
    bm = placed(bm, Matrix.Diagonal((0.085, 0.13, 0.055, 1.0)))
    for v in bm.verts:
        if v.co.z < -0.03:
            v.co.z = -0.03 + (v.co.z + 0.03) * 0.35        # flatten the sole
    return placed(bm, Matrix.Translation((0.0, 0.085, -ANKLE_Z + 0.046)))


def build():
    """Builds the creature; returns {node name: object}."""
    make_materials()
    bm = body_mesh()
    rigid_anchor = {}
    pupils = {}
    for side in ("L", "R"):
        white, pupil, node, anchor = eye_parts(side)
        for v in append(bm, white, 2):
            rigid_anchor[v.index] = anchor
        pupils[side] = (pupil, node, anchor)
    body = mesh_object("Avatar", bm, ["player", "trim", "eye"])
    add_crouch_key(body, rigid_anchor)
    arm = make_armature()
    add_bend_skin(body, arm, rigid_anchor)
    nodes = {"Avatar": body, "Armature": arm}
    for side, (pbm, node, anchor) in pupils.items():
        o = mesh_object("Pupil" + side, pbm, ["pupil"])
        o.matrix_world = node
        set_crouch_extras(o, anchor)
        set_bend_extras(o, anchor)
        nodes["Pupil" + side] = o
    for side, sx in (("L", -1), ("R", 1)):
        fb = foot_mesh()
        splay = Matrix.Rotation(-sx * math.radians(10), 4, "Z")
        fb = placed(fb, splay)
        o = mesh_object("Foot" + side, fb, ["trim"])
        o.location = (sx * FOOT_X, 0.0, ANKLE_Z)
        nodes["Foot" + side] = o
    hp, hn = surface_frame(math.pi / 2 - HOLD[0], HOLD[1])
    hold = empty("HoldPoint", hp + hn * HOLD[2])
    set_crouch_extras(hold, hp)
    set_bend_extras(hold, hp)
    top = body_point(0.0, STAND, r=0.0)
    head = empty("Head", top)
    set_crouch_extras(head, top)
    set_bend_extras(head, top)
    lean_slope = 2 * LEAN_X * STAND / STAND ** 2
    tilt = math.atan(TOP_TILT / 0.27) + math.atan(lean_slope)
    hat = empty("HatPoint", top, (0.0, tilt, 0.0))
    set_crouch_extras(hat, top)
    set_bend_extras(hat, top)
    nodes.update({"HoldPoint": hold, "Head": head, "HatPoint": hat})
    return nodes


def tris(obj):
    obj.data.calc_loop_triangles()
    return len(obj.data.loop_triangles)


def export(objs, path):
    for o in bpy.context.scene.objects:
        o.select_set(o in objs)
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_yup=True, export_apply=False,
                              export_morph=True, export_extras=True, export_cameras=False,
                              export_lights=False, use_selection=True)


# --- Previews -------------------------------------------------------------------------------

def setup_stage(final, res):
    """Floor, camera and light (EEVEE when final, else flat Workbench). Returns the camera."""
    scene = bpy.context.scene
    scene.render.threads_mode = "FIXED"
    scene.render.threads = 4
    scene.view_settings.view_transform = "Standard"
    fm = bpy.data.materials.new("FloorMat")
    fc = srgb(0.86, 0.74, 0.60)
    fm.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = fc
    fm.diffuse_color = fc
    me = bpy.data.meshes.new("Floor")
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=12.0)
    bm.to_mesh(me)
    bm.free()
    me.materials.append(fm)
    scene.collection.objects.link(bpy.data.objects.new("Floor", me))
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
    cam.data.lens = 50
    scene.collection.objects.link(cam)
    scene.camera = cam
    if final:
        world = bpy.data.worlds.new("W")
        world.use_nodes = True
        world.node_tree.nodes["Background"].inputs[0].default_value = srgb(0.86, 0.82, 0.78)
        world.node_tree.nodes["Background"].inputs[1].default_value = 0.55
        scene.world = world
        key = bpy.data.objects.new("Key", bpy.data.lights.new("Key", "AREA"))
        key.data.energy, key.data.size = 320, 2.0
        key.location = (2.0, 3.5, 3.4)
        key.rotation_euler = (Vector((0, 0, 0.9)) - key.location).to_track_quat("-Z", "Y").to_euler()
        scene.collection.objects.link(key)
        scene.render.engine = "BLENDER_EEVEE"
        scene.eevee.taa_render_samples = 16
    else:
        scene.render.engine = "BLENDER_WORKBENCH"
        scene.display.render_aa = "OFF"
        sh = scene.display.shading
        sh.light = "STUDIO"
        sh.color_type = "MATERIAL"
        sh.show_shadows = False
        sh.show_cavity = False
        res = (res[0] // 2, res[1] // 2)
    scene.render.resolution_x, scene.render.resolution_y = res
    return cam


def shoot(cam, loc, target, path):
    cam.location = loc
    cam.rotation_euler = (Vector(target) - cam.location).to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def tint(mat_name, rgb):
    m = bpy.data.materials[mat_name]
    c = srgb(*rgb)
    m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = c
    m.diffuse_color = c


def pose_crouch(nodes):
    """Puts the creature (and anything with a Crouch key) at full Crouch for a preview."""
    for o in bpy.context.scene.objects:
        if o.type == "MESH" and o.data.shape_keys and "Crouch" in o.data.shape_keys.key_blocks:
            o.data.shape_keys.key_blocks["Crouch"].value = 1.0
        if "crouch_offset" in o.keys():
            g = list(o["crouch_offset"])
            o.location += Vector((g[0], -g[2], g[1]))


def bend_matrices(degrees, crouch=0.0):
    """Each bone's move (BONES order, armature space) at a bend of `degrees` in all, shared over
    the three joints (+ curls forward, looking down; - leans back), each joint pivoting where the
    Crouch at weight `crouch` took it. game/player/avatar.gd does the same sums."""
    per = math.radians(degrees) / (len(BONES) - 1)
    out = [Matrix.Identity(4)]
    for z in BEND_Z:
        c = axis_point(z) + crouch * crouch_shift(axis_point(z))
        turn = Matrix.Translation(c) @ Matrix.Rotation(-per, 4, "X") @ Matrix.Translation(-c)
        out.append(out[-1] @ turn)
    return out


def pose_bend(degrees, crouch=0.0):
    """Bends every creature in the scene by `degrees` (bend_matrices()), and moves the empties and
    pupils riding on it as their bend_weights say (their crouch already applied)."""
    moves = bend_matrices(degrees, crouch)
    arms = [o for o in bpy.context.scene.objects if o.type == "ARMATURE"]
    for arm in arms:
        for name, m in zip(BONES, moves):
            arm.pose.bones[name].matrix = m @ arm.data.bones[name].matrix_local
            bpy.context.view_layer.update()
    for o in bpy.context.scene.objects:
        if "bend_weights" not in o.keys():
            continue
        moved = Matrix.Diagonal((0.0, 0.0, 0.0, 0.0))
        for wk, m in zip(list(o["bend_weights"]), moves):
            moved += wk * m
        loc, rot, scale = (moved @ o.matrix_basis).decompose()
        o.matrix_basis = Matrix.LocRotScale(loc, rot, Vector((1.0, 1.0, 1.0)))


def render_previews(nodes, preview_dir, final, crouch, bend=0.0):
    cam = setup_stage(final, (800, 1000))
    tint("player", (0.52, 0.78, 0.82))
    if crouch:
        pose_crouch(nodes)
    if bend:
        pose_bend(bend, 1.0 if crouch else 0.0)
    target = (0, 0, 0.85)
    suffix = ("_crouch" if crouch else "") + ("_bend%+d" % round(bend) if bend else "")
    for name, loc in (("avatar_front", (0.0, 4.6, 0.95)), ("avatar_three_quarter", (2.9, 3.4, 1.5)),
                      ("avatar_side", (4.6, 0.0, 0.95))):
        shoot(cam, loc, target, os.path.join(preview_dir, name + suffix + ".png"))


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    final = "--final" in argv
    crouch = "--crouch" in argv
    bend = next((float(a.split("=", 1)[1]) for a in argv if a.startswith("--bend=")), 0.0)
    pos = [a for a in argv if not a.startswith("--")]
    out_dir = pos[0] if pos else "."
    preview_dir = pos[1] if len(pos) > 1 else None
    bpy.ops.wm.read_factory_settings(use_empty=True)
    nodes = build()
    export(list(nodes.values()), os.path.join(out_dir, "avatar.glb"))
    export([nodes["FootL"], nodes["FootR"]], os.path.join(out_dir, "feet.glb"))
    print("EXPORTED", out_dir, {n: tris(o) for n, o in nodes.items() if o.type == "MESH"})
    if preview_dir:
        os.makedirs(preview_dir, exist_ok=True)
        render_previews(nodes, preview_dir, final, crouch, bend)


if __name__ == "__main__":
    main()
