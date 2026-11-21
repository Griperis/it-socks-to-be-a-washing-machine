"""Generate the flat (assets/flat/flat.glb and assets/flat/flat_layout.json).

Run headless (cap the threads so the machine stays responsive):
    blender -b -t 4 -P tools/blender/make_flat.py -- <out_dir> [preview_dir] [--only <room>] [--final]

  --only <room>  build the shell plus one room's furniture (kitchen, living, bedroom,
                 bathroom, hall) and render only that room's views; exports nothing
  --final        render the few final previews with EEVEE (12 samples) instead of
                 the cheap Workbench iteration previews (640x400, 1 sample, no shadows)

The sock-spill flat (spec docs/llm/flat/spec.md, look ADR-0003): an L-shaped ~84 m2
flat with an open kitchen/living room, a hall, a bathroom and a bedroom, joined by
open doorways. Ceiling at y 2.7; exterior walls 0.2 m thick outward, partitions
0.12 m thick centred on the room boundary. The origin is the north-west inner
corner of the kitchen; x runs east, z runs south.

    kitchen  x 0.00..3.60  z 0.00..5.94  (open to the living room at x 3.6)
    living   x 3.60..8.00  z 0.00..5.94
    hall     x 0.00..2.34  z 6.06..8.94  (front door, west wall)
    bathroom x 2.46..5.40  z 6.06..8.94  (washing machine, spawn)
    bedroom  x 0.00..5.40  z 9.06..13.00

Axes: geometry is authored in glTF/Godot axes (x right, y up, z south) and
converted to Blender axes (x, -z, y) when written, so the glTF exporter's Y-up
conversion brings it back unchanged.

Mesh nodes. Static meshes are merged per room and have their origin at the scene
origin (vertices are in flat space): Floor, Walls (with bathroom wall tiles and
pictures), Ceiling (with the ceiling lamps' roses, cords and the other lamps), Shades (the
living room and bedroom globe shades with their bulbs, sockets and inner cords, material `shade_paper`: translucent,
glowing paper that code keeps from casting shadows, flat/28 Q203), Trim, Windows (frames, sills, rods,
curtains), Glass, Rugs, Kitchen, Living, Bedroom, Bathroom, Hall. Low poly: bevels
of at most 2 segments, shared materials, textures 1024 px or smaller.
Openable nodes have their origin ON THE HINGE AXIS and identity rotation; code
rotates them about `axis` (Godot coordinates) by `open_deg` to open them:
FridgeDoor, OvenDoor, CupboardADoor, CupboardBDoorL, CupboardBDoorR,
LaundryBasketLid. (The wardrobe's doors are its own model's since pipeline/05.)
Empty nodes (light markers): CeilingLight_<room>, LampLight_<name>, Sun_<window>.

Layout JSON (flat_layout.json). Every x/z pair ("min"/"max" with two numbers) is a
floor footprint; every [x, y, z] triple is a point or box corner in Godot metres.
  units, bounds        overall interior box, ceiling height, wall thicknesses
  outline              interior outline polygon (x/z), clockwise from the NW corner
  rooms[]              {name, min, max, floor, open_to[]}: clear interior rects
  doorways[]           {name, between[2], min, max, height}: open doorways (no door)
  front_door           {min, max, height}: closed, decorative
  windows[]            {name, room, wall, min, max, sill_y, head_y}
  spawn                {pos [x,y,z], yaw, look_at}: next to the washer; yaw is the
                       player's rotation.y (0 looks towards -z)
  washer               {pos, yaw, zone}: the Upgrade station; modelled facing +z,
                       yaw turns it (as room.gd's CABINET_SPOTS)
  cabinet_spots[]      {spot, collection, room, wall, pos, yaw, zone, max_height}: spot
                       is its id (make_house.py; collection the default one, a run
                       draws its own: progression/52); pos is
                       the footprint centre of a 1.5 x 0.5 Cabinet whose back
                       touches the wall; yaw turns its +z front into the room
  clear_zones          the cabinet and washer zones, kept free of every mesh from
                       the floor up to y_max (cabinet 0.5 + drawer pull-out 0.45)
  colliders[]          {name, min [x,y,z], max [x,y,z]}: primitive boxes for every
                       static mesh (walls, floor, ceiling, furniture parts); hollow
                       things (cupboards, fridge, oven, basket, tub) are split into
                       panels so socks fit inside, and under-furniture gaps stay open
  surfaces[]           {name, room, min, max, y}: flat tops where socks may rest
  crawl_spaces[]       {name, room, min, max, y_max}: open gaps under the bed, sofa
                       and kitchen table (socks there are seen only when crouched)
  openables[]          {name, room, kind, doors[{node, hinge, axis, open_deg,
                       min, max}], interior {min, max}, shelves_y[]}: containers
                       that open with a click; door min/max are the door's box in
                       node-local metres (relative to the hinge)
  furniture[]          {name, room, min, max, height}: footprints, for the Mess
                       spread and blocked areas
  lights[]             {name, kind (ceiling|lamp|window), room, pos}
  rugs[]               {name, room, min, max, top_y}
  wardrobe             {pos, yaw, size [w, h, d], room, zone, doors[], interior}: the
                       Wardrobe Station (flat/48): pos its floor centre, yaw turns its +z
                       front into the room, zone its footprint plus the floor in front
                       (kept free of socks), doors and interior as an openable's (not
                       listed in openables: its doors follow who is in the Wardrobe)
  mirror               {pos, yaw, radius, room}: the round mirror over the bathroom
                       sink, pos the centre of its glass's face, yaw turns its +z face
                       into the room (Godot draws its reflection there)
  clock                {pos, yaw, room, wall}: where the wall clock
                       (assets/clock/clock.glb, make_clock.py) hangs: pos is
                       its back centre on the wall face, yaw turns its +z face into the room

If preview_dir is given, renders flat_top.png and room views, crouch views and
openables views into it (with --final only flat_top, kitchen_living, bathroom and
crouch_under_bed). Stand-in boxes show the Cabinet spots, and the washing
machine and wall clock models (if their glbs exist) in the previews only; they are
not exported.
"""

import json
import math
import os
import sys

import bpy
import bmesh
import numpy as np
from mathutils import Matrix, Vector

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
FINAL = "--final" in argv
ONLY = argv[argv.index("--only") + 1] if "--only" in argv else None
_pos = [a for i, a in enumerate(argv) if not a.startswith("--") and (i == 0 or argv[i - 1] != "--only")]
OUT_DIR = _pos[0] if _pos else "."
PREVIEW_DIR = _pos[1] if len(_pos) > 1 else None
REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# --- Contract dimensions (metres, glTF axes) ---------------------------------
H = 2.7                      # ceiling height
EXT_T = 0.2                  # exterior wall thickness (outward)
PART_T = 0.12                # partition thickness (centred)
FLOOR_T = 0.1
DOOR_H = 2.1
CLEAR_TOP = 2.5
CAB_W, CAB_D, CAB_ZONE_W, CAB_ZONE_D = 1.5, 0.5, 1.8, 0.95
CASING_W = 0.07

ROOMS = {   # name: ((min x, min z), (max x, max z)), floor material
    "kitchen": (((0.0, 0.0), (3.6, 5.94)), "kitchen_tile"),
    "living": (((3.6, 0.0), (8.0, 5.94)), "wood"),
    "hall": (((0.0, 6.06), (2.34, 8.94)), "wood"),
    "bathroom": (((2.46, 6.06), (5.4, 8.94)), "bath_tile"),
    "bedroom": (((0.0, 9.06), (5.4, 13.0)), "wood"),
}
OUTLINE = [(0.0, 0.0), (8.0, 0.0), (8.0, 5.94), (5.4, 5.94), (5.4, 13.0), (0.0, 13.0)]

# Wall boxes: name, run axis, (s0, s1) along it, (t0, t1) across it, holes.
# A hole is (s0, s1, y0, y1, kind, name); kind is window, doorway or front_door.
WALLS = [
    ("N", "x", (-0.2, 8.2), (-0.2, 0.0), [(2.2, 3.2, 1.1, 2.15, "window", "Kitchen"),
                                          (3.9, 4.7, 0.9, 2.15, "window", "LivingNorth")]),
    ("E1", "z", (0.0, 5.94), (8.0, 8.2), [(3.4, 5.0, 0.9, 2.15, "window", "LivingEast")]),
    ("S1", "x", (5.6, 8.2), (5.94, 6.14), [(6.1, 7.5, 0.9, 2.15, "window", "LivingSouth")]),
    ("E2", "z", (5.94, 13.2), (5.4, 5.6), [(6.95, 7.75, 1.3, 2.0, "window", "Bathroom")]),
    ("S2", "x", (-0.2, 5.6), (13.0, 13.2), [(3.6, 4.9, 0.95, 2.15, "window", "Bedroom")]),
    ("W", "z", (0.0, 13.0), (-0.2, 0.0), [(6.5, 7.5, 0.0, DOOR_H, "front_door", "Front")]),
    ("P1", "x", (0.0, 5.4), (5.94, 6.06), [(0.3, 1.2, 0.0, DOOR_H, "doorway", "KitchenHall")]),
    ("P2", "x", (0.0, 5.4), (8.94, 9.06), [(1.2, 2.1, 0.0, DOOR_H, "doorway", "HallBedroom")]),
    ("P3", "z", (6.06, 8.94), (2.34, 2.46), [(8.0, 8.86, 0.0, DOOR_H, "doorway", "HallBathroom")]),
]
DOORWAY_ROOMS = {"KitchenHall": ["kitchen", "hall"], "HallBedroom": ["hall", "bedroom"],
                 "HallBathroom": ["hall", "bathroom"]}

# Interior wall faces: (wall, run axis, face coordinate, inward sign, s0, s1).
FACES = [
    ("N", "x", 0.0, +1, 0.0, 8.0),
    ("E1", "z", 8.0, -1, 0.0, 5.94),
    ("S1", "x", 5.94, -1, 5.4, 8.0),
    ("E2", "z", 5.4, -1, 6.06, 13.0),
    ("S2", "x", 13.0, -1, 0.0, 5.4),
    ("W", "z", 0.0, +1, 0.0, 13.0),
    ("P1", "x", 5.94, -1, 0.0, 5.4),
    ("P1", "x", 6.06, +1, 0.0, 5.4),
    ("P2", "x", 8.94, -1, 0.0, 5.4),
    ("P2", "x", 9.06, +1, 0.0, 5.4),
    ("P3", "z", 2.34, -1, 6.06, 8.94),
    ("P3", "z", 2.46, +1, 6.06, 8.94),
]

# Cabinet spots: collection, room, wall face (wall, face coord), centre along the wall.
CABINETS = [
    ("simple", "bedroom", "W", 0.0, +1, 11.2, 6),
    ("winter", "bedroom", "P2", 9.06, +1, 3.3, 3),
    ("superhero", "bedroom", "E2", 5.4, -1, 10.0, 2),
    ("space", "bedroom", "S2", 13.0, -1, 2.05, 2),
    ("patterns", "living", "N", 0.0, +1, 5.9, 4),
    ("animals", "living", "E1", 8.0, -1, 1.6, 2),
    ("food", "kitchen", "W", 0.0, +1, 2.4, 2),
    ("sport", "hall", "P3", 2.34, -1, 6.98, 3),
]
WASHER_POS = (4.6, 0.0, 6.42)        # 0.70 x 0.70 x 0.95, back against the bathroom's north wall
WASHER_ZONE = ((4.2, 6.06), (5.0, 7.3))
SPAWN = (4.0, 0.0, 7.5)
# The wall clock (flat/28 Q204): living room north wall, east of the patterns Cabinet's clear zone.
CLOCK_POS = (7.3, 1.95, 0.0)
CLOCK_YAW = 0.0

# Furniture placements.
BED = ((3.3, 11.4), (5.4, 12.98))    # head against the east wall
BED_GAP = 0.30                       # crawl height under the bed
NIGHTSTAND = ((4.92, 10.95), (5.38, 11.36))
SOFA = ((4.6, 4.2), (6.8, 5.1))      # faces north
SOFA_GAP = 0.20
COFFEE = ((5.15, 3.0), (6.25, 3.6))
TABLE = ((1.45, 2.9), (2.75, 3.7))   # kitchen table
TABLE_TOP = 0.76
FRIDGE = ((0.05, 0.0), (0.78, 0.68))
FRIDGE_H = 1.85
COUNTER = (0.8, 3.4)                 # x range; depth 0.6 from the north wall
COUNTER_TOP = 0.9
BASKET_C = (3.85, 6.42)
TUB = ((3.55, 8.12), (5.38, 8.92))
VANITY = ((2.62, 6.06), (3.38, 6.5))
COL_WALL = 0.045                     # the thinnest wall collider of a hollow container (the basket)
MIRROR_Y, MIRROR_R = 1.55, 0.26     # the round mirror over the sink: centre height, glass radius
# The Wardrobe Station (multiplayer/20, flat/48): against the bedroom's west wall, left of the
# door, its doors facing into the room (+x). x 0..depth, z centre +- width / 2.
WARDROBE_C = 9.6
WARDROBE_W, WARDROBE_D, WARDROBE_H = 1.0, 0.56, 1.92
WARDROBE_ZONE = ((0.0, 9.06), (1.25, 10.15))
WARDROBE = {}


def srgb(r, g, b):
    f = lambda c: c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return (f(r), f(g), f(b), 1.0)


