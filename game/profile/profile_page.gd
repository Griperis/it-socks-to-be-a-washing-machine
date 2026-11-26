## The Profile page (core/147, docs/architecture/wardrobe.md "The Profile page", Q2681): the player's name, the five
## Lifetime tallies in a row of numbers over captions, then every Achievement of the list in a grid (earned in full
## colour with its date, unearned greyed, a hidden unearned one "???") and "%d / %d earned". Batch B ships no
## Achievements list (Q2687), so then it shows the tallies and "0 / 0 earned". Opened from the title's Profile key and
## the ESC menu's Profile entry; Esc or the close key shuts it. Set `profile` (and, for a test, `list`) before it
## enters the tree. The look is the scene's; code instances a cell per tally and per Achievement and fills it.
class_name ProfilePage
extends Control

signal closed

const TALLY_CELL := preload("res://game/profile/tally_cell.tscn")
const ACHIEVEMENT_CELL := preload("res://game/profile/achievement_cell.tscn")
const TUNING := preload("res://game/profile/achievement_tuning.tres")
## The caption of each Lifetime tally.
const CAPTIONS: Dictionary[String, String] = {
	PlayerProfile.PAIRS_SHELVED: "Pairs",
	PlayerProfile.COINS_EARNED: "Coins",
	PlayerProfile.COLLECTIONS_COMPLETED: "Collections",
	PlayerProfile.FLOORS_COMPLETED: "Floors",
	PlayerProfile.GAMES_FINISHED: "Games",
}

## Whose page it is (its tallies and earned Achievements); null reads `Worlds.profile()`.
var profile: PlayerProfile = null
## The Achievements shown; null reads the folder's list (Achievements.all()).
var list: Array[Achievement] = []
## Whether `list` was set by the caller.
var has_list := false

var _tally_cells: Array[TallyCell] = []
var _cells: Array[AchievementCell] = []

@onready var _name: Label = %PlayerName
@onready var _tallies: HBoxContainer = %Tallies
@onready var _grid: GridContainer = %Achievements
@onready var _count: Label = %Count
@onready var _close: CloseButton = %Close


func _ready() -> void:
	_close.pressed.connect(close)
	if profile == null:
		profile = Worlds.profile()
	if not has_list:
		list = Achievements.all()
	var shown := profile.shown_name()
	_name.text = shown if shown != "" else PlayerProfile.NAME
	for t in PlayerProfile.TALLIES:
		var tally_cell := TALLY_CELL.instantiate() as TallyCell
		_tallies.add_child(tally_cell)
		tally_cell.fill(CAPTIONS[t], profile.tally(t))
		_tally_cells.append(tally_cell)
	var earned := 0
	for a in list:
		var at := 0
		if profile.achievements.has(String(a.id)):
			earned += 1
			at = maxi(1, int(profile.achievements[String(a.id)]))
		var cell := ACHIEVEMENT_CELL.instantiate() as AchievementCell
		_grid.add_child(cell)
		cell.fill(a, at, TUNING.placeholder_icon)
		_cells.append(cell)
	_count.text = "%d / %d earned" % [earned, list.size()]
	_close.key().grab_focus()


## The tally cells, in the row's order.
func tally_cells() -> Array[TallyCell]:
	return _tally_cells


## The Achievement cells, in the list's order.
func cells() -> Array[AchievementCell]:
	return _cells


## "3 / 10 earned".
func count_text() -> String:
	return _count.text


func close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
