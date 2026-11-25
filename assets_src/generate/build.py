"""Build a family's models from its scripts, then export them (assets_src/generate/README.md).

    blender -b -P assets_src/generate/build.py -- <family> [--only a,b] [--out <dir>] [--save] [--no-export]

  <family>     sock | cabinet | furniture | avatar | appliance
  --only       only these: Sock shapes (ankle, crew ...) and balls (ball_crew_plain ...), Collections
               (food, space ...) or furniture pieces (sofa, piano ...)
  --out        write the glbs under <dir> (same relative paths as in the game) instead of over the
               game's own files; compare with glb_compare.py before you copy one in
  --save       also save the built scene as the family's .blend source(s) in assets_src/blender/<family>/
  --no-export  build (and --save) only

Without Blender installed, run it as `<python with bpy 5.3> assets_src/generate/bpy_run.py
assets_src/generate/build.py -- <family> ...` (see bpy_run.py).

The scripts build meshes only (Q2152): materials, UVs, rigs, LODs, the Cabinet's slot points; never
collision, placement, Sock spots or settings, which live in the Godot scenes.
Prints one line per model: `EXPORT-OK <asset> -> <path>` (or `BUILT` with --no-export), and a last
line `PASS build <family>: <n> models` or `FAIL build ...`.
"""
import importlib
import json
import os
import sys

import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, "..", ".."))
SRC = os.path.join(REPO, "assets_src", "blender")


def args():
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out = {"family": a[0] if a else "", "only": None, "out": REPO, "save": False, "export": True}
    i = 1
    while i < len(a):
        k = a[i]
        if k == "--only":
            out["only"] = a[i + 1].split(",")
            i += 1
        elif k == "--out":
            out["out"] = os.path.abspath(a[i + 1])
            i += 1
        elif k == "--save":
            out["save"] = True
        elif k == "--no-export":
            out["export"] = False
        else:
            raise SystemExit(f"FAIL build: unknown argument {k}")
        i += 1
    return out


def empty_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    us = bpy.context.scene.unit_settings
    us.system, us.scale_length, us.length_unit = "METRIC", 1.0, "METERS"


def export_root(asset, rel, out_root):
    """The root object <asset> and everything under it, as export.py writes it."""
    root = bpy.data.objects[asset]
    if bpy.context.object and bpy.context.object.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    for o in [root] + list(root.children_recursive):
        o.hide_viewport = False
        o.hide_set(False)
        o.select_set(True)
    out = os.path.join(out_root, rel)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=out, export_format="GLB", use_selection=True, export_apply=True,
        export_yup=True, export_cameras=False, export_lights=False, export_animations=False,
        export_extras=False)
    return f"EXPORT-OK {asset} -> {out}"


def finish(assets, a, manifest, lines):
    for asset in assets:
        if a["export"]:
            lines.append(export_root(asset, manifest[asset]["glb"], a["out"]))
        else:
            lines.append(f"BUILT {asset}")
        print(lines[-1])


def sock(a, manifest, lines):
    sys.path.insert(0, os.path.join(HERE, "sock"))
    import make_socks
    import make_sock_balls
    shapes = [n for n in make_socks.VARIANTS if not a["only"] or n in a["only"]]
    balls = [n for n in make_sock_balls.STYLES if not a["only"] or "ball_" + n in a["only"]]
    for module, names, prefix, source in ((make_socks, shapes, "sock_", "socks"),
                                          (make_sock_balls, balls, "ball_", "sock_balls")):
        if not names:
            continue
        empty_scene()
        for n in names:
            print(module.build(n))
        if a["save"]:
            if a["only"]:
                raise SystemExit("FAIL build: --save rebuilds a whole source file; leave out --only")
            bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SRC, "sock", source + ".blend"), compress=True)
        finish([prefix + n for n in names], a, manifest, lines)


