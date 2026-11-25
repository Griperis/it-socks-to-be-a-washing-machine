## The Laundry station's Bin pillar (core/90): used with the use key (E), it empties the station's
## full bin the way the washer will (the Host's answer sets `full` false, every machine's bin tips toward
## the washer and its heap eases down), or fills it again when it is empty. Stands in for the Laundry
## day's load (core/93).
class_name BinPillar
extends Part

const FLIP := &"flip"

## The bin the pillar works.
@export var bin: LaundryBin


func prompt_title() -> String:
	return "Empty or fill the bin"


func use(by: int) -> void:
	if bin != null:
		parts.ask(Command.new(FLIP, by, id))


func decide(cmd: Command) -> Dictionary:
	if cmd.kind != FLIP or bin == null:
		return refuse("wrong")
	return {"ok": true, "changes": {bin.id: {"full": not bin.full}}}


## Bound: every machine hears the answers; a bin that has just emptied tips into the washer.
func _show(_now: bool) -> void:
	if parts != null and not parts.applied.is_connected(_on_applied):
		parts.applied.connect(_on_applied)


func _on_applied(ev: Dictionary) -> void:
	var changes: Dictionary = ev.get("changes", {})
	if bin != null and ev.get("ok", false) and changes.has(bin.id) and (changes[bin.id] as Dictionary).get("full", true) == false:
		bin.tip()
