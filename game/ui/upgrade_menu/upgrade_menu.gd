## The Upgrade menu the Old Tree opens (docs/architecture/economy.md "The Upgrade menu", Q2613: the old
## grid): one page over the play view, the title "The Old Tree" with the Coins and Drawers counters (the
## HUD's scene), the Personal and House sections side by side, the close key. Built from the Upgrades
## folder (Upgrades.listed()) when first opened, again when which Upgrades show changes (co-op only ones
## are left out alone, Q1357); refreshed while open.
##
## While open the player's input is frozen and the mouse is free; the world runs on. Esc, a pad's B or the
## close key shuts it. A click asks `buy`; the Host's refusal shakes the button and says why (as any
## refusal, with `refuse`); a purchase plays `buy`. The pad's route is the old true grid (UM:177-229).
class_name UpgradeMenu
extends CanvasLayer

signal opened
signal closed

const SECTION := preload("res://game/ui/upgrade_menu/upgrade_section.tscn")
const CANCEL := &"ui_cancel"

@export var tuning: UpgradeMenuTuning = preload("res://game/ui/upgrade_menu/upgrade_menu_tuning.tres")

## The Upgrades it shows and buys from (the level's), and whose: this machine's player.
var upgrades: Upgrades = null
var player: Player = null

## The buttons by Upgrade id.
var _buttons: Dictionary[StringName, UpgradeButton] = {}
## The sections, left to right.
var _sections: Array[UpgradeSection] = []
## The ids the sections were built with.
var _built: Array[StringName] = []
var _mouse_before := Input.MOUSE_MODE_VISIBLE

@onready var _sections_box: HBoxContainer = %Sections
@onready var _counters: MoneyCounters = %Counters
@onready var _close: CloseButton = %Close
@onready var _tip: UpgradeTip = %Tip


func _ready() -> void:
	visible = false
	_tip.visible = false
	_close.pressed.connect(close)
	set_process(false)


func is_open() -> bool:
	return visible


## Opens over the game for `buyer` (this machine's player), on `levels`: built if need be, refreshed,
## the mouse free, the player's input held; on the first button when a pad is in use.
func open(levels: Upgrades, buyer: Player) -> void:
	if visible or levels == null or buyer == null:
		return
	if upgrades != levels:
		if upgrades != null and is_instance_valid(upgrades):
			upgrades.bought.disconnect(_on_bought)
			upgrades.refused.disconnect(_on_refused)
		upgrades = levels
		upgrades.bought.connect(_on_bought)
		upgrades.refused.connect(_on_refused)
	player = buyer
	_counters.for_player = buyer
	_counters.holds_back = buyer.hud().get_node_or_null(^"CoinFlight") as CoinFlight
	visible = true
	_rebuild_if_changed()
	refresh()
	set_process(true)
	_mouse_before = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.set_input_blocked(true)
	Sounds.play(&"menu_open")
	if PadFocus.pad_used and not _buttons.is_empty():
		_first_button().key.grab_focus()
	opened.emit()


func close() -> void:
	if not visible:
		return
	visible = false
	set_process(false)
	_tip.visible = false
	for b: UpgradeButton in _buttons.values():
		b.put_out()
	var f := get_viewport().gui_get_focus_owner() if get_viewport() != null else null
	if f != null:
		f.release_focus()
	Input.mouse_mode = _mouse_before
	if player != null and is_instance_valid(player):
		player.set_input_blocked(false)
	Sounds.play(&"menu_close")
	closed.emit()


## The button of the Upgrade whose id is `id`, or null (a case reads and clicks it).
func button(id: StringName) -> UpgradeButton:
	return _buttons.get(id)


## The tip card.
func tip() -> UpgradeTip:
	return _tip


## The close key.
func close_key() -> Button:
	return _close.key()


## Every button from the Upgrades now (a setter runs only when its value changed).
func refresh() -> void:
	if upgrades == null:
		return
	var me := _me()
	for b: UpgradeButton in _buttons.values():
		var u := b.upgrade
		var lv := upgrades.level(u, me)
		var price := u.price_after(lv)
		var locked := price >= 0 and not upgrades.is_open(u, me)
		b.show_state(lv, price, u.stat == null, locked, price >= 0 and upgrades.shown_funds(u, me) < price)
	if _tip.visible and _tip.upgrade != null:
		_tip.fill(_tip.upgrade, upgrades, me, _currency_of(_tip.upgrade))


func _process(_delta: float) -> void:
	_rebuild_if_changed()
	refresh()
	_place_tip()


## Esc or a pad's B shuts it before the ESC menu hears it.
func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(CANCEL):
		get_viewport().set_input_as_handled()
		close()


# --- Building ------------------------------------------------------------------------------------

## The Upgrades shown here now, by id.
func _shown_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for u in Upgrades.listed():
		if upgrades.shown(u):
			out.append(u.id())
	return out


