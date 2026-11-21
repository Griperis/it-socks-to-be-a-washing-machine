"""Generate the house shell (assets/house/house.glb and assets/house/house_layout.json).

Run headless (cap the threads so the machine stays responsive):
    LP_NUM_THREADS=4 blender -b -t 4 -P tools/blender/make_house.py -- <out_dir> [preview_dir] [--final] [--only <level>]

  --only <level>  render only that level's previews (basement, ground, first, attic); still exports
  --final         render the previews with EEVEE instead of the cheap Workbench ones (half size,
                  1 sample, no shadows)

The family house on four levels (spec docs/llm/house/spec.md, ticket house/03), from the plan
house/01 (docs/art/house/plan.py: its rooms, doorways, windows, stair and shaft are copied here,
in the same coordinates, then house/37 made every room 10% bigger each way, Q995: walls, doors,
furniture and ceiling heights kept). The interior of the exterior walls spans x 0..10.1, z 0..8.34 (x east,
z south, north up); exterior walls 0.2 m outward, partitions 0.12 m. Levels by their floor y:

    basement  y -2.9  ceiling 2.7   workshop, laundry (washer, New Game start), boiler room,
                                    stair lobby, garage (the car, house/11)
    ground    y  0.0  ceiling 2.7   kitchen & dining, hall (front door), living room
    first     y  2.9  ceiling 2.6   home office (Q400), parents' bedroom, landing, bathroom,
                                    kids' room
    attic     y  5.8  sloped roof   the junk loft: ridge east-west over z 4.17, knee wall 0.4 m,
                                    pitch 37.4 deg, a dormer to the garden, gable windows

The house is built in parts (house/25, docs/art/house/pipeline.md), each with its own script and
glb: this shell (walls, floors, roof, stairs, windows, room doors, ceiling lamps, the shell's rugs),
the Elevator (make_elevator.py, assets/house/elevator.glb), the outside
(make_exterior.py, assets/house/exterior.glb) and the furniture (house_furniture/build.py, one glb
per piece). The furniture is not in this model: house_layout.json's placements[] lists every piece
and the game places it at load (game/house/house_parts.gd), with its colliders, crawl space, openables
and resting tops from its manifest entry. The Wardrobe Station's spot, doors and colliders are
still the flat's, moved here by placed(); its model is a Blender MCP asset (pipeline/05,
assets/wardrobe_station/wardrobe_station.glb) that the game stands on that spot.

The U stair (16 risers of 181 mm a storey, 299 mm going) is stacked in x 3.95..6.28, z 5.15..8.34 on
every storey: the west flight rises south from the floor to the half landing (z 7.24..8.34), the
east flight rises north to the next floor at z 5.15. The steps are real boxes (colliders the
Socks rest on); the player walks on a ramp over their nosings ("ramps", Layers.STAIRS), so the
pace is the same as on the floor. A newel wall parts the flights; the attic has a balustrade round
the stair void. Every room's doorway has a door leaf (house/21, ROOM_DOORS: not the open-plan ground
floor's), modelled shut, turning into its room; the front door is a closed leaf.
The Elevator (house/17, make_elevator.py) runs in the shaft (x 3.13..3.83, z 4.45..5.15); the shell
leaves its slab and partition openings (SHAFT, SILL_H, CAR_*). Plan revisions (house/11, Q428-Q431): the ground floor's WC is gone, the hall takes its
space; the basement storage is the garage, the car (an openable: cabin and boot, a crawl gap under
it) in its middle, the shelves, bikes and Sport cabinet round it; the floor slabs stop at the
south wall behind the stair windows, so the half-landing glass no longer crosses them. house/19
(Q453-Q458): the garage has a shut up-and-over door in its north wall (GARAGE_DOOR; the ramp down
to it is make_exterior.py's) in place of its north light well; the car stands 0.3 m from it; the
wall shelving moved to the south wall; a tall plant stands in the hall's corner where the WC was.

Axes, nodes and the openables are as in make_flat.py (whose builders and helpers this imports).
Mesh nodes: Floor, Ceiling, Walls, Trim, Windows, Glass, Roof, Stairs, Rugs, Bedroom (the
wardrobe); each room door's leaf is a node of its own, Door_<doorway> (Door_KidsLanding), origin
on its pin. The game adds the Elevator's nodes and the placed pieces (Props, game/house/house_parts.gd).
The Socks' colliders (physics/08) are collision-only objects <name>_<n>-convcolonly, not drawn
(make_sock_colliders(); docs/art/house/pipeline.md "The shell's collision").

Layout JSON (house_layout.json): the flat's fields (make_flat.py's docstring), every point and
box in absolute Godot metres, plus the levels. This script writes the shell's sections and keeps
KEPT_SECTIONS as they are: parts (each part's model and origin), placements[] (the furniture, edited
by hand: {name, piece (the manifest's), room, level, pos [x, z] (its footprint's centre), yaw
(degrees, turns its +z front), options: y (lifted over the floor), crawl (the crawl space under
it), rug, lamp (a lamp light at this piece-local point), names (container -> openable name), furn
(false: no furniture footprint), open_deg (part -> degrees), apart (containers whose doors
open one by one, each with its own toggle: the car's Cabin), decor (no resting tops)}) and elevator
{colliders, furniture, shaft, car, stops} (make_elevator.py), and props[] (carried props' start spots,
edited by hand: {kind, room, level, pos [x, y, z] (bottom centre), yaw (degrees)}; the encyclopedia
book, progression/54). The game adds pieces[], surfaces[] and the
pieces' colliders, furniture, crawl spaces, openables, lamps and rugs at load (game/house/house_parts.gd):
  levels[]             {name, y, height}: a level's floor y and ceiling height (the attic's is
                       its ridge)
  rooms[]              + level, y (floor), height (to the ceiling), stairs (true for a storey's
                       stair zone, y to the next floor), roof {knee, pitch, ridge_z, dormer} (the
                       attic: the ceiling follows the roof)
  doorways[]           + y; "open" links (no wall: a stair zone to the lobby it opens on, and
                       the top of each flight to the floor above) are doorways too
  furniture[]          + y (its base); crawl_spaces[] + y_min (the floor under it)
  pieces[]             (at load) {name, piece, room, level, min, max (its footprint), y (its base,
                       lifted for a hung piece), height, rug}: every placed piece (house/16)
  colliders[]          + piece (at load): the placed piece a collider belongs to (the heap bake
                       collides with the piece's drawn mesh instead; the player keeps the boxes)
  surfaces[]           (at load) {name (the piece), room, min, max, y (its highest spot), top (the
                       lowest free height over it)}: the resting tops found on the pieces' drawn
                       meshes (house/16; the manifest's spots, house_furniture/tops.py)
  ramps[]              {name, centre [x,y,z], size [w, thickness, length], pitch}: a box turned
                       by `pitch` about x, over a flight's nosings, for the player only
  devices              {tv, radio}: {pos, yaw, size, room}
  elevator             (kept as make_elevator.py wrote it: its docstring)
  locked_doors[]       {name (the floor it locks), level, from (the floor below), node (the leaf),
                       chain, padlock (their nodes, origins at chain_pos and padlock_pos), hinge
                       (the pin, on the floor), axis, open_deg (the turn that opens it: a door's back
                       over the flight, to rest along the newel wall; the attic's gate out onto the
                       first floor), min, max (the shut leaf, relative to the pin), width, chain_pos,
                       padlock_pos, stair_side (the side players come from: a door's stair side, the
                       gate's floor side), drop_y (the top step's or the floor's height, where the
                       dropped chain and padlock fall to), blocker (the gate's: {min, max}, the
                       players' box over it to the ceiling, until it opens)} (progression/03, house/36)
  room_doors[]         {name (its doorway), node, room (the room it swings into), other (the room
                       on its other side), level, hinge (the pin, on the floor), axis, open_deg (the
                       turn that opens it), min, max (the shut leaf, relative to the pin), width,
                       thickness, wall (the partition's), along (the shut leaf's direction from the
                       pin), into (the room's direction from the doorway)} (house/21)
  openables[].doors[]  + kind (hinge | slide: a drawer moves by open_m along axis), boxes (its
                       collision, relative to the pivot: a drawer's front and tray walls)
"""

import json
import math
import os
import sys

import bpy
import numpy as np
from mathutils import Matrix, Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_flat as F  # noqa: E402  (its build() runs only as a script)

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
FINAL = "--final" in argv
ONLY = argv[argv.index("--only") + 1] if "--only" in argv else None
_pos = [a for i, a in enumerate(argv) if not a.startswith("--") and (i == 0 or argv[i - 1] != "--only")]
OUT_DIR = _pos[0] if _pos else "."
PREVIEW_DIR = _pos[1] if len(_pos) > 1 else None
REPO = F.REPO
r3, v3 = F.r3, F.v3

# --- Contract dimensions --------------------------------------------------------------
W, D = 10.1, 8.34
EXT, PART = 0.2, 0.12
STOREY = 2.9
DOOR_H = 2.1
CLEAR_TOP = 2.5
CAB_D, CAB_ZONE_W, CAB_ZONE_D = 0.5, 1.8, 0.95
KNEE = 0.4
RIDGE_Z = D / 2
# The ridge keeps its height over the attic floor as the house grew (house/37, Q995: the ceilings
# keep their height), so the roof is a little flatter: about 37.4 deg.
RIDGE_H = KNEE + 3.8 * math.tan(math.radians(40.0))     # about 3.59 over the attic floor
PITCH = math.atan((RIDGE_H - KNEE) / RIDGE_Z)
TAN = math.tan(PITCH)
DORMER = (6.89, 8.69)                          # x range; full height to the south wall
DORMER_H = 2.2                                 # its flat ceiling over the attic floor
DORMER_Z = D - (DORMER_H - KNEE) / TAN         # where its ceiling meets the main roof

LEVELS = [("basement", -2.9, 2.7), ("ground", 0.0, 2.7), ("first", 2.9, 2.6), ("attic", 5.8, RIDGE_H)]
LY = {n: y for n, y, _ in LEVELS}
LH = {n: h for n, _, h in LEVELS}

STAIR = (3.95, 5.15, 6.28, 8.34)
LAND_Z = STAIR[3] - 1.1                        # the half landing: z 7.24..8.34
MID = (STAIR[0] + STAIR[2]) / 2                # the newel wall's middle
WEST = (STAIR[0], MID - 0.06)                  # the west flight's x range
EAST = (MID + 0.06, STAIR[2])
RISE = STOREY / 16
GOING = (LAND_Z - STAIR[1]) / 7
SHAFT = (3.13, 4.45, 3.83, 5.15)
# The Elevator (house/17, Q509-Q516): a stainless car about 0.6 m a side in the kitchen shaft,
# through all four levels. Each level's hatch has its sill at waist height (Q511) and slides up
# while the car stands there; a column of four floor buttons stands beside it (Q512).
SILL_H = 0.8                       # the hatch's sill (the car's floor) over the level's floor
CAR_Z = (4.53, 5.07)               # the car's inside across the shaft, and its hatch opening
CAR_H = 0.58                       # its inside height
CAR_T = 0.03                       # its floor and roof plates

# name, level, rect (x0, z0, x1, z1), floor finish
ROOMS = [
    ("workshop", "basement", (0.0, 0.0, 3.83, 3.16), "basement_tile"),
    ("laundry", "basement", (0.0, 3.28, 3.83, 8.34), "basement_tile"),
    ("boiler", "basement", (3.95, 0.0, 6.28, 1.98), "basement_tile"),
    ("stair_lobby", "basement", (3.95, 2.1, 6.28, 5.15), "basement_tile"),
    ("garage", "basement", (6.4, 0.0, 10.1, 8.34), "basement_tile"),
    ("stairs_basement", "basement", STAIR, "basement_tile"),
    ("kitchen", "ground", (0.0, 0.0, 3.83, 8.34), "kitchen_tile"),
    ("hall", "ground", (3.95, 0.0, 6.28, 5.15), "wood"),
    ("living", "ground", (6.4, 0.0, 10.1, 8.34), "wood"),
    ("stairs_ground", "ground", STAIR, "wood"),
    ("office", "first", (0.0, 0.0, 3.83, 3.16), "wood"),
    ("bedroom", "first", (0.0, 3.28, 3.83, 8.34), "wood"),
    ("landing", "first", (3.95, 0.0, 6.28, 5.15), "wood"),
    ("bathroom", "first", (6.4, 0.0, 10.1, 3.16), "bath_tile"),
    ("kids", "first", (6.4, 3.28, 10.1, 8.34), "wood"),
    ("stairs_first", "first", STAIR, "wood"),
    ("loft", "attic", (0.0, 0.0, 10.1, 8.34), "wood"),
]
STAIR_ROOMS = {"basement": "stairs_basement", "ground": "stairs_ground", "first": "stairs_first"}
LOBBY = {"basement": "stair_lobby", "ground": "hall", "first": "landing", "attic": "loft"}
UP = {"basement": "ground", "ground": "first", "first": "attic"}

