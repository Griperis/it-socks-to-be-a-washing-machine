## The Lobby (docs/architecture/lobby.md "Core/63", Q2582, Q2583): where the players of a game gather
## before the house, its own scene over the title's backdrop, no house. A view of the link's LobbyState
## and Roster: a key asks (Parts.ask), never writes. Its look (core/66): the 3D stage behind the keys
## (LobbyStage: pedestals, Avatars, silhouettes), a place under each pedestal (LobbyPlace), the World's
## card with its "i" page (WhoPage), the status line and the bottom bar.
##
## - Solo (a Host of one, nothing listening): one place, no Ready; Back, Continue (hidden with no save)
##   and New Game (asks before a saved game is overwritten: the question's close key or Esc cancels,
##   Q2578), then the house (the old Solo bar). In a debug build New Game always opens that page, the New
##   Game page, with the "Pairs per Drawer" slider (core/91, Q668); the Host's is in the World drawer.
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
const PLACE := preload("res://game/lobby/lobby_place.tscn")
const JOINING_CARD := preload("res://game/level/loading_screen.tscn")

enum Mode {SOLO, HOST, JOIN}

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
var _place_nodes: Array[LobbyPlace] = []
## The peer standing at each place now (0: nobody), for the Wardrobe key and the stats card.
var _place_peers: Array[int] = [0, 0, 0, 0]

@onready var _card_title: Label = %CardTitle
@onready var _card_line: Label = %CardLine
@onready var _stage: LobbyStage = %Stage
@onready var _places: Control = %Places
@onready var _who_key: Button = %WhoKey
@onready var _who: WhoPage = %Who
@onready var _back: Button = %Back
@onready var _ready_key: Button = %Ready
@onready var _start: Button = %Start
@onready var _ready_caption: Label = %ReadyCaption
@onready var _start_caption: Label = %StartCaption
@onready var _status: Label = %Status
@onready var _waiting: Label = %Waiting
@onready var _continue: Button = %Continue
@onready var _new_game: Button = %NewGame
@onready var _drawer: WorldDrawer = %Drawer
@onready var _ask: Control = %Ask
@onready var _ask_yes: Button = %AskYes
@onready var _ask_close: CloseButton = %AskClose
@onready var _pairs: PairsSlider = %AskPairs
@onready var _wardrobe_key: Button = %WardrobeKey
@onready var _stats: LobbyStatsCard = %Stats
@onready var _wardrobe_layer: Control = %WardrobeLayer
@onready var _wardrobe_page: WardrobePage = %Page


func _enter_tree() -> void:
	link = GameLink.of(self)
	if link == null:
		link = GameLink.open_beside(self)


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_words()
	_back.pressed.connect(back)
	_ready_key.pressed.connect(toggle_ready)
	_ready_key.pressed.connect(UiSounds.hover)  # Ready ticks and does not click (it has no_ui_sound)
	_start.pressed.connect(start)
	_continue.pressed.connect(continue_world)
	_new_game.pressed.connect(new_game)
	_ask_yes.pressed.connect(_ask_confirmed)
	_ask_close.pressed.connect(func() -> void: _show_ask(false))
	_who_key.pressed.connect(open_who)
	_wardrobe_key.pressed.connect(open_wardrobe)
	_wardrobe_page.closed.connect(close_wardrobe)
	var tuning := _stage.tuning
	_wardrobe_key.custom_minimum_size = Vector2.ONE * tuning.key_size
	_wardrobe_key.size = Vector2.ONE * tuning.key_size
	_wardrobe_key.add_theme_constant_override(&"icon_max_width", int(tuning.key_icon))
	_stats.custom_minimum_size.x = tuning.card_width
	_who.closed.connect(_sync_focus)
	for i in LobbyStage.PLACES:
		var place := PLACE.instantiate() as LobbyPlace
		place.index = i
		place.tuning = _stage.tuning
		_places.add_child(place)
		place.focus_changed.connect(_sync_focus)
		_place_nodes.append(place)
	_drawer.visible = mode != Mode.SOLO
	_drawer.set_open(mode == Mode.HOST, true)
	_drawer.choose_world.connect(choose_world)
	_drawer.new_game_pressed.connect(new_world)
	_drawer.pairs_moved.connect(set_pairs)
	_pairs.moved.connect(set_pairs)
	_drawer.delete_confirmed.connect(delete_world)
	_drawer.full_closed.connect(func() -> void: _pending = "")
	_drawer.open_changed.connect(link_pad)
	_drawer.invite_pressed.connect(func() -> void: link.session.transport.invite())
	link.lobby.changed.connect(_refresh)
	link.roster.changed.connect(_refresh)
	link.session.linked.connect(_on_linked)
	link.session.ended.connect(_on_ended)
	_show_ask(false)
	_refresh()
	_begin.call_deferred()


