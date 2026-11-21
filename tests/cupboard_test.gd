## The example entity: a cupboard is its behaviour (an Openable part and its collision) plus a
## swappable Looks scene whose AnimationPlayer shows the state. Every behaviour case runs once with
## each Looks in the folder, so a new Looks (the real model) passes the same cases or fails loudly.
## The cases go through Parts as a Host of one, the path co-op uses too.
extends TestSuite

const FOLDER := "res://game/entities/cupboard/"
const CUPBOARD := FOLDER + "cupboard.tscn"
const OPENABLE := &"Cupboard/Openable"

var _level: Node3D = null


func cases() -> Array[Dictionary]:
	return [
		{"name": "contract", "method": "case_contract", "world": false,
				"title": "every Looks loads, has what looks_contract.json names, and its open animation turns the pivot"},
		{"name": "swap", "method": "case_swap", "world": false,
				"title": "with each Looks: use opens it, use again shuts it, and the pose follows the state"},
		{"name": "reverse", "method": "case_reverse", "world": false,
				"title": "shut while it is still opening: it turns back from where it is, with no jump"},
		{"name": "now", "method": "case_now", "world": false,
				"title": "a state that arrives whole (a late Guest, a load) shows the open pose at once, with no swing"},
		{"name": "save", "method": "case_save", "world": false,
				"title": "a snapshot taken open, written as text and loaded into a fresh level gives the open pose"},
		{"name": "locked", "method": "case_locked", "world": false,
				"title": "a locked cupboard refuses to open and its door stays shut"},
		{"name": "r2_same_open", "method": "case_r2", "world": false,
				"title": "R2: a patch that leaves `open` as it is (a lock) on a resting cupboard replays no swing"},
		{"name": "push", "method": "case_push", "world": false,
				"title": "the opening door pushes a box that stands in its way"},
	]


func _before_case() -> void:
	if _level != null:
		_level.free()
		_level = null


## Every looks*.tscn in the folder, by path.
static func looks_paths() -> PackedStringArray:
	var out := PackedStringArray()
	for f in DirAccess.get_files_at(FOLDER):
		if f.begins_with("looks") and f.ends_with(".tscn"):
			out.append(FOLDER + f)
	return out


func case_contract() -> void:
	var contract: Variant = JSON.parse_string(FileAccess.get_file_as_string(FOLDER + "looks_contract.json"))
	_check(contract is Dictionary, "looks_contract.json reads")
	var paths := looks_paths()
	_check(paths.size() >= 2, "the folder has at least two Looks to swap between")
	for path in paths:
		var scene := load(path) as PackedScene
		_check(scene != null, "%s loads" % path.get_file())
		if scene == null:
			continue
		var looks := scene.instantiate() as Node3D
		add_child(looks)
		for n: String in contract.get("nodes", []):
			_check(looks.get_node_or_null(n) != null, "%s has %s" % [path.get_file(), n])
		var player := _player(looks)
		_check(player != null and player.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS,
				"%s has an AnimationPlayer that runs on physics frames" % path.get_file())
		for a: String in contract.get("animations", []):
			_check(player != null and player.has_animation(a), "%s has the animation %s" % [path.get_file(), a])
		if player != null and player.has_animation(&"open"):
			var pivot := looks.get_node("DoorPivot") as Node3D
			var before := pivot.basis
			player.play(&"open")
			player.advance(player.get_animation(&"open").length)
			await _settle()
			_check(pivot.basis.get_rotation_quaternion().angle_to(before.get_rotation_quaternion()) > 1.0,
					"%s: the open animation turns DoorPivot by more than a radian" % path.get_file())
		looks.free()


func case_swap() -> void:
	for path in looks_paths():
		var openable := _build(path)
		var what := path.get_file()
		openable.use(Parts.HOST)
		_check(openable.open, "%s: use opens it" % what)
		await _until(func() -> bool: return not openable.animator().is_playing(), "%s: the swing to end" % what)
		await _settle()
		_check(_shows_open(openable), "%s: the pose is open" % what)
		openable.use(Parts.HOST)
		_check(not openable.open, "%s: use again shuts it" % what)
		await _until(func() -> bool: return not openable.animator().is_playing(), "%s: the swing back to end" % what)
		await _settle()
		_check(_shows_shut(openable), "%s: the pose is shut" % what)
		_level.free()
		_level = null


func case_reverse() -> void:
	var openable := _build(looks_paths()[0])
	var player := openable.animator()
	openable.use(Parts.HOST)
	await _until(func() -> bool: return player.current_animation_position > 0.25 * player.current_animation_length,
			"the door to be part way open")
	# The swing is read on the pivot: a Looks with its own "shut" (core/27 P15) plays that from the
	# pose it has now instead of "open" backwards.
	await _settle()
	var pivot := openable.get_node("../Looks/DoorPivot") as Node3D
	var mid := absf(pivot.rotation.y)
	openable.use(Parts.HOST)
	_check(not openable.open, "the second press shuts it")
	await _settle()
	_near(absf(pivot.rotation.y), mid, 0.2, "it turns back from where it was")
	await _frames(4)
	await _settle()
	_check(absf(pivot.rotation.y) < mid, "and goes on towards shut")
	await _until(func() -> bool: return not player.is_playing(), "the swing back to end")
	await _settle()
	_check(_shows_shut(openable), "it ends shut")


