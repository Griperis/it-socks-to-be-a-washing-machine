## A zoo button of the handling station (core/16, Q2369) that loses or sinks its Socks, so the
## Host's lost rule can be seen: "lose" puts each down far out of the playable space, and they come
## back at the return spot scattered, with a pop at each (P12, P12b); "sink" puts each down sunk
## into the floor, and it is pushed up onto the floor where it lay, with no pop (P13). Clicked like
## a drawer; it has no state of its own: the Mess's put_down() decides where each Sock lies.
class_name LoseButton
extends Part

## How far under its place a lost Sock is put down: out of any level's playable space.
const LOST_DEPTH := 1000.0

## What a click does: &"lose" or &"sink".
@export_custom(PROPERTY_HINT_ENUM, "lose,sink") var verb: StringName = &"lose"
## The Mess the Socks are in (the zoo's, once the station joins it).
@export var mess: Mess
## The SockSpots whose Socks it loses or sinks (each that still lies or flies).
@export var spots: Array[SockSpot] = []
## How far under its pose a sunk Sock is put down, in m (between the Mess's `sunk` and `sunk_depth`).
@export_range(0.0, 0.3, 0.005, "suffix:m") var sink_depth := 0.05 # placeholder: a zoo tool's number, not felt in play
## How far from it a player may stand to use it, in m.
@export var reach := 4.0 # placeholder: a zoo tool's number, as the UpgradeSwitch's


## The words its label and the crosshair's prompt use.
func prompt_title() -> String:
	return "Lose Socks" if verb == &"lose" else "Sink a Sock"


## The player's click asks it.
func use(by: int) -> void:
	if parts != null:
		parts.ask(Command.new(verb, by, id, {}))


func accepts() -> Dictionary[StringName, Dictionary]:
	return {verb: {"args": {}, "rate": 5}}


## The Host: each of its spots' Socks that lies or flies is put down far below the space (lose) or
## sunk into the floor under it (sink), where the Mess's put_down() says; a returned one pops.
func decide(cmd: Command) -> Dictionary:
	if cmd.kind != verb or mess == null:
		return refuse("wrong")
	if not parts.near(cmd.by, get_parent(), reach):
		return refuse("far")
	var patch := {}
	var popped := PackedVector3Array()
	var any := false
	for spot in spots:
		var sock := spot.sock if spot != null else -1
		if sock < 0 or sock >= mess.count() or mess.state_of(sock) not in [Mess.State.LYING, Mess.State.FLYING]:
			continue
		var pose := mess.pose_of(sock)
		if mess.state_of(sock) == Mess.State.FLYING and mess.flight_of(sock) != null:
			pose = mess.flight_of(sock).global_transform.orthonormalized()
		pose.origin += Vector3.DOWN * (LOST_DEPTH if verb == &"lose" else sink_depth)
		var down := mess.put_down(sock, pose)
		patch = mess.lying_patch(sock, down["pose"], patch)
		if down["returned"]:
			popped.append((down["pose"] as Transform3D).origin)
		any = true
	if not any:
		return refuse("gone")
	var ev := {"ok": true, "changes": {mess.id: patch}}
	if not popped.is_empty():
		ev[Mess.POPPED] = popped
	return ev
