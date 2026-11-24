## The Lobby (docs/architecture/lobby.md "Core/63", Q2582, Q2583): where the players of a game gather
## before the house, its own scene over the title's backdrop, no house. A view of the link's LobbyState
## and Roster: a key asks (Parts.ask), never writes. A plain stand-in look (core/66 makes the look): the
## World's card, the places as a list of names in their colours, the status line and the bottom bar.
##
## - Solo (a Host of one, nothing listening): one place, no Ready; Back, Continue (hidden with no save)
##   and New Game (asks before a saved game is overwritten: the question's close key or Esc cancels,
##   Q2578), then the house (the old Solo bar).
## - Host: listening; four places; Back, Ready and Start (greyed until everyone present is Ready). Start
##   has every machine load the house behind the loading screen; the house handshake does the rest.
## - Guest: joins the Host's address behind the "Joining..." card until the link's snapshot comes; Leave,
##   Ready and "Waiting for the Host to start". A Guest whose snapshot says the game started goes into
##   the house at once (it skips the Lobby).
## - Back ends the session for everyone (each Guest goes to its title with "The Host ended the
##   session", Q250); a Guest's Leave leaves; Esc is Back. A session that ends here goes to the title
##   with its reason.
class_name LobbyScreen
extends Control

const SCENE := "res://game/lobby/lobby.tscn"
const TITLE := "res://game/ui/title/title.tscn"
const JOINING_CARD := preload("res://game/level/loading_screen.tscn")

enum Mode {SOLO, HOST, JOIN}

## The Lobby's words. placeholder: the old wording (02-lobby.md "Words and refusals"), core/67 owns it.
const BACK := "Back"
const LEAVE := "Leave"
const READY := "Ready"
const READY_ON := "✓ Ready"
const START := "Start"
const WAITING_HOST := "Waiting for the Host to start"
const WAITING_PLAYER := "Waiting for a player"
const HOST_MARK := "HOST"
const NOT_READY_MARK := "-"
const SOLO_TITLE := "Solo"
const NEW_WORLD := "New World"
const CANNOT_HOST := "Could not host on port %d"
## Back and Leave say nothing on the title.
const NO_NOTICE := ""

## How this Lobby was opened (the title sets it before the scene enters the tree).
var mode := Mode.SOLO
## The World this machine plays (Solo, Host); a Guest has none.
var world: WorldSlot = null
## Where a Guest joins (ENet: "ip" or "ip:port").
var address := ""
## What the house is started with besides the way in (`--profile=<tag>`).
var launch := PackedStringArray()
## How the Lobby goes into the house: func(path, heading, setup: Callable). The title hands its own on,
## so a test that swaps the title's way in swaps this one too.
var go_into := func(path: String, heading: String, setup: Callable) -> void: SceneChanger.change_to(path, heading, setup)
## How the Lobby goes back to the title, saying `notice` there once.
var go_to_title := func(notice: String) -> void:
	Worlds.notice = notice
	SceneChanger.change_to(TITLE)

## The game link (found as the Lobby enters the tree; made beside it when it has none: F5 on the scene).
var link: GameLink = null

## What the "full" page goes on with once a World is deleted: a slot to choose, or NEW_GAME.
const NEW_GAME_PENDING := "+new"

var _going := false
var _pending := ""
var _joining_card: LoadingScreen = null

@onready var _card_title: Label = %CardTitle
@onready var _card_line: Label = %CardLine
@onready var _places: VBoxContainer = %Places
@onready var _back: Button = %Back
@onready var _ready_key: Button = %Ready
@onready var _start: Button = %Start
@onready var _waiting: Label = %Waiting
@onready var _continue: Button = %Continue
@onready var _new_game: Button = %NewGame
@onready var _drawer: WorldDrawer = %Drawer
@onready var _ask: Control = %Ask
@onready var _ask_yes: Button = %AskYes
@onready var _ask_close: CloseButton = %AskClose


func _enter_tree() -> void:
	link = GameLink.of(self)
	if link == null:
		link = GameLink.open_beside(self)


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_back.pressed.connect(back)
	_ready_key.pressed.connect(toggle_ready)
	_start.pressed.connect(start)
	_continue.pressed.connect(continue_world)
	_new_game.pressed.connect(new_game)
	_ask_yes.pressed.connect(_new_game_over_save)
	_ask_close.pressed.connect(func() -> void: _show_ask(false))
	_drawer.visible = mode != Mode.SOLO
	_drawer.set_open(mode == Mode.HOST, true)
	_drawer.choose_world.connect(choose_world)
	_drawer.new_game_pressed.connect(new_world)
	_drawer.delete_confirmed.connect(delete_world)
	_drawer.full_closed.connect(func() -> void: _pending = "")
	link.lobby.changed.connect(_refresh)
	link.roster.changed.connect(_refresh)
	link.session.linked.connect(_on_linked)
	link.session.ended.connect(_on_ended)
	_show_ask(false)
	_refresh()
	_begin.call_deferred()


