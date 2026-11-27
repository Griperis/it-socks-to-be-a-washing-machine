## A stand-in for a carried device's own input (core/163, the held thing's input): put beside a Carriable,
## it records every held_input() it is given and uses the actions named in `uses`.
extends Node

## The actions it says it used (returns true for), pressed ones only.
var uses: Array[StringName] = []
## Every call: [by, action, pressed, held_seconds].
var calls: Array[Array] = []


func held_input(by: int, action: StringName, pressed: bool, held_seconds: float) -> bool:
	calls.append([by, action, pressed, held_seconds])
	return pressed and uses.has(action)


## Whether it was given `action` (`pressed` or released).
func got(action: StringName, pressed: bool) -> bool:
	for c: Array in calls:
		if StringName(c[1]) == action and bool(c[2]) == pressed:
			return true
	return false
