#!/usr/bin/env python3
"""The mesh check: does a re-exported .glb match the one in the game, within a tolerance?

    python3 assets_src/generate/glb_compare.py <new.glb> <game.glb> [--tol 0.0001] [--quiet]
    python3 assets_src/generate/glb_compare.py <new dir> <game dir> [--tol ...]   every glb of <game dir>

Plain Python (no Blender). It compares what makes the model, and nothing the exporter is free to
order or pack differently:

- the drawn nodes by name (collision-only nodes, `-colonly` and `-convcolonly`, are left out: in this
  project collision lives in the Godot scenes, Q2152), each one's parent, translation, rotation and
  scale;
- per drawn mesh: its primitives in order, each one's material name, vertex count, triangle count, the
  POSITION box, and every vertex position (in order; when the order differs, as sorted points);
- the skins' joint names;
- the embedded images (the Cabinets' front art) by name, pixel by pixel (8-bit PNG; a channel may
  differ by 1 of 255).

A difference within `--tol` (metres, default 0.1 mm) passes. Prints one line per difference, then one
verdict line: `MESH-SAME <game.glb>` or `MESH-DIFF <game.glb>: <n> differences`. Exit 1 on any DIFF.
"""
import json
import os
import re
import struct
import sys
import zlib

COLLIDER_ENDS = ("-colonly", "-convcolonly")
COMP = {5120: ("b", 1), 5121: ("B", 1), 5122: ("h", 2), 5123: ("H", 2), 5125: ("I", 4), 5126: ("f", 4)}
WIDTH = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def read_glb(path):
    data = open(path, "rb").read()
    if data[:4] != b"glTF":
        raise ValueError(f"{path}: not a binary glTF (an LFS pointer? run git lfs pull)")
    jlen = struct.unpack("<I", data[12:16])[0]
    j = json.loads(data[20:20 + jlen])
    off = 20 + jlen
    blob = b""
    if off < len(data):
        blen = struct.unpack("<I", data[off:off + 4])[0]
        blob = data[off + 8:off + 8 + blen]
    return j, blob


def accessor(j, blob, i):
    a = j["accessors"][i]
    v = j["bufferViews"][a["bufferView"]]
    fmt, size = COMP[a["componentType"]]
    n = WIDTH[a["type"]]
    stride = v.get("byteStride") or size * n
    base = v.get("byteOffset", 0) + a.get("byteOffset", 0)
    out = []
    for k in range(a["count"]):
        out.append(struct.unpack_from("<" + fmt * n, blob, base + k * stride))
    return out


def is_collider(name):
    """`-colonly` or `-convcolonly` at the end, after any digits and Blender's `.001` copies."""
    low = re.sub(r"[0-9.]+$", "", name.lower())
    return low.endswith(COLLIDER_ENDS)


