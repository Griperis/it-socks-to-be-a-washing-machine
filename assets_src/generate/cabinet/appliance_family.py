"""The retro appliance family's shared look (pipeline/10, Q908-Q910): the Sock pairing machine and
the Sock vacuum (pipeline/11) are one product family with the same body colour, trim, button style
and maker badge. A builder imports this module, builds its parts with `Part` and the helpers here,
and gets the family's materials, chrome trim beads, chunky round buttons and badge for free.

Ported unchanged from the old game's tools/blender/appliance_family.py (assets/08) because
make_cabinets.py builds on it; the pairing machine and the vacuum are not ported yet. In the old game
the numbers are written up in docs/art/pairing_machine/pairing_machine.md, "Family look".

Coordinates are the old asset contract's: metres, Blender Z up, the front
facing -Y, the origin at the bottom centre. `front(x, y, z)` gives the frame of a part that faces
the front: its local +Z points out of the front (-Y), local +X is world +X and local +Y is up.
"""

import math

import bpy
import bmesh
from mathutils import Matrix, Vector

# --- Colours (sRGB hex, the designer-facing values) and materials ---------------------------

COLOURS = {
    "mint": "#A8DCC5",    # the body: pastel mint (Q910)
    "cream": "#F4EAD3",   # details: top cap, fascia, the inside, the badge's mark (Q910)
    "chrome": "#DCE1E4",  # trim, bezels, feet, nozzles (Q908, Q910); metallic
    "red": "#D9463E",     # button caps and the badge's enamel
    "dark": "#26302D",    # lamps and lights when off, mouths and throats
    "glass": "#D6F0F2",   # windows, alpha GLASS_ALPHA
}
GLASS_ALPHA = 0.2
# Principled settings per material: (metallic, roughness).
FINISH = {"mint": (0.0, 0.42), "cream": (0.0, 0.5), "chrome": (1.0, 0.16), "red": (0.0, 0.32),
          "dark": (0.0, 0.35), "glass": (0.0, 0.05)}
ORDER = ["mint", "cream", "chrome", "red", "dark", "glass"]

# --- Family dimensions (m) -------------------------------------------------------------------

TRIM_R = 0.007          # the chrome bead's tube radius (belt lines, bezels round windows)
BUTTON_R = 0.03         # a round button's cap radius
BUTTON_OUT = 0.025      # how far the cap stands out of its bezel
BUTTON_EDGE = 0.009     # the cap's rounded front edge
BUTTON_BEZEL_R = 0.037  # the chrome bezel ring's radius round the cap (tube 0.007)
BADGE_W, BADGE_H = 0.078, 0.05  # the maker badge's oval (outside the chrome rim)
FOOT_R, FOOT_H = 0.02, 0.03     # a chrome bullet foot


def srgb(hexstr, alpha=1.0):
    """A '#rrggbb' sRGB colour as linear RGBA (what Principled's Base Color wants)."""
    h = hexstr.lstrip("#")
    out = []
    for i in (0, 2, 4):
        c = int(h[i:i + 2], 16) / 255.0
        out.append(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)
    return (*out, alpha)


def material(name):
    """The family material `name` (one of ORDER), made once per file."""
    m = bpy.data.materials.get(name)
    if m is None:
        m = bpy.data.materials.new(name)
    alpha = GLASS_ALPHA if name == "glass" else 1.0
    col = srgb(COLOURS[name], alpha)
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Base Color"].default_value = col
    b.inputs["Metallic"].default_value, b.inputs["Roughness"].default_value = FINISH[name]
    b.inputs["Alpha"].default_value = alpha
    m.diffuse_color = col  # Workbench previews
    m.metallic, m.roughness = FINISH[name]
    if name == "glass":
        m.surface_render_method = "BLENDED"
    return m


# --- Frames and outlines ---------------------------------------------------------------------

def front(x, y, z):
    """A part's frame facing the front: local +Z out of the front (-Y), local +Y up."""
    return Matrix.Translation((x, y, z)) @ Matrix.Rotation(math.pi / 2, 4, "X")


