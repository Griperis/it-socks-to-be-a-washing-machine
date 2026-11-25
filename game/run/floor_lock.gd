## A floor's lock (docs/architecture/stages.md "The floor locks"; the old LockedDoor and Padlock): the plank
## door or the baby gate that shuts the way up to floor `floor` until the Stage that opens it. The scene's
## leaf is an `Openable` child of its root (`locked`, shown through the Looks next to it); this Part is the
## padlock, a thing of its own to aim at: outlined, reading "Please the washing machine" with no key. It
## keeps no state: `Stages` writes the leaf's `{open true, locked false}` in the answer that opens the floor,
## and every machine shows it here (looks only): the padlock pops (`unlock` in the Looks), the chain drops,
## the lamps of the floor come on, the leaf swings (the leaf's own `open`). A state arriving whole (a
## load, a join) shows the end pose at once, no sound. The gate's blocker (up to the ceiling) and the
## padlock's aim body are on only while it is locked.
class_name FloorLock
extends Part

## The door has no blocker (the code skips a null one).
const WIRING_OPTIONAL := ["blocker"]
## Every FloorLock is in this group (Stages finds the locks of a floor by it).
const GROUP := &"floor_locks"
## The animation of the padlock and chain, in a Looks' AnimationPlayer of its own (the leaf's is `open`).
const UNLOCK := &"unlock"
## What the crosshair reads on the padlock: it needs no key, the washing machine opens it.
const HINT := "Please the washing machine"
const POP_SOUND := &"padlock_pop"
const CHAIN_SOUND := &"chain_drop"
const SWING_SOUND := &"lock_door_open"
## How far over the leaf's floor the swing's sound comes from, metres (old: 1 m up).
const SWING_SOUND_UP := 1.0
## The share of the pop time at which the chain's sound plays (old: 75 %).
const CHAIN_SOUND_AT := 0.75
## The nodes of a Looks that the lock keys (the models of assets/10 have them too).
const PADLOCK_NODE := "padlock"
## Where the leaf's Openable and the Looks are, from this part (a child of the Padlock node).
const LEAF := ^"../../Openable"
const LOOKS := ^"../../Looks"

## The floor this lock shuts the way up to (an index into HouseLights.floors, as Stage.floor).
@export_range(0, 16, 1) var floor := 1
@export var tuning: FloorLockTuning
## The padlock's aim body (layer 1 for the aim ray; off once the lock is open).
@export var aim: StaticBody3D
## The padlock's outline (meshes of the Looks' `padlock` node, found at ready).
@export var outline: Outline
## The gate's blocker up to the ceiling (null for a door); off once the lock is open.
@export var blocker: StaticBody3D

var _leaf: Openable
var _unlock_player: AnimationPlayer
var _tween: Tween = null


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	_leaf = get_node_or_null(LEAF) as Openable
	var looks := get_node_or_null(LOOKS)
	if looks != null:
		for node in looks.find_children("*", "AnimationPlayer", true, false):
			if (node as AnimationPlayer).has_animation(UNLOCK):
				_unlock_player = node as AnimationPlayer
		var padlock := looks.find_child(PADLOCK_NODE, true, false) as Node3D
		if padlock != null:
			if aim != null:
				aim.global_position = padlock.global_position  # its rest pose, before any animation plays
			if outline != null:
				var paths: Array[NodePath] = []
				for mesh in padlock.find_children("*", "MeshInstance3D", true, false):
					paths.append(outline.get_path_to(mesh))
				outline.meshes = paths
	if _unlock_player != null and tuning != null:
		_unlock_player.speed_scale = _unlock_player.get_animation(UNLOCK).length / maxf(tuning.pop_time * 1.9, 0.01)
	if _leaf != null:
		_leaf.shown.connect(_on_leaf_shown)
		var open_player := _leaf.animator()
		if open_player != null and tuning != null:
			open_player.speed_scale = open_player.get_animation(Openable.ANIMATION).length \
					/ maxf(tuning.swing_delay + tuning.swing_time, 0.01)


## The leaf, whose state is the lock's.
func leaf() -> Openable:
	return _leaf


## Whether the way up is shut now.
func is_locked() -> bool:
	return _leaf != null and _leaf.locked


func prompt_title() -> String:
	return HINT


func prompt_has_key() -> bool:
	return false


## The crosshair rests on the padlock only while it hangs there.
func aimable() -> bool:
	return is_locked()


## There is nothing to press: the washing machine opens it.
func decide(_cmd: Command) -> Dictionary:
	return refuse("wrong")


## Looks only: shows the leaf's lock. `unlocked`: the turn from locked, with its sounds and lamps.
func _on_leaf_shown(locked: bool, now: bool, unlocked: bool) -> void:
	_stop()
	if aim != null:
		aim.collision_layer = Mess.LAYER_HOUSE if locked else 0
	if blocker != null:
		blocker.collision_layer = Mess.LAYER_HOUSE if locked else 0
	var lights := _lights()
	if unlocked:
		if lights != null:
			var t := tuning if tuning != null else FloorLockTuning.new()
			lights.reveal(floor, t.lights_fade, t.lights_hold, t.lights_fade_out)
		_play_unlock()
	else:
		if lights != null:
			lights.set_level_dark(floor, locked)
		_pose(locked)


## The unlock's end pose (open and gone) or its start (locked, in place), at once.
func _pose(locked: bool) -> void:
	if _unlock_player == null:
		return
	_unlock_player.play(UNLOCK)
	_unlock_player.seek(0.0 if locked else _unlock_player.get_animation(UNLOCK).length, true)
	_unlock_player.pause()


## The padlock springs off, the chain drops, the leaf swings after its delay (its own animation holds it).
func _play_unlock() -> void:
	if _unlock_player != null:
		_unlock_player.play(UNLOCK)
	var t := tuning if tuning != null else FloorLockTuning.new()
	_sound(POP_SOUND, _node_spot(PADLOCK_NODE))
	if not is_inside_tree():
		return
	_tween = create_tween()
	_tween.tween_callback(func() -> void: _sound(CHAIN_SOUND, _node_spot("chain"))).set_delay(t.pop_time * CHAIN_SOUND_AT)
	_tween.tween_callback(func() -> void: _sound(SWING_SOUND, _leaf_spot() + Vector3.UP * SWING_SOUND_UP)) \
			.set_delay(maxf(t.swing_delay - t.pop_time * CHAIN_SOUND_AT, 0.0))


func _stop() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null


func _sound(event: StringName, at: Vector3) -> void:
	if is_inside_tree():
		Sounds.play_at(event, at)


## Where a node of the Looks stands now (the rest spot for a node already gone: the leaf's).
func _node_spot(node_name: String) -> Vector3:
	var looks := get_node_or_null(LOOKS)
	var node := looks.find_child(node_name, true, false) as Node3D if looks != null else null
	return node.global_position if node != null else _leaf_spot()


func _leaf_spot() -> Vector3:
	var thing := _leaf.get_parent() as Node3D if _leaf != null else null
	return thing.global_position if thing != null else Vector3.ZERO


func _lights() -> HouseLights:
	if not is_inside_tree():
		return null
	return get_tree().get_first_node_in_group(HouseLights.GROUP) as HouseLights
