"""The talking washing machine's face (rogue-machine/04 phase 1a, Q1374, Q1381): no eye, the door is
the mouth (on its side hinge, Q1392), two thick dark rounded brows, and a rig with mood poses and
loops, applied to the pipeline/02 model in assets_src/blender/appliance/washing_machine.blend.

Ported from the old game's tools/blender/make_washing_machine_face.py (assets/14, Q2151-Q2153: technical
changes only, the shapes, poses and loops are the old numbers). Run by assets_src/generate/build.py
(`-- appliance`), which opens the .blend, calls build() and export(). What differs from the old script:
- Every bone points up (Blender +Z, roll 0), so every rest in Godot is a plain move with no turn
  (washer_acting.tres keys the brows and the door on such rests; the old brows pointed out of the face
  and the drum's two bones back into it). The poses are set in armature space (_set), so every
  action moves the meshes exactly as before.
- The glowing lining behind the drum's holes and the power light (both drum_glow) are one mesh,
  `Lining`: its lining part skinned to drum_spin, its power light to bob. The Looks scene colours that
  one mesh per mood (WasherLooks `lining`), so the power light still glows with the drum.
- The laundry is the mesh `Pile`, parented rigid to laundry_tumble (Godot: a BoneAttachment3D), its
  origin the heap's bottom middle: the Looks scales it from there to show more or less laundry, as
  the old game scaled its copy of the heap.
- export(): the rig, everything on it and the collider, with the eight actions (only the bones each
  keys), and no root object, so `face_rig` is a top node of the glb (the Looks contract).

The rig `face_rig` (Godot: a Skeleton3D at the top of the glb), every bone's rest is the neutral face:
- `lean`: the mood's lean, keyed by the mood actions (pivots on the front or back feet).
- `bob`: under `lean`, keyed by the `talk` and `rumble` loops only, so they add over a mood.
- `door_hinge`: under `bob`, on the door's side hinge (upright); turning it about the upright
  (the hinge line) swings the mouth open, 0 to DOOR_OPEN_DEG. Action `mouth` runs shut (frame
  0) to open (frame MOUTH_FRAMES) linearly in angle: the game seeks it by a 0-1 value.
- `brow_left_pivot` (moves mesh `brow_left`, at -X, the left as players face it) and
  `brow_right_pivot`: under `bob`; a tilt is a turn about the axis out of the face, a raise moves
  it along the face's up.
- `drum_spin` (moves mesh `drum` and the lining of `Lining`) and `laundry_tumble` (moves `Pile`):
  under `bob`, both on the drum's axis; a turn about that axis turns the drum (or swings the
  laundry round it). So the drum leans and bobs with the body.
Actions: `angry`, `calming`, `entitled`, `surprised` (holds; keys on lean and the brows), `talk` and `rumble`
(loops; keys on bob only: the drum and laundry stay still while it talks, the machine is broken,
Q1411), `spin` (loop, 30 frames: the drum one full turn, the laundry tumbling; keys on drum_spin
and laundry_tumble only, for the game's real wash, after the Final wash) and `mouth` (keys on
door_hinge). Each action keys only its own bones, so the Looks' three players never fight.
The drum is the lit drum (Q1400, Q1401): a dark perforated drum, no paddles, glowing from behind
its holes, with dark laundry lumps tumbling in silhouette against its glowing back. The glow is
the material `drum_glow`; its colour per mood is the game's (MOOD_GLOW below, washer_acting.tres),
glTF actions don't carry material colours. The stills add a point light of that colour at
DRUM_CENTRE (not exported); the game does the same (DrumLight on a BoneAttachment3D of `drum_spin`).
"""
import math

import bmesh
import bpy
from mathutils import Matrix, Quaternion, Vector

FPS = 30
ROOT = "washing_machine"
RIG = "face_rig"
# The side hinge's line, upright through pipeline/02's knuckles on the door ring's left (Q1392).
DOOR_PIVOT = Vector((-0.262, -0.318, 0.420))
# Fully open: wide enough to read as a mouth from the players' front-three-quarter view, small
# enough that quick lip-sync flaps stay a flap, not a door swinging wide.
DOOR_OPEN_DEG = 40.0
MOUTH_FRAMES = 30
BROW_CENTRE = {"brow_left": Vector((-0.115, -0.311, 0.729)), "brow_right": Vector((0.115, -0.311, 0.729))}
# Each moving mesh's bone (bones named apart from meshes: Godot keeps node names unique).
BONE = {"door": "door_hinge", "brow_left": "brow_left_pivot", "brow_right": "brow_right_pivot",
        "drum": "drum_spin", "laundry": "laundry_tumble"}
