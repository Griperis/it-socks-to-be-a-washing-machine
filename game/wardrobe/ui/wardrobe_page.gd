## The Wardrobe page (core/142, docs/architecture/wardrobe.md "The Wardrobe page", the old WardrobeView): the
## heading "Colour & Wardrobe", the preview stage beside the colour row and the four slot rows, and the close key.
## The house's Wardrobe menu holds it (and the Lobby's page layer, core/143). bind() gives it whose page it is: a
## player on `peer`, read from the Roster, asking through `parts`.
##
## - The preview: the player's creature in their colour and look, turning one turn per `spin_time`, its pupils
##   on the camera while it faces it (within `facing`); the worn Trail's sample steps beside it on its own (a
##   second creature showing only the marks, so it stays beside as the first turns).
## - The colour row: a swatch per Player colour (CoopTuning), this player's ringed and raised, another present
##   player's greyed with their name and not clickable. A click on a free one shows it at once and asks
##   `colour`; the Host's refusal ("taken": someone got there first) springs it back to the Roster's.
## - The rows: "None" and the owned listed pieces of each slot (the basic ones from the first game, Q2679; the
##   Lost Socks' six neither listed nor counted, Q2683), "N/M unlocked"; each step shows the piece on the
##   preview at once and asks `wear`; a refusal springs it back.
## The look is the scene's (Theme variations, Q2658); code fills it and instances a swatch per colour.
class_name WardrobePage
extends PanelContainer

## The close key was pressed.
signal closed

const SWATCH := preload("res://game/wardrobe/ui/colour_swatch.tscn")
const STAGE := ^"Stage"
const CAMERA := ^"Stage/Camera"
const BODY := ^"Body"

@export var tuning: WardrobeTuning

## Whose page: the Roster it reads, the Parts it asks through, the player's peer.
var roster: Roster = null
var parts: Parts = null
var peer := 0
## What the page shows as worn and picked now (the Roster's, or a step still waiting on its answer).
var look: Dictionary[StringName, StringName] = WardrobeLook.empty()
var colour_index := -1

var _clock := 0.0
var _swatches: Array[ColourSwatch] = []

@onready var _preview: PreviewStage = %Preview
@onready var _creature: AvatarLooks = %Creature
@onready var _sample: AvatarLooks = %TrailSample
@onready var _colours: HFlowContainer = %Colours
@onready var _rows: Array[WardrobeRow] = [%Hats, %Clothes, %Socks, %Trail]
@onready var _close: CloseButton = %Close


func _ready() -> void:
	if tuning == null:
		tuning = Wardrobe.tuning()
	_close.pressed.connect(closed.emit)
	for row in _rows:
		row.stepped.connect(_on_stepped)
	(_sample.get_node(BODY) as Node3D).visible = false  # the marks alone
	_sample.dresser().demo = true
	_run_stage(false)


## Shows the page of the player on `peer`, from `with` (the Roster), asking through `through`; kept up to date
## while bound.
func bind(with: Roster, through: Parts, on_peer: int) -> void:
	unbind()
	roster = with
	parts = through
	peer = on_peer
	roster.changed.connect(refresh)
	if parts != null:
		parts.applied.connect(_on_applied)
	_clock = 0.0
	refresh()
	_run_stage(true)


## Stops following the Roster (the page closed).
func unbind() -> void:
	if roster != null and is_instance_valid(roster) and roster.changed.is_connected(refresh):
		roster.changed.disconnect(refresh)
	if parts != null and is_instance_valid(parts) and parts.applied.is_connected(_on_applied):
		parts.applied.disconnect(_on_applied)
	_run_stage(false)


## Everything from the Roster now: the rows, the colours, the preview.
func refresh() -> void:
	if roster == null or not is_instance_valid(roster):
		return
	var pid := roster.id_of(peer)
	look = WardrobeLook.clean(roster.look_of(peer))
	colour_index = roster.colour_index_of(peer)
	var owned := roster.owned_of(pid)
	for row in _rows:
		var offered: Array[StringName] = []
		for p in Wardrobe.row(row.slot):
			if Wardrobe.shown(p) and owned.has(String(p.id)):
				offered.append(p.id)
		row.fill(offered, look[WardrobeLook.key(row.slot)], offered.size(), Wardrobe.counted(row.slot))
	_fill_colours()
	_dress()


