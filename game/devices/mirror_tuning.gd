## The wall mirrors' reflection (assets/07, Q2505; the old mirror.json after graphics/02). Edited in
## the inspector (mirror_tuning.tres beside it). Whether a real reflection is drawn at all is the
## graphics preset's `mirror` (Low: off).
class_name MirrorTuning
extends Resource

## The reflection's pixels over the glass's height (its width follows the glass's shape).
@export_range(16, 2048, 1, "suffix:px") var size := 256 # placeholder: the designer's number (ported from the old game, mirror.json size)
## Metres it reflects.
@export_range(0.5, 50.0, 0.5, "suffix:m") var far := 6.0 # placeholder: the designer's number (ported from the old game, mirror.json far)
## Metres from the glass beyond which it stops reflecting (0: no limit).
@export_range(0.0, 50.0, 0.5, "suffix:m") var reach := 4.5 # placeholder: the designer's number (ported from the old game, mirror.json range)
## 0 off, 2 for 2x.
@export_enum("Off:0", "2x:2") var msaa := 0 # placeholder: the designer's number (ported from the old game, mirror.json msaa)
## The reflection redraws every n-th frame while in view (1: every frame).
@export_range(1, 10, 1) var update_every := 3 # placeholder: the designer's number (ported from the old game, mirror.json update_every)
## Whether the lamps cast shadows in the reflection (the sun still does).
@export var lamp_shadows := false # placeholder: the old game's (mirror.json lamp_shadows)
## Whether the Mess Socks show in it.
@export var mess_socks := false # placeholder: the old game's (mirror.json mess_socks, Q2505)
