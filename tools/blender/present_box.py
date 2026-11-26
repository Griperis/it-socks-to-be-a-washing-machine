"""The Stage present's box (assets/16), ported from the old game's code-built box, `make_box` in
game/campaign/gift_view.gd (reference/it-socks, tag v0.1.1; GV:126-192; Q1591, Q1611): a wrapped
gift 0.3 m across, its body 0.82 of that high, a ribbon cross 0.18 of it wide, a lid a little wider
(1.06) with the ribbon over it and a bow of two loops and a knot on top.

Run from the repository root (Blender is the kit's pinned one, kit/tools/blender.sh):

    ~/tools/blender/blender -b -P tools/blender/present_box.py -- [--save] [--no-export] [--out <dir>]
        [--lineup <dir> --icons <dir>]

It builds the box from scratch (build() is safe to re-run in an open file), writes
`assets/present/present_box.glb` (under `--out` when given) and with `--save` the source
`assets_src/blender/present/present_box.blend`. `--lineup <dir>` renders the review line-up's tiles
there instead (the old box beside this one, closed, lid off seen from above into the box, and the
bow close up, in two Collections' wrapping; the Collections' icons as PNGs `<collection>.png` in
`--icons`). Last line: `PASS present_box ...` or `FAIL ...`.

Blender metres, the bottom's middle on the origin. Under the root `present_box` (only its children
are exported, so in Godot they sit straight under the glb's root; core/137's Looks contract,
gifts.md "The box's Looks"):
  Box       the body (hollow, open at the top) and its ribbon cross; origin on the floor at the
            middle (the turn and bob pivot)
  Box/Lid   the lid (hollow, open underneath), its ribbon cross and the bow; origin at the lid's
            underside, on the body's top (0.246 m), so the `open` clip's lid flight and tumble turn
            about its own middle bottom

Materials: `gift_paper` on the outside paper (the body and the lid), `gift_ribbon` on the ribbon and
the bow, `gift_inside` (the paper's plain back, matte) on the rims and the inside walls, floor and
ceiling. `gift_paper` and `gift_ribbon` are placeholders the Looks overrides: the paper with
`gift_paper.gdshader` (core/137, which maps its pattern from the object-space position, so the model
needs no pattern UVs) and the ribbon with the Collection's bow colour (the present's
`SockCollection`, at run time). Their glb colours are the old plain ones (paper 0.98, 0.96, 0.9; the
old fallback ribbon 0.8, 0.3, 0.3; roughness 0.45).

What differs from the old: one model instead of eleven BoxMesh cubes; the ribbon crosses no longer
poke 5 mm below the floor (the origin is the lowest point). The designer's look changes (Q2690): the
edges rounded a little (BEVEL); the bow's two loops are ribbon loops (a flat band round an oval, at
the old loops' size and lean) instead of tilted cubes; the knot a flat wrapped band instead of a
cube; the body and the lid hollow (WALL thick), so an opened box shows its inside.
"""

import math
import os
import sys

import bpy
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, os.path.join(REPO, "assets_src", "generate", "cabinet"))
import appliance_family as fam  # noqa: E402

ASSET = "present_box"
GLB = os.path.join("assets", "present", "present_box.glb")
SOURCE = os.path.join("assets_src", "blender", "present", "present_box.blend")