func _exit_tree() -> void:
	if link == null or not is_instance_valid(link):
		return
	for pair: Array in [[link.lobby.changed, _refresh], [link.roster.changed, _refresh],
			[link.session.linked, _on_linked], [link.session.ended, _on_ended]]:
		var sig: Signal = pair[0]
		if sig.is_connected(pair[1]):
			sig.disconnect(pair[1])


## Starts the way in: alone, listening, or joining.
func _begin() -> void:
	var s := link.session
	if s.profile == null:
		s.profile = world.profile if world != null and world.profile != null else Worlds.profile()
	match mode:
		Mode.SOLO:
			s.enter_alone()
			_choose_world()
		Mode.HOST:
			if not s.is_online():
				var err := s.host()
				if err != OK:
					go_to_title.call(CANNOT_HOST % s.port)
					return
			_choose_world()
			_publish_worlds()
		Mode.JOIN:
			_joining_card = JOINING_CARD.instantiate() as LoadingScreen
			_joining_card.free_when_faded = true
			_joining_card.set_heading(LoadingScreen.JOINING)
			add_child(_joining_card)
			var err := s.join(address)
			if err != OK:
				go_to_title.call(Session.UNREACHABLE % address)
				return
	_refresh()


## The Host (and Solo): the World this machine plays goes on the card, through the Host's answer.
func _choose_world() -> void:
	if world == null:
		return
	var heading := SOLO_TITLE if mode == Mode.SOLO else (NEW_WORLD if world.is_new else Worlds.display_name(world.slot, world.record))
	var line := ""
	if not world.is_new:
		line = Worlds.row_details(world.record)
		if mode == Mode.SOLO:
			line = "%s · %s" % [Worlds.SOLO_WORLD, line]
	_ask_lobby(link.lobby.world_command(_me(), world.record.level, heading, line, world.slot))


## The Host's Worlds, as the drawers list them (Worlds.rows()), through the Host's answer.
func _publish_worlds() -> void:
	if mode == Mode.HOST:
		_ask_lobby(link.lobby.worlds_command(_me(), Worlds.rows()))


# --- The drawer's keys (the Host's) -------------------------------------------------------------------

## Choose: the World in `slot` is the one this game plays (Ready clears on every machine). The Solo World
## with every co-op slot used asks to delete one first: a Guest would make it a co-op World (Q1738).
func choose_world(slot: String) -> void:
	if _going or mode != Mode.HOST:
		return
	if slot == Worlds.SOLO and Worlds.free_coop_slot() == "":
		_ask_to_delete(slot)
		return
	var picked := Worlds.pick_slot(slot, true)
	if picked == null:
		return
	world = picked
	_choose_world()


## New game: a New Game in the first free co-op slot; with every one used the full page asks to delete one.
func new_world() -> void:
	if _going or mode != Mode.HOST:
		return
	var free := Worlds.free_coop_slot()
	if free == "":
		_ask_to_delete(NEW_GAME_PENDING)
		return
	world = Worlds.pick_slot(free, true, true)
	_choose_world()


## Delete (after its question): the World's files go; the chosen World gone puts the Lobby on the
## last-played co-op World, else a New Game; the full page goes on at once with what it was asked for.
func delete_world(slot: String) -> void:
	if _going or mode != Mode.HOST:
		return
	Worlds.delete(slot)
	var chosen_gone := world != null and world.slot == slot
	var pending := _pending
	_pending = ""
	_drawer.hide_full()
	if pending == NEW_GAME_PENDING:
		new_world()
	elif pending != "":
		choose_world(pending)
	elif chosen_gone:
		var next := Worlds.pick_host()
		if next != null:
			world = next
			_choose_world()
	_publish_worlds()


func _ask_to_delete(pending: String) -> void:
	_pending = pending
	_drawer.show_full(Worlds.coop_slots().size())


## The drawer (read-only for a Guest).
func drawer() -> WorldDrawer:
	return _drawer


# --- Keys -------------------------------------------------------------------------------------------

## Ready: this player's Ready flips (the Host decides; a Guest asks).
func toggle_ready() -> void:
	if _going or mode == Mode.SOLO:
		return
	_ask_lobby(link.lobby.ready_command(_me(), not link.lobby.is_ready(_me())))


## Start (the Host's): every machine loads the house once the Host's answer says started.
func start() -> void:
	if _going or mode != Mode.HOST:
		return
	_ask_lobby(link.lobby.start_command(_me()))


## Solo's Continue: the saved Solo World.
func continue_world() -> void:
	if _going or mode != Mode.SOLO or world == null or world.is_new:
		return
	_into_house()


## Solo's New Game: at once with no save, else it asks first.
func new_game() -> void:
	if _going or mode != Mode.SOLO:
		return
	if world != null and not world.is_new:
		_show_ask(true)
		return
	_new_game_over_save()


## Back (Host, Solo) or Leave (Guest): the Host's ends the session for everyone, a Guest's leaves it.
func back() -> void:
	if _going:
		return
	link.session.close()
	go_to_title.call(NO_NOTICE)


