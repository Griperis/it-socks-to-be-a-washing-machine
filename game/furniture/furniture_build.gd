## Makes the furniture scenes (assets/04 F02, F04) from the data tools/furniture_from_old.py wrote, step
## two of two. Run it from the project folder after that script and an import:
##   "$(kit/tools/engine.sh --path)" --headless --path . --script res://game/furniture/furniture_build.gd -- [--force] [--pieces a,b]
## A scene that exists is left as it is (the scenes are edited by hand once made, Q2151); --force remakes it.
##
## Per piece:
## - looks/looks_<piece>.tscn: its still meshes (Body, and Board, MirrorGlass, the piano's Key_<midi>)
##   where the old model hung them. Contract: looks_contract.json.
## - parts/looks_<piece>_<opening>.tscn: one per opening (an old container, the parts that open it):
##   each moving part an AnimatableBody3D named as in the old model, at its pivot, with its mesh and
##   collision; an Outline; an AnimationPlayer on physics frames with "open" and "shut" (the old swing:
##   0.35 s, easing out both ways). Contract: parts/looks_contract.json.
## - <piece>.tscn: a StaticBody3D on the house layer with the old collision (a box where the old hull
##   was a box), the Looks, each opening as a Node3D holding an Openable (metadata `kind`: its old
##   container kind, what it sounds like), its Looks and its Inside (the interior where Socks hide, an
##   Area3D on no layer; `shelves_y`), the Sock spots as Spots/Top<n> (an Area3D box on no layer: the
##   rect a Sock may rest on, from its floor to the headroom over it), and the old Lamp where it had one.
##   The rest of the old manifest entry rides as metadata (footprint, height, crawl, hide, rooms, note).
extends SceneTree

const DATA := "res://.godot/furniture_from_old.json"
const FOLDER := "res://game/furniture"
const LOOKS := "res://game/furniture/looks"
const PARTS := "res://game/furniture/parts"
const OPENABLE := preload("res://game/parts/openable.gd")
const OUTLINE := preload("res://game/outline/outline.gd")
## The house's physics layer, the Mess's LAYER_HOUSE (game/mess/mess.gd).
const LAYER_HOUSE := 1
## The old furniture's swing (game/house/openable.gd SWING_TIME of the reference) and its sine ease
## out, as an AnimationPlayer key's easing (Math.ease with this curve is within 3 % of a sine).
const SWING_TIME := 0.35
const EASE_OUT := 0.56
## Metadata copied from the old manifest entry onto the piece's root, as they were.
const META := ["footprint", "height", "crawl_gap", "crawl_box", "hide", "rooms", "plan_spot", "note"]

var _force := false
var _only: PackedStringArray = []


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	_force = args.has("--force")
	var at := args.find("--pieces")
	if at >= 0 and at + 1 < args.size():
		_only = args[at + 1].split(",")
	var text := FileAccess.get_file_as_string(DATA)
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary:
		push_error("furniture_build: no data at %s (run tools/furniture_from_old.py)" % DATA)
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(LOOKS)
	DirAccess.make_dir_recursive_absolute(PARTS)
	var made := 0
	for piece: String in (data as Dictionary).keys():
		if not _only.is_empty() and not _only.has(piece):
			continue
		if FileAccess.file_exists(FOLDER.path_join(piece + ".tscn")) and not _force:
			continue
		_build(piece, data[piece])
		made += 1
	print("furniture_build: %d pieces made" % made)
	quit(0)