BROW_SIZE = (0.185, 0.072, 0.078)  # x, y, z of the cage before smoothing
FRONT_FEET = Vector((0.0, -0.248, 0.0))  # the lean's pivots: the feet's outer edges
BACK_FEET = Vector((0.0, 0.268, 0.0))
# The drum glow's colour (linear RGB) and strength per mood, for the game and the stills.
MOOD_GLOW = {"angry": ((1.0, 0.02, 0.005), 3.0), "calming": ((1.0, 0.45, 0.12), 2.0),
             "entitled": ((0.50, 0.06, 1.0), 2.4),  # purple (Q1393)
             "surprised": ((0.95, 0.8, 0.55), 1.2),
             "neutral": ((0.9, 0.75, 0.5), 0.6)}
# Mood poses: lean degrees (+ forward), per brow (tilt degrees, + lowers the inner end; raise metres).
# The brow numbers are also in tools/voiceover/brows.py (MOODS), which writes each line's brow keys.
MOODS = {
    "angry": {"lean": 5.0, "brow_left": (24.0, -0.004), "brow_right": (24.0, -0.004)},
    "calming": {"lean": 0.0, "brow_left": (0.0, 0.012), "brow_right": (0.0, 0.012)},
    "entitled": {"lean": -5.0, "brow_left": (12.0, -0.010), "brow_right": (-6.0, 0.052)},
    "surprised": {"lean": -2.0, "brow_left": (-10.0, 0.035), "brow_right": (-10.0, 0.035)},
}
# The lit drum (Q1400): its axis along Y through DRUM_CENTRE, the old steel drum's size.
DRUM_CENTRE = Vector((0.0, -0.10, 0.42))
DRUM_R, DRUM_Y0, DRUM_Y1 = 0.19, -0.222, 0.018  # radius, front and back
DRUM_SLEEVE = (20, 4)  # perforation cells around and along the sleeve
DRUM_BACK_RINGS = (0.045, 0.095, 0.142, DRUM_R)  # the back plate's cell rings ...
DRUM_BACK_CELLS = (8, 16, 16)  # ... and cells per ring
HOLE = 0.46  # a hole's half-width, in a cell's half-width
GLASS_ALPHA = 0.07  # the clearer porthole glass (Q1401)
LINING = "Lining"  # the Looks contract's names (game/entities/washer/looks_contract.json "named")
PILE = "Pile"
COLLIDER = "body-convcolonly"
EYE = ["eye_white", "iris", "pupil", "eyelid_upper", "eyelid_lower"]
X, Y, Z = Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1))


# --- materials -----------------------------------------------------------------------------------

def _material(name, colour, rough=0.5, emission=None, strength=0.0):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = (*colour, 1.0)
    bsdf.inputs["Roughness"].default_value = rough
    if emission is not None:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = strength
        bsdf.inputs["Specular IOR Level"].default_value = 0.0  # a pure glow, no highlight on it
    m.diffuse_color = (*(emission or colour), 1.0)
    return m


def set_glow(mood):
    """Colours drum_glow for a mood (the stills; the game does the same on its copy)."""
    colour, strength = MOOD_GLOW[mood]
    _material("drum_glow", (0.0, 0.0, 0.0), 1.0, colour, strength)


# --- mesh helpers --------------------------------------------------------------------------------

def _bake_transform(obj):
    """Moves obj's own location into its mesh (a skinned mesh's node transform is dropped)."""
    if obj.location.length > 0:
        obj.data.transform(Matrix.Translation(obj.location))
        obj.location = (0, 0, 0)
        bpy.context.view_layer.update()  # matrix_world, which _join reads


def _join(target, src):
    """Appends src's mesh into target (object space, materials mapped), then removes src."""
    m = target.matrix_world.inverted() @ src.matrix_world
    slots = []
    for s in src.material_slots:
        names = [t.material.name for t in target.material_slots]
        if s.material.name not in names:
            target.data.materials.append(s.material)
            names.append(s.material.name)
        slots.append(names.index(s.material.name))
    bm = bmesh.new()
    bm.from_mesh(target.data)
    other = src.data.copy()
    other.transform(m)
    for p in other.polygons:
        p.material_index = slots[p.material_index]
    bm.from_mesh(other)
    bm.to_mesh(target.data)
    bm.free()
    bpy.data.meshes.remove(other)
    bpy.data.objects.remove(src)


