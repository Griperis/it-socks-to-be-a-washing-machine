## The Final screen (run-ends.md "The Final screen"; the old ending_screen.gd): over the frozen game, on the one
## Theme, the title, a FinalColumn per player in the game at the end side by side, the World totals from
## final_totals.tres, the unlock strip (empty, hidden: batch B fills it) and Continue. `open(summary)` starts it:
## every column pops its Pairs on its schedule, the scores count up, then the totals show and count up, the finale
## bursts over every column with its sting, and Continue waits. Any key, mouse button or pad button before the
## totals show skips this machine's screen to them. The player is held, the mouse free, and Esc does not open the
## Esc menu over it. Continue only says it was pressed (`continue_pressed`): what it does is the owner's (core/97).
class_name FinalScreen
extends CanvasLayer

## The screen is up (after `open`) and gone (after `close`; not `closed`: it is no dialogue with an Esc key).
signal opened
signal taken_down
## Continue was pressed.
signal continue_pressed

const COLUMN := preload("res://game/ui/final_screen/final_column.tscn")
## The group whose nodes are told `set_input_blocked(bool)` while a menu is open (the Esc menu's).
const INPUT_GROUP := &"local_input"
## The gap between the panel and the window's edge.
const MARGIN := 20.0
const COLUMN_GAP := 14.0
## What the title, the column heads, the totals and Continue take of the window's height, kept off the stages.
const CHROME := 430.0
const MIN_STAGE_H := 160.0
const MAX_STAGE_H := 760.0
const TOTAL_CELL := preload("res://game/ui/final_screen/final_total_cell.tscn")
const GOLD := Color(1.0, 0.8, 0.4)

@export var tuning: FinalScreenTuning
@export var totals: FinalTotalList
@export var catalogue: DesignCatalogue

## The columns on show, in order.
var columns: Array[FinalColumn] = []
## Seconds the screen has run.
var clock := 0.0

var _summary: FinalSummary = null
var _open := false
var _totals_at := 0.0
var _totals_shown := false
var _count_t := 0.0
var _finale := false
var _waves := 0
var _wave_in := 0.0
var _silent := false
var _mouse_before := Input.MOUSE_MODE_VISIBLE
var _total_labels: Array[Label] = []
var _rng := RandomNumberGenerator.new()

@onready var _panel: Control = %Panel
@onready var _title: Label = %Title
@onready var _row: HBoxContainer = %Columns
@onready var _totals_row: HBoxContainer = %Totals
@onready var _unlocked: Control = %Unlocked
@onready var _continue: Button = %Continue


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.visible = false
	_continue.pressed.connect(_on_continue)
	set_process(false)


func is_open() -> bool:
	return _open


## Shows the screen for `summary`: a column per entry of its columns, the totals under them.
func open(summary: FinalSummary) -> void:
	_summary = summary
	_clear()
	var view := get_viewport().get_visible_rect().size
	var count := maxi(summary.columns.size(), 1)
	var col_w := floorf((view.x - 2.0 * MARGIN - 80.0 - COLUMN_GAP * (count - 1)) / count)
	var stage := Vector2(col_w - 2.0 * FinalColumn.PAD, clampf(view.y - CHROME, MIN_STAGE_H, MAX_STAGE_H))
	var end := 0.0
	for entry: Dictionary in summary.columns:
		var c := COLUMN.instantiate() as FinalColumn
		c.setup(entry, stage, tuning, catalogue)
		c.cue.connect(_on_cue)
		_row.add_child(c)
		columns.append(c)
		end = maxf(end, c.end)
	_totals_at = end + tuning.totals_delay
	for total in totals.totals:
		var cell := TOTAL_CELL.instantiate() as VBoxContainer
		(cell.get_child(0) as Label).text = total.caption
		var value := cell.get_child(1) as Label
		value.name = "Total_%s" % total.source
		_total_labels.append(value)
		_totals_row.add_child(cell)
	_totals_row.modulate.a = 0.0
	_continue.visible = false
	_panel.visible = true
	_open = true
	_mouse_before = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().call_group(INPUT_GROUP, &"set_input_blocked", true)
	_show_totals(0.0)
	set_process(true)
	opened.emit()