## The openings of a piece: its old containers, then every part no container opens (the piano's keys
## are not openings: they stay in the still Looks).
static func openings(d: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var taken: Array[String] = []
	for c: Dictionary in d.get("containers", []):
		out.append(c)
		for p: String in c["parts"]:
			taken.append(p)
	for p: String in (d["parts"] as Dictionary).keys():
		if not taken.has(p) and not p.begins_with("Key_"):
			out.append({"name": p, "parts": [p], "kind": ""})
	return out


func _build(piece: String, d: Dictionary) -> void:
	var pascal := piece.to_pascal_case()
	var root := StaticBody3D.new()
	root.name = pascal
	root.collision_layer = LAYER_HOUSE
	root.collision_mask = 0
	for key: String in META:
		if d.has(key) and d[key] != null:
			root.set_meta(key, d[key])
	var looks := _looks_scene(piece, d)
	_instance(root, looks, "Looks")
	var n := 0
	for s: Dictionary in d["shapes"]:
		if s["owner"] == "":
			n += 1
			_own(root, _shape(s, "Shape%d" % n))
	if n == 0:
		for c: Dictionary in d.get("colliders", []):
			n += 1
			_own(root, _box_shape(c, "Shape%d" % n))
	for o in openings(d):
		_opening(root, piece, d, o)
	if not (d["spots"] as Array).is_empty():
		var spots := Node3D.new()
		spots.name = "Spots"
		_own(root, spots)
		var k := 0
		for r: Dictionary in d["spots"]:
			k += 1
			var top := _area("Top%d" % k, Vector3(r["min"][0], r["y"], r["min"][1]), Vector3(r["max"][0], r["top"], r["max"][1]))
			_own(spots, top)
	if d.has("lamp"):
		var lamp := OmniLight3D.new()
		lamp.name = "Lamp"
		lamp.position = _vec(d["lamp"])
		var c: Array = d["lamp_colour"]
		lamp.light_color = Color(c[0], c[1], c[2])
		lamp.light_energy = d["lamp_energy"]
		lamp.omni_range = d["lamp_range"]
		lamp.shadow_enabled = false
		_own(root, lamp)
	_save(root, FOLDER.path_join(piece + ".tscn"))


## The piece's still Looks: every mesh no opening moves.
func _looks_scene(piece: String, d: Dictionary) -> String:
	var root := Node3D.new()
	root.name = "Looks" + piece.to_pascal_case()
	var keys: Dictionary = d.get("keys", {})
	for m: Dictionary in d["meshes"]:
		var part: String = m["part"]
		if part != "" and not part.begins_with("Key_"):
			continue
		var mi := _mesh(m, m["node"])
		if keys.has(m["node"]):
			mi.set_meta("midi", keys[m["node"]])
		_own(root, mi)
	var path := LOOKS.path_join("looks_%s.tscn" % piece)
	_save(root, path)
	return path


func _opening(root: StaticBody3D, piece: String, d: Dictionary, o: Dictionary) -> void:
	var holder := Node3D.new()
	holder.name = o["name"]
	_own(root, holder)
	var part := Node.new()
	part.name = "Openable"
	part.set_script(OPENABLE)
	if o["kind"] != "":
		part.set_meta("kind", o["kind"])
	_own(holder, part)
	_instance(holder, _part_looks(piece, d, o), "Looks")
	if o.has("interior"):
		var inside := _area("Inside", _vec(o["interior"]["min"]), _vec(o["interior"]["max"]))
		inside.set_meta("shelves_y", o.get("shelves_y", []))
		_own(holder, inside)


func _part_looks(piece: String, d: Dictionary, o: Dictionary) -> String:
	var root := Node3D.new()
	root.name = "Looks%s%s" % [piece.to_pascal_case(), String(o["name"]).to_pascal_case()]
	var reset := Animation.new()
	reset.length = 0.001
	var open := Animation.new()
	open.length = SWING_TIME
	var shut := Animation.new()
	shut.length = SWING_TIME
	for p: String in o["parts"]:
		var info: Dictionary = d["parts"][p]
		var body := AnimatableBody3D.new()
		body.name = p
		body.collision_layer = LAYER_HOUSE
		body.collision_mask = 0
		var pivot := _vec(info["pivot"])
		body.position = pivot
		_own(root, body)
		for m: Dictionary in d["meshes"]:
			if m["part"] == p:
				var mi := _mesh(m, "Mesh")
				mi.position = Vector3.ZERO
				_own(body, mi)
		var n := 0
		for s: Dictionary in d["shapes"]:
			if s["owner"] == p:
				n += 1
				_own(body, _shape(s, "Shape%d" % n))
		if n == 0:
			for b: Dictionary in info.get("boxes", []):
				n += 1
				_own(body, _box_shape(b, "Shape%d" % n))
		var axis := _vec(info["axis"])
		var prop := "rotation"
		var shut_at: Variant = Vector3.ZERO
		var open_at: Variant = axis * deg_to_rad(float(info.get("open_deg", 0.0)))
		if info["kind"] == "slide":
			prop = "position"
			shut_at = pivot
			open_at = pivot + axis * float(info.get("open_m", 0.0))
		var track := NodePath("%s:%s" % [p, prop])
		_track(reset, track, [0.0], [shut_at], [1.0])
		_track(open, track, [0.0, SWING_TIME], [shut_at, open_at], [EASE_OUT, 1.0])
		_track(shut, track, [0.0, SWING_TIME], [open_at, shut_at], [EASE_OUT, 1.0])
	var outline := Node3D.new()
	outline.name = "Outline"
	outline.set_script(OUTLINE)
	outline.visible = false
	_own(root, outline)
	var lib := AnimationLibrary.new()
	lib.add_animation(&"RESET", reset)
	lib.add_animation(&"open", open)
	lib.add_animation(&"shut", shut)
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	player.add_animation_library(&"", lib)
	_own(root, player)
	var path := PARTS.path_join("looks_%s_%s.tscn" % [piece, String(o["name"]).to_lower()])
	_save(root, path)
	return path


func _track(anim: Animation, path: NodePath, times: Array, values: Array, easing: Array) -> void:
	var t := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t, path)
	anim.value_track_set_update_mode(t, Animation.UPDATE_CONTINUOUS)
	for i in times.size():
		anim.track_insert_key(t, times[i], values[i], easing[i])


