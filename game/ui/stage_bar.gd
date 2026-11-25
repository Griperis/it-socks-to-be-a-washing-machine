## The Stage bar on the HUD (core/82; docs/architecture/stages.md "The Stage bar"): the old panel
## at the top centre with the Collection icons of the bar's Cabinets stacked on its left, then a
## label over a track. It shows one `StageBarPhase` of the run's StagePlan at a time:
## `goal_phase` while a node of the group `GOAL_GROUP` says the First wash is pending, `after_phase`
## once the machine is fixed (the old fold into the Laundry day's counter), else `stage_phase`.
## It shows what the run's state says and decides nothing; it is hidden in a level with no run, and
## redraws only when what it would show changed.
##
## A phase's numbers come from the provider of the phase's `source` (group `StageBarPhase.SOURCES`):
## `bar_numbers()` gives the two last numbers of its text and the optional `bar_words()` the
## arguments before them; the optional `bar_collections()` gives a CABINETS phase its icons. A
## provider may emit `bar_changed` when its numbers move.
class_name StageBar
extends PanelContainer

## Nodes in this group answer `goal_pending() -> bool`: true while the First wash is still to come
## (core/72's), among those in the run's level. None there: the run starts at `stage_phase`.
const GOAL_GROUP := &"stage_bar_goal"

## The sound of the fold (placeholder: the old rig's `pop`, Q1620), played as it begins.
const FOLD_SOUND := &"pop"

## One icon of the stack: a TextureRect scene (core/111).
const ICON := preload("res://game/ui/ui_icon.tscn")

@export var tuning: StageBarTuning

## A fold into another phase began.
signal folded

## How many times the bar was drawn again (a case reads that nothing changes it needlessly).
var redraws := 0
## How many Stages the bar reset for (a new Stage's drain and refill).
var resets := 0
## How many folds into another phase began.
var folds := 0

@onready var _icons: Control = %Icons
@onready var _label: Label = %Label
@onready var _track: Panel = %Track
@onready var _fill: ColorRect = %Fill

var _stages: Stages = null
var _phase: StageBarPhase = null
var _stage_index := -1
var _text := ""
var _ratio := 0.0
var _keys: Array[String] = []
var _sig := ""
var _key: Array = []
var _fill_tween: Tween = null
var _fold_tween: Tween = null
var _pop_tween: Tween = null


func _ready() -> void:
	if tuning == null:
		tuning = StageBarTuning.new()
	offset_top = tuning.top_gap
	_track.custom_minimum_size = tuning.track_size
	_fill.color = tuning.fill_colour
	_fill.position = Vector2(tuning.fill_inset, tuning.fill_inset)
	_fill.size = Vector2(0.0, tuning.track_size.y - 2.0 * tuning.fill_inset)
	visible = false


func _process(_delta: float) -> void:
	if _stages != null and not is_instance_valid(_stages):
		_stages = null
	if _stages == null:
		_stages = get_tree().get_first_node_in_group(Stages.GROUP) as Stages
		if _stages == null:
			if visible:
				_hide()
			return
	if _stages.parts != null and not _stages.parts.applied.is_connected(_on_applied):
		_stages.parts.applied.connect(_on_applied)
	var key := [_stages.stage, _stages.phase, _goal_pending()]
	if key != _key:
		_key = key
		refresh()


## The phase on show, or null.
func phase() -> StageBarPhase:
	return _phase if visible else null


## The label's text ("" while hidden).
func text() -> String:
	return _text if visible else ""


## The fill's share (0 to 1) it shows or moves to.
func ratio() -> float:
	return _ratio


## The icons' keys on show, left to right.
func icon_keys() -> Array[String]:
	return _keys.duplicate()


## Whether the track shows.
func track_shown() -> bool:
	return _track.visible


## Whether a phase change is playing.
func folding() -> bool:
	return _fold_tween != null and _fold_tween.is_valid()