# Open doorways: name, level, rect, between.
DOORWAYS = [
    ("WorkshopLobby", "basement", (3.83, 2.18, 3.95, 3.08), ["workshop", "stair_lobby"]),
    ("LaundryLobby", "basement", (3.83, 3.38, 3.95, 4.28), ["laundry", "stair_lobby"]),
    ("BoilerLobby", "basement", (4.65, 1.98, 5.55, 2.1), ["boiler", "stair_lobby"]),
    ("LobbyGarage", "basement", (6.28, 4.15, 6.4, 5.05), ["stair_lobby", "garage"]),
    ("KitchenHall", "ground", (3.83, 2.18, 3.95, 3.08), ["kitchen", "hall"]),
    ("HallLiving", "ground", (6.28, 4.15, 6.4, 5.05), ["hall", "living"]),
    ("OfficeLanding", "first", (3.83, 2.18, 3.95, 3.08), ["office", "landing"]),
    ("BedroomLanding", "first", (3.83, 3.38, 3.95, 4.28), ["bedroom", "landing"]),
    ("BathroomLanding", "first", (6.28, 2.18, 6.4, 3.08), ["bathroom", "landing"]),
    ("KidsLanding", "first", (6.28, 4.15, 6.4, 5.05), ["kids", "landing"]),
]
# The room doors (house/21, Q517): a leaf in every room's doorway but the open-plan ground floor's
# (the kitchen, dining, living room and hall keep open arches). Each turns DOOR_OPEN_DEG into its
# room about a pin at the room-side corner of its hinge jamb; the hinge end ("lo": the doorway's
# x0/z0 end, "hi": x1/z1) keeps the swing clear of the room's furniture (tests/room_test.gd case_layout_rules).
# doorway -> (the room it swings into, the hinge end)
ROOM_DOORS = {
    "WorkshopLobby": ("workshop", "hi"),
    "LaundryLobby": ("laundry", "lo"),
    "BoilerLobby": ("boiler", "lo"),
    "LobbyGarage": ("stair_lobby", "hi"),   # into the lobby: in the garage its open leaf boxed the car in
    "OfficeLanding": ("office", "hi"),
    "BedroomLanding": ("bedroom", "lo"),
    "BathroomLanding": ("bathroom", "hi"),
    "KidsLanding": ("kids", "hi"),
}
LEAF_T = 0.04                      # the leaf's thickness
LEAF_GAP = 0.017                   # between the leaf and the jamb linings (0.015 each)
DOOR_OPEN_DEG = 90.0
ROOM_DOOR_RECS = []
FRONT_DOOR = (5.28, 6.18)          # in the north wall, ground floor
# The garage door (house/19, Q453): a closed up-and-over door in the garage's north wall, on the
# street side, centred on the car; a ramp outside (make_exterior.py) runs down to it. It never opens.
GARAGE_DOOR = (7.05, 9.45)         # x along the north wall, basement floor up to DOOR_H
# The locked doors (progression/03, Q620, Q638): a padlocked plank door at the top of the ground's
# and the first floor's flight, a padlocked baby gate at the foot of the attic's (house/36; the U
# landing is open, no door, frame or window: house/43); each floor but the basement starts locked. Its frame's
# posts and the leaf's thickness.
LOCK_POST = 0.07
# The leaf keeps its width as the flights grew (house/37, Q995: doors keep their size); the posts
# take up the rest of the flight's width.
LOCK_LEAF_W = 0.826
LOCK_FRAME_D = 0.1
LOCK_LEAF_T = 0.045
# The attic's baby gate at the foot of its flight (house/36, designer 2026-11-06): its leaf's top,
# its posts' width and depth, the leaf's thickness.
GATE_H = 0.8
GATE_POST = 0.07
GATE_D = 0.07
GATE_LEAF_T = 0.035
LOCKED_DOOR_RECS = []

# Windows: name, wall (N/S/W/E), s0, s1 along the wall, sill y, head y (absolute), frosted.
_B, _G, _F, _A = -2.9, 0.0, 2.9, 5.8
WINDOWS = [
    ("WorkshopWell", "N", 1.16, 2.36, _B + 1.75, _B + 2.45, False),
    ("LaundryWellW", "W", 6.19, 7.19, _B + 1.75, _B + 2.45, False),
    ("LaundryWellS", "S", 2.58, 3.58, _B + 1.75, _B + 2.45, False),
    ("GarageWellE", "E", 3.11, 4.11, _B + 1.75, _B + 2.45, False),
    ("KitchenN", "N", 2.55, 3.55, _G + 1.1, _G + 2.15, False),
    ("KitchenW", "W", 6.64, 7.74, _G + 0.9, _G + 2.15, False),
    ("KitchenS", "S", 0.76, 2.76, _G + 0.9, _G + 2.15, False),
    ("HallN", "N", 4.25, 4.75, _G + 1.3, _G + 2.0, False),      # the WC's window, now the hall's
    ("LivingN", "N", 7.63, 8.83, _G + 0.9, _G + 2.15, False),
    ("LivingE", "E", 4.01, 5.41, _G + 0.9, _G + 2.15, False),
    ("LivingS", "S", 7.03, 9.43, _G + 0.9, _G + 2.15, False),
    ("StairGround", "S", 4.35, 5.85, _G + 2.35, _G + 3.45, False),
    ("OfficeN", "N", 1.16, 2.36, _F + 0.9, _F + 2.1, False),
    ("OfficeW", "W", 1.05, 2.15, _F + 0.9, _F + 2.1, False),
    ("BedroomW", "W", 7.17, 7.97, _F + 0.9, _F + 2.1, False),
    ("BedroomS", "S", 1.39, 2.79, _F + 0.9, _F + 2.1, False),
    ("LandingN", "N", 4.55, 5.65, _F + 0.9, _F + 2.1, False),
    ("Bathroom", "N", 7.18, 8.18, _F + 1.3, _F + 2.0, True),
    ("KidsS", "S", 7.09, 8.59, _F + 0.9, _F + 2.1, False),
    ("GableW", "W", 2.11, 2.81, _A + 0.8, _A + 1.7, False),
    ("GableE", "E", 2.11, 2.81, _A + 0.8, _A + 1.7, False),
    ("Dormer", "S", 7.19, 8.39, _A + 0.9, _A + 1.95, False),
]
# Wall faces: (wall, run axis, face coordinate, inward sign, s0, s1), as make_flat's FACES.
SIDES = {"N": ("N", "x", 0.0, +1, 0.0, W), "S": ("S", "x", D, -1, 0.0, W),
         "W": ("W", "z", 0.0, +1, 0.0, D), "E": ("E", "z", W, -1, 0.0, D)}

# Cabinet spots (progression/52): spot id, its default Collection (the one standing there when a
# game draws none: the tests, the shots; "" for none), room, level, wall, centre along the wall.
# A New Game draws the Collection at each spot (CabinetPlan, tuning "stages").
CABINETS = [
    ("laundry", "simple", "laundry", "basement", "S", 1.32),
    ("garage", "sport", "garage", "basement", "E", 7.24),
    ("kitchen", "food", "kitchen", "ground", "W", 4.93),
    ("living", "patterns", "living", "ground", "E", 1.98),
    ("kids_north", "animals", "kids", "first", "N3", 7.68),    # the kids' room's north partition (z 3.28)
    ("kids_east", "superhero", "kids", "first", "E", 5.1),
    ("loft_west", "winter", "loft", "attic", "W", 4.16),
    ("loft_east", "space", "loft", "attic", "E", 4.16),
]
WASHER_POS = (0.36, LY["basement"], 4.93)        # 0.7 x 0.95 x 0.7, back to the laundry's west wall
WASHER_YAW = math.pi / 2                         # modelled facing +z; turned to face +x
WASHER_ZONE = ((0.0, 4.53), (1.24, 5.33))
SPAWN = (1.58, LY["basement"], 5.59)
CLOCK_POS = (9.49, 1.95, 0.0)
# The bedroom mirror hangs over the dresser on the west wall (house/05).
MIRROR = {"pos": (0.03, LY["first"] + 1.55, 6.55), "yaw": math.pi / 2, "radius": 0.26, "room": "bedroom"}
DEVICES = {
    # The widescreen set on its 1.5 m console (house/04, flat/62): as far west as its back corner
    # allows, turned to face the sofa; its east end reaches in front of the north window.
    "tv": {"pos": [7.22, 0.0, 0.4], "yaw": r3(math.atan2(8.12 - 7.22, 5.87 - 0.4)), "size": [1.5, 1.22, 0.46],
           "room": "living"},
    "radio": {"pos": [1.915, 1.55, 0.115], "yaw": 0.0, "size": [0.16, 0.11, 0.09], "room": "kitchen"},
}

POSTS = [(3.74, 1.71), (8.56, 1.71), (2.64, 6.64), (9.22, 6.64)]

WALL_COLOURS = {
    "workshop": (0.86, 0.84, 0.78), "laundry": (0.80, 0.91, 0.88), "boiler": (0.84, 0.81, 0.78),
    "stair_lobby": (0.91, 0.88, 0.82), "garage": (0.88, 0.86, 0.80), "stairs_basement": (0.91, 0.88, 0.82),
    "kitchen": (0.96, 0.89, 0.77), "hall": (0.97, 0.86, 0.62),
    "living": (0.96, 0.89, 0.77), "stairs_ground": (0.97, 0.86, 0.62), "office": (0.90, 0.86, 0.94),
    "bedroom": (0.94, 0.79, 0.73), "landing": (0.97, 0.86, 0.62), "bathroom": (0.80, 0.91, 0.88),
    "kids": (0.98, 0.86, 0.80), "stairs_first": (0.97, 0.86, 0.62), "loft": (0.93, 0.85, 0.72),
}
EXTRA_MATERIALS = {
    "basement_tile": (F.srgb(0.72, 0.71, 0.68), 0.7, 0.0, 0.0, 1.0),
    "cardboard": (F.srgb(0.78, 0.62, 0.42), 0.9, 0.0, 0.0, 1.0),
    "stainless": (F.srgb(0.80, 0.81, 0.82), 0.32, 0.85, 0.0, 1.0),
    "rafter": (F.srgb(0.62, 0.45, 0.30), 0.8, 0.0, 0.0, 1.0),
    "roof_tile": (F.srgb(0.62, 0.30, 0.24), 0.8, 0.0, 0.0, 1.0),
    "loft_boards": (F.srgb(0.80, 0.66, 0.48), 0.8, 0.0, 0.0, 1.0),
    "garage_door": (F.srgb(0.36, 0.52, 0.55), 0.5, 0.0, 0.0, 1.0),     # the front door's teal (house/19)
    "chain": (F.srgb(0.42, 0.43, 0.45), 0.35, 1.0, 0.0, 1.0),          # the locks' chains (progression/03)
    "lock_dark": (F.srgb(0.08, 0.07, 0.06), 0.6, 0.0, 0.0, 1.0),       # a padlock's keyhole
}
for _room, _c in WALL_COLOURS.items():
    EXTRA_MATERIALS["wall_" + _room] = (F.srgb(*_c), 0.9, 0.0, 0.0, 1.0)

RAMPS = []


# --- Lookups --------------------------------------------------------------------------

def level_of(y):
    best = LEVELS[0][0]
    for name, ly, _ in LEVELS:
        if y >= ly - 0.05:
            best = name
    return best


def room_top(name, level):
    return STOREY if name.startswith("stairs_") else LH[level]


def room_at3(x, y, z):
    for name, level, (x0, z0, x1, z1), _ in ROOMS:
        ly = LY[level]
        if x0 - 1e-4 <= x <= x1 + 1e-4 and z0 - 1e-4 <= z <= z1 + 1e-4 and ly - 0.01 <= y <= ly + room_top(name, level):
            return name
    return None


def wall_mat(c, n):
    if abs(n.y) > 0.5:
        return "wall_outside"
    p = c + n * 0.05
    room = room_at3(p.x, p.y, p.z)
    return "wall_" + room if room else "wall_outside"


def fp(x0, z0, x1, z1):
    return {"min": [r3(min(x0, x1)), r3(min(z0, z1))], "max": [r3(max(x0, x1)), r3(max(z0, z1))]}


# --- Moving the flat's pieces into the house -----------------------------------------------

def _turn(x, z, yaw):
    c, s = math.cos(yaw), math.sin(yaw)
    return x * c + z * s, -x * s + z * c


def placed(fns, room, yaw=0.0, off=(0.0, 0.0, 0.0)):
    """Runs make_flat builders (which work in flat space) and moves what they made into the
    house: turned by `yaw` about the origin (quarter turns only: a box stays a box), then moved by
    `off`. Their layout records are moved alike and given `room`. Openables only move."""
    regs = [F.COLLIDERS, F.SURFACES, F.CRAWL, F.OPENABLES, F.FURNITURE, F.LIGHTS, F.RUGS]
    before = [len(r) for r in regs]
    ward = dict(F.WARDROBE)
    objs = []
    for fn in fns:
        r = fn()
        objs += r if isinstance(r, list) else [r]
    ox, oy, oz = off

    def pt(p):
        x, z = _turn(p[0], p[2], yaw)
        return [r3(x + ox), r3(p[1] + oy), r3(z + oz)]

    def rect(d):
        (ax, az), (bx, bz) = _turn(d["min"][0], d["min"][1], yaw), _turn(d["max"][0], d["max"][1], yaw)
        d["min"], d["max"] = [r3(min(ax, bx) + ox), r3(min(az, bz) + oz)], [r3(max(ax, bx) + ox), r3(max(az, bz) + oz)]

    def box3(d):
        a, b = pt(d["min"]), pt(d["max"])
        d["min"], d["max"] = [min(a[i], b[i]) for i in range(3)], [max(a[i], b[i]) for i in range(3)]

    for c in F.COLLIDERS[before[0]:]:
        box3(c)
    for s in F.SURFACES[before[1]:]:
        rect(s)
        s["y"] = r3(s["y"] + oy)
        s["room"] = room
    for c in F.CRAWL[before[2]:]:
        rect(c)
        c["y_min"] = r3(oy)
        c["y_max"] = r3(c["y_max"] + oy)
        c["room"] = room
    for o in F.OPENABLES[before[3]:]:
        assert yaw == 0.0, "an openable only moves"
        o["room"] = room
        for d in o["doors"]:
            d["hinge"] = pt(d["hinge"])
        box3(o["interior"])
    for f in F.FURNITURE[before[4]:]:
        rect(f)
        f["y"] = r3(oy)
        f["room"] = room
    for l in F.LIGHTS[before[5]:]:
        l["pos"] = pt(l["pos"])
        l["room"] = room
    for g in F.RUGS[before[6]:]:
        rect(g)
        g["top_y"] = r3(g["top_y"] + oy)
        g["room"] = room
    if F.WARDROBE and F.WARDROBE != ward:
        assert yaw == 0.0
        F.WARDROBE["pos"] = pt(F.WARDROBE["pos"])
        F.WARDROBE["room"] = room
        rect(F.WARDROBE["zone"])
        for d in F.WARDROBE["doors"]:
            d["hinge"] = pt(d["hinge"])
        box3(F.WARDROBE["interior"])
    # The meshes: static ones have their vertices in flat space (origin at 0), doors and lids
    # their origin on the hinge.
    for o in objs:
        if o.name in F.OPENABLE_NODES:
            o.location = (o.location.x + ox, o.location.y - oz, o.location.z + oy)
            continue
        me = o.data
        for v in me.vertices:
            bx, by, bz = v.co
            x, z = _turn(bx, -by, yaw)
            v.co = Vector((x + ox, -(z + oz), bz + oy))
        me.update()
    return objs


