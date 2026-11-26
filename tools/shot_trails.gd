## core/144's stills: one Trail's mark laid on a floor, seen from behind and above. `GAME_TRAIL=<piece id>`
## names the Trail (default lint_puffs); `kit/tools/shot.sh --scene=res://tools/shot_trails.tscn --shots=<frames>`
## takes its moments (the shot runs at a fixed 60 frames a second, so frame 60 is one second of the mark's life).
extends Node3D


func _ready() -> void:
	var id := OS.get_environment("GAME_TRAIL")
	var piece := load("res://game/wardrobe/pieces/%s.tres" % (id if id != "" else "lint_puffs")) as WardrobePiece
	var mark := piece.looks.instantiate() as TrailMark
	mark.position = Vector3(0.0, 0.006, 0.0)
	add_child(mark)