S = 0.3              # the box across (the old Gifts.SIZE)
BODY_H = S * 0.82    # the body's height; the lid sits on it
LID_W = S * 1.06     # the lid, a little wider
LID_H = S * 0.2
R = S * 0.18         # the ribbon's width
RIB = 0.003          # how far the ribbon stands proud of the paper
BEVEL = 0.006        # the rounded outside edges
SEG = 2              # rounding segments
WALL = 0.006         # the body's and the lid's walls (both hollow, Q2690)
# The bow, as the old (in the lid's space): two loops 2R across and 1.4R high, 0.7R deep, their
# middles 0.9R either side and 0.6R over the lid (here 0.66R, so the lowest band stays out of the
# hollow lid), leaning 0.5 rad (their inner ends up).
LOOP_W, LOOP_H, LOOP_D = R * 2.0, R * 1.4, R * 0.7
LOOP_X, LOOP_Z, LOOP_LEAN = R * 0.9, LID_H + R * 0.66, 0.5
LOOP_T = 0.009       # the loop band's thickness
# The knot (Q2690: flat and wrapped, not a ball): a short band wrapped round the loops' roots, wider
# than it is high, a little deeper than the loops.
KNOT_W, KNOT_H, KNOT_D = R * 0.7, R * 0.5, LOOP_D * 1.15
KNOT_Z = LID_H + R * 0.68   # its underside

# `gift_inside` is the paper's plain back, on the rims and the inside walls and floors (the old box
# was solid, so it had no inside to copy; Q2690: lit as the paper's inside, no pattern).
COLOURS = {"gift_paper": "#FAF5E6", "gift_ribbon": "#CC4D4D", "gift_inside": "#F1ECE2"}
ROUGHNESS = {"gift_paper": 0.45, "gift_ribbon": 0.45, "gift_inside": 0.8}
ORDER = list(COLOURS)


def material(name):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    col = fam.srgb(COLOURS[name])
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Base Color"].default_value = col
    b.inputs["Metallic"].default_value, b.inputs["Roughness"].default_value = 0.0, ROUGHNESS[name]
    m.diffuse_color = col  # Workbench previews
    m.metallic, m.roughness = 0.0, ROUGHNESS[name]
    return m


def part():
    return fam.Part(ORDER, material)


def _arc(i0, z0, up):
    """The outside rounding as (inset, z) points: from the bottom round onto the wall's foot (up
    False) or from the wall's top round onto the top (up True)."""
    pts = []
    for k in range(SEG + 1):
        a = math.pi / 2 * k / SEG
        if up:
            pts.append((i0 + BEVEL * (1 - math.cos(a)), z0 - BEVEL * (1 - math.sin(a))))
        else:
            pts.append((i0 + BEVEL * (1 - math.sin(a)), z0 + BEVEL * (1 - math.cos(a))))
    return pts


def _shell(p, w, profile, cap_start, cap_end):
    """A hollow square shell w across, rounded in plan: `profile` is [(inset, z, material of the
    band to the next point)], each point a rounded-square ring inset from the outside."""
    rings = [[Vector((q.x, q.y, z)) for q in fam.rounded_rect(w - 2 * i, w - 2 * i, BEVEL - i, SEG)]
             for i, z, _m in profile]
    last = len(rings) - 2
    for k in range(len(rings) - 1):
        p._strip([rings[k], rings[k + 1]], profile[k][2],
                 cap_start=cap_start if k == 0 else None, cap_end=cap_end if k == last else None)


def _body(p):
    """The body, open at the top: the outside up from the rounded foot, over the rim and down the
    inside walls to the inside floor."""
    prof = [(i, z, "gift_paper") for i, z in _arc(0.0, 0.0, False)]
    prof.append((0.0, BODY_H, "gift_inside"))
    prof.append((WALL, BODY_H, "gift_inside"))
    prof.append((WALL, WALL, None))
    _shell(p, S, prof, cap_start="gift_paper", cap_end="gift_inside")
    # The ribbon cross: a strip down the middle of each side, proud by RIB (none over the opening).
    for turn in range(4):
        m = Matrix.Rotation(turn * math.pi / 2, 4, "Z") @ Matrix.Translation((S / 2 + (RIB - 0.001) / 2, 0, 0))
        p.rounded_box(RIB + 0.001, R, 0.0, BODY_H, 0.0012, 0.0, 0.0, "gift_ribbon", matrix=m, seg=1, seg_round=1)


