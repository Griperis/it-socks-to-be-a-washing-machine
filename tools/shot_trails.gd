## core/144's stills: one Trail's mark laid on a floor, seen from behind and above. `GAME_TRAIL=<piece id>` names
## the Trail (default lint_puffs); `GAME_AGE=<seconds>` shows the mark that old: it is run that far ahead, then
## its particles and clip are held, so a still is the same on every machine (`kit/tools/shot.sh
## --scene=res://tools/shot_trails.tscn --shots=12`).
extends Node3D

const HOLD := 2

var _mark: TrailMark = null
var _frames := 0


func _ready() -> void:
	var id := OS.get_environment("GAME_TRAIL")
	var piece := load("res://game/wardrobe/pieces/%s.tres" % (id if id != "" else "lint_puffs")) as WardrobePiece
	_mark = piece.looks.instantiate() as TrailMark
	_mark.position = Vector3(0.0, 0.006, 0.0)
	_mark.layout = int(OS.get_environment("GAME_LAYOUT")) if OS.get_environment("GAME_LAYOUT") != "" else 0
	var age := OS.get_environment("GAME_AGE")
	if age != "":
		_mark.laid_ago(maxf(float(age) - float(HOLD) / 60.0, 0.0))
	add_child(_mark)


func _process(_delta: float) -> void:
	_frames += 1
	if _frames == HOLD and OS.get_environment("GAME_AGE") != "":
		for p: Node in _mark.find_children("*", "GPUParticles3D", true, false):
			(p as GPUParticles3D).speed_scale = 0.0
		for a: Node in _mark.find_children("*", "AnimationPlayer", true, false):
			(a as AnimationPlayer).speed_scale = 0.0
		_mark.set_process(false)
