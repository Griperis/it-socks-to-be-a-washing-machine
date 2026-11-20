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
