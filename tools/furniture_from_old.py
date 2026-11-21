#!/usr/bin/env python3
"""The old game's 67 furniture pieces into this project (assets/04 F02, F04), step one of two.

    python3 tools/furniture_from_old.py [--old <dir>] [--pieces a,b] [--data <file>]
    python3 tools/furniture_from_old.py --uids     after tools/furniture_build.gd: the uids

For every old `assets/house/furniture/<piece>.glb` and its manifest entry it writes:

- `assets/furniture/<piece>.glb`: the old model with its collision-only nodes (`sock_<n>-convcolonly`,
  `-colonly`) taken out and the buffer repacked (technical, Q2153: the collision lives in the scene).
  Meshes, names, origins (floor centre of the bounding box, +Z front, F04) and materials stay.
- `assets/furniture/<piece>.glb.import`: each mesh saved to `assets/furniture/meshes/<mesh>.res`, each
  material mapped to the shared library's `game/materials/<name>.tres` (Q2389).
- The data file (default `.godot/furniture_from_old.json`) that `tools/furniture_build.gd` turns into the
  scenes: per piece its meshes and where they hang, the moving parts (pivot, axis, how far), the
  collision shapes from the old collision nodes (a hull of 8 box corners as a box, the old game's
  HouseParts rule; other hulls as convex points; `-colonly` as triangles), the manifest's colliders,
  containers, crawl data, lamp, piano keys, and the Sock spots joined into rects.

`--uids` gives the scenes furniture_build.gd wrote (a script run saves them without uids) their
`uid=` header and the uid of every ext_resource, as the editor writes them (Q2268).

Run once: after that the scenes are the truth, edited by hand (Q2151, Q2152). The glbs and their imports
are rewritten only for the pieces named (--pieces) or all.
"""
import json
import math
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OLD = os.path.join(ROOT, "reference", "it-socks", "assets", "house", "furniture")
OUT = os.path.join(ROOT, "assets", "furniture")
DATA = os.path.join(ROOT, ".godot", "furniture_from_old.json")
# The old game's resting tops (tools/blender/house_furniture/tops.py, game/house/house_parts.gd): the grid
# (cell (i, k) centred on ((i + 0.5) * step, (k + 0.5) * step)) and HouseParts' rules.
SPOT_STEP = 0.04
SPOT_RISE = 0.05
SPOT_HEADROOM = 0.12
SPOT_INSET = 0.06
SPOT_LEVEL = 0.02
SPOT_BAND = 0.05

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import materials_from_old  # noqa: E402  (its uid rule names the library files)


def arg(name, default):
    return sys.argv[sys.argv.index(name) + 1] if name in sys.argv else default


# --- glb ------------------------------------------------------------------------------------------

def read_glb(path):
    data = open(path, "rb").read()
    jlen = struct.unpack("<I", data[12:16])[0]
    j = json.loads(data[20:20 + jlen])
    off = 20 + jlen
    blen = struct.unpack("<I", data[off:off + 4])[0]
    return j, data[off + 8:off + 8 + blen]


