## assets/21's still of the Elevator's Looks with their clips: the stop (looks_stop.tscn) as the ground floor's,
## the car (looks_car.tscn) standing behind it, the four floor letters (letter/looks_letter.tscn) on the car's +Z wall,
## and a stand-in of the house kit's cream shaft wall. Each view poses the Looks by their own clips, seeked to a time.
## `--scene=res://tools/elevator_still.tscn`, then the shot hook `elevator:<view>` (tools/shots/sets/elevator.txt).
extends Node3D

## view -> the camera (from, at) and the clips: [player path under Stop, clip, seconds into it].
const VIEWS: Dictionary = {
	"shut": {"from": Vector3(0.1, 1.3, 1.9), "at": Vector3(0.08, 1.15, 0.0),
		"clips": [["TagPlayer", "out_of_order", 0.0]]},
	"open": {"from": Vector3(-0.45, 1.45, 1.45), "at": Vector3(0.04, 1.05, -0.3),
		"clips": [["AnimationPlayer", "open", 0.5]]},
	"locked": {"from": Vector3(0.75, 1.2, 0.75), "at": Vector3(0.3, 1.02, 0.0),
		"clips": [["LockPlayer", "locked", 0.0]]},
	"unlock_a": {"from": Vector3(0.9, 0.9, 1.3), "at": Vector3(0.25, 0.7, 0.0),
		"clips": [["LockPlayer", "unlock", 0.12]]},
	"unlock_b": {"from": Vector3(0.9, 0.9, 1.3), "at": Vector3(0.25, 0.7, 0.0),
		"clips": [["LockPlayer", "unlock", 0.3]]},
	"unlock_c": {"from": Vector3(0.9, 0.9, 1.3), "at": Vector3(0.25, 0.7, 0.0),
		"clips": [["LockPlayer", "unlock", 0.6]]},
	"repaired": {"from": Vector3(0.1, 1.3, 1.9), "at": Vector3(0.08, 1.0, 0.0),
		"clips": [["TagPlayer", "out_of_order", 0.0], ["TagPlayer", "repaired", 0.25]]},
	"press": {"from": Vector3(0.62, 1.05, 0.3), "at": Vector3(0.42, 1.02, 0.0),
		"clips": [["ButtonPlayer", "press", 0.05]]},
	"letters": {"from": Vector3(-0.15, 1.02, -0.35), "at": Vector3(0.27, 1.08, -0.35),
		"clips": [["AnimationPlayer", "open", 0.5]]},
}
## The letters' clips, B to A: the car stands at the ground floor (lit), the first floor is locked.
const LETTERS: Array[StringName] = [&"dark", &"lit", &"locked", &"dark"]
const GLYPHS: Array[String] = ["b", "g", "1", "a"]

@onready var _camera: Camera3D = $Camera
@onready var _stop: Node3D = $Stop


func _ready() -> void:
	# The ground floor's stop: its call set shows (the stop's own code does this in the game).
	for g: String in GLYPHS:
		(_stop.get_node("Model/call_" + g) as Node3D).visible = g == "g"
	for i in GLYPHS.size():
		var letter := get_node("Car/Letter%d" % i) as Node3D
		for g: String in GLYPHS:
			(letter.get_node("Model/glyph_" + g) as Node3D).visible = g == GLYPHS[i]
		_pose(letter.get_node("AnimationPlayer") as AnimationPlayer, LETTERS[i], 0.0)


## Frames view `name` of VIEWS and poses the Looks by its clips.
func show_view(name: String) -> void:
	var view: Dictionary = VIEWS[name]
	_camera.position = view["from"]
	_camera.look_at(view["at"])
	for c: Array in view["clips"]:
		_pose(_stop.get_node(String(c[0])) as AnimationPlayer, StringName(c[1]), float(c[2]))


func _pose(player: AnimationPlayer, clip: StringName, at: float) -> void:
	player.play(clip)
	player.seek(at, true)
	player.pause()
