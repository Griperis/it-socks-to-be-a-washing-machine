## A button on the Day station's board (core/160; docs/architecture/day-and-exterior.md "How it is authored"): a
## key's or an hour notch's button sets the station's hour to its `hour`, the speed switch runs the station's day at
## x1 or x60, the lock switch locks the station's "locked" level (its lamp stays off, core/80). Its use asks
## `switch` and the Host answers with the station Day's hour (and its own `on`), so every machine shows the same.
class_name DayZooSwitch
extends Part

## What a switch does.
enum Does { SET_HOUR, SPEED, LOCK }

const SWITCH := &"switch"
## Only the lock switch has lamps.
const WIRING_OPTIONAL := ["lights"]
## How much faster the speed switch runs the day.
const FAST := 60.0
## Its words. placeholder: zoo wording
const SPEED_TITLES: Array[String] = ["Speed x1", "Speed x60"]
const LOCK_TITLES: Array[String] = ["Lock the level", "Unlock the level"]

## The station's day it sets.
@export var day: Day
@export var does := Does.SET_HOUR
## The hour a SET_HOUR button sets.
@export var hour := 12.0
## The lamps whose `level` the lock switch locks.
@export var lights: HouseLights
@export var level := 1
## How far from it a player may stand to use it, in metres.
@export var reach := 4.0

@export_group("State")
## The speed switch: fast; the lock switch: locked.
@export var on := false
@export_group("")


func prompt_title() -> String:
	match does:
		Does.SPEED:
			return SPEED_TITLES[int(on)]
		Does.LOCK:
			return LOCK_TITLES[int(on)]
	return "Set %s" % hour_text(hour)


## "07:30" for 7.5.
static func hour_text(h: float) -> String:
	var minutes := roundi(fposmod(h, 24.0) * 60.0) % (24 * 60)
	@warning_ignore("integer_division")
	return "%02d:%02d" % [minutes / 60, minutes % 60]


func use(player: int) -> void:
	parts.ask(Command.new(SWITCH, player, id, {}))


func accepts() -> Dictionary[StringName, Dictionary]:
	return {SWITCH: {"args": {}, "rate": 4}}


func decide(cmd: Command) -> Dictionary:
	if cmd.kind != SWITCH or day == null:
		return refuse("wrong")
	if not parts.near(cmd.by, get_parent(), reach):
		return refuse("far")
	match does:
		Does.SET_HOUR:
			return {"ok": true, "changes": {day.id: {"hour": fposmod(hour, 24.0)}}}
		Does.SPEED:
			# The hour is written with the speed, so every machine runs on from the same hour.
			return {"ok": true, "changes": {id: {"on": not on}, day.id: {"hour": day.shown_hour()}}}
	return grant({"on": not on})


func _show(_now: bool) -> void:
	match does:
		Does.SPEED:
			if day != null:
				day.speed = FAST if on else 1.0
		Does.LOCK:
			if lights != null:
				lights.set_level_dark(level, on)
	var label := get_node_or_null(^"../Label") as Label3D
	if label != null and does != Does.SET_HOUR:
		label.text = prompt_title()