# name: (base colour, roughness, metallic, emission strength, alpha)
MATERIALS = {
    "wall_kitchen": (srgb(0.96, 0.89, 0.77), 0.9, 0.0, 0.0, 1.0),
    "wall_living": (srgb(0.96, 0.89, 0.77), 0.9, 0.0, 0.0, 1.0),
    "wall_hall": (srgb(0.97, 0.86, 0.62), 0.9, 0.0, 0.0, 1.0),
    "wall_bathroom": (srgb(0.80, 0.91, 0.88), 0.9, 0.0, 0.0, 1.0),
    "wall_bedroom": (srgb(0.94, 0.79, 0.73), 0.9, 0.0, 0.0, 1.0),
    "wall_outside": (srgb(0.93, 0.90, 0.84), 0.9, 0.0, 0.0, 1.0),
    "ceiling": (srgb(0.98, 0.95, 0.89), 0.9, 0.0, 0.0, 1.0),
    "trim": (srgb(0.98, 0.96, 0.91), 0.55, 0.0, 0.0, 1.0),
    "oak": (srgb(0.80, 0.57, 0.34), 0.62, 0.0, 0.0, 1.0),
    "dark_wood": (srgb(0.47, 0.29, 0.16), 0.5, 0.0, 0.0, 1.0),
    "linen": (srgb(0.97, 0.94, 0.88), 0.85, 0.0, 0.0, 1.0),
    "duvet": (srgb(0.93, 0.73, 0.44), 0.9, 0.0, 0.0, 1.0),
    "pad": (srgb(0.93, 0.84, 0.66), 0.9, 0.0, 0.0, 1.0),
    "curtain": (srgb(0.62, 0.72, 0.56), 0.9, 0.0, 0.0, 1.0),
    "curtain_bed": (srgb(0.86, 0.62, 0.55), 0.9, 0.0, 0.0, 1.0),
    "rug": (srgb(0.80, 0.48, 0.39), 0.95, 0.0, 0.0, 1.0),
    "rug_stripe": (srgb(0.96, 0.88, 0.72), 0.95, 0.0, 0.0, 1.0),
    "rug_blue": (srgb(0.45, 0.58, 0.72), 0.95, 0.0, 0.0, 1.0),
    "rug_mint": (srgb(0.62, 0.82, 0.74), 0.95, 0.0, 0.0, 1.0),
    "door": (srgb(0.96, 0.93, 0.87), 0.5, 0.0, 0.0, 1.0),
    "front_door": (srgb(0.36, 0.52, 0.55), 0.5, 0.0, 0.0, 1.0),
    "brass": (srgb(0.88, 0.68, 0.32), 0.32, 1.0, 0.0, 1.0),
    "steel": (srgb(0.78, 0.80, 0.82), 0.3, 1.0, 0.0, 1.0),
    "shade": (srgb(1.0, 0.82, 0.55), 0.8, 0.0, 2.0, 1.0),
    "paper": (srgb(1.0, 0.93, 0.80), 0.8, 0.0, 1.5, 1.0),
    "shade_paper": (srgb(1.0, 0.93, 0.80), 0.85, 0.0, 1.5, 0.92),
    "bulb": (srgb(1.0, 0.90, 0.70), 0.3, 0.0, 6.0, 1.0),
    "glass": (srgb(0.85, 0.93, 0.97), 0.05, 0.0, 0.0, 0.25),
    "frosted": (srgb(0.92, 0.96, 0.97), 0.4, 0.0, 0.0, 0.7),
    "mirror": (srgb(0.80, 0.86, 0.90), 0.05, 1.0, 0.0, 1.0),
    "wood": (srgb(0.66, 0.45, 0.28), 0.6, 0.0, 0.0, 1.0),
    "kitchen_tile": (srgb(0.85, 0.55, 0.40), 0.5, 0.0, 0.0, 1.0),
    "bath_tile": (srgb(0.92, 0.95, 0.93), 0.4, 0.0, 0.0, 1.0),
    "wall_tile": (srgb(0.95, 0.97, 0.95), 0.3, 0.0, 0.0, 1.0),
    "cupboard": (srgb(0.55, 0.72, 0.66), 0.55, 0.0, 0.0, 1.0),       # sage kitchen fronts
    "worktop": (srgb(0.74, 0.53, 0.33), 0.5, 0.0, 0.0, 1.0),
    "carcass_in": (srgb(0.93, 0.90, 0.84), 0.7, 0.0, 0.0, 1.0),
    "fridge": (srgb(0.96, 0.90, 0.78), 0.35, 0.0, 0.0, 1.0),         # retro cream
    "enamel": (srgb(0.92, 0.42, 0.32), 0.35, 0.0, 0.0, 1.0),         # tomato oven
    "oven_in": (srgb(0.18, 0.16, 0.16), 0.6, 0.0, 0.0, 1.0),
    "hob": (srgb(0.16, 0.15, 0.15), 0.5, 0.0, 0.0, 1.0),
    "porcelain": (srgb(0.98, 0.98, 0.97), 0.2, 0.0, 0.0, 1.0),
    "sofa": (srgb(0.38, 0.56, 0.55), 0.95, 0.0, 0.0, 1.0),           # teal velvet
    "cushion_a": (srgb(0.95, 0.70, 0.35), 0.95, 0.0, 0.0, 1.0),
    "cushion_b": (srgb(0.92, 0.60, 0.55), 0.95, 0.0, 0.0, 1.0),
    "seat_pad": (srgb(0.90, 0.55, 0.42), 0.9, 0.0, 0.0, 1.0),
    "wicker": (srgb(0.80, 0.64, 0.42), 0.9, 0.0, 0.0, 1.0),
    "wicker_dark": (srgb(0.62, 0.46, 0.28), 0.9, 0.0, 0.0, 1.0),
    "leaf": (srgb(0.36, 0.60, 0.36), 0.8, 0.0, 0.0, 1.0),
    "terracotta": (srgb(0.80, 0.45, 0.30), 0.85, 0.0, 0.0, 1.0),
    "coat_a": (srgb(0.85, 0.62, 0.25), 0.9, 0.0, 0.0, 1.0),
    "coat_b": (srgb(0.55, 0.30, 0.25), 0.9, 0.0, 0.0, 1.0),
    "orange": (srgb(0.98, 0.58, 0.18), 0.6, 0.0, 0.0, 1.0),
    "apple": (srgb(0.80, 0.25, 0.22), 0.5, 0.0, 0.0, 1.0),
    "jar": (srgb(0.88, 0.80, 0.62), 0.5, 0.0, 0.0, 1.0),
    "art_a": (srgb(0.95, 0.75, 0.45), 0.9, 0.0, 0.0, 1.0),
    "art_b": (srgb(0.55, 0.70, 0.80), 0.9, 0.0, 0.0, 1.0),
    "art_c": (srgb(0.85, 0.55, 0.60), 0.9, 0.0, 0.0, 1.0),
    "towel": (srgb(0.95, 0.80, 0.55), 0.95, 0.0, 0.0, 1.0),
    "oak_panel": (srgb(0.72, 0.50, 0.30), 0.65, 0.0, 0.0, 1.0),     # wardrobe door panels
    "wardrobe_in": (srgb(0.88, 0.76, 0.60), 0.75, 0.0, 0.0, 1.0),    # pale birch lining
}

# --- Layout registries --------------------------------------------------------
COLLIDERS, SURFACES, CRAWL, OPENABLES, FURNITURE, LIGHTS, RUGS = [], [], [], [], [], [], []


def col(name, x0, x1, y0, y1, z0, z1):
    COLLIDERS.append({"name": name, "min": [r3(min(x0, x1)), r3(y0), r3(min(z0, z1))],
                      "max": [r3(max(x0, x1)), r3(y1), r3(max(z0, z1))]})


def surf(name, room, x0, x1, z0, z1, y):
    SURFACES.append({"name": name, "room": room, "min": [r3(x0), r3(z0)], "max": [r3(x1), r3(z1)],
                     "y": r3(y)})


def furn(name, room, rect, height):
    (x0, z0), (x1, z1) = rect
    FURNITURE.append({"name": name, "room": room, "min": [r3(x0), r3(z0)], "max": [r3(x1), r3(z1)],
                      "height": r3(height)})


def r3(v):
    return round(float(v), 3)


def v3(p):
    return [r3(c) for c in p]


# --- Geometry helpers (all in glTF axes) --------------------------------------

class Part:
    """Accumulates primitives into one bmesh with material indices and UVs."""

    def __init__(self):
        self.bm = bmesh.new()
        self.uv = self.bm.loops.layers.uv.new("UVMap")
        self.mats = []

    def _idx(self, mat):
        if mat not in self.mats:
            self.mats.append(mat)
        return self.mats.index(mat)

    def add(self, bm, mat, uv_scale=1.0):
        """mat: a material name, or a function (face centre, face normal) -> name."""
        bm.normal_update()
        for f in bm.faces:
            f.material_index = self._idx(mat(f.calc_center_median(), f.normal) if callable(mat) else mat)
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
            for loop in f.loops:   # box-projected planar UVs
                c = loop.vert.co / uv_scale
                if abs(n.x) >= max(abs(n.y), abs(n.z)):
                    loop[self.uv].uv = (c.z, c.y)
                elif abs(n.y) >= abs(n.z):
                    loop[self.uv].uv = (c.x, c.z)
                else:
                    loop[self.uv].uv = (c.x, c.y)

    def to_object(self, name, smooth_angle=35, origin=(0.0, 0.0, 0.0)):
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
            me.materials.append(bpy.data.materials[m])
        obj = bpy.data.objects.new(name, me)
        obj.location = (ox, -oz, oy)
        bpy.context.scene.collection.objects.link(obj)
        return obj


def _bevel(bm, edges, offset, segments):
    if edges and offset > 0:
        bmesh.ops.bevel(bm, geom=list(edges), offset=offset, offset_type="OFFSET",
                        segments=min(segments, 2),   # low poly: at most 2 segments profile=0.5, affect="EDGES",
                        clamp_overlap=True)


def box(x0, x1, y0, y1, z0, z1, bevel=0.0, seg=2, edges="all"):
    """Axis box. edges: 'all', 'vertical' (parallel to y), or a predicate on the edge midpoint."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = Vector((min(x0, x1) if v.co.x < 0 else max(x0, x1), y0 if v.co.y < 0 else y1,
                       min(z0, z1) if v.co.z < 0 else max(z0, z1)))
    if edges == "all":
        sel = bm.edges[:]
    elif edges == "vertical":
        sel = [e for e in bm.edges if abs(e.verts[0].co.y - e.verts[1].co.y) > 1e-6]
    else:
        sel = [e for e in bm.edges if edges((e.verts[0].co + e.verts[1].co) / 2)]
    _bevel(bm, sel, bevel, seg)
    return bm


def _axis_point(axis, a, b, t):
    """axis 'x': (t, a, b); 'y': (a, t, b); 'z': (a, b, t)."""
    return {"x": (t, a, b), "y": (a, t, b), "z": (a, b, t)}[axis]


def cyl(axis, ca, cb, t0, t1, r, n=12, r1=None, caps=True, bevel=0.0):
    """Cylinder (or frustum: r at t0, r1 at t1) along an axis; (ca, cb) as in _axis_point."""
    r1 = r if r1 is None else r1
    bm = bmesh.new()
    rings = []
    for t, rr in ((t0, r), (t1, r1)):
        ring = []
        for k in range(n):
            a = 2 * math.pi * k / n
            ring.append(bm.verts.new(_axis_point(axis, ca + rr * math.cos(a), cb + rr * math.sin(a), t)))
        rings.append(ring)
    for k in range(n):
        j = (k + 1) % n
        bm.faces.new((rings[0][k], rings[0][j], rings[1][j], rings[1][k]))
    if caps:
        bm.faces.new(rings[0])
        bm.faces.new(rings[1])
    bm.normal_update()
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    if bevel and caps:
        _bevel(bm, [e for e in bm.edges if len(e.link_faces) == 2 and
                    abs(e.link_faces[0].normal.dot(e.link_faces[1].normal)) < 0.5], bevel, 2)
    return bm


def ellipsoid(c, rx, ry, rz, u=12, v=8, stretch_x=0.0, power=1.0, cut_below=None):
    """UV sphere scaled to radii. power < 1 squares it off (pillow);
    cut_below deletes vertices below that y (before scaling: in -1..1)."""
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=u, v_segments=v, radius=1.0)
    if cut_below is not None:
        bmesh.ops.delete(bm, geom=[vv for vv in bm.verts if vv.co.z < cut_below - 1e-6],
                         context="VERTS")
    for vert in bm.verts:
        x, z, y = vert.co.x, vert.co.y, vert.co.z
        if power != 1.0:
            x = math.copysign(abs(x) ** power, x)
            z = math.copysign(abs(z) ** power, z)
        sx = math.copysign(stretch_x / 2, x) if abs(x) > 1e-6 else 0.0
        vert.co = Vector((c[0] + x * rx + sx, c[1] + y * ry, c[2] + z * rz))
    bm.normal_update()
    return bm


def prism(axis, outline, t0, t1):
    """Extrude a closed 2D outline (a, b) along an axis between t0 and t1."""
    bm = bmesh.new()
    lo = [bm.verts.new(_axis_point(axis, a, b, t0)) for a, b in outline]
    hi = [bm.verts.new(_axis_point(axis, a, b, t1)) for a, b in outline]
    bm.faces.new(lo)
    bm.faces.new(hi)
    n = len(outline)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
    bm.normal_update()
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bm


def rounded_rect(hx, hz, r, n=6, cx=0.0, cz=0.0):
    pts = []
    for qx, qz, a0 in ((hx - r, hz - r, 0.0), (-hx + r, hz - r, 90.0),
                       (-hx + r, -hz + r, 180.0), (hx - r, -hz + r, 270.0)):
        for k in range(n + 1):
            a = math.radians(a0 + 90.0 * k / n)
            pts.append((cx + qx + r * math.cos(a), cz + qz + r * math.sin(a)))
    return pts


def vessel(cx, cz, hx, hz, r, wall, y0, y1, floor_y, n=6, lip=0.0):
    """Open-top hollow rounded box (tub, basket, basin): outer wall y0..y1, rim, inner
    wall down to floor_y, inner floor; lip rounds the rim outward a little."""
    bm = bmesh.new()

    def ring(ihx, ihz, ir, y):
        return [bm.verts.new((x, y, z)) for x, z in rounded_rect(ihx, ihz, max(ir, 0.005), n, cx, cz)]

    rings = [ring(hx - lip, hz - lip, r - lip, y0),
             ring(hx, hz, r, y1 - lip),
             ring(hx - lip, hz - lip, r - lip, y1),
             ring(hx - wall, hz - wall, r - wall, y1),
             ring(hx - wall, hz - wall, r - wall, floor_y)]
    if lip <= 0:
        rings = [rings[0], rings[2], rings[3], rings[4]]
    m = len(rings[0])
    for a, b in zip(rings, rings[1:]):
        for k in range(m):
            j = (k + 1) % m
            bm.faces.new((a[k], a[j], b[j], b[k]))
    bm.faces.new(rings[0])
    bm.faces.new(rings[-1])
    bm.normal_update()
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bm


def band(cx, cz, hx, hz, r, out, inset, y0, y1, n=6):
    """A hollow band round a rounded box's wall (a woven hoop): from `inset` inside the wall's
    outer face to `out` outside it, y0..y1. Open in the middle, unlike prism()."""
    bm = bmesh.new()

    def ring(d, y):
        return [bm.verts.new((x, y, z)) for x, z in rounded_rect(hx + d, hz + d, max(r + d, 0.005), n, cx, cz)]

    rings = [ring(out, y0), ring(out, y1), ring(-inset, y1), ring(-inset, y0)]
    m = len(rings[0])
    for a, b in zip(rings, rings[1:] + rings[:1]):
        for k in range(m):
            j = (k + 1) % m
            bm.faces.new((a[k], a[j], b[j], b[k]))
    bm.normal_update()
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bm


# --- Rooms and walls --------------------------------------------------------------

def room_at(x, z):
    for name, (((x0, z0), (x1, z1)), _) in ROOMS.items():
        if x0 - 1e-4 <= x <= x1 + 1e-4 and z0 - 1e-4 <= z <= z1 + 1e-4:
            return name
    return None


def wall_mat(c, n):
    if abs(n.y) > 0.5:
        return "wall_outside"
    p = c + n * 0.05
    room = room_at(p.x, p.z)
    return "wall_" + room if room else "wall_outside"


def run_box(axis, s0, s1, t0, t1, y0, y1, **kw):
    if axis == "x":
        return box(s0, s1, y0, y1, t0, t1, **kw)
    return box(t0, t1, y0, y1, s0, s1, **kw)


def face_point(face, d, y, s):
    """Point d metres in from a wall face, at height y and position s along it."""
    _, axis, c, sign, _, _ = face
    return (s, y, c + sign * d) if axis == "x" else (c + sign * d, y, s)


def face_box(face, d0, d1, y0, y1, s0, s1, **kw):
    (x0, _, z0), (x1, _, z1) = face_point(face, d0, 0, s0), face_point(face, d1, 0, s1)
    return box(x0, x1, y0, y1, z0, z1, **kw)


def face_strip(face, profile, s0, s1):
    """Extrude a closed (d, y) profile along a wall face from s0 to s1."""
    bm = bmesh.new()
    a = [bm.verts.new(face_point(face, d, y, s0)) for d, y in profile]
    b = [bm.verts.new(face_point(face, d, y, s1)) for d, y in profile]
    bm.faces.new(a)
    bm.faces.new(b)
    n = len(profile)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((a[i], a[j], b[j], b[i]))
    bm.normal_update()
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bm


def find_face(wall, coord):
    for f in FACES:
        if f[0] == wall and abs(f[2] - coord) < 1e-6:
            return f
    raise KeyError((wall, coord))


def free_spans(s0, s1, skip):
    spans = [(s0, s1)]
    for a, b in skip:
        nxt = []
        for p, q in spans:
            if b <= p or a >= q:
                nxt.append((p, q))
                continue
            if a > p:
                nxt.append((p, a))
            if b < q:
                nxt.append((b, q))
        spans = nxt
    return [(p, q) for p, q in spans if q - p > 0.01]


ROOM_SPLITS = (2.34, 2.46, 5.94, 6.06, 8.94, 9.06)


def split_at_rooms(spans):
    """Cuts wall spans at the room boundaries so each face gets its room's paint."""
    out = []
    for a, b in spans:
        cuts = [a] + [c for c in ROOM_SPLITS if a + 0.01 < c < b - 0.01] + [b]
        out += list(zip(cuts, cuts[1:]))
    return out