## Takes the screen down, the game's input and mouse back.
func close() -> void:
	if not _open:
		return
	_open = false
	set_process(false)
	_panel.visible = false
	_clear()
	Input.mouse_mode = _mouse_before
	get_tree().call_group(INPUT_GROUP, &"set_input_blocked", false)
	taken_down.emit()


func _process(delta: float) -> void:
	advance(delta)


## Moves the screen on by `delta` seconds (its own _process; tests call it too).
func advance(delta: float) -> void:
	if not _open:
		return
	clock += delta
	for c in columns:
		c.advance(clock, delta, _silent)
	if clock >= _totals_at:
		if not _totals_shown:
			_totals_shown = true
			_continue.visible = true
			_totals_row.modulate.a = 1.0
			_focus_continue()
		_count_t += delta
		_show_totals(_count_t / maxf(tuning.count_time, 0.01))
		if not _finale and _count_t >= tuning.count_time:
			_start_finale()
	_step_finale(delta)


## Skips to the World totals (Q1844): every Pair in place, the scores final, no patter of sounds for what
## flashes by.
func skip() -> void:
	if not _open or _totals_shown:
		return
	_silent = true
	for c in columns:
		c.finish()
	clock = _totals_at
	advance(0.0)
	_silent = false
	_count_t = tuning.count_time
	advance(0.002)


func totals_shown() -> bool:
	return _totals_shown


func finale_started() -> bool:
	return _finale


## The totals as the screen writes them, in order ("Play time 0:05:00").
func total_texts() -> Array[String]:
	var out: Array[String] = []
	for i in _total_labels.size():
		out.append("%s %s" % [totals.totals[i].caption, _total_labels[i].text])
	return out


## The Continue key (for a case that presses it).
func continue_button() -> Button:
	return _continue


## The strip of unlocked Collections: empty and hidden until batch B fills it.
func unlocked_strip() -> Control:
	return _unlocked


func _input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()  # the Esc menu never opens over the screen
	if _totals_shown:
		return
	var key := event as InputEventKey
	var pressed := (key != null and key.pressed and not key.echo) \
			or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed) \
			or (event is InputEventJoypadButton and (event as InputEventJoypadButton).pressed)
	if pressed:
		skip()
		get_viewport().set_input_as_handled()


func _on_cue(event: StringName) -> void:
	if not _silent:
		Sounds.play(event)


func _on_continue() -> void:
	continue_pressed.emit()


func _focus_continue() -> void:
	if _continue.is_inside_tree() and Input.get_connected_joypads().size() > 0:
		_continue.grab_focus()


## The totals count up over `k` (0 to 1) of their count_time.
func _show_totals(k: float) -> void:
	var f := 1.0 - pow(1.0 - clampf(k, 0.0, 1.0), 3.0)
	for i in _total_labels.size():
		var total := totals.totals[i]
		var v := int(roundf(float(_summary.values.get(total.source, 0)) * f))
		_total_labels[i].text = total.text_of(v)


func _start_finale() -> void:
	_finale = true
	_waves = 3
	_wave_in = 0.0
	_rng.seed = 7919
	if not _silent:
		Sounds.play(&"final_sting")


## Three waves of bursts over every column during finale_time, in the players' colours toward gold.
func _step_finale(delta: float) -> void:
	if not _finale or _waves <= 0:
		return
	_wave_in -= delta
	if _wave_in > 0.0:
		return
	_wave_in = tuning.finale_time / 3.0
	_waves -= 1
	for c in columns:
		var metres := c.stage_metres()
		for i in 3:
			var at := Vector3((_rng.randf() - 0.5) * metres.x * 0.8, 0.0, (_rng.randf() - 0.5) * metres.y * 0.8)
			c.burst(at, tuning.confetti, c.colour.lerp(GOLD, float(i) / 2.0), metres.x * 0.35)


func _clear() -> void:
	for child in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	for child in _totals_row.get_children():
		_totals_row.remove_child(child)
		child.queue_free()
	columns.clear()
	_total_labels.clear()
	clock = 0.0
	_count_t = 0.0
	_totals_shown = false
	_finale = false
	_waves = 0
	_silent = false
