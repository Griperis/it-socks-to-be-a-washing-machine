## The Laundry station's stand-in for the run (core/107, Q2409): the station has no Stages, so its Laundry day's
## `stages` link points here and this Part answers the same reads (`is_fixed()`, `lay_first_answer()`). The station's
## pillars ask its own Commands, decided by the Host; their state is its own (the last Fix done, the held Socks) or
## the Laundry day's and the bins' own fields, written by its answer.
##   `last_fix {on}`: "Last Fix done", a switch: the machine is fixed.
##   `final`: "Final wash": the first press loads every bin in use but one (the last Fix done), the next loads the last,
##            which starts the ending's wait.
##   `first_wash`: "First wash": PENDING again and `HELD` Socks held round the station's washer, let in by the next
##                 bin used on it. Refused while one plays.
## It keeps nothing in a save.
class_name LaundryRun
extends Part

const LAST_FIX := &"last_fix"
const FINAL := &"final"
const FIRST_WASH := &"first_wash"
## How many Socks "First wash" holds, and how far round the station's washer they lie (metres).
const HELD := 6
const HELD_RING := 1.4

## The station's Laundry day, and the washer box the held Socks lie round.
@export var day: LaundryDay
@export var washer: Node3D

@export_group("State")
## "Last Fix done": the machine is fixed.
@export var fixed := false
## The held Socks: their Designs and Mess.POSE floats each, let in by the First wash.
@export var held_designs := PackedInt32Array()
@export var held_poses := PackedFloat32Array()
@export_group("")


func save_state() -> Dictionary:
	return {}


func accepts() -> Dictionary[StringName, Dictionary]:
	return {
		LAST_FIX: {"args": {"on": TYPE_BOOL}, "rate": 5},
		FINAL: {"args": {}, "rate": 5},
		FIRST_WASH: {"args": {}, "rate": 5},
	}


func decide(cmd: Command) -> Dictionary:
	if day == null:
		return refuse("wrong")
	match cmd.kind:
		LAST_FIX:
			var on: Variant = cmd.args.get("on")
			if not (on is bool) or on == fixed:
				return refuse("wrong")
			return grant({"fixed": on})
		FINAL:
			return _final_answer()
		FIRST_WASH:
			return _first_wash_answer()
	return refuse("wrong")


# --- The run's reads -----------------------------------------------------------------------------

func is_fixed() -> bool:
	return fixed


## The held Socks into the Mess (the Laundry day's First wash asks it), or a no when none are held.
func lay_first_answer() -> Dictionary:
	var mess := _mess()
	if held_designs.is_empty() or mess == null:
		return refuse("already")
	return {"ok": true, "changes": {mess.id: mess.added_lying_patch(held_designs, held_poses),
			id: {"held_designs": PackedInt32Array(), "held_poses": PackedFloat32Array()}}}


# --- Answers -------------------------------------------------------------------------------------

func _final_answer() -> Dictionary:
	var used := day.used_bins()
	if used.is_empty() or day.final_started or day.ending_left >= 0.0:
		return refuse("wrong")
	var patch := {}
	var changes := {id: {"fixed": true}, day.id: patch}
	if day.loaded_bins < used.size() - 1:
		for i in used.size() - 1:
			changes[used[i].id] = {"full": false}
		patch["loaded_bins"] = used.size() - 1
	else:
		changes[used[used.size() - 1].id] = {"full": false}
		patch["loaded_bins"] = used.size()
		patch["ending_left"] = day.tuning.tip_seconds if day.tuning != null else 1.4
	return {"ok": true, "changes": changes}


func _first_wash_answer() -> Dictionary:
	if day.first_wash == LaundryDay.FirstWash.PLAYING:
		return refuse("busy")
	var mess := _mess()
	var designs := PackedInt32Array()
	var poses := PackedFloat32Array()
	if mess != null and mess.catalogue != null and mess.catalogue.size() > 0 and washer != null:
		var middle := washer.global_position
		if washer is VisualInstance3D:
			middle.y = (washer.global_transform * (washer as VisualInstance3D).get_aabb()).position.y
		for i in HELD:
			designs.append(int(i / 2.0) % mess.catalogue.size())
			var a := TAU * float(i) / float(HELD) + PI * 0.5
			var at := middle + Vector3(cos(a), 0.0, sin(a)) * HELD_RING
			at.y = middle.y + 0.03
			poses.append_array(Mess.pack(Transform3D(Basis(Vector3.UP, a), at)))
	return {"ok": true, "changes": {id: {"held_designs": designs, "held_poses": poses},
			day.id: {"first_wash": LaundryDay.FirstWash.PENDING}}}


func _mess() -> Mess:
	var runtime := LevelRuntime.of(self) if is_inside_tree() else null
	return runtime.mess if runtime != null else null
