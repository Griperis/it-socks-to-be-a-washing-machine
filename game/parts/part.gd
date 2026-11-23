## One ability of a thing (it can be opened, it can be carried), with its state. A thing is a scene;
## its abilities are child nodes extending Part. State is every field under
## `@export_group("State")`: the inspector shows it, a save and a late Guest receive it, and only
## Parts writes it, with the Host's answer or a whole snapshot.
##
## Who may call what: decide() only Parts.answer(), on the Host; write() only Parts; _show() only
## write(); use() the player's input; state() and state_names() anyone; accepts() the Host's
## Session, before a Guest's Command reaches decide().
@abstract
class_name Part
extends Node

const STATE_GROUP := "State"

## The state field names of each script, read once from the inspector's property list: {Script: names}.
static var _names_by_script: Dictionary[Script, PackedStringArray] = {}

## This part's name on the wire and in a save: its node path from the level ("Room/Door/Openable").
var id: StringName
## The level's Parts, which asks the Host for this part. Set by Parts.bind().
var parts: Parts


## The Host's answer to `cmd`. Reads, never writes: returns grant(...) or refuse(...).
@abstract func decide(cmd: Command) -> Dictionary


## What a Guest may ask of this part, per verb: {&"verb": {"args": {"name": TYPE_BOOL, ...},
## "rate": a most per second per player}}. An arg is a type from Command.ARG_TYPES, or
## {"type": ..., "min": ..., "max": ...} (Command.args_error()); "rate" is optional
## (Session.RATE). The Host drops a Guest's Command for a verb not here, or whose args differ.
## The Host's own Commands are not checked against it.
func accepts() -> Dictionary[StringName, Dictionary]:
	return {}


## The words of this thing's crosshair prompt when the player aims at it; "" for no prompt of its own
## (an Openable's prompt is made by Prompts.openable_prompt).
func prompt_title() -> String:
	return ""


## Whether the crosshair may rest on this thing now: false hides it from the aim (no outline, no
## prompt, no use), as a Cabinet under its dust sheet (Q2513).
func aimable() -> bool:
	return true


## Whether this thing is used by the left click alone (a piano key, the old game's click-only
## Station): the use key does nothing on it and its prompt shows the left button.
func click_only() -> bool:
	return false


## What the player's use button does to this thing: it asks (parts.ask), never writes.
func use(_by: int) -> void:
	pass


## Looks only: make the nodes show the state. `now`: the state arrived whole (bind, a late Guest,
## a load), so jump to it with no animation. Never writes state.
func _show(_now: bool) -> void:
	pass


## This machine was a Guest and decides alone now (it left, or its Host quit; coop/12): whatever it
## showed as looks only becomes its own. Looks only: never writes state.
func went_alone() -> void:
	pass


## The Host: what player `by` leaving does to this part, as grant(...); {} for nothing.
func left(_by: int) -> Dictionary:
	return {}


## What this part keeps in a save (docs/architecture/saves.md): whole_state() by default; {} keeps
## nothing (who lies knocked down now is not kept). Never writes state.
func save_state() -> Dictionary:
	return whole_state()


## The version of save_state()'s shape (Q2557): raise it when a State field is added, renamed or
## changes type, and teach upgrade_save() the step. tests/save_test.gd keeps every part's shape beside
## its number and fails when the shape changes but the number does not.
func save_version() -> int:
	return 1


## A saved state of version `from` brought to version `from + 1` (the steps run one at a time up to
## save_version()). A field the save lacks keeps the scene's own value (write() sets only what it gets).
func upgrade_save(state: Dictionary, _from: int) -> Dictionary:
	return state


## The Host, as a save loads: the state to write, made from the saved one (at this part's version)
## and what the part holds now. The saved state as it is by default; the Roster merges (core/62).
## Never writes state.
func restored(saved: Dictionary) -> Dictionary:
	return saved


## The Host, after a save is loaded: what a load resets (Q2559), as grant(...); {} for nothing. Kept
## beside the thing it resets (a Door shuts, absent players' Socks drop). `host`: the Host's player id.
func loaded(_host: String) -> Dictionary:
	return {}


## The names of the state fields, read from the "State" group of the inspector (once per script:
## a part's script does not change while the game runs).
func state_names() -> PackedStringArray:
	var script := get_script() as Script
	if _names_by_script.has(script):
		return _names_by_script[script]
	var names := PackedStringArray()
	var inside := false
	for p: Dictionary in get_property_list():
		if int(p["usage"]) & PROPERTY_USAGE_GROUP:
			inside = p["name"] == STATE_GROUP
		elif inside and int(p["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			names.append(p["name"])
	_names_by_script[script] = names
	return names


## The state as plain values, by field name.
func state() -> Dictionary:
	var d := {}
	for n in state_names():
		d[n] = get(n)
	return d


## The state as it is sent whole (a late Guest's snapshot, a save): state(), unless a part packs it
## smaller (the Mess, coop/08). write() with `now` takes it back.
func whole_state() -> Dictionary:
	return state()


## The one writer of state. Called only by Parts: with the Host's answer, or a whole snapshot.
func write(patch: Dictionary, now: bool) -> void:
	var names := state_names()
	for key: Variant in patch:
		if String(key) in names:
			set(String(key), patch[key])
		else:
			Log.error("parts", "%s has no state field %s" % [id, key])
	_show(now)


## A yes: these fields of this part take these values on every machine.
func grant(patch: Dictionary) -> Dictionary:
	return {"ok": true, "changes": {id: patch}}


## A no, and why ("locked", "gone", "full", "already", "wrong").
func refuse(why: String) -> Dictionary:
	return {"ok": false, "reason": why}
