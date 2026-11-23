## The `stacking` shot action of tools/shot_hooks.gd (core/41), on its own so that file stays short.
class_name ShotStacking
extends RefCounted

## core/41 at the Stacking station, played alone: the zoo's player climbs the stand-in carrier (peer 7) by
## its pressed jump and rides it round its loop. Arg "setup" stands the player 0.7 m beside the carrier,
## facing it, shows its full body (the mirror's, as a Teammate sees it) and puts a camera on the station
## from above; "jump" presses the jump, "release" lets it go; "rider" puts the camera in the player's own
## eyes, looking down over the carrier's head.
static func act(world: Node, arg: String) -> void:
	var player := LevelRuntime.of(world).player
	var station := world.get_node("Stations/Stacking") as Node3D
	var carrier := station.get_node("Teammates/7") as Avatar
	match arg:
		"setup":
			var top := carrier.back.top()
			player.global_position = Vector3(top.x, 0.0, top.z + 0.7)
			player.rotation.y = 0.0
			player.reset_physics_interpolation()
			StackStandIn.show_body(player)
			StackStandIn.camera(world, station.to_global(Vector3(-1.5, 4.2, 3.2)), station.to_global(Vector3(0.9, 0.9, 0.0)))
		"jump":
			Input.action_press(Player.JUMP)
		"release":
			Input.action_release(Player.JUMP)
		"rider":
			(player.get_node("Head") as Node3D).rotation.x = deg_to_rad(-45.0)
			player.own_body().visible = true
			player.mirror_body().visible = false
			player.camera().make_current()
