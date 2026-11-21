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


## What the player's use button does to this thing: it asks (parts.ask), never writes.
func use(_by: int) -> void:
	pass


## Looks only: make the nodes show the state. `now`: the state arrived whole (bind, a late Guest,
## a load), so jump to it with no animation. Never writes state.
func _show(_now: bool) -> void:
	pass


## The Host: what player `by` leaving does to this part, as grant(...); {} for nothing.
func left(_by: int) -> Dictionary:
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


## The one writer of state. Called only by Parts: with the Host's answer, or a whole snapshot.
func write(patch: Dictionary, now: bool) -> void:
	var names := state_names()
	for key: Variant in patch:
		if String(key) in names:
			set(String(key), patch[key])
		else:
			push_error("%s has no state field %s" % [id, key])
	_show(now)


## A yes: these fields of this part take these values on every machine.
func grant(patch: Dictionary) -> Dictionary:
	return {"ok": true, "changes": {id: patch}}


## A no, and why ("locked", "gone", "full", "already", "wrong").
func refuse(why: String) -> Dictionary:
	return {"ok": false, "reason": why}