def cabinet_spot(c):
    coll, room, wall, coord, sign, s, drawers = c
    face = find_face(wall, coord)
    axis = face[1]
    cd, zd = CAB_D / 2, CAB_ZONE_D
    if axis == "x":
        pos = (s, 0.0, coord + sign * cd)
        yaw = 0.0 if sign > 0 else math.pi
        zone = ((s - CAB_ZONE_W / 2, min(coord, coord + sign * zd)),
                (s + CAB_ZONE_W / 2, max(coord, coord + sign * zd)))
    else:
        pos = (coord + sign * cd, 0.0, s)
        yaw = math.pi / 2 if sign > 0 else -math.pi / 2
        zone = ((min(coord, coord + sign * zd), s - CAB_ZONE_W / 2),
                (max(coord, coord + sign * zd), s + CAB_ZONE_W / 2))
    return pos, yaw, zone


def all_zones():
    zones = [cabinet_spot(c)[2] for c in CABINETS]
    zones.append(WASHER_ZONE)
    return zones


def make_walls():
    p = Part()
    for name, axis, (s0, s1), (t0, t1), holes in WALLS:
        hs = sorted(holes)
        for a, b in split_at_rooms(free_spans(s0, s1, [(h[0], h[1]) for h in hs])):
            p.add(run_box(axis, a, b, t0, t1, 0.0, H), wall_mat)
            col("Wall" + name, *((a, b, 0.0, H, t0, t1) if axis == "x" else (t0, t1, 0.0, H, a, b)))
        for a, b, y0, y1, kind, _ in hs:
            pieces = [(y1, H)] + ([(0.0, y0)] if y0 > 0 else [])
            for ya, yb in pieces:
                p.add(run_box(axis, a, b, t0, t1, ya, yb), wall_mat)
                col("Wall" + name, *((a, b, ya, yb, t0, t1) if axis == "x" else (t0, t1, ya, yb, a, b)))
    return p.to_object("Walls")


def make_floor():
    p = Part()
    # Wooden slab under the whole L (and under the walls), tiles laid on top in the
    # kitchen and the bathroom.
    p.add(box(-EXT_T, 8.0 + EXT_T, -FLOOR_T, 0.0, -EXT_T, 5.94), "wood", uv_scale=2.0)
    p.add(box(-EXT_T, 5.4 + EXT_T, -FLOOR_T, 0.0, 5.94, 13.0 + EXT_T), "wood", uv_scale=2.0)
    (kx0, kz0), (kx1, kz1) = ROOMS["kitchen"][0]
    p.add(box(kx0, kx1, -0.01, 0.003, kz0, kz1), "kitchen_tile", uv_scale=1.2)
    (bx0, bz0), (bx1, bz1) = ROOMS["bathroom"][0]
    p.add(box(bx0, bx1 + 0.0, -0.01, 0.003, bz0, bz1), "bath_tile", uv_scale=0.6)
    col("Floor", -EXT_T, 8.0 + EXT_T, -FLOOR_T, 0.0, -EXT_T, 5.94)
    col("Floor", -EXT_T, 5.4 + EXT_T, -FLOOR_T, 0.0, 5.94, 13.0 + EXT_T)
    return p.to_object("Floor")


def make_ceiling():
    p = Part()
    p.add(box(-EXT_T, 8.0 + EXT_T, H, H + FLOOR_T, -EXT_T, 5.94), "ceiling")
    p.add(box(-EXT_T, 5.4 + EXT_T, H, H + FLOOR_T, 5.94, 13.0 + EXT_T), "ceiling")
    col("Ceiling", -EXT_T, 8.0 + EXT_T, H, H + FLOOR_T, -EXT_T, 5.94)
    col("Ceiling", -EXT_T, 5.4 + EXT_T, H, H + FLOOR_T, 5.94, 13.0 + EXT_T)
    return p.to_object("Ceiling")


SKIRTING = [(0.0, 0.0), (0.022, 0.0), (0.022, 0.095), (0.017, 0.112), (0.008, 0.12), (0.0, 0.12)]


def crown_profile():
    pts = [(0.0, H - 0.08), (0.01, H - 0.08), (0.01, H - 0.068)]
    cx, cy, r = 0.06, H - 0.068, 0.05
    for k in range(1, 6):
        a = math.pi - (math.pi / 2) * k / 6
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    pts += [(0.06, H - 0.018), (0.06, H), (0.0, H)]
    return pts


def face_skips(face):
    """Spans along a face where floor trim must stop: doorways and clear zones."""
    wall, axis, c, sign, s0, s1 = face
    skips = []
    for name, _, _, _, holes in WALLS:
        if name != wall:
            continue
        for a, b, y0, _, kind, _ in holes:
            if y0 <= 0:
                skips.append((a - CASING_W, b + CASING_W))
    for (x0, z0), (x1, z1) in all_zones():
        if axis == "x" and z0 - 0.03 <= c <= z1 + 0.03:
            skips.append((x0, x1))
        if axis == "z" and x0 - 0.03 <= c <= x1 + 0.03:
            skips.append((z0, z1))
    # Behind the kitchen counter run and the fridge (hidden anyway).
    if wall == "N":
        skips.append((0.0, COUNTER[1]))
    return skips


def make_trim():
    p = Part()
    crown = crown_profile()
    for face in FACES:
        s0, s1 = face[4], face[5]
        for a, b in free_spans(s0, s1, face_skips(face)):
            p.add(face_strip(face, SKIRTING, a, b), "trim")
        p.add(face_strip(face, crown, s0, s1), "trim")
    # Casings round the open doorways (both faces) and the reveal lining.
    for name, axis, _, (t0, t1), holes in WALLS:
        for a, b, y0, y1, kind, hname in holes:
            if kind == "window":
                continue
            faces = [f for f in FACES if f[0] == name]
            for f in faces:
                kw = dict(bevel=0.008, seg=1)
                p.add(face_box(f, -0.004, 0.018, 0.0, y1 + CASING_W, a - CASING_W, a + 0.01, **kw), "trim")
                p.add(face_box(f, -0.004, 0.018, 0.0, y1 + CASING_W, b - 0.01, b + CASING_W, **kw), "trim")
                p.add(face_box(f, -0.004, 0.018, y1 - 0.01, y1 + CASING_W, a - CASING_W, b + CASING_W,
                               **kw), "trim")
            lin = 0.015
            p.add(run_box(axis, a, a + lin, t0, t1, 0.0, y1), "trim")
            p.add(run_box(axis, b - lin, b, t0, t1, 0.0, y1), "trim")
            p.add(run_box(axis, a, b, t0, t1, y1 - lin, y1), "trim")
    return p.to_object("Trim")


def window_parts():
    """All windows: frames, sills, curtains (one mesh) and glass (one mesh)."""
    f, g = Part(), Part()
    out = []
    curtains = {"LivingNorth": "curtain", "LivingEast": "curtain", "LivingSouth": "curtain",
                "Bedroom": "curtain_bed"}
    for name, axis, _, (t0, t1), holes in WALLS:
        for w0, w1, sill, head, kind, wname in holes:
            if kind != "window":
                continue
            face = [fc for fc in FACES if fc[0] == name][0]
            room = room_at(*[face_point(face, 0.3, 0, (w0 + w1) / 2)[i] for i in (0, 2)])
            out.append((wname, room, name, face, w0, w1, sill, head))
            bar = 0.06
            fd0, fd1 = -0.14, -0.07
            sill_top = sill + 0.035
            f.add(face_box(face, -EXT_T, 0.05, sill, sill_top, w0 - 0.05, w1 + 0.05, bevel=0.01, seg=2),
                  "trim")
            kw = dict(bevel=0.008, seg=1)
            f.add(face_box(face, fd0, fd1, sill_top, head, w0, w0 + bar, **kw), "trim")
            f.add(face_box(face, fd0, fd1, sill_top, head, w1 - bar, w1, **kw), "trim")
            f.add(face_box(face, fd0, fd1, sill_top, sill_top + bar, w0 + bar, w1 - bar, **kw), "trim")
            f.add(face_box(face, fd0, fd1, head - bar, head, w0 + bar, w1 - bar, **kw), "trim")
            if w1 - w0 > 1.0:
                wc = (w0 + w1) / 2
                f.add(face_box(face, fd0 + 0.01, fd1 - 0.01, sill_top + bar, head - bar, wc - 0.025,
                               wc + 0.025, **kw), "trim")
            # Casing round the opening on the room side.
            for a, b, y0, y1 in ((w0 - 0.06, w0, sill_top, head + 0.06), (w1, w1 + 0.06, sill_top, head + 0.06),
                                 (w0 - 0.06, w1 + 0.06, head, head + 0.06)):
                f.add(face_box(face, -0.004, 0.016, y0, y1, a, b, **kw), "trim")
            g.add(face_box(face, -0.105, -0.095, sill_top + bar - 0.01, head - bar + 0.01, w0 + bar - 0.01,
                           w1 - bar + 0.01), "frosted" if wname == "Bathroom" else "glass")
            if wname in curtains:
                rod_y, rod_d = head + 0.17, 0.1
                r0, r1 = w0 - 0.25, w1 + 0.25
                pa, pb = face_point(face, rod_d, rod_y, r0), face_point(face, rod_d, rod_y, r1)
                if axis == "x":
                    f.add(cyl("x", rod_y, pa[2], r0, r1, 0.014, n=10), "dark_wood")
                else:
                    f.add(cyl("z", pa[0], rod_y, r0, r1, 0.014, n=10), "dark_wood")
                for s in (r0, r1):
                    f.add(ellipsoid(face_point(face, rod_d, rod_y, s), 0.026, 0.026, 0.026, u=10, v=6),
                          "dark_wood")
                for s in (r0 + 0.08, r1 - 0.08):
                    f.add(face_box(face, 0.0, rod_d, rod_y - 0.008, rod_y + 0.008, s - 0.008, s + 0.008),
                          "dark_wood")
                cw, folds, n = 0.36, 3, 12
                for a in (w0 - 0.22, w1 + 0.22 - cw):
                    b = a + cw
                    front, back = [], []
                    for k in range(n + 1):
                        s = a + (b - a) * k / n
                        d = 0.065 + 0.022 * math.cos(2 * math.pi * folds * k / n)
                        front.append((d + 0.011, s))
                        back.append((d - 0.011, s))
                    outline = front + list(reversed(back))
                    pts = [face_point(face, d, 0, s) for d, s in outline]
                    outline_xz = [(q[0], q[2]) for q in pts]
                    f.add(prism("y", outline_xz, max(sill - 0.1, 0.5), rod_y + 0.01), curtains[wname])
    return f.to_object("Windows"), g.to_object("Glass"), out


def make_front_door():
    p = Part()
    face = find_face("W", 0.0)
    a, b = 6.5, 7.5
    lz0, lz1 = -0.13, -0.08          # leaf inside the reveal (d < 0 is outward)
    p.add(face_box(face, lz0, lz1, 0.01, DOOR_H - 0.015, a + 0.017, b - 0.017, bevel=0.006, seg=2),
          "front_door")
    for y0, y1 in ((0.18, 0.95), (1.1, 1.9)):
        p.add(face_box(face, lz1 - 0.004, lz1 + 0.012, y0, y1, a + 0.13, b - 0.13, bevel=0.01, seg=2),
              "front_door")
    kx = b - 0.12
    for d0, d1, r in ((lz1, lz1 + 0.01, 0.03), (lz1, lz1 + 0.05, 0.011)):
        p0, p1 = face_point(face, d0, 1.0, kx), face_point(face, d1, 1.0, kx)
        p.add(cyl("x", 1.0, kx, p0[0], p1[0], r, n=12), "brass")
    p.add(ellipsoid(face_point(face, lz1 + 0.065, 1.0, kx), 0.026, 0.032, 0.032, u=12, v=8), "brass")
    col("FrontDoor", -0.13, -0.08, 0.0, DOOR_H, a, b)
    return p.to_object("FrontDoor")


# --- Kitchen ----------------------------------------------------------------------

def make_fridge():
    p = Part()
    (x0, z0), (x1, z1) = FRIDGE
    t = 0.04
    front = z1 - 0.005
    kw = dict(bevel=0.02, seg=3)
    # Hollow body: back, sides, top, bottom; open front.
    for bx in ((x0, x0 + t), (x1 - t, x1)):
        p.add(box(*bx, 0.04, FRIDGE_H, z0 + 0.03, front, **kw), "fridge")
        col("Fridge", *bx, 0.04, FRIDGE_H, z0 + 0.03, front)
    p.add(box(x0, x1, FRIDGE_H - 0.06, FRIDGE_H, z0 + 0.03, front, bevel=0.04, seg=4), "fridge")
    p.add(box(x0, x1, 0.04, 0.1, z0 + 0.03, front, **kw), "fridge")
    p.add(box(x0, x1, 0.04, FRIDGE_H, z0 + 0.03, z0 + 0.07, **kw), "fridge")
    p.add(box(x0 + 0.05, x1 - 0.05, 0.0, 0.04, z0 + 0.08, front - 0.05), "dark_wood")
    col("Fridge", x0, x1, FRIDGE_H - 0.06, FRIDGE_H, z0, front)
    col("Fridge", x0, x1, 0.0, 0.1, z0, front)
    col("Fridge", x0, x1, 0.04, FRIDGE_H, z0, z0 + 0.07)
    # Interior liner and two shelves.
    p.add(box(x0 + t, x1 - t, 0.1, FRIDGE_H - 0.06, z0 + 0.07, z0 + 0.075), "carcass_in")
    shelves = [0.72, 1.24]
    for sy in shelves:
        p.add(box(x0 + t, x1 - t, sy - 0.012, sy, z0 + 0.075, front - 0.06, bevel=0.004, seg=1), "glass")
        col("FridgeShelf", x0 + t, x1 - t, sy - 0.012, sy, z0 + 0.075, front - 0.06)
    body = p.to_object("Fridge")
    # Door: rounded slab, chrome handle; hinge on its west edge.
    d = Part()
    dz0, dz1 = front, front + 0.07
    hinge = (x0 + 0.005, 0.04, dz0)
    d.add(box(x0 + 0.005, x1, 0.06, FRIDGE_H - 0.01, dz0, dz1, bevel=0.03, seg=4), "fridge")
    d.add(box(x0 + 0.04, x1 - 0.035, 0.12, FRIDGE_H - 0.07, dz0 - 0.03, dz0, bevel=0.01, seg=2), "carcass_in")
    hx = x1 - 0.06
    d.add(cyl("y", hx, dz1 + 0.04, 0.95, 1.35, 0.014, n=10), "steel")
    for hy in (0.95, 1.35):
        d.add(cyl("z", hx, hy, dz1, dz1 + 0.05, 0.012, n=8), "steel")
    door = d.to_object("FridgeDoor", origin=hinge)
    OPENABLES.append({
        "name": "Fridge", "room": "kitchen", "kind": "fridge",
        "doors": [{"node": "FridgeDoor", "hinge": v3(hinge), "axis": [0, 1, 0], "open_deg": -100,
                   "min": v3((0.0, 0.02, -0.03)), "max": v3((x1 - x0 - 0.005, FRIDGE_H - 0.05, 0.12))}],
        "interior": {"min": v3((x0 + t, 0.1, z0 + 0.075)), "max": v3((x1 - t, FRIDGE_H - 0.06, front - 0.035))},
        "shelves_y": shelves,
    })
    furn("Fridge", "kitchen", ((x0, z0), (x1, dz1 + 0.09)), FRIDGE_H)
    surf("FridgeTop", "kitchen", x0, x1, z0, front, FRIDGE_H)
    return [body, door]


