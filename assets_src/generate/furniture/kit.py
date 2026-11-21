"""Shared helpers for the house art style trial (house/02): palette, mesh helpers, the stage.

Blender axes (z up). Every piece stands on z = 0, centred on x = 0, its front facing -y.
"""

import math

import bmesh
import bpy
from mathutils import Vector


def srgb(r, g, b, a=1.0):
    f = lambda c: c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return (f(r), f(g), f(b), a)


# The flat's palette (tools/blender/make_flat.py MATERIALS), so all three styles share hues.
PALETTE = {
    "sofa": (0.38, 0.56, 0.55),        # teal velvet
    "sofa_dark": (0.30, 0.46, 0.46),
    "cushion_a": (0.95, 0.70, 0.35),   # mustard
    "cushion_b": (0.92, 0.60, 0.55),   # dusty pink
    "oak": (0.80, 0.57, 0.34),
    "dark_wood": (0.47, 0.29, 0.16),
    "linen": (0.97, 0.94, 0.88),
    "duvet": (0.93, 0.73, 0.44),
    "pad": (0.93, 0.84, 0.66),
    "rug_blue": (0.45, 0.58, 0.72),
    "stripe": (0.98, 0.92, 0.82),      # the sock creature's cuff trim
    "leaf": (0.36, 0.60, 0.36),
    "leaf_light": (0.52, 0.72, 0.42),
    "leaf_dark": (0.22, 0.42, 0.26),
    "stem": (0.40, 0.48, 0.26),
    "terracotta": (0.80, 0.45, 0.30),
    "soil": (0.30, 0.21, 0.15),
    "floor": (0.66, 0.45, 0.28),       # the flat's "wood" floor
    "wall": (0.96, 0.89, 0.77),        # wall_living
    "skirting": (0.98, 0.96, 0.91),    # trim
}

# The flat's light colours: the noon sun (game/house/day_cycle.gd), the lamps (game/house/room.gd
# LAMP_COLOUR) and the sky tint of the flat's final previews (make_flat.py).
SUN_COLOUR = (1.0, 0.93, 0.82)
LAMP_COLOUR = (1.0, 0.88, 0.7)
SKY_COLOUR = srgb(0.80, 0.88, 0.96)


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    _MATS.clear()


_MATS = {}


def mat(name, colour=None, rough=0.85, metal=0.0, sheen=0.0, setup=None):
    """A Principled material, cached by name. colour: sRGB triple (or a PALETTE key = name).
    setup(material, nodes, links, bsdf) may add texture nodes (the realistic style)."""
    if name in _MATS:
        return _MATS[name]
    c = srgb(*(colour if colour is not None else PALETTE[name]))
    m = bpy.data.materials.new(name)
    nodes = m.node_tree.nodes
    bsdf = nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = c
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    if sheen:
        bsdf.inputs["Sheen Weight"].default_value = sheen
    m.diffuse_color = c
    if setup:
        setup(m, nodes, m.node_tree.links, bsdf)
    _MATS[name] = m
    return m


def obj_from_bm(name, bm, material, smooth=True):
    me = bpy.data.meshes.new(name)
    bm.normal_update()
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = smooth
    if isinstance(material, (list, tuple)):
        for m in material:
            me.materials.append(m)
    else:
        me.materials.append(material)
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    return ob


def bevel(ob, width, segments=3, harden=True, angle=None):
    md = ob.modifiers.new("Bevel", "BEVEL")
    md.width = width
    md.segments = segments
    md.limit_method = "ANGLE" if angle else "NONE"
    if angle:
        md.angle_limit = math.radians(angle)
    md.harden_normals = harden
    md.profile = 0.5
    return md


def subsurf(ob, levels=1):
    md = ob.modifiers.new("Subsurf", "SUBSURF")
    md.levels = md.render_levels = levels
    return md