def _lid(p):
    """The lid, open underneath: the inside ceiling and walls, the bottom rim, the outside up and
    round onto the top."""
    prof = [(WALL, LID_H - WALL, "gift_inside"), (WALL, 0.0, "gift_inside"), (0.0, 0.0, "gift_paper")]
    prof += [(i, z, "gift_paper") for i, z in _arc(0.0, LID_H, True)]
    prof[-1] = (prof[-1][0], prof[-1][1], None)
    _shell(p, LID_W, prof, cap_start="gift_inside", cap_end="gift_paper")
    # The ribbon cross: two bands over the top and down the sides, each an upside-down U (none
    # under the opening); the second a hair proud of the first where they cross on the top.
    for turn, step in ((0, 0.0), (1, 0.0005)):
        o, i = LID_W / 2 + RIB, LID_W / 2 - 0.001
        top, under = LID_H + RIB + step, LID_H - 0.001
        outline = [Vector(v + (0.0,)) for v in ((-o, 0), (-i, 0), (-i, under), (i, under), (i, 0), (o, 0),
                                               (o, top), (-o, top))]
        m = Matrix.Rotation(turn * math.pi / 2, 4, "Z") @ Matrix.Rotation(math.pi / 2, 4, "X")
        p.slab(outline, -R / 2 - step, R / 2 + step, "gift_ribbon", matrix=m)


def _loop(p, side):
    """One bow loop: a flat band round an oval LOOP_W x LOOP_H in the XZ plane, LOOP_D deep (along
    Y), at the old loop's place and lean."""
    n = 16
    path = [Vector((0.5 * (LOOP_W - LOOP_T) * math.cos(2 * math.pi * k / n), 0.0,
                    0.5 * (LOOP_H - LOOP_T) * math.sin(2 * math.pi * k / n))) for k in range(n)]
    m = Matrix.Translation((side * LOOP_X, 0.0, LOOP_Z)) @ Matrix.Rotation(side * LOOP_LEAN, 4, "Y")
    p.sweep(path, LOOP_T / 2, "gift_ribbon", normal=(0, 1, 0), matrix=m, n=6, squash=LOOP_D / LOOP_T)


def _box_uvs(ob, scale=1.0 / S):
    """A plain box projection (each face by its main axis), so the mesh carries a UV map."""
    me = ob.data
    uv = me.uv_layers.new(name="UVMap")
    for poly in me.polygons:
        n = poly.normal
        a = max(range(3), key=lambda i: abs(n[i]))
        u, v = [(1, 2), (0, 2), (0, 1)][a]
        for li in poly.loop_indices:
            co = me.vertices[me.loops[li].vertex_index].co
            uv.data[li].uv = (co[u] * scale, co[v] * scale)


def build(clean=True):
    """Rebuilds the box in the open file (closed). Returns a one-line report."""
    if clean:
        fam.wipe()
    root = fam.root(ASSET)
    root.empty_display_size = 0.1
    p = part()
    _body(p)
    box = p.finish("Box", parent=root, sharp_deg=50.0)
    p = part()
    _lid(p)
    for side in (-1, 1):
        _loop(p, side)
    p.rounded_box(KNOT_W, KNOT_D, KNOT_Z, KNOT_Z + KNOT_H, 0.008, 0.006, 0.008, "gift_ribbon",
                  seg=SEG, seg_round=SEG)
    # The lid's vertices are made in the lid's own space; it sits on the body.
    lid = p.finish("Lid", parent=box, sharp_deg=50.0)
    lid.location = (0.0, 0.0, BODY_H)
    objs = (box, lid)
    tris = {}
    for o in objs:
        _box_uvs(o)
        o.data.calc_loop_triangles()
        tris[o.name] = len(o.data.loop_triangles)
    mats = {s.material.name for o in objs for s in o.material_slots}
    return "render_tris=%d (Box %d, Lid %d) materials=%d" % (sum(tris.values()), tris["Box"], tris["Lid"], len(mats))


