## The Gifts station's zoo-only switches (core/137, docs/architecture/gifts.md "Zoo stations"), one class for its
## three pillars by `mode`:
## - DIAL: a click turns to the next Collection a present can be wrapped in (State `index`, every machine sees it).
## - DROP: "Drop presents": one present per player in the Session for the dial's Collection, through the station's
##   Presents, as a Stage that completed it drops them (the Host's answer is the SpawnedParts' rows).
## - COMPLETE: "Complete a Collection": the clicker owns every piece of the dial's Collection for this Session (the
##   Roster's `own`, never their profile file), so the next drop shows the G1 rule (Q2673): a piece of another
##   unlocked Collection, or a refund piece once none is lacking.
class_name GiftSwitch
extends Part

enum Mode { DIAL, DROP, COMPLETE }

const SWITCH := &"switch"
## The pillars' words. placeholder: zoo wording
const DIAL_WORDS := "Collection: %s"
const DROP_WORDS := "Drop presents: %s"
const COMPLETE_WORDS := "Complete a Collection: own every %s piece"

@export var mode := Mode.DROP
## The station's Presents (DROP).
@export var presents: Presents
## The dial whose Collection DROP and COMPLETE use.
@export var dial: GiftSwitch
## Its pillar's label.
@export var label: Label3D
## How far from it a player may stand to use it, in metres.
@export var reach := 4.0

@export_group("State")
## DIAL: which of Collections.shown() it shows.
@export var index := 0
@export_group("")


func _process(_delta: float) -> void:
	if label != null and label.text != prompt_title():
		label.text = prompt_title()


func prompt_title() -> String:
	var c := collection()
	var shown := c.name if c != null else "?"
	match mode:
		Mode.DIAL:
			return DIAL_WORDS % shown
		Mode.COMPLETE:
			return COMPLETE_WORDS % shown
	return DROP_WORDS % shown


## The Collection the dial shows.
func collection() -> SockCollection:
	if mode != Mode.DIAL:
		return dial.collection() if dial != null else null
	var all := Collections.shown()
	return all[posmod(index, all.size())] if not all.is_empty() else null


func use(player: int) -> void:
	if mode == Mode.COMPLETE:
		_own_all(player)
		return
	parts.ask(Command.new(SWITCH, player, id, {}))


func accepts() -> Dictionary[StringName, Dictionary]:
	return {SWITCH: {"args": {}, "rate": 4}}


func decide(cmd: Command) -> Dictionary:
	if cmd.kind != SWITCH:
		return refuse("wrong")
	if not parts.near(cmd.by, get_parent(), reach):
		return refuse("far")
	match mode:
		Mode.DIAL:
			return grant({"index": posmod(index + 1, maxi(Collections.shown().size(), 1))})
		Mode.DROP:
			var c := collection()
			if presents == null or c == null:
				return refuse("wrong")
			var one: Array[StringName] = [c.id]
			var drop := presents.drop(one)
			if drop.is_empty():
				return refuse("already")
			return {"ok": true, "changes": drop["changes"], Presents.DROPPED: drop[Presents.DROPPED]}
	return refuse("wrong")


## The clicker asks the Roster to own each piece of the dial's Collection they lack.
func _own_all(player: int) -> void:
	var c := collection()
	var roster := parts.find(func(p: Part) -> bool: return p is Roster) as Roster
	if c == null or roster == null:
		return
	var have := roster.owned_of(roster.id_of(player))
	for piece in PresentDraw.pieces_of(c.id):
		if not have.has(String(piece.id)):
			parts.ask(Command.new(Roster.OWN, player, roster.id, {"piece": piece.id}))
