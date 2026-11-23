#!/usr/bin/env python3
"""The house's level scene from the old house (house/04, Q2503, Q2509-Q2512): writes
game/house/house.tscn once, then it is edited by hand in the editor.

    python3 tools/house_from_old.py [--ref <old game folder>] [--force] [--print]

What it writes, in the editor's format (uids, unique_ids):
- the shell (game/house/shell.tscn, tools/house_shell_build.gd) at the origin, the house's frame;
- every old furniture placement of the house's four floors (the old layout's `placements`, read through
  the old game's own reading of it: HouseParts.placed) as an instance of game/furniture/<piece>.tscn,
  moved to the re-gridded plan (below), turned as the old one, lifted by its old `y`;
- the old lights: a ceiling light per old room light marker (Room._build_light: 8 cm under the marker,
  the old lamp colour, energy 1, range 6, shadow on, blur 2, bias 0.05) and the old lamps' lights
  (a placement's `lamp`: the lamp colour, energy 0.7, range 3, no shadow);
- the zoo's noon light (sun, sky, grade), the player at the old spawn (room.gd spawn_pos, spawn_yaw),
  and the shared-state path as the zoo has it (Socks, Parts, Session, Avatars, LevelNet; a Host of one).

The move to the plan (docs/architecture/house-kit-plan.md): the old layout measures from the old
walls' inside faces; each room's inside faces moved to the new plan's (its "Rooms" table). A piece keeps
its distance to the nearer wall of its room on each axis, so what stood against a wall still does; a
ceiling light keeps its place across its room in proportion (the old ones hang in their rooms' middles).
Heights over a floor are the old ones; the floors are the new (-3, 0, 3, 6).
"""
import json
import math
import os
import random
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "game", "house", "house.tscn")

OLD_LEVELS = {"basement": -2.9, "ground": 0.0, "first": 2.9, "attic": 5.8}
NEW_LEVELS = {"basement": -3.0, "ground": 0.0, "first": 3.0, "attic": 6.0}
STOREY_OLD = 2.9
# The rooms' inside faces on the new plan (x0, z0, x1, z1), house-kit-plan.md "Rooms"; the stair rooms
# are the U stair's well between the partitions' faces, from its first riser to the south wall's face.
STAIRS = (4.06, 5.5, 6.44, 8.4)
NEW_ROOMS = {
    "workshop": (0.1, 0.1, 3.94, 3.44), "laundry": (0.1, 3.56, 3.94, 8.4), "boiler": (4.06, 0.1, 6.44, 1.94),
    "stair_lobby": (4.06, 2.06, 6.44, 5.5), "garage": (6.56, 0.1, 10.4, 8.4), "stairs_basement": STAIRS,
    "kitchen": (0.1, 0.1, 3.94, 8.4), "hall": (4.06, 0.1, 6.44, 5.5), "living": (6.56, 0.1, 10.4, 8.4),
    "stairs_ground": STAIRS, "office": (0.1, 0.1, 3.94, 3.44), "bedroom": (0.1, 3.56, 3.94, 8.4),
    "landing": (4.06, 0.1, 6.44, 5.5), "bathroom": (6.56, 0.1, 10.4, 3.44), "kids": (6.56, 3.56, 10.4, 8.4),
    "stairs_first": STAIRS, "loft": (0.1, 0.1, 10.4, 8.4),
}
# The old room's lights (game/house/room.gd).
LAMP_COLOUR = (1.0, 0.88, 0.7)
CEILING_LIGHT_DROP = 0.08
# The res:// files the level uses beside the furniture: id -> (type, path).
EXT = [
    ("parts", "Script", "res://game/parts/parts.gd"),
    ("player", "PackedScene", "res://game/player/player.tscn"),
    ("session", "Script", "res://game/parts/session.gd"),
    ("avatars", "Script", "res://game/parts/avatar/avatars.gd"),
    ("avatar", "PackedScene", "res://game/parts/avatar/avatar.tscn"),
    ("net", "Script", "res://game/net/level_net.gd"),
    ("mess", "Script", "res://game/mess/mess.gd"),
    ("hands", "Script", "res://game/hands/hands.gd"),
    ("coins", "Script", "res://game/coins/coins.gd"),
    ("designs", "Resource", "res://game/sock/designs.tres"),
    ("tuning", "Resource", "res://game/hands/hands_tuning.tres"),
    ("env", "Environment", "res://game/look/noon_environment.tres"),
    ("picture", "PackedScene", "res://game/look/picture.tscn"),
    ("roster", "Script", "res://game/net/roster.gd"),
    ("coop", "Resource", "res://game/net/coop_tuning.tres"),
    ("knockdowns", "Script", "res://game/knockdown/knockdowns.gd"),
    ("knock_tuning", "Resource", "res://game/knockdown/knockdown_tuning.tres"),
    ("shell", "PackedScene", "res://game/house/shell.tscn"),
]
# What the zoo's FlightSpawner spawns (a flying Sock and a thrown pair), the same here.
SPAWNABLE = '"uid://uajin4n0hgrt", "uid://1pbfln7cmu0i"'


