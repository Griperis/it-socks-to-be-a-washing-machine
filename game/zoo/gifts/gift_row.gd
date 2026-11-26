## One row of the Gifts station's shelf (core/137): a Collection's wrapped present box, its name and its pieces
## (core/122's previews, `Wardrobe.preview`) side by side. Filled from the Collection's file by `fill()`.
class_name GiftRow
extends Node3D

## The present's Looks the row wraps.
@export var box: Node3D
@export var name_label: Label3D
## Where the pieces stand, `pitch` apart along +x.
@export var pieces: Node3D
@export var pitch := 0.7
@export var tuning: PresentTuning


## Shows Collection `c`.
func fill(c: SockCollection) -> void:
	name = String(c.id)
	name_label.text = c.name
	Present.wrap_looks(box, c, tuning if tuning != null else PresentTuning.new())
	var player := box.get_node_or_null(^"AnimationPlayer") as AnimationPlayer
	if player != null and player.has_animation(Present.LYING):
		player.play(Present.LYING)
	var x := 0.0
	for piece in PresentDraw.pieces_of(c.id):
		var preview := Wardrobe.preview(piece.id)
		preview.name = String(piece.id)
		preview.position = Vector3(x, 0.35, 0.0)
		pieces.add_child(preview)
		x += pitch