def rounded_rect(w, d, r, seg=8):
    """A rounded rectangle's outline in the XY plane, counter-clockwise, centred."""
    r = max(min(r, w / 2, d / 2), 0.0005)
    cx, cy = w / 2 - r, d / 2 - r
    pts = []
    for sx, sy, a0 in ((1, -1, -90), (1, 1, 0), (-1, 1, 90), (-1, -1, 180)):
        for k in range(seg + 1):
            a = math.radians(a0 + 90 * k / seg)
            pts.append(Vector((sx * cx + r * math.cos(a), sy * cy + r * math.sin(a), 0)))
    return pts


def stadium(w, h, seg=10):
    """A capsule (pill) outline, w wide and h tall, in the XY plane."""
    return rounded_rect(w, h, min(w, h) / 2, seg)


def ellipse(w, h, n=32):
    return [Vector((w / 2 * math.cos(2 * math.pi * k / n), h / 2 * math.sin(2 * math.pi * k / n), 0))
            for k in range(n)]


def circle(r, n=24):
    return ellipse(2 * r, 2 * r, n)


# --- Part: one mesh object built from several pieces, each in a family material --------------

class Part:
    """Accumulates pieces into one bmesh; `finish` makes the object (smooth, sharp by angle).
    Pieces name their material from `order` (the family's ORDER by default); `make(name)` makes it
    (the family's `material`). Another prop (the radio, pipeline/06) passes its own palette."""

    def __init__(self, order=None, make=None):
        self.bm = bmesh.new()
        self.order = order or ORDER
        self.make = make or material

    def _strip(self, rings, mat, wrap_rings=True, close_path=False, cap_start=None, cap_end=None):
        """Quads between consecutive rings (loops of equal length). cap_* = a material for an ngon."""
        mi = self.order.index(mat)
        verts = [[self.bm.verts.new(p) for p in ring] for ring in rings]
        n = len(rings[0])
        pairs = list(zip(verts, verts[1:])) + ([(verts[-1], verts[0])] if close_path else [])
        for a, b in pairs:
            for i in range(n if wrap_rings else n - 1):
                j = (i + 1) % n
                f = self.bm.faces.new((a[i], a[j], b[j], b[i]))
                f.material_index = mi
        for vs, cmat, rev in ((verts[0], cap_start, True), (verts[-1], cap_end, False)):
            if cmat is not None and not close_path:
                f = self.bm.faces.new(list(reversed(vs)) if rev else vs)
                f.material_index = self.order.index(cmat)
        return verts

    def rounded_box(self, w, d, z0, z1, r_plan, r_bot, r_top, mat, matrix=None, seg=8, seg_round=4,
                    cap_mat=None):
        """A box rounded in plan (r_plan) with rounded bottom and top edges, z0..z1 (in `matrix`)."""
        prof = []
        if r_bot > 0:
            for k in range(seg_round + 1):
                a = math.pi / 2 * k / seg_round
                prof.append((z0 + r_bot * (1 - math.cos(a)), r_bot * (1 - math.sin(a))))
        else:
            prof.append((z0, 0.0))
        if r_top > 0:
            for k in range(seg_round + 1):
                a = math.pi / 2 * k / seg_round
                prof.append((z1 - r_top * (1 - math.sin(a)), r_top * (1 - math.cos(a))))
        else:
            prof.append((z1, 0.0))
        m = matrix or Matrix()
        rings = []
        for z, i in prof:
            ring = rounded_rect(w - 2 * i, d - 2 * i, r_plan - i, seg)
            rings.append([m @ Vector((p.x, p.y, z)) for p in ring])
        return self._strip(rings, mat, cap_start=cap_mat or mat, cap_end=cap_mat or mat)

    def lathe(self, profile, mat, matrix=None, n=32, cap_start=None, cap_end=None):
        """Turns a (radius, height) profile round local Z."""
        m = matrix or Matrix()
        rings = [[m @ Vector((r * math.cos(2 * math.pi * k / n), r * math.sin(2 * math.pi * k / n), h))
                  for k in range(n)] for r, h in profile]
        return self._strip(rings, mat, cap_start=cap_start, cap_end=cap_end)

    def sweep(self, path, radius, mat, normal=(0, 0, 1), matrix=None, n=10, closed=True,
              squash=1.0):
        """A round tube along `path` (points in a plane with `normal`): chrome beads, rims, handles.
        squash < 1 flattens the tube along `normal`."""
        m = matrix or Matrix()
        nv = Vector(normal).normalized()
        cnt = len(path)
        rings = []
        for i, p in enumerate(path):
            a = path[(i - 1) % cnt] if closed or i > 0 else p
            b = path[(i + 1) % cnt] if closed or i < cnt - 1 else p
            t = (b - a).normalized()
            side = t.cross(nv).normalized()
            rings.append([m @ (p + radius * (math.cos(2 * math.pi * k / n) * side
                                             + squash * math.sin(2 * math.pi * k / n) * nv))
                          for k in range(n)])
        return self._strip(rings, mat, close_path=closed,
                           cap_start=None if closed else mat, cap_end=None if closed else mat)

    def slab(self, outline, z0, z1, mat, matrix=None):
        """A flat prism of an outline (counter-clockwise), z0..z1 in `matrix`."""
        m = matrix or Matrix()
        rings = [[m @ Vector((p.x, p.y, z)) for p in outline] for z in (z0, z1)]
        return self._strip(rings, mat, cap_start=mat, cap_end=mat)

    def add_mesh(self, me):
        """Appends a mesh whose material slots are family materials."""
        names = [s.name if s else self.order[0] for s in me.materials]
        base = len(self.bm.faces)
        self.bm.from_mesh(me)
        self.bm.faces.ensure_lookup_table()
        for f in self.bm.faces[base:]:
            f.material_index = self.order.index(names[f.material_index] if f.material_index < len(names)
                                                else self.order[0])

    def finish(self, name, parent=None, location=(0, 0, 0), sharp_deg=40.0):
        """The object `name` (vertices given in the asset's space, origin moved to `location`)."""
        bmesh.ops.remove_doubles(self.bm, verts=self.bm.verts, dist=1e-6)
        bmesh.ops.recalc_face_normals(self.bm, faces=self.bm.faces)
        loc = Vector(location)
        for v in self.bm.verts:
            v.co -= loc
        used = sorted({f.material_index for f in self.bm.faces})
        for f in self.bm.faces:
            f.material_index = used.index(f.material_index)
        me = bpy.data.meshes.new(name)
        self.bm.to_mesh(me)
        self.bm.free()
        for i in used:
            me.materials.append(self.make(self.order[i]))
        for p in me.polygons:
            p.use_smooth = True
        me.set_sharp_from_angle(angle=math.radians(sharp_deg))
        ob = bpy.data.objects.new(name, me)
        bpy.context.scene.collection.objects.link(ob)
        ob.location = loc
        if parent is not None:
            ob.parent = parent
        return ob


