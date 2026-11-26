## A zoo switch at the Wardrobe station (core/128, core/141): one per slot. Using it (E) asks the real
## `wear` of the Roster for the player who used it: their look with this slot on the next piece of its
## row they own (every shown owned piece, then none, then round again), as the Wardrobe page steps a row.
## The Host decides; the switch keeps no state of its own. Looks only, on every machine: its label names
## this machine's own player's piece of the slot, and the stand-in Teammate (`wearer`) walks the loop in
## this machine's own player's look, since the own body in first person shows no hat or clothes.
class_name WardrobeSwitch
extends Part

## Where the Looks' label is, from this part.
const LABEL := ^"../Looks/Label"
## The slots' names on the switch.
const SLOT_NAMES: Array[String] = ["Hat", "Clothes", "Socks", "Trail"]

## The slot it steps through.
@export var slot := WardrobePiece.Slot.HAT
## The stand-in Teammate that shows this machine's own look.
@export var wearer: Avatar

var _roster: Roster = null


## The piece after `id` in this slot's row of shown pieces in `owned`; none after the last, the first
## after none.
func next_after(id: StringName, owned: PackedStringArray) -> StringName:
	var row: Array[StringName] = []
	for p in Wardrobe.row(slot):
		if Wardrobe.shown(p) and owned.has(String(p.id)):
			row.append(p.id)
	var i := row.find(id)
	if i + 1 < row.size():
		return row[i + 1]
	return &""


## The piece this machine's own player wears in this slot (&"" for none).
func piece() -> StringName:
	var roster := _find_roster()
	if roster == null:
		return &""
	return WardrobeLook.clean(roster.look_of(multiplayer.get_unique_id()))[WardrobeLook.key(slot)]


func prompt_title() -> String:
	var worn := piece()
	return "%s: %s" % [SLOT_NAMES[slot], Wardrobe.piece_name(worn) if worn != &"" else "None"]


func use(player: int) -> void:
	var roster := _find_roster()
	if roster == null:
		return
	var look := WardrobeLook.clean(roster.look_of(player))
	var k := WardrobeLook.key(slot)
	look[k] = next_after(look[k], roster.owned_of(roster.id_of(player)))
	parts.ask(Command.new(Roster.WEAR, player, roster.id, Roster.wear_args(look)))


func decide(_cmd: Command) -> Dictionary:
	return refuse("wrong")


func _ready() -> void:
	_show(true)


func _show(_now: bool) -> void:
	var label := get_node_or_null(LABEL) as Label3D
	if label != null:
		label.text = prompt_title()
	var roster := _find_roster()
	if wearer != null and wearer.looks != null and roster != null:
		wearer.looks.look = roster.look_of(multiplayer.get_unique_id())


## The Roster, once this part is bound (the link's, read through the level's Parts); its changes show.
func _find_roster() -> Roster:
	if _roster != null and is_instance_valid(_roster):
		return _roster
	_roster = parts.find(func(part: Part) -> bool: return part is Roster) as Roster if parts != null else null
	if _roster != null and not _roster.changed.is_connected(_on_roster_changed):
		_roster.changed.connect(_on_roster_changed)
	return _roster


func _on_roster_changed() -> void:
	_show(false)
