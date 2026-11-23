## The `teammates` shot action of tools/shot_hooks.gd (coop/05), on its own so that file stays short.
class_name ShotTeammates
extends RefCounted


## coop/05: two Teammates' avatars (peers 4 and 5, puppets on this machine; the Avatar station's
## stand-ins are 2 and 3) side by side before the Handling station, facing a camera, driven only
## through their poses, as the network would: arg "setup" places them (coral and teal, tagged "Player", as the Roster would colour them), "walk" walks
## them 1 m toward the camera at 3 m/s (a full waddle), "crouch" / "stand", "look_up" / "look_down"
## / "look_level" (the full pitch, 85 degrees), "hold" has each pick a Sock of the station, "hold_more"
## a second one each, "close" moves the camera nearer, from their right.
static func act(world: Node, arg: String) -> void:
	var players := LevelRuntime.of(world).players
	var station := world.get_node("Stations/Handling") as Node3D
	var hands := LevelRuntime.of(world).hands
	var peers: Array[int] = [4, 5]
	if arg == "setup":
		var scene := load("res://game/parts/avatar/avatar.tscn") as PackedScene
		var colours: Array[Color] = [Color("f08a7a"), Color("4fb3a9")]
		for i in peers.size():
			var a := scene.instantiate() as Avatar
			a.name = str(peers[i])
			a.pose_position = station.to_global(Vector3(-0.6 + 1.2 * i, 0.0, 0.9))
			a.pose_yaw = PI
			players.add_child(a)
			a.looks.colour = colours[i]
			a.looks.player_name = "Player"
		# Room for two Socks each, for this run only (a player's Hands hold one before the Upgrade).
		hands.tuning = hands.tuning.duplicate() as HandsTuning
		hands.tuning.capacity = 4
		var player := LevelRuntime.of(world).player
		player.global_position = station.to_global(Vector3(0.0, 0.0, 12.0))  # out of the way
		# Only the two show: no HUD, no station sign.
		player.hud().visible = false
		(LevelRuntime.of(world).net.get_node(^"Hud") as CanvasLayer).visible = false
		(station.get_node("Name") as Node3D).visible = false
		var cam := Camera3D.new()
		world.add_child(cam)
		cam.fov = 45.0
		cam.global_position = station.to_global(Vector3(1.2, 1.3, 5.2))
		cam.look_at(station.to_global(Vector3(0.0, 0.85, 1.5)))
		cam.reset_physics_interpolation()
		cam.make_current()
		return
	if arg == "close":
		# Nearer, from their right and a little above: the held Socks at their HoldPoints.
		var near := world.get_viewport().get_camera_3d()
		near.global_position = station.to_global(Vector3(-1.6, 1.6, 3.4))
		near.look_at(station.to_global(Vector3(0.0, 0.8, 1.8)))
		near.reset_physics_interpolation()
		return
	var spots: Array[String] = ["Floor", "Under"]
	if arg == "hold_more":
		spots = ["MateUnder", "Over"]
	for i in peers.size():
		var a := players.get_node(str(peers[i])) as Avatar
		match arg:
			"walk":
				var tween := world.create_tween()
				tween.tween_property(a, ^"pose_position", a.pose_position + Vector3(0.0, 0.0, 1.0), 1.0 / 3.0)
			"crouch", "stand":
				a.pose_crouch = 1.0 if arg == "crouch" else 0.0
			"look_up", "look_down", "look_level":
				a.pose_pitch = float({"look_up": 1.0, "look_down": -1.0}.get(arg, 0.0)) * deg_to_rad(85.0)
			"hold", "hold_more":
				hands.pick(peers[i], (station.get_node("Spots/" + spots[i]) as SockSpot).sock)