## Every static word of the screen, from LobbyWords (the scene carries none).
func _words() -> void:
	_who_key.text = LobbyWords.WHO_KEY
	_wardrobe_key.tooltip_text = LobbyWords.WARDROBE_TIP
	_back.text = LobbyWords.BACK
	_ready_key.text = LobbyWords.READY
	_ready_caption.text = LobbyWords.READY_CAPTION
	_start.text = LobbyWords.START
	_start_caption.text = LobbyWords.START_CAPTION
	_waiting.text = LobbyWords.WAITING_HOST
	_continue.text = LobbyWords.CONTINUE
	_new_game.text = LobbyWords.NEW_GAME_SOLO
	($Ask/Center/Panel/Box/Heading as Label).text = LobbyWords.NEW_GAME_HEADING
	($Ask/Center/Panel/Box/Question as Label).text = LobbyWords.NEW_GAME_ASK
	_ask_yes.text = LobbyWords.NEW_GAME


## Every frame the places follow where their figures fall on the screen.
func _process(_delta: float) -> void:
	for place in _place_nodes:
		if place.visible:
			place.lay_out(_stage.box_of(place.index), _stage.tuning.label_gap)
	_lay_wardrobe_key()
	_lay_card()


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
					go_to_title.call(LobbyWords.CANNOT_HOST % s.port)
					return
			_choose_world()
			_publish_worlds()
		Mode.JOIN when s.is_online():
			pass  # back from the house after the run ended (core/97): already joined to this Host
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
	var heading := LobbyWords.SOLO_TITLE if mode == Mode.SOLO else (LobbyWords.NEW_WORLD if world.is_new else Worlds.display_name(world.slot, world.record))
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


## Start (the Host's): every machine loads the house once the Host's answer says started. With a finished World
## chosen it asks first (core/97, Q2631): yes replaces that World with a New Game in its slot.
func start() -> void:
	if _going or mode != Mode.HOST:
		return
	if _finished():
		_ask_replace()
		return
	_ask_lobby(link.lobby.start_command(_me()))


## Solo's Continue: the saved Solo World.
func continue_world() -> void:
	if _going or mode != Mode.SOLO or world == null or world.is_new or world.record.finished:
		return
	_into_house()


## Solo's New Game: at once with no save, else it asks first; a debug build always opens the New Game page
## (the question only over a save) with the "Pairs per Drawer" slider.
func new_game() -> void:
	if _going or mode != Mode.SOLO:
		return
	var saved := world != null and not world.is_new
	if saved or PairsSlider.in_build():
		($Ask/Center/Panel/Box/Question as Label).visible = saved
		($Ask/Center/Panel/Box/Question as Label).text = LobbyWords.FINISHED_ASK if _finished() else LobbyWords.NEW_GAME_ASK
		_ask_yes.text = LobbyWords.NEW_GAME if saved else LobbyWords.NEW_GAME_GO
		_pairs.visible = PairsSlider.in_build()
		_show_ask(true)
		return
	_new_game_over_save()


## The New Game's Pairs per Drawer (the debug slider, the Host's and Solo's): nobody is Ready any more.
func set_pairs(value: int) -> void:
	if _going or mode == Mode.JOIN:
		return
	_ask_lobby(link.lobby.pairs_command(_me(), value))


## Solo's New Game page's slider (debug builds).
func pairs_slider() -> PairsSlider:
	return _pairs


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
	for place in _place_nodes:
		if place.visible:
			out.append(place.texts())
	return out


## The places, one node each (a free one too), left to right; only the first `count` show.
func places() -> Array[LobbyPlace]:
	return _place_nodes


## The 3D stage.
func stage() -> LobbyStage:
	return _stage


