## What this game adds to shots (kit/docs/TESTING.md "The shot harness").
extends RefCounted


## The game's own --do actions. Return true when `what` was handled.
static func act(world: Node, what: String, _arg: String) -> bool:
	match what:
		"throw_charge":
			# The zoo's player steps onto the handling station, takes its first Sock and holds the
			# drop button: the Throw's ring starts filling after the tap (core/08).
			var player := world.get_node("Player") as Player
			var hands := world.get_node("Stations/Handling/Socks/Hands") as Hands
			var station := hands.get_parent().get_parent() as Node3D
			player.global_position = station.global_position + Vector3(0.0, 0.0, 1.5)
			player.rotation.y = 0.0
			hands.pick(player.player_id(), 0)
			Input.action_press(Player.DROP_THROW)
			return true
		"pair_first", "pair_mate":
			# The zoo's player steps onto the handling station and takes its first Sock, then (a
			# grab interval later) that Sock's mate: the pairing moment plays in the Hands (core/03).
			var player := world.get_node("Player") as Player
			var hands := world.get_node("Stations/Handling/Socks/Hands") as Hands
			var station := hands.get_parent().get_parent() as Node3D
			if what == "pair_first":
				player.global_position = station.global_position + Vector3(0.0, 0.0, 1.5)
				player.rotation.y = 0.0
				hands.pick(player.player_id(), 0)
			else:
				hands.pick(player.player_id(), 6)
			return true
	return false
