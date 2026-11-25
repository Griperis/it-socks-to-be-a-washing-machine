## The Lobby's one 3D view (docs/architecture/lobby.md "Core/66", the old lobby/06): a SubViewport with
## a World3D of its own, one camera 10 m in front of a row of pedestals, each with a player's Avatar
## (the game's sock creature, in the player's colour, idling as an Avatar does) or, on a free place, a flat
## grey silhouette on a dimmed pedestal. It fills the Lobby behind its keys, so a point of the stage is a
## point of the Lobby: the places follow their figures through `box_of()`. A view: the Lobby says what to show.
class_name LobbyStage
extends SubViewportContainer

const LOOKS := preload("res://game/parts/avatar/looks_avatar.tscn")
## The most places a Lobby shows (the Roster's most players).
const PLACES := 4
## 16:9, the screen the framing is made for.
const WIDE := 16.0 / 9.0

@export var tuning: LobbyTuning = preload("res://game/lobby/lobby_tuning.tres")

var _count := PLACES
var _pedestals: Array[MeshInstance3D] = []
var _figures: Array[AvatarLooks] = []
var _free: Array[bool] = []
var _focus := -1
var _silhouette_material: StandardMaterial3D = null

@onready var _view: SubViewport = %View
@onready var _camera: Camera3D = %Camera
@onready var _row: Node3D = %Row


func _ready() -> void:
	stretch = true
	_silhouette_material = StandardMaterial3D.new()
	_silhouette_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_silhouette_material.albedo_color = tuning.backdrop.lerp(Color(0.5, 0.5, 0.5), tuning.silhouette_show)
	for i in PLACES:
		_pedestals.append(_row.get_node("Pedestal%d" % i) as MeshInstance3D)
		var figure := LOOKS.instantiate() as AvatarLooks
		figure.name = "Figure%d" % i
		figure.seed_idle("lobby%d" % i)
		figure.rotation.y = PI  # the creature faces -z; the camera is in front of the row, on +z
		_row.add_child(figure)
		_figures.append(figure)
		_free.append(true)
	resized.connect(_frame)
	set_places(_count)
	_frame()


## How many places stand in the row (Solo one, co-op four), centred.
func set_places(count: int) -> void:
	_count = clampi(count, 1, PLACES)
	for i in PLACES:
		var x := (i - (_count - 1) * 0.5) * tuning.spacing
		_pedestals[i].visible = i < _count
		_figures[i].visible = i < _count
		_pedestals[i].position.x = x
		_figures[i].position.x = x
	_paint()


## Place `i` stands a player: their Avatar in `colour`, no name tag (the name is under the pedestal).
func show_player(i: int, colour: Color) -> void:
	_free[i] = false
	var figure := _figures[i]
	_dress(figure, false)
	figure.colour = colour
	_paint()


## Place `i` is free: a flat grey silhouette of the bare creature on a dimmed pedestal.
func show_free(i: int) -> void:
	_free[i] = true
	_dress(_figures[i], true)
	_paint()


## Whether place `i` shows a silhouette.
func is_free(i: int) -> bool:
	return _free[i]


## The pedestal of place `i` turns gold; -1 for none.
func set_focus(i: int) -> void:
	_focus = i
	_paint()


## The Avatar of place `i` (a silhouette too).
func figure(i: int) -> AvatarLooks:
	return _figures[i]


## Where place `i`'s figure falls on the stage (the Lobby's pixels): the box round it (head to base, `figure_width`
## wide), and the point under its pedestal where the name row hangs.
func box_of(i: int) -> Rect2:
	if _view == null or _view.size.x < 2 or not _camera.is_inside_tree() or not is_visible_in_tree() \
			or DisplayServer.get_name() == "headless":  # a headless run draws no view: nothing to project
		return Rect2()
	var x := _pedestals[i].position.x
	var half := tuning.figure_width * 0.5
	var top := _camera.unproject_position(Vector3(x, tuning.figure_height, 0.0))
	# The pedestal's front-bottom edge: its mesh is the one source of its size (lobby_stage.tscn).
	var mesh := _pedestals[i].mesh as CylinderMesh
	var foot := _camera.unproject_position(Vector3(x, _pedestals[i].position.y - mesh.height * 0.5, mesh.bottom_radius))
	var left := _camera.unproject_position(Vector3(x - half, 0.0, 0.0))
	var right := _camera.unproject_position(Vector3(x + half, 0.0, 0.0))
	return Rect2(left.x, top.y, right.x - left.x, foot.y - top.y)


func _dress(figure: AvatarLooks, silhouette: bool) -> void:
	figure.player_name = ""
	if silhouette:
		figure.colour = Color.WHITE
	for mi: Node in figure.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = _silhouette_material if silhouette else null
	for pupil: Node in figure.find_children("Pupil*", "Node3D", true, false):
		(pupil as Node3D).visible = not silhouette


func _paint() -> void:
	for i in _pedestals.size():
		var colour := tuning.pedestal_colour
		if _free[i]:
			colour = colour.lerp(tuning.backdrop, tuning.free_dim)
		elif i == _focus:
			colour = tuning.focus_colour
		((_pedestals[i]).material_override as StandardMaterial3D).albedo_color = colour


## The camera: 16:9 or wider keeps the height it sees, a narrower screen keeps the width a 16:9 one sees.
func _frame() -> void:
	if _camera == null:
		return
	var at := Vector3(0.0, tuning.camera_height, tuning.camera_distance)
	_camera.position = at
	_camera.look_at(Vector3(0.0, tuning.camera_look_height, 0.0))
	var narrow := size.y > 0.0 and size.x / size.y < WIDE
	if narrow:
		_camera.keep_aspect = Camera3D.KEEP_WIDTH
		_camera.fov = rad_to_deg(2.0 * atan(tan(deg_to_rad(tuning.camera_fov) * 0.5) * WIDE))
	else:
		_camera.keep_aspect = Camera3D.KEEP_HEIGHT
		_camera.fov = tuning.camera_fov