def export(out_root):
    """The root's children (not the root) to the glb: +Y up."""
    root = bpy.data.objects[ASSET]
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    for o in root.children_recursive:
        o.hide_viewport = False
        o.hide_set(False)
        o.select_set(True)
    out = os.path.join(out_root, GLB)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=out, export_format="GLB", use_selection=True, export_apply=True,
        export_yup=True, export_cameras=False, export_lights=False, export_animations=False,
        export_extras=False)
    return out


# --- The review line-up (not part of the asset) -------------------------------------------------

# The old wrapping tuning (data/tuning/wrapping.json): paper, ink, bow; tiles 2, ink strength 0.85.
WRAPS = {
    "patterns": ("#82b6e6", "#2f6ba2", "#377ebe"),
    "sport": ("#eb9175", "#a84020", "#c54c25"),
}
TILES, INK = 2.0, 0.85


def _wrap_image(col, icons):
    """The paper pattern as an image a cell wide and two rows high (the second row half-dropped, as
    gift_paper.gdshader): the icon's alpha mixes the ink over the paper, 0.7 of a cell."""
    import numpy as np
    paper, ink, _bow = WRAPS[col]
    icon = bpy.data.images.load(os.path.join(icons, col + ".png"))
    iw, ih = icon.size
    a = np.array(icon.pixels[:], dtype=np.float32).reshape(ih, iw, 4)[..., 3]
    bpy.data.images.remove(icon)
    n = 128
    out = np.zeros((2 * n, n, 4), dtype=np.float32)
    pc = np.array(fam.srgb(paper)[:3], dtype=np.float32)
    ic = np.array(fam.srgb(ink)[:3], dtype=np.float32)
    ys, xs = np.mgrid[0:2 * n, 0:n]
    cu = (xs + 0.5) / n
    cv = (ys + 0.5) / n
    row = np.floor(cv)
    cu = np.mod(cu + row * 0.5, 1.0)
    cv = cv - row
    pu, pv = (cu - 0.5) / 0.7 + 0.5, (cv - 0.5) / 0.7 + 0.5
    inside = (pu >= 0) & (pu <= 1) & (pv >= 0) & (pv <= 1)
    sx = np.clip((pu * iw).astype(int), 0, iw - 1)
    sy = np.clip((pv * ih).astype(int), 0, ih - 1)
    al = np.where(inside, a[sy, sx], 0.0) * INK
    out[..., :3] = pc * (1 - al[..., None]) + ic * al[..., None]
    out[..., 3] = 1.0
    img = bpy.data.images.new("_wrap_" + col, n, 2 * n)
    img.colorspace_settings.name = "Linear Rec.709" if "Linear Rec.709" in [
        i.name for i in bpy.types.ColorManagedInputColorspaceSettings.bl_rna.properties["name"].enum_items] else "Non-Color"
    img.pixels[:] = out.ravel()
    return img


def _paper_preview(col, icons):
    """A preview of the paper shader: the pattern box-projected from object space, `tiles` icons a
    face (the shader's mapping; Blender's box projection, so the top's rows may run another way)."""
    m = bpy.data.materials.new("_paper_" + col)
    nt = m.node_tree
    b = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Roughness"].default_value = ROUGHNESS["gift_paper"]
    tc = nt.nodes.new("ShaderNodeTexCoord")
    mp = nt.nodes.new("ShaderNodeMapping")
    k = TILES / S
    mp.inputs["Scale"].default_value = (k, k, k * 0.5)
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = _wrap_image(col, icons)
    tex.projection = "BOX"
    tex.interpolation = "Linear"
    nt.links.new(tc.outputs["Object"], mp.inputs["Vector"])
    nt.links.new(mp.outputs["Vector"], tex.inputs["Vector"])
    nt.links.new(tex.outputs["Color"], b.inputs["Base Color"])
    return m


