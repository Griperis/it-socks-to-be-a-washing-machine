## A player's wish to change one thing ("open Room/Door/Openable"). It goes to the Host, who answers
## it; nothing changes until the answer comes back. A Command names its target part by id (the
## part's node path from the level), so routing it is one lookup.
class_name Command
extends RefCounted

## The most args one Command may carry, and the longest String on the wire.
const ARGS_MAX := 16
const TEXT_MAX := 256
## The largest seq a Command may carry.
const SEQ_MAX := (1 << 30)
## The arg types a part may declare (Part.accepts()); none of them can carry an Object.
const ARG_TYPES: Array[int] = [TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_STRING_NAME, TYPE_VECTOR2, TYPE_VECTOR3]

## What is asked: a verb the target part knows (&"open", &"pick", &"drop").
var kind: StringName
## Who asks: a player id (the Host is 1). On the Host it is the sender's, never read off the wire.
var by: int
## The id of the part asked (Part.id).
var to: StringName
## Plain values only (plain_value()), by name.
var args: Dictionary
## The asker's own number for it (coop/09), echoed in the Host's answer as "seq" so a Guest's ghost
## knows its answer; 0 when nobody waits on it. Never read for a rule of play.
var seq := 0


func _init(p_kind: StringName, p_by: int, p_to: StringName, p_args: Dictionary = {}) -> void:
	kind = p_kind
	by = p_by
	to = p_to
	args = p_args


## What travels up to the Host. `by` is left out: the Host knows who sent it.
func to_wire() -> Array:
	return [String(kind), String(to), args, seq]


## The Host's reading of a Guest's wire form, or null when it is malformed (shape_error()).
static func from_wire(wire: Variant, sender: int) -> Command:
	if shape_error(wire) != "":
		return null
	var w: Array = wire
	var cmd := Command.new(StringName(w[0]), sender, StringName(w[1]), w[2])
	if w.size() == 4:
		cmd.seq = int(w[3])
	return cmd


## Why `wire` is not a Command's wire form, or "": [kind, to, args] or [kind, to, args, seq] with
## short Strings, at most ARGS_MAX plain values in args and a seq from 0 to SEQ_MAX. Rules of play (is
## that kind known, may this player do it) are the target part's decide(), not this.
static func shape_error(wire: Variant) -> String:
	if not (wire is Array) or (wire as Array).size() < 3 or (wire as Array).size() > 4:
		return "not [kind, to, args, seq]"
	var w: Array = wire
	if w.size() == 4 and (not (w[3] is int) or int(w[3]) < 0 or int(w[3]) > SEQ_MAX):
		return "seq is not an int from 0 to %d" % SEQ_MAX
	for i in 2:
		if not (w[i] is String) or (w[i] as String).is_empty() or (w[i] as String).length() > TEXT_MAX:
			return "member %d is not a short String" % i
	if not (w[2] is Dictionary) or (w[2] as Dictionary).size() > ARGS_MAX:
		return "args is not a Dictionary of at most %d" % ARGS_MAX
	var args_in: Dictionary = w[2]
	for key: Variant in args_in:
		if not (key is String) or (key as String).length() > TEXT_MAX:
			return "an arg name is not a short String"
		if not plain_value(args_in[key]):
			return "arg %s is not a plain value" % (key as String).left(40)
	return ""


## Whether `v` may travel in args: bool, int, a finite float, a short String or StringName, a
## finite Vector2 or Vector3.
static func plain_value(v: Variant) -> bool:
	if v is bool or v is int:
		return true
	if v is float:
		return is_finite(v)
	if v is String or v is StringName:
		return String(v).length() <= TEXT_MAX
	if v is Vector2:
		return (v as Vector2).is_finite()
	if v is Vector3:
		return (v as Vector3).is_finite()
	return false


## Why `p_args` does not match `declared` exactly, or "". `declared` is a verb's "args" from
## Part.accepts(): a name (a String) -> a type (TYPE_BOOL) or {"type": ..., "min": ..., "max": ...}. Every
## declared name must be there and no other; "min"/"max" bound a number or each component of a
## vector, "max" alone the length of a String.
static func args_error(p_args: Dictionary, declared: Dictionary) -> String:
	for key: Variant in p_args:
		if not declared.has(String(key)):
			return "an extra arg %s" % String(key).left(40)
	for key: Variant in declared:
		var arg := String(key)
		if not p_args.has(arg):
			return "no arg %s" % arg
		var why := arg_error(p_args[arg], declared[key])
		if why != "":
			return "%s %s" % [arg, why]
	return ""


## Why `v` does not match one declared arg `spec` (see args_error()), or "".
static func arg_error(v: Variant, spec: Variant) -> String:
	var d: Dictionary = spec if spec is Dictionary else {"type": spec}
	var want := int(d.get("type", TYPE_NIL))
	if want not in ARG_TYPES:
		return "has an undeclarable type %s" % type_string(want)
	var text := want == TYPE_STRING or want == TYPE_STRING_NAME
	if not plain_value(v) or (typeof(v) != want and not (text and (v is String or v is StringName))):
		return "is not a %s" % type_string(want)
	if text:
		return "" if String(v).length() <= int(d.get("max", TEXT_MAX)) else "is too long"
	var low := float(d.get("min", -INF))
	var high := float(d.get("max", INF))
	var numbers: Array[float] = []
	if v is Vector2:
		numbers = [(v as Vector2).x, (v as Vector2).y]
	elif v is Vector3:
		numbers = [(v as Vector3).x, (v as Vector3).y, (v as Vector3).z]
	elif v is int or v is float:
		numbers = [float(v)]
	for n in numbers:
		if n < low or n > high:
			return "is out of [%s, %s]" % [low, high]
	return ""
