## One playable key of the piano (house/28, Q544, Q2508; the old devices/piano_key.gd): a left click on
## it plays its note for everyone. The key is its own thing: `Keys/Key_<midi>` under the piano, standing
## on the key's hinge at its back, with its collision body (the old key's boxes) and this Part. Its mesh
## is the piano Looks' `Key_<midi>`, which it dips by `dip_deg` about `axis` and lets back up whenever
## anyone plays it. The shut key lid covers it, so the crosshair reaches it only once the lid is open.
##
## The state is how many times it was played and by whom: a granted `play` counts one more, and every
## machine that shows the new count dips the key and sounds its note at it (Sounds.play_note, the
## catalogue's "piano" instrument). A Guest's own key sounds and dips at once on its press, before the
## Host's word, and not again when the word comes (the old HouseRules.play_key()). A count arriving whole
## (a late Guest) plays nothing.
class_name PianoKey
extends Part

const NAMES: Array[String] = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
## The sound catalogue's instrument the keys play.
const INSTRUMENT := &"piano"
## The key's mesh in the piano's Looks, from this part (Piano/Keys/Key_<midi>/Key).
const MESH := "../../../Looks/Key_%d"
const PLAY := &"play"

@export var tuning: PianoTuning
## This key's MIDI note (60 is middle C).
@export_range(21, 108, 1) var note := 60
## How far the key turns down about its back when played, and the axis it turns about (the piano's
## own frame), from the old model.
@export var dip_deg := 3.0
@export var axis := Vector3.RIGHT

@export_group("State")
## How many times it has been played.
@export var strikes := 0
## Who played it last.
@export var by := 0
@export_group("")

## The count last shown: a new one dips and sounds.
var _shown := 0
var _tween: Tween = null
var _mesh: Node3D = null
var _home := Transform3D.IDENTITY


## The note's name with its octave ("C4" for middle C, "F#3").
static func note_name(midi: int) -> String:
	return "%s%d" % [NAMES[midi % 12], midi / 12 - 1]


func prompt_title() -> String:
	return "Play %s" % note_name(note)


func click_only() -> bool:
	return true


## The left click: ask to play it. A Guest hears and sees its own key at once.
func use(player: int) -> void:
	if not parts.is_host():
		press()
	parts.ask(Command.new(PLAY, player, id, {}))


func accepts() -> Dictionary[StringName, Dictionary]:
	return {PLAY: {"args": {}, "rate": _tuning().rate}}


func decide(cmd: Command) -> Dictionary:
	if cmd.kind != PLAY:
		return refuse("wrong")
	if not parts.near(cmd.by, get_parent(), _tuning().reach):
		return refuse("far")
	return grant({"strikes": strikes + 1, "by": cmd.by})


func _show(now: bool) -> void:
	if now or strikes == _shown:
		_shown = strikes
		return
	_shown = strikes
	var mine := parts != null and not parts.is_host() and is_inside_tree() and by == multiplayer.get_unique_id()
	if not mine:
		press()


## Dips the key and lets it back up, and sounds its note at the key: what a play looks and sounds like.
func press() -> void:
	var spot := get_parent() as Node3D
	if spot != null and spot.is_inside_tree():
		Sounds.play_note(INSTRUMENT, note, spot.global_position)
	var mesh := key_mesh()
	if mesh == null or not is_inside_tree():
		return
	if _tween != null:
		_tween.kill()
	var t := _tuning()
	_tween = create_tween()
	_tween.tween_method(_set_dip, dip(), 1.0, t.dip_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_dip, 1.0, 0.0, t.rise_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## The key's mesh in the piano's Looks (found once, and again after a Looks swap), or null.
func key_mesh() -> Node3D:
	if is_instance_valid(_mesh) and _mesh.is_inside_tree():
		return _mesh
	_mesh = get_node_or_null(NodePath(MESH % note)) as Node3D
	if _mesh != null:
		_home = _mesh.transform
	return _mesh


## How far down the key is now: 0 at rest, 1 fully down.
func dip() -> float:
	var mesh := key_mesh()
	if mesh == null:
		return 0.0
	var a := (_home.basis.inverse() * mesh.transform.basis).get_rotation_quaternion().get_angle()
	return clampf(rad_to_deg(a) / maxf(dip_deg, 0.001), 0.0, 1.0)


## Whether the key is still dipping or rising.
func moving() -> bool:
	return _tween != null and _tween.is_valid() and _tween.is_running()


func _set_dip(t: float) -> void:
	var mesh := key_mesh()
	if mesh != null:
		mesh.transform = Transform3D(Basis(axis.normalized(), deg_to_rad(dip_deg) * t) * _home.basis, _home.origin)


func _tuning() -> PianoTuning:
	if tuning == null:
		tuning = PianoTuning.new()
	return tuning