# --- Small builders ---------------------------------------------------------------------

def col(name, x0, x1, y0, y1, z0, z1, sock=True):
    """A layout collider (the player's); also the Socks' unless `sock` is False (physics/08)."""
    F.col(name, x0, x1, y0, y1, z0, z1)
    if not sock:
        NO_SOCK.add(len(F.COLLIDERS) - 1)


# --- The Socks' colliders (physics/08, Q795) ----------------------------------------------
# The Socks never collide with the shell as drawn: they meet authored simple shapes, exported as
# Godot collision-only objects <name>_<n>-convcolonly (docs/art/pipeline_mcp.md, Q771), which the
# game gathers into one static body (game/house/house_parts.gd). They are every layout collider but the
# roof's and the dormer cheeks' steps (the player's: the Socks meet the roof's own slabs), plus
# what the layout leaves out: sills, window frames and glass, door casings and linings, rafters,
# the attic balustrade's rails and spindles, the locked doors' leaves, lamps, rugs. A shape of 8
# corners that make a box becomes a box (turned or not); anything else stays a convex hull. Each
# is in game axes (x east, y up, z south) and matches the drawn surface within 5 mm where Socks
# rest (Q795).
SOCK_COLS = []
SOCK_SKIP = ("Roof", "Dormer", "Balustrade")
NO_SOCK = set()   # the layout colliders (by index) the Socks meet otherwise
SOCK_FLOOR_BASE = 0.5   # the basement floor's Sock slab depth (m; nothing under it)


def sock_box(name, x0, x1, y0, y1, z0, z1):
    xa, xb, za, zb = min(x0, x1), max(x0, x1), min(z0, z1), max(z0, z1)
    SOCK_COLS.append((name, [(x, y, z) for x in (xa, xb) for y in (y0, y1) for z in (za, zb)]))


def sock_hull(name, points):
    SOCK_COLS.append((name, [tuple(p) for p in points]))


def sbox(name, bm):
    """Notes the axis box round a drawn primitive as a Sock collider; returns the primitive."""
    xs, ys, zs = ([v.co[i] for v in bm.verts] for i in range(3))
    sock_box(name, min(xs), max(xs), min(ys), max(ys), min(zs), max(zs))
    return bm


def shull(name, bm):
    """Notes a drawn primitive's convex hull as a Sock collider; returns the primitive."""
    sock_hull(name, [v.co[:] for v in bm.verts])
    return bm


def sock_face_box(name, face, d0, d1, y0, y1, s0, s1):
    (x0, _, z0), (x1, _, z1) = F.face_point(face, d0, 0, s0), F.face_point(face, d1, 0, s1)
    sock_box(name, x0, x1, y0, y1, z0, z1)


def make_sock_colliders():
    """One collision-only object per Sock collider (after the level split: they are not drawn).
    Returns their count and how many are boxes."""
    import bmesh
    for i, c in enumerate(F.COLLIDERS):
        if c["name"] not in SOCK_SKIP and i not in NO_SOCK:
            (x0, y0, z0), (x1, y1, z1) = c["min"], c["max"]
            sock_box(c["name"], x0, x1, y0, y1, z0, z1)
    seen = {}
    boxes = 0
    for name, pts in SOCK_COLS:
        n = seen.get(name, 0)
        seen[name] = n + 1
        bm = bmesh.new()
        verts = [bm.verts.new((x, -z, y)) for x, y, z in pts]
        bmesh.ops.remove_doubles(bm, verts=verts, dist=1e-5)
        hull = bmesh.ops.convex_hull(bm, input=bm.verts[:])
        inside = {g for g in hull["geom_interior"] + hull["geom_unused"] if isinstance(g, bmesh.types.BMVert)}
        bmesh.ops.delete(bm, geom=list(inside), context="VERTS")
        assert bm.faces, "a flat Sock collider: %s %s" % (name, pts)
        boxes += len(pts) == 8 and len(bm.verts) == 8
        me = bpy.data.meshes.new("%s_%d" % (name, n))
        bm.to_mesh(me)
        bm.free()
        o = bpy.data.objects.new("%s_%d-convcolonly" % (name, n), me)
        o.display_type = "WIRE"
        o.hide_render = True
        bpy.context.scene.collection.objects.link(o)
    return len(SOCK_COLS), boxes


def furn(name, room, rect, y, height):
    x0, z0, x1, z1 = rect
    F.FURNITURE.append({"name": name, "room": room, "min": [r3(x0), r3(z0)], "max": [r3(x1), r3(z1)],
                        "y": r3(y), "height": r3(height)})


def hexa(corners):
    """A six-faced solid from 8 corners, indexed by (sx, sy, sz) in {0, 1}."""
    bm = F.box(0, 1, 0, 1, 0, 1)
    for v in bm.verts:
        v.co = Vector(corners[(int(v.co.x > 0.5), int(v.co.y > 0.5), int(v.co.z > 0.5))])
    bm.normal_update()
    import bmesh
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bm


def grid_rects(mask, step):
    """Greedy rectangles covering the True cells of a 2D mask (rows z, columns x)."""
    out, open_runs = [], {}
    nz, nx = mask.shape
    for j in range(nz + 1):
        runs = set()
        if j < nz:
            row = mask[j]
            i = 0
            while i < nx:
                if row[i]:
                    k = i
                    while k < nx and row[k]:
                        k += 1
                    runs.add((i, k))
                    i = k
                else:
                    i += 1
        nxt = {}
        for run, start in open_runs.items():
            if run in runs:
                nxt[run] = start
            else:
                out.append((run[0] * step, start * step, run[1] * step, j * step))
        for run in runs:
            if run not in nxt:
                nxt[run] = j
        open_runs = nxt
    return out


def cut(rects, xs, zs):
    out = []
    for x0, z0, x1, z1 in rects:
        cx = [x0] + sorted(c for c in xs if x0 + 0.01 < c < x1 - 0.01) + [x1]
        cz = [z0] + sorted(c for c in zs if z0 + 0.01 < c < z1 - 0.01) + [z1]
        for a, b in zip(cx, cx[1:]):
            for c, d in zip(cz, cz[1:]):
                out.append((a, c, b, d))
    return out


# --- The shell ------------------------------------------------------------------------------

def free_rects(level):
    out = [r for _, lv, r, _ in ROOMS if lv == level]
    out += [r for _, lv, r, _ in DOORWAYS if lv == level]
    return out


def make_partitions():
    """Every level's partition walls: the footprint minus its rooms, doorways and stair zone,
    floor to ceiling, cut at the room edges so each face gets its room's paint, and the lintels
    over the doorways."""
    p = F.Part()
    step = 0.01
    for level, y0, h in LEVELS:
        if level == "attic":
            continue
        mask = np.ones((int(round(D / step)), int(round(W / step))), dtype=bool)
        holes = wall_holes(level)
        for x0, z0, x1, z1 in free_rects(level) + [hole[0] for hole in holes]:
            mask[int(round(z0 / step)):int(round(z1 / step)), int(round(x0 / step)):int(round(x1 / step))] = False
        xs = {c for _, lv, r, _ in ROOMS if lv == level for c in (r[0], r[2])}
        zs = {c for _, lv, r, _ in ROOMS if lv == level for c in (r[1], r[3])}
        for x0, z0, x1, z1 in cut(grid_rects(mask, step), xs, zs):
            p.add(F.box(x0, x1, y0, y0 + h, z0, z1), wall_mat)
            col("Wall", x0, x1, y0, y0 + h, z0, z1)
        for name, lv, (x0, z0, x1, z1), _ in DOORWAYS:
            if lv == level:
                p.add(F.box(x0, x1, y0 + DOOR_H, y0 + h, z0, z1), wall_mat)
                col("Wall", x0, x1, y0 + DOOR_H, y0 + h, z0, z1)
        # A hatch through a partition: the wall under its sill (drawn under the sill's plate) and
        # over its head.
        for (x0, z0, x1, z1), lo, hi in holes:
            p.add(F.box(x0, x1, y0, lo - CAR_T, z0, z1), wall_mat)
            col("Wall", x0, x1, y0, lo, z0, z1, sock=False)
            sock_box("Wall", x0, x1, y0, lo - CAR_T, z0, z1)
            p.add(F.box(x0, x1, hi, y0 + h, z0, z1), wall_mat)
            col("Wall", x0, x1, hi, y0 + h, z0, z1)
    return p.to_object("Partitions")


def wall_holes(level):
    """The Elevator's hatch openings through a partition on `level`: [(rect, sill y, head y)]."""
    if level != "first":
        return []
    f = LY[level] + SILL_H
    return [((SHAFT[2], CAR_Z[0], STAIR[0], CAR_Z[1]), f, f + CAR_H)]


def roof_y(z):
    """The roof's underside over the attic floor at z (absolute y)."""
    return LY["attic"] + KNEE + min(z, D - z) * TAN


def wall_with_holes(p, face_name, t0, t1, s0, s1, y0, y1, holes, name="Wall"):
    """A wall slab along a side, t0..t1 across, s0..s1 along, y0..y1 high, with rectangular
    holes (s0, s1, y0, y1)."""
    axis = SIDES[face_name][1]
    cuts = sorted({s0, s1} | {h[0] for h in holes if s0 < h[0] < s1} | {h[1] for h in holes if s0 < h[1] < s1})
    for a, b in zip(cuts, cuts[1:]):
        ys = [(y0, y1)]
        for hs0, hs1, hy0, hy1 in holes:
            if hs0 <= a + 1e-6 and hs1 >= b - 1e-6:
                ys = [q for yy in ys for q in _minus(yy, (hy0, hy1))]
        for ya, yb in ys:
            if axis == "x":
                p.add(F.box(a, b, ya, yb, t0, t1), wall_mat)
                col(name, a, b, ya, yb, t0, t1)
            else:
                p.add(F.box(t0, t1, ya, yb, a, b), wall_mat)
                col(name, t0, t1, ya, yb, a, b)


def _minus(span, hole):
    a, b = span
    c, d = hole
    if d <= a or c >= b:
        return [span]
    out = []
    if c > a + 1e-6:
        out.append((a, c))
    if d < b - 1e-6:
        out.append((d, b))
    return out


def make_exterior_walls():
    """The four outer walls from the basement floor up: the long ones to the knee wall (higher
    over the dormer), the gables in bands up under the roof."""
    p = F.Part()
    bottom = LY["basement"] - 0.1
    knee = LY["attic"] + KNEE
    holes = {k: [] for k in SIDES}
    for _, side, s0, s1, sill, head, _ in WINDOWS:
        holes[side].append((s0, s1, sill, head))
    holes["N"].append((FRONT_DOOR[0], FRONT_DOOR[1], 0.0, DOOR_H))
    holes["N"].append((GARAGE_DOOR[0], GARAGE_DOOR[1], LY["basement"], LY["basement"] + DOOR_H))
    wall_with_holes(p, "N", -EXT, 0.0, -EXT, W + EXT, bottom, knee, holes["N"])
    s_holes = [h for h in holes["S"] if h[3] <= knee]
    wall_with_holes(p, "S", D, D + EXT, -EXT, W + EXT, bottom, knee, s_holes)
    # The dormer's front wall over the knee.
    dx0, dx1 = DORMER[0] - 0.2, DORMER[1] + 0.2
    d_holes = [h for h in holes["S"] if h[3] > knee]
    wall_with_holes(p, "S", D, D + EXT, dx0, dx1, knee, LY["attic"] + DORMER_H, d_holes)
    for side, t0, t1 in (("W", -EXT, 0.0), ("E", W, W + EXT)):
        low = [h for h in holes[side] if h[3] <= knee]
        wall_with_holes(p, side, t0, t1, 0.0, D, bottom, knee, low)
        high = [h for h in holes[side] if h[3] > knee]
        band = 0.05
        y = knee
        while y < LY["attic"] + RIDGE_H + 0.25:
            yb = y + band
            d = max(0.0, (y - knee) / TAN - 0.25)
            z0, z1 = max(-EXT, d - EXT), min(D + EXT, D - d + EXT)
            if z1 > z0:
                hs = [(h[0], h[1], h[2], h[3]) for h in high]
                wall_with_holes(p, side, t0, t1, z0, z1, y, yb, hs)
            y = yb
    return p.to_object("ExteriorWalls")


# The Cellar hatch's opening (x0, z0, x1, z1): make_grotto.py's HATCH (2.70, 1.55), 0.75 m square.
GROTTO_HATCH = (2.325, 1.175, 3.075, 1.925)


