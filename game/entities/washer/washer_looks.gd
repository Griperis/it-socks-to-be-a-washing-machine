## The washing machine's face and body (docs/architecture/washer.md "looks_contract.json"): the script on the
## root of every washer Looks (the graybox and the real one). A `VoiceSource` (core/85): `Voices` plays a line's
## sound at this node and calls `act(take)`, which plays the take's baked acting on `AnimationPlayer`.
## Besides the acting, the face is three animation players of the Looks scene:
##   `AnimationPlayer`  the acting, the held mood poses, and `mouth` (shut to 40 degrees open) which this
##                      script seeks to `door` while no line plays (the spit's and the washes' door);
##   `Loops`            `talk` or `rumble` on the `bob` bone, weighted by the acting's `wiggle` (the angry
##                      share picks rumble); completely still in pauses and silence (Q1412);
##   `Spin`             `spin` on the drum's two bones, a turn a second at speed 1, scaled by `spin`.
## What the washes and the run set: `door` 0-1, `spin` turns a second, `pile` 0-1 (the laundry behind the
## porthole), `repair` and `damage` 0-1 (the broken look, core/87), `bubbles(on)`.
## Looks only: it never writes state.
class_name WasherLooks
extends VoiceSource

## The bones of the contract, by name.
const BONE_BOB := &"bob"
const BONE_DRUM := &"drum_spin"
const BONE_TUMBLE := &"laundry_tumble"
const MOUTH := &"mouth"
const TALK := &"talk"
const RUMBLE := &"rumble"
const SPIN := &"spin"

@export var tuning: WasherTuning
## The skeleton (`face_rig`), the loops' and the spin's players.
@export var rig: Skeleton3D
@export var loops: AnimationPlayer
@export var spinner: AnimationPlayer
## The drum's lining, whose glow shows the mood, and the light inside the drum.
@export var lining: MeshInstance3D
@export var drum_light: OmniLight3D
## The laundry behind the porthole, and the bubbles.
@export var pile_node: Node3D
@export var bubbles_node: GPUParticles3D

## The door outside a line, 0 shut to 1 open (40 degrees).
var door := 0.0
## Turns a second of the drum (0: still).
var spin := 0.0
## The laundry behind the porthole: 0 hides it, 1 the model's own heap.
var pile := 0.0
## How healthy it looks, 1 fine to 0 dim and flickering (core/87), and how much it sparks and smokes.
var repair := 1.0
var damage := 0.0
## The light inside the drum is on (a line plays).
var lit := false

var _door_shown := -1.0
var _glow_now := Color.BLACK
var _glow_energy_now := 0.0
var _material: StandardMaterial3D = null
var _bob_rest := Transform3D.IDENTITY


func _ready() -> void:
	super._ready()
	if rig != null:
		var bob := rig.find_bone(BONE_BOB)
		if bob >= 0:
			_bob_rest = rig.get_bone_rest(bob)
	if loops != null and not loops.mixer_applied.is_connected(_weigh_bob):
		loops.mixer_applied.connect(_weigh_bob)
	if lining != null and lining.material_override is StandardMaterial3D:
		_material = (lining.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		lining.material_override = _material
	if drum_light != null and tuning != null:
		drum_light.omni_range = tuning.light_range
	_glow_now = tuning.glow_idle_colour if tuning != null else Color.WHITE
	_glow_energy_now = tuning.glow_idle_energy if tuning != null else 0.0
	_apply_pile()
	_apply_glow()


## Plays the take's acting and lights the drum.
func act(take: VoiceTake) -> void:
	lit = true
	_door_shown = -1.0
	super.act(take)


## Back to the basic pose: neutral brows, no lean, door shut, still, the idle glow (Q1436).
func rest() -> void:
	super.rest()
	lit = false
	_door_shown = -1.0
	if loops != null:
		loops.stop()
	_reset_bob()


## Bubbles rise out of the porthole, or stop.
func bubbles(on: bool) -> void:
	if bubbles_node != null:
		bubbles_node.emitting = on


## Whether bubbles rise now.
func bubbling() -> bool:
	return bubbles_node != null and bubbles_node.emitting


func _process(delta: float) -> void:
	_loop()
	_spin()
	_door()
	_ease_glow(delta)
	_apply_pile()


## The body loop the acting's wiggle and anger ask for.
func _loop() -> void:
	if loops == null:
		return
	var want := &""
	if wiggle > 0.001:
		want = RUMBLE if angry >= (tuning.rumble_from if tuning != null else 0.5) else TALK
	if want == &"":
		if loops.is_playing():
			loops.stop()
			_reset_bob()
	elif loops.current_animation != String(want) or not loops.is_playing():
		loops.play(want, -1.0, tuning.rumble_speed if want == RUMBLE and tuning != null else (tuning.talk_speed if tuning != null else 1.0))


## The spin loop at `spin` turns a second.
func _spin() -> void:
	if spinner == null:
		return
	if absf(spin) < 0.001:
		if spinner.is_playing():
			spinner.stop()
			_reset_bone(BONE_DRUM)
			_reset_bone(BONE_TUMBLE)
	elif not spinner.is_playing():
		spinner.play(SPIN)
	if spinner.is_playing():
		spinner.speed_scale = spin


## The door outside a line follows `door` (the player is the acting's while a line plays).
func _door() -> void:
	if player == null or is_acting() or is_equal_approx(door, _door_shown) or not player.has_animation(MOUTH):
		return
	_door_shown = door
	player.play(MOUTH)
	player.seek(clampf(door, 0.0, 1.0) * player.get_animation(MOUTH).length, true)
	player.pause()


## The shown glow eases toward the wanted one: the acting's colour while a line plays, else the idle glow.
func _ease_glow(delta: float) -> void:
	var colour := glow_colour if lit else (tuning.glow_idle_colour if tuning != null else Color.WHITE)
	var energy := glow_energy if lit else (tuning.glow_idle_energy if tuning != null else 0.0)
	var k := 1.0 - exp(-(tuning.glow_ease if tuning != null else 6.0) * delta)
	_glow_now = _glow_now.lerp(colour, k)
	_glow_energy_now = lerpf(_glow_energy_now, energy, k)
	_apply_glow()


## The colour and energy the lining shows now, and the light's.
func shown_glow() -> Color:
	return _glow_now


func shown_energy() -> float:
	return _glow_energy_now


func _apply_glow() -> void:
	if _material != null:
		_material.emission_enabled = true
		_material.emission = _glow_now
		_material.emission_energy_multiplier = _glow_energy_now
	if drum_light != null:
		drum_light.visible = lit
		drum_light.light_color = _glow_now
		drum_light.light_energy = _glow_energy_now * (tuning.light_energy if tuning != null else 0.6)


func _apply_pile() -> void:
	if pile_node != null:
		pile_node.visible = pile > 0.001
		pile_node.scale = Vector3.ONE * clampf(pile, 0.001, 1.0)


## After the loops' pose is applied the bob is weighted by the wiggle: none, the rest; full, the loop.
func _weigh_bob() -> void:
	if rig == null:
		return
	var bob := rig.find_bone(BONE_BOB)
	if bob >= 0:
		rig.set_bone_pose(bob, _bob_rest.interpolate_with(rig.get_bone_pose(bob), clampf(wiggle, 0.0, 1.0)))


func _reset_bob() -> void:
	_reset_bone(BONE_BOB)


func _reset_bone(bone: StringName) -> void:
	if rig == null:
		return
	var i := rig.find_bone(bone)
	if i >= 0:
		rig.reset_bone_pose(i)
