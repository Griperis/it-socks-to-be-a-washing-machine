## The Gifts station's zoo-only switch (core/126): a click spawns a plain crate at the station's
## PresentSpot through its SpawnedParts, as a present will come (core/137). It holds no state: its use
## asks `switch` and the Host's answer is the SpawnedParts' add patch, so the spawner makes the crate on
## every machine. Refused while a crate still lies on the spot ("already").
class_name CrateSwitch
extends Part

const SWITCH := &"switch"
## How near the spot a lying crate counts as on it, in metres.
const ON_SPOT := 0.4
## The words on its prompt and its label. placeholder: zoo wording
const TITLE := "Spawn a crate"

## Where the crates are made.
@export var spawned: SpawnedParts
## The marker a crate lies on.
@export var spot: Marker3D
## The thing it makes.
@export var crate: PackedScene
## How far from it a player may stand to use it, in metres.
@export var reach := 4.0


func prompt_title() -> String:
	return TITLE


func use(player: int) -> void:
	parts.ask(Command.new(SWITCH, player, id, {}))


func accepts() -> Dictionary[StringName, Dictionary]:
	return {SWITCH: {"args": {}, "rate": 2}}


func decide(cmd: Command) -> Dictionary:
	if cmd.kind != SWITCH or spawned == null or spot == null or crate == null:
		return refuse("wrong")
	if not parts.near(cmd.by, get_parent(), reach):
		return refuse("far")
	if _spot_taken():
		return refuse("already")
	var states := {"Carriable": {"holder": 0, "at": spot.global_position, "yaw": spot.global_rotation.y}}
	return {"ok": true, "changes": {spawned.id: spawned.add_patch(crate.resource_path, states)}}


## Whether a spawned crate lies on the spot now.
func _spot_taken() -> bool:
	for row: Dictionary in spawned.rows:
		var node := spawned.node_of(int(row["id"])) as Node3D
		var carriable := node.get_node_or_null(^"Carriable") as Carriable if node != null else null
		if carriable != null and carriable.holder == 0 \
				and node.global_position.distance_to(spot.global_position) < ON_SPOT:
			return true
	return false
