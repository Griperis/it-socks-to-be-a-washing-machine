## Where a speaker's voice sounds from, and the speaker's face (core/85, V2): the script on the root of a
## speaker's Looks. `Voices` plays a line's sound at this node and calls `act(take)`, which plays the take's
## baked acting Animation on the Looks' AnimationPlayer from its start; `rest()` goes back to the basic pose.
## The acting's tracks are paths from this node (`face_rig:door_hinge`, `.:wiggle`, ...), so the four
## properties below are what its `.:` tracks key. A Looks that wants more (the washer's) extends this.
## Looks only: it never writes state.
class_name VoiceSource
extends Node3D

## The group every source is in, so `Voices` finds a speaker's source for a cutscene line.
const GROUP := &"voice_source"
## The library the takes' acting is played from.
const LIBRARY := &"voice"
const ACTING := &"acting"

## Whose face this is.
@export var speaker: VoiceSpeaker
## Plays the acting; found under this node when left empty.
@export var player: AnimationPlayer

## What the acting keys (VoiceActing.wiggle_property and the others): body motion 0-1, the angry mood's
## share, the glow inside the drum.
var wiggle := 0.0
var angry := 0.0
var glow_colour := Color.BLACK
var glow_energy := 0.0
## The take now acting, or null at rest.
var acting_take: VoiceTake = null


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	if player == null:
		player = _find_player(self)


## Plays `take`'s acting from its start (a take with none leaves the face still).
func act(take: VoiceTake) -> void:
	acting_take = take
	if player == null or take == null or take.acting == null:
		return
	var library: AnimationLibrary
	if player.has_animation_library(LIBRARY):
		library = player.get_animation_library(LIBRARY)
	else:
		library = AnimationLibrary.new()
		player.add_animation_library(LIBRARY, library)
	if library.has_animation(ACTING):
		library.remove_animation(ACTING)
	library.add_animation(ACTING, take.acting)
	player.play("%s/%s" % [LIBRARY, ACTING])


## Back to the basic pose: the acting stops and what it keyed goes to rest.
func rest() -> void:
	acting_take = null
	wiggle = 0.0
	angry = 0.0
	glow_energy = 0.0
	if player != null and player.has_animation_library(LIBRARY) \
			and player.get_animation_library(LIBRARY).has_animation(ACTING):
		# The acting's first keys are the basic pose: seek there, then let it go.
		player.play("%s/%s" % [LIBRARY, ACTING])
		player.seek(0.0, true)
		player.stop()
		player.get_animation_library(LIBRARY).remove_animation(ACTING)


## Whether the take is acting now.
func is_acting() -> bool:
	return player != null and player.is_playing() and acting_take != null


func _find_player(node: Node) -> AnimationPlayer:
	for child in node.get_children():
		if child is AnimationPlayer:
			return child as AnimationPlayer
		var found := _find_player(child)
		if found != null:
			return found
	return null
