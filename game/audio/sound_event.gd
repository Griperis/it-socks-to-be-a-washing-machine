## One named sound of the game, edited in the inspector: which clips it may play, how loud, on which
## bus, flat or from where it happens, and whether it loops. Code asks for it by its name
## (Sounds.play / Sounds.play_at); adding or swapping a clip is dropping the file in and adding it
## to `clips` here, with no code change. The catalogue (SoundCatalogue) holds them all.
class_name SoundEvent
extends Resource

## The name code asks for ("pick", "drawer_open", "step_wood").
@export var event: StringName = &""
## One of these plays at random each time, its pitch jittered (SoundCatalogue.pitch_jitter).
@export var clips: Array[AudioStream] = []
## The level of this event on its bus.
@export_range(-40.0, 12.0, 0.5, "suffix:dB") var volume_db := 0.0
## The mixer bus it plays on (default_bus_layout.tres).
@export_enum("SFX", "Ambient", "Music", "UI") var bus := "SFX"
## From where it happens (a world sound: fades with distance, muffled behind a shut Door) or flat
## (the player's own sounds, the UI).
@export var spatial := false
## Plays again as it ends, until stopped (an ambience).
@export var loop := false
## Where the clips came from and what is left to decide, for the person editing.
@export_multiline var note := ""
## The least time between two plays of this event, in seconds: a play sooner than this after the last
## is dropped (a bounce heard 20 times in one tick is one bounce). 0 plays every one.
@export_range(0.0, 2.0, 0.01, "suffix:s") var min_gap := 0.0
@export_group("By strength")
## For a play asked with a strength (a bounce's hit speed, 0 soft to 1 hard): how much quieter than
## `volume_db` the softest is, and the pitch scale of the softest and of the hardest. All at their
## defaults, the strength changes nothing.
@export_range(-40.0, 0.0, 0.5, "suffix:dB") var soft_db := 0.0
@export_range(0.25, 4.0, 0.01) var soft_pitch := 1.0
@export_range(0.25, 4.0, 0.01) var hard_pitch := 1.0