def cupboard_door(name, x0, x1, hinge_left, y0, y1, z0, z1):
    d = Part()
    d.add(box(x0, x1, y0, y1, z0, z1, bevel=0.012, seg=2), "cupboard")
    # Shaker frame.
    for a, b, c0, c1 in ((x0 + 0.05, x1 - 0.05, y0 + 0.05, y0 + 0.07), (x0 + 0.05, x1 - 0.05, y1 - 0.07, y1 - 0.05)):
        d.add(box(a, b, c0, c1, z1 - 0.004, z1 + 0.006, bevel=0.003, seg=1), "cupboard")
    for a, b in ((x0 + 0.05, x0 + 0.07), (x1 - 0.07, x1 - 0.05)):
        d.add(box(a, b, y0 + 0.05, y1 - 0.05, z1 - 0.004, z1 + 0.006, bevel=0.003, seg=1), "cupboard")
    kx = x1 - 0.045 if hinge_left else x0 + 0.045
    ky = y1 - 0.11
    d.add(cyl("z", kx, ky, z1, z1 + 0.02, 0.008, n=8), "brass")
    d.add(ellipsoid((kx, ky, z1 + 0.028), 0.017, 0.017, 0.012, u=10, v=6), "brass")
    hx = x0 if hinge_left else x1
    hinge = (hx, y0, z0)
    obj = d.to_object(name, origin=hinge)
    door = {"node": name, "hinge": v3(hinge), "axis": [0, 1, 0], "open_deg": -100 if hinge_left else 100,
            "min": v3((x0 - hx, 0.0, 0.0)), "max": v3((x1 - hx, y1 - y0, z1 - z0 + 0.04))}
    return obj, door


def make_counter():
    """Counter run along the north wall: cupboard A, the oven bay, cupboard B (two doors).
    Worktop with a hob over the oven and a sink, tiled splashback, wall shelf."""
    p = Part()
    xa, xb = COUNTER
    d0, d1 = 0.0, 0.58               # carcass depth; doors in front
    top0, top1 = COUNTER_TOP - 0.04, COUNTER_TOP
    t = 0.02
    bays = [(xa, 1.4), (1.4, 2.0), (2.0, xb)]
    # Plinth (recessed), sides and dividers, bottoms, back.
    p.add(box(xa + 0.01, xb - 0.01, 0.0, 0.1, d0 + 0.02, d1 - 0.06), "dark_wood")
    col("CounterPlinth", xa, xb, 0.0, 0.1, d0, d1 - 0.06)
    for x in (xa, 1.4 - t / 2, 2.0 - t / 2, xb - t):
        p.add(box(x, x + t, 0.1, top0, d0, d1), "cupboard")
        col("CounterSide", x, x + t, 0.1, top0, d0, d1)
    for a, b in bays:
        p.add(box(a, b, 0.1, 0.12, d0, d1), "carcass_in")
        p.add(box(a, b, 0.1, top0, d0, d0 + 0.015), "carcass_in")
        col("CounterBottom", a, b, 0.1, 0.12, d0, d1)
        col("CounterBack", a, b, 0.1, top0, d0, d0 + 0.015)
    shelf_y = 0.48
    for a, b in (bays[0], bays[2]):
        p.add(box(a + t / 2, b - t / 2, shelf_y - 0.018, shelf_y, d0 + 0.015, d1 - 0.04), "carcass_in")
        col("CupboardShelf", a + t / 2, b - t / 2, shelf_y - 0.018, shelf_y, d0 + 0.015, d1 - 0.04)
    # Worktop.
    p.add(box(xa - 0.02, xb + 0.02, top0, top1, d0, d1 + 0.04, bevel=0.012, seg=2,
              edges=lambda c: c.z > d1), "worktop")
    col("Worktop", xa - 0.02, xb + 0.02, top0, top1, d0, d1 + 0.04)
    # Oven body in the middle bay: a hollow enamel box open at the front (the door covers it),
    # its cavity lined dark, with a wire rack at the shelf level and an oven light at the back.
    ox0, ox1 = 1.4 + t / 2, 2.0 - t / 2
    cx0, cx1, cy0, cy1, cz0 = ox0 + 0.04, ox1 - 0.04, 0.18, 0.68, d0 + 0.05   # the cavity
    front = lambda c: c.z > d1 - 0.01
    p.add(box(ox0, cx0, 0.12, top0, d0 + 0.015, d1, bevel=0.006, seg=1, edges=front), "enamel")
    p.add(box(cx1, ox1, 0.12, top0, d0 + 0.015, d1, bevel=0.006, seg=1, edges=front), "enamel")
    p.add(box(cx0, cx1, 0.12, cy0, d0 + 0.015, d1, bevel=0.006, seg=1, edges=front), "enamel")
    p.add(box(cx0, cx1, cy1, top0, d0 + 0.015, d1, bevel=0.006, seg=1, edges=front), "enamel")
    p.add(box(cx0, cx1, cy0, cy1, d0 + 0.015, cz0), "enamel")
    lz1, lt = d1 - 0.006, 0.003      # dark liner, set back from the enamel front
    p.add(box(cx0, cx0 + lt, cy0, cy1, cz0, lz1), "oven_in")
    p.add(box(cx1 - lt, cx1, cy0, cy1, cz0, lz1), "oven_in")
    p.add(box(cx0, cx1, cy0, cy0 + lt, cz0, lz1), "oven_in")
    p.add(box(cx0, cx1, cy1 - lt, cy1, cz0, lz1), "oven_in")
    p.add(box(cx0, cx1, cy0, cy1, cz0, cz0 + lt), "oven_in")
    # Rack runners on the side walls, and the wire rack on them (its top is the shelf level).
    rack_y, wr = 0.4, 0.003
    for a, b in ((cx0 + lt, cx0 + 0.012), (cx1 - 0.012, cx1 - lt)):
        p.add(box(a, b, rack_y - 0.016, rack_y - 0.008, cz0 + lt, lz1 - 0.01), "steel")
    rz0, rz1 = cz0 + 0.02, lz1 - 0.02
    for rz in (rz0, rz1):
        p.add(cyl("x", rack_y - wr, rz, cx0 + lt, cx1 - lt, wr * 1.5, n=6), "steel")
    nrods = 12
    for k in range(nrods):
        rx = cx0 + 0.02 + k * (cx1 - cx0 - 0.04) / (nrods - 1)
        p.add(cyl("z", rx, rack_y - wr, rz0, rz1, wr, n=6), "steel")
    # Oven light: a steel-rimmed glowing bulb high on the right wall, near enough the front to
    # be seen past the oven's top from a standing or crouching eye.
    ly, lz = cy1 - 0.12, d1 - 0.09
    p.add(cyl("x", ly, lz, cx1 - lt - 0.01, cx1 - lt, 0.026, n=12), "steel")
    p.add(ellipsoid((cx1 - lt - 0.01, ly, lz), 0.013, 0.019, 0.019, u=10, v=6), "bulb")
    for k in range(4):
        kx = ox0 + 0.08 + k * (ox1 - ox0 - 0.16) / 3
        p.add(cyl("z", kx, 0.79, d1, d1 + 0.025, 0.018, n=12), "trim")
    # Hob on the worktop: four burners.
    for bx in (1.55, 1.85):
        for bz in (0.17, 0.43):
            p.add(cyl("y", bx, bz, top1, top1 + 0.01, 0.085 if bz < 0.3 else 0.07, n=16), "hob")
            p.add(cyl("y", bx, bz, top1 + 0.01, top1 + 0.018, 0.035, n=12), "steel")
    # Sink: a steel rim with a dark basin floor, and a brass swan-neck tap.
    sx, sz = 2.75, 0.32
    p.add(vessel(sx, sz, 0.27, 0.2, 0.05, 0.025, top1 - 0.001, top1 + 0.02, top1 + 0.002, n=4), "steel")
    p.add(cyl("y", sx, 0.07, top1, top1 + 0.3, 0.014, n=10), "brass")
    p.add(cyl("z", sx, top1 + 0.3, 0.06, 0.2, 0.012, n=10), "brass")
    p.add(cyl("y", sx, 0.2, top1 + 0.25, top1 + 0.3, 0.012, n=10), "brass")
    p.add(ellipsoid((sx, top1 + 0.3, 0.07), 0.016, 0.016, 0.016, u=8, v=6), "brass")
    # Tiled splashback strip up to the window sill height.
    p.add(box(xa, xb, top1, 1.1, 0.0, 0.012), "wall_tile")
    surf("Worktop", "kitchen", xa, xb, d0 + 0.05, d1, top1)
    furn("Counter", "kitchen", ((xa, d0), (xb, d1 + 0.04)), top1)
    body = p.to_object("Counter")

    objs = [body]
    doors_a, doors_b = [], []
    dz0, dz1 = d1, d1 + 0.022
    o, dr = cupboard_door("CupboardADoor", xa + 0.005, 1.4 - 0.005, True, 0.12, top0 - 0.005, dz0, dz1)
    objs.append(o)
    doors_a.append(dr)
    o, dr = cupboard_door("CupboardBDoorL", 2.0 + 0.005, (2.0 + xb) / 2 - 0.003, True, 0.12, top0 - 0.005,
                          dz0, dz1)
    objs.append(o)
    doors_b.append(dr)
    o, dr = cupboard_door("CupboardBDoorR", (2.0 + xb) / 2 + 0.003, xb - 0.005, False, 0.12, top0 - 0.005,
                          dz0, dz1)
    objs.append(o)
    doors_b.append(dr)
    OPENABLES.append({"name": "CupboardA", "room": "kitchen", "kind": "cupboard", "doors": doors_a,
                      "interior": {"min": v3((xa + t, 0.12, d0 + 0.015)), "max": v3((1.4 - t / 2, top0, d1))},
                      "shelves_y": [shelf_y]})
    OPENABLES.append({"name": "CupboardB", "room": "kitchen", "kind": "cupboard", "doors": doors_b,
                      "interior": {"min": v3((2.0 + t / 2, 0.12, d0 + 0.015)), "max": v3((xb - t, top0, d1))},
                      "shelves_y": [shelf_y]})

    # Oven door: hinged along its bottom edge, falls open towards the player.
    od = Part()
    oy0, oy1 = 0.13, 0.72
    od.add(box(ox0 + 0.005, ox1 - 0.005, oy0, oy1, dz0, dz1 + 0.01, bevel=0.012, seg=2), "enamel")
    od.add(box(ox0 + 0.07, ox1 - 0.07, 0.3, 0.6, dz1 + 0.009, dz1 + 0.013), "oven_in")
    # Its inner face, dark like the cavity: what shows when it lies open.
    od.add(box(cx0 + 0.01, cx1 - 0.01, cy0 + 0.01, cy1 - 0.01, dz0 - 0.002, dz0 + 0.001), "oven_in")
    od.add(cyl("x", 0.66, dz1 + 0.05, ox0 + 0.07, ox1 - 0.07, 0.011, n=10), "steel")
    for hx in (ox0 + 0.08, ox1 - 0.08):
        od.add(cyl("z", hx, 0.66, dz1 + 0.01, dz1 + 0.05, 0.009, n=8), "steel")
    hinge = (ox0, oy0, dz0)
    objs.append(od.to_object("OvenDoor", origin=hinge))
    OPENABLES.append({
        "name": "Oven", "room": "kitchen", "kind": "oven",
        "doors": [{"node": "OvenDoor", "hinge": v3(hinge), "axis": [1, 0, 0], "open_deg": 85,
                   "min": v3((0.0, 0.0, 0.0)), "max": v3((ox1 - ox0, oy1 - oy0, 0.08))}],
        "interior": {"min": v3((cx0, cy0, cz0)), "max": v3((cx1, cy1, d1 - 0.01))},
        "shelves_y": [rack_y],
    })
    # The hollow's walls. The wire rack has no collider (the crosshair reaches through it);
    # the bake rests Socks on it as a shelf (mess_physics.gd).
    col("OvenTop", ox0, ox1, cy1, top0, d0, d1)
    col("OvenFloor", ox0, ox1, 0.12, cy0, d0, d1)
    col("OvenSide", ox0, cx0, cy0, cy1, d0, d1)
    col("OvenSide", cx1, ox1, cy0, cy1, d0, d1)
    col("OvenBack", cx0, cx1, cy0, cy1, d0, cz0)
    return objs


def make_kitchen_shelf():
    """Open wall shelf over cupboard A with jars and a pot plant."""
    p = Part()
    x0, x1, y = 0.95, 1.95, 1.55
    p.add(box(x0, x1, y - 0.035, y, 0.0, 0.24, bevel=0.01, seg=2), "oak")
    for bx in (x0 + 0.12, x1 - 0.12):
        p.add(box(bx - 0.015, bx + 0.015, y - 0.2, y - 0.035, 0.0, 0.03), "dark_wood")
        p.add(box(bx - 0.015, bx + 0.015, y - 0.065, y - 0.035, 0.0, 0.2), "dark_wood")
    for k, jx in enumerate((1.1, 1.27, 1.42)):
        h = (0.18, 0.14, 0.2)[k]
        p.add(cyl("y", jx, 0.12, y, y + h, 0.055, n=14), "jar")
        p.add(cyl("y", jx, 0.12, y + h, y + h + 0.03, 0.058, n=14, bevel=0.005), "dark_wood")
    p.add(cyl("y", 1.75, 0.12, y, y + 0.11, 0.06, n=14, r1=0.075), "terracotta")
    for k in range(6):
        a = 2 * math.pi * k / 6
        p.add(ellipsoid((1.75 + 0.06 * math.cos(a), y + 0.16, 0.12 + 0.05 * math.sin(a)), 0.05, 0.06, 0.035,
                        u=8, v=6), "leaf")
    col("KitchenShelf", x0, x1, y - 0.035, y, 0.0, 0.24)
    surf("KitchenShelf", "kitchen", x0, 1.0, 0.03, 0.22, y)
    return p.to_object("KitchenShelf")


