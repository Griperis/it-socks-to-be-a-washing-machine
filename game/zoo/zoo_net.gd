## Co-op in the zoo: the level's LevelNet (game/net/level_net.gd: `-- --host`, `-- --join=<where>`,
## `--profile=<tag>`, the corner label and the join and leave lines), with the zoo's word and the
## Avatar station's stand-in Teammate, which places itself.
class_name ZooNet
extends LevelNet


func place_name() -> String:
	return "zoo"


## The Avatar station's stand-in Teammate (coop/05, Q2468): it picks where its body stands.
func _where_else(by: int) -> Variant:
	for node in get_tree().get_nodes_in_group(TeammateStandIn.GROUP):
		var stand_in := node as Avatar
		if stand_in != null and stand_in.peer() == by and owner != null and owner.is_ancestor_of(stand_in):
			return stand_in.global_position
	return null
