## A zoo switch at the Wardrobe station (core/128): one per slot, each use puts the next piece of its slot's
## row on the stand-in Teammate (every shown piece, then none, then round again). Its state is the piece it
## picked; the Host decides the next one; every machine dresses the stand-in from it. Until core/141's
## `wear` exists it sets the stand-in's look directly; core/141 points it at `wear`.
class_name WardrobeSwitch
extends Part

const SWITCH := &"wardrobe_switch"
## Where the Looks' label is, from this part.
const LABEL := ^"../Looks/Label"
## The slots' names on the switch.
const SLOT_NAMES: Array[String] = ["Hat", "Clothes", "Socks", "Trail"]

## The slot it steps through.
@export var slot := WardrobePiece.Slot.HAT
## The stand-in Teammate it dresses.
@export var wearer: Avatar
## How far from it a player may stand to use it, in metres.
@export var reach := 4.0

@export_group("State")
## The piece it put on (&"" for none).
@export var piece: StringName = &""
@export_group("")


## The piece after `id` in this slot's row of shown pieces; none after the last, the first after none.
func next_after(id: StringName) -> StringName:
	var row: Array[StringName] = []
	for p in Wardrobe.row(slot):
		if Wardrobe.shown(p):
			row.append(p.id)
	var i := row.find(id)
	if i + 1 < row.size():
		return row[i + 1]
	return &""


func prompt_title() -> String:
	return "%s: %s" % [SLOT_NAMES[slot], Wardrobe.piece_name(piece) if piece != &"" else "None"]


func use(player: int) -> void:
	parts.ask(Command.new(SWITCH, player, id, {}))


func accepts() -> Dictionary[StringName, Dictionary]:
	return {SWITCH: {"args": {}, "rate": 4}}


func decide(cmd: Command) -> Dictionary:
	if cmd.kind != SWITCH:
		return refuse("wrong")
	if not parts.near(cmd.by, get_parent(), reach):
		return refuse("far")
	return grant({"piece": next_after(piece)})


func _ready() -> void:
	_show(true)


func _show(_now: bool) -> void:
	var label := get_node_or_null(LABEL) as Label3D
	if label != null:
		label.text = prompt_title()
	if wearer == null or wearer.looks == null:
		return
	var look := WardrobeLook.clean(wearer.looks.look)
	look[WardrobeLook.key(slot)] = piece
	wearer.looks.look = look