## The row of `slot`.
func row(slot: WardrobePiece.Slot) -> WardrobeRow:
	return _rows[slot]


## The swatches, in the colours' order.
func swatches() -> Array[ColourSwatch]:
	return _swatches


## The creature on the preview.
func creature() -> AvatarLooks:
	return _creature


## The Trail's sample beside it.
func trail_sample() -> AvatarLooks:
	return _sample


## The close key.
func close_key() -> Button:
	return _close.key()


## With the pad in use the first arrow takes the focus.
func focus_first() -> void:
	_rows[0].prev_key().grab_focus()


func _process(delta: float) -> void:
	_clock += delta
	var turn := wrapf(_clock * TAU / maxf(tuning.spin_time, 0.01), 0.0, TAU)
	_creature.rotation.y = turn
	var facing := absf(angle_difference(0.0, turn)) <= tuning.facing
	_creature.watch = (_preview.get_node(CAMERA) as Node3D).global_position if facing else null


## The stage draws and its creatures move only while the page is bound (a closed menu costs nothing).
func _run_stage(on: bool) -> void:
	set_process(on)
	_preview.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	(_preview.get_node(STAGE) as SubViewport).render_target_update_mode = \
			SubViewport.UPDATE_ALWAYS if on else SubViewport.UPDATE_DISABLED


# --- Colours -------------------------------------------------------------------------------------

func _fill_colours() -> void:
	var palette := roster.tuning.colours
	if _swatches.size() != palette.size():
		for s in _swatches:
			_colours.remove_child(s)
			s.queue_free()
		_swatches.clear()
		for i in palette.size():
			var swatch := SWATCH.instantiate() as ColourSwatch
			swatch.index = i
			_colours.add_child(swatch)
			swatch.picked.connect(_on_picked)
			_swatches.append(swatch)
	var holders := {}
	var me := roster.id_of(peer)
	for pid: Variant in roster.players:
		var e: Dictionary = roster.players[pid]
		if String(pid) != me and int(e.get("peer", 0)) != 0:
			var who := String(e.get("name", ""))
			holders[int(e.get("colour", -1))] = who if who != "" else ColourSwatch.TAKEN
	for i in _swatches.size():
		_swatches[i].show_state(palette[i], i == colour_index, String(holders.get(i, "")), tuning)


## A free swatch clicked: shown at once, asked of the Host.
func _on_picked(index: int) -> void:
	if roster == null or index == colour_index or _swatches[index].taken:
		return
	colour_index = index
	_fill_colours()
	_dress()
	_ask(Command.new(Roster.COLOUR, peer, roster.id, {"index": index}))


# --- Rows ----------------------------------------------------------------------------------------

## A row stepped: the piece on the preview at once, the whole look asked of the Host.
func _on_stepped(slot: WardrobePiece.Slot, piece: StringName) -> void:
	if roster == null:
		return
	look[WardrobeLook.key(slot)] = piece
	_dress()
	_ask(Command.new(Roster.WEAR, peer, roster.id, Roster.wear_args(look)))


## The Host said no to this player's ask: the page shows the Roster's again (the swatch or row springs back).
func _on_applied(ev: Dictionary) -> void:
	if ev.get("ok", true) or int(ev.get("by", 0)) != peer or not (ev.get("kind") in [Roster.WEAR, Roster.COLOUR]):
		return
	refresh()


func _ask(cmd: Command) -> void:
	if parts != null and is_instance_valid(parts):
		parts.ask(cmd)


## The preview in the page's colour and look; the sample steps the worn Trail.
func _dress() -> void:
	var palette := roster.tuning.colours
	_creature.colour = palette[colour_index] if colour_index >= 0 and colour_index < palette.size() else Color.WHITE
	_creature.look = look.duplicate()
	_sample.look = {&"trail": look[&"trail"]}