## The Wardrobe key beside this machine's own figure's head (Q1773): on it, its page over the Lobby; this
## player's Ready is cleared (Q1764), so the others see the new look before anyone starts.
func open_wardrobe() -> void:
	if _going or _wardrobe_layer.visible or asking() or _who.visible or _own_place() == null:
		return
	_wardrobe_layer.visible = true
	_wardrobe_page.bind(link.roster, link.parts, _me())
	Sounds.play(&"menu_open")
	if mode != Mode.SOLO and link.lobby.is_ready(_me()):
		_ask_lobby(link.lobby.ready_command(_me(), false))
	_sync_focus()
	if PadFocus.pad_used:
		_wardrobe_page.focus_first()


## Shuts the Wardrobe page: the Lobby shows the new look.
func close_wardrobe() -> void:
	if not _wardrobe_layer.visible:
		return
	_wardrobe_layer.visible = false
	_wardrobe_page.unbind()
	Sounds.play(&"menu_close")
	_sync_focus()
	if PadFocus.pad_used and LobbyPad.on_route(_wardrobe_key):
		_wardrobe_key.grab_focus()


## Whether the Wardrobe page lies over the Lobby.
func wardrobe_open() -> bool:
	return _wardrobe_layer.visible


## The Wardrobe key.
func wardrobe_key() -> Button:
	return _wardrobe_key


## The Wardrobe page.
func wardrobe_page() -> WardrobePage:
	return _wardrobe_page


## The stats card.
func stats_card() -> LobbyStatsCard:
	return _stats


## The place of this machine's own player, null when none stands (a Guest before its snapshot).
func _own_place() -> LobbyPlace:
	if link == null or not is_instance_valid(link):
		return null
	var at := _place_peers.find(_me())
	return _place_nodes[at] if at >= 0 and _place_nodes[at].visible else null


## The key floats at `key_across` of the figure's width, at its head.
func _lay_wardrobe_key() -> void:
	var mine := _own_place()
	_wardrobe_key.visible = mine != null and not _going
	if mine != null:
		_wardrobe_key.position = mine.position + Vector2(mine.size.x * _stage.tuning.key_across, 0.0)


## The card sits on the right of the focused figure, on its left where the right would leave `card_edge` of the
## screen; beside this machine's own figure it clears the Wardrobe key too.
func _lay_card() -> void:
	if not _stats.visible:
		return
	var tuning := _stage.tuning
	var focus := _focused_place()
	if focus == null:
		return
	var left := focus.position.x + focus.size.x + tuning.card_gap
	if focus == _own_place() and _wardrobe_key.visible:
		left = maxf(left, _wardrobe_key.position.x + _wardrobe_key.size.x + tuning.card_gap)
	if left + _stats.size.x > size.x - tuning.card_edge:
		left = focus.position.x - tuning.card_gap - _stats.size.x
	_stats.position = Vector2(left, focus.position.y + focus.size.y * tuning.card_drop)


func _focused_place() -> LobbyPlace:
	for place in _place_nodes:
		if place.visible and place.focused():
			return place
	return null


## The "i" page of the chosen World: who was in it.
func open_who() -> void:
	var names := _members_of(link.lobby.world)
	if names.is_empty():
		return
	_who.open(link.lobby.title, names)
	_sync_focus()


## Whether the "i" page lies over the Lobby.
func who_open() -> bool:
	return _who.visible


## Whether the Lobby has gone on into the house (its keys locked).
func is_going() -> bool:
	return _going


## Whether the chosen World's run has ended: a record, never loaded into the house.
func _finished() -> bool:
	return world != null and not world.is_new and world.record.finished


## The Host's Start over a finished World asks before it replaces it.
func _ask_replace() -> void:
	($Ask/Center/Panel/Box/Question as Label).visible = true
	($Ask/Center/Panel/Box/Question as Label).text = LobbyWords.FINISHED_ASK
	_ask_yes.text = LobbyWords.NEW_GAME
	_pairs.visible = false
	_show_ask(true)


## The question's yes: the Host's replaces the finished World and starts; Solo's makes the New Game.
func _ask_confirmed() -> void:
	if mode != Mode.HOST:
		_new_game_over_save()
		return
	_show_ask(false)
	var fresh := Worlds.pick_slot(world.slot, true, true) if _finished() else null
	if fresh == null:
		return
	world = fresh
	_ask_lobby(link.lobby.start_command(_me()))


func _new_game_over_save() -> void:
	_show_ask(false)
	var fresh := Worlds.pick_slot(Worlds.SOLO, false, true)
	if fresh == null:
		return
	world = fresh
	_into_house()


