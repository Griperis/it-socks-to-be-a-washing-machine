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
## The broken look (core/87): the sparks, smoke, flash and buzz under `Damage` as strong as `damage`, bursts on a fixed
## clock with fixed seeds; the drum's light dimmed and flickering by `repair`; the rumble under an angry voice. A
## cutscene's `WasherCutsceneLook` (`set_cutscene`) takes both over from the run's mood.
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

## The cutscene's look while one plays (null: the run's mood shows).
var _cut: WasherCutsceneLook = null
var _intensity := 0.0
var _clock := 0.0
var _next_burst := 0.0
var _last_burst := -INF
var _flash_left := 0.0
var _on := false
var _strength := 0.0
var _flicker := 1.0
var _flicker_rng := RandomNumberGenerator.new()
var _flicker_at := -1
var _sparks: Array[GPUParticles3D] = []
var _smoke: GPUParticles3D = null
var _flash: OmniLight3D = null
var _buzz: AudioStreamPlayer3D = null
var _rumble: AudioStreamPlayer3D = null
var _buzz_db := 0.0
var _rumble_db := 0.0

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
	_flicker_rng.seed = 70
	_find_damage()


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
	_clock += delta
	_loop()
	_spin()
	_door()
	_flicker_now()
	_ease_glow(delta)
	_apply_pile()
	_effects(delta)
	_rumbling()


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


## The glow's energy as shown: the eased glow, dimmed by the repair and flickering.
func shown_energy() -> float:
	return _glow_energy_now * dim() * _flicker


## The repair now: the cutscene's while one plays, else the run's.
func shown_repair() -> float:
	return clampf(_cut.repair if _cut != null else repair, 0.0, 1.0)


## The share the glow keeps for the repair: `repair_dim` at 0, 1 at 1.
func dim() -> float:
	return lerpf(tuning.repair_dim if tuning != null else 1.0, 1.0, shown_repair())


## The flicker's latest level, 1 steady down to `1 - repair_flicker` at repair 0.
func flicker() -> float:
	return _flicker


## A new pseudo-random level every `flicker_step`, deeper the less repaired, from a fixed seed.
func _flicker_now() -> void:
	if tuning == null:
		return
	var step := floori(_clock / tuning.flicker_step)
	if step == _flicker_at:
		return
	_flicker_at = step
	_flicker = 1.0 - tuning.repair_flicker * (1.0 - shown_repair()) * _flicker_rng.randf()


## A cutscene's look takes over the repair and the damage (null ends it, back to the run's mood).
func set_cutscene(look: WasherCutsceneLook) -> void:
	_cut = look
	_intensity = 0.0


func cutscene_playing() -> bool:
	return _cut != null


func _apply_glow() -> void:
	if _material != null:
		_material.emission_enabled = true
		_material.emission = _glow_now
		_material.emission_energy_multiplier = shown_energy()
	if drum_light != null:
		drum_light.visible = lit
		drum_light.light_color = _glow_now
		drum_light.light_energy = shown_energy() * (tuning.light_energy if tuning != null else 0.6)


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


# --- The broken look (core/87) ---------------------------------------------------------------------

func _find_damage() -> void:
	_sparks.clear()
	for n: StringName in [&"SparksBack", &"SparksCable"]:
		var sp := get_node_or_null("Damage/%s" % n) as GPUParticles3D
		if sp != null:
			if tuning != null:
				sp.amount = tuning.sparks_max
			sp.emitting = false
			_sparks.append(sp)
	_smoke = get_node_or_null("Damage/Smoke") as GPUParticles3D
	_flash = get_node_or_null("Damage/Flash") as OmniLight3D
	_buzz = _loop_player("Damage/Buzz", &"washer_buzz")
	_rumble = _loop_player("Damage/Rumble", &"washer_rumble")