def _plain(name, hexcol):
    m = bpy.data.materials.new(name)
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Base Color"].default_value = fam.srgb(hexcol)
    b.inputs["Roughness"].default_value = ROUGHNESS["gift_paper"]
    return m


def _cube(parent, size, pos, mat, rot_y=0.0):
    """The old _cube: a BoxMesh `size` (Godot x, y-up, z) at `pos`, here in Blender axes."""
    me = bpy.data.meshes.new("_old")
    sx, sy, sz = size
    import bmesh
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=(sx, sz, sy), verts=bm.verts)
    bm.to_mesh(me)
    bm.free()
    me.materials.append(mat)
    ob = bpy.data.objects.new("_old", me)
    bpy.context.scene.collection.objects.link(ob)
    ob.parent = parent
    ob.location = (pos[0], -pos[2], pos[1])
    ob.rotation_euler = (0.0, rot_y, 0.0)
    return ob


def _old_box(paper, ribbon):
    """The old make_box (GV:166-192), cube for cube: returns (box root, lid root)."""
    s, r = S, R
    box = bpy.data.objects.new("_old_box", None)
    bpy.context.scene.collection.objects.link(box)
    _cube(box, (s, s * 0.82, s), (0, s * 0.41, 0), paper)
    _cube(box, (s + 0.01, s * 0.82 + 0.01, r), (0, s * 0.41, 0), ribbon)
    _cube(box, (r, s * 0.82 + 0.01, s + 0.01), (0, s * 0.41, 0), ribbon)
    lid = bpy.data.objects.new("_old_lid", None)
    bpy.context.scene.collection.objects.link(lid)
    lid.parent = box
    lid.location = (0, 0, s * 0.82)
    _cube(lid, (s * 1.06, s * 0.2, s * 1.06), (0, s * 0.1, 0), paper)
    _cube(lid, (s * 1.07, s * 0.21, r), (0, s * 0.1, 0), ribbon)
    _cube(lid, (r, s * 0.21, s * 1.07), (0, s * 0.1, 0), ribbon)
    for side in (-1.0, 1.0):
        # Godot's rotation.z = -side * 0.5 is a turn about Blender's +Y of side * 0.5.
        _cube(lid, (r * 2.0, r * 1.4, r * 0.7), (side * r * 0.9, s * 0.2 + r * 0.6, 0), ribbon, rot_y=side * 0.5)
    _cube(lid, (r * 0.9, r * 0.9, r * 0.9), (0, s * 0.2 + r * 0.45, 0), ribbon)
    return box, lid


def _stage():
    """A floor, a world and two lights, EEVEE; returns the camera."""
    scene = bpy.context.scene
    try:
        scene.render.engine = "BLENDER_EEVEE"
    except TypeError:
        scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x, scene.render.resolution_y = 520, 520
    scene.render.film_transparent = False
    world = bpy.data.worlds.new("_world")
    world.color = (0.5, 0.52, 0.56)
    if world.node_tree is None:
        world.use_nodes = True
    bg = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs[0].default_value = (0.42, 0.45, 0.5, 1.0)
    bg.inputs[1].default_value = 0.7
    scene.world = world
    floor = bpy.data.objects.new("_floor", bpy.data.meshes.new("_floor"))
    import bmesh
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=3.0)
    bm.to_mesh(floor.data)
    bm.free()
    floor.data.materials.append(_plain("_floor", "#8C7A66"))
    scene.collection.objects.link(floor)
    for d, e in (((0.5, -0.9, 1.2), 3.2), ((-1.0, 0.4, 0.5), 1.0)):
        sun = bpy.data.objects.new("_sun", bpy.data.lights.new("_sun", "SUN"))
        sun.data.energy = e
        sun.data.angle = 0.2
        sun.rotation_euler = (-Vector(d)).to_track_quat("-Z", "Y").to_euler()
        scene.collection.objects.link(sun)
    cam = bpy.data.objects.new("_cam", bpy.data.cameras.new("_cam"))
    cam.data.lens = 60
    scene.collection.objects.link(cam)
    scene.camera = cam
    return cam