def _without(rect, cut):
    """The rect (x0, z0, x1, z1) less `cut`, as up to four rects."""
    x0, z0, x1, z1 = rect
    cx0, cz0, cx1, cz1 = cut
    if cx0 >= x1 or cx1 <= x0 or cz0 >= z1 or cz1 <= z0:
        return [rect]
    out = []
    if cz0 > z0:
        out.append((x0, z0, x1, cz0))
    if cz1 < z1:
        out.append((x0, cz1, x1, z1))
    za, zb = max(z0, cz0), min(z1, cz1)
    if cx0 > x0:
        out.append((x0, za, cx0, zb))
    if cx1 < x1:
        out.append((cx1, za, x1, zb))
    return out


def make_floors_and_ceilings():
    fl, ce = F.Part(), F.Part()
    # Round the stair zone; behind it the slabs stop at the south wall's inner face, so the stair
    # windows (which span a floor's level) have no slab through them (house/11).
    hole = [(-EXT, -EXT, W + EXT, STAIR[1]), (-EXT, STAIR[1], STAIR[0], D + EXT), (STAIR[2], STAIR[1], W + EXT, D + EXT)]
    full = [(-EXT, -EXT, W + EXT, D + EXT)]
    # The Elevator's shaft runs through every slab above the basement floor (house/21).
    hole = [r for rect in hole for r in _without(rect, SHAFT)]
    # The Cellar hatch's opening in the workshop's floor, down to the Lost Sock Grotto (house/38,
    # Q1053; its leaf, shaft and ladder are make_grotto.py's).
    full = [r for rect in full for r in _without(rect, GROTTO_HATCH)]
    below = None
    for level, y0, h in LEVELS:
        mat = "loft_boards" if level == "attic" else ("basement_tile" if level == "basement" else "wood")
        # The Socks meet each floor as one thick slab (physics/26, Q895): down to the ceiling of the
        # level under it (the floor and that ceiling's slabs as one box, 0.2-0.3 m), the basement's
        # SOCK_FLOOR_BASE deep; a falling Sock never tunnels through 10 cm. The players keep both.
        sock_y = y0 - SOCK_FLOOR_BASE if below is None else below
        below = y0 + h
        for x0, z0, x1, z1 in (full if level == "basement" else hole):
            fl.add(F.box(x0, x1, y0 - 0.1, y0, z0, z1), mat, uv_scale=2.0)
            col("Floor", x0, x1, y0 - 0.1, y0, z0, z1, sock=False)
            sock_box("Floor", x0, x1, sock_y, y0, z0, z1)
        for name, lv, rect, finish in ROOMS:
            if lv == level and finish.endswith("_tile") and finish != "basement_tile":
                for x0, z0, x1, z1 in _without(rect, SHAFT):
                    fl.add(F.box(x0, x1, y0 - 0.01, y0 + 0.003, z0, z1), finish,
                           uv_scale=0.6 if finish == "bath_tile" else 1.2)
        if level == "attic":
            continue
        top = y0 + STOREY - 0.1
        for x0, z0, x1, z1 in hole:
            ce.add(F.box(x0, x1, y0 + h, top, z0, z1), "ceiling")
            col("Ceiling", x0, x1, y0 + h, top, z0, z1, sock=False)  # the floor's Sock slab above
    return fl.to_object("Floor"), ce.to_object("CeilingSlabs")


def make_roof():
    """Both roof slopes (rafters inside, tiles outside), the dormer (cheeks, flat roof) and the
    roof's colliders: steps of 0.1 m along the slope, under the underside."""
    p = F.Part()
    ay = LY["attic"]
    eave = ay + KNEE
    th = 0.22
    ov = 0.45
    n_up = (math.cos(PITCH), math.sin(PITCH))          # (y, z-ish) magnitudes of the normal

    def slab(x0, x1, za, zb, south):
        # Underside line from za to zb (za nearer the eave), thickness th above it.
        def under(z):
            return eave + ((D - z) if south else z) * TAN
        nz = math.sin(PITCH) * (1 if south else -1)
        ny = math.cos(PITCH)
        cs = {}
        for sx, x in ((0, x0), (1, x1)):
            for sz, z in ((0, za), (1, zb)):
                y = under(z)
                cs[(sx, 0, sz)] = (x, y, z)
                cs[(sx, 1, sz)] = (x, y + ny * th, z + nz * th)
        return hexa(cs)

    # North slope: eave (with overhang) to the ridge; south: the ridge to the eave, the dormer cut.
    # The Socks meet these slabs (and the rafters) as they are drawn, turned boxes (physics/08).
    p.add(shull("RoofSlab", slab(-ov, W + ov, -ov, RIDGE_Z, False)), "rafter")
    p.add(shull("RoofSlab", slab(-ov, DORMER[0], RIDGE_Z, D + ov, True)), "rafter")
    p.add(shull("RoofSlab", slab(DORMER[1], W + ov, RIDGE_Z, D + ov, True)), "rafter")
    p.add(shull("RoofSlab", slab(DORMER[0], DORMER[1], RIDGE_Z, DORMER_Z, True)), "rafter")
    # Ridge board and the tiles' outer skin (a shade of red over the rafters).
    p.add(F.box(-ov, W + ov, ay + RIDGE_H + 0.15, ay + RIDGE_H + 0.32, RIDGE_Z - 0.09, RIDGE_Z + 0.09), "roof_tile")
    # Rafters inside, every 0.9 m.
    x = 0.45
    while x < W:
        for south in (False, True):
            if south and DORMER[0] - 0.1 < x < DORMER[1] + 0.1:
                continue
            za, zb = (0.0, RIDGE_Z - 0.05) if not south else (RIDGE_Z + 0.05, D)
            cs = {}
            for sx, xx in ((0, x - 0.04), (1, x + 0.04)):
                for sz, z in ((0, za), (1, zb)):
                    y = eave + ((D - z) if south else z) * TAN
                    cs[(sx, 0, sz)] = (xx, y - 0.12, z)
                    cs[(sx, 1, sz)] = (xx, y + 0.01, z)
            p.add(shull("Rafter", hexa(cs)), "rafter")
        x += 0.9
    # Dormer: cheeks and a flat roof.
    top = ay + DORMER_H
    for xa, xb in ((DORMER[0] - 0.2, DORMER[0]), (DORMER[1], DORMER[1] + 0.2)):
        outline = [(eave - 0.05, D + EXT), (top + 0.2, D + EXT), (top + 0.2, DORMER_Z - 0.25)]
        p.add(shull("DormerCheek", F.prism("x", outline, xa, xb)), "wall_outside")
        z = DORMER_Z - 0.2
        while z < D:
            col("Dormer", xa, xb, roof_y(min(z + 0.1, D)) - 0.05, top + 0.2, z, z + 0.1)
            z += 0.1
    p.add(F.box(DORMER[0] - 0.3, DORMER[1] + 0.3, top, top + 0.2, DORMER_Z, D + ov), "roof_tile")
    p.add(F.box(DORMER[0], DORMER[1], top - 0.01, top, DORMER_Z, D), "ceiling")
    col("Dormer", DORMER[0], DORMER[1], top, top + 0.2, DORMER_Z - 0.3, D + EXT)
    sock_box("DormerRoof", DORMER[0], DORMER[1], top - 0.01, top + 0.2, DORMER_Z - 0.3, D + EXT)
    # Colliders: 0.1 m steps under the slope, the eave side of each step at the underside.
    k = 0.1
    z = 0.0
    while z < RIDGE_Z - 1e-6:
        col("Roof", -EXT, W + EXT, eave + z * TAN, ay + RIDGE_H + 0.3, z, z + k)
        z += k
    z = RIDGE_Z
    while z < D - 1e-6:
        y = eave + (D - (z + k)) * TAN
        if z + k > DORMER_Z + 1e-6:
            col("Roof", -EXT, DORMER[0], y, ay + RIDGE_H + 0.3, z, z + k)
            col("Roof", DORMER[1], W + EXT, y, ay + RIDGE_H + 0.3, z, z + k)
        else:
            col("Roof", -EXT, W + EXT, y, ay + RIDGE_H + 0.3, z, z + k)
        z += k
    # The roof posts.
    for px, pz in POSTS:
        p.add(F.box(px - 0.08, px + 0.08, ay, roof_y(pz) + 0.05, pz - 0.08, pz + 0.08, bevel=0.01, seg=1), "rafter")
        col("RoofPost", px - 0.08, px + 0.08, ay, roof_y(pz), pz - 0.08, pz + 0.08)
        furn("RoofPost", "loft", (px - 0.12, pz - 0.12, px + 0.12, pz + 0.12), ay, roof_y(pz) - ay)
    return p.to_object("Roof")


def make_stairs():
    """Per storey: the west flight up to the half landing, the east flight up to the next floor,
    the newel wall between them; the player's ramps; the attic's balustrade round the void."""
    p = F.Part()
    for level, y0, _ in LEVELS:
        if level == "attic":
            continue
        solid = level == "basement"
        for k in range(1, 8):
            top = y0 + k * RISE
            za, zb = STAIR[1] + (k - 1) * GOING, STAIR[1] + k * GOING
            bot = y0 if solid else top - 0.36
            p.add(F.box(WEST[0], WEST[1], bot, top, za, zb, bevel=0.01, seg=1,
                        edges=lambda c, za=za, top=top: c.y > top - 0.02 and c.z < za + 0.02), "oak")
            col("Step", WEST[0], WEST[1], bot, top, za, zb)
            top = y0 + STOREY / 2 + k * RISE
            za, zb = LAND_Z - k * GOING, LAND_Z - (k - 1) * GOING
            bot = y0 if solid else top - 0.36
            p.add(F.box(EAST[0], EAST[1], bot, top, za, zb, bevel=0.01, seg=1,
                        edges=lambda c, zb=zb, top=top: c.y > top - 0.02 and c.z > zb - 0.02), "oak")
            col("Step", EAST[0], EAST[1], bot, top, za, zb)
        land = y0 + STOREY / 2
        bot = y0 if solid else land - 0.2
        p.add(F.box(STAIR[0], STAIR[2], bot, land, LAND_Z, STAIR[3]), "oak")
        col("Landing", STAIR[0], STAIR[2], bot, land, LAND_Z, STAIR[3])
        # The ramps: a plane 1 cm over the nosings, from where it meets the floor (landing) to
        # the top nosing.
        _ramp("Ramp_" + level + "_W", WEST, (STAIR[1] - GOING, y0), (LAND_Z, land))
        _ramp("Ramp_" + level + "_E", EAST, (LAND_Z + GOING, land), (STAIR[1], y0 + STOREY))
    # The newel wall from the basement floor to a handrail height over the attic floor.
    top = LY["attic"] + 1.0
    p.add(F.box(WEST[1], EAST[0], LY["basement"], top, STAIR[1], LAND_Z), "trim")
    col("Newel", WEST[1], EAST[0], LY["basement"], top, STAIR[1], LAND_Z)
    p.add(F.box(WEST[1] - 0.02, EAST[0] + 0.02, top, top + 0.05, STAIR[1] - 0.02, LAND_Z), "oak")
    # The cap collides as drawn, so no Sock balances on a ledge that is not there (house/36).
    col("NewelCap", WEST[1] - 0.02, EAST[0] + 0.02, top, top + 0.05, STAIR[1] - 0.02, LAND_Z)
    # Balustrade round the attic's stair void: west, north (over the up flight) and east.
    ay = LY["attic"]
    for x0, x1, z0, z1 in ((STAIR[0] - 0.06, STAIR[0], STAIR[1], STAIR[3]), (STAIR[0], WEST[1], STAIR[1] - 0.06, STAIR[1]),
                           (STAIR[2], STAIR[2] + 0.06, STAIR[1], STAIR[3])):
        p.add(sbox("Handrail", F.box(x0 - 0.01, x1 + 0.01, ay + 0.95, ay + 1.0, z0, z1, bevel=0.01, seg=1)), "oak")
        p.add(sbox("Handrail", F.box(x0, x1, ay, ay + 0.06, z0, z1)), "oak")
        along_x = (x1 - x0) > (z1 - z0)
        s, e = (x0, x1) if along_x else (z0, z1)
        t = s + 0.05
        while t < e - 0.02:
            if along_x:
                p.add(sbox("Spindle", F.box(t - 0.015, t + 0.015, ay + 0.06, ay + 0.95, z0 + 0.015, z1 - 0.015)), "oak")
            else:
                p.add(sbox("Spindle", F.box(x0 + 0.015, x1 - 0.015, ay + 0.06, ay + 0.95, t - 0.015, t + 0.015)), "oak")
            t += 0.12
        col("Balustrade", x0, x1, ay, ay + 1.0, z0, z1)
    return p.to_object("Stairs")


def _ramp(name, xr, a, b):
    """A box whose top face runs from (z, y) `a` to `b` (1 cm up), xr wide, 0.1 thick."""
    (za, ya), (zb, yb) = a, b
    ya += 0.01
    yb += 0.01
    dz, dy = zb - za, yb - ya
    length = math.hypot(dz, dy)
    pitch = math.atan2(-dy, dz)
    # The box's local y, turned by pitch about x: (0, cos, sin); pick the upward one.
    ny, nz = math.cos(pitch), math.sin(pitch)
    if ny < 0:
        ny, nz = -ny, -nz
    th = 0.1
    cy, cz = (ya + yb) / 2 - ny * th / 2, (za + zb) / 2 - nz * th / 2
    RAMPS.append({"name": name, "centre": v3(((xr[0] + xr[1]) / 2, cy, cz)), "size": v3((xr[1] - xr[0], th, length)),
                  "pitch": r3(pitch)})


