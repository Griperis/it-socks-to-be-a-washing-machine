## The Sock generator station's sign (core/52): the seed its Socks were laid from and how many lie there.
class_name SeedSign
extends Label3D

@export var generated: GeneratedSocks

var _shown := Vector2i(-1, -1)


func _process(_delta: float) -> void:
	if generated == null:
		return
	var now := Vector2i(generated.seed, generated.socks)
	if now == _shown:
		return
	_shown = now
	text = "Seed %d: %d Socks (%d Pairs)" % [now.x, now.y, now.y / 2]
