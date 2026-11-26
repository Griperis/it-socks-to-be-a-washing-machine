## The Wardrobe Station (core/142, docs/architecture/wardrobe.md "The station in the house", the old
## WardrobeStation): the oak wardrobe in the parents' bedroom. The crosshair on it outlines its doors and reads
## "Wardrobe" with the E key; using it asks `use`, and the asker's machine opens its Wardrobe menu from the Host's
## answer; shutting the menu asks `leave`. Its two doors swing open while anyone is inside and shut when the last
## one leaves (the Looks' `open` and `shut` clips), with `wardrobe_open` / `wardrobe_close` a metre up; a state
## arriving whole shows without sound (as an Openable's).
##
## State: `inside`, the player ids in its menu now. A leaver is dropped; a load starts empty (a menu never
## survives one). The floor in front of it is kept free of Socks: it is in the `sock_clear` group, and
## SockPlaces keeps `clear_box` (width, depth) clear, centred at `clear_centre` in the station's space.
class_name WardrobeStation
extends Part

const TITLE := "Wardrobe"
const USE := &"use"
const LEAVE := &"leave"
## The group whose members SockPlaces keeps clear of Socks (`clear_box`, `clear_centre`).
const SOCK_CLEAR := &"sock_clear"
const LOOKS := ^"../Looks"
const OPEN := &"open"
const SHUT := &"shut"

## This machine's Wardrobe menu (a child of the station's scene).
@export var menu: WardrobeMenu
## How far from it a player may stand to use it, in metres.
@export var reach := 4.0
## Its doors' sounds, from `sound_height` over its place (the old: a metre up).
@export var open_sound: StringName = &"wardrobe_open"
@export var close_sound: StringName = &"wardrobe_close"
@export_range(0.0, 3.0, 0.05, "suffix:m") var sound_height := 1.0
## The floor kept clear of Socks in front of it: width (x) and depth (z), in metres (the old house_layout
## "wardrobe" zone, 1.09 x 1.25 m, over the carcass and in front of it).
@export var clear_box := Vector2(1.09, 1.25) # placeholder: the old zone, until the designer sets it
## The middle of that zone on the floor, in the station's space (its front is +z).
@export var clear_centre := Vector3(0.0, 0.0, 0.345)

@export_group("State")
@export var inside := PackedStringArray()
@export_group("")

## Whether the doors were shown open, and whether this machine's player was shown inside.
var _was_open := false
var _was_mine := false
var _roster: Roster = null


func _ready() -> void:
	if menu != null:
		menu.closed.connect(_on_menu_closed)


func prompt_title() -> String:
	return TITLE


func accepts() -> Dictionary[StringName, Dictionary]:
	return {USE: {"args": {}, "rate": 5}, LEAVE: {"args": {}, "rate": 5}}


## This machine's player pressed E on it: ask to go in (the menu opens from the answer). One already in by the
## state (its menu shut meanwhile) opens again at once.
func use(by: int) -> void:
	if menu == null or menu.is_open() or by != multiplayer.get_unique_id():
		return
	if inside.has(_pid(by)):
		_open_menu()
		return
	parts.ask(Command.new(USE, by, id, {}))


func decide(cmd: Command) -> Dictionary:
	var pid := _pid(cmd.by)
	if pid == "":
		return refuse("wrong")
	var now := inside.duplicate()
	match cmd.kind:
		USE:
			if not parts.near(cmd.by, get_parent(), reach):
				return refuse("far")
			if now.has(pid):
				return refuse("already")
			now.append(pid)
			return grant({"inside": now})
		LEAVE:
			if not now.has(pid):
				return refuse("already")
			now.remove_at(now.find(pid))
			return grant({"inside": now})
	return refuse("wrong")


## The Host: player `by` left the Session: out of the Wardrobe (and anyone the Roster no longer has playing).
func left(by: int) -> Dictionary:
	var gone := _pid(by)
	var roster := _find_roster()
	var keep := PackedStringArray()
	for p in inside:
		if p == gone or (roster != null and roster.players.has(p) and not roster.is_live(p)):
			continue
		keep.append(p)
	return grant({"inside": keep}) if keep != inside else {}


## A menu never survives a load: nothing is kept.
func save_state() -> Dictionary:
	return {}


## The Host, after a load: nobody is inside.
func loaded(_host: String) -> Dictionary:
	return grant({"inside": PackedStringArray()}) if not inside.is_empty() else {}


func _show(now: bool) -> void:
	var open := not inside.is_empty()
	if now or open != _was_open:
		if not now:
			_make_sound(open)
		_swing(open, now)
	_was_open = open
	var mine := inside.has(_pid(multiplayer.get_unique_id()))
	if mine and not _was_mine and not now:
		_open_menu()
	elif not mine and _was_mine and menu != null and menu.is_open():
		menu.close()
	_was_mine = mine


## The Looks' AnimationPlayer plays `open` or `shut` from the pose it has now; `now` jumps to the end.
func _swing(open: bool, now: bool) -> void:
	var player := animator()
	if player == null:
		return
	var clip := OPEN if open else SHUT
	var other := SHUT if open else OPEN
	var length := player.get_animation(clip).length
	var from := 0.0
	if now:
		from = length
	elif player.is_playing() and player.current_animation == other:
		from = length * (1.0 - player.current_animation_position / maxf(player.get_animation(other).length, 0.0001))
	player.play(clip)
	player.seek(from, true)


## The Looks' AnimationPlayer with the doors' clips, or null.
func animator() -> AnimationPlayer:
	var looks := get_node_or_null(LOOKS)
	if looks == null:
		return null
	for node in looks.find_children("*", "AnimationPlayer", true, false):
		var player := node as AnimationPlayer
		if player.has_animation(OPEN) and player.has_animation(SHUT):
			return player
	return null


func _make_sound(open: bool) -> void:
	var event := open_sound if open else close_sound
	var spot := get_parent() as Node3D
	if event != &"" and spot != null and spot.is_inside_tree():
		Sounds.play_at(event, spot.global_position + Vector3.UP * sound_height)


func _open_menu() -> void:
	var roster := _find_roster()
	var player := _local_player()
	if menu != null and roster != null and player != null:
		menu.open(player, roster, parts, multiplayer.get_unique_id())


## The menu shut: this machine's player leaves.
func _on_menu_closed() -> void:
	if parts != null and inside.has(_pid(multiplayer.get_unique_id())):
		parts.ask(Command.new(LEAVE, multiplayer.get_unique_id(), id, {}))


## The player id of peer `peer` (the Roster's; the peer itself where there is no Roster).
func _pid(peer: int) -> String:
	var roster := _find_roster()
	if roster == null:
		return str(peer) if peer != 0 else ""
	return roster.id_of(peer)


func _find_roster() -> Roster:
	if _roster != null and is_instance_valid(_roster):
		return _roster
	_roster = parts.find(func(part: Part) -> bool: return part is Roster) as Roster if parts != null else null
	return _roster


func _local_player() -> Player:
	for node in get_tree().get_nodes_in_group(&"local_input"):
		if node is Player and node.multiplayer == multiplayer:
			return node as Player
	return null