def make_door_frames():
    """Casings round every open doorway (both faces) and the lining in its reveal."""
    p = F.Part()
    cw = F.CASING_W
    for name, level, (x0, z0, x1, z1), _ in DOORWAYS:
        y0 = LY[level]
        y1 = y0 + DOOR_H
        along_x = (x1 - x0) > (z1 - z0)
        kw = dict(bevel=0.008, seg=1)
        if along_x:
            a, b = x0, x1
            for zf, sgn in ((z0, -1), (z1, +1)):
                za, zb = sorted((zf - sgn * 0.004, zf + sgn * 0.018))
                p.add(sbox("DoorFrame", F.box(a - cw, a + 0.01, y0, y1 + cw, za, zb, **kw)), "trim")
                p.add(sbox("DoorFrame", F.box(b - 0.01, b + cw, y0, y1 + cw, za, zb, **kw)), "trim")
                p.add(sbox("DoorFrame", F.box(a - cw, b + cw, y1 - 0.01, y1 + cw, za, zb, **kw)), "trim")
            p.add(sbox("DoorFrame", F.box(a, a + 0.015, y0, y1, z0, z1)), "trim")
            p.add(sbox("DoorFrame", F.box(b - 0.015, b, y0, y1, z0, z1)), "trim")
            p.add(sbox("DoorFrame", F.box(a, b, y1 - 0.015, y1, z0, z1)), "trim")
        else:
            a, b = z0, z1
            for xf, sgn in ((x0, -1), (x1, +1)):
                xa, xb = sorted((xf - sgn * 0.004, xf + sgn * 0.018))
                p.add(sbox("DoorFrame", F.box(xa, xb, y0, y1 + cw, a - cw, a + 0.01, **kw)), "trim")
                p.add(sbox("DoorFrame", F.box(xa, xb, y0, y1 + cw, b - 0.01, b + cw, **kw)), "trim")
                p.add(sbox("DoorFrame", F.box(xa, xb, y1 - 0.01, y1 + cw, a - cw, b + cw, **kw)), "trim")
            p.add(sbox("DoorFrame", F.box(x0, x1, y0, y1, a, a + 0.015)), "trim")
            p.add(sbox("DoorFrame", F.box(x0, x1, y0, y1, b - 0.015, b)), "trim")
            p.add(sbox("DoorFrame", F.box(x0, x1, y1 - 0.015, y1, a, b)), "trim")
    # The front door: a closed leaf in the north wall's opening, with a brass knob.
    a, b = FRONT_DOOR
    p.add(F.box(a + 0.017, b - 0.017, 0.01, DOOR_H - 0.015, -0.13, -0.08, bevel=0.006, seg=2), "front_door")
    for y0, y1 in ((0.18, 0.95), (1.1, 1.9)):
        p.add(sbox("FrontDoor", F.box(a + 0.13, b - 0.13, y0, y1, -0.08, -0.068, bevel=0.01, seg=2)), "front_door")
    p.add(shull("FrontDoor", F.ellipsoid((a + 0.12, 1.0, -0.05), 0.026, 0.032, 0.032, u=12, v=8)), "brass")
    col("FrontDoor", a, b, 0.0, DOOR_H, -0.13, -0.08)
    for sgn, zf in ((+1, 0.0),):
        p.add(sbox("DoorFrame", F.box(a - cw, a + 0.01, 0.0, DOOR_H + cw, zf - 0.004, zf + 0.018)), "trim")
        p.add(sbox("DoorFrame", F.box(b - 0.01, b + cw, 0.0, DOOR_H + cw, zf - 0.004, zf + 0.018)), "trim")
        p.add(sbox("DoorFrame", F.box(a - cw, b + cw, DOOR_H - 0.01, DOOR_H + cw, zf - 0.004, zf + 0.018)), "trim")
    make_garage_door(p)
    return p.to_object("DoorFrames")


def _godot_turn(x, z, deg):
    """(x, z) turned by `deg` about Godot's +y (Basis(Vector3.UP, angle))."""
    a = math.radians(deg)
    return x * math.cos(a) + z * math.sin(a), -x * math.sin(a) + z * math.cos(a)


def make_room_doors():
    """The room doors' leaves (house/21), shut, each its own node Door_<doorway> with its origin on
    the pin; their records go to ROOM_DOOR_RECS (the layout's room_doors[])."""
    rooms = {n: (lv, r) for n, lv, r, _ in ROOMS}
    made = []
    ROOM_DOOR_RECS.clear()
    for name, level, (x0, z0, x1, z1), between in DOORWAYS:
        if name not in ROOM_DOORS:
            continue
        room, end = ROOM_DOORS[name]
        other = [b for b in between if b != room][0]
        y0 = LY[level]
        along_x = (x1 - x0) > (z1 - z0)
        sa, sb = (x0, x1) if along_x else (z0, z1)
        na, nb = (z0, z1) if along_x else (x0, x1)
        rr = rooms[room][1]
        room_n0 = rr[1] if along_x else rr[0]
        nsign = 1.0 if room_n0 >= nb - 0.01 else -1.0
        face = nb if nsign > 0 else na
        e = 1.0 if end == "lo" else -1.0
        s_pin = sa + LEAF_GAP if end == "lo" else sb - LEAF_GAP
        w = (sb - sa) - 2 * LEAF_GAP
        s_far = s_pin + e * w

        def at(s, n):
            return (s, n) if along_x else (n, s)

        def sn_box(s0, s1, n0, n1, ya, yb, **kw):
            (xa, za), (xb, zb) = at(s0, n0), at(s1, n1)
            return F.box(xa, xb, ya, yb, za, zb, **kw)

        def sn_cyl(s, y, n0, n1, r, nseg=12):
            # a cylinder through the leaf's thickness (along the wall's normal)
            n0, n1 = sorted((n0, n1))
            return F.cyl("z", s, y, n0, n1, r, n=nseg) if along_x else F.cyl("x", y, s, n0, n1, r, n=nseg)

        ya, yb = y0 + 0.008, y0 + DOOR_H - LEAF_GAP
        n_in, n_out = face, face - nsign * LEAF_T      # the room face and the lobby face
        p = F.Part()
        p.add(sn_box(s_pin, s_far, n_out, n_in, ya, yb, bevel=0.004, seg=1), "door")
        lo_s, hi_s = sorted((s_pin, s_far))
        for nf in (n_in, n_out):
            out = nsign if nf == n_in else -nsign
            for pa, pb in ((0.2, 0.95), (1.1, 1.92)):
                p.add(sn_box(lo_s + 0.11, hi_s - 0.11, nf, nf + out * 0.006, y0 + pa, y0 + pb, bevel=0.004, seg=1),
                      "door")
            # The handle: a rose and a lever pointing at the hinge, brass.
            hs, hy = s_far - e * 0.075, y0 + 1.0
            p.add(sn_cyl(hs, hy, nf, nf + out * 0.012, 0.03, 16), "brass")
            p.add(sn_cyl(hs, hy, nf, nf + out * 0.05, 0.009, 8), "brass")
            p.add(sn_box(hs, hs - e * 0.13, nf + out * 0.04, nf + out * 0.058, hy - 0.009, hy + 0.009,
                         bevel=0.003, seg=1), "brass")
        px, pz = at(s_pin, face)
        node = "Door_" + name
        made.append(p.to_object(node, origin=(px, y0, pz)))
        # Its box relative to the pin, and the turn that swings its far edge into the room.
        (bx0, bz0), (bx1, bz1) = at(s_pin, n_out), at(s_far, n_in)
        lo = [min(bx0, bx1) - px, ya - y0, min(bz0, bz1) - pz]
        hi = [max(bx0, bx1) - px, yb - y0, max(bz0, bz1) - pz]
        fx, fz = at(e, 0.0)
        ix, iz = at(0.0, nsign)
        deg = DOOR_OPEN_DEG
        tx, tz = _godot_turn(fx, fz, deg)
        if tx * ix + tz * iz < 0.5:
            deg = -DOOR_OPEN_DEG
        ROOM_DOOR_RECS.append({
            "name": name, "node": node, "room": room, "other": other, "level": level,
            "hinge": v3((px, y0, pz)), "axis": [0.0, 1.0, 0.0], "open_deg": deg,
            "min": v3(lo), "max": v3(hi), "width": r3(w), "thickness": LEAF_T, "wall": PART,
            "along": v3((fx, 0.0, fz)), "into": v3((ix, 0.0, iz)),
        })
    return made


# --- Locks (progression/03) -----------------------------------------------------------------

def torus_link(length, width, wire, n=10, m=4):
    """One chain link in its own frame: an oval ring along x (`length` and `width` outside), lying
    in the xy plane, `wire` its wire's radius; n segments round the ring, m round the wire."""
    import bmesh
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
    """A chain of links along the polyline `points` (game x, y, z), the face it hangs on facing
    `out` (a unit vector): links in turn lie flat on the face and stand out of it. A Part."""
    p = F.Part()
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
            import bmesh
            bmesh.ops.transform(bm, matrix=mat, verts=bm.verts)
            p.add(bm, "chain")
            k += 1
    return p


def sag(a, b, drop, n=6):
    """Points from a to b hanging `drop` low in the middle (a parabola)."""
    out = []
    for i in range(n + 1):
        t = i / n
        out.append((a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t - drop * 4 * t * (1 - t),
                    a[2] + (b[2] - a[2]) * t))
    return out


def padlock_part(centre, out, size=1.0):
    """A padlock hanging at `centre` (its body's middle), its front facing `out` (+-x or +-z): a
    brass body with a keyhole, a steel shackle over it. A Part, built facing +z and turned."""
    import bmesh
    p = F.Part()
    s = size
    turn = Matrix.Rotation(math.atan2(out[0], out[2]), 4, "Y")
    turn.translation = Vector(centre)

    def put(bm, mat):
        bmesh.ops.transform(bm, matrix=turn, verts=bm.verts)
        p.add(bm, mat)

    bw, bh, bd = 0.06 * s, 0.065 * s, 0.024 * s
    put(F.box(-bw, bw, -bh, bh, -bd, bd, bevel=0.012 * s, seg=2), "brass")
    put(F.cyl("z", 0.0, -0.005 * s, bd - 0.002, bd + 0.003, 0.011 * s, n=10), "lock_dark")
    put(F.box(-0.004 * s, 0.004 * s, -0.03 * s, -0.008 * s, bd - 0.002, bd + 0.003), "lock_dark")
    r, w = 0.038 * s, 0.009 * s
    for x in (-r, r):
        put(F.cyl("y", x, 0.0, bh - 0.005, bh + 0.035 * s, w, n=8), "steel")
    arc = torus_link(2 * (r + w), 2 * (r + w), w, n=16, m=6)
    bmesh.ops.delete(arc, geom=[v for v in arc.verts if v.co.y < -1e-6], context="VERTS")
    bmesh.ops.translate(arc, vec=(0.0, bh + 0.035 * s, 0.0), verts=arc.verts)
    put(arc, "steel")
    return p


def _lock_frames():
    """Where each locked way stands (progression/03; house/36): a list of {kind ("door" or "gate"), up (the floor it locks), below (the floor under it), o (x, z) (the opening's end
    where s = 0), u (along the opening from there), n (the side players come from), length, y0
    (its floor), h (the leaf's height), swing (+1: the leaf opens towards n), top(x, z) (the
    panel's top over a door), drop_y (where the dropped chain and padlock fall to)}.
    The ground's and the first floor's are plank doors at the top of their flight. The attic's is a
    baby gate at the foot of the flight up to it, on the first floor, its leaf pinned on the west
    post and swinging out onto the floor to rest along the west wall, under the Elevator's hatch
    (its top at the hatch's sill), clear of the walk round the newel (designer, 2026-11-06). The U landing above is open: no
    door, frame or window (house/36, house/43, Q1132)."""
    out = []
    for below, up in UP.items():
        if up == "attic":
            y0 = LY[below]
            out.append(dict(kind="gate", up=up, below=below, o=(WEST[0], STAIR[1] - GATE_D / 2), u=(1.0, 0.0),
                            n=(0.0, -1.0), length=WEST[1] - WEST[0], y0=y0, h=GATE_H, swing=+1,
                            top=lambda x, z, y0=y0, below=below: y0 + LH[below], drop_y=y0))
        else:
            y0 = LY[up]
            out.append(dict(kind="door", up=up, below=below, o=(EAST[0], STAIR[1]), u=(1.0, 0.0), n=(0.0, 1.0),
                            length=EAST[1] - EAST[0], y0=y0, h=DOOR_H, swing=+1,
                            top=lambda x, z, y0=y0, up=up: y0 + LH[up], drop_y=y0 - RISE))
    return out


