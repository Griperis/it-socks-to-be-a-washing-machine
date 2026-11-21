## The Sounds station's buttons (core/22, Q2337): one small box per event of the sound catalogue, in
## the catalogue's order, grouped by bus, each with its name in front of it. All of it is made when the
## station enters the tree: a new event in sound_catalogue.tres has its button with no other change.
## A looping event (an ambience) has none: the station's Ambience node plays it. Each button is a
## SoundSpot beside a body the player's use can hit, so it plays flat or from its own spot as the
## event says.
class_name SoundsStation
extends Node3D

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
		var title := _label(g.to_upper(), layout.group_pixel_size,
				Vector3(layout.origin.x - layout.group_offset, 0.01, z))
		title.name = "Group_%s" % g
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


func _button(e: SoundEvent, at: Vector3, mesh: BoxMesh, shape: BoxShape3D, material: Material) -> Node3D:
	var root := Node3D.new()
	root.name = String(e.event)
	root.position = at
	var body := StaticBody3D.new()
	body.name = "Body"
	root.add_child(body)
	var box := MeshInstance3D.new()
	box.name = "Mesh"
	box.mesh = mesh
	box.material_override = material
	box.position.y = layout.button_size * 0.5
	body.add_child(box)
	var collider := CollisionShape3D.new()
	collider.name = "Shape"
	collider.shape = shape
	collider.position.y = layout.button_size * 0.5
	body.add_child(collider)
	var spot := SoundSpot.new()
	spot.name = "Spot"
	spot.event = e.event
	root.add_child(spot)
	var label := _label(String(e.event), layout.label_pixel_size, Vector3(0.0, 0.01, layout.label_offset))
	label.name = "Label"
	root.add_child(label)
	return root


func _material(colour: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	return m


## A name lying on the ground, to be read from above and from the front.
func _label(text: String, pixel_size: float, at: Vector3) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.pixel_size = pixel_size
	label.modulate = Color(0.97, 0.97, 0.92)
	label.shaded = false
	label.double_sided = false
	label.transform = Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), at)
	return label