## Whether the First wash is still to come, by the group's nodes in the run's level (as Stages asks its own).
func _goal_pending() -> bool:
	var root := _stages.level() if _stages != null and _stages.is_inside_tree() else null
	for node in get_tree().get_nodes_in_group(GOAL_GROUP):
		if root != null and not root.is_ancestor_of(node):
			continue
		if node.has_method(&"goal_pending") and bool(node.call(&"goal_pending")):
			return true
	return false


func _on_applied(_ev: Dictionary) -> void:
	refresh()


func _on_bar_changed() -> void:
	refresh()


## The phase the run is in now, or null for none.
func _wanted() -> StageBarPhase:
	if _stages == null or _stages.plan == null:
		return null
	if _goal_pending():
		return _stages.plan.goal_phase
	if _stages.stage < 0:
		return null
	if _stages.phase == Stages.Phase.FIXED:
		return _stages.plan.after_phase
	return _stages.plan.stage_phase


## The provider of `phase`'s numbers, or null.
func _provider(phase: StageBarPhase) -> Node:
	if phase == null or phase.source == &"":
		return null
	for node in get_tree().get_nodes_in_group(StageBarPhase.SOURCES):
		if node.has_method(&"bar_source") and node.call(&"bar_source") == phase.source:
			if node.has_signal(&"bar_changed") and not node.is_connected(&"bar_changed", _on_bar_changed):
				node.connect(&"bar_changed", _on_bar_changed)
			return node
	return null


## The label, the fill's share and the icons of `phase` from its provider.
func _words(phase: StageBarPhase) -> Dictionary:
	var out := {"text": phase.text, "ratio": 0.0, "keys": [] as Array[String]}
	var provider := _provider(phase)
	if provider != null:
		var n: Vector2i = provider.call(&"bar_numbers")
		var args: Array = provider.call(&"bar_words") if provider.has_method(&"bar_words") else []
		args = args + [n.x, n.y]
		out["text"] = phase.text % args
		out["ratio"] = clampf(float(n.x) / maxf(float(n.y), 1.0), 0.0, 1.0)
	var keys: Array[String] = []
	match phase.icons:
		StageBarPhase.Icons.CABINETS:
			if provider != null and provider.has_method(&"bar_collections"):
				for c: Variant in provider.call(&"bar_collections"):
					keys.append(UiIcons.or_simple(String(c)))
		StageBarPhase.Icons.GIVEN:
			keys.append(UiIcons.or_simple(phase.icon))
	out["keys"] = keys
	return out


## Shows what the run's state says now; nothing is drawn again when it says what it did.
func refresh() -> void:
	var wanted := _wanted()
	if wanted == null:
		if visible:
			_hide()
		return
	var plan := _stages.plan
	var w := _words(wanted)
	var stage_now: int = _stages.stage if wanted == plan.stage_phase else -1
	var sig := "%d|%s|%s|%d|%s" % [wanted.get_instance_id(), w["text"], w["ratio"], stage_now, w["keys"]]
	if sig == _sig and visible:
		return
	_sig = sig
	redraws += 1
	var from := _phase
	var was_shown := visible
	_phase = wanted
	if not was_shown or not is_inside_tree():
		_kill()
		_draw_phase(w)
		visible = true
		return
	if wanted != from:
		if wanted == plan.after_phase and from == plan.stage_phase:
			_fold()
		else:
			_kill()
			_draw_phase(w)
			if from == plan.goal_phase:
				_pop_in()
		return
	if folding():
		return  # the fold draws what is current when it lands
	if stage_now != _stage_index and _stage_index >= 0 and wanted == plan.stage_phase:
		resets += 1
		_stage_index = stage_now
		_set_text(w)
		_set_icons(w["keys"], true)
		_move_fill(0.0, w["ratio"], true)
	else:
		_stage_index = stage_now
		_set_text(w)
		if w["keys"] != _keys:
			_set_icons(w["keys"], false)
		_move_fill(_ratio, w["ratio"], false)


func _hide() -> void:
	_kill()
	visible = false
	_phase = null
	_sig = ""
	_text = ""
	_stage_index = -1


