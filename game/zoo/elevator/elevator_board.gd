## The Elevator station's board, built from the data at load (Q2337): a row lying on the ground per stop of its
## Elevator (letter, floor, the car's floor height there), the tuning's numbers, and every Elevator Upgrade from the
## Upgrades folder (Elevator Repair and what needs it) with its level and its stat now -> top (UpgradeBoard's line).
## A new stop, number or Upgrade shows here with no other change. Looks only.
class_name ElevatorBoard
extends Node3D

const LABEL := preload("res://game/zoo/zoo_label.tscn")
const STOP := "Stop %s: %s, floor %d, the car's floor at %.2f m"
const TUNING := "hatch %.2f s, a floor %.2f s, creak every %.2f s, reach %.2f m, %d seats, exit %.2f m, eyes %.2f m"
const REPAIR := &"elevator_repair"
## How often the Upgrades' levels are read again, in seconds.
const EVERY := 0.5

@export var elevator: Elevator
## The station's Upgrades, whose levels it shows.
@export var upgrades: Upgrades
## The space between two rows, in metres.
@export var row_gap := 0.45

var _upgrade_rows: Dictionary[StringName, Label3D] = {}
var _since := 0.0


func _ready() -> void:
	if elevator == null:
		return
	var rows: Array[String] = []
	for at in elevator.floors():
		var s: ElevatorStop = elevator.stops()[at]
		rows.append(STOP % [ElevatorStop.LETTERS[at].to_upper(), ElevatorControl.FLOORS[at], at, s.car_height()])
	var t := elevator.tuning
	if t != null:
		rows.append(TUNING % [t.hatch_time, t.floor_time, t.creak_every, t.reach, t.seats, t.exit_gap, t.eye_height])
	for text in rows:
		_row(text)
	for u in _elevator_upgrades():
		_upgrade_rows[u.id()] = _row("")
	_relabel()


func _process(delta: float) -> void:
	_since += delta
	if _since >= EVERY:
		_since = 0.0
		_relabel()


## Elevator Repair and every Upgrade that needs it.
func _elevator_upgrades() -> Array[Upgrade]:
	var out: Array[Upgrade] = []
	var all := upgrades.all() if upgrades != null else Upgrades.listed()
	for u in all:
		if u.id() == REPAIR:
			out.append(u)
	for u in all:
		for need: Upgrade in u.needs:
			if need.id() == REPAIR and not out.has(u):
				out.append(u)
	return out


func _row(text: String) -> Label3D:
	var label := LABEL.instantiate() as Label3D
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.position = Vector3(0.0, 0.01, get_child_count() * row_gap)
	add_child(label)
	return label


func _relabel() -> void:
	for u in _elevator_upgrades():
		var row: Label3D = _upgrade_rows.get(u.id())
		if row != null:
			var text := UpgradeBoard.line_of(u, upgrades, Parts.HOST)
			if row.text != text:
				row.text = text
