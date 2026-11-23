## Adds the piano's 88 playable keys (assets/07) to game/furniture/piano.tscn from the old manifest. Run once
## (it refuses a piano that has its Keys): python3 tools/piano_keys_from_old.py <repo> <repo>/reference/it-socks
import json, re, sys
root, ref = sys.argv[1], sys.argv[2]
LIFT = 0.02  # the key's aim box stands this much over the key, above the old keyboard hull
scene = root + "/game/furniture/piano.tscn"
s = open(scene).read()
assert "Keys" not in re.findall(r'\[node name="(\w+)"', s)
man = json.load(open(ref + "/assets/house/furniture/manifest.json"))["pieces"]["piano"]
keys = sorted(((int(n), part) for part, n in man["keys"].items()))
key_uid = open(root + "/game/devices/piano_key.gd.uid").read().strip()
outline_uid = open(root + "/game/outline/outline.gd.uid").read().strip()
tuning_uid = re.search(r'uid="([^"]+)"', open(root + "/game/devices/piano_tuning.tres").read()).group(1)
ext = ('[ext_resource type="Script" uid="%s" path="res://game/devices/piano_key.gd" id="20_key"]\n'
	'[ext_resource type="Script" uid="%s" path="res://game/outline/outline.gd" id="22_outline"]\n'
	'[ext_resource type="Resource" uid="%s" path="res://game/devices/piano_tuning.tres" id="21_tuning"]\n') % (key_uid, outline_uid, tuning_uid)
subs = []
nodes = ['[node name="Keys" type="Node3D" parent="."]\n']


def v3(v):
	return "Vector3(%s)" % ", ".join("%.6g" % x for x in v)


for note, part in keys:
	rec = man["parts"][part]
	assert rec["kind"] == "hinge"
	pivot = rec["pivot"]
	name = "Key_%d" % note
	nodes.append('[node name="%s" type="Node3D" parent="Keys"]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s)\n'
		% (name, ", ".join("%.6g" % x for x in pivot)))
	props = ['script = ExtResource("20_key")', 'tuning = ExtResource("21_tuning")', "note = %d" % note]
	if float(rec["open_deg"]) != 3.0:
		props.append("dip_deg = %s" % rec["open_deg"])
	if rec["axis"] != [1, 0, 0]:
		props.append("axis = %s" % v3(rec["axis"]))
	nodes.append('[node name="Key" type="Node" parent="Keys/%s"]\n%s\n' % (name, "\n".join(props)))
	nodes.append('[node name="Body" type="StaticBody3D" parent="Keys/%s"]\ncollision_mask = 0\n' % name)
	nodes.append('[node name="Outline" type="Node3D" parent="Keys/%s"]\nvisible = false\nscript = ExtResource("22_outline")\n'
		'meshes = Array[NodePath]([NodePath("../../../Looks/%s")])\n' % (name, name))
	for i, b in enumerate(rec["boxes"]):
		lo = list(b["min"])
		hi = list(b["max"])
		hi[1] += LIFT
		sid = "BoxShape3D_key%d_%d" % (note, i + 1)
		subs.append('[sub_resource type="BoxShape3D" id="%s"]\nsize = %s\n' % (sid, v3([hi[k] - lo[k] for k in range(3)])))
		nodes.append('[node name="Shape%d" type="CollisionShape3D" parent="Keys/%s/Body"]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s)\nshape = SubResource("%s")\n'
			% (i + 1, name, ", ".join("%.6g" % ((lo[k] + hi[k]) / 2.0) for k in range(3)), sid))

# ext after the last ext_resource; subs before the first node; nodes after Lid's subtree (at the end, before Spots is fine: append at end).
last_ext = list(re.finditer(r'\[ext_resource[^\n]*\]\n', s))[-1]
s = s[:last_ext.end()] + ext + s[last_ext.end():]
first_node = s.index("[node ")
s = s[:first_node] + "\n".join(subs) + "\n" + s[first_node:]
s = s.rstrip("\n") + "\n\n" + "\n".join(nodes)
open(scene, "w").write(s)
print("keys", len(keys))
