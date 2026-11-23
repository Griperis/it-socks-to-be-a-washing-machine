## What makes a SoundEvent a sampled instrument (the piano, assets/07): each clip is one recorded
## note, `roots` its measured MIDI note in the same order. Sounds.play_note() plays a note from the
## clip whose root is nearest, pitched to it, on a voice of the instrument's own, rings it `hold`
## seconds at full and fades it out over `release`. Edited in the inspector, inside the catalogue.
class_name Instrument
extends Resource

## Each clip's measured MIDI note (60 is middle C), in the order of the event's clips.
@export var roots: PackedFloat32Array = PackedFloat32Array()
## How many notes may ring at once; when more are played the oldest is cut.
@export_range(1, 32, 1) var voices := 12 # placeholder: the designer's number (ported from the old game, piano.json voices)
## Seconds a note rings at full before it is let go, and the seconds it then fades out over (the
## sampled notes last 4.5 s, so the two stay under that).
@export_range(0.0, 5.0, 0.01, "suffix:s") var hold := 1.6 # placeholder: the designer's number (ported from the old game, piano.json note_s)
@export_range(0.01, 5.0, 0.01, "suffix:s") var release := 1.2 # placeholder: the designer's number (ported from the old game, piano.json release_s)
## How quickly a note still ringing fades when the same note is played again.
@export_range(0.01, 1.0, 0.01, "suffix:s") var restrike := 0.08 # placeholder: the designer's number (ported from the old game, piano.json restrike_s)
## How far (m) it is heard at full level before it fades with distance (the world sounds' is the
## catalogue's unit_size).
@export_range(0.5, 20.0, 0.5, "suffix:m") var unit_size := 3.0 # placeholder: the designer's number (ported from the old game, piano.json unit_size)


## The index of the clip that plays MIDI `note` best (its root nearest), or -1 with no roots.
func nearest(note: float) -> int:
	var best := -1
	for i in roots.size():
		if best < 0 or absf(roots[i] - note) < absf(roots[best] - note):
			best = i
	return best


## The pitch scale that tunes clip `index` to MIDI `note`.
func pitch_of(index: int, note: float) -> float:
	return pow(2.0, (note - roots[index]) / 12.0)