def make_locked_doors():
    """The locked ways up (progression/03, Q620, Q638; house/36): a plank door at the top of the
    ground's and the first floor's flight, a baby gate at the foot of the attic's (_lock_frames()),
    shutting the floor above off until its stage opens it. A door stands in a frame with a wall
    panel over it to the ceiling; the gate between two posts, a player's blocker over it to the
    ceiling (the layout's record, not drawn). A chain runs across from post to post on the side
    players come from, with a padlock on it. The U landing has none (house/43). Returns the static frame, the panels and the moving parts, each its own node:
    LockDoor_<floor> (the leaf, origin on its pin), LockChain_<floor> and LockPadlock_<floor>;
    fills LOCKED_DOOR_RECS."""
    frame, panels, moving = F.Part(), F.Part(), []
    LOCKED_DOOR_RECS.clear()
    for d in _lock_frames():
        kind, up, (ox, oz), u, n, length, y0 = d["kind"], d["up"], d["o"], d["u"], d["n"], d["length"], d["y0"]

        def at(s, t, ox=ox, oz=oz, u=u, n=n):
            # house (x, z) of the point `s` along the opening, `t` towards n
            return (ox + u[0] * s + n[0] * t, oz + u[1] * s + n[1] * t)

        def pt(s, y, t, at=at):
            x, z = at(s, t)
            return (x, y, z)

        def st_box(s0, s1, ya, yb, t0, t1, at=at, **kw):
            (xa, za), (xb, zb) = at(s0, t0), at(s1, t1)
            return F.box(min(xa, xb), max(xa, xb), ya, yb, min(za, zb), max(za, zb), **kw)

        def st_col(name, s0, s1, ya, yb, t0, t1, sock=True, at=at):
            (xa, za), (xb, zb) = at(s0, t0), at(s1, t1)
            col(name, min(xa, xb), max(xa, xb), ya, yb, min(za, zb), max(za, zb), sock=sock)

        def st_cyl(s, y, t0, t1, r, nseg, at=at, n=n):
            # a cylinder through the leaf's thickness (along n)
            (xa, za), (xb, zb) = at(s, t0), at(s, t1)
            if n[0] == 0.0:
                return F.cyl("z", xa, y, min(za, zb), max(za, zb), r, n=nseg)
            return F.cyl("x", y, za, min(xa, xb), max(xa, xb), r, n=nseg)

        nv = (n[0], 0.0, n[1])
        door_h = d["h"]
        if kind == "gate":
            post = GATE_POST
            f0, f1 = -GATE_D / 2, GATE_D / 2
            ptop = y0 + door_h + 0.06
            for sa, sb in ((0.0, post), (length - post, length)):
                frame.add(st_box(sa, sb, y0, ptop, f0, f1, bevel=0.008, seg=1), "trim")
                frame.add(sbox("Gate", st_box(sa - 0.01, sb + 0.01, ptop, ptop + 0.02, f0 - 0.01, f1 + 0.01,
                                              bevel=0.005, seg=1)), "oak")
                c = pt((sa + sb) / 2, ptop + 0.02 + 0.035, 0.0)
                frame.add(shull("Gate", F.ellipsoid(c, 0.035, 0.035, 0.035, u=12, v=8)), "oak")
                st_col("LockFrame", sa, sb, y0, ptop + 0.02, f0, f1)
            gap = 0.012
        else:
            head = y0 + door_h + LOCK_POST
            post = (length - LOCK_LEAF_W) / 2 - LEAF_GAP       # each post's width
            f0, f1 = -LOCK_FRAME_D / 2, LOCK_FRAME_D / 2
            for sa, sb in ((0.0, post), (length - post, length)):
                frame.add(st_box(sa, sb, y0, head, f0, f1, bevel=0.008, seg=1), "dark_wood")
            frame.add(st_box(0.0, length, y0 + door_h, head, f0, f1, bevel=0.008, seg=1), "dark_wood")
            st_col("LockFrame", 0.0, post, y0, head, f0, f1)
            st_col("LockFrame", length - post, length, y0, head, f0, f1)
            # The wall panel over the head, up to the ceiling (under the roof: a sloped top).
            top_at = d["top"]
            ta, tb = top_at(*at(0.0, 0.0)), top_at(*at(length, 0.0))
            if abs(ta - tb) < 1e-6:
                panels.add(st_box(0.0, length, head, ta, -0.03, 0.03), wall_mat)
                st_col("LockFrame", 0.0, length, y0 + door_h, ta, f0, f1)
            else:
                xs = sorted({round(at(s, t)[0], 6) for s in (0.0, length) for t in (-0.03, 0.03)})
                zs = sorted({round(at(s, t)[1], 6) for s in (0.0, length) for t in (-0.03, 0.03)})
                corners = {}
                for i, x in enumerate(xs):
                    for k, z in enumerate(zs):
                        corners[(i, 0, k)] = (x, head, z)
                        corners[(i, 1, k)] = (x, top_at(x, z), z)
                panels.add(shull("LockPanel", hexa(corners)), wall_mat)
                # The player's: a box up to the higher end (the roof stops them past the lower).
                st_col("LockFrame", 0.0, length, y0 + door_h, max(ta, tb), f0, f1, sock=False)
            gap = LEAF_GAP
        la, lb = post + gap, length - post - gap
        leaf = F.Part()
        if kind == "gate":
            # A painted baby gate: two stiles, a bottom rail and round spindles under an oak
            # handrail.
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
                s = la + sw + i * step
                x, z = at(s, 0.0)
                leaf.add(F.cyl("y", x, z, ya + 0.05, yb - 0.05, 0.011, n=8), "trim")
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
                    leaf.add(sbox("LockLeaf", st_box(la + 0.04, lb - 0.04, y0 + ly - 0.07, y0 + ly + 0.07,
                                                     *sorted((tf, tf + sgn * 0.025)), bevel=0.006, seg=1)), "dark_wood")
            bw = 0.06
            t2 = to + 0.025
            lo, hi = y0 + 0.32, y0 + 0.93
            leaf.add(hexa({(0, 0, 0): pt(la + 0.06, lo, to), (1, 0, 0): pt(la + 0.06 + bw, lo, to),
                           (0, 1, 0): pt(lb - 0.06 - bw, hi, to), (1, 1, 0): pt(lb - 0.06, hi, to),
                           (0, 0, 1): pt(la + 0.06, lo, t2), (1, 0, 1): pt(la + 0.06 + bw, lo, t2),
                           (0, 1, 1): pt(lb - 0.06 - bw, hi, t2), (1, 1, 1): pt(lb - 0.06, hi, t2)}),
                     "dark_wood")
            # A ring pull on both faces, near the latch edge.
            for tf, sgn in ((to + 0.025, 1), (ti - 0.025, -1)):
                leaf.add(shull("LockLeaf", st_cyl(lb - 0.09, y0 + 1.0, *sorted((tf, tf + sgn * 0.012)), 0.025, 10)), "steel")
        # The Socks meet the shut leaf (as they met it drawn: it never opens for them).
        (xa, za), (xb, zb) = at(la, ti), at(lb, to)
        sock_box("LockLeaf", xa, xb, ya, yb, za, zb)
        # The pin on the leaf's s = 0 end, on the face it swings towards. The doors swing back over
        # their flight to rest along the newel wall, so the open door leaves the floor's way clear;
        # the gate swings out onto the first floor to rest along its west wall.
        pin = pt(la, y0, to if d["swing"] > 0 else ti)
        node = "LockDoor_" + up
        moving.append(leaf.to_object(node, origin=pin))
        # The chain across the side players come from, eye to eye on the posts, the padlock on its
        # middle.
        cy = y0 + (0.6 if kind == "gate" else 1.05)
        ct = f1 + 0.012
        ea, eb = pt(post / 2, cy, ct), pt(length - post / 2, cy, ct)
        for s in (post / 2, length - post / 2):
            frame.add(st_cyl(s, cy, f1, f1 + 0.02, 0.016, 10), "steel")
        mid = pt(length / 2, cy - 0.12, ct + 0.01)
        chain = chain_part(sag(ea, mid, 0.02, 4) + sag(mid, eb, 0.02, 4)[1:], nv)
        moving.append(chain.to_object("LockChain_" + up, origin=mid))
        lock_at = pt(length / 2, mid[1] - 0.105, ct + 0.022)
        moving.append(padlock_part(lock_at, nv, 1.15).to_object("LockPadlock_" + up, origin=lock_at))
        # The turn that opens it (about +y): the leaf's far end (+u from the pin) comes round to
        # swing * n; a -90 degree turn takes (x, z) to (-z, x).
        want = (d["swing"] * n[0], d["swing"] * n[1])
        open_deg = -DOOR_OPEN_DEG if (-u[1], u[0]) == want else DOOR_OPEN_DEG
        lx, lz = sorted((xa, xb)), sorted((za, zb))
        rec = {
            "name": up, "level": up, "from": d["below"], "node": node, "chain": "LockChain_" + up,
            "padlock": "LockPadlock_" + up, "hinge": v3(pin), "axis": [0.0, 1.0, 0.0], "open_deg": open_deg,
            "min": v3((lx[0] - pin[0], ya - y0, lz[0] - pin[2])), "max": v3((lx[1] - pin[0], yb - y0, lz[1] - pin[2])),
            "width": r3(lb - la), "chain_pos": v3(mid), "padlock_pos": v3(lock_at), "stair_side": v3(nv),
            "drop_y": r3(d["drop_y"]),
        }
        if kind == "gate":
            # Over the low gate, up to the ceiling: the players' only (none jumps or climbs over a
            # locked floor's gate); gone once it opens.
            (xa, za), (xb, zb) = at(0.0, f0), at(length, f1)
            top = d["top"](*at(0.0, 0.0))
            rec["blocker"] = {"min": v3((min(xa, xb), yb, min(za, zb))), "max": v3((max(xa, xb), top, max(za, zb)))}
        LOCKED_DOOR_RECS.append(rec)
    return frame.to_object("LockFrames"), panels.to_object("LockPanels"), moving


def make_garage_door(p):
    """The garage's up-and-over door (house/19, Q453), shut for good: one ribbed leaf in the north
    wall's opening with a handle on both faces, a lining and casing round it inside, and the
    up-and-over gear (a track in from each jamb under the head, hung from the ceiling, and a spring
    arm down each jamb). It collides as one slab."""
    a, b = GARAGE_DOOR
    y0 = LY["basement"]
    y1 = y0 + DOOR_H
    cw = F.CASING_W
    zo, zi = -0.13, -0.07           # the leaf's outer and inner faces, set back in the opening
    p.add(F.box(a + 0.02, b - 0.02, y0 + 0.01, y1 - 0.02, zo, zi, bevel=0.006, seg=1), "garage_door")
    # The ribs on the street side: shallow horizontal panels, a plain band at the handle.
    n = 9
    h = (DOOR_H - 0.12) / n
    for k in range(n):
        ya = y0 + 0.06 + k * h + 0.02
        if abs(ya + h / 2 - (y0 + 1.0)) < h / 2:
            continue
        p.add(F.box(a + 0.08, b - 0.08, ya, ya + h - 0.04, zo - 0.012, zo, bevel=0.004, seg=1), "garage_door")
    hx = (a + b) / 2
    for zf, out in ((zo, -1), (zi, +1)):
        p.add(sbox("GarageDoor", F.box(hx - 0.13, hx + 0.13, y0 + 0.97, y0 + 1.03, *sorted((zf + out * 0.03, zf + out * 0.045)),
                                       bevel=0.008, seg=1)), "steel")
        for sx in (hx - 0.11, hx + 0.11):
            p.add(sbox("GarageDoor", F.box(sx - 0.015, sx + 0.015, y0 + 0.985, y0 + 1.015, *sorted((zf, zf + out * 0.035)))), "steel")
    # Inside: the leaf's stiffening frame, then the lining and casing round the opening.
    for ya, yb in ((y0 + 0.05, y0 + 0.11), (y1 - 0.12, y1 - 0.06), (y0 + 0.72, y0 + 0.78)):
        p.add(sbox("GarageDoor", F.box(a + 0.06, b - 0.06, ya, yb, zi, zi + 0.02)), "steel")
    for xa in (a + 0.06, b - 0.12):
        p.add(sbox("GarageDoor", F.box(xa, xa + 0.06, y0 + 0.05, y1 - 0.06, zi, zi + 0.02)), "steel")
    p.add(sbox("GarageDoor", F.box(a, a + 0.015, y0, y1, zi, 0.0)), "trim")
    p.add(sbox("GarageDoor", F.box(b - 0.015, b, y0, y1, zi, 0.0)), "trim")
    p.add(sbox("GarageDoor", F.box(a, b, y1 - 0.015, y1, zi, 0.0)), "trim")
    kw = dict(bevel=0.008, seg=1)
    p.add(sbox("GarageDoor", F.box(a - cw, a + 0.01, y0, y1 + cw, -0.004, 0.018, **kw)), "trim")
    p.add(sbox("GarageDoor", F.box(b - 0.01, b + cw, y0, y1 + cw, -0.004, 0.018, **kw)), "trim")
    p.add(sbox("GarageDoor", F.box(a - cw, b + cw, y1 - 0.01, y1 + cw, -0.004, 0.018, **kw)), "trim")
    ceil = y0 + LH["basement"]
    run = 2.3
    for xa, xb in ((a + 0.03, a + 0.09), (b - 0.09, b - 0.03)):
        p.add(sbox("GarageDoor", F.box(xa, xb, y1 + cw + 0.01, y1 + cw + 0.07, 0.02, run)), "steel")
        for zh in (0.9, run - 0.05):
            p.add(sbox("GarageDoor", F.box(xa + 0.02, xb - 0.02, y1 + cw + 0.07, ceil, zh - 0.02, zh + 0.02)), "steel")
        p.add(sbox("GarageDoor", F.box(xa + 0.01, xb - 0.01, y0 + 0.9, y1 + cw + 0.01, 0.02, 0.06)), "steel")
    col("GarageDoor", a, b, y0, y1, zo, zi)