## A looping world sound at `path` with the catalogue event's first clip, bus and level.
func _loop_player(path: String, event: StringName) -> AudioStreamPlayer3D:
	var p := get_node_or_null(path) as AudioStreamPlayer3D
	var e := Sounds.catalogue.find(event) if p != null else null
	if e == null or e.clips.is_empty():
		return null
	var stream := e.clips[0].duplicate() as AudioStream
	if "loop" in stream:
		stream.set("loop", true)
	p.stream = stream
	p.bus = e.bus
	p.unit_size = Sounds.catalogue.unit_size
	p.max_distance = Sounds.catalogue.max_distance
	return p


## How strong the effects are now (0..1) and whether any show; the sparks burst on the fixed clock.
func _effects(delta: float) -> void:
	if tuning == null:
		return
	var bursts := true
	if _cut != null:
		var angry_stretch := lit and angry >= tuning.rumble_from
		var goal := _cut.damage * (lerpf(tuning.cutscene_quiet, 1.0, clampf(wiggle, 0.0, 1.0)) if angry_stretch else tuning.cutscene_calm)
		_intensity = move_toward(_intensity, goal, delta * tuning.intensity_rate)
		_on = _intensity > 0.02
		_strength = _intensity
		bursts = angry_stretch and wiggle > tuning.cutscene_burst_wiggle
	else:
		_on = damage > 0.001
		var floor_share := 1.0 / float(maxi(tuning.zoo_levels, 1))
		_strength = clampf(inverse_lerp(floor_share, 1.0, damage), 0.0, 1.0)
	if _smoke != null:
		_smoke.emitting = _on
		var rate := lerpf(tuning.smoke_min, tuning.smoke_max, _strength)
		_smoke.amount_ratio = clampf(rate / (float(_smoke.amount) / _smoke.lifetime), 0.01, 1.0)
	if _on and bursts:
		if _clock >= _next_burst:
			_burst()
	else:
		_next_burst = _clock
	_flash_left = maxf(_flash_left - delta, 0.0)
	if _flash != null:
		_flash.visible = _flash_left > 0.0
		_flash.light_energy = tuning.flash_energy
	if _buzz != null:
		_buzz_db = lerpf(tuning.buzz_db_min, tuning.buzz_db_max, _strength)
		_buzz.volume_db = _buzz_db
		if _on and not _buzz.playing:
			_buzz.play()
		elif not _on and _buzz.playing:
			_buzz.stop()


## One burst: both spots spray as many sparks as the strength gives, the flash lights.
func _burst() -> void:
	var count := lerpf(tuning.sparks_min, tuning.sparks_max, _strength)
	for sp in _sparks:
		sp.amount_ratio = clampf(count / float(maxi(sp.amount, 1)), 0.01, 1.0)
		sp.restart()
	_last_burst = _clock
	_flash_left = tuning.flash_seconds
	_next_burst = _clock + lerpf(tuning.burst_slowest, tuning.burst_fastest, _strength)


## The angry rumble under the voice: from `rumble_db_min` to `rumble_db_max` by the anger times the wiggle.
func _rumbling() -> void:
	if _rumble == null or tuning == null:
		return
	var level := clampf(angry * wiggle, 0.0, 1.0) if lit else 0.0
	_rumble_db = lerpf(tuning.rumble_db_min, tuning.rumble_db_max, level)
	_rumble.volume_db = _rumble_db
	if level > 0.001 and not _rumble.playing:
		_rumble.play()
	elif level <= 0.001 and _rumble.playing:
		_rumble.stop()


## Whether the effects show now (any damage), and the strength they have.
func broken_on() -> bool:
	return _on


func broken_strength() -> float:
	return _strength


## Whether a burst of sparks is flying (inside its lifetime).
func sparking() -> bool:
	return not _sparks.is_empty() and _clock - _last_burst < _sparks[0].lifetime


func buzzing() -> bool:
	return _buzz != null and _buzz.playing


func buzz_db() -> float:
	return _buzz_db


func rumbling() -> bool:
	return _rumble != null and _rumble.playing


func rumble_db() -> float:
	return _rumble_db


## Whether the flash of a burst is lit.
func flashing() -> bool:
	return _flash_left > 0.0
