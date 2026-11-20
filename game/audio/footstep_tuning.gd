## When the player's body is heard: one .tres beside it, edited in the inspector.
class_name FootstepTuning
extends Resource

## Metres walked per footstep (sprinting covers it faster).
@export_range(0.3, 4.0, 0.1, "suffix:m") var step_distance := 1.4 # placeholder: the designer's number (ported from the old game, audio.json step_distance)
## The falling speed a landing needs to be heard.
@export_range(0.5, 20.0, 0.5, "suffix:m/s") var land_speed := 3.0 # placeholder: the designer's number (ported from the old game, audio.json land_speed)
