"""The furniture kit, ported from the old game (tools/blender/house_furniture/fkit.py, house/04) to
build meshes only (Q2152): the stylised look of the old style trial (kit.py here) and the piece builder
that joins a piece's parts into the nodes of its glb. assets_src/generate/build.py runs it.

Blender axes while modelling: z up, every piece stands on z = 0 centred on x = 0, its front facing
-y. The glb is Y-up (Godot): the front faces +z.

A piece's glb holds a root node (the piece id) with these children:
  Body          every static part, joined (one mesh, several materials)
  Door, Door_L, Door_R, Door_<n>, Lid, Drawer_<n>, Flap, Boot (the car's tailgate)
                openable parts. The node origin is the pivot: a hinge part's origin sits on its
                hinge axis, a drawer's at its closed position.
  Screen        the TV's glass only (see ground.py tv).
  Key_<note>    the piano's keys (ground.py piano).
  PowerLight    the TV's standby lamp (one material, the game makes it glow).

What the old kit also wrote is in the Godot scenes now (game/furniture/, tools/furniture_from_old.py):
the parts' axes and travel, the collision boxes, the containers, the lamps, the Socks' colliders
(old sockcol.py) and the resting tops (old tops.py). The group files still call the old calls that
recorded them (P.collide, P.container, P.sock_box, P.sock_skip, P.sock_mesh, P.sock_tube,
P.sock_split, P.extra[...]): here they record and nothing is built or written from them, so the
group files stay as the old game had them and build the same meshes.
"""

import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))

import bmesh  # noqa: E402
import bpy  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

import kit  # noqa: E402
from kit import mat  # noqa: E402

PAL = dict(kit.PALETTE)
PAL.update({
    "mustard": PAL["cushion_a"],
    "pink": PAL["cushion_b"],          # dusty pink (Q406)
    "white": (0.95, 0.93, 0.88),       # appliances, painted cupboards
    "porcelain": (0.97, 0.97, 0.95),
    "steel": (0.74, 0.74, 0.72),
    "charcoal": (0.20, 0.20, 0.21),
    "screen": (0.05, 0.07, 0.07),
    "sage": (0.60, 0.68, 0.52),
    "sage_dark": (0.45, 0.54, 0.40),
    "cardboard": (0.78, 0.62, 0.42),
    "sheet": (0.93, 0.91, 0.86),
    "red": (0.80, 0.34, 0.28),
    "navy": (0.28, 0.35, 0.50),
    "grey": (0.58, 0.60, 0.60),
    "brass": (0.86, 0.68, 0.36),
    "lavender": (0.72, 0.66, 0.82),
    "sky": (0.55, 0.72, 0.85),
    "rubber": (0.15, 0.15, 0.15),
    "power_light": (0.85, 0.15, 0.10),
    "paper": (0.98, 0.97, 0.94),
})


def M(key, rough=0.7, metal=0.0, sheen=0.0):
    """The palette material `key` (one material per key, shared by every piece)."""
    return mat(key, PAL[key], rough=rough, metal=metal, sheen=sheen)


def fab(key):
    """A soft fabric in palette colour `key`."""
    return mat("fab_" + key, PAL[key], rough=0.9, sheen=0.1)


# --- Shapes (no subdivision; bevels and enough segments keep them round) -------------------

def box(name, size, loc, m, r=0.02, seg=2):
    """A bevelled box: size (w, d, h), bottom centre at loc."""
    return kit.rbox(name, size, loc, m, r=r, seg=seg)


def cush(name, size, loc, m, puff=(0.08, 0.08, 0.25), cuts=5, pinch=0.0):
    """A puffed cushion block (bottom centre at loc), smooth shaded, no subdivision."""
    return kit.cushion(name, size, loc, m, puff=puff, levels=0, cuts=cuts, pinch=pinch)


def lathe(name, profile, m, n=16, loc=(0, 0, 0), smooth=True):
    """Revolve [(radius, z)] about z at loc."""
    return kit.obj_from_bm(name, kit.lathe_bm(profile, n=n, loc=loc), m, smooth=smooth)