def uid_of(res_path):
    """A res:// file's uid: its .uid file (a script, a shader) or its header's uid=."""
    path = os.path.join(ROOT, res_path[len("res://"):])
    if os.path.exists(path + ".uid"):
        return open(path + ".uid").read().strip()
    with open(path) as f:
        head = f.readline()
    m = re.search(r'uid="(uid://[^"]+)"', head)
    if not m:
        sys.exit("house_from_old: %s has no uid" % res_path)
    return m.group(1)


def new_uid(rng):
    """A fresh uid as Godot writes one (ResourceUID::id_to_text: base 36, a-z then 0-9)."""
    n = rng.getrandbits(62)
    chars = []
    while True:
        c = n % 36
        chars.append(chr(ord("a") + c) if c < 26 else chr(ord("0") + c - 26))
        n //= 36
        if n == 0:
            break
    return "uid://" + "".join(reversed(chars))


def anchor(v, o0, o1, n0, n1):
    """The distance to the nearer wall kept."""
    return n0 + (v - o0) if v - o0 <= o1 - v else n1 - (o1 - v)


def across(v, o0, o1, n0, n1):
    """The place across the room kept in proportion."""
    return n0 + (v - o0) * (n1 - n0) / (o1 - o0)


def new_y(y):
    """An old height to the new: moved with the storey it is in."""
    for name in ("attic", "first", "ground", "basement"):
        if y >= OLD_LEVELS[name] - 1e-6:
            return y - OLD_LEVELS[name] + NEW_LEVELS[name]
    return y - OLD_LEVELS["basement"] + NEW_LEVELS["basement"]


def r(v):
    v = round(v, 4)
    return "0" if v == 0 else ("%g" % v)


def xform(yaw_deg, x, y, z):
    a = math.radians(yaw_deg)
    c, s = math.cos(a), math.sin(a)
    if abs(c) < 1e-9:
        c = 0.0
    if abs(s) < 1e-9:
        s = 0.0
    return "Transform3D(%s, 0, %s, 0, 1, 0, %s, 0, %s, %s, %s, %s)" % (r(c), r(s), r(-s), r(c), r(x), r(y), r(z))


def turn(yaw_deg, v):
    """A piece-space point turned as Basis(UP, yaw) turns it."""
    a = math.radians(yaw_deg)
    c, s = math.cos(a), math.sin(a)
    return (c * v[0] + s * v[2], v[1], -s * v[0] + c * v[2])


