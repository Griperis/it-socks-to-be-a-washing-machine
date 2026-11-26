## The preview's stage (core/128, the old WardrobeView.stage()): a SubViewport with a world of its own on a
## clear background, its warm ambient light, key light and camera as nodes of `preview_stage.tscn`. What it
## shows stands under `Stage/Shown` (a piece centred on `Stage/Focus`, where the camera looks). The Wardrobe page (core/142) shows the
## player's creature on it, the gift reveal (core/138) a piece (show_piece()).
class_name PreviewStage
extends SubViewportContainer

const SHOWN := ^"Stage/Shown"
## Where the camera looks: a piece stands centred there.
const FOCUS := ^"Stage/Focus"


## Shows `node` alone on the stage (whatever stood there goes); null clears it.
func put(node: Node3D) -> void:
	var shown := get_node(SHOWN) as Node3D
	for c: Node in shown.get_children():
		shown.remove_child(c)
		c.queue_free()
	if node != null:
		shown.add_child(node)


## Shows a piece as `Wardrobe.preview` makes it: a Socks piece on feet in `tint`.
func show_piece(id: StringName, tint := Color.WHITE) -> Node3D:
	var node := Wardrobe.preview(id, tint)
	node.position = (get_node(FOCUS) as Node3D).position
	put(node)
	return node


## What stands on the stage now, or null.
func shown() -> Node3D:
	var at := get_node(SHOWN)
	return at.get_child(0) as Node3D if at.get_child_count() > 0 else null