def make_table_and_chairs():
    t = Part()
    (x0, z0), (x1, z1) = TABLE
    top = TABLE_TOP
    t.add(box(x0, x1, top - 0.045, top, z0, z1, bevel=0.018, seg=3), "oak")
    t.add(box(x0 + 0.08, x1 - 0.08, top - 0.12, top - 0.045, z0 + 0.08, z1 - 0.08), "oak")
    for lx in (x0 + 0.1, x1 - 0.1):
        for lz in (z0 + 0.1, z1 - 0.1):
            t.add(cyl("y", lx, lz, 0.0, top - 0.045, 0.024, n=10, r1=0.034), "oak")
            col("TableLeg", lx - 0.03, lx + 0.03, 0.0, top - 0.12, lz - 0.03, lz + 0.03)
    # Fruit bowl.
    bx, bz = (x0 + x1) / 2 + 0.2, (z0 + z1) / 2
    t.add(ellipsoid((bx, top + 0.06, bz), 0.15, 0.07, 0.15, u=16, v=8, cut_below=-0.0001), "porcelain")
    t.add(ellipsoid((bx, top + 0.04, bz), 0.15, 0.06, 0.15, u=16, v=8), "porcelain")
    for k, (fx, fz, m) in enumerate(((-0.05, -0.03, "orange"), (0.05, 0.02, "orange"), (0.0, 0.06, "apple"),
                                      (0.02, -0.07, "apple"))):
        t.add(ellipsoid((bx + fx, top + 0.12 + 0.01 * k, bz + fz), 0.042, 0.04, 0.042, u=10, v=6), m)
    col("TableTop", x0, x1, top - 0.12, top, z0, z1)
    surf("KitchenTable", "kitchen", x0, x1, z0, z1, top)
    CRAWL.append({"name": "UnderKitchenTable", "room": "kitchen", "min": [r3(x0 + 0.05), r3(z0 + 0.05)],
                  "max": [r3(x1 - 0.05), r3(z1 - 0.05)], "y_max": r3(top - 0.12)})
    furn("KitchenTable", "kitchen", TABLE, top)
    table = t.to_object("KitchenTable")

    c = Part()
    seat_y, w = 0.45, 0.42
    for cx, cz, facing in ((1.78, 2.58, 1), (2.42, 2.58, 1), (1.78, 4.02, -1), (2.42, 4.02, -1)):
        x0c, x1c = cx - w / 2, cx + w / 2
        z0c, z1c = cz - w / 2, cz + w / 2
        c.add(box(x0c, x1c, seat_y - 0.04, seat_y, z0c, z1c, bevel=0.015, seg=2), "oak")
        c.add(box(x0c + 0.03, x1c - 0.03, seat_y, seat_y + 0.035, z0c + 0.03, z1c - 0.03, bevel=0.015, seg=3),
              "seat_pad")
        back_z = z0c + 0.02 if facing > 0 else z1c - 0.02
        for lx in (x0c + 0.04, x1c - 0.04):
            for lz in (z0c + 0.04, z1c - 0.04):
                top_y = 0.92 if abs(lz - back_z) < 0.03 else seat_y - 0.04
                c.add(cyl("y", lx, lz, 0.0, top_y, 0.018, n=8, r1=0.016), "oak")
                col("ChairLeg", lx - 0.02, lx + 0.02, 0.0, seat_y, lz - 0.02, lz + 0.02)
        for ry in (0.68, 0.84):
            c.add(box(x0c + 0.03, x1c - 0.03, ry, ry + 0.07, back_z - 0.015, back_z + 0.015, bevel=0.01,
                      seg=2), "oak")
        col("ChairSeat", x0c, x1c, seat_y - 0.04, seat_y + 0.035, z0c, z1c)
        col("ChairBack", x0c, x1c, seat_y, 0.92, back_z - 0.02, back_z + 0.02)
        surf("ChairSeat", "kitchen", x0c + 0.03, x1c - 0.03, z0c + 0.05, z1c - 0.03, seat_y + 0.035)
        furn("Chair", "kitchen", ((x0c, z0c), (x1c, z1c)), 0.92)
    return [table, c.to_object("Chairs")]


# --- Living room ------------------------------------------------------------------

def make_sofa():
    p = Part()
    (x0, z0), (x1, z1) = SOFA
    gap = SOFA_GAP
    arm = 0.2
    back0 = z1 - 0.24
    # Feet.
    for fx in (x0 + 0.1, x1 - 0.1):
        for fz in (z0 + 0.1, z1 - 0.1):
            p.add(cyl("y", fx, fz, 0.0, gap + 0.01, 0.022, n=10, r1=0.03), "dark_wood")
            col("SofaFoot", fx - 0.03, fx + 0.03, 0.0, gap, fz - 0.03, fz + 0.03)
    # Base frame, arms and back.
    p.add(box(x0 + 0.02, x1 - 0.02, gap, gap + 0.2, z0 + 0.02, z1, bevel=0.05, seg=3), "sofa")
    for ax in ((x0, x0 + arm), (x1 - arm, x1)):
        p.add(box(*ax, gap, 0.68, z0, z1, bevel=0.08, seg=4), "sofa")
        col("SofaArm", *ax, gap, 0.68, z0, z1)
    p.add(box(x0 + 0.05, x1 - 0.05, gap + 0.1, 0.92, back0, z1, bevel=0.09, seg=4), "sofa")
    # Seat cushions (two) and back cushions.
    seat_top = 0.54
    xm = (x0 + x1) / 2
    for a, b in ((x0 + arm, xm - 0.005), (xm + 0.005, x1 - arm)):
        p.add(box(a, b, gap + 0.18, seat_top, z0 + 0.03, back0 + 0.02, bevel=0.06, seg=4), "sofa")
        p.add(box(a + 0.02, b - 0.02, seat_top - 0.05, 0.86, back0 - 0.16, back0 + 0.04, bevel=0.08, seg=4), "sofa")
    # Throw pillows.
    p.add(ellipsoid((x0 + arm + 0.22, 0.72, back0 - 0.2), 0.2, 0.17, 0.07, u=14, v=8, power=0.55), "cushion_a")
    p.add(ellipsoid((x1 - arm - 0.22, 0.72, back0 - 0.2), 0.2, 0.17, 0.07, u=14, v=8, power=0.55), "cushion_b")
    col("SofaBase", x0, x1, gap, seat_top, z0, z1)
    col("SofaBack", x0, x1, seat_top, 0.92, back0, z1)
    surf("SofaSeat", "living", x0 + arm, x1 - arm, z0 + 0.05, back0 - 0.18, seat_top)
    CRAWL.append({"name": "UnderSofa", "room": "living", "min": [r3(x0 + 0.05), r3(z0 + 0.05)],
                  "max": [r3(x1 - 0.05), r3(z1 - 0.05)], "y_max": r3(gap)})
    furn("Sofa", "living", SOFA, 0.92)
    return p.to_object("Sofa")


def make_coffee_table():
    p = Part()
    (x0, z0), (x1, z1) = COFFEE
    top = 0.42
    p.add(box(x0, x1, top - 0.05, top, z0, z1, bevel=0.025, seg=3), "oak")
    for lx in (x0 + 0.08, x1 - 0.08):
        for lz in (z0 + 0.08, z1 - 0.08):
            p.add(cyl("y", lx, lz, 0.0, top - 0.05, 0.022, n=10, r1=0.03), "dark_wood")
            col("CoffeeLeg", lx - 0.03, lx + 0.03, 0.0, top - 0.05, lz - 0.03, lz + 0.03)
    # A stack of books and a mug.
    for k, (m, h) in enumerate((("art_b", 0.035), ("art_c", 0.03), ("art_a", 0.028))):
        y0 = top + sum(hh for _, hh in (("", 0.035), ("", 0.03), ("", 0.028))[:k])
        p.add(box(x0 + 0.15 + 0.01 * k, x0 + 0.42 - 0.01 * k, y0, y0 + h, z0 + 0.15, z0 + 0.38, bevel=0.004,
                  seg=1), m)
    p.add(cyl("y", x1 - 0.25, z0 + 0.3, top, top + 0.09, 0.04, n=14, bevel=0.006), "enamel")
    col("CoffeeTop", x0, x1, top - 0.05, top, z0, z1)
    surf("CoffeeTable", "living", x0, x1, z0, z1, top)
    CRAWL.append({"name": "UnderCoffeeTable", "room": "living", "min": [r3(x0 + 0.05), r3(z0 + 0.05)],
                  "max": [r3(x1 - 0.05), r3(z1 - 0.05)], "y_max": r3(top - 0.05)})
    furn("CoffeeTable", "living", COFFEE, top)
    return p.to_object("CoffeeTable")


def make_floor_lamp():
    p = Part()
    cx, cz = 7.5, 5.45
    p.add(cyl("y", cx, cz, 0.0, 0.03, 0.16, n=20, bevel=0.01), "brass")
    p.add(cyl("y", cx, cz, 0.03, 1.42, 0.014, n=8), "brass")
    p.add(ellipsoid((cx, 1.42, cz), 0.04, 0.045, 0.04, u=10, v=6), "bulb")
    p.add(cyl("y", cx, cz, 1.3, 1.58, 0.24, n=24, r1=0.16, caps=False), "shade")
    col("FloorLamp", cx - 0.16, cx + 0.16, 0.0, 1.58, cz - 0.16, cz + 0.16)
    furn("FloorLamp", "living", ((cx - 0.24, cz - 0.24), (cx + 0.24, cz + 0.24)), 1.58)
    LIGHTS.append({"name": "LampLight_Floor", "kind": "lamp", "room": "living", "pos": v3((cx, 1.38, cz))})
    return p.to_object("FloorLamp")


def make_plant():
    p = Part()
    cx, cz = 7.62, 2.95
    p.add(cyl("y", cx, cz, 0.0, 0.34, 0.15, n=18, r1=0.19, bevel=0.01), "terracotta")
    p.add(cyl("y", cx, cz, 0.3, 0.33, 0.17, n=18), "dark_wood")
    import random
    rng = random.Random(3)
    for k in range(11):
        a = 2 * math.pi * k / 11 + rng.random() * 0.3
        tilt = 0.12 + 0.12 * rng.random()
        h = 0.5 + 0.45 * rng.random()
        lx, lz = cx + tilt * math.cos(a), cz + tilt * math.sin(a)
        leaf = ellipsoid((0, 0, 0), 0.08, 0.2, 0.03, u=10, v=6)
        for v in leaf.verts:      # tilt each leaf outward, its face turned out
            x, y, z = v.co
            yy = y * math.cos(0.5) - z * math.sin(0.5)
            zz = y * math.sin(0.5) + z * math.cos(0.5)
            v.co = Vector((lx - x * math.sin(a) + zz * math.cos(a), 0.3 + h * 0.7 + yy,
                           lz + x * math.cos(a) + zz * math.sin(a)))
        p.add(leaf, "leaf")
    col("PlantPot", cx - 0.19, cx + 0.19, 0.0, 0.34, cz - 0.19, cz + 0.19)
    furn("Plant", "living", ((cx - 0.3, cz - 0.3), (cx + 0.3, cz + 0.3)), 1.3)
    return p.to_object("Plant")


# --- Bedroom ----------------------------------------------------------------------

def make_bed():
    p = Part()
    (x0, z0), (x1, z1) = BED
    gap = BED_GAP
    hb0 = x1 - 0.12                   # headboard against the east wall
    mattress_top = 0.62
    # Headboard: chunky oak board with a soft padded panel.
    p.add(box(hb0, x1 - 0.02, 0.0, 1.05, z0, z1, bevel=0.04, seg=3), "oak")
    p.add(box(hb0 - 0.06, hb0 + 0.01, 0.62, 0.97, z0 + 0.12, z1 - 0.12, bevel=0.03, seg=3), "pad")
    # Footboard posts and side rails on tall legs: the gap below stays open.
    for lz in (z0 + 0.05, z1 - 0.05):
        p.add(cyl("y", x0 + 0.06, lz, 0.0, gap + 0.14, 0.04, n=12, r1=0.04), "oak")
        p.add(ellipsoid((x0 + 0.06, gap + 0.15, lz), 0.045, 0.03, 0.045, u=10, v=6), "oak")
        col("BedLeg", x0 + 0.02, x0 + 0.1, 0.0, gap, lz - 0.04, lz + 0.04)
    p.add(box(x0 + 0.02, hb0, gap, gap + 0.12, z0, z1, bevel=0.03, seg=2), "oak")
    # Mattress, duvet with a rolled fold, pillows.
    p.add(box(x0 + 0.04, hb0 - 0.01, gap + 0.1, mattress_top, z0 + 0.03, z1 - 0.03, bevel=0.06, seg=3), "linen")
    fold = hb0 - 0.62
    p.add(box(x0 - 0.01, fold, gap + 0.14, mattress_top + 0.06, z0 - 0.02, z1 + 0.0, bevel=0.1, seg=4), "duvet")
    p.add(ellipsoid((fold - 0.03, mattress_top + 0.03, (z0 + z1) / 2), 0.085, 0.055, 0.06, u=12, v=8), "linen")
    p.add(cyl("z", fold - 0.03, mattress_top + 0.035, z0 - 0.01, z1 - 0.01, 0.06, n=12), "linen")
    for pz in (z0 + 0.42, z1 - 0.42):
        p.add(ellipsoid((hb0 - 0.26, mattress_top + 0.07, pz), 0.2, 0.1, 0.32, u=16, v=10, power=0.55), "linen")
    # Knit throw across the foot.
    p.add(box(x0 + 0.08, x0 + 0.5, mattress_top + 0.06, mattress_top + 0.085, z0 - 0.03, z1 + 0.01,
              bevel=0.012, seg=2), "rug_blue")
    col("BedBase", x0, hb0, gap, mattress_top, z0, z1)
    col("Headboard", hb0, x1, 0.0, 1.05, z0, z1)
    surf("Bed", "bedroom", x0 + 0.05, hb0 - 0.05, z0 + 0.05, z1 - 0.05, mattress_top + 0.06)
    CRAWL.append({"name": "UnderBed", "room": "bedroom", "min": [r3(x0 + 0.08), r3(z0 + 0.05)],
                  "max": [r3(hb0 - 0.02), r3(z1 - 0.05)], "y_max": r3(gap)})
    furn("Bed", "bedroom", BED, mattress_top + 0.06)
    return p.to_object("Bed")