def _new_obj(name, me, parent, mats):
    old = bpy.data.objects.get(name)
    if old is not None:
        old_me = old.data
        bpy.data.objects.remove(old)
        if old_me.users == 0:
            bpy.data.meshes.remove(old_me)
    me.name = name
    for m in mats:
        me.materials.append(m)
    o = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(o)
    o.parent = parent
    for p in me.polygons:
        p.use_smooth = True
    return o


# --- the build steps -----------------------------------------------------------------------------

def remove_eye():
    gone = []
    for n in EYE + ["brow_left", "brow_right"]:
        o = bpy.data.objects.get(n)
        if o is not None:
            me = o.data
            bpy.data.objects.remove(o)
            if me.users == 0:
                bpy.data.meshes.remove(me)
            gone.append(n)
    return gone


def prepare_door(door):
    """Joins the glass into the door and bakes the door's location into its mesh (a skinned mesh's
    node transform is dropped); the side hinge and latch of pipeline/02 stay as they are (Q1392)."""
    glass = bpy.data.objects.get("glass")
    if glass is not None:
        _join(door, glass)
    _bake_transform(door)


def make_brows(parent, mat):
    """Two thick rounded bars: a cage of 6 segments along x, arched and fatter in the middle, smoothed
    by a subdivision modifier (applied at export)."""
    out = {}
    sx, sy, sz = BROW_SIZE
    for name, c in BROW_CENTRE.items():
        bm = bmesh.new()
        segs = 6
        rings = []
        for i in range(segs + 1):
            u = i / segs * 2 - 1  # -1..1 along the bar
            fat = 1.0 - 0.22 * u * u
            lift = 0.010 * (1 - u * u)
            ring = []
            for (py, pz) in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
                ring.append(bm.verts.new((u * sx / 2, py * sy / 2, pz * sz / 2 * fat + lift)))
            rings.append(ring)
        for a, b in zip(rings, rings[1:]):
            for k in range(4):
                bm.faces.new((a[k], b[k], b[(k + 1) % 4], a[(k + 1) % 4]))
        bm.faces.new(list(reversed(rings[0])))
        bm.faces.new(rings[-1])
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
        bmesh.ops.translate(bm, verts=bm.verts[:], vec=c)
        me = bpy.data.meshes.new(name)
        bm.to_mesh(me)
        bm.free()
        o = _new_obj(name, me, parent, [mat])
        sub = o.modifiers.new("smooth", "SUBSURF")
        sub.levels = sub.render_levels = 2
        out[name] = o
    return out


def remove_old_drum(body):
    """Deletes pipeline/02's steel drum and its three paddles from the body (Q1401): the all-steel
    pieces inside the drum's space. Nothing happens once they are gone."""
    steel = [i for i, s in enumerate(body.material_slots) if s.material and s.material.name == "steel"]
    bm = bmesh.new()
    bm.from_mesh(body.data)
    seen, gone = set(), []
    for f in bm.faces:
        if f.index in seen:
            continue
        isl, stack = [], [f]
        seen.add(f.index)
        while stack:
            g = stack.pop()
            isl.append(g)
            for e in g.edges:
                for h in e.link_faces:
                    if h.index not in seen:
                        seen.add(h.index)
                        stack.append(h)
        vs = {v for g in isl for v in g.verts}
        lo = Vector([min(v.co[i] for v in vs) for i in range(3)])
        hi = Vector([max(v.co[i] for v in vs) for i in range(3)])
        inside = (lo.x > -0.2 and hi.x < 0.2 and lo.y > -0.23 and hi.y < 0.03 and lo.z > 0.22
                  and hi.z < 0.62)
        if inside and all(g.material_index in steel for g in isl):
            gone += isl
    n = len(gone)
    if gone:
        bmesh.ops.delete(bm, geom=list({v for g in gone for v in g.verts}), context="VERTS")
        bm.to_mesh(body.data)
    bm.free()
    return n


def _cell(bm, c, solid, faces_out):
    """One perforation cell on the corners c (4 verts, in order): a quad, or a ring round an
    octagonal hole (corners bilinearly blended, so it suits the sleeve's and the back's cells)."""
    if solid:
        faces_out.append(bm.faces.new(c))
        return
    p = [v.co for v in c]

    def at(u, v):  # u, v in -1..1 across the cell
        a, b = (1 - u) / 2, (1 + u) / 2
        lo = p[0] * a + p[1] * b
        hi = p[3] * a + p[2] * b
        return lo * ((1 - v) / 2) + hi * ((1 + v) / 2)

    # The corners sit at 225, 315, 45 and 135 degrees in (u, v); the octagon's points between them.
    o = []
    for m in range(8):
        a = math.radians(225 + 22.5 + 45 * m)
        o.append(bm.verts.new(at(HOLE * math.cos(a), HOLE * math.sin(a))))
    for k in range(4):
        ck, cn = c[k], c[(k + 1) % 4]
        oa, ob, oc = o[(2 * k - 1) % 8], o[2 * k], o[2 * k + 1]
        faces_out.append(bm.faces.new((ck, ob, oa)))
        faces_out.append(bm.faces.new((ck, cn, oc, ob)))


