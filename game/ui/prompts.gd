## What one player's screen prompts (core/15, the old prompts.gd): target() is the crosshair's row
## (the thing aimed at, with its key), hints() the corner's (what each key would do right now). Both
## are plain functions of the player's aim and Hands, so they are always current; the player asks
## every frame and the Hud redraws only on a change (A08). The words live here and in the Parts that
## own them (an Openable's noun), never in the player or the Hud.
class_name Prompts
extends RefCounted

## The corner's words (the old game's).
const DROP_THROW := "Drop / hold: Throw"
const ZOOM := "Zoom"
const TURN := "Turn"
const CYCLE := "Cycle"
const JUMP := "Jump"
const CROUCH := "Crouch"


## The keycap of input action `action` (its first keyboard or mouse key, or its first pad glyph when
## `pad`), as a one-item list; empty when it has none.
static func keys(action: StringName, pad := false) -> Array[String]:
	var all := UiIcons.keys_for_action(action, pad)
	var out: Array[String] = []
	if not all.is_empty():
		out.append(all[0])
	return out


## The crosshair's prompts for `player` aiming at Part `part` (null for none), in drawing order: an
## openable reads "Open the X" or "Shut the X" by its state, with the use key (A03, Q2364).
static func target(part: Part, pad := false) -> Array[Prompt]:
	var out: Array[Prompt] = []
	if part is Openable:
		var openable := part as Openable
		if openable.noun != "":
			out.append(Prompt.of(verb_title(openable.open, openable.noun), keys(Player.INTERACT, pad)))
	elif part is UpgradeSwitch:
		out.append(Prompt.of((part as UpgradeSwitch).title(), keys(Player.INTERACT, pad)))
	return out


## The prompt of a part that opens or shuts, by the noun it goes by ("Open the Door").
static func verb_title(open: bool, noun: String) -> String:
	return "%s the %s" % ["Shut" if open else "Open", noun]


## The corner's key hints: what each key does now (A04-A07, Q2361, Q2365). `held` is how many items
## the Hands hold; a held item is always a Sock or a Pair today, so it can zoom and turn.
static func hints(held: int, pad := false) -> Array[Prompt]:
	var out: Array[Prompt] = []
	if held > 0:
		out.append(Prompt.of(DROP_THROW, keys(Player.DROP_THROW, pad)))
		out.append(Prompt.of(ZOOM, keys(Player.ZOOM, pad)))
		out.append(Prompt.of(TURN, keys(Player.TURN, pad)))
	if held > 1:
		out.append(Prompt.of(CYCLE, keys(Player.HANDS_NEXT, pad)))
	out.append(Prompt.of(JUMP, keys(Player.JUMP, pad)))
	out.append(Prompt.of(CROUCH, keys(Player.CROUCH, pad)))
	return out
