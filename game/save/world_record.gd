## What a World knows about itself beside its Parts (the old WorldMeta, smaller): which kind it is,
## who played it, how long, when, and which level. Host-only: never in the join snapshot. The player
## id (Q2458) is the key everywhere, so the old per-World player id is gone.
class_name WorldRecord
extends RefCounted

const SOLO := "solo"
const COOP := "coop"

## SOLO or COOP.
var kind := SOLO
## The players last seen in it: {player id: {"name": String, "colour": int}}.
var members := {}
## Seconds played in it.
var play_time := 0.0
## When it was last played, Unix seconds.
var last_played := 0
## The level's scene.
var level := ""
## The floor the World is on (Stages; "" until they exist).
var floor_name := ""
## The seed its Socks were laid with (Q2524).
var seed := 0


## As plain data, for the file.
func to_dict() -> Dictionary:
	return {"kind": kind, "members": members.duplicate(true), "play_time": play_time, "last_played": last_played,
			"level": level, "floor": floor_name, "seed": seed}


## Read back from the file (unknown or missing fields take their defaults).
static func from_dict(d: Dictionary) -> WorldRecord:
	var r := WorldRecord.new()
	r.kind = COOP if String(d.get("kind", SOLO)) == COOP else SOLO
	var m: Variant = d.get("members", {})
	r.members = (m as Dictionary).duplicate(true) if m is Dictionary else {}
	r.play_time = maxf(float(d.get("play_time", 0.0)), 0.0)
	r.last_played = int(d.get("last_played", 0))
	r.level = String(d.get("level", ""))
	r.floor_name = String(d.get("floor", ""))
	r.seed = int(d.get("seed", 0))
	return r