func _rebuild_if_changed() -> void:
	var ids := _shown_ids()
	if ids == _built:
		return
	_built = ids
	for s in _sections:
		_sections_box.remove_child(s)
		s.queue_free()
	_sections.clear()
	_buttons.clear()
	for of: Upgrade.Section in [Upgrade.Section.PERSONAL, Upgrade.Section.HOUSE]:
		var ups: Array[Upgrade] = []
		for u in Upgrades.listed():
			if u.section == of and ids.has(u.id()):
				ups.append(u)
		if ups.is_empty():
			continue
		var section := SECTION.instantiate() as UpgradeSection
		_sections_box.add_child(section)
		var currency := _currency(of == Upgrade.Section.HOUSE)
		for b in section.fill(of, ups, currency):
			_buttons[b.upgrade.id()] = b
			b.chosen.connect(_on_chosen)
			b.lit_changed.connect(_on_lit)
		_sections.append(section)
	_link_grid()


## The pad's route as a true grid: Left and Right walk a row and cross to the other section's same row
## at its ends; Up and Down go to the nearest button of the row above or below; the last row's Down is
## the close key, whose Up is the last section's bottom row; every other edge stays put.
func _link_grid() -> void:
	var close_key := _close.key()
	var last: Button = null
	for s in _sections.size():
		var grid: Array = _sections[s].rows
		for r in grid.size():
			var row: Array = grid[r]
			for i in row.size():
				var b: Button = (row[i]["button"] as UpgradeButton).key
				var col := int(row[i]["col"])
				_set_links(b,
						_at_row(grid, r - 1, col) if r > 0 else b,
						_at_row(grid, r + 1, col) if r < grid.size() - 1 else close_key,
						(row[i - 1]["button"] as UpgradeButton).key if i > 0 else (_edge(s - 1, r, true) if s > 0 else b),
						(row[i + 1]["button"] as UpgradeButton).key if i < row.size() - 1 else (_edge(s + 1, r, false) if s < _sections.size() - 1 else b))
				last = b
	if last != null:
		_set_links(close_key, last, close_key, close_key, close_key)


static func _set_links(c: Control, up: Control, down: Control, left: Control, right: Control) -> void:
	c.focus_neighbor_top = c.get_path_to(up)
	c.focus_neighbor_bottom = c.get_path_to(down)
	c.focus_neighbor_left = c.get_path_to(left)
	c.focus_neighbor_right = c.get_path_to(right)


## The button of `grid`'s row `r` nearest column `col` (the left one on a tie).
static func _at_row(grid: Array, r: int, col: int) -> Button:
	var best: Button = null
	var best_d := 1 << 30
	for e: Dictionary in grid[r]:
		var d := absi(int(e["col"]) - col)
		if d < best_d:
			best_d = d
			best = (e["button"] as UpgradeButton).key
	return best


## Where Left or Right leaves into section `s` at row `r`: its row (its last when it has fewer), its last
## button going left and its first going right.
func _edge(s: int, r: int, last: bool) -> Button:
	var grid: Array = _sections[s].rows
	var row: Array = grid[mini(r, grid.size() - 1)]
	return (row[row.size() - 1 if last else 0]["button"] as UpgradeButton).key


func _first_button() -> UpgradeButton:
	var row: Array = _sections[0].rows[0]
	return row[0]["button"] as UpgradeButton


# --- Buying --------------------------------------------------------------------------------------

func _on_chosen(b: UpgradeButton) -> void:
	if upgrades != null and visible:
		upgrades.ask_buy(b.upgrade, _me())


func _on_bought(by: int, _upgrade: Upgrade) -> void:
	if by == _me() and visible:
		Sounds.play(&"buy")
	if visible:
		refresh()


## The Host refused this player: the button shakes and the refusal shows (and buzzes) as any refusal.
func _on_refused(by: int, upgrade: Upgrade, says: String) -> void:
	if by != _me() or not visible:
		return
	var b := button(upgrade.id()) if upgrade != null else null
	if b != null:
		b.shake()
	if says != "" and player != null:
		player.say(says)
	else:
		Sounds.play(&"refuse")


# --- The tip card --------------------------------------------------------------------------------

func _on_lit(b: UpgradeButton, lit: bool) -> void:
	if lit and visible:
		_tip.fill(b.upgrade, upgrades, _me(), _currency_of(b.upgrade))
		_tip.visible = true
		_place_tip()
	elif _tip.upgrade == b.upgrade:
		_tip.visible = false


## Keeps the card beside its button, on the side with room, inside the screen.
func _place_tip() -> void:
	if not _tip.visible or _tip.upgrade == null or not _buttons.has(_tip.upgrade.id()):
		return
	_tip.size = Vector2(tuning.tip_width, 0.0)
	var rect := _buttons[_tip.upgrade.id()].get_global_rect()
	var screen := _tip.get_viewport_rect().size
	var at := Vector2(rect.end.x + tuning.tip_gap, rect.position.y)
	if at.x + _tip.size.x > screen.x:
		at.x = rect.position.x - tuning.tip_gap - _tip.size.x
	at.y = clampf(at.y, tuning.tip_margin, maxf(tuning.tip_margin, screen.y - _tip.size.y - tuning.tip_margin))
	_tip.global_position = at


func _currency_of(u: Upgrade) -> Currency:
	return _currency(u.is_house())


func _currency(house: bool) -> Currency:
	if upgrades == null or upgrades.bank == null:
		return null
	return upgrades.bank.drawers_currency if house else upgrades.bank.coins_currency


func _me() -> int:
	return player.player_id() if player != null and is_instance_valid(player) else Parts.HOST
