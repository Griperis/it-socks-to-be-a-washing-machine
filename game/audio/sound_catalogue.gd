## Every SoundEvent of the game in one resource (sound_catalogue.tres), and the numbers all of them
## share. A name this does not know is a fault, not a silence: Sounds says so, and a test reads the
## game's code for names that are not here.
class_name SoundCatalogue
extends Resource

@export var events: Array[SoundEvent] = []
## How far a play's pitch may stray: 1 plus or minus this share (the old game's 0.05).
@export_range(0.0, 0.5, 0.01) var pitch_jitter := 0.05 # placeholder: the designer's number (ported from the old game, audio.json pitch_jitter)
## A world sound's distance fade: full level inside `unit_size` metres, gone at `max_distance`.
@export_range(0.5, 20.0, 0.5, "suffix:m") var unit_size := 3.0 # placeholder: the designer's number (ported from the old game, audio.json world_unit_size)
@export_range(1.0, 100.0, 1.0, "suffix:m") var max_distance := 20.0 # placeholder: the designer's number (ported from the old game, audio.json world_max_distance)
## The things that muffle a sound behind them while shut: scene files of entities with an Openable
## (the room Door). How much: the Muffled* buses of default_bus_layout.tres (-9 dB, 900 Hz low-pass).
@export var muffling_scenes: Array[String] = []

var _by_name: Dictionary[StringName, SoundEvent] = {}


## The event of this name, or null.
func find(name: StringName) -> SoundEvent:
	if _by_name.size() != events.size():
		_by_name.clear()
		for e in events:
			_by_name[e.event] = e
	return _by_name.get(name)


func has(name: StringName) -> bool:
	return find(name) != null


## Every event name, in the catalogue's order.
func names() -> Array[StringName]:
	var out: Array[StringName] = []
	for e in events:
		out.append(e.event)
	return out
