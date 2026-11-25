## What one player's screen prompts (core/15, the old prompts.gd): target() is the crosshair's row
## (the thing aimed at, with its key), hints() the corner's (what each key would do right now). Both
## are plain functions of the player's aim and Hands, so they are always current; the player asks
## every frame and the Hud redraws only on a change (A08). The words live here and in the Parts that
## own them (an Openable's noun), never in the player or the Hud.
class_name Prompts
extends RefCounted

## The corner's words (the old game's).
const DROP_THROW := "Drop / hold: Throw"
## What the right click does to a carried thing (the old prompts.gd's "Drop" for what is not thrown).
const DROP := "Drop"
const ZOOM := "Zoom"
const TURN := "Turn"
const CYCLE := "Cycle"
const JUMP := "Jump"
const CROUCH := "Crouch"
## Pinging works (core/43 line 56, Q2590: only this one, no hold hint).
const PING := "Ping"
## A lying Teammate under the crosshair, and a dragged player's one hint (coop/10, the old prompts.gd, Q2489).
const DRAG := "Hold: Drag"
const STRUGGLE := "Mash: Struggle"


## The keycap of input action `action` (its first keyboard or mouse key, or its first pad glyph when
## `pad`), as a one-item list; empty when it has none.
static func keys(action: StringName, pad := false) -> Array[String]:
	var all := UiIcons.keys_for_action(action, pad)
	var out: Array[String] = []
	if not all.is_empty():
		out.append(all[0])
	return out


## The crosshair's prompts for the player aiming at Part `part` (null for none), in drawing order,
## each with the use key (A03, Q2364, Q2388): the Door reads "Open the Door" or "Shut the Door" by its
## state (its `noun`); a Cabinet's drawer its Cabinet's name and "drawer" with the Collection's icon
## ("Simple Cabinet Drawer", the old cabinet.gd); any other openable its own name ("Cupboard A
## Drawer": its `title`, else the name of the thing it is on, as the old room.gd named it).
static func target(part: Part, pad := false) -> Array[Prompt]:
	var out: Array[Prompt] = []
	if part is Openable:
		out.append(openable_prompt(part as Openable, pad))
	elif part != null and part.hint_only() and part.prompt_title() != "":
		out.append(Prompt.of(part.prompt_title()))
	elif part != null and part.prompt_title() != "":
		out.append(Prompt.of(part.prompt_title(), keys(Player.PICK if part.click_only() else Player.INTERACT, pad)))
	return out


## The crosshair's row for a carried thing (core/78, the old prompts.gd's bin): `carried`'s name with
## no key while it is carried; else the aimed lying `aimed`'s name with the click key when `empty`
## Hands may pick it up, without it otherwise.
static func carry_target(aimed: Carriable, carried: Carriable, empty: bool, pad := false) -> Array[Prompt]:
	var out: Array[Prompt] = []
	var no_key: Array[String] = []
	if carried != null:
		if carried.prompt_title() != "":
			out.append(Prompt.of(carried.prompt_title(), no_key))
	elif aimed != null and aimed.prompt_title() != "":
		out.append(Prompt.of(aimed.prompt_title(), keys(Player.PICK, pad) if empty else no_key))
	return out


## The crosshair's row for the washing machine's slot while a Machine Part is carried (core/79, the old
## prompts.gd): "Fit the new filter" with the click key.
static func fit_prompt(carried: Carriable, pad := false) -> Prompt:
	return Prompt.of("Fit the %s" % carried.prompt_title().to_lower(), keys(Player.PICK, pad))


## An openable's prompt (target()).
static func openable_prompt(openable: Openable, pad := false) -> Prompt:
	var use := keys(Player.INTERACT, pad)
	if openable.noun != "":
		return Prompt.of(verb_title(openable.open, openable.noun), use)
	var cabinet := Cabinet.of(openable)
	if cabinet != null and cabinet != openable:
		var catalogue := cabinet.hands.mess.catalogue if cabinet.hands != null and cabinet.hands.mess != null else null
		var cabinet_name := catalogue.cabinet_name(cabinet.collection) if catalogue != null else String(cabinet.collection)
		return Prompt.of(("%s drawer" % cabinet_name).capitalize(), use, String(cabinet.collection))
	var own := openable.title
	if own == "" and openable.get_parent() != null:
		own = String(openable.get_parent().name).capitalize()
	return Prompt.of(own, use)


## The prompt of a part that opens or shuts, by the noun it goes by ("Open the Door").
static func verb_title(open: bool, noun: String) -> String:
	return "%s the %s" % ["Shut" if open else "Open", noun]


## The corner's key hints: what each key does now (A04-A07, Q2361, Q2365). `held` is how many items
## the Hands hold; a held item is always a Sock or a Pair today, so it can zoom and turn. With `ping`
## (pinging works) "Ping" stands after "Cycle", before "Jump" (core/43 line 56).
static func hints(held: int, pad := false, ping := false, carrying := false) -> Array[Prompt]:
	var out: Array[Prompt] = []
	if carrying:
		out.append(Prompt.of(DROP, keys(Player.DROP_THROW, pad)))  # core/78: a carried thing only goes down
	if held > 0:
		out.append(Prompt.of(DROP_THROW, keys(Player.DROP_THROW, pad)))
		out.append(Prompt.of(ZOOM, keys(Player.ZOOM, pad)))
		out.append(Prompt.of(TURN, keys(Player.TURN, pad)))
	if held > 1:
		out.append(Prompt.of(CYCLE, keys(Player.HANDS_NEXT, pad)))
	if ping:
		out.append(Prompt.of(PING, keys(Pinger.CLICK_MIDDLE, pad)))
	out.append(Prompt.of(JUMP, keys(Player.JUMP, pad)))
	out.append(Prompt.of(CROUCH, keys(Player.CROUCH, pad)))
	return out


## The crosshair's prompt on a lying Teammate with empty Hands: "Hold: Drag" with the left button (H91).
static func drag_prompt(pad := false) -> Prompt:
	return Prompt.of(DRAG, keys(Player.PICK, pad))


## A dragged player's corner hint: "Mash: Struggle" with the jump key, no count (H105, Q2489).
static func struggle_hint(pad := false) -> Prompt:
	return Prompt.of(STRUGGLE, keys(Player.JUMP, pad))