def make_nightstand():
    p = Part()
    (x0, z0), (x1, z1) = NIGHTSTAND
    h = 0.52
    front = x0 + 0.02                # faces west
    p.add(box(front, x1 - 0.02, 0.08, h - 0.035, z0 + 0.015, z1 - 0.015, bevel=0.02, seg=2), "oak")
    p.add(box(x0, x1 - 0.02, h - 0.04, h, z0, z1, bevel=0.015, seg=2), "oak")
    for fx in (front + 0.06, x1 - 0.08):
        for fz in (z0 + 0.06, z1 - 0.06):
            p.add(cyl("y", fx, fz, 0.0, 0.08, 0.018, n=8, r1=0.024), "dark_wood")
    p.add(box(front - 0.012, front + 0.005, 0.12, 0.44, z0 + 0.04, z1 - 0.04, bevel=0.01, seg=2), "oak")
    p.add(ellipsoid((front - 0.025, 0.36, (z0 + z1) / 2), 0.012, 0.02, 0.02, u=10, v=6), "dark_wood")
    col("Nightstand", x0, x1, 0.0, h, z0, z1)
    surf("Nightstand", "bedroom", x0, x1 - 0.05, z0, (z0 + z1) / 2 - 0.02, h)
    furn("Nightstand", "bedroom", NIGHTSTAND, h)
    nightstand = p.to_object("Nightstand")
    lp = Part()
    cx, cz = x1 - 0.2, (z0 + z1) / 2 + 0.06
    lp.add(ellipsoid((cx, h + 0.035, cz), 0.07, 0.035, 0.07, u=14, v=8, cut_below=0.0), "brass")
    lp.add(cyl("y", cx, cz, h + 0.03, h + 0.26, 0.011, n=8), "brass")
    lp.add(ellipsoid((cx, h + 0.26, cz), 0.032, 0.036, 0.032, u=10, v=6), "bulb")
    lp.add(cyl("y", cx, cz, h + 0.2, h + 0.35, 0.12, n=20, r1=0.08, caps=False), "shade")
    col("BedLamp", cx - 0.1, cx + 0.1, h, h + 0.35, cz - 0.1, cz + 0.1)
    LIGHTS.append({"name": "LampLight_Bed", "kind": "lamp", "room": "bedroom", "pos": v3((cx, h + 0.24, cz))})
    return [nightstand, lp.to_object("BedLamp")]


def make_wardrobe():
    """The Wardrobe Station's spot (Q309, flat/48, house/09) against the bedroom's west wall: two
    doors meeting in the middle, hinged at its sides, swinging into the room. Its spot, doors and
    inside go to the layout as "wardrobe" (not an openable: using it opens the Wardrobe, and its
    doors follow who is in it), with its colliders and footprint. Nothing is drawn here: the model
    is a Blender MCP asset (pipeline/05, assets/wardrobe_station/wardrobe_station.glb, built by
    make_wardrobe_station.py), whose door_left / door_right hinges are these."""
    x0, depth, h = 0.0, WARDROBE_D, WARDROBE_H
    z0, z1 = WARDROBE_C - WARDROBE_W / 2, WARDROBE_C + WARDROBE_W / 2
    t, dt = 0.025, 0.022              # board and door thickness
    fx = x0 + depth - dt              # the carcass front; the doors lie in front of it
    plinth, top = 0.08, h - 0.07      # bottom board's underside, top board's top
    # The piece's frame (front -y, +x its right) into flat space (Blender x, -z, y): its front
    # faces +x, its back on the wall at x = 0, its middle at z = WARDROBE_C.
    to_flat = Matrix.Translation((x0 + depth / 2, -WARDROBE_C, 0.0)) @ Matrix.Rotation(math.pi / 2, 4, "Z")
    y0, y1 = plinth + 0.01, top - 0.01
    doors = []
    for name, s, open_deg in (("door_left", -1, -80), ("door_right", 1, 80)):
        pv = to_flat @ Vector((s * (WARDROBE_W / 2 - 0.004), -depth / 2 + dt, y0))
        hinge = (pv.x, pv.z, -pv.y)
        # Both swing out into the room (+x), short of flat against the wall.
        doors.append({"node": name, "hinge": v3(hinge), "axis": [0, 1, 0], "open_deg": open_deg,
                      "min": v3((0.0, 0.0, -0.494 if open_deg < 0 else 0.0)),
                      "max": v3((dt + 0.04, y1 - y0, 0.0 if open_deg < 0 else 0.494))})
    # Collision: the carcass panels (hollow, the doors close it) and the cornice.
    col("Wardrobe", x0, fx, 0.0, top, z0, z0 + t)
    col("Wardrobe", x0, fx, 0.0, top, z1 - t, z1)
    col("Wardrobe", x0, x0 + t, 0.0, top, z0, z1)
    col("Wardrobe", x0, fx, 0.0, plinth + t, z0, z1)
    col("Wardrobe", x0, fx + dt + 0.035, top - t, h, z0 - 0.025, z1 + 0.025)
    furn("Wardrobe", "bedroom", ((x0, z0), (fx + dt, z1)), h)
    WARDROBE.update({
        "pos": v3((x0 + depth / 2, 0.0, WARDROBE_C)), "yaw": r3(math.pi / 2),
        "size": v3((WARDROBE_W, h, depth)), "room": "bedroom",
        "zone": {"min": [r3(WARDROBE_ZONE[0][0]), r3(WARDROBE_ZONE[0][1])],
                 "max": [r3(WARDROBE_ZONE[1][0]), r3(WARDROBE_ZONE[1][1])]},
        "doors": doors,
        "interior": {"min": v3((x0 + t, plinth + t, z0 + t)), "max": v3((fx, top - t, z1 - t))},
    })
    return []


# --- Bathroom ---------------------------------------------------------------------

def make_bathtub():
    p = Part()
    (x0, z0), (x1, z1) = TUB
    cx, cz, hx, hz = (x0 + x1) / 2, (z0 + z1) / 2, (x1 - x0) / 2, (z1 - z0) / 2
    top, floor_y, wall = 0.56, 0.12, 0.09
    p.add(vessel(cx, cz, hx, hz, 0.14, wall, 0.0, top, floor_y, n=6, lip=0.02), "porcelain")
    # Tap on the wall end and a folded towel on the rim.
    p.add(cyl("x", top + 0.2, cz, x1 + 0.02, x1 - 0.12, 0.018, n=10), "brass")
    p.add(cyl("y", x1 - 0.12, cz, top + 0.12, top + 0.2, 0.016, n=10), "brass")
    for dz in (-0.08, 0.08):
        p.add(cyl("y", x1 + 0.0 - 0.05, cz + dz, top + 0.24, top + 0.28, 0.025, n=10), "porcelain")
    p.add(box(x0 + 0.25, x0 + 0.6, top - 0.06, top + 0.03, z0 - 0.025, z0 + 0.06, bevel=0.02, seg=3), "towel")
    col("TubFloor", x0, x1, 0.0, floor_y, z0, z1)
    col("TubWall", x0, x1, 0.0, top, z0, z0 + wall)
    col("TubWall", x0, x1, 0.0, top, z1 - wall, z1)
    col("TubWall", x0, x0 + wall, 0.0, top, z0, z1)
    col("TubWall", x1 - wall, x1, 0.0, top, z0, z1)
    surf("TubInside", "bathroom", x0 + wall + 0.05, x1 - wall - 0.05, z0 + wall + 0.04, z1 - wall - 0.04, floor_y)
    furn("Bathtub", "bathroom", TUB, top)
    return p.to_object("Bathtub")


def make_vanity():
    p = Part()
    (x0, z0), (x1, z1) = VANITY
    top = 0.8
    p.add(box(x0 + 0.02, x1 - 0.02, 0.1, top - 0.03, z0, z1 - 0.02, bevel=0.015, seg=2), "cupboard")
    p.add(box(x0 + 0.05, x1 - 0.05, 0.0, 0.1, z0, z1 - 0.06), "dark_wood")
    p.add(box(x0, x1, top - 0.035, top, z0, z1, bevel=0.012, seg=2), "worktop")
    for a, b in ((x0 + 0.04, (x0 + x1) / 2 - 0.005), ((x0 + x1) / 2 + 0.005, x1 - 0.04)):
        p.add(box(a, b, 0.14, top - 0.07, z1 - 0.025, z1 - 0.005, bevel=0.008, seg=2), "cupboard")
    for kx in ((x0 + x1) / 2 - 0.045, (x0 + x1) / 2 + 0.045):
        p.add(ellipsoid((kx, top - 0.14, z1 + 0.005), 0.014, 0.014, 0.012, u=10, v=6), "brass")
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2 + 0.03
    p.add(vessel(cx, cz, 0.21, 0.16, 0.12, 0.02, top, top + 0.13, top + 0.03, n=6, lip=0.012), "porcelain")
    p.add(cyl("y", cx, z0 + 0.06, top, top + 0.24, 0.013, n=10), "brass")
    p.add(cyl("z", cx, top + 0.23, z0 + 0.06, z0 + 0.17, 0.011, n=8), "brass")
    # Round mirror with an oak frame.
    my = 1.55
    p.add(cyl("z", cx, my, z0, z0 + 0.025, 0.3, n=32, bevel=0.008), "oak")
    p.add(cyl("z", cx, my, z0 + 0.02, z0 + 0.03, 0.26, n=32), "mirror")
    col("Vanity", x0, x1, 0.0, top, z0, z1)
    col("Basin", cx - 0.21, cx + 0.21, top, top + 0.13, cz - 0.16, cz + 0.16)
    surf("VanityTop", "bathroom", x0, cx - 0.22, z0 + 0.05, z1, top)
    furn("Vanity", "bathroom", VANITY, top)
    return p.to_object("Vanity")


def make_laundry_basket():
    """A hollow wicker basket (flat/48, Q351): walls and a floor, open under a hinged lid, so
    Socks lie inside it. Its colliders are its four walls and its floor, the walls at least
    COL_WALL thick (grown outwards), so a falling or thrown Sock never slips through one."""
    p = Part()
    cx, cz = BASKET_C
    hx, hz, r, wall, h, floor_y = 0.26, 0.2, 0.08, 0.025, 0.5, 0.04
    p.add(vessel(cx, cz, hx, hz, r, wall, 0.0, h, floor_y, n=5), "wicker")
    # Woven hoops round the outside (hollow: open over the inside), the inside floor a shade darker.
    for by in (0.08, 0.2, 0.32, 0.44):
        p.add(band(cx, cz, hx, hz, r, 0.006, 0.0, by, by + 0.025, n=5), "wicker_dark")
    p.add(prism("y", rounded_rect(hx - wall - 0.004, hz - wall - 0.004, r - wall - 0.004, 5, cx, cz),
                floor_y, floor_y + 0.004), "wicker_dark")
    for sx in (-1, 1):
        p.add(box(cx + sx * hx - 0.012, cx + sx * hx + 0.012, h - 0.12, h - 0.06, cz - 0.06, cz + 0.06,
                  bevel=0.008, seg=2), "wicker_dark")
    body = p.to_object("LaundryBasket")
    z_back = cz - hz
    grow = COL_WALL - wall          # the wall colliders grow outwards to COL_WALL
    col("BasketFloor", cx - hx, cx + hx, 0.0, floor_y, cz - hz, cz + hz)
    col("BasketWall", cx - hx - grow, cx + hx + grow, 0.0, h, cz - hz - grow, cz - hz + wall)
    col("BasketWall", cx - hx - grow, cx + hx + grow, 0.0, h, cz + hz - wall, cz + hz + grow)
    col("BasketWall", cx - hx - grow, cx - hx + wall, 0.0, h, cz - hz, cz + hz)
    col("BasketWall", cx + hx - wall, cx + hx + grow, 0.0, h, cz - hz, cz + hz)
    lid = Part()
    lid.add(prism("y", rounded_rect(hx + 0.012, hz + 0.012, r + 0.012, 5, cx, cz), h, h + 0.035), "wicker")
    lid.add(prism("y", rounded_rect(hx - 0.04, hz - 0.04, r - 0.03, 5, cx, cz), h + 0.035, h + 0.045), "wicker_dark")
    lid.add(box(cx - 0.06, cx + 0.06, h + 0.04, h + 0.065, cz + hz - 0.07, cz + hz - 0.04, bevel=0.01, seg=2),
            "wicker_dark")
    hinge = (cx, h, z_back - 0.012)
    lid_obj = lid.to_object("LaundryBasketLid", origin=hinge)
    OPENABLES.append({
        "name": "LaundryBasket", "room": "bathroom", "kind": "basket",
        "doors": [{"node": "LaundryBasketLid", "hinge": v3(hinge), "axis": [1, 0, 0], "open_deg": -100,
                   "min": v3((-hx - 0.012, 0.0, 0.0)), "max": v3((hx + 0.012, 0.065, 2 * hz + 0.024))}],
        "interior": {"min": v3((cx - hx + wall, floor_y, cz - hz + wall)), "max": v3((cx + hx - wall, h, cz + hz - wall))},
        "shelves_y": [],
    })
    furn("LaundryBasket", "bathroom", ((cx - hx, cz - hz), (cx + hx, cz + hz)), h + 0.065)
    return [body, lid_obj]


def make_wall_tiles():
    """Bathroom tile wainscot to 1.2 m (a thin skin on the bathroom faces)."""
    p = Part()
    (bx0, bz0), (bx1, bz1) = ROOMS["bathroom"][0]
    y1 = 1.2
    for face in FACES:
        wall, axis, c, sign, s0, s1 = face
        if axis == "x" and abs(c - (bz0 if sign > 0 else bz1)) < 1e-6:
            a, b = max(s0, bx0), min(s1, bx1)
        elif axis == "z" and abs(c - (bx0 if sign > 0 else bx1)) < 1e-6:
            a, b = max(s0, bz0), min(s1, bz1)
        else:
            continue
        if b <= a:
            continue
        skips = [(h[0] - CASING_W, h[1] + CASING_W) for w in WALLS if w[0] == wall for h in w[4] if h[2] <= 0]
        for p0, p1 in free_spans(a, b, skips):
            p.add(face_box(face, 0.0, 0.008, 0.0, y1, p0, p1), "wall_tile", uv_scale=0.6)
            p.add(face_box(face, 0.0, 0.025, y1, y1 + 0.035, p0, p1, bevel=0.008, seg=2), "trim")
    return p.to_object("WallTiles")


# --- Hall, rugs, lamps, pictures -------------------------------------------------

def make_coat_rack():
    p = Part()
    cx, cz = 0.32, 8.6
    for k in range(3):
        a = 2 * math.pi * k / 3 + 0.4
        ex, ez = cx + 0.24 * math.cos(a), cz + 0.24 * math.sin(a)
        seg = box(-0.02, 0.02, 0.0, 0.05, 0.0, 1.0, bevel=0.01, seg=2)
        for v in seg.verts:
            t = v.co.z
            v.co = Vector((cx + (ex - cx) * t + v.co.x * -math.sin(a), v.co.y + 0.12 * (1 - t),
                           cz + (ez - cz) * t + v.co.x * math.cos(a)))
        p.add(seg, "dark_wood")
    p.add(cyl("y", cx, cz, 0.0, 1.78, 0.025, n=12, r1=0.02), "dark_wood")
    p.add(ellipsoid((cx, 1.8, cz), 0.04, 0.04, 0.04, u=10, v=6), "dark_wood")
    for k in range(4):
        a = 2 * math.pi * k / 4 + math.pi / 4
        hx, hz = cx + 0.13 * math.cos(a), cz + 0.13 * math.sin(a)
        p.add(cyl("y", (cx + hx) / 2, (cz + hz) / 2, 1.62, 1.66, 0.012, n=6), "dark_wood")
        p.add(ellipsoid((hx, 1.66, hz), 0.025, 0.025, 0.025, u=8, v=6), "brass")
    # Two hanging coats and a scarf, a hat on top.
    for k, (ang, top, length, mat) in enumerate(((-0.25, 1.64, 0.95, "coat_a"), (-1.35, 1.6, 0.8, "coat_b"))):
        # A coat: a slab narrow at the shoulders, flaring to the hem, hung off a hook.
        coat = box(-0.15, 0.15, -length, 0.0, -0.05, 0.05, bevel=0.035, seg=2)
        for v in coat.verts:
            t = -v.co.y / length                   # 0 at the shoulders, 1 at the hem
            sx = 0.75 + 0.45 * t
            if v.co.y > -0.06:
                sx *= 0.8                          # rounded shoulders
            x, z = v.co.x * sx, v.co.z * (0.8 + 0.6 * t)
            ox, oz = 0.12 * math.cos(ang), 0.12 * math.sin(ang)
            v.co = Vector((cx + ox + x * -math.sin(ang) + z * math.cos(ang), top + v.co.y,
                           cz + oz + x * math.cos(ang) + z * math.sin(ang)))
        p.add(coat, mat)
        p.add(ellipsoid((cx + 0.15 * math.cos(ang), top - 0.02, cz + 0.15 * math.sin(ang)), 0.07, 0.03, 0.07,
                        u=10, v=6), mat)
    p.add(ellipsoid((cx + 0.02, 1.86, cz), 0.14, 0.03, 0.14, u=16, v=6), "rug_blue")
    p.add(ellipsoid((cx + 0.02, 1.9, cz), 0.09, 0.07, 0.09, u=16, v=8, cut_below=0.0), "rug_blue")
    col("CoatRack", cx - 0.25, cx + 0.25, 0.0, 1.95, cz - 0.25, cz + 0.25)
    furn("CoatRack", "hall", ((cx - 0.3, cz - 0.3), (cx + 0.3, cz + 0.3)), 1.95)
    return p.to_object("CoatRack")


