## The opener's reveal of a present (core/138, docs/architecture/gifts.md "Opening"; the old gift_preview.gd), on
## the opener's machine alone. A CanvasLayer authored in nodes (`gift_reveal.tscn`): a 520 x 520 preview stage
## (core/128's `preview_stage.tscn`, its camera brought 1.75 m in front of the piece) raised 40 px over the middle,
## the same box (1.6 x, yaw 0.5) playing the Looks' `open` clip, a turntable the piece pops in on after the pop (the
## `pop` clip, then `spin` or, for a Trail, `spin_trail`), and a Caption of three Labels (name, Rarity, "New in your
## Wardrobe" or "Already yours: +%d Coins"). Code only fills it.
##
## It stays PresentTuning.preview seconds after the pop, then closes; any click or pad face button after the pop
## closes it sooner, and during the shake a click does nothing; either way the click goes no further (GiftClicks).
## The player may walk the whole time. A new reveal replaces one still open.
class_name GiftReveal
extends CanvasLayer

signal closed

const OPEN := &"open"
const POP := &"pop"
const SPIN := &"spin"
const SPIN_TRAIL := &"spin_trail"
const RESET := &"RESET"
## The shake's length the Looks' `open` clip is keyed at (its pop comes at this second).
const KEYED_SHAKE := 1.0
## The Caption's words (the old placeholder wording, GP:113).
const NEW_WORDS := "New in your Wardrobe"
const REFUND_WORDS := "Already yours: +%d Coins"
## The Caption's outline: the box's bow colour darkened this much.
const OUTLINE_DARKEN := 0.6
## The clicks that close it besides the left and right buttons' actions: any mouse button, a pad face button.
const FACE_BUTTONS := JOY_BUTTON_Y
const CLICK_BUTTONS: Array[MouseButton] = [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]
const CLICK_ACTIONS: Array[StringName] = [&"pick", &"drop_throw"]

@export var tuning: PresentTuning
## The player whose clicks it takes (its machine's own; Presents sets it).
var player: Player

## What it shows: {"piece", "refund", "collection"}, or {} when shut.
var showing: Dictionary = {}

var _clock := 0.0
var _shake := 1.0
var _revealed := false
var _clicked := false
var _tint := Color.WHITE

@onready var _root: Control = $Root
@onready var _stage: PreviewStage = $Root/Stage
@onready var _spin: Node3D = $Root/Stage/Stage/Turntable/Spin
@onready var _box: Node3D = $Root/Stage/Stage/Box
@onready var _box_anim: AnimationPlayer = $Root/Stage/Stage/Box/AnimationPlayer
@onready var _caption: VBoxContainer = $Root/Caption
@onready var _name: Label = $Root/Caption/Name
@onready var _rarity: Label = $Root/Caption/Rarity
@onready var _line: Label = $Root/Caption/Line
@onready var _pop: AnimationPlayer = $PopPlayer
@onready var _spinner: AnimationPlayer = $SpinPlayer


func _ready() -> void:
	if tuning == null:
		tuning = PresentTuning.new()
	process_physics_priority = GiftClicks.BEFORE_PLAYER


## Shows `piece` from a present of Collection `collection`: new in the Wardrobe, or already owned and paying
## `refund` Coins. A Socks piece stands on feet in `tint` (the opener's colour). The box shakes first.
func open(piece: StringName, refund: int, collection: StringName, tint := Color.WHITE) -> void:
	close()
	showing = {"piece": piece, "refund": refund, "collection": collection}
	_clock = 0.0
	_shake = maxf(tuning.shake, 0.01)
	_revealed = false
	_clicked = false
	_tint = tint
	var col := Collections.of(collection)
	var outline := col.bow_colour().darkened(OUTLINE_DARKEN) if col != null else Color.BLACK
	_name.text = Wardrobe.piece_name(piece)
	var p := Wardrobe.of(piece)
	_rarity.text = String(WardrobePiece.Rarity.keys()[p.rarity]).capitalize() if p != null else ""
	_rarity.visible = _rarity.text != ""
	_line.text = (REFUND_WORDS % refund) if refund > 0 else NEW_WORDS
	for label: Label in [_name, _rarity, _line]:
		label.add_theme_color_override(&"font_outline_color", outline)
	_caption.visible = false
	if col != null:
		Present.wrap_looks(_box, col, tuning)
	_box.visible = true
	_box_anim.speed_scale = KEYED_SHAKE / _shake
	_box_anim.stop()
	_box_anim.play(OPEN)
	_pop.play(RESET)
	_spinner.play(RESET)
	_root.visible = true


## Whether it shows (the shake included).
func is_open() -> bool:
	return not showing.is_empty()


## Whether the piece shows yet (the box has popped).
func revealed() -> bool:
	return _revealed


## The Caption's three lines as shown ("" for a hidden one), for tests and shots.
func caption_lines() -> PackedStringArray:
	return PackedStringArray([_name.text, _rarity.text if _rarity.visible else "", _line.text])


## The piece on the turntable, or null before the pop.
func piece_node() -> Node3D:
	return _spin.get_child(0) as Node3D if _spin.get_child_count() > 0 else null


## Shuts it at once.
func close() -> void:
	var was := is_open()
	showing = {}
	_revealed = false
	for c: Node in _spin.get_children():
		_spin.remove_child(c)
		c.queue_free()
	_box_anim.stop()
	_box.visible = false
	_caption.visible = false
	_root.visible = false
	if was:
		closed.emit()


func _process(delta: float) -> void:
	if not is_open():
		return
	_clock += delta
	if not _revealed and _clock >= _shake:
		_reveal()
	if _box.visible and not _box_anim.is_playing():
		_box.visible = false
	if _revealed and _clock >= _shake + tuning.preview:
		close()


## The box pops: the piece pops in on the turntable, the Caption shows.
func _reveal() -> void:
	_revealed = true
	var piece: StringName = showing["piece"]
	var node := Wardrobe.preview(piece, _tint)
	node.name = "Piece"
	_spin.add_child(node)
	var p := Wardrobe.of(piece)
	_pop.play(POP)
	_spinner.play(SPIN_TRAIL if p != null and p.slot == WardrobePiece.Slot.TRAIL else SPIN)
	_caption.visible = true


## A mouse button or a pad face button pressed while it shows (the polled actions catch the rest).
func _input(event: InputEvent) -> void:
	if not is_open():
		return
	var mb := event as InputEventMouseButton
	var jb := event as InputEventJoypadButton
	if (mb != null and mb.pressed and mb.button_index in CLICK_BUTTONS) or (jb != null and jb.pressed and jb.button_index <= FACE_BUTTONS):
		_clicked = true
		get_viewport().set_input_as_handled()


## Before the player's tick: a click is taken (it goes no further) and, once the piece shows, closes it.
func _physics_process(_delta: float) -> void:
	if not is_open():
		_clicked = false
		return
	var clicked := _clicked
	_clicked = false
	for action in CLICK_ACTIONS:
		if Input.is_action_just_pressed(action):
			clicked = true
	if not clicked:
		return
	GiftClicks.swallow(player)
	if _revealed:
		close()