def make_drum(parent, dark, glow):
    """The lit drum (Q1400): a dark perforated sleeve and back plate (no paddles), and just behind
    them a glowing lining that shows through every hole. Faces point into the drum."""
    bm = bmesh.new()
    cx, cz = DRUM_CENTRE.x, DRUM_CENTRE.z
    n_round, n_along = DRUM_SLEEVE
    walls = []
    grid = []
    for j in range(n_along + 1):
        y = DRUM_Y0 + (DRUM_Y1 - DRUM_Y0) * j / n_along
        grid.append([bm.verts.new((cx + DRUM_R * math.cos(2 * math.pi * i / n_round), y,
                                   cz + DRUM_R * math.sin(2 * math.pi * i / n_round)))
                     for i in range(n_round)])
    for j in range(n_along):
        for i in range(n_round):
            k = (i + 1) % n_round
            _cell(bm, [grid[j][i], grid[j][k], grid[j + 1][k], grid[j + 1][i]], (i + j) % 2 == 1, walls)
    # The back plate: rings of cells round a solid hub, staggered holes; its rim overlaps the
    # sleeve's back edge by 2 mm, so no seam lets the lining through.
    def circle(r, n):
        return [bm.verts.new((cx + r * math.cos(2 * math.pi * i / n), DRUM_Y1, cz + r * math.sin(2 * math.pi * i / n)))
                for i in range(n)]

    inner = circle(DRUM_BACK_RINGS[0], DRUM_BACK_CELLS[0])
    walls.append(bm.faces.new(inner))
    for ring, n in enumerate(DRUM_BACK_CELLS):
        if len(inner) < n:  # double the inner ring with points on its edges (no crack)
            inner = [v for i in range(len(inner)) for v in
                     (inner[i], bm.verts.new(inner[i].co.lerp(inner[(i + 1) % len(inner)].co, 0.5)))]
        r_out = DRUM_BACK_RINGS[ring + 1] + (0.002 if ring + 1 == len(DRUM_BACK_CELLS) else 0.0)
        outer = circle(r_out, n)
        for i in range(n):
            k = (i + 1) % n
            _cell(bm, [inner[i], inner[k], outer[k], outer[i]], (i + ring) % 2 == 1, walls)
        inner = outer
    # The glow lining: a sleeve just outside, a disc just behind.
    g_r, g_back, segs = DRUM_R + 0.007, DRUM_Y1 + 0.007, n_round
    front = [bm.verts.new((cx + g_r * math.cos(2 * math.pi * i / segs), DRUM_Y0 + 0.004,
                           cz + g_r * math.sin(2 * math.pi * i / segs))) for i in range(segs)]
    back = [bm.verts.new((cx + g_r * math.cos(2 * math.pi * i / segs), g_back,
                          cz + g_r * math.sin(2 * math.pi * i / segs))) for i in range(segs)]
    lining = [bm.faces.new((front[i], front[(i + 1) % segs], back[(i + 1) % segs], back[i]))
              for i in range(segs)]
    lining.append(bm.faces.new(back))
    bm.normal_update()
    axis_c = Vector((cx, 0.0, cz))
    for f in bm.faces:
        mid = f.calc_center_median()
        if abs(mid.y - DRUM_Y1) < 0.004 or abs(mid.y - g_back) < 0.004:
            want = Vector((0, -1, 0))  # the back faces the front
        else:
            want = Vector((axis_c.x, mid.y, axis_c.z)) - mid  # the sleeve faces the axis
        if f.normal.dot(want) < 0:
            f.normal_flip()
    # Port: the walls are the mesh `drum`, the lining goes into `Lining` (make_lining).
    bm.faces.index_update()
    lining_ix = {f.index for f in lining}
    lin = bm.copy()
    lin.faces.index_update()
    bmesh.ops.delete(bm, geom=lining, context="FACES")
    bmesh.ops.delete(lin, geom=[f for f in lin.faces[:] if f.index not in lining_ix], context="FACES")
    me = bpy.data.meshes.new("drum")
    bm.to_mesh(me)
    bm.free()
    lining_me = bpy.data.meshes.new("drum_lining")
    lin.to_mesh(lining_me)
    lin.free()
    return _new_obj("drum", me, parent, [dark]), lining_me