def rug_bm(cx, cz, w, d, r, top, inner_mat, stripe_mat, out):
    hx, hz = w / 2, d / 2
    k = min(1.0, min(w, d) / 1.4)       # small mats get a narrower border
    rings = [(0.0, 0.0), (0.004, top - 0.003), (0.012, top), (0.11 * k, top), (0.16 * k, top)]
    mats = [inner_mat, inner_mat, inner_mat, stripe_mat]
    for i in range(len(rings) - 1):
        (ia, ya), (ib, yb) = rings[i], rings[i + 1]
        bm = bmesh.new()
        ra = [bm.verts.new((x, ya, z)) for x, z in rounded_rect(hx - ia, hz - ia, max(r - ia, 0.01), 6, cx, cz)]
        rb = [bm.verts.new((x, yb, z)) for x, z in rounded_rect(hx - ib, hz - ib, max(r - ib, 0.01), 6, cx, cz)]
        for k in range(len(ra)):
            j = (k + 1) % len(ra)
            bm.faces.new((ra[k], ra[j], rb[j], rb[k]))
        bm.normal_update()
        for f in bm.faces:
            if f.normal.y < 0:
                f.normal_flip()
        out.add(bm, mats[i])
    bm = bmesh.new()
    ins, y = rings[-1]
    face = bm.faces.new([bm.verts.new((x, y, z)) for x, z in rounded_rect(hx - ins, hz - ins, max(r - ins, 0.01), 6, cx, cz)])
    bm.normal_update()
    if face.normal.y < 0:
        face.normal_flip()
    out.add(bm, inner_mat)


def make_rugs():
    p = Part()
    rugs = [("LivingRug", "living", 5.7, 3.3, 2.8, 2.0, 0.3, "rug", "rug_stripe"),
            ("BedroomRug", "bedroom", 2.2, 11.05, 2.0, 1.4, 0.25, "rug_blue", "rug_stripe"),
            ("BathMat", "bathroom", 4.4, 7.75, 0.9, 0.5, 0.12, "rug_mint", "linen"),
            ("Doormat", "hall", 0.5, 7.0, 0.5, 0.85, 0.06, "wicker", "wicker_dark"),
            ("KitchenRunner", "kitchen", 2.1, 1.05, 2.0, 0.6, 0.1, "rug_blue", "rug_stripe")]
    for name, room, cx, cz, w, d, r, m0, m1 in rugs:
        top = 0.012
        rug_bm(cx, cz, w, d, r, top, m0, m1, p)
        RUGS.append({"name": name, "room": room, "min": [r3(cx - w / 2), r3(cz - d / 2)],
                     "max": [r3(cx + w / 2), r3(cz + d / 2)], "top_y": top})
    return p.to_object("Rugs")


CEILING_LAMPS = [   # room, x, z, kind
    ("kitchen", 2.1, 3.3, "pendant_low"),
    ("living", 5.7, 2.8, "globe"),
    ("bedroom", 2.6, 11.0, "globe"),
    ("hall", 1.15, 7.5, "flush"),
    ("bathroom", 3.9, 7.5, "flush"),
]


def make_ceiling_lamps():
    """Roses, cords and the opaque lamps; the globes' paper and bulbs are make_shades()'."""
    p = Part()
    for room, cx, cz, kind in CEILING_LAMPS:
        p.add(cyl("y", cx, cz, H - 0.03, H + 0.01, 0.06, n=16, bevel=0.008), "trim")
        if kind == "flush":
            p.add(ellipsoid((cx, H - 0.03, cz), 0.2, 0.1, 0.2, u=20, v=10, cut_below=-0.0001), "paper")
            p.add(cyl("y", cx, cz, H - 0.035, H - 0.02, 0.21, n=20), "brass")
            bulb_y = H - 0.08
        elif kind == "pendant_low":
            rim = 1.95
            p.add(cyl("y", cx, cz, rim + 0.18, H - 0.03, 0.005, n=6), "dark_wood")
            p.add(cyl("y", cx, cz, rim, rim + 0.2, 0.22, n=24, r1=0.05, caps=False), "enamel")
            p.add(cyl("y", cx, cz, rim + 0.19, rim + 0.24, 0.05, n=12), "enamel")
            p.add(ellipsoid((cx, rim + 0.05, cz), 0.045, 0.05, 0.045, u=12, v=8), "bulb")
            bulb_y = rim + 0.05
        else:
            # The cord stops at the globe's top: inside it would sit beside the light and throw
            # its shadow over the whole ceiling.
            p.add(cyl("y", cx, cz, GLOBE_CENTRE + GLOBE_R - 0.01, H - 0.03, 0.005, n=6), "dark_wood")
            bulb_y = GLOBE_CENTRE - 0.02
        LIGHTS.append({"name": "CeilingLight_" + room, "kind": "ceiling", "room": room,
                       "pos": v3((cx, bulb_y, cz))})
    return p.to_object("CeilingLamps")


GLOBE_CENTRE, GLOBE_R, GLOBE_RIM = H - 0.42, 0.22, 0.13   # the globe is open below centre - rim


def make_shades():
    """The globe shades (ribbed paper, open below) and their bulbs, a node of their own so
    code can keep them from casting shadows: the light inside then reaches the upper walls
    and ceiling through the paper (flat/28 Q203)."""
    p = Part()
    for room, cx, cz, kind in CEILING_LAMPS:
        if kind != "globe":
            continue
        cut = -GLOBE_RIM / GLOBE_R
        bm = ellipsoid((0, 0, 0), 1, 1, 1, u=16, v=10, cut_below=cut)
        for v in bm.verts:
            lat = math.asin(max(-1.0, min(1.0, v.co.y)))
            rib = 1.0 + 0.015 * math.cos(lat * 10)
            v.co = Vector((cx + v.co.x * GLOBE_R * rib, GLOBE_CENTRE + v.co.y * GLOBE_R, cz + v.co.z * GLOBE_R * rib))
        p.add(bm, "shade_paper")
        p.add(ellipsoid((cx, GLOBE_CENTRE - 0.02, cz), 0.045, 0.05, 0.045, u=12, v=8), "bulb")
        p.add(cyl("y", cx, cz, GLOBE_CENTRE + 0.02, GLOBE_CENTRE + GLOBE_R - 0.005, 0.005, n=6), "dark_wood")
        p.add(cyl("y", cx, cz, GLOBE_CENTRE + 0.015, GLOBE_CENTRE + 0.06, 0.02, n=10), "brass")   # socket
    return p.to_object("Shades")


def make_pictures():
    """Framed pictures on free wall: a soft sun, hills, a cat-ish blob (plain shapes)."""
    p = Part()
    pics = [  # wall face, coord, s centre, y centre, w, h, art material
        ("P1", 5.94, 3.0, 1.55, 0.6, 0.45, "art_a"),
        ("P1", 5.94, 2.25, 1.6, 0.32, 0.42, "art_b"),
        ("W", 0.0, 4.6, 1.5, 0.5, 0.65, "art_c"),
        ("P2", 9.06, 0.9, 1.5, 0.4, 0.5, "art_b"),   # right of the wardrobe (flat/48)
        ("W", 0.0, 7.95, 1.6, 0.3, 0.4, "art_a"),
    ]
    for wall, c, s, y, w, h, art in pics:
        face = find_face(wall, c)
        p.add(face_box(face, 0.0, 0.03, y - h / 2, y + h / 2, s - w / 2, s + w / 2, bevel=0.01, seg=2), "oak")
        p.add(face_box(face, 0.0, 0.034, y - h / 2 + 0.04, y + h / 2 - 0.04, s - w / 2 + 0.04, s + w / 2 - 0.04),
              "linen")
        p.add(face_box(face, 0.0, 0.038, y - h / 2 + 0.07, y + h / 2 * 0.3, s - w / 2 + 0.07, s + w / 2 - 0.07),
              art)
        p.add(face_box(face, 0.0, 0.04, y + h * 0.1, y + h * 0.3, s + w * 0.05, s + w * 0.25), "orange")
    return p.to_object("Pictures")


# --- Textures -----------------------------------------------------------------------

def _image(name, rgb):
    n = rgb.shape[0]
    rgba = np.concatenate([np.clip(rgb, 0, 1), np.ones((n, n, 1))], axis=2).astype(np.float32)
    img = bpy.data.images.new(name, width=n, height=n)
    img.pixels.foreach_set(rgba.ravel())
    img.file_format = "PNG"
    img.pack()
    return img


def plank_image():
    """2 m tile: planks along x, 0.2 m wide, staggered 1 m joints."""
    rng = np.random.default_rng(7)
    n, tile, pw, pl = 1024, 2.0, 0.2, 1.0
    rows, per_row = int(round(tile / pw)), int(round(tile / pl))
    m = tile / n
    xs = (np.arange(n) + 0.5) * m
    X, Z = np.meshgrid(xs, xs)
    row = np.minimum((Z / pw).astype(int), rows - 1)
    offset = rng.random(rows) * pl
    px = np.mod(X + offset[row], tile)
    col_ = np.minimum((px / pl).astype(int), per_row - 1)
    tone = 1.0 + (rng.random((rows, per_row)) - 0.5) * 0.18
    base = np.array([0.66, 0.45, 0.28])
    t = tone[row, col_][..., None]
    phase = rng.random((rows, per_row)) * 10
    zin = np.mod(Z, pw)
    grain = 0.5 + 0.5 * np.sin(zin * 140 + 2.0 * np.sin(px * 3.0 + phase[row, col_]))
    rgb = base * t * (0.95 + 0.06 * grain[..., None])
    seam = 0.006
    edge = np.minimum(zin, pw - zin)
    joint = np.minimum(np.mod(px, pl), pl - np.mod(px, pl))
    gap = np.minimum(edge, joint)
    rgb = rgb * (0.45 + 0.55 * np.clip(gap / seam, 0, 1)[..., None]) * (0.92 + 0.08 * np.clip(gap / (seam * 3), 0, 1)[..., None])
    return _image("flat_planks", rgb)


def tile_image(name, size_m, tile_m, c0, c1, grout, checker=True, jitter=0.04, seed=1):
    rng = np.random.default_rng(seed)
    n = 512
    k = int(round(size_m / tile_m))
    m = size_m / n
    xs = (np.arange(n) + 0.5) * m
    X, Z = np.meshgrid(xs, xs)
    i, j = (X / tile_m).astype(int) % k, (Z / tile_m).astype(int) % k
    pick = ((i + j) % 2 == 0) if checker else np.ones_like(i, dtype=bool)
    rgb = np.where(pick[..., None], np.array(c0), np.array(c1)).astype(float)
    tone = 1.0 + (rng.random((k, k)) - 0.5) * jitter * 2
    rgb *= tone[i, j][..., None]
    lx, lz = np.mod(X, tile_m), np.mod(Z, tile_m)
    g = np.minimum(np.minimum(lx, tile_m - lx), np.minimum(lz, tile_m - lz))
    gw = 0.006
    a = np.clip((g - gw * 0.5) / gw, 0, 1)[..., None]
    rgb = rgb * a + np.array(grout) * (1 - a)
    return _image(name, rgb)


def make_materials():
    imgs = {
        "wood": plank_image(),
        "kitchen_tile": tile_image("flat_kitchen_tiles", 1.2, 0.3, (0.85, 0.52, 0.38), (0.96, 0.90, 0.78),
                                   (0.78, 0.72, 0.64)),
        "bath_tile": tile_image("flat_bath_tiles", 0.6, 0.15, (0.95, 0.96, 0.94), (0.72, 0.88, 0.84),
                                (0.80, 0.82, 0.80), seed=2),
        "wall_tile": tile_image("flat_wall_tiles", 0.6, 0.15, (0.97, 0.98, 0.96), (0.97, 0.98, 0.96),
                                (0.80, 0.84, 0.82), checker=False, seed=3),
    }
    for name, (color, rough, metal, emit, alpha) in MATERIALS.items():
        m = bpy.data.materials.new(name)
        bsdf = m.node_tree.nodes["Principled BSDF"]
        bsdf.inputs["Base Color"].default_value = color
        m.diffuse_color = color          # what the Workbench previews show
        bsdf.inputs["Roughness"].default_value = rough
        bsdf.inputs["Metallic"].default_value = metal
        if emit:
            bsdf.inputs["Emission Color"].default_value = color
            bsdf.inputs["Emission Strength"].default_value = emit
        if alpha < 1.0:
            bsdf.inputs["Alpha"].default_value = alpha
            m.surface_render_method = "BLENDED"
        if name in imgs:
            tex = m.node_tree.nodes.new("ShaderNodeTexImage")
            tex.image = imgs[name]
            m.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])


# --- Build, layout, export, preview -------------------------------------------------

def empty(name, pos):
    o = bpy.data.objects.new(name, None)
    o.empty_display_type = "PLAIN_AXES"
    o.empty_display_size = 0.1
    x, y, z = pos
    o.location = (x, -z, y)
    bpy.context.scene.collection.objects.link(o)
    return o


def yaw_towards(src, dst):
    dx, dz = dst[0] - src[0], dst[2] - src[2]
    return math.atan2(-dx, -dz)


