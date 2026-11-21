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
		"house_kit":
			# A camera on the house kit station (house/02): "lineup" (every piece from above), "walls",
			# "openings", "floors", "roof_pieces" (rows of the line-up), "room" (the U room from
			# above), "door" (the front door's frame from inside), "window" (the landing's window and
			# frame from inside), "corner" (the upper floor's corner: a floor meets two walls, K14),
			# "stair" (the U stair from the hall), "roof" (the roof corner with the dormer from outside),
			# "dormer" (the dormer from inside the attic corner).
			var station := world.get_node("Stations/HouseKit") as Node3D
			var views := {
				"lineup": [Vector3(-20.0, 34.0, 50.0), Vector3(-20.0, 0.0, 24.0)],
				"walls": [Vector3(-23.0, 7.0, 15.0), Vector3(-23.0, 0.5, 8.0)],
				"openings": [Vector3(-23.0, 7.0, 18.0), Vector3(-23.0, 0.5, 11.0)],
				"floors": [Vector3(-23.0, 7.0, 21.0), Vector3(-23.0, 0.5, 14.0)],
				"roof_pieces": [Vector3(-21.0, 9.0, 33.0), Vector3(-21.0, 1.0, 21.0)],
				"room": [Vector3(7.5, 10.0, -8.5), Vector3(2.0, 2.0, 1.0)],
				"door": [Vector3(2.0, 1.5, -0.6), Vector3(2.75, 1.0, -3.0)],
				"window": [Vector3(2.4, 4.6, -1.0), Vector3(2.25, 4.4, -3.0)],
				"corner": [Vector3(2.4, 4.4, -1.6), Vector3(1.05, 3.0, -2.95)],
				"stair": [Vector3(3.2, 1.7, -0.5), Vector3(1.9, 0.9, 3.5)],
				"roof": [Vector3(-12.0, 4.5, 10.0), Vector3(-5.5, 1.8, 2.5)],
				"dormer": [Vector3(-6.5, 1.5, 0.8), Vector3(-5.0, 1.4, 4.7)],
			}
			var view: Array = views.get(arg, views["lineup"])
			var cam := Camera3D.new()
			world.add_child(cam)
			cam.fov = 70.0
			cam.global_position = station.to_global(view[0])
			cam.look_at(station.to_global(view[1]))
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
		"drop_aimed":
			# core/23: arg "look" tilts the head 45 degrees down at the open floor; without one, the held
			# Sock is dropped where the crosshair is, as a tap of the drop button does.
			var player := world.get_node("Player") as Player
			if arg == "look":
				(player.get_node("Head") as Node3D).rotation.x = deg_to_rad(-45.0)
				player.reset_physics_interpolation()
				return true
			var hands := world.get_node("Socks/Hands") as Hands
			var spot := player.drop_spot()
			if not spot.is_empty():
				hands.drop(player.player_id(), spot["point"], spot["normal"])
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
		"heap_more":
			# core/20: a camera over the heap station's front (its buttons, its counter sign, the pad),
			# and the zoo's player, standing at the buttons, presses More: the spout pours one batch.
			# Arg "close": the camera close on the landing under the spout (core/23).
			var station := world.get_node("Stations/Heap") as Node3D
			var player := world.get_node("Player") as Player
			player.global_position = station.to_global(Vector3(2.5, 0.0, -4.6))
			player.reset_physics_interpolation()
			var cam := Camera3D.new()
			world.add_child(cam)
			cam.fov = 60.0
			if arg == "close":
				# core/23: close on the heap's landing, under the spout.
				cam.global_position = station.to_global(Vector3(-1.1, 0.9, -1.5))
				cam.look_at(station.to_global(Vector3(0.0, 0.1, 0.0)))
			else:
				cam.global_position = station.to_global(Vector3(-2.8, 3.4, -6.4))
				cam.look_at(station.to_global(Vector3(0.0, 0.4, 0.2)))
			cam.make_current()
			(station.get_node("More/HeapButton") as HeapButton).use(player.player_id())
			return true
		"outline":
			# core/11: the zoo's player stands before a thing of the outline station and aims at it, so
			# its own aim shows the outline. arg "<thing>_<near|far>": thing sock, box, drawer (the
			# middle one), top (the top drawer, above the Rows: no room), door or cupboard; near and far
			# are eye distances (1.5 and 2.4 m; a Sock on the floor 1.8 and 2.4 m). arg "pair": the
			# player takes the station's first Sock and its mate, one Pair in the Hands.
			var station := world.get_node("Stations/Outline") as Node3D
			var player := world.get_node("Player") as Player
			if arg == "pair":
				var hands := world.get_node("Socks/Hands") as Hands
				player.global_position = station.to_global(Vector3(-1.7, 0.0, 1.2))
				player.reset_physics_interpolation()
				hands.pick(player.player_id(), (station.get_node("Spots/Sock") as SockSpot).sock)
				hands.clock += 10.0
				hands.pick(player.player_id(), (station.get_node("Spots/Mate") as SockSpot).sock)
				return true
			var parts := arg.split("_")
			var thing := parts[0]
			var far := parts.size() > 1 and parts[1] == "far"
			var target := Vector3.ZERO
			match thing:
				"sock":
					var mess := world.get_node("Socks/Mess") as Mess
					target = mess.box_of((station.get_node("Spots/Sock") as SockSpot).sock).get_center()
				"box":
					target = (station.get_node("Box") as Node3D).global_position
				"drawer", "top":
					var drawer := "Cabinet/Drawer3/Looks/Slide" if thing == "top" else "Cabinet/Drawer2/Looks/Slide"
					target = (station.get_node(drawer) as Node3D).global_transform * Vector3(0.0, 0.14, 0.25)
				"door":
					target = (station.get_node("Door/Looks/Hinge") as Node3D).global_transform * Vector3(0.45, 1.3, 0.025)
				"cupboard":
					target = (station.get_node("Cupboard") as Node3D).global_transform * Vector3(0.0, 0.6, 0.3)
			var head := player.get_node("Head") as Node3D
			var eye := station.global_position.y + head.global_position.y - player.global_position.y
			var dist := (2.4 if far else 1.8) if thing == "sock" else (2.4 if far else 1.5)
			var dy := eye - target.y
			var flat := sqrt(maxf(dist * dist - dy * dy, 0.04))
			var side := Vector3(0.3, 0.0, 1.0).normalized()
			player.global_position = Vector3(target.x, station.global_position.y, target.z) + side * flat
			player.velocity = Vector3.ZERO
			var to := target - player.global_position
			player.rotation.y = atan2(-to.x, -to.z)
			head.rotation.x = atan2(target.y - eye, flat)
			player.reset_physics_interpolation()
			return true
		"sock_looks":
			# assets/01: a camera over the Sock looks station, in the zoo or played alone (then with the
			# zoo's noon sky and sun, no grade, so it compares with the old game's render of the same
			# line-up). arg "lineup" from the front and above, "top" straight down.
			var station := (world if world is SockLooksStation else world.get_node("Stations/SockLooks")) as Node3D
			if world is SockLooksStation:
				var env := WorldEnvironment.new()
				env.environment = load("res://game/look/noon_environment.tres") as Environment
				world.add_child(env)
				var sun := DirectionalLight3D.new()
				sun.transform = Transform3D(Basis(Vector3(0.900969, 0.0, -0.433884), Vector3(-0.198987, 0.888633, -0.413201),
						Vector3(0.385564, 0.458618, 0.800631)), Vector3(0.0, 6.0, 0.0))
				sun.light_color = Color(1, 0.93, 0.82)
				sun.light_energy = 2.4
				sun.shadow_enabled = true
				sun.shadow_blur = 1.5
				sun.directional_shadow_max_distance = 18.0
				world.add_child(sun)
			var cam := Camera3D.new()
			world.add_child(cam)
			cam.fov = 50.0
			if arg == "top":
				cam.global_position = station.to_global(Vector3(0.0, 3.3, -0.95))
				cam.look_at(station.to_global(Vector3(0.0, 0.0, -0.95)), Vector3.FORWARD)
			else:
				cam.global_position = station.to_global(Vector3(0.0, 2.3, 1.2))
				cam.look_at(station.to_global(Vector3(0.0, 0.0, -1.0)))
			cam.make_current()
			return true
	return false
