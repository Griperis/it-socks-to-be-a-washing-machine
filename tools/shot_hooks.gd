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
		"cabinet":
			# assets/02: a camera on the Cabinet station. arg "overview" looks over the line-up of
			# every Collection's Cabinet; arg <collection> stands before that Collection's Cabinet at
			# eye height, as the old game's cab-* views did ("simple" is the station's own Cabinet).
			var station := world.get_node("Stations/Cabinet") as Node3D
			var gallery := station.get_node("Gallery") as CabinetGallery
			var cam := Camera3D.new()
			world.add_child(cam)
			cam.fov = 75.0
			if arg == "overview":
				cam.global_position = gallery.to_global(Vector3(-2.4, 6.5, 5.0))
				cam.look_at(gallery.to_global(Vector3(2.7, 0.0, -3.4)))
			else:
				var cabinet := gallery.cabinet_of(StringName(arg))
				if cabinet == null:
					cabinet = station.get_node("Cabinet") as Node3D
				cam.global_position = cabinet.to_global(Vector3(0.0, 1.45, 1.7))
				cam.look_at(cabinet.to_global(Vector3(0.0, 0.55, 0.0)))
			cam.reset_physics_interpolation()
			cam.make_current()
			return true
		"materials":
			# assets/04 F01: a camera on the Materials station's board. arg "overview" looks at the
			# whole board; arg <row> ("oak", "singles_1") hides every other row and stands before that
			# one, so a candidate group is seen alone for the designer's pick. The other stations are hidden.
			var board := world.get_node("Stations/Materials/Board") as MaterialBoard
			var cam := Camera3D.new()
			world.add_child(cam)
			var target := board.row(arg)
			# Other stations' things stand between the camera and the board: they are hidden.
			for s in world.get_node("Stations").get_children():
				(s as Node3D).visible = s == board.get_parent()
			if target == null:
				cam.fov = 50.0
				cam.global_position = board.to_global(Vector3(7.75, 3.4, 11.0))
				cam.look_at(board.to_global(Vector3(7.75, 3.4, 0.0)))
			else:
				for r in board.get_children():
					(r as Node3D).visible = r == target
				var swatches := target.get_child_count() - 1
				var mid := target.position + Vector3((board.layout.name_width + (swatches - 1) * board.layout.pitch) / 2.0, -0.15, 0.0)
				cam.fov = 50.0
				cam.global_position = board.to_global(mid + Vector3(0.0, 0.0, 3.6))
				cam.look_at(board.to_global(mid))
			cam.reset_physics_interpolation()
			cam.make_current()
			return true
		"furniture":
			# assets/04 F03: a camera on the Furniture station's line-up, the other stations hidden. arg
			# "overview" looks down over it all; "row<n>" stands before row n (0 the front one). With
			# "old_" first ("old_row2") each piece shows the old game's model instead, read at run time
			# from the reference's glb with its own materials (IT_SOCKS_REFERENCE, else res://reference/it-socks).
			_furniture_shot(world, arg)
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
		"old_house":
			# house/03: the zoo's player in house A or B as the old game's looks-baseline tour stood
			# (docs/migration/baseline/views_baseline.json), for stills old beside new. arg "a,<view>"
			# or "b,<view>". The old numbers are moved +0.1 m on x and z (the plan's frame) and the
			# old floors (-2.9, 0, 2.9, 5.8) become the new (-3, 0, 3, 6); every other station hides.
			var station := world.get_node("Stations/OldHouse" + arg.get_slice(",", 0).to_upper()) as Node3D
			var house := station.get_node("House") as Node3D
			for other: Node in world.get_node("Stations").get_children():
				(other as Node3D).visible = other == station
			var player := world.get_node("Player") as Player
			var head := player.get_node("%Head") as Node3D
			var view := arg.get_slice(",", 1)
			var outside := {"exterior-front": [Vector3(5.0, 3.0, 22.0), Vector3(5.0, 3.5, 4.0)],
					"exterior-high": [Vector3(22.0, 9.0, 18.0), Vector3(5.0, 2.0, 4.0)]}
			# name: x, z, yaw, the old floor (the old views' pitch is 0.12 down).
			var rooms := {"workshop": [0.60, 0.60, -2.241, -2.9], "laundry": [0.60, 3.88, -2.515, -2.9],
					"boiler": [4.55, 0.60, -2.244, -2.9], "stair_lobby": [4.55, 2.70, -2.527, -2.9],
					"garage": [7.00, 0.60, -2.761, -2.9], "stairs_basement": [4.55, 5.75, -2.553, -2.9],
					"kitchen": [0.60, 0.60, -2.746, 0.0], "hall": [4.55, 0.60, -2.778, 0.0], "living": [7.00, 0.60, -2.761, 0.0],
					"stairs_ground": [4.55, 5.75, -2.553, 0.0], "office": [0.60, 0.60, -2.241, 2.9],
					"bedroom": [0.60, 3.88, -2.515, 2.9], "landing": [4.55, 0.60, -2.778, 2.9],
					"bathroom": [7.00, 0.60, -2.261, 2.9], "kids": [7.00, 3.88, -2.534, 2.9],
					"stairs_first": [4.55, 5.75, -2.553, 2.9], "loft": [0.60, 0.60, -2.254, 5.8],
					"kitchen-b": [3.23, 7.74, 0.395, 0.0], "living-b": [9.50, 7.74, 0.381, 0.0]}
			var shift := Vector3(0.1, 0.0, 0.1)
			if outside.has(view):
				var o: Array = outside[view]
				player.global_position = house.to_global((o[0] as Vector3) + shift)
				player.rotation = Vector3.ZERO
				var dir := (house.to_global((o[1] as Vector3) + shift) - head.global_position).normalized()
				player.rotation = Vector3(0.0, atan2(-dir.x, -dir.z), 0.0)
				head.rotation.x = asin(dir.y)
			else:
				var r: Array = rooms[view.trim_prefix("room-")]
				var floor_y: float = roundf(float(r[3]) / 2.9) * 3.0
				player.global_position = house.to_global(Vector3(float(r[0]), floor_y + 0.05, float(r[1])) + shift)
				player.rotation = Vector3(0.0, float(r[2]), 0.0)
				head.rotation.x = -0.12
			player.reset_physics_interpolation()
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
		"cloth":
			# core/36: a tuning override for this run only, arg "drag/stiffness/gravity" (the .tres is not
			# written); do it before the Sock is picked, as the cloth reads drag and stiffness when it is made.
			var parts := arg.split("/")
			var tuning := load("res://game/sock/sock_cloth_tuning.tres") as SockClothTuning
			tuning.drag = float(parts[0])
			tuning.stiffness = float(parts[1])
			tuning.gravity = float(parts[2])
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
			# The view turns left by 1.2 rad in 0.4 s, as the mouse would; arg "quick" (core/36): 90 degrees in 0.15 s.
			var player := world.get_node("Player") as Player
			if arg == "quick":
				player.create_tween().tween_property(player, ^"rotation:y", player.rotation.y + PI / 2.0, 0.15)
			else:
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
		"landing_cam":
			# core/16 P04: a camera low beside where the crosshair points on the floor, looking at it
			# (a dropped Pair's landing seen from the side).
			var player := world.get_node("Player") as Player
			var spot := player.drop_spot()
			if spot.is_empty():
				return false
			var at := spot["point"] as Vector3
			var cam := Camera3D.new()
			world.add_child(cam)
			cam.fov = 40.0
			cam.global_position = at + Vector3(0.55, 0.12, 0.35)
			cam.look_at(at + Vector3(0.0, 0.05, 0.0))
			cam.make_current()
			return true
		"lose_socks":
			# core/16 P12: the handling station's Lose button is used: its Socks come back at the zoo's
			# return spot, scattered; a camera looks down on the spot.
			var player := world.get_node("Player") as Player
			var station := world.get_node("Stations/Handling") as Node3D
			player.global_position = station.to_global(Vector3(-1.4, 0.0, 1.4))
			player.reset_physics_interpolation()
			var spot := world.get_node("ReturnSpot") as Marker3D
			var cam := Camera3D.new()
			world.add_child(cam)
			cam.fov = 45.0
			cam.global_position = spot.global_position + Vector3(0.0, 1.1, 0.9)
			cam.look_at(spot.global_position)
			cam.make_current()
			(station.get_node("Lose/LoseButton") as LoseButton).use(player.player_id())
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
		"shelve_throw":
			# core/27 P11: the zoo's player, holding the Cabinet station's Pair (shelve_pair, shelve_mate),
			# steps back and throws it at the second drawer's front with a firm charge; arg "cam" puts a
			# camera beside the drawers instead, looking along their fronts.
			var player := world.get_node("Player") as Player
			var station := world.get_node("Stations/Cabinet") as Node3D
			var cab := station.get_node("Cabinet") as Node3D
			var front := (cab.get_node("Drawer2/Looks/Slide/Front") as Node3D).global_position
			if arg == "cam":
				var cam := Camera3D.new()
				world.add_child(cam)
				cam.fov = 50.0
				cam.global_position = front + cab.global_transform.basis * Vector3(1.4, 0.5, 1.3)
				cam.look_at(front + Vector3(0.0, -0.1, 0.0))
				cam.make_current()
				return true
			player.global_position = station.to_global(Vector3(-1.0, 0.0, 0.8))
			var to := front - player.global_position
			player.rotation.y = atan2(-to.x, -to.z)
			(player.get_node("Head") as Node3D).rotation.x = deg_to_rad(-25.0)
			player.reset_physics_interpolation()
			var dir := (front - player.eyes()).normalized()
			(world.get_node("Socks/Hands") as Hands).throw(player.player_id(), dir, 0.5)
			return true
		"swing_view", "swing_use":
			# core/27 P15: arg "door" (the Cabinet station's Door) or "cupboard" (the openables station's
			# first cupboard): `swing_view` puts a camera to its side, `swing_use` opens or shuts it as
			# the player's use does.
			var path := "Stations/Cabinet/Door" if arg == "door" else "Stations/Openables/Cupboard"
			var thing := world.get_node(path) as Node3D
			var openable := thing.get_node("Openable") as Openable
			if what == "swing_use":
				openable.use((world.get_node("Player") as Player).player_id())
				return true
			# The player stands in front of it, in reach of the use.
			var player := world.get_node("Player") as Player
			player.global_position = thing.global_transform * Vector3(0.0, 0.0, 1.6)
			player.reset_physics_interpolation()
			var cam := Camera3D.new()
			world.add_child(cam)
			cam.fov = 55.0
			var back := Vector3(1.6, 2.6, 2.6) if arg == "door" else Vector3(1.2, 1.9, 2.0)
			cam.global_position = thing.global_transform * back
			cam.look_at(thing.global_transform * Vector3(0.0, 0.9, 0.0))
			cam.make_current()
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
		"screen":
			# core/15: the zoo's player at the screen station. arg "plain" turns Sock Smarts and Sock
			# Sense off; "sock", "mate", "drawer", "door" stand before that thing and aim at it; "take"
			# takes the station's first Sock, "take2" also the Apricot; "floor" aims at the floor ahead.
			var station := world.get_node("Stations/Screen") as Node3D
			var player := world.get_node("Player") as Player
			var hands := world.get_node("Socks/Hands") as Hands
			var mess := world.get_node("Socks/Mess") as Mess
			var head := player.get_node("Head") as Node3D
			var spot := Vector3.ZERO
			var target := Vector3.ZERO
			match arg:
				"plain":
					player.upgrades.sock_smarts = false
					player.upgrades.sock_sense = false
					return true
				"take", "take2":
					hands.clock += 10.0
					hands.pick(player.player_id(), (station.get_node("Spots/Sock") as SockSpot).sock)
					if arg == "take2":
						hands.clock += 10.0
						hands.pick(player.player_id(), (station.get_node("Spots/Other") as SockSpot).sock)
					return true
				"sock", "mate", "floor":
					spot = Vector3(-0.7, 0.0, 2.4)
					var name := "Spots/Mate" if arg == "mate" else "Spots/Sock"
					target = mess.box_of((station.get_node(name) as SockSpot).sock).get_center() if arg != "floor" \
							else station.to_global(Vector3(-0.7, 0.0, 1.2))
				"drawer":
					spot = Vector3(-1.4, 0.0, -0.1)
					target = (station.get_node("Cabinet/Drawer2/Looks/Slide") as Node3D).global_transform * Vector3(0.0, 0.14, 0.25)
				"door":
					spot = Vector3(1.3, 0.0, -0.1)
					target = (station.get_node("Door/Looks/Hinge") as Node3D).global_transform * Vector3(0.45, 1.3, 0.025)
			player.global_position = station.to_global(spot)
			player.velocity = Vector3.ZERO
			var to := target - player.global_position
			player.rotation.y = atan2(-to.x, -to.z)
			var up := target - head.global_position
			head.rotation.x = atan2(up.y, Vector2(up.x, up.z).length())
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
		"icons":
			# assets/03: the Icons still (tools/icons_still.tscn): arg "<group>" frames that group's block;
			# the old game's files (env ICONS_OLD_DIR) stand beside each icon.
			var station := world.get_node("Icons") as IconsStation
			var old_dir := OS.get_environment("ICONS_OLD_DIR")
			if old_dir != "":
				station.show_old_beside(old_dir)
			var keys := station.keys_of(arg)
			var cam := world.get_node("Camera") as Camera3D
			var rows := ceili(keys.size() / float(station.per_row))
			var top := station.cell_position(keys[0]).y
			# The view is 15 m wide: the window is 15 * 130 px wide and the group's rows plus a margin high.
			cam.size = rows * station.row_pitch + 0.9
			cam.position = Vector3(6.2, top - (rows - 1) * station.row_pitch * 0.5 - 0.15, 12.0)
			return true
		"sign":
			# core/33: arg "<Station>" stands 3 m in front of that station's Name label at eye height
			# and looks at it ("<Station>:north" stands on its north side, as the old houses' sign faces
			# the door); arg "wide" looks over the zoo from the start spot.
			var cam := Camera3D.new()
			world.add_child(cam)
			cam.fov = 75.0
			if arg == "wide":
				cam.global_position = (world.get_node("Spawn") as Node3D).global_position + Vector3(0.0, 1.6, 0.0)
				cam.look_at(cam.global_position + Vector3(0.0, -0.1, -10.0))
			else:
				var parts := arg.split(":")
				var label := world.get_node("Stations/%s/Name" % parts[0]) as Label3D
				var side := -1.0 if parts.size() > 1 else 1.0
				cam.global_position = label.global_position + Vector3(0.0, 0.4, 3.0 * side)
				cam.look_at(label.global_position + Vector3(0.0, 0.4, 0.0))
			cam.reset_physics_interpolation()
			cam.make_current()
			return true
	return false


