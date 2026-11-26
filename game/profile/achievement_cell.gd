## One Achievement on the Profile page (core/147): icon, title, description and, once earned, the date. Earned it is
## in full colour with the date; unearned it is greyed; a hidden one unearned reads "???" with no description
## (Q1693). The look is the scene's; code fills it.
class_name AchievementCell
extends Control

## What a hidden Achievement is called until earned.
const UNKNOWN := "???"
## The tint of an unearned one.
const GREY := Color(0.55, 0.55, 0.55, 0.8)

@onready var _icon: TextureRect = %Icon
@onready var _title: Label = %Title
@onready var _description: Label = %Description
@onready var _date: Label = %Date


## Shows `a`; `earned_at` is the unix time it was earned, or 0 while it is not. `fallback` is the icon of one with none.
func fill(a: Achievement, earned_at: int, fallback: Texture2D) -> void:
	var earned := earned_at > 0
	var secret := a.hidden and not earned
	_icon.texture = a.icon if a.icon != null else fallback
	_title.text = UNKNOWN if secret else a.title
	_description.text = "" if secret else a.description
	_description.visible = not secret
	_date.text = Time.get_date_string_from_unix_time(earned_at) if earned else ""
	_date.visible = earned
	modulate = Color.WHITE if earned else GREY


## The title shown.
func shown_title() -> String:
	return _title.text


## The date shown, or "".
func shown_date() -> String:
	return _date.text if _date.visible else ""


## Whether it is drawn greyed.
func is_greyed() -> bool:
	return modulate != Color.WHITE
