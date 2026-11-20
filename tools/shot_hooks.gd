## What this game adds to shots (kit/docs/TESTING.md "The shot harness").
extends RefCounted


## The game's own --do actions. Return true when `what` was handled.
static func act(world: Node, what: String, arg: String) -> bool:
	match what:
		"throw_charge":
			# The zoo's player steps onto the handling station, takes its first Sock and holds the
			# drop button: the Throw's ring starts filling after the tap (core/08).
			var player := world.get_node("Player") as Player
			var hands := world.get_node("Socks/Hands") as Hands
			var station := world.get_node("Stations/Handling") as Node3D
			player.global_position = station.global_position + Vector3(0.0, 0.0, 1.5)
			player.rotation.y = 0.0
			hands.pick(player.player_id(), (station.get_node("Spots/Floor") as SockSpot).sock)
			Input.action_press(Player.DROP_THROW)
			return true
		"every_sock":
			# A camera over the every-Sock station (core/12): arg "overview" looks down on all of
			# it, "row" stands at the first row's start and looks along it.
			var station := world.get_node("Stations/EverySock") as Node3D
			var cam := Camera3D.new()
			world.add_child(cam)
			cam.fov = 70.0
			if arg == "overview":
				cam.global_position = station.to_global(Vector3(0.0, 32.0, 10.0))
				cam.look_at(station.to_global(Vector3(0.0, 0.0, -18.0)))
			else:
				cam.global_position = station.to_global(Vector3(-10.0, 1.6, 2.2))
				cam.look_at(station.to_global(Vector3(-11.5, 0.0, -0.4)))
			cam.make_current()
			return true
		"pair_first", "pair_mate":
			# The zoo's player steps onto the handling station and takes its first Sock, then (a
			# grab interval later) that Sock's mate: the pairing moment plays in the Hands (core/03).
			var player := world.get_node("Player") as Player
			var hands := world.get_node("Socks/Hands") as Hands
			var station := world.get_node("Stations/Handling") as Node3D
			if what == "pair_first":
				player.global_position = station.global_position + Vector3(0.0, 0.0, 1.5)
				player.rotation.y = 0.0
				hands.pick(player.player_id(), (station.get_node("Spots/Floor") as SockSpot).sock)
			else:
				hands.pick(player.player_id(), (station.get_node("Spots/MateFloor") as SockSpot).sock)
			return true
	return false