def main():
    args = sys.argv[1:]
    ref = os.path.join(ROOT, "reference", "it-socks")
    if "--ref" in args:
        ref = args[args.index("--ref") + 1]
    layout = json.load(open(os.path.join(ref, "assets", "house", "house_layout.json")))
    old_rooms = {rm["name"]: rm for rm in layout["rooms"]}
    rng = random.Random(2504)
    ids = set()

    def uid_node():
        while True:
            n = rng.randint(1, 2 ** 31 - 1)
            if n not in ids:
                ids.add(n)
                return n

    furniture = []
    counts = {}
    for p in layout["placements"]:
        if p["level"] not in NEW_LEVELS:
            continue
        tag = p["name"]
        counts[tag] = counts.get(tag, 0) + 1
        name = tag if counts[tag] == 1 else "%s%d" % (tag, counts[tag])
        o = old_rooms[p["room"]]
        n = NEW_ROOMS[p["room"]]
        x = anchor(p["pos"][0], o["min"][0], o["max"][0], n[0], n[2])
        z = anchor(p["pos"][1], o["min"][1], o["max"][1], n[1], n[3])
        y = NEW_LEVELS[p["level"]] + float(p.get("y", 0.0))
        scene = "res://game/furniture/%s.tscn" % p["piece"]
        if not os.path.exists(os.path.join(ROOT, scene[len("res://"):])):
            sys.exit("house_from_old: no %s for %s" % (scene, name))
        furniture.append({"name": name, "scene": scene, "yaw": float(p["yaw"]), "at": (x, y, z),
                          "room": p["room"], "lamp": p.get("lamp")})
    lights = []
    for lt in layout["lights"]:
        if lt["kind"] != "ceiling":
            continue
        o = old_rooms[lt["room"]]
        n = NEW_ROOMS[lt["room"]]
        x = across(lt["pos"][0], o["min"][0], o["max"][0], n[0], n[2])
        z = across(lt["pos"][2], o["min"][1], o["max"][1], n[1], n[3])
        y = new_y(lt["pos"][1]) - CEILING_LIGHT_DROP
        name = lt["name"].replace("CeilingLight_", "Ceiling_")
        lights.append({"name": name, "at": (x, y, z), "energy": 1.0, "range": 6.0, "shadow": True})
    for f in furniture:
        if f["lamp"]:
            off = turn(f["yaw"], f["lamp"])
            at = (f["at"][0] + off[0], f["at"][1] + off[1], f["at"][2] + off[2])
            lights.append({"name": "Lamp_" + f["name"], "at": at, "energy": 0.7, "range": 3.0, "shadow": False})
    sp = layout["spawn"]
    lr = old_rooms["laundry"]
    spawn_room = next(rm for rm in layout["rooms"] if rm["level"] == "basement"
                      and rm["min"][0] <= sp["pos"][0] <= rm["max"][0] and rm["min"][1] <= sp["pos"][2] <= rm["max"][1])
    n = NEW_ROOMS[spawn_room["name"]]
    spawn = (anchor(sp["pos"][0], spawn_room["min"][0], spawn_room["max"][0], n[0], n[2]),
             NEW_LEVELS["basement"],
             anchor(sp["pos"][2], spawn_room["min"][1], spawn_room["max"][1], n[1], n[3]))
    yaw = math.degrees(float(sp["yaw"]))
    del lr

    if "--print" in args:
        for f in furniture:
            print("%-16s %-22s yaw %4g at %s" % (f["name"], f["scene"].rsplit("/", 1)[1], f["yaw"],
                                                  ", ".join(r(v) for v in f["at"])))
        for lt in lights:
            print("%-22s at %s energy %s range %s" % (lt["name"], ", ".join(r(v) for v in lt["at"]), lt["energy"], lt["range"]))
        print("spawn %s yaw %.3f rad (%s in the old %s)" % (", ".join(r(v) for v in spawn), sp["yaw"], sp["pos"], spawn_room["name"]))
        return
    if os.path.exists(OUT) and "--force" not in args:
        sys.exit("house_from_old: %s exists (it is edited by hand); --force writes it again" % OUT)

    ext_lines = []
    ext_id = {}
    k = 1
    for key, kind, path in EXT:
        ext_id[key] = "%d_%s" % (k, key)
        ext_lines.append('[ext_resource type="%s" uid="%s" path="%s" id="%s"]' % (kind, uid_of(path), path, ext_id[key]))
        k += 1
    pieces = sorted({f["scene"] for f in furniture})
    for scene in pieces:
        key = scene.rsplit("/", 1)[1][:-5]
        ext_id[scene] = "%d_%s" % (k, key)
        ext_lines.append('[ext_resource type="PackedScene" uid="%s" path="%s" id="%s"]' % (uid_of(scene), scene, ext_id[scene]))
        k += 1

    out = ['[gd_scene format=3 uid="%s"]' % (uid_of("res://game/house/house.tscn") if os.path.exists(OUT) else new_uid(rng)), ""]
    out += ext_lines + [""]

    def node(name, kind=None, parent=None, extra=None, instance=None, props=()):
        head = '[node name="%s"' % name
        if kind:
            head += ' type="%s"' % kind
        if parent is not None:
            head += ' parent="%s"' % parent
        if extra:
            head += " " + extra
        head += " unique_id=%d" % uid_node()
        if instance:
            head += ' instance=ExtResource("%s")' % instance
        head += "]"
        out.append(head)
        out.extend(props)
        out.append("")

    E = lambda key: 'ExtResource("%s")' % ext_id[key]
    node("House", "Node3D")
    node("Environment", "WorldEnvironment", ".", props=["environment = " + E("env")])
    node("Sun", "DirectionalLight3D", ".", props=[
        "transform = Transform3D(0.900969, -0.198987, 0.385564, 0, 0.888633, 0.458618, -0.433884, -0.413201, 0.800631, 0, 6, 0)",
        "light_color = Color(1, 0.93, 0.82, 1)", "light_energy = 2.4", "shadow_enabled = true", "shadow_blur = 1.5",
        "directional_shadow_max_distance = 18.0", "sky_mode = 1"])
    node("Picture", None, ".", extra='node_paths=PackedStringArray("world_environment", "sun")', instance=ext_id["picture"],
         props=['world_environment = NodePath("../Environment")', 'sun = NodePath("../Sun")'])
    node("Shell", None, ".", instance=ext_id["shell"])
    node("Furniture", "Node3D", ".")
    for f in furniture:
        node(f["name"], None, "Furniture", instance=ext_id[f["scene"]],
             props=["transform = " + xform(f["yaw"], *f["at"])])
    node("Lights", "Node3D", ".")
    for lt in lights:
        props = ["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s, %s, %s)" % tuple(r(v) for v in lt["at"]),
                 "light_color = Color(%s, %s, %s, 1)" % tuple(r(v) for v in LAMP_COLOUR)]
        if lt["energy"] != 1.0:
            props.append("light_energy = %s" % r(lt["energy"]))
        if lt["shadow"]:
            props += ["shadow_enabled = true", "shadow_bias = 0.05", "shadow_blur = 2.0"]
        props.append("omni_range = %s" % r(lt["range"]))
        node(lt["name"], "OmniLight3D", "Lights", props=props)
    node("Player", None, ".", instance=ext_id["player"], props=["transform = " + xform(yaw, *spawn)])
    node("Spots", "Node3D", ".")
    node("ReturnSpot", "Marker3D", ".", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s, %s, %s)" % tuple(r(v) for v in spawn)])
    node("Lying", "Node3D", ".")
    node("Flights", "Node3D", ".")
    node("FlightSpawner", "MultiplayerSpawner", ".", props=["_spawnable_scenes = PackedStringArray(%s)" % SPAWNABLE,
                                                             'spawn_path = NodePath("../Flights")'])
    node("Socks", "Node", ".")
    node("Mess", "Node", "Socks", extra='node_paths=PackedStringArray("spots", "lying", "flights", "return_spot")', props=[
        "script = " + E("mess"), "catalogue = " + E("designs"), "tuning = " + E("tuning"), 'spots = NodePath("../../Spots")',
        'lying = NodePath("../../Lying")', 'flights = NodePath("../../Flights")', "bounds = AABB(-2, -5, -2, 14.5, 17, 12.5)",
        'return_spot = NodePath("../../ReturnSpot")'])
    node("Hands", "Node", "Socks", extra='node_paths=PackedStringArray("mess")', props=[
        "script = " + E("hands"), 'mess = NodePath("../Mess")', "tuning = " + E("tuning")])
    node("Knockdowns", "Node", "Socks", extra='node_paths=PackedStringArray("hands")', props=[
        "script = " + E("knockdowns"), "tuning = " + E("knock_tuning"), 'hands = NodePath("../Hands")'])
    node("Coins", "Node", "Socks", props=["script = " + E("coins")])
    node("Parts", "Node", ".", props=["script = " + E("parts")])
    node("Players", "Node3D", ".")
    node("Avatars", "MultiplayerSpawner", ".", extra='node_paths=PackedStringArray("local_body", "roster")', props=[
        'spawn_path = NodePath("../Players")', "script = " + E("avatars"), "avatar_scene = " + E("avatar"),
        'local_body = NodePath("../Player")', 'roster = NodePath("../Session/Roster")'])
    node("Session", "Node", ".", extra='node_paths=PackedStringArray("parts", "roster")', props=[
        "script = " + E("session"), 'parts = NodePath("../Parts")', 'roster = NodePath("Roster")', "tuning = " + E("coop")])
    node("Roster", "Node", "Session", props=["script = " + E("roster"), "tuning = " + E("coop")])
    node("Net", "Node", ".", extra='node_paths=PackedStringArray("session", "avatars")', props=[
        "script = " + E("net"), 'session = NodePath("../Session")', 'avatars = NodePath("../Avatars")'])
    node("Hud", "CanvasLayer", "Net")
    node("Mode", "Label", "Net/Hud", props=["unique_name_in_owner = true", "offset_left = 12.0", "offset_top = 8.0",
                                            "offset_right = 600.0", "offset_bottom = 34.0"])
    while out and out[-1] == "":
        out.pop()
    with open(OUT, "w", newline="\n") as f:
        f.write("\n".join(out) + "\n")
    print("house_from_old: %s, %d pieces, %d lights" % (OUT, len(furniture), len(lights)))


if __name__ == "__main__":
    main()
