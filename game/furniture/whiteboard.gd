## The Whiteboard: the board on its wheeled easel shows this run's tallies on its face (docs/architecture/
## stages.md "The tallies, the Whiteboard and Tab"). It puts the sheet in a SubViewport of its own and
## that picture on the face (`Looks/Board`, lit a little by itself, `glow`), and draws the picture
## again only when the sheet says a tally changed. Looks only: it reads the tallies and decides nothing.
class_name Whiteboard
extends StaticBody3D

const SHEET := preload("res://game/ui/whiteboard/whiteboard_sheet.tscn")

@export var tuning: WhiteboardTuning

## How many times the board's picture was asked to draw again (a case reads that a change draws once).
var renders := 0

var _viewport: SubViewport
var _sheet: WhiteboardSheet


func _ready() -> void:
	if tuning == null:
		tuning = WhiteboardTuning.new()
	_viewport = SubViewport.new()
	_viewport.name = "BoardPicture"
	_viewport.size = tuning.resolution
	_viewport.disable_3d = true
	_viewport.transparent_bg = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(_viewport)
	_sheet = SHEET.instantiate() as WhiteboardSheet
	_sheet.size = Vector2(tuning.resolution)
	_viewport.add_child(_sheet)
	_sheet.changed.connect(_render)
	var face := get_node_or_null("Looks/Board") as MeshInstance3D
	if face != null:
		var m := StandardMaterial3D.new()
		m.albedo_texture = _viewport.get_texture()
		m.roughness = 0.3
		m.emission_enabled = true
		m.emission_texture = _viewport.get_texture()
		m.emission = Color.WHITE
		m.emission_energy_multiplier = tuning.glow
		face.material_override = m


## The sheet on the face.
func sheet() -> WhiteboardSheet:
	return _sheet


func _render() -> void:
	renders += 1
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
