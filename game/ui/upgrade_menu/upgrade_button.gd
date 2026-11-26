## One Upgrade's cell on the Upgrade menu's grid (docs/architecture/economy.md "The Upgrade menu"): a holder
## the grid lays out, and the button free inside it so it can lift. The button shows the icon, "level/top"
## and the next price with its currency's icon; locked: greyed, the lock over a dimmed icon; no stat: greyed,
## "Coming soon"; at its top: the gold frame and "MAX"; dearer than the funds: `PriceShort`. Hovered or
## focused it lifts, grows and glows in its section's colour; a refusal shakes it. The looks are the
## Theme's variations (`UpgradeButtonPersonal` / `UpgradeButtonHouse`, with `Off` and `Max`); code only
## fills it.
class_name UpgradeButton
extends Control

## The player clicked it (or pressed it with the pad or Enter).
signal chosen(button: UpgradeButton)
## It lit (hovered or focused) or went out.
signal lit_changed(button: UpgradeButton, lit: bool)

## How it looks now.
const OK := "ok"
const OFF := "off"
const MAX := "max"
const MAX_TEXT := "MAX"
const SOON_TEXT := "Coming soon"

@export var tuning: UpgradeMenuTuning = preload("res://game/ui/upgrade_menu/upgrade_menu_tuning.tres")
## The icon's tint while locked (under the lock) and while greyed for "Coming soon".
@export var locked_tint := Color(0.45, 0.45, 0.45)
@export var off_tint := Color(0.62, 0.62, 0.62)

## The Upgrade it buys.
var upgrade: Upgrade
## How it looks now: OK, OFF (locked or Coming soon) or MAX.
var state := OK
## How many times it has shaken (a case reads it).
var shakes := 0
## Whether it is lit now (hovered or focused).
var lit := false

var _hovered := false
var _focused := false
var _lit_tween: Tween = null
var _shake_tween: Tween = null

@onready var key: Button = %Key
@onready var _glow: Control = %Glow
@onready var _icon: TextureRect = %Icon
@onready var _lock: Control = %Lock
@onready var _level: Label = %Level
@onready var _currency: TextureRect = %Currency
@onready var _price: Label = %Price


func _ready() -> void:
	custom_minimum_size = Vector2.ONE * tuning.cell
	key.pressed.connect(func() -> void: chosen.emit(self))
	key.mouse_entered.connect(_set_hover.bind(true))
	key.mouse_exited.connect(_set_hover.bind(false))
	key.focus_entered.connect(_set_focus.bind(true))
	key.focus_exited.connect(_set_focus.bind(false))


## Shows `u`, paid with the currency whose icon is `currency_icon`.
func setup(u: Upgrade, currency_icon: Texture2D) -> void:
	upgrade = u
	name = String(u.id())
	_icon.texture = u.icon
	_currency.texture = currency_icon
	_glow.theme_type_variation = &"UpgradeGlowHouse" if u.is_house() else &"UpgradeGlowPersonal"


## Shows level `level` of `top`, the next `price`, and whether it is `soon` (no stat), `locked` and
## `short` (dearer than the funds). A setter runs only when its value changed.
func show_state(level: int, price: int, soon: bool, locked: bool, short: bool) -> void:
	var maxed := price < 0
	state = MAX if maxed else (OFF if soon or locked else OK)
	_set_text(_level, "%d/%d" % [level, upgrade.top()])
	_currency.visible = not maxed and not soon
	if maxed:
		_set_text(_price, MAX_TEXT)
		_set_variation(_price, &"PriceMax")
	elif soon:
		_set_text(_price, SOON_TEXT)
		_set_variation(_price, &"UpgradePrice")
	else:
		_set_text(_price, str(price))
		_set_variation(_price, &"PriceShort" if short and not locked else &"UpgradePrice")
	_lock.visible = locked and not maxed
	var tint := locked_tint if locked and not maxed else (off_tint if state == OFF else Color.WHITE)
	if _icon.modulate != tint:
		_icon.modulate = tint
	var look := "UpgradeButton" + ("House" if upgrade.is_house() else "Personal") + ("Max" if state == MAX else ("Off" if state == OFF else ""))
	_set_variation(key, StringName(look))


## The level text ("1/1"), the price text ("30", "MAX", "Coming soon") and its look.
func level_text() -> String:
	return _level.text


func price_text() -> String:
	return _price.text


func price_look() -> StringName:
	return _price.theme_type_variation


## Whether the lock shows over the icon.
func lock_shown() -> bool:
	return _lock.visible


## A quick wobble about its middle: a refusal.
func shake() -> void:
	shakes += 1
	if _shake_tween != null:
		_shake_tween.kill()
	key.pivot_offset = key.size * 0.5
	_shake_tween = create_tween()
	for a in tuning.shake_angles:
		_shake_tween.tween_property(key, "rotation", a, tuning.shake_step)


## Puts its light out at once (the menu closing).
func put_out() -> void:
	_hovered = false
	_focused = false
	_update_lit()


func _set_hover(on: bool) -> void:
	_hovered = on
	_update_lit()


func _set_focus(on: bool) -> void:
	_focused = on
	_update_lit()


## Lit: it lifts, grows about its middle and its glow fades in, over the tuning's time.
func _update_lit() -> void:
	var on := _hovered or _focused
	if on == lit:
		return
	lit = on
	z_index = 1 if on else 0
	key.pivot_offset = key.size * 0.5
	if _lit_tween != null:
		_lit_tween.kill()
	var scale_to := Vector2.ONE * (tuning.grow if on else 1.0)
	var y_to := -tuning.lift if on else 0.0
	if not is_inside_tree():
		key.scale = scale_to
		key.position.y = y_to
		_glow.modulate.a = 1.0 if on else 0.0
	else:
		_lit_tween = create_tween().set_parallel(true)
		_lit_tween.tween_property(key, "scale", scale_to, tuning.glow_time)
		_lit_tween.tween_property(key, "position:y", y_to, tuning.glow_time)
		_lit_tween.tween_property(_glow, "modulate:a", 1.0 if on else 0.0, tuning.glow_time)
	lit_changed.emit(self, on)


static func _set_text(label: Label, text: String) -> void:
	if label.text != text:
		label.text = text


static func _set_variation(c: Control, look: StringName) -> void:
	if c.theme_type_variation != look:
		c.theme_type_variation = look
