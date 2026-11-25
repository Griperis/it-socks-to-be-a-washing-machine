## How the bake turns a take into its speaker's acting Animation (core/84): `<speaker>_acting.tres`. The
## washer's carries the old `tools/voiceover/voiceover.py` door curve and `brows.py` acting numbers; the
## defaults here are the washer's, every one a placeholder as in the old tuning. A bone left empty gets no
## track (the Old Tree has no brows), a property left empty likewise.
##
## The tracks are paths from the Looks root (the AnimationPlayer's root): `<rig>:<bone>` bone poses and
## `.:<property>` values. A bone track keys the whole pose, so each bone's rest here must be the Looks
## skeleton's rest (the washer's Looks contract, docs/architecture/washer.md).
class_name VoiceActing
extends Resource

@export_group("Rig")
## The Skeleton3D, from the Looks root.
@export var rig := NodePath("face_rig")

@export_group("Mouth")
## The door-mouth opens with the voice's loudness (lip sync, Q1372).
@export var mouth_bone: StringName = &"door_hinge"
@export var mouth_rest := Transform3D(Basis(), Vector3(-0.262, 0.42, 0.318)) # placeholder: the old rig's door pivot (make_washing_machine_face.py DOOR_PIVOT, in Godot's axes)
## About the upright hinge, its free edge swinging out to the front.
@export var mouth_axis := Vector3.DOWN
@export_range(0.0, 120.0, 0.5, "suffix:deg") var mouth_open := 40.0 # placeholder: the old DOOR_OPEN_DEG
## The loudness window, its smoothing up and down (1 = none), the gate under which it stays shut (a share
## of the take's peak) and the keys a second.
@export_range(0.005, 0.1, 0.001, "suffix:s") var window := 0.02 # placeholder: the old voiceover.py WINDOW_SEC
@export_range(0.01, 1.0, 0.01) var attack := 0.6 # placeholder: the old voiceover.py ATTACK
@export_range(0.01, 1.0, 0.01) var release := 0.25 # placeholder: the old voiceover.py RELEASE
@export_range(0.0, 0.5, 0.01) var gate := 0.08 # placeholder: the old voiceover.py GATE
@export_range(10, 60, 1) var keys_per_second := 30 # placeholder: the old voiceover.py KEYS_PER_SEC

@export_group("Brows")
@export var brow_left_bone: StringName = &"brow_left_pivot"
@export var brow_right_bone: StringName = &"brow_right_pivot"
@export var brow_left_rest := Transform3D(Basis(), Vector3(-0.115, 0.729, 0.311)) # placeholder: the old rig's BROW_CENTRE, in Godot's axes
@export var brow_right_rest := Transform3D(Basis(), Vector3(0.115, 0.729, 0.311)) # placeholder: the old rig's BROW_CENTRE, in Godot's axes
## The left brow tilts about this axis (the right about its opposite), + lowering the inner end.
@export var brow_tilt_axis := Vector3.FORWARD
@export var brow_raise_axis := Vector3.UP
## The brows stay off the door ring and under the control panel: (min, max) metres and degrees.
@export var raise_range := Vector2(-0.022, 0.06) # placeholder: the old brows.py RAISE
@export var tilt_range := Vector2(-22.0, 40.0) # placeholder: the old brows.py TILT
## A flick on a "!" segment is this much bigger.
@export var exclaim_flick := 1.5 # placeholder: the old brows.py bang
## A "?" segment ends raised: over `question_ramp` s from `question_start` s before its end.
@export var question_raise := 0.02 # placeholder: the old brows.py question raise
@export var question_tilt := -8.0 # placeholder: the old brows.py question tilt
@export var question_start := 0.7 # placeholder: the old brows.py
@export var question_ramp := 0.3 # placeholder: the old brows.py
## A segment still counts (for "!" and "?") this long past its end.
@export var segment_linger := 0.25 # placeholder: the old brows.py

@export_group("Flicks")
## The take's typical loud level: this share of its voiced keys (over `voiced`), at least `loud_floor`.
@export var loud_percentile := 0.9 # placeholder: the old brows.py loud()
@export var loud_floor := 0.25 # placeholder: the old brows.py loud()
@export var voiced := 0.05 # placeholder: the old brows.py voiced level
## A flick is a loudness peak at `onset_level` of the loud level that rose by `onset_rise` of it within
## `onset_lookback` s, at least `onset_gap` s after the last.
@export var onset_level := 0.75 # placeholder: the old brows.py onsets()
@export var onset_rise := 0.4 # placeholder: the old brows.py onsets()
@export var onset_lookback := 0.2 # placeholder: the old brows.py onsets() (6 keys)
@export var onset_gap := 0.22 # placeholder: the old brows.py onsets()
## A flick rises over `flick_attack` s and fades by e every `flick_decay` s, for `flick_length` s.
@export var flick_attack := 0.05 # placeholder: the old brows.py _acting()
@export var flick_decay := 0.18 # placeholder: the old brows.py _acting()
@export var flick_length := 0.8 # placeholder: the old brows.py _acting()

@export_group("Lean")
@export var lean_bone: StringName = &"lean"
@export var lean_rest := Transform3D.IDENTITY # placeholder: the old rig's lean bone at the origin
@export var lean_axis := Vector3.RIGHT
## The lean pivots on the front feet's outer edge (forward) or the back feet's (back).
@export var front_feet := Vector3(0.0, 0.0, 0.248) # placeholder: the old FRONT_FEET, in Godot's axes
@export var back_feet := Vector3(0.0, 0.0, -0.268) # placeholder: the old BACK_FEET, in Godot's axes

@export_group("Moods")
## The moods a line may name (the old angry, calming, entitled, surprised; their numbers are placeholders,
## the old ones).
@export var moods: Array[VoiceMood] = []
## Seconds from one mood to the next.
@export var mood_blend := 0.4 # placeholder: the old brows.py BLEND
## The mood whose share keys `angry_property` (the washer's rumble and sparks).
@export var angry_mood: StringName = &"angry"

@export_group("Body")
## 0-1 body motion while the voice is on (Q1412): gaps under `wiggle_hold` s bridged, eased in and out.
@export var wiggle_ease_in := 0.12 # placeholder: the old brows.py wiggle()
@export var wiggle_ease_out := 0.3 # placeholder: the old brows.py wiggle()
@export var wiggle_hold := 0.15 # placeholder: the old brows.py wiggle()
## The glow eases to the mood's colour at this rate a second.
@export var glow_ease := 6.0 # placeholder: the old washer_face.gd glow lerp
@export var wiggle_property: StringName = &"wiggle"
@export var angry_property: StringName = &"angry"
@export var glow_colour_property: StringName = &"glow_colour"
@export var glow_energy_property: StringName = &"glow_energy"


## The mood named `id`, or null.
func mood(id: StringName) -> VoiceMood:
	for m: VoiceMood in moods:
		if m != null and m.id == id:
			return m
	return null


## The mood names, for messages.
func mood_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for m: VoiceMood in moods:
		if m != null:
			out.append(String(m.id))
	return out
