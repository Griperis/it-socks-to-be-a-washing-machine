## The Sounds station's buttons (core/22, Q2337): one small box per event of the sound catalogue, in
## the catalogue's order, grouped by bus, each with its name in front of it. All of it is made when the
## station enters the tree: a new event in sound_catalogue.tres has its button with no other change.
## A looping event (an ambience) has none: the station's Ambience node plays it. Each button is a
## SoundSpot beside a body the player's use can hit, so it plays flat or from its own spot as the
## event says.
class_name SoundsStation
extends Node3D

const BUTTON := preload("res://game/zoo/sounds/sound_button.tscn")
const LABEL := preload("res://game/zoo/zoo_label.tscn")
## The light text of the group names, as the buttons' (sound_button.tscn's Label).
const LIGHT := Color(0.97, 0.97, 0.92)

## The events to make buttons for.
@export var catalogue: SoundCatalogue
@export var layout: SoundsLayout
## Where the buttons and the group names go.
@export var buttons: Node3D

var _built := false
var _positions: Dictionary[StringName, Vector3] = {}


func _enter_tree() -> void:
	if _built or catalogue == null or layout == null or buttons == null:
		return
	_built = true
	build()


## The buttoned events (no loops) in the catalogue's order.
func events() -> Array[SoundEvent]:
	var out: Array[SoundEvent] = []
	for e in catalogue.events:
		if not e.loop:
			out.append(e)
	return out


## The buses of those events, in the order their first event appears.
func groups() -> Array[String]:
	var out: Array[String] = []
	for e in events():
		if not out.has(e.bus):
			out.append(e.bus)
	return out


## The events of a group, in the catalogue's order.
func events_of(group: String) -> Array[SoundEvent]:
	var out: Array[SoundEvent] = []
	for e in events():
		if e.bus == group:
			out.append(e)
	return out


## Where an event's button stands in the station's space (the box's foot).
func button_position(event: StringName) -> Vector3:
	return _positions.get(event, Vector3.INF)


## Lays out every button: one pass, each group a block of rows, the first row nearest the player.
func build() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * layout.button_size
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	var flat := _material(layout.flat_colour)
	var world := _material(layout.world_colour)
	var z := layout.origin.z
	for g in groups():
		var list := events_of(g)
		var title := LABEL.instantiate() as Label3D
		title.name = "Group_%s" % g
		title.text = g.to_upper()
		title.pixel_size = layout.group_pixel_size
		title.modulate = LIGHT
		title.position = Vector3(layout.origin.x - layout.group_offset, 0.01, z)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		buttons.add_child(title)
		for i in list.size():
			@warning_ignore("integer_division")
			var at := Vector3(layout.origin.x + (i % layout.per_row) * layout.column_pitch, 0.0,
					z - (i / layout.per_row) * layout.row_pitch)
			var e := list[i]
			_positions[e.event] = at
			buttons.add_child(_button(e, at, mesh, shape, world if e.spatial else flat))
		@warning_ignore("integer_division")
		z -= ((list.size() + layout.per_row - 1) / layout.per_row) * layout.row_pitch + layout.group_gap


## A button (sound_button.tscn) for event `e` at `at`, sized by the layout.
func _button(e: SoundEvent, at: Vector3, mesh: BoxMesh, shape: BoxShape3D, material: Material) -> Node3D:
	var root := BUTTON.instantiate() as Node3D
	root.name = String(e.event)
	root.position = at
	var box := root.get_node(^"Body/Mesh") as MeshInstance3D
	box.mesh = mesh
	box.material_override = material
	box.position.y = layout.button_size * 0.5
	var collider := root.get_node(^"Body/Shape") as CollisionShape3D
	collider.shape = shape
	collider.position.y = layout.button_size * 0.5
	(root.get_node(^"Spot") as SoundSpot).event = e.event
	var label := root.get_node(^"Label") as Label3D
	label.text = String(e.event)
	label.pixel_size = layout.label_pixel_size
	label.position = Vector3(0.0, 0.01, layout.label_offset)
	return root


func _material(colour: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	return m