def make_windows():
    """Frames, sills and casings (one mesh), the panes (another); the window list for the layout."""
    f, g = F.Part(), F.Part()
    out = []
    for wname, side, w0, w1, sill, head, frosted in WINDOWS:
        face = SIDES[side]
        mid = F.face_point(face, 0.3, (sill + head) / 2, (w0 + w1) / 2)
        room = room_at3(*mid) or "loft"
        out.append((wname, room, side, face, w0, w1, sill, head))
        bar = 0.06
        fd0, fd1 = -0.14, -0.07
        st = sill + 0.035
        kw = dict(bevel=0.008, seg=1)
        f.add(sbox("Window", F.face_box(face, -EXT, 0.05, sill, st, w0 - 0.05, w1 + 0.05, bevel=0.01, seg=2)), "trim")
        f.add(sbox("Window", F.face_box(face, fd0, fd1, st, head, w0, w0 + bar, **kw)), "trim")
        f.add(sbox("Window", F.face_box(face, fd0, fd1, st, head, w1 - bar, w1, **kw)), "trim")
        f.add(sbox("Window", F.face_box(face, fd0, fd1, st, st + bar, w0 + bar, w1 - bar, **kw)), "trim")
        f.add(sbox("Window", F.face_box(face, fd0, fd1, head - bar, head, w0 + bar, w1 - bar, **kw)), "trim")
        if w1 - w0 > 1.0:
            wc = (w0 + w1) / 2
            f.add(sbox("Window", F.face_box(face, fd0 + 0.01, fd1 - 0.01, st + bar, head - bar, wc - 0.025, wc + 0.025, **kw)), "trim")
        for a, b, y0, y1 in ((w0 - 0.06, w0, st, head + 0.06), (w1, w1 + 0.06, st, head + 0.06),
                             (w0 - 0.06, w1 + 0.06, head, head + 0.06)):
            f.add(sbox("Window", F.face_box(face, -0.004, 0.016, y0, y1, a, b, **kw)), "trim")
        g.add(F.face_box(face, -0.105, -0.095, st + bar - 0.01, head - bar + 0.01, w0 + bar - 0.01, w1 - bar + 0.01),
              "frosted" if frosted else "glass")
        # The Socks' pane is as thick as the frame behind its room face, so none passes through.
        sock_face_box("Glass", face, fd0, -0.095, st + bar - 0.01, head - bar + 0.01, w0 + bar - 0.01, w1 - bar + 0.01)
    return f.to_object("Windows"), g.to_object("Glass"), out


def make_lamps():
    """A flush ceiling lamp in every room (two bulbs on the attic's ridge, one over each half
    landing), with their light markers."""
    p = F.Part()
    for name, level, (x0, z0, x1, z1), _ in ROOMS:
        y0 = LY[level]
        cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
        if name.startswith("stairs_"):
            # Under the next landing up (the attic has none: a bulb under the roof there).
            cy = y0 + STOREY / 2 + (STOREY - 0.2 if level != "first" else 2.1)
            cz = (LAND_Z + STAIR[3]) / 2
            p.add(shull("Lamp", F.cyl("y", cx, cz, cy + 0.03, cy + 0.12, 0.05, n=12)), "trim")
            p.add(shull("Lamp", F.ellipsoid((cx, cy - 0.02, cz), 0.12, 0.08, 0.12, u=14, v=8, cut_below=-0.0001)), "paper")
            F.LIGHTS.append({"name": "CeilingLight_" + name, "kind": "ceiling", "room": name,
                             "pos": v3((cx, cy - 0.04, cz))})
            continue
        if level == "attic":
            for bx in (2.64, 7.46):
                top = y0 + RIDGE_H
                p.add(F.cyl("y", bx, RIDGE_Z, top - 0.6, top, 0.005, n=6), "dark_wood")
                p.add(shull("Lamp", F.cyl("y", bx, RIDGE_Z, top - 0.66, top - 0.6, 0.02, n=10)), "brass")
                p.add(shull("Lamp", F.ellipsoid((bx, top - 0.7, RIDGE_Z), 0.04, 0.05, 0.04, u=10, v=6)), "bulb")
                F.LIGHTS.append({"name": "CeilingLight_loft_%d" % int(bx), "kind": "ceiling", "room": name,
                                 "pos": v3((bx, top - 0.7, RIDGE_Z))})
            continue
        h = LY[level] + LH[level]
        if name in GLOBES:
            # A paper globe (its paper and bulb are make_shades()'), its cord stopping at its top.
            centre = h - 0.42
            p.add(shull("Lamp", F.cyl("y", cx, cz, h - 0.03, h + 0.01, 0.06, n=16, bevel=0.008)), "trim")
            p.add(F.cyl("y", cx, cz, centre + F.GLOBE_R - 0.01, h - 0.03, 0.005, n=6), "dark_wood")
            F.LIGHTS.append({"name": "CeilingLight_" + name, "kind": "ceiling", "room": name,
                             "pos": v3((cx, centre - 0.02, cz))})
            GLOBE_SPOTS.append((cx, centre, cz))
            continue
        p.add(F.cyl("y", cx, cz, h - 0.03, h + 0.01, 0.06, n=16, bevel=0.008), "trim")
        p.add(shull("Lamp", F.ellipsoid((cx, h - 0.03, cz), 0.2, 0.1, 0.2, u=20, v=10, cut_below=-0.0001)), "paper")
        p.add(shull("Lamp", F.cyl("y", cx, cz, h - 0.035, h - 0.02, 0.21, n=20)), "brass")
        F.LIGHTS.append({"name": "CeilingLight_" + name, "kind": "ceiling", "room": name, "pos": v3((cx, h - 0.08, cz))})
    return p.to_object("Lamps")


GLOBES = ("living", "bedroom")
GLOBE_SPOTS = []


def make_shades():
    """The globe shades (ribbed paper, open below) and their bulbs, a node of their own so code
    keeps them from casting shadows (flat/28 Q203), as make_flat's."""
    p = F.Part()
    for cx, centre, cz in GLOBE_SPOTS:
        cut = -F.GLOBE_RIM / F.GLOBE_R
        bm = F.ellipsoid((0, 0, 0), 1, 1, 1, u=16, v=10, cut_below=cut)
        for v in bm.verts:
            lat = math.asin(max(-1.0, min(1.0, v.co.y)))
            rib = 1.0 + 0.015 * math.cos(lat * 10)
            v.co = Vector((cx + v.co.x * F.GLOBE_R * rib, centre + v.co.y * F.GLOBE_R, cz + v.co.z * F.GLOBE_R * rib))
        p.add(shull("Shade", bm), "shade_paper")
        p.add(F.ellipsoid((cx, centre - 0.02, cz), 0.045, 0.05, 0.045, u=12, v=8), "bulb")
        p.add(F.cyl("y", cx, cz, centre + 0.02, centre + F.GLOBE_R - 0.005, 0.005, n=6), "dark_wood")
        p.add(F.cyl("y", cx, cz, centre + 0.015, centre + 0.06, 0.02, n=10), "brass")
    return p.to_object("Shades")


def make_rugs():
    p = F.Part()
    # The rugs house/04 has no piece for (its living rug, doormat, bath mat and play rug are pieces).
    rugs = [("KitchenRunner", "kitchen", 0.0, 2.1, 1.05, 2.0, 0.6, 0.1, "rug_blue", "rug_stripe"),
            ("BedroomRug", "bedroom", 2.9, 2.8, 5.59, 1.4, 0.7, 0.2, "rug_blue", "rug_stripe"),
            ("LaundryMat", "laundry", -2.9, 1.65, 5.92, 1.0, 0.6, 0.1, "rug_blue", "linen")]
    for name, room, y0, cx, cz, w, d, r, m0, m1 in rugs:
        top = 0.012
        before = set(p.bm.verts)
        F.rug_bm(cx, cz, w, d, r, top, m0, m1, p)
        # The Socks' rug: its edge's rings as drawn (F.rug_bm(), a convex profile), on its outline
        # 2 cm down into the slab, so it is not thin.
        rings = [(0.0, -0.02), (0.0, 0.0), (0.004, top - 0.003), (0.012, top)]
        sock_hull("Rug", [(x, y0 + y, z) for ins, y in rings
                          for x, z in F.rounded_rect(w / 2 - ins, d / 2 - ins, r - ins, 6, cx, cz)])
        for v in p.bm.verts:
            if v not in before:
                v.co.y += y0
        F.RUGS.append({"name": name, "room": room, "min": [r3(cx - w / 2), r3(cz - d / 2)],
                       "max": [r3(cx + w / 2), r3(cz + d / 2)], "top_y": r3(y0 + top)})
    return p.to_object("Rugs")


def make_mirror_frame():
    """The oak ring round the bedroom mirror (the glass is drawn by the game, game/house/mirror.gd), on
    the west wall."""
    p = F.Part()
    x, y, z = MIRROR["pos"]
    p.add(shull("MirrorFrame", F.cyl("x", y, z, 0.0, x - 0.005, 0.3, n=32, bevel=0.008)), "oak")
    return p.to_object("MirrorFrame")


# --- Layout -----------------------------------------------------------------------------------

def cabinet_spot(c):
    _, _, room, level, wall, s = c
    y0 = LY[level]
    if wall == "N3":
        face = ("N3", "x", 3.28, +1)
    else:
        face = SIDES[wall][:4]
    _, axis, coord, sign = face
    cd, zd = CAB_D / 2, CAB_ZONE_D
    if axis == "x":
        pos = (s, y0, coord + sign * cd)
        yaw = 0.0 if sign > 0 else math.pi
        zone = ((s - CAB_ZONE_W / 2, min(coord, coord + sign * zd)), (s + CAB_ZONE_W / 2, max(coord, coord + sign * zd)))
    else:
        pos = (coord + sign * cd, y0, s)
        yaw = math.pi / 2 if sign > 0 else -math.pi / 2
        zone = ((min(coord, coord + sign * zd), s - CAB_ZONE_W / 2), (max(coord, coord + sign * zd), s + CAB_ZONE_W / 2))
    return pos, yaw, zone


def all_zones():
    """(x0, z0, x1, z1, y) per clear zone: the Cabinets' and the washer's."""
    out = []
    for c in CABINETS:
        _, _, ((x0, z0), (x1, z1)) = cabinet_spot(c)
        out.append((x0, z0, x1, z1, LY[c[3]]))
    (x0, z0), (x1, z1) = WASHER_ZONE
    out.append((x0, z0, x1, z1, LY["basement"]))
    return out


def check_zones(objs):
    bad = []
    for o in objs.values():
        if o.type != "MESH" or o.name in ("Floor", "Ceiling", "Walls", "Rugs", "Roof", "Stairs"):
            continue
        mw = o.matrix_world
        for v in o.data.vertices:
            w = mw @ v.co
            x, y, z = w.x, w.z, -w.y
            for x0, z0, x1, z1, y0 in all_zones():
                if y0 + 0.02 < y < y0 + CLEAR_TOP and x0 + 0.005 < x < x1 - 0.005 and z0 + 0.005 < z < z1 - 0.005:
                    bad.append((o.name, round(x, 2), round(y, 2), round(z, 2)))
                    break
    if bad:
        raise SystemExit("CLEAR ZONE VIOLATION %s" % bad[:10])


def layout(window_info):
    levels = [{"name": n, "y": r3(y), "height": r3(h)} for n, y, h in LEVELS]
    open_to = {}

    def link(a, b):
        open_to.setdefault(a, set()).add(b)
        open_to.setdefault(b, set()).add(a)

    rooms = []
    for name, level, (x0, z0, x1, z1), finish in ROOMS:
        r = dict(name=name, level=level, **fp(x0, z0, x1, z1), y=r3(LY[level]), height=r3(room_top(name, level)),
                 floor=finish if finish != "basement_tile" else "basement_tile")
        if name.startswith("stairs_"):
            r["stairs"] = True
        if level == "attic":
            r["roof"] = {"knee": KNEE, "pitch": r3(PITCH), "ridge_z": RIDGE_Z,
                         "dormer": {"min": [DORMER[0], r3(DORMER_Z)], "max": [DORMER[1], D], "height": DORMER_H}}
        rooms.append(r)
    doorways = []
    for name, level, (x0, z0, x1, z1), between in DOORWAYS:
        doorways.append(dict(name=name, between=between, **fp(x0, z0, x1, z1), y=r3(LY[level]), height=DOOR_H))
    # The stairs: each storey's stair zone opens on its lobby (z 5.15, both flights' feet) and its
    # east flight's top on the floor above.
    for level, y0, _ in LEVELS:
        if level == "attic":
            continue
        st = STAIR_ROOMS[level]
        doorways.append(dict(name="Stairs_%s_foot" % level, between=[LOBBY[level], st],
                             **fp(STAIR[0], STAIR[1] - 0.02, STAIR[2], STAIR[1] + 0.02), y=r3(y0), height=r3(LH[level]),
                             open=True))
        up = UP[level]
        doorways.append(dict(name="Stairs_%s_top" % level, between=[st, LOBBY[up]],
                             **fp(EAST[0], STAIR[1] - 0.02, EAST[1], STAIR[1] + 0.02), y=r3(y0 + STOREY),
                             height=r3(min(2.0, LH[up])), open=True))
        link(LOBBY[level], st)
        link(st, LOBBY[up])
    for r in rooms:
        r["open_to"] = sorted(open_to.get(r["name"], set()))
    wins = []
    for wname, room, side, face, w0, w1, sill, head in window_info:
        _, axis, c, sign, _, _ = face
        t = [c, c - sign * EXT]
        rect = (w0, min(t), w1, max(t)) if axis == "x" else (min(t), w0, max(t), w1)
        wins.append(dict(name=wname, room=room, wall=side, **fp(*rect), sill_y=r3(sill), head_y=r3(head)))
    spots = []
    for c in CABINETS:
        pos, yaw, ((x0, z0), (x1, z1)) = cabinet_spot(c)
        spots.append({"spot": c[0], "collection": c[1], "room": c[2], "wall": c[4], "pos": v3(pos), "yaw": r3(yaw),
                      "zone": fp(x0, z0, x1, z1), "max_height": CLEAR_TOP})
    washer_front = (WASHER_POS[0] + 0.35, WASHER_POS[1] + 0.6, WASHER_POS[2])
    zones = {s["spot"]: dict(s["zone"], y=s["pos"][1]) for s in spots}
    (wx0, wz0), (wx1, wz1) = WASHER_ZONE
    zones["washer"] = dict(fp(wx0, wz0, wx1, wz1), y=WASHER_POS[1])
    ward = F.WARDROBE
    ward["zone"]["y"] = ward["pos"][1]
    return {
        "units": "metres; x/z footprints and [x, y, z] points in Godot coordinates",
        "bounds": {"min": [0.0, 0.0], "max": [W, D], "y_min": LY["basement"], "y_max": r3(LY["attic"] + RIDGE_H),
                   "height": r3(LY["attic"] + RIDGE_H), "exterior_wall": EXT, "partition": PART},
        "levels": levels,
        "outline": [[0.0, 0.0], [W, 0.0], [W, D], [0.0, D]],
        "rooms": rooms,
        "doorways": doorways,
        "front_door": dict(**fp(FRONT_DOOR[0], -EXT, FRONT_DOOR[1], 0.0), height=DOOR_H),
        "windows": wins,
        "spawn": {"pos": v3(SPAWN), "yaw": r3(F.yaw_towards(SPAWN, washer_front)), "look_at": v3(washer_front)},
        "washer": {"pos": v3(WASHER_POS), "yaw": r3(WASHER_YAW), "room": "laundry", "zone": fp(wx0, wz0, wx1, wz1)},
        "cabinet_spots": spots,
        "clear_zones": dict(zones, y_max=CLEAR_TOP,
                            note="cabinet zones are 1.8 x 0.95 m (cabinet 0.5 + drawer pull-out 0.45); y: the floor"),
        "colliders": F.COLLIDERS,
        "ramps": RAMPS,
        "crawl_spaces": F.CRAWL,
        "openables": F.OPENABLES,
        "furniture": F.FURNITURE,
        "lights": F.LIGHTS,
        "rugs": F.RUGS,
        "clock": {"pos": v3(CLOCK_POS), "yaw": 0.0, "room": "living", "wall": "N"},
        "wardrobe": ward,
        "mirror": {"pos": v3(MIRROR["pos"]), "yaw": r3(MIRROR["yaw"]), "radius": MIRROR["radius"],
                   "room": MIRROR["room"]},
        "devices": DEVICES,
        "room_doors": ROOM_DOOR_RECS,
        "locked_doors": LOCKED_DOOR_RECS,
    }


