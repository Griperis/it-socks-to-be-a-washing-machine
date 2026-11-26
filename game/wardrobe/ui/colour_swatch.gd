## One Player colour on the Wardrobe page's colour row (core/142, the old WardrobeView's swatch): a round key in
## the colour with the name of who has it under it. The picked one is ringed and raised (Theme variation
## `ColourSwatchPicked`); a taken one is greyed toward `taken_grey`, faded, not clickable and named after its
## holder ("Taken" when the name is unknown). A click says `picked`. The look is the scene's and the Theme's; the
## page fills it (show_state()).
class_name ColourSwatch
extends VBoxContainer

signal picked(index: int)

const PLAIN := &"ColourSwatch"
const PICKED := &"ColourSwatchPicked"
const TAKEN := "Taken"

## Which Player colour it is (an index into CoopTuning.colours).
var index := 0
## Whether another present player has it now.
var taken := false

@onready var _key: Button = %Key
@onready var _who: Label = %Who


func _ready() -> void:
	_key.pressed.connect(func() -> void: picked.emit(index))


## In `colour`; `is_picked` this player's; `holder` the name of who has it, "" when nobody else does.
func show_state(colour: Color, is_picked: bool, holder: String, tuning: WardrobeTuning) -> void:
	taken = holder != ""
	_key.theme_type_variation = PICKED if is_picked else PLAIN
	_key.self_modulate = colour.lerp(tuning.taken_grey, tuning.taken_mix) if taken else colour
	_key.modulate.a = tuning.taken_alpha if taken else 1.0
	_key.disabled = taken
	_key.focus_mode = Control.FOCUS_NONE if taken else Control.FOCUS_ALL
	if taken and _key.has_focus():
		_key.release_focus()
	_who.text = holder
	_key.tooltip_text = holder


## Whether it shows as this player's.
func is_picked() -> bool:
	return _key.theme_type_variation == PICKED


## The name under it ("" for a free one).
func holder() -> String:
	return _who.text


## The key (the pad's stop; a test clicks it).
func key() -> Button:
	return _key
