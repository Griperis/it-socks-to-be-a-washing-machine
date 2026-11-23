## The game's first screen (the old TitleScreen, B60; core/58): the dark backdrop, one cream keycap
## panel with its pages shown one at a time (home, Multiplayer, Join, Options, Licence), the status
## line under them and the Licence key in the corner (the Zoo key too in a debug build). The pages swap
## at once; the Zoo key in the corner is a debug build's only (Q2580). The look is the scene's, on the Theme; code fills data and reacts to presses.
##
## - Solo: the Solo World (Worlds.pick_solo(): Continue it, or a New Game when there is none) behind
##   the loading screen, alone, nothing listening (Q2561; the Lobby comes later).
## - Multiplayer: one "Your name" field above Host and Join (kept in the profile; Q2585), Host (the last-played co-op World, or a New Game in a free slot; listening) and Join
##   (address, kept in the profile; "Joining..." behind the loading screen).
## - Options, Licence: their pages. Quit closes the game.
## - Each way into the game (Solo, Host, Join) makes the game link (GameLink, core/62) beside the title,
##   which the level then plays through and a scene change keeps; back at the title the game is over
##   and the title frees the link it finds.
## - The command line: `--host` hosts at once (the newest co-op World, else the Solo World, else a New
##   Game); `--join=<address>` joins at once.
class_name TitleScreen
extends Control

const ZOO := "res://game/zoo/zoo.tscn"
const OPTIONS := preload("res://game/ui/options/options.tscn")
const LICENCE := preload("res://game/ui/licence/licence.tscn")
## The loading screen's words for a Guest (the old M:506). placeholder: the old wording.
const JOINING := "Joining..."
const HOME := "home"
const MULTIPLAYER := "multiplayer"
const JOIN := "join"
const OPTIONS_PAGE := "options"
const LICENCE_PAGE := "licence"

## How a choice goes into the game: func(path, heading, setup: Callable). A test swaps it to stay put.
var go_into := func(path: String, heading: String, setup: Callable) -> void: SceneChanger.change_to(path, heading, setup)
## How Quit closes the game. A test swaps it to stay put.
var quit_game := func() -> void: get_tree().quit()
## The page on show.
var page := HOME

var _page_node: Control = null

@onready var _pages: Dictionary[String, Control] = {HOME: %Home, MULTIPLAYER: %Multiplayer, JOIN: %Join}
@onready var _holder: Control = %Pages
@onready var _status: Label = %Status
@onready var _solo: Button = %Solo
@onready var _multiplayer: Button = %MultiplayerKey
@onready var _options: Button = %OptionsKey
@onready var _quit: Button = %Quit
@onready var _host: Button = %Host
@onready var _join_page: Button = %JoinKey
@onready var _join: Button = %JoinGo
@onready var _name: LineEdit = %NameField
@onready var _address: LineEdit = %AddressField
@onready var _licence_key: Button = %LicenceKey
@onready var _zoo_key: Button = %ZooKey
@onready var _close: CloseButton = %Close


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE  # back from the game the mouse is still captured
	GameLink.close_beside(self)  # back at the title the game is over
	_solo.pressed.connect(solo)
	_multiplayer.pressed.connect(show_page.bind(MULTIPLAYER))
	_options.pressed.connect(show_page.bind(OPTIONS_PAGE))
	_quit.pressed.connect(func() -> void: quit_game.call())
	_host.pressed.connect(host)
	_join_page.pressed.connect(show_page.bind(JOIN))
	_join.pressed.connect(join)
	_address.text_submitted.connect(func(_t: String) -> void: join())
	_licence_key.pressed.connect(show_page.bind(LICENCE_PAGE))
	# The Zoo key is a debug build's only (Q2580): a release build has none.
	if OS.is_debug_build():
		_zoo_key.pressed.connect(func() -> void: go_into.call(ZOO, "", Callable()))
	else:
		_zoo_key.queue_free()
		_zoo_key = null
	_close.pressed.connect(back_out)
	var p := Worlds.profile()
	_name.text = p.shown_name()
	_address.text = p.address
	_status.text = Worlds.take_notice()
	show_page(HOME)
	_from_command_line.call_deferred()


