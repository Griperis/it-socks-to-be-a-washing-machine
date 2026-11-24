## core/66's stills: the Lobby as a Host with players the shot makes up (no network peers: the Roster and
## LobbyState are set straight, as the Host's answers would). `--scene=res://tools/shot_lobby.tscn`, then
## `--do` steps `call` one of these by name.
extends Node

const NAMES: Array[String] = ["Ada", "Mia", "Zoltan", "Bart"]
const LONG := "Bartholomew Longname"

var lobby: LobbyScreen = null


func _ready() -> void:
	lobby = (load("res://game/lobby/lobby.tscn") as PackedScene).instantiate() as LobbyScreen
	lobby.mode = LobbyScreen.Mode.HOST
	add_child(lobby)
	await get_tree().process_frame
	await get_tree().process_frame
	rows(false)


## Fills the first `n` places (the Host first); the first `ready_count` are Ready.
func make(n: int, long_name := false, ready_count := 2) -> void:
	var roster := lobby.link.roster
	var players := {}
	var ready := PackedStringArray()
	for i in n:
		var pid := "shot-%d" % i
		var who := LONG if (long_name and i == 3) else NAMES[i]
		players[pid] = {"peer": i + 1, "name": who, "colour": i}
		if i < ready_count:
			ready.append(pid)
	lobby.drawer().set_open(false, true)
	roster.players = players
	lobby.link.lobby.readied = ready
	roster.changed.emit()
	lobby.link.lobby.changed.emit()


func four() -> void:
	make(4)


func three() -> void:
	make(3)


func long_name() -> void:
	make(4, true)


func focus_two() -> void:
	make(4)
	lobby.places()[1].grab_focus()


func drawer_open() -> void:
	make(3)
	await get_tree().process_frame
	lobby.drawer().set_open(true, true)


func who() -> void:
	make(3)
	lobby.open_who()


## The row names: the members' names, or "World n" (L7).
func members_form() -> void:
	rows(false)


func numbered_form() -> void:
	rows(true)


func rows(numbered: bool) -> void:
	Worlds.name_form = Worlds.NameForm.NUMBERED if numbered else Worlds.NameForm.MEMBERS
	var mk := func(slot: String, members: Array, details: String) -> Dictionary:
		var rec := WorldRecord.new()
		var colours := []
		for i in members.size():
			colours.append(i)
			rec.members["p%d" % i] = {"name": members[i], "colour": i}
		return {"slot": slot, "name": Worlds.display_name(slot, rec), "details": details, "damaged": false,
				"last_played": 0, "colours": colours, "members": members}
	var list: Array = [
		mk.call(Worlds.SOLO, [], "Floor 3 · played 12h 40m · last 2026-11-20 21:02"),
		mk.call("coop2", ["Ada", "Mia", "Zoltan"], "Floor 2 · played 5h 02m · last 2026-11-11 13:07"),
		mk.call("coop1", ["Ada", "Bart"], "Floor 1 · played 0h 48m · last 2026-11-02 18:30"),
	]
	var l := lobby.link.lobby
	l.worlds = list
	l.world = "coop2"
	l.title = (list[1] as Dictionary)["name"]
	l.line = (list[1] as Dictionary)["details"]
	l.changed.emit()


## core/67: the bar's captions (the Host is Ready, so "press again to un-ready" shows and Start is held with its
## caption), and the pad's selection on the Ready key.
func details() -> void:
	rows(false)
	make(4, false, 1)
	lobby.get_node("%Ready").grab_focus()


## The pad's first selection: the "i" key.
func pad_first() -> void:
	pad_press()
	rows(false)
	make(4, false, 1)
	lobby.first_selection().grab_focus()


## The pad inside the open drawer.
func pad_drawer() -> void:
	rows(false)
	make(3, false, 1)
	await get_tree().process_frame
	lobby.drawer().set_open(true, true)
	await get_tree().process_frame
	await get_tree().process_frame
	var rows_on: Array = lobby.drawer().pad_rows()
	((rows_on[0] as Array)[0] as Control).grab_focus()


## core/75: a pad press, so the selection ring shows (the shot has no real pad).
func pad_press() -> void:
	var ev := InputEventJoypadButton.new()
	ev.button_index = JOY_BUTTON_DPAD_DOWN
	ev.pressed = true
	PadFocus.on_input(ev)


## The pad inside the open drawer, a row key selected (the ring shows).
func pad_drawer_key() -> void:
	pad_press()
	await pad_drawer()


## core/75, Q2650: the drawer with a World row's Delete key selected (full width, with its text).
func pad_drawer_delete() -> void:
	pad_press()
	await pad_drawer()
	var row: WorldRow = lobby.drawer().row_nodes()[1]
	row.get_node("%Delete").grab_focus()