func case_now() -> void:
	var openable := _build(looks_paths()[0])
	openable.parts.load_snapshot({OPENABLE: {"open": true, "locked": false}})
	_check(openable.open, "the state arrived")
	_check(not openable.animator().is_playing(), "it is not swinging")
	await _settle()
	_check(_shows_open(openable), "the open pose shows on the next physics frame")


func case_save() -> void:
	var openable := _build(looks_paths()[0])
	openable.use(Parts.HOST)
	# Through the text a save file holds (JSON of plain values: no object is ever built from it).
	var back := _roundtrip(openable.parts.snapshot())
	_level.free()
	var fresh := _build(looks_paths()[-1])
	await _settle()
	_check(_shows_shut(fresh), "a fresh cupboard starts shut")
	fresh.parts.load_snapshot(back)
	await _settle()
	_check(fresh.open and _shows_open(fresh), "the loaded cupboard stands open")


func case_locked() -> void:
	var openable := _build(looks_paths()[0])
	openable.parts.load_snapshot({OPENABLE: {"locked": true}})
	var heard: Array[String] = []
	openable.parts.applied.connect(func(ev: Dictionary) -> void: heard.append(String(ev.get("reason", ""))))
	openable.use(Parts.HOST)
	_check(not openable.open and heard == ["locked"], "it refuses: locked")
	await _frames(5)
	_check(_shows_shut(openable), "its door stays shut")


func case_r2() -> void:
	var openable := _build(looks_paths()[0])
	openable.use(Parts.HOST)
	await _until(func() -> bool: return not openable.is_moving() and openable.open, "the cupboard to rest open")
	openable.parts.apply({"ok": true, "changes": {OPENABLE: {"locked": true}}})
	_check(openable.locked and not openable.is_moving(), "a lock patch on the open cupboard starts no swing")
	openable.parts.apply({"ok": true, "changes": {OPENABLE: {"locked": false, "open": false}}})
	_check(openable.is_moving(), "a patch that shuts it still swings")


func case_push() -> void:
	var openable := _build(looks_paths()[0])
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var plane := BoxShape3D.new()
	plane.size = Vector3(10.0, 0.2, 10.0)
	floor_shape.shape = plane
	floor_shape.position.y = -0.1
	floor_body.add_child(floor_shape)
	_level.add_child(floor_body)
	var box := RigidBody3D.new()
	var box_shape := CollisionShape3D.new()
	var cube := BoxShape3D.new()
	cube.size = Vector3(0.3, 0.3, 0.3)
	box_shape.shape = cube
	box.add_child(box_shape)
	box.position = Vector3(0.3, 0.16, 0.45)
	_level.add_child(box)
	await _frames(20)
	var start := box.global_position
	openable.use(Parts.HOST)
	await _until(func() -> bool: return not openable.animator().is_playing(), "the swing to end")
	await _frames(10)
	_check(box.global_position.distance_to(start) > 0.1,
			"the box was pushed (moved %.2f m)" % box.global_position.distance_to(start))


# --- Helpers -------------------------------------------------------------------------------------

## The door is an AnimatableBody3D synced to physics: a pose set now is on the node after the next
## physics frame.
func _settle() -> void:
	for _i in 2:
		await get_tree().physics_frame

## A level holding one cupboard wearing the Looks at `looks_path`, with its Parts; the cupboard's
## Openable, bound and shown.
func _build(looks_path: String) -> Openable:
	_level = Node3D.new()
	_level.name = "Level"
	var cupboard := (load(CUPBOARD) as PackedScene).instantiate()
	cupboard.name = "Cupboard"
	_swap_looks(cupboard, looks_path)
	_level.add_child(cupboard)
	var parts := Parts.new()
	parts.name = "Parts"
	_level.add_child(parts)
	add_child(_level)
	return parts.of(OPENABLE) as Openable


## What a person does in the editor: delete the Looks child, instance another Looks scene in its
## place and name it Looks.
static func _swap_looks(cupboard: Node, looks_path: String) -> void:
	var old := cupboard.get_node("Looks")
	cupboard.remove_child(old)
	old.free()
	var looks := (load(looks_path) as PackedScene).instantiate()
	looks.name = "Looks"
	cupboard.add_child(looks)


static func _player(looks: Node) -> AnimationPlayer:
	var found := looks.find_children("*", "AnimationPlayer", true, false)
	return found[0] as AnimationPlayer if not found.is_empty() else null


## Whether the pivot stands where the open animation ends (or starts, for shut).
static func _shows_open(openable: Openable) -> bool:
	return _pivot_at(openable, 1.0)


static func _shows_shut(openable: Openable) -> bool:
	return _pivot_at(openable, 0.0)


static func _pivot_at(openable: Openable, end: float) -> bool:
	var player := openable.animator()
	var anim := player.get_animation(Openable.ANIMATION)
	var track := anim.find_track(^"DoorPivot:rotation", Animation.TYPE_VALUE)
	var want: Vector3 = anim.value_track_interpolate(track, end * anim.length)
	var pivot := openable.get_node("../Looks/DoorPivot") as Node3D
	return pivot.rotation.is_equal_approx(want) or pivot.rotation.distance_to(want) < 0.01
