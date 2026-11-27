## The local player's X-rays (docs/architecture/x-rays.md "The shape"): at ready, one XRay child
## (xray.tscn) per XRayAbility file in FOLDER, sorted by `order`, so a dropped ability file is a new
## X-ray with no code. Under the local player in `player.tscn` only: a Teammate's avatar has none
## (only its user sees an X-ray).
class_name XRays
extends Node

## Where the abilities are: every resource file in it is one.
const FOLDER := "res://game/xray/abilities/"
const XRAY := preload("res://game/xray/xray.tscn")


func _ready() -> void:
	for ability in listed():
		var x := XRAY.instantiate() as XRay
		x.ability = ability
		x.name = ability.resource_path.get_file().get_basename().to_pascal_case()
		add_child(x)


## Every ability in FOLDER, sorted by `order` then file name (ResourceLoader.list_directory() lists an
## exported build's remapped files too).
static func listed() -> Array[XRayAbility]:
	var out: Array[XRayAbility] = []
	var files := Array(ResourceLoader.list_directory(FOLDER))
	files.sort()
	for f: String in files:
		if f.ends_with(".tres") or f.ends_with(".res"):
			var a := load(FOLDER + f) as XRayAbility
			if a != null:
				out.append(a)
	out.sort_custom(func(a: XRayAbility, b: XRayAbility) -> bool: return a.order < b.order)
	return out


## Its X-rays, left to right.
func all() -> Array[XRay]:
	var out: Array[XRay] = []
	for child in get_children():
		if child is XRay:
			out.append(child as XRay)
	return out


## The X-ray used by input action `action`, or null.
func of_action(action: StringName) -> XRay:
	for x in all():
		if x.ability != null and x.ability.action == action:
			return x
	return null
