"""Export assets from the open .blend to their .glb, the way the old game exported them. Run in Blender
by assets_src/generate/export.sh, not by hand:

    blender -b assets_src/blender/<family>/<source>.blend -P assets_src/generate/export.py -- <asset>... [--out <dir>] [--check]

For each asset (a key of assets/blender_assets.json): the root object named <asset> and everything
under it is exported (glTF, +Y up, modifiers applied, armatures as skins, no cameras, lights or
animation) to the manifest's `glb`, under `--out` (default: this repository, so the game's own file is
overwritten; use `--out` to a scratch folder and assets_src/generate/glb_compare.py to see the
difference first). Before it, the kit's contract checks (kit/tools/blender/asset_checks.py) report on
the asset; they are shown, not enforced: the old models predate them (see README.md).

Prints one line per asset: `EXPORT-OK <asset> -> <path>` or `EXPORT-FAIL <asset>: <why>`.
"""
import json
import os
import sys

import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, "..", ".."))
MANIFEST = os.path.join(REPO, "assets", "blender_assets.json")


def kit_report(asset):
    """The kit's checks, pointed at this game's manifest (the kit's own path is the kit's folder)."""
    try:
        sys.path.insert(0, os.path.join(REPO, "kit", "tools", "blender"))
        import asset_checks
        asset_checks.REPO = REPO
        asset_checks.MANIFEST = MANIFEST
        return asset_checks.report(asset)
    except Exception as e:  # the report is advice; the export does not depend on it
        return f"{asset}: kit checks not run ({type(e).__name__}: {e})"


def export(asset, entry, out_root):
    root = bpy.data.objects.get(asset)
    if root is None:
        return f"EXPORT-FAIL {asset}: no root object named {asset} in {bpy.data.filepath}"
    if bpy.context.object and bpy.context.object.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    for o in [root] + list(root.children_recursive):
        o.hide_viewport = False
        o.hide_set(False)
        o.select_set(True)
    rel = entry.get("glb", f"assets/{asset}/{asset}.glb")
    out = os.path.join(out_root, rel)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=out, export_format="GLB", use_selection=True, export_apply=True,
        export_yup=True, export_cameras=False, export_lights=False, export_animations=False,
        export_extras=False)
    return f"EXPORT-OK {asset} -> {out}"


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    out_root = REPO
    if "--out" in argv:
        i = argv.index("--out")
        out_root = os.path.abspath(argv[i + 1])
        del argv[i:i + 2]
    check = "--check" in argv
    assets = [a for a in argv if not a.startswith("--")]
    manifest = json.load(open(MANIFEST, encoding="utf-8"))["assets"]
    fail = False
    for asset in assets:
        if asset not in manifest:
            print(f"EXPORT-FAIL {asset}: not in assets/blender_assets.json")
            fail = True
            continue
        print(kit_report(asset))
        if check:
            print(f"EXPORT-CHECKED {asset}")
            continue
        line = export(asset, manifest[asset], out_root)
        fail |= line.startswith("EXPORT-FAIL")
        print(line)
    if fail:
        sys.exit(1)


try:
    main()
except SystemExit:
    raise
except Exception as e:  # a crash is a failure too, never a silent pass
    import traceback
    traceback.print_exc()
    print(f"EXPORT-FAIL crashed: {e}")
    sys.exit(1)
