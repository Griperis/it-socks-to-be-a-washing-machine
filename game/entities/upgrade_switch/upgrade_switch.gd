## A zoo switch that turns one screen Upgrade on or off for every player in the level (core/15 A16):
## Sock Smarts or Sock Sense, so the three states of the Sock prompt can be tried. Its state is the
## flag; its _show() sets it on each player's PlayerUpgrades and its Looks' label says it. M4 replaces
## it with buying.
class_name UpgradeSwitch
extends Part

## The PlayerUpgrades field it switches.
@export_enum("sock_smarts", "sock_sense") var flag := "sock_smarts"
## The words its label and prompt use ("Sock Smarts").
@export var upgrade_name := "Sock Smarts"
## How far from it a player may stand to use it, in metres.
@export var reach := 4.0

@export_group("State")
## On or off.
@export var on := true
@export_group("")

## Where the Looks' label is, from this part.
const LABEL := ^"../Looks/Label"


## The prompt and the label: "Sock Smarts: on".
func title() -> String:
	return "%s: %s" % [upgrade_name, "on" if on else "off"]


func use(by: int) -> void:
	parts.ask(Command.new(&"switch", by, id, {"on": not on}))


func accepts() -> Dictionary[StringName, Dictionary]:
	return {&"switch": {"args": {"on": TYPE_BOOL}, "rate": 5}}


func decide(cmd: Command) -> Dictionary:
	var to: Variant = cmd.args.get("on")
	if cmd.kind != &"switch" or not (to is bool):
		return refuse("wrong")
	if not parts.near(cmd.by, get_parent(), reach):
		return refuse("far")
	if to == on:
		return refuse("already")
	return grant({"on": to})


func _show(_now: bool) -> void:
	var label := get_node_or_null(LABEL) as Label3D
	if label != null:
		label.text = title()
	if not is_inside_tree():
		return
	for node in get_tree().get_nodes_in_group(Hands.PLAYERS):
		var player := node as Player
		if player != null and player.upgrades != null:
			player.upgrades.set(flag, on)