def write_glb(path, j, bin_data):
    js = json.dumps(j, separators=(",", ":")).encode()
    js += b" " * ((4 - len(js) % 4) % 4)
    bin_data += b"\0" * ((4 - len(bin_data) % 4) % 4)
    total = 12 + 8 + len(js) + 8 + len(bin_data)
    with open(path, "wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, total))
        f.write(struct.pack("<II", len(js), 0x4E4F534A) + js)
        f.write(struct.pack("<II", len(bin_data), 0x004E4942) + bin_data)


def accessor(j, bin_data, i):
    """The accessor's values as a list of tuples (floats or ints)."""
    a = j["accessors"][i]
    bv = j["bufferViews"][a["bufferView"]]
    comps = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[a["type"]]
    fmt = {5126: "f", 5125: "I", 5123: "H", 5121: "B"}[a["componentType"]]
    size = struct.calcsize(fmt)
    stride = bv.get("byteStride", size * comps)
    start = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
    out = []
    for n in range(a["count"]):
        o = start + n * stride
        out.append(struct.unpack_from("<" + fmt * comps, bin_data, o))
    return out


def is_collision(name):
    return "-colonly" in name or "-convcolonly" in name


def cleaned(j, bin_data):
    """The glb without its collision-only nodes and what only they used, the buffer repacked."""
    root = j["scenes"][0]["nodes"][0]
    keep_nodes = [root] + [c for c in j["nodes"][root].get("children", []) if not is_collision(j["nodes"][c]["name"])]
    node_map = {old: new for new, old in enumerate(keep_nodes)}
    nodes = []
    mesh_ids = []
    for old in keep_nodes:
        nd = dict(j["nodes"][old])
        if old == root:
            nd["children"] = [node_map[c] for c in nd.get("children", []) if c in node_map]
        else:
            nd.pop("children", None)   # a moving part's children are its collision nodes only
        if "mesh" in nd:
            mesh_ids.append(nd["mesh"])
        nodes.append(nd)
    mesh_map = {old: new for new, old in enumerate(mesh_ids)}
    for nd in nodes:
        if "mesh" in nd:
            nd["mesh"] = mesh_map[nd["mesh"]]
    meshes = [json.loads(json.dumps(j["meshes"][m])) for m in mesh_ids]
    for nd in nodes:
        if "mesh" in nd:
            meshes[nd["mesh"]]["name"] = nd["name"]   # Godot names it <file>_<mesh>: kitchen_oven_Door
    acc_ids = []
    for m in meshes:
        for p in m["primitives"]:
            for k in list(p["attributes"]):
                acc_ids.append(p["attributes"][k])
            if "indices" in p:
                acc_ids.append(p["indices"])
    acc_ids = sorted(set(acc_ids))
    acc_map = {old: new for new, old in enumerate(acc_ids)}
    for m in meshes:
        for p in m["primitives"]:
            p["attributes"] = {k: acc_map[v] for k, v in p["attributes"].items()}
            if "indices" in p:
                p["indices"] = acc_map[p["indices"]]
    accessors = [dict(j["accessors"][a]) for a in acc_ids]
    bv_ids = sorted({a["bufferView"] for a in accessors})
    bv_map = {}
    views = []
    blob = bytearray()
    for new, old in enumerate(bv_ids):
        bv = dict(j["bufferViews"][old])
        chunk = bin_data[bv.get("byteOffset", 0):bv.get("byteOffset", 0) + bv["byteLength"]]
        blob += b"\0" * ((4 - len(blob) % 4) % 4)
        bv["byteOffset"] = len(blob)
        bv["buffer"] = 0
        blob += chunk
        views.append(bv)
        bv_map[old] = new
    for a in accessors:
        a["bufferView"] = bv_map[a["bufferView"]]
    out = dict(j)
    out["nodes"] = nodes
    out["meshes"] = meshes
    out["accessors"] = accessors
    out["bufferViews"] = views
    out["buffers"] = [{"byteLength": len(blob)}]
    out["scenes"] = [{"name": j["scenes"][0].get("name", "Scene"), "nodes": [0]}]
    out["scene"] = 0
    return out, bytes(blob)


# --- collision ------------------------------------------------------------------------------------

def sub(a, b): return (a[0] - b[0], a[1] - b[1], a[2] - b[2])
def add(a, b): return (a[0] + b[0], a[1] + b[1], a[2] + b[2])
def dot(a, b): return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
def length(a): return math.sqrt(dot(a, a))
def cross(a, b): return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
def near(a, b, eps=1e-5): return length(sub(a, b)) <= eps


def box_of(points):
    """[basis x, y, z, centre, size] when 8 points are a box's corners (turned any way), else None
    (the old game's HouseParts._box_of)."""
    if len(points) != 8:
        return None
    p0 = points[0]
    far = max(points, key=lambda p: dot(sub(p, p0), sub(p, p0)))
    for i in range(1, 8):
        for jj in range(i + 1, 8):
            for k in range(jj + 1, 8):
                a, b, c = sub(points[i], p0), sub(points[jj], p0), sub(points[k], p0)
                if not near(add(add(add(p0, a), b), c), far, 1e-4):
                    continue
                tol = 1e-4 * (length(a) + length(b) + length(c))
                if abs(dot(a, b)) > tol or abs(dot(b, c)) > tol or abs(dot(a, c)) > tol:
                    continue
                corners = [add(add(add(p0, a if m & 1 else (0, 0, 0)), b if m & 2 else (0, 0, 0)), c if m & 4 else (0, 0, 0)) for m in range(8)]
                if not all(any(near(p, q, 1e-4) for q in corners) for p in points):
                    continue
                x = tuple(v / length(a) for v in a)
                y = tuple(v / length(b) for v in b)
                centre = add(p0, tuple((a[n] + b[n] + c[n]) / 2 for n in range(3)))
                return [x, y, cross(x, y), centre, (length(a), length(b), length(c))]
    return None


def r(v, n=5):
    return [round(x, n) for x in v]


def shapes_of(j, bin_data, node_index, owner, offset):
    """The collision node's shapes, in its owner's space (offset: the node's place there)."""
    nd = j["nodes"][node_index]
    t = nd.get("translation", [0, 0, 0])
    at = add(tuple(offset), tuple(t))
    mesh = j["meshes"][nd["mesh"]]
    out = []
    if "-colonly" in nd["name"]:
        tris = []
        for p in mesh["primitives"]:
            pos = accessor(j, bin_data, p["attributes"]["POSITION"])
            idx = [i[0] for i in accessor(j, bin_data, p["indices"])] if "indices" in p else list(range(len(pos)))
            tris += [r(add(pos[i], at)) for i in idx]
        out.append({"owner": owner, "type": "trimesh", "name": nd["name"], "faces": tris})
        return out
    pts = []
    for p in mesh["primitives"]:
        for v in accessor(j, bin_data, p["attributes"]["POSITION"]):
            v = add(v, at)
            if not any(near(v, q) for q in pts):
                pts.append(v)
    box = box_of(pts)
    if box is not None:
        out.append({"owner": owner, "type": "box", "name": nd["name"], "basis": [r(box[0]), r(box[1]), r(box[2])],
                    "origin": r(box[3]), "size": r(box[4])})
    else:
        out.append({"owner": owner, "type": "convex", "name": nd["name"], "points": [r(p) for p in pts]})
    return out


# --- spots ----------------------------------------------------------------------------------------

def spot_rects(spots):
    """The manifest's spot cells [i, k, y, clear, seen] as the old game joined them (HouseParts.tops(),
    its piece-local part; what the house round a placed piece leaves clear is the level's to decide):
    only seen spots at least SPOT_RISE over the floor with SPOT_HEADROOM clear over them, whose
    neighbours within SPOT_INSET lie on the same top (within SPOT_LEVEL), joined greedily into rects per
    SPOT_BAND of height: {min: [x, z], max: [x, z], y (the highest), top (the lowest y + clear)}."""
    cells = {}
    for i, k, y, clear, seen in spots:
        if y < SPOT_RISE or clear < SPOT_HEADROOM:
            continue
        cells.setdefault((i, k), []).append((y, clear, int(seen) == 1))
    reach = math.ceil(SPOT_INSET / SPOT_STEP - 1e-3)
    near_cells = [(a, b) for a in range(-reach, reach + 1) for b in range(-reach, reach + 1) if a * a + b * b <= reach * reach]
    good = {}
    for (i, k), hs in cells.items():
        for y, clear, seen in hs:
            if not seen:
                continue
            if all(any(abs(o[0] - y) <= SPOT_LEVEL for o in cells.get((i + a, k + b), [])) for a, b in near_cells):
                good[(i, k, math.floor(y / SPOT_BAND))] = (y, clear)
    out = []
    left = dict(good)
    for key in sorted(good, key=lambda c: (c[2], c[1], c[0])):
        if key not in left:
            continue
        i0, k0, band = key
        i1 = i0
        while (i1 + 1, k0, band) in left:
            i1 += 1
        k1 = k0
        while all((i, k1 + 1, band) in left for i in range(i0, i1 + 1)):
            k1 += 1
        y_max, top = -1e9, 1e9
        for i in range(i0, i1 + 1):
            for k in range(k0, k1 + 1):
                y, clear = left.pop((i, k, band))
                y_max = max(y_max, y)
                top = min(top, y + clear)
        out.append({"min": [round(i0 * SPOT_STEP, 3), round(k0 * SPOT_STEP, 3)],
                    "max": [round((i1 + 1) * SPOT_STEP, 3), round((k1 + 1) * SPOT_STEP, 3)],
                    "y": round(y_max, 3), "top": round(top, 3)})
    return out


# --- import ---------------------------------------------------------------------------------------

IMPORT_HEAD = """[remap]

importer="scene"
importer_version=1
type="PackedScene"

[params]

nodes/root_type=""
nodes/root_name=""
nodes/root_script=null
mesh_library/use_node_names_as_mesh_names=false
array_mesh/deduplicate_surfaces=true
nodes/apply_root_scale=true
nodes/root_scale=1.0
nodes/import_as_skeleton_bones=false
nodes/use_name_suffixes=true
nodes/use_node_type_suffixes=true
meshes/ensure_tangents=true
meshes/generate_lods=true
meshes/create_shadow_meshes=true
meshes/light_baking=1
meshes/lightmap_texel_size=0.2
meshes/force_disable_compression=false
skins/use_named_skins=true
animation/import=false
animation/fps=30
animation/trimming=false
animation/remove_immutable_tracks=true
animation/import_rest_as_RESET=false
import_script/path=""
materials/extract=0
materials/extract_format=0
materials/extract_path=""
"""


def mesh_path(piece, node):
    return "res://assets/furniture/meshes/%s_%s.res" % (piece, node)


def import_text(piece, j):
    meshes = {}
    for m in j["meshes"]:
        path = mesh_path(piece, m["name"])
        meshes["%s_%s" % (piece, m["name"])] = {"generate/lightmap_uv": 0, "generate/lods": 0, "generate/shadow_meshes": 0,
                             "lods/normal_merge_angle": 20.0, "save_to_file/enabled": True,
                             "save_to_file/fallback_path": path, "save_to_file/path": path}
    materials = {}
    for m in j.get("materials", []):
        path = "res://game/materials/%s.tres" % m["name"]
        materials[m["name"]] = {"use_external/enabled": True, "use_external/fallback_path": path,
                                "use_external/path": materials_from_old.uid(path)}
    sub_res = json.dumps({"materials": materials, "meshes": meshes}, indent=0, sort_keys=True)
    return IMPORT_HEAD + "_subresources=" + sub_res + "\ngltf/naming_version=2\ngltf/embedded_image_handling=1\n"


# --- uids ---------------------------------------------------------------------------------------

def known_uids():
    """res path -> uid text of every file the furniture scenes refer to."""
    import re
    out = {}
    for dirpath, _dirs, files in os.walk(ROOT):
        if "/." in dirpath.replace(ROOT, "") or "/reference" in dirpath.replace(ROOT, "") or "/kit/" in dirpath + "/":
            continue
        for f in files:
            full = os.path.join(dirpath, f)
            res = "res://" + os.path.relpath(full, ROOT).replace(os.sep, "/")
            if f.endswith(".uid"):
                out[res[:-4]] = open(full).read().strip()
            elif f.endswith(".import"):
                text = open(full).read()
                m = re.search(r'^uid="([^"]+)"', text, re.M)
                if m:
                    out[res[:-7]] = m.group(1)
                for path, uid in re.findall(r'"save_to_file/fallback_path": "([^"]+)",\s*"save_to_file/path": "(uid://[^"]+)"', text):
                    out[path] = uid
            elif f.endswith((".tscn", ".tres")):
                m = re.search(r'uid="(uid://[^"]+)"', open(full).readline())
                if m:
                    out[res] = m.group(1)
    return out


def add_uids():
    import re
    folder = os.path.join(ROOT, "game", "furniture")
    scenes = []
    for dirpath, _dirs, files in os.walk(folder):
        scenes += [os.path.join(dirpath, f) for f in files if f.endswith(".tscn")]
    for full in scenes:
        text = open(full).read()
        first, rest = text.split("\n", 1)
        if "uid=" not in first:
            res = "res://" + os.path.relpath(full, ROOT).replace(os.sep, "/")
            first = first[:-1] + ' uid="%s"]' % materials_from_old.uid(res)
            open(full, "w", newline="\n").write(first + "\n" + rest)
    uids = known_uids()
    missing = set()
    for full in scenes:
        text = open(full).read()

        def fill(m):
            if "uid=" in m.group(0):
                return m.group(0)
            uid = uids.get(m.group(2))
            if uid is None:
                missing.add(m.group(2))
                return m.group(0)
            return '[ext_resource type="%s" uid="%s" path="%s"' % (m.group(1), uid, m.group(2))
        new = re.sub(r'\[ext_resource type="([^"]+)"(?: uid="[^"]+")? path="([^"]+)"', fill, text)
        if new != text:
            open(full, "w", newline="\n").write(new)
    print("furniture_from_old: uids in %d scenes%s" % (len(scenes), ("; no uid for " + ", ".join(sorted(missing))) if missing else ""))
    return 1 if missing else 0


# --- main -----------------------------------------------------------------------------------------

def main():
    if "--uids" in sys.argv:
        return add_uids()
    old = arg("--old", OLD)
    data_path = arg("--data", DATA)
    only = set(arg("--pieces", "").split(",")) - {""}
    if not os.path.isdir(old):
        print("furniture_from_old: no %s (the reference submodule; --old <dir>)" % old)
        return 1
    manifest = json.load(open(os.path.join(old, "manifest.json")))["pieces"]
    os.makedirs(os.path.join(OUT, "meshes"), exist_ok=True)
    data = {}
    lib = os.path.join(ROOT, "game", "materials")
    missing = set()
    for piece in sorted(manifest):
        e = manifest[piece]
        j, bin_data = read_glb(os.path.join(old, piece + ".glb"))
        root = j["scenes"][0]["nodes"][0]
        parts = e.get("parts", {})
        meshes, shapes = [], []
        for c in j["nodes"][root].get("children", []):
            nd = j["nodes"][c]
            name = nd["name"]
            t = nd.get("translation", [0, 0, 0])
            if is_collision(name):
                shapes += shapes_of(j, bin_data, c, "", (0, 0, 0))
                continue
            owner = name if name in parts else ""
            meshes.append({"node": name, "mesh": mesh_path(piece, name), "origin": r(t), "part": owner})
            for cc in nd.get("children", []):
                if is_collision(j["nodes"][cc]["name"]):
                    shapes += shapes_of(j, bin_data, cc, name, (0, 0, 0))
        for m in j.get("materials", []):
            if not os.path.exists(os.path.join(lib, m["name"] + ".tres")):
                missing.add(m["name"])
        keep = {k: e[k] for k in ("footprint", "height", "crawl_gap", "crawl_box", "hide", "rooms", "plan_spot",
                                  "note", "colliders", "containers", "lamp", "lamp_colour", "lamp_energy",
                                  "lamp_range", "keys") if k in e}
        keep["parts"] = {k: {kk: v[kk] for kk in ("kind", "pivot", "axis", "open_deg", "open_m", "boxes") if kk in v}
                         for k, v in parts.items()}
        keep["meshes"] = meshes
        keep["shapes"] = shapes
        keep["spots"] = spot_rects(e.get("spots", []))
        data[piece] = keep
        if not only or piece in only:
            cj, cb = cleaned(j, bin_data)
            write_glb(os.path.join(OUT, piece + ".glb"), cj, cb)
            with open(os.path.join(OUT, piece + ".glb.import"), "w", newline="\n") as f:
                f.write(import_text(piece, cj))
        print("%-22s meshes %3d  shapes %3d  spot rects %4d" % (piece, len(meshes), len(shapes), len(keep["spots"])))
    if missing:
        print("furniture_from_old: materials not in the library: %s" % ", ".join(sorted(missing)))
        return 1
    os.makedirs(os.path.dirname(data_path), exist_ok=True)
    with open(data_path, "w") as f:
        json.dump(data, f)
    print("furniture_from_old: %d pieces, data %s" % (len(data), data_path))
    return 0


if __name__ == "__main__":
    sys.exit(main())