def _power_light(body, glow):
    """The power light's faces (drum_glow on the body, the old eye's iris): taken out of the body the
    first time, after that out of the old `Lining` (its faces on bob). A mesh in object space, or None."""
    lining = bpy.data.objects.get(LINING)
    if lining is not None and "bob" in lining.vertex_groups:
        src, keep = lining, lambda f, bob: all(bob in [g.group for g in lining.data.vertices[i].groups]
                                               for i in f.vertices)
        bob = lining.vertex_groups["bob"].index
        faces = [f.index for f in src.data.polygons if keep(f, bob)]
        delete_from_src = False
    else:
        src = body
        mats = [i for i, sl in enumerate(body.material_slots) if sl.material == glow]
        faces = [f.index for f in body.data.polygons if f.material_index in mats]
        delete_from_src = True
    if not faces:
        return None
    bm = bmesh.new()
    bm.from_mesh(src.data)
    bm.faces.ensure_lookup_table()
    chosen = {bm.faces[i] for i in faces}
    part = bm.copy()
    part.faces.index_update()
    want = set(faces)
    bmesh.ops.delete(part, geom=[f for f in part.faces[:] if f.index not in want], context="FACES")
    if delete_from_src:
        bmesh.ops.delete(bm, geom=list(chosen), context="FACES")
        bm.to_mesh(src.data)
    bm.free()
    me = bpy.data.meshes.new("power_light")
    part.to_mesh(me)
    part.free()
    me.transform(src.matrix_world)
    return me


def make_lining(rig, lining_me, light_me, glow):
    """`Lining`: the drum's glowing lining (skinned to drum_spin) and the power light (skinned to bob),
    one mesh in drum_glow so the Looks colours both at once."""
    n_lining = len(lining_me.vertices)
    bm = bmesh.new()
    bm.from_mesh(lining_me)
    if light_me is not None:
        bm.from_mesh(light_me)
    me = bpy.data.meshes.new(LINING)
    bm.to_mesh(me)
    bm.free()
    for m in [lining_me, light_me]:
        if m is not None:
            bpy.data.meshes.remove(m)
    for p in me.polygons:
        p.material_index = 0
    o = _new_obj(LINING, me, rig, [glow])
    o.matrix_parent_inverse = Matrix.Identity(4)
    spin = o.vertex_groups.new(name=BONE["drum"])
    spin.add(list(range(n_lining)), 1.0, "REPLACE")
    bob = o.vertex_groups.new(name="bob")
    if len(me.vertices) > n_lining:
        bob.add(list(range(n_lining, len(me.vertices))), 1.0, "REPLACE")
    mod = o.modifiers.new("rig", "ARMATURE")
    mod.object = rig
    return o


def make_laundry(parent, mat):
    """A heap of dark lumps in the drum's lower half (Q1400), silhouettes against the glowing back:
    squashed, dented low spheres, a seeded shape so a rebuild matches."""
    import random
    rnd = random.Random(1400)
    bm = bmesh.new()
    lumps = [((-0.045, -0.085, 0.275), (0.095, 0.060, 0.034), 8, 2),  # two heaps of clothes
             ((0.075, -0.060, 0.287), (0.075, 0.055, 0.036), 25, 2),
             ((-0.135, -0.120, 0.330), (0.022, 0.024, 0.072), 28, 1),  # a sock up the side
             ((0.020, -0.150, 0.305), (0.065, 0.020, 0.022), -18, 1)]  # another, draped on top
    for (c, size, tilt, subdiv) in lumps:
        geom = bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=1.0)
        vs = geom["verts"]
        for v in vs:
            d = 1.0 + rnd.uniform(-0.22, 0.12)  # dented: crumpled cloth, not balls
            v.co = Vector((v.co.x * size[0] * d, v.co.y * size[1] * d, v.co.z * size[2] * d))
        bmesh.ops.rotate(bm, verts=vs, cent=Vector(), matrix=Matrix.Rotation(math.radians(tilt), 3, "Y"))
        bmesh.ops.translate(bm, verts=vs, vec=Vector(c))
    bm.normal_update()
    # Port: its origin is the heap's bottom middle, where the old game scaled its copy from (pile).
    lo = Vector([min(v.co[i] for v in bm.verts) for i in range(3)])
    hi = Vector([max(v.co[i] for v in bm.verts) for i in range(3)])
    pivot = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))
    bmesh.ops.translate(bm, verts=bm.verts[:], vec=-pivot)
    me = bpy.data.meshes.new(PILE)
    bm.to_mesh(me)
    bm.free()
    old = bpy.data.objects.get("laundry")  # the old script's name
    if old is not None:
        old_me = old.data
        bpy.data.objects.remove(old)
        if old_me.users == 0:
            bpy.data.meshes.remove(old_me)
    return _new_obj(PILE, me, parent, [mat]), pivot