## Whether Solo's "Start a new game?" question shows.
func asking() -> bool:
	return _ask.visible


## The places' lines as shown (the HOST mark, the name, the Ready mark; a free place's words), top down.
func place_texts() -> PackedStringArray:
	var out := PackedStringArray()
	for row in _places.get_children():
		if row.is_queued_for_deletion():
			continue
		var words := PackedStringArray()
		for label in row.get_children():
			if label is Label and (label as Label).visible and (label as Label).text != "":
				words.append((label as Label).text)
		out.append(" ".join(words))
	return out


## Whether the Lobby has gone on into the house (its keys locked).
func is_going() -> bool:
	return _going


func _new_game_over_save() -> void:
	_show_ask(false)
	var fresh := Worlds.pick_slot(Worlds.SOLO, false, true)
	if fresh == null:
		return
	world = fresh
	_into_house()


func _show_ask(on: bool) -> void:
	_ask.visible = on
	if on:
		_ask_yes.grab_focus()


func _ask_lobby(cmd: Command) -> void:
	link.parts.ask(cmd)


func _me() -> int:
	return link.session.me()


# --- Going on -----------------------------------------------------------------------------------------

## Into the house: the Host and Solo with their World, a Guest as a Guest of the Host's address.
func _into_house() -> void:
	if _going:
		return
	_going = true
	_refresh()
	var path := world.record.level if world != null and mode != Mode.JOIN else link.lobby.level
	var heading := world.loading_heading() if world != null and mode != Mode.JOIN else LoadingScreen.JOINING
	var args := PackedStringArray()
	match mode:
		Mode.HOST:
			args.append("--host")
		Mode.JOIN:
			args.append("--join=%s" % address)
	args.append_array(launch)
	var w := world if mode != Mode.JOIN else null
	go_into.call(path, heading, func(root: Node) -> void:
		var runtime := LevelRuntime.of(root)
		if runtime != null:
			runtime.world = w
			runtime.from_title = true
			runtime.launch = args)


func _on_linked() -> void:
	if _joining_card != null and is_instance_valid(_joining_card) and not link.lobby.started:
		_joining_card.finish()
	_refresh()


func _on_ended(text: String) -> void:
	if _going:
		return
	go_to_title.call(text)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if asking():
		_show_ask(false)
	elif _drawer.close_dialog():
		pass
	else:
		back()


# --- The view -----------------------------------------------------------------------------------------

func _refresh() -> void:
	if not is_node_ready():
		return
	var lobby := link.lobby
	var guest := mode == Mode.JOIN
	if lobby.started and not _going and mode != Mode.SOLO and (not guest or _in_game()):
		_into_house.call_deferred()
	_drawer.show_rows(lobby.worlds, lobby.world, mode == Mode.HOST, _going, link.roster.tuning.colour)
	_card_title.text = lobby.title
	_card_line.text = lobby.line
	_card_line.visible = lobby.line != ""
	_fill_places()
	var solo := mode == Mode.SOLO
	var me_ready := lobby.is_ready(_me())
	_back.text = LEAVE if guest else BACK
	_ready_key.visible = not solo
	_ready_key.text = READY_ON if me_ready else READY
	_start.visible = mode == Mode.HOST
	_start.disabled = not lobby.all_ready() or lobby.level == ""
	_waiting.visible = guest
	_continue.visible = solo and world != null and not world.is_new
	_new_game.visible = solo
	for key: Button in [_back, _ready_key, _start, _continue, _new_game]:
		if _going:
			key.disabled = true
	_ready_key.disabled = _going or (guest and not _in_game())


## Whether this machine plays in the game: the Host and Solo always, a Guest once it has the link's snapshot.
func _in_game() -> bool:
	return mode != Mode.JOIN or (link.session.is_online() and link.roster.entry_of(_me()).size() > 0)


func _fill_places() -> void:
	for row in _places.get_children():
		_places.remove_child(row)
		row.queue_free()
	var roster := link.roster
	var count := 1 if mode == Mode.SOLO else roster.tuning.max_players
	var peers := roster.peers()
	for i in count:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override(&"separation", 16)
		_places.add_child(row)
		if i >= peers.size():
			row.add_child(_label(WAITING_PLAYER, &"ThinLabel", Color.TRANSPARENT))
			continue
		var peer := peers[i]
		if peer == Roster.HOST and mode != Mode.SOLO:
			row.add_child(_label(HOST_MARK, &"RowLabel", Color.TRANSPARENT))
		var name_label := _label(roster.name_of(peer), &"RowName", roster.colour_of(peer))
		name_label.name = "Name"
		row.add_child(name_label)
		if mode != Mode.SOLO:
			row.add_child(_label(READY_ON if link.lobby.is_ready(peer) else NOT_READY_MARK, &"RowLabel", Color.TRANSPARENT))


func _label(text: String, variation: StringName, colour: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = variation
	if colour.a > 0.0:
		l.add_theme_color_override(&"font_color", colour)
	return l