def layout(window_info):
    def fp(rect):
        (x0, z0), (x1, z1) = rect
        return {"min": [r3(x0), r3(z0)], "max": [r3(x1), r3(z1)]}

    rooms = []
    for name, (rect, floor) in ROOMS.items():
        r = dict(name=name, **fp(rect), floor=floor.replace("_tile", "_tile") if floor != "wood" else "wood")
        r["open_to"] = {"kitchen": ["living"], "living": ["kitchen"]}.get(name, [])
        rooms.append(r)
    doorways, front = [], None
    for name, axis, _, (t0, t1), holes in WALLS:
        for a, b, y0, y1, kind, hname in holes:
            if kind == "window":
                continue
            rect = ((a, t0), (b, t1)) if axis == "x" else ((t0, a), (t1, b))
            if kind == "doorway":
                doorways.append(dict(name=hname, between=DOORWAY_ROOMS[hname], **fp(rect), height=y1))
            else:
                front = dict(**fp(rect), height=y1)
    wins = []
    for wname, room, wall, face, w0, w1, sill, head in window_info:
        _, axis, c, sign, _, _ = face
        t = [c, c - sign * EXT_T]
        rect = ((w0, min(t)), (w1, max(t))) if axis == "x" else ((min(t), w0), (max(t), w1))
        wins.append(dict(name=wname, room=room, wall=wall, **fp(rect), sill_y=sill, head_y=head))
    spots = []
    for c in CABINETS:
        pos, yaw, zone = cabinet_spot(c)
        spots.append({"collection": c[0], "room": c[1], "wall": c[2], "pos": v3(pos), "yaw": r3(yaw),
                      "zone": fp(zone), "max_height": CLEAR_TOP})
    washer_front = (WASHER_POS[0], 0.6, WASHER_POS[2] + 0.35)
    zones = {s["collection"]: s["zone"] for s in spots}
    zones["washer"] = fp(WASHER_ZONE)
    return {
        "units": "metres; x/z footprints and [x, y, z] points in Godot coordinates",
        "bounds": {"min": [0.0, 0.0], "max": [8.0, 13.0], "height": H, "exterior_wall": EXT_T,
                   "partition": PART_T},
        "outline": [[r3(x), r3(z)] for x, z in OUTLINE],
        "rooms": rooms,
        "doorways": doorways,
        "front_door": front,
        "windows": wins,
        "spawn": {"pos": v3(SPAWN), "yaw": r3(yaw_towards(SPAWN, washer_front)), "look_at": v3(washer_front)},
        "washer": {"pos": v3(WASHER_POS), "yaw": 0.0, "room": "bathroom", "zone": fp(WASHER_ZONE)},
        "cabinet_spots": spots,
        "clear_zones": dict(zones, y_max=CLEAR_TOP,
                            note="cabinet zones are 1.8 x 0.95 m (cabinet 0.5 + drawer pull-out 0.45)"),
        "colliders": COLLIDERS,
        "surfaces": SURFACES,
        "crawl_spaces": CRAWL,
        "openables": OPENABLES,
        "furniture": FURNITURE,
        "lights": LIGHTS,
        "rugs": RUGS,
        "clock": {"pos": v3(CLOCK_POS), "yaw": CLOCK_YAW, "room": "living", "wall": "N"},
        "wardrobe": WARDROBE,
        "mirror": {"pos": v3(((VANITY[0][0] + VANITY[1][0]) / 2, MIRROR_Y, VANITY[0][1] + 0.03)), "yaw": 0.0,
                   "radius": MIRROR_R, "room": "bathroom"},
    }


def tris(obj):
    if obj.type != "MESH":
        return 0
    obj.data.calc_loop_triangles()
    return len(obj.data.loop_triangles)


def check_zones(objs):
    """Fails loudly if any exported mesh enters a clear zone below CLEAR_TOP."""
    bad = []
    for o in objs.values():
        if o.type != "MESH" or o.name in ("Floor", "Ceiling", "Shades", "Walls", "Rugs"):
            continue
        mw = o.matrix_world
        for v in o.data.vertices:
            w = mw @ v.co
            x, y, z = w.x, w.z, -w.y
            if y > CLEAR_TOP or y < 0.02:
                continue
            for (x0, z0), (x1, z1) in all_zones():
                if x0 + 0.005 < x < x1 - 0.005 and z0 + 0.005 < z < z1 - 0.005:
                    bad.append((o.name, round(x, 2), round(y, 2), round(z, 2)))
                    break
    if bad:
        raise SystemExit("CLEAR ZONE VIOLATION %s" % bad[:10])


def stand_ins():
    """Preview-only: Cabinet boxes at their spots and the washing machine model."""
    made = []
    colours = {"simple": (0.97, 0.97, 0.95), "winter": (0.75, 0.30, 0.30), "superhero": (0.95, 0.80, 0.25),
               "space": (0.20, 0.25, 0.45), "patterns": (0.55, 0.75, 0.90), "animals": (0.95, 0.75, 0.55),
               "food": (0.80, 0.65, 0.45), "sport": (0.35, 0.55, 0.40)}
    for c in CABINETS:
        pos, yaw, _ = cabinet_spot(c)
        h = 0.15 + 0.3 * c[6]
        m = bpy.data.materials.new("stand_" + c[0])
        m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = srgb(*colours[c[0]])
        m.diffuse_color = srgb(*colours[c[0]])
        p = Part()
        p.add(box(-0.75, 0.75, 0.0, h, -0.25, 0.25, bevel=0.02, seg=2), "stand_" + c[0])
        for k in range(c[6]):
            y0 = 0.1 + 0.3 * k
            p.add(box(-0.68, 0.68, y0 + 0.02, y0 + 0.28, 0.24, 0.27, bevel=0.01, seg=1), "stand_" + c[0])
            p.add(box(-0.1, 0.1, y0 + 0.13, y0 + 0.17, 0.27, 0.3), "brass")
        o = p.to_object("Stand_" + c[0])
        o.location = (pos[0], -pos[2], 0.0)
        o.rotation_euler = (0, 0, yaw)
        made.append(o)
    for rel, pos, yaw in ((("washing_machine", "washing_machine.glb"), WASHER_POS, 0.0),
                          (("clock", "clock.glb"), CLOCK_POS, CLOCK_YAW)):
        path = os.path.join(REPO, "assets", *rel)
        if not os.path.exists(path):
            continue
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=path)
        for o in set(bpy.data.objects) - before:
            if o.parent is None:
                o.location = Vector((pos[0], -pos[2], pos[1])) + o.location
                o.rotation_euler.z += yaw
            made.append(o)
    return made


VIEWS = {   # room: [(name, camera, target, lens)]
    "kitchen": [("kitchen", (3.4, 1.6, 5.3), (0.9, 0.7, 0.6), 15),
                ("crouch_under_table", (2.1, 0.9, 5.4), (2.1, 0.15, 3.3), 15),
                ("openables_open", (2.6, 1.45, 2.3), (1.3, 0.55, 0.3), 15),
                ("openables_oven", (1.7, 1.15, 1.45), (1.7, 0.4, 0.3), 24)],
    "living": [("kitchen_living", (7.3, 1.6, 4.9), (1.0, 0.8, 0.8), 14),
               ("living_clock", (6.6, 1.7, 1.6), (7.3, 1.9, 0.0), 18),
               ("living_shade", (4.2, 1.6, 4.8), (5.9, 2.2, 1.0), 15),
               ("living", (1.3, 1.6, 5.4), (7.2, 0.7, 1.6), 14),
               ("crouch_under_sofa", (5.7, 0.9, 2.6), (5.7, 0.12, 4.65), 15)],
    "bedroom": [("bedroom", (1.3, 1.6, 9.4), (4.8, 0.6, 12.3), 15),
                ("openables_wardrobe", (2.3, 1.3, 10.4), (0.2, 1.0, 9.6), 18),
                ("bedroom_b", (5.0, 1.6, 12.6), (0.3, 0.7, 9.6), 15),
                ("crouch_under_bed", (2.0, 0.9, 12.2), (4.2, 0.12, 12.2), 15)],
    "bathroom": [("bathroom", (2.65, 1.6, 8.7), (5.0, 0.6, 6.4), 15),
                 ("openables_basket", (3.3, 1.4, 7.6), (4.0, 0.45, 6.4), 18),
                 ("bathroom_mirror", (3.3, 1.5, 7.4), (3.0, 1.2, 6.06), 18)],
    "hall": [("hall", (2.1, 1.6, 6.3), (0.2, 0.9, 8.6), 15),
             ("hall_b", (1.0, 1.6, 4.6), (1.4, 1.1, 9.5), 15)],
}
FINAL_VIEWS = ["flat_top", "kitchen_living", "bathroom", "crouch_under_bed", "living_clock", "living_shade",
               "openables_oven", "openables_wardrobe", "bathroom_mirror"]


def set_open(objs, opened):
    """Swings every openable to its open angle (preview only), or back."""
    from mathutils import Matrix
    for o in OPENABLES + [WARDROBE]:
        for d in o.get("doors", []):
            ob = objs.get(d["node"])
            if ob is None:
                continue
            ax = d["axis"]
            bax = Vector((ax[0], -ax[2], ax[1]))     # Godot axis -> Blender axis
            ang = math.radians(d["open_deg"]) if opened else 0.0
            ob.rotation_euler = Matrix.Rotation(ang, 3, bax).to_euler()


def render_previews(objs, preview_dir, final, only_room):
    """Iteration previews: Workbench, 640x400, 1 sample, no shadows/AO (cheap).
    Final previews (--final): EEVEE at 12 samples, only FINAL_VIEWS."""
    scene = bpy.context.scene
    scene.render.threads_mode = "FIXED"
    scene.render.threads = 4
    scene.view_settings.view_transform = "Standard"
    stand_ins()
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
    scene.collection.objects.link(cam)
    scene.camera = cam
    cam.data.clip_start = 0.02
    cam.data.clip_end = 100
    if final:
        world = bpy.data.worlds.new("W")
        world.use_nodes = True
        world.node_tree.nodes["Background"].inputs[0].default_value = srgb(0.80, 0.88, 0.96)
        world.node_tree.nodes["Background"].inputs[1].default_value = 0.7
        scene.world = world

        def light(pos, energy, color, size, shadow):
            lo = bpy.data.objects.new("L", bpy.data.lights.new("L", "POINT"))
            lo.data.energy, lo.data.color = energy, color
            lo.data.shadow_soft_size, lo.data.use_shadow = size, shadow
            lo.location = (pos[0], -pos[2], pos[1])
            scene.collection.objects.link(lo)

        for l in LIGHTS:
            if l["kind"] == "ceiling":
                light(l["pos"], 45, (1.0, 0.85, 0.65), 0.3, True)
            elif l["kind"] == "lamp":
                light(l["pos"], 12, (1.0, 0.75, 0.45), 0.1, False)
        for name, (rect, _) in ROOMS.items():
            (x0, z0), (x1, z1) = rect
            light(((x0 + x1) / 2, 1.5, (z0 + z1) / 2), 25 if name in ("hall", "bathroom") else 50,
                  (1.0, 0.95, 0.88), 1.2, False)
        sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
        sun.data.energy, sun.data.color = 1.5, (1.0, 0.92, 0.8)
        sun.rotation_euler = (math.radians(55), 0, math.radians(-50))
        scene.collection.objects.link(sun)
        scene.render.engine = "BLENDER_EEVEE"
        scene.eevee.taa_render_samples = 12
        res = (1280, 800)
    else:
        scene.render.engine = "BLENDER_WORKBENCH"
        scene.display.render_aa = "OFF"
        sh = scene.display.shading
        sh.light = "STUDIO"
        sh.color_type = "MATERIAL"
        sh.show_shadows = False
        sh.show_cavity = False
        sh.use_dof = False
        res = (640, 400)

    def shot(name, pos, target, lens=16, ortho=None, size=res):
        scene.render.resolution_x, scene.render.resolution_y = size
        cam.data.type = "ORTHO" if ortho else "PERSP"
        if ortho:
            cam.data.ortho_scale = ortho
        cam.data.lens = lens
        cam.location = Vector((pos[0], -pos[2], pos[1]))
        t = Vector((target[0], -target[2], target[1]))
        cam.rotation_euler = (t - cam.location).to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = os.path.join(preview_dir, name + ".png")
        bpy.ops.render.render(write_still=True)

    rooms = [only_room] if only_room else list(VIEWS)
    for room in rooms:
        for name, pos, target, lens in VIEWS[room]:
            if final and name not in FINAL_VIEWS:
                continue
            set_open(objs, name.startswith("openables"))
            shot(name, pos, target, lens)
    set_open(objs, False)
    if not only_room:
        for n in ("Ceiling", "Shades"):
            objs[n].hide_render = True
        shot("flat_top", (4.0, 30.0, 6.5 + 0.001), (4.0, 0.0, 6.5), ortho=14.0,
             size=(1000, 1500) if final else (500, 750))


# Builders by group. Static meshes of a group are merged into one node named after the
# group; openable doors and lids stay separate nodes (origin on the hinge).
GROUPS = [
    ("Floor", "shell", [make_floor]),
    ("Walls", "shell", [make_walls, make_wall_tiles, make_pictures]),
    ("Ceiling", "shell", [make_ceiling, make_ceiling_lamps]),
    ("Shades", "shell", [make_shades]),
    ("Trim", "shell", [make_trim]),
    ("Rugs", "shell", [make_rugs]),
    ("Kitchen", "kitchen", [make_fridge, make_counter, make_kitchen_shelf, make_table_and_chairs]),
    ("Living", "living", [make_sofa, make_coffee_table, make_floor_lamp, make_plant]),
    ("Bedroom", "bedroom", [make_bed, make_nightstand, make_wardrobe]),
    ("Bathroom", "bathroom", [make_bathtub, make_vanity, make_laundry_basket]),
    ("Hall", "hall", [make_front_door, make_coat_rack]),
]
OPENABLE_NODES = {"FridgeDoor", "OvenDoor", "CupboardADoor", "CupboardBDoorL", "CupboardBDoorR",
                  "LaundryBasketLid"}


def merge(name, objs):
    if len(objs) == 1:
        objs[0].name = name
        objs[0].data.name = name
        return objs[0]
    with bpy.context.temp_override(active_object=objs[0], selected_editable_objects=objs,
                                   selected_objects=objs):
        bpy.ops.object.join()
    objs[0].name = name
    objs[0].data.name = name
    return objs[0]


def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    make_materials()
    objs = {}
    for group, room, fns in GROUPS:
        if ONLY and room not in ("shell", ONLY):
            continue
        static = []
        for fn in fns:
            r = fn()
            for o in (r if isinstance(r, list) else [r]):
                if o.name in OPENABLE_NODES:
                    objs[o.name] = o
                else:
                    static.append(o)
        o = merge(group, static)
        objs[o.name] = o
    frame, glass, window_info = window_parts()
    objs[frame.name] = frame
    objs[glass.name] = glass
    for w in window_info:
        wname, room, wall, face, w0, w1, sill, head = w
        pos = face_point(face, 0.1, (sill + head) / 2, (w0 + w1) / 2)
        LIGHTS.append({"name": "Sun_" + wname, "kind": "window", "room": room, "pos": v3(pos)})
    for l in LIGHTS:
        empty(l["name"], l["pos"])
    check_zones(objs)
    counts = {k: tris(v) for k, v in objs.items()}
    print("TRIS", counts, "TOTAL", sum(counts.values()))
    if not ONLY:
        for o in bpy.context.scene.objects:
            o.select_set(True)
        os.makedirs(OUT_DIR, exist_ok=True)
        out = os.path.join(OUT_DIR, "flat.glb")
        bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_yup=True, export_apply=True,
                                  export_cameras=False, export_lights=False, use_selection=True)
        with open(os.path.join(OUT_DIR, "flat_layout.json"), "w") as fh:
            json.dump(layout(window_info), fh, indent=1)
            fh.write("\n")
        print("EXPORTED", out)
    if PREVIEW_DIR:
        os.makedirs(PREVIEW_DIR, exist_ok=True)
        render_previews(objs, PREVIEW_DIR, FINAL, ONLY)


# tools/blender/make_house.py imports this file for its furniture builders and helpers.
if __name__ == "__main__":
    build()