def cube_bm(size, loc, cuts=0):
    """A box of size (w, d, h) whose bottom centre sits at loc."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    if cuts:
        bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=cuts, use_grid_fill=True)
    w, d, h = size
    for v in bm.verts:
        v.co = Vector((loc[0] + v.co.x * w, loc[1] + v.co.y * d, loc[2] + (v.co.z + 0.5) * h))
    return bm


def rbox(name, size, loc, material, r=0.02, seg=3, harden=True):
    """A bevelled box (bottom centre at loc)."""
    ob = obj_from_bm(name, cube_bm(size, loc), material, smooth=r > 0)
    if r > 0:
        bevel(ob, r, seg, harden)
    return ob


def puff_bm(size, loc, puff=(0.08, 0.08, 0.25), cuts=4, pinch=0.0):
    """A cushion: a subdivided box whose faces bulge out in the middle (puff is the bulge per
    axis, as a fraction of the half size). pinch pulls the edge rims in (a stitched seam look)."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=2.0)
    bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=cuts, use_grid_fill=True)
    w, d, h = size
    px, py, pz = puff
    for v in bm.verts:
        u, s, t = v.co
        x = u * (1 + px * (1 - s * s) * (1 - t * t))
        y = s * (1 + py * (1 - u * u) * (1 - t * t))
        z = t * (1 + pz * (1 - u * u) * (1 - s * s))
        if pinch:
            edge = max(0.0, (u * u) * (s * s))   # corners tuck in a little
            x *= 1 - pinch * edge * 0.5
            y *= 1 - pinch * edge * 0.5
        v.co = Vector((loc[0] + x * w / 2, loc[1] + y * d / 2, loc[2] + (z + 1) * h / 2))
    return bm


def cushion(name, size, loc, material, puff=(0.08, 0.08, 0.25), levels=1, cuts=4, pinch=0.0):
    ob = obj_from_bm(name, puff_bm(size, loc, puff, cuts, pinch), material)
    if levels:
        subsurf(ob, levels)
    return ob


def tube_bm(points, radii, n=8, caps=True):
    """A tube along a polyline of points, radius per point (frames by parallel transport)."""
    bm = bmesh.new()
    pts = [Vector(p) for p in points]
    rings = []
    prev_side = None
    for i, p in enumerate(pts):
        t = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
        if prev_side is None:
            ref = Vector((0, 0, 1)) if abs(t.z) < 0.9 else Vector((1, 0, 0))
            side = t.cross(ref).normalized()
        else:
            side = (prev_side - t * prev_side.dot(t)).normalized()
        prev_side = side
        up = t.cross(side).normalized()
        ring = []
        for k in range(n):
            a = 2 * math.pi * k / n
            ring.append(bm.verts.new(p + (side * math.cos(a) + up * math.sin(a)) * radii[i]))
        rings.append(ring)
    for i in range(len(rings) - 1):
        for k in range(n):
            j = (k + 1) % n
            bm.faces.new((rings[i][k], rings[i][j], rings[i + 1][j], rings[i + 1][k]))
    if caps:
        bm.faces.new(list(reversed(rings[0])))
        bm.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bm


