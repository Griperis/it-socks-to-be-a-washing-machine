#!/usr/bin/env python3
"""The shared material library's first fill (assets/04 F01): one StandardMaterial3D .tres per material
of the old game's furniture, read from the old glbs' glTF materials.

    python3 tools/materials_from_old.py            write what is missing, print the groups
    python3 tools/materials_from_old.py --check    print only, write nothing
    --old <dir>   the old furniture folder when this checkout's reference/ is empty (a worktree)

A name the old furniture used with one set of values becomes game/materials/<name>.tres. A name used
with several (oak: 6 sets in 35 pieces) becomes candidates, game/materials/candidates/<name>/<name>_<k>.tres,
k = 1 the set most pieces used, for the designer to pick the one that stays (Q2177). Where the house
kit (game/house/kit/materials/) holds a material of the same name with other values, its values are one
more candidate, <name>_kit.tres (the kit's file stays as it is). Once a group is picked (Q2389) its
game/materials/<name>.tres stands and no candidates are written again. Every file carries the old pieces that
used it as metadata `old_pieces`.

Values are what Godot's glTF importer made of them in the old game: base colour and emission from linear
to sRGB, roughness, metallic, BLEND as alpha transparency, glTF doubleSided as culling off, emission
strength as emission energy. KHR_materials_sheen (the fab_* cloths) has no StandardMaterial3D field and
the old import dropped it too. Run once: after that the .tres are the truth, edited in the inspector; an
existing file is never overwritten.
"""
import hashlib
import json
import os
import struct
import sys
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OLD = os.path.join(ROOT, "reference", "it-socks", "assets", "house", "furniture")
OUT = os.path.join(ROOT, "game", "materials")
KIT = os.path.join(ROOT, "game", "house", "kit", "materials")


def srgb(c: float) -> float:
    """Godot's Color.linear_to_srgb for one channel."""
    return c * 12.92 if c < 0.0031308 else 1.055 * c ** (1.0 / 2.4) - 0.055


def uid(path: str) -> str:
    """A Godot uid text (base 34: a-y, 0-8) made from the file's res:// path, so a rerun gives the same."""
    n = int.from_bytes(hashlib.sha256(path.encode()).digest()[:8], "big") & ((1 << 63) - 1)
    out = ""
    while True:
        c = n % 34
        out = (chr(ord("a") + c) if c < 25 else chr(ord("0") + c - 25)) + out
        n //= 34
        if n == 0:
            return "uid://" + out


def num(x: float) -> str:
    s = ("%.4f" % x).rstrip("0").rstrip(".")
    return s if s not in ("", "-0") else "0"


def colour(c) -> str:
    return "Color(%s)" % ", ".join(num(v) for v in c)


def read_glb(path: str) -> dict:
    with open(path, "rb") as f:
        data = f.read()
    n = struct.unpack("<I", data[12:16])[0]
    return json.loads(data[20:20 + n])


def godot_fields(m: dict) -> list:
    """The material's StandardMaterial3D fields in the editor's order, as (name, text)."""
    p = m.get("pbrMetallicRoughness", {})
    base = p.get("baseColorFactor", [1, 1, 1, 1])
    out = []
    if m.get("alphaMode") == "BLEND":
        out.append(("transparency", "1"))
    if m.get("doubleSided"):
        out.append(("cull_mode", "2"))
    out.append(("albedo_color", colour([srgb(base[0]), srgb(base[1]), srgb(base[2]), base[3]])))
    metal = p.get("metallicFactor", 1.0)
    if metal != 0.0:
        out.append(("metallic", num(metal)))
    out.append(("roughness", num(p.get("roughnessFactor", 1.0))))
    em = m.get("emissiveFactor", [0, 0, 0])
    if any(em):
        out.append(("emission_enabled", "true"))
        out.append(("emission", colour([srgb(em[0]), srgb(em[1]), srgb(em[2]), 1])))
        strength = m.get("extensions", {}).get("KHR_materials_emissive_strength", {}).get("emissiveStrength", 1.0)
        if strength != 1.0:
            out.append(("emission_energy_multiplier", num(strength)))
    return out


def kit_fields(name: str):
    """The house kit's material `name` as its raw [resource] lines, or None."""
    path = os.path.join(KIT, name + ".tres")
    if not os.path.exists(path):
        return None
    lines = open(path).read().split("[resource]", 1)[1].strip().splitlines()
    if any("ExtResource" in line for line in lines):
        return None   # a textured kit material: not a colour to compare
    return [tuple(line.split(" = ", 1)) for line in lines if not line.startswith("resource_name")]


def tres(rel: str, name: str, fields: list, pieces: list) -> str:
    body = ['resource_name = "%s"' % name] + ["%s = %s" % f for f in fields]
    body.append("metadata/old_pieces = PackedStringArray(%s)" % ", ".join('"%s"' % p for p in sorted(pieces)))
    return '[gd_resource type="StandardMaterial3D" format=3 uid="%s"]\n\n[resource]\n%s\n' % (
        uid("res://" + rel), "\n".join(body))


def main() -> int:
    check = "--check" in sys.argv
    old = sys.argv[sys.argv.index("--old") + 1] if "--old" in sys.argv else OLD
    if not os.path.isdir(old):
        print("materials_from_old: no %s (the reference submodule; --old <dir>)" % old)
        return 1
    groups = defaultdict(dict)   # name -> {signature: [fields, [pieces]]}
    for f in sorted(os.listdir(old)):
        if not f.endswith(".glb"):
            continue
        for m in read_glb(os.path.join(old, f)).get("materials", []):
            fields = godot_fields(m)
            sig = tuple(fields)
            entry = groups[m["name"]].setdefault(sig, [fields, []])
            if f[:-4] not in entry[1]:
                entry[1].append(f[:-4])
    files = {}
    for name in sorted(groups):
        sets = sorted(groups[name].values(), key=lambda e: (-len(e[1]), e[0]))
        kit = kit_fields(name)
        if kit is not None and all(tuple(kit) != tuple(e[0]) for e in sets):
            sets.append([kit, ["house kit"]])
        if len(sets) == 1 or os.path.exists(os.path.join(OUT, name + ".tres")):
            # one set, or a group already picked (Q2389): the library file stays as it is
            files["game/materials/%s.tres" % name] = (name, sets[0])
        else:
            for k, e in enumerate(sets, 1):
                tag = "kit" if e[1] == ["house kit"] else str(k)
                files["game/materials/candidates/%s/%s_%s.tres" % (name, name, tag)] = (name, e)
        print("%-16s %d set(s): %s" % (name, len(sets), ", ".join(str(len(e[1])) for e in sets)))
    wrote = 0
    for rel, (name, (fields, pieces)) in files.items():
        path = os.path.join(ROOT, rel)
        if check or os.path.exists(path):
            continue
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", newline="\n") as f:
            f.write(tres(rel, name, fields, pieces))
        wrote += 1
    print("materials_from_old: %d names, %d files, %d written" % (len(groups), len(files), wrote))
    return 0


if __name__ == "__main__":
    sys.exit(main())
