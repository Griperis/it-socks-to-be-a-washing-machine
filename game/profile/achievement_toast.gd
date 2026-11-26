## The Achievement toast (core/145, docs/architecture/wardrobe.md "Achievements"; Q1695): a cream card at the top
## right of the HUD (the icon at 48 px, or the shared placeholder; the caption "Achievement"; the title). It slides
## in (the `slide_in` clip), stays `toast_seconds`, slides out (`slide_out`), and the next queued one follows; the
## `achievement` chime plays as each slides in. It is held, the clip and the stay stopped where they are, while the
## HUD is hidden (a cutscene, the drum: the HUD's own hide rule) or the Final screen shows. Authored in nodes; the
## clips run on its own AnimationPlayer, stepped from here so a hold stops them.
class_name AchievementToast
extends Control

enum Phase { IDLE, IN, STAY, OUT }

const IN_CLIP := &"slide_in"
const OUT_CLIP := &"slide_out"
const SOUND := &"achievement"

@export var tuning: AchievementTuning

## What it does now.
var phase := Phase.IDLE
## The one on the card now (null while idle).
var shown: Achievement = null

var _queue: Array[Achievement] = []
var _stay_left := 0.0

@onready var _card: Control = $Slot/Card
@onready var _icon: TextureRect = $Slot/Card/Row/Icon
@onready var _title: Label = $Slot/Card/Row/Text/Title
@onready var _slide: AnimationPlayer = $Slide


func _enter_tree() -> void:
	add_to_group(Achievements.TOAST_GROUP)


func _ready() -> void:
	if tuning == null:
		tuning = AchievementTuning.new()
	_slide.play(&"RESET")
	_slide.advance(0.0)
	# What was earned before this HUD was there (at the link's start) is shown now.
	var achievements := Achievements.of(self)
	if achievements != null:
		achievements.deliver.call_deferred()


## Queues `a` to slide in after the ones before it.
func queue(a: Achievement) -> void:
	_queue.append(a)


## How many wait behind the one shown.
func waiting() -> int:
	return _queue.size()


## The title on the card while it shows ("" while idle).
func shown_title() -> String:
	return _title.text if phase != Phase.IDLE else ""


## The card's picture now.
func shown_icon() -> Texture2D:
	return _icon.texture


## Whether the card is on screen (sliding or staying, and the HUD not hidden).
func card_on_screen() -> bool:
	return _card.is_visible_in_tree()


## Whether it is held now: the HUD hidden, or the Final screen up.
func held() -> bool:
	if not is_visible_in_tree():
		return true
	var runtime := LevelRuntime.of(self)
	return runtime != null and runtime.final_screen != null and runtime.final_screen.is_open()


func _process(delta: float) -> void:
	if held():
		return
	match phase:
		Phase.IDLE:
			if not _queue.is_empty():
				_start(_queue.pop_front())
		Phase.IN:
			_step(delta)
			if not _slide.is_playing():
				phase = Phase.STAY
				_stay_left = tuning.toast_seconds
		Phase.STAY:
			_stay_left -= delta
			if _stay_left <= 0.0:
				phase = Phase.OUT
				_play(OUT_CLIP)
		Phase.OUT:
			_step(delta)
			if not _slide.is_playing():
				phase = Phase.IDLE
				shown = null


func _start(a: Achievement) -> void:
	shown = a
	_title.text = a.title
	_icon.texture = a.icon if a.icon != null else tuning.placeholder_icon
	phase = Phase.IN
	_play(IN_CLIP)
	Sounds.play(SOUND)


## Plays clip `clip` from its start at the speed that makes it `slide_seconds` long.
func _play(clip: StringName) -> void:
	var length := _slide.get_animation(clip).length
	_slide.play(clip, -1.0, length / maxf(tuning.slide_seconds, 0.01))
	_slide.advance(0.0)


func _step(delta: float) -> void:
	_slide.advance(delta)