def hang(obj, rig, bone, at):
    """Parents obj rigid to a bone (Godot: a BoneAttachment3D), its origin at `at` in the rest pose."""
    obj.vertex_groups.clear()
    for m in [m for m in obj.modifiers if m.type == "ARMATURE"]:
        obj.modifiers.remove(m)
    obj.parent = rig
    obj.parent_type = "BONE"
    obj.parent_bone = bone
    bpy.context.view_layer.update()
    obj.matrix_world = Matrix.Translation(at)


def make_rig(root):
    old = bpy.data.objects.get(RIG)
    if old is not None:
        arm_old = old.data
        bpy.data.objects.remove(old)
        bpy.data.armatures.remove(arm_old)
    arm = bpy.data.armatures.new(RIG)
    rig = bpy.data.objects.new(RIG, arm)
    bpy.context.scene.collection.objects.link(rig)
    rig.parent = root
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")
    bones = {
        "lean": ((0, 0, 0), (0, 0, 0.30), None),
        "bob": ((0, 0, 0.0), (0, 0, 0.20), "lean"),
        BONE["door"]: (tuple(DOOR_PIVOT), tuple(DOOR_PIVOT + Vector((0, 0, 0.12))), "bob"),
    }
    # Port: every bone points up, roll 0, so its rest in Godot is a move only (the old brows pointed out
    # of the face and the drum's bones back into it).
    for name, c in BROW_CENTRE.items():
        bones[BONE[name]] = (tuple(c), tuple(c + Vector((0, 0, 0.08))), "bob")
    for name in ("drum", "laundry"):  # on the drum's axis
        bones[BONE[name]] = (tuple(DRUM_CENTRE), tuple(DRUM_CENTRE + Vector((0, 0, 0.10))), "bob")
    for name, (h, t, parent) in bones.items():
        eb = arm.edit_bones.new(name)
        eb.head, eb.tail, eb.roll = h, t, 0.0
        if parent:
            eb.parent = arm.edit_bones[parent]
    bpy.ops.object.mode_set(mode="OBJECT")
    arm.display_type = "STICK"
    for pb in rig.pose.bones:
        pb.rotation_mode = "QUATERNION"
    return rig


def skin(obj, rig, bone):
    obj.parent = rig
    obj.matrix_parent_inverse = Matrix.Identity(4)
    obj.vertex_groups.clear()
    g = obj.vertex_groups.new(name=bone)
    g.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
    for m in [m for m in obj.modifiers if m.type == "ARMATURE"]:
        obj.modifiers.remove(m)
    mod = obj.modifiers.new("rig", "ARMATURE")
    mod.object = rig


# --- posing --------------------------------------------------------------------------------------

def _set(pb, q_arm=Quaternion(), loc_arm=Vector()):
    """Poses a bone by a rotation and a move in armature space, about the bone's head."""
    r = pb.bone.matrix_local.to_quaternion()
    pb.rotation_quaternion = r.inverted() @ q_arm @ r
    pb.location = r.inverted() @ Vector(loc_arm)


def _lean_about(pb, deg, pivot):
    """Turns a bone with its head at the origin about X by deg, keeping pivot fixed."""
    q = Quaternion(X, math.radians(deg))
    _set(pb, q, pivot - q @ pivot)


def rest(rig):
    for pb in rig.pose.bones:
        pb.rotation_quaternion = Quaternion()
        pb.location = Vector()


def pose_mood(rig, mood):
    m = MOODS[mood]
    lean = m["lean"]
    _lean_about(rig.pose.bones["lean"], lean, FRONT_FEET if lean >= 0 else BACK_FEET)
    for name in ("brow_left", "brow_right"):
        tilt, raise_ = m[name]
        sign = 1.0 if name == "brow_left" else -1.0  # + about Y lowers the +X end: the left brow's inner end
        _set(rig.pose.bones[BONE[name]], Quaternion(Y, math.radians(tilt * sign)), Z * raise_)


def pose_mouth(rig, v):
    """Opens the door-mouth by v in 0-1."""
    # About the upright hinge, the free (right) edge swinging out towards the front (-Y).
    _set(rig.pose.bones[BONE["door"]], Quaternion(Z, math.radians(-DOOR_OPEN_DEG * v)))