def model(path):
    """{node name: {parent, t, r, s, mesh: [primitive dicts] or None, skin: [joint names] or None}}"""
    j, blob = read_glb(path)
    nodes = j.get("nodes", [])
    parent = {}
    for i, n in enumerate(nodes):
        for c in n.get("children", []):
            parent[c] = i
    mats = [m.get("name", "") for m in j.get("materials", [])]
    out = {}
    for i, n in enumerate(nodes):
        name = n.get("name", f"#{i}")
        if is_collider(name) or any(is_collider(nodes[p].get("name", "")) for p in chain(parent, i)):
            continue
        e = {"parent": nodes[parent[i]].get("name") if i in parent else None,
             "t": n.get("translation", [0, 0, 0]), "r": n.get("rotation", [0, 0, 0, 1]),
             "s": n.get("scale", [1, 1, 1]), "mesh": None, "skin": None}
        if "mesh" in n:
            prims = []
            for p in j["meshes"][n["mesh"]]["primitives"]:
                pos = accessor(j, blob, p["attributes"]["POSITION"])
                idx = accessor(j, blob, p["indices"]) if "indices" in p else [(k,) for k in range(len(pos))]
                prims.append({"material": mats[p["material"]] if "material" in p else None,
                              "pos": pos, "tris": len(idx) // 3})
            e["mesh"] = prims
        if "skin" in n:
            e["skin"] = [nodes[k].get("name") for k in j["skins"][n["skin"]]["joints"]]
        out[name] = e
    return out


def png_pixels(data):
    """(width, height, channels, raw rows) of an 8-bit, non-interlaced PNG; None if it is another kind.
    Pixels only: colour-profile chunks (Blender 5.3 adds cICP and iCCP) do not count."""
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    i, idat, head = 8, [], None
    while i < len(data):
        n, t = struct.unpack(">I4s", data[i:i + 8])
        body = data[i + 8:i + 8 + n]
        if t == b"IHDR":
            head = struct.unpack(">IIBBBBB", body)
        elif t == b"IDAT":
            idat.append(body)
        i += 12 + n
    w, h, depth, ctype, _c, _f, interlace = head
    ch = {0: 1, 2: 3, 4: 2, 6: 4}.get(ctype)
    if depth != 8 or interlace or ch is None:
        return None
    raw = zlib.decompress(b"".join(idat))
    stride = w * ch
    rows, prev = [], bytearray(stride)
    for y in range(h):
        f = raw[y * (stride + 1)]
        line = bytearray(raw[y * (stride + 1) + 1:(y + 1) * (stride + 1)])
        for x in range(stride):
            a = line[x - ch] if x >= ch else 0
            b = prev[x]
            c = prev[x - ch] if x >= ch else 0
            if f == 1:
                line[x] = (line[x] + a) & 255
            elif f == 2:
                line[x] = (line[x] + b) & 255
            elif f == 3:
                line[x] = (line[x] + (a + b) // 2) & 255
            elif f == 4:
                pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
                line[x] = (line[x] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        rows.append(bytes(line))
        prev = line
    return w, h, ch, b"".join(rows)


def images(path):
    """{image name: (width, height, channels, pixels) or the raw bytes}"""
    j, blob = read_glb(path)
    out = {}
    for k, im in enumerate(j.get("images", [])):
        if "bufferView" not in im:
            continue
        v = j["bufferViews"][im["bufferView"]]
        data = blob[v.get("byteOffset", 0):v.get("byteOffset", 0) + v["byteLength"]]
        out[im.get("name", f"#{k}")] = png_pixels(data) or data
    return out


def chain(parent, i):
    while i in parent:
        i = parent[i]
        yield i


def far(a, b):
    return max((abs(x - y) for x, y in zip(a, b)), default=0.0)


def compare(new_path, game_path, tol):
    a, b = model(new_path), model(game_path)
    diffs = []
    for name in sorted(set(b) - set(a)):
        diffs.append(f"missing node {name}")
    for name in sorted(set(a) - set(b)):
        diffs.append(f"extra node {name}")
    for name in sorted(set(a) & set(b)):
        x, y = a[name], b[name]
        if x["parent"] != y["parent"]:
            diffs.append(f"{name}: parent {x['parent']} != {y['parent']}")
        for k in ("t", "s"):
            if far(x[k], y[k]) > tol:
                diffs.append(f"{name}: {k} {x[k]} != {y[k]}")
        # q and -q are the same turn
        if min(far(x["r"], y["r"]), far(x["r"], [-v for v in y["r"]])) > tol:
            diffs.append(f"{name}: rotation {x['r']} != {y['r']}")
        if x["skin"] != y["skin"]:
            diffs.append(f"{name}: skin joints {x['skin']} != {y['skin']}")
        if (x["mesh"] is None) != (y["mesh"] is None):
            diffs.append(f"{name}: mesh on one side only")
            continue
        if x["mesh"] is None:
            continue
        if len(x["mesh"]) != len(y["mesh"]):
            diffs.append(f"{name}: {len(x['mesh'])} primitives != {len(y['mesh'])}")
            continue
        for k, (p, q) in enumerate(zip(x["mesh"], y["mesh"])):
            tag = f"{name}[{k}]"
            if p["material"] != q["material"]:
                diffs.append(f"{tag}: material {p['material']} != {q['material']}")
            if p["tris"] != q["tris"]:
                diffs.append(f"{tag}: {p['tris']} triangles != {q['tris']}")
            if len(p["pos"]) != len(q["pos"]):
                diffs.append(f"{tag}: {len(p['pos'])} vertices != {len(q['pos'])}")
                continue
            d = max((far(u, v) for u, v in zip(p["pos"], q["pos"])), default=0.0)
            if d > tol:
                d2 = max((far(u, v) for u, v in zip(sorted(p["pos"]), sorted(q["pos"]))), default=0.0)
                if d2 > tol:
                    diffs.append(f"{tag}: vertices differ by up to {min(d, d2):.6f} m")
    ia, ib = images(new_path), images(game_path)
    for name in sorted(set(ia) ^ set(ib)):
        diffs.append(f"image {name} on one side only")
    for name in sorted(set(ia) & set(ib)):
        p, q = ia[name], ib[name]
        if isinstance(p, tuple) and isinstance(q, tuple):
            if p[:3] != q[:3]:
                diffs.append(f"image {name}: {p[0]}x{p[1]}x{p[2]} != {q[0]}x{q[1]}x{q[2]}")
            elif p[3] != q[3]:
                worst = max(abs(x - y) for x, y in zip(p[3], q[3]))
                if worst > 1:
                    diffs.append(f"image {name}: pixels differ by up to {worst}/255")
        elif p != q:
            diffs.append(f"image {name}: bytes differ")
    return diffs


def main():
    args = [x for x in sys.argv[1:] if not x.startswith("--")]
    tol = float(sys.argv[sys.argv.index("--tol") + 1]) if "--tol" in sys.argv else 1e-4
    if "--tol" in sys.argv:
        args.remove(sys.argv[sys.argv.index("--tol") + 1])
    quiet = "--quiet" in sys.argv
    if len(args) != 2:
        print(__doc__)
        sys.exit(2)
    new, game = args
    if os.path.isdir(game):
        pairs = [(os.path.join(new, f), os.path.join(game, f)) for f in sorted(os.listdir(game)) if f.endswith(".glb")]
    else:
        pairs = [(new, game)]
    bad = 0
    for n, g in pairs:
        if not os.path.exists(n):
            print(f"MESH-DIFF {g}: no re-export at {n}")
            bad += 1
            continue
        diffs = compare(n, g, tol)
        if diffs:
            bad += 1
            for d in diffs[:12] if quiet else diffs:
                print("  - " + d)
            if quiet and len(diffs) > 12:
                print(f"  - ... {len(diffs) - 12} more")
            print(f"MESH-DIFF {g}: {len(diffs)} differences")
        else:
            print(f"MESH-SAME {g}")
    if len(pairs) > 1:
        print(f"{'PASS' if not bad else 'FAIL'} glb_compare: {len(pairs) - bad}/{len(pairs)} the same within {tol} m")
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