# The line-up's views: (target, direction, distance). `lid_off` looks down into the open box.
VIEWS = {
    "closed": ((0.0, 0.0, 0.17), (0.55, -0.95, 0.62), 1.2),
    "lid_off": ((-0.1, 0.06, 0.12), (0.45, -0.8, 1.1), 1.55),
    "knot": ((0.0, 0.0, BODY_H + LID_H + 0.03), (0.3, -1.0, 0.55), 0.42),
}


def _aim(cam, view):
    target, d, dist = VIEWS[view]
    target = Vector(target)
    cam.location = target + Vector(d).normalized() * dist
    cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()


def lineup(out_dir, icons):
    """Renders the tiles: for each Collection, the old box and this one closed, lid off (the lid
    propped beside, its inside to the camera; the view looks into the box) and the bow close up,
    each turned as a lying box starts (id 1: 0.4 rad). Returns the tile paths."""
    scene = bpy.context.scene
    cam = _stage()
    new_root = bpy.data.objects[ASSET]
    box, lid = bpy.data.objects["Box"], bpy.data.objects["Lid"]
    home = lid.location.copy()
    os.makedirs(out_dir, exist_ok=True)
    paths = []
    for col in WRAPS:
        paper = _paper_preview(col, icons)
        ribbon = _plain("_ribbon_" + col, WRAPS[col][2])
        old, old_lid = _old_box(paper, ribbon)
        for o in (box, lid):
            for i, m in enumerate(o.data.materials):
                if m.name.startswith(("gift_paper", "_paper")):
                    o.data.materials[i] = paper
                elif m.name.startswith(("gift_ribbon", "_ribbon")):
                    o.data.materials[i] = ribbon
        for view in ("closed", "lid_off", "knot"):
            _aim(cam, view)
            for which in ("old", "port"):
                show_old = which == "old"
                for o in [old] + list(old.children_recursive):
                    o.hide_render = not show_old
                for o in [new_root] + list(new_root.children_recursive):
                    o.hide_render = show_old
                b, l_ = (old, old_lid) if show_old else (box, lid)
                b.rotation_euler = (0.0, 0.0, 0.4)
                if view == "lid_off":
                    # Propped on its back edge behind the box's left, its inside to the camera.
                    l_.location = (-0.36, 0.25, 0.158)
                    l_.rotation_euler = (-1.3, 0.0, -0.3)
                else:
                    l_.location = (0.0, 0.0, BODY_H)
                    l_.rotation_euler = (0.0, 0.0, 0.0)
                path = os.path.join(out_dir, "%s_%s_%s.png" % (col, which, view))
                scene.render.filepath = path
                bpy.ops.render.render(write_still=True)
                paths.append(path)
        for o in [old] + list(old.children_recursive):
            bpy.data.objects.remove(o, do_unlink=True)
    lid.location = home
    lid.rotation_euler = (0.0, 0.0, 0.0)
    return paths


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out_root = REPO
    if "--out" in argv:
        out_root = os.path.abspath(argv[argv.index("--out") + 1])
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.unit_settings.system = "METRIC"
    report = build()
    said = [report]
    if "--lineup" in argv:
        out = os.path.abspath(argv[argv.index("--lineup") + 1])
        icons = os.path.abspath(argv[argv.index("--icons") + 1])
        said.append("lineup %d tiles in %s" % (len(lineup(out, icons)), out))
        print("PASS present_box " + " | ".join(said))
        return
    if "--no-export" not in argv:
        said.append("glb " + export(out_root))
    if "--save" in argv:
        path = os.path.join(REPO, SOURCE)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=path, compress=True)
        said.append("blend " + path)
    print("PASS present_box " + " | ".join(said))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:  # a crash is a failure, never a silent pass
        import traceback
        traceback.print_exc()
        print("FAIL present_box: %s" % e)
        sys.exit(1)
