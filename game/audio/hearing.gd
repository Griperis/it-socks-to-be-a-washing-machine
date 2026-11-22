## What the Host's answers sound like (core/25): one place that turns an answer of Parts (the `applied`
## signal) into the sound and the pad rumble of that moment. A player's own moments (a pick, a pair, a
## cycle, a drop, a throw) play flat and only for the player they are answered to; a Pair shelved is
## heard in the world at its drawer by everyone. Refusals are said by Player.say(), which plays
## "refuse". Looks only: it reads the answer and decides nothing.
class_name Hearing
extends RefCounted


## An answer `ev` of `parts` reached this machine, whose own player is `me`.
static func applied(ev: Dictionary, me: int, parts: Parts) -> void:
	if not ev.get("ok", false):
		return
	# core/16 P12b (core/25 W15): a lost Sock or Pair came back; everyone hears a pop at each.
	var popped: Variant = ev.get(Mess.POPPED)
	if popped is PackedVector3Array:
		for at: Vector3 in popped:
			Sounds.play_at(&"lost_pop", at)
	var own := int(ev.get("by", 0)) == me
	match StringName(ev.get("kind", &"")):
		&"pick":
			if own and ev.has("paired"):
				Sounds.play(&"pair")
				PadRumble.play(PadRumble.PAIR)
			elif own:
				Sounds.play(&"pick")
		&"cycle":
			if own:
				Sounds.play(&"cycle")
		&"drop":
			if own:
				Sounds.play(&"drop")
		&"throw":
			if own:
				Sounds.play(&"throw")
				PadRumble.play(PadRumble.THROW)
		&"shelve", &"thrown_shelve":
			_shelved(ev, parts)
		&"left":
			# coop/03: a leaver's Hands dropped where they stood; everyone still here hears it once.
			if ev.get("dropped_at") is Vector3:
				Sounds.play(&"drop")


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