func _show_ask(on: bool) -> void:
	_ask.visible = on
	_sync_focus()
	if on:
		_ask_yes.grab_focus()


func _ask_lobby(cmd: Command) -> void:
	link.parts.ask(cmd)


func _me() -> int:
	return link.session.me()


# --- Going on -----------------------------------------------------------------------------------------

## Into the house: the Host and Solo with their World, a Guest as a Guest of the Host's address.
func _into_house() -> void:
	if _going or (world != null and mode != Mode.JOIN and not world.is_new and world.record.finished):
		return  # a finished World never loads into the house (Q2631)
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
	if w != null and w.is_new and PairsSlider.in_build():
		args.append("%s%d" % [Stages.PAIRS_ARG, link.lobby.pairs_per_drawer])
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


func _input(event: InputEvent) -> void:
	# The pad's first press with nothing selected selects the first key and takes the press (no key is pressed by it).
	if _going or not is_visible_in_tree() or selected() != null:
		return
	for action: StringName in [&"ui_left", &"ui_right", &"ui_up", &"ui_down", &"ui_accept"]:
		if event.is_action_pressed(action):
			first_selection().grab_focus()
			get_viewport().set_input_as_handled()
			return


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if asking():
		_show_ask(false)
	elif _wardrobe_layer.visible:
		close_wardrobe()
	elif _who.visible:
		_who.close()
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
	_drawer.show_rows(lobby.worlds, lobby.world, mode == Mode.HOST, _going, link.roster.tuning.colour, lobby.pairs_per_drawer)
	_pairs.show_value(lobby.pairs_per_drawer, not _going)
	_card_title.text = lobby.title
	_card_line.text = lobby.line
	_card_line.visible = lobby.line != ""
	_who_key.visible = mode != Mode.SOLO and not _members_of(lobby.world).is_empty()
	_fill_places()
	var solo := mode == Mode.SOLO
	var me_ready := lobby.is_ready(_me())
	_back.text = LobbyWords.LEAVE if guest else LobbyWords.BACK
	_ready_key.visible = not solo
	_ready_key.text = LobbyWords.READY_ON if me_ready else LobbyWords.READY
	_start.visible = mode == Mode.HOST
	_start.disabled = not lobby.all_ready() or lobby.level == ""
	_waiting.visible = guest
	_ready_key.get_parent().visible = _ready_key.visible
	_start.get_parent().visible = _start.visible
	# A caption keeps its line (it fades, never hides) so nothing under the keys jumps.
	_ready_caption.modulate.a = 1.0 if me_ready and not solo else 0.0
	_start_caption.modulate.a = 1.0 if _start.disabled and not _going else 0.0
	_drawer.set_can_invite(mode == Mode.HOST and link.session.transport.can_invite())
	_status.text = status_text()
	_status.visible = _status.text != ""
	_continue.visible = solo and world != null and not world.is_new and not world.record.finished
	_new_game.visible = solo
	for key: Button in [_back, _ready_key, _start, _continue, _new_game]:
		if _going:
			key.disabled = true
	_ready_key.disabled = _going or (guest and not _in_game())
	link_pad.call_deferred()


## Whether this machine plays in the game: the Host and Solo always, a Guest once it has the link's snapshot.
func _in_game() -> bool:
	return mode != Mode.JOIN or (link.session.is_online() and link.roster.entry_of(_me()).size() > 0)


func _fill_places() -> void:
	var roster := link.roster
	var count := 1 if mode == Mode.SOLO else roster.tuning.max_players
	count = mini(count, LobbyStage.PLACES)
	_stage.set_places(count)
	var peers := roster.peers()
	_place_peers.assign([0, 0, 0, 0])
	for i in LobbyStage.PLACES:
		var place := _place_nodes[i]
		place.visible = i < count
		if i >= count:
			continue
		if i >= peers.size():
			place.show_free()
			_stage.show_free(i)
			continue
		var peer := peers[i]
		var colour := roster.colour_of(peer)
		place.show_player(roster.name_of(peer), colour, peer == Roster.HOST and mode != Mode.SOLO,
				mode != Mode.SOLO, link.lobby.is_ready(peer))
		_place_peers[i] = peer
		_stage.show_player(i, colour, roster.look_of(peer))
	_sync_focus()


