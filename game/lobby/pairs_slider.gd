## The "Pairs per Drawer" slider of a New Game (docs/architecture/stages.md "Saves, joins and the Lobby", Q668,
## Q2586, core/91): debug builds only, 1 to 25, its value beside its name. It says only what was moved
## (`moved`); the Lobby asks the Host's answer and shows it back with show_value(). In the Host's World drawer
## while "New game" is chosen (a Guest's reads it, unable to move it) and on Solo's New Game page; the value
## rides the launch into the run's `start` (`Stages.PAIRS_ARG`).
class_name PairsSlider
extends VBoxContainer

## The player moved it to `value`.
signal moved(value: int)

@onready var _caption: Label = %Caption
@onready var _slider: HSlider = %Slider


## Whether the slider is in this build at all (never in a release build).
static func in_build() -> bool:
	return OS.is_debug_build()


func _ready() -> void:
	_slider.min_value = 1
	_slider.max_value = StagePlan.PAIRS_AT
	_slider.step = 1
	_slider.value_changed.connect(_on_changed)
	show_value(StagePlan.PAIRS_AT, true)


## Shows `value`; `editable`: the slider can be moved (the Host's, Solo's). Says nothing back.
func show_value(value: int, editable: bool) -> void:
	_slider.set_value_no_signal(clampi(value, 1, StagePlan.PAIRS_AT))
	_slider.editable = editable
	_slider.focus_mode = Control.FOCUS_ALL if editable else Control.FOCUS_NONE
	_caption.text = LobbyWords.PAIRS % value


## The value shown.
func value() -> int:
	return int(_slider.value)


## The slider itself (the pad's route, a test's drag).
func slider() -> HSlider:
	return _slider


func _on_changed(v: float) -> void:
	_caption.text = LobbyWords.PAIRS % int(v)
	moved.emit(int(v))