# --- The family's parts ----------------------------------------------------------------------

def trim_bead(part, outline, matrix=None):
    """The chrome bead round an outline (a belt line or a bezel), TRIM_R thick."""
    return part.sweep(outline, TRIM_R, "chrome", matrix=matrix, n=8)


def button_bezel(part, matrix):
    """The chrome ring a round button sits in (in a front() frame at the button's middle)."""
    part.sweep(circle(BUTTON_BEZEL_R, 24), TRIM_R, "chrome", matrix=matrix, n=8, squash=0.7)


def button_cap(part, matrix, cap_mat="red"):
    """A chunky round button's cap in a front() frame: base at z = 0, front at BUTTON_OUT (+Z).
    Build it in its own Part and finish it with its location at the frame's origin (the moving
    node: the game pushes it in along -Z)."""
    r, e, h = BUTTON_R, BUTTON_EDGE, BUTTON_OUT
    prof = [(r - 0.002, -0.004), (r, 0.0)]
    for k in range(1, 6):
        a = math.pi / 2 * k / 5
        prof.append((r - e + e * math.cos(a), h - e + e * math.sin(a)))
    prof.append((r * 0.55, h + 0.002))  # a slightly domed face
    part.lathe(prof, cap_mat, matrix=matrix, n=24, cap_start=cap_mat, cap_end=cap_mat)


