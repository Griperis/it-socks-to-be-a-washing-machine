"""Small reads of assets/blender_assets.json for export.sh (plain Python):

    manifest.py family  <manifest> <family>       every asset whose source is <family>/...
    manifest.py sources <manifest> <asset>...     one line per source: <source> TAB <its assets>
"""
import json
import sys

mode, path = sys.argv[1], sys.argv[2]
assets = json.load(open(path, encoding="utf-8"))["assets"]
if mode == "family":
    for k, v in assets.items():
        if v.get("source", "").startswith(sys.argv[3] + "/"):
            print(k)
elif mode == "sources":
    by = {}
    for a in sys.argv[3:]:
        by.setdefault(assets.get(a, {}).get("source", a), []).append(a)
    for s, group in by.items():
        print(s + "\t" + " ".join(group))
