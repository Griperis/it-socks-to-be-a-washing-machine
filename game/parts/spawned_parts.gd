## Things made during play (a present, batch C's bought devices; docs/architecture/gifts.md "A present is
## a spawned scene"): one row per thing, {scene, id, states}, and Godot's spawner (the child `Spawner`,
## whose spawn path is this node) makes or frees its node on every machine, a late Guest included.
## A spawnable thing is a scene with its Parts; nothing registers it but its row's `scene` path.
##
## Rows are decided state: a Host verb of any Part puts add_patch() or remove_patch() in its answer's
## changes, and this part's _show() on the Host spawns each new row's node and frees each gone one;
## on a Guest the spawner does. Each node is named `<its scene root's name><id>` and its Parts are bound
## by path (Parts.adopt(): Run/Spawned/Crate3/Carriable), written first with the row's `states` (by the
## part's path from the node), then with what reached this machine before the node (Parts waits by id).
## The save and the join snapshot keep the rows here and each node's Parts' states under their own ids;
## a load writes the rows (spawning the nodes) before those states (Parts.load_save()).
##
## Each node gets a SpawnGate (spawn_gate.tscn): the synchronizer the level's house filter goes on, so a
## Guest still loading its level is sent no spawn (LevelRuntime, Session.sees_house()); its authority
## stays the Host's whoever carries the thing (a Carriable hands its node's authority to its holder).
class_name SpawnedParts
extends Part

## The spawner child, whose spawn path is this node.
const SPAWNER := ^"Spawner"
## The SpawnGate every spawned node gets, and its name there.
const GATE_SCENE := preload("res://game/parts/spawn_gate.tscn")
const GATE := &"SpawnGate"
## Only the game's own scenes are spawned (a Guest refuses other spawn data).
const SCENE_ROOT := "res://game/"

@export_group("State")
## What was spawned: each {"scene": a scene's path, "id": int, "states": {part path: state}}.
@export var rows: Array = []
## The id the next row gets.
@export var next_id := 1
@export_group("")

## The live node of each row on this machine, by row id.
var _nodes: Dictionary[int, Node] = {}


func _ready() -> void:
	var spawner := spawner()
	spawner.spawn_function = _make
	spawner.spawned.connect(_on_spawned)
	spawner.despawned.connect(_on_despawned)


## Nothing asks this part directly: its rows change in other Parts' answers.
func decide(_cmd: Command) -> Dictionary:
	return refuse("wrong")


func spawner() -> MultiplayerSpawner:
	return get_node(SPAWNER) as MultiplayerSpawner


## The patch (for this part's id) that adds a thing of `scene` (a path), its Parts starting as `states`
## ({part path from the node: state}); `ahead` rows already added in the same answer (adding several).
func add_patch(scene: String, states: Dictionary = {}, ahead: Dictionary = {}) -> Dictionary:
	var now: Array = (ahead.get("rows", rows) as Array).duplicate(true)
	var n := int(ahead.get("next_id", next_id))
	now.append({"scene": scene, "id": n, "states": states})
	return {"rows": now, "next_id": n + 1}


## The patch that removes the rows with these ids (their nodes go on every machine).
func remove_patch(ids: PackedInt32Array, ahead: Dictionary = {}) -> Dictionary:
	var now: Array = []
	for row: Dictionary in ahead.get("rows", rows):
		if not ids.has(int(row["id"])):
			now.append(row.duplicate(true))
	return {"rows": now, "next_id": int(ahead.get("next_id", next_id))}


## The node of row `id` on this machine, or null (a Guest's may not have come yet).
func node_of(id: int) -> Node:
	var node: Node = _nodes.get(id)
	return node if is_instance_valid(node) else null


## The id the row of node `node` has, or 0.
func id_of(node: Node) -> int:
	for id: int in _nodes:
		if _nodes[id] == node:
			return id
	return 0


## The Host spawns each row with no node and frees each node with no row. A Guest's are the spawner's;
## bound (`now` at bind) it only binds what is already here.
func _show(_now: bool) -> void:
	if parts == null or not is_inside_tree():
		return
	for node in get_children():
		if node.has_meta(&"spawned_row") and not node.is_queued_for_deletion():
			_nodes[int(node.get_meta(&"spawned_row"))] = node
	if not parts.is_host():
		return
	var live := {}
	for row: Dictionary in rows:
		var id := int(row.get("id", 0))
		live[id] = true
		if node_of(id) == null:
			var node := spawner().spawn({"scene": row.get("scene", ""), "id": id, "states": row.get("states", {})})
			if node != null:
				_bind(node)
	for id: int in _nodes.keys():
		if not live.has(id):
			var node := node_of(id)
			_nodes.erase(id)
			if node != null:
				parts.release(node)
				remove_child(node)
				node.queue_free()


## Runs on every machine with the Host's data: {"scene": a path under res://game/, "id": int, "states":
## Dictionary}. Anything else makes nothing.
func _make(data: Variant) -> Node:
	var d: Dictionary = data if data is Dictionary else {}
	var scene: Variant = d.get("scene")
	var id: Variant = d.get("id")
	var states: Variant = d.get("states", {})
	if not (scene is String) or not (scene as String).begins_with(SCENE_ROOT) or not (id is int) \
			or int(id) < 1 or not (states is Dictionary) or not ResourceLoader.exists(scene):
		Log.error("spawned", "refused spawn data %s" % str(data).left(60))
		return null
	var packed := load(scene) as PackedScene
	if packed == null:
		Log.error("spawned", "not a scene: %s" % scene)
		return null
	var node := packed.instantiate()
	node.name = "%s%d" % [node.name, int(id)]
	node.set_meta(&"spawned_row", int(id))
	node.set_meta(&"spawned_states", states)
	var gate := GATE_SCENE.instantiate()
	gate.name = GATE
	node.add_child(gate)
	return node


## A Guest: the spawner brought a node.
func _on_spawned(node: Node) -> void:
	_bind(node)


## A Guest: the spawner freed one.
func _on_despawned(node: Node) -> void:
	_nodes.erase(int(node.get_meta(&"spawned_row", 0)))
	if parts != null:
		parts.release(node)


## The node is this machine's row's: its Parts are bound by path, with the spawn's states.
func _bind(node: Node) -> void:
	_nodes[int(node.get_meta(&"spawned_row"))] = node
	if parts != null:
		parts.adopt(node, node.get_meta(&"spawned_states", {}))
		if not parts.applied.is_connected(_keep_gates):
			parts.applied.connect(_keep_gates)
	_keep_gates({})


## Every spawned node's SpawnGate stays the Host's (a Carriable just gave its node to its holder), so
## the house filter keeps deciding who is sent the spawn.
func _keep_gates(_ev: Dictionary) -> void:
	for id: int in _nodes:
		var node := node_of(id)
		var gate := node.get_node_or_null(NodePath(GATE)) if node != null else null
		if gate != null and gate.get_multiplayer_authority() != Parts.HOST:
			gate.set_multiplayer_authority(Parts.HOST)