def _turn(rig, name, deg, lift=0.0):
    """Turns the drum or the laundry about the drum's axis by deg (+ is anticlockwise as players
    face it), the laundry lifted by `lift` metres."""
    _set(rig.pose.bones[BONE[name]], Quaternion(Y, math.radians(-deg)), Z * lift)


def pose_drum(rig, t, turns=0.0, rock=0.0, tumble=0.0):
    """The drum and laundry at t in 0-1 over a loop: the drum turns `turns` whole turns plus a
    `rock` of degrees back and forth; the laundry rides up the rising side and drops (`tumble`
    degrees), lagging the drum, with a small hop as it lands. Whole cycles, so it loops."""
    w = 2 * math.pi * t
    _turn(rig, "drum", 360.0 * turns * t + rock * math.sin(w))
    swing = tumble * (math.sin(w - 0.7) + 0.25 * math.sin(2 * w - 1.4))
    _turn(rig, "laundry", 360.0 * turns * t + swing, 0.008 * max(0.0, math.sin(2 * w - 1.0)))


def pose_talk(rig, t):
    """t in 0-1 over the loop: two bounces and one rock forward and back. The drum stays still: the
    machine is broken until the wash (Q1411)."""
    pb = rig.pose.bones["bob"]
    up = 0.014 * abs(math.sin(2 * math.pi * t))
    q = Quaternion(X, math.radians(2.2 * math.sin(2 * math.pi * t))) @ Quaternion(Y, math.radians(1.2 * math.sin(4 * math.pi * t)))
    _set(pb, q, Z * up)


def pose_rumble(rig, t):
    """t in 0-1 over the loop: a fast jitter, sums of whole cycles so it loops."""
    pb = rig.pose.bones["bob"]
    s = lambda k, ph: math.sin(2 * math.pi * k * t + ph)
    loc = Vector((0.003 * s(3, 0.0) + 0.0015 * s(5, 1.1), 0.002 * s(4, 0.5), 0.002 * (1 + s(4, 2.0)) + 0.001 * (1 + s(6, 0.3))))
    q = Quaternion(Y, math.radians(0.9 * s(2, 0.7) + 0.4 * s(5, 0.2))) @ Quaternion(X, math.radians(0.5 * s(3, 1.4)))
    _set(pb, q, loc)


def pose_spin(rig, t):
    """The game's real wash (Q1411): one full turn per loop (1 s at 30 fps), the laundry tumbling."""
    pose_drum(rig, t, turns=1.0, tumble=40.0)


DRUM_BONES = [BONE["drum"], BONE["laundry"]]
LOOPS = {"talk": (24, pose_talk, ["bob"]), "rumble": (12, pose_rumble, ["bob"]),
         "spin": (30, pose_spin, DRUM_BONES)}


def _write_action(rig, name, frames, bones):
    """frames: a list of {bone: (quaternion, location)} samples, one per frame from 0."""
    old = bpy.data.actions.get(name)
    if old is not None:
        bpy.data.actions.remove(old)
    act = bpy.data.actions.new(name)
    act.use_fake_user = True
    slot = act.slots.new(id_type="OBJECT", name=RIG)
    bag = act.layers.new("motion").strips.new(type="KEYFRAME").channelbag(slot, ensure=True)
    for b in bones:
        for prop, n in (("rotation_quaternion", 4), ("location", 3)):
            for i in range(n):
                fc = bag.fcurves.new('pose.bones["%s"].%s' % (b, prop), index=i, group_name=b)
                vals = [(f[b][0] if prop == "rotation_quaternion" else f[b][1])[i] for f in frames]
                fc.keyframe_points.add(len(vals))
                co = []
                for k, v in enumerate(vals):
                    co += [float(k), float(v)]
                fc.keyframe_points.foreach_set("co", co)
                fc.keyframe_points.foreach_set("interpolation", [1] * len(vals))
                fc.update()
    act.frame_range = (0, len(frames) - 1)
    act.use_frame_range = True
    return act


def _sample(rig, bones):
    out = {}
    for b in bones:
        pb = rig.pose.bones[b]
        out[b] = (pb.rotation_quaternion.copy(), pb.location.copy())
    return out


