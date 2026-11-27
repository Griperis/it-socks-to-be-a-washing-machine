## The Day station (core/160, Q2337; docs/architecture/day-and-exterior.md "How it is authored"): a small room of
## house kit pieces running its own day, and a board built from the data at load: one button (day_key_button.tscn)
## per DayKey in the keys folder (its hour and its light's colour; a new key shows with no other change) and the hour
## slider's notches, one per hour, with a knob at the station's shown hour.
##
## The rest of the zoo keeps its noon (Q2299): only while the player's camera is inside `room` does the camera show
## the station's Environment (its Picture's copy, which its DayLight writes) and the station's Sun instead of the
## zoo's; the station's Sun hangs under `sun_holder`, shown only then.
class_name DayStation
extends Node3D

const BUTTON := preload("res://game/zoo/day/day_key_button.tscn")

## The station's day, its look and its lamps.
@export var day: Day
@export var day_light: DayLight
@export var picture: Picture
@export var lights: HouseLights
## Holds the station's Sun: shown only while the camera is in the room.
@export var sun_holder: Node3D
## Where the key buttons and the slider's notches go.
@export var board: Node3D
## The slider's knob, moved along the notches to the shown hour.
@export var knob: Node3D
## The room, in the station's space: inside it the camera shows the station's day.
@export var room := AABB(Vector3(-1.0, 0.0, -5.0), Vector3(4.0, 3.0, 4.0))
## The key buttons' row: the first button's place and the step to the next (station space).
@export var keys_at := Vector3(0.6, 0.0, 1.0)
@export var key_step := 0.6
## The slider's notches: the 0:00 notch's place and the step to the next hour.
@export var slider_at := Vector3(0.3, 0.0, 0.2)
@export var hour_step := 0.22
## The slider's notches are labelled every this many hours.
@export var label_every := 3

var _built := false
## Whether the camera was in the room at the last frame (-1 before the first).
var _inside := -1
var _zoo_sun: DirectionalLight3D = null


## The station's lamps are its own: no floor lock, washing machine or tree elsewhere in the zoo finds them.
func _ready() -> void:
	if lights != null:
		lights.remove_from_group(HouseLights.GROUP)


func _enter_tree() -> void:
	if _built or board == null or day_light == null:
		return
	_built = true
	build()


## One button per key in the keys folder, then one notch per hour.
func build() -> void:
	var keys := DayLight.load_keys(day_light.keys_folder)
	for i in keys.size():
		var k := keys[i]
		var b := _button("Key_%s" % DayZooSwitch.hour_text(k.hour).replace(":", ""), k.hour, keys_at + Vector3(i * key_step, 0.0, 0.0))
		(b.get_node(^"Label") as Label3D).text = DayZooSwitch.hour_text(k.hour)
		((b.get_node(^"Body/Mesh") as MeshInstance3D).material_override as StandardMaterial3D).albedo_color = k.light_colour
	for h in 24:
		var n := _button("Hour_%02d" % h, float(h), slider_at + Vector3(h * hour_step, 0.0, 0.0))
		n.scale = Vector3(0.5, 0.5, 0.5)
		(n.get_node(^"Label") as Label3D).text = str(h) if h % label_every == 0 else ""


func _button(title: String, at_hour: float, at: Vector3) -> Node3D:
	var b := BUTTON.instantiate() as Node3D
	b.name = title
	b.position = at
	var s := b.get_node(^"Switch") as DayZooSwitch
	s.day = day
	s.hour = at_hour
	board.add_child(b)
	return b


func _process(_delta: float) -> void:
	if day != null and knob != null:
		knob.position = slider_at + Vector3(day.shown_hour() * hour_step, knob.position.y, 0.0)
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	var inside := cam != null and room.has_point(global_transform.affine_inverse() * cam.global_position)
	if int(inside) == _inside:
		return
	_inside = int(inside)
	if sun_holder != null:
		sun_holder.visible = inside
	if _zoo_sun == null:
		_zoo_sun = _level_sun()
	if _zoo_sun != null:
		_zoo_sun.visible = not inside
	if cam != null:
		cam.environment = picture.environment() if inside and picture != null else null


## The level's own Sun (the zoo's): the Sun of the nearest Picture beside an ancestor of this station.
func _level_sun() -> DirectionalLight3D:
	var at := get_parent()
	while at != null:
		for child in at.get_children():
			if child is Picture and child != picture:
				return (child as Picture).sun
		at = at.get_parent()
	return null
