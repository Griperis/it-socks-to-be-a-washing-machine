## What the knockdown wash looks and sounds like on every machine (core/98, `WasherWash`'s looks; nothing
## synced changes here). A body let go at the door slides in as a blob in its player's colour over
## `wash_slide`, squared in speed, shrinking into the drum; the door swings open and slams shut (the "wash_slam"
## sound) and the drum sloshes (the "wash_slosh" loop at the porthole) while the drum and the face's drum turn
## at `wash_turns`. Behind the porthole a blob in their colour tumbles for everyone else; the washed player's
## own eyes sit in the drum, their view turning with it and lolling a little, the HUD hidden, the screen
## fading to black over the spin's last `wash_fade_out`. When the Host's end comes the door bursts open (the
## slam again), stands open `door_open` and swings shut, and the screen fades back in over `wash_fade_in` as
## they tumble out. The washed player's avatar is hidden and out of play on every machine meanwhile
## (`Avatar.set_washed`), their own body held still in the machine (`Player.set_washed`).
##
## A cutscene that starts meanwhile keeps its own camera; its end ends the wash.
class_name WashView
extends Node3D

## The washer's face (its `door` and `spin` are set here) and the Part this shows.
@export var looks: WasherLooks
## The drum's middle in the machine's frame and what turns in it, the slide's blob, the camera and the fade.
@export var drum: Node3D
@export var blob: MeshInstance3D
@export var slider: MeshInstance3D
@export var camera: Camera3D
@export var overlay: CanvasLayer
@export var fade: ColorRect
@export var porthole: Marker3D
@export var slosh: AudioStreamPlayer3D

var _wash: WasherWash
var _serial := -1
var _out_seen := 0
## Who is in the drum as this machine shows it (0 nobody), and whether that is this machine's player.
var _peer := 0
var _local := false
## Seconds since the body went in (-1: none), where its slide starts, whether the door slammed.
var _since_in := -1.0
var _from := Vector3.ZERO
var _slammed := true
## Seconds since the door burst open (-1: none).
var _since_out := -1.0
var _tween: Tween = null
var _material := StandardMaterial3D.new()
## How many slams and bursts sounded (a test reads it).
var slams := 0


func _ready() -> void:
	_material.roughness = 0.6
	_material.emission_enabled = true  # it reads in the dark drum behind the glass
	_material.emission_energy_multiplier = 0.35
	if blob != null:
		blob.material_override = _material
		blob.visible = false
	if slider != null:
		slider.material_override = _material
		slider.visible = false
		slider.top_level = true
	if overlay != null:
		overlay.visible = false
	var e := Sounds.catalogue.find(&"wash_slosh") if slosh != null else null
	if e != null and not e.clips.is_empty():
		var stream := e.clips[0].duplicate() as AudioStream
		if "loop" in stream:
			stream.set("loop", true)
		slosh.stream = stream
		slosh.bus = e.bus
		slosh.unit_size = Sounds.catalogue.unit_size
		slosh.max_distance = Sounds.catalogue.max_distance


## Who is in the drum as this machine shows it, 0 nobody.
func washing() -> int:
	return _peer


## Whether this machine's own player is in the drum.
func is_local() -> bool:
	return _local


## The black the washed player's screen shows now, 0 clear to 1 black.
func black() -> float:
	return fade.color.a if overlay != null and overlay.visible else 0.0


## Whether the slosh loop plays.
func sloshing() -> bool:
	return slosh != null and slosh.playing


## Whether the body is going in now (its slide through the door, until the slam).
func going_in() -> bool:
	return _since_in >= 0.0 and _since_in < _tuning().wash_slide + _tuning().shut_time


## Whether the door burst open and has not swung shut yet.
func bursting() -> bool:
	return _since_out >= 0.0


## The Part's state arrived (`now`: whole, a bind or a late joiner's snapshot: no slide, no slam).
func follow(wash: WasherWash, now: bool) -> void:
	_wash = wash
	if wash.peer != 0:
		if wash.serial != _serial:
			_serial = wash.serial
			_enter(wash, now)
	elif _peer != 0:
		_leave(wash.out_serial != _out_seen)
	_out_seen = wash.out_serial


func _enter(wash: WasherWash, now: bool) -> void:
	if _peer != 0:
		_leave(false)
	_peer = wash.peer
	var runtime := LevelRuntime.of(self)
	_local = runtime != null and runtime.player != null and runtime.player.player_id() == _peer
	_since_out = -1.0
	_since_in = -1.0 if now else 0.0
	_slammed = now
	_from = wash.from
	var colour := Color.WHITE
	if runtime != null and runtime.roster != null and not runtime.roster.entry_of(_peer).is_empty():
		colour = runtime.roster.colour_of(_peer)
	_material.albedo_color = colour
	_material.emission = colour
	if slosh != null and not slosh.playing and slosh.stream != null:
		slosh.play()
	if _tween != null:
		_tween.kill()
		_tween = null
	if _local:
		_hold_player(true)
		_take_view()
	_hide_avatar(true)
	_door(0.0)


func _leave(out: bool) -> void:
	_hide_avatar(false)
	if slosh != null:
		slosh.stop()
	var was_local := _local
	_peer = 0
	_local = false
	_since_in = -1.0
	if slider != null:
		slider.visible = false
	if blob != null:
		blob.visible = false
	if looks != null:
		looks.spin = 0.0
	if out:
		_since_out = 0.0
		_slam()
	else:
		_since_out = -1.0
		_door(0.0)
	if was_local:
		_hold_player(false)
		_give_view(out)