def lathe_bm(profile, n=24, loc=(0, 0, 0)):
    """Revolve a profile [(radius, z)] about the z axis (closed at r = 0 ends)."""
    bm = bmesh.new()
    rings = []
    for r, z in profile:
        if r <= 1e-6:
            rings.append([bm.verts.new((loc[0], loc[1], loc[2] + z))])
        else:
            rings.append([bm.verts.new((loc[0] + r * math.cos(2 * math.pi * k / n),
                                        loc[1] + r * math.sin(2 * math.pi * k / n), loc[2] + z))
                          for k in range(n)])
    for a, b in zip(rings, rings[1:]):
        if len(a) == 1 and len(b) == 1:
            continue
        for k in range(n):
            j = (k + 1) % n
            if len(a) == 1:
                bm.faces.new((a[0], b[k], b[j]))
            elif len(b) == 1:
                bm.faces.new((a[k], a[j], b[0]))
            else:
                bm.faces.new((a[k], a[j], b[j], b[k]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bm


def leaf_bm(length, width, shape, nl=8, nw=3, fold=0.3, curl=0.0, droop=0.0, wave=0.0, tip=1.0):
    """A leaf blade along +y from the origin, lying in the xy plane (normal +z).
    shape(t) -> half width factor 0..1 at t = 0..1 along the blade. fold lifts the edges
    (a V along the midrib), curl bends the blade down along its length, wave ripples the rim."""
    bm = bmesh.new()
    rows = []
    for i in range(nl + 1):
        t = i / nl
        hw = width / 2 * shape(t)
        row = []
        for j in range(-nw, nw + 1):
            s = j / nw
            x = s * hw
            y = t * length
            z = fold * abs(s) * hw + wave * math.sin(t * 9.0) * abs(s) * hw
            # Curl: bend the blade down over its length.
            ang = curl * t
            yy = y * (math.sin(ang) / ang if abs(ang) > 1e-6 else 1.0)
            zz = z - (y * (1 - math.cos(ang)) / ang if abs(ang) > 1e-6 else 0.0) - droop * t * t
            row.append(bm.verts.new((x, yy, zz)))
        rows.append(row)
    for a, b in zip(rows, rows[1:]):
        for j in range(len(a) - 1):
            bm.faces.new((a[j], a[j + 1], b[j + 1], b[j]))
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    return bm


def transform_bm(bm, loc=(0, 0, 0), yaw=0.0, pitch=0.0, roll=0.0, scale=1.0):
    from mathutils import Euler, Matrix
    m = (Matrix.Translation(loc) @ Euler((pitch, roll, yaw), "ZXY").to_matrix().to_4x4()
         @ Matrix.Scale(scale, 4))
    bmesh.ops.transform(bm, matrix=m, verts=bm.verts)
    return bm


def join(name, objs):
    """Join objects (modifiers applied) into one mesh object."""
    for o in objs:
        bpy.context.view_layer.objects.active = o
        for md in list(o.modifiers):
            bpy.ops.object.modifier_apply(modifier=md.name)
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    objs[0].name = name
    return objs[0]


def tri_count(objs):
    """Triangles of the evaluated meshes (modifiers included)."""
    dg = bpy.context.evaluated_depsgraph_get()
    n = 0
    for o in objs:
        if o.type != "MESH":
            continue
        me = o.evaluated_get(dg).to_mesh()
        me.calc_loop_triangles()
        n += len(me.loop_triangles)
        o.evaluated_get(dg).to_mesh_clear()
    return n


def bounds(objs):
    lo = Vector((1e9, 1e9, 1e9))
    hi = -lo
    dg = bpy.context.evaluated_depsgraph_get()
    for o in objs:
        if o.type != "MESH":
            continue
        for c in o.evaluated_get(dg).bound_box:
            w = o.matrix_world @ Vector(c)
            lo = Vector(map(min, lo, w))
            hi = Vector(map(max, hi, w))
    return lo, hi


def parent_to(objs, name):
    """Group a piece under an empty so it moves as one."""
    e = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(e)
    for o in objs:
        if o.parent is None:
            o.parent = e
    return e


# --- The stage ----------------------------------------------------------------------

def stage(width, depth_back, final):
    """A floor and a back wall in the flat's colours, the flat's light colours, AgX like the game."""
    scene = bpy.context.scene
    scene.render.threads_mode = "FIXED"
    scene.render.threads = 4
    floor_m = mat("floor", rough=0.6)
    wall_m = mat("wall", rough=0.9)
    skirt_m = mat("skirting", rough=0.55)
    rbox("Floor", (width, 40.0, 0.1), (0, depth_back - 20.0, -0.1), floor_m, r=0)
    rbox("Wall", (width, 0.1, 5.0), (0, depth_back + 0.05, 0), wall_m, r=0)
    rbox("Skirting", (width, 0.02, 0.1), (0, depth_back - 0.01, 0), skirt_m, r=0.005, seg=1)
    world = bpy.data.worlds.new("W")
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs[0].default_value = SKY_COLOUR
    bg.inputs[1].default_value = 0.45
    scene.world = world
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.exposure = -0.45
    scene.view_settings.look = "AgX - Medium High Contrast"   # near the game's light grade
    if final:
        sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
        sun.data.energy, sun.data.color = 3.5, SUN_COLOUR
        sun.data.angle = math.radians(6)
        sun.rotation_euler = (math.radians(55), 0, math.radians(-40))
        scene.collection.objects.link(sun)
        lamp = bpy.data.objects.new("Lamp", bpy.data.lights.new("Lamp", "AREA"))
        lamp.data.energy, lamp.data.color = 150.0, LAMP_COLOUR
        lamp.data.size = 3.0
        lamp.location = (0, -2.0, 3.2)
        lamp.rotation_euler = (math.radians(25), 0, 0)
        scene.collection.objects.link(lamp)
        scene.render.engine = "BLENDER_EEVEE"
        ee = scene.eevee
        ee.taa_render_samples = 32
        for attr, val in (("use_shadows", True), ("use_raytracing", True)):
            if hasattr(ee, attr):
                setattr(ee, attr, val)
    else:
        scene.render.engine = "BLENDER_WORKBENCH"
        sh = scene.display.shading
        sh.light = "STUDIO"
        sh.color_type = "MATERIAL"
        sh.show_shadows = False
        sh.show_cavity = True
        scene.view_settings.view_transform = "Standard"


def camera(pos, target, lens=50):
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
    bpy.context.scene.collection.objects.link(cam)
    cam.location = pos
    cam.rotation_euler = (Vector(target) - Vector(pos)).to_track_quat("-Z", "Y").to_euler()
    cam.data.lens = lens
    cam.data.clip_end = 100
    bpy.context.scene.camera = cam
    return cam


def render(path, res):
    scene = bpy.context.scene
    scene.render.resolution_x, scene.render.resolution_y = res
    scene.render.resolution_percentage = 100
    scene.render.filepath = path
    scene.render.image_settings.file_format = "PNG"
    bpy.ops.render.render(write_still=True)