def cyl(name, r, h, loc, m, n=16, bev=0.0):
    """A cylinder (bottom centre at loc); bev rounds its rims."""
    if bev:
        b = min(bev, r * 0.5, h * 0.5)
        prof = [(0, 0), (r - b, 0), (r - b * 0.3, b * 0.3), (r, b), (r, h - b), (r - b * 0.3, h - b * 0.3),
                (r - b, h), (0, h)]
    else:
        prof = [(0, 0), (r, 0), (r, h), (0, h)]
    return lathe(name, prof, m, n=n, loc=loc, smooth=bool(bev))


def tube(name, pts, r, m, n=8, caps=True):
    rr = r if isinstance(r, (list, tuple)) else [r] * len(pts)
    return kit.obj_from_bm(name, kit.tube_bm(pts, rr, n=n, caps=caps), m)


def ball(name, r, loc, m, seg=12, rings=8, scale=(1, 1, 1)):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=seg, v_segments=rings, radius=r)
    for v in bm.verts:
        v.co = Vector((loc[0] + v.co.x * scale[0], loc[1] + v.co.y * scale[1], loc[2] + v.co.z * scale[2]))
    return kit.obj_from_bm(name, bm, m)


def bun_feet(xs, ys, h, r, m):
    """Squashed ball feet like the sock creature's, their tops tucked under the piece at z = h."""
    out = []
    for x in xs:
        for y in ys:
            out.append(lathe("Foot", [(0, 0), (r * 0.8, 0.005), (r, h * 0.35), (r * 0.92, h * 0.8),
                                      (r * 0.7, h + 0.02), (0, h + 0.02)], m, n=12, loc=(x, y, 0)))
    return out


def peg_legs(xs, ys, h, r, m, taper=0.7):
    """Round tapered legs from the floor to z = h."""
    return [lathe("Leg", [(0, 0), (r * taper, 0), (r * taper * 1.05, 0.01), (r, h), (0, h)], m, n=10,
                  loc=(x, y, 0)) for x in xs for y in ys]


def stripes(name, w, y, z, m, gap=0.06, t=0.03, d=0.012, h=None, axis="x"):
    """The sock creature's two cream cuff stripes (Q407): two thin bands across x (or z) at y, z."""
    out = []
    for k in (-1, 1):
        if axis == "x":
            out.append(box(name, (w, d, t), (0, y, z + k * gap / 2 - t / 2), m, r=0.004, seg=1))
        else:
            out.append(box(name, (d, w, t), (y, 0, z + k * gap / 2 - t / 2), m, r=0.004, seg=1))
    return out


def face_out(ob, loc, front=-1):
    """Turns an object built along +z about the origin (a cyl, a lathe) to point out of a front
    (front -1: towards -y) and moves it to loc. Shapes built at a loc rotate about the world
    origin, so build these at (0, 0, 0)."""
    ob.rotation_euler.x = math.pi / 2 if front < 0 else -math.pi / 2
    ob.location = loc
    return ob


def knob(name, loc, m, r=0.018, front=-1):
    """A little round knob pointing out of a front (front -1: -y)."""
    x, y, z = loc
    ob = ball(name, r, (x, y + front * r * 0.6, z), m, seg=10, rings=6, scale=(1, 0.8, 1))
    return ob


def handle_bar(name, x0, x1, y, z, m, r=0.008):
    """A bar handle along x, standing proud of a front at y (front -y)."""
    return tube(name, [(x0, y, z), (x0, y - 0.03, z), (x1, y - 0.03, z), (x1, y, z)], r, m, n=6)


# --- The piece builder ------------------------------------------------------------------