def badge(part, matrix):
    """The maker badge (in a front() frame at its middle): a chrome oval rim round red enamel, and
    the family's mark on it in cream, two interlocking rings (a pair)."""
    part.sweep(ellipse(BADGE_W - 0.008, BADGE_H - 0.008, 24), 0.004, "chrome", matrix=matrix, n=6)
    part.slab(ellipse(BADGE_W - 0.01, BADGE_H - 0.01, 24), -0.004, 0.003, "red", matrix=matrix)
    for dx in (-0.0075, 0.0075):
        part.sweep(circle(0.0105, 14), 0.0022, "cream",
                   matrix=matrix @ Matrix.Translation((dx, 0, 0.0035)), n=5)


def bullet_foot(part, x, y):
    """A chrome bullet foot standing on the floor at (x, y), FOOT_H tall."""
    r, h = FOOT_R, FOOT_H
    prof = [(0.004, 0.0), (r * 0.6, 0.002), (r * 0.9, 0.008), (r, h * 0.55), (r * 0.95, h)]
    part.lathe(prof, "chrome", matrix=Matrix.Translation((x, y, 0)), n=12, cap_start="chrome",
               cap_end="chrome")


def lamp(part, matrix, r=0.011):
    """A round indicator lamp's lens in a front() frame (base at z = 0, dome to +Z), dark when off."""
    prof = [(r, -0.003), (r, 0.0)] + [(r * math.cos(a), r * 0.7 * math.sin(a))
                                       for a in (math.radians(d) for d in (35, 65))]
    part.lathe(prof, "dark", matrix=matrix, n=12, cap_start="dark", cap_end="dark")


# --- Scene helpers -----------------------------------------------------------------------------

def wipe():
    """Removes every object, mesh and material from the open file (a full rebuild)."""
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)
    for me in list(bpy.data.meshes):
        bpy.data.meshes.remove(me)
    for m in list(bpy.data.materials):
        bpy.data.materials.remove(m)


def root(name):
    ob = bpy.data.objects.new(name, None)
    ob.empty_display_size = 0.2
    bpy.context.scene.collection.objects.link(ob)
    return ob


def collider_box(name, parent, size, z0=0.0):
    """A `<name>-convcolonly` box collider, size (x, y, z), standing on z0, shown as wire."""
    sx, sy, sz = size
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * sx, v.co.y * sy, v.co.z * sz + z0 + sz / 2))
    me = bpy.data.meshes.new(name + "-convcolonly")
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name + "-convcolonly", me)
    bpy.context.scene.collection.objects.link(ob)
    ob.parent = parent
    ob.display_type = "WIRE"
    return ob


def apply_booleans(ob, cutters):
    """Cuts `cutters` (objects) out of `ob` (exact, materials transferred) and deletes them."""
    for c in cutters:
        mod = ob.modifiers.new("cut_" + c.name, "BOOLEAN")
        mod.operation = "DIFFERENCE"
        mod.solver = "EXACT"
        mod.object = c
        mod.material_mode = "TRANSFER"
        c.hide_set(True)
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
    old = ob.data
    ob.modifiers.clear()
    ob.data = me
    bpy.data.meshes.remove(old)
    for c in cutters:
        m = c.data
        bpy.data.objects.remove(c, do_unlink=True)
        bpy.data.meshes.remove(m)
    return ob


# --- Preview line-up -------------------------------------------------------------------------

VIEWS = {"front": (0.0, -1.0, 0.18), "three_quarter": (0.75, -1.0, 0.45), "side": (1.0, 0.0, 0.15),
         "back": (-0.7, 1.0, 0.4), "top": (0.25, -0.5, 1.6)}


