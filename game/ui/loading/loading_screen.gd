## The loading screen (the old card, Q356): the title's dark backdrop, a cream card with a tumbling
## sock, the heading ("The washer bursts open...", "Loading the house...", "Joining...") and a progress
## bar while the wait can tell how far it is; the bar never goes backwards. finish() takes the card
## away and fades the backdrop out over `fade_seconds`, over everything, with no input lock
## (Q1262-Q1265). SceneChanger puts it up; the look is the scene's, on the Theme.
class_name LoadingScreen
extends CanvasLayer

@export var tuning: LoadingTuning

var _time := 0.0
var _fading := false

@onready var _back: ColorRect = %Back
@onready var _card: Control = %Card
@onready var _sock: TextureRect = %Sock
@onready var _heading: Label = %Heading
@onready var _bar: ProgressBar = %Bar


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if tuning == null:
		tuning = LoadingTuning.new()
	_bar.value = 0.0
	_bar.visible = false
	_sock.pivot_offset = _sock.size / 2.0


## What the card says.
func set_heading(text: String) -> void:
	_heading.text = text


func heading() -> String:
	return _heading.text


## How far the wait is, 0 to 1: the bar shows, and never goes back.
func set_progress(ratio: float) -> void:
	_bar.visible = true
	_bar.value = maxf(_bar.value, clampf(ratio, 0.0, 1.0))


## The bar's value now (-1 while no bar shows).
func shown_progress() -> float:
	return _bar.value if _bar.visible else -1.0


## The wait is over: the bar shows full, the card goes, the backdrop fades out and the screen frees
## itself. Nothing under it is held back meanwhile.
func finish() -> void:
	if _fading:
		return
	_fading = true
	if _bar.visible:
		_bar.value = 1.0
	_card.visible = false
	_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween := create_tween()
	tween.tween_property(_back, "modulate:a", 0.0, tuning.fade_seconds)
	tween.tween_callback(queue_free)


func is_fading() -> bool:
	return _fading


func _process(delta: float) -> void:
	_time += delta
	_sock.rotation = _time * tuning.tumble_speed
	_sock.position.y = _sock_rest_y() + sin(_time * tuning.tumble_speed * 0.5) * tuning.bob_px


func _sock_rest_y() -> float:
	return (_sock.get_parent() as Control).size.y * 0.5 - _sock.size.y * 0.5