def cabinet(a, manifest, lines):
    sys.path.insert(0, os.path.join(HERE, "cabinet"))
    import make_cabinets as mc
    for name in mc.THEMES:
        if a["only"] and name not in a["only"]:
            continue
        empty_scene()
        print(mc.build(name))
        if a["save"]:
            bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SRC, "cabinet", f"cabinet_{name}.blend"),
                                        compress=True)
        finish(["cabinet_" + name], a, manifest, lines)


def furniture(a, manifest, lines):
    sys.path.insert(0, os.path.join(HERE, "furniture"))
    import fkit
    for mod in fkit.GROUPS:
        importlib.import_module(mod)
    for pid in sorted(fkit.REG):
        if a["only"] and pid not in a["only"]:
            continue
        fkit.kit.reset()   # its material cache too
        empty_scene()
        P =fkit.Piece(pid)
        fkit.REG[pid]["fn"](P)
        P.finish()
        P.clean_names()
        print(f"{pid}: {sum(P.tris().values())} triangles")
        if a["save"]:
            os.makedirs(os.path.join(SRC, "furniture"), exist_ok=True)
            P.strip_helpers()
            bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SRC, "furniture", pid + ".blend"), compress=True)
        finish([pid], a, {pid: {"glb": f"assets/furniture/{pid}.glb"}}, lines)


def avatar(a, manifest, lines):
    """The player avatar: avatar.glb and feet.glb from one scene, with the old script's own export
    (no root object, glTF extras and the Crouch shape key kept; coop/04), not export_root()."""
    sys.path.insert(0, os.path.join(HERE, "avatar"))
    import make_avatar
    empty_scene()
    nodes = make_avatar.build()
    print("avatar:", {n: make_avatar.tris(o) for n, o in nodes.items() if o.type == "MESH"}, "triangles")
    if a["save"]:
        os.makedirs(os.path.join(SRC, "avatar"), exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SRC, "avatar", "avatar.blend"), compress=True)
    for name, objs in (("avatar", list(nodes.values())), ("feet", [nodes["FootL"], nodes["FootR"]])):
        if a["only"] and name not in a["only"]:
            continue
        if a["export"]:
            out = os.path.join(a["out"], "assets", "avatar", name + ".glb")
            make_avatar.export(objs, out)
            lines.append(f"EXPORT-OK {name} -> {out}")
        else:
            lines.append(f"BUILT {name}")
        print(lines[-1])


def appliance(a, manifest, lines):
    """The washing machine (assets/14): the face script applied to its .blend (it starts from the old
    model in that file, not from an empty scene), exported by the script's own export() (no root
    object, the eight actions; not export_root())."""
    sys.path.insert(0, os.path.join(HERE, "appliance"))
    import make_washing_machine_face as wf
    if a["only"] and "washing_machine" not in a["only"]:
        return
    bpy.ops.wm.open_mainfile(filepath=os.path.join(SRC, "appliance", "washing_machine.blend"))
    print(wf.build())
    if a["save"]:
        bpy.ops.wm.save_mainfile(compress=True)
    if a["export"]:
        lines.append(wf.export(os.path.join(a["out"], manifest["washing_machine"]["glb"])))
    else:
        lines.append("BUILT washing_machine")
    print(lines[-1])


def main():
    a = args()
    fn = {"sock": sock, "cabinet": cabinet, "furniture": furniture, "avatar": avatar, "appliance": appliance}.get(a["family"])
    if fn is None:
        raise SystemExit("FAIL build: name a family: sock | cabinet | furniture | avatar | appliance")
    manifest = json.load(open(os.path.join(REPO, "assets", "blender_assets.json"), encoding="utf-8"))["assets"]
    lines = []
    fn(a, manifest, lines)
    if not lines:
        raise SystemExit(f"FAIL build {a['family']}: nothing matched --only {a['only']}")
    print(f"PASS build {a['family']}: {len(lines)} models")


try:
    main()
except SystemExit as e:
    if e.code not in (None, 0):
        print(e.code if isinstance(e.code, str) else f"FAIL build: exit {e.code}")
    raise
except Exception as e:  # a crash is a failure too, never a silent pass
    import traceback
    traceback.print_exc()
    print(f"FAIL build: crashed: {e}")
    sys.exit(1)