def lineup(path, views=("front", "three_quarter", "side", "back"), size=(360, 420), final=False):
    """Renders the visible meshes from `views` side by side into one PNG (Workbench, or EEVEE with
    `final`), colliders hidden. Restores the scene. Returns a one-line report."""
    import os
    import tempfile
    import numpy as np
    scene = bpy.context.scene
    r = scene.render
    keep = (r.engine, r.resolution_x, r.resolution_y, r.resolution_percentage, r.filepath,
            scene.camera, r.film_transparent, scene.world)
    meshes = [o for o in scene.objects if o.type == "MESH" and o.visible_get()
              and not o.name.endswith(("-colonly", "-convcolonly"))]
    hidden = [o for o in scene.objects if o.name.endswith(("-colonly", "-convcolonly")) and not o.hide_render]
    pts = [o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box]
    lo = Vector([min(p[i] for p in pts) for i in range(3)])
    hi = Vector([max(p[i] for p in pts) for i in range(3)])
    centre, radius = (lo + hi) / 2, (hi - lo).length / 2
    cam = bpy.data.objects.new("_lineup_cam", bpy.data.cameras.new("_lineup_cam"))
    scene.collection.objects.link(cam)
    cam.data.lens = 70
    made = []
    world = None
    try:
        for o in hidden:
            o.hide_render = True
        if final:
            try:
                r.engine = "BLENDER_EEVEE"
            except TypeError:
                r.engine = "BLENDER_EEVEE_NEXT"
            world = bpy.data.worlds.new("_lineup_world")
            world.color = (0.55, 0.56, 0.6)
            if world.node_tree is None:
                world.use_nodes = True
            bg = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
            # A sky-to-floor gradient, so chrome has something to reflect.
            tc = world.node_tree.nodes.new("ShaderNodeTexCoord")
            sep = world.node_tree.nodes.new("ShaderNodeSeparateXYZ")
            ramp = world.node_tree.nodes.new("ShaderNodeValToRGB")
            world.node_tree.links.new(tc.outputs["Generated"], sep.inputs[0])
            world.node_tree.links.new(sep.outputs[2], ramp.inputs[0])
            world.node_tree.links.new(ramp.outputs[0], bg.inputs[0])
            ramp.color_ramp.elements[0].position = 0.45
            ramp.color_ramp.elements[0].color = (0.12, 0.11, 0.1, 1)
            ramp.color_ramp.elements[1].position = 0.6
            ramp.color_ramp.elements[1].color = (0.9, 0.93, 1.0, 1)
            bg.inputs[1].default_value = 0.8
            scene.world = world
            for d, e in (((0.6, -0.8, 1.0), 3.5), ((-1.0, 0.3, 0.6), 1.2)):
                sun = bpy.data.objects.new("_lineup_sun", bpy.data.lights.new("_lineup_sun", "SUN"))
                sun.data.energy = e
                sun.rotation_euler = (-Vector(d)).to_track_quat("-Z", "Y").to_euler()
                scene.collection.objects.link(sun)
                made.append(sun)
        else:
            r.engine = "BLENDER_WORKBENCH"
            scene.display.shading.light = "STUDIO"
            scene.display.shading.color_type = "MATERIAL"
        r.resolution_x, r.resolution_y = size
        r.resolution_percentage = 100
        r.film_transparent = False
        scene.camera = cam
        tiles = []
        tmp = tempfile.mkdtemp()
        dist = radius / math.tan(cam.data.angle / 2) * 1.08
        for v in views:
            d = Vector(VIEWS[v]).normalized()
            cam.location = centre + d * dist
            cam.rotation_euler = (centre - cam.location).to_track_quat("-Z", "Y").to_euler()
            r.filepath = os.path.join(tmp, v + ".png")
            bpy.ops.render.render(write_still=True)
            img = bpy.data.images.load(r.filepath)
            tiles.append(np.array(img.pixels[:], dtype=np.float32).reshape(size[1], size[0], 4))
            bpy.data.images.remove(img)
        out = np.concatenate(tiles, axis=1)
        img = bpy.data.images.new("_lineup", out.shape[1], out.shape[0], alpha=True)
        img.pixels[:] = out.ravel()
        img.filepath_raw = path
        img.file_format = "PNG"
        img.save()
        bpy.data.images.remove(img)
    finally:
        for o in hidden:
            o.hide_render = False
        for o in made:
            light = o.data
            bpy.data.objects.remove(o, do_unlink=True)
            bpy.data.lights.remove(light)
        cd = cam.data
        bpy.data.objects.remove(cam, do_unlink=True)
        bpy.data.cameras.remove(cd)
        (r.engine, r.resolution_x, r.resolution_y, r.resolution_percentage, r.filepath,
         scene.camera, r.film_transparent, scene.world) = keep
        if world is not None:
            bpy.data.worlds.remove(world)
    return "LINEUP %s %dx%d %s" % (path, size[0] * len(views), size[1], "EEVEE" if final else "Workbench")
