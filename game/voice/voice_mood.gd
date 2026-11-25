## One mood of a speaker's acting (core/84): its pose (lean, brows), its glow, and how the brows act on top
## of it while the voice is on. A line's `moods` keys name these by `id`. The numbers of `brows.py` (Q1374,
## Q1410) and `make_washing_machine_face.py` MOODS of the old game, kept in `<speaker>_acting.tres`.
##
## The brow acting, per brow, as Vector3s (x: by the voice's loudness 0-1, y: by a flick, z: by a flick on
## a "!" segment, times `VoiceActing.exclaim_flick`): tilt in degrees (+ lowers the inner end, a frown),
## raise in metres up the face. The `beat_` pair adds to the one brow whose turn it is (flicks alternate
## sides, the left first).
class_name VoiceMood
extends Resource

@export var id: StringName = &""
## Degrees, + leans forward onto the front feet.
@export var lean := 0.0
## The pose: (tilt degrees, raise metres) per brow.
@export var brow_left := Vector2.ZERO
@export var brow_right := Vector2.ZERO
@export var brow_left_tilt := Vector3.ZERO
@export var brow_left_raise := Vector3.ZERO
@export var brow_right_tilt := Vector3.ZERO
@export var brow_right_raise := Vector3.ZERO
@export var beat_tilt := Vector3.ZERO
@export var beat_raise := Vector3.ZERO
## The drum light while this mood speaks (linear colour) and its strength.
@export var glow_colour := Color(0.9, 0.75, 0.5)
@export var glow_energy := 0.6
