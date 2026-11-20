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
		"sounds":
			# A camera over the Sounds station's buttons (core/22): arg "overview" looks down on the
			# whole station, "block" from above the button block.
			var station := world.get_node("Stations/Sounds") as Node3D
			var cam := Camera3D.new()
			world.add_child(cam)
			cam.fov = 60.0
			if arg == "overview":
				cam.global_position = station.to_global(Vector3(0.0, 12.0, 6.0))
				cam.look_at(station.to_global(Vector3(0.0, 0.0, -0.5)))
			else:
				cam.global_position = station.to_global(Vector3(0.0, 4.2, 2.2))
				cam.look_at(station.to_global(Vector3(0.0, 0.0, -0.1)))
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
		"pick_floor", "pick_over":
			# core/09: the zoo's player steps onto the handling station (looking down at its Socks)
			# and takes the Sock on the floor; `pick_over` then takes the one lying over another.
			var player := world.get_node("Player") as Player
			var hands := world.get_node("Socks/Hands") as Hands
			var station := world.get_node("Stations/Handling") as Node3D
			var spot := "Spots/Floor"
			if what == "pick_floor":
				player.global_position = station.global_position + Vector3(0.0, 0.0, 1.5)
				player.rotation.y = 0.0
				(player.get_node("Head") as Node3D).rotation.x = deg_to_rad(-30.0)
				player.reset_physics_interpolation()
			else:
				spot = "Spots/Over"
			hands.pick(player.player_id(), (station.get_node(spot) as SockSpot).sock)
			return true
		"refuse":
			# core/18: the zoo's player takes the first Sock and aims at the open air, where a drop is refused: the
			# crosshair is red and the message shows.
			var player := world.get_node("Player") as Player
			var hands := world.get_node("Socks/Hands") as Hands
			var station := world.get_node("Stations/Handling") as Node3D
			player.global_position = station.global_position + Vector3(0.0, 0.0, 1.5)
			player.rotation.y = 0.0
			(player.get_node("Head") as Node3D).rotation.x = deg_to_rad(8.0)
			player.reset_physics_interpolation()
			hands.pick(player.player_id(), (station.get_node("Spots/Floor") as SockSpot).sock)
			player.say(Player.CANT_DROP)
			return true
		"look_down":
			# The head tilts down at the Socks on the floor (core/09: a fly-in seen from where it lay).
			var player := world.get_node("Player") as Player
			(player.get_node("Head") as Node3D).rotation.x = deg_to_rad(-30.0)
			player.reset_physics_interpolation()
			return true
		"wheel":
			# The next held item becomes active, as a wheel step does.
			var player := world.get_node("Player") as Player
			(world.get_node("Socks/Hands") as Hands).cycle(player.player_id(), 1)
			return true
		"walk", "stop":
			# Walking forward, or standing again.
			if what == "walk":
				Input.action_press(&"move_forward")
			else:
				Input.action_release(&"move_forward")
			return true
		"look_up":
			# The player turns round to the open floor behind, head nearly level, so a held Sock
			# shows against the far floor and a walk meets no wall.
			var player := world.get_node("Player") as Player
			player.rotation.y = PI
			(player.get_node("Head") as Node3D).rotation.x = deg_to_rad(-10.0)
			player.reset_physics_interpolation()
			return true
		"turn_view":
			# The view turns left by 1.2 rad in 0.4 s, as the mouse would.
			var player := world.get_node("Player") as Player
			player.create_tween().tween_property(player, ^"rotation:y", player.rotation.y + 1.2, 0.4)
			return true
		"throw_lob":
			# The held Sock is thrown ahead with a light charge, landing in view.
			var player := world.get_node("Player") as Player
			(player.get_node("Head") as Node3D).rotation.x = deg_to_rad(-25.0)
			var hands := world.get_node("Socks/Hands") as Hands
			hands.throw(player.player_id(), player.aim_dir(), 0.3)
			return true
		"shelve_pair", "shelve_mate", "shelve_click":
			# core/09 D11: the zoo's player stands before the Cabinet station's drawers, takes a
			# Simple Sock and its mate (one Pair), and shelves it by a click on the bottom drawer.
			var player := world.get_node("Player") as Player
			var hands := world.get_node("Socks/Hands") as Hands
			var station := world.get_node("Stations/Cabinet") as Node3D
			match what:
				"shelve_pair":
					player.global_position = station.to_global(Vector3(-1.4, 0.0, -0.3))
					player.rotation.y = deg_to_rad(-10.0)
					(player.get_node("Head") as Node3D).rotation.x = deg_to_rad(-22.0)
					player.reset_physics_interpolation()
					hands.pick(player.player_id(), (station.get_node("Spots/Simple0") as SockSpot).sock)
				"shelve_mate":
					hands.pick(player.player_id(), (station.get_node("Spots/Simple0Mate") as SockSpot).sock)
				_:
					(station.get_node("Cabinet/Cabinet") as Cabinet).click(player.player_id(), 0)
			return true
		"drawer_view", "drawer_use":
			# core/09 D12: the zoo's player looks at the Cabinet station's bottom drawer from the
			# side; `drawer_use` opens or shuts it, as a click with empty Hands does.
			var player := world.get_node("Player") as Player
			var station := world.get_node("Stations/Cabinet") as Node3D
			if what == "drawer_view":
				player.global_position = station.to_global(Vector3(0.6, 0.0, -0.6))
				player.rotation.y = deg_to_rad(40.0)
				(player.get_node("Head") as Node3D).rotation.x = deg_to_rad(-30.0)
				player.reset_physics_interpolation()
			else:
				(station.get_node("Cabinet/Cabinet") as Cabinet).drawer(0).use(player.player_id())
			return true
	return false