def make_actions(rig):
    bpy.context.scene.render.fps, bpy.context.scene.render.fps_base = FPS, 1.0
    ad = rig.animation_data or rig.animation_data_create()
    ad.action = None
    made = []
    mood_bones = ["lean", BONE["brow_left"], BONE["brow_right"]]
    for mood in MOODS:
        rest(rig)
        pose_mood(rig, mood)
        s = _sample(rig, mood_bones)
        _write_action(rig, mood, [s, s], mood_bones)
        made.append(mood)
    for name, (n, fn, bones) in LOOPS.items():
        frames = []
        for f in range(n + 1):
            rest(rig)
            fn(rig, f / n)
            frames.append(_sample(rig, bones))
        _write_action(rig, name, frames, bones)
        made.append(name)
    frames = []
    for f in range(MOUTH_FRAMES + 1):
        rest(rig)
        pose_mouth(rig, f / MOUTH_FRAMES)
        frames.append(_sample(rig, [BONE["door"]]))
    _write_action(rig, "mouth", frames, [BONE["door"]])
    made.append("mouth")
    rest(rig)
    return made


def build():
    """Applies the face to the open washing_machine.blend. Returns a one-line report."""
    if bpy.context.object and bpy.context.object.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    root = bpy.data.objects[ROOT]
    body, door = bpy.data.objects["body"], bpy.data.objects["door"]
    glow = _material("drum_glow", (0.0, 0.0, 0.0), 1.0, *MOOD_GLOW["neutral"])
    brow = _material("brow", (0.022, 0.018, 0.018), 0.55)
    # The power light wore the eye's iris material: it glows with the drum now.
    iris = bpy.data.materials.get("iris")
    for o in (body,):
        for s in o.material_slots:
            if s.material == iris:
                s.material = glow
    gone = remove_eye()
    for n in ("iris", "eye_white"):
        m = bpy.data.materials.get(n)
        if m is not None and m.users == 0:
            bpy.data.materials.remove(m)
    prepare_door(door)
    glass = bpy.data.materials["porthole_glass"]  # clearer (Q1401)
    next(n for n in glass.node_tree.nodes if n.type == "BSDF_PRINCIPLED").inputs["Alpha"].default_value = GLASS_ALPHA
    brows = make_brows(root, brow)
    paddles = remove_old_drum(body)
    old_glow = bpy.data.objects.get("drum_glow")  # the lining before the lit drum
    if old_glow is not None:
        old_me = old_glow.data
        bpy.data.objects.remove(old_glow)
        if old_me.users == 0:
            bpy.data.meshes.remove(old_me)
    light_me = _power_light(body, glow)
    drum, lining_me = make_drum(root, bpy.data.materials["rubber"], glow)
    laundry, pile_at = make_laundry(root, brow)
    rig = make_rig(root)
    make_lining(rig, lining_me, light_me, glow)
    for o in (body, bpy.data.objects["dial"], bpy.data.objects["detergent_drawer"]):
        _bake_transform(o)
        skin(o, rig, "bob")
    skin(door, rig, BONE["door"])
    skin(drum, rig, BONE["drum"])
    hang(laundry, rig, BONE["laundry"], pile_at)
    for name, o in brows.items():
        skin(o, rig, BONE[name])
    for s in [s for s in body.material_slots if s.material == glow]:
        s.material = None  # the power light is in Lining now
    while body.data.materials and body.data.materials[-1] is None:
        body.data.materials.pop()
    gone = list(gone) + (["old drum and paddles (%d faces)" % paddles] if paddles else [])
    made = make_actions(rig)
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    tris = 0
    for o in root.children_recursive:
        if o.type == "MESH" and "colonly" not in o.name:
            tris += sum(len(p.vertices) - 2 for p in o.evaluated_get(dg).data.polygons)
    return "WASHER-FACE built: removed %s; %d render triangles; actions %s" % (gone or "nothing", tris, made)


def export(path):
    """Writes the glb: `face_rig` and everything on it, and the collider, with the eight actions; no
    root object, so face_rig is a top node (the Looks contract). Each action keys only its own bones."""
    import os
    if bpy.context.object and bpy.context.object.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    rig = bpy.data.objects[RIG]
    rest(rig)
    if rig.animation_data:
        rig.animation_data.action = None
    keep = [rig] + list(rig.children_recursive) + [bpy.data.objects[COLLIDER]]
    for o in bpy.context.view_layer.objects:
        o.select_set(o in keep)
        if o in keep:
            o.hide_viewport = False
            o.hide_set(False)
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=path, export_format="GLB", use_selection=True, export_apply=True, export_yup=True,
        export_cameras=False, export_lights=False, export_extras=False, export_animations=True,
        export_animation_mode="ACTIONS", export_force_sampling=False, export_def_bones=False,
        export_skins=True)
    return "EXPORT-OK washing_machine -> %s" % path