func _mesh(m: Dictionary, node_name: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = load(m["mesh"]) as Mesh
	mi.position = _vec(m["origin"])
	return mi


func _shape(s: Dictionary, node_name: String) -> CollisionShape3D:
	var cs := CollisionShape3D.new()
	cs.name = node_name
	match s["type"]:
		"box":
			var box := BoxShape3D.new()
			box.size = _vec(s["size"])
			cs.shape = box
			var b: Array = s["basis"]
			cs.transform = Transform3D(Basis(_vec(b[0]), _vec(b[1]), _vec(b[2])), _vec(s["origin"]))
		"convex":
			var hull := ConvexPolygonShape3D.new()
			var pts := PackedVector3Array()
			for p: Array in s["points"]:
				pts.append(_vec(p))
			hull.points = pts
			cs.shape = hull
		"trimesh":
			# Met from both sides, as the drawn triangles were (the old HouseParts rule: a tub's or a
			# seat ring's inside).
			var tri := ConcavePolygonShape3D.new()
			var faces := PackedVector3Array()
			for p: Array in s["faces"]:
				faces.append(_vec(p))
			tri.set_faces(faces)
			tri.backface_collision = true
			cs.shape = tri
	return cs


func _box_shape(b: Dictionary, node_name: String) -> CollisionShape3D:
	var lo := _vec(b["min"])
	var hi := _vec(b["max"])
	var cs := CollisionShape3D.new()
	cs.name = node_name
	var box := BoxShape3D.new()
	box.size = hi - lo
	cs.shape = box
	cs.position = (lo + hi) / 2.0
	return cs


## A box marker on no physics layer from `lo` to `hi`.
func _area(node_name: String, lo: Vector3, hi: Vector3) -> Area3D:
	var area := Area3D.new()
	area.name = node_name
	area.collision_layer = 0
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = false
	area.position = (lo + hi) / 2.0
	var cs := CollisionShape3D.new()
	cs.name = "Box"
	var box := BoxShape3D.new()
	box.size = hi - lo
	cs.shape = box
	area.add_child(cs)
	return area


func _vec(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))


func _instance(parent: Node, path: String, node_name: String) -> void:
	var inst := (ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE) as PackedScene).instantiate()
	inst.name = node_name
	parent.add_child(inst)
	inst.owner = parent if parent.owner == null else parent.owner


## Adds `node` (and what it holds, unless that is an instance) to `parent`, owned by the scene's root.
func _own(parent: Node, node: Node) -> void:
	parent.add_child(node)
	var top := parent if parent.owner == null else parent.owner
	node.owner = top
	for child in node.get_children():
		_own_tree(child, top)


func _own_tree(node: Node, top: Node) -> void:
	node.owner = top
	if node.scene_file_path.is_empty():
		for child in node.get_children():
			_own_tree(child, top)


func _save(root: Node, path: String) -> void:
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, path)
	if err != OK:
		push_error("furniture_build: could not save %s (%d)" % [path, err])
	root.free()
