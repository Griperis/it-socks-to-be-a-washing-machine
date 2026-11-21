"""Run a Blender script with pip's `bpy` module instead of the Blender binary (same results for meshes
and glb export; no renders). Used when the pinned Blender is not installed:

    <python with bpy 5.3> assets_src/generate/bpy_run.py [<file.blend>] <script.py> -- <args>

does what `blender -b [<file.blend>] -P <script.py> -- <args>` does. bpy 5.3 needs Python 3.13:
`uv venv --python 3.13 <dir> && uv pip install --python <dir>/bin/python "bpy==5.3.*"`.
"""
import runpy
import sys

import bpy

argv = sys.argv[1:]
cut = argv.index("--") if "--" in argv else len(argv)
head, tail = argv[:cut], argv[cut:]
if head and head[0].endswith(".blend"):
    bpy.ops.wm.open_mainfile(filepath=head.pop(0))
script = head[0]
sys.argv = ["blender", "-P", script] + tail
runpy.run_path(script, run_name="__main__")