## The focused place (the mouse over its figure or the pad's selection) turns its pedestal gold; a page over the
## Lobby takes the focus away.
func _sync_focus() -> void:
	if not is_node_ready():
		return
	var blocked := asking() or _who.visible or _wardrobe_layer.visible
	var at := -1
	for place in _place_nodes:
		place.set_blocked(blocked)
		if place.visible and place.focused():
			at = place.index
	_stage.set_focus(at)
	if at < 0 or _place_peers[at] == 0:
		_stats.hide_card()
	else:
		var peer := _place_peers[at]
		_stats.show_player(link.roster.id_of(peer), link.roster.name_of(peer),
				link.roster.entry_of(peer).get("tallies", {}))
		_lay_card()


## The status line's words: why the game cannot go on, "" when nothing holds it. The Group lock that held Start
## in the old game is dropped (Q2554), so nothing holds it yet: this is the one place a reason would be said.
func status_text() -> String:
	return ""


## The pad's route (LobbyPad): the "i" key and the World settings key; the figures left to right; the bottom keys;
## the open drawer a column on the right, entered by Right of the last figure and left by Left.
func link_pad() -> void:
	if not is_node_ready() or not is_inside_tree():
		return
	var top := LobbyPad.live([_who_key, _drawer.key()])
	var figures := LobbyPad.live(_place_nodes)
	var mine := figures.find(_own_place())
	if mine >= 0 and LobbyPad.on_route(_wardrobe_key):
		figures.insert(mine + 1, _wardrobe_key)  # the key beside the own figure is the next stop
	var bottom := LobbyPad.live([_back, _ready_key, _start, _continue, _new_game])
	LobbyPad.clear([_who_key, _drawer.key(), _back, _ready_key, _start, _continue, _new_game])
	LobbyPad.clear(_place_nodes)
	LobbyPad.clear([_wardrobe_key])
	var side: Array = _drawer.pad_rows() if _drawer.is_open() and _drawer.is_visible_in_tree() else []
	for row: Variant in side:
		LobbyPad.clear(row as Array)
	var rows: Array = [top, figures, bottom]
	LobbyPad.link_rows(rows)
	if mine >= 0 and figures.has(_wardrobe_key):
		# Up and Down land on the figures, never on the key beside the own one (Right of the figure reaches it).
		var own: Control = figures[mine]
		for c: Control in top:
			if c.get_node_or_null(c.focus_neighbor_bottom) == _wardrobe_key:
				c.focus_neighbor_bottom = c.get_path_to(own)
		for c: Control in bottom:
			if c.get_node_or_null(c.focus_neighbor_top) == _wardrobe_key:
				c.focus_neighbor_top = c.get_path_to(own)
	if side.is_empty():
		return
	LobbyPad.link_rows(side)
	var first: Control = (side[0] as Array)[0]
	var last: Control = (side[side.size() - 1] as Array)[0]
	var beside: Control = figures[figures.size() - 1] if not figures.is_empty() else (bottom[bottom.size() - 1] if not bottom.is_empty() else null)
	if beside != null:
		beside.focus_neighbor_right = beside.get_path_to(first)
		for row: Variant in side:
			for c: Control in row:
				c.focus_neighbor_left = c.get_path_to(beside)
	if not bottom.is_empty():
		var foot: Control = bottom[bottom.size() - 1]
		foot.focus_neighbor_right = foot.get_path_to(last)
		for c: Control in (side[side.size() - 1] as Array):
			c.focus_neighbor_bottom = c.get_path_to(foot)
	var key := _drawer.key()
	if LobbyPad.on_route(key):
		key.focus_neighbor_bottom = key.get_path_to(first)
		for c: Control in (side[0] as Array):
			c.focus_neighbor_top = c.get_path_to(key)


## The control the pad's selection starts on: the "i" key when there is one, else Back.
func first_selection() -> Control:
	return _who_key if LobbyPad.on_route(_who_key) else _back


## The control with the pad's selection, null when none.
func selected() -> Control:
	return get_viewport().gui_get_focus_owner()


## The names of the Group of the World in `slot`, as the Host's rows say them.
func _members_of(slot: String) -> PackedStringArray:
	var out := PackedStringArray()
	for row: Variant in link.lobby.worlds:
		if String((row as Dictionary).get("slot", "")) == slot:
			for who: Variant in (row as Dictionary).get("members", []):
				out.append(String(who))
	return out
