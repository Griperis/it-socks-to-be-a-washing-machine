## What the Host's answers sound like (core/25): one place that turns an answer of Parts (the `applied`
## signal) into the sound and the pad rumble of that moment. A player's own moments (a pick, a pair, a
## cycle, a drop, a throw) play flat for the player they are answered to; everyone else hears a pick, a
## pair, a drop and a throw as loud, in the world at 1.2 m over that Teammate's feet (coop/05, Q2453;
## a cycle is the player's own). A Pair shelved is heard in the world at its drawer by everyone, and a
## leaver's dropped Hands at their last place. Refusals are said by Player.say(), which plays "refuse".
## Looks only: it reads the answer and decides nothing.
class_name Hearing
extends RefCounted

## A Teammate's cues play this far over their feet (the old sound_installer.gd).
const CUE_HEIGHT := 1.2


## An answer `ev` of `parts` reached this machine, whose own player is `me`.
static func applied(ev: Dictionary, me: int, parts: Parts) -> void:
	if not ev.get("ok", false):
		return
	# core/16 P12b (core/25 W15): a lost Sock or Pair came back; everyone hears a pop at each.
	var popped: Variant = ev.get(Mess.POPPED)
	if popped is PackedVector3Array:
		for at: Vector3 in popped:
			Sounds.play_at(&"lost_pop", at)
	var by := int(ev.get("by", 0))
	var own := by == me
	match StringName(ev.get("kind", &"")):
		&"pick":
			if own and ev.has("paired"):
				Sounds.play(&"pair")
				PadRumble.play(PadRumble.PAIR)
			elif own:
				Sounds.play(&"pick")
			else:
				_teammate(&"pair" if ev.has("paired") else &"pick", by, parts)
		&"cycle":
			if own:
				Sounds.play(&"cycle")
		&"drop":
			if own:
				Sounds.play(&"drop")
			else:
				_teammate(&"drop", by, parts)
		&"throw":
			if own:
				Sounds.play(&"throw")
				PadRumble.play(PadRumble.THROW)
			else:
				_teammate(&"throw", by, parts)
		&"shelve", &"thrown_shelve":
			_shelved(ev, parts)
		&"left":
			# coop/03: a leaver's Hands dropped where they stood; everyone still here hears it once,
			# there (coop/05).
			if ev.get("dropped_at") is Vector3:
				Sounds.play_from(&"drop", (ev["dropped_at"] as Vector3) + Vector3.UP * CUE_HEIGHT)


## Teammate `by`'s cue `name`, as loud as one's own, at 1.2 m over where they stand on this machine;
## nothing when this machine cannot place them.
static func _teammate(name: StringName, by: int, parts: Parts) -> void:
	var at: Variant = parts.where.call(by) if parts != null and parts.where.is_valid() else null
	if at is Vector3:
		Sounds.play_from(name, (at as Vector3) + Vector3.UP * CUE_HEIGHT)


## A Pair went into a drawer: "shelve" at the first drawer it went into.
static func _shelved(ev: Dictionary, parts: Parts) -> void:
	var cabinet := parts.of(StringName(ev.get("to", &""))) as Cabinet if parts != null else null
	var paid: Array = ev.get("paid", [])
	if cabinet == null or paid.is_empty():
		return
	var drawer := cabinet.drawer(int((paid[0] as Dictionary)["drawer"]))
	var spot := drawer.get_parent() as Node3D if drawer != null else null
	if spot != null and spot.is_inside_tree():
		Sounds.play_at(&"shelve", spot.global_position)