def bx(name, lo, hi, m, r=0.004, seg=1):
    """A box from corner lo to corner hi (Blender axes)."""
    return box(name, (hi[0] - lo[0], hi[1] - lo[1], hi[2] - lo[2]),
               ((lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2, lo[2]), m, r=r, seg=seg)


# The thinnest collider of a wall (grown outwards from its panel), as make_flat's COL_WALL.
COL_WALL = 0.04
FACES = {"front": (1, 0), "back": (1, 1), "left": (0, 0), "right": (0, 1), "bottom": (2, 0), "top": (2, 1)}


def shell(P, name, lo, hi, t, m, open=("front",), r=0.004, collide=True, skip=()):
    """A hollow box from lo to hi (Blender axes) of panels t thick, the faces in `open` left out
    (front is -y, top +z; `skip` faces collide but are not drawn). Each panel collides, grown
    outwards to COL_WALL. Returns its inside (lo, hi); open faces reach the outside."""
    ilo, ihi = list(lo), list(hi)
    for face, (ax, side) in FACES.items():
        if face in open:
            continue
        a, b = list(lo), list(hi)
        if side == 0:
            b[ax] = lo[ax] + t
            ilo[ax] = lo[ax] + t
        else:
            a[ax] = hi[ax] - t
            ihi[ax] = hi[ax] - t
        if face not in skip:
            P.add(bx(name + face.title(), a, b, m, r=r))
        if collide:
            ca, cb = list(a), list(b)
            if b[ax] - a[ax] < COL_WALL:
                if side == 0:
                    ca[ax] = b[ax] - COL_WALL
                else:
                    cb[ax] = a[ax] + COL_WALL
            P.collide(ca, cb)
    return ilo, ihi


def tray_boxes(lo, hi, front=0.022):
    """A drawer's collision: its front slab (front thick, before lo.y) and its tray's floor and
    walls; lo..hi the tray (Blender axes, the front at lo.y)."""
    (x0, y0, z0), (x1, y1, z1) = lo, hi
    w = COL_WALL / 2
    return [((x0 - 0.02, y0 - front, z0 - 0.02), (x1 + 0.02, y0 + w, z1 + 0.03)),
            ((x0, y0, z0 - 0.02), (x1, y1, z0 + 0.012)),
            ((x0, y1 - w, z0), (x1, y1, z1)),
            ((x0, y0, z0), (x0 + w, y1, z1)),
            ((x1 - w, y0, z0), (x1, y1, z1))]


def gbox(lo, hi, shift=(0, 0, 0)):
    """A Blender box (lo, hi), moved by shift, as a Godot {min, max}."""
    a = [lo[i] + shift[i] for i in range(3)]
    b = [hi[i] + shift[i] for i in range(3)]
    return {"min": [round(min(a[0], b[0]), 4), round(min(a[2], b[2]), 4), round(-max(a[1], b[1]), 4)],
            "max": [round(max(a[0], b[0]), 4), round(max(a[2], b[2]), 4), round(-min(a[1], b[1]), 4)]}


def to_godot(v):
    """Blender (x, y, z) -> glTF/Godot (x, z, -y)."""
    return [round(v[0], 4), round(v[2], 4), round(-v[1], 4)]


class Piece:
    """Collects a piece's static objects and its openable parts, then joins and exports them."""

    def __init__(self, pid):
        self.id = pid
        self.body = []
        self.parts = []      # (name, objs, pivot, info)
        self.special = []    # (name, objs) non-openable named nodes (Screen, PowerLight)
        self.root = None
        self.nodes = {}
        self.colliders = []   # (lo, hi) Blender
        self.containers = []  # dict(name, parts, kind, lo, hi, shelves)
        self.extra = {}       # manifest fields written as they are (Godot units)
        # The old Socks' colliders (sockcol.py, not ported): recorded by the group files, unused.
        self.sock_skips = set()
        self.sock_boxes = []
        self.sock_merge = None
        self.sock_dev = None
        self.sock_cap = None
        self.sock = True
        self.crawl = REG[pid]["crawl"] if pid in REG else None
        self.sock_meshes = []
        self.sock_splits = []
        self.sock_hulls = []
        self.sock_objs = []

    def add(self, *objs):
        for o in objs:
            if isinstance(o, (list, tuple)):
                self.body.extend(o)
            else:
                self.body.append(o)
        return objs[0] if len(objs) == 1 else objs

    def hinge(self, name, objs, pivot, axis, open_deg, boxes=None):
        """An openable part turning about `axis` (Blender axes) through `pivot` by +open_deg;
        `boxes` (Blender, absolute) its collision, its own bounding box when None, one box per
        object when "each" (a handle or knob then stays a box of its own, house/12)."""
        if boxes == "each":
            bpy.context.view_layer.update()
            boxes = [tuple(tuple(v) for v in kit.bounds([o])) for o in objs]
        self.parts.append((name, list(objs), pivot, {"kind": "hinge", "axis": axis, "open_deg": open_deg,
                                                     "boxes": boxes}))

    def slide(self, name, objs, pivot, axis, open_m, boxes=None):
        """A drawer sliding along `axis` (Blender axes) by open_m; pivot = its closed position."""
        self.parts.append((name, list(objs), pivot, {"kind": "slide", "axis": axis, "open_m": open_m,
                                                     "boxes": boxes}))

    def collide(self, lo, hi, sock=False):
        """A collider box (Blender axes). A piece with none collides as one box over its
        footprint from its crawl gap up (make_house.py). sock: the Socks meet it too (sock_box())."""
        self.colliders.append((tuple(lo), tuple(hi)))
        if sock:
            self.sock_box(lo, hi)

    def sock_box(self, lo, hi):
        """An authored box the Socks met in the old game (recorded, unused here)."""
        self.sock_boxes.append((tuple(lo), tuple(hi)))

    def sock_skip(self, *names):
        """Drawn objects (by name) the Socks don't meet as drawn: a hollow tub or shell, which its
        authored boxes stand for (sock_box())."""
        self.sock_skips.update(names)

    def sock_mesh(self, ob):
        """A trimesh the Socks meet: the concave inside of a tub or basket that Socks lie in, under
        500 triangles (Q795). `ob` is a drawn object (then also sock_skip() it) or a mesh made for
        this alone (then not added to the piece)."""
        if ob not in self.body:
            ob.hide_render = True
        self.sock_meshes.append(ob)

    def sock_tube(self, pts, r, n=8):
        """A bent tube the Socks meet as one hull per straight run (as one hull it would roof what
        its bends reach over): pts and r as tube()'s (Blender axes)."""
        for a, b in zip(pts, pts[1:]):
            a, b = Vector(a), Vector(b)
            ax = (b - a).normalized()
            u = ax.orthogonal().normalized()
            v = ax.cross(u)
            ring = [u * math.cos(2 * math.pi * k / n) * r + v * math.sin(2 * math.pi * k / n) * r for k in range(n)]
            self.sock_hulls.append([tuple(c + q) for c in (a, b) for q in ring])

    def sock_split(self, ob, regions):
        """A hollow drawn object the Socks meet as pieces: the hull of what of it lies in each
        region (lo, hi; Blender boxes), e.g. a tub's walls and floor one by one."""
        self.sock_skip(ob.name.split(".")[0])
        self.sock_splits.append((ob, [(tuple(a), tuple(b)) for a, b in regions]))

    def container(self, name, parts, lo, hi, kind, shelves=()):
        """A space inside the piece (lo..hi, Blender) where Socks hide, opened by `parts`; kind
        names its sounds (fridge, cupboard, oven, drawer, basket); shelves: the heights (z) of
        the shelves inside that hold Socks."""
        self.containers.append(dict(name=name, parts=list(parts), kind=kind, lo=tuple(lo), hi=tuple(hi),
                                    shelves=list(shelves)))

    def named(self, name, objs):
        self.special.append((name, list(objs)))

    def finish(self):
        self.root = bpy.data.objects.new(self.id, None)
        bpy.context.scene.collection.objects.link(self.root)
        body = _join(self.id + ":Body", self.body)
        body.parent = self.root
        self.nodes["Body"] = body
        for name, objs in self.special:
            o = _join(self.id + ":" + name, objs)
            o.parent = self.root
            self.nodes[name] = o
        for name, objs, pivot, part in self.parts:
            o = _join(self.id + ":" + name, objs)
            o.parent = self.root
            self.nodes[name] = o
        # Centre the footprint on the origin and stand it on y = 0.
        bpy.context.view_layer.update()
        lo, hi = kit.bounds(list(self.nodes.values()))
        shift = Vector((-(lo.x + hi.x) / 2, -(lo.y + hi.y) / 2, -lo.z))
        for o in self.nodes.values():
            o.data.transform(Matrix.Translation(shift))
        info = {}
        bpy.context.view_layer.update()
        for name, objs, pivot, part in self.parts:
            o = self.nodes[name]
            pv = Vector(pivot) + shift
            boxes = part["boxes"]
            if boxes is None:
                lo, hi = kit.bounds([o])
                boxes = [(tuple(lo - shift), tuple(hi - shift))]
            o.data.transform(Matrix.Translation(-pv))
            o.location = pv
            p = {"kind": part["kind"], "pivot": to_godot(pv), "axis": to_godot(part["axis"])}
            p.update({k: v for k, v in part.items() if k.startswith("open")})
            p["boxes"] = [gbox(a, b, tuple(shift - pv)) for a, b in boxes]
            info[name] = p
        self.shift = tuple(shift)
        bpy.context.view_layer.update()
        return info

    def tris(self):
        n = {}
        for k, o in self.nodes.items():
            o.data.calc_loop_triangles()
            n[k] = len(o.data.loop_triangles)
        return n

    def bounds(self):
        return kit.bounds(list(self.nodes.values()))

    def export(self, path):
        """Writes the glb with clean node names (Body, Door, ...)."""
        bpy.ops.object.select_all(action="DESELECT")
        self.root.select_set(True)
        for k, o in self.nodes.items():
            o.name = k
            o.data.name = self.id + "_" + k
            o.select_set(True)
        bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_yup=True, export_apply=True,
                                  export_cameras=False, export_lights=False, use_selection=True)
        for k, o in self.nodes.items():
            o.name = self.id + ":" + k

    def clean_names(self):
        """Gives the nodes their glb names for good (Body, Door, ...; meshes <piece>_<node>), as
        export() does for its own write: the piece is then ready to export or save as a source."""
        for k, o in self.nodes.items():
            o.name = k
            o.data.name = self.id + "_" + k

    def strip_helpers(self):
        """Removes every object that is not the piece (made only to be measured, such as a hidden
        sock_mesh()), so a saved source holds the piece alone."""
        keep = {self.root} | set(self.root.children_recursive)
        for o in list(bpy.data.objects):
            if o not in keep:
                bpy.data.objects.remove(o, do_unlink=True)
        bpy.data.orphans_purge(do_recursive=True)

    def pose_open(self, parts_info, frac=0.6):
        """Opens every part by frac of its range (for the lineup render)."""
        for name, p in parts_info.items():
            o = self.nodes[name]
            ax = Vector((p["axis"][0], -p["axis"][2], p["axis"][1]))   # Godot -> Blender
            if p["kind"] == "hinge":
                o.rotation_mode = "QUATERNION"
                from mathutils import Quaternion
                o.rotation_quaternion = Quaternion(ax, math.radians(p["open_deg"] * frac))
            else:
                o.location = o.location + ax * p["open_m"] * frac


# --- The registry: each room-group module registers its pieces --------------------------

REG = {}
# The group files, each registering its pieces (build.py imports them all).
GROUPS = ("basement", "ground", "first", "attic", "plants", "grotto")


def piece(pid, rooms, spot=None, crawl=None, hide=None, note=None):
    """Registers a piece builder fn(P: Piece). rooms: where it goes (the house/01 plan's rooms);
    spot: the plan's furniture label(s) it fills; crawl: the clear height under it (m) Socks can
    crawl or hide in; hide: what the hiding spot is; note: anything house/03 needs to know."""
    def deco(fn):
        REG[pid] = dict(fn=fn, rooms=rooms, spot=spot, crawl=crawl, hide=hide, note=note,
                        group=fn.__module__)
        return fn
    return deco


def _join(name, objs):
    """Applies modifiers (keeping custom normals) and joins objs into one mesh object."""
    objs = [o for o in objs if o is not None]
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.convert(target="MESH")
    if len(objs) > 1:
        bpy.ops.object.join()
    ob = bpy.context.view_layer.objects.active
    ob.name = name
    # Bake the object transform into the mesh so the node sits at identity.
    ob.data.transform(ob.matrix_world)
    ob.matrix_world = Matrix.Identity(4)
    return ob