## The local player's body is held in the machine, out of the way, while its eyes are in the drum.
func _hold_player(on: bool) -> void:
	var runtime := LevelRuntime.of(self)
	if runtime == null or runtime.player == null:
		return
	runtime.player.set_washed(on, _body_hold())


func _body_hold() -> Vector3:
	var thing := get_parent() as Node3D
	return thing.global_position if thing != null else global_position


func _hide_avatar(on: bool) -> void:
	var runtime := LevelRuntime.of(self)
	var kd := runtime.knockdowns if runtime != null else null
	var a := kd.avatar_of(_peer) if kd != null else null
	if a != null:
		a.set_washed(on)


## The eyes go into the drum: this machine's camera takes the view, clear of black.
func _take_view() -> void:
	if camera == null:
		return
	overlay.visible = true
	fade.color.a = 0.0
	_aim_camera()
	camera.make_current()


## Out of the drum: the player's own camera is back (knocked, or standing), and a tumble fades in from black.
func _give_view(out: bool) -> void:
	var runtime := LevelRuntime.of(self)
	if camera != null and camera.current:
		camera.clear_current(false)
		if runtime != null and runtime.player != null:
			runtime.player.camera().make_current()
	if not out:
		overlay.visible = false
		return
	overlay.visible = true
	fade.color.a = 1.0
	_tween = create_tween()
	_tween.tween_property(fade, "color:a", 0.0, maxf(_tuning().wash_fade_in, 0.001))
	_tween.tween_callback(func() -> void: overlay.visible = false)


func _process(delta: float) -> void:
	var t := _tuning()
	if _since_in >= 0.0:
		_since_in += delta
		# The body slides in through the open door, shrinking into the drum; the door slams.
		var f := clampf(_since_in / maxf(t.wash_slide, 0.01), 0.0, 1.0)
		if slider != null:
			slider.visible = f < 1.0 and _peer != 0
			slider.global_position = _from.lerp(_porthole_at(), f * f)
			slider.scale = Vector3.ONE * lerpf(2.4, 1.0, f)
		var open := clampf(_since_in / maxf(t.shut_time, 0.001), 0.0, 1.0)
		if _since_in >= t.wash_slide:
			open = 1.0 - clampf((_since_in - t.wash_slide) / maxf(t.shut_time, 0.001), 0.0, 1.0)
			if open <= 0.0 and not _slammed:
				_slammed = true
				_slam()
		_door(open)
	elif _since_out >= 0.0:
		_since_out += delta
		var open := clampf(_since_out / maxf(t.burst_time, 0.001), 0.0, 1.0)
		if _since_out > t.burst_time + t.door_open:
			open = 1.0 - clampf((_since_out - t.burst_time - t.door_open) / maxf(t.close_time, 0.001), 0.0, 1.0)
		_door(open)
		if open <= 0.0 and _since_out > t.burst_time:
			_since_out = -1.0
	if _peer != 0:
		_turn(delta, t)
		# A machine that joined mid-wash, or an avatar that came late, hides it here too.
		_keep_hidden()
	if _local and _wash != null:
		_aim_camera()
		if overlay != null and overlay.visible and (_tween == null or not _tween.is_valid()):
			fade.color.a = 1.0 - clampf(_wash.left_of() / maxf(t.wash_fade_out, 0.001), 0.0, 1.0)


## The drum and the face's drum turn; the blob tumbles behind the porthole for everyone but the washed player.
func _turn(delta: float, t: WasherTuning) -> void:
	if looks != null:
		looks.spin = t.wash_turns
	var slid := _since_in < 0.0 or _since_in >= t.wash_slide
	if blob != null:
		blob.visible = not _local and slid
		if blob.visible and drum != null:
			drum.rotation.z -= t.wash_turns * TAU * delta
			blob.rotation.z += 3.0 * delta


func _keep_hidden() -> void:
	var runtime := LevelRuntime.of(self)
	var kd := runtime.knockdowns if runtime != null else null
	var a := kd.avatar_of(_peer) if kd != null else null
	if a != null and not a.washed:
		a.set_washed(true)


## The washed player's view: from inside the drum out through the porthole, turning with the drum and
## lolling a little (the old rig_wash.gd drum_view).
func _aim_camera() -> void:
	var thing := get_parent() as Node3D
	if camera == null or thing == null or _wash == null:
		return
	var t := _tuning()
	var spun := (t.wash_seconds - _wash.left_of()) * t.wash_turns * TAU
	var b := thing.global_basis * Basis(Vector3.UP, PI) * Basis(Vector3.BACK, -spun) \
			* Basis(Vector3.RIGHT, t.drum_loll * sin(spun * 0.5))
	camera.global_transform = Transform3D(b.orthonormalized(), thing.global_transform * t.drum_eye)


func _door(open: float) -> void:
	if looks != null:
		looks.door = clampf(open, 0.0, 1.0)


func _slam() -> void:
	slams += 1
	Sounds.play_at(&"wash_slam", _porthole_at())


func _porthole_at() -> Vector3:
	return porthole.global_position if porthole != null else global_position


func _tuning() -> WasherTuning:
	return _wash.tuning if _wash != null and _wash.tuning != null else WasherTuning.new()
