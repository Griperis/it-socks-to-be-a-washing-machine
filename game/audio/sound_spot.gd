## A spot that plays one sound event when a player uses it (the zoo's Sounds station: a button per
## event, heard where it stands). A world event plays from the spot's node, a flat one flat. It holds
## no state and decides nothing: it is looks and sound on this machine only, never a Command.
class_name SoundSpot
extends Part

## The catalogue name it plays.
@export var event: StringName = &""


func use(_by: int) -> void:
	play()


## Plays the event now, from where this spot stands when it is a world event.
func play() -> void:
	var e := Sounds.catalogue.find(event)
	if e != null and e.spatial:
		Sounds.play_at(event, (get_parent() as Node3D).global_position)
	else:
		Sounds.play(event)


func decide(_cmd: Command) -> Dictionary:
	return refuse("wrong")