# --- Previews ------------------------------------------------------------------------------

VIEWS = {   # level: [(name, camera, target, lens)]
    "basement": [("basement_laundry", (3.3, -1.3, 7.9), (0.33, -2.6, 4.6), 15),
                 ("basement_garage", (6.8, -1.3, 8.01), (9.33, -2.6, 0.55), 15),
                 ("basement_garage_door", (6.69, -1.2, 5.04), (8.23, -2.0, 0.0), 15),
                 ("basement_stairs", (5.16, -1.3, 2.41), (4.5, -1.6, 7.68), 16),
                 ("basement_sport", (7.68, -1.4, 7.24), (10.4, -2.0, 7.24), 18)],
    "ground": [("ground_lock", (5.71, -0.5, 7.02), (5.73, 0.9, 5.15), 18),
               ("ground_kitchen", (3.52, 1.6, 8.01), (0.99, 0.7, 0.66), 15),
               ("ground_living", (6.69, 1.6, 8.01), (8.78, 0.8, 0.44), 15),
               ("ground_hall", (5.71, 1.6, 0.44), (4.83, 1.0, 6.58), 15),
               ("ground_hall_plant", (5.82, 1.6, 4.6), (4.5, 0.6, 0.44), 15)],
    "first": [("first_bedroom", (3.52, 4.5, 8.01), (0.55, 3.4, 3.94), 15),
              ("first_kids", (6.58, 4.5, 3.61), (9.66, 3.4, 7.9), 15),
              ("first_bathroom", (6.58, 4.5, 2.85), (9.88, 3.4, 0.33), 15),
              ("first_landing_doors", (5.16, 4.6, 0.66), (5.05, 3.6, 5.04), 15)],
    "attic": [("attic_loft", (0.66, 7.4, 4.16), (9.33, 6.4, 4.16), 14),
              ("attic_dormer", (5.05, 7.4, 2.63), (7.9, 6.6, 8.12), 15)],
}


def stand_ins():
    """Preview only: the Cabinets as coloured boxes and the washing machine as a box."""
    made = []
    for c in CABINETS:
        pos, yaw, _ = cabinet_spot(c)
        name = "stand_" + c[0]
        if name not in bpy.data.materials:
            m = bpy.data.materials.new(name)
            m.diffuse_color = F.srgb(0.9, 0.5, 0.2)
        p = F.Part()
        p.add(F.box(-0.75, 0.75, 0.0, 2.0, -0.25, 0.25), name)
        o = p.to_object("Stand_" + c[0])
        o.location = (pos[0], -pos[2], pos[1])
        o.rotation_euler = (0, 0, yaw)
        made.append(o)
    if "stand_washer" not in bpy.data.materials:
        bpy.data.materials.new("stand_washer").diffuse_color = F.srgb(0.6, 0.85, 0.75)
    p = F.Part()
    x, y, z = WASHER_POS
    p.add(F.box(x - 0.35, x + 0.35, y, y + 0.95, z - 0.35, z + 0.35), "stand_washer")
    made.append(p.to_object("Stand_washer"))
    return made


def render_previews(objs, preview_dir, final, only):
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
        world.node_tree.nodes["Background"].inputs[0].default_value = F.srgb(0.80, 0.88, 0.96)
        world.node_tree.nodes["Background"].inputs[1].default_value = 0.7
        scene.world = world
        for l in F.LIGHTS:
            if l["kind"] in ("ceiling", "lamp"):
                lo = bpy.data.objects.new("L", bpy.data.lights.new("L", "POINT"))
                lo.data.energy, lo.data.color = (60 if l["kind"] == "ceiling" else 12), (1.0, 0.88, 0.7)
                lo.data.shadow_soft_size = 0.3
                p = l["pos"]
                lo.location = (p[0], -p[2], p[1])
                scene.collection.objects.link(lo)
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
        sh.show_backface_culling = True     # the top views look down from inside the ceiling slab
        res = (640, 400)

    def shot(name, pos, target, lens=16, ortho=None, size=res, clip=0.02):
        scene.render.resolution_x, scene.render.resolution_y = size
        cam.data.type = "ORTHO" if ortho else "PERSP"
        if ortho:
            cam.data.ortho_scale = ortho
        cam.data.lens = lens
        cam.data.clip_start = clip
        cam.location = Vector((pos[0], -pos[2], pos[1]))
        t = Vector((target[0], -target[2], target[1]))
        cam.rotation_euler = (t - cam.location).to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = os.path.join(preview_dir, name + ".png")
        bpy.ops.render.render(write_still=True)

    for level, y0, h in LEVELS:
        if only and level != only:
            continue
        # Top view: an ortho camera just under the ceiling (above the attic floor's eaves) sees
        # only what is below it.
        cy = y0 + (h + 0.01 if level != "attic" else 2.0)
        shot("top_" + level, (W / 2, cy, D / 2 + 0.0001), (W / 2, y0 - 5, D / 2), ortho=11.6,
             size=(560, 480) if not final else (1120, 960), clip=0.001)
        for name, pos, target, lens in VIEWS[level]:
            shot(name, pos, target, lens)


# --- Build ----------------------------------------------------------------------------------

GROUPS_STATIC = {}


def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    F.MATERIALS.update(EXTRA_MATERIALS)
    F.make_materials()
    objs = {}

    def add_group(name, made):
        static = []
        for o in made:
            if o.name in F.OPENABLE_NODES:
                objs[o.name] = o
            else:
                static.append(o)
        if static:
            o = F.merge(name, static)
            objs[o.name] = o

    fl, ce = make_floors_and_ceilings()
    add_group("Floor", [fl])
    add_group("Ceiling", [ce, make_lamps()])
    add_group("Shades", [make_shades()])
    lock_frames, lock_panels, lock_parts = make_locked_doors()
    add_group("Walls", [make_partitions(), make_exterior_walls(), make_mirror_frame(), lock_panels])
    add_group("Trim", [make_door_frames(), lock_frames])
    for o in make_room_doors() + lock_parts:
        objs[o.name] = o
    add_group("Roof", [make_roof()])
    add_group("Stairs", [make_stairs()])
    add_group("Rugs", [make_rugs()])
    # The Wardrobe Station's spot, doors, colliders and footprint, moved to the plan. Its model is
    # a Blender MCP asset the game places there (pipeline/05), so nothing is drawn here.
    placed([F.make_wardrobe], "bedroom", off=(0.0, LY["first"], -5.72))
    frame, glass, window_info = make_windows()
    objs[frame.name] = frame
    objs[glass.name] = glass
    for wname, room, side, face, w0, w1, sill, head in window_info:
        F.LIGHTS.append({"name": "Sun_" + wname, "kind": "window", "room": room,
                         "pos": v3(F.face_point(face, 0.1, (sill + head) / 2, (w0 + w1) / 2))})
    for l in F.LIGHTS:
        F.empty(l["name"], l["pos"])
    check_zones(objs)
    split_by_level()
    objs = {o.name: o for o in bpy.context.scene.objects if o.type == "MESH"}
    counts = {k: F.tris(v) for k, v in objs.items()}
    print("TRIS", counts, "TOTAL", sum(counts.values()))
    print("COLLIDERS", len(F.COLLIDERS), "RAMPS", len(RAMPS), "LIGHTS", len(F.LIGHTS))
    print("SOCK_COLLIDERS %d (%d of 8 corners)" % make_sock_colliders())
    for o in bpy.context.scene.objects:
        o.select_set(True)
    os.makedirs(OUT_DIR, exist_ok=True)
    out = os.path.join(OUT_DIR, "house.glb")
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_yup=True, export_apply=True,
                              export_cameras=False, export_lights=False, use_selection=True)
    path = os.path.join(OUT_DIR, "house_layout.json")
    data = layout(window_info)
    # The sections the shell does not own (house/25) are kept as they are: the parts' models, the
    # furniture's placements, the Elevator's records (make_elevator.py).
    old = json.load(open(path)) if os.path.exists(path) else {}
    for key in KEPT_SECTIONS:
        if key in old:
            data[key] = old[key]
    write_layout(path, data)
    print("EXPORTED", out)
    if PREVIEW_DIR:
        os.makedirs(PREVIEW_DIR, exist_ok=True)
        render_previews(objs, PREVIEW_DIR, FINAL, ONLY)


def level_cuts():
    """The heights (Blender z, the game's y) between the levels: the middle of each floor slab."""
    return [(LEVELS[i][1] + LEVELS[i][2] + LEVELS[i + 1][1]) / 2.0 for i in range(len(LEVELS) - 1)]


def split_by_level():
    """Cuts every mesh that spans more than one level at the floor slabs and parts it into one
    object per level, named <name>_<level> (house/27). The game puts each level on a render layer
    of its own and each ceiling light lights only its level's layers, so a light shines through
    no floor even where it casts no shadow."""
    import bmesh
    cuts = level_cuts()
    names = [n for n, _, _ in LEVELS]

    def band(z):
        return sum(1 for c in cuts if z > c)

    for o in [o for o in bpy.context.scene.objects if o.type == "MESH"]:
        # A moving part stays whole, on its pin (a leaf that spans a floor slab); the game keeps
        # what spans levels on every light's layer.
        if o.name.startswith(("Door_", "LockDoor_", "LockChain_", "LockPadlock_")):
            continue
        zs = [(o.matrix_world @ v.co).z for v in o.data.vertices]
        if not zs or band(min(zs) + 0.01) == band(max(zs) - 0.01):
            continue
        me = o.data
        me.transform(o.matrix_world)
        o.matrix_world = Matrix.Identity(4)
        bm = bmesh.new()
        bm.from_mesh(me)
        for c in cuts:
            if min(zs) < c < max(zs):
                bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:],
                                       plane_co=(0.0, 0.0, c), plane_no=(0.0, 0.0, 1.0))
        bands = {}
        for f in bm.faces:
            bands.setdefault(band(f.calc_center_median().z), []).append(f.index)
        bm.free()
        for b, keep in sorted(bands.items()):
            part = bmesh.new()
            part.from_mesh(me)
            for c in cuts:
                if min(zs) < c < max(zs):
                    bmesh.ops.bisect_plane(part, geom=part.verts[:] + part.edges[:] + part.faces[:],
                                           plane_co=(0.0, 0.0, c), plane_no=(0.0, 0.0, 1.0))
            part.faces.ensure_lookup_table()
            keep = set(keep)
            bmesh.ops.delete(part, geom=[f for f in part.faces if f.index not in keep], context="FACES")
            pm = me.copy()
            pm.name = "%s_%s" % (me.name, names[b])
            part.to_mesh(pm)
            part.free()
            po = bpy.data.objects.new("%s_%s" % (o.name, names[b]), pm)
            bpy.context.scene.collection.objects.link(po)
        bpy.data.objects.remove(o)


# The layout's sections other scripts or hands own; make_house.py keeps them when it rewrites the file.
KEPT_SECTIONS = ("parts", "placements", "elevator", "machines", "props", "grotto", "laundry_bins")


def write_layout(path, data):
    """house_layout.json, indented by one, each placement on a line of its own (moving a piece is a
    one-line edit)."""
    copy = dict(data)
    rows = copy.pop("placements", None)
    text = json.dumps(copy, indent=1)
    if rows is not None:
        lines = ",\n".join("  " + json.dumps(r) for r in rows)
        text = text[:-2] + ',\n "placements": [\n' + lines + "\n ]\n}"
    with open(path, "w") as fh:
        fh.write(text)
        fh.write("\n")


if __name__ == "__main__":
    build()