## The furniture camera (assets/04): see "furniture" in act().
static func _furniture_shot(world: Node, arg: String) -> void:
	var station := world.get_node("Stations/Furniture") as Node3D
	var line_up := station.get_node("LineUp") as FurnitureLineUp
	for s in world.get_node("Stations").get_children():
		(s as Node3D).visible = s == station
	(station.get_node("Name") as Node3D).visible = false
	var old := arg.begins_with("old_")
	var view := arg.trim_prefix("old_")
	if old:
		_show_old_furniture(line_up)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.fov = 50.0
	if view.begins_with("row"):
		var row := line_up.row_of(view.trim_prefix("row").to_int())
		for p: Node in line_up.get_children():
			(p as Node3D).visible = row.has(p)
		var lo := INF
		var hi := -INF
		var front := -INF
		for p in row:
			var fp: Array = p.get_meta(&"footprint", [1.0, 1.0])
			lo = minf(lo, p.position.x - float(fp[0]) / 2.0)
			hi = maxf(hi, p.position.x + float(fp[0]) / 2.0)
			front = maxf(front, p.position.z + float(fp[1]) / 2.0)
		# Far enough for the row's width (and a margin) in the view's width, from in front and above.
		var half_h := tan(deg_to_rad(cam.fov) / 2.0) * 16.0 / 9.0
		var dist := (maxf(hi - lo, 5.0) / 2.0 + 0.3) / half_h
		var mid := Vector3((lo + hi) / 2.0, 0.75, front - 1.0)
		cam.global_position = line_up.to_global(mid + Vector3(0.0, dist * 0.3, dist))
		cam.look_at(line_up.to_global(mid))
	else:
		cam.global_position = line_up.to_global(Vector3(6.0, 24.0, 10.0))
		cam.look_at(line_up.to_global(Vector3(6.0, 0.0, -13.0)))
	cam.reset_physics_interpolation()
	cam.make_current()


## Puts the old game's model of every piece in the line-up in place of its Looks (a review still).
static func _show_old_furniture(line_up: FurnitureLineUp) -> void:
	var root := OS.get_environment("IT_SOCKS_REFERENCE")
	if root.is_empty():
		root = ProjectSettings.globalize_path("res://reference/it-socks")
	for p: Node in line_up.get_children():
		for looks: Node in p.find_children("Looks", "", true, false):
			(looks as Node3D).visible = false
		var file := root.path_join("assets/house/furniture/%s.glb" % String(p.name).to_snake_case())
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		if doc.append_from_file(file, state) != OK:
			push_warning("furniture shot: no old model at %s" % file)
			continue
		var model := doc.generate_scene(state) as Node3D
		for n: Node in model.find_children("*", "", true, false):
			if String(n.name).contains("-col") or String(n.name).contains("-convcol"):
				(n as Node3D).visible = false
		p.add_child(model)