func _kill() -> void:
	for t: Tween in [_fill_tween, _fold_tween, _pop_tween]:
		if t != null:
			t.kill()
	_fill_tween = null
	_fold_tween = null
	_pop_tween = null
	scale = Vector2.ONE
	modulate = Color.WHITE


## The whole phase at once (no animation).
func _draw_phase(w: Dictionary) -> void:
	_stage_index = _stages.stage if _phase == _stages.plan.stage_phase else -1
	_track.visible = _phase.track
	_set_text(w)
	_set_icons(w["keys"], false)
	_ratio = w["ratio"]
	_fill.size.x = _full() * _ratio


func _full() -> float:
	return tuning.track_size.x - 2.0 * tuning.fill_inset


func _set_text(w: Dictionary) -> void:
	_text = w["text"]
	_label.text = _text


## The icons stacked, `pop`ping in one after another once the drain is over.
func _set_icons(keys: Array[String], pop: bool) -> void:
	_keys = keys.duplicate()
	for c in _icons.get_children():
		_icons.remove_child(c)
		c.queue_free()
	var side := float(tuning.icon_size)
	_icons.custom_minimum_size = Vector2.ZERO if keys.is_empty() \
			else Vector2(side + tuning.icon_overlap * (keys.size() - 1), side)
	_icons.visible = not keys.is_empty()
	for i in keys.size():
		var icon := ICON.instantiate() as TextureRect
		icon.texture = UiIcons.texture(keys[i])
		icon.size = Vector2(side, side)
		icon.position = Vector2(tuning.icon_overlap * i, 0.0)
		icon.pivot_offset = icon.size * 0.5
		_icons.add_child(icon)
		if pop and is_inside_tree():
			icon.scale = Vector2.ZERO
			var t := create_tween()
			t.tween_interval(tuning.reset_time + tuning.icon_pop_gap * i)
			t.tween_property(icon, "scale", Vector2.ONE, tuning.icon_pop_time) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## The fill to share `to`; a reset drains it from where it stood first.
func _move_fill(from: float, to: float, reset: bool) -> void:
	if _fill_tween != null:
		_fill_tween.kill()
		_fill_tween = null
	_ratio = to
	var full := _full()
	if not is_inside_tree() or (is_equal_approx(from, to) and not reset):
		_fill.size.x = full * to
		return
	_fill_tween = create_tween()
	if reset:
		_fill_tween.tween_property(_fill, "size:x", 0.0, tuning.reset_time).set_trans(Tween.TRANS_CUBIC)
	_fill_tween.tween_property(_fill, "size:x", full * to, tuning.fill_time)


## The bar pops in from nothing (the first Stage after the goal).
func _pop_in() -> void:
	pivot_offset = size * 0.5
	scale = Vector2.ZERO
	_pop_tween = create_tween()
	_pop_tween.tween_property(self, "scale", Vector2.ONE, tuning.fold_pop_time) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## The old fold (HUD:325-360): the fill runs full, the bar glows and shrinks into itself with a
## back ease, then the new phase pops in.
func _fold() -> void:
	folds += 1
	_kill()
	Sounds.play(FOLD_SOUND)
	folded.emit()
	pivot_offset = size * 0.5
	_fold_tween = create_tween()
	_fold_tween.tween_property(_fill, "size:x", _full(), tuning.fold_fill_time)
	_fold_tween.tween_property(self, "modulate", tuning.glow_colour, tuning.fold_glow_time)
	_fold_tween.tween_property(self, "scale", Vector2.ONE * tuning.shrink_to, tuning.fold_shrink_time) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_fold_tween.tween_callback(_land_fold)
	_fold_tween.tween_property(self, "scale", Vector2.ONE, tuning.fold_pop_time) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## The fold's middle: the new phase is drawn while the bar is out of sight; the pop shows it.
func _land_fold() -> void:
	modulate = Color.WHITE
	scale = Vector2.ZERO
	var wanted := _wanted()
	if wanted == null:
		_hide()
		return
	_phase = wanted
	_draw_phase(_words(wanted))
	pivot_offset = size * 0.5