## Shows page `which` alone (no slide, no fade); the corner keys only on home. Leaving the Join page
## keeps what was typed in the profile.
func show_page(which: String) -> void:
	if page == MULTIPLAYER and which != MULTIPLAYER:
		_keep_name()
	if page == JOIN and which != JOIN:
		_keep_join_fields()
	if is_instance_valid(_page_node):
		_page_node.queue_free()
	_page_node = null
	page = which
	for k: String in _pages:
		_pages[k].visible = k == which
	if which == OPTIONS_PAGE:
		_page_node = OPTIONS.instantiate() as Control
	elif which == LICENCE_PAGE:
		_page_node = LICENCE.instantiate() as Control
	if _page_node != null:
		_page_node.connect(&"closed", _on_page_closed)
		_holder.add_child(_page_node)
	_licence_key.visible = which == HOME
	_close.visible = which == MULTIPLAYER or which == JOIN
	if _zoo_key != null:
		_zoo_key.visible = which == HOME
	var first := _first_focus(which)
	if first != null:
		first.grab_focus()


## The close key of a page (Esc does the same): one page up.
func back_out() -> void:
	show_page(MULTIPLAYER if page == JOIN else HOME)


## What the status line says now.
func status() -> String:
	return _status.text


## Solo: the Solo World, alone.
func solo() -> void:
	var w := Worlds.pick_solo()
	if w == null:
		_status.text = Worlds.take_notice()
		return
	_go(w, _profile_args())


## Host: the Host's World, listening. `from_command_line`: the `--host` rule.
func host(from_command_line := false) -> void:
	_keep_name()
	var w := Worlds.pick_host(from_command_line)
	if w == null:
		_status.text = Worlds.take_notice()
		return
	var launch := PackedStringArray(["--host"])
	launch.append_array(_profile_args())
	_go(w, launch)


## Join: the Host at the typed address (the remembered one when empty).
func join(where := "") -> void:
	_keep_name()
	_keep_join_fields()
	var address := where if where != "" else _address.text.strip_edges()
	if address == "":
		_address.grab_focus()
		return
	var launch := PackedStringArray(["--join=%s" % address])
	launch.append_array(_profile_args())
	GameLink.open_beside(self)
	go_into.call(Worlds.LEVEL, JOINING, func(root: Node) -> void:
		var runtime := LevelRuntime.of(root)
		if runtime != null:
			runtime.from_title = true
			runtime.launch = launch)


func _go(w: WorldSlot, launch: PackedStringArray) -> void:
	GameLink.open_beside(self)
	go_into.call(w.record.level, w.loading_heading(), func(root: Node) -> void:
		var runtime := LevelRuntime.of(root)
		if runtime != null:
			runtime.world = w
			runtime.from_title = true
			runtime.launch = launch)


func _keep_join_fields() -> void:
	var p := Worlds.profile()
	var address := _address.text.strip_edges().left(PlayerProfile.ADDRESS_MAX)
	if address != p.address:
		p.address = address
		p.save()


## The one "Your name" field (Multiplayer page, for Host and Join): kept in the profile.
func _keep_name() -> void:
	var p := Worlds.profile()
	var typed := PlayerProfile.clean_name(_name.text)
	if _name.text.strip_edges() == p.shown_name():
		return  # untouched (a suggestion shown is not a typed name)
	if typed != p.name:
		p.name = typed
		p.save()


func _profile_args() -> PackedStringArray:
	var out := PackedStringArray()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--profile="):
			out.append(arg)
	return out


func _first_focus(which: String) -> Control:
	match which:
		HOME:
			return _solo
		MULTIPLAYER:
			return _name
		JOIN:
			return _address
	return null


func _on_page_closed() -> void:
	_page_node = null
	show_page(HOME)


## `--host` / `--join=<address>` on the command line act at once, unless the command line asked for
## another scene (GameCli does that) or the title was not the launched scene.
func _from_command_line() -> void:
	if GameCli.other_scene_asked(OS.get_cmdline_args()) or get_tree().current_scene != self:
		return
	var args := OS.get_cmdline_user_args()
	if GameCli.plan(args, GameCli.debug_build)["action"] != "none":
		return
	for arg in args:
		if arg == "--host":
			host(true)
			return
		if arg.begins_with("--join="):
			join(arg.trim_prefix("--join="))
			return


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and page != HOME and _page_node == null:
		get_viewport().set_input_as_handled()
		back_out()
